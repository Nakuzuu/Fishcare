import 'master_data.dart';

final int64Max = BigInt.parse('9223372036854775807');
int checkedInteger(BigInt value) {
  if (value < BigInt.zero || value > int64Max) {
    throw const ValidationFailure(
      'Angka atau hasil perhitungan melebihi kapasitas penyimpanan.',
    );
  }
  return value.toInt();
}

int parseCount(String raw) {
  final value = raw.trim();
  if (!RegExp(r'^\d+$').hasMatch(value))
    throw const ValidationFailure(
      'Jumlah ikan harus bilangan bulat positif tanpa pemisah ribuan.',
    );
  final significant = value.replaceFirst(RegExp(r'^0+'), '');
  if (significant.isEmpty || significant.length > 19)
    throw const ValidationFailure(
      'Jumlah ikan tidak valid atau terlalu besar.',
    );
  return checkedInteger(BigInt.parse(significant));
}

/// Dua desimal disimpan sebagai integer: bobot cg, rate 0,01 persen.
int parseHundredths(String raw, {bool rate = false}) {
  final value = raw.trim();
  if (!RegExp(r'^\d+(?:[.,]\d{1,2})?$').hasMatch(value)) {
    throw const ValidationFailure(
      'Isi angka positif maksimal dua desimal, tanpa pemisah ribuan.',
    );
  }
  final parts = value.replaceAll(',', '.').split('.');
  final whole = parts.first.replaceFirst(RegExp(r'^0+'), '');
  if (whole.length > 19) throw const ValidationFailure('Angka terlalu besar.');
  final scaled =
      BigInt.parse(whole.isEmpty ? '0' : whole) * BigInt.from(100) +
      BigInt.parse(parts.length == 2 ? parts[1].padRight(2, '0') : '0');
  if (scaled <= BigInt.zero || (rate && scaled > BigInt.from(10000))) {
    throw ValidationFailure(
      rate ? 'Rate harus >0 sampai 100%.' : 'Bobot harus >0.',
    );
  }
  return checkedInteger(scaled);
}

int halfUp(BigInt numerator, BigInt denominator) {
  if (numerator < BigInt.zero || denominator <= BigInt.zero)
    throw const ValidationFailure('Perhitungan tidak valid.');
  return checkedInteger((numerator + denominator ~/ BigInt.two) ~/ denominator);
}

int feedingCost(int actual, int price) {
  if (actual <= 0 || price <= 0)
    throw const ValidationFailure('Aktual dan harga harus positif.');
  return halfUp(BigInt.from(actual) * BigInt.from(price), BigInt.from(1000));
}

int harvestValue(int count, int weightCg, int price) {
  if (count <= 0 || weightCg <= 0 || price <= 0) {
    throw const ValidationFailure(
      'Jumlah, bobot panen dan harga harus positif.',
    );
  }
  for (final value in [count, weightCg, price]) {
    checkedInteger(BigInt.from(value));
  }
  return halfUp(
    BigInt.from(count) * BigInt.from(weightCg) * BigInt.from(price),
    BigInt.from(100000),
  );
}

int parseGrams(String raw, {bool zero = false}) {
  if (zero && RegExp(r'^0+$').hasMatch(raw.trim())) return 0;
  try {
    return parseCount(raw);
  } on ValidationFailure {
    throw ValidationFailure(
      zero
          ? 'Jumlah gram harus bulat nonnegatif tanpa pemisah ribuan dan dalam batas penyimpanan.'
          : 'Jumlah gram harus bulat positif tanpa pemisah ribuan dan dalam batas penyimpanan.',
    );
  }
}

int remainingGrams(int need, int actual) {
  checkedInteger(BigInt.from(need));
  checkedInteger(BigInt.from(actual));
  return need > actual ? need - actual : 0;
}

List<int> pendingPortions(int need, int actual, int count) {
  final remaining = remainingGrams(need, actual);
  if (count == 0) return [];
  return splitGrams(remaining, count);
}

