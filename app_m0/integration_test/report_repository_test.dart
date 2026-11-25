import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fishcare_m0/master_repository.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/cycle_repository.dart';
import 'package:fishcare_m0/feed_repository.dart';
import 'package:fishcare_m0/report_rules.dart';
import 'package:fishcare_m0/report_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SqliteMasterRepository master;
  late SqliteCycleRepository cycles;
  late FeedRepository feed;
  late SqliteReportRepository report;
  late DateTime now;
  late String path;
  Future<Database> open() => openDatabase(
    path,
    version: SqliteMasterRepository.schemaVersion,
    singleInstance: false,
    onCreate: SqliteMasterRepository.createSchema,
    onUpgrade: SqliteMasterRepository.migrateSchema,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
  );
  Future<void> action(
    String id,
    String kind,
    String cycle,
    Map<String, Object?> p,
  ) => feed.run(id, kind, {
    'cycle': cycle,
    'date': businessDate(now, 'Asia/Jakarta'),
    ...p,
  });
  setUp(() async {
    now = DateTime.utc(2026, 10, 12, 2);
    path = '${await getDatabasesPath()}/m5_isolated_${newMasterId()}.db';
    master = SqliteMasterRepository(open: open);
    cycles = SqliteCycleRepository(master, clock: () => now);
    feed = FeedRepository(master, cycles);
    report = SqliteReportRepository(master, clock: () => now);
    await master.save(
      const MasterRecord(
        id: 'f',
        kind: MasterKind.feed,
        name: 'Uji M5',
        price: 10000,
      ),
      create: true,
    );
    for (final pond in ['a', 'b']) {
      await master.save(
        MasterRecord(id: pond, kind: MasterKind.pond, name: 'Kolam $pond'),
        create: true,
      );
      await cycles.start(
        StartCycle(
          id: pond,
          pondId: pond,
          feedId: 'f',
          fish: 'Uji',
          count: 100,
          weightCg: 10000,
          rateBp: 300,
          times: [480, 960],
          zone: 'Asia/Jakarta',
          date: '2026-10-12',
        ),
      );
    }
    await feed.run('in', 'stock_in', {
      'feed': 'f',
      'date': '2026-10-12',
      'zone': 'Asia/Jakarta',
      'grams': 2000,
    });
    await action('g', 'feeding', 'a', {
      'minute': 480,
      'grams': 150,
      'price': 10000,
      'rate': 300,
      'allow_excess': false,
    });
    now = now.add(const Duration(days: 1));
    await action('h', 'partial', 'a', {
      'count': 20,
      'weight': 20000,
      'price': 25000,
    });
    await action('dc', 'death', 'a', {'count': 10});
    await action('cdc', 'cancel_operation', 'a', {
      'operation': 'dc',
      'reason': 'Uji batal',
    });
    await action('d', 'death', 'b', {'count': 5});
    await action('hb', 'partial', 'b', {
      'count': 10,
      'weight': 10000,
      'price': 1000,
    });
    await action('fb', 'final', 'b', {
      'expected_count': 85,
      'weight': 10000,
      'price': 1000,
    });
    await master.archive(await master.get(MasterKind.pond, 'b'));
  });
  tearDown(() async => master.close());
  testWidgets(
    'panen akhir merangkum seluruh siklus dan biaya historis setelah reopen',
    (tester) async {
      await action('finish-a', 'final', 'a', {
        'expected_count': 80,
        'weight': 20000,
        'price': 25000,
      });
      final filter = ReportFilter('2026-10-13', '2026-10-13', pondId: 'a');
      final snapshot = await report.load(filter);
      final result = HarvestFeedResult.fromTotals(snapshot.cycleTotals('a'));
      expect(snapshot.totals['feed_cost'], 0);
      expect(result.revenue, 500000);
      expect(result.feedGrams, 150);
      expect(result.feedCost, 1500);
      expect(result.afterFeed, 498500);
      final f = await master.get(MasterKind.feed, 'f');
      await master.save(
        MasterRecord(
          id: f.id,
          kind: f.kind,
          name: f.name,
          price: 99999,
          revision: f.revision,
        ),
        create: false,
      );
      await master.close();
      master = SqliteMasterRepository(open: open);
      report = SqliteReportRepository(master, clock: () => now);
      final reopened = HarvestFeedResult.fromTotals(
        (await report.load(filter)).cycleTotals('a'),
      );
      expect(reopened.afterFeed, 498500);
      expect(reopened.feedCost, 1500);
    },
  );
  testWidgets(
    'batas tanggal inklusif satu/semua termasuk arsip partial final dan batal',
    (tester) async {
      final s = await report.load(ReportFilter('2026-10-13', '2026-10-13'));
      expect(s.totals, {
        'feed_g': 0,
        'feed_cost': 0,
        'dead': 5,
        'harvest_count': 115,
        'harvest_value': 109500,
      });
      expect(
        s.rows.any((r) => r['id'] == 'dc' && r['cancel_action_id'] == 'cdc'),
        isTrue,
      );
      final b = await report.load(
        ReportFilter('2026-10-13', '2026-10-13', pondId: 'b'),
      );
      expect(b.totals['harvest_count'], 95);
      expect(b.totals['harvest_value'], 9500);
      expect(b.ponds.singleWhere((p) => p['id'] == 'b')['is_archived'], 1);
      final a = await report.load(
        ReportFilter('2026-10-12', '2026-10-13', pondId: 'a'),
      );
      expect(a.totals['feed_g'], 150);
      expect(a.totals['feed_cost'], 1500);
      expect(a.totals['dead'], 0);
      expect(a.totals['harvest_value'], 100000);
      expect(
        (await report.load(ReportFilter('2026-10-11', '2026-10-11')))
            .totals
            .values
            .every((v) => v == 0),
        isTrue,
      );
      expect(s.cycleTotals('a')['feed_cost'], 1500);
      expect(
        s.conditions.singleWhere((c) => c['id'] == 'a')['current_count'],
        80,
      );
    },
  );
  testWidgets(
    'snapshot tetap setelah harga rate sampling dan reopen schema4 tanpa migrasi baru',
    (tester) async {
      now = now.add(const Duration(days: 1));
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
      await cycles.changeRate('a', 500, 'rate', '2026-10-14');
      await action('s', 'sampling', 'a', {'count': 10, 'weight': 12000});
      await action('g2', 'feeding', 'a', {
        'minute': 480,
        'grams': 200,
        'price': 20000,
        'rate': 500,
        'allow_excess': false,
      });
      final old = await report.load(
        ReportFilter('2026-10-12', '2026-10-13', pondId: 'a'),
      );
      expect(old.totals['feed_cost'], 1500);
      expect(old.totals['harvest_value'], 100000);
      final all = await report.load(ReportFilter('2026-10-12', '2026-10-14'));
      expect(all.totals['feed_cost'], 5500);
      expect(all.totals['feed_g'], 350);
      await master.close();
      master = SqliteMasterRepository(open: open);
      report = SqliteReportRepository(master, clock: () => now);
      final restored = await report.load(
        ReportFilter('2026-10-12', '2026-10-14'),
      );
      expect(restored.totals, all.totals);
      expect(
        await (await master.database()).getVersion(),
        SqliteMasterRepository.schemaVersion,
      );
      expect(
        await FeedRepository(
          master,
          SqliteCycleRepository(master, clock: () => now),
        ).balance('f'),
        1650,
      );
    },
  );
  testWidgets(
    'nilai per transaksi half-up dan laporan sesudah pemberian dibatalkan',
    (tester) async {
      final f = await master.get(MasterKind.feed, 'f');
      await master.save(
        MasterRecord(
          id: f.id,
          kind: f.kind,
          name: f.name,
          price: 500,
          revision: f.revision,
        ),
        create: false,
      );
      await action('ph1', 'partial', 'a', {
        'count': 1,
        'weight': 50,
        'price': 1000,
      });
      await action('ph2', 'partial', 'a', {
        'count': 1,
        'weight': 50,
        'price': 1000,
      });
      await action('tiny1', 'feeding', 'a', {
        'minute': 480,
        'grams': 1,
        'price': 500,
        'rate': 300,
        'allow_excess': false,
      });
      await action('tiny2', 'feeding', 'a', {
        'minute': 960,
        'grams': 1,
        'price': 500,
        'rate': 300,
        'allow_excess': false,
      });
      final filter = ReportFilter('2026-10-13', '2026-10-13', pondId: 'a');
      expect((await report.load(filter)).totals['feed_cost'], 2);
      expect((await report.load(filter)).totals['harvest_value'], 100002);
      await action('cancel', 'cancel', 'a', {
        'feeding': 'tiny2',
        'reason': 'Uji',
      });
      final after = await report.load(filter);
      expect(after.totals['feed_cost'], 1);
      expect(after.totals['feed_g'], 1);
      expect(
        after.rows.singleWhere((r) => r['id'] == 'tiny2')['cancel_action_id'],
        'cancel',
      );
    },
  );
}
