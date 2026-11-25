# M5 — laporan budidaya dan kandidat gabungan M4+M5

Sumber **0.6.0+6**, skema tetap **4**, application ID `id.ac.fishcare.m0`. M4 dan M5 **belum terverifikasi di HP**; pengguna memilih pemasangan/uji setelah M5. Manual gabungan M2+M3 sebelumnya lulus menurut pengguna. Tidak menambah identitas perangkat atau hasil otomatis tanpa bukti. Berhenti M5; backup/restore dan cuaca produk lengkap belum dibuat.

## Perubahan FR-07 dan AT

FR-07; AT-18/19/37–40, regresi AT-08–17/25/31–36. PRD, alur, database dan wireframe diperbarui. Tidak menambah FCR atau keuntungan bersih; selisih nilai panen/biaya tidak dihitung/diberi label keuntungan.

- Mulai/akhir inklusif, validasi tanggal/rentang, satu/semua kolam termasuk arsip. Semua lima metrik memakai filter yang sama.
- Gram feeding aktual, biaya snapshot, ikan mati, panen partial+final, nilai snapshot. Batal tetap di riwayat, dikecualikan total. Sampling/close tanpa panen bukan pengurangan/pendapatan fiktif.
- BigInt/int64 untuk akumulasi hasil per transaksi. Tidak menghitung harga/bobot/rate terkini atau membulatkan ulang gabungan.
- Transaksi periode, Kondisi saat ini (active) dan Seluruh siklus (active/closed) terpisah jelas; current/whole hanya mengikuti kolam, tidak periode.
- Metrik→pendukung jenis terkait→detail dengan tanggal/kolam tetap. Batal berlabel, ID/snapshot/alasan dapat dibaca. Filter tetap saat pindah tab; pendukung menerima salinan filter immutable.
- Beranda menampilkan lima total hari ini pada zona usaha serta kondisi active. Commit/batal meminta pembacaan ulang layar terbuka; saat tab ditampilkan ulang dibaca lagi. Resume memuat ulang; Beranda mengecek pergantian hari saat resume dan timer menit.
- Kosong/loading/gagal/retry/offline tersedia. Angka lama dibersihkan saat request baru, hasil/error request lama dan request setelah dispose diabaikan.

## Sumber dan data

[report_rules.dart](../app_m0/lib/report_rules.dart): filter immutable dan satu fold total. [report_repository.dart](../app_m0/lib/report_repository.dart): query operations/cycles/ponds/feedings dalam satu transaksi baca konsisten. [report_controller.dart](../app_m0/lib/report_controller.dart): generation request, error/loading dan refresh. [report_ui.dart](../app_m0/lib/report_ui.dart): Beranda/Laporan/pendukung/detail mobile.

[data_changes.dart](../app_m0/lib/data_changes.dart), [action_journal.dart](../app_m0/lib/action_journal.dart), [master_repository.dart](../app_m0/lib/master_repository.dart): sinyal sesudah commit/recovery acknowledgement, tidak mengganti ID/hasil persisten. [product_app.dart](../app_m0/lib/product_app.dart): source SQLite produk terhubung ke kedua tab, key berbeda mencegah state Beranda tertukar dengan Laporan, filter disimpan parent.

M5 tidak memerlukan kolom/tabel/index/dependency/migrasi baru. Skema4/lockfile dipertahankan; data M1–M4 tidak reset atau uninstall. Query tidak mengubah riwayat. Kolam arsip tetap tersedia. Upgrade dari1–3 tetap memakai migrasi M4; schema4 dibuka langsung. Fixture terisolasi, tidak memasukkan data uji ke produk.

## Tes dan pemeriksaan

[report_test.dart](../app_m0/test/report_test.dart): **11 tes terdefinisi** untuk batas tanggal/kolam, parsial+akhir/batal, jumlah snapshot, stale result/error/dispose, refresh commit/batal, UI kosong/loading/gagal/retry/pergantian filter, pendukung/detail tetapfilter, Beranda refresh dan filter antar tab. Bukan11 lulus; perbaikan detail kematian/panen dan bukti izin ada di [M5_PERBAIKAN_DETAIL.md](M5_PERBAIKAN_DETAIL.md).

[report_repository_test.dart](../app_m0/integration_test/report_repository_test.dart): **3 tes native terdefinisi**, periode dua batas/kolam arsip, snapshot setelah harga/rate/sampling+reopen schema4, half-up per transaksi (dua biaya1→2, dua nilai1→2) dan batal. Database `m5_isolated_*`, bukan produk. Regresi M4 migrasi3 diperluas membaca laporan feeding lama/canceled; suite lama M0–M4 dipertahankan di [all_database_test.dart](../app_m0/integration_test/all_database_test.dart).

