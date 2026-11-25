import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/introduction_ui.dart';
import 'package:fishcare_m0/intro_store.dart';
import 'package:fishcare_m0/design_system.dart';

import 'design_match_test.dart' show renderTheme;

class MemoryIntro implements IntroStore {
  bool seen = false, failRead = false, failWrite = false;
  int writes = 0;
  Completer<void>? saving;
  Completer<bool>? reading;
  @override
  Future<bool> completed() async {
    if (failRead) throw StateError('read');
    return reading != null ? reading!.future : seen;
  }

  @override
  Future<void> complete() async {
    writes++;
    if (saving != null) await saving!.future;
    if (failWrite) throw StateError('write');
    seen = true;
  }
}

Widget app(MemoryIntro store, {VoidCallback? onHome}) => MaterialApp(
  theme: FishCareDesign.theme(),
  home: StartupGate(
    store: store,
    minimumSplash: Duration.zero,
    homeBuilder: (_) {
      onHome?.call();
      return const Scaffold(body: Text('Beranda uji'));
    },
  ),
);

void main() {
  testWidgets('splash menunggu preferensi; Beranda belum dibuat', (
    tester,
  ) async {
    final store = MemoryIntro()..reading = Completer<bool>();
    var homes = 0;
    await tester.pumpWidget(app(store, onHome: () => homes++));
    expect(find.byType(FishSplash), findsOneWidget);
    expect(homes, 0);
    store.reading!.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('Semua kolam,\nlebih tertata'), findsOneWidget);
    expect(homes, 0);
  });
  testWidgets('tiga halaman, selesai sekali, buka ulang langsung Beranda', (
    tester,
  ) async {
    final store = MemoryIntro();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Pakan lebih\nterencana'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan jadi\nlebih jelas'), findsOneWidget);
    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(store.writes, 1);
    expect(store.seen, isTrue);
    expect(find.text('Beranda uji'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    expect(find.byType(FishIntroduction), findsNothing);
    expect(find.text('Beranda uji'), findsOneWidget);
  });
  testWidgets('Lewati disimpan sekali walau ditekan berulang', (tester) async {
    final store = MemoryIntro()..saving = Completer<void>();
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati'));
    await tester.tap(find.text('Lewati'));
    await tester.pump();
    expect(store.writes, 1);
    expect(find.text('Beranda uji'), findsNothing);
    store.saving!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Beranda uji'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    expect(find.byType(FishIntroduction), findsNothing);
  });
  testWidgets('gagal simpan jujur; lanjut sementara tetap membuka pencatatan', (
    tester,
  ) async {
    final store = MemoryIntro()..failWrite = true;
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(store.seen, isFalse);
    expect(find.text('Coba lagi'), findsOneWidget);
    await tester.tap(find.text('Lanjut tanpa menyimpan'));
    await tester.pumpAndSettle();
    expect(find.text('Beranda uji'), findsOneWidget);
  });
  testWidgets(
    'gagal baca tidak membuat splash tanpa akhir; retry simpan berhasil',
    (tester) async {
      final store = MemoryIntro()
        ..failRead = true
        ..failWrite = true;
      await tester.pumpWidget(app(store));
      await tester.pumpAndSettle();
      expect(
        find.text('Preferensi perkenalan belum dapat dibaca.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      store.failWrite = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(store.seen, isTrue);
      expect(find.text('Beranda uji'), findsOneWidget);
    },
  );
  testWidgets('Kembali pada halaman kedua kembali ke pengenalan pertama', (
    tester,
  ) async {
    await tester.pumpWidget(app(MemoryIntro()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.text('Semua kolam,\nlebih tertata').hitTestable(),
      findsOneWidget,
    );
  });
  testWidgets(
    'channel Android membaca flag dan tidak menganggap write false berhasil',
    (tester) async {
      const store = AndroidIntroStore();
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        AndroidIntroStore.channel,
        (call) async {
          calls.add(call.method);
          return false;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          AndroidIntroStore.channel,
          null,
        ),
      );
      expect(await store.completed(), isFalse);
      await expectLater(store.complete(), throwsStateError);
      expect(calls, ['completed', 'complete']);
    },
  );

  for (final size in [
    (390.0, 844.0, 1.0),
    (360.0, 800.0, 1.3),
    (640.0, 360.0, 2.0),
  ]) {
    testWidgets('render perkenalan ${size.$1} teks${size.$3} tanpa overflow', (
      tester,
    ) async {
      tester.view.physicalSize = Size(size.$1, size.$2);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final file = File(
          'C:/flutter/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
        );
        if (file.existsSync())
          await (FontLoader('Roboto')..addFont(
                Future.value(ByteData.sublistView(file.readAsBytesSync())),
              ))
              .load();
      });
      final boundary = GlobalKey();
      final store = MemoryIntro();
      Widget surface(Widget child) => RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: renderTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(size.$3)),
            child: child!,
          ),
          home: child,
        ),
      );
      Future<void> capture(String screen) async {
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('../output/onboarding-2026-11-18')
            ..createSync(recursive: true);
          File(
            '${directory.path}/$screen-${size.$1.toInt()}-${(size.$3 * 100).toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.pumpWidget(surface(const FishSplash()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.getCenter(find.byType(FishMascot)).dx, closeTo(size.$1 / 2, 1));
      await capture('splash');
      await tester.pumpWidget(
        surface(FishIntroduction(store: store, onFinished: () {})),
      );
      await tester.pumpAndSettle();
      for (var page = 0; page < 3; page++) {
        await capture('intro-${page + 1}');
        if (page < 2) {
          await tester.tap(find.text('Lanjut'));
          await tester.pumpAndSettle();
        }
      }
      expect(find.text('Mulai').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Mulai'));
      await tester.pumpAndSettle();
      expect(store.seen, isTrue);
    });
  }
}
