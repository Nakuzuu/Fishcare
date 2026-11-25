# Revisi dosen — Tahap 2: Grading

Tanggal: 25 Oktober 2026. Sumber: **0.8.2+10**, skema **6**, application ID tetap `id.ac.fishcare.m0`. Implementasi FR-05/AT-51 tersedia; pemasangan dan verifikasi database di HP belum dilakukan. Konfirmasi aturan rate ke dosen ditunda sesuai permintaan pengguna dan tidak menghalangi perubahan Grading yang terpisah ini.

## Perubahan dan dampak

- Istilah tampilan Sampling menjadi **Grading** pada tindakan, riwayat, detail, pembatalan dan laporan. Kode internal/payload `sampling` tetap agar riwayat serta retry niat lama kompatibel.
- Riwayat menampilkan **Grading1, Grading2, dst. per siklus**. Urutan berdasarkan commit, bukan timestamp HP. Catatan batal tetap bernomor; nomor tidak digunakan ulang. Catatan lama diberi nomor saat migrasi tanpa mengubah bobot/populasi/ID/payload asal.
- Form Grading menawarkan tanggal rencana default **tujuh hari setelah tanggal usaha grading** dan pemilih tanggal untuk mengubahnya. Ini rencana masa depan, bukan pengisian transaksi mundur/maju.
- Detail kolam aktif menampilkan tanggal/bobot grading sah terakhir, rencana berikutnya, tombol mengubah rencana, serta peringatan jika terlewat. Tanpa grading, bobot awal ditampilkan. Tidak perlu menunggu tujuh hari untuk grading baru; batas satu grading sah per tanggal tetap.
- Rencana baru harus setelah tanggal usaha hari ini. Rencana yang kemudian terlewat tetap tersimpan dan tidak menghalangi pakan. Tidak ada notifikasi background, sortir, perpindahan ikan, atau pengurangan populasi karena grading.
- Pengeditan rencana memakai ID tindakan persisten, validasi ulang tanggal/siklus aktif/revision dan commit atomik. Pengulangan ID tidak membuat perubahan ganda; pratinjau revision lama ditolak.
- Pembatalan grading tetap tunduk pada sah terakhir lintas kegiatan. Bobot dipulihkan dan rencana bawaan grading ikut dipulihkan ke kondisi sebelumnya bila belum diedit terpisah. Rencana yang sudah diedit terpisah dipertahankan. Edit rencana bukan penghalang pembatalan operasional.
- Payload grading baru menyimpan rencana dan revision yang ditinjau. Niat sampling lama tanpa field baru tetap bisa diproses memakai tanggal+7, tanpa mengubah payload asal. Pemulihan tindakan menampilkan tanggal rencana bila tersedia.

## Penyimpanan dan berkas utama

`grading.dart` mendefinisikan aturan tanggal, label nomor, skema dan pemulihan rencana. `grading_ui.dart` memuat panel rencana dan pemilih tanggal. `lifecycle_ui.dart`, `activity_ui.dart`, `feed_ui.dart` menghubungkan form, riwayat dan pemulihan. `m4_operations.dart` serta `feed_repository.dart` menyimpan perubahan dalam transaksi. `report_repository.dart` dan `report_ui.dart` membawa nomor grading ke laporan.

`master_repository.dart` menambah migrasi **1–5→6**, mempertahankan jalur migrasi sebelumnya. Dua tabel tambahan:

- `grading_records`: hubungan ke operasi sampling, nomor per siklus dan kondisi rencana sebelum grading. Migrasi mencakup sampling batal untuk nomor yang stabil. Tidak mengarang rencana historis.
- `grading_plans`: tanggal rencana terkini per siklus, asal grading bila ada, dan revision. NULL tanggal berarti tidak ada rencana. Pengeditan manual memutus hubungan asal agar pembatalan grading tidak menimpa edit pengguna.

Tidak reset database, uninstall, mengubah ID aplikasi, mengganti rumus pakan atau mengubah snapshot transaksi lama. Versi pada pubspec berubah; tidak menambah dependency atau mengubah pin paket. Belum membangun backup/restore, rate otomatis, input suhu/pH, atau ekspor XLSX.

## Pemeriksaan dan bukti

