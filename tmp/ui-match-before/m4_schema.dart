const m4Schema = <String>[
  'ALTER TABLE cycles ADD COLUMN current_count INTEGER NOT NULL DEFAULT 0 CHECK(current_count>=0)',
  'ALTER TABLE cycles ADD COLUMN current_weight_cg INTEGER NOT NULL DEFAULT 1 CHECK(current_weight_cg>0)',
  'ALTER TABLE cycles ADD COLUMN closed_action_id TEXT REFERENCES action_intents(id)',
  'ALTER TABLE cycle_slots ADD COLUMN stopped_action_id TEXT REFERENCES action_intents(id)',
  'UPDATE cycles SET current_count=initial_count,current_weight_cg=weight_cg',
  '''CREATE TABLE operations (
    seq INTEGER PRIMARY KEY AUTOINCREMENT, id TEXT NOT NULL UNIQUE REFERENCES action_intents(id),
    cycle_id TEXT NOT NULL REFERENCES cycles(id), business_date TEXT NOT NULL,
    kind TEXT NOT NULL CHECK(kind IN ('feeding','sampling','death','partial','final','close')),
    before_count INTEGER NOT NULL CHECK(before_count>=0), after_count INTEGER NOT NULL CHECK(after_count>=0),
    before_weight_cg INTEGER NOT NULL CHECK(before_weight_cg>0), after_weight_cg INTEGER NOT NULL CHECK(after_weight_cg>0),
    quantity INTEGER NOT NULL CHECK(quantity>=0), harvest_weight_cg INTEGER, price_rp_kg INTEGER,
    value_rp INTEGER, cancel_action_id TEXT UNIQUE REFERENCES action_intents(id), cancel_reason TEXT,
    created_at_ms INTEGER NOT NULL,
    CHECK((kind='close' AND quantity=0) OR (kind<>'close' AND quantity>0)),
    CHECK((kind IN ('partial','final') AND harvest_weight_cg IS NOT NULL AND price_rp_kg IS NOT NULL AND value_rp IS NOT NULL AND harvest_weight_cg>0 AND price_rp_kg>0 AND value_rp>=0)
      OR (kind NOT IN ('partial','final') AND harvest_weight_cg IS NULL AND price_rp_kg IS NULL AND value_rp IS NULL)),
    CHECK((cancel_action_id IS NULL AND cancel_reason IS NULL)
      OR (cancel_action_id IS NOT NULL AND cancel_reason IS NOT NULL AND length(trim(cancel_reason))>0 AND kind NOT IN ('final','close'))))''',
  '''INSERT INTO operations(id,cycle_id,business_date,kind,before_count,after_count,
    before_weight_cg,after_weight_cg,quantity,cancel_action_id,cancel_reason,created_at_ms)
    SELECT id,cycle_id,business_date,'feeding',population_snapshot,population_snapshot,
    weight_snapshot_cg,weight_snapshot_cg,actual_g,cancel_action_id,cancel_reason,created_at_ms
    FROM feedings ORDER BY seq''',
  "CREATE UNIQUE INDEX one_valid_sampling ON operations(cycle_id,business_date) WHERE kind='sampling' AND cancel_action_id IS NULL",
  'CREATE INDEX operations_cycle ON operations(cycle_id,seq)',
];
