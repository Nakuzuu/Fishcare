import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/master_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late SqliteMasterRepository repo;
  late String path;
  Future<Database> openTest() => openDatabase(
    path,
    version: SqliteMasterRepository.schemaVersion,
    singleInstance: false,
    onCreate: SqliteMasterRepository.createSchema,
  );
  setUp(() async {
    path = '${await getDatabasesPath()}/m1_isolated_test_${newMasterId()}.db';
    repo = SqliteMasterRepository(open: openTest);
  });
  tearDown(() async {
    await repo.close();
  });

  testWidgets('nama lintas kapitalisasi dan arsip tetap unik; rollback utuh', (
    tester,
  ) async {
    const first = MasterRecord(
      id: 'first',
      kind: MasterKind.pond,
      name: '  Kolam Uji  ',
    );
    await repo.save(first, create: true);
    await expectLater(
      repo.save(
        const MasterRecord(
          id: 'other',
          kind: MasterKind.pond,
          name: 'KOLAM UJI',
        ),
        create: true,
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect((await repo.list(MasterKind.pond, archived: false)).length, 1);
    await repo.archive(await repo.get(MasterKind.pond, 'first'));
    expect(await repo.list(MasterKind.pond, archived: false), isEmpty);
    expect(
      (await repo.list(MasterKind.pond, archived: true)).single.name,
      'Kolam Uji',
    );
    await expectLater(
      repo.save(
        const MasterRecord(
          id: 'other',
          kind: MasterKind.pond,
          name: 'kolam uji',
        ),
        create: true,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });
  testWidgets(
    'create ulang ID sama tidak ganda; harga invalid dan update stale ditolak',
    (tester) async {
      const feed = MasterRecord(
        id: 'feed',
        kind: MasterKind.feed,
        name: 'Pakan Uji',
        price: 10000,
      );
      await repo.save(feed, create: true);
      await repo.save(feed, create: true);
      expect((await repo.list(MasterKind.feed, archived: false)).length, 1);
      await expectLater(
        repo.save(
          const MasterRecord(
            id: 'bad',
            kind: MasterKind.feed,
            name: 'Harga invalid',
            price: 0,
          ),
          create: true,
        ),
        throwsA(isA<ValidationFailure>()),
      );
      await repo.save(
        const MasterRecord(
          id: 'feed',
          kind: MasterKind.feed,
          name: 'Pakan Baru',
          price: 12000,
        ),
        create: false,
      );
      await expectLater(
        repo.save(feed, create: false),
        throwsA(isA<ValidationFailure>()),
      );
      expect((await repo.get(MasterKind.feed, 'feed')).price, 12000);
    },
  );
  testWidgets('file data tetap saat repository dan koneksi dibuka ulang', (
    tester,
  ) async {
    await repo.save(
      const MasterRecord(
        id: 'persist',
        kind: MasterKind.pond,
        name: 'Persistensi Uji M1',
        notes: 'Data tes terisolasi',
      ),
      create: true,
    );
    await repo.close();
    repo = SqliteMasterRepository(open: openTest);
    expect(
      (await repo.get(MasterKind.pond, 'persist')).notes,
      'Data tes terisolasi',
    );
    // Reopen file, bukan bukti cold restart proses HP; tidak memakai fishcare_app.db.
  });
}
