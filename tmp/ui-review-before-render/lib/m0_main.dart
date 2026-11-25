import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'probe_store.dart';
import 'weather_probe.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(M0App(store: SqliteProbeStore()));
}

class M0App extends StatelessWidget {
  const M0App({super.key, required this.store, this.weatherFactory});
  final ProbeStore store;
  final WeatherSource Function()? weatherFactory;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FishCare M0 (Uji)',
    theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
    home: ProbePage(store: store, weatherFactory: weatherFactory),
  );
}

class ProbePage extends StatefulWidget {
  const ProbePage({super.key, required this.store, this.weatherFactory});
  final ProbeStore store;
  final WeatherSource Function()? weatherFactory;

  @override
  State<ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<ProbePage> {
  bool _busy = false;
  String? _marker;
  String _status = 'Membaca database uji…';

  @override
  void initState() {
    super.initState();
    unawaited(_databaseAction(save: false));
  }

  Future<void> _databaseAction({required bool save}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = save ? 'Menyimpan marker uji…' : 'Membaca database uji…';
    });
    try {
      final value = save
          ? await widget.store.saveOnce()
          : await widget.store.read();
      if (!mounted) return;
      setState(() {
        _marker = value;
        _status = value == null
            ? 'Belum ada marker. Tekan Simpan marker M0.'
            : 'Marker dibaca dari SQLite (bukan data budidaya).';
      });
    } catch (error, stack) {
      debugPrint('M0 SQLite: $error\n$stack');
      if (!mounted) return;
      setState(() {
        _status = 'SQLite gagal. Tekan Baca ulang sebelum mencoba simpan lagi.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('FishCare M0 (Uji)')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'HANYA DATA PENGUJIAN M0',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text(
          'Tidak ada fitur budidaya atau data pengguna. Database: fishcare_m0_probe_v1.db',
        ),
        const SizedBox(height: 16),
        Text(_status, key: const Key('sqlite-status')),
        if (_busy) const LinearProgressIndicator(),
        if (_marker != null)
          SelectableText(_marker!, key: const Key('sqlite-marker')),
        FilledButton(
          key: const Key('save-marker'),
          onPressed: _busy ? null : () => _databaseAction(save: true),
          child: const Text('Simpan marker M0 (sekali)'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _databaseAction(save: false),
          child: const Text('Baca ulang SQLite'),
        ),
        const Text(
          'Catat marker, tutup paksa aplikasi M0, buka kembali. Marker harus sama. Tombol simpan tidak menimpa marker lama.',
        ),
        const SizedBox(height: 24),
        FilledButton.tonal(
          key: const Key('open-weather'),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => WeatherPage(
                source: widget.weatherFactory?.call() ?? OpenMeteoProbe(),
              ),
            ),
          ),
          child: const Text('Buka percobaan API cuaca'),
        ),
      ],
    ),
  );
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key, required this.source});
  final WeatherSource source;

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  bool _busy = false;
  bool _failed = false;
  WeatherReading? _reading;
  String _status =
      'Belum ada permintaan. Tekan tombol untuk memilih lokasi uji dan meminta API nyata.';
  DateTime? _lastAttempt;
  Timer? _cooldown;

  bool get _canFetch =>
      !_busy &&
      (_lastAttempt == null ||
          DateTime.now().difference(_lastAttempt!) >=
              const Duration(seconds: 60));

  Future<void> _fetch() async {
    if (!_canFetch) return;
    setState(() {
      _lastAttempt = DateTime.now();
      _busy = true;
      _failed = false;
      _status = 'Memuat API nyata, batas total 10 detik…';
    });
    _cooldown?.cancel();
    _cooldown = Timer(const Duration(seconds: 60), () {
      if (mounted) setState(() {});
    });
    try {
      final reading = await widget.source.fetch();
      if (!mounted) return;
      setState(() {
        _reading = reading;
        _status =
            'API nyata berhasil. Data model cuaca, bukan sensor air kolam.';
      });
    } catch (error, stack) {
      debugPrint('M0 weather: $error\n$stack');
      if (!mounted) return;
      final message = switch (error) {
        TimeoutException() => 'Timeout 10 detik.',
        SocketException() => 'Jaringan/DNS gagal atau offline.',
        HandshakeException() => 'Koneksi HTTPS gagal.',
        HttpException() => 'Server menolak permintaan: ${error.message}',
        FormatException() => 'Respons cuaca rusak/tidak valid.',
        _ => 'Permintaan cuaca gagal.',
      };
      setState(() {
        _failed = true;
        _status =
            '${_reading == null ? 'Cuaca belum tersedia.' : 'Data tersimpan di memori — pembaruan gagal/offline.'} $message Coba lagi setelah jeda 60 detik.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _cooldown?.cancel();
    widget.source.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cuaca uji M0')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(OpenMeteoProbe.locationLabel),
        const Text('Koordinat: -6.2088, 106.8456; zona data Asia/Jakarta'),
        const Text(
          'Lokasi ini hanya untuk pembuktian API. Tidak disimpan sebagai lokasi usaha.',
        ),
        const SizedBox(height: 16),
        Text(_status, key: const Key('weather-status')),
        if (_busy) const LinearProgressIndicator(),
        if (_reading case final reading?) ...[
          Text(
            'Suhu udara: ${reading.temperature ?? 'Tidak tersedia'} ${reading.unit ?? ''}',
          ),
          Text('Kode kondisi WMO: ${reading.code ?? 'Tidak tersedia'}'),
          Text(
            'Waktu data (Asia/Jakarta): ${reading.providerTime ?? 'Tidak tersedia'}',
          ),
          Text('Diambil (UTC): ${reading.fetchedAt.toIso8601String()}'),
        ],
        FilledButton(
          key: const Key('fetch-weather'),
          onPressed: _canFetch ? _fetch : null,
          child: Text(
            _failed
                ? 'Coba lagi — API Jakarta uji'
                : 'Pilih Jakarta uji dan minta API nyata',
          ),
        ),
        if (!_canFetch && !_busy)
          const Text(
            'Tunggu jeda minimal 60 detik sebelum percobaan berikutnya.',
          ),
        OutlinedButton(
          key: const Key('back-to-sqlite'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Kembali ke SQLite (tetap aktif)'),
        ),
        const SelectableText(
          'Sumber/atribusi: Open-Meteo — https://open-meteo.com/',
        ),
        const Text(
          'M0 hanya menguji current suhu/kode kondisi. Geocoding, peluang hujan, dan cache cuaca persisten belum diimplementasikan.',
        ),
      ],
    ),
  );
}
