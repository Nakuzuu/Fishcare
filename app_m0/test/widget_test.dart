import 'dart:async';
import 'dart:io';

import 'package:fishcare_m0/m0_main.dart';
import 'package:fishcare_m0/probe_store.dart';
import 'package:fishcare_m0/weather_probe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryProbe implements ProbeStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<String> saveOnce() async =>
      value ??= 'DATA UJI M0 â€” fixture tes widget';
}

class PendingWeather implements WeatherSource {
  final result = Completer<WeatherReading>();
  bool cancelled = false;
  @override
  Future<WeatherReading> fetch() => result.future;
  @override
  void cancel() => cancelled = true;
}

void main() {
  testWidgets(
    'kembali saat request berjalan; hasil lama tidak mengubah layar SQLite',
    (tester) async {
      final weather = PendingWeather();
      await tester.pumpWidget(
        M0App(store: MemoryProbe(), weatherFactory: () => weather),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-weather')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fetch-weather')));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('back-to-sqlite')));
      await tester.tap(find.byKey(const Key('back-to-sqlite')));
      await tester.pumpAndSettle();
      expect(weather.cancelled, isTrue);
      weather.result.completeError(
        const SocketException('offline fixture tes'),
      );
      await tester.pump();
      expect(find.byKey(const Key('save-marker')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'error jaringan menghentikan loading dan penyimpanan lokal tetap tersedia',
    (tester) async {
      final weather = PendingWeather();
      await tester.pumpWidget(
        M0App(store: MemoryProbe(), weatherFactory: () => weather),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-weather')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('fetch-weather')));
      await tester.pump();
      weather.result.completeError(
        const SocketException('offline fixture tes'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('Cuaca belum tersedia.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('back-to-sqlite')));
      await tester.tap(find.byKey(const Key('back-to-sqlite')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-marker')));
      await tester.pumpAndSettle();
      expect(find.text('DATA UJI M0 â€” fixture tes widget'), findsOneWidget);
    },
  );
}
