import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'pending hanya mendapat sisa, kelebihan aktual tidak menjadi negatif',
    () {
      expect(pendingPortions(301, 150, 2), [76, 75]);
      expect(pendingPortions(100, 150, 2), [0, 0]);
      expect(pendingPortions(301, 150, 0), isEmpty);
      expect(remainingGrams(301, 150), 151);
    },
  );
  test('biaya memakai harga snapshot, half-up per transaksi', () {
    expect(feedingCost(150, 10000), 1500);
    expect(feedingCost(1, 500), 1);
    expect(() => feedingCost(0, 10000), throwsA(isA<ValidationFailure>()));
    expect(
      () => feedingCost(9223372036854775807, 10000),
      throwsA(isA<ValidationFailure>()),
    );
  });
  test('pemberian positif, koreksi nol sah, pemisah/negatif ditolak', () {
    expect(parseGrams('150'), 150);
    expect(parseGrams('0', zero: true), 0);
    for (final value in ['0', '-1', '1.500', '1,5', 'NaN', 'Infinity'])
      expect(() => parseGrams(value), throwsA(isA<ValidationFailure>()));
    expect(
      () => parseGrams('-1', zero: true),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
