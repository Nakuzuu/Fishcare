import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'action_journal.dart';
import 'cycle_repository.dart';
import 'cycle_rules.dart';
import 'day_actual.dart';
import 'master_data.dart';
import 'master_repository.dart';
import 'm4_operations.dart';
import 'feeding_policy.dart';
import 'feeding_schema.dart';
import 'feeding_input.dart';
import 'action_payload.dart';

class FeedRepository {
  FeedRepository(this.master, this.cycles) : journal = ActionJournal(master);
  final SqliteMasterRepository master;
  final SqliteCycleRepository cycles;
  final ActionJournal journal;
  Future<int> balanceIn(DatabaseExecutor db, String feed) async {
    final rows = await db.query(
      'stock_movements',
      columns: ['delta_g'],
      where: 'feed_id=?',
      whereArgs: [feed],
    );
    return checkedInteger(
      rows.fold<BigInt>(
        BigInt.zero,
        (sum, row) => sum + BigInt.from(row['delta_g'] as int),
      ),
    );
  }

  Future<int> balance(String feed) async =>
      balanceIn(await master.database(), feed);
  Future<List<Map<String, Object?>>> movements(String feed) async =>
      (await master.database()).query(
        'stock_movements',
        where: 'feed_id=?',
        whereArgs: [feed],
        orderBy: 'seq DESC',
      );
  Future<List<Map<String, Object?>>> history(String cycle) async =>
      (await master.database()).rawQuery(
        '''SELECT f.*,
        CASE WHEN f.id=(SELECT id FROM operations WHERE cycle_id=f.cycle_id
          AND cancel_action_id IS NULL ORDER BY seq DESC LIMIT 1) THEN 1 ELSE 0 END is_last_operation
        FROM feedings f WHERE f.cycle_id=? ORDER BY f.seq DESC''',
        [cycle],
      );
  Future<int> effectiveIn(DatabaseExecutor db, String source) async {
    final rows = await db.query(
      'stock_movements',
      where: 'id=? AND kind=?',
      whereArgs: [source, 'in'],
    );
    if (rows.isEmpty)
      throw const ValidationFailure('Stok masuk asal tidak ditemukan.');
    final corrections = await db.query(
      'stock_movements',
      columns: ['delta_g'],
      where: 'original_in_id=? AND kind=?',
      whereArgs: [source, 'correction'],
    );
    return checkedInteger(
      corrections.fold<BigInt>(
        BigInt.from(rows.single['delta_g'] as int),
        (sum, row) => sum + BigInt.from(row['delta_g'] as int),
      ),
    );
  }

  Future<int> effective(String source) async =>
      effectiveIn(await master.database(), source);
  Future<Map<String, Object?>> contextFor(
    String cycle,
    String date,
    int minute,
  ) async => (await master.database()).transaction((txn) async {
    await _date(txn, {'date': date});
    return contextIn(txn, await cycles.cycleIn(txn, cycle), date, minute);
  });

