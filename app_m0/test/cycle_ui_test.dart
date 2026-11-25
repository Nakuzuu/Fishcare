import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/cycle_ui.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CycleFixture implements CycleRepository {
  int starts = 0;
  @override
  Future<String?> lockedZone() async => 'Asia/Jakarta';
  @override
  Future<CycleView?> active(String pondId) async => const CycleView(
    id: 'cycle',
    fish: 'Ikan fixture',
    feedName: 'Pakan fixture',
    startDate: '2026-10-13',
    population: 100,
    weightCg: 10000,
    rateBp: 301,
    need: 301,
    date: '2026-10-13',
    zone: 'Asia/Jakarta',
    times: [480, 960],
    portions: [151, 150],
    tomorrowTimes: [540, 1020],
  );
  @override
  Future<void> start(StartCycle draft) async {
    starts++;
  }

  @override
  Future<void> changeRate(
    String id,
    int rate,
    String operation,
    String date,
  ) async {}
  @override
  Future<void> changeTimes(
    String id,
    List<int> times,
    String operation,
    String date,
  ) async {}
}

class MasterFixture implements MasterRepository {
  @override
  Future<List<MasterRecord>> list(
    MasterKind kind, {
    required bool archived,
  }) async => [
    const MasterRecord(
      id: 'feed',
      kind: MasterKind.feed,
      name: 'Pakan fixture',
      price: 10000,
    ),
  ];
  @override
  Future<MasterRecord> get(MasterKind kind, String id) async =>
      throw UnimplementedError();
  @override
  Future<void> save(MasterRecord record, {required bool create}) async {}
  @override
  Future<void> archive(MasterRecord record) async {}
}

void main() {
  const pond = MasterRecord(
    id: 'pond',
    kind: MasterKind.pond,
    name: 'Kolam fixture',
  );
  testWidgets(
    'detail membedakan jam hari ini/besok; tidak menawarkan Berikan',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                CyclePanel(
                  pond: pond,
                  masters: MasterFixture(),
                  repository: CycleFixture(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kebutuhan harian'), findsOneWidget);
      expect(find.text('301 g/hari'), findsOneWidget);
      expect(find.textContaining('08:00 — 151 g'), findsOneWidget);
      expect(
        find.textContaining('Jam berlaku besok 2026-10-14: 09:00, 17:00'),
        findsOneWidget,
      );
      expect(find.text('Berikan'), findsNothing);
      expect(find.text('Mulai siklus'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'bobot NaN ditolak sebelum mulai siklus otomatis dan draft tetap tersedia',
    (tester) async {
      final cycles = CycleFixture();
      await tester.pumpWidget(
        MaterialApp(
          home: StartCycleForm(
            pond: pond,
            masters: MasterFixture(),
            repository: cycles,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fishController = tester
          .widget<TextFormField>(find.byType(TextFormField).at(0))
          .controller!;
      await tester.enterText(find.byType(TextFormField).at(0), 'Lele fixture');
      await tester.enterText(find.byType(TextFormField).at(1), '100');
      await tester.enterText(find.byType(TextFormField).at(2), 'NaN');
      await tester.scrollUntilVisible(
        find.text('Tinjau dan mulai siklus').hitTestable(),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Tinjau dan mulai siklus'));
      await tester.pumpAndSettle();
      expect(cycles.starts, 0);
      expect(
        find.textContaining('Isi angka positif maksimal dua desimal'),
        findsOneWidget,
      );
      expect(fishController.text, 'Lele fixture');
    },
  );
}
