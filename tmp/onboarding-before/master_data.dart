import 'dart:math';

enum MasterKind { pond, feed }

class ValidationFailure implements Exception {
  const ValidationFailure(this.message, {this.field = 'name'});
  final String message;
  final String field;
}

String normalizedName(String value) {
  final name = value.trim();
  if (name.isEmpty) throw const ValidationFailure('Nama wajib diisi.');
  return name.toLowerCase();
}

int parsePrice(String raw) {
  final value = raw.trim();
  if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
    throw const ValidationFailure(
      'Isi rupiah bulat tanpa pemisah ribuan, contoh 1500.',
      field: 'price',
    );
  }
  final significant = value.replaceFirst(RegExp(r'^0+'), '');
  if (significant.length > 19) {
    throw const ValidationFailure(
      'Harga melebihi kapasitas penyimpanan.',
      field: 'price',
    );
  }
  final parsed = BigInt.parse(significant.isEmpty ? '0' : significant);
  if (parsed <= BigInt.zero || parsed > BigInt.parse('9223372036854775807')) {
    throw const ValidationFailure(
      'Harga harus positif dan tidak melebihi kapasitas penyimpanan.',
      field: 'price',
    );
  }
  return parsed.toInt();
}

String newMasterId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

class MasterRecord {
  const MasterRecord({
    required this.id,
    required this.kind,
    required this.name,
    this.notes = '',
    this.size = '',
    this.price,
    this.archived = false,
    this.revision = 1,
  });
  final String id;
  final MasterKind kind;
  final String name;
  final String notes;
  final String size;
  final int? price;
  final bool archived;
  final int revision;
}

abstract interface class MasterRepository {
  Future<List<MasterRecord>> list(MasterKind kind, {required bool archived});
  Future<MasterRecord> get(MasterKind kind, String id);
  Future<void> save(MasterRecord record, {required bool create});
  Future<void> archive(MasterRecord record);
}
