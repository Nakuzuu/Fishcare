import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fishcare_m0/report_rules.dart';
import 'package:fishcare_m0/report_controller.dart';
import 'package:fishcare_m0/report_ui.dart';
import 'package:fishcare_m0/data_changes.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/product_app.dart';

import 'product_app_test.dart' show TestRepository;

Map<String, Object?> row(
  String date,
  String pond,
  String kind,
  int quantity, {
  int cost = 0,
  int? value,
  int harvestWeight = 20000,
  int harvestPrice = 25000,
  String? canceled,
}) {
  final harvest = kind == 'partial' || kind == 'final';
  if (harvest && value == null)
    throw ArgumentError('Fixture panen wajib punya snapshot nilai.');
  return {
    'id': '$date-$pond-$kind',
    'cycle_id': pond,
    'business_date': date,
    'pond_id': pond,
    'pond_name': pond,
    'kind': kind,
    'quantity': quantity,
    'cost_snapshot': kind == 'feeding' ? cost : null,
    'harvest_weight_cg': harvest ? harvestWeight : null,
    'price_rp_kg': harvest ? harvestPrice : null,
    'value_rp': harvest ? value : null,
    'cancel_action_id': canceled,
  };
}

ReportSnapshot view(ReportFilter f, List<Map<String, Object?>> rows) =>
    ReportSnapshot(
      filter: f,
      rows: rows.where(f.includes).toList(),
      ponds: const [
        {'id': 'a', 'name': 'Kolam A', 'is_archived': 0},
        {'id': 'b', 'name': 'Kolam B', 'is_archived': 1},
      ],
      conditions: const [],
      wholeRows: rows,
    );

class FakeReports implements ReportSource {
  List<Map<String, Object?>> rows = [];
  bool fail = false;
  final pending = <Completer<ReportSnapshot>>[];
  final filters = <ReportFilter>[];
  bool deferred = false;
  @override
  Future<String> today() async => '2026-10-13';
  @override
  Future<ReportSnapshot> load(ReportFilter f) async {
    filters.add(f);
    if (deferred) {
      final c = Completer<ReportSnapshot>();
      pending.add(c);
      return c.future;
    }
    if (fail) throw StateError('Fixture');
    return view(f, rows);
  }
}

