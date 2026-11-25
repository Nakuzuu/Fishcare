from pathlib import Path
p=Path('app_m0/lib')
def edit(name, old, new):
 f=p/name
 s=f.read_text(encoding='utf-8')
 assert old in s, (name,old[:100])
 f.write_text(s.replace(old,new,1),encoding='utf-8')
edit('dashboard_ui.dart', "        ValueRow('Populasi', '${v.population} ekor'),\n        ValueRow('Bobot rata-rata', '${decimalText(v.weightCg)} g/ikan'),", "        FishMetrics(population: uiNumber(v.population), weight: uiDecimal(v.weightCg)),")
f=p/'cycle_ui.dart'
s=f.read_text(encoding='utf-8')
start=s.index('      Wrap(')
end=s.index('      OutlinedButton(',start)
s=s[:start]+'''      const SizedBox(height: 12),
      for (var i = 0; i < times.length; i++)
        FishCard(child: Row(children: [
          const Icon(Icons.schedule_outlined, color: FishCareDesign.green),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pemberian ${i + 1}', style: Theme.of(context).textTheme.bodySmall),
            Text(timeText(times[i]), style: Theme.of(context).textTheme.titleLarge),
          ])),
          IconButton(
            tooltip: 'Hapus jam ${timeText(times[i])}',
            onPressed: !enabled ? null : () => onChanged([...times]..removeAt(i)),
            icon: const Icon(Icons.close),
          ),
        ])),
''' + s[end:]
# Stretch the schedule editor and the detail column, not just individual controls.
s=s.replace('crossAxisAlignment: CrossAxisAlignment.start,\n    children: [\n      const Text(\'Jam pemberian', 'crossAxisAlignment: CrossAxisAlignment.stretch,\n    children: [\n      const Text(\'Jam pemberian',1)
s=s.replace("          const SectionTitle('Siklus aktif — kondisi saat ini'),", "          const SectionTitle('Siklus aktif — kondisi saat ini'),",1)
start=s.index("                ValueRow(\n                  'Populasi terkini'")
end=s.index("                ValueRow('Pakan'",start)
s=s[:start]+"                FishMetrics(population: uiNumber(view.population), weight: uiDecimal(view.weightCg)),\n"+s[end:]
# Stretch active detail; retain callbacks, data and labels.
anchor=s.index("          const SectionTitle('Siklus aktif")
before=s.rfind('crossAxisAlignment: CrossAxisAlignment.start',0,anchor)
s=s[:before]+s[before:].replace('crossAxisAlignment: CrossAxisAlignment.start','crossAxisAlignment: CrossAxisAlignment.stretch',1)
start=s.index("                Text(\n                  view.need == null")
end=s.index("                ValueRow('Sudah diberikan'",start)
s=s[:start]+'''                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: view.need == null ? 'Belum bisa dihitung' : uiNumber(view.need!), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                      if (view.need != null) const TextSpan(text: ' g/hari', style: TextStyle(fontSize: 15)),
                    ]),
                    key: const Key('daily-need'),
                  ),
                ),
''' + s[end:]
# In-page shortcut keeps the live existing feeding widget and its refresh behavior.
s=s.replace('  late Future<CycleView?> _view;', '  late Future<CycleView?> _view;\n  final _feedingSection = GlobalKey();',1)
anchor="                ValueRow('Sudah diberikan', '${view.actualToday} g'),"
s=s.replace(anchor,'''                if (widget.feeds != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: OutlinedButton(
                    onPressed: () => Scrollable.ensureVisible(_feedingSection.currentContext!, duration: const Duration(milliseconds: 250)),
                    child: const Text('Lihat pakan hari ini'),
                  )),
                ],
''' + anchor,1)
start=s.index("          const SectionTitle('Atur siklus'),")
end=s.index('          if (widget.feeds != null)\n            FeedingControls(',start)
settings=s[start:end]
s=s[:start]+s[end:]
s=s.replace('            FeedingControls(\n              showHistory:', '            FeedingControls(\n              key: _feedingSection,\n              showHistory:',1)
settings='''Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SectionTitle('Atur siklus'),
              FishActionGrid(children: [
                if (!view.automatic) OutlinedButton(onPressed: () => _open(view, rate: true), child: const Text('Ubah rate sekarang', textAlign: TextAlign.center)),
                OutlinedButton(onPressed: () => _open(view), child: const Text('Ubah jam untuk besok', textAlign: TextAlign.center)),
              ]),
            ])'''
