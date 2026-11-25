// Pemeriksaan Dart murni tambahan, bukan flutter test standar.
import '../app_m0/lib/master_data.dart';

void main() {
  if (normalizedName(' Kolam A ') != normalizedName('KOLAM A')) {
    throw StateError('Normalisasi nama gagal');
  }
  if (parsePrice('1500') != 1500 ||
      parsePrice('9223372036854775807') != 9223372036854775807) {
    throw StateError('Harga sah tidak dipertahankan');
  }
  for (final value in [
    '',
    '0',
    '-1',
    '1.500',
    '1,5',
    'NaN',
    'Infinity',
    '9223372036854775808',
  ]) {
    var rejected = false;
    try {
      parsePrice(value);
    } on ValidationFailure {
      rejected = true;
    }
    if (!rejected) throw StateError('Input invalid diterima: $value');
  }
  print(
    'Pemeriksaan tambahan normalisasi/harga lulus; bukan flutter test, SQL, UI atau uji HP.',
  );
}
