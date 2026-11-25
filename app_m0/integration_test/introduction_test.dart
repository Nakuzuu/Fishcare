import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fishcare_m0/intro_store.dart';
import 'package:fishcare_m0/introduction_ui.dart';
import 'package:fishcare_m0/design_system.dart';

// Run only with FISHCARE_NATIVE_TEST=1, --no-uninstall, in FishCare Uji.
// This test never opens a farming database.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android menyimpan preferensi setelah Lewati dan membacanya kembali',
    (tester) async {
      const store = AndroidIntroStore();
      expect(await store.completed(), isA<bool>());
      var finished = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: FishCareDesign.theme(),
          home: FishIntroduction(store: store, onFinished: () => finished++),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lewati'));
      for (var i = 0; i < 30 && finished == 0; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(finished, 1);
      expect(await const AndroidIntroStore().completed(), isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          theme: FishCareDesign.theme(),
          home: StartupGate(
            store: const AndroidIntroStore(),
            minimumSplash: Duration.zero,
            homeBuilder: (_) =>
                const Scaffold(body: Text('Beranda uji native')),
          ),
        ),
      );
      for (
        var i = 0;
        i < 30 && find.text('Beranda uji native').evaluate().isEmpty;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Beranda uji native'), findsOneWidget);
      expect(find.byType(FishIntroduction), findsNothing);
    },
  );
}
