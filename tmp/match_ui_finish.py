from pathlib import Path
p=Path('app_m0/lib')
f=p/'product_app.dart';s=f.read_text(encoding='utf-8')
start=s.index('class _MasterFormState');a,b=s[:start],s[start:]
button="""              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Menyimpan…' : 'Simpan'),
              ),"""
assert button in b;b=b.replace(button,'',1)
anchor='      body: SafeArea('
footer='''      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(top: false, child: Container(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(color: FishCareDesign.background, border: Border(top: BorderSide(color: FishCareDesign.line))),
          child: FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Menyimpan…' : 'Simpan')),
        )),
      ),
'''
b=b.replace(anchor,footer+anchor,1);f.write_text(a+b,encoding='utf-8')
f=p/'cycle_ui.dart';s=f.read_text(encoding='utf-8')
# Remove unreachable duplicate left by the layout move.
start=s.index('          if (widget.feeds == null) ...[')
end=s.index('          if (widget.feeds == null)\n            Column(',start)
a=s[start:end]
q=a.index('            if (widget.feeds != null)');a=a[:q]+'          ],\n'
a=a.replace('            if (widget.feeds == null)\n','',1)
s=s[:start]+a+s[end:]
# Keep rate preview and explanatory text in a visually distinct section.
start=s.index('class _StartCycleFormState');a,b=s[:start],s[start:]
b=b.replace('                  TextFormField(', "                  const SectionTitle('Data awal siklus'),\n                  TextFormField(",1)
b=b.replace('                  DropdownButtonFormField<String>(', "                  const SectionTitle('Pakan dan kebutuhan'),\n                  DropdownButtonFormField<String>(",1)
b=b.replace("                  const Text(\n                    'Rate mengikuti bobot awal", "                  const Notice(\n                    'Rate mengikuti bobot awal",1)
f.write_text(a+b,encoding='utf-8')
# Existing identity assertion remains, after navigating to its new secondary location.
f=Path('app_m0/test/ui_polish_test.dart');s=f.read_text(encoding='utf-8')
start=s.index("  testWidgets('detail kolam nama sekali")
at=s.index('    await tester.pumpAndSettle();',start)+len('    await tester.pumpAndSettle();')
s=s[:at]+"\n    await tester.scrollUntilVisible(find.text('Ubah identitas'), 200, scrollable: find.byType(Scrollable).first);"+s[at:]
f.write_text(s,encoding='utf-8')
