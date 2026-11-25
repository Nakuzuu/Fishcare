import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/design_system.dart';
import 'package:fishcare_m0/water_feeding_ui.dart';

import 'water_feeding_test.dart' show FormFeedRepo, enter;

void main() {
  testWidgets('form pengukuran 360dp teks130 dapat digulir tanpa overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.runAsync(() async {
      final fonts = [
        'C:/Windows/Fonts/segoeui.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
        '/System/Library/Fonts/Supplemental/Arial.ttf',
      ].map((path) => File(path)).where((f) => f.existsSync());
      if (fonts.isEmpty) return;
      final bytes = fonts.first.readAsBytesSync();
      await (FontLoader(
        'Stage4Render',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    });
    final baseTheme = FishCareDesign.theme();
    await tester.pumpWidget(
      MaterialApp(
        theme: baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(fontFamily: 'Stage4Render'),
          primaryTextTheme: baseTheme.primaryTextTheme.apply(
            fontFamily: 'Stage4Render',
          ),
          appBarTheme: baseTheme.appBarTheme.copyWith(
            titleTextStyle: baseTheme.appBarTheme.titleTextStyle!.copyWith(
              fontFamily: 'Stage4Render',
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: baseTheme.filledButtonTheme.style!.copyWith(
              textStyle: WidgetStatePropertyAll(
                baseTheme.filledButtonTheme.style!.textStyle!
                    .resolve({})!
                    .copyWith(fontFamily: 'Stage4Render'),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: baseTheme.outlinedButtonTheme.style!.copyWith(
              textStyle: WidgetStatePropertyAll(
                baseTheme.outlinedButtonTheme.style!.textStyle!
                    .resolve({})!
                    .copyWith(fontFamily: 'Stage4Render'),
              ),
            ),
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: key,
          child: WaterFeedingForm(
            repo: FormFeedRepo(),
            cycle: 'c',
            date: '2026-10-26',
            minute: 480,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = Directory('../output/feeding-stage4')
          ..createSync(recursive: true);
        File('${folder.path}/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('initial-360-text130');
    await enter(tester, 'water-temperature', '23');
    await enter(tester, 'water-ph', '7');
    await enter(tester, 'actual-feed', '500');
    await tester.scrollUntilVisible(
      find.text('Tinjau dan simpan').hitTestable(),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await capture('filled-360-text130');
    expect(find.text('Rp7.500'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
