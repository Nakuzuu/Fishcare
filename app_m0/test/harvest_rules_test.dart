import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/master_data.dart';

void main() {
  test('nilai panen memakai gram berskala dan half-up', () {
    expect(harvestValue(20, 20000, 25000), 100000);
    expect(harvestValue(1, 50, 1000), 1);
    expect(harvestValue(1, 49, 1000), 0);
    expect(() => harvestValue(0, 100, 1), throwsA(isA<ValidationFailure>()));
    expect(() => harvestValue(1, -1, 1), throwsA(isA<ValidationFailure>()));
    expect(() => harvestValue(1, 100, 0), throwsA(isA<ValidationFailure>()));
    expect(
      () => harvestValue(int64Max.toInt(), 100000, 2),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
