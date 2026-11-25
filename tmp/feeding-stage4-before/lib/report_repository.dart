import 'master_repository.dart';
import 'report_rules.dart';
import 'cycle_rules.dart';

class SqliteReportRepository implements ReportSource {
  SqliteReportRepository(this.master, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final SqliteMasterRepository master;
  final DateTime Function() clock;
  @override
  Future<String> today() async {
    final settings = await (await master.database()).query('business_settings');
    return businessDate(
      clock(),
      settings.isEmpty
          ? deviceBusinessZone() ?? 'UTC'
          : settings.single['zone'] as String,
    );
  }

  @override
  Future<ReportSnapshot> load(
    ReportFilter filter,
  ) async => (await master.database()).transaction((db) async {
    final ponds = await db.query(
      'ponds',
      columns: ['id', 'name', 'is_archived'],
      orderBy: 'name_key',
    );
    final pondWhere = filter.pondId == null ? '' : ' AND c.pond_id=?';
    final pondArgs = <Object?>[if (filter.pondId != null) filter.pondId];
    const select = '''SELECT o.*,c.pond_id,c.fish,p.name pond_name,p.is_archived pond_archived,
      f.actual_g,f.price_snapshot,f.cost_snapshot,f.rate_snapshot,f.weight_snapshot_cg,
      f.population_snapshot,f.biomass_snapshot_cg,f.feed_id,f.minute,
      g.ordinal AS grading_number
      FROM operations o JOIN cycles c ON c.id=o.cycle_id JOIN ponds p ON p.id=c.pond_id
      LEFT JOIN feedings f ON f.id=o.id
      LEFT JOIN grading_records g ON g.operation_id=o.id''';
    final rows = await db.rawQuery(
      '$select WHERE o.business_date>=? AND o.business_date<=?$pondWhere ORDER BY o.seq DESC',
      [filter.start, filter.end, ...pondArgs],
    );
    final whole = await db.rawQuery(
      '$select WHERE 1=1$pondWhere ORDER BY o.seq DESC',
      pondArgs,
    );
    final conditions = await db.rawQuery(
      '''SELECT c.*,p.name pond_name,p.is_archived pond_archived,
      (SELECT rate_bp FROM cycle_rates r WHERE r.cycle_id=c.id ORDER BY seq DESC LIMIT 1) rate_bp
      FROM cycles c JOIN ponds p ON p.id=c.pond_id WHERE 1=1$pondWhere ORDER BY c.created_at_ms DESC,c.id''',
      pondArgs,
    );
    final snapshot = ReportSnapshot(
      filter: filter,
      rows: rows,
      ponds: ponds,
      conditions: conditions,
      wholeRows: whole,
    );
    snapshot
        .totals; // Gagal snapshot/overflow sebelum menampilkan angka sebagian.
    for (final c in conditions) {
      snapshot.cycleTotals(c['id'] as String);
    }
    return snapshot;
  });
}
