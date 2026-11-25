import 'package:fishcare_m0/weather_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('field null tidak berubah menjadi nol atau waktu rekaan', () {
    final fetched = DateTime.utc(2026, 10, 13);
    final reading = WeatherReading.parse('{"current":{}}', fetched);
    expect(reading.temperature, isNull);
    expect(reading.code, isNull);
    expect(reading.providerTime, isNull);
    expect(reading.fetchedAt, fetched);
  });
  test('suhu, satuan, dan timestamp penyedia dipertahankan', () {
    final reading = WeatherReading.parse(
      '{"current":{"temperature_2m":28.5,"weather_code":3,'
      '"time":"2026-10-13T12:00"},"current_units":{"temperature_2m":"°C"}}',
      DateTime.utc(2026, 10, 13),
    );
    expect(reading.temperature, 28.5);
    expect(reading.unit, '°C');
    expect(reading.providerTime, '2026-10-13T12:00');
  });
  test('JSON rusak dan tipe salah ditolak', () {
    for (final body in [
      'invalid',
      '{}',
      '{"current":{"temperature_2m":"hot"}}',
    ]) {
      expect(
        () => WeatherReading.parse(body, DateTime.utc(2026)),
        throwsFormatException,
      );
    }
  });
}
