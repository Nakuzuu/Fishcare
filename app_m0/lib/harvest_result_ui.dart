import 'package:flutter/material.dart';

import 'design_system.dart';
import 'report_rules.dart';
import 'ui_format.dart';

class HarvestFeedResultTable extends StatelessWidget {
  const HarvestFeedResultTable({super.key, required this.result});
  final HarvestFeedResult result;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionTitle('Hasil panen setelah biaya pakan'),
      Text(
        'Seluruh siklus, termasuk panen sebagian dan panen akhir. Tidak dibatasi filter tanggal laporan.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      Table(
        columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(color: Theme.of(context).dividerColor),
        children: [
          for (final entry in [
            ('Pendapatan kotor', uiMoney(result.revenue)),
            ('Total pakan terpakai', '${uiNumber(result.feedGrams)} g'),
            ('Total biaya pakan', uiMoney(result.feedCost)),
            ('Hasil setelah biaya pakan', uiMoney(result.afterFeed)),
          ])
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(entry.$1),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    entry.$2,
                    style: entry.$1 == 'Hasil setelah biaya pakan'
                        ? const TextStyle(fontWeight: FontWeight.bold)
                        : null,
                  ),
                ),
              ],
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Hanya mengurangi biaya pakan aktual yang sah. Biaya lain belum diperhitungkan; bukan keuntungan bersih.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
