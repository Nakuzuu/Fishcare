import 'dart:async';

import 'package:fishcare_m0/business_location.dart';
import 'package:fishcare_m0/weather_contract.dart';
import 'package:fishcare_m0/weather_api.dart';

final locationA = BusinessLocation('Usaha lama', -6, 106);
final locationB = BusinessLocation(
  'Lokasi HP',
  -7,
  110,
  approximate: true,
  accuracy: 150,
);
ProductWeather weatherReading(int temperature) => ProductWeather.parse(
  '{"current":{"temperature_2m":$temperature,"weather_code":3,"time":"2026-10-14T12:00"},"current_units":{"temperature_2m":"°C"},"daily":{"time":["2026-10-14"],"precipitation_probability_max":[40]},"daily_units":{"precipitation_probability_max":"%"}}',
  DateTime.utc(2026, 10, 14),
);

class MemoryWeatherStore implements WeatherStore {
  BusinessLocation? value;
  int writes = 0;
  bool fail = false;
  final cached = <String, Map<String, Object?>>{};
  @override
  Future<BusinessLocation?> location() async => value;
  @override
  Future<void> confirm(BusinessLocation location) async {
    if (fail) throw StateError('Fixture storage error');
    writes++;
    value = location;
  }

  @override
  Future<Map<String, Object?>?> cache(String key) async => cached[key];
  @override
  Future<void> saveCache(String key, String body, int fetchedMs) async {
    if (value?.key == key)
      cached[key] = {'body': body, 'fetched_ms': fetchedMs};
  }
}

class FakeDeviceLocation implements DeviceLocation {
  int calls = 0, cancels = 0;
  Object? failure;
  Completer<BusinessLocation>? pending;
  @override
  Future<BusinessLocation> acquire() async {
    calls++;
    if (failure != null) throw failure!;
    return pending == null ? locationB : await pending!.future;
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }
}

class FakeBusinessApi implements BusinessWeatherApi {
  final requests = <BusinessLocation>[];
  final pending = <Completer<ProductWeather>>[];
  bool deferred = false, fail = false;
  int cancellations = 0;
  @override
  Future<ProductWeather> fetch(BusinessLocation location) async {
    requests.add(location);
    if (fail) throw StateError('Fixture offline');
    if (deferred) {
      final c = Completer<ProductWeather>();
      pending.add(c);
      return c.future;
    }
    return weatherReading(25);
  }

  @override
  Future<List<BusinessLocation>> search(String query) async => [
    BusinessLocation('Kota B, Jawa Tengah, Indonesia', -7, 110),
  ];
  @override
  void cancelWeather() {
    cancellations++;
  }

  @override
  void dispose() {}
}
