import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'business_location.dart';
import 'weather_probe.dart';

class ProductWeather {
  ProductWeather(this.body, this.reading, this.rain, this.rainDay);
  final String body;
  final WeatherReading reading;
  final num? rain;
  final String? rainDay;
  factory ProductWeather.parse(String body, DateTime fetched) {
    final reading = WeatherReading.parse(body, fetched);
    final p = jsonDecode(body) as Map;
    final daily = p['daily'];
    num? rain;
    String? day;
    if (daily != null) {
      if (daily is! Map)
        throw const FormatException('Prakiraan harian tidak valid.');
      final amounts = daily['precipitation_probability_max'],
          days = daily['time'];
      if (amounts != null) {
        if (amounts is! List || amounts.isEmpty)
          throw const FormatException('Peluang hujan tidak valid.');
        final v = amounts.first;
        if (v != null && (v is! num || !v.isFinite || v < 0 || v > 100))
          throw const FormatException('Peluang hujan tidak valid.');
        rain = v as num?;
      }
      if (days != null) {
        if (days is! List ||
            days.isEmpty ||
            days.first is! String ||
            DateTime.tryParse(days.first as String) == null)
          throw const FormatException('Tanggal prakiraan tidak valid.');
        day = days.first as String;
      }
      final unit = p['daily_units'];
      if (rain != null &&
          (unit is! Map || unit['precipitation_probability_max'] != '%'))
        throw const FormatException('Satuan peluang hujan tidak valid.');
    }
    return ProductWeather(body, reading, rain, day);
  }
}

abstract interface class BusinessWeatherApi {
  Future<ProductWeather> fetch(BusinessLocation location);
  Future<List<BusinessLocation>> search(String query);
  void cancelWeather();
  void dispose();
}

class OpenMeteoBusinessApi implements BusinessWeatherApi {
  final _clients = <HttpClient>{};
  HttpClient? _weather;
  Future<String> _get(Uri uri, {bool weather = false}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    _clients.add(client);
    if (weather) _weather = client;
    try {
      return await (() async {
        final response = await (await client.getUrl(uri)).close();
        if (response.statusCode != 200)
          throw HttpException('HTTP ${response.statusCode}', uri: uri);
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 256 * 1024)
            throw const FormatException('Respons terlalu besar.');
        }
        return utf8.decode(bytes);
      })().timeout(const Duration(seconds: 10));
    } finally {
      client.close(force: true);
      _clients.remove(client);
      if (identical(_weather, client)) _weather = null;
    }
  }

  @override
  Future<ProductWeather> fetch(BusinessLocation location) async {
    final body = await _get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': '${location.latitude}',
        'longitude': '${location.longitude}',
        'current': 'temperature_2m,weather_code',
        'daily': 'precipitation_probability_max',
        'forecast_days': '1',
        'timezone': 'auto',
      }),
      weather: true,
    );
    return ProductWeather.parse(body, DateTime.now().toUtc());
  }

  @override
  Future<List<BusinessLocation>> search(String query) async {
    final p = jsonDecode(
      await _get(
        Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
          'name': query.trim(),
          'count': '10',
          'language': 'id',
          'format': 'json',
        }),
      ),
    );
    if (p is! Map || (p['results'] != null && p['results'] is! List))
      throw const FormatException('Hasil pencarian tidak valid.');
    return [
      for (final row in (p['results'] as List? ?? []))
        BusinessLocation(
          [
            row['name'],
            row['admin1'],
            row['country'],
          ].where((v) => v is String && v.isNotEmpty).join(', '),
          (row['latitude'] as num).toDouble(),
          (row['longitude'] as num).toDouble(),
        ),
    ];
  }

  @override
  void cancelWeather() {
    _weather?.close(force: true);
    _weather = null;
  }

  @override
  void dispose() {
    for (final c in _clients.toList()) {
      c.close(force: true);
    }
    _clients.clear();
    _weather = null;
  }
}
