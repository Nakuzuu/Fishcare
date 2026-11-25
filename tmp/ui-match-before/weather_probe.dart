import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WeatherReading {
  const WeatherReading({
    required this.temperature,
    required this.unit,
    required this.code,
    required this.providerTime,
    required this.fetchedAt,
  });
  final num? temperature;
  final String? unit;
  final num? code;
  final String? providerTime;
  final DateTime fetchedAt;

  factory WeatherReading.parse(String body, DateTime fetchedAt) {
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic> || json['current'] is! Map) {
      throw const FormatException('Respons cuaca tidak memiliki current');
    }
    final current = json['current'] as Map;
    final units = json['current_units'];
    final temperature = current['temperature_2m'];
    final code = current['weather_code'];
    final time = current['time'];
    if ((temperature != null &&
            (temperature is! num || !temperature.isFinite)) ||
        (code != null && (code is! num || !code.isFinite)) ||
        (time != null &&
            (time is! String || DateTime.tryParse(time) == null))) {
      throw const FormatException('Field cuaca tidak valid');
    }
    final unit = units is Map ? units['temperature_2m'] : null;
    if (unit != null && unit is! String) {
      throw const FormatException('Satuan suhu tidak valid');
    }
    return WeatherReading(
      temperature: temperature as num?,
      unit: unit as String?,
      code: code as num?,
      providerTime: time as String?,
      fetchedAt: fetchedAt,
    );
  }
}

abstract interface class WeatherSource {
  Future<WeatherReading> fetch();
  void cancel();
}

/// Lokasi uji dipilih eksplisit lewat tombol, bukan lokasi kolam pengguna.
class OpenMeteoProbe implements WeatherSource {
  static const locationLabel = 'Jakarta (lokasi uji M0, bukan lokasi kolam)';
  static final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '-6.2088',
    'longitude': '106.8456',
    'current': 'temperature_2m,weather_code',
    'timezone': 'Asia/Jakarta',
  });
  HttpClient? _client;

  @override
  Future<WeatherReading> fetch() async {
    if (_client != null) throw StateError('Permintaan sedang berjalan');
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    _client = client;
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException('HTTP ${response.statusCode}', uri: uri);
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 256 * 1024) {
            throw const FormatException('Respons cuaca terlalu besar');
          }
        }
        return WeatherReading.parse(utf8.decode(bytes), DateTime.now().toUtc());
      })().timeout(const Duration(seconds: 10));
    } finally {
      client.close(force: true);
      if (identical(_client, client)) _client = null;
    }
  }

  @override
  void cancel() {
    _client?.close(force: true);
    _client = null;
  }
}
