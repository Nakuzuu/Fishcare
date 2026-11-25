import 'package:fishcare_m0/cycle_repository.dart';
import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/master_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SqliteMasterRepository masters;
  late SqliteCycleRepository cycles;
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
  StartCycle draft({String id = 'cycle', List<int> times = const [480, 960]}) =>
      StartCycle(
        id: id,
        pondId: 'pond',
        feedId: 'feed',
        fish: 'Ikan Uji',
        count: 100,
        weightCg: 10000,
        rateBp: 300,
        times: times,
        zone: 'Asia/Jakarta',
        date: businessDate(now, 'Asia/Jakarta'),
      );
  setUp(() async {
    now = DateTime.utc(2026, 10, 13, 2);
    path = '${await getDatabasesPath()}/m2_isolated_${newMasterId()}.db';
    masters = SqliteMasterRepository(open: open);
    cycles = SqliteCycleRepository(masters, clock: () => now);
    await masters.save(
      const MasterRecord(id: 'pond', kind: MasterKind.pond, name: 'Kolam Uji'),
      create: true,
    );
    await masters.save(
      const MasterRecord(
        id: 'feed',
        kind: MasterKind.feed,
        name: 'Pakan Uji',
        price: 10000,
      ),
      create: true,
    );
  });
  tearDown(() async => masters.close());
  testWidgets(
    'start atomic, retry sama id tidak ganda, siklus aktif kedua ditolak',
    (tester) async {
      await cycles.start(draft());
      await cycles.start(draft());
      expect((await cycles.active('pond'))!.portions, [150, 150]);
      await expectLater(
        cycles.start(draft(id: 'second')),
        throwsA(isA<ValidationFailure>()),
      );
      final db = await masters.database();
      expect(
        Sqflite.firstIntValue(await db.rawQuery('SELECT count(*) FROM cycles')),
        1,
      );
      expect(
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT count(*) FROM cycle_rates'),
        ),
        1,
      );
      expect(
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT count(*) FROM cycle_slots'),
        ),
        2,
      );
      await expectLater(
        masters.archive(await masters.get(MasterKind.pond, 'pond')),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
        masters.archive(await masters.get(MasterKind.feed, 'feed')),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );
  testWidgets('jam duplikat dan kegagalan insert rate rollback seluruh start', (
    tester,
  ) async {
    await expectLater(
      cycles.start(draft(times: [480, 480])),
      throwsA(isA<ValidationFailure>()),
    );
    final db = await masters.database();
    await db.execute(
      "CREATE TRIGGER fail_rate BEFORE INSERT ON cycle_rates BEGIN SELECT RAISE(ABORT,'isolated failure'); END",
    );
    await expectLater(cycles.start(draft()), throwsA(isA<DatabaseException>()));
    expect(await cycles.active('pond'), isNull);
    expect(await db.query('business_settings'), isEmpty);
    expect(await db.query('cycle_schedules'), isEmpty);
  });
  testWidgets(
    'ubah jam sebelum membuka detail: hari ini tetap besok mengganti, rate langsung',
    (tester) async {
      await cycles.start(draft());
      await cycles.changeTimes('cycle', [540, 1020], 'times1', '2026-10-13');
      await cycles.changeTimes('cycle', [600, 1080], 'times2', '2026-10-13');
      var view = (await cycles.active('pond'))!;
      expect(view.times, [480, 960]);
      expect(view.tomorrowTimes, [600, 1080]);
      await cycles.changeRate('cycle', 301, 'rate1', view.date);
      await cycles.changeRate('cycle', 301, 'rate1', view.date);
      view = (await cycles.active('pond'))!;
      expect(view.need, 301);
      expect(view.portions, [151, 150]);
      await cycles.active('pond');
      final db = await masters.database();
      expect(
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT count(*) FROM cycle_slots'),
        ),
        2,
      );
      now = DateTime.utc(2026, 10, 14, 2);
      view = (await cycles.active('pond'))!;
      expect(view.times, [600, 1080]);
      // Hari berikutnya belum dibuka: perubahan jam tetap harus membekukan
      // template hari itu, bukan memakai template baru untuk besok.
      now = DateTime.utc(2026, 10, 15, 2);
      await cycles.changeTimes('cycle', [660], 'unopened-day', '2026-10-15');
      view = (await cycles.active('pond'))!;
      expect(view.times, [600, 1080]);
      expect(view.tomorrowTimes, [660]);
      await expectLater(
        cycles.changeRate('cycle', 300, 'stale', '2026-10-13'),
        throwsA(isA<ValidationFailure>()),
      );
      await masters.close();
      masters = SqliteMasterRepository(open: open);
      cycles = SqliteCycleRepository(masters, clock: () => now);
      expect((await cycles.active('pond'))!.need, 301);
    },
  );
  testWidgets('migrasi v1 mempertahankan master termasuk arsip dan harga', (
    tester,
  ) async {
    await masters.close();
    path = '${await getDatabasesPath()}/m2_migration_${newMasterId()}.db';
    var db = await openDatabase(
      path,
      version: 1,
      singleInstance: false,
      onCreate: SqliteMasterRepository.createM1Schema,
    );
    await db.insert('ponds', {
      'id': 'old',
      'name': 'Kolam lama',
      'name_key': 'kolam lama',
      'notes': 'Catatan lama',
      'size_description': '2×3',
      'is_archived': 1,
      'revision': 2,
      'created_at_ms': 1,
      'updated_at_ms': 2,
    });
    await db.insert('feeds', {
      'id': 'feed',
      'name': 'Pakan lama',
      'name_key': 'pakan lama',
      'price_rp_kg': 12345,
      'is_archived': 0,
      'revision': 1,
      'created_at_ms': 1,
      'updated_at_ms': 1,
    });
    await db.close();
    masters = SqliteMasterRepository(open: open);
    expect((await masters.get(MasterKind.pond, 'old')).notes, 'Catatan lama');
    expect((await masters.get(MasterKind.pond, 'old')).archived, isTrue);
    expect((await masters.get(MasterKind.feed, 'feed')).price, 12345);
    db = await masters.database();
    expect(await db.getVersion(), SqliteMasterRepository.schemaVersion);
    expect(await db.query('cycles'), isEmpty);
  });
  testWidgets(
    'pratinjau rate otomatis tidak mengganti rate manual atau menulis slot',
    (tester) async {
      await cycles.start(draft());
      final db = await masters.database();
      final beforeSlots = await db.query('cycle_slots');
      final beforeRates = await db.query('cycle_rates');
      final preview = await cycles.previewWeightPlan('cycle', '2026-10-13');
      expect(preview.rate.rateBp, 200);
      expect(preview.dailyGrams, 200);
      expect(preview.slots.map((s) => s.grams).toList(), [100, 100]);
      expect(await db.query('cycle_slots'), beforeSlots);
      expect(await db.query('cycle_rates'), beforeRates);
      expect((await cycles.active('pond'))!.need, 300);
      await expectLater(
        cycles.previewWeightPlan('cycle', '2026-10-12'),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );
  testWidgets(
    'pratinjau memakai jam hari ini, besok memakai template efektif tanpa materialisasi',
    (tester) async {
      await cycles.start(draft());
      await cycles.changeTimes(
        'cycle',
        [600, 1200, 1320],
        'hours',
        '2026-10-13',
      );
      expect(
        (await cycles.previewWeightPlan(
          'cycle',
          '2026-10-13',
        )).slots.map((s) => s.minute).toList(),
        [480, 960],
      );
      now = now.add(const Duration(days: 1));
      final p = await cycles.previewWeightPlan('cycle', '2026-10-14');
      expect(p.slots.map((s) => s.minute).toList(), [600, 1200, 1320]);
      expect(p.slots.map((s) => s.grams).toList(), [67, 67, 66]);
      expect(
        await (await masters.database()).query(
          'cycle_slots',
          where: 'business_date=?',
          whereArgs: ['2026-10-14'],
        ),
        isEmpty,
      );
    },
  );
}
