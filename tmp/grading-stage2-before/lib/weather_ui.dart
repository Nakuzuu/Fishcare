import 'dart:async';

import 'package:flutter/material.dart';

import 'design_system.dart';
import 'weather_card.dart';
export 'weather_card.dart' show weatherCodeText;

import 'business_location.dart';
import 'weather_controller.dart';
import 'weather_api.dart';
import 'weather_store.dart';
import 'device_location.dart';

class BusinessWeatherPanel extends StatefulWidget {
  const BusinessWeatherPanel({
    super.key,
    required this.store,
    this.device,
    this.api,
    this.attempts,
    this.settings = false,
  });
  final WeatherStore store;
  final DeviceLocation? device;
  final BusinessWeatherApi? api;
  final Map<String, DateTime>? attempts;
  final bool settings;
  @override
  State<BusinessWeatherPanel> createState() => _BusinessWeatherPanelState();
}

class _BusinessWeatherPanelState extends State<BusinessWeatherPanel>
    with WidgetsBindingObserver {
  late final BusinessWeatherController c;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    c = BusinessWeatherController(
      widget.store,
      widget.device ?? AndroidDeviceLocation(),
      widget.api ?? OpenMeteoBusinessApi(),
      attempts: widget.attempts,
      changed: () {
        if (mounted) setState(() {});
      },
    );
    unawaited(c.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached)
      unawaited(c.cancelCandidate());
    if (state == AppLifecycleState.resumed)
      unawaited(c.refresh(automatic: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    c.dispose();
    super.dispose();
  }

  Future<void> _manual() async {
    await c.cancelCandidate();
    if (!mounted) return;
    final chosen = await Navigator.of(context).push<BusinessLocation>(
      MaterialPageRoute(builder: (_) => ManualLocationPage(api: c.api)),
    );
    if (chosen != null && mounted) await c.choose(chosen);
  }

  Future<void> _confirm() async {
    final candidate = c.candidate;
    if (candidate == null) return;
    final yes = await reviewAction(
      context,
      title: 'Simpan sebagai lokasi usaha',
      backLabel: 'Batal',
      summary:
          '${candidate.name}\n${candidate.latitude}, ${candidate.longitude}\nDipakai untuk cuaca seluruh kolam. Lokasi HP tidak dilacak; pembaruan memakai koordinat tersimpan.',
    );
    if (!mounted) return;
    if (yes == true)
      await c.confirm();
    else
      await c.cancelCandidate();
  }

  Future<void> _settings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: FishAppBar(title: const Text('Lokasi usaha')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                BusinessWeatherPanel(
                  store: widget.store,
                  device: widget.device,
                  api: widget.api,
                  attempts: widget.attempts,
                  settings: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted) await c.initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.settings)
      return WeatherCard(
        location: c.saved,
        weather: c.weather,
        loading: c.initializing || c.loading,
        cached: c.cached,
        failed: c.updateFailed,
        error: c.error,
        onSettings: _settings,
        onRefresh: c.loading || c.saving
            ? null
            : () => c.saved == null ? c.initialize() : c.refresh(),
      );
    final saved = c.saved;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FishCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lokasi usaha tersimpan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                saved == null
                    ? 'Lokasi usaha belum dipilih.'
                    : 'Lokasi usaha tersimpan: ${saved.name}',
              ),
              if (saved != null)
                ValueRow(
                  'Koordinat',
                  '${saved.latitude.toStringAsFixed(5)}, ${saved.longitude.toStringAsFixed(5)}',
                ),
              const Text('Dipakai untuk cuaca seluruh kolam.'),
            ],
          ),
        ),
        if (c.initializing || c.locating || c.saving)
          const LinearProgressIndicator(),
        if (!c.initializing) ...[
          FilledButton(
            onPressed: c.locating || c.saving ? null : () => c.acquire(),
            child: const Text('Ambil lokasi saat ini'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mengambil sekali saat tombol ditekan. Tidak melacak perpindahan.',
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: c.saving ? null : _manual,
            child: const Text('Pilih lokasi manual'),
          ),
        ],
        if (c.locating)
          TextButton(
            onPressed: () => c.cancelCandidate(),
            child: const Text('Batalkan pengambilan lokasi'),
          ),
        if (c.locationError != null) ...[
          Notice(c.locationError!, warning: true),
          OutlinedButton(
            onPressed: c.locating || c.saving
                ? null
                : c.candidate == null
                ? () => c.acquire()
                : () => c.initialize(),
            child: Text(
              c.candidate == null
                  ? 'Coba lagi pengambilan lokasi'
                  : 'Periksa lokasi tersimpan',
            ),
          ),
        ],
        if (c.candidate != null) ...[
          const SectionTitle('Tinjau calon lokasi'),
          FishCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusBadge('Belum disimpan', warning: true),
                const SizedBox(height: 12),
                Text(
                  c.candidate!.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ValueRow('Lintang', c.candidate!.latitude.toStringAsFixed(5)),
                ValueRow('Bujur', c.candidate!.longitude.toStringAsFixed(5)),
                if (c.candidate!.approximate) const Text('Lokasi perkiraan'),
                if (c.candidate!.accuracy != null)
                  Text('Akurasi sekitar ${c.candidate!.accuracy!.round()} m'),
              ],
            ),
          ),
          FilledButton(
            onPressed: c.saving ? null : _confirm,
            child: const Text('Simpan sebagai lokasi usaha'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: c.saving ? null : () => c.cancelCandidate(),
            child: const Text('Batalkan calon lokasi'),
          ),
        ],
        const Notice(
          'Lokasi sebelumnya tetap digunakan sampai pengganti dikonfirmasi dan tersimpan.',
        ),
      ],
    );
  }
}

