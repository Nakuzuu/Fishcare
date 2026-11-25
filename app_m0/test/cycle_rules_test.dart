import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('100 ikan 100 gram rate3 menghasilkan 300 dan 150+150', () {
    final need = dailyNeed(population: 100, weightCg: 10000, rateBp: 300);
    expect(need, 300);
    expect(splitGrams(need, 2), [150, 150]);
  });
  test('301 gram dibagi paling awal; total tetap tepat untuk 1–6 slot', () {
    expect(splitGrams(301, 2), [151, 150]);
    for (var slots = 1; slots <= 6; slots++)
      for (var grams = 0; grams <= 310; grams++) {
        final portions = splitGrams(grams, slots);
        expect(portions.fold<int>(0, (a, b) => a + b), grams);
        expect(portions.first - portions.last, lessThanOrEqualTo(1));
      }
  });
  test('half-up tepat setengah naik, bawah setengah turun; tanpa float', () {
    expect(dailyNeed(population: 1, weightCg: 5000, rateBp: 100), 1);
    expect(dailyNeed(population: 1, weightCg: 4999, rateBp: 100), 0);
    expect(halfUp(BigInt.from(5), BigInt.from(2)), 3);
  });
  test('parser bobot dan rate presisi dua desimal, invalid bukan nol', () {
    expect(parseHundredths('12,5'), 1250);
    expect(parseHundredths('3.01', rate: true), 301);
    for (final raw in [
      '',
      '0',
      '-1',
      '100.01',
      'NaN',
      'Infinity',
      '1.500',
      '1,234',
    ]) {
      expect(
        () => parseHundredths(raw, rate: true),
        throwsA(isA<ValidationFailure>()),
        reason: raw,
      );
    }
    expect(
      () => dailyNeed(population: 100, weightCg: 10000, rateBp: 0),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => dailyNeed(
        population: 9223372036854775807,
        weightCg: 10000,
        rateBp: 10000,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
  test('jam duplikat/di luar rentang/lebih6 ditolak', () {
    expect(validTimes([960, 480]), [480, 960]);
    for (final times in [
      <int>[],
      [480, 480],
      [1440],
      [1, 2, 3, 4, 5, 6, 7],
    ]) {
      expect(() => validTimes(times), throwsA(isA<ValidationFailure>()));
    }
  });
  test('tanggal usaha mengikuti zona, termasuk pergantian tahun', () {
    expect(
      businessDate(DateTime.utc(2026, 12, 31, 18), 'Asia/Jakarta'),
      '2027-01-01',
    );
    expect(nextDate('2026-12-31'), '2027-01-01');
  });
}