  Future<Map<String, Object?>> contextIn(
    DatabaseExecutor txn,
    Map<String, Object?> c,
    String date,
    int minute,
  ) async {
    await cycles.refreshDayIn(txn, c, date);
    final feed = (await txn.query(
      'feeds',
      where: 'id=?',
      whereArgs: [c['feed_id']],
    )).single;
    final slots = await txn.query(
      'cycle_slots',
      where: 'cycle_id=? AND business_date=?',
      whereArgs: [c['id'], date],
      orderBy: 'minute',
    );
    final matches = slots.where((s) => s['minute'] == minute);
    if (matches.isEmpty) throw const ValidationFailure('Slot tidak ditemukan.');
    final slot = matches.single;
    final auto = automaticCycle(c);
    final rate = await cycles.rateIn(txn, c['id'] as String);
    final need = c['current_count'] == 0
        ? 0
        : rate == null
        ? null
        : dailyNeed(
            population: c['current_count'] as int,
            weightCg: c['current_weight_cg'] as int,
            rateBp: rate,
          );
    final actual = await actualForDay(txn, c['id'] as String, date);
    final operations = (await txn.rawQuery(
      'SELECT count(*) AS n,coalesce(max(seq),0) AS seq,coalesce(sum(cancel_action_id IS NOT NULL),0) AS cancelled FROM operations WHERE cycle_id=?',
      [c['id']],
    )).single;
    final rateChanges = (await txn.rawQuery(
      'SELECT coalesce(max(seq),0) AS seq FROM cycle_rates WHERE cycle_id=?',
      [c['id']],
    )).single;
    final result = <String, Object?>{
      'cycle': c['id'],
      'date': date,
      'minute': minute,
      'feed': feed['id'],
      'feed_name': feed['name'],
      'price': feed['price_rp_kg'],
      'feed_revision': feed['revision'],
      'stock': await balanceIn(txn, feed['id'] as String),
      'rate': rate,
      'need': need,
      'actual': actual,
      'population': c['current_count'],
      'weight': c['current_weight_cg'],
      'plan': auto ? slot['normal_auto_g'] : slot['planned_g'],
      'state': slot['status'],
      'automatic': auto,
      'policy_version': auto ? weightFeedingPolicyVersion : legacyFeedingPolicy,
      'times': slots.map((s) => s['minute'] as int).toList(),
      'remaining': need == null
          ? null
          : auto
          ? slots
                .where((s) => s['status'] == 'pending')
                .fold<int>(
                  0,
                  (sum, s) => sum + (s['normal_auto_g'] as int? ?? 0),
                )
          : remainingGrams(need, actual),
      'operations': operations,
      'rate_changes': rateChanges,
    };
    result['expected_context'] = canonicalPayload({...result}..remove('stock'));
    if (auto && rate != null)
      result['day'] = await cycles.weightDayIn(txn, c, date);
    return result;
  }

  String target(String kind, Map<String, Object?> p) => switch (kind) {
    'stock_in' => 'stock-add:${p['feed']}',
    'stock_correct' => 'stock-correct:${p['source']}',
    'feeding' || 'skip' => 'slot:${p['cycle']}:${p['date']}:${p['minute']}',
    'cancel' => 'cancel:${p['feeding']}',
    'sampling' ||
    'death' ||
    'partial' ||
    'final' ||
    'grading_plan' => 'lifecycle:${p['cycle']}',
    'cancel_operation' => 'cancel:${p['operation']}',
    _ => throw const ValidationFailure('Jenis tindakan tidak didukung.'),
  };
  Future<void> run(String id, String kind, Map<String, Object?> payload) async {
    await journal.guard(id, kind, payload, target(kind, payload), () async {
      await (await master.database()).transaction((txn) async {
        final intent = (await txn.query(
          'action_intents',
          where: 'id=?',
          whereArgs: [id],
        )).single;
        if (intent['state'] == 'committed') return;
        if (intent['state'] != 'prepared')
          throw const ValidationFailure('Tindakan sudah ditutup.');
        final p = Map<String, Object?>.from(
          jsonDecode(intent['payload'] as String) as Map,
        );
        if (kind == 'stock_in' || kind == 'stock_correct')
          await _stock(txn, id, kind, p);
        else if ([
          'sampling',
          'grading_plan',
          'death',
          'partial',
          'final',
          'cancel_operation',
        ].contains(kind))
          await lifecycleTransaction(
            txn,
            cycles,
            id,
            kind,
            p,
            await _date(txn, p),
          );
        else
          await _feeding(txn, id, kind, p);
        await ActionJournal.commitIn(txn, id, {'id': id, 'kind': kind});
      });
    });
  }

  Future<void> resume(String id) async {
    final intent = await journal.inspect(id); // hasil commit diperiksa dahulu
    if (intent['state'] == 'committed') return;
    if (intent['state'] != 'prepared')
      throw ValidationFailure(
        intent['error'] as String? ?? 'Tindakan sudah ditutup.',
      );
    final p = Map<String, Object?>.from(
      jsonDecode(intent['payload'] as String) as Map,
    );
    final kind = intent['kind'] as String;
    if (kind == 'cycle_start') {
      await cycles.start(
        StartCycle(
          id: id,
          pondId: p['pond'] as String,
          feedId: p['feed'] as String,
          fish: p['fish'] as String,
          count: p['count'] as int,
          weightCg: p['weight'] as int,
          rateBp: p['rate'] as int?,
          feedingPolicy: p['feeding_policy'] as String? ?? legacyFeedingPolicy,
          times: (p['times'] as List).cast<int>(),
          zone: p['zone'] as String,
          date: p['date'] as String,
        ),
      );
    } else if (kind == 'cycle_rate')
      await cycles.changeRate(
        p['cycle'] as String,
        p['rate'] as int,
        id,
        p['date'] as String,
      );
    else if (kind == 'cycle_times')
      await cycles.changeTimes(
        p['cycle'] as String,
        (p['times'] as List).cast<int>(),
        id,
        p['date'] as String,
      );
    else
      await run(id, kind, p);
  }

