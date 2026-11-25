import 'dart:async';

import 'package:flutter/material.dart';

import 'design_system.dart';
import 'ui_format.dart';

import 'report_rules.dart';
import 'report_controller.dart';
import 'cycle_rules.dart';
import 'master_data.dart';
import 'feed_ui.dart';
import 'grading.dart';

String filterLabel(ReportFilter f, List<Map<String, Object?>> ponds) {
  final matching = ponds.where((p) => p['id'] == f.pondId);
  final pond = f.pondId == null
      ? 'Semua kolam (termasuk arsip)'
      : matching.isEmpty
      ? 'Kolam ${f.pondId}'
      : '${matching.single['name']}${matching.single['is_archived'] == 1 ? ' (arsip)' : ''}';
  return '${f.start} s.d. ${f.end} (inklusif) · $pond';
}

class ReportPage extends StatefulWidget {
  const ReportPage({
    super.key,
    required this.source,
    this.home = false,
    this.embedded = false,
    this.top,
    this.initialFilter,
    this.onFilterChanged,
  });
  final ReportSource source;
  final bool home;
  final bool embedded;
  final Widget? top;
  final ReportFilter? initialFilter;
  final ValueChanged<ReportFilter>? onFilterChanged;
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> with WidgetsBindingObserver {
  final _start = TextEditingController(), _end = TextEditingController();
  ReportController? _controller;
  String? _pond, _inputError;
  Object? _initialError;
  Timer? _timer;
  int _initialRequest = 0;
  List<Map<String, Object?>> _ponds = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
    if (widget.home)
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refreshDay());
  }

  Future<void> _initialize() async {
    final request = ++_initialRequest;
    try {
      final today = await widget.source.today();
      if (!mounted || request != _initialRequest) return;
      final filter =
          widget.initialFilter ??
          ReportFilter(
            widget.home ? today : '${today.substring(0, 7)}-01',
            today,
          );
      _start.text = filter.start;
      _end.text = filter.end;
      _pond = filter.pondId;
      _controller?.dispose();
      _controller = ReportController(
        widget.source,
        filter,
        onChanged: () {
          if (mounted) {
            setState(() {
              if (_controller?.snapshot != null)
                _ponds = _controller!.snapshot!.ponds;
            });
          }
        },
      );
      setState(() => _initialError = null);
      await _controller!.load();
    } catch (e) {
      if (mounted && request == _initialRequest)
        setState(() => _initialError = e);
    }
  }

  Future<void> _refreshDay() async {
    if (!mounted || _controller == null) return;
    try {
      final today = await widget.source.today();
      if (mounted && today != _controller!.filter.end)
        await _controller!.load(ReportFilter(today, today));
    } catch (e) {
      if (mounted) setState(() => _initialError = e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.home) {
        unawaited(_refreshDay());
      }
      unawaited(_controller?.load());
    }
  }

  @override
  void dispose() {
    _initialRequest++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  void _apply() {
    try {
      final filter = ReportFilter(
        _start.text.trim(),
        _end.text.trim(),
        pondId: _pond,
      );
      setState(() => _inputError = null);
      widget.onFilterChanged?.call(filter);
      unawaited(_controller!.load(filter));
    } on ValidationFailure catch (e) {
      setState(() => _inputError = e.message);
    }
  }

  Future<void> _pick(TextEditingController field) async {
    final candidate = DateTime.tryParse(field.text);
    final date = await showDatePicker(
      context: context,
      initialDate:
          candidate != null && candidate.year >= 1 && candidate.year <= 9999
          ? candidate
          : DateTime.now(),
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (mounted && date != null) {
      field.text =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _apply();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return ListView(
      primary: false,
      shrinkWrap: widget.embedded,
      physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
      padding: widget.embedded ? EdgeInsets.zero : const EdgeInsets.all(18),
      children: [
        if (widget.top != null) widget.top!,
        if (widget.home) const SectionTitle('Beranda — transaksi hari ini'),
        if (_initialError != null) ...[
          const Text('Pengaturan laporan gagal dimuat.'),
          TextButton(onPressed: _initialize, child: const Text('Coba lagi')),
        ] else if (c == null)
          const LinearProgressIndicator()
        else ...[
          if (!widget.home) ...[
            FishCard(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: 12),
                title: const Text('Periode laporan'),
                subtitle: Text(filterLabel(c.filter, _ponds)),
                trailing: const Icon(Icons.tune),
                children: [
                  for (final entry in [
                    ('Tanggal mulai', _start),
                    ('Tanggal akhir', _end),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: TextField(
                        controller: entry.$2,
                        decoration: InputDecoration(
                          labelText: entry.$1,
                          helperText: 'YYYY-MM-DD, inklusif',
                          suffixIcon: IconButton(
                            onPressed: () => _pick(entry.$2),
                            icon: const Icon(Icons.calendar_month),
                          ),
                        ),
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_pond),
                    initialValue: _pond ?? '',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Kolam'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Semua kolam (termasuk arsip)'),
                      ),
                      if (_pond != null && !_ponds.any((p) => p['id'] == _pond))
                        DropdownMenuItem(
                          value: _pond,
                          child: const Text('Kolam terpilih (memuat)'),
                        ),
                      for (final p in _ponds)
                        DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text(
                            '${p['name']}${p['is_archived'] == 1 ? ' (arsip)' : ''}',
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      _pond = v == '' ? null : v;
                      _apply();
                    },
                  ),
                  FilledButton(
                    onPressed: _apply,
                    child: const Text('Terapkan filter'),
                  ),
                  if (_inputError != null) Text(_inputError!),
                ],
              ),
            ),
          ],
          if (c.loading)
            const LinearProgressIndicator(key: Key('report-loading'))
          else if (c.error != null) ...[
            const Text('Laporan gagal dimuat; angka bukan nol.'),
            TextButton(
              onPressed: () => c.load(),
              child: const Text('Coba lagi'),
            ),
          ] else if (c.snapshot != null)
            ReportBody(
              snapshot: c.snapshot!,
              source: widget.source,
              home: widget.home,
            ),
        ],
      ],
    );
  }
}

