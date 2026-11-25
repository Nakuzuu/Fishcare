import 'package:sqflite/sqflite.dart';

import 'master_data.dart';
import 'cycle_schema.dart';
import 'm3_schema.dart';
import 'm4_schema.dart';
import 'data_changes.dart';
import 'weather_schema.dart';
import 'grading.dart';

class SqliteMasterRepository implements MasterRepository {
  SqliteMasterRepository({Future<Database> Function()? open})
    : _customOpen = open;
  static const fileName = 'fishcare_app.db';
  static const schemaVersion = 6;
  final Future<Database> Function()? _customOpen;
  Future<Database>? _opening;

  static Future<void> createSchema(Database db, int version) async {
    await createM1Schema(db, 1);
    if (version >= 2) await addCycleSchema(db);
    if (version >= 3) await addM3Schema(db);
    if (version >= 4) await addM4Schema(db);
    if (version >= 5) await addWeatherSchema(db);
    if (version >= 6) await addGradingSchema(db);
  }

  static Future<void> addGradingSchema(Database db) async {
    for (final sql in gradingSchema) {
      await db.execute(sql);
    }
  }

  static Future<void> addWeatherSchema(Database db) async {
    for (final sql in weatherSchema) {
      await db.execute(sql);
    }
  }

  static Future<void> addM4Schema(Database db) async {
    for (final sql in m4Schema) {
      await db.execute(sql);
    }
  }

  static Future<void> addM3Schema(Database db) async {
    await db.execute('''CREATE TABLE cycle_slots_v3 (
      cycle_id TEXT NOT NULL REFERENCES cycles(id), business_date TEXT NOT NULL,
      minute INTEGER NOT NULL CHECK(minute>=0 AND minute<1440), planned_g INTEGER NOT NULL CHECK(planned_g>=0),
      status TEXT NOT NULL CHECK(status IN ('pending','given','skipped')) DEFAULT 'pending',
      PRIMARY KEY(cycle_id,business_date,minute))''');
    await db.execute(
      'INSERT INTO cycle_slots_v3 SELECT cycle_id,business_date,minute,planned_g,status FROM cycle_slots',
    );
    final counts = await db.rawQuery(
      'SELECT (SELECT count(*) FROM cycle_slots) old_count,(SELECT count(*) FROM cycle_slots_v3) new_count',
    );
    if (counts.single['old_count'] != counts.single['new_count'])
      throw StateError('Migrasi slot tidak lengkap.');
    await db.execute('DROP TABLE cycle_slots');
    await db.execute('ALTER TABLE cycle_slots_v3 RENAME TO cycle_slots');
    for (final sql in m3Schema) {
      await db.execute(sql);
    }
  }

  static Future<void> addCycleSchema(Database db) async {
    for (final sql in cycleSchema) {
      await db.execute(sql);
    }
  }

