import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/dashboard_ui.dart';
import 'package:fishcare_m0/data_changes.dart';
import 'package:fishcare_m0/design_system.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/product_app.dart';
import 'package:fishcare_m0/weather_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cycle_ui_test.dart' show CycleFixture;
import 'product_app_test.dart' show TestRepository;
import 'support/weather_fakes.dart';

class DesignCycles extends CycleFixture {
  int actual = 0;
  bool fail = false;
  @override
  Future<CycleView?> active(String pondId) async {
    if (fail) throw StateError('Isolated UI read failure');
    return CycleView(
      id: 'test-cycle',
      fish: 'Ikan uji',
      feedName: 'Pakan uji',
      startDate: '2026-10-20',
      population: 100,
      weightCg: 10000,
      rateBp: 300,
      need: 300,
      actualToday: actual,
      date: '2026-10-20',
      zone: 'Asia/Jakarta',
      times: const [480, 960],
      portions: const [150, 150],
      tomorrowTimes: const [480, 960],
      statuses: const ['pending', 'pending'],
    );
  }
}

void smallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget surface(Widget child) => MaterialApp(
  theme: FishCareDesign.theme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.3)),
    child: child!,
  ),
  home: child,
);

void main() {
  testWidgets('kembali dari form menjaga draft sampai Buang dikonfirmasi', (
    tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      surface(
        Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: const FishAppBar(title: Text('Form pengujian')),
                    body: FormList(
                      controllers: [controller],
                      children: [TextField(controller: controller)],
                    ),
                  ),
                ),
              ),
              child: const Text('Buka form'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka form'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Draft dipertahankan');
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Buang perubahan?'), findsOneWidget);
    await tester.tap(find.text('Tetap mengisi'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Draft dipertahankan');
    expect(find.text('Form pengujian'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buang'));
    await tester.pumpAndSettle();
    expect(find.text('Buka form'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
  testWidgets('360dp teks130: ringkasan nyata diperbarui setelah commit', (
    tester,
  ) async {
    smallPhone(tester);
    final master = TestRepository()
      ..rows.add(
        const MasterRecord(
          id: 'pond-test',
          kind: MasterKind.pond,
          name: 'Kolam pengujian',
        ),
      );
    final cycles = DesignCycles();
    await tester.pumpWidget(
      surface(
        Scaffold(
          body: HomeDashboard(
            repository: master,
            cycles: cycles,
            attempts: {},
            openFeed: () {},
            openPonds: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('300 g tersisa'), findsOneWidget);
    cycles.actual = 150;
    DataChanges.committed();
    await tester.pumpAndSettle();
    expect(find.text('150 g tersisa'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'gagal baca kegiatan tidak menjadi kebutuhan nol; retry memuat data',
    (tester) async {
      final master = TestRepository()
        ..rows.add(
          const MasterRecord(
            id: 'pond-test',
            kind: MasterKind.pond,
            name: 'Kolam uji',
          ),
        );
      final cycles = DesignCycles()..fail = true;
      await tester.pumpWidget(
        surface(
          Scaffold(
            body: HomeDashboard(
              repository: master,
              cycles: cycles,
              attempts: {},
              openFeed: () {},
              openPonds: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 g tersisa'), findsNothing);
      expect(find.textContaining('Kebutuhan belum diketahui'), findsOneWidget);
      cycles.fail = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('300 g tersisa'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    '360dp teks130 keyboard: field, validasi dan Simpan dapat digulir',
    (tester) async {
      smallPhone(tester);
      final repo = TestRepository();
      await tester.pumpWidget(
        surface(MasterForm(kind: MasterKind.pond, repository: repo)),
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final notes = find.byType(TextFormField).last;
      await tester.ensureVisible(notes);
      await tester.tap(notes);
      await tester.enterText(notes, 'Draft saat keyboard terbuka');
      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(repo.saves, 0);
      await tester.ensureVisible(find.byType(TextFormField).first);
      expect(tester.takeException(), isNull);
      expect(
        tester.getBottomLeft(find.byType(TextFormField).first).dy,
        lessThan(500),
      );
    },
  );

  testWidgets(
    'konfirmasi panjang dapat digulir pada360dp teks130 dan batal tidak menyimpan',
    (tester) async {
      smallPhone(tester);
      bool? result;
      await tester.pumpWidget(
        surface(
          Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () async {
                  result = await reviewAction(
                    context,
                    title: 'Tinjau pencatatan',
                    summary: List.filled(
                      25,
                      'Rincian transaksi uji dengan satuan dan snapshot.',
                    ).join('\n'),
                  );
                },
                child: const Text('Tinjau'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tinjau'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Kembali mengubah').hitTestable(),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Kembali mengubah'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Tinjau'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('confirm-action')).hitTestable(),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final confirmPosition = tester.getCenter(
        find.byKey(const ValueKey('confirm-action')),
      );
      await tester.tapAt(confirmPosition);
      await tester.tapAt(confirmPosition);
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(find.text('Tinjau'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cuaca memuat: navigasi lokal dan Atur lokasi tetap aktif tanpa ambil HP',
    (tester) async {
      smallPhone(tester);
      final store = MemoryWeatherStore()..value = locationA;
      final api = FakeBusinessApi()..deferred = true;
      final device = FakeDeviceLocation();
      var selected = 0;
      await tester.pumpWidget(
        surface(
          StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: selected == 0
                  ? ListView(
                      children: [
                        BusinessWeatherPanel(
                          store: store,
                          api: api,
                          device: device,
                        ),
                      ],
                    )
                  : const Text('Pencatatan lokal'),
              bottomNavigationBar: NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (v) => setState(() => selected = v),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home),
                    label: 'Beranda',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.water),
                    label: 'Kolam',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(device.calls, 0);
      expect(find.text('Atur lokasi'), findsOneWidget);
      expect(find.text('Ambil lokasi saat ini'), findsNothing);
      await tester.tap(find.text('Kolam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Pencatatan lokal'), findsOneWidget);
      expect(device.calls, 0);
      for (final pending in api.pending) {
        if (!pending.isCompleted) pending.complete(weatherReading(25));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
