// Bukti tambahan Dart murni; bukan flutter test atau native Android.
import '../app_m0/lib/cycle_rules.dart';
import '../app_m0/lib/master_data.dart';

void check(bool valid, String message) {
  if (!valid) throw StateError(message);
}

void main() {
  check(
    dailyNeed(population: 100, weightCg: 10000, rateBp: 300) == 300,
    'Kebutuhan 300',
  );
  check(splitGrams(301, 2).join(',') == '151,150', 'Sisa gram paling awal');
  check(dailyNeed(population: 1, weightCg: 5000, rateBp: 100) == 1, 'Half-up');
  for (var n = 1; n <= 6; n++)
    for (var total = 0; total <= 310; total++)
      check(
        splitGrams(total, n).fold<int>(0, (a, b) => a + b) == total,
        'Total porsi',
      );
  for (final raw in ['', '0', '-1', '100.01', 'NaN', 'Infinity', '1.500']) {
    var rejected = false;
    try {
      parseHundredths(raw, rate: true);
    } on ValidationFailure {
      rejected = true;
    }
    check(rejected, 'Rate invalid $raw');
  }
  print(
    'M2 rumus, half-up, parser dan 1866 pembagian total lulus sebagai bukti tambahan; bukan flutter test/native SQLite/HP.',
  );
}
