import 'dart:async';

import 'package:flutter/material.dart';

import 'design_system.dart';

import 'cycle_rules.dart';
import 'master_data.dart';
import 'feed_repository.dart';
import 'feed_ui.dart';
import 'lifecycle_ui.dart';

class ScheduleEditor extends StatelessWidget {
  const ScheduleEditor({
    super.key,
    required this.times,
    required this.onChanged,
    required this.enabled,
  });
  final List<int> times;
  final ValueChanged<List<int>> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Jam pemberian: pilih 1–6 jam unik'),
      Wrap(
        spacing: 8,
        children: [
          for (var i = 0; i < times.length; i++)
            InputChip(
              label: Text(timeText(times[i])),
              onDeleted: !enabled
                  ? null
                  : () => onChanged([...times]..removeAt(i)),
            ),
        ],
      ),
      OutlinedButton(
        onPressed: !enabled || times.length >= 6
            ? null
            : () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  ),
                );
                if (context.mounted && time != null)
                  onChanged([...times, time.hour * 60 + time.minute]);
              },
        child: const Text('Tambah jam'),
      ),
    ],
  );
}

class CyclePanel extends StatefulWidget {
  const CyclePanel({
    super.key,
    required this.pond,
    required this.masters,
    required this.repository,
    this.feeds,
  });
  final MasterRecord pond;
  final MasterRepository masters;
  final CycleRepository repository;
  final FeedRepository? feeds;
  @override
  State<CyclePanel> createState() => _CyclePanelState();
}

class _CyclePanelState extends State<CyclePanel> with WidgetsBindingObserver {
  late Future<CycleView?> _view;
  Timer? _dayTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  void _reload() {
    _view = widget.repository.active(widget.pond.id);
    _dayTimer?.cancel();
    _dayTimer = null;
  }

