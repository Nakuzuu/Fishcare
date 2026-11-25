import 'cycle_rules.dart';
import 'feeding_policy.dart';
import 'master_data.dart';

int parseWaterNumber(String raw, {required bool ph}) {
  final decimals = ph ? 2 : 1;
  final value = raw.trim();
  if (!RegExp('^\\d+(?:[.,]\\d{1,$decimals})?\$').hasMatch(value)) {
    throw ValidationFailure(
      ph
          ? 'Isi pH maksimal dua desimal, contoh 7,25.'
          : 'Isi suhu maksimal satu desimal, contoh 27,5.',
    );
  }
  final parts = value.replaceAll(',', '.').split('.');
  if (parts.first.length > 3)
    throw const ValidationFailure('Pengukuran di luar batas input.');
  final scale = ph ? 100 : 10;
  final number =
      int.parse(parts.first) * scale +
      int.parse(parts.length == 1 ? '0' : parts[1].padRight(decimals, '0'));
  if (number > (ph ? 1400 : 500))
    throw ValidationFailure(
      ph ? 'pH harus 0 sampai 14.' : 'Suhu input harus 0 sampai 50 °C.',
    );
  return number;
}

FeedingWaterReading readingFromPayload(
  Map<String, Object?> p,
  DateTime now,
  String zone,
) {
  final temp = p['water_temperature_deci_c'],
      ph = p['water_ph_hundredths'],
      stamp = p['water_recorded_at_ms'];
  if (temp is! int || ph is! int || stamp is! int) {
    throw const ValidationFailure(
      'Suhu air dan pH pengukuran saat ini wajib diisi.',
    );
  }
  final reading = FeedingWaterReading(
    temperatureDeciC: temp,
    phHundredths: ph,
    recordedAtMs: stamp,
  );
  if (stamp > now.millisecondsSinceEpoch ||
      businessDate(
            DateTime.fromMillisecondsSinceEpoch(stamp, isUtc: true),
            zone,
          ) !=
          p['date']) {
    throw const ValidationFailure(
      'Waktu pengukuran berbeda hari atau berada di masa depan. Ukur kembali.',
    );
  }
  return reading;
}
