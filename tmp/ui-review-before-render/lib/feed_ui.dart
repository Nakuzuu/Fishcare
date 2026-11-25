import 'dart:convert';

import 'package:flutter/material.dart';

import 'design_system.dart';

import 'cycle_rules.dart';
import 'feed_repository.dart';
import 'master_data.dart';

String movementLabel(String kind) =>
    const {
      'in': 'Stok masuk',
      'correction': 'Koreksi stok masuk',
      'out': 'Pemberian pakan',
      'reversal': 'Pembalikan pembatalan',
    }[kind] ??
    kind;
String actionLabel(String kind) =>
    const {
      'cycle_start': 'Mulai siklus',
      'cycle_rate': 'Ubah rate',
      'cycle_times': 'Ubah jam',
      'stock_in': 'Stok masuk',
      'stock_correct': 'Koreksi stok',
      'feeding': 'Pemberian pakan',
      'cancel': 'Pembatalan pemberian',
      'skip': 'Lewati slot',
      'sampling': 'Sampling',
      'death': 'Kematian',
      'partial': 'Panen parsial',
      'final': 'Panen akhir / tutup siklus',
      'close': 'Tutup tanpa panen',
      'cancel_operation': 'Pembatalan kegiatan',
    }[kind] ??
    kind;
String stateLabel(String state) =>
    const {
      'prepared': 'Niat tersimpan — hasil belum pasti',
      'committed': 'Telah tersimpan',
      'rejected': 'Ditolak',
      'abandoned': 'Niat ditutup tanpa commit',
    }[state] ??
    state;
String intentSummary(String raw) {
  try {
    final p = jsonDecode(raw) as Map;
    return [
      if (p['date'] != null) 'Tanggal: ${p['date']}',
      if (p['grams'] != null) 'Jumlah: ${p['grams']} g',
      if (p['old'] != null) 'Jumlah lama: ${p['old']} g → baru ${p['new']} g',
      if (p['minute'] != null) 'Jam: ${timeText(p['minute'] as int)}',
      if (p['fish'] != null) 'Jenis ikan: ${p['fish']}; jumlah ${p['count']}',
      if (p['rate'] != null) 'Rate: ${decimalText(p['rate'] as int)}%',
      if (p['reason'] != null) 'Alasan: ${p['reason']}',
      if (p['count'] != null) 'Jumlah: ${p['count']} ekor',
      if (p['expected_count'] != null)
        'Seluruh sisa ditinjau: ${p['expected_count']} ekor',
      if (p['weight'] != null)
        'Bobot: ${decimalText(p['weight'] as int)} g/ikan',
      if (p['times'] != null)
        'Jam: ${(p['times'] as List).cast<int>().map(timeText).join(', ')}',
    ].join('\n');
  } catch (_) {
    return 'Input belum dapat dibaca. Jangan mengulang otomatis.';
  }
}

class ActionForm extends StatefulWidget {
  const ActionForm({
    super.key,
    required this.repo,
    required this.kind,
    required this.base,
    required this.title,
  });
  final FeedRepository repo;
  final String kind, title;
  final Map<String, Object?> base;
  @override
  State<ActionForm> createState() => _ActionFormState();
}

