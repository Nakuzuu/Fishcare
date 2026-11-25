import 'package:flutter/material.dart';

import 'design_system.dart';
import 'activity_ui.dart';

import 'cycle_rules.dart';
import 'feed_repository.dart';
import 'feed_ui.dart';
import 'master_data.dart';
import 'grading.dart';
import 'grading_ui.dart';
import 'ui_format.dart';
import 'report_rules.dart';

class LifecyclePanel extends StatefulWidget {
  const LifecyclePanel({
    super.key,
    required this.repo,
    required this.pondId,
    this.view,
    required this.onSaved,
  });
  final FeedRepository repo;
  final String pondId;
  final CycleView? view;
  final VoidCallback onSaved;
  @override
  State<LifecyclePanel> createState() => _LifecyclePanelState();
}

class _LifecyclePanelState extends State<LifecyclePanel> {
  late Future<List<Map<String, Object?>>> _rows;
  void _reload() {
    _rows = widget.repo.master.database().then(
      (db) => db.transaction(
        (txn) async => withHarvestFeedResults(
          await txn.rawQuery(
            'SELECT o.*,g.ordinal AS grading_number,c.start_date AS cycle_start,c.fish AS cycle_fish,f.price_snapshot,f.cost_snapshot,f.planned_snapshot_g,f.policy_version,f.water_temperature_deci_c,f.water_ph_hundredths,f.water_recorded_at_ms,f.recommendation_status,f.recommended_g,f.temperature_percent,f.recommendation_reason FROM operations o JOIN cycles c ON c.id=o.cycle_id LEFT JOIN feedings f ON f.id=o.id LEFT JOIN grading_records g ON g.operation_id=o.id WHERE c.pond_id=? ORDER BY o.seq DESC',
            [widget.pondId],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(LifecyclePanel old) {
    super.didUpdateWidget(old);
    _reload();
  }

  Future<void> _open(String kind, {Map<String, Object?>? operation}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LifecycleForm(
          repo: widget.repo,
          view: widget.view!,
          kind: kind,
          operation: operation,
        ),
      ),
    );
    if (mounted) {
      setState(_reload);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(),
      if (widget.view != null)
        GradingPlanPanel(
          repo: widget.repo,
          view: widget.view!,
          onSaved: widget.onSaved,
        ),
      if (widget.view != null) const SectionTitle('Kegiatan kolam'),
      if (widget.view != null)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final kind in ['sampling', 'death', 'partial', 'final'])
              OutlinedButton(
                onPressed: () => _open(kind),
                child: Text(actionLabel(kind)),
              ),
          ],
        ),
      const SectionTitle('Riwayat kegiatan dan siklus selesai'),
      FutureBuilder<List<Map<String, Object?>>>(
        future: _rows,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done)
            return const LinearProgressIndicator();
          if (s.hasError)
            return TextButton(
              onPressed: () => setState(_reload),
              child: const Text('Riwayat gagal — coba lagi'),
            );
          final rows = s.data!;
          if (rows.isEmpty)
            return const Text('Belum ada kegiatan operasional.');
          final valid = rows
              .where(
                (r) =>
                    r['cycle_id'] == widget.view?.id &&
                    r['cancel_action_id'] == null,
              )
              .toList();
          return Column(
            children: [
              for (final row in rows)
                ActivityCard(
                  row: row,
                  key: ValueKey('activity-${row['id']}'),
                  onCancel:
                      widget.view != null &&
                          valid.isNotEmpty &&
                          valid.first['id'] == row['id'] &&
                          row['business_date'] == widget.view!.date &&
                          !['final', 'close'].contains(row['kind'])
                      ? () => _open('cancel_operation', operation: row)
                      : null,
                ),
            ],
          );
        },
      ),
    ],
  );
}

class LifecycleForm extends StatefulWidget {
  const LifecycleForm({
    super.key,
    required this.repo,
    required this.view,
    required this.kind,
    this.operation,
  });
  final FeedRepository repo;
  final CycleView view;
  final String kind;
  final Map<String, Object?>? operation;
  @override
  State<LifecycleForm> createState() => _LifecycleFormState();
}

