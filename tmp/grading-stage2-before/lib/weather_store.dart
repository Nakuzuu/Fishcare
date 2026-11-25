import 'business_location.dart';
import 'master_repository.dart';
import 'weather_contract.dart';
export 'weather_contract.dart';

class SqliteWeatherStore implements WeatherStore {
  SqliteWeatherStore(this.master);
  final SqliteMasterRepository master;
  @override
  Future<BusinessLocation?> location() async {
    final rows = await (await master.database()).query('weather_location');
    return rows.isEmpty ? null : BusinessLocation.fromMap(rows.single);
  }

  @override
  Future<void> confirm(BusinessLocation location) async {
    await (await master.database()).transaction((db) async {
      await db.delete('weather_location');
      await db.insert('weather_location', {'id': 1, ...location.toMap()});
    });
  }

  @override
  Future<Map<String, Object?>?> cache(String key) async {
    final rows = await (await master.database()).query(
      'weather_cache',
      where: 'location_key=?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.single;
  }

  @override
  Future<void> saveCache(String key, String body, int fetchedMs) async {
    await (await master.database()).transaction((db) async {
      final active = await db.query('weather_location');
      if (active.isEmpty || BusinessLocation.fromMap(active.single).key != key)
        return;
      await db.delete(
        'weather_cache',
        where: 'location_key=?',
        whereArgs: [key],
      );
      await db.insert('weather_cache', {
        'location_key': key,
        'body': body,
        'fetched_ms': fetchedMs,
      });
    });
  }
}
