import 'package:fishcare_m0/action_payload.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'angka nonfinite ditolak sebagai input invalid sebelum jurnal ditulis',
    () {
      for (final value in [
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => canonicalPayload({
            'nested': [
              {'weight': value},
            ],
          }),
          throwsA(isA<ValidationFailure>()),
        );
      }
    },
  );
  test(
    'payload kanonik tidak tergantung urutan key dan mempertahankan input',
    () {
      final first = canonicalPayload({
        'grams': 150,
        'target': {'cycle': 'c', 'minute': 480},
        'date': '2026-10-13',
      });
      final second = canonicalPayload({
        'date': '2026-10-13',
        'target': {'minute': 480, 'cycle': 'c'},
        'grams': 150,
      });
      expect(first, second);
      expect(
        canonicalPayload({'grams': 151}),
        isNot(canonicalPayload({'grams': 150})),
      );
      expect(
        canonicalPayload({
          'times': [480, 960],
        }),
        isNot(
          canonicalPayload({
            'times': [960, 480],
          }),
        ),
      );
    },
  );
}