void main() {
  test(
    'fixture mengikuti field panen nullable SQLite dan nilai wajib untuk panen',
    () {
      for (final kind in ['feeding', 'sampling', 'death', 'close']) {
        final data = row(
          '2026-10-13',
          'a',
          kind,
          kind == 'close' ? 0 : 1,
          value: 0,
        );
        expect(data['harvest_weight_cg'], isNull);
        expect(data['price_rp_kg'], isNull);
        expect(data['value_rp'], isNull);
      }
      expect(() => row('2026-10-13', 'a', 'partial', 20), throwsArgumentError);
      expect(() => row('2026-10-13', 'a', 'final', 80), throwsArgumentError);
    },
  );
  test('tanggal inklusif dan kolam satu/semua, tanggal invalid ditolak', () {
    final rows = [
      row('2026-10-11', 'a', 'death', 1),
      row('2026-10-12', 'a', 'death', 2),
      row('2026-10-13', 'b', 'death', 3),
      row('2026-10-14', 'a', 'death', 4),
    ];
    expect(
      reportTotals(
        rows.where(ReportFilter('2026-10-12', '2026-10-13').includes),
      )['dead'],
      5,
    );
    expect(
      reportTotals(
        rows.where(
          ReportFilter('2026-10-12', '2026-10-13', pondId: 'a').includes,
        ),
      )['dead'],
      2,
    );
    for (final dates in [
      ['2026-10-14', '2026-10-12'],
      ['2026-02-30', '2026-10-13'],
      ['', '2026-10-13'],
    ]) {
      expect(
        () => ReportFilter(dates[0], dates[1]),
        throwsA(isA<ValidationFailure>()),
      );
    }
  });
  test('panen parsial/akhir dan semua jenis batal dikecualikan', () {
    final rows = [
      row('2026-10-13', 'a', 'partial', 20, value: 100000),
      row('2026-10-13', 'a', 'final', 80, value: 400000),
      row('2026-10-13', 'a', 'death', 5, canceled: 'c'),
      row('2026-10-13', 'a', 'feeding', 150, cost: 1500, canceled: 'cf'),
      row('2026-10-13', 'a', 'partial', 10, value: 50000, canceled: 'ch'),
    ];
    final totals = reportTotals(rows);
    expect(totals['harvest_count'], 100);
    expect(totals['harvest_value'], 500000);
    expect(totals['dead'], 0);
    expect(totals['feed_cost'], 0);
    expect(totals['feed_g'], 0);
    expect(rows.length, 5);
  });
  test('penjumlahan snapshot per transaksi tanpa pembulatan gabungan atau harga kini', () {
    final rows = [
      row('2026-10-13', 'a', 'feeding', 1, cost: 1),
      row('2026-10-13', 'a', 'feeding', 1, cost: 1),
      row(
        '2026-10-13',
        'a',
        'partial',
        1,
        value: 1,
        harvestWeight: 50,
        harvestPrice: 1000,
      ),
      row(
        '2026-10-13',
        'a',
        'final',
        1,
        value: 1,
        harvestWeight: 50,
        harvestPrice: 1000,
      ),
    ];
    rows.first.addAll({
      'price_current': 999999,
      'weight_current': 999999,
      'rate_current': 9999,
    });
    final t = reportTotals(rows);
    expect(t['feed_cost'], 2);
    expect(t['harvest_value'], 2);
    expect(
      () => reportTotals([
        row('2026-10-13', 'a', 'feeding', 1, cost: 9223372036854775807),
        row('2026-10-13', 'a', 'feeding', 1, cost: 1),
      ]),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => reportTotals([
        row('2026-10-13', 'a', 'feeding', 1)..remove('cost_snapshot'),
      ]),
      throwsA(isA<ValidationFailure>()),
    );
  });
  test('controller membuang hasil/error filter lama dan dispose', () async {
    final source = FakeReports()..deferred = true;
    final first = ReportFilter('2026-10-12', '2026-10-12'),
        next = ReportFilter('2026-10-13', '2026-10-13', pondId: 'b');
    final c = ReportController(source, first);
    final one = c.load();
    final two = c.load(next);
    source.pending[1].complete(
      view(next, [row('2026-10-13', 'b', 'death', 5)]),
    );
    await two;
    source.pending[0].completeError(StateError('old'));
    await one;
    expect(c.snapshot!.totals['dead'], 5);
    expect(c.error, isNull);
    expect(c.loading, isFalse);
    final three = c.load(first);
    final four = c.load(next);
    source.pending[3].complete(view(next, []));
    await four;
    source.pending[2].complete(
      view(first, [row('2026-10-12', 'a', 'death', 99)]),
    );
    await three;
    expect(c.snapshot!.totals['dead'], 0);
    final last = c.load();
    c.dispose();
    source.pending.last.complete(view(next, []));
    await last;
  });
  test('commit/batal memicu refresh dengan filter tetap', () async {
    final source = FakeReports();
    final f = ReportFilter('2026-10-13', '2026-10-13', pondId: 'a');
    final c = ReportController(source, f);
    await c.load();
    source.rows = [row('2026-10-13', 'a', 'feeding', 150, cost: 1500)];
    DataChanges.committed();
    await Future<void>.delayed(Duration.zero);
    expect(c.snapshot!.totals['feed_cost'], 1500);
    expect(c.filter, same(f));
    source.rows.single['cancel_action_id'] = 'c';
    DataChanges.committed();
    await Future<void>.delayed(Duration.zero);
    expect(c.snapshot!.totals['feed_cost'], 0);
    expect(c.snapshot!.rows.length, 1);
    c.dispose();
  });
  testWidgets('empty/loading/gagal/retry dan filter yang berubah', (
    tester,
  ) async {
    final source = FakeReports()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReportPage(source: source)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Laporan gagal dimuat; angka bukan nol.'), findsOneWidget);
    await tester.tap(find.text('Periode laporan'));
    await tester.pumpAndSettle();
    source.fail = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada transaksi pada filter ini.'), findsOneWidget);
    source.deferred = true;
    await tester.tap(find.text('Terapkan filter'));
    await tester.pump();
    expect(find.byKey(const Key('report-loading')), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '2026-10-12');
    await tester.tap(find.text('Terapkan filter'));
    await tester.pump();
    final f = source.filters.last;
    source.pending.last.complete(
      view(f, [row('2026-10-12', 'a', 'feeding', 100, cost: 1000)]),
    );
    await tester.pumpAndSettle();
    source.pending.first.complete(
      view(source.filters[source.filters.length - 2], []),
    );
    await tester.pumpAndSettle();
    expect(find.text('100 g'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('pendukung dan detail mempertahankan filter, batal terlihat', (
    tester,
  ) async {
    final source = FakeReports()
      ..rows = [
        row('2026-10-13', 'b', 'death', 5, canceled: 'c')..addAll({
          'before_count': 100,
          'after_count': 95,
          'before_weight_cg': 10000,
          'after_weight_cg': 10000,
          'cancel_reason': 'Uji',
        }),
      ];
    final f = ReportFilter('2026-10-13', '2026-10-13', pondId: 'b');
    await tester.pumpWidget(
      MaterialApp(
        home: ReportTransactions(source: source, filter: f, metric: 'dead'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Batal — dikecualikan dari total'), findsOneWidget);
    await tester.tap(find.text('Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Alasan batal: Uji'), findsOneWidget);
    expect(find.text('Batal — dikecualikan dari total'), findsOneWidget);
    expect(find.textContaining('Populasi 100 → 95 ekor'), findsOneWidget);
    expect(find.textContaining('Bobot panen'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      source.filters.every(
        (r) => r.start == f.start && r.end == f.end && r.pondId == 'b',
      ),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final kind in ['partial', 'final']) {
    testWidgets('detail panen $kind valid memakai snapshot dan filter tetap', (
      tester,
    ) async {
      final count = kind == 'partial' ? 20 : 80;
      final value = kind == 'partial' ? 100000 : 400000;
      final source = FakeReports()
        ..rows = [
          row('2026-10-13', 'b', kind, count, value: value)..addAll({
            'before_count': kind == 'final' ? count : 100,
            'after_count': kind == 'final' ? 0 : 100 - count,
            'before_weight_cg': 10000,
            'after_weight_cg': 10000,
          }),
        ];
      final filter = ReportFilter('2026-10-13', '2026-10-13', pondId: 'b');
      await tester.pumpWidget(
        MaterialApp(
          home: ReportTransactions(
            source: source,
            filter: filter,
            metric: 'harvest_value',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Detail'));
      await tester.pumpAndSettle();
      expect(find.text('Sah'), findsOneWidget);
      expect(find.text('Jumlah $count ekor'), findsOneWidget);
      expect(
        find.textContaining(
          kind == 'final' ? 'Populasi 80 → 0 ekor' : 'Populasi 100 → 80 ekor',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Bobot panen 200,00 g/ikan\nHarga Rp25000/kg · Nilai snapshot Rp$value',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(
        source.filters.every(
          (f) =>
              f.start == filter.start &&
              f.end == filter.end &&
              f.pondId == filter.pondId,
        ),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'Beranda refresh commit/batal dan laporan tersimpan saat pindah tab',
    (tester) async {
      final source = FakeReports();
      await tester.pumpWidget(
        FishCareApp(repository: TestRepository(), reports: source),
      );
      await tester.pumpAndSettle();
      source.rows = [row('2026-10-13', 'a', 'feeding', 150, cost: 1500)];
      DataChanges.committed();
      await tester.pumpAndSettle();
      expect(find.text('150 g'), findsOneWidget);
      source.rows.single['cancel_action_id'] = 'c';
      DataChanges.committed();
      await tester.pumpAndSettle();
      expect(find.text('0 g'), findsOneWidget);
      await tester.tap(find.text('Laporan').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Periode laporan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '2026-10-12');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Terapkan filter'));
      await tester.tap(find.text('Terapkan filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Beranda').last);
      await tester.pumpAndSettle();
      expect(find.text('Beranda — transaksi hari ini'), findsOneWidget);
      await tester.tap(find.text('Laporan').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Periode laporan'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '2026-10-12',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
