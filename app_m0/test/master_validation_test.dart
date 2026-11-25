import 'package:fishcare_m0/master_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nama trim dan kapitalisasi memakai key yang sama', () {
    expect(normalizedName('  Kolam A  '), normalizedName('KOLAM A'));
    expect(normalizedName('ÉTANG'), normalizedName('étang'));
    expect(() => normalizedName('   '), throwsA(isA<ValidationFailure>()));
  });
  test('harga positif bulat sampai batas SQLite int64', () {
    expect(parsePrice('1500'), 1500);
    expect(parsePrice('9223372036854775807'), 9223372036854775807);
  });
  test(
    'harga kosong, ambigu, pecahan, negatif, nonfinite, overflow ditolak',
    () {
      for (final value in [
        '',
        '0',
        '-1',
        '1.500',
        '1,5',
        '1.5',
        'NaN',
        'Infinity',
        '1e3',
        '9223372036854775808',
      ]) {
        expect(
          () => parsePrice(value),
          throwsA(isA<ValidationFailure>()),
          reason: value,
        );
      }
    },
  );
}
