import 'package:flutter/material.dart';

import 'design_system.dart';
import 'feed_ui.dart' show actionLabel;
import 'cycle_rules.dart' show timeText;
import 'ui_format.dart';
import 'grading.dart';
import 'water_snapshot_ui.dart';
import 'report_rules.dart';
import 'harvest_result_ui.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.row, this.onCancel});
  final Map<String, Object?> row;
  final VoidCallback? onCancel;
  @override
  Widget build(BuildContext context) {
    final kind = row['kind'] as String? ?? 'feeding';
    final cancelled = row['cancel_action_id'] != null;
    final quantity = (row['quantity'] ?? row['actual_g']) as int?;
    return FishCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            kind == 'sampling' ? gradingLabel(row) : actionLabel(kind),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                uiDate(row['business_date'] as String),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              StatusBadge(cancelled ? 'Batal' : 'Sah', warning: cancelled),
            ],
          ),
          if (quantity != null)
            ValueRow(
              kind == 'sampling' ? 'Jumlah sampel' : 'Jumlah',
              '${uiNumber(quantity)} ${kind == 'feeding' ? 'g' : 'ekor'}',
            ),
          if (row['cycle_start'] != null)
            Text(
              'Siklus ${uiDate(row['cycle_start'] as String)} · ${row['cycle_fish']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (row['value_rp'] is int)
            ValueRow('Nilai panen', uiMoney(row['value_rp'] as int)),
          if (row['cost_snapshot'] is int)
            ValueRow('Biaya pakan', uiMoney(row['cost_snapshot'] as int)),
          if (row['harvest_feed_result'] is HarvestFeedResult)
            HarvestFeedResultTable(
              result: row['harvest_feed_result'] as HarvestFeedResult,
            ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => ActivityDetail(row: row)),
            ),
            child: const Text('Detail kegiatan'),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onCancel,
              child: Text(
                kind == 'feeding'
                    ? 'Batalkan pemberian terakhir'
                    : 'Batalkan kegiatan terakhir',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ActivityDetail extends StatelessWidget {
  const ActivityDetail({super.key, required this.row});
  final Map<String, Object?> row;
  @override
  Widget build(BuildContext context) {
    final kind = row['kind'] as String? ?? 'feeding';
    return Scaffold(
      appBar: FishAppBar(
        title: Text(kind == 'sampling' ? gradingLabel(row) : actionLabel(kind)),
      ),
      body: SafeArea(
        child: FormList(
          children: [
            FishCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ValueRow('Tanggal', uiDate(row['business_date'] as String)),
                  ValueRow(
                    'Status',
                    row['cancel_action_id'] == null
                        ? 'Sah'
                        : 'Batal — dikecualikan dari total',
                  ),
                  if (row['minute'] is int)
                    ValueRow('Jam pemberian', timeText(row['minute'] as int)),
                  if (kind == 'feeding') WaterSnapshot(row: row),
                  if (row['quantity'] is int || row['actual_g'] is int)
                    ValueRow(
                      'Jumlah',
                      '${uiNumber((row['quantity'] ?? row['actual_g']) as int)} ${kind == 'feeding' ? 'g' : 'ekor'}',
                    ),
                  if (row['before_count'] is int)
                    ValueRow(
                      'Populasi sebelum → setelah',
                      '${uiNumber(row['before_count'] as int)} → ${uiNumber(row['after_count'] as int)} ekor',
                    ),
                  if (row['before_weight_cg'] is int)
                    ValueRow(
                      'Bobot sebelum → setelah',
                      '${uiDecimal(row['before_weight_cg'] as int)} → ${uiDecimal(row['after_weight_cg'] as int)} g/ikan',
                    ),
                  if (row['price_snapshot'] is int)
                    ValueRow(
                      'Harga snapshot',
                      '${uiMoney(row['price_snapshot'] as int)}/kg',
                    ),
                  if (row['cost_snapshot'] is int)
                    ValueRow(
                      'Biaya snapshot',
                      uiMoney(row['cost_snapshot'] as int),
                    ),
                  if (row['rate_snapshot'] is int)
                    ValueRow(
                      'Rate snapshot',
                      '${uiDecimal(row['rate_snapshot'] as int)}%',
                    ),
                  if (row['biomass_snapshot_cg'] is int)
                    ValueRow(
                      'Biomassa snapshot',
                      '${uiDecimal(row['biomass_snapshot_cg'] as int)} g',
                    ),
                  if (row['harvest_weight_cg'] is int)
                    ValueRow(
                      'Bobot panen',
                      '${uiDecimal(row['harvest_weight_cg'] as int)} g/ikan',
                    ),
                  if (row['price_rp_kg'] is int)
                    ValueRow(
                      'Harga panen snapshot',
                      '${uiMoney(row['price_rp_kg'] as int)}/kg',
                    ),
                  if (row['value_rp'] is int)
                    ValueRow(
                      'Nilai panen snapshot',
                      uiMoney(row['value_rp'] as int),
                    ),
                ],
              ),
            ),
            if (row['cancel_reason'] != null)
              Notice('Alasan batal: ${row['cancel_reason']}', warning: true),
            if (row['harvest_feed_result'] is HarvestFeedResult)
              HarvestFeedResultTable(
                result: row['harvest_feed_result'] as HarvestFeedResult,
              ),
            ExpansionTile(
              title: const Text('Identitas pencatatan'),
              children: [
                SelectableText('ID ${row['id']}\nID siklus ${row['cycle_id']}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
