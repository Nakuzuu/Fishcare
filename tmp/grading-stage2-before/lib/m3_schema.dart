const m3Schema = <String>[
  '''CREATE TABLE action_intents (
    id TEXT PRIMARY KEY NOT NULL, kind TEXT NOT NULL, payload TEXT NOT NULL,
    target_key TEXT NOT NULL, state TEXT NOT NULL CHECK(state IN ('prepared','committed','rejected','abandoned')),
    result TEXT, error TEXT, acknowledged INTEGER NOT NULL DEFAULT 0 CHECK(acknowledged IN (0,1)),
    created_at_ms INTEGER NOT NULL, completed_at_ms INTEGER)''',
  "CREATE UNIQUE INDEX unresolved_target ON action_intents(target_key) WHERE state='prepared'",
  '''CREATE TABLE feedings (
    seq INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT NOT NULL UNIQUE REFERENCES action_intents(id),
    cycle_id TEXT NOT NULL REFERENCES cycles(id), business_date TEXT NOT NULL, minute INTEGER NOT NULL,
    feed_id TEXT NOT NULL REFERENCES feeds(id), actual_g INTEGER NOT NULL CHECK(actual_g>0),
    planned_snapshot_g INTEGER NOT NULL, price_snapshot INTEGER NOT NULL CHECK(price_snapshot>0),
    rate_snapshot INTEGER NOT NULL CHECK(rate_snapshot>0 AND rate_snapshot<=10000),
    population_snapshot INTEGER NOT NULL, weight_snapshot_cg INTEGER NOT NULL,
    biomass_snapshot_cg INTEGER NOT NULL, cost_snapshot INTEGER NOT NULL CHECK(cost_snapshot>=0),
    need_snapshot_g INTEGER NOT NULL, cancel_action_id TEXT UNIQUE REFERENCES action_intents(id),
    cancel_reason TEXT, created_at_ms INTEGER NOT NULL,
    FOREIGN KEY(cycle_id,business_date,minute) REFERENCES cycle_slots(cycle_id,business_date,minute))''',
  "CREATE UNIQUE INDEX one_valid_feeding ON feedings(cycle_id,business_date,minute) WHERE cancel_action_id IS NULL",
  '''CREATE TABLE stock_movements (
    seq INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT NOT NULL UNIQUE REFERENCES action_intents(id),
    feed_id TEXT NOT NULL REFERENCES feeds(id), kind TEXT NOT NULL CHECK(kind IN ('in','correction','out','reversal')),
    delta_g INTEGER NOT NULL, original_in_id TEXT REFERENCES stock_movements(id),
    feeding_id TEXT REFERENCES feedings(id), business_date TEXT NOT NULL, created_at_ms INTEGER NOT NULL,
    CHECK((kind='in' AND delta_g>0 AND original_in_id IS NULL AND feeding_id IS NULL)
      OR (kind='out' AND delta_g<0 AND feeding_id IS NOT NULL AND original_in_id IS NULL)
      OR (kind='reversal' AND delta_g>0 AND feeding_id IS NOT NULL AND original_in_id IS NULL)
      OR (kind='correction' AND delta_g<>0 AND original_in_id IS NOT NULL AND feeding_id IS NULL)))''',
  "CREATE UNIQUE INDEX one_out_movement ON stock_movements(feeding_id) WHERE kind='out'",
  "CREATE UNIQUE INDEX one_reversal_movement ON stock_movements(feeding_id) WHERE kind='reversal'",
  '''CREATE TABLE stock_corrections (
    id TEXT PRIMARY KEY NOT NULL REFERENCES action_intents(id), source_id TEXT NOT NULL REFERENCES stock_movements(id),
    old_g INTEGER NOT NULL CHECK(old_g>=0), new_g INTEGER NOT NULL CHECK(new_g>=0), reason TEXT NOT NULL CHECK(length(trim(reason))>0),
    business_date TEXT NOT NULL, created_at_ms INTEGER NOT NULL)''',
  'CREATE INDEX movements_by_feed ON stock_movements(feed_id,seq)',
  'CREATE INDEX feeding_day ON feedings(cycle_id,business_date,seq)',
];
