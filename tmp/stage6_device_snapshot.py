from pathlib import Path
import subprocess, sqlite3, json, sys, hashlib
adb = 'C:/Users/basti/AppData/Local/Android/sdk/platform-tools/adb.exe'
stage = sys.argv[1]
assert stage in ('before', 'after')
root = Path(__file__).resolve().parent.parent
target = root / 'tmp' / ('device-stage6-' + stage)
target.mkdir(exist_ok=False)
def call(*args):
    return subprocess.run([adb, '-d', *args], capture_output=True, check=True).stdout
call('shell', 'am', 'force-stop', 'id.ac.fishcare.m0')
files = call('shell', 'run-as', 'id.ac.fishcare.m0', 'ls', 'databases').decode().split()
for name in files:
    if name in ('fishcare_app.db', 'fishcare_app.db-wal', 'fishcare_app.db-shm'):
        (target/name).write_bytes(call('exec-out', 'run-as', 'id.ac.fishcare.m0', 'cat', 'databases/'+name))
db = sqlite3.connect(target/'fishcare_app.db')
summary = {'stage': stage, 'schema': db.execute('pragma user_version').fetchone()[0],
           'integrity': db.execute('pragma integrity_check').fetchone()[0], 'tables': {}}
baseline = None
if stage == 'after':
    baseline = json.loads((root/'tmp/device-stage6-before/baseline.json').read_text(encoding='utf-8'))
columns_by_table = {}
for (table,) in db.execute("select name from sqlite_master where type='table' and name not like 'sqlite_%' order by name"):
    assert table.replace('_', '').isalnum()
    columns = [r[1] for r in db.execute('pragma table_info('+table+')')]
    columns_by_table[table] = columns
    if baseline is not None:
        if table not in baseline['columns']:
            continue
        columns = baseline['columns'][table]
    query = 'select '+','.join(columns)+' from '+table
    rows = sorted([list(r) for r in db.execute(query)], key=lambda r: json.dumps(r, ensure_ascii=True))
    digest = hashlib.sha256(json.dumps(rows, sort_keys=True).encode()).hexdigest()
    summary['tables'][table] = {'count': len(rows), 'sha256_original_columns': digest}
    if baseline is not None and table != 'cycle_slots':
        summary['tables'][table]['unchanged'] = digest == baseline['summary']['tables'][table]['sha256_original_columns']
if stage == 'before':
    (target/'baseline.json').write_text(json.dumps({'columns': columns_by_table, 'summary': summary}, indent=2), encoding='utf-8')
(root/'logs'/('regression-stage6-device-'+stage+'.json')).write_text(json.dumps(summary, indent=2), encoding='utf-8')
db.close()
print(json.dumps(summary, indent=2))
