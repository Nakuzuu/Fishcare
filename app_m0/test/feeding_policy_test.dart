import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/cycle_rules.dart';
import 'package:fishcare_m0/feeding_policy.dart';
import 'package:fishcare_m0/master_data.dart';

FeedingWaterReading water(int temperatureDeciC, [int phHundredths = 700]) =>
    FeedingWaterReading(
      temperatureDeciC: temperatureDeciC,
      phHundredths: phHundredths,
      recordedAtMs: 1792886400000,
    );

NormalFeedingPlan plan({
  int? population = 1000,
  int? weight = 5000,
  List<int> times = const [480, 960],
}) => normalFeedingPlan(population: population, weightCg: weight, times: times);

void main() {
  test('batas tabel kontinu: bobot desimal tidak dibulatkan ke gram utuh', () {
    final boundaries = <int, int>{
      200: 500,
      500: 500,
      501: 400,
      550: 400,
      1000: 400,
      1001: 300,
      1050: 300,
      3500: 300,
      3501: 250,
      3550: 250,
      5000: 250,
      5001: 220,
      5050: 220,
      7000: 220,
      7001: 200,
      7100: 200,
    };
    for (final entry in boundaries.entries) {
      expect(
        rateForWeight(entry.key).rateBp,
        entry.value,
        reason: '${entry.key}/100 gram',
      );
    }
  });

  test(
    'bobot di bawah 2 gram atau hilang tidak menjadi rate nol/manual/10%',
    () {
      expect(rateForWeight(null).status, RateStatus.missingWeight);
      expect(rateForWeight(199).status, RateStatus.belowReference);
      expect(rateForWeight(1).rateBp, isNull);
      expect(plan(weight: 199).dailyGrams, isNull);
      expect(plan(weight: 199).slots, isEmpty);
      expect(plan(weight: null).status, NormalPlanStatus.missingData);
      expect(plan(population: null).dailyGrams, isNull);
    },
  );

  test('AT54: 1000 ikan x50g x2.5% menghasilkan1250g dengan625+625', () {
    final p = plan();
    expect(p.status, NormalPlanStatus.ready);
    expect(p.rate.rateBp, 250);
    expect(p.dailyGrams, 1250);
    expect(p.slots.map((s) => s.grams).toList(), [625, 625]);
    expect(p.toSnapshot()['policy_version'], weightFeedingPolicyVersion);
  });

  test('tabel yang sama sejak bobot awal dan sesudah grading tanpa override minggu pertama', () {
    final initial = plan(population: 1000, weight: 300);
    expect(initial.rate.rateBp, 500);
    expect(initial.dailyGrams, 150);
    final graded = plan(population: 1000, weight: 600);
    expect(graded.rate.rateBp, 400);
    expect(graded.dailyGrams, 240);
    expect(initial.dailyGrams, 150);
    expect(initial.toSnapshot()['weight_cg'], 300);
  });

  test(
    'gram sisa pembulatan ke jam paling awal, total tepat untuk1–6 slot',
    () {
      for (var count = 1; count <= 6; count++) {
        final p = plan(
          population: 1001,
          times: List.generate(count, (i) => 480 + i * 60),
        );
        expect(p.dailyGrams, 1251);
        expect(p.slots.fold<int>(0, (sum, s) => sum + s.grams), 1251);
        expect(p.slots.first.grams - p.slots.last.grams, lessThanOrEqualTo(1));
      }
      final p = plan(population: 1001, times: [960, 480]);
      expect(p.slots.map((s) => s.minute).toList(), [480, 960]);
      expect(p.slots.map((s) => s.grams).toList(), [626, 625]);
    },
  );

  test('setengah gram dibulatkan naik tanpa pembulatan biomassa antara', () {
    expect(plan(population: 1, weight: 500).dailyGrams, 0);
    expect(plan(population: 2, weight: 500).dailyGrams, 1);
    expect(plan(population: 1, weight: 1250).dailyGrams, 0);
    expect(plan(population: 2, weight: 1250).dailyGrams, 1);
    expect(plan(population: 3, weight: 5000).dailyGrams, 4);
  });

  test(
    'data invalid, overflow dan jadwal duplikat tidak menjadi hasil nol',
    () {
      for (final weight in [0, -1]) {
        expect(() => plan(weight: weight), throwsA(isA<ValidationFailure>()));
      }
      expect(() => plan(population: -1), throwsA(isA<ValidationFailure>()));
      expect(
        () => plan(population: 9223372036854775807, weight: 10000),
        throwsA(isA<ValidationFailure>()),
      );
      expect(() => plan(times: []), throwsA(isA<ValidationFailure>()));
      expect(() => plan(times: [480, 480]), throwsA(isA<ValidationFailure>()));
    },
  );

  test(
    'populasi nol berbeda dari data hilang dan tidak mengizinkan pemberian',
    () {
      final p = plan(population: 0);
      expect(p.status, NormalPlanStatus.noFish);
      expect(p.dailyGrams, 0);
      final result = recommendFeedingSlot(
        plan: p,
        minute: 480,
        reading: water(270),
      );
      expect(result.status, SlotRecommendationStatus.noFish);
      expect(result.permitsActualEntry, isFalse);
    },
  );

  test('rekomendasi belum tersedia sebelum pengukuran, termasuk setelah slot lain dihitung', () {
    final p = plan();
    recommendFeedingSlot(plan: p, minute: 480, reading: water(230));
    final afternoon = recommendFeedingSlot(plan: p, minute: 960, reading: null);
    expect(afternoon.status, SlotRecommendationStatus.measurementRequired);
    expect(afternoon.recommendedGrams, isNull);
    expect(afternoon.permitsActualEntry, isFalse);
  });

  test('AT48: porsi normal500, pagi dingin400, sore normal500; tanpa mengubah baseline', () {
    final p = plan(population: 800);
    final before = p.toSnapshot();
    final morning = recommendFeedingSlot(
      plan: p,
      minute: 480,
      reading: water(230),
    );
    expect(morning.normalGrams, 500);
    expect(morning.recommendedGrams, 400);
    expect(morning.temperatureReductionGrams, 100);
    expect(morning.temperaturePercent, 80);
    final afternoon = recommendFeedingSlot(
      plan: p,
      minute: 960,
      reading: water(270),
    );
    expect(afternoon.recommendedGrams, 500);
    expect(afternoon.temperatureReductionGrams, 0);
    expect(p.toSnapshot(), before);
  });

  test('kedua slot dingin625 menjadi500 per slot, tidak mengalikan target sehari berulang', () {
    final p = plan();
    for (final minute in [480, 960]) {
      final r = recommendFeedingSlot(
        plan: p,
        minute: minute,
        reading: water(239),
      );
      expect(r.recommendedGrams, 500);
      expect(r.temperatureReductionGrams, 125);
    }
  });

  test('AT49: tepat25/30C dan pH6.5/8 normal; pH bukan pengali rate', () {
    for (final temp in [250, 300]) {
      for (final ph in [650, 800]) {
        final r = recommendFeedingSlot(
          plan: plan(),
          minute: 480,
          reading: water(temp, ph),
        );
        expect(r.status, SlotRecommendationStatus.recommended);
        expect(r.recommendedGrams, 625);
        expect(r.temperaturePercent, 100);
      }
    }
  });

  test(
    '24 sampai24.9C dan suhu tinggi termasuk32C: tidak ada angka rekomendasi',
    () {
      for (final temp in [240, 249, 301, 320]) {
        final r = recommendFeedingSlot(
          plan: plan(),
          minute: 480,
          reading: water(temp),
        );
        expect(r.status, SlotRecommendationStatus.waterWarning);
        expect(r.recommendedGrams, isNull);
        expect(r.temperaturePercent, isNull);
        expect(r.temperatureReductionGrams, isNull);
        expect(r.permitsActualEntry, isTrue);
      }
      expect(
        waterConditions(water(240)).temperature,
        TemperatureCondition.noRule,
      );
      expect(
        waterConditions(water(301)).temperature,
        TemperatureCondition.high,
      );
    },
  );

  test(
    'pH di luar acuan menghalangi rekomendasi numerik termasuk ketika dingin',
    () {
      for (final temp in [230, 270]) {
        for (final ph in [649, 801]) {
          final r = recommendFeedingSlot(
            plan: plan(),
            minute: 480,
            reading: water(temp, ph),
          );
          expect(r.conditions!.ph, PhCondition.outsideReference);
          expect(r.recommendedGrams, isNull);
          expect(r.permitsActualEntry, isTrue);
        }
      }
    },
  );

  test('input teknis pengukuran invalid ditolak, bukan status air normal', () {
    for (final temp in [-1, 501]) {
      expect(() => water(temp), throwsA(isA<ValidationFailure>()));
    }
    for (final ph in [-1, 1401]) {
      expect(() => water(270, ph), throwsA(isA<ValidationFailure>()));
    }
    expect(
      () => FeedingWaterReading(
        temperatureDeciC: 270,
        phHundredths: 700,
        recordedAtMs: -1,
      ),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('porsi nol hasil pembulatan bukan pengukuran hilang dan tidak disimpan sebagai aktual nol', () {
    final r = recommendFeedingSlot(
      plan: plan(population: 1, weight: 200),
      minute: 480,
      reading: water(270),
    );
    expect(r.status, SlotRecommendationStatus.zeroPortion);
    expect(r.recommendedGrams, 0);
    expect(r.permitsActualEntry, isFalse);
  });

  test('snapshot rekomendasi menyimpan satuan presisi dan tak berubah oleh perhitungan berikutnya', () {
    final p = plan();
    final r = recommendFeedingSlot(
      plan: p,
      minute: 480,
      reading: water(230, 725),
    );
    final snapshot = r.toSnapshot();
    recommendFeedingSlot(
      plan: plan(weight: 6000),
      minute: 480,
      reading: water(270),
    );
    expect(r.toSnapshot(), snapshot);
    expect(snapshot['water_temperature_deci_c'], 230);
    expect(snapshot['water_ph_hundredths'], 725);
    expect(snapshot['recommended_g'], 500);
    expect(() => p.slots.clear(), throwsUnsupportedError);
  });

  test(
    'slot di luar jadwal ditolak dan perhitungan manual lama tidak berubah',
    () {
      expect(
        () => recommendFeedingSlot(
          plan: plan(),
          minute: 123,
          reading: water(270),
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(dailyNeed(population: 100, weightCg: 10000, rateBp: 300), 300);
      expect(pendingPortions(1000, 400, 1), [600]);
    },
  );
}
