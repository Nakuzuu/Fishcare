import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fishcare_m0/action_payload.dart';
import 'package:fishcare_m0/cycle_repository.dart';
import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/feed_repository.dart';
import 'package:fishcare_m0/feeding_policy.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/master_repository.dart';
import 'package:fishcare_m0/report_repository.dart';
import 'package:fishcare_m0/report_rules.dart';
import 'package:fishcare_m0/report_export.dart';
import 'package:fishcare_m0/water_feeding_ui.dart';
import 'package:fishcare_m0/design_system.dart';

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
    onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
    onCreate: SqliteMasterRepository.createSchema,
    onUpgrade: SqliteMasterRepository.migrateSchema,
  );
  Future<void> restart() async {
    await master.close();
    master = SqliteMasterRepository(open: open);
    cycles = SqliteCycleRepository(master, clock: () => now);
    feed = FeedRepository(master, cycles);
  }

  Future<Map<String, Object?>> payload({
    int minute = 480,
    int grams = 500,
    int temp = 230,
    int ph = 700,
    bool excess = false,
  }) async {
    final date = businessDate(now, 'Asia/Jakarta');
    final ctx = await feed.contextFor('c', date, minute);
    return {
      'cycle': 'c',
      'date': date,
      'minute': minute,
      'grams': grams,
      'price': ctx['price'],
      'rate': ctx['rate'],
      'policy_version': ctx['policy_version'],
      'expected_context': ctx['expected_context'],
      'allow_excess': excess,
      'water_temperature_deci_c': temp,
      'water_ph_hundredths': ph,
      'water_recorded_at_ms': now.millisecondsSinceEpoch,
    };
  }

  setUp(() async {
    now = DateTime.utc(2026, 10, 26, 2);
    path = '${await getDatabasesPath()}/automatic_isolated_${newMasterId()}.db';
    master = SqliteMasterRepository(open: open);
    cycles = SqliteCycleRepository(master, clock: () => now);
    feed = FeedRepository(master, cycles);
    await master.save(
      const MasterRecord(
        id: 'p',
        kind: MasterKind.pond,
        name: 'Kolam lele uji',
      ),
      create: true,
    );
    await master.save(
      const MasterRecord(
        id: 'f',
        kind: MasterKind.feed,
        name: 'Pakan uji',
        price: 15000,
      ),
      create: true,
    );
    await cycles.start(
      const StartCycle(
        id: 'c',
        pondId: 'p',
        feedId: 'f',
        fish: 'Lele',
        count: 1000,
        weightCg: 5000,
        rateBp: 250,
        times: [480, 960],
        zone: 'Asia/Jakarta',
        date: '2026-10-26',
        feedingPolicy: weightFeedingPolicyVersion,
      ),
    );
    await feed.run('stock', 'stock_in', {
      'feed': 'f',
      'grams': 10000,
      'zone': 'Asia/Jakarta',
      'date': '2026-10-26',
    });
  });
  tearDown(() async {
    await master.close();
  });
  testWidgets(
    'form HP menyimpan suhu pH biaya dan kembali dengan database native',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: FishCareDesign.theme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WaterFeedingForm(
                        repo: feed,
                        cycle: 'c',
                        date: '2026-10-26',
                        minute: 480,
                      ),
                    ),
                  ),
                  child: const Text('Buka pemberian uji'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka pemberian uji'));
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 20 &&
            find.byKey(const ValueKey('water-temperature')).evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      for (final entry in [
        ('water-temperature', '23'),
        ('water-ph', '7'),
        ('actual-feed', '450'),
      ]) {
        final field = find.byKey(ValueKey(entry.$1));
        await tester.scrollUntilVisible(
          field.hitTestable(),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(field, entry.$2);
        await tester.pump();
      }
      final review = find.text('Tinjau dan simpan');
      await tester.scrollUntilVisible(
        review.hitTestable(),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Rp6.750'), findsOneWidget);
      await tester.tap(review);
      await tester.pumpAndSettle();
      final confirm = find.byKey(const ValueKey('confirm-action'));
      await tester.scrollUntilVisible(
        confirm.hitTestable(),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 20 && find.text('Buka pemberian uji').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      expect(find.text('Buka pemberian uji'), findsOneWidget);
      final saved = (await feed.history('c')).single;
      expect(saved['water_temperature_deci_c'], 230);
      expect(saved['water_ph_hundredths'], 700);
      expect(saved['actual_g'], 450);
      expect(saved['recommended_g'], 500);
      expect(saved['cost_snapshot'], 6750);
      expect(await feed.balance('f'), 9550);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'alur grading-pakan-laporan-XLSX tetap konsisten setelah reopen',
    (tester) async {
      await feed.run('morning', 'feeding', await payload(grams: 450));
      await feed.run('grade', 'sampling', {
        'cycle': 'c',
        'date': '2026-10-26',
        'count': 10,
        'weight': 6000,
      });
      await feed.run(
        'afternoon',
        'feeding',
        await payload(minute: 960, temp: 270, grams: 660),
      );
      final filter = ReportFilter('2026-10-26', '2026-10-26', pondId: 'p');
      final snapshot = await SqliteReportRepository(master).load(filter);
      expect(snapshot.totals['feed_g'], 1110);
      expect(snapshot.totals['feed_cost'], 16650);
      final morning = snapshot.rows.singleWhere((r) => r['id'] == 'morning');
      expect(morning['rate_snapshot'], 250);
      expect(morning['recommended_g'], 500);
      final afternoon = snapshot.rows.singleWhere(
        (r) => r['id'] == 'afternoon',
      );
      expect(afternoon['rate_snapshot'], 220);
      expect(afternoon['recommended_g'], 660);
      final before = await feed.balance('f');
      final bytes = reportXlsx(snapshot);
      final contents = utf8.decode(bytes, allowMalformed: true);
      expect(contents, contains('<v>1110</v>'));
      expect(contents, contains('<v>16650</v>'));
      expect(contents, contains('Grading'));
      expect(await feed.balance('f'), before);
      await restart();
      final restored = await SqliteReportRepository(master).load(filter);
      expect(restored.totals, snapshot.totals);
      expect(restored.rows, snapshot.rows);
      expect(reportXlsx(restored), bytes);
    },
  );
  testWidgets(
    'XLSX sesudah batal mengecualikan biaya dan tidak menulis ulang pengukuran',
    (tester) async {
      await feed.run('morning', 'feeding', await payload(grams: 450));
      await feed.run('cancel-morning', 'cancel', {
        'cycle': 'c',
        'date': '2026-10-26',
        'feeding': 'morning',
        'reason': 'Uji terisolasi',
      });
      final snapshot = await SqliteReportRepository(master)
          .load(ReportFilter('2026-10-26', '2026-10-26'));
      expect(snapshot.totals['feed_g'], 0);
      expect(snapshot.totals['feed_cost'], 0);
      final old = snapshot.rows.singleWhere((r) => r['id'] == 'morning');
      expect(old['water_temperature_deci_c'], 230);
      expect(old['cost_snapshot'], 6750);
      expect(old['cancel_action_id'], 'cancel-morning');
      final contents = utf8.decode(reportXlsx(snapshot), allowMalformed: true);
      expect(contents, contains('Batal'));
      expect(contents, contains('<v>6750</v>'));
      expect(await feed.balance('f'), 10000);
      expect((await feed.history('c')).single['water_temperature_deci_c'], 230);
    },
  );
  testWidgets(
    'pagi dingin aktual450, sore tetap625; snapshot immutable, retry dan reopen',
    (tester) async {
      final p = await payload(grams: 450);
      await feed.run('g', 'feeding', p);
      await feed.run('g', 'feeding', p);
      expect(await feed.balance('f'), 9550);
      expect((await cycles.active('p'))!.portions, [625, 625]);
      final old = (await feed.history('c')).single;
      expect(old['recommended_g'], 500);
      expect(old['temperature_reduction_g'], 125);
      expect(old['water_temperature_deci_c'], 230);
      expect(old['cost_snapshot'], 6750);
      await feed.run('grade', 'sampling', {
        'cycle': 'c',
        'date': '2026-10-26',
        'count': 10,
        'weight': 6000,
      });
      expect((await cycles.active('p'))!.rateBp, 220);
      expect((await cycles.active('p'))!.portions.last, 660);
      await restart();
      expect(
        {...((await feed.history('c')).single)}..remove('is_last_operation'),
        {...old}..remove('is_last_operation'),
      );
      expect(await feed.balance('f'), 9550);
    },
  );
  testWidgets(
    '32C atau pH di luar rentang menyimpan aktual tanpa rekomendasi numerik',
    (tester) async {
      await feed.run('hot', 'feeding', await payload(temp: 320, grams: 200));
      await feed.run(
        'ph',
        'feeding',
        await payload(minute: 960, temp: 270, ph: 850, grams: 200),
      );
      for (final row in await feed.history('c')) {
        expect(row['recommended_g'], isNull);
        expect(row['recommendation_status'], 'waterWarning');
      }
      expect(await feed.balance('f'), 9600);
    },
  );
  testWidgets(
    'pengukuran kosong, stok kurang dan konfirmasi kelebihan ditolak utuh',
    (tester) async {
      final missing = await payload();
      missing.remove('water_ph_hundredths');
      await expectLater(
        feed.run('missing', 'feeding', missing),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        feed.run('short', 'feeding', await payload(grams: 10001, excess: true)),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        feed.run('over', 'feeding', await payload(grams: 600)),
        throwsA(isA<ValidationFailure>()),
      );
      expect(await feed.balance('f'), 10000);
      expect(await feed.history('c'), isEmpty);
      await feed.run(
        'confirmed',
        'feeding',
        await payload(grams: 600, excess: true),
      );
      expect(await feed.balance('f'), 9400);
    },
  );
  testWidgets('harga/grading setelah pratinjau menolak snapshot stale', (
    tester,
  ) async {
    final old = await payload();
    final f = await master.get(MasterKind.feed, 'f');
    await master.save(
      MasterRecord(
        id: f.id,
        kind: f.kind,
        name: f.name,
        price: 20000,
        revision: f.revision,
      ),
      create: false,
    );
    await expectLater(
      feed.run('price', 'feeding', old),
      throwsA(isA<ValidationFailure>()),
    );
    final next = await payload();
    await feed.run('grade', 'sampling', {
      'cycle': 'c',
      'date': '2026-10-26',
      'count': 10,
      'weight': 6000,
    });
    await expectLater(
      feed.run('weight', 'feeding', next),
      throwsA(isA<ValidationFailure>()),
    );
    expect(await feed.history('c'), isEmpty);
    expect(await feed.balance('f'), 10000);
  });
  testWidgets(
    'gagal teknis rollback lalu retry ID sama setelah reopen memotong stok sekali',
    (tester) async {
      final db = await master.database();
      final p = await payload();
      await db.execute(
        "CREATE TRIGGER test_fail BEFORE INSERT ON feedings BEGIN SELECT RAISE(ABORT,'isolated failure'); END",
      );
      await expectLater(
        feed.run('retry', 'feeding', p),
        throwsA(isA<DatabaseException>()),
      );
      expect(await feed.balance('f'), 10000);
      expect((await feed.journal.inspect('retry'))['state'], 'prepared');
      await db.execute('DROP TRIGGER test_fail');
      await restart();
      await feed.resume('retry');
      await feed.resume('retry');
      expect(await feed.balance('f'), 9500);
      expect((await feed.history('c')).length, 1);
    },
  );
  testWidgets(
    'Lewati tidak redistribusi, pembatalan pulihkan stok dan minta pengukuran baru',
    (tester) async {
      await feed.run('skip', 'skip', {
        'cycle': 'c',
        'date': '2026-10-26',
        'minute': 480,
      });
      expect((await cycles.active('p'))!.portions.last, 625);
      await feed.run('g', 'feeding', await payload(minute: 960, grams: 500));
      await feed.run('cancel', 'cancel', {
        'feeding': 'g',
        'date': '2026-10-26',
        'reason': 'Uji koreksi',
      });
      final view = (await cycles.active('p'))!;
      expect(view.statuses, ['skipped', 'pending']);
      expect(view.portions.last, 625);
      expect(await feed.balance('f'), 10000);
      final replacement = await payload(minute: 960);
      replacement.remove('water_recorded_at_ms');
      await expectLater(
        feed.run('replacement', 'feeding', replacement),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );
  testWidgets(
    'pergantian hari menolak tanggal/pengukuran lama tanpa menulis pemberian',
    (tester) async {
      final p = await payload();
      now = now.add(const Duration(days: 1));
      await expectLater(
        feed.run('old', 'feeding', p),
        throwsA(isA<ValidationFailure>()),
      );
      final newDay = await payload();
      newDay['water_recorded_at_ms'] = now
          .subtract(const Duration(days: 1))
          .millisecondsSinceEpoch;
      await expectLater(
        feed.run('oldwater', 'feeding', newDay),
        throwsA(isA<ValidationFailure>()),
      );
      expect(await feed.history('c'), isEmpty);
      expect(await feed.balance('f'), 10000);
    },
  );
  testWidgets(
    'migrasi6 ke7 aktivasi langsung menjaga riwayat dan niat prepared lama',
    (tester) async {
      await master.close();
      path = '${await getDatabasesPath()}/automatic_legacy_${newMasterId()}.db';
      final db = await openDatabase(
        path,
        version: 6,
        singleInstance: false,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
        onCreate: SqliteMasterRepository.createSchema,
      );
      await db.insert('ponds', {
        'id': 'p',
        'name': 'Kolam lama',
        'name_key': 'kolam lama',
        'revision': 1,
        'created_at_ms': 1,
        'updated_at_ms': 1,
      });
      await db.insert('feeds', {
        'id': 'f',
        'name': 'Pakan lama',
        'name_key': 'pakan lama',
        'revision': 1,
        'price_rp_kg': 15000,
        'created_at_ms': 1,
        'updated_at_ms': 1,
      });
      await db.insert('business_settings', {'id': 1, 'zone': 'Asia/Jakarta'});
      await db.insert('cycles', {
        'id': 'c',
        'pond_id': 'p',
        'feed_id': 'f',
        'fish': 'Lele',
        'initial_count': 1000,
        'weight_cg': 5000,
        'current_count': 1000,
        'current_weight_cg': 5000,
        'start_date': '2026-10-26',
        'status': 'active',
        'start_payload': 'old',
        'created_at_ms': 1,
      });
      await db.insert('cycle_rates', {
        'cycle_id': 'c',
        'rate_bp': 250,
        'operation_id': 'start',
        'changed_at_ms': 1,
      });
      await db.insert('cycle_schedules', {
        'id': 'schedule',
        'cycle_id': 'c',
        'effective_date': '2026-10-26',
      });
      for (final minute in [480, 960]) {
        await db.insert('cycle_times', {
          'schedule_id': 'schedule',
          'minute': minute,
        });
        await db.insert('cycle_slots', {
          'cycle_id': 'c',
          'business_date': '2026-10-26',
          'minute': minute,
          'planned_g': minute == 480 ? 625 : 750,
          'status': minute == 480 ? 'given' : 'pending',
        });
      }
      final original = <String, Object?>{
        'cycle': 'c',
        'date': '2026-10-26',
        'minute': 960,
        'grams': 750,
        'price': 15000,
        'rate': 250,
        'allow_excess': false,
      };
      for (final id in ['in', 'old', 'pending']) {
        await db.insert('action_intents', {
          'id': id,
          'kind': id == 'in' ? 'stock_in' : 'feeding',
          'payload': id == 'pending' ? canonicalPayload(original) : '{}',
          'target_key': id == 'pending' ? 'slot:c:2026-10-26:960' : id,
          'state': id == 'pending' ? 'prepared' : 'committed',
          'created_at_ms': 1,
        });
      }
      await db.insert('feedings', {
        'id': 'old',
        'cycle_id': 'c',
        'business_date': '2026-10-26',
        'minute': 480,
        'feed_id': 'f',
        'actual_g': 500,
        'planned_snapshot_g': 625,
        'price_snapshot': 15000,
        'rate_snapshot': 250,
        'population_snapshot': 1000,
        'weight_snapshot_cg': 5000,
        'biomass_snapshot_cg': 5000000,
        'cost_snapshot': 7500,
        'need_snapshot_g': 1250,
        'created_at_ms': 1,
      });
      await db.insert('operations', {
        'id': 'old',
        'cycle_id': 'c',
        'business_date': '2026-10-26',
        'kind': 'feeding',
        'before_count': 1000,
        'after_count': 1000,
        'before_weight_cg': 5000,
        'after_weight_cg': 5000,
        'quantity': 500,
        'created_at_ms': 1,
      });
      await db.insert('stock_movements', {
        'id': 'in',
        'feed_id': 'f',
        'kind': 'in',
        'delta_g': 10000,
        'business_date': '2026-10-26',
        'created_at_ms': 1,
      });
      await db.insert('stock_movements', {
        'id': 'old',
        'feed_id': 'f',
        'kind': 'out',
        'delta_g': -500,
        'feeding_id': 'old',
        'business_date': '2026-10-26',
        'created_at_ms': 1,
      });
      await db.close();
      await restart();
      expect((await cycles.active('p'))!.automatic, isTrue);
      expect((await cycles.active('p'))!.portions.last, 625);
      final old = (await feed.history('c')).single;
      expect(old['water_temperature_deci_c'], isNull);
      expect(old['cost_snapshot'], 7500);
      expect(
        (await feed.journal.inspect('pending'))['payload'],
        canonicalPayload(original),
      );
      await feed.resume('pending');
      await feed.resume('pending');
      expect(await feed.balance('f'), 8750);
      expect((await feed.history('c')).length, 2);
      expect(
        {...((await feed.history('c')).where((r) => r['id'] == 'old').single)}
          ..remove('is_last_operation'),
        {...old}..remove('is_last_operation'),
      );
    },
  );
}
