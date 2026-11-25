import 'dart:async';

import 'package:flutter/material.dart';

import 'master_data.dart';
import 'cycle_rules.dart';
import 'cycle_ui.dart';
import 'feed_repository.dart';
import 'feed_ui.dart';
import 'report_repository.dart';
import 'report_rules.dart';
import 'report_ui.dart';
import 'weather_ui.dart';
import 'weather_store.dart';
import 'design_system.dart';
import 'dashboard_ui.dart';
import 'ui_format.dart';
import 'intro_store.dart';
import 'introduction_ui.dart';

class FishCareApp extends StatelessWidget {
  const FishCareApp({
    super.key,
    required this.repository,
    this.cycles,
    this.feeds,
    this.reports,
    this.introStore,
  });
  final MasterRepository repository;
  final CycleRepository? cycles;
  final FeedRepository? feeds;
  final ReportSource? reports;
  final IntroStore? introStore;
  Widget _home(BuildContext context) => ProductHome(
    repository: repository,
    cycles: cycles,
    feeds: feeds,
    reports: reports,
  );
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FishCare V2',
    debugShowCheckedModeBanner: false,
    theme: FishCareDesign.theme(),
    home: introStore == null
        ? _home(context)
        : StartupGate(store: introStore!, homeBuilder: _home),
  );
}

class ProductHome extends StatefulWidget {
  const ProductHome({
    super.key,
    required this.repository,
    this.cycles,
    this.feeds,
    this.reports,
  });
  final MasterRepository repository;
  final CycleRepository? cycles;
  final FeedRepository? feeds;
  final ReportSource? reports;
  @override
  State<ProductHome> createState() => _ProductHomeState();
}

class _ProductHomeState extends State<ProductHome> {
  int _tab = 0;
  ReportFilter? _reportFilter;
  final _weatherAttempts = <String, DateTime>{};
  late final ReportSource? _reports =
      widget.reports ??
      (widget.feeds == null
          ? null
          : SqliteReportRepository(widget.feeds!.master));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FishAppBar(
      title: Text(['FishCare', 'Kolam', 'Pakan', 'Laporan'][_tab]),
      actions: [
        if (_tab == 0 && widget.feeds != null)
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  feeds: widget.feeds!,
                  attempts: _weatherAttempts,
                ),
              ),
            ),
          ),
        if (widget.feeds != null)
          IconButton(
            tooltip: 'Pemulihan tindakan',
            icon: const Icon(Icons.restore),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => RecoveryPage(repo: widget.feeds!),
              ),
            ),
          ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: switch (_tab) {
        1 => MasterList(
          key: const ValueKey('pond-list'),
          kind: MasterKind.pond,
          repository: widget.repository,
          cycles: widget.cycles,
          feeds: widget.feeds,
        ),
        2 => FeedHub(
          repository: widget.repository,
          cycles: widget.cycles,
          feeds: widget.feeds,
          stock: MasterList(
            key: const ValueKey('feed-list'),
            kind: MasterKind.feed,
            repository: widget.repository,
            feeds: widget.feeds,
          ),
        ),
        3 =>
          _reports != null
              ? ReportPage(
                  key: const ValueKey('reports'),
                  source: _reports,
                  initialFilter: _reportFilter,
                  onFilterChanged: (filter) => _reportFilter = filter,
                )
              : const EmptyPanel(
                  title: 'Belum ada laporan transaksi',
                  message: 'Sumber laporan belum tersedia. Muat ulang aplikasi dengan database produk.',
                ),
        _ =>
          widget.cycles != null
              ? HomeDashboard(
                  repository: widget.repository,
                  cycles: widget.cycles!,
                  feeds: widget.feeds,
                  reports: _reports,
                  attempts: _weatherAttempts,
                  openFeed: () => setState(() => _tab = 2),
                  openPonds: () => setState(() => _tab = 1),
                )
              : _reports != null
              ? ReportPage(
                  key: const ValueKey('home-reports'),
                  source: _reports,
                  home: true,
                  top: widget.feeds == null
                      ? null
                      : Column(
                          children: [
                            RecoveryBanner(repo: widget.feeds!),
                            BusinessWeatherPanel(
                              store: SqliteWeatherStore(widget.feeds!.master),
                              attempts: _weatherAttempts,
                            ),
                          ],
                        ),
                )
              : EmptyPanel(
                  top: widget.feeds == null
                      ? null
                      : RecoveryBanner(repo: widget.feeds!),
                  title: 'Kebutuhan pakan per kolam',
                  message: 'Buka detail kolam untuk kebutuhan dan pemberian. Stok bersama ada pada detail pakan.',
                  button: 'Buka Kolam',
                  action: () => setState(() => _tab = 1),
                ),
      },
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (value) => setState(() => _tab = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Beranda',
        ),
        NavigationDestination(icon: Icon(Icons.water_outlined), label: 'Kolam'),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'Pakan',
        ),
        NavigationDestination(
          icon: Icon(Icons.assessment_outlined),
          label: 'Laporan',
        ),
      ],
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.title,
    required this.message,
    this.button,
    this.action,
    this.top,
  });
  final String title, message;
  final String? button;
  final VoidCallback? action;
  final Widget? top;
  @override
  Widget build(BuildContext context) => ListView(
    primary: false,
    padding: const EdgeInsets.all(18),
    children: [
      if (top != null) top!,
      const SizedBox(height: 24),
      const Icon(Icons.water_outlined, size: 40, color: FishCareDesign.green),
      const SizedBox(height: 18),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Notice(message),
      if (action != null) FilledButton(onPressed: action, child: Text(button!)),
    ],
  );
}