| Pemeriksaan M5 | Status |
|---|---|
| `flutter analyze` | Terhalang lingkungan; belum dijalankan |
| Seluruh `flutter test` | Terhalang; belum dijalankan, jumlah lulus/gagal tidak diketahui |
| Native/integration SQLite | Belum dijalankan |
| `flutter build apk --debug` M4+M5 | Terhalang; belum menghasilkan APK baru |
| Format Dart | Lulus; [log](../logs/m5-format.log), bukan analisis tipe |
| Checker Dart murni M5/M4 | Lulus exit0, [laporan](../logs/m5-reports-extra.log), [M4](../logs/m5-m4-regression-extra.log); bukti tambahan, bukan Flutter/SQLite/HP |
| Pemasangan/uji HP M4+M5 | Belum dijalankan; dilakukan pengguna setelah tahap ini |

Lingkungan tidak berubah: SDK/cache di luar writable root. Bukti sebelumnya [log M4](../logs/m4-standard-status.log) menunjukkan `UnauthorizedAccessException` untuk `C:\flutter\bin\cache\flutter.bat.lock`. **Tidak mengulang percobaan lock/bootstrap yang sama**, sesuai instruksi pengguna. Status M5 [log](../logs/m5-standard-status.log) merujuk bukti tersebut, bukan log analyze/test/build palsu. Tidak menyalin SDK/menghapus lock/cache/memakai runner alternatif sebagai pengganti standar.

Artifact yang tersedia masih APK M3 v0.4.0+4 (152.201.251byte), bukan M4+M5. Konfigurasi Android/Flutter/dependency tetap riwayat berhasil di README; lockfile tetap SHA256 `5F58FFBDCCAB977D516CEA1A50AAA3BAF679AE979D94CC2DEB671F0E1EA71434`. Metadata saat ini dicatat [di log](../logs/m5-existing-evidence.log). Tidak mengklaim build baru hanya karena versi sumber berubah.

## Terminal Android Studio — verifikasi gabungan

Belum dijalankan untuk sumber M5. Jalankan berurutan, simpan log/exit code dan perbaiki kegagalan sebelum kandidat demo:

```powershell
Set-Location 'C:\Users\basti\OneDrive\Lampiran\Documents\FishCare V2\app_m0'
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>
```

APK produk di `build/app/outputs/flutter-apk/app-debug.apk` wajib **versionName0.6.0/versionCode6**, hash/waktu baru. Suite native dapat memasang entrypoint tes; setelah suite pasang APK produk gabungan sekali melalui `flutter install --debug -d <ID_HP_LOKAL>`. Pemasangan/uji dilakukan pengguna. Jangan uninstall/clear data. Jangan memakai APK M3 sebagai kandidat baru atau menyatakan M4 sudah diverifikasi.

## Uji HP gabungan M4+M5

1. Upgrade versi6 tanpa uninstall; master/stok/koreksi/rate/jam/riwayat M1–M3 tetap. Jalankan sampling/kegiatan/pembatalan M4:100×100g×3%, setelah feeding150 lalu sampling120g→need360/sisa210; mati150 ditolak; parsial20×200g×25000→80ikan/Rp100000; akhir seluruhsisa; populasi0 close tanpa panen.
2. Uji batal lintas kegiatan: hanya last sah active/hari sama; rate/jam/Lewati tidak menghalangi; pemulihan tepat, snapshot/given/skipped utuh; akhir/closed tidak batal. Force-stop/reopen mempertahankan data dan recovery ID sama (crash injection hanya fixture).
3. Laporan pilih tanggal mulai/akhir tepat pada transaksi, satu/semua kolam dan kolam arsip. Cocokkan kelima total dengan pendukung; partial/final sama-sama masuk; tanggal di luar filter tidak masuk. Kondisi kini dan seluruh siklus terpisah dari periode.
4. Ubah harga/rate/sampling setelah transaksi: biaya/nilai lama tetap. Batal kegiatan sah: total turun, riwayat/detail tetap berlabel batal/alasan. Jumlah total sama dengan penjumlahan nilai snapshot tiap transaksi, bukan rumus gabungan.
5. Klik setiap metrik→pendukung→detail→kembali, filter tetap; pindah tab dan transaksi/batal lalu Beranda/Laporan terbaru tanpa restart. Ganti filter cepat saat loading: hanya hasil terakhir ditampilkan. Empty/error/retry tidak berpura-pura nol; offline/keyboard/layar kecil tetap usable.

Catat hasil M4/M5 terpisah, versi APK dan perangkat aktual bila diperiksa. Backup/restore/cuaca produk lengkap belum dibangun. **Berhenti setelah M5.**
