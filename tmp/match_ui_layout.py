from pathlib import Path
p=Path('app_m0/lib')
f=p/'cycle_ui.dart';s=f.read_text(encoding='utf-8')
start=s.index("          const SectionTitle('Pakan hari ini'),")
end=s.index('          if (widget.feeds == null)\n            Column(',start)
feeding=s[start:end]
# Preserve no-repository display for isolated/read-only views.
s=s[:start]+"          if (widget.feeds == null) ...[\n"+feeding+"          ],\n"+s[end:]
start=feeding.index('          if (widget.feeds != null)\n            FeedingControls(')
live=feeding[start:].replace('          if (widget.feeds != null)\n','',1).strip().removesuffix(',')
s=s.replace('            LifecyclePanel(\n              settings:', '''            LifecyclePanel(
              feeding: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SectionTitle('Pakan hari ini'),
                Text('Jam berlaku besok ${nextDate(view.date)}: ${view.tomorrowTimes.map(timeText).join(', ')}'),
                '''+live+''',
              ]),
              settings:''',1)
f.write_text(s,encoding='utf-8')
f=p/'lifecycle_ui.dart';s=f.read_text(encoding='utf-8')
s=s.replace('    this.settings,','    this.settings,\n    this.feeding,',1).replace('  final Widget? settings;','  final Widget? settings;\n  final Widget? feeding;',1)
start=s.index('      if (widget.view != null)\n        GradingPlanPanel(')
end=s.index("      if (widget.view != null) const SectionTitle('Kegiatan kolam'),",start)
grading=s[start:end];s=s[:start]+s[end:]
anchor="      SectionTitle('Riwayat kegiatan dan siklus selesai', key: _historySection),"
s=s.replace(anchor, grading+'      if (widget.feeding != null) widget.feeding!,\n'+anchor,1)
f.write_text(s,encoding='utf-8')
# Put operational overview first; identity editing remains below it.
f=p/'product_app.dart';s=f.read_text(encoding='utf-8')
start=s.index('                if (widget.cycles != null)\n                  CyclePanel(')
end=s.index('              ] else ...[',start)
cycle=s[start:end];s=s[:start]+s[end:]
anchor="              if (row.kind == MasterKind.pond) ...[\n"
s=s.replace(anchor,anchor+cycle,1)
f.write_text(s,encoding='utf-8')
