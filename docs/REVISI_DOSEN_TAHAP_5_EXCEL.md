# Revisi dosen — Tahap 5: ekspor laporan Excel

Tanggal: **26 Oktober 2026**. Sumber **0.10.0+13**, skema tetap **7**, ID tetap `id.ac.fishcare.m0`.

## Perilaku dan cakupan

FR-07/PRD15.5, AT-52–53: tombol **Ekspor Excel (.xlsx)** pada halaman Laporan mengekspor snapshot yang sedang tampil, memakai tanggal inklusif dan kolam dari snapshot tersebut. Tombol tidak tersedia saat laporan memuat/gagal, dan terkunci selama penyimpanan. Beranda tidak menambahkan tombol ekspor.

File berisi dua lembar:

- **Ringkasan**: periode, pilihan satu/semua kolam, total pakan aktual, biaya pakan, kematian, jumlah dan nilai panen. Memakai fungsi agregasi yang sama dengan layar. Kondisi saat ini/seluruh siklus tidak dicampur ke total periode.
- **Transaksi**: rincian pada filter, termasuk transaksi batal yang ditandai dan dikecualikan dari total. Memuat suhu/pH, jumlah aktual, harga/kg dan biaya snapshot, porsi normal/rekomendasi, alasan, bobot/nomor grading, nilai panen, rate, waktu ukur UTC dan versi aturan. Pengukuran historis kosong ditulis **Tidak tercatat**; rekomendasi kosong bukan nol. Nilai uang/jumlah berupa angka; bilangan bulat 16 digit atau lebih berupa teks untuk menjaga ketepatan Excel. Teks pengguna selalu sel teks, bukan rumus.

Laporan kosong tetap mempunyai konteks periode, judul kolom dan total sah nol. Header diberi warna, teks dibungkus, baris pertama dibekukan. Ekspor membaca data lokal dan tidak memanggil cuaca/jaringan. Pemilih Android dapat menawarkan penyedia cloud; ketersediaan penyedia tersebut bukan jaminan ekspor offline. Untuk offline pilih penyimpanan lokal HP.

Pengguna menentukan lokasi lewat `ACTION_CREATE_DOCUMENT` Android. Tidak meminta izin akses seluruh penyimpanan. Hanya penutupan stream yang berhasil menghasilkan status sukses. Batal menghasilkan **Ekspor dibatalkan**, gagal menghasilkan pesan gagal tanpa mengubah database. Penyedia dokumen mungkin meninggalkan file tidak lengkap ketika tulis gagal; file itu bukan backup atau ekspor berhasil. Activity terhenti saat pemilih terbuka tidak dianggap pembatalan karena itu alur normal Android; Activity dihancurkan tidak dilaporkan sukses.

