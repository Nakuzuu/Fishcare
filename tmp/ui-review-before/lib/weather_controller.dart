import 'dart:async';

import 'business_location.dart';
import 'weather_api.dart';
import 'weather_contract.dart';

class BusinessWeatherController {
  BusinessWeatherController(
    this.store,
    this.device,
    this.api, {
    DateTime Function()? clock,
    Map<String, DateTime>? attempts,
    this.changed,
  }) : clock = clock ?? DateTime.now,
       _attempts = attempts ?? {};
  final WeatherStore store;
  final DeviceLocation device;
  final BusinessWeatherApi api;
  final DateTime Function() clock;
  final void Function()? changed;
  BusinessLocation? saved, candidate;
  ProductWeather? weather;
  String? error, locationError;
  bool locating = false,
      saving = false,
      loading = false,
      initializing = true,
      cached = true;
  bool updateFailed = false;
  bool _disposed = false;
  int _locationRequest = 0, _weatherRequest = 0;
  final Map<String, DateTime> _attempts;
  void _notify() {
    if (!_disposed) changed?.call();
  }

  Future<void> initialize() async {
    if (_disposed || saving || locating) return;
    initializing = true;
    _weatherRequest++;
    api.cancelWeather();
    loading = false;
    _notify();
    try {
      saved = await store.location();
      if (_disposed) return;
      if (candidate?.key == saved?.key &&
          candidate?.name.trim() == saved?.name.trim() &&
          candidate?.approximate == saved?.approximate &&
          candidate?.accuracy == saved?.accuracy) {
        candidate = null;
        locationError = null;
      }
      await _cached();
      if (_disposed) return;
      initializing = false;
      _notify();
      await refresh(automatic: true);
    } catch (_) {
      if (!_disposed) {
        initializing = false;
        error = 'Lokasi/cuaca tersimpan gagal dibaca. Coba lagi.';
        _notify();
      }
    }
  }

  Future<void> _cached() async {
    weather = null;
    cached = true;
    if (saved == null) return;
    final key = saved!.key, request = _weatherRequest;
    final data = await store.cache(key);
    if (_disposed || saved?.key != key || request != _weatherRequest) return;
    if (data != null) {
      try {
        weather = ProductWeather.parse(
          data['body'] as String,
          DateTime.fromMillisecondsSinceEpoch(
            data['fetched_ms'] as int,
            isUtc: true,
          ),
        );
      } catch (_) {
        error = 'Cache cuaca tidak valid; muat ulang tersedia.';
      }
    }
  }

  Future<void> acquire() async {
    if (locating || saving || _disposed) return;
    final request = ++_locationRequest;
    candidate = null;
    locationError = null;
    locating = true;
    _notify();
    try {
      final result = await device.acquire();
      if (!_disposed && request == _locationRequest) candidate = result;
    } catch (e) {
      if (!_disposed && request == _locationRequest)
        locationError =
            '${e.toString()}\nCoba lagi atau pilih lokasi manual. Lokasi usaha sebelumnya tetap.';
    } finally {
      if (!_disposed && request == _locationRequest) {
        locating = false;
        _notify();
      }
    }
  }

  Future<void> cancelCandidate() async {
    _locationRequest++;
    candidate = null;
    locating = false;
    locationError = null;
    _notify();
    try {
      await device.cancel();
    } catch (_) {
      /* Late native result is also ignored by request ID. */
    }
  }

  Future<void> choose(BusinessLocation location) async {
    await cancelCandidate();
    if (_disposed) return;
    candidate = location;
    _notify();
  }

  Future<void> confirm() async {
    final replacement = candidate;
    if (replacement == null || saving || _disposed) return;
    saving = true;
    locationError = null;
    _notify();
    // Invalidate previous weather before saving; even a technical failure cannot publish old callbacks.
    _weatherRequest++;
    api.cancelWeather();
    loading = false;
    try {
      await store.confirm(replacement);
    } catch (_) {
      // A commit may have succeeded before a technical response error. Read back rather than inventing failure/success.
      BusinessLocation? actual;
      try {
        actual = await store.location();
      } catch (_) {
        if (!_disposed) {
          locationError = 'Hasil simpan lokasi belum diketahui. Periksa lokasi tersimpan sebelum mencoba lagi.';
          saving = false;
          _notify();
        }
        return;
      }
      if (_disposed) return;
      if (actual?.key != replacement.key ||
          actual?.name != replacement.name.trim() ||
          actual?.approximate != replacement.approximate ||
          actual?.accuracy != replacement.accuracy) {
        saved = actual;
        locationError = 'Lokasi pengganti gagal disimpan. Lokasi tersimpan sebelumnya dipertahankan; coba lagi atau pilih lokasi manual.';
        saving = false;
        _notify();
        return;
      }
    }
    if (_disposed) return;
    saved = replacement;
    updateFailed = false;
    candidate = null;
    weather = null;
    error = null;
    cached = true;
    try {
      await _cached();
    } catch (_) {
      error = 'Lokasi usaha sudah disimpan; cache cuaca belum dapat dibaca.';
    }
    await refresh(automatic: true);
    if (!_disposed) {
      saving = false;
      _notify();
    }
  }

  Future<void> refresh({bool automatic = false}) async {
    final location = saved;
    if (_disposed || location == null || loading) return;
    final now = clock(), previous = _attempts[location.key];
    if (automatic &&
        weather != null &&
        !now.difference(weather!.reading.fetchedAt).isNegative &&
        now.difference(weather!.reading.fetchedAt) <
            const Duration(minutes: 30))
      return;
    if (previous != null &&
        now.difference(previous) < const Duration(seconds: 60)) {
      if (!automatic) {
        error = 'Tunggu 60 detik sejak percobaan terakhir sebelum muat ulang.';
        _notify();
      }
      return;
    }
    _attempts[location.key] = now;
    final request = ++_weatherRequest;
    loading = true;
    updateFailed = false;
    error = null;
    _notify();
    try {
      final result = await api.fetch(location);
      if (_disposed || request != _weatherRequest || saved?.key != location.key)
        return;
      await store.saveCache(
        location.key,
        result.body,
        result.reading.fetchedAt.millisecondsSinceEpoch,
      );
      if (_disposed || request != _weatherRequest || saved?.key != location.key)
        return;
      weather = result;
      cached = false;
    } catch (_) {
      if (!_disposed && request == _weatherRequest) {
        updateFailed = true;
        error = 'Pembaruan cuaca gagal/offline. Coba lagi; pencatatan lokal tetap tersedia.';
      }
    } finally {
      if (!_disposed && request == _weatherRequest) {
        loading = false;
        _notify();
      }
    }
  }

  void dispose() {
    _disposed = true;
    _locationRequest++;
    _weatherRequest++;
    unawaited(device.cancel().catchError((Object _) {}));
    api.dispose();
  }
}
