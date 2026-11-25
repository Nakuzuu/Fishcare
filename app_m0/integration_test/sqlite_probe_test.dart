import 'package:fishcare_m0/probe_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'SQLite native menyimpan dan membuka ulang koneksi tanpa menimpa marker',
    (tester) async {
      final firstStore = SqliteProbeStore();
      final saved = await firstStore.saveOnce();
      final reopened = SqliteProbeStore();
      expect(await reopened.read(), saved);
      expect(await reopened.saveOnce(), saved);
      expect(await reopened.read(), saved);
      // Ini membuktikan reopen koneksi, bukan restart proses aplikasi.
      // Cold restart wajib diuji tersendiri sesuai README.
    },
  );
}
