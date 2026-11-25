# M4 — sampling, populasi dan panen

13 Oktober 2026. Sumber versi **0.5.0+5**, skema produk **4**, application ID tetap `id.ac.fishcare.m0`. **M4 belum terverifikasi melalui analyze/test/build Flutter standar atau HP.** Berhenti M4; tanpa laporan lengkap, backup/restore atau cuaca produk lengkap.

Pengguna mengonfirmasi **seluruh percobaan manual gabungan M2+M3 yang diberikan berhasil tanpa kendala**. Ini hasil pengguna, bukan pengujian yang diulang agen. Tidak menambah model/serial perangkat atau log analyze/test/build yang tidak diberikan. Catatan historis M3 saat serah terima tetap historis.

## Cakupan dan keputusan

FR-05/06, regresi FR-02/03/04; AT-08–17, AT-19 sebatas refresh detail, AT-25/31–36. PRD, Alur Sistem, Rancangan Database, Wireframe dan Keputusan Review diselaraskan. Pembatalan M3 diperluas sesuai keputusan pengguna: last valid commit lintas feeding/sampling/death/partial pada active/hari sama; rate/jam/Lewati bukan penghalang; final/closed tidak batal. Ini keputusan yang disetujui untuk M4, bukan persetujuan seluruh draf PRD.

- Sampling positif <=populasi, bobot positif maksimal2desimal; satu sah/hari; tidak mengurangi populasi. Sampling batal memungkinkan sampling baru hari sama.
- Kematian positif <=populasi terbaru; seluruh sisa boleh mati. Nol kebutuhan tidak membuat feeding nol.
- Parsial positif <populasi; bobot panen/harga positif, snapshot jumlah/bobot/harga/nilai half-up. Contoh20×200g×Rp25.000/kg=Rp100.000.
- Akhir seluruh sisa otomatis; transaksi membaca current kembali. Populasi berbeda dari konfirmasi ditolak untuk ditinjau ulang. Sisa0 hanya operasi close, field panen/nilai NULL, tanpa panen fiktif.
- Closure/panen/current/stop pending/result atomik. Closed menolak semua operasi dan tidak membuat slot baru. Retry ID committed mengembalikan hasil lama, ID baru pada closed ditolak.
- Batal terakhir memulihkan before_count/bobot untuk sampling/kematian/parsial; feeding reversal aktual persis dan menandai kedua riwayat. Tidak mengembalikan rate/jam/Lewati. Pending memakai kondisi/rate terbaru; given/skipped snapshot tetap.

## Sumber dan migrasi

[m4_schema.dart](../app_m0/lib/m4_schema.dart): tambah current_count/current_weight_cg dari data awal (initial_count/weight_cg tetap), closed_action_id dan stopped_action_id slot; operations sequence bersama, kondisi before/after, snapshot panen, alasan/FK pembatalan. Unique satu sampling sah/hari. Import seluruh feedings lama termasuk batal menurut seq; urutan legacy tidak direka memakai timestamp.

[master_repository.dart](../app_m0/lib/master_repository.dart): upgrade1/2/3→4 dalam transaksi callback sqflite; tahap lama tetap tersedia untuk fixture migrasi. Ledger, koreksi, niat, snapshot, master/rate/jam lama tidak dihapus; kegagalan upgrade rollback. Database produk `fishcare_app.db` tetap terpisah marker M0; tidak uninstall/reset/clear data.

[m4_operations.dart](../app_m0/lib/m4_operations.dart): validasi dan perubahan dalam transaksi yang dipanggil [feed_repository.dart](../app_m0/lib/feed_repository.dart). Feeding baru masuk operations dalam commit yang sama dengan snapshot/out/slot; pembatalan feeding mengecek last sequence semua jenis. Operations latest index menentukan kandidat UI dan validasi penyimpanan. Perubahan kondisi/recalc memakai [cycle_repository.dart](../app_m0/lib/cycle_repository.dart) dan satu fungsi [cycle_rules.dart](../app_m0/lib/cycle_rules.dart), dengan BigInt/int64/half-up.

