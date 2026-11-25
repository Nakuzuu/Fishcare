import 'dart:async';

import 'package:flutter/material.dart';

import 'cycle_rules.dart';
import 'cycle_ui.dart';
import 'data_changes.dart';
import 'design_system.dart';
import 'feed_repository.dart';
import 'feed_ui.dart';
import 'master_data.dart';
import 'product_app.dart';
import 'report_rules.dart';
import 'report_ui.dart';
import 'weather_store.dart';
import 'weather_ui.dart';
import 'ui_format.dart';

typedef PondDay = ({MasterRecord pond, CycleView? view});

/// Membaca repository detail yang sama, tanpa data contoh.
class PondDays extends StatefulWidget {
  const PondDays({
    super.key,
    required this.repository,
    required this.cycles,
    required this.builder,
  });
  final MasterRepository repository;
  final CycleRepository cycles;
  final Widget Function(BuildContext, List<PondDay>) builder;
  @override
  State<PondDays> createState() => _PondDaysState();
}

class _PondDaysState extends State<PondDays> with WidgetsBindingObserver {
  late Future<List<PondDay>> _data;
  StreamSubscription<void>? _changes;
  Timer? _dayCheck;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
    _changes = DataChanges.events.listen((_) {
      if (mounted) setState(_reload);
    });
    _dayCheck = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(_reload);
    });
  }

  void _reload() {
    _data = _load();
  }

  @override
  void didUpdateWidget(PondDays oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reload();
  }

  Future<List<PondDay>> _load() async {
    final ponds = await widget.repository.list(
      MasterKind.pond,
      archived: false,
    );
    final result = <PondDay>[];
    for (final pond in ponds) {
      result.add((pond: pond, view: await widget.cycles.active(pond.id)));
    }
    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(_reload);
  }

  @override
  void dispose() {
    _changes?.cancel();
    _dayCheck?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PondDay>>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const Padding(
          padding: EdgeInsets.all(18),
          child: Column(
            children: [
              LinearProgressIndicator(),
              Text('Memuat kegiatan kolam…'),
            ],
          ),
        );
      if (snapshot.hasError)
        return FishCard(
          child: Column(
            children: [
              const Notice(
                'Kegiatan belum dapat dimuat. Kebutuhan belum diketahui.',
                warning: true,
              ),
              OutlinedButton(
                onPressed: () => setState(_reload),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        );
      return widget.builder(context, snapshot.data!);
    },
  );
}

class PondSummary extends StatefulWidget {
  const PondSummary({super.key, required this.pond, required this.cycles});
  final MasterRecord pond;
  final CycleRepository cycles;
  @override
  State<PondSummary> createState() => _PondSummaryState();
}

class _PondSummaryState extends State<PondSummary> {
  late Future<CycleView?> _data = widget.cycles.active(widget.pond.id);
  @override
  void didUpdateWidget(PondSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    _data = widget.cycles.active(widget.pond.id);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<CycleView?>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done)
        return const LinearProgressIndicator();
      if (snapshot.hasError)
        return const Notice(
          'Kondisi belum dapat dimuat. Buka detail untuk mencoba lagi.',
          warning: true,
        );
      return ConditionSummary(view: snapshot.data);
    },
  );
}

class ConditionSummary extends StatelessWidget {
  const ConditionSummary({super.key, this.view});
  final CycleView? view;
  @override
  Widget build(BuildContext context) {
    final v = view;
    if (v == null)
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge('Belum ada siklus', warning: true),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Mulai siklus untuk mencatat kegiatan.'),
          ),
        ],
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusBadge('Siklus aktif'),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            '${v.fish} · ${v.feedName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        FishMetrics(
          population: uiNumber(v.population),
          weight: uiDecimal(v.weightCg),
        ),
      ],
    );
  }
}

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.repository,
    required this.cycles,
    this.feeds,
    this.reports,
    this.weather,
    required this.attempts,
    required this.openFeed,
    required this.openPonds,
  });
  final MasterRepository repository;
  final CycleRepository cycles;
  final FeedRepository? feeds;
  final ReportSource? reports;
  final Widget? weather;
  final Map<String, DateTime> attempts;
  final VoidCallback openFeed, openPonds;
  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('home-scroll'),
    primary: false,
    padding: const EdgeInsets.all(18),
    children: [
      if (weather != null)
        weather!
      else if (feeds != null)
        BusinessWeatherPanel(
          store: SqliteWeatherStore(feeds!.master),
          attempts: attempts,
        ),
      PondDays(
        repository: repository,
        cycles: cycles,
        builder: (context, days) {
          final active = days.where((d) => d.view != null).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FishCard(
                emphasis: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Pakan hari ini'),
                    if (active.isEmpty)
                      const Text('Belum ada siklus aktif')
                    else ...[
                      Text(
                        '${uiDate(active.first.view!.date)} · ${active.first.view!.zone}',
                      ),
                      Text(
                        active.any((d) => d.view!.remaining == null)
                            ? 'Rencana belum lengkap'
                            : '${active.fold<int>(0, (sum, d) => sum + d.view!.remaining!)} g ${active.any((d) => d.view!.automatic) ? 'porsi menunggu' : 'tersisa'}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${active.fold<int>(0, (sum, d) => sum + d.view!.statuses.where((s) => s == 'pending').length)} slot menunggu',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sisa seluruh kolam aktif; rincian per kolam ada pada Pakan.',
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: openFeed,
                      child: const Text('Buka pakan hari ini'),
                    ),
                  ],
                ),
              ),
              const SectionTitle('Kolam aktif'),
              if (days.isEmpty)
                const Notice(
                  'Belum ada kolam. Tambahkan kolam pertama untuk mulai mencatat budidaya.',
                ),
              for (final day in days)
                FishCard(
                  key: ValueKey('home-${day.pond.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        day.pond.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ConditionSummary(view: day.view),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => MasterDetail(
                              record: day.pond,
                              repository: repository,
                              cycles: cycles,
                              feeds: feeds,
                            ),
                          ),
                        ),
                        child: const Text('Lihat kolam'),
                      ),
                    ],
                  ),
                ),
              TextButton(
                onPressed: openPonds,
                child: const Text('Lihat semua kolam'),
              ),
            ],
          );
        },
      ),
      if (feeds != null) RecoveryBanner(repo: feeds!),
      if (reports != null)
        ReportPage(source: reports!, home: true, embedded: true),
    ],
  );
}