class ManualLocationPage extends StatefulWidget {
  const ManualLocationPage({super.key, required this.api});
  final BusinessWeatherApi api;
  @override
  State<ManualLocationPage> createState() => _ManualLocationPageState();
}

class _ManualLocationPageState extends State<ManualLocationPage> {
  final _query = TextEditingController();
  int _request = 0;
  bool _loading = false, _searched = false;
  String? _error;
  List<BusinessLocation> _rows = [];
  @override
  void dispose() {
    _request++;
    _query.dispose();
    super.dispose();
  }

  void _edited(String text) {
    _request++;
    setState(() {
      _rows = [];
      _loading = false;
      _error = null;
      _searched = false;
    });
  }

  Future<void> _search() async {
    if (_query.text.trim().length < 2) {
      setState(() => _error = 'Isi minimal dua karakter kota/kecamatan.');
      return;
    }
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _rows = [];
      _searched = true;
    });
    try {
      final rows = await widget.api.search(_query.text.trim());
      if (mounted && request == _request) setState(() => _rows = rows);
    } catch (_) {
      if (mounted && request == _request)
        setState(
          () => _error = 'Pencarian gagal/offline. Coba lagi; lokasi usaha sebelumnya tetap.',
        );
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: FishAppBar(title: const Text('Pilih lokasi manual')),
    body: SafeArea(
      child: FormList(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _query,
            onChanged: _edited,
            decoration: const InputDecoration(labelText: 'Kota/kecamatan'),
          ),
          FilledButton(
            onPressed: _loading ? null : _search,
            child: const Text('Cari'),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Text(_error!),
          if (!_loading && _searched && _error == null && _rows.isEmpty)
            const Text('Lokasi tidak ditemukan. Ubah kata pencarian.'),
          for (final location in _rows)
            ListTile(
              title: Text(location.name),
              subtitle: Text('${location.latitude}, ${location.longitude}'),
              onTap: () => Navigator.pop(context, location),
            ),
          const Text(
            'Memilih hasil hanya membuat calon lokasi. Konfirmasi Simpan sebagai lokasi usaha diperlukan.',
          ),
        ],
      ),
    ),
  );
}