Tidak ada migrasi, perubahan rumus pakan atau dependency baru. Writer SpreadsheetML/ZIP terbatas di Dart menghasilkan paket XLSX asli, bukan CSV yang diganti ekstensi. Struktur mengikuti [SpreadsheetML Microsoft](https://learn.microsoft.com/en-us/office/open-xml/spreadsheet/structure-of-a-spreadsheetml-document); penyimpanan mengikuti [Storage Access Framework Android](https://developer.android.com/training/data-storage/shared/documents-files). Batas baris Excel/teks sel diperiksa; kegagalan tidak dilaporkan sukses. Ekspor dilakukan di memori; ukuran sangat besar belum diuji pada HP RAM terbatas, gunakan filter periode yang wajar.

## Berkas

- `app_m0/lib/report_export.dart`: pemetaan snapshot, agregasi bersama, paket XLSX dan kanal simpan.
- `app_m0/lib/report_ui.dart`: tombol, pencegahan ketukan saat sibuk, pesan hasil.
- `app_m0/android/app/src/main/java/id/ac/fishcare/m0/ReportExport.java` dan `MainActivity.java`: pemilih file, penulisan di thread terpisah, hasil batal/gagal/sukses.
- `app_m0/test/report_export_test.dart`: empat tes baru, termasuk contoh workbook terisolasi.
- `app_m0/pubspec.yaml`: versi aplikasi; lockfile/dependency tetap.

## Verifikasi

| Pemeriksaan | Status dan bukti |
|---|---|
| `flutter analyze` | Lulus, tanpa issue; `logs/export-stage5-analyze-final.log` |
| `flutter test --concurrency=1 --reporter expanded` | **110 tes lulus** (106 sebelumnya +4 ekspor); `logs/export-stage5-flutter-test-final.log` |
| `flutter build apk --debug` | **Lulus**,52,3detik; `logs/export-stage5-build.log` |
| Identitas APK | **Lulus**,0.10.0+13,ID sama,minSdk24,target/compile36; `logs/export-stage5-apk-badging.log` |
| Pembaca XLSX terpisah | **Lulus pada fixture**: openpyxl3.1.5 membaca dua sheet, CRC ZIP valid, angka1125g/Rp16875 cocok, harga15000/kg,23°C/pH7, batal terpisah dan pengukuran lama tidak dibuat-buat; `logs/export-stage5-xlsx-reader.json` |
| Pemilih file pada tes widget | Lulus dengan kanal palsu: permintaan tertunda menolak ketukan kedua, batal/gagal tidak sukses, berhasil menampilkan sukses |
| Pemilih file Android nyata, buka di Excel/WPS HP, mode offline HP | **Belum dijalankan**, perangkat Android tidak tersedia |

Tes awal ketukan ganda memakai respons batal instan sehingga permintaan kedua sebenarnya terjadi setelah yang pertama selesai. Fixture diperbaiki memakai respons tertunda untuk menguji kondisi sibuk yang dimaksud; pemeriksaan jumlah panggilan tetap dipertahankan. Log awal `logs/export-stage5-targeted.log`; hasil empat tes akhir `logs/export-stage5-targeted-final.log`. Ini perbaikan pengaturan tes, bukan klaim menemukan transaksi ganda dalam database.

Fixture `output/export-stage5/fixture-report.xlsx` berisi data uji, bukan data pengguna. Pemeriksaan pembaca independen membuktikan format/isi file tersebut, bukan hasil pemilih file Android atau kompatibilitas semua aplikasi spreadsheet. Verifikasi SQLite/migrasi Tahap4 yang belum dilakukan tetap terbuka.

## Uji HP berikutnya

APK: [fishcare-0.10.0-debug.apk](../artifacts/revisi-tahap5/fishcare-0.10.0-debug.apk), **152.440.572 byte**. SHA-256 **D5DB5A3B8E63E443C4FA8CDCFE8902307D0637EF37FDEEAD5E8D8B3E3ADEA907**. Salinan stabil sama dengan hasil build. Metadata: `logs/export-stage5-artifact.json`. Warning native access Gradle tidak menghentikan build; tidak mengubah SDK global.

1. Pasang APK sebagai pembaruan tanpa uninstall/clear data. Pastikan versi0.10.0+13 dan data lama tetap.
2. Pilih satu kolam dan rentang tanggal; catat total layar, ekspor ke penyimpanan lokal, buka di Excel/WPS dan cocokkan semua total serta rincian. Ulangi semua kolam/kolam arsip.
3. Periksa transaksi batal tetap berlabel dan tidak masuk total; data lama tanpa suhu/pH bukan nol. Ganti grading/harga dan pastikan transaksi lama tetap memakai snapshotnya.
4. Coba periode kosong, batal pemilih, tujuan gagal/penyedia tak tersedia, serta mode pesawat dengan tujuan lokal. Tidak boleh ada pesan sukses pada batal/gagal atau perubahan data lokal.
5. Ketuk ekspor berulang, kembali dari pemilih, tutup/buka aplikasi, cek file hasil. Uji SQLite native dan migrasi Tahap4 tetap memerlukan suite Android terisolasi.

Tahap5 tidak menambahkan backup/restore dan tidak otomatis melanjutkan tahap berikutnya.