Penutupan memakai enum slot M3 `skipped` serta **stopped_action_id** untuk pending saja, dengan planned_g lama tetap; flag membedakan dihentikan penutupan dari Lewati pengguna. Given/skipped lama tidak diubah. Tidak ada pemberian otomatis untuk hari belum dibuka. Jika kebutuhan turun di bawah actual, remaining0/excess jelas tanpa mengembalikan stok otomatis.

[lifecycle_ui.dart](../app_m0/lib/lifecycle_ui.dart): tombol/form dari detail kolam, input satuan/validasi, ringkasan/sisa/biomassa/nilai, konfirmasi scrollable, loading/error/retry, snackbar+reload, riwayat semua siklus kolam termasuk closed/batal. Form ListView/SafeArea saat keyboard terbuka. Akhir jumlah otomatis; sisa0 tanpa field panen. Pemulihan teknis membuka halaman M3 dan mencegah tindakan ID baru otomatis. Riwayat menampilkan snapshot panen dan biaya feeding. Beranda/Laporan belum menjadi laporan penuh.

Niat disimpan terlebih dahulu oleh ActionJournal; hasil bisnis/committed atomic. Technical error tetap prepared; startup/recovery inspect ID sama sebelum retry eksplisit, tidak retry otomatis. M4 dispatcher resume memakai payload tersimpan, tanggal tidak ditulis ulang. Cancel validasi ulang dalam transaksi; double cancel ID baru ditolak, ID commit lama idempotent.

## Tes dan bukti yang tersedia

[lifecycle_transactions_test.dart](../app_m0/integration_test/lifecycle_transactions_test.dart) menambah **10 skenario native terdefinisi**, bukan10 lulus: sampling setelah feeding360/sisa210; shortage populasi dan semua mati/close0; parsial80/snapshot100000; batal lintas jenis+rate/jam/skip; sampling invalid/unik dan resampling setelah batal; akhir tepat70/idempotent/stop/closed; stale/day-lalu; fault-trigger rollback penutupan+reopen/resume ID sama; double sampling/cancel; fixture migrasi3 menjaga snapshot/stock/master dan urutan feeding lama. Trigger hanya pada database terisolasi `m4_isolated_*`; fixture `m4_migration_*`. Reopen merupakan simulasi penyimpanan, bukan force-stop HP.

Tes M3 dipertahankan, memakai schemaVersion terbaru tanpa melemahkan assertion isi/migrasi. Tes standar [harvest_rules_test.dart](../app_m0/test/harvest_rules_test.dart) menambah nilai/half-up/invalid/overflow. Suite [all_database_test.dart](../app_m0/integration_test/all_database_test.dart) menjalankan semua kelompok native berurutan. Semua suite wajib belum dijalankan di sesi ini, sehingga jumlah lulus/gagal tidak diketahui.

Fixture migrasi3 juga memeriksa feeding yang sudah batal, reversal, koreksi masuk, jumlah efektif, alasan dan ID lama tetap. Kasus akhir menguji bobot/harga hilang/nol/NaN ditolak utuh. Detail kolam arsip tetap dapat membaca riwayat closed, tetapi mulai siklus nonaktif.

| Pemeriksaan M4 | Status dan bukti |
|---|---|
| `flutter analyze` | Terhalang; belum dijalankan. SDK lock ReadWrite ditolak |
| Seluruh `flutter test` | Terhalang; belum dijalankan, bukan dianggap lulus |
| `flutter build apk --debug` | Terhalang; belum menghasilkan APK M4 |
| Native SQLite/integration | Belum dijalankan |
| Format Dart | Lulus; [log](../logs/m4-format.log), bukan analisis tipe |
| Checker Dart murni M4 | Lulus exit0; [log](../logs/m4-rules-extra.log); bukan Flutter/SQLite/HP |
| Regresi checker M3/M2 | Lulus exit0; [M3](../logs/m4-m3-regression-extra.log), [M2](../logs/m4-m2-regression-extra.log); M2 mencakup1866 pembagian; bukan suite standar |
| Pemasangan/uji HP M4 | Belum dijalankan |
| Manual M2+M3 | Lulus menurut konfirmasi pengguna; tidak mengarang log/perangkat |