class _ActionFormState extends State<ActionForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  late Future<String?> _zoneLoad;
  Future<Map<String, Object?>>? _preview;
  String? _zone, _error;
  bool _busy = false, _unknown = false;
  Future<Map<String, Object?>> _readPreview() async {
    if (widget.kind == 'feeding')
      return widget.repo.contextFor(
        widget.base['cycle'] as String,
        widget.base['date'] as String,
        widget.base['minute'] as int,
      );
    final feed = await widget.repo.master.get(
      MasterKind.feed,
      widget.base['feed'] as String,
    );
    return {
      'feed_name': feed.name,
      'stock': await widget.repo.balance(feed.id),
    };
  }

  @override
  void initState() {
    super.initState();
    _zone = deviceBusinessZone();
    _zoneLoad = widget.repo.cycles.lockedZone();
    if (widget.kind == 'feeding') _amount.text = '${widget.base['plan']}';
    if (widget.kind == 'stock_correct') _amount.text = '${widget.base['old']}';
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _unknown || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? id;
    try {
      final zone = await _zoneLoad ?? _zone;
      if (zone == null) throw const ValidationFailure('Pilih zona usaha.');
      final p = <String, Object?>{
        ...widget.base,
        'date': businessDate(widget.repo.cycles.clock(), zone),
      };
      final amount = parseGrams(
        _amount.text,
        zero: widget.kind == 'stock_correct',
      );
      if (widget.kind == 'stock_correct') {
        p['new'] = amount;
        p['reason'] = _reason.text.trim();
      } else
        p['grams'] = amount;
      String summary;
      if (widget.kind == 'feeding') {
        // Tanggal slot berasal dari layar, bukan ditulis ulang ke hari baru.
        p['date'] = widget.base['date'];
        final ctx = await widget.repo.contextFor(
          p['cycle'] as String,
          p['date'] as String,
          p['minute'] as int,
        );
        p['price'] = ctx['price'];
        p['rate'] = ctx['rate'];
        p['allow_excess'] = amount > (ctx['remaining'] as int);
        summary =
            '${ctx['feed_name']}\nAktual $amount g; stok ${ctx['stock']} g\nHarga Rp${ctx['price']}/kg\nBiaya Rp${feedingCost(amount, ctx['price'] as int)}\n${p['allow_excess'] == true ? 'PERHATIAN: aktual melebihi sisa kebutuhan.' : ''}';
      } else if (widget.kind == 'stock_correct')
        summary =
            'Koreksi masuk: ${p['old']} → $amount g\nSelisih ${amount - (p['old'] as int)} g\nAlasan: ${p['reason']}\nCatatan asal tetap tersedia.';
      else {
        p['zone'] = zone;
        summary =
            'Stok masuk $amount g\nTanggal ${p['date']} ($zone)\nSaldo bertambah melalui pergerakan stok.';
      }
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      final yes = await reviewAction(
        context,
        title: 'Konfirmasi pencatatan',
        summary: summary,
        backLabel: 'Kembali mengubah',
      );
      if (yes != true || !mounted) return;
      id = newMasterId(); // Niat baru hanya setelah pengguna mengonfirmasi.
      await widget.repo.run(id, widget.kind, p);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Tersimpan.')));
        Navigator.pop(context);
      }
    } catch (error, stack) {
      debugPrint('M3 action: $error\n$stack');
      var unknown = error is! ValidationFailure;
      if (id != null) {
        try {
          final intent = await widget.repo.journal.inspect(id);
          unknown = intent['state'] == 'prepared';
        } catch (_) {
          unknown = true;
        }
      }
      if (mounted)
        setState(() {
          _unknown = unknown;
          _error = error is ValidationFailure ? error.message : 'Hasil belum pasti. Buka Pemulihan tindakan dan periksa ID yang tersimpan sebelum retry.';
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FishAppBar(title: Text(widget.title)),
    body: SafeArea(
      child: FutureBuilder<String?>(
        future: _zoneLoad,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return const Center(
              child: Text('Pengaturan gagal dimuat. Kembali dan coba lagi.'),
            );
          return Form(
            key: _form,
            child: FormList(
              controllers: [_amount, _reason],
              busy: _busy,
              padding: const EdgeInsets.all(18),
              children: [
                FutureBuilder<Map<String, Object?>>(
                  future: _preview ??= _readPreview(),
                  builder: (context, preview) {
                    if (preview.hasError)
                      return Column(
                        children: [
                          const Notice(
                            'Rincian pakan belum dapat dimuat. Nilai akan diperiksa kembali saat meninjau.',
                            warning: true,
                          ),
                          TextButton(
                            onPressed: () => setState(() => _preview = null),
                            child: const Text('Muat ulang rincian'),
                          ),
                        ],
                      );
                    if (!preview.hasData)
                      return const LinearProgressIndicator();
                    final values = preview.data!;
                    return FishCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${values['feed_name']}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          ValueRow(
                            'Stok bersama saat dibuka',
                            '${values['stock']} g',
                          ),
                          if (widget.kind == 'feeding') ...[
                            ValueRow(
                              'Sisa kebutuhan',
                              '${values['remaining']} g',
                            ),
                            ValueRow(
                              'Harga tercatat',
                              'Rp${values['price']}/kg',
                            ),
                            Text(
                              'Slot ${timeText(widget.base['minute'] as int)} · ${widget.base['date']}',
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                if (widget.kind == 'stock_in' && snapshot.data == null)
                  DropdownButtonFormField<String>(
                    initialValue: _zone,
                    items: [
                      for (final zone in businessZones.keys)
                        DropdownMenuItem(value: zone, child: Text(zone)),
                    ],
                    onChanged: _busy ? null : (v) => setState(() => _zone = v),
                    decoration: const InputDecoration(
                      labelText: 'Zona usaha (dikunci setelah simpan)',
                    ),
                    validator: (v) => v == null ? 'Pilih zona usaha.' : null,
                  ),
                if (widget.kind == 'stock_correct')
                  Text(
                    'Jumlah efektif lama ${widget.base['old']} g; jumlah baru boleh nol.',
                  ),
                TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                  controller: _amount,
                  enabled: !_busy && !_unknown,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.kind == 'stock_correct'
                        ? 'Jumlah baru'
                        : 'Aktual/jumlah masuk',
                    suffixText: 'g',
                    helperText: 'Gram bulat tanpa pemisah ribuan: 1500',
                  ),
                  validator: (v) {
                    try {
                      parseGrams(v ?? '', zero: widget.kind == 'stock_correct');
                      return null;
                    } on ValidationFailure catch (e) {
                      return e.message;
                    }
                  },
                ),
                if (widget.kind == 'stock_correct')
                  TextFormField(
                    scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                    controller: _reason,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Alasan koreksi *',
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Alasan wajib diisi.' : null,
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
          );
        },
      ),
    ),
  );
}

class StockPanel extends StatefulWidget {
  const StockPanel({super.key, required this.feed, required this.repo});
  final MasterRecord feed;
  final FeedRepository repo;
  @override
  State<StockPanel> createState() => _StockPanelState();
}

class _StockPanelState extends State<StockPanel> {
  late Future<Map<String, Object?>> _view;
  void _reload() {
    _view = _read();
  }

  Future<Map<String, Object?>> _read() async => {
    'stock': await widget.repo.balance(widget.feed.id),
    'rows': await widget.repo.movements(widget.feed.id),
  };
  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(StockPanel old) {
    super.didUpdateWidget(old);
    _reload();
  }

  Future<void> _open({Map<String, Object?>? movement}) async {
    try {
      final base = <String, Object?>{'feed': widget.feed.id};
      if (movement != null) {
        base['source'] = movement['id'];
        base['old'] = await widget.repo.effective(movement['id'] as String);
      }
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ActionForm(
            repo: widget.repo,
            kind: movement == null ? 'stock_in' : 'stock_correct',
            base: base,
            title: movement == null ? 'Stok masuk' : 'Koreksi stok masuk',
          ),
        ),
      );
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok gagal dibaca. Muat ulang.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, Object?>>(
    future: _view,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const LinearProgressIndicator();
      if (snapshot.hasError)
        return Column(
          children: [
            const Text('Saldo gagal dibaca; bukan stok nol.'),
            TextButton(
              onPressed: () => setState(_reload),
              child: const Text('Coba lagi'),
            ),
          ],
        );
      final view = snapshot.data!,
          rows = view['rows'] as List<Map<String, Object?>>;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text('Stok bersama: ${view['stock']} g'),
          if (!widget.feed.archived)
            FilledButton(
              onPressed: () => _open(),
              child: const Text('Stok masuk'),
            ),
          const Text('Riwayat pergerakan stok'),
          if (rows.isEmpty) const Text('Belum ada pergerakan stok.'),
          for (final row in rows)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${row['business_date']} · ${movementLabel(row['kind'] as String)} · ${row['delta_g']} g',
                    ),
                    if (row['kind'] == 'in')
                      TextButton(
                        onPressed: () => _open(movement: row),
                        child: const Text('Tinjau/koreksi jumlah masuk'),
                      ),
                    if (row['kind'] == 'correction')
                      FutureBuilder<List<Map<String, Object?>>>(
                        future: widget.repo.master.database().then(
                          (db) => db.query(
                            'stock_corrections',
                            where: 'id=?',
                            whereArgs: [row['id']],
                          ),
                        ),
                        builder: (context, data) => data.hasData
                            ? Text(
                                '${data.data!.single['old_g']} → ${data.data!.single['new_g']} g; ${data.data!.single['reason']}',
                              )
                            : const Text('Memuat rincian koreksi…'),
                      ),
                  ],
                ),
              ),
            ),
          TextButton(
            onPressed: () => setState(_reload),
            child: const Text('Muat ulang stok'),
          ),
        ],
      );
    },
  );
}

