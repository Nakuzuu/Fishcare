// Bukti tambahan Dart murni; bukan flutter test/SQLite/HP.
import 'dart:async';

import '../app_m0/lib/report_rules.dart';
import '../app_m0/lib/report_controller.dart';
import '../app_m0/lib/data_changes.dart';
import '../app_m0/lib/master_data.dart';

void check(bool ok) {
  if (!ok) throw StateError('M5 checker gagal');
}

class Source implements ReportSource {
  final pending = <Completer<ReportSnapshot>>[];
  @override
  Future<String> today() async => '2026-10-13';
  @override
  Future<ReportSnapshot> load(ReportFilter f) {
    final c = Completer<ReportSnapshot>();
    pending.add(c);
    return c.future;
  }
}

Map<String, Object?> row(
  String date,
  String pond,
  String kind,
  int q, {
  int cost = 0,
  int value = 0,
  bool canceled = false,
}) => {
  'business_date': date,
  'pond_id': pond,
  'cycle_id': pond,
  'kind': kind,
  'quantity': q,
  'cost_snapshot': cost,
  'value_rp': value,
  'cancel_action_id': canceled ? 'c' : null,
};
ReportSnapshot snapshot(ReportFilter f, List<Map<String, Object?>> rows) =>
    ReportSnapshot(
      filter: f,
      rows: rows.where(f.includes).toList(),
      ponds: [],
      conditions: [],
      wholeRows: rows,
    );
Future<void> main() async {
  final rows = [
    row('2026-10-12', 'a', 'feeding', 1, cost: 1),
    row('2026-10-13', 'a', 'feeding', 1, cost: 1),
    row('2026-10-13', 'b', 'partial', 20, value: 100000),
    row('2026-10-13', 'b', 'final', 80, value: 400000),
    row('2026-10-14', 'a', 'death', 50),
    row('2026-10-13', 'a', 'death', 5, canceled: true),
  ];
  final f = ReportFilter('2026-10-12', '2026-10-13');
  final t = snapshot(f, rows).totals;
  check(
    t['feed_g'] == 2 &&
        t['feed_cost'] == 2 &&
        t['dead'] == 0 &&
        t['harvest_count'] == 100 &&
        t['harvest_value'] == 500000,
  );
  final b = ReportFilter('2026-10-13', '2026-10-13', pondId: 'b');
  check(snapshot(b, rows).totals['feed_g'] == 0);
  check(snapshot(f, rows).rows.length == 5);
  check(
    reportTotals([
          row('2026-10-13', 'a', 'partial', 1, value: 1),
          row('2026-10-13', 'a', 'final', 1, value: 1),
        ])['harvest_value'] ==
        2,
  );
  var invalid = false;
  try {
    ReportFilter('2026-02-30', '2026-10-13');
  } on ValidationFailure {
    invalid = true;
  }
  check(invalid);
  var overflow = false;
  try {
    reportTotals([
      row('2026-10-13', 'a', 'feeding', 1, cost: 9223372036854775807),
      row('2026-10-13', 'a', 'feeding', 1, cost: 1),
    ]);
  } on ValidationFailure {
    overflow = true;
  }
  check(overflow);
  final source = Source();
  final c = ReportController(source, f);
  final old = c.load(), newer = c.load(b);
  source.pending[1].complete(snapshot(b, rows));
  await newer;
  source.pending[0].completeError(StateError('stale'));
  await old;
  check(
    c.error == null &&
        c.snapshot!.filter == b &&
        c.snapshot!.totals['harvest_value'] == 500000,
  );
  DataChanges.committed();
  await Future<void>.delayed(Duration.zero);
  check(source.pending.length == 3 && c.loading);
  source.pending.last.complete(snapshot(b, []));
  await Future<void>.delayed(Duration.zero);
  check(c.snapshot!.totals['harvest_value'] == 0 && c.filter == b);
  c.dispose();
  print(
    'M5 filter inklusif/kolam, snapshot per transaksi, batal, panen parsial/akhir, stale response dan refresh lulus sebagai bukti tambahan. Bukan flutter test/SQLite/HP.',
  );
}
