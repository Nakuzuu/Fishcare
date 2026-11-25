import 'package:fishcare_m0/cycle_repository.dart';
import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/feed_repository.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/master_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:fishcare_m0/feed_ui.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SqliteMasterRepository masters;
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
    await masters.close();
    masters = SqliteMasterRepository(open: open);
    cycles = SqliteCycleRepository(masters, clock: () => now);
    feed = FeedRepository(masters, cycles);
  }

  Map<String, Object?> giving(String cycle, int minute, int amount) => {
    'cycle': cycle,
    'date': '2026-10-13',
    'minute': minute,
    'grams': amount,
    'price': 10000,
    'rate': 300,
    'allow_excess': false,
  };
  Future<void> put(String id, int amount) => feed.run(id, 'stock_in', {
    'feed': 'feed',
    'grams': amount,
    'zone': 'Asia/Jakarta',
    'date': '2026-10-13',
  });
  setUp(() async {
    path = '${await getDatabasesPath()}/m3_isolated_${newMasterId()}.db';
    now = DateTime.utc(2026, 10, 13, 2);
    masters = SqliteMasterRepository(open: open);
    cycles = SqliteCycleRepository(masters, clock: () => now);
    feed = FeedRepository(masters, cycles);
    await masters.save(
      const MasterRecord(
        id: 'feed',
        kind: MasterKind.feed,
        name: 'Pakan uji',
        price: 10000,
      ),
      create: true,
    );
    for (final pond in ['pond1', 'pond2']) {
      await masters.save(
        MasterRecord(id: pond, kind: MasterKind.pond, name: 'Kolam uji $pond'),
        create: true,
      );
      await cycles.start(
        StartCycle(
          id: pond,
          pondId: pond,
          feedId: 'feed',
          fish: 'Ikan uji',
          count: 100,
          weightCg: 10000,
          rateBp: 300,
          times: [480, 960],
          zone: 'Asia/Jakarta',
          date: '2026-10-13',
        ),
      );
    }
  });
  tearDown(() async => masters.close());
  testWidgets('dua kolam berbagi stok: kurang ditolak utuh', (tester) async {
    await put('in', 200);
    await feed.run('give1', 'feeding', giving('pond1', 480, 150));
    await expectLater(
      feed.run('give2', 'feeding', giving('pond2', 480, 100)),
      throwsA(isA<ValidationFailure>()),
    );
    expect(await feed.balance('feed'), 50);
    expect(await feed.history('pond2'), isEmpty);
    expect((await cycles.active('pond2'))!.statuses, ['pending', 'pending']);
    final first = (await feed.history('pond1')).single;
    expect(first['cost_snapshot'], 1500);
    expect(first['actual_g'], 150);
  });
  testWidgets('permintaan bersamaan stok sama tidak membuat saldo negatif', (
    tester,
  ) async {
    await put('in', 200);
    final outcomes = await Future.wait([
      for (final pond in ['pond1', 'pond2'])
        feed
            .run('give-$pond', 'feeding', giving(pond, 480, 150))
            .then((_) => true)
            .onError((error, stack) => false),
    ]);
    expect(outcomes.where((ok) => ok).length, 1);
    expect(await feed.balance('feed'), 50);
  });
  testWidgets(
    'koreksi efektif berulang, asal dan alasan utuh; saldo/jumlah negatif ditolak',
    (tester) async {
      await put('in', 500);
      await feed.run('correct1', 'stock_correct', {
        'source': 'in',
        'old': 500,
        'new': 0,
        'reason': 'Salah jumlah',
        'date': '2026-10-13',
      });
      expect(await feed.balance('feed'), 0);
      expect(await feed.effective('in'), 0);
      await feed.run('correct2', 'stock_correct', {
        'source': 'in',
        'old': 0,
        'new': 200,
        'reason': 'Jumlah terkonfirmasi',
        'date': '2026-10-13',
      });
      await feed.run('give', 'feeding', giving('pond1', 480, 150));
      await expectLater(
        feed.run('bad', 'stock_correct', {
          'source': 'in',
          'old': 200,
          'new': 100,
          'reason': 'Terlalu kecil',
          'date': '2026-10-13',
        }),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        feed.run('negative', 'stock_correct', {
          'source': 'in',
          'old': 200,
          'new': -1,
          'reason': 'Invalid',
          'date': '2026-10-13',
        }),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        feed.run('stale', 'stock_correct', {
          'source': 'in',
          'old': 500,
          'new': 700,
          'reason': 'Pratinjau lama',
          'date': '2026-10-13',
        }),
        throwsA(isA<ValidationFailure>()),
      );
      expect(await feed.balance('feed'), 50);
      expect(await feed.effective('in'), 200);
      final db = await masters.database();
      expect(
        (await db.query(
          'stock_movements',
          where: 'id=?',
          whereArgs: ['in'],
        )).single['delta_g'],
        500,
      );
      final corrections = await db.query(
        'stock_corrections',
        orderBy: 'created_at_ms,id',
      );
      expect(corrections.length, 2);
      expect(
        corrections.any(
          (row) =>
              row['old_g'] == 500 &&
              row['new_g'] == 0 &&
              row['reason'] == 'Salah jumlah',
        ),
        isTrue,
      );
    },
  );
  testWidgets(
    'snapshot tetap sesudah harga/rate; actual lebih besar tidak mengembalikan stok',
    (tester) async {
      await put('in', 500);
      await feed.run('give', 'feeding', giving('pond1', 480, 150));
      final before = (await feed.history('pond1')).single;
      await masters.save(
        const MasterRecord(
          id: 'feed',
          kind: MasterKind.feed,
          name: 'Harga baru',
          price: 20000,
        ),
        create: false,
      );
      await cycles.changeRate('pond1', 100, 'rate-low', '2026-10-13');
      final after = (await feed.history('pond1')).single;
      for (final key in [
        'price_snapshot',
        'rate_snapshot',
        'cost_snapshot',
        'biomass_snapshot_cg',
        'planned_snapshot_g',
      ])
        expect(after[key], before[key]);
      final view = (await cycles.active('pond1'))!;
      expect(view.actualToday, 150);
      expect(view.need, 100);
      expect(view.remaining, 0);
      expect(view.excess, 50);
      expect(view.portions, [150, 0]);
      expect(await feed.balance('feed'), 350);
    },
  );
  testWidgets(
    'double tap dan retry memakai satu ID hanya satu feeding dan satu out',
    (tester) async {
      await put('in', 500);
      final p = giving('pond1', 480, 150);
      await Future.wait([
        feed.run('same', 'feeding', p),
        feed.run('same', 'feeding', p),
      ]);
      await feed.run('same', 'feeding', p);
      expect((await feed.history('pond1')).length, 1);
      expect(await feed.balance('feed'), 350);
      final db = await masters.database();
      expect(
        (await db.query(
          'stock_movements',
          where: 'kind=?',
          whereArgs: ['out'],
        )).length,
        1,
      );
      await expectLater(
        feed.run('same', 'feeding', giving('pond1', 480, 100)),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );
  testWidgets(
    'batal setelah rate/jam/Lewati pulih tepat, skipped tidak dibagi ulang',
    (tester) async {
      await put('in', 500);
      await feed.run('give', 'feeding', giving('pond1', 480, 150));
      await cycles.changeRate('pond1', 301, 'rate-new', '2026-10-13');
      await cycles.changeTimes('pond1', [540, 1020], 'hours-new', '2026-10-13');
      await feed.run('skip', 'skip', {
        'cycle': 'pond1',
        'minute': 960,
        'date': '2026-10-13',
      });
      await feed.run('cancel', 'cancel', {
        'feeding': 'give',
        'reason': 'Salah catat',
        'date': '2026-10-13',
      });
      await feed.run('cancel', 'cancel', {
        'feeding': 'give',
        'reason': 'Salah catat',
        'date': '2026-10-13',
      });
      expect(await feed.balance('feed'), 500);
      final view = (await cycles.active('pond1'))!;
      expect(view.statuses, ['pending', 'skipped']);
      expect(view.portions, [301, 151]);
      expect(view.actualToday, 0);
      final original = (await feed.history('pond1')).single;
      expect(original['cancel_reason'], 'Salah catat');
      expect(original['cost_snapshot'], 1500);
      final movements = await feed.movements('feed');
      expect(movements.where((m) => m['kind'] == 'reversal').length, 1);
      expect(
        movements.where((m) => m['kind'] == 'out').single['delta_g'],
        -150,
      );
    },
  );
  testWidgets('pemberian lama atau hari lampau tidak dapat batal', (
    tester,
  ) async {
    await put('in', 500);
    await feed.run('first', 'feeding', giving('pond1', 480, 150));
    await feed.run('last', 'feeding', giving('pond1', 960, 100));
    await expectLater(
      feed.run('old-cancel', 'cancel', {
        'feeding': 'first',
        'reason': 'Lama',
        'date': '2026-10-13',
      }),
      throwsA(isA<ValidationFailure>()),
    );
    now = DateTime.utc(2026, 10, 14, 2);
    await expectLater(
      feed.run('yesterday', 'cancel', {
        'feeding': 'last',
        'reason': 'Hari lalu',
        'date': '2026-10-14',
      }),
      throwsA(isA<ValidationFailure>()),
    );
    expect(await feed.balance('feed'), 250);
    expect(
      (await feed.history('pond1')).every((r) => r['cancel_action_id'] == null),
      isTrue,
    );
  });
  testWidgets(
    'rollback seluruh bisnis, niat tetap prepared; reopen dan retry sama ID',
    (tester) async {
      await put('in', 500);
      var db = await masters.database();
      await db.execute(
        "CREATE TRIGGER fail_out BEFORE INSERT ON stock_movements WHEN NEW.kind='out' BEGIN SELECT RAISE(ABORT,'isolated fail'); END",
      );
      await expectLater(
        feed.run('uncertain', 'feeding', giving('pond1', 480, 150)),
        throwsA(isA<DatabaseException>()),
      );
      expect(await feed.balance('feed'), 500);
      expect(await feed.history('pond1'), isEmpty);
      expect((await feed.journal.inspect('uncertain'))['state'], 'prepared');
      expect((await cycles.active('pond1'))!.statuses, ['pending', 'pending']);
      // Memulihkan fault injector hanya pada file uji terisolasi.
      await db.execute('DROP TRIGGER fail_out');
      await restart();
      expect((await feed.journal.inspect('uncertain'))['state'], 'prepared');
      expect(await feed.history('pond1'), isEmpty);
      await feed.resume('uncertain');
      expect(await feed.balance('feed'), 350);
      await restart();
      expect((await feed.journal.inspect('uncertain'))['state'], 'committed');
      await feed.resume('uncertain');
      expect(await feed.balance('feed'), 350);
      expect((await feed.history('pond1')).length, 1);
    },
  );
  testWidgets(
    'restart setelah niat sebelum bisnis tidak melakukan retry otomatis',
    (tester) async {
      await put('in', 500);
      final p = giving('pond1', 480, 150);
      await feed.journal.prepare(
        'prepared-only',
        'feeding',
        p,
        feed.target('feeding', p),
      );
      await restart();
      expect(await feed.history('pond1'), isEmpty);
      expect(await feed.balance('feed'), 500);
      expect(
        (await feed.journal.outstanding()).any(
          (r) => r['id'] == 'prepared-only' && r['state'] == 'prepared',
        ),
        isTrue,
      );
      await feed.resume('prepared-only');
      expect(await feed.balance('feed'), 350);
      await feed.journal.acknowledge('prepared-only');
      expect(
        (await feed.journal.outstanding()).any(
          (r) => r['id'] == 'prepared-only',
        ),
        isFalse,
      );
    },
  );
  testWidgets('migrasi v2 menjaga cycle/rate/jam/slot dan master', (
    tester,
  ) async {
    await masters.close();
    path = '${await getDatabasesPath()}/m3_migrate_${newMasterId()}.db';
    var db = await openDatabase(
      path,
      version: 2,
      singleInstance: false,
      onCreate: SqliteMasterRepository.createSchema,
    );
    await db.insert('ponds', {
      'id': 'p',
      'name': 'Kolam lama',
      'name_key': 'kolam lama',
      'notes': 'Tetap',
      'size_description': '2x3',
      'revision': 1,
      'created_at_ms': 1,
      'updated_at_ms': 1,
    });
    await db.insert('feeds', {
      'id': 'f',
      'name': 'Pakan lama',
      'name_key': 'pakan lama',
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
      'fish': 'Ikan',
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
      'operation_id': 'legacy',
      'changed_at_ms': 1,
    });
    await db.insert('cycle_schedules', {
      'id': 's',
      'cycle_id': 'c',
      'effective_date': '2026-10-13',
    });
    for (final minute in [480, 960]) {
      await db.insert('cycle_times', {'schedule_id': 's', 'minute': minute});
      await db.insert('cycle_slots', {
        'cycle_id': 'c',
        'business_date': '2026-10-13',
        'minute': minute,
        'planned_g': 150,
      });
    }
    await db.close();
    masters = SqliteMasterRepository(open: open);
    cycles = SqliteCycleRepository(masters, clock: () => now);
    feed = FeedRepository(masters, cycles);
    db = await masters.database();
    expect(await db.getVersion(), SqliteMasterRepository.schemaVersion);
    expect((await masters.get(MasterKind.pond, 'p')).notes, 'Tetap');
    final view = (await cycles.active('p'))!;
    expect(view.times, [480, 960]);
    expect(view.portions, [150, 150]);
    expect(view.rateBp, 300);
    expect(await feed.balance('f'), 0);
    expect(await feed.history('c'), isEmpty);
  });
  testWidgets(
    'UI recovery memeriksa ID dahulu dan tidak retry saat baru dibuka',
    (tester) async {
      await put('in', 500);
      for (final id in ['pond1', 'pond2', 'in'])
        await feed.journal.acknowledge(id);
      final p = giving('pond1', 480, 150);
      await feed.journal.prepare(
        'ui-pending',
        'feeding',
        p,
        feed.target('feeding', p),
      );
      await tester.pumpWidget(MaterialApp(home: RecoveryPage(repo: feed)));
      await tester.pumpAndSettle();
      final retry = find.widgetWithText(FilledButton, 'Retry ID yang sama');
      expect(tester.widget<FilledButton>(retry).onPressed, isNull);
      expect(await feed.history('pond1'), isEmpty);
      await tester.tap(find.text('Periksa hasil'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(retry).onPressed, isNotNull);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(await feed.balance('feed'), 350);
      expect((await feed.journal.inspect('ui-pending'))['state'], 'committed');
      expect(find.text('Sudah tersimpan — tutup hasil'), findsOneWidget);
      await tester.tap(find.text('Sudah tersimpan — tutup hasil'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tidak ada tindakan yang perlu ditinjau.'),
        findsOneWidget,
      );
      expect((await feed.journal.inspect('ui-pending'))['acknowledged'], 1);
      expect(await feed.balance('feed'), 350);
      expect((await feed.history('pond1')).length, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
