// Bukti tambahan Dart murni, bukan Flutter/Android GPS/SQLite native/HP.
import 'dart:async';

import '../app_m0/lib/business_location.dart';
import '../app_m0/lib/location_failure.dart';
import '../app_m0/lib/weather_controller.dart';
import '../app_m0/test/support/weather_fakes.dart';

void check(bool value) {
  if (!value) throw StateError('Lokasi check gagal');
}

Future<void> main() async {
  final store = MemoryWeatherStore()..value = locationA,
      device = FakeDeviceLocation(),
      api = FakeBusinessApi();
  final c = BusinessWeatherController(store, device, api);
  await c.initialize();
  check(device.calls == 0 && api.requests.single.key == locationA.key);
  await c.acquire();
  check(
    device.calls == 1 && store.writes == 0 && c.candidate!.key == locationB.key,
  );
  await c.cancelCandidate();
  check(c.candidate == null && store.value!.key == locationA.key);
  device.failure = const LocationFailure('Izin lokasi ditolak');
  await c.acquire();
  check(c.locationError != null && store.value!.key == locationA.key);
  device.failure = null;
  await c.choose(locationB);
  store.fail = true;
  await c.confirm();
  check(store.value!.key == locationA.key);
  store.fail = false;
  await c.confirm();
  check(store.value!.key == locationB.key);
  c.dispose();
  final restarted = BusinessWeatherController(store, device, FakeBusinessApi());
  final calls = device.calls;
  await restarted.initialize();
  check(device.calls == calls && restarted.saved!.key == locationB.key);
  restarted.dispose();
  final pendingDevice = FakeDeviceLocation()
    ..pending = Completer<BusinessLocation>();
  final pendingController = BusinessWeatherController(
    MemoryWeatherStore()..value = locationA,
    pendingDevice,
    FakeBusinessApi(),
  );
  await pendingController.initialize();
  final acquiring = pendingController.acquire();
  await pendingController.cancelCandidate();
  await pendingController.choose(locationA);
  pendingDevice.pending!.complete(locationB);
  await acquiring;
  check(pendingController.candidate!.key == locationA.key);
  pendingController.dispose();
  final freshStore = MemoryWeatherStore()..value = locationA,
      slow = FakeBusinessApi()..deferred = true;
  final guarded = BusinessWeatherController(
    freshStore,
    FakeDeviceLocation(),
    slow,
  );
  final opening = guarded.initialize();
  await Future<void>.delayed(Duration.zero);
  await guarded.choose(locationB);
  final confirming = guarded.confirm();
  await Future<void>.delayed(Duration.zero);
  slow.pending[1].complete(weatherReading(20));
  await confirming;
  slow.pending[0].complete(weatherReading(99));
  await opening;
  check(
    guarded.weather!.reading.temperature == 20 &&
        freshStore.value!.key == locationB.key &&
        !freshStore.cached.containsKey(locationA.key),
  );
  guarded.dispose();
  print(
    'Lokasi: tombol sekali, calon/batal, izin ditolak, rollback mock, buka ulang tanpa GPS, respons HP/cuaca lama diabaikan: lulus bukti tambahan. Bukan flutter test/SQLite/izin Android/HP.',
  );
}