  static Future<void> migrateSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion >= 1 && oldVersion <= 5 && newVersion == 6) {
      if (oldVersion < 5) await migrateSchema(db, oldVersion, 5);
      await addGradingSchema(db);
      return;
    }
    if (oldVersion >= 1 && oldVersion <= 4 && newVersion == 5) {
      if (oldVersion < 4) await migrateSchema(db, oldVersion, 4);
      await addWeatherSchema(db);
      return;
    }
    if (oldVersion >= 1 && oldVersion <= 3 && newVersion == 4) {
      if (oldVersion == 1) await addCycleSchema(db);
      if (oldVersion <= 2) await addM3Schema(db);
      await addM4Schema(db);
      return;
    }
    if (oldVersion >= 1 && oldVersion <= 2 && newVersion == 3) {
      if (oldVersion == 1) await addCycleSchema(db);
      await addM3Schema(db);
      return;
    }
    if (oldVersion == 1 && newVersion == 2) {
      await addCycleSchema(db);
      return;
    }
    throw StateError(
      'Migrasi skema $oldVersion ke $newVersion belum tersedia.',
    );
  }

  static Future<void> createM1Schema(Database db, int version) async {
    for (final table in ['ponds', 'feeds']) {
      await db.execute(
        'CREATE TABLE $table ('
        'id TEXT PRIMARY KEY NOT NULL, '
        'name TEXT NOT NULL CHECK(length(trim(name)) > 0), '
        'name_key TEXT NOT NULL UNIQUE CHECK(length(name_key) > 0), '
        'notes TEXT NOT NULL DEFAULT \'\', '
        'size_description TEXT NOT NULL DEFAULT \'\', '
        'price_rp_kg INTEGER ${table == 'feeds' ? 'NOT NULL CHECK(typeof(price_rp_kg) = \'integer\' AND price_rp_kg > 0)' : 'CHECK(price_rp_kg IS NULL)'}, '
        'is_archived INTEGER NOT NULL DEFAULT 0 CHECK(is_archived IN (0,1)), '
        'revision INTEGER NOT NULL CHECK(revision > 0), '
        'created_at_ms INTEGER NOT NULL, updated_at_ms INTEGER NOT NULL)',
      );
    }
  }

  Future<Database> _db() async {
    try {
      return await (_opening ??= _customOpen?.call() ?? _openNative());
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<Database> database() => _db();

  Future<Database> _openNative() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      '$directory/$fileName',
      version: schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: createSchema,
      onUpgrade: migrateSchema,
      onDowngrade: (db, oldVersion, newVersion) async {
        throw StateError('Database versi lebih baru tidak didukung.');
      },
    );
  }

  String _table(MasterKind kind) => kind == MasterKind.pond ? 'ponds' : 'feeds';
  MasterRecord _record(MasterKind kind, Map<String, Object?> row) =>
      MasterRecord(
        id: row['id'] as String,
        kind: kind,
        name: row['name'] as String,
        notes: row['notes'] as String,
        size: row['size_description'] as String,
        price: row['price_rp_kg'] as int?,
        archived: row['is_archived'] == 1,
        revision: row['revision'] as int,
      );
  @override
  Future<List<MasterRecord>> list(
    MasterKind kind, {
    required bool archived,
  }) async {
    final rows = await (await _db()).query(
      _table(kind),
      where: 'is_archived = ?',
      whereArgs: [archived ? 1 : 0],
      orderBy: 'name_key ASC, id ASC',
    );
    return rows.map((row) => _record(kind, row)).toList();
  }

  @override
  Future<MasterRecord> get(MasterKind kind, String id) async {
    final rows = await (await _db()).query(
      _table(kind),
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty)
      throw const ValidationFailure('Data tidak ditemukan. Muat ulang daftar.');
    return _record(kind, rows.single);
  }

  @override
  Future<void> save(MasterRecord record, {required bool create}) async {
    await (await _db()).transaction((txn) async {
      final key = normalizedName(record.name);
      if (record.kind == MasterKind.feed) {
        if (record.price == null)
          throw const ValidationFailure('Harga wajib diisi.', field: 'price');
        parsePrice(record.price.toString());
      } else if (record.price != null) {
        throw const ValidationFailure(
          'Kolam tidak mempunyai harga pakan.',
          field: 'price',
        );
      }
      final table = _table(record.kind);
      final existing = await txn.query(
        table,
        where: 'id = ?',
        whereArgs: [record.id],
      );
      if (create && existing.isNotEmpty) {
        final old = _record(record.kind, existing.single);
        if (!old.archived &&
            old.name == record.name.trim() &&
            old.notes == record.notes.trim() &&
            old.size == record.size.trim() &&
            old.price == record.price)
          return;
        throw const ValidationFailure(
          'ID penyimpanan sudah dipakai. Muat ulang data.',
        );
      }
      if (!create &&
          (existing.isEmpty ||
              existing.single['revision'] != record.revision ||
              existing.single['is_archived'] != 0)) {
        throw const ValidationFailure(
          'Data telah berubah atau diarsipkan. Kembali dan muat ulang.',
        );
      }
      final duplicate = await txn.query(
        table,
        columns: ['id'],
        where: 'name_key = ? AND id <> ?',
        whereArgs: [key, record.id],
      );
      if (duplicate.isNotEmpty)
        throw const ValidationFailure(
          'Nama sudah digunakan, termasuk pada data arsip.',
        );
      final now = DateTime.now().millisecondsSinceEpoch;
      final values = <String, Object?>{
        'name': record.name.trim(),
        'name_key': key,
        'notes': record.notes.trim(),
        'size_description': record.size.trim(),
        'price_rp_kg': record.price,
        'updated_at_ms': now,
      };
      if (create) {
        await txn.insert(table, {
          ...values,
          'id': record.id,
          'is_archived': 0,
          'revision': 1,
          'created_at_ms': now,
        });
      } else {
        await txn.update(
          table,
          {...values, 'revision': record.revision + 1},
          where: 'id = ? AND revision = ? AND is_archived = 0',
          whereArgs: [record.id, record.revision],
        );
      }
    });
    DataChanges.committed();
  }

  @override
  Future<void> archive(MasterRecord record) async {
    await (await _db()).transaction((txn) async {
      final relation = record.kind == MasterKind.pond ? 'pond_id' : 'feed_id';
      if ((await txn.query(
        'cycles',
        where: '$relation=? AND status=?',
        whereArgs: [record.id, 'active'],
        limit: 1,
      )).isNotEmpty) {
        throw const ValidationFailure(
          'Tidak dapat diarsipkan: masih digunakan siklus aktif.',
        );
      }
      final count = await txn.update(
        _table(record.kind),
        {
          'is_archived': 1,
          'revision': record.revision + 1,
          'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ? AND revision = ? AND is_archived = 0',
        whereArgs: [record.id, record.revision],
      );
      if (count != 1)
        throw const ValidationFailure(
          'Data telah berubah. Muat ulang sebelum mengarsipkan.',
        );
    });
    DataChanges.committed();
  }

  Future<void> close() async {
    final pending = _opening;
    _opening = null;
    if (pending != null) await (await pending).close();
  }
}