int dailyNeed({
  required int population,
  required int weightCg,
  required int rateBp,
}) {
  if (population < 0 || weightCg <= 0 || rateBp <= 0 || rateBp > 10000)
    throw const ValidationFailure(
      'Belum bisa dihitung: populasi/bobot/rate tidak valid.',
    );
  for (final value in [population, weightCg, rateBp]) {
    checkedInteger(BigInt.from(value));
  }
  return halfUp(
    BigInt.from(population) * BigInt.from(weightCg) * BigInt.from(rateBp),
    BigInt.from(1000000),
  );
}

List<int> validTimes(List<int> values) {
  if (values.isEmpty ||
      values.length > 6 ||
      values.toSet().length != values.length ||
      values.any((v) => v < 0 || v > 1439)) {
    throw const ValidationFailure('Pilih 1–6 jam pemberian unik.');
  }
  return [...values]..sort();
}

List<int> splitGrams(int total, int slots) {
  checkedInteger(BigInt.from(total));
  if (slots < 1 || slots > 6)
    throw const ValidationFailure('Jumlah slot tidak valid.');
  return List.generate(
    slots,
    (i) => total ~/ slots + (i < total % slots ? 1 : 0),
  );
}

String decimalText(int scaled) =>
    '${scaled ~/ 100},${(scaled % 100).toString().padLeft(2, '0')}';
String timeText(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
const businessZones = {
  'Asia/Jakarta': 420,
  'Asia/Makassar': 480,
  'Asia/Jayapura': 540,
  'UTC': 0,
};
String? deviceBusinessZone() {
  final offset = DateTime.now().timeZoneOffset.inMinutes;
  for (final entry in businessZones.entries) {
    if (entry.value == offset) return entry.key;
  }
  return null;
}

String businessDate(DateTime now, String zone) {
  final offset = businessZones[zone];
  if (offset == null)
    throw const ValidationFailure('Pilih zona usaha yang didukung.');
  final local = now.toUtc().add(Duration(minutes: offset));
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String nextDate(String date) =>
    DateTime.parse('${date}T00:00:00Z')
        .add(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

class StartCycle {
  const StartCycle({
    required this.id,
    required this.pondId,
    required this.feedId,
    required this.fish,
    required this.count,
    required this.weightCg,
    required this.rateBp,
    required this.times,
    required this.zone,
    required this.date,
    this.feedingPolicy = 'legacy_manual',
  });
  final String id, pondId, feedId, fish, zone, date, feedingPolicy;
  final int count, weightCg;
  final int? rateBp;
  final List<int> times;
}

class CycleView {
  const CycleView({
    required this.id,
    required this.fish,
    required this.feedName,
    required this.startDate,
    required this.population,
    required this.weightCg,
    required this.rateBp,
    required this.need,
    required this.date,
    required this.zone,
    required this.times,
    required this.portions,
    required this.tomorrowTimes,
    this.actualToday = 0,
    this.statuses = const [],
    this.automatic = false,
    this.calculationIssue,
  });
  final String id, fish, feedName, startDate, date, zone;
  final int population, weightCg;
  final int? rateBp, need;
  final List<int> times, tomorrowTimes;
  final List<int?> portions;
  final bool automatic;
  final String? calculationIssue;
  final int actualToday;
  final List<String> statuses;
  int? get remaining {
    if (need == null) return null;
    if (!automatic) return remainingGrams(need!, actualToday);
    var total = BigInt.zero;
    for (var i = 0; i < portions.length; i++) {
      if (statuses[i] != 'pending') continue;
      if (portions[i] == null) return null;
      total += BigInt.from(portions[i]!);
    }
    return checkedInteger(total);
  }

  int? get excess => need == null ? null : remainingGrams(actualToday, need!);
}

abstract interface class CycleRepository {
  Future<String?> lockedZone();
  Future<CycleView?> active(String pondId);
  Future<void> start(StartCycle draft);
  Future<void> changeRate(
    String cycleId,
    int rateBp,
    String operationId,
    String expectedDate,
  );
  Future<void> changeTimes(
    String cycleId,
    List<int> times,
    String operationId,
    String expectedDate,
  );
}
