import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'master_data.dart';
import 'master_repository.dart';
import 'cycle_rules.dart';
import 'action_journal.dart';
import 'day_actual.dart';

class SqliteCycleRepository implements CycleRepository {
  SqliteCycleRepository(this.master, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final SqliteMasterRepository master;
  final DateTime Function() clock;
  Future<Map<String, Object?>> cycleIn(DatabaseExecutor db, String id) =>
      _cycle(db, id);
  Future<int> rateIn(DatabaseExecutor db, String id) => _rate(db, id);
  Future<String> zoneIn(DatabaseExecutor db) => _zone(db);
  Future<void> refreshDayIn(
    DatabaseExecutor db,
    Map<String, Object?> cycle,
    String date,
  ) => _materialize(db, cycle, date);
  @override
  Future<String?> lockedZone() async {
    final rows = await (await master.database()).query('business_settings');
    return rows.isEmpty ? null : rows.single['zone'] as String;
  }

  Future<String> _zone(DatabaseExecutor db) async {
    final rows = await db.query('business_settings');
    if (rows.isEmpty)
      throw const ValidationFailure('Zona usaha belum ditetapkan.');
    return rows.single['zone'] as String;
  }

  Future<Map<String, Object?>> _cycle(DatabaseExecutor db, String id) async {
    final rows = await db.query(
      'cycles',
      where: 'id=? AND status=?',
      whereArgs: [id, 'active'],
    );
    if (rows.isEmpty)
      throw const ValidationFailure('Siklus aktif tidak ditemukan.');
    return rows.single;
  }

  Future<int> _rate(DatabaseExecutor db, String id) async {
    final rows = await db.query(
      'cycle_rates',
      where: 'cycle_id=?',
      whereArgs: [id],
      orderBy: 'seq DESC',
      limit: 1,
    );
    if (rows.isEmpty)
      throw const ValidationFailure(
        'Belum bisa dihitung: rate belum tersedia.',
      );
    return rows.single['rate_bp'] as int;
  }

  Future<List<int>> _template(
    DatabaseExecutor db,
    String id,
    String date,
  ) async {
    final schedules = await db.query(
      'cycle_schedules',
      where: 'cycle_id=? AND effective_date<=?',
      whereArgs: [id, date],
      orderBy: 'effective_date DESC',
      limit: 1,
    );
    if (schedules.isEmpty)
      throw const ValidationFailure('Jadwal tidak ditemukan.');
    final times = await db.query(
      'cycle_times',
      where: 'schedule_id=?',
      whereArgs: [schedules.single['id']],
      orderBy: 'minute',
    );
    return validTimes(times.map((row) => row['minute'] as int).toList());
  }

  Future<void> _materialize(
    DatabaseExecutor db,
    Map<String, Object?> cycle,
    String date,
  ) async {
    if (date.compareTo(cycle['start_date'] as String) < 0)
      throw const ValidationFailure(
        'Tanggal sebelum tebar ditolak. Periksa jam HP.',
      );
    final id = cycle['id'] as String;
    var slots = await db.query(
      'cycle_slots',
      where: 'cycle_id=? AND business_date=?',
      whereArgs: [id, date],
      orderBy: 'minute',
    );
    final hours = slots.isEmpty
        ? await _template(db, id, date)
        : slots.map((row) => row['minute'] as int).toList();
    final need = dailyNeed(
      population: cycle['current_count'] as int,
      weightCg: cycle['current_weight_cg'] as int,
      rateBp: await _rate(db, id),
    );
    if (slots.isEmpty) {
      final portions = splitGrams(need, hours.length);
      for (var i = 0; i < hours.length; i++) {
        await db.insert('cycle_slots', {
          'cycle_id': id,
          'business_date': date,
          'minute': hours[i],
          'planned_g': portions[i],
        });
      }
      return;
    }
    final actual = await actualForDay(db, id, date);
    final pending = slots.where((slot) => slot['status'] == 'pending').toList();
    if (pending.isEmpty) return;
    final portions = pendingPortions(need, actual, pending.length);
    for (var i = 0; i < pending.length; i++) {
      await db.update(
        'cycle_slots',
        {'planned_g': portions[i]},
        where: 'cycle_id=? AND business_date=? AND minute=? AND status=?',
        whereArgs: [id, date, pending[i]['minute'], 'pending'],
      );
    }
  }

  void _checkDate(String actual, String expected) {
    if (actual != expected)
      throw const ValidationFailure(
        'Hari sudah berganti. Buka ulang form untuk meninjau tanggal baru.',
      );
  }

  @override
  Future<void> start(StartCycle draft) async {
    await ActionJournal(master).guard(
      draft.id,
      'cycle_start',
      {
        'pond': draft.pondId,
        'feed': draft.feedId,
        'fish': draft.fish.trim(),
        'count': draft.count,
        'weight': draft.weightCg,
        'rate': draft.rateBp,
        'times': validTimes(draft.times),
        'zone': draft.zone,
        'date': draft.date,
      },
      'cycle-start:${draft.pondId}',
      () => _startTransaction(draft),
    );
  }

  Future<void> _startTransaction(StartCycle draft) async {
    await (await master.database()).transaction((txn) async {
      final times = validTimes(draft.times);
      if (draft.fish.trim().isEmpty || draft.count <= 0)
        throw const ValidationFailure(
          'Jenis ikan dan jumlah awal wajib valid.',
        );
      dailyNeed(
        population: draft.count,
        weightCg: draft.weightCg,
        rateBp: draft.rateBp,
      );
      final settings = await txn.query('business_settings');
      if (settings.isNotEmpty && settings.single['zone'] != draft.zone)
        throw const ValidationFailure('Zona usaha sudah terkunci.');
      final date = businessDate(clock(), draft.zone);
      _checkDate(date, draft.date);
      final payload = jsonEncode([
        draft.pondId,
        draft.feedId,
        draft.fish.trim(),
        draft.count,
        draft.weightCg,
        draft.rateBp,
        times,
        draft.zone,
        draft.date,
      ]);
      final previous = await txn.query(
        'cycles',
        where: 'id=?',
        whereArgs: [draft.id],
      );
      if (previous.isNotEmpty) {
        if (previous.single['start_payload'] == payload) {
          await ActionJournal.commitIn(txn, draft.id, {'cycle': draft.id});
          return;
        }
        throw const ValidationFailure(
          'ID siklus telah dipakai oleh input lain.',
        );
      }
      final ponds = await txn.query(
        'ponds',
        where: 'id=? AND is_archived=0',
        whereArgs: [draft.pondId],
      );
      final feeds = await txn.query(
        'feeds',
        where: 'id=? AND is_archived=0 AND price_rp_kg>0',
        whereArgs: [draft.feedId],
      );
      if (ponds.isEmpty || feeds.isEmpty)
        throw const ValidationFailure(
          'Pilih kolam dan pakan aktif dengan harga positif.',
        );
      if ((await txn.query(
        'cycles',
        where: 'pond_id=? AND status=?',
        whereArgs: [draft.pondId, 'active'],
      )).isNotEmpty)
        throw const ValidationFailure('Kolam sudah memiliki siklus aktif.');
      if (settings.isEmpty)
        await txn.insert('business_settings', {'id': 1, 'zone': draft.zone});
      final cycle = <String, Object?>{
        'id': draft.id,
        'pond_id': draft.pondId,
        'feed_id': draft.feedId,
        'fish': draft.fish.trim(),
        'initial_count': draft.count,
        'weight_cg': draft.weightCg,
        'current_count': draft.count,
        'current_weight_cg': draft.weightCg,
        'start_date': date,
        'status': 'active',
        'start_payload': payload,
        'created_at_ms': clock().millisecondsSinceEpoch,
      };
      await txn.insert('cycles', cycle);
      await txn.insert('cycle_rates', {
        'cycle_id': draft.id,
        'rate_bp': draft.rateBp,
        'operation_id': draft.id,
        'changed_at_ms': clock().millisecondsSinceEpoch,
      });
      await txn.insert('cycle_schedules', {
        'id': draft.id,
        'cycle_id': draft.id,
        'effective_date': date,
      });
      for (final time in times) {
        await txn.insert('cycle_times', {
          'schedule_id': draft.id,
          'minute': time,
        });
      }
      await _materialize(txn, cycle, date);
      await ActionJournal.commitIn(txn, draft.id, {'cycle': draft.id});
    });
  }

  @override
  Future<CycleView?> active(String pondId) async {
    return (await master.database()).transaction((txn) async {
      final rows = await txn.query(
        'cycles',
        where: 'pond_id=? AND status=?',
        whereArgs: [pondId, 'active'],
      );
      if (rows.isEmpty) return null;
      final row = rows.single;
      final id = row['id'] as String;
      final zone = await _zone(txn);
      final date = businessDate(clock(), zone);
      await _materialize(txn, row, date);
      final slots = await txn.query(
        'cycle_slots',
        where: 'cycle_id=? AND business_date=?',
        whereArgs: [id, date],
        orderBy: 'minute',
      );
      final feed = (await txn.query(
        'feeds',
        where: 'id=?',
        whereArgs: [row['feed_id']],
      )).single;
      final rate = await _rate(txn, id);
      return CycleView(
        id: id,
        fish: row['fish'] as String,
        feedName: feed['name'] as String,
        startDate: row['start_date'] as String,
        population: row['current_count'] as int,
        weightCg: row['current_weight_cg'] as int,
        rateBp: rate,
        need: dailyNeed(
          population: row['current_count'] as int,
          weightCg: row['current_weight_cg'] as int,
          rateBp: rate,
        ),
        date: date,
        zone: zone,
        times: slots.map((s) => s['minute'] as int).toList(),
        portions: slots.map((s) => s['planned_g'] as int).toList(),
        tomorrowTimes: await _template(txn, id, nextDate(date)),
        actualToday: await actualForDay(txn, id, date),
        statuses: slots.map((slot) => slot['status'] as String).toList(),
      );
    });
  }

  @override
  Future<void> changeRate(
    String cycleId,
    int rateBp,
    String operationId,
    String expectedDate,
  ) async {
    await ActionJournal(master).guard(
      operationId,
      'cycle_rate',
      {'cycle': cycleId, 'rate': rateBp, 'date': expectedDate},
      'cycle-rate:$cycleId',
      () => _changeRateTransaction(cycleId, rateBp, operationId, expectedDate),
    );
  }

  Future<void> _changeRateTransaction(
    String cycleId,
    int rateBp,
    String operationId,
    String expectedDate,
  ) async {
    await (await master.database()).transaction((txn) async {
      final cycle = await _cycle(txn, cycleId);
      dailyNeed(
        population: cycle['current_count'] as int,
        weightCg: cycle['current_weight_cg'] as int,
        rateBp: rateBp,
      );
      final date = businessDate(clock(), await _zone(txn));
      _checkDate(date, expectedDate);
      final previous = await txn.query(
        'cycle_rates',
        where: 'operation_id=?',
        whereArgs: [operationId],
      );
      if (previous.isNotEmpty) {
        if (previous.single['cycle_id'] == cycleId &&
            previous.single['rate_bp'] == rateBp) {
          await ActionJournal.commitIn(txn, operationId, {'cycle': cycleId});
          return;
        }
        throw const ValidationFailure('ID perubahan rate sudah digunakan.');
      }
      await _materialize(txn, cycle, date);
      await txn.insert('cycle_rates', {
        'cycle_id': cycleId,
        'rate_bp': rateBp,
        'operation_id': operationId,
        'changed_at_ms': clock().millisecondsSinceEpoch,
      });
      await _materialize(txn, cycle, date);
      await ActionJournal.commitIn(txn, operationId, {'cycle': cycleId});
    });
  }

  @override
  Future<void> changeTimes(
    String cycleId,
    List<int> times,
    String operationId,
    String expectedDate,
  ) async {
    await ActionJournal(master).guard(
      operationId,
      'cycle_times',
      {'cycle': cycleId, 'times': validTimes(times), 'date': expectedDate},
      'cycle-times:$cycleId',
      () => _changeTimesTransaction(cycleId, times, operationId, expectedDate),
    );
  }

  Future<void> _changeTimesTransaction(
    String cycleId,
    List<int> times,
    String operationId,
    String expectedDate,
  ) async {
    await (await master.database()).transaction((txn) async {
      final hours = validTimes(times);
      final cycle = await _cycle(txn, cycleId);
      final date = businessDate(clock(), await _zone(txn));
      _checkDate(date, expectedDate);
      final tomorrow = nextDate(date);
      final previous = await txn.query(
        'schedule_changes',
        where: 'operation_id=?',
        whereArgs: [operationId],
      );
      if (previous.isNotEmpty) {
        if (previous.single['cycle_id'] == cycleId &&
            previous.single['effective_date'] == tomorrow &&
            previous.single['after_times'] == jsonEncode(hours)) {
          await ActionJournal.commitIn(txn, operationId, {'cycle': cycleId});
          return;
        }
        throw const ValidationFailure('ID perubahan jam sudah digunakan.');
      }
      await _materialize(
        txn,
        cycle,
        date,
      ); // Bekukan hari ini bahkan bila layar belum dibuka.
      final before = await _template(txn, cycleId, tomorrow);
      final versions = await txn.query(
        'cycle_schedules',
        where: 'cycle_id=? AND effective_date=?',
        whereArgs: [cycleId, tomorrow],
      );
      final id = versions.isEmpty
          ? operationId
          : versions.single['id'] as String;
      if (versions.isEmpty)
        await txn.insert('cycle_schedules', {
          'id': id,
          'cycle_id': cycleId,
          'effective_date': tomorrow,
        });
      else
        await txn.delete(
          'cycle_times',
          where: 'schedule_id=?',
          whereArgs: [id],
        );
      for (final hour in hours) {
        await txn.insert('cycle_times', {'schedule_id': id, 'minute': hour});
      }
      await txn.insert('schedule_changes', {
        'operation_id': operationId,
        'cycle_id': cycleId,
        'effective_date': tomorrow,
        'before_times': jsonEncode(before),
        'after_times': jsonEncode(hours),
        'changed_at_ms': clock().millisecondsSinceEpoch,
      });
      await ActionJournal.commitIn(txn, operationId, {'cycle': cycleId});
    });
  }
}
