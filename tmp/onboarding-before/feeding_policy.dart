import 'cycle_rules.dart';
import 'master_data.dart';

/// Rules selected in PRD 15.8, active for tagged lele cycles since stage 4.
/// The source table was adapted for continuous weights; this is not a claim of
/// certification or a general standard for ordinary ponds.
const weightFeedingPolicyVersion = 'lele_weight_2026_10_v1';
const weightFeedingPolicyReference = 'PRD 15.8 — tabel bobot pilihan pengguna';

enum RateStatus { available, missingWeight, belowReference }

class WeightRate {
  const WeightRate._(this.status, this.rateBp, this.reason);
  final RateStatus status;

  /// Hundredths of percent: 250 means 2.5% of biomass per day.
  final int? rateBp;
  final String? reason;
}

WeightRate rateForWeight(int? weightCg) {
  if (weightCg == null) {
    return const WeightRate._(
      RateStatus.missingWeight,
      null,
      'Bobot ikan belum tersedia.',
    );
  }
  checkedInteger(BigInt.from(weightCg));
  if (weightCg == 0) throw const ValidationFailure('Bobot ikan harus positif.');
  if (weightCg < 200) {
    return const WeightRate._(
      RateStatus.belowReference,
      null,
      'Rate untuk bobot kurang dari 2 gram belum memiliki acuan yang disepakati.',
    );
  }
  final rate = switch (weightCg) {
    <= 500 => 500,
    <= 1000 => 400,
    <= 3500 => 300,
    <= 5000 => 250,
    <= 7000 => 220,
    _ => 200,
  };
  return WeightRate._(RateStatus.available, rate, null);
}

enum NormalPlanStatus { ready, missingData, unsupportedWeight, noFish }

class NormalFeedingSlot {
  const NormalFeedingSlot(this.minute, this.grams);
  final int minute;
  final int grams;
}

/// A normal daily baseline, before applying each slot's water measurement.
/// Does not consume actual feedings or redistribute previously missed amounts.
class NormalFeedingPlan {
  NormalFeedingPlan._(
    this.status,
    this.population,
    this.weightCg,
    this.rate,
    this.dailyGrams,
    List<NormalFeedingSlot> slots,
    this.reason,
  ) : slots = List.unmodifiable(slots);
  final NormalPlanStatus status;
  final int? population, weightCg, dailyGrams;
  final WeightRate rate;
  final List<NormalFeedingSlot> slots;
  final String? reason;
  String get policyVersion => weightFeedingPolicyVersion;
  int? get biomassCg => population == null || weightCg == null
      ? null
      : checkedInteger(BigInt.from(population!) * BigInt.from(weightCg!));

  Map<String, Object?> toSnapshot() => {
    'policy_version': policyVersion,
    'rate_reference': weightFeedingPolicyReference,
    'status': status.name,
    'population': population,
    'biomass_cg': biomassCg,
    'weight_cg': weightCg,
    'rate_bp': rate.rateBp,
    'normal_daily_g': dailyGrams,
    'reason': reason,
    'slots': [
      for (final slot in slots) {'minute': slot.minute, 'normal_g': slot.grams},
    ],
  };
}

NormalFeedingPlan normalFeedingPlan({
  required int? population,
  required int? weightCg,
  required List<int> times,
}) {
  final hours = validTimes(times);
  if (population != null) checkedInteger(BigInt.from(population));
  final rate = rateForWeight(weightCg);
  if (population != null && weightCg != null) {
    // Biomass is also persisted in integer units in a feeding snapshot.
    checkedInteger(BigInt.from(population) * BigInt.from(weightCg));
  }
  if (population == null || weightCg == null) {
    return NormalFeedingPlan._(
      NormalPlanStatus.missingData,
      population,
      weightCg,
      rate,
      null,
      [],
      'Populasi atau bobot ikan belum lengkap.',
    );
  }
  if (population == 0) {
    return NormalFeedingPlan._(
      NormalPlanStatus.noFish,
      population,
      weightCg,
      rate,
      0,
      [for (final hour in hours) NormalFeedingSlot(hour, 0)],
      'Populasi kolam nol.',
    );
  }
  if (rate.rateBp == null) {
    return NormalFeedingPlan._(
      NormalPlanStatus.unsupportedWeight,
      population,
      weightCg,
      rate,
      null,
      [],
      rate.reason,
    );
  }
  final need = dailyNeed(
    population: population,
    weightCg: weightCg,
    rateBp: rate.rateBp!,
  );
  final portions = splitGrams(need, hours.length);
  return NormalFeedingPlan._(
    NormalPlanStatus.ready,
    population,
    weightCg,
    rate,
    need,
    [
      for (var i = 0; i < hours.length; i++)
        NormalFeedingSlot(hours[i], portions[i]),
    ],
    null,
  );
}

/// Manual water measurement. Technical input limits are not safe-farming limits.
class FeedingWaterReading {
  FeedingWaterReading({
    required this.temperatureDeciC,
    required this.phHundredths,
    required this.recordedAtMs,
  }) {
    if (temperatureDeciC < 0 ||
        temperatureDeciC > 500 ||
        phHundredths < 0 ||
        phHundredths > 1400 ||
        recordedAtMs < 0) {
      throw const ValidationFailure(
        'Pengukuran suhu/pH atau waktu pencatatan tidak valid.',
      );
    }
    checkedInteger(BigInt.from(recordedAtMs));
  }
  final int temperatureDeciC, phHundredths, recordedAtMs;
  Map<String, Object?> toSnapshot() => {
    'water_temperature_deci_c': temperatureDeciC,
    'water_ph_hundredths': phHundredths,
    'water_recorded_at_ms': recordedAtMs,
  };
}

