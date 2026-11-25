import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/business_location.dart';
import 'package:fishcare_m0/device_location.dart';
import 'package:fishcare_m0/location_failure.dart';
import 'package:fishcare_m0/weather_controller.dart';
import 'package:fishcare_m0/weather_ui.dart';

import 'support/weather_fakes.dart';

void main() {
  test('buka/refresh hanya koordinat tersimpan, tidak membaca HP', () async {
    final store = MemoryWeatherStore()..value = locationA,
        device = FakeDeviceLocation(),
        api = FakeBusinessApi();
    final c = BusinessWeatherController(
      store,
      device,
      api,
      clock: () => DateTime.utc(2026, 10, 14, 1),
    );
    await c.initialize();
    expect(device.calls, 0);
    expect(api.requests.single.key, locationA.key);
    await c.refresh();
    expect(device.calls, 0);
    expect(store.writes, 0);
    expect(c.updateFailed, isFalse);
    c.dispose();
    final emptyDevice = FakeDeviceLocation(), emptyApi = FakeBusinessApi();
    final empty = BusinessWeatherController(
      MemoryWeatherStore(),
      emptyDevice,
      emptyApi,
    );
    await empty.initialize();
    expect(emptyDevice.calls, 0);
    expect(emptyApi.requests, isEmpty);
    empty.dispose();
  });
  test(
    'lokasi sekali hanya calon; batal dan gagal simpan mempertahankan lama',
    () async {
      final store = MemoryWeatherStore()..value = locationA,
          device = FakeDeviceLocation(),
          api = FakeBusinessApi();
      final c = BusinessWeatherController(store, device, api);
      await c.initialize();
      await c.acquire();
      expect(device.calls, 1);
      expect(c.candidate!.key, locationB.key);
      expect(store.value!.key, locationA.key);
      await c.cancelCandidate();
      expect(c.candidate, isNull);
      expect(store.writes, 0);
      await c.choose(locationB);
      store.fail = true;
      await c.confirm();
      expect(store.value!.key, locationA.key);
      expect(c.saved!.key, locationA.key);
      expect(c.locationError, isNotNull);
      c.dispose();
    },
  );
  test(
    'batal saat fix belum selesai mengabaikan hasil HP yang terlambat',
    () async {
      final store = MemoryWeatherStore()..value = locationA,
          device = FakeDeviceLocation()
            ..pending = Completer<BusinessLocation>();
      final c = BusinessWeatherController(store, device, FakeBusinessApi());
      await c.initialize();
      final acquiring = c.acquire();
      await c.cancelCandidate();
      await c.choose(locationA);
      device.pending!.complete(locationB);
      await acquiring;
      expect(c.candidate!.key, locationA.key);
      expect(store.writes, 0);
      c.dispose();
    },
  );
  test('respons cuaca lama tidak menggantikan lokasi/cache baru', () async {
    final store = MemoryWeatherStore()..value = locationA,
        device = FakeDeviceLocation(),
        api = FakeBusinessApi()..deferred = true;
    final c = BusinessWeatherController(store, device, api);
    final opening = c.initialize();
    await Future<void>.delayed(Duration.zero);
    await c.choose(locationB);
    final confirming = c.confirm();
    await Future<void>.delayed(Duration.zero);
    api.pending[1].complete(weatherReading(20));
    await confirming;
    api.pending[0].complete(weatherReading(99));
    await opening;
    expect(c.saved!.key, locationB.key);
    expect(c.weather!.reading.temperature, 20);
    expect(store.cached.containsKey(locationA.key), isFalse);
    expect(device.calls, 0);
    c.dispose();
  });
  testWidgets(
    'HP ditolak melalui channel menjadi pesan; constructor tidak meminta lokasi',
    (tester) async {
      const channel = MethodChannel('fishcare/location');
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        throw PlatformException(
          code: 'permission_denied',
          message: 'Izin lokasi ditolak.',
        );
      });
      final device = AndroidDeviceLocation();
      expect(calls, isEmpty);
      await expectLater(device.acquire(), throwsA(isA<LocationFailure>()));
      expect(calls, ['getCurrentLocation']);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );
  testWidgets(
    'tombol ambil, batal konfirmasi, simpan, buka ulang tanpa ambil HP otomatis',
    (tester) async {
      final store = MemoryWeatherStore()..value = locationA,
          device = FakeDeviceLocation(),
          api = FakeBusinessApi();
      Future<void> open() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BusinessWeatherPanel(
                  settings: true,
                  store: store,
                  device: device,
                  api: api,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await open();
      expect(device.calls, 0);
      await tester.tap(find.text('Ambil lokasi saat ini'));
      await tester.pumpAndSettle();
      expect(device.calls, 1);
      expect(store.writes, 0);
      await tester.ensureVisible(find.text('Simpan sebagai lokasi usaha'));
      await tester.tap(find.text('Simpan sebagai lokasi usaha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(store.value!.key, locationA.key);
      expect(store.writes, 0);
      await tester.ensureVisible(find.text('Ambil lokasi saat ini'));
      await tester.tap(find.text('Ambil lokasi saat ini'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Simpan sebagai lokasi usaha'));
      await tester.tap(find.text('Simpan sebagai lokasi usaha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi simpan'));
      await tester.pumpAndSettle();
      expect(store.value!.key, locationB.key);
      expect(store.writes, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await open();
      expect(device.calls, 2);
      expect(
        find.textContaining('Lokasi usaha tersimpan: Lokasi HP'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final message in [
    'Izin lokasi ditolak.',
    'GPS/layanan lokasi dimatikan.',
  ]) {
    testWidgets('kegagalan $message menawarkan manual tanpa mengganti lama', (
      tester,
    ) async {
      final store = MemoryWeatherStore()..value = locationA,
          device = FakeDeviceLocation()..failure = LocationFailure(message),
          api = FakeBusinessApi();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BusinessWeatherPanel(
                settings: true,
                store: store,
                device: device,
                api: api,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ambil lokasi saat ini'));
      await tester.pumpAndSettle();
      expect(find.textContaining(message), findsOneWidget);
      expect(find.text('Pilih lokasi manual'), findsOneWidget);
      expect(store.value!.key, locationA.key);
      expect(store.writes, 0);
      await tester.tap(find.text('Pilih lokasi manual'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Kota B');
      await tester.tap(find.text('Cari'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kota B, Jawa Tengah, Indonesia'));
      await tester.pumpAndSettle();
      expect(store.writes, 0);
      expect(store.value!.key, locationA.key);
      expect(device.calls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