class FeedHub extends StatefulWidget {
  const FeedHub({
    super.key,
    required this.repository,
    required this.stock,
    this.cycles,
    this.feeds,
  });
  final MasterRepository repository;
  final CycleRepository? cycles;
  final FeedRepository? feeds;
  final Widget stock;
  @override
  State<FeedHub> createState() => _FeedHubState();
}

class _FeedHubState extends State<FeedHub> {
  bool _stock = false;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: SegmentedButton<bool>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: const [
            ButtonSegment(value: false, label: Text('Pemberian hari ini')),
            ButtonSegment(value: true, label: Text('Stok pakan')),
          ],
          selected: {_stock},
          onSelectionChanged: (v) => setState(() => _stock = v.single),
        ),
      ),
      Expanded(
        child: _stock || widget.cycles == null
            ? widget.stock
            : ListView(
                primary: false,
                padding: const EdgeInsets.all(18),
                children: [
                  PondDays(
                    repository: widget.repository,
                    cycles: widget.cycles!,
                    builder: (context, days) {
                      final active = days.where((d) => d.view != null).toList();
                      if (active.isEmpty)
                        return const Notice(
                          'Belum ada siklus aktif. Mulai siklus melalui menu Kolam untuk membuat jadwal pemberian.',
                        );
                      return Column(
                        children: [
                          for (final day in active)
                            FishCard(
                              key: ValueKey('feed-${day.pond.id}'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    day.pond.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    '${day.view!.date} · ${day.view!.zone}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  ValueRow(
                                    'Kebutuhan terbaru',
                                    day.view!.need == null
                                        ? 'Belum bisa dihitung'
                                        : '${day.view!.need} g',
                                  ),
                                  ValueRow(
                                    'Sudah diberikan',
                                    '${day.view!.actualToday} g',
                                  ),
                                  ValueRow(
                                    day.view!.automatic
                                        ? 'Rencana porsi menunggu'
                                        : 'Sisa kebutuhan',
                                    day.view!.remaining == null
                                        ? 'Belum bisa dihitung'
                                        : '${day.view!.remaining} g',
                                  ),
                                  if ((day.view!.excess ?? 0) > 0)
                                    Notice(
                                      'Kelebihan aktual ${day.view!.excess} g; stok tidak dikembalikan otomatis.',
                                      warning: true,
                                    ),
                                  if ((day.view!.remaining ?? 0) > 0 &&
                                      !day.view!.statuses.contains('pending'))
                                    const Notice(
                                      'Sisa belum diberikan; tidak ada slot menunggu.',
                                      warning: true,
                                    ),
                                  if (widget.feeds != null)
                                    FeedingControls(
                                      view: day.view!,
                                      repo: widget.feeds!,
                                      onSaved: () => setState(() {}),
                                    ),
                                  OutlinedButton(
                                    onPressed: () async {
                                      await Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (_) => ChangeCycleForm(
                                            repository: widget.cycles!,
                                            view: day.view!,
                                            rate: false,
                                          ),
                                        ),
                                      );
                                      if (mounted) setState(() {});
                                    },
                                    child: const Text('Ubah jam untuk besok'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
      ),
    ],
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.feeds, required this.attempts});
  final FeedRepository feeds;
  final Map<String, DateTime> attempts;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FishAppBar(title: const Text('Pengaturan')),
    body: SafeArea(
      child: ListView(
        primary: false,
        padding: const EdgeInsets.all(18),
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: FishAppBar(title: const Text('Lokasi usaha')),
                  body: SafeArea(
                    child: ListView(
                      primary: false,
                      padding: const EdgeInsets.all(18),
                      children: [
                        BusinessWeatherPanel(
                          store: SqliteWeatherStore(feeds.master),
                          attempts: attempts,
                          settings: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('Lokasi usaha'),
          ),
          const SectionTitle('Zona waktu usaha'),
          FutureBuilder<String?>(
            future: feeds.cycles.lockedZone(),
            builder: (context, snapshot) => Notice(
              snapshot.hasError
                  ? 'Zona belum dapat dibaca.'
                  : snapshot.connectionState != ConnectionState.done
                  ? 'Memuat zona…'
                  : snapshot.data ?? 'Belum ditetapkan. Pilih saat memulai siklus atau stok masuk.',
            ),
          ),
          const Notice('Zona dikunci setelah transaksi pertama.'),
          const SectionTitle('Backup dan restore'),
          const Notice('Belum tersedia pada tahap ini.'),
          const SectionTitle('Tentang FishCare'),
          const Text(
            'Catatan budidaya pribadi pada perangkat ini. Pencatatan lokal tetap tersedia tanpa internet.',
          ),
        ],
      ),
    ),
  );
}
