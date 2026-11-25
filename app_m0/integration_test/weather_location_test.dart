import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fishcare_m0/master_repository.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/business_location.dart';
import 'package:fishcare_m0/weather_store.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'migrasi4 menjaga master dan lokasi terkonfirmasi bertahan setelah reopen',
    (tester) async {
      final path =
          '${await getDatabasesPath()}/weather_upgrade_${newMasterId()}.db';
      final old = await openDatabase(
        path,
        version: 4,
        singleInstance: false,
        onCreate: SqliteMasterRepository.createSchema,
      );
      await old.insert('ponds', {
        'id': 'p',
        'name': 'Kolam lama',
        'name_key': 'kolam lama',
        'revision': 1,
        'created_at_ms': 1,
        'updated_at_ms': 1,
      });
      await old.close();
      Future<Database> open() => openDatabase(
        path,
        version: SqliteMasterRepository.schemaVersion,
        singleInstance: false,
        onCreate: SqliteMasterRepository.createSchema,
        onUpgrade: SqliteMasterRepository.migrateSchema,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
      );
      var master = SqliteMasterRepository(open: open);
      var store = SqliteWeatherStore(master);
      expect((await master.get(MasterKind.pond, 'p')).name, 'Kolam lama');
      expect(await store.location(), isNull);
      await store.confirm(
        BusinessLocation(
          'Usaha terkonfirmasi',
          -7,
          110,
          approximate: true,
          accuracy: 100,
        ),
      );
      await master.close();
      master = SqliteMasterRepository(open: open);
      store = SqliteWeatherStore(master);
      final saved = (await store.location())!;
      expect(saved.name, 'Usaha terkonfirmasi');
      expect(saved.latitude, -7);
      expect(saved.longitude, 110);
      expect(saved.approximate, isTrue);
      expect(saved.accuracy, 100);
      expect((await master.get(MasterKind.pond, 'p')).name, 'Kolam lama');
      await master.close();
    },
  );
  testWidgets(
    'gagal simpan atomik menjaga lokasi lama dan mengabaikan cache lokasi lama',
    (tester) async {
      final path =
          '${await getDatabasesPath()}/weather_rollback_${newMasterId()}.db';
      final master = SqliteMasterRepository(
        open: () => openDatabase(
          path,
          version: SqliteMasterRepository.schemaVersion,
          singleInstance: false,
          onCreate: SqliteMasterRepository.createSchema,
        ),
      );
      final store = SqliteWeatherStore(master);
      final a = BusinessLocation('Lama', -6, 106),
          b = BusinessLocation('Baru', -7, 110);
      await store.confirm(a);
      final db = await master.database();
      await db.execute(
        "CREATE TRIGGER fail_location BEFORE INSERT ON weather_location BEGIN SELECT RAISE(ABORT,'fixture fault'); END",
      );
      await expectLater(store.confirm(b), throwsA(isA<DatabaseException>()));
      expect((await store.location())!.key, a.key);
      await db.execute('DROP TRIGGER fail_location');
      await store.confirm(b);
      await store.saveCache(a.key, 'old', 1);
      expect(await store.cache(a.key), isNull);
      expect((await store.location())!.key, b.key);
      await master.close();
    },
  );
}
