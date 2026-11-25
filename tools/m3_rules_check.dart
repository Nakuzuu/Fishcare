// Hanya bukti tambahan Dart murni; tidak menjalankan Flutter/native SQLite.
import '../app_m0/lib/cycle_rules.dart';
import '../app_m0/lib/master_data.dart';
import '../app_m0/lib/action_payload.dart';

void check(bool ok, String message) {
  if (!ok) throw StateError(message);
}

void main() {
  check(
    canonicalPayload({'grams': 150, 'date': 'd'}) ==
        canonicalPayload({'date': 'd', 'grams': 150}),
    'Payload kanonik',
  );
  check(feedingCost(150, 10000) == 1500, 'Biaya snapshot');
  check(feedingCost(1, 500) == 1, 'Half-up biaya');
  check(pendingPortions(301, 150, 2).join(',') == '76,75', 'Porsi sisa');
  check(
    pendingPortions(100, 150, 2).join(',') == '0,0',
    'Aktual melebihi kebutuhan',
  );
  check(pendingPortions(300, 150, 0).isEmpty, 'Tidak menambah slot');
  check(parseGrams('0', zero: true) == 0, 'Koreksi menjadi nol');
  for (final value in ['0', '-1', '1.500', '1,5', 'NaN', 'Infinity']) {
    var rejected = false;
    try {
      parseGrams(value);
    } on ValidationFailure {
      rejected = true;
    }
    check(rejected, 'Gram invalid $value');
  }
  print(
    'M3 biaya half-up, porsi sisa, kelebihan dan parser lulus sebagai bukti tambahan. Bukan flutter test/transaksi SQLite/HP.',
  );
}
