// Bukti tambahan Dart murni, bukan flutter test atau SQLite/native HP.
import '../app_m0/lib/cycle_rules.dart';
import '../app_m0/lib/master_data.dart';

void check(bool condition) {
  if (!condition) throw StateError('M4 rule check gagal');
}

void main() {
  check(harvestValue(20, 20000, 25000) == 100000);
  check(harvestValue(1, 50, 1000) == 1);
  check(harvestValue(1, 49, 1000) == 0);
  check(dailyNeed(population: 100, weightCg: 12000, rateBp: 300) == 360);
  check(pendingPortions(360, 150, 1).single == 210);
  check(dailyNeed(population: 0, weightCg: 12000, rateBp: 300) == 0);
  check(dailyNeed(population: 80, weightCg: 10000, rateBp: 300) == 240);
  for (final inputs in [
    [0, 100, 1],
    [1, 0, 1],
    [1, 100, 0],
    [int64Max.toInt(), 100000, 2],
  ]) {
    var rejected = false;
    try {
      harvestValue(inputs[0], inputs[1], inputs[2]);
    } on ValidationFailure {
      rejected = true;
    }
    check(rejected);
  }
  print(
    'M4 nilai panen, half-up, overflow, kebutuhan sampling/populasi dan porsi210 lulus sebagai bukti tambahan. Bukan flutter test/SQLite/HP.',
  );
}