s=s.replace('          if (widget.feeds != null)\n            LifecyclePanel(', '          if (widget.feeds == null) '+settings+',\n          if (widget.feeds != null)\n            LifecyclePanel(\n              settings: '+settings+',',1)
f.write_text(s,encoding='utf-8')
f=p/'lifecycle_ui.dart'
s=f.read_text(encoding='utf-8')
s=s.replace('    this.view,','    this.view,\n    this.settings,',1).replace('  final CycleView? view;','  final CycleView? view;\n  final Widget? settings;',1)
s=s.replace('  late Future<List<Map<String, Object?>>> _rows;', '  late Future<List<Map<String, Object?>>> _rows;\n  final _historySection = GlobalKey();',1)
start=s.index('        Wrap(')
end=s.index("      const SectionTitle('Riwayat kegiatan dan siklus selesai'),",start)
s=s[:start]+'''        FishActionGrid(children: [
          for (final kind in ['sampling', 'death', 'partial'])
            OutlinedButton(onPressed: () => _open(kind), child: Text(actionLabel(kind), textAlign: TextAlign.center)),
          OutlinedButton(
            onPressed: () => Scrollable.ensureVisible(_historySection.currentContext!, duration: const Duration(milliseconds: 250)),
            child: const Text('Riwayat'),
          ),
        ]),
      if (widget.settings != null) widget.settings!,
      if (widget.view != null) Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => _open('final'),
          child: const Text('Panen akhir / tutup siklus', textAlign: TextAlign.center),
        )),
      ),
      SectionTitle('Riwayat kegiatan dan siklus selesai', key: _historySection),
''' + s[end+len("      const SectionTitle('Riwayat kegiatan dan siklus selesai'),\n"):]
f.write_text(s,encoding='utf-8')
# Labels above the fields match the supplied form; validation/controllers are unchanged.
f=p/'product_app.dart'
s=f.read_text(encoding='utf-8')
start=s.index('class _MasterFormState')
a,b=s[:start],s[start:]
b=b.replace('padding: const EdgeInsets.all(16)', 'padding: const EdgeInsets.all(18)',1)
b=b.replace('              TextFormField(\n', "              FishFieldLabel(widget.kind == MasterKind.pond ? 'Nama kolam *' : 'Nama pakan *', child: TextFormField(\n",1)
b=b.replace("                  labelText: 'Nama *',", "                  hintText: widget.kind == MasterKind.pond ? 'Contoh: Kolam Timur' : 'Nama pakan',",1)
b=b.replace('validator: (value) => _validate(value),\n              ),','validator: (value) => _validate(value),\n              )),',1)
b=b.replace('                TextFormField(\n', "                FishFieldLabel('Ukuran / catatan dimensi', child: TextFormField(\n",1)
b=b.replace("                    labelText: 'Ukuran/catatan dimensi (opsional)',", "                    hintText: 'Contoh: 4 × 6 m',\n                    helperText: 'Opsional. Tidak digunakan dalam perhitungan pakan.',",1)
b=b.replace("                ),\n                TextFormField(\n", "                )),\n                FishFieldLabel('Catatan', child: TextFormField(\n",1)
b=b.replace("                    labelText: 'Catatan (opsional)',", "                    hintText: 'Contoh: dekat pintu masuk',",1)
b=b.replace('                  minLines: 2,','                  minLines: 3,',1)
b=b.replace('                  maxLines: 4,\n                ),', '                  maxLines: 4,\n                )),\n                const Notice(\'Nama yang sama, termasuk perbedaan huruf besar dan kecil, tidak dapat digunakan.\'),',1)
f.write_text(a+b,encoding='utf-8')
