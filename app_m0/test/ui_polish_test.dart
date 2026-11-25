import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/activity_ui.dart';
import 'package:fishcare_m0/business_location.dart';
import 'package:fishcare_m0/dashboard_ui.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/product_app.dart';
import 'package:fishcare_m0/report_ui.dart';
import 'package:fishcare_m0/ui_format.dart';
import 'package:fishcare_m0/weather_api.dart';
import 'package:fishcare_m0/weather_card.dart';

import 'cycle_ui_test.dart' show CycleFixture;
import 'product_app_test.dart' show TestRepository;
import 'design_ui_test.dart' show smallPhone, surface;
import 'report_test.dart' show FakeReports;

final _now = DateTime.utc(2026, 10, 20, 6);
ProductWeather _weather({bool old = false}) => ProductWeather.parse(
  '''{
  "current":{"temperature_2m":29,"weather_code":61,"time":"2026-10-20T13:00"},
  "current_units":{"temperature_2m":"°C"},"utc_offset_seconds":25200,
  "timezone":"Asia/Jakarta","timezone_abbreviation":"WIB",
  "daily":{"time":["2026-10-20"],"precipitation_probability_max":[60]},
  "daily_units":{"precipitation_probability_max":"%"}}''',
  old ? _now.subtract(const Duration(hours: 2)) : _now,
);

