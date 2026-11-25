import 'package:sqflite/sqflite.dart';

import 'cycle_rules.dart';

Future<int> actualForDay(DatabaseExecutor db, String cycle, String date) async {
  final rows = await db.query(
    'feedings',
    columns: ['actual_g'],
    where: 'cycle_id=? AND business_date=? AND cancel_action_id IS NULL',
    whereArgs: [cycle, date],
  );
  return checkedInteger(
    rows.fold<BigInt>(
      BigInt.zero,
      (sum, row) => sum + BigInt.from(row['actual_g'] as int),
    ),
  );
}
