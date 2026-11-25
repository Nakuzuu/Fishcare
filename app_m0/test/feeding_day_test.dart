import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/feeding_day.dart';
import 'package:fishcare_m0/feeding_policy.dart';
import 'package:fishcare_m0/master_data.dart';

FeedingWaterReading water(int temperature) => FeedingWaterReading(
  temperatureDeciC: temperature,
  phHundredths: 700,
  recordedAtMs: 1792886400000,
);

NormalFeedingPlan baseline({int population = 800, int weight = 5000}) =>
    normalFeedingPlan(
      population: population,
      weightCg: weight,
      times: [480, 960],
    );

void main() {
  test('aktual350 dari rekomendasi400 tidak menambah porsi sore normal500', () {
    final record = DailyFeedingRecord(
      id: 'morning',
      minute: 480,
      actualGrams: 350,
    );
    final day = FeedingDayPlan(
      normal: baseline(),
      states: {480: FeedingSlotState.given, 960: FeedingSlotState.pending},
      records: [record],
    );
    expect(day.actualGrams, 350);
    expect(day.pendingSlots.single.grams, 500);
    expect(day.recommend(960, water(270)).recommendedGrams, 500);
    expect(day.recommend(960, water(230)).recommendedGrams, 400);
    expect(record.actualGrams, 350);
  });

  test('Lewati tidak memindahkan500g ke sore atau membuat aktual nol', () {
    final day = FeedingDayPlan(
      normal: baseline(),
      states: {480: FeedingSlotState.skipped, 960: FeedingSlotState.pending},
      records: [],
    );
    expect(day.actualGrams, 0);
    expect(day.pendingSlots.single.grams, 500);
    expect(day.recommend(960, water(270)).recommendedGrams, 500);
    expect(
      () => day.recommend(480, water(270)),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('grading/populasi terbaru membagi seluruh jadwal, tidak menghitung sisa dari aktual', () {
    final records = [
      DailyFeedingRecord(id: 'morning', minute: 480, actualGrams: 400),
    ];
    final day = FeedingDayPlan(
      normal: baseline(population: 960),
      states: {480: FeedingSlotState.given, 960: FeedingSlotState.pending},
      records: records,
    );
    expect(day.normal.dailyGrams, 1200);
    expect(day.pendingSlots.single.grams, 600);
    expect(day.recommend(960, water(270)).recommendedGrams, 600);
    expect(day.actualGrams, 400);
    final afterDeaths = FeedingDayPlan(
      normal: baseline(population: 400),
      states: day.states,
      records: records,
    );
    expect(afterDeaths.normal.dailyGrams, 500);
    expect(afterDeaths.pendingSlots.single.grams, 250);
  });

  test('grading melewati batas rate mengubah baseline tetapi snapshot rekomendasi lama utuh', () {
    final oldPlan = baseline(population: 1000);
    final before = recommendFeedingSlot(
      plan: oldPlan,
      minute: 480,
      reading: water(270),
    );
    final snapshot = before.toSnapshot();
    final day = FeedingDayPlan(
      normal: baseline(population: 1000, weight: 5001),
      states: {480: FeedingSlotState.given, 960: FeedingSlotState.pending},
      records: [
        DailyFeedingRecord(id: 'morning', minute: 480, actualGrams: 625),
      ],
    );
    expect(day.normal.rate.rateBp, 220);
    expect(day.normal.dailyGrams, 1100);
    expect(day.pendingSlots.single.grams, 550);
    expect(before.toSnapshot(), snapshot);
    expect(before.recommendedGrams, 625);
  });

  test(
    'aktual melebihi rekomendasi atau total harian meminta konfirmasi tambahan',
    () {
      final day = FeedingDayPlan(
        normal: baseline(),
        states: {480: FeedingSlotState.given, 960: FeedingSlotState.pending},
        records: [
          DailyFeedingRecord(id: 'morning', minute: 480, actualGrams: 700),
        ],
      );
      final review = day.reviewActual(
        minute: 960,
        grams: 400,
        reading: water(230),
      );
      expect(review.exceedsRecommendation, isFalse);
      expect(review.exceedsNormalSlot, isFalse);
      expect(review.exceedsNormalDay, isTrue);
      expect(review.requiresExtraConfirmation, isTrue);
      expect(review.totalAfterGrams, 1100);
      final larger = day.reviewActual(
        minute: 960,
        grams: 450,
        reading: water(230),
      );
      expect(larger.exceedsRecommendation, isTrue);
      expect(day.pendingSlots.single.grams, 500);
      expect(day.actualGrams, 700);
    },
  );

  test('kebutuhan turun di bawah aktual memperlihatkan kelebihan tanpa menarik stok', () {
    final day = FeedingDayPlan(
      normal: baseline(population: 200),
      states: {480: FeedingSlotState.given, 960: FeedingSlotState.pending},
      records: [
        DailyFeedingRecord(id: 'morning', minute: 480, actualGrams: 400),
      ],
    );
    expect(day.normal.dailyGrams, 250);
    expect(day.excessActualGrams, 150);
    expect(day.actualGrams, 400);
    expect(
      day
          .reviewActual(minute: 960, grams: 125, reading: water(270))
          .requiresExtraConfirmation,
      isTrue,
    );
  });

  test('pembatalan mengecualikan aktual lama dan hanya membuka slotnya, tanpa redistribusi', () {
    final day = FeedingDayPlan(
      normal: baseline(),
      states: {480: FeedingSlotState.pending, 960: FeedingSlotState.skipped},
      records: [
        DailyFeedingRecord(
          id: 'cancelled',
          minute: 480,
          actualGrams: 400,
          cancelled: true,
        ),
      ],
    );
    expect(day.actualGrams, 0);
    expect(day.pendingSlots.single.minute, 480);
    expect(day.pendingSlots.single.grams, 500);
    expect(day.records.single.actualGrams, 400);
    expect(
      day.recommend(480, null).status,
      SlotRecommendationStatus.measurementRequired,
    );
  });

  test('semua slot selesai/dilewati tidak membuat slot tambahan', () {
    final day = FeedingDayPlan(
      normal: baseline(),
      states: {480: FeedingSlotState.given, 960: FeedingSlotState.skipped},
      records: [
        DailyFeedingRecord(id: 'morning', minute: 480, actualGrams: 350),
      ],
    );
    expect(day.pendingSlots, isEmpty);
    expect(day.states.length, 2);
    expect(
      () => day.recommend(960, water(270)),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('aktual memerlukan pengukuran baru, nol invalid, kondisi32C tetap boleh ditinjau', () {
    final day = FeedingDayPlan(
      normal: baseline(),
      states: {480: FeedingSlotState.pending, 960: FeedingSlotState.pending},
      records: [],
    );
    expect(
      () => day.reviewActual(minute: 480, grams: 400, reading: null),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      () => day.reviewActual(minute: 480, grams: 0, reading: water(270)),
      throwsA(isA<ValidationFailure>()),
    );
    final review = day.reviewActual(
      minute: 480,
      grams: 400,
      reading: water(320),
    );
    expect(review.totalAfterGrams, 400);
    expect(day.recommend(480, water(320)).recommendedGrams, isNull);
  });

  test(
    'duplikasi atau status tidak cocok ditolak, bukan diam-diam dijumlah',
    () {
      final record = DailyFeedingRecord(
        id: 'one',
        minute: 480,
        actualGrams: 400,
      );
      expect(
        () => FeedingDayPlan(
          normal: baseline(),
          states: {480: FeedingSlotState.given, 960: FeedingSlotState.pending},
          records: [record, record],
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => FeedingDayPlan(
          normal: baseline(),
          states: {
            480: FeedingSlotState.pending,
            960: FeedingSlotState.pending,
          },
          records: [record],
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => FeedingDayPlan(
          normal: baseline(),
          states: {480: FeedingSlotState.pending},
          records: [],
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => FeedingDayPlan(
          normal: baseline(),
          states: {480: FeedingSlotState.given, 960: FeedingSlotState.pending},
          records: [],
        ),
        throwsA(isA<ValidationFailure>()),
      );
    },
  );
}