class ReportBody extends StatelessWidget {
  const ReportBody({
    super.key,
    required this.snapshot,
    required this.source,
    this.home = false,
  });
  final ReportSnapshot snapshot;
  final ReportSource source;
  final bool home;
  void _support(BuildContext context, String? metric) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ReportTransactions(
            source: source,
            filter: snapshot.filter,
            metric: metric,
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final totals = snapshot.totals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Transaksi periode'),
        Text(
          filterLabel(snapshot.filter, snapshot.ponds),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (snapshot.rows.isEmpty)
          const Notice('Belum ada transaksi pada filter ini.'),
        if (snapshot.rows.isNotEmpty &&
            snapshot.rows.every((r) => r['cancel_action_id'] != null))
          const Notice(
            'Semua transaksi pada periode ini batal; total sah nol.',
          ),
        FishCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final metric in reportMetrics.entries) ...[
                InkWell(
                  onTap: () => _support(context, metric.key),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: metric.key == 'feed_g'
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                metric.value,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                reportValue(metric.key, totals[metric.key]!),
                                key: Key('total-${metric.key}'),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : ValueRow(
                            metric.value,
                            reportValue(metric.key, totals[metric.key]!),
                            valueKey: Key('total-${metric.key}'),
                          ),
                  ),
                ),
                if (metric.key != reportMetrics.keys.last)
                  const Divider(height: 1),
              ],
            ],
          ),
        ),
        Text(
          'Biaya berdasarkan snapshot harga tercatat. Transaksi batal tidak masuk total.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _support(context, null),
          child: const Text('Riwayat periode (termasuk batal)'),
        ),
        const SectionTitle('Kondisi saat ini'),
        Text(
          'Siklus aktif; mengikuti kolam terpilih, tidak dibatasi tanggal periode.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (!snapshot.conditions.any((c) => c['status'] == 'active'))
          const Notice('Tidak ada siklus aktif untuk kolam ini.'),
        for (final c in snapshot.conditions.where(
          (c) => c['status'] == 'active',
        ))
          FishCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${c['pond_name']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${c['fish']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                ValueRow(
                  'Populasi',
                  '${uiNumber(c['current_count'] as int)} ekor',
                ),
                ValueRow(
                  'Bobot rata-rata',
                  '${uiDecimal(c['current_weight_cg'] as int)} g/ikan',
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge('Siklus aktif'),
                ),
              ],
            ),
          ),
        if (!home) ...[
          const SectionTitle('Seluruh siklus'),
          Text(
            'Semua tanggal tiap siklus; mengikuti kolam terpilih, bukan total transaksi periode.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (snapshot.conditions.isEmpty)
            const Notice('Belum ada siklus pada kolam terpilih.'),
          for (final c in snapshot.conditions)
            ReportCycleCard(
              condition: c,
              totals: snapshot.cycleTotals(c['id'] as String),
            ),
        ],
      ],
    );
  }
}

String reportValue(String metric, int value) =>
    metric == 'feed_cost' || metric == 'harvest_value'
    ? uiMoney(value)
    : '${uiNumber(value)} ${metricUnit(metric)}';