  Future<String> _date(
    DatabaseExecutor txn,
    Map<String, Object?> p, {
    bool initialZone = false,
  }) async {
    final settings = await txn.query('business_settings');
    final String zone;
    if (settings.isEmpty) {
      if (!initialZone)
        throw const ValidationFailure('Zona usaha belum tersedia.');
      zone = p['zone'] as String;
      businessDate(cycles.clock(), zone);
      await txn.insert('business_settings', {'id': 1, 'zone': zone});
    } else {
      zone = settings.single['zone'] as String;
      if (p['zone'] != null && p['zone'] != zone)
        throw const ValidationFailure('Zona usaha sudah terkunci.');
    }
    final date = businessDate(cycles.clock(), zone);
    if (date != p['date'])
      throw const ValidationFailure(
        'Hari sudah berganti. Tindakan lama tidak dijalankan pada tanggal baru.',
      );
    return date;
  }

  void _reason(Map<String, Object?> p) {
    if ((p['reason'] as String? ?? '').trim().isEmpty)
      throw const ValidationFailure('Alasan wajib diisi.');
  }

  Future<void> _movement(
    DatabaseExecutor txn,
    String id,
    String feed,
    String kind,
    int delta,
    String date, {
    String? source,
    String? feeding,
  }) async {
    await txn.insert('stock_movements', {
      'id': id,
      'feed_id': feed,
      'kind': kind,
      'delta_g': delta,
      'original_in_id': source,
      'feeding_id': feeding,
      'business_date': date,
      'created_at_ms': cycles.clock().millisecondsSinceEpoch,
    });
  }

  Future<void> _stock(
    DatabaseExecutor txn,
    String id,
    String kind,
    Map<String, Object?> p,
  ) async {
    final date = await _date(txn, p, initialZone: kind == 'stock_in');
    if (kind == 'stock_in') {
      final amount = p['grams'] as int;
      if (amount <= 0)
        throw const ValidationFailure('Stok masuk harus positif.');
      checkedInteger(BigInt.from(amount));
      final feed = p['feed'] as String;
      if ((await txn.query(
        'feeds',
        where: 'id=? AND is_archived=0',
        whereArgs: [feed],
      )).isEmpty)
        throw const ValidationFailure('Pakan aktif tidak tersedia.');
      checkedInteger(
        BigInt.from(await balanceIn(txn, feed)) + BigInt.from(amount),
      );
      await _movement(txn, id, feed, 'in', amount, date);
    } else {
      _reason(p);
      final source = p['source'] as String;
      final original = (await txn.query(
        'stock_movements',
        where: 'id=? AND kind=?',
        whereArgs: [source, 'in'],
      ));
      if (original.isEmpty)
        throw const ValidationFailure('Asal stok masuk tidak ditemukan.');
      final old = await effectiveIn(txn, source), value = p['new'] as int;
      checkedInteger(BigInt.from(value));
      if (old != p['old'])
        throw const ValidationFailure(
          'Jumlah efektif telah berubah. Tinjau koreksi lagi.',
        );
      if (value == old)
        throw const ValidationFailure('Tidak ada perubahan jumlah.');
      final feed = original.single['feed_id'] as String;
      final delta = value - old;
      checkedInteger(
        BigInt.from(await balanceIn(txn, feed)) + BigInt.from(delta),
      );
      await txn.insert('stock_corrections', {
        'id': id,
        'source_id': source,
        'old_g': old,
        'new_g': value,
        'reason': (p['reason'] as String).trim(),
        'business_date': date,
        'created_at_ms': cycles.clock().millisecondsSinceEpoch,
      });
      await _movement(txn, id, feed, 'correction', delta, date, source: source);
    }
  }

