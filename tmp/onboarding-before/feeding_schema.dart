import 'package:sqflite/sqflite.dart';

import 'feeding_policy.dart';

const legacyFeedingPolicy = 'legacy_manual';
bool isLele(String fish) =>
    RegExp(r'\blele\b', caseSensitive: false).hasMatch(fish);
bool automaticCycle(Map<String, Object?> cycle) =>
    cycle['feeding_policy'] == weightFeedingPolicyVersion;

Future<void> addFeedingPolicySchema(Database db) async {
  await db.execute(
    "ALTER TABLE cycles ADD COLUMN feeding_policy TEXT NOT NULL DEFAULT 'legacy_manual'",
  );
  await db.execute(
    'ALTER TABLE cycle_slots ADD COLUMN normal_auto_g INTEGER CHECK(normal_auto_g>=0)',
  );
  for (final column in [
    'policy_version TEXT',
    'water_temperature_deci_c INTEGER',
    'water_ph_hundredths INTEGER',
    'water_recorded_at_ms INTEGER',
    'recommendation_status TEXT',
    'recommended_g INTEGER',
    'temperature_percent INTEGER',
    'temperature_reduction_g INTEGER',
    'temperature_status TEXT',
    'ph_status TEXT',
    'recommendation_reason TEXT',
    'rate_reference TEXT',
  ]) {
    await db.execute('ALTER TABLE feedings ADD COLUMN $column');
  }
  // Only IDs already prepared before this migration can retain their old input.
  await db.execute(
    'CREATE TABLE legacy_feeding_intents (id TEXT PRIMARY KEY REFERENCES action_intents(id))',
  );
  await db.execute(
    "INSERT INTO legacy_feeding_intents SELECT id FROM action_intents WHERE state='prepared' AND kind='feeding'",
  );
  final cycles = await db.query('cycles', where: "status='active'");
  for (final cycle in cycles) {
    if (isLele(cycle['fish'] as String)) {
      await db.update(
        'cycles',
        {'feeding_policy': weightFeedingPolicyVersion},
        where: 'id=?',
        whereArgs: [cycle['id']],
      );
    }
  }
}