class FeedingControls extends StatefulWidget {
  const FeedingControls({
    super.key,
    required this.view,
    required this.repo,
    required this.onSaved,
  });
  final CycleView view;
  final FeedRepository repo;
  final VoidCallback onSaved;
  @override
  State<FeedingControls> createState() => _FeedingControlsState();
}

class _FeedingControlsState extends State<FeedingControls> {
  late Future<List<Map<String, Object?>>> _history;
  bool _busy = false;
  bool _unknown = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(FeedingControls old) {
    super.didUpdateWidget(old);
    _reload();
  }

  void _reload() {
    _history = widget.repo.history(widget.view.id);
  }

  Future<void> _give(int index) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ActionForm(
          repo: widget.repo,
          kind: 'feeding',
          base: {
            'cycle': widget.view.id,
            'date': widget.view.date,
            'minute': widget.view.times[index],
            'plan': widget.view.portions[index],
          },
          title: 'Pemberian ${timeText(widget.view.times[index])}',
        ),
      ),
    );
    if (mounted) {
      setState(_reload);
      widget.onSaved();
    }
  }

  Future<void> _simple(String kind, Map<String, Object?> payload) async {
    if (_busy || _unknown) return;
    setState(() => _busy = true);
    final reason = TextEditingController();
    String? actionId;
    try {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            kind == 'cancel' ? 'Batalkan pemberian terakhir?' : 'Lewati slot?',
          ),
          content: kind == 'cancel'
              ? TextField(
                  controller: reason,
                  decoration: const InputDecoration(labelText: 'Alasan wajib'),
                )
              : const Text(
                  'Tidak mengurangi stok. Sisa dibagi ulang ke slot menunggu.',
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Kembali'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Konfirmasi'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
      if (kind == 'cancel') payload['reason'] = reason.text.trim();
      payload['date'] = widget.view.date;
      actionId = newMasterId();
      await widget.repo.run(actionId, kind, payload);
      if (mounted) {
        setState(_reload);
        widget.onSaved();
      }
    } catch (e) {
      var unknown = e is! ValidationFailure;
      if (actionId != null) {
        try {
          unknown =
              (await widget.repo.journal.inspect(actionId))['state'] ==
              'prepared';
        } catch (_) {
          unknown = true;
        }
      }
      if (mounted) setState(() => _unknown = unknown);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ValidationFailure
                  ? e.message
                  : 'Hasil belum pasti. Buka Pemulihan tindakan sebelum retry.',
            ),
          ),
        );
    } finally {
      reason.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < widget.view.times.length; i++)
        if (widget.view.statuses[i] != 'pending')
          FishCard(
            key: ValueKey('slot-${widget.view.id}-${widget.view.times[i]}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeText(widget.view.times[i]),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                StatusBadge(
                  widget.view.statuses[i] == 'given' ? 'Diberikan' : 'Dilewati',
                  warning: widget.view.statuses[i] != 'given',
                ),
                const Text(
                  'Rincian aktual dan snapshot ada di riwayat pemberian.',
                ),
              ],
            ),
          )
        else if (widget.view.statuses[i] == 'pending')
          FishCard(
            key: ValueKey('slot-${widget.view.id}-${widget.view.times[i]}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueRow(
                  timeText(widget.view.times[i]),
                  '${widget.view.portions[i]} g',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    widget.view.portions[i] == 0
                        ? 'Tidak ada sisa kebutuhan'
                        : 'Menunggu',
                    warning: true,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed:
                          _busy || _unknown || widget.view.portions[i] == 0
                          ? null
                          : () => _give(i),
                      child: Text('Berikan ${timeText(widget.view.times[i])}'),
                    ),
                    OutlinedButton(
                      onPressed: _busy || _unknown
                          ? null
                          : () => _simple('skip', {
                              'cycle': widget.view.id,
                              'minute': widget.view.times[i],
                            }),
                      child: Text('Lewati ${timeText(widget.view.times[i])}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      const SectionTitle('Riwayat pemberian (batal tetap tersedia)'),
      if (_unknown)
        OutlinedButton(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => RecoveryPage(repo: widget.repo)),
          ),
          child: const Text('Periksa hasil sebelum mengulang'),
        ),
      FutureBuilder<List<Map<String, Object?>>>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const LinearProgressIndicator();
          if (snapshot.hasError)
            return TextButton(
              onPressed: () => setState(_reload),
              child: const Text('Riwayat gagal — coba lagi'),
            );
          final rows = snapshot.data!,
              valid = rows.where((r) => r['cancel_action_id'] == null).toList();
          if (rows.isEmpty) return const Text('Belum ada pemberian.');
          return Column(
            children: [
              for (final row in rows)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row['business_date']} ${timeText(row['minute'] as int)} · ${row['actual_g']} g · ${row['cancel_action_id'] == null ? 'Sah' : 'Batal'}',
                        ),
                        Text(
                          'Harga Rp${row['price_snapshot']}/kg · Biaya Rp${row['cost_snapshot']}',
                        ),
                        Text(
                          'Rate ${decimalText(row['rate_snapshot'] as int)}% · Biomassa ${decimalText(row['biomass_snapshot_cg'] as int)} g',
                        ),
                        if (row['cancel_action_id'] != null)
                          Text('Alasan batal: ${row['cancel_reason']}'),
                        if (valid.isNotEmpty &&
                            row['is_last_operation'] == 1 &&
                            valid.first['id'] == row['id'] &&
                            row['business_date'] == widget.view.date)
                          OutlinedButton(
                            onPressed: _busy || _unknown
                                ? null
                                : () =>
                                      _simple('cancel', {'feeding': row['id']}),
                            child: const Text('Batalkan pemberian terakhir'),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key, required this.repo});
  final FeedRepository repo;
  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  late Future<List<Map<String, Object?>>> _rows;
  final _checked = <String>{};
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _rows = widget.repo.journal.outstanding();
  }

  Future<void> _act(String id, String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final latest = await widget.repo.journal.inspect(id);
      if (action == 'inspect') {
        _checked.add(id);
      } else if (action == 'retry') {
        if (!_checked.contains(id))
          throw const ValidationFailure(
            'Periksa hasil memakai ID yang sama sebelum retry.',
          );
        if (latest['state'] == 'prepared') await widget.repo.resume(id);
      } else if (action == 'abandon')
        await widget.repo.journal.abandon(id);
      else
        await widget.repo.journal.acknowledge(id);
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ValidationFailure ? e.message : 'Pemeriksaan/tindakan gagal. ID tetap tersimpan; tidak membuat ID baru.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FishAppBar(title: const Text('Pemulihan tindakan')),
    body: SafeArea(
      child: FutureBuilder<List<Map<String, Object?>>>(
        future: _rows,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: TextButton(
                onPressed: () => setState(_reload),
                child: const Text('Gagal membaca niat — coba lagi'),
              ),
            );
          final rows = snapshot.data!;
          if (rows.isEmpty)
            return const Center(
              child: Text('Tidak ada tindakan yang perlu ditinjau.'),
            );
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Notice(
                'Tidak ada retry otomatis. Hasil commit diperiksa menggunakan ID tersimpan, bukan ID baru.',
                warning: true,
              ),
              for (final row in rows)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${actionLabel(row['kind'] as String)} · ${stateLabel(row['state'] as String)}',
                        ),
                        SelectableText('ID: ${row['id']}'),
                        Text(intentSummary(row['payload'] as String)),
                        if (row['error'] != null) Text('${row['error']}'),
                        if (row['state'] == 'prepared')
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () =>
                                          _act(row['id'] as String, 'inspect'),
                                child: const Text('Periksa hasil'),
                              ),
                              FilledButton(
                                onPressed:
                                    _busy || !_checked.contains(row['id'])
                                    ? null
                                    : () => _act(row['id'] as String, 'retry'),
                                child: const Text('Retry ID yang sama'),
                              ),
                              TextButton(
                                onPressed:
                                    _busy || !_checked.contains(row['id'])
                                    ? null
                                    : () =>
                                          _act(row['id'] as String, 'abandon'),
                                child: const Text('Tutup niat belum commit'),
                              ),
                            ],
                          ),
                        if (row['state'] != 'prepared')
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _act(row['id'] as String, 'ack'),
                            child: Text(
                              row['state'] == 'committed'
                                  ? 'Sudah tersimpan — tutup hasil'
                                  : 'Tutup hasil ditolak',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class RecoveryBanner extends StatelessWidget {
  const RecoveryBanner({super.key, required this.repo});
  final FeedRepository repo;
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, Object?>>>(
        future: repo.journal.outstanding(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Text(
              'Status tindakan belum dapat dibaca. Buka Pemulihan tindakan.',
            );
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const SizedBox.shrink();
          return ListTile(
            title: Text('${snapshot.data!.length} hasil/niat perlu ditinjau'),
            subtitle: const Text('Periksa sebelum mengulang pencatatan.'),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => RecoveryPage(repo: repo)),
            ),
          );
        },
      );
}
