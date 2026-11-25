import 'dart:async';

import 'package:fishcare_m0/master_data.dart';
import 'package:fishcare_m0/product_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestRepository implements MasterRepository {
  final rows = <MasterRecord>[];
  bool readFailure = false;
  bool duplicate = false;
  int saves = 0;
  Completer<void>? saveGate;
  @override
  Future<List<MasterRecord>> list(
    MasterKind kind, {
    required bool archived,
  }) async {
    if (readFailure) throw StateError('Fixture read failure');
    return rows
        .where((row) => row.kind == kind && row.archived == archived)
        .toList();
  }

  @override
  Future<MasterRecord> get(MasterKind kind, String id) async =>
      rows.singleWhere((row) => row.id == id);
  @override
  Future<void> save(MasterRecord record, {required bool create}) async {
    saves++;
    if (duplicate)
      throw const ValidationFailure(
        'Nama sudah digunakan, termasuk pada data arsip.',
      );
    if (saveGate != null) await saveGate!.future;
    rows.removeWhere((row) => row.id == record.id);
    rows.add(record);
  }

  @override
  Future<void> archive(MasterRecord record) async {}
}

void main() {
  testWidgets(
    'empat tab tidak menampilkan hasil laporan rekaan atau halaman M0',
    (tester) async {
      await tester.pumpWidget(FishCareApp(repository: TestRepository()));
      expect(find.text('Kebutuhan pakan per kolam'), findsOneWidget);
      expect(find.text('HANYA DATA PENGUJIAN M0'), findsNothing);
      await tester.tap(find.text('Laporan').last);
      await tester.pumpAndSettle();
      expect(find.text('Belum ada laporan transaksi'), findsOneWidget);
      await tester.tap(find.text('Pakan').last);
      await tester.pumpAndSettle();
      expect(find.text('Belum ada pakan'), findsOneWidget);
    },
  );
  testWidgets(
    'loading dan kegagalan daftar punya retry yang memuat data baru',
    (tester) async {
      final repo = TestRepository()..readFailure = true;
      await tester.pumpWidget(FishCareApp(repository: repo));
      await tester.tap(find.text('Kolam').last);
      await tester.pumpAndSettle();
      expect(find.text('Daftar gagal dimuat'), findsOneWidget);
      repo.readFailure = false;
      await tester.ensureVisible(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada kolam'), findsOneWidget);
    },
  );
  testWidgets(
    'simpan ganda saat pending hanya memanggil sekali dan daftar langsung berubah',
    (tester) async {
      final repo = TestRepository()..saveGate = Completer<void>();
      await tester.pumpWidget(FishCareApp(repository: repo));
      await tester.tap(find.text('Kolam').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah kolam').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Kolam tes M1');
      await tester.tap(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));
      await tester.pump();
      expect(repo.saves, 1);
      expect(find.text('Menyimpan…'), findsOneWidget);
      repo.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Kolam tes M1'), findsOneWidget);
      expect(find.byType(MasterForm), findsNothing);
    },
  );
  testWidgets(
    'duplikat dari penyimpanan ditampilkan dekat field; draft tetap',
    (tester) async {
      final repo = TestRepository()..duplicate = true;
      await tester.pumpWidget(
        MaterialApp(
          home: MasterForm(kind: MasterKind.feed, repository: repo),
        ),
      );
      await tester.enterText(find.byType(TextFormField).first, 'Pakan tes M1');
      await tester.enterText(find.byType(TextFormField).last, '1500');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nama sudah digunakan, termasuk pada data arsip.'),
        findsOneWidget,
      );
      expect(find.text('Pakan tes M1'), findsOneWidget);
      expect(repo.rows, isEmpty);
    },
  );
}
