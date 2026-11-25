// Skema tambahan M2; tidak menghapus atau menulis ulang tabel master M1.
const cycleSchema = <String>[
  'CREATE TABLE business_settings (id INTEGER PRIMARY KEY CHECK(id=1), zone TEXT NOT NULL)',
  '''CREATE TABLE cycles (
    id TEXT PRIMARY KEY NOT NULL, pond_id TEXT NOT NULL REFERENCES ponds(id),
    feed_id TEXT NOT NULL REFERENCES feeds(id), fish TEXT NOT NULL CHECK(length(trim(fish))>0),
    initial_count INTEGER NOT NULL CHECK(initial_count>0), weight_cg INTEGER NOT NULL CHECK(weight_cg>0),
    start_date TEXT NOT NULL, status TEXT NOT NULL CHECK(status IN ('active','closed')),
    start_payload TEXT NOT NULL, created_at_ms INTEGER NOT NULL)''',
  "CREATE UNIQUE INDEX one_active_cycle ON cycles(pond_id) WHERE status='active'",
  '''CREATE TABLE cycle_rates (
    seq INTEGER PRIMARY KEY AUTOINCREMENT, cycle_id TEXT NOT NULL REFERENCES cycles(id),
    rate_bp INTEGER NOT NULL CHECK(rate_bp>0 AND rate_bp<=10000),
    operation_id TEXT NOT NULL UNIQUE, changed_at_ms INTEGER NOT NULL)''',
  '''CREATE TABLE cycle_schedules (
    id TEXT PRIMARY KEY NOT NULL, cycle_id TEXT NOT NULL REFERENCES cycles(id),
    effective_date TEXT NOT NULL, UNIQUE(cycle_id,effective_date))''',
  '''CREATE TABLE cycle_times (
    schedule_id TEXT NOT NULL REFERENCES cycle_schedules(id), minute INTEGER NOT NULL CHECK(minute>=0 AND minute<1440),
    PRIMARY KEY(schedule_id,minute))''',
  '''CREATE TABLE cycle_slots (
    cycle_id TEXT NOT NULL REFERENCES cycles(id), business_date TEXT NOT NULL,
    minute INTEGER NOT NULL CHECK(minute>=0 AND minute<1440),
    planned_g INTEGER NOT NULL CHECK(planned_g>=0),
    status TEXT NOT NULL DEFAULT 'pending' CHECK(status='pending'),
    PRIMARY KEY(cycle_id,business_date,minute))''',
  '''CREATE TABLE schedule_changes (
    operation_id TEXT PRIMARY KEY NOT NULL, cycle_id TEXT NOT NULL REFERENCES cycles(id),
    effective_date TEXT NOT NULL, before_times TEXT NOT NULL, after_times TEXT NOT NULL,
    changed_at_ms INTEGER NOT NULL)''',
];
