import 'package:sqflite/sqflite.dart';

import 'master_data.dart';

const gradingSchema = <String>[
  '''CREATE TABLE grading_records (
    operation_id TEXT PRIMARY KEY REFERENCES operations(id),
    cycle_id TEXT NOT NULL REFERENCES cycles(id),
    ordinal INTEGER NOT NULL CHECK(ordinal>0),
    before_date TEXT, before_source TEXT,
    UNIQUE(cycle_id,ordinal))''',
  '''INSERT INTO grading_records(operation_id,cycle_id,ordinal)
    SELECT o.id,o.cycle_id,(SELECT count(*) FROM operations p
      WHERE p.cycle_id=o.cycle_id AND p.kind='sampling' AND p.seq<=o.seq)
    FROM operations o WHERE o.kind='sampling' ORDER BY o.seq''',
  '''CREATE TABLE grading_plans (
    cycle_id TEXT PRIMARY KEY REFERENCES cycles(id),
    next_date TEXT, source_operation TEXT REFERENCES operations(id),
    revision INTEGER NOT NULL CHECK(revision>0))''',
];

String gradingDateAfter(String date, [int days = 7]) =>
    DateTime.parse('${date}T00:00:00Z')
        .add(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);

String validGradingPlan(Object? value, String today) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const ValidationFailure('Pilih tanggal rencana grading yang valid.');
  }
  final parsed = DateTime.tryParse('${value}T00:00:00Z');
  if (parsed == null ||
      parsed.year < 1 ||
      parsed.toIso8601String().substring(0, 10) != value ||
      value.compareTo(today) <= 0) {
    throw const ValidationFailure(
      'Rencana grading berikutnya harus setelah hari ini.',
    );
  }
  return value;
}

Future<Map<String, Object?>?> gradingPlanIn(
  DatabaseExecutor db,
  String cycle,
) async {
  final rows = await db.query(
    'grading_plans',
    where: 'cycle_id=?',
    whereArgs: [cycle],
  );
  return rows.isEmpty ? null : rows.single;
}

Future<void> recordGradingPlan(
  DatabaseExecutor db,
  String id,
  String cycle,
  String nextDate,
) async {
  final before = await gradingPlanIn(db, cycle);
  final number =
      (await db.rawQuery(
            'SELECT coalesce(max(ordinal),0)+1 AS n FROM grading_records WHERE cycle_id=?',
            [cycle],
          )).single['n']
          as int;
  await db.insert('grading_records', {
    'operation_id': id,
    'cycle_id': cycle,
    'ordinal': number,
    'before_date': before?['next_date'],
    'before_source': before?['source_operation'],
  });
  await db.insert('grading_plans', {
    'cycle_id': cycle,
    'next_date': nextDate,
    'source_operation': id,
    'revision': (before?['revision'] as int? ?? 0) + 1,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<void> restoreGradingPlan(
  DatabaseExecutor db,
  String id,
  String cycle,
) async {
  final current = await gradingPlanIn(db, cycle);
  // A separately edited plan is preserved. Legacy records never created a plan.
  if (current == null || current['source_operation'] != id) return;
  final records = await db.query(
    'grading_records',
    where: 'operation_id=?',
    whereArgs: [id],
  );
  if (records.isEmpty)
    throw StateError('Riwayat rencana grading tidak lengkap.');
  await db.update(
    'grading_plans',
    {
      'next_date': records.single['before_date'],
      'source_operation': records.single['before_source'],
      'revision': (current['revision'] as int) + 1,
    },
    where: 'cycle_id=?',
    whereArgs: [cycle],
  );
}

String gradingLabel(Map<String, Object?> row) => row['kind'] == 'sampling'
    ? 'Grading${row['grading_number'] is int ? ' ${row['grading_number']}' : ''}'
    : '';