enum TemperatureCondition { cold, normal, noRule, high }

enum PhCondition { normal, outsideReference }

class WaterConditions {
  const WaterConditions(this.temperature, this.ph);
  final TemperatureCondition temperature;
  final PhCondition ph;
  bool get permitsRecommendation =>
      ph == PhCondition.normal &&
      (temperature == TemperatureCondition.cold ||
          temperature == TemperatureCondition.normal);
}

WaterConditions waterConditions(FeedingWaterReading reading) => WaterConditions(
  reading.temperatureDeciC < 240
      ? TemperatureCondition.cold
      : reading.temperatureDeciC < 250
      ? TemperatureCondition.noRule
      : reading.temperatureDeciC <= 300
      ? TemperatureCondition.normal
      : TemperatureCondition.high,
  reading.phHundredths >= 650 && reading.phHundredths <= 800
      ? PhCondition.normal
      : PhCondition.outsideReference,
);

enum SlotRecommendationStatus {
  recommended,
  measurementRequired,
  waterWarning,
  missingData,
  unsupportedWeight,
  noFish,
  zeroPortion,
}

class SlotRecommendation {
  const SlotRecommendation._(
    this.status,
    this.minute,
    this.normalGrams,
    this.recommendedGrams,
    this.temperaturePercent,
    this.temperatureReductionGrams,
    this.reading,
    this.conditions,
    this.reason,
  );
  final SlotRecommendationStatus status;
  final int minute;
  final int? normalGrams,
      recommendedGrams,
      temperaturePercent,
      temperatureReductionGrams;
  final FeedingWaterReading? reading;
  final WaterConditions? conditions;
  final String? reason;

  /// Does not authorize saving: active-cycle, stock, date, staleness and
  /// idempotency validation must still run inside the transaction in stage 4.
  bool get permitsActualEntry =>
      status == SlotRecommendationStatus.recommended ||
      status == SlotRecommendationStatus.waterWarning;

  Map<String, Object?> toSnapshot() => {
    'policy_version': weightFeedingPolicyVersion,
    'minute': minute,
    'status': status.name,
    'normal_slot_g': normalGrams,
    'recommended_g': recommendedGrams,
    'temperature_percent': temperaturePercent,
    'temperature_reduction_g': temperatureReductionGrams,
    'temperature_status': conditions?.temperature.name,
    'ph_status': conditions?.ph.name,
    'reason': reason,
    ...?reading?.toSnapshot(),
  };
}

SlotRecommendation recommendFeedingSlot({
  required NormalFeedingPlan plan,
  required int minute,
  required FeedingWaterReading? reading,
}) {
  if (minute < 0 || minute >= 1440)
    throw const ValidationFailure('Jam pemberian tidak valid.');
  if (plan.status != NormalPlanStatus.ready) {
    final status = switch (plan.status) {
      NormalPlanStatus.missingData => SlotRecommendationStatus.missingData,
      NormalPlanStatus.unsupportedWeight =>
        SlotRecommendationStatus.unsupportedWeight,
      NormalPlanStatus.noFish => SlotRecommendationStatus.noFish,
      NormalPlanStatus.ready => throw StateError('Unexpected ready state'),
    };
    return SlotRecommendation._(
      status,
      minute,
      null,
      null,
      null,
      null,
      reading,
      reading == null ? null : waterConditions(reading),
      plan.reason,
    );
  }
  final slots = plan.slots.where((s) => s.minute == minute);
  if (slots.isEmpty)
    throw const ValidationFailure('Jam tidak terdaftar dalam jadwal hari ini.');
  final normal = slots.single.grams;
  final conditions = reading == null ? null : waterConditions(reading);
  if (normal == 0) {
    return SlotRecommendation._(
      SlotRecommendationStatus.zeroPortion,
      minute,
      0,
      0,
      null,
      0,
      reading,
      conditions,
      'Porsi normal membulat ke nol; tidak membuat pemberian nol.',
    );
  }
  if (reading == null) {
    return SlotRecommendation._(
      SlotRecommendationStatus.measurementRequired,
      minute,
      normal,
      null,
      null,
      null,
      null,
      null,
      'Ukur dan masukkan suhu air serta pH untuk pemberian ini.',
    );
  }
  if (!conditions!.permitsRecommendation) {
    return SlotRecommendation._(
      SlotRecommendationStatus.waterWarning,
      minute,
      normal,
      null,
      null,
      null,
      reading,
      conditions,
      'Kondisi air di luar acuan rekomendasi. Angka rekomendasi otomatis tidak tersedia.',
    );
  }
  final percent = conditions.temperature == TemperatureCondition.cold
      ? 80
      : 100;
  final grams = halfUp(
    BigInt.from(normal) * BigInt.from(percent),
    BigInt.from(100),
  );
  return SlotRecommendation._(
    SlotRecommendationStatus.recommended,
    minute,
    normal,
    grams,
    percent,
    normal - grams,
    reading,
    conditions,
    null,
  );
}