  Future<void> _feeding(
    DatabaseExecutor txn,
    String id,
    String kind,
    Map<String, Object?> p,
  ) async {
    final date = await _date(txn, p);
    if (kind == 'cancel') {
      _reason(p);
      final rows = await txn.query(
        'feedings',
        where: 'id=?',
        whereArgs: [p['feeding']],
      );
      if (rows.isEmpty)
        throw const ValidationFailure('Pemberian tidak ditemukan.');
      final original = rows.single;
      final cycle = await cycles.cycleIn(txn, original['cycle_id'] as String);
      await lastCancelable(txn, original['id'] as String, date);
      final latest = await txn.query(
        'feedings',
        where: 'cycle_id=? AND cancel_action_id IS NULL',
        whereArgs: [cycle['id']],
        orderBy: 'seq DESC',
        limit: 1,
      );
      if (original['business_date'] != date ||
          original['cancel_action_id'] != null ||
          latest.isEmpty ||
          latest.single['id'] != original['id'])
        throw const ValidationFailure(
          'Hanya pemberian sah terakhir hari ini pada siklus aktif dapat dibatalkan.',
        );
      final feed = original['feed_id'] as String,
          amount = original['actual_g'] as int;
      checkedInteger(
        BigInt.from(await balanceIn(txn, feed)) + BigInt.from(amount),
      );
      await txn.update(
        'feedings',
        {
          'cancel_action_id': id,
          'cancel_reason': (p['reason'] as String).trim(),
        },
        where: 'id=?',
        whereArgs: [original['id']],
      );
      await _movement(
        txn,
        id,
        feed,
        'reversal',
        amount,
        date,
        feeding: original['id'] as String,
      );
      await txn.update(
        'operations',
        {
          'cancel_action_id': id,
          'cancel_reason': (p['reason'] as String).trim(),
        },
        where: 'id=?',
        whereArgs: [original['id']],
      );
      await txn.update(
        'cycle_slots',
        {'status': 'pending'},
        where: 'cycle_id=? AND business_date=? AND minute=?',
        whereArgs: [cycle['id'], date, original['minute']],
      );
      await cycles.refreshDayIn(txn, cycle, date);
      return;
    }
    final cycle = await cycles.cycleIn(txn, p['cycle'] as String);
    await cycles.refreshDayIn(txn, cycle, date);
    final slots = await txn.query(
      'cycle_slots',
      where: 'cycle_id=? AND business_date=? AND minute=?',
      whereArgs: [cycle['id'], date, p['minute']],
    );
    if (slots.isEmpty || slots.single['status'] != 'pending')
      throw const ValidationFailure('Slot tidak lagi menunggu atau tidak sah.');
    final slot = slots.single;
    if (kind == 'skip') {
      await txn.update(
        'cycle_slots',
        {'status': 'skipped'},
        where: 'cycle_id=? AND business_date=? AND minute=?',
        whereArgs: [cycle['id'], date, p['minute']],
      );
    } else {
      final amount = p['grams'] as int;
      final auto = automaticCycle(cycle);
      final legacyRetry =
          auto &&
          p['policy_version'] != weightFeedingPolicyVersion &&
          (await txn.query(
            'legacy_feeding_intents',
            where: 'id=?',
            whereArgs: [id],
          )).isNotEmpty;
      if (auto &&
          !legacyRetry &&
          p['policy_version'] != weightFeedingPolicyVersion) {
        throw const ValidationFailure(
          'Aturan pakan berubah. Buka kembali form suhu dan pH.',
        );
      }
      final useAuto = auto && !legacyRetry;
      final ctx = await contextIn(txn, cycle, date, p['minute'] as int);
      if ((useAuto || p.containsKey('expected_context')) &&
          p['expected_context'] != ctx['expected_context']) {
        throw const ValidationFailure(
          'Kondisi ikan, harga, jadwal atau pemberian berubah. Tinjau ulang sebelum menyimpan.',
        );
      }
      if (amount <= 0 ||
          (useAuto
              ? slot['normal_auto_g'] == null ||
                    (slot['normal_auto_g'] as int) <= 0
              : (slot['planned_g'] as int) <= 0)) {
        throw const ValidationFailure(
          'Porsi belum tersedia atau nol; lengkapi data atau gunakan Lewati.',
        );
      }
      checkedInteger(BigInt.from(amount));
      final feed = (await txn.query(
        'feeds',
        where: 'id=?',
        whereArgs: [cycle['feed_id']],
      )).single;
      final price = feed['price_rp_kg'] as int;
      final rate = useAuto
          ? await cycles.rateIn(txn, cycle['id'] as String)
          : await cycles.legacyRateIn(txn, cycle['id'] as String);
      if (rate == null || price != p['price'] || rate != p['rate']) {
        throw const ValidationFailure(
          'Harga/rate berubah atau belum tersedia. Tinjau ringkasan baru.',
        );
      }
      final need = dailyNeed(
        population: cycle['current_count'] as int,
        weightCg: cycle['current_weight_cg'] as int,
        rateBp: rate,
      );
      final actual = await actualForDay(txn, cycle['id'] as String, date);
      SlotRecommendation? recommendation;
      FeedingWaterReading? reading;
      if (useAuto || p.containsKey('water_recorded_at_ms')) {
        reading = readingFromPayload(
          p,
          cycles.clock(),
          await cycles.zoneIn(txn),
        );
      }
      if (useAuto) {
        final day = await cycles.weightDayIn(txn, cycle, date);
        recommendation = day.recommend(p['minute'] as int, reading);
        final review = day.reviewActual(
          minute: p['minute'] as int,
          grams: amount,
          reading: reading,
        );
        if (review.requiresExtraConfirmation && p['allow_excess'] != true) {
          throw const ValidationFailure(
            'Aktual melebihi rekomendasi/porsi normal/kebutuhan harian. Konfirmasi tambahan diperlukan.',
          );
        }
      } else if (amount > remainingGrams(need, actual) &&
          p['allow_excess'] != true) {
        throw const ValidationFailure(
          'Aktual melebihi sisa kebutuhan. Konfirmasi tambahan diperlukan.',
        );
      }
      if (await balanceIn(txn, feed['id'] as String) < amount)
        throw const ValidationFailure(
          'Stok kurang. Ubah aktual atau catat stok masuk; tidak ada perubahan yang disimpan.',
        );
      checkedInteger(BigInt.from(actual) + BigInt.from(amount));
      final biomass = checkedInteger(
        BigInt.from(cycle['current_count'] as int) *
            BigInt.from(cycle['current_weight_cg'] as int),
      );
      await txn.insert('feedings', {
        'id': id,
        'cycle_id': cycle['id'],
        'business_date': date,
        'minute': p['minute'],
        'feed_id': feed['id'],
        'actual_g': amount,
        'planned_snapshot_g': useAuto
            ? slot['normal_auto_g']
            : slot['planned_g'],
        'price_snapshot': price,
        'rate_snapshot': rate,
        'population_snapshot': cycle['current_count'],
        'weight_snapshot_cg': cycle['current_weight_cg'],
        'biomass_snapshot_cg': biomass,
        'cost_snapshot': feedingCost(amount, price),
        'need_snapshot_g': need,
        'policy_version': useAuto
            ? weightFeedingPolicyVersion
            : legacyFeedingPolicy,
        if (reading != null) ...reading.toSnapshot(),
        if (recommendation != null) ...{
          'recommendation_status': recommendation.status.name,
          'recommended_g': recommendation.recommendedGrams,
          'temperature_percent': recommendation.temperaturePercent,
          'temperature_reduction_g': recommendation.temperatureReductionGrams,
          'temperature_status': recommendation.conditions?.temperature.name,
          'ph_status': recommendation.conditions?.ph.name,
          'recommendation_reason': recommendation.reason,
          'rate_reference': weightFeedingPolicyReference,
        },
        'created_at_ms': cycles.clock().millisecondsSinceEpoch,
      });
      await appendOperation(
        txn,
        id,
        'feeding',
        cycle,
        date,
        amount,
        cycle['current_count'] as int,
        cycle['current_weight_cg'] as int,
        cycles.clock().millisecondsSinceEpoch,
      );
      await _movement(
        txn,
        id,
        feed['id'] as String,
        'out',
        -amount,
        date,
        feeding: id,
      );
      await txn.update(
        'cycle_slots',
        {'status': 'given'},
        where: 'cycle_id=? AND business_date=? AND minute=?',
        whereArgs: [cycle['id'], date, p['minute']],
      );
    }
    await cycles.refreshDayIn(txn, cycle, date);
  }
}
