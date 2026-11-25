import 'package:sqflite/sqflite.dart';

import 'cycle_repository.dart';
import 'cycle_rules.dart';
import 'master_data.dart';

int requiredPositive(Map<String, Object?> payload, String key, String label) {
  final value = payload[key];
  if (value is! int || value <= 0)
    throw ValidationFailure('$label wajib bilangan positif yang valid.');
  checkedInteger(BigInt.from(value));
  return value;
}

Future<void> appendOperation(
  DatabaseExecutor db,
  String id,
  String kind,
  Map<String, Object?> cycle,
  String date,
  int quantity,
  int afterCount,
  int afterWeight,
  int timestamp, {
  int? harvestWeight,
  int? price,
  int? value,
}) async {
  await db.insert('operations', {
    'id': id,
    'kind': kind,
    'cycle_id': cycle['id'],
    'business_date': date,
    'before_count': cycle['current_count'],
    'after_count': afterCount,
    'before_weight_cg': cycle['current_weight_cg'],
    'after_weight_cg': afterWeight,
    'quantity': quantity,
    'harvest_weight_cg': harvestWeight,
    'price_rp_kg': price,
    'value_rp': value,
    'created_at_ms': timestamp,
  });
}

Future<Map<String, Object?>> lastCancelable(
  DatabaseExecutor db,
  String id,
  String date,
) async {
  final rows = await db.query('operations', where: 'id=?', whereArgs: [id]);
  if (rows.isEmpty) throw const ValidationFailure('Kegiatan tidak ditemukan.');
  final op = rows.single;
  final latest = await db.query(
    'operations',
    where: 'cycle_id=? AND cancel_action_id IS NULL',
    whereArgs: [op['cycle_id']],
    orderBy: 'seq DESC',
    limit: 1,
  );
  if (op['cancel_action_id'] != null ||
      op['business_date'] != date ||
      latest.isEmpty ||
      latest.single['id'] != id ||
      ['final', 'close'].contains(op['kind'])) {
    throw const ValidationFailure(
      'Pembatalan ditolak: kegiatan bukan sah terakhir hari ini, sudah batal, atau memiliki kegiatan operasional lanjutan. Panen akhir tidak dapat dibatalkan.',
    );
  }
  return op;
}

Future<void> lifecycleTransaction(
  DatabaseExecutor db,
  SqliteCycleRepository cycles,
  String id,
  String kind,
  Map<String, Object?> p,
  String date,
) async {
  if (kind == 'cancel_operation') {
    final reason = (p['reason'] as String? ?? '').trim();
    if (reason.isEmpty) throw const ValidationFailure('Alasan wajib diisi.');
    final op = await lastCancelable(db, p['operation'] as String, date);
    if (op['kind'] == 'feeding')
      throw const ValidationFailure('Gunakan pembatalan pemberian.');
    final c = await cycles.cycleIn(db, op['cycle_id'] as String);
    await db.update(
      'operations',
      {'cancel_action_id': id, 'cancel_reason': reason},
      where: 'id=?',
      whereArgs: [op['id']],
    );
    await db.update(
      'cycles',
      {
        'current_count': op['before_count'],
        'current_weight_cg': op['before_weight_cg'],
      },
      where: 'id=?',
      whereArgs: [c['id']],
    );
    await cycles.refreshDayIn(
      db,
      await cycles.cycleIn(db, c['id'] as String),
      date,
    );
    return;
  }
  final c = await cycles.cycleIn(db, p['cycle'] as String);
  final count = c['current_count'] as int,
      weight = c['current_weight_cg'] as int;
  await cycles.refreshDayIn(db, c, date);
  int quantity = 0, after = count, afterWeight = weight;
  int? harvestWeight, price, value;
  if (kind == 'sampling') {
    quantity = requiredPositive(p, 'count', 'Jumlah sampel');
    afterWeight = requiredPositive(p, 'weight', 'Bobot sampel');
    if (quantity <= 0 || quantity > count || afterWeight <= 0)
      throw const ValidationFailure(
        'Sampel positif tidak boleh melebihi populasi; bobot harus positif.',
      );
    checkedInteger(BigInt.from(afterWeight));
    if ((await db.query(
      'operations',
      where: "cycle_id=? AND business_date=? AND kind='sampling' AND cancel_action_id IS NULL",
      whereArgs: [c['id'], date],
    )).isNotEmpty)
      throw const ValidationFailure('Sampling sah hari ini sudah ada.');
  } else if (kind == 'death' || kind == 'partial') {
    quantity = requiredPositive(p, 'count', 'Jumlah');
    if (quantity <= 0 ||
        quantity > count ||
        (kind == 'partial' && quantity == count))
      throw const ValidationFailure(
        'Jumlah melebihi populasi atau panen parsial tidak menyisakan ikan.',
      );
    after = count - quantity;
  } else if (kind == 'final') {
    // Populasi terbaru dibaca dalam transaksi; pratinjau berubah meminta konfirmasi ulang.
    if (p['expected_count'] != count)
      throw const ValidationFailure('Populasi berubah. Tinjau penutupan lagi.');
    quantity = count;
    after = 0;
  } else {
    throw const ValidationFailure('Jenis kegiatan tidak tersedia.');
  }
  if (kind == 'partial' || (kind == 'final' && count > 0)) {
    harvestWeight = requiredPositive(p, 'weight', 'Bobot panen');
    price = requiredPositive(p, 'price', 'Harga jual');
    value = harvestValue(quantity, harvestWeight, price);
  }
  await appendOperation(
    db,
    id,
    kind == 'final' && count == 0 ? 'close' : kind,
    c,
    date,
    quantity,
    after,
    afterWeight,
    cycles.clock().millisecondsSinceEpoch,
    harvestWeight: harvestWeight,
    price: price,
    value: value,
  );
  await db.update(
    'cycles',
    {
      'current_count': after,
      'current_weight_cg': afterWeight,
      if (kind == 'final') 'status': 'closed',
      if (kind == 'final') 'closed_action_id': id,
    },
    where: 'id=?',
    whereArgs: [c['id']],
  );
  if (kind == 'final') {
    // Existing CHECK supports skipped; closure is explicit in cycle/operation, not a user skip.
    await db.update(
      'cycle_slots',
      {'status': 'skipped', 'stopped_action_id': id},
      where: "cycle_id=? AND status='pending'",
      whereArgs: [c['id']],
    );
  } else {
    await cycles.refreshDayIn(
      db,
      await cycles.cycleIn(db, c['id'] as String),
      date,
    );
  }
}