[m4-standard-status.log](../logs/m4-standard-status.log): `UnauthorizedAccessException: Access to C:\flutter\bin\cache\flutter.bat.lock is denied.` SDK/cache di luar writable root; izin eskalasi tidak tersedia. Tidak mengulang bootstrap lock loop, mengganti SDK atau menghapus cache/lock untuk mengakali lingkungan. Konfigurasi Flutter/Dart/Android/Gradle/dependency tetap riwayat konfigurasi berhasil di README; lockfile SHA256 tetap `5F58FFBDCCAB977D516CEA1A50AAA3BAF679AE979D94CC2DEB671F0E1EA71434`.

APK yang ditemukan sebelum build M4 adalah **v0.4.0+4 M3**, diperiksa via aapt, ukuran152.201.251byte dan SHA256 `D4EDC32D2A5F61788792AF67C8201EAA6C3F7786180F6064424A1B9CD4450BF5`. Tidak disebut APK M4 atau hasil perintah build agen. Laporan ukuran M1 sekitar151MB tetap hasil pengguna. Bukti artifact dan lock ada di [log](../logs/m4-existing-evidence.log).

## Jalur standar terminal Android Studio

Perintah berikut **belum dijalankan untuk M4**, dari terminal yang dapat menulis cache SDK. Jalankan berurutan dan simpan output:

```powershell
Set-Location 'C:\Users\basti\OneDrive\Lampiran\Documents\FishCare V2\app_m0'
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>
flutter install --debug -d <ID_HP_LOKAL>
```

Setelah integration (runner dapat memasang entrypoint tes), pasang APK produk gabungan M1–M4 satu kali. Pastikan `build/app/outputs/flutter-apk/app-debug.apk` **versionName0.5.0/versionCode5**, hash/waktu baru. Jangan uninstall/clear data untuk melewati migrasi. APK lama bukan kandidat M4. Tes native hanya database fixture, serial tidak dipublikasikan.

## Uji HP M4 yang belum dijalankan

1. Upgrade ke versi5, data M1–M3 termasuk stok/koreksi/riwayat/ID/rate/jam tetap. Offline buka detail kolam dan seluruh tab; Laporan tetap jujur belum penuh.
2. Siklus100×100g×3%, stok cukup: beri150g; sampling10 ikan bobot120g. Populasi100, need360/sisa210, snapshot feeding150/bobot100/harga/biaya tetap. Sampling0/101/bobotinvalid/dua sah hari sama ditolak.
3. Mati150 dari100 ditolak utuh; mati10 menyisakan90. Pada siklus terpisah mati seluruh100→need0; tutup tanpa panen/nilai fiktif.
4. Siklus100: parsial20 bobot200g harga25000→80 ikan dan Rp100000. Parsial100/0/harga atau bobot kosong ditolak. Sampling berikutnya tidak mengubah snapshot panen tadi.
5. Buat urutan feeding→sampling→kematian→parsial; kandidat hanya parsial. Batal feeding/sampling yang punya lanjutan ditolak. Rate/jam/Lewati lalu batal parsial→populasi pulih; batal kematian→pulih; batal sampling→bobot pulih; batal feeding→stok pulih tepat. Alasan wajib dan riwayat batal tetap; given/skipped tetap; pending dihitung ulang dengan rate terkini. Ulang ketukan tidak menggandakan perubahan.
6. Akhir memakai seluruh sisa otomatis, bobot/harga wajib bila>0. Konfirmasi jumlah/biomassa/nilai/closed. Ketuk ulang hanya satu panen; semua pending berhenti; closed tidak menerima kegiatan/batal, riwayat tetap. Mulai siklus baru tidak mengubah riwayat lama.
7. Tutup paksa/buka lagi: current/riwayat/stock/closed tetap. Untuk crash point memakai fault-trigger pada database uji integration saja; recovery Periksa hasil dahulu, committed tidak retry, prepared retry ID sama. Jangan memodifikasi data pengguna untuk menyuntik kegagalan.
8. Keyboard terbuka, layar kecil/teks besar, loading/gagal/retry dan Kembali tetap dapat digunakan. Catat hasil serta versi/model/API aktual bila diperiksa, tidak diasumsikan.

Keputusan pembatalan sampling/populasi sudah selesai untuk M4. Pemulihan setelah backup/restore, laporan penuh dan cuaca produk tetap tahap berikutnya yang belum dikerjakan. **Tidak lanjut otomatis setelah M4.**
