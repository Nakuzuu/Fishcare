import 'cycle_rules.dart';
import 'feeding_policy.dart';
import 'master_data.dart';

enum FeedingSlotState { pending, given, skipped, stopped }

/// Actual historical grams remain independent of the latest normal baseline.
class DailyFeedingRecord {
  DailyFeedingRecord({
    required this.id,
    required this.minute,
    required this.actualGrams,
    this.cancelled = false,
  }) {
    if (id.isEmpty || minute < 0 || minute >= 1440 || actualGrams <= 0) {
      throw const ValidationFailure('Catatan pemberian harian tidak valid.');
    }
    checkedInteger(BigInt.from(actualGrams));
  }
  final String id;
  final int minute, actualGrams;
  final bool cancelled;
}

class ActualFeedingReview {
  const ActualFeedingReview({
    required this.totalAfterGrams,
    required this.exceedsRecommendation,
    required this.exceedsNormalSlot,
    required this.exceedsNormalDay,
  });
  final int totalAfterGrams;
  final bool exceedsRecommendation, exceedsNormalSlot, exceedsNormalDay;
  bool get requiresExtraConfirmation =>
      exceedsRecommendation || exceedsNormalSlot || exceedsNormalDay;
}

/// Current-day projection under the new policy. Skipped/underfed slots do not
/// contribute extra grams to pending slots. This is not the legacy allocator.
class FeedingDayPlan {
  FeedingDayPlan({
    required this.normal,
    required Map<int, FeedingSlotState> states,
    required List<DailyFeedingRecord> records,
  }) : states = Map.unmodifiable(states),
       records = List.unmodifiable(records) {
    if (normal.status != NormalPlanStatus.ready &&
        normal.status != NormalPlanStatus.noFish) {
      throw ValidationFailure(
        normal.reason ?? 'Belum bisa menghitung porsi harian.',
      );
    }
    final hours = normal.slots.map((s) => s.minute).toSet();
    if (states.length != hours.length || !hours.every(states.containsKey)) {
      throw const ValidationFailure('Status slot tidak sesuai jadwal harian.');
    }
    final ids = <String>{};
    final active = <int>{};
    var sum = BigInt.zero;
    for (final record in records) {
      if (!ids.add(record.id) || !hours.contains(record.minute)) {
        throw const ValidationFailure(
          'Catatan pemberian ganda atau di luar jadwal.',
        );
      }
      if (record.cancelled) continue;
      if (!active.add(record.minute) ||
          states[record.minute] != FeedingSlotState.given) {
        throw const ValidationFailure(
          'Pemberian sah tidak sesuai status slot.',
        );
      }
      sum += BigInt.from(record.actualGrams);
    }
    for (final entry in states.entries) {
      if (entry.value == FeedingSlotState.given &&
          !active.contains(entry.key)) {
        throw const ValidationFailure(
          'Snapshot pemberian slot tidak tersedia.',
        );
      }
    }
    actualGrams = checkedInteger(sum);
  }

  final NormalFeedingPlan normal;
  final Map<int, FeedingSlotState> states;
  final List<DailyFeedingRecord> records;
  late final int actualGrams;
  int get excessActualGrams => remainingGrams(actualGrams, normal.dailyGrams!);
  List<NormalFeedingSlot> get pendingSlots => List.unmodifiable(
    normal.slots.where(
      (slot) => states[slot.minute] == FeedingSlotState.pending,
    ),
  );

  SlotRecommendation recommend(int minute, FeedingWaterReading? reading) {
    if (states[minute] != FeedingSlotState.pending) {
      throw const ValidationFailure(
        'Rekomendasi hanya untuk slot yang masih menunggu.',
      );
    }
    return recommendFeedingSlot(plan: normal, minute: minute, reading: reading);
  }

  ActualFeedingReview reviewActual({
    required int minute,
    required int grams,
    required FeedingWaterReading? reading,
  }) {
    if (grams <= 0)
      throw const ValidationFailure('Jumlah aktual harus positif.');
    checkedInteger(BigInt.from(grams));
    final recommendation = recommend(minute, reading);
    if (!recommendation.permitsActualEntry) {
      throw ValidationFailure(
        recommendation.reason ?? 'Pemberian belum dapat dicatat.',
      );
    }
    final total = checkedInteger(BigInt.from(actualGrams) + BigInt.from(grams));
    return ActualFeedingReview(
      totalAfterGrams: total,
      exceedsRecommendation:
          recommendation.recommendedGrams != null &&
          grams > recommendation.recommendedGrams!,
      exceedsNormalSlot: grams > recommendation.normalGrams!,
      exceedsNormalDay: total > normal.dailyGrams!,
    );
  }
}