  void _scheduleDayChange(CycleView view) {
    if (_dayTimer != null) return;
    final local = DateTime.now().toUtc().add(
      Duration(minutes: businessZones[view.zone]!),
    );
    final midnight = DateTime.utc(local.year, local.month, local.day + 1);
    _dayTimer = Timer(
      midnight.difference(local) + const Duration(seconds: 1),
      () {
        if (mounted) setState(_reload);
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(_reload);
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _open(CycleView? view, {bool rate = false}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => view == null
            ? StartCycleForm(
                pond: widget.pond,
                masters: widget.masters,
                repository: widget.repository,
              )
            : ChangeCycleForm(
                view: view,
                repository: widget.repository,
                rate: rate,
              ),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CycleView?>(
    future: _view,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const Padding(
          padding: EdgeInsets.all(12),
          child: LinearProgressIndicator(),
        );
      if (snapshot.hasError)
        return Column(
          children: [
            const Text(
              'Siklus/kebutuhan belum dapat dimuat. Bukan kebutuhan nol.',
            ),
            TextButton(
              onPressed: () => setState(_reload),
              child: const Text('Coba lagi'),
            ),
          ],
        );
      final view = snapshot.data;
      if (view != null) _scheduleDayChange(view);
      if (view == null)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Belum ada siklus aktif.'),
            if (widget.feeds != null)
              LifecyclePanel(
                repo: widget.feeds!,
                pondId: widget.pond.id,
                onSaved: () => setState(_reload),
              ),
            FilledButton(
              onPressed: widget.pond.archived ? null : () => _open(null),
              child: const Text('Mulai siklus'),
            ),
            if (widget.pond.archived)
              const Text(
                'Kolam arsip: riwayat tetap tersedia, tidak dapat mulai siklus.',
              ),
          ],
        );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SectionTitle('Siklus aktif — kondisi saat ini'),
          Text('Jenis ikan: ${view.fish} · Tebar: ${view.startDate}'),
          FishCard(
            child: Column(
              children: [
                ValueRow('Populasi terkini', '${view.population} ekor'),
                ValueRow(
                  'Bobot rata-rata',
                  '${decimalText(view.weightCg)} g/ikan',
                ),
                ValueRow('Pakan', view.feedName),
                ValueRow(
                  'Feeding rate tersimpan',
                  '${decimalText(view.rateBp)}%',
                ),
              ],
            ),
          ),
          Text('Tanggal usaha: ${view.date} · ${view.zone}'),
          FishCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kebutuhan harian: ${view.need} g',
                  key: const Key('daily-need'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ValueRow('Sudah diberikan', '${view.actualToday} g'),
                ValueRow('Sisa kebutuhan', '${view.remaining} g'),
              ],
            ),
          ),
          if (view.excess > 0)
            Text(
              'Kelebihan aktual: ${view.excess} g; stok tidak dikembalikan otomatis.',
            ),
          if (view.statuses.isNotEmpty &&
              !view.statuses.contains('pending') &&
              view.remaining > 0)
            Text('Sisa belum diberikan: ${view.remaining} g'),
          const SectionTitle('Rencana hari ini'),
          for (var i = 0; i < view.times.length; i++)
            FishCard(
              child: Text(
                '${timeText(view.times[i])} — ${view.portions[i]} g · ${view.statuses.isNotEmpty && view.statuses[i] != 'pending'
                    ? view.statuses[i] == 'given'
                          ? 'Diberikan'
                          : 'Dilewati'
                    : view.portions[i] == 0
                    ? 'Tidak ada sisa kebutuhan'
                    : 'Menunggu'}',
              ),
            ),
          Text(
            'Jam berlaku besok ${nextDate(view.date)}: ${view.tomorrowTimes.map(timeText).join(', ')}',
          ),
          FilledButton.tonal(
            onPressed: () => _open(view, rate: true),
            child: const Text('Ubah rate sekarang'),
          ),
          OutlinedButton(
            onPressed: () => _open(view),
            child: const Text('Ubah jam untuk besok'),
          ),
          TextButton(
            onPressed: () => setState(_reload),
            child: const Text('Muat ulang kebutuhan'),
          ),
          if (widget.feeds != null)
            FeedingControls(
              view: view,
              repo: widget.feeds!,
              onSaved: () => setState(_reload),
            ),
          if (widget.feeds != null)
            LifecyclePanel(
              repo: widget.feeds!,
              pondId: widget.pond.id,
              view: view,
              onSaved: () => setState(_reload),
            ),
        ],
      );
    },
  );
}

class StartCycleForm extends StatefulWidget {
  const StartCycleForm({
    super.key,
    required this.pond,
    required this.masters,
    required this.repository,
  });
  final MasterRecord pond;
  final MasterRepository masters;
  final CycleRepository repository;
  @override
  State<StartCycleForm> createState() => _StartCycleFormState();
}

