import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/cycle_repository.dart';
import 'package:fishcare_m0/feed_repository.dart';
import 'package:fishcare_m0/master_repository.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/report_repository.dart';
import 'package:fishcare_m0/report_rules.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SqliteMasterRepository master;
  late SqliteCycleRepository cycles;
  late FeedRepository feed;
  late String path;
  late DateTime now;
  Future<Database> open() => openDatabase(
    path,
    version: SqliteMasterRepository.schemaVersion,
    singleInstance: false,
    onCreate: SqliteMasterRepository.createSchema,
    onUpgrade: SqliteMasterRepository.migrateSchema,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
  );
  Future<void> restart() async {
    await master.close();
    master = SqliteMasterRepository(open: open);
    cycles = SqliteCycleRepository(master, clock: () => now);
    feed = FeedRepository(master, cycles);
  }

  Future<void> run(String id, String kind, Map<String, Object?> input) =>
      feed.run(id, kind, {'cycle': 'c', 'date': '2026-10-13', ...input});
  Future<void> give(String id, int minute, int grams) => run(id, 'feeding', {
    'minute': minute,
    'grams': grams,
    'price': 10000,
    'rate': 300,
    'allow_excess': false,
  });
  Future<void> cancel(String id, String op, {bool feeding = false}) => run(
    id,
    feeding ? 'cancel' : 'cancel_operation',
    {feeding ? 'feeding' : 'operation': op, 'reason': 'Koreksi pengujian'},
  );
  Future<Map<String, Object?>> condition() async =>
      (await (await master.database()).query(
        'cycles',
        where: 'id=?',
        whereArgs: ['c'],
      )).single;
  setUp(() async {
    path = '${await getDatabasesPath()}/m4_isolated_${newMasterId()}.db';
    now = DateTime.utc(2026, 10, 13, 2);
    master = SqliteMasterRepository(open: open);
    cycles = SqliteCycleRepository(master, clock: () => now);
    feed = FeedRepository(master, cycles);
    await master.save(
      const MasterRecord(id: 'p', kind: MasterKind.pond, name: 'Kolam M4 uji'),
      create: true,
    );
    await master.save(
      const MasterRecord(
        id: 'f',
        kind: MasterKind.feed,
        name: 'Pakan M4 uji',
        price: 10000,
      ),
      create: true,
    );
    await cycles.start(
      const StartCycle(
        id: 'c',
        pondId: 'p',
        feedId: 'f',
        fish: 'Uji',
        count: 100,
        weightCg: 10000,
        rateBp: 300,
        times: [480, 960],
        zone: 'Asia/Jakarta',
        date: '2026-10-13',
      ),
    );
    await feed.run('in', 'stock_in', {
      'feed': 'f',
      'grams': 1000,
      'zone': 'Asia/Jakarta',
      'date': '2026-10-13',
    });
  });
  tearDown(() async => master.close());
  testWidgets('sampling setelah pakan: kebutuhan360 sisa210 snapshot tetap', (
    tester,
  ) async {
    await give('g', 480, 150);
    final before = (await feed.history('c')).single;
    await run('s', 'sampling', {'count': 10, 'weight': 12000});
    final v = (await cycles.active('p'))!;
    expect(v.population, 100);
    expect(v.need, 360);
    expect(v.portions, [150, 210]);
    expect(v.remaining, 210);
    final after = (await feed.history('c')).single;
    for (final key in [
      'actual_g',
      'weight_snapshot_cg',
      'biomass_snapshot_cg',
      'price_snapshot',
      'cost_snapshot',
    ]) {
      expect(after[key], before[key]);
    }
    await expectLater(
      run('s2', 'sampling', {'count': 1, 'weight': 13000}),
      throwsA(isA<ValidationFailure>()),
    );
  });
  testWidgets(
    'kematian melebihi populasi rollback dan seluruh sisa boleh mati',
    (tester) async {
      await expectLater(
        run('bad', 'death', {'count': 150}),
        throwsA(isA<ValidationFailure>()),
      );
      expect((await condition())['current_count'], 100);
      expect(await (await master.database()).query('operations'), isEmpty);
      await run('d', 'death', {'count': 100});
      expect((await cycles.active('p'))!.need, 0);
      await run('z', 'final', {'expected_count': 0});
      expect(await cycles.active('p'), isNull);
      final rows = await (await master.database()).query('operations');
      expect(rows.last['kind'], 'close');
      expect(rows.last['value_rp'], isNull);
    },
  );
  testWidgets('parsial snapshot100000 tetap setelah sampling dan validasi', (
    tester,
  ) async {
    await expectLater(
      run('all', 'partial', {'count': 100, 'weight': 20000, 'price': 25000}),
      throwsA(isA<ValidationFailure>()),
    );
    await run('h', 'partial', {'count': 20, 'weight': 20000, 'price': 25000});
    expect((await condition())['current_count'], 80);
    await run('s', 'sampling', {'count': 5, 'weight': 15000});
    final h = (await (await master.database()).query(
      'operations',
      where: 'id=?',
      whereArgs: ['h'],
    )).single;
    expect(h['quantity'], 20);
    expect(h['harvest_weight_cg'], 20000);
    expect(h['price_rp_kg'], 25000);
    expect(h['value_rp'], 100000);
  });
  testWidgets('batal lintas kegiatan menolak lanjutan dan memulihkan tepat', (
    tester,
  ) async {
    await give('g', 480, 150);
    await run('s', 'sampling', {'count': 5, 'weight': 12000});
    await expectLater(
      cancel('cg-bad', 'g', feeding: true),
      throwsA(isA<ValidationFailure>()),
    );
    await run('d', 'death', {'count': 10});
    await run('h', 'partial', {'count': 20, 'weight': 20000, 'price': 25000});
    await expectLater(cancel('cs-bad', 's'), throwsA(isA<ValidationFailure>()));
    await cycles.changeRate('c', 400, 'r', '2026-10-13');
    await cycles.changeTimes('c', [600, 1000], 't', '2026-10-13');
    await run('skip', 'skip', {'minute': 960});
    await cancel('ch', 'h');
    expect((await condition())['current_count'], 90);
    await cancel('cd', 'd');
    expect((await condition())['current_count'], 100);
    await cancel('cs', 's');
    expect((await condition())['current_weight_cg'], 10000);
    await cancel('cg', 'g', feeding: true);
    expect(await feed.balance('f'), 1000);
    final v = (await cycles.active('p'))!;
    expect(v.portions, [400, 186]);
    expect(v.statuses, ['pending', 'skipped']);
    await expectLater(
      cancel('cg2', 'g', feeding: true),
      throwsA(isA<ValidationFailure>()),
    );
  });
  testWidgets(
    'sampling sample positif dan tidak lebih populasi; batal boleh sampling lagi',
    (tester) async {
      for (final n in [0, 101]) {
        await expectLater(
          run('bad$n', 'sampling', {'count': n, 'weight': 12000}),
          throwsA(isA<ValidationFailure>()),
        );
      }
      await run('s', 'sampling', {'count': 100, 'weight': 12000});
      await cancel('cs', 's');
      await run('s2', 'sampling', {'count': 1, 'weight': 13000});
      expect((await condition())['current_count'], 100);
    },
  );
  testWidgets('panen akhir tepat sisa idempotent dan siklus selesai terkunci', (
    tester,
  ) async {
    await run('d', 'death', {'count': 10});
    await run('h', 'partial', {'count': 20, 'weight': 20000, 'price': 25000});
    final p = {'expected_count': 70, 'weight': 20000, 'price': 25000};
    for (final bad in [
      <String, Object?>{'expected_count': 70},
      <String, Object?>{'expected_count': 70, 'weight': 20000, 'price': 0},
      <String, Object?>{
        'expected_count': 70,
        'weight': double.nan,
        'price': 25000,
      },
    ]) {
      await expectLater(
        run(newMasterId(), 'final', bad),
        throwsA(isA<ValidationFailure>()),
      );
      expect((await condition())['current_count'], 70);
      expect((await condition())['status'], 'active');
    }
    await Future.wait([run('fin', 'final', p), run('fin', 'final', p)]);
    await run('fin', 'final', p);
    expect((await condition())['current_count'], 0);
    expect((await condition())['status'], 'closed');
    final rows = await (await master.database()).query(
      'operations',
      where: "kind='final'",
    );
    expect(rows.length, 1);
    expect(rows.single['quantity'], 70);
    expect(rows.single['value_rp'], 350000);
    expect(
      (await (await master.database()).query('cycle_slots'))
          .every((s) => s['stopped_action_id'] == 'fin'),
      isTrue,
    );
    await expectLater(
      run('fin2', 'final', p),
      throwsA(isA<ValidationFailure>()),
    );
    await expectLater(cancel('cf', 'fin'), throwsA(isA<ValidationFailure>()));
    await expectLater(give('g', 480, 1), throwsA(isA<ValidationFailure>()));
  });
  testWidgets(
    'pratinjau akhir stale ditolak dan pembatalan hari lampau ditolak',
    (tester) async {
      await run('d', 'death', {'count': 10});
      await expectLater(
        run('fin', 'final', {
          'expected_count': 100,
          'weight': 20000,
          'price': 25000,
        }),
        throwsA(isA<ValidationFailure>()),
      );
      expect((await condition())['status'], 'active');
      now = now.add(const Duration(days: 1));
      await expectLater(
        feed.run('cd', 'cancel_operation', {
          'operation': 'd',
          'date': '2026-10-14',
          'reason': 'Uji',
        }),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );
  testWidgets('rollback penutupan dan recovery ID sama setelah restart', (
    tester,
  ) async {
    final db = await master.database();
    await db.execute(
      "CREATE TRIGGER fail_close BEFORE UPDATE OF status ON cycles WHEN NEW.status='closed' BEGIN SELECT RAISE(ABORT,'fault M4'); END",
    );
    final p = {'expected_count': 100, 'weight': 20000, 'price': 25000};
    await expectLater(
      run('fin', 'final', p),
      throwsA(isA<DatabaseException>()),
    );
    expect((await condition())['current_count'], 100);
    expect(await db.query('operations'), isEmpty);
    expect((await feed.journal.inspect('fin'))['state'], 'prepared');
    expect(
      (await db.query('cycle_slots')).every((s) => s['status'] == 'pending'),
      isTrue,
    );
    await db.execute('DROP TRIGGER fail_close');
    await restart();
    await feed.journal.inspect('fin');
    await feed.resume('fin');
    await feed.resume('fin');
    expect((await condition())['status'], 'closed');
    expect((await (await master.database()).query('operations')).length, 1);
  });
  testWidgets('sampling dan pembatalan ID sama tidak menggandakan perubahan', (
    tester,
  ) async {
    await Future.wait([
      run('s', 'sampling', {'count': 10, 'weight': 12000}),
      run('s', 'sampling', {'count': 10, 'weight': 12000}),
    ]);
    await Future.wait([cancel('cs', 's'), cancel('cs', 's')]);
    expect((await condition())['current_weight_cg'], 10000);
    expect((await (await master.database()).query('operations')).length, 1);
  });
  testWidgets(
    'migrasi3 menjaga master snapshot pakan dan urutan lintas kegiatan',
    (tester) async {
      await master.close();
      path = '${await getDatabasesPath()}/m4_migration_${newMasterId()}.db';
      final db = await openDatabase(
        path,
        version: 3,
        singleInstance: false,
        onCreate: SqliteMasterRepository.createSchema,
        onConfigure: (d) => d.execute('PRAGMA foreign_keys=ON'),
      );
      await db.insert('ponds', {
        'id': 'p',
        'name': 'Lama',
        'name_key': 'lama',
        'revision': 1,
        'created_at_ms': 1,
        'updated_at_ms': 1,
      });
      await db.insert('feeds', {
        'id': 'f',
        'name': 'Pakan',
        'name_key': 'pakan',
        'price_rp_kg': 10000,
        'revision': 1,
        'created_at_ms': 1,
        'updated_at_ms': 1,
      });
      await db.insert('business_settings', {'id': 1, 'zone': 'Asia/Jakarta'});
      await db.insert('cycles', {
        'id': 'c',
        'pond_id': 'p',
        'feed_id': 'f',
        'fish': 'Uji',
        'initial_count': 100,
        'weight_cg': 10000,
        'start_date': '2026-10-13',
        'status': 'active',
        'start_payload': 'legacy',
        'created_at_ms': 1,
      });
      await db.insert('cycle_rates', {
        'cycle_id': 'c',
        'rate_bp': 300,
        'operation_id': 'r',
        'changed_at_ms': 1,
      });
      await db.insert('cycle_schedules', {
        'id': 't',
        'cycle_id': 'c',
        'effective_date': '2026-10-13',
      });
      for (final m in [480, 960]) {
        await db.insert('cycle_times', {'schedule_id': 't', 'minute': m});
        await db.insert('cycle_slots', {
          'cycle_id': 'c',
          'business_date': '2026-10-13',
          'minute': m,
          'planned_g': 150,
          'status': m == 480 ? 'given' : 'pending',
        });
      }
      for (final id in ['in', 'g', 'g0', 'cg0', 'corr']) {
        await db.insert('action_intents', {
          'id': id,
          'kind': switch (id) {
            'in' => 'stock_in',
            'corr' => 'stock_correct',
            'cg0' => 'cancel',
            _ => 'feeding',
          },
          'payload': '{}',
          'target_key': id,
          'state': 'committed',
          'created_at_ms': 1,
        });
      }
      await db.insert('feedings', {
        'id': 'g',
        'cycle_id': 'c',
        'business_date': '2026-10-13',
        'minute': 480,
        'feed_id': 'f',
        'actual_g': 150,
        'planned_snapshot_g': 150,
        'price_snapshot': 10000,
        'rate_snapshot': 300,
        'population_snapshot': 100,
        'weight_snapshot_cg': 10000,
        'biomass_snapshot_cg': 1000000,
        'cost_snapshot': 1500,
        'need_snapshot_g': 300,
        'created_at_ms': 1,
      });
      await db.insert('stock_movements', {
        'id': 'in',
        'feed_id': 'f',
        'kind': 'in',
        'delta_g': 500,
        'business_date': '2026-10-13',
        'created_at_ms': 1,
      });
      await db.insert('stock_movements', {
        'id': 'g',
        'feed_id': 'f',
        'kind': 'out',
        'delta_g': -150,
        'feeding_id': 'g',
        'business_date': '2026-10-13',
        'created_at_ms': 1,
      });
      final oldFeeding = Map<String, Object?>.from(
        (await db.query('feedings')).single,
      )..remove('seq');
      await db.insert('feedings', {
        ...oldFeeding,
        'id': 'g0',
        'minute': 960,
        'actual_g': 50,
        'cost_snapshot': 500,
        'cancel_action_id': 'cg0',
        'cancel_reason': 'Koreksi lama',
      });
      for (final move in [
        <String, Object?>{
          'id': 'g0',
          'kind': 'out',
          'delta_g': -50,
          'feeding_id': 'g0',
        },
        <String, Object?>{
          'id': 'cg0',
          'kind': 'reversal',
          'delta_g': 50,
          'feeding_id': 'g0',
        },
        <String, Object?>{
          'id': 'corr',
          'kind': 'correction',
          'delta_g': 100,
          'original_in_id': 'in',
        },
      ]) {
        await db.insert('stock_movements', {
          'feed_id': 'f',
          'business_date': '2026-10-13',
          'created_at_ms': 1,
          ...move,
        });
      }
      await db.insert('stock_corrections', {
        'id': 'corr',
        'source_id': 'in',
        'old_g': 500,
        'new_g': 600,
        'reason': 'Tambah salah catat',
        'business_date': '2026-10-13',
        'created_at_ms': 1,
      });
      await db.close();
      await restart();
      expect((await master.get(MasterKind.pond, 'p')).name, 'Lama');
      expect(await feed.balance('f'), 450);
      expect(await feed.effective('in'), 600);
      expect(
        (await feed.history('c'))
            .firstWhere((r) => r['id'] == 'g')['cost_snapshot'],
        1500,
      );
      final migrated = await (await master.database()).query(
        'operations',
        where: 'id=?',
        whereArgs: ['g0'],
      );
      expect(migrated.single['cancel_action_id'], 'cg0');
      expect(migrated.single['cancel_reason'], 'Koreksi lama');
      expect((await feed.journal.inspect('corr'))['state'], 'committed');
      final legacyReport = await SqliteReportRepository(master)
          .load(ReportFilter('2026-10-13', '2026-10-13', pondId: 'p'));
      expect(legacyReport.totals['feed_g'], 150);
      expect(legacyReport.totals['feed_cost'], 1500);
      expect((await cycles.active('p'))!.portions, [150, 150]);
      await run('s', 'sampling', {'count': 10, 'weight': 12000});
      await expectLater(
        cancel('cg', 'g', feeding: true),
        throwsA(isA<ValidationFailure>()),
      );
      await cancel('cs', 's');
      await cancel('cg2', 'g', feeding: true);
      expect(await feed.balance('f'), 600);
    },
  );
  testWidgets(
    'grading nomor tetap setelah batal, rencana pulih, retry tidak ganda',
    (tester) async {
      await run('s1', 'sampling', {'count': 10, 'weight': 12000});
      final db = await master.database();
      expect((await db.query('grading_records')).single['ordinal'], 1);
      expect(
        (await db.query('grading_plans')).single['next_date'],
        '2026-10-20',
      );
      await cancel('cs1', 's1');
      expect((await db.query('grading_plans')).single['next_date'], isNull);
      await run('s2', 'sampling', {
        'count': 10,
        'weight': 13000,
        'next_date': '2026-10-23',
      });
      await run('s2', 'sampling', {
        'count': 10,
        'weight': 13000,
        'next_date': '2026-10-23',
      });
      expect(
        (await db.query(
          'grading_records',
          orderBy: 'ordinal',
        )).map((r) => r['ordinal']).toList(),
        [1, 2],
      );
      expect((await condition())['current_count'], 100);
      await restart();
      expect(
        (await (await master.database()).query('grading_plans'))
            .single['next_date'],
        '2026-10-23',
      );
    },
  );
  testWidgets(
    'edit rencana dipertahankan saat grading batal; pratinjau lama ditolak',
    (tester) async {
      await run('s1', 'sampling', {'count': 10, 'weight': 12000});
      await run('plan', 'grading_plan', {
        'next_date': '2026-10-24',
        'expected_revision': 1,
      });
      await expectLater(
        run('stale', 'grading_plan', {
          'next_date': '2026-10-25',
          'expected_revision': 1,
        }),
        throwsA(isA<ValidationFailure>()),
      );
      await cancel('cancel', 's1');
      expect(
        (await (await master.database()).query('grading_plans'))
            .single['next_date'],
        '2026-10-24',
      );
      expect((await condition())['current_weight_cg'], 10000);
    },
  );
  testWidgets(
    'tanggal rencana invalid rollback grading; fleksibel tidak menunggu tujuh hari',
    (tester) async {
      await expectLater(
        run('badplan', 'sampling', {
          'count': 10,
          'weight': 12000,
          'next_date': '2026-02-30',
        }),
        throwsA(isA<ValidationFailure>()),
      );
      expect(await (await master.database()).query('grading_records'), isEmpty);
      expect((await condition())['current_weight_cg'], 10000);
      await run('s1', 'sampling', {'count': 10, 'weight': 12000});
      now = now.add(const Duration(days: 1));
      await feed.run('s2', 'sampling', {
        'cycle': 'c',
        'date': '2026-10-14',
        'count': 10,
        'weight': 12500,
      });
      expect(
        (await (await master.database()).query('grading_records')).length,
        2,
      );
      now = now.add(const Duration(days: 10));
      final active = (await cycles.active('p'))!;
      expect(active.population, 100);
      expect(active.weightCg, 12500);
      expect(
        (await feed.contextFor('c', active.date, 480))['state'],
        'pending',
      );
    },
  );
  testWidgets(
    'migrasi skema5 memberi nomor sampling lama tanpa mengarang rencana',
    (tester) async {
      await master.close();
      path = '${await getDatabasesPath()}/grading_legacy_${newMasterId()}.db';
      final legacy = await openDatabase(
        path,
        version: 5,
        singleInstance: false,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
        onCreate: SqliteMasterRepository.createSchema,
      );
      await legacy.insert('ponds', {
        'id': 'p',
        'name': 'Kolam lama',
        'name_key': 'kolam lama',
        'revision': 1,
        'created_at_ms': 1,
        'updated_at_ms': 1,
      });
      await legacy.insert('feeds', {
        'id': 'f',
        'name': 'Pakan lama',
        'name_key': 'pakan lama',
        'revision': 1,
        'price_rp_kg': 10000,
        'created_at_ms': 1,
        'updated_at_ms': 1,
      });
      await legacy.insert('cycles', {
        'id': 'c',
        'pond_id': 'p',
        'feed_id': 'f',
        'fish': 'Lele',
        'initial_count': 100,
        'weight_cg': 10000,
        'current_count': 100,
        'current_weight_cg': 12000,
        'start_date': '2026-10-13',
        'status': 'active',
        'start_payload': 'legacy',
        'created_at_ms': 1,
      });
      for (final id in ['s1', 's2', 'cancel']) {
        await legacy.insert('action_intents', {
          'id': id,
          'kind': 'sampling',
          'payload': '{}',
          'target_key': id,
          'state': 'committed',
          'created_at_ms': 1,
        });
      }
      for (final id in ['s1', 's2']) {
        await legacy.insert('operations', {
          'id': id,
          'cycle_id': 'c',
          'kind': 'sampling',
          'business_date': '2026-10-13',
          'before_count': 100,
          'after_count': 100,
          'before_weight_cg': 10000,
          'after_weight_cg': 12000,
          'quantity': 10,
          'created_at_ms': 1,
          if (id == 's1') 'cancel_action_id': 'cancel',
          if (id == 's1') 'cancel_reason': 'Koreksi lama',
        });
      }
      await legacy.close();
      await restart();
      final db = await master.database();
      expect(await db.getVersion(), SqliteMasterRepository.schemaVersion);
      expect(
        (await db.query(
          'grading_records',
          orderBy: 'ordinal',
        )).map((r) => r['ordinal']).toList(),
        [1, 2],
      );
      expect(await db.query('grading_plans'), isEmpty);
      expect((await db.query('cycles')).single['current_weight_cg'], 12000);
      expect((await feed.journal.inspect('s1'))['payload'], '{}');
    },
  );
  testWidgets(
    'pratinjau setelah grading, kematian dan pembatalan membaca kondisi terbaru tanpa mengubah snapshot',
    (tester) async {
      await give('g', 480, 150);
      final before = (await feed.history('c')).single;
      await run('s', 'sampling', {'count': 10, 'weight': 12000});
      expect(
        (await cycles.previewWeightPlan('c', '2026-10-13')).dailyGrams,
        240,
      );
      await run('d', 'death', {'count': 10});
      expect(
        (await cycles.previewWeightPlan('c', '2026-10-13')).dailyGrams,
        216,
      );
      await cancel('cd', 'd');
      expect(
        (await cycles.previewWeightPlan('c', '2026-10-13')).dailyGrams,
        240,
      );
      await cancel('cs', 's');
      expect(
        (await cycles.previewWeightPlan('c', '2026-10-13')).dailyGrams,
        200,
      );
      expect((await feed.history('c')).single, before);
      expect((await cycles.active('p'))!.need, 300);
    },
  );
  testWidgets(
    'pratinjau harian membaca aktual/batal/Lewati tanpa mengubah ledger atau porsi tersimpan',
    (tester) async {
      await give('g', 480, 150);
      final db = await master.database();
      final savedSlots = await db.query('cycle_slots');
      final savedMovements = await db.query('stock_movements');
      final day = await cycles.previewWeightDay('c', '2026-10-13');
      expect(day.actualGrams, 150);
      expect(day.pendingSlots.single.grams, 100);
      expect(await db.query('cycle_slots'), savedSlots);
      expect(await db.query('stock_movements'), savedMovements);
      await cancel('cg', 'g', feeding: true);
      final cancelled = await cycles.previewWeightDay('c', '2026-10-13');
      expect(cancelled.actualGrams, 0);
      expect(cancelled.records.single.cancelled, isTrue);
      expect(cancelled.pendingSlots.map((s) => s.grams).toList(), [100, 100]);
      await run('skip', 'skip', {'minute': 480});
      final savedAfterSkip = await db.query('cycle_slots');
      final skipped = await cycles.previewWeightDay('c', '2026-10-13');
      expect(skipped.pendingSlots.single.minute, 960);
      expect(skipped.pendingSlots.single.grams, 100);
      expect(await db.query('cycle_slots'), savedAfterSkip);
    },
  );
}