class _LifecycleFormState extends State<LifecycleForm> {
  final _form = GlobalKey<FormState>();
  final _count = TextEditingController(),
      _weight = TextEditingController(),
      _price = TextEditingController(),
      _reason = TextEditingController();
  bool _busy = false, _unknown = false;
  String? _error;
  late String _nextDate;
  @override
  void initState() {
    super.initState();
    _nextDate = gradingDateAfter(widget.view.date);
  }

  @override
  void dispose() {
    for (final c in [_count, _weight, _price, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate(String? text, bool decimal) {
    try {
      if (decimal) {
        parseHundredths(text ?? '');
      } else {
        parseCount(text ?? '');
      }
      return null;
    } on ValidationFailure catch (e) {
      return e.message;
    }
  }

  Future<void> _save() async {
    if (_busy || _unknown || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? id;
    try {
      final p = <String, Object?>{
        'cycle': widget.view.id,
        'date': widget.view.date,
      };
      String kind = widget.kind;
      String summary;
      if (kind == 'cancel_operation') {
        p['reason'] = _reason.text.trim();
        final op = widget.operation!;
        if (op['kind'] == 'feeding') {
          kind = 'cancel';
          p['feeding'] = op['id'];
        } else {
          p['operation'] = op['id'];
        }
        summary =
            'Batalkan ${actionLabel(op['kind'] as String)}\nAlasan: ${p['reason']}\nKondisi dipulihkan dan porsi menunggu dihitung ulang. Riwayat tetap tersedia.';
      } else {
        final c = await widget.repo.cycles.cycleIn(
          await widget.repo.master.database(),
          widget.view.id,
        );
        final population = c['current_count'] as int;
        if (kind == 'final') {
          p['expected_count'] = population;
        } else {
          p['count'] = parseCount(_count.text);
        }
        if (kind == 'sampling' ||
            kind == 'partial' ||
            (kind == 'final' && population > 0)) {
          p['weight'] = parseHundredths(_weight.text);
        }
        if (kind == 'partial' || (kind == 'final' && population > 0)) {
          p['price'] = parseCount(_price.text);
        }
        summary =
            '${actionLabel(kind)}\nPopulasi terkini $population ekor\nJumlah ${kind == 'final' ? population : p['count']} ekor';
        if (p['weight'] != null)
          summary += '\nBobot ${decimalText(p['weight'] as int)} g/ikan';
        if (p['price'] != null) {
          final quantity = kind == 'final' ? population : p['count'] as int;
          final biomassCg = checkedInteger(
            BigInt.from(quantity) * BigInt.from(p['weight'] as int),
          );
          summary +=
              '\nBiomassa panen ${decimalText(biomassCg)} g\nHarga Rp${p['price']}/kg\nNilai Rp${harvestValue(quantity, p['weight'] as int, p['price'] as int)}';
        }
        if (kind == 'partial')
          summary +=
              '\nSisa setelah panen ${population - (p['count'] as int)} ekor';
        if (kind == 'sampling') {
          final plan = await gradingPlanIn(
            await widget.repo.master.database(),
            widget.view.id,
          );
          p['expected_plan_revision'] = plan?['revision'] ?? 0;
          p['next_date'] = validGradingPlan(_nextDate, widget.view.date);
          summary +=
              '\nGrading tidak mengurangi populasi.\nRencana berikutnya ${uiDate(_nextDate)} (dapat diubah).';
        }
        if (kind == 'final')
          summary += population == 0 ? '\nTutup tanpa panen atau pendapatan.' : '\nSeluruh sisa dipanen. Siklus selesai tidak dapat dibatalkan.';
      }
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      final yes = await reviewAction(
        context,
        title: 'Konfirmasi kegiatan',
        summary: summary,
        backLabel: 'Kembali',
      );
      if (yes != true || !mounted) return;
      id = newMasterId();
      await widget.repo.run(id, kind, p);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Kegiatan tersimpan.')));
        Navigator.pop(context);
      }
    } catch (e) {
      var unknown = e is! ValidationFailure;
      if (id != null) {
        try {
          final state = (await widget.repo.journal.inspect(id))['state'];
          unknown = state == 'prepared' || state == 'committed';
        } catch (_) {
          unknown = true;
        }
      }
      if (mounted)
        setState(() {
          _unknown = unknown;
          _error = unknown
              ? 'Hasil belum pasti. Periksa ID pada Pemulihan tindakan sebelum retry.'
              : e is ValidationFailure
              ? e.message
              : 'Pencatatan gagal. Periksa hasil tersimpan sebelum tindakan baru.';
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind,
        harvest = kind == 'partial' || kind == 'final',
        zeroFinal = kind == 'final' && widget.view.population == 0;
    return Scaffold(
      appBar: FishAppBar(title: Text(actionLabel(kind))),
      body: SafeArea(
        child: Form(
          key: _form,
          child: FormList(
            controllers: [_count, _weight, _price, _reason],
            busy: _busy,
            padding: const EdgeInsets.all(18),
            children: [
              Text(
                'Tanggal ${widget.view.date} · Populasi ${widget.view.population} ekor',
              ),
              if (kind == 'final')
                Text(
                  zeroFinal ? 'Tutup tanpa panen; tidak membuat pendapatan.' : 'Jumlah otomatis seluruh sisa. Populasi diverifikasi ulang sebelum commit.',
                ),
              if (kind == 'sampling' || kind == 'death' || kind == 'partial')
                TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                  controller: _count,
                  enabled: !_busy && !_unknown,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: kind == 'sampling' ? 'Jumlah sampel' : 'Jumlah',
                    suffixText: 'ekor',
                  ),
                  validator: (v) {
                    final error = _validate(v, false);
                    if (error != null) return error;
                    final count = parseCount(v!);
                    if (count > widget.view.population)
                      return 'Jumlah tidak boleh melebihi populasi.';
                    if (kind == 'partial' && count == widget.view.population)
                      return 'Panen parsial harus menyisakan ikan.';
                    return null;
                  },
                ),
              if (kind == 'sampling' || (harvest && !zeroFinal))
                TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                  controller: _weight,
                  enabled: !_busy && !_unknown,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: kind == 'sampling'
                        ? 'Bobot rata-rata sampel'
                        : 'Bobot rata-rata panen',
                    suffixText: 'g/ikan',
                    helperText: 'Positif; maksimal dua desimal',
                  ),
                  validator: (v) => _validate(v, true),
                ),
              if (harvest && !zeroFinal)
                TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                  controller: _price,
                  enabled: !_busy && !_unknown,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga jual',
                    suffixText: 'Rp/kg',
                  ),
                  validator: (v) => _validate(v, false),
                ),
              if (kind == 'sampling') ...[
                Text('Saran grading berikutnya: ${uiDate(_nextDate)}'),
                const Text(
                  'Awalnya 7 hari lagi; ubah sesuai kesibukan. Ini rencana, bukan batas wajib.',
                ),
                OutlinedButton(
                  onPressed: _busy || _unknown
                      ? null
                      : () async {
                          final date = await pickGradingDate(
                            context,
                            widget.view.date,
                            _nextDate,
                          );
                          if (date != null && mounted)
                            setState(() => _nextDate = date);
                        },
                  child: const Text('Ubah tanggal rencana'),
                ),
              ],
              if (kind == 'cancel_operation')
                TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                  controller: _reason,
                  enabled: !_busy && !_unknown,
                  decoration: const InputDecoration(
                    labelText: 'Alasan pembatalan',
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Alasan wajib' : null,
                ),
              if (_error != null) Notice(_error!, warning: true),
              if (_busy) const LinearProgressIndicator(),
              FilledButton(
                onPressed: _busy || _unknown ? null : _save,
                child: const Text('Tinjau dan simpan'),
              ),
              if (_unknown)
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => RecoveryPage(repo: widget.repo),
                    ),
                  ),
                  child: const Text('Pemulihan tindakan'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
