import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fishcare_m0/report_export.dart';
import 'package:fishcare_m0/report_rules.dart';
import 'package:fishcare_m0/report_ui.dart';
import 'package:fishcare_m0/master_data.dart';

import 'report_test.dart' show FakeReports, row, view;

Map<String, String> parts(Uint8List bytes) {
  final result = <String, String>{};
  final b = ByteData.sublistView(bytes);
  var p = 0;
  while (b.getUint32(p, Endian.little) == 0x04034b50) {
    final length = b.getUint32(p + 18, Endian.little);
    final n = b.getUint16(p + 26, Endian.little);
    final extra = b.getUint16(p + 28, Endian.little);
    final start = p + 30 + n + extra;
    result[utf8.decode(bytes.sublist(p + 30, p + 30 + n))] = utf8.decode(
      bytes.sublist(start, start + length),
    );
    p = start + length;
  }
  expect(b.getUint32(p, Endian.little), 0x02014b50);
  return result;
}

void main() {
  test('semua kolam termasuk arsip, grading dan snapshot panen diekspor', () {
    final records = [
      row('2026-10-26', 'a', 'feeding', 1125, cost: 16875),
      {
        ...row('2026-10-26', 'a', 'sampling', 10),
        'after_weight_cg': 6050,
        'grading_number': 2,
      },
      row('2026-10-26', 'b', 'partial', 20, value: 30000),
    ];
    final before = jsonEncode(records);
    final xml = parts(
      reportXlsx(view(ReportFilter('2026-10-26', '2026-10-26'), records)),
    );
    expect(
      xml['xl/worksheets/sheet1.xml'],
      contains('Semua kolam (termasuk arsip)'),
    );
    expect(xml['xl/worksheets/sheet1.xml'], contains('<v>30000</v>'));
    expect(xml['xl/worksheets/sheet2.xml'], contains('Grading'));
    expect(xml['xl/worksheets/sheet2.xml'], contains('<v>60.5</v>'));
    expect(xml['xl/worksheets/sheet2.xml'], contains('Panen sebagian'));
    expect(jsonEncode(records), before);
  });
  test('snapshot invalid dan teks melebihi batas gagal sebelum menyimpan', () {
    final invalid = row('2026-10-26', 'a', 'feeding', 10)
      ..remove('cost_snapshot');
    expect(
      () =>
          reportXlsx(view(ReportFilter('2026-10-26', '2026-10-26'), [invalid])),
      throwsA(isA<ValidationFailure>()),
    );
    final long = {
      ...row('2026-10-26', 'a', 'death', 1),
      'pond_name': 'a' * 32768,
    };
    expect(
      () => reportXlsx(view(ReportFilter('2026-10-26', '2026-10-26'), [long])),
      throwsA(isA<ValidationFailure>()),
    );
  });
  testWidgets('ekspor tidak tersedia ketika laporan sedang dimuat atau gagal', (
    t,
  ) async {
    final source = FakeReports()..deferred = true;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReportPage(source: source)),
      ),
    );
    await t.pump();
    expect(find.text('Ekspor Excel (.xlsx)'), findsNothing);
    expect(source.pending.length, 1);
    source.pending.single.completeError(
      StateError('Fixture offline database error'),
    );
    await t.pumpAndSettle();
    expect(find.text('Ekspor Excel (.xlsx)'), findsNothing);
    expect(find.text('Laporan gagal dimuat; angka bukan nol.'), findsOneWidget);
  });
  test('XLSX filter, snapshot, cancellation, exact totals and safe text', () {
    final records = [
      {
        ...row('2026-10-26', 'a', 'feeding', 1125, cost: 16875),
        'pond_name': '=HYPERLINK("unsafe") & <kolam>',
        'price_snapshot': 15000,
        'water_temperature_deci_c': 230,
        'water_ph_hundredths': 700,
        'recommended_g': 400,
        'planned_snapshot_g': 500,
      },
      row('2026-10-26', 'a', 'feeding', 200, cost: 3000, canceled: 'cancel'),
      row('2026-10-26', 'b', 'death', 7),
      row('2026-10-25', 'a', 'death', 9),
    ];
    final snap = view(
      ReportFilter('2026-10-26', '2026-10-26', pondId: 'a'),
      records,
    );
    final bytes = reportXlsx(snap);
    final xml = parts(bytes);
    expect(xml.length, 7);
    expect(xml['xl/worksheets/sheet1.xml'], contains('<v>16875</v>'));
    expect(xml['xl/worksheets/sheet1.xml'], contains('<v>1125</v>'));
    final detail = xml['xl/worksheets/sheet2.xml']!;
    expect(detail, contains('Batal'));
    expect(detail, contains('<v>23.0</v>'));
    expect(detail, contains('<v>7.0</v>'));
    expect(detail, contains('Tidak tercatat'));
    expect(detail, contains('&amp; &lt;kolam&gt;'));
    expect(detail, isNot(contains('<f>')));
    expect(detail, isNot(contains('2026-10-25')));
    expect(detail, isNot(contains('<v>9</v>')));
    final out = Directory('../output/export-stage5')
      ..createSync(recursive: true);
    File('${out.path}/fixture-report.xlsx').writeAsBytesSync(bytes);
  });
  test(
    'empty offline workbook keeps inclusive filter and zero genuine totals',
    () {
      final xml = parts(
        reportXlsx(view(ReportFilter('2026-10-01', '2026-10-26'), [])),
      );
      expect(xml['xl/worksheets/sheet1.xml'], contains('Belum ada transaksi'));
      expect(xml['xl/worksheets/sheet1.xml'], contains('2026-10-01'));
      expect(xml['xl/worksheets/sheet1.xml'], contains('Semua kolam'));
      expect(xml['xl/worksheets/sheet2.xml']!.split('<row ').length, 2);
    },
  );
  test('large integers exported as exact text, control characters removed', () {
    final r = {
      ...row('2026-10-26', 'a', 'death', 1000000000000001),
      'pond_name': 'A\x01B',
    };
    final xml = parts(
      reportXlsx(view(ReportFilter('2026-10-26', '2026-10-26'), [r])),
    );
    expect(xml['xl/worksheets/sheet2.xml'], contains('>1000000000000001</t>'));
    expect(xml['xl/worksheets/sheet2.xml'], isNot(contains('\x01')));
  });
  testWidgets('save busy guard, cancellation and errors never report success', (
    t,
  ) async {
    final source = FakeReports();
    var calls = 0;
    final firstSave = Completer<bool>();
    const channel = MethodChannel('fishcare/report_export');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls++;
          if (calls == 1) return firstSave.future;
          if (calls == 2) throw PlatformException(code: 'save_failed');
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReportPage(source: source)),
      ),
    );
    await t.pumpAndSettle();
    final button = find.text('Ekspor Excel (.xlsx)');
    await t.ensureVisible(button);
    await t.tap(button);
    await t.tap(button);
    expect(calls, 1);
    firstSave.complete(false);
    await t.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Ekspor dibatalkan.'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    await t.tap(button);
    await t.pumpAndSettle();
    expect(find.textContaining('gagal disimpan'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    await t.tap(button);
    await t.pumpAndSettle();
    expect(find.text('Laporan Excel berhasil disimpan.'), findsOneWidget);
  });
}
