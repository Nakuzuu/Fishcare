import sqlite3, json
from pathlib import Path
root=Path(__file__).resolve().parent.parent
a=sqlite3.connect(root/'tmp/device-stage6-before/fishcare_app.db')
b=sqlite3.connect(root/'tmp/device-stage6-after/fishcare_app.db')
a.row_factory=b.row_factory=sqlite3.Row
cols=[r[1] for r in a.execute('pragma table_info(cycle_slots)')]
old=[dict(r) for r in a.execute('select * from cycle_slots')]
new=[dict(r) for r in b.execute('select * from cycle_slots')]
key=lambda r:(r['cycle_id'],r['business_date'],r['minute'])
index={key(r):r for r in new}
changed=[[c for c in cols if r[c]!=index[key(r)][c]] for r in old if any(r[c]!=index[key(r)][c] for c in cols)]
out={'old_slots':len(old), 'new_slots':len(new), 'original_slots_changed_columns':changed,
     'active_automatic_cycles':b.execute("select count(*) from cycles where feeding_policy!='legacy_manual' and status='active'").fetchone()[0]}
ca=[r[1] for r in a.execute('pragma table_info(weather_cache)')]
ar=[dict(r) for r in a.execute('select * from weather_cache')]
br=[dict(r) for r in b.execute('select * from weather_cache')]
out['cache_changed_columns']=sorted(set(c for x,y in zip(ar,br) for c in ca if x[c]!=y[c]))
(root/'logs/regression-stage6-migration-detail.json').write_text(json.dumps(out,indent=2), encoding='utf-8')
print(json.dumps(out))