class _StartCycleFormState extends State<StartCycleForm> {
  final _form = GlobalKey<FormState>();
  final _fish = TextEditingController(),
      _count = TextEditingController(),
      _weight = TextEditingController(),
      _rate = TextEditingController();
  final _id = newMasterId();
  List<int> _times = [];
  String? _feedId, _zone, _error;
  bool _busy = false, _loading = true, _locked = false;
  List<MasterRecord> _feeds = [];
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feeds = await widget.masters.list(MasterKind.feed, archived: false);
      final zone = await widget.repository.lockedZone();
      if (mounted)
        setState(() {
          _feeds = feeds;
          _zone = zone ?? deviceBusinessZone();
          _locked = zone != null;
        });
    } catch (error, stack) {
      debugPrint('M2 start load: $error\n$stack');
      if (mounted)
        setState(() => _error = 'Pakan/pengaturan gagal dimuat. Coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _fish.dispose();
    _count.dispose();
    _weight.dispose();
    _rate.dispose();
    super.dispose();
  }

  String? _validate(String? value, int type) {
    try {
      switch (type) {
        case 0:
          normalizedName(value ?? '');
        case 1:
          parseCount(value ?? '');
        case 2:
          parseHundredths(value ?? '');
        case 3:
          parseHundredths(value ?? '', rate: true);
      }
      return null;
    } on ValidationFailure catch (error) {
      return error.message;
    }
  }

  Future<void> _start() async {
    if (_busy || !_form.currentState!.validate()) return;
    try {
      final hours = validTimes(_times);
      if (_feedId == null || _zone == null)
        throw const ValidationFailure('Pilih pakan dan zona usaha.');
      final draft = StartCycle(
        id: _id,
        pondId: widget.pond.id,
        feedId: _feedId!,
        fish: _fish.text,
        count: parseCount(_count.text),
        weightCg: parseHundredths(_weight.text),
        rateBp: parseHundredths(_rate.text, rate: true),
        times: hours,
        zone: _zone!,
        date: businessDate(DateTime.now(), _zone!),
      );
      final need = dailyNeed(
        population: draft.count,
        weightCg: draft.weightCg,
        rateBp: draft.rateBp,
      );
      FocusScope.of(context).unfocus();
      setState(() => _busy = true);
      final yes = await reviewAction(
        context,
        title: 'Konfirmasi siklus',
        confirmLabel: 'Mulai siklus',
        summary:
            '${widget.pond.name}\n${draft.fish}\n${draft.count} ikan ? ${decimalText(draft.weightCg)} g\nRate ${decimalText(draft.rateBp)}%\nKebutuhan $need g/hari\nJam ${hours.map(timeText).join(', ')}\nTanggal ${draft.date} (${draft.zone})\nData awal dan pakan dikunci setelah simpan.',
      );
      if (yes != true || !mounted) return;
      setState(() => _busy = true);
      await widget.repository.start(draft);
      if (mounted) Navigator.pop(context);
    } catch (error, stack) {
      debugPrint('M2 start: $error\n$stack');
      if (mounted)
        setState(
          () => _error = error is ValidationFailure ? error.message : 'Simpan belum berhasil dikonfirmasi. Kembali dan muat ulang detail sebelum mencoba lagi.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FishAppBar(title: Text('Mulai siklus ${widget.pond.name}')),
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: FormList(
                controllers: [_fish, _count, _weight, _rate],
                busy: _busy,
                additionalDirty: () => _times.isNotEmpty || _feedId != null,
                padding: const EdgeInsets.all(18),
                children: [
                  if (_error != null) Notice(_error!, warning: true),
                  if (_feeds.isEmpty) ...[
                    const Text(
                      'Belum ada pakan aktif. Buat master pakan terlebih dahulu.',
                    ),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Muat ulang pakan'),
                    ),
                  ],
                  TextFormField(
                    scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                    controller: _fish,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Jenis ikan *',
                    ),
                    validator: (v) => _validate(v, 0),
                  ),
                  TextFormField(
                    scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                    controller: _count,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah awal *',
                      suffixText: 'ekor',
                    ),
                    validator: (v) => _validate(v, 1),
                  ),
                  TextFormField(
                    scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                    controller: _weight,
                    enabled: !_busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Bobot awal *',
                      suffixText: 'g/ikan',
                      helperText: 'Maksimal 2 desimal, contoh 12,5',
                    ),
                    validator: (v) => _validate(v, 2),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _feedId,
                    isExpanded: true,
                    items: [
                      for (final f in _feeds)
                        DropdownMenuItem(value: f.id, child: Text(f.name)),
                    ],
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _feedId = v),
                    decoration: const InputDecoration(labelText: 'Pakan *'),
                    validator: (v) => v == null ? 'Pilih pakan aktif.' : null,
                  ),
                  TextFormField(
                    scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                    controller: _rate,
                    enabled: !_busy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Feeding rate manual *',
                      suffixText: '%',
                      helperText: 'Gunakan acuan Anda/dosen; bukan rekomendasi aplikasi.',
                    ),
                    validator: (v) => _validate(v, 3),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _zone,
                    isExpanded: true,
                    items: [
                      for (final zone in businessZones.keys)
                        DropdownMenuItem(value: zone, child: Text(zone)),
                    ],
                    onChanged: _busy || _locked
                        ? null
                        : (v) => setState(() => _zone = v),
                    decoration: InputDecoration(
                      labelText: 'Zona waktu usaha',
                      helperText: _locked
                          ? 'Terkunci oleh siklus pertama.'
                          : 'Konfirmasi zona; dikunci setelah siklus pertama.',
                    ),
                    validator: (v) => v == null ? 'Pilih zona usaha.' : null,
                  ),
                  ScheduleEditor(
                    times: _times,
                    onChanged: (v) => setState(() => _times = v),
                    enabled: !_busy,
                  ),
                  if (_busy) const LinearProgressIndicator(),
                  FilledButton(
                    onPressed: _busy || _feeds.isEmpty ? null : _start,
                    child: const Text('Tinjau dan mulai siklus'),
                  ),
                ],
              ),
            ),
    ),
  );
}

