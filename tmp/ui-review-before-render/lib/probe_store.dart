import 'package:sqflite/sqflite.dart';

abstract interface class ProbeStore {
  Future<String?> read();
  Future<String> saveOnce();
}

/// Hanya satu marker M0. Tidak pernah membuka database aplikasi lama/pengguna.
class SqliteProbeStore implements ProbeStore {
  static const fileName = 'fishcare_m0_probe_v1.db';

  Future<T> _withDatabase<T>(Future<T> Function(Database) action) async {
    final directory = await getDatabasesPath();
    final db = await openDatabase(
      '$directory/$fileName',
      version: 1,
      onCreate: (db, version) => db.execute(
        'CREATE TABLE m0_probe ('
        'id INTEGER PRIMARY KEY CHECK(id = 1), '
        'marker TEXT NOT NULL)',
      ),
    );
    try {
      return await action(db);
    } finally {
      await db.close();
    }
  }

  @override
  Future<String?> read() => _withDatabase((db) async {
    final rows = await db.query('m0_probe', where: 'id = ?', whereArgs: [1]);
    return rows.isEmpty ? null : rows.single['marker'] as String;
  });

  @override
  Future<String> saveOnce() => _withDatabase((db) {
    return db.transaction((txn) async {
      final marker =
          'DATA UJI M0 — ${DateTime.now().toUtc().toIso8601String()}';
      await txn.insert('m0_probe', {
        'id': 1,
        'marker': marker,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      final rows = await txn.query('m0_probe', where: 'id = ?', whereArgs: [1]);
      return rows.single['marker'] as String;
    });
  });
}
