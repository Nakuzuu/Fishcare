// API nyata dengan koordinat Jakarta yang dipilih eksplisit untuk uji CLI,
// bukan lokasi HP/pengguna dan tidak menulis database produk.
import '../app_m0/lib/business_location.dart';
import '../app_m0/lib/weather_api.dart';

Future<void> main() async {
  final api = OpenMeteoBusinessApi();
  try {
    final weather = await api.fetch(
      BusinessLocation('Jakarta — uji CLI', -6.2088, 106.8456),
    );
    print(
      'API nyata Jakarta (-6.2088,106.8456): suhu ${weather.reading.temperature} ${weather.reading.unit}, kode ${weather.reading.code}, prakiraan hujan ${weather.rain}%, tanggal ${weather.rainDay}, diambil ${weather.reading.fetchedAt.toIso8601String()}. Bukan uji HP.',
    );
  } finally {
    api.dispose();
  }
}
