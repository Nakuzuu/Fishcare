import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'master_data.dart';
import 'master_repository.dart';
import 'action_payload.dart';
import 'data_changes.dart';

class ActionJournal {
  ActionJournal(this.master);
  final SqliteMasterRepository master;
  Future<Map<String, Object?>> inspect(String id) async {
    final rows = await (await master.database()).query(
      'action_intents',
      where: 'id=?',
      whereArgs: [id],
    );
    if (rows.isEmpty)
      throw const ValidationFailure(
        'ID tindakan tidak ditemukan; jangan retry memakai ID baru otomatis.',
      );
    return rows.single;
  }

  Future<void> prepare(
    String id,
    String kind,
    Map<String, Object?> payload,
    String target,
  ) async {
    if (id.trim().isEmpty || kind.isEmpty || target.isEmpty)
      throw const ValidationFailure('ID/jenis/target tindakan wajib valid.');
    final encoded = canonicalPayload(payload);
    await (await master.database()).transaction((txn) async {
      final previous = await txn.query(
        'action_intents',
        where: 'id=?',
        whereArgs: [id],
      );
      if (previous.isNotEmpty) {
        if (previous.single['kind'] != kind ||
            previous.single['payload'] != encoded ||
            previous.single['target_key'] != target)
          throw const ValidationFailure(
            'ID tindakan sama mempunyai input berbeda.',
          );
        return;
      }
      final unresolved = await txn.query(
        'action_intents',
        where: 'target_key=? AND state=?',
        whereArgs: [target, 'prepared'],
      );
      if (unresolved.isNotEmpty)
        throw ValidationFailure(
          'Ada tindakan belum pasti (${unresolved.single['id']}). Buka Pemulihan tindakan terlebih dahulu.',
        );
      await txn.insert('action_intents', {
        'id': id,
        'kind': kind,
        'payload': encoded,
        'target_key': target,
        'state': 'prepared',
        'created_at_ms': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  static Future<void> commitIn(
    DatabaseExecutor txn,
    String id,
    Map<String, Object?> result,
  ) async {
    final rows = await txn.query(
      'action_intents',
      where: 'id=?',
      whereArgs: [id],
    );
    if (rows.isEmpty)
      throw StateError('Niat harus tersimpan sebelum transaksi bisnis.');
    if (rows.single['state'] == 'committed') return;
    if (rows.single['state'] != 'prepared')
      throw const ValidationFailure(
        'Tindakan sudah ditutup; tidak dapat dijalankan ulang.',
      );
    await txn.update(
      'action_intents',
      {
        'state': 'committed',
        'result': jsonEncode(result),
        'completed_at_ms': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id=?',
      whereArgs: [id],
    );
  }

  Future<void> guard(
    String id,
    String kind,
    Map<String, Object?> payload,
    String target,
    Future<void> Function() operation,
  ) async {
    await prepare(id, kind, payload, target);
    final intent = await inspect(id);
    if (intent['state'] == 'committed') {
      DataChanges.committed();
      return;
    }
    if (intent['state'] != 'prepared')
      throw ValidationFailure(
        intent['error'] as String? ?? 'Tindakan telah ditutup.',
      );
    try {
      await operation();
      DataChanges.committed();
    } on ValidationFailure catch (error) {
      await (await master.database()).update(
        'action_intents',
        {
          'state': 'rejected',
          'error': error.message,
          'completed_at_ms': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id=? AND state=?',
        whereArgs: [id, 'prepared'],
      );
      rethrow;
    }
    // Error teknis tidak mengubah prepared: setelah restart periksa/retry ID sama.
  }

  Future<List<Map<String, Object?>>> outstanding() async =>
      (await master.database()).query(
        'action_intents',
        where: 'acknowledged=0',
        orderBy: 'created_at_ms,id',
      );
  Future<void> acknowledge(String id) async {
    await (await master.database()).update(
      'action_intents',
      {'acknowledged': 1},
      where: 'id=? AND state<>?',
      whereArgs: [id, 'prepared'],
    );
    DataChanges.committed();
  }

  Future<void> abandon(String id) async {
    await (await master.database()).transaction((txn) async {
      final rows = await txn.query(
        'action_intents',
        where: 'id=?',
        whereArgs: [id],
      );
      if (rows.isEmpty || rows.single['state'] != 'prepared')
        throw const ValidationFailure(
          'Periksa hasil terbaru; tindakan tidak lagi belum commit.',
        );
      await txn.update(
        'action_intents',
        {
          'state': 'abandoned',
          'acknowledged': 1,
          'completed_at_ms': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id=?',
        whereArgs: [id],
      );
    });
  }
}