| Pemeriksaan | Status | Bukti |
|---|---|---|
| `flutter analyze` | Lulus pada pemeriksaan sebelum suite akhir; hasil final dicatat di log | `logs/grading-stage2-analyze.log` |
| `flutter test --concurrency=1 --reporter expanded` | **Lulus70 tes**, seluruh suite standar | `logs/grading-stage2-flutter-test-final.log` |
| `flutter build apk --debug` | **Lulus**, APK0.8.2+10 dibuat sesi ini | `logs/grading-stage2-build.log` |
| Migrasi/rollback/reopen SQLite Android | **Belum dijalankan di HP** | Empat skenario native baru disiapkan di `integration_test/lifecycle_transactions_test.dart`; bukan bagian70 tes unit/widget |
| Pemasangan dan manual HP | **Belum dijalankan** | `flutter devices --machine` tidak menemukan Android; tidak menggantinya dengan Windows/web |

Pemeriksaan awal SDK lokal tertahan lock. Jalur eskalasi resmi kemudian berhasil, sehingga analyze/test/build di atas adalah jalur Flutter standar, bukan harness alternatif.

Suite awal menemukan konflik tipe pada fixture cuaca karena impor relatif dan package bercampur, dua impor tidak terpakai, serta asumsi tes bahwa kontrol di luar layar sudah terpasang/terjangkau. Diperbaiki dengan impor package konsisten, menggulir kontrol sampai dapat ditekan, memeriksa controller untuk draft yang tidak terlihat, dan mengirim dua ketukan pada posisi tombol konfirmasi yang sama. Assertion bisnis dipertahankan. Log percobaan gagal tetap ada pada `grading-stage2-flutter-test.log`, `grading-stage2-flutter-test-retry.log`, serta `grading-stage2-targeted.log`; hasil akhir70 lulus tidak menghapus riwayat diagnosis.

Tes baru standar: kalender rencana melintasi bulan/tahun dan validasi tanggal; riwayat Grading2 batal menampilkan nomor, populasi dan alasan yang sama pada detail. Skenario native baru: nomor setelah batal/retry/reopen, edit rencana bertahan saat pembatalan dan revision stale, rollback tanggal invalid serta grading fleksibel/rencana terlewat, migrasi skema5 mempertahankan sampling lama tanpa rencana rekaan.

APK: `app_m0/build/app/outputs/flutter-apk/app-debug.apk`, ukuran **152.378.696 byte**, SHA-256 **4F59076187C8401F175F533C3F75AEA8A7E07BCE06F930ECAF183BB472ACFE13**. Metadata build menyatakan0.8.2+10. Peringatan Gradle tentang native access muncul tetapi build selesai; tidak mengubah konfigurasi global sebagai respons.

## Langkah uji HP berikutnya

1. Hubungkan HP dan periksa model/API aktual. Tanpa uninstall/clear data, simpan bukti kondisi data lama.
2. Pada lingkungan uji yang sesuai, jalankan `flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>` dari `app_m0`. Suite memakai database terisolasi; bukan data budidaya pengguna. Tes native dapat memasang aplikasi uji, sehingga setelah suite pasang kembali APK produk melalui upgrade biasa.
3. Verifikasi label Grading dan nomor pada data lama, termasuk batal. Pastikan populasi, stok, riwayat pemberian dan biaya lama tidak berubah.
4. Catat grading, ubah saran tanggal, pastikan bobot berubah tanpa populasi berkurang. Tutup/buka aplikasi dan periksa persistensi.
5. Ubah rencana setelah grading, batalkan grading sah terakhir dengan alasan; pastikan rencana edit tetap dan bobot pulih. Buat grading pengganti pada hari yang sama setelah pembatalan: nomor baru tidak memakai ulang nomor batal.
6. Verifikasi tanggal terlewat pada data uji terisolasi, bukan mengganti jam HP/data produk demi tes. Peringatan tidak memblokir pemberian.
7. Periksa layar360dp/teks130%, keyboard, kembali, konfirmasi batal dan simpan berulang.

Tahap ini belum disebut terverifikasi penuh sampai uji database dan manual HP selesai. Berhenti di Tahap2; keputusan pakan yang ditunda tidak diterapkan.
