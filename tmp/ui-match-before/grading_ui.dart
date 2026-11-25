import 'package:flutter/material.dart';

import 'cycle_rules.dart';
import 'design_system.dart';
import 'feed_repository.dart';
import 'feed_ui.dart' show RecoveryPage;
import 'grading.dart';
import 'master_data.dart';
import 'ui_format.dart';

Future<String?> pickGradingDate(
  BuildContext context,
  String today,
  String initial,
) async {
  final first = DateTime.parse(gradingDateAfter(today, 1));
  final current = DateTime.parse(initial);
  final picked = await showDatePicker(
    context: context,
    initialDate: current.isBefore(first) ? first : current,
    firstDate: first,
    lastDate: DateTime(9999, 12, 31),
    helpText: 'Rencana grading berikutnya',
  );
  if (picked == null) return null;
  return '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
}

class GradingPlanPanel extends StatefulWidget {
  const GradingPlanPanel({
    super.key,
    required this.repo,
    required this.view,
    required this.onSaved,
  });
  final FeedRepository repo;
  final CycleView view;
  final VoidCallback onSaved;
  @override
  State<GradingPlanPanel> createState() => _GradingPlanPanelState();
}

class _GradingPlanPanelState extends State<GradingPlanPanel> {
  late Future<Map<String, Object?>> _load;
  bool _busy = false, _unknown = false;
  String? _error;
  Future<Map<String, Object?>> _read() async =>
      (await widget.repo.master.database()).transaction((db) async {
        final plan = await gradingPlanIn(db, widget.view.id);
        final last = await db.rawQuery(
          '''SELECT o.business_date,o.after_weight_cg,g.ordinal
      FROM operations o JOIN grading_records g ON g.operation_id=o.id
      WHERE o.cycle_id=? AND o.kind='sampling' AND o.cancel_action_id IS NULL
      ORDER BY o.seq DESC LIMIT 1''',
          [widget.view.id],
        );
        return {'plan': plan, 'last': last.isEmpty ? null : last.single};
      });
  @override
  void initState() {
    super.initState();
    _load = _read();
  }

  @override
  void didUpdateWidget(GradingPlanPanel old) {
    super.didUpdateWidget(old);
    _load = _read();
  }

  Future<void> _edit(Map<String, Object?>? plan) async {
    if (_busy || _unknown) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? id;
    try {
      final date = await pickGradingDate(
        context,
        widget.view.date,
        plan?['next_date'] as String? ?? gradingDateAfter(widget.view.date),
      );
      if (date == null || !mounted) return;
      final yes = await reviewAction(
        context,
        title: 'Konfirmasi rencana grading',
        summary:
            'Rencana berikutnya ${uiDate(date)}. Tanggal ini dapat diubah dan tidak membatasi pemberian pakan.',
        backLabel: 'Kembali',
      );
      if (yes != true || !mounted) return;
      id = newMasterId();
      await widget.repo.run(id, 'grading_plan', {
        'cycle': widget.view.id,
        'date': widget.view.date,
        'next_date': date,
        'expected_revision': plan?['revision'] ?? 0,
      });
      if (mounted) {
        setState(() => _load = _read());
        widget.onSaved();
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _unknown = id != null && e is! ValidationFailure;
          _error = e is ValidationFailure ? e.message : 'Hasil belum pasti. Periksa Pemulihan tindakan sebelum mengulang.';
          _load = _read();
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, Object?>>(
    future: _load,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const LinearProgressIndicator();
      if (snapshot.hasError)
        return TextButton(
          onPressed: () => setState(() => _load = _read()),
          child: const Text('Rencana grading gagal dimuat — coba lagi'),
        );
      final plan = snapshot.data!['plan'] as Map<String, Object?>?;
      final last = snapshot.data!['last'] as Map<String, Object?>?;
      final next = plan?['next_date'] as String?;
      final overdue = next != null && next.compareTo(widget.view.date) < 0;
      return FishCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('Grading dan rencana berikutnya'),
            Text(
              last == null
                  ? 'Belum ada grading. Bobot awal ${uiDecimal(widget.view.weightCg)} g/ikan digunakan.'
                  : 'Grading ${last['ordinal']} terakhir: ${uiDate(last['business_date'] as String)} · ${uiDecimal(last['after_weight_cg'] as int)} g/ikan',
            ),
            if (next != null)
              Text('Rencana berikutnya: ${uiDate(next)}')
            else
              const Text(
                'Belum ada tanggal rencana. Anda dapat mengaturnya sesuai kesibukan.',
              ),
            if (overdue)
              const Notice(
                'Rencana grading sudah terlewat. Bobot terakhir tetap digunakan; pemberian pakan tetap tersedia.',
                warning: true,
              ),
            const Text(
              'Grading hanya mencatat bobot, tanpa mengurangi populasi. Waktunya fleksibel.',
            ),
            if (_error != null) Notice(_error!, warning: true),
            if (_busy) const LinearProgressIndicator(),
            OutlinedButton(
              onPressed: _busy || _unknown ? null : () => _edit(plan),
              child: Text(
                next == null ? 'Atur rencana grading' : 'Ubah tanggal rencana',
              ),
            ),
            if (_unknown)
              OutlinedButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => RecoveryPage(repo: widget.repo),
                    ),
                  );
                  if (mounted)
                    setState(() {
                      _unknown = false;
                      _load = _read();
                    });
                },
                child: const Text('Pemulihan tindakan'),
              ),
          ],
        ),
      );
    },
  );
}
