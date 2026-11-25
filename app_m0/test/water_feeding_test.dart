import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/cycle_repository.dart';
import 'package:fishcare_m0/feed_repository.dart';
import 'package:fishcare_m0/feeding_day.dart';
import 'package:fishcare_m0/feeding_input.dart';
import 'package:fishcare_m0/feeding_policy.dart';
import 'package:fishcare_m0/feeding_schema.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/master_repository.dart';
import 'package:fishcare_m0/water_feeding_ui.dart';
import 'package:fishcare_m0/water_snapshot_ui.dart';

final instant = DateTime.utc(2026, 10, 26, 2);

class FormFeedRepo extends FeedRepository {
  FormFeedRepo._(super.master, super.cycles);
  factory FormFeedRepo() {
    final master = SqliteMasterRepository(
      open: () => throw StateError('This UI fixture must not open SQLite'),
    );
    return FormFeedRepo._(
      master,
      SqliteCycleRepository(master, clock: () => instant),
    );
  }
  int price = 15000, saves = 0;
  Map<String, Object?>? saved;
  @override
  Future<Map<String, Object?>> contextFor(
    String cycle,
    String date,
    int minute,
  ) async => {
    'cycle': cycle,
    'date': date,
    'minute': minute,
    'price': price,
    'rate': 250,
    'feed_name': 'Pakan uji',
    'stock': 10000,
    'plan': 625,
    'remaining': 1250,
    'automatic': true,
    'policy_version': weightFeedingPolicyVersion,
    'state': 'pending',
    'expected_context': 'price:$price',
    'day': FeedingDayPlan(
      normal: normalFeedingPlan(
        population: 1000,
        weightCg: 5000,
        times: [480, 960],
      ),
      states: {480: FeedingSlotState.pending, 960: FeedingSlotState.pending},
      records: [],
    ),
  };
  @override
  Future<void> run(String id, String kind, Map<String, Object?> payload) async {
    saves++;
    saved = Map.of(payload);
  }
}

Future<void> openForm(WidgetTester tester, FormFeedRepo repo) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => WaterFeedingForm(
                  repo: repo,
                  cycle: 'c',
                  date: '2026-10-26',
                  minute: 480,
                ),
              ),
            ),
            child: const Text('Buka pemberian'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Buka pemberian'));
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    finder.hitTestable(),
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(finder, value);
  await tester.pump();
}

Future<void> review(WidgetTester tester) async {
  final finder = find.text('Tinjau dan simpan');
  await tester.scrollUntilVisible(
    finder.hitTestable(),
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('parser suhu/pH presisi menerima koma/titik dan menolak kosong/pemisah/nonfinite', () {
    expect(parseWaterNumber('27,5', ph: false), 275);
    expect(parseWaterNumber('7.25', ph: true), 725);
    expect(parseWaterNumber('0', ph: true), 0);
    for (final s in ['', '-1', 'NaN', 'Infinity', '1.500', '27,55', '50.1']) {
      expect(
        () => parseWaterNumber(s, ph: false),
        throwsA(isA<ValidationFailure>()),
      );
    }
    for (final s in ['14.01', '7,255', '1.500']) {
      expect(
        () => parseWaterNumber(s, ph: true),
        throwsA(isA<ValidationFailure>()),
      );
    }
  });
  test('waktu pengukuran hari lama/masa depan ditolak dan nama lele tidak menebak spesies lain', () {
    final p = <String, Object?>{
      'date': '2026-10-26',
      'water_temperature_deci_c': 270,
      'water_ph_hundredths': 700,
      'water_recorded_at_ms': instant.millisecondsSinceEpoch,
    };
    expect(readingFromPayload(p, instant, 'Asia/Jakarta').phHundredths, 700);
    expect(
      () => readingFromPayload(
        {
          ...p,
          'water_recorded_at_ms': instant
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
        },
        instant,
        'Asia/Jakarta',
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => readingFromPayload(
        {
          ...p,
          'water_recorded_at_ms': instant
              .add(const Duration(seconds: 1))
              .millisecondsSinceEpoch,
        },
        instant,
        'Asia/Jakarta',
      ),
      throwsA(isA<ValidationFailure>()),
    );
    expect(isLele('Ikan LELE Sangkuriang'), isTrue);
    expect(isLele('Udang'), isFalse);
    expect(isLele('Lelehan'), isFalse);
  });
  testWidgets(
    'AT50: harga awal dan biaya aktual1125g Rp16.875 terlihat sebelum konfirmasi',
    (tester) async {
      final repo = FormFeedRepo();
      await openForm(tester, repo);
      expect(find.text('Rp15.000/kg'), findsOneWidget);
      await enter(tester, 'water-temperature', '27');
      await enter(tester, 'water-ph', '7');
      await enter(tester, 'actual-feed', '1125');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('feeding-cost-preview')).hitTestable(),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Rp16.875'), findsOneWidget);
      expect(repo.saves, 0);
    },
  );
  testWidgets(
    'pengukuran wajib; kondisi32C boleh dicatat dengan rekomendasi kosong; batal tidak menyimpan',
    (tester) async {
      final repo = FormFeedRepo();
      await openForm(tester, repo);
      await enter(tester, 'actual-feed', '200');
      await review(tester);
      expect(repo.saves, 0);
      await enter(tester, 'water-temperature', '32');
      await enter(tester, 'water-ph', '7');
      await review(tester);
      expect(
        find.textContaining('Peringatan: rekomendasi otomatis tidak tersedia'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Kembali mengubah').hitTestable(),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Kembali mengubah'));
      await tester.pumpAndSettle();
      expect(repo.saves, 0);
    },
  );
  testWidgets(
    'pemberian dingin menyimpan pengukuran/payload sama sekali; buka form baru kosong',
    (tester) async {
      final repo = FormFeedRepo();
      await openForm(tester, repo);
      await enter(tester, 'water-temperature', '23');
      await enter(tester, 'water-ph', '7,25');
      await enter(tester, 'actual-feed', '500');
      await review(tester);
      final confirm = find.byKey(const ValueKey('confirm-action'));
      await tester.scrollUntilVisible(
        confirm.hitTestable(),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      final point = tester.getCenter(confirm);
      await tester.tapAt(point);
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(repo.saves, 1);
      expect(repo.saved!['water_temperature_deci_c'], 230);
      expect(repo.saved!['water_ph_hundredths'], 725);
      expect(
        repo.saved!['water_recorded_at_ms'],
        instant.millisecondsSinceEpoch,
      );
      await tester.tap(find.text('Buka pemberian'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('water-temperature')),
            )
            .controller!
            .text,
        isEmpty,
      );
    },
  );
  testWidgets(
    'harga berubah sebelum tinjau harus ditampilkan dan ditinjau ulang',
    (tester) async {
      final repo = FormFeedRepo();
      await openForm(tester, repo);
      await enter(tester, 'water-temperature', '27');
      await enter(tester, 'water-ph', '7');
      await enter(tester, 'actual-feed', '200');
      repo.price = 20000;
      await review(tester);
      expect(repo.saves, 0);
      expect(find.text('Konfirmasi pemberian'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Rp20.000/kg').hitTestable(),
        -180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Rp20.000/kg'), findsOneWidget);
    },
  );
  testWidgets('snapshot lama tanpa pengukuran tidak ditampilkan sebagai nol', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: WaterSnapshot(row: {'kind': 'feeding'})),
      ),
    );
    expect(find.text('Tidak tercatat'), findsNWidgets(2));
    expect(find.text('0 °C'), findsNothing);
  });
}