class ChangeCycleForm extends StatefulWidget {
  const ChangeCycleForm({
    super.key,
    required this.view,
    required this.repository,
    required this.rate,
  });
  final CycleView view;
  final CycleRepository repository;
  final bool rate;
  @override
  State<ChangeCycleForm> createState() => _ChangeCycleFormState();
}

class _ChangeCycleFormState extends State<ChangeCycleForm> {
  late final TextEditingController _rate;
  late List<int> _times;
  final _operation = newMasterId();
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _rate = TextEditingController(text: decimalText(widget.view.rateBp));
    _times = [...widget.view.tomorrowTimes];
  }

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final newRate = widget.rate
          ? parseHundredths(_rate.text, rate: true)
          : null;
      final newTimes = widget.rate ? null : validTimes(_times);
      FocusScope.of(context).unfocus();
      final yes = await reviewAction(
        context,
        title: widget.rate ? 'Tinjau rate baru' : 'Tinjau jam besok',
        summary: widget.rate
            ? 'Rate ${decimalText(widget.view.rateBp)}% → ${decimalText(newRate!)}%\nBerlaku sekarang untuk porsi menunggu. Pemberian selesai tetap utuh.'
            : 'Hari ini ${widget.view.date}: ${widget.view.times.map(timeText).join(', ')} tetap.\nBerlaku besok ${nextDate(widget.view.date)}: ${newTimes!.map(timeText).join(', ')}',
      );
      if (yes != true || !mounted) return;
      if (widget.rate)
        await widget.repository.changeRate(
          widget.view.id,
          newRate!,
          _operation,
          widget.view.date,
        );
      else
        await widget.repository.changeTimes(
          widget.view.id,
          newTimes!,
          _operation,
          widget.view.date,
        );
      if (mounted) Navigator.pop(context);
    } catch (error, stack) {
      debugPrint('M2 change: $error\n$stack');
      if (mounted)
        setState(
          () => _error = error is ValidationFailure ? error.message : 'Penyimpanan belum dikonfirmasi. Kembali dan muat ulang sebelum retry.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FishAppBar(
      title: Text(widget.rate ? 'Ubah rate sekarang' : 'Ubah jam untuk besok'),
    ),
    body: SafeArea(
      child: FormList(
        controllers: [_rate],
        busy: _busy,
        additionalDirty: () =>
            _times.join(',') != widget.view.tomorrowTimes.join(','),
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Hari ini ${widget.view.date}: ${widget.view.times.map(timeText).join(', ')} (jam tetap)',
          ),
          if (widget.rate) ...[
            TextFormField(
              scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
              controller: _rate,
              enabled: !_busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Rate baru',
                suffixText: '%',
                helperText:
                    'Maksimal 2 desimal; mengikuti acuan pengguna/dosen.',
              ),
            ),
            const Text('Langsung menghitung ulang porsi menunggu hari ini.'),
          ] else ...[
            Text('Berlaku besok ${nextDate(widget.view.date)}'),
            ScheduleEditor(
              times: _times,
              onChanged: (v) => setState(() => _times = v),
              enabled: !_busy,
            ),
          ],
          if (_error != null) Notice(_error!, warning: true),
          if (_busy) const LinearProgressIndicator(),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(widget.rate ? 'Simpan rate' : 'Simpan jam untuk besok'),
          ),
        ],
      ),
    ),
  );
}