void main() {
  test('format tampilan uang, angka besar, tanggal dan zona penyedia', () {
    expect(uiMoney(45000), 'Rp45.000');
    expect(uiNumber(9223372036854775807), '9.223.372.036.854.775.807');
    expect(uiDecimal(1250), '12,5');
    expect(uiDate('2026-10-20'), '20 Okt 2026');
    final time = weatherTimes(_weather(), _now);
    expect(time.provider, '20 Okt 2026, 13.00 · WIB');
    expect(time.fetched, '20 Okt 2026, 13.00 · WIB');
  });

  for (final state in ['empty', 'loading', 'live', 'old', 'offline', 'error']) {
    testWidgets('cuaca $state 360dp teks130 tanpa dummy atau koordinat utama', (
      tester,
    ) async {
      smallPhone(tester);
      final hasData = ['live', 'old'].contains(state);
      final loc = state == 'empty'
          ? null
          : BusinessLocation('Lokasi HP', -6.123456789, 106.123456789);
      await tester.pumpWidget(
        surface(
          Scaffold(
            body: ListView(
              children: [
                WeatherCard(
                  location: loc,
                  weather: hasData ? _weather(old: state == 'old') : null,
                  now: _now,
                  loading: state == 'loading',
                  cached: state == 'old',
                  failed: state == 'old',
                  error: ['offline', 'error'].contains(state)
                      ? 'Pembaruan gagal/offline.'
                      : null,
                  onSettings: () {},
                  onRefresh: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('-6.123456789'), findsNothing);
      expect(find.textContaining('T13:00'), findsNothing);
      expect(
        find.text('Lokasi HP'),
        state == 'empty' ? findsNothing : findsOneWidget,
      );
      if (!hasData) expect(find.text('29 °C'), findsNothing);
      if (hasData) {
        expect(find.text('29 °C'), findsOneWidget);
        expect(find.text('Prakiraan hujan hari ini'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Detail cuaca').hitTestable(),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Detail cuaca'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('-6.123456789'),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('-6.123456789'), findsOneWidget);
        expect(find.text('20 Okt 2026, 13.00 · WIB'), findsWidgets);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Beranda menempatkan cuaca sebelum pakan dan ringkasan lokal', (
    tester,
  ) async {
    smallPhone(tester);
    final masters = TestRepository()
      ..rows.add(
        const MasterRecord(
          id: 'pond',
          kind: MasterKind.pond,
          name: 'Kolam uji',
        ),
      );
    await tester.pumpWidget(
      surface(
        Scaffold(
          body: HomeDashboard(
            repository: masters,
            cycles: CycleFixture(),
            attempts: {},
            openFeed: () {},
            openPonds: () {},
            weather: WeatherCard(
              location: BusinessLocation('Lokasi uji', -6, 106),
              weather: _weather(),
              now: _now,
              onSettings: () {},
              onRefresh: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Pakan hari ini'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('weather-card'))).dy,
      lessThan(tester.getTopLeft(find.text('Pakan hari ini')).dy),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('detail kolam nama sekali dan identitas sekunder', (
    tester,
  ) async {
    smallPhone(tester);
    const pond = MasterRecord(
      id: 'pond',
      kind: MasterKind.pond,
      name: 'Kolam pengujian dengan nama panjang',
    );
    final masters = TestRepository()..rows.add(pond);
    await tester.pumpWidget(
      surface(
        MasterDetail(record: pond, repository: masters, cycles: CycleFixture()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(pond.name), findsOneWidget);
    expect(find.text('Kolam aktif'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ubah identitas'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.ancestor(
        of: find.text('Ubah identitas'),
        matching: find.byWidgetPredicate((w) => w is TextButton),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('kartu siklus menyembunyikan ID panjang dan memformat snapshot', (
    tester,
  ) async {
    smallPhone(tester);
    await tester.pumpWidget(
      surface(
        Scaffold(
          body: ListView(
            children: [
              ReportCycleCard(
                condition: const {
                  'id': 'panjang-teknis-123456789',
                  'pond_name': 'Kolam Utara',
                  'fish': 'Nila',
                  'start_date': '2026-10-01',
                  'status': 'active',
                },
                totals: const {
                  'feed_g': 1500,
                  'feed_cost': 45000,
                  'dead': 0,
                  'harvest_count': 20,
                  'harvest_value': 100000,
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rp45.000'), findsOneWidget);
    expect(find.textContaining('panjang-teknis'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Detail siklus'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Detail siklus'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Identitas siklus').hitTestable(),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Identitas siklus'));
    await tester.pumpAndSettle();
    expect(find.textContaining('panjang-teknis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('riwayat ringkas membuka snapshot dan alasan batal yang sama', (
    tester,
  ) async {
    final row = <String, Object?>{
      'id': 'test',
      'cycle_id': 'siklus-panjang',
      'kind': 'partial',
      'business_date': '2026-10-20',
      'quantity': 20,
      'before_count': 100,
      'after_count': 80,
      'before_weight_cg': 10000,
      'after_weight_cg': 10000,
      'harvest_weight_cg': 20000,
      'price_rp_kg': 25000,
      'value_rp': 100000,
      'cancel_action_id': 'cancel',
      'cancel_reason': 'Salah input',
    };
    await tester.pumpWidget(
      surface(
        Scaffold(
          body: ListView(children: [ActivityCard(row: row)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('siklus-panjang'), findsNothing);
    expect(find.text('Rp100.000'), findsOneWidget);
    await tester.tap(find.text('Detail kegiatan'));
    await tester.pumpAndSettle();
    expect(find.text('100 → 80 ekor'), findsOneWidget);
    expect(find.text('200 g/ikan'), findsOneWidget);
    expect(find.text('Alasan batal: Salah input'), findsOneWidget);
    expect(row['value_rp'], 100000);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'posisi gulir awal Beranda dan Laporan tidak diwariskan antartab',
    (tester) async {
      smallPhone(tester);
      final masters = TestRepository()
        ..rows.add(
          const MasterRecord(
            id: 'pond',
            kind: MasterKind.pond,
            name: 'Kolam uji',
          ),
        );
      await tester.pumpWidget(
        surface(
          ProductHome(
            repository: masters,
            cycles: CycleFixture(),
            reports: FakeReports(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('home-scroll')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laporan').last);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Periode laporan')).dy, lessThan(200));
      await tester.tap(find.text('Beranda').last);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Pakan hari ini')).dy, lessThan(200));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
