import 'cycle_rules.dart';
import 'master_data.dart';

class ReportFilter {
  ReportFilter(this.start, this.end, {this.pondId}) {
    for (final date in [start, end]) {
      final parsed = DateTime.tryParse('${date}T00:00:00Z');
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
          parsed == null ||
          parsed.year < 1 ||
          parsed.toIso8601String().substring(0, 10) != date) {
        throw const ValidationFailure('Tanggal laporan tidak valid.');
      }
    }
    if (start.compareTo(end) > 0)
      throw const ValidationFailure(
        'Tanggal mulai tidak boleh setelah tanggal akhir.',
      );
  }
  final String start, end;
  final String? pondId;
  bool includes(Map<String, Object?> row) =>
      (row['business_date'] as String).compareTo(start) >= 0 &&
      (row['business_date'] as String).compareTo(end) <= 0 &&
      (pondId == null || row['pond_id'] == pondId);
}

const reportMetrics = {
  'feed_g': 'Pakan aktual',
  'feed_cost': 'Biaya pakan',
  'dead': 'Ikan mati',
  'harvest_count': 'Ikan panen',
  'harvest_value': 'Nilai panen',
};
String metricUnit(String metric) => metric == 'feed_g'
    ? 'g'
    : metric == 'dead' || metric == 'harvest_count'
    ? 'ekor'
    : 'Rp';
bool supportsMetric(Map<String, Object?> row, String metric) =>
    switch (metric) {
      'feed_g' || 'feed_cost' => row['kind'] == 'feeding',
      'dead' => row['kind'] == 'death',
      'harvest_count' ||
      'harvest_value' => ['partial', 'final'].contains(row['kind']),
      _ => false,
    };
Map<String, int> reportTotals(Iterable<Map<String, Object?>> rows) {
  final sums = {for (final key in reportMetrics.keys) key: BigInt.zero};
  for (final row in rows) {
    if (row['cancel_action_id'] != null) continue;
    for (final key in sums.keys) {
      if (!supportsMetric(row, key)) continue;
      final column = key == 'feed_cost'
          ? 'cost_snapshot'
          : key == 'harvest_value'
          ? 'value_rp'
          : 'quantity';
      final value = row[column];
      if (value is! int || value < 0)
        throw const ValidationFailure(
          'Snapshot laporan tidak lengkap/valid; total tidak dapat dihitung.',
        );
      sums[key] = sums[key]! + BigInt.from(value);
    }
  }
  return {for (final key in sums.keys) key: checkedInteger(sums[key]!)};
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.filter,
    required this.rows,
    required this.ponds,
    required this.conditions,
    required this.wholeRows,
  });
  final ReportFilter filter;
  final List<Map<String, Object?>> rows, ponds, conditions, wholeRows;
  Map<String, int> get totals => reportTotals(rows);
  Map<String, int> cycleTotals(String cycle) =>
      reportTotals(wholeRows.where((r) => r['cycle_id'] == cycle));
}

abstract interface class ReportSource {
  Future<ReportSnapshot> load(ReportFilter filter);
  Future<String> today();
}
