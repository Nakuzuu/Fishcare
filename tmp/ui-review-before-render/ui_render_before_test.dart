import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'lib/product_app.dart';
import 'lib/dashboard_ui.dart';
import 'lib/master_data.dart';
import 'lib/cycle_rules.dart';
import 'lib/report_rules.dart';
import 'lib/report_ui.dart';
import 'lib/design_system.dart';
import 'lib/weather_ui.dart';
import 'lib/weather_api.dart';
import 'lib/weather_contract.dart';
import 'lib/business_location.dart';

// Fixture hanya untuk render. Tidak membuka SQLite/GPS/jaringan atau data pengguna.
const pond = MasterRecord(
  id: 'render-pond',
  kind: MasterKind.pond,
  name: 'Kolam Utara',
  size: '4 × 6 m',
  notes: 'Dekat pintu masuk',
);

class RenderMasters implements MasterRepository {
  @override
  Future<List<MasterRecord>> list(
    MasterKind kind, {
    required bool archived,
  }) async => kind == MasterKind.pond && !archived ? [pond] : [];
  @override
  Future<MasterRecord> get(MasterKind kind, String id) async => pond;
  @override
  Future<void> save(MasterRecord record, {required bool create}) async =>
      throw StateError('Render tidak boleh menyimpan');
  @override
  Future<void> archive(MasterRecord record) async =>
      throw StateError('Render tidak boleh mengarsipkan');
}

class RenderCycles implements CycleRepository {
  @override
  Future<String?> lockedZone() async => 'Asia/Jakarta';
  @override
  Future<CycleView?> active(String pondId) async => const CycleView(
    id: 'render-cycle-long-id-for-visual-review',
    fish: 'Nila',
    feedName: 'Pakan A',
    startDate: '2026-10-01',
    population: 100,
    weightCg: 10000,
    rateBp: 300,
    need: 300,
    date: '2026-10-20',
    zone: 'Asia/Jakarta',
    times: [480, 960],
    portions: [150, 150],
    tomorrowTimes: [480, 960],
    actualToday: 150,
    statuses: ['given', 'pending'],
  );
  @override
  Future<void> start(StartCycle draft) async =>
      throw StateError('Render baca saja');
  @override
  Future<void> changeRate(
    String id,
    int rate,
    String operation,
    String date,
  ) async => throw StateError('Render baca saja');
  @override
  Future<void> changeTimes(
    String id,
    List<int> times,
    String operation,
    String date,
  ) async => throw StateError('Render baca saja');
}

class RenderReports implements ReportSource {
  @override
  Future<String> today() async => '2026-10-20';
  @override
  Future<ReportSnapshot> load(ReportFilter filter) async {
    final rows = <Map<String, Object?>>[
      {
        'id': 'render-feeding',
        'cycle_id': 'render-cycle-long-id-for-visual-review',
        'business_date': '2026-10-20',
        'pond_id': pond.id,
        'pond_name': pond.name,
        'pond_archived': 0,
        'kind': 'feeding',
        'quantity': 150,
        'cost_snapshot': 45000,
        'cancel_action_id': null,
      },
    ];
    return ReportSnapshot(
      filter: filter,
      rows: rows.where(filter.includes).toList(),
      ponds: [
        {'id': pond.id, 'name': pond.name, 'is_archived': 0},
      ],
      conditions: [
        {
          'id': 'render-cycle-long-id-for-visual-review',
          'pond_name': pond.name,
          'pond_archived': 0,
          'fish': 'Nila',
          'start_date': '2026-10-01',
          'status': 'active',
          'current_count': 100,
          'current_weight_cg': 10000,
        },
      ],
      wholeRows: rows,
    );
  }
}

class RenderWeatherStore implements WeatherStore {
  @override
  Future<BusinessLocation?> location() async =>
      BusinessLocation('Lokasi uji render', -6.2000123456, 106.8000123456);
  @override
  Future<void> confirm(BusinessLocation location) async =>
      throw StateError('Render baca saja');
  @override
  Future<Map<String, Object?>?> cache(String key) async => null;
  @override
  Future<void> saveCache(String key, String body, int fetchedMs) async {}
}

class RenderWeatherApi implements BusinessWeatherApi {
  @override
  Future<ProductWeather> fetch(BusinessLocation location) async =>
      ProductWeather.parse(
        '''{
    "current":{"temperature_2m":29,"weather_code":61,"time":"2026-10-20T13:00"},
    "current_units":{"temperature_2m":"°C"},"utc_offset_seconds":25200,"timezone":"Asia/Jakarta","timezone_abbreviation":"WIB",
    "daily":{"time":["2026-10-20"],"precipitation_probability_max":[60]},"daily_units":{"precipitation_probability_max":"%"}}'''
            .replaceAll('\n', ''),
        DateTime.now().toUtc(),
      );
  @override
  Future<List<BusinessLocation>> search(String query) async => [];
  @override
  void cancelWeather() {}
  @override
  void dispose() {}
}

void main() {
  for (final size in [(390.0, 1.0), (360.0, 1.3)]) {
    for (final screen in ['beranda', 'detail-kolam', 'laporan']) {
      testWidgets('render before $screen ${size.$1}dp teks${size.$2}', (
        tester,
      ) async {
        tester.view.physicalSize = Size(size.$1, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        final masters = RenderMasters(),
            cycles = RenderCycles(),
            reports = RenderReports();
        Widget nav(int index) => NavigationBar(
          selectedIndex: index,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.water_outlined),
              label: 'Kolam',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              label: 'Pakan',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              label: 'Laporan',
            ),
          ],
        );
        final Widget page = switch (screen) {
          'detail-kolam' => MasterDetail(
            record: pond,
            repository: masters,
            cycles: cycles,
          ),
          'laporan' => Scaffold(
            appBar: const FishAppBar(title: Text('Laporan')),
            body: ReportPage(source: reports),
            bottomNavigationBar: nav(3),
          ),
          _ => Scaffold(
            appBar: const FishAppBar(title: Text('FishCare')),
            body: HomeDashboard(
              repository: masters,
              cycles: cycles,
              reports: reports,
              attempts: {},
              openFeed: () {},
              openPonds: () {},
              weather: BusinessWeatherPanel(
                store: RenderWeatherStore(),
                api: RenderWeatherApi(),
              ),
            ),
            bottomNavigationBar: nav(0),
          ),
        };
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              theme: FishCareDesign.theme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(size.$2)),
                child: Banner(
                  message: 'DATA UJI RENDER',
                  location: BannerLocation.topEnd,
                  child: child!,
                ),
              ),
              home: page,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('../output/ui-review/before-render')
            ..createSync(recursive: true);
          File(
            '${directory.path}/$screen-${size.$1.toInt()}-text${(size.$2 * 100).round()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
        if ('before' == 'after') expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
