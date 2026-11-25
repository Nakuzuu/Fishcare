import 'dart:convert';

import 'package:flutter/material.dart';

import 'business_location.dart';
import 'design_system.dart';
import 'ui_format.dart';
import 'weather_api.dart';

Map<String, dynamic> weatherMetadata(ProductWeather weather) {
  try {
    final data = jsonDecode(weather.body);
    return data is Map<String, dynamic> ? data : {};
  } on FormatException {
    return {};
  }
}

({String provider, String fetched, String? today}) weatherTimes(
  ProductWeather weather,
  DateTime now,
) {
  final meta = weatherMetadata(weather);
  final offset = meta['utc_offset_seconds'];
  final zone = meta['timezone_abbreviation'] ?? meta['timezone'];
  final raw = weather.reading.providerTime;
  final provider = raw == null ? null : DateTime.tryParse(raw);
  final hasOffset = offset is int;
  final fetched = hasOffset
      ? weather.reading.fetchedAt.toUtc().add(Duration(seconds: offset))
      : weather.reading.fetchedAt.toLocal();
  final localNow = hasOffset
      ? now.toUtc().add(Duration(seconds: offset))
      : null;
  final localProvider = provider != null && provider.isUtc && hasOffset
      ? provider.add(Duration(seconds: offset))
      : provider;
  final zoneLabel = zone is String
      ? zone
      : hasOffset
      ? 'UTC${offset >= 0 ? '+' : ''}${offset / 3600}'
      : 'zona lokasi penyedia';
  return (
    provider: localProvider == null
        ? 'Tidak tersedia'
        : '${uiDateTime(localProvider)} · $zoneLabel',
    fetched:
        '${uiDateTime(fetched)} · ${hasOffset ? zoneLabel : 'waktu perangkat (${fetched.timeZoneName})'}',
    today: localNow?.toIso8601String().substring(0, 10),
  );
}

String weatherCodeText(num? code) => switch (code) {
  0 => 'Cerah',
  1 => 'Sebagian besar cerah',
  2 => 'Sebagian berawan',
  3 => 'Berawan',
  45 || 48 => 'Kabut',
  51 || 53 || 55 || 56 || 57 => 'Gerimis',
  61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => 'Hujan',
  71 || 73 || 75 || 77 || 85 || 86 => 'Salju',
  95 || 96 || 99 => 'Badai petir',
  null => 'Kondisi tidak tersedia',
  _ => 'Kondisi belum dikenali',
};

IconData weatherIcon(num? code) => switch (code) {
  0 || 1 => Icons.wb_sunny_rounded,
  2 => Icons.wb_cloudy_rounded,
  3 || 45 || 48 => Icons.cloud_rounded,
  51 ||
  53 ||
  55 ||
  56 ||
  57 ||
  61 ||
  63 ||
  65 ||
  66 ||
  67 ||
  80 ||
  81 ||
  82 => Icons.grain_rounded,
  95 || 96 || 99 => Icons.thunderstorm_rounded,
  71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit_rounded,
  _ => Icons.cloud_outlined,
};

