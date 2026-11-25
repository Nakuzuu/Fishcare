import '../app_m0/lib/ui_format.dart';

void main() {
  final cases = <String, (String, String)>{
    'rupiah': (uiMoney(45000), 'Rp45.000'),
    'nol': (uiMoney(0), 'Rp0'),
    'angka besar': (uiNumber(9223372036854775807), '9.223.372.036.854.775.807'),
    'desimal': (uiDecimal(1250), '12,5'),
    'desimal bulat': (uiDecimal(10000), '100'),
    'tanggal': (uiDate('2026-10-20'), '20 Okt 2026'),
    'waktu': (
      uiDateTime(DateTime.utc(2026, 10, 20, 13, 5)),
      '20 Okt 2026, 13.05',
    ),
  };
  for (final entry in cases.entries) {
    if (entry.value.$1 != entry.value.$2)
      throw StateError('${entry.key}: ${entry.value.$1} != ${entry.value.$2}');
  }
  print(
    '${cases.length} pemeriksaan format tampilan lulus. Bukti Dart murni tambahan; bukan flutter test atau render.',
  );
}
