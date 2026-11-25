import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fishcare_m0/cycle_ui.dart';
import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/cycle_repository.dart';
import 'package:fishcare_m0/dashboard_ui.dart';
import 'package:fishcare_m0/design_system.dart';
import 'package:fishcare_m0/feed_repository.dart';
import 'package:fishcare_m0/master_repository.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/product_app.dart';

import 'ui_render_after_test.dart' show RenderMasters, RenderCycles, pond;
import 'cycle_ui_test.dart' show MasterFixture;

// Read-only fixtures. No production database, GPS, network, or writes.
class EmptyTransaction implements Transaction {
  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async => [];
  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Unexpected fixture operation: ${invocation.memberName}',
  );
}

class EmptyDatabase implements Database {
  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action, {
    bool? exclusive,
  }) => action(EmptyTransaction());
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Unexpected fixture operation: ${invocation.memberName}',
  );
}

class RenderFeed extends FeedRepository {
  RenderFeed._(SqliteMasterRepository master)
    : super(master, SqliteCycleRepository(master));
  factory RenderFeed() =>
      RenderFeed._(SqliteMasterRepository(open: () async => EmptyDatabase()));
  @override
  Future<List<Map<String, Object?>>> history(String cycle) async => [];
}

ThemeData renderTheme() {
  final base = FishCareDesign.theme();
  ButtonStyle font(ButtonStyle style) => style.copyWith(
    textStyle: WidgetStatePropertyAll(
      style.textStyle!.resolve({})!.copyWith(fontFamily: 'Roboto'),
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'Roboto'),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: base.appBarTheme.titleTextStyle!.copyWith(
        fontFamily: 'Roboto',
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: font(base.filledButtonTheme.style!),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: font(base.outlinedButtonTheme.style!),
    ),
    textButtonTheme: TextButtonThemeData(
      style: font(base.textButtonTheme.style!),
    ),
  );
}

void main() {
  setUpAll(() async {
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final file = File(
        'C:/flutter/bin/cache/artifacts/material_fonts/${entry.value}',
      );
      if (file.existsSync()) {
        await (FontLoader(entry.key)..addFont(
              Future.value(ByteData.sublistView(file.readAsBytesSync())),
            ))
            .load();
      }
    }
  });
  testWidgets('jam tetap dapat dibuka ketika rate otomatis belum tersedia', (
    tester,
  ) async {
    const view = CycleView(
      id: 'c',
      fish: 'Lele',
      feedName: 'Pakan',
      startDate: '2026-11-18',
      population: 100,
      weightCg: 100,
      rateBp: null,
      need: null,
      date: '2026-11-18',
      zone: 'Asia/Jakarta',
      times: [480],
      portions: [null],
      tomorrowTimes: [480],
      statuses: ['pending'],
      automatic: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: FishCareDesign.theme(),
        home: ChangeCycleForm(
          view: view,
          repository: RenderCycles(),
          rate: false,
        ),
      ),
    );
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('Simpan jam untuk besok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'metric columns align and schedule removal preserves remaining times',
    (tester) async {
      var times = [480, 960];
      await tester.pumpWidget(
        MaterialApp(
          theme: FishCareDesign.theme(),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: SizedBox(
                width: 360,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const FishMetrics(population: '100', weight: '100'),
                    ScheduleEditor(
                      times: times,
                      enabled: true,
                      onChanged: (value) => setState(() => times = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('Populasi')).dy,
        tester.getTopLeft(find.text('Bobot rata-rata')).dy,
      );
      final cards = find.byType(FishCard);
      expect(tester.getSize(cards.first).width, 324);
      await tester.tap(find.byTooltip('Hapus jam 08:00'));
      await tester.pump();
      expect(times, [960]);
      expect(find.text('16:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [(390.0, 1.0), (360.0, 1.3)]) {
    for (final screen in [
      'ringkasan',
      'kolam',
      'tambah-kolam',
      'siklus-baru',
      'detail-kolam',
      'jam',
    ]) {
      testWidgets('design match $screen ${size.$1} ${size.$2}', (tester) async {
        tester.view.physicalSize = Size(size.$1, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cycles = RenderCycles();
        final masters = RenderMasters();
        final CycleView view = (await cycles.active(pond.id))!;
        final boundary = GlobalKey();
        final Widget page = switch (screen) {
          'ringkasan' => Scaffold(
            appBar: const FishAppBar(title: Text('Kolam aktif')),
            body: ListView(
              padding: const EdgeInsets.all(18),
              children: [FishCard(child: ConditionSummary(view: view))],
            ),
          ),
          'kolam' => Scaffold(
            appBar: const FishAppBar(title: Text('Kolam')),
            body: MasterList(
              kind: MasterKind.pond,
              repository: masters,
              cycles: cycles,
            ),
          ),
          'tambah-kolam' => MasterForm(
            kind: MasterKind.pond,
            repository: masters,
          ),
          'siklus-baru' => StartCycleForm(
            pond: pond,
            masters: MasterFixture(),
            repository: cycles,
          ),
          'detail-kolam' => MasterDetail(
            record: pond,
            repository: masters,
            cycles: cycles,
            feeds: RenderFeed(),
          ),
          _ => ChangeCycleForm(view: view, repository: cycles, rate: false),
        };
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              theme: renderTheme(),
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(size.$2)),
                child: child!,
              ),
              home: page,
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> capture(String suffix) async {
          expect(tester.takeException(), isNull);
          await tester.runAsync(() async {
            final picture =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final dir = Directory('../output/ui-match-2026-11-18')
              ..createSync(recursive: true);
            File(
              '${dir.path}/$screen-${size.$1.toInt()}-${(size.$2 * 100).round()}-$suffix.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }

        await capture('atas');
        if (screen == 'detail-kolam') {
          await tester.scrollUntilVisible(
            find.text('Kegiatan kolam'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await capture('kegiatan');
          await tester.tap(find.text('Riwayat'));
          await tester.pumpAndSettle();
          expect(
            find.text('Belum ada kegiatan operasional.').hitTestable(),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.text('Lihat pakan hari ini').hitTestable(),
            -200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.tap(find.text('Lihat pakan hari ini'));
          await tester.pumpAndSettle();
          expect(find.text('Berikan 16:00').hitTestable(), findsOneWidget);
          await capture('pakan');
        }
        if (screen == 'siklus-baru') {
          await tester.scrollUntilVisible(
            find.text('Tambah jam'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await capture('jadwal');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
