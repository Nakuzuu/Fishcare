// Bukti tambahan Dart/HTTPS di laptop; bukan flutter test atau uji HP.
import '../app_m0/lib/weather_probe.dart';

import 'dart:io';

Future<void> main() async {
  final fetched = DateTime.utc(2026, 10, 13);
  final empty = WeatherReading.parse('{"current":{}}', fetched);
  if (empty.temperature != null || empty.providerTime != null) {
    throw StateError('Field null berubah menjadi nilai rekaan');
  }
  for (final body in ['bad', '{}', '{"current":{"temperature_2m":"bad"}}']) {
    var rejected = false;
    try {
      WeatherReading.parse(body, fetched);
    } on FormatException {
      rejected = true;
    }
    if (!rejected) throw StateError('Respons invalid diterima');
  }
  stdout.writeln('Pemeriksaan parser tambahan lulus (bukan flutter test).');
  stdout.writeln('Lokasi uji: ${OpenMeteoProbe.locationLabel}');
  stdout.writeln('URL: ${OpenMeteoProbe.uri}');
  final probe = OpenMeteoProbe();
  try {
    final reading = await probe.fetch();
    stdout.writeln(
      'API laptop: suhu=${reading.temperature}, unit=${reading.unit}, '
      'WMO=${reading.code}, data=${reading.providerTime}, '
      'fetched=${reading.fetchedAt.toIso8601String()}',
    );
  } catch (error, stack) {
    stderr.writeln('API laptop gagal: $error\n$stack');
    exitCode = 1;
  } finally {
    probe.cancel();
  }
}
