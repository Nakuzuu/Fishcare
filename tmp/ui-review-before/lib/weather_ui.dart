import 'dart:async';

import 'package:flutter/material.dart';

import 'design_system.dart';

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

  @override
  Widget build(BuildContext context) {
    final saved = c.saved, w = c.weather;
    final age = w == null
        ? null
        : DateTime.now().toUtc().difference(w.reading.fetchedAt);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuaca terkini dan prakiraan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Satu lokasi usaha untuk seluruh kolam; suhu udara bukan suhu air kolam.',
            ),
            if (c.initializing) const LinearProgressIndicator(),
            Text(
              saved == null
                  ? 'Lokasi usaha belum dipilih.'
                  : 'Lokasi usaha tersimpan: ${saved.name}\n${saved.latitude}, ${saved.longitude}${saved.approximate ? ' (perkiraan)' : ''}',
            ),
            if (!widget.settings)
              OutlinedButton(
                onPressed: () async {
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
                },
                child: const Text('Atur lokasi'),
              ),
            if (!c.initializing && widget.settings) ...[
              FilledButton(
                onPressed: c.locating || c.saving ? null : () => c.acquire(),
                child: const Text('Ambil lokasi saat ini'),
              ),
              const Text(
                'Hanya mengambil sekali saat tombol ditekan; izin lokasi diminta jika diperlukan.',
              ),
              TextButton(
                onPressed: c.saving ? null : _manual,
                child: const Text('Pilih lokasi manual'),
              ),
            ],
            if (c.locating) ...[
              const LinearProgressIndicator(),
              TextButton(
                onPressed: () => c.cancelCandidate(),
                child: const Text('Batalkan pengambilan lokasi'),
              ),
            ],
            if (c.locationError != null) ...[
              Notice(c.locationError!, warning: true),
              TextButton(
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
              Text(
                'Calon lokasi (belum disimpan): ${c.candidate!.name}\n${c.candidate!.latitude}, ${c.candidate!.longitude}${c.candidate!.approximate ? ' · perkiraan' : ''}${c.candidate!.accuracy != null ? ' · akurasi sekitar ${c.candidate!.accuracy} m' : ''}',
              ),
              FilledButton(
                onPressed: c.saving ? null : _confirm,
                child: const Text('Simpan sebagai lokasi usaha'),
              ),
              TextButton(
                onPressed: c.saving ? null : () => c.cancelCandidate(),
                child: const Text('Batalkan calon lokasi'),
              ),
            ],
            if (c.saving || c.loading) const LinearProgressIndicator(),
            if (c.error != null) Notice(c.error!, warning: true),
            if (w == null)
              const Text('Cuaca belum tersedia.')
            else ...[
              Text(
                c.updateFailed
                    ? 'Data tersimpan — pembaruan gagal/offline'
                    : c.cached ||
                          age == null ||
                          age.isNegative ||
                          age >= const Duration(minutes: 30)
                    ? 'Data tersimpan'
                    : 'Berhasil diperbarui',
              ),
              Text(
                'Suhu udara: ${w.reading.temperature == null || w.reading.unit == null ? 'Tidak tersedia' : '${w.reading.temperature} ${w.reading.unit}'}',
              ),
              Text('Kondisi cuaca: ${weatherCodeText(w.reading.code)}'),
              Text(
                'Peluang hujan prakiraan hari ${w.rainDay ?? 'tidak tersedia'}: ${w.rain == null ? 'Tidak tersedia' : '${w.rain}%'}',
              ),
              Text(
                'Waktu penyedia (zona lokasi): ${w.reading.providerTime ?? 'Tidak tersedia'}\nDiambil: ${w.reading.fetchedAt.toIso8601String()}',
              ),
            ],
            if (saved != null)
              TextButton(
                onPressed: c.loading || c.saving ? null : () => c.refresh(),
                child: const Text('Muat ulang cuaca'),
              ),
            if (c.error != null && saved == null)
              TextButton(
                onPressed: () => c.initialize(),
                child: const Text('Coba lagi'),
              ),
            const SelectableText(
              'Sumber: Open-Meteo · https://open-meteo.com/ · data model/prakiraan',
            ),
          ],
        ),
      ),
    );
  }
}

String weatherCodeText(num? code) => switch (code) {
  0 => 'Cerah',
  1 => 'Sebagian besar cerah',
  2 => 'Sebagian berawan',
  3 => 'Mendung',
  45 || 48 => 'Kabut',
  51 || 53 || 55 => 'Gerimis',
  61 || 63 || 65 || 80 || 81 || 82 => 'Hujan',
  95 || 96 || 99 => 'Badai petir',
  null => 'Tidak tersedia',
  _ => 'Kode WMO $code',
};

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