/// Tampilan murni: tidak meminta lokasi, jaringan, atau menulis data.
class WeatherCard extends StatelessWidget {
  const WeatherCard({
    super.key,
    this.location,
    this.weather,
    this.loading = false,
    this.cached = false,
    this.failed = false,
    this.error,
    this.onSettings,
    this.onRefresh,
    this.now,
  });
  final BusinessLocation? location;
  final ProductWeather? weather;
  final bool loading, cached, failed;
  final String? error;
  final VoidCallback? onSettings, onRefresh;
  final DateTime? now;
  @override
  Widget build(BuildContext context) {
    final data = weather;
    final clock = now ?? DateTime.now();
    final age = data == null
        ? null
        : clock.toUtc().difference(data.reading.fetchedAt.toUtc());
    final stale =
        cached ||
        age == null ||
        age.isNegative ||
        age >= const Duration(minutes: 30);
    final wet =
        data != null &&
        [
          51,
          53,
          55,
          56,
          57,
          61,
          63,
          65,
          66,
          67,
          80,
          81,
          82,
          95,
          96,
          99,
        ].contains(data.reading.code);
    final sunny = data?.reading.code == 0 || data?.reading.code == 1;
    final times = data == null ? null : weatherTimes(data, clock);
    final status = failed
        ? 'Data tersimpan · pembaruan gagal/offline'
        : stale
        ? 'Data tersimpan'
        : 'Berhasil diperbarui';
    final rainToday =
        data != null && data.rainDay != null && times!.today == data.rainDay;
    return Container(
      key: const ValueKey('weather-card'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FishCareDesign.line),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: wet
              ? const [Color(0xFFE4EDF4), Color(0xFFF2F7F6)]
              : sunny
              ? const [Color(0xFFF9F0D9), Color(0xFFF1F7ED)]
              : const [Color(0xFFE5F1EC), Color(0xFFF2F7F4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            location?.name ?? 'Lokasi usaha belum dipilih',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Cuaca terkini dan prakiraan',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (data != null) ...[
            Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  data.reading.temperature == null || data.reading.unit == null
                      ? '—'
                      : '${data.reading.temperature.toString().replaceAll('.', ',')} ${data.reading.unit}',
                  key: const ValueKey('weather-temperature'),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                    letterSpacing: -2,
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(
                    weatherIcon(data.reading.code),
                    size: 80,
                    color: sunny
                        ? const Color(0xFFB87913)
                        : FishCareDesign.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              weatherCodeText(data.reading.code),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ValueRow(
              rainToday
                  ? 'Prakiraan hujan hari ini'
                  : 'Prakiraan hujan${data.rainDay == null ? '' : ' · ${uiDate(data.rainDay!)}'}',
              data.rain == null ? 'Tidak tersedia' : '${data.rain}%',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusBadge(status, warning: stale || failed),
            ),
            const SizedBox(height: 8),
            Text(
              'Data: ${times!.provider}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Diambil: ${times.fetched}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.cloud_outlined,
                size: 56,
                color: FishCareDesign.green,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loading ? 'Memuat cuaca…' : 'Cuaca belum tersedia',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error != null && location == null
                  ? error!
                  : location == null
                  ? 'Pilih lokasi usaha untuk melihat cuaca di sekitar kolam.'
                  : error != null
                  ? 'Pembaruan gagal/offline. Coba muat ulang saat terhubung.'
                  : 'Muat ulang untuk mendapatkan data cuaca.',
            ),
          ],
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (error != null && data != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 12),
          Text(
            'Suhu udara, bukan suhu air kolam. · Open-Meteo',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onSettings,
                icon: const Icon(Icons.location_on_outlined, size: 18),
                label: const Text('Atur lokasi'),
              ),
              if (location != null)
                TextButton.icon(
                  onPressed: loading ? null : onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Muat ulang'),
                ),
              if (location == null && error != null)
                TextButton(
                  onPressed: loading ? null : onRefresh,
                  child: const Text('Coba lagi'),
                ),
              if (data != null)
                TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: const FishAppBar(title: Text('Detail cuaca')),
                        body: SafeArea(
                          child: FormList(
                            children: [
                              FishCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      location?.name ?? 'Lokasi belum dipilih',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    ValueRow('Status', status),
                                    ValueRow('Waktu penyedia', times!.provider),
                                    ValueRow(
                                      'Waktu pengambilan',
                                      times.fetched,
                                    ),
                                    if (location != null) ...[
                                      ValueRow(
                                        'Lintang',
                                        '${location!.latitude}',
                                      ),
                                      ValueRow(
                                        'Bujur',
                                        '${location!.longitude}',
                                      ),
                                      ValueRow(
                                        'Ketelitian lokasi',
                                        location!.approximate
                                            ? 'Perkiraan'
                                            : 'Koordinat tersimpan',
                                      ),
                                    ],
                                    ValueRow(
                                      'Tanggal prakiraan',
                                      data.rainDay == null
                                          ? 'Tidak tersedia'
                                          : uiDate(data.rainDay!),
                                    ),
                                  ],
                                ),
                              ),
                              const Notice(
                                'Data model/prakiraan untuk satu lokasi usaha seluruh kolam. Suhu udara bukan pengukuran suhu air dan tidak mengubah kebutuhan pakan.',
                              ),
                              ExpansionTile(
                                title: const Text('Metadata teknis'),
                                children: [
                                  SelectableText(
                                    'Waktu penyedia asli: ${data.reading.providerTime}\nDiambil UTC: ${data.reading.fetchedAt.toUtc().toIso8601String()}\nZona: ${weatherMetadata(data)['timezone'] ?? 'tidak tersedia'}\nKode WMO: ${data.reading.code ?? 'tidak tersedia'}',
                                  ),
                                ],
                              ),
                              const SelectableText(
                                'Sumber: Open-Meteo · https://open-meteo.com/',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Detail cuaca'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
