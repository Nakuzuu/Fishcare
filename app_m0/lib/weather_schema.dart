const weatherSchema = <String>[
  '''CREATE TABLE weather_location (id INTEGER PRIMARY KEY CHECK(id=1),name TEXT NOT NULL CHECK(length(trim(name))>0),
    latitude REAL NOT NULL CHECK(latitude>=-90 AND latitude<=90),longitude REAL NOT NULL CHECK(longitude>=-180 AND longitude<=180),
    approximate INTEGER NOT NULL CHECK(approximate IN (0,1)),accuracy REAL CHECK(accuracy>=0))''',
  'CREATE TABLE weather_cache (location_key TEXT PRIMARY KEY NOT NULL,body TEXT NOT NULL,fetched_ms INTEGER NOT NULL)',
];
