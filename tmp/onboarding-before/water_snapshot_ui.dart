import 'package:flutter/material.dart';

import 'design_system.dart';
import 'ui_format.dart';

class WaterSnapshot extends StatelessWidget {
  const WaterSnapshot({super.key, required this.row});
  final Map<String, Object?> row;
  @override
  Widget build(BuildContext context) {
    final temperature = row['water_temperature_deci_c'] as int?;
    final ph = row['water_ph_hundredths'] as int?;
    final stamp = row['water_recorded_at_ms'] as int?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueRow(
          'Suhu air saat pemberian',
          temperature == null
              ? 'Tidak tercatat'
              : '${uiDecimal(temperature * 10)} °C',
        ),
        ValueRow(
          'pH air saat pemberian',
          ph == null ? 'Tidak tercatat' : uiDecimal(ph),
        ),
        if (stamp != null)
          ValueRow(
            'Waktu catat pengukuran (UTC)',
            uiDateTime(DateTime.fromMillisecondsSinceEpoch(stamp, isUtc: true)),
          ),
        if (row['policy_version'] != null)
          Text(
            row['policy_version'] == 'legacy_manual'
                ? 'Rate manual pada catatan ini'
                : 'Rate otomatis berdasarkan bobot ikan',
          ),
        if (row['recommendation_status'] != null) ...[
          ValueRow(
            'Porsi normal saat pemberian',
            '${row['planned_snapshot_g']} g',
          ),
          ValueRow(
            'Rekomendasi saat pemberian',
            row['recommended_g'] == null
                ? 'Tidak tersedia'
                : '${row['recommended_g']} g',
          ),
          if (row['temperature_percent'] != null)
            ValueRow(
              'Penyesuaian suhu',
              '${row['temperature_percent']}% dari porsi normal',
            ),
          if (row['recommendation_reason'] != null)
            Notice('${row['recommendation_reason']}', warning: true),
        ],
      ],
    );
  }
}
