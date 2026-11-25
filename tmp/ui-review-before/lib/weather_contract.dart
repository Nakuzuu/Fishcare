import 'business_location.dart';

abstract interface class WeatherStore {
  Future<BusinessLocation?> location();
  Future<void> confirm(BusinessLocation location);
  Future<Map<String, Object?>?> cache(String key);
  Future<void> saveCache(String key, String body, int fetchedMs);
}
