import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/report_rules.dart';
import 'package:fishcare_m0/harvest_result_ui.dart';
import 'package:fishcare_m0/activity_ui.dart';
import 'package:fishcare_m0/master_data.dart';

import 'report_test.dart' show row;

void main() {
  final records = [
    row('2026-10-01', 'a', 'feeding', 1000, cost: 15000),
    row('2026-10-02', 'a', 'feeding', 2000, cost: 40000),
    row('2026-10-02', 'a', 'feeding', 500, cost: 9999, canceled: 'cancel'),
    row('2026-10-03', 'a', 'partial', 10, value: 100000),
    row('2026-10-04', 'a', 'partial', 10, value: 99999, canceled: 'cancel'),
    row('2026-10-26', 'a', 'final', 80, value: 400000),
    row('2026-10-26', 'b', 'final', 10, value: 900000),
  ];
  test('seluruh siklus, snapshot harga berbeda, batal dikecualikan dan siklus terpisah', () {
    final enriched = withHarvestFeedResults(records);
    final result = enriched[5]['harvest_feed_result'] as HarvestFeedResult;
    expect(result.revenue, 500000);
    expect(result.feedGrams, 3000);
    expect(result.feedCost, 55000);
    expect(result.afterFeed, 445000);
    expect(
      (enriched[6]['harvest_feed_result'] as HarvestFeedResult).revenue,
      900000,
    );
    expect(records[5].containsKey('harvest_feed_result'), isFalse);
    expect(enriched.first.containsKey('harvest_feed_result'), isFalse);
  });
  test('hasil siklus tetap seluruh siklus ketika filter periode hanya tanggal akhir', () {
    final filter = ReportFilter('2026-10-26', '2026-10-26', pondId: 'a');
    final snapshot = ReportSnapshot(
      filter: filter,
      rows: records.where(filter.includes).toList(),
      ponds: const [],
      conditions: const [],
      wholeRows: records,
    );
    expect(snapshot.totals['feed_cost'], 0);
    expect(snapshot.totals['harvest_value'], 400000);
    expect(
      HarvestFeedResult.fromTotals(snapshot.cycleTotals('a')).afterFeed,
      445000,
    );
  });
  test('tutup tanpa panen, tanpa biaya, dan selisih negatif tetap jujur', () {
    final rows = [
      row('2026-10-01', 'a', 'feeding', 1000, cost: 15000),
      row('2026-10-26', 'a', 'close', 0),
    ];
    final result =
        withHarvestFeedResults(rows).last['harvest_feed_result']
            as HarvestFeedResult;
    expect(result.revenue, 0);
    expect(result.afterFeed, -15000);
    expect(HarvestFeedResult.fromTotals(reportTotals([])).afterFeed, 0);
  });
  test('data biaya tidak lengkap tetap gagal, bukan keuntungan rekaan', () {
    final invalid = [
      ...records.map((r) => {...r}),
    ];
    invalid.first.remove('cost_snapshot');
    expect(
      () => withHarvestFeedResults(invalid),
      throwsA(isA<ValidationFailure>()),
    );
  });
  testWidgets(
    'tabel 360dp teks besar menampilkan nilai negatif tanpa overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: HarvestFeedResultTable(
                    result: HarvestFeedResult(
                      revenue: 10000,
                      feedGrams: 2000,
                      feedCost: 15000,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Rp-5.000'), findsOneWidget);
      expect(find.text('Pendapatan kotor'), findsOneWidget);
      expect(find.textContaining('bukan keuntungan bersih'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('detail panen akhir memuat tabel seluruh siklus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetail(row: withHarvestFeedResults(records)[5]),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Pendapatan kotor'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rp500.000'), findsOneWidget);
  });
}