class ReportCycleCard extends StatelessWidget {
  const ReportCycleCard({
    super.key,
    required this.condition,
    required this.totals,
  });
  final Map<String, Object?> condition;
  final Map<String, int> totals;
  @override
  Widget build(BuildContext context) {
    final c = condition;
    return FishCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${c['pond_name']}${c['pond_archived'] == 1 ? ' (arsip)' : ''}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${c['fish']} ? Mulai ${uiDate(c['start_date'] as String)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(
              c['status'] == 'active' ? 'Siklus aktif' : 'Siklus selesai',
            ),
          ),
          const SizedBox(height: 8),
          for (final metric in reportMetrics.entries)
            ValueRow(
              metric.value,
              reportValue(metric.key, totals[metric.key]!),
            ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: const FishAppBar(title: Text('Detail siklus')),
                  body: SafeArea(
                    child: FormList(
                      children: [
                        Text(
                          '${c['pond_name']}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        FishCard(
                          child: Column(
                            children: [
                              ValueRow('Jenis ikan', '${c['fish']}'),
                              ValueRow(
                                'Mulai siklus',
                                uiDate(c['start_date'] as String),
                              ),
                              ValueRow(
                                'Status',
                                c['status'] == 'active'
                                    ? 'Siklus aktif'
                                    : 'Siklus selesai',
                              ),
                              for (final metric in reportMetrics.entries)
                                ValueRow(
                                  metric.value,
                                  reportValue(metric.key, totals[metric.key]!),
                                ),
                            ],
                          ),
                        ),
                        const Notice(
                          'Seluruh siklus: semua tanggal, bukan total transaksi periode. Transaksi batal dikecualikan.',
                        ),
                        ExpansionTile(
                          title: const Text('Identitas siklus'),
                          children: [SelectableText('ID siklus ${c['id']}')],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('Detail siklus'),
          ),
        ],
      ),
    );
  }
}

class ReportTransactions extends StatefulWidget {
  const ReportTransactions({
    super.key,
    required this.source,
    required this.filter,
    this.metric,
    this.detailId,
  });
  final ReportSource source;
  final ReportFilter filter;
  final String? metric, detailId;
  @override
  State<ReportTransactions> createState() => _ReportTransactionsState();
}

class _ReportTransactionsState extends State<ReportTransactions> {
  late final ReportController _controller;
  @override
  void initState() {
    super.initState();
    _controller = ReportController(
      widget.source,
      widget.filter,
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _controller.snapshot;
    final rows =
        s?.rows
            .where(
              (r) =>
                  (widget.metric == null ||
                      supportsMetric(r, widget.metric!)) &&
                  (widget.detailId == null || r['id'] == widget.detailId),
            )
            .toList() ??
        [];
    return Scaffold(
      appBar: FishAppBar(
        title: Text(
          widget.detailId != null
              ? 'Detail transaksi'
              : widget.metric == null
              ? 'Riwayat periode'
              : reportMetrics[widget.metric]!,
        ),
      ),
      body: SafeArea(
        child: ListView(
          primary: false,
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              s == null
                  ? '${widget.filter.start} s.d. ${widget.filter.end} · Kolam ${widget.filter.pondId ?? 'semua'}'
                  : filterLabel(widget.filter, s.ponds),
            ),
            if (_controller.loading)
              const LinearProgressIndicator()
            else if (_controller.error != null) ...[
              const Text('Transaksi gagal dimuat.'),
              TextButton(
                onPressed: () => _controller.load(),
                child: const Text('Coba lagi'),
              ),
            ] else ...[
              if (rows.isEmpty)
                const Text('Belum ada transaksi pendukung pada filter ini.'),
              for (final r in rows)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r['business_date']} · ${r['pond_name']}${r['pond_archived'] == 1 ? ' (arsip)' : ''} · ${r['kind'] == 'sampling' ? gradingLabel(r) : actionLabel(r['kind'] as String)}',
                        ),
                        StatusBadge(
                          r['cancel_action_id'] == null
                              ? 'Sah'
                              : 'Batal — dikecualikan dari total',
                          key: ValueKey('status-${r['id']}'),
                          warning: r['cancel_action_id'] != null,
                        ),
                        Text(
                          'Jumlah ${r['quantity']} ${r['kind'] == 'feeding' ? 'g' : 'ekor'}',
                        ),
                        if (widget.detailId == null)
                          TextButton(
                            onPressed: () => Navigator.of(context).push<void>(
                              MaterialPageRoute(
                                builder: (_) => ReportTransactions(
                                  source: widget.source,
                                  filter: widget.filter,
                                  metric: widget.metric,
                                  detailId: r['id'] as String,
                                ),
                              ),
                            ),
                            child: const Text('Detail'),
                          ),
                        if (widget.detailId != null) ...[
                          SelectableText(
                            'ID ${r['id']} · Siklus ${r['cycle_id']}',
                          ),
                          Text(
                            'Populasi ${r['before_count']} → ${r['after_count']} ekor\nBobot ${decimalText(r['before_weight_cg'] as int)} → ${decimalText(r['after_weight_cg'] as int)} g/ikan',
                          ),
                          if (r['kind'] == 'feeding')
                            Text(
                              'Jam ${timeText(r['minute'] as int)} · Harga Rp${r['price_snapshot']}/kg\nBiaya snapshot Rp${r['cost_snapshot']}\nRate ${decimalText(r['rate_snapshot'] as int)}% · Biomassa ${decimalText(r['biomass_snapshot_cg'] as int)} g',
                            ),
                          if (r['kind'] == 'partial' || r['kind'] == 'final')
                            Text(
                              'Bobot panen ${decimalText(r['harvest_weight_cg'] as int)} g/ikan\nHarga Rp${r['price_rp_kg']}/kg · Nilai snapshot Rp${r['value_rp']}',
                            ),
                          if (r['cancel_reason'] != null)
                            Text('Alasan batal: ${r['cancel_reason']}'),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