class MasterList extends StatefulWidget {
  const MasterList({
    super.key,
    required this.kind,
    required this.repository,
    this.cycles,
    this.feeds,
  });
  final MasterKind kind;
  final MasterRepository repository;
  final CycleRepository? cycles;
  final FeedRepository? feeds;
  @override
  State<MasterList> createState() => _MasterListState();
}

class _MasterListState extends State<MasterList> with WidgetsBindingObserver {
  bool _archived = false;
  late Future<List<MasterRecord>> _rows;
  String get _noun => widget.kind == MasterKind.pond ? 'kolam' : 'pakan';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(_reload);
  }

  void _reload() {
    _rows = widget.repository.list(widget.kind, archived: _archived);
  }

  Future<void> _open({MasterRecord? record, bool create = false}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => create
            ? MasterForm(kind: widget.kind, repository: widget.repository)
            : MasterDetail(
                record: record!,
                repository: widget.repository,
                cycles: widget.cycles,
                feeds: widget.feeds,
              ),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(value: false, label: Text('Aktif')),
                ButtonSegment(value: true, label: Text('Arsip')),
              ],
              selected: {_archived},
              onSelectionChanged: (v) => setState(() {
                _archived = v.single;
                _reload();
              }),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _open(create: true),
              icon: const Icon(Icons.add),
              label: Text('Tambah $_noun'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Muat ulang daftar',
                onPressed: () => setState(_reload),
                icon: const Icon(Icons.refresh),
              ),
            ),
          ],
        ),
      ),
      if (widget.kind == MasterKind.feed)
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Stok dipakai bersama. Buka detail pakan untuk stok masuk dan koreksi.',
          ),
        ),
      Expanded(
        child: FutureBuilder<List<MasterRecord>>(
          future: _rows,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return EmptyPanel(
                title: 'Daftar gagal dimuat',
                message: 'Data lokal tidak dapat dibaca. Coba muat ulang.',
                button: 'Coba lagi',
                action: () => setState(_reload),
              );
            final rows = snapshot.data!;
            if (rows.isEmpty)
              return EmptyPanel(
                title: _archived
                    ? 'Belum ada $_noun arsip'
                    : 'Belum ada $_noun',
                message: _archived
                    ? 'Data yang diarsipkan akan tetap dapat dilihat di sini.'
                    : 'Tambahkan identitas $_noun untuk memulai.',
                button: 'Tambah $_noun',
                action: _archived ? null : () => unawaited(_open(create: true)),
              );
            return ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: FishCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(row.name),
                          subtitle: Text(
                            row.kind == MasterKind.feed
                                ? 'Rp${row.price}/kg · ${row.archived ? 'Arsip' : 'Aktif'}'
                                : row.archived
                                ? 'Arsip'
                                : 'Buka detail untuk melihat siklus',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _open(record: row),
                        ),
                        if (row.kind == MasterKind.pond &&
                            widget.cycles != null)
                          PondSummary(pond: row, cycles: widget.cycles!),
                        if (row.kind == MasterKind.feed && widget.feeds != null)
                          FutureBuilder<int>(
                            future: widget.feeds!.balance(row.id),
                            builder: (context, balance) => balance.hasError
                                ? const Notice(
                                    'Saldo belum dapat dibaca.',
                                    warning: true,
                                  )
                                : !balance.hasData
                                ? const LinearProgressIndicator()
                                : ValueRow('Stok bersama', '${balance.data} g'),
                          ),
                        OutlinedButton(
                          onPressed: () => _open(record: row),
                          child: Text(
                            row.kind == MasterKind.pond
                                ? 'Lihat kolam'
                                : 'Lihat stok pakan',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

class MasterDetail extends StatefulWidget {
  const MasterDetail({
    super.key,
    required this.record,
    required this.repository,
    this.cycles,
    this.feeds,
  });
  final MasterRecord record;
  final MasterRepository repository;
  final CycleRepository? cycles;
  final FeedRepository? feeds;
  @override
  State<MasterDetail> createState() => _MasterDetailState();
}

class _MasterDetailState extends State<MasterDetail> {
  late Future<MasterRecord> _record;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _record = widget.repository.get(widget.record.kind, widget.record.id);
  }

  Future<void> _archive(MasterRecord record) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arsipkan data?'),
        content: Text(
          '${record.name} akan dipindahkan ke daftar Arsip. Data tetap disimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arsipkan'),
          ),
        ],
      ),
    );
    if (agreed != true || !mounted || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.repository.archive(record);
      if (mounted) {
        setState(_reload);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Data diarsipkan.')));
      }
    } catch (error, stack) {
      debugPrint('M1 archive: $error\n$stack');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ValidationFailure
                  ? error.message
                  : 'Arsip gagal. Muat ulang sebelum mencoba lagi.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit(MasterRecord record) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MasterForm(
          kind: record.kind,
          repository: widget.repository,
          record: record,
        ),
      ),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FishAppBar(title: Text(widget.record.name)),
    body: SafeArea(
      child: FutureBuilder<MasterRecord>(
        future: _record,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return EmptyPanel(
              title: 'Detail gagal dimuat',
              message: 'Kembali ke daftar atau coba lagi.',
              button: 'Coba lagi',
              action: () => setState(_reload),
            );
          final row = snapshot.data!;
          return ListView(
            primary: false,
            padding: const EdgeInsets.all(18),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  row.kind == MasterKind.pond
                      ? (row.archived ? 'Kolam arsip' : 'Kolam aktif')
                      : (row.archived ? 'Pakan arsip' : 'Pakan aktif'),
                ),
              ),
              if (row.kind == MasterKind.pond) ...[
                if (widget.cycles != null)
                  CyclePanel(
                    pond: row,
                    masters: widget.repository,
                    repository: widget.cycles!,
                    feeds: widget.feeds,
                  ),
                const SectionTitle('Identitas kolam'),
                FishCard(
                  child: Column(
                    children: [
                      ValueRow(
                        'Ukuran / dimensi',
                        row.size.isEmpty ? 'Belum diisi' : row.size,
                      ),
                      ValueRow(
                        'Catatan',
                        row.notes.isEmpty ? 'Belum diisi' : row.notes,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: row.archived || _saving
                        ? null
                        : () => _edit(row),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Ubah identitas'),
                  ),
                ),
              ] else ...[
                ValueRow('Harga tercatat', '${uiMoney(row.price!)} / kg'),
                const Text(
                  'Biaya memakai harga saat pemberian. Harga baru tidak mengubah riwayat lama.',
                ),
                if (widget.feeds != null)
                  StockPanel(feed: row, repo: widget.feeds!),
              ],
              if (_saving) const LinearProgressIndicator(),
              if (!row.archived) ...[
                const SizedBox(height: 16),
                if (row.kind == MasterKind.feed)
                  OutlinedButton(
                    onPressed: _saving ? null : () => _edit(row),
                    child: Text(
                      row.kind == MasterKind.pond
                          ? 'Ubah identitas'
                          : 'Ubah nama/harga',
                    ),
                  ),
                const SizedBox(height: 20),
                const Divider(),
                TextButton(
                  onPressed: _saving ? null : () => _archive(row),
                  child: const Text('Arsipkan'),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

class MasterForm extends StatefulWidget {
  const MasterForm({
    super.key,
    required this.kind,
    required this.repository,
    this.record,
  });
  final MasterKind kind;
  final MasterRepository repository;
  final MasterRecord? record;
  @override
  State<MasterForm> createState() => _MasterFormState();
}

class _MasterFormState extends State<MasterForm> {
  final _form = GlobalKey<FormState>();
  late final String _id;
  late final TextEditingController _name, _notes, _size, _price;
  bool _saving = false;
  String? _error;
  String? _nameError, _priceError;
  bool _exitAllowed = false;
  bool get _dirty =>
      _name.text != (widget.record?.name ?? '') ||
      _notes.text != (widget.record?.notes ?? '') ||
      _size.text != (widget.record?.size ?? '') ||
      _price.text != (widget.record?.price?.toString() ?? '');
  @override
  void initState() {
    super.initState();
    _id = widget.record?.id ?? newMasterId();
    _name = TextEditingController(text: widget.record?.name ?? '');
    _notes = TextEditingController(text: widget.record?.notes ?? '');
    _size = TextEditingController(text: widget.record?.size ?? '');
    _price = TextEditingController(
      text: widget.record?.price?.toString() ?? '',
    );
    for (final controller in [_name, _notes, _size, _price]) {
      controller.addListener(() {
        if (mounted)
          setState(() {
            _nameError = null;
            _priceError = null;
          });
      });
    }
  }

  Future<void> _leave() async {
    if (_saving) return;
    if (!_dirty || _exitAllowed) {
      Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buang perubahan?'),
        content: const Text('Perubahan pada form belum disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap mengisi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _exitAllowed = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _size.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _nameError = null;
      _priceError = null;
    });
    try {
      await widget.repository.save(
        MasterRecord(
          id: _id,
          kind: widget.kind,
          name: _name.text,
          notes: _notes.text,
          size: _size.text,
          price: widget.kind == MasterKind.feed
              ? parsePrice(_price.text)
              : null,
          revision: widget.record?.revision ?? 1,
        ),
        create: widget.record == null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Data tersimpan.')));
      setState(() => _exitAllowed = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } catch (error, stack) {
      debugPrint('M1 save: $error\n$stack');
      if (mounted)
        setState(() {
          if (error is ValidationFailure) {
            if (error.field == 'price') {
              _priceError = error.message;
            } else {
              _nameError = error.message;
            }
          } else {
            _error = 'Penyimpanan gagal. Kembali dan muat ulang sebelum mencoba lagi.';
          }
        });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _validate(String? value, {bool price = false}) {
    try {
      price ? parsePrice(value ?? '') : normalizedName(value ?? '');
      return null;
    } on ValidationFailure catch (error) {
      return error.message;
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && (_exitAllowed || !_dirty),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) unawaited(_leave());
    },
    child: Scaffold(
      appBar: FishAppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: _saving ? null : _leave,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          '${widget.record == null ? 'Tambah' : 'Ubah'} ${widget.kind == MasterKind.pond ? 'kolam' : 'pakan'}',
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: FishCareDesign.background,
              border: Border(top: BorderSide(color: FishCareDesign.line)),
            ),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Menyimpan…' : 'Simpan'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: FormList(
            padding: const EdgeInsets.all(18),
            children: [
              FishFieldLabel(
                widget.kind == MasterKind.pond
                    ? 'Nama kolam *'
                    : 'Nama pakan *',
                child: TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                  controller: _name,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    hintText: widget.kind == MasterKind.pond
                        ? 'Contoh: Kolam Timur'
                        : 'Nama pakan',
                    errorText: _nameError,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) => _validate(value),
                ),
              ),
              if (widget.kind == MasterKind.pond) ...[
                FishFieldLabel(
                  'Ukuran / catatan dimensi',
                  child: TextFormField(
                    scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                    controller: _size,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: 4 × 6 m',
                      helperText:
                          'Opsional. Tidak digunakan dalam perhitungan pakan.',
                    ),
                  ),
                ),
                FishFieldLabel(
                  'Catatan',
                  child: TextFormField(
                    scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                    controller: _notes,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      hintText: 'Contoh: dekat pintu masuk',
                    ),
                    minLines: 3,
                    maxLines: 4,
                  ),
                ),
                const Notice(
                  'Nama yang sama, termasuk perbedaan huruf besar dan kecil, tidak dapat digunakan.',
                ),
              ] else
                TextFormField(
                  scrollPadding: const EdgeInsets.only(bottom: 100, top: 24),
                  controller: _price,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Harga tercatat *',
                    suffixText: 'Rp/kg',
                    helperText: 'Rupiah bulat tanpa pemisah ribuan: 1500',
                    errorText: _priceError,
                  ),
                  validator: (value) => _validate(value, price: true),
                ),
              const SizedBox(height: 20),
              if (_error != null) Text(_error!, key: const Key('save-error')),
              if (_saving) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    ),
  );
}
