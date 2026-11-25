import 'package:flutter_test/flutter_test.dart';

import 'sqlite_probe_test.dart' as m0;
import 'master_repository_test.dart' as m1;
import 'cycle_repository_test.dart' as m2;
import 'feed_transactions_test.dart' as m3;
import 'lifecycle_transactions_test.dart' as m4;
import 'report_repository_test.dart' as m5;
import 'weather_location_test.dart' as weather;
import 'automatic_feeding_transactions_test.dart' as automatic;

// Satu sesi native berurutan, bukan beberapa build/tes berat paralel.
void main() {
  group('M0 SQLite', m0.main);
  group('M1 master', m1.main);
  group('M2 siklus dan migrasi', m2.main);
  group('M3 stok, pemberian dan recovery', m3.main);
  group('M4 sampling, populasi, panen dan pembatalan', m4.main);
  group('M5 laporan periode, snapshot dan refresh', m5.main);
  group('Lokasi usaha atas tindakan pengguna', weather.main);
  group('Pakan otomatis, pengukuran dan migrasi', automatic.main);
}
