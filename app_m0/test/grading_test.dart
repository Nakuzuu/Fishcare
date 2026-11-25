import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/grading.dart';
import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/activity_ui.dart';

void main() {
  test('rencana melewati akhir bulan/tahun dan bukan tanggal transaksi', () {
    expect(gradingDateAfter('2026-12-28'), '2027-01-04');
    expect(gradingDateAfter('2028-02-25'), '2028-03-03');
    expect(validGradingPlan('2026-11-02', '2026-10-25'), '2026-11-02');
    for (final invalid in [
      null,
      '2026-02-30',
      '2026-10-25',
      '2026-10-24',
      '25/10/2026',
    ]) {
      expect(
        () => validGradingPlan(invalid, '2026-10-25'),
        throwsA(isA<ValidationFailure>()),
      );
    }
  });
  testWidgets('riwayat grading batal mempertahankan nomor, bobot dan alasan', (
    tester,
  ) async {
    final row = <String, Object?>{
      'id': 's2',
      'cycle_id': 'c',
      'kind': 'sampling',
      'grading_number': 2,
      'business_date': '2026-10-25',
      'quantity': 10,
      'before_weight_cg': 5000,
      'after_weight_cg': 6000,
      'before_count': 100,
      'after_count': 100,
      'cancel_action_id': 'cancel',
      'cancel_reason': 'Timbangan salah',
    };
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ActivityCard(row: row)),
      ),
    );
    expect(find.text('Grading 2'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    await tester.tap(find.text('Detail kegiatan'));
    await tester.pumpAndSettle();
    expect(find.text('Grading 2'), findsOneWidget);
    expect(find.textContaining('Timbangan salah'), findsOneWidget);
    expect(find.textContaining('100 → 100 ekor'), findsOneWidget);
  });
}
