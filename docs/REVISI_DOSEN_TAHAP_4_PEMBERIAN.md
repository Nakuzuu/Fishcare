# Revisi dosen — Tahap 4: pemberian dengan pengukuran air

Tanggal: **26 Oktober 2026**. Sumber **0.9.0+12**, skema **7**, ID `id.ac.fishcare.m0` tetap.

**Implementasi aktif dalam APK baru. Analisis,106 tes standar dan build APK lulus; pemasangan, migrasi SQLite Android dan uji manual HP belum dilakukan karena perangkat Android tidak terdeteksi.** Tidak menyatakan kandidat sudah terverifikasi penuh di HP.

## 1. Perilaku yang berubah

Pengguna memilih aktivasi **langsung hari ini untuk pemberian berikutnya** pada siklus lele yang sudah berjalan. PRD15.8/15.10/15.11 menjadi acuan, bukan usulan redistribusi lama Tahap1.

- Mulai siklus baru menggunakan lele, bobot awal, populasi, pakan dan jadwal. Rate ditampilkan otomatis dari tabel bobot; bukan field manual. Setelah grading, rate dan porsi menunggu mengikuti bobot terbaru.
- Setiap halaman pemberian baru memulai input **suhu air dan pH kosong**. Nilai tidak diambil dari transaksi lama atau API cuaca. Waktu pencatatan pengukuran disimpan; pengukuran tanggal usaha lain/masa depan ditolak.
- Suhu25–30 °C dan pH6,5–8: rekomendasi normal. Suhu<24 °C dengan pH sesuai:80% porsi normal slot. Suhu24–<25 °C, >30 °C, atau pH di luar acuan: peringatan tanpa angka rekomendasi; aktual valid tetap boleh ditinjau/dicatat.
- Harga/kg terlihat pada kartu awal. Saat aktual diisi, total biaya langsung berubah sebelum konfirmasi. Tombol Gunakan jumlah rekomendasi mengisi aktual hanya atas tindakan pengguna. Perubahan pengukuran tidak diam-diam mengganti aktual yang sudah diketik.
- Selisih aktual dan Lewati tidak dibagikan ke slot lain. Perubahan kondisi ikan membagi kebutuhan normal terbaru pada seluruh jam hari ini; hanya porsi menunggu diperbarui. Jam besok tetap terpisah. Aktual berlebih memerlukan konfirmasi tambahan.
- Tanpa rate yang disepakati (contoh bobot<2 g), statusnya **Belum bisa dihitung**, bukan rate/kebutuhan nol. Populasi benar-benar nol dan porsi valid yang membulat nol tetap tidak menerima transaksi pemberian nol.
- Sebelum konfirmasi, harga/kondisi/jadwal baru yang berbeda dari rincian form harus ditinjau ulang. Saat commit, baca ulang fingerprint kondisi serta stok bersama dalam transaksi. Perubahan saat konfirmasi terbuka juga ditolak tanpa potongan stok sebagian.
- Detail kegiatan, riwayat pemberian dan laporan membaca snapshot pengukuran/rekomendasi yang tersimpan. Data lama tanpa pengukuran bertanda Tidak tercatat. Perubahan grading/harga berikutnya tidak menulis ulang snapshot lama.

Contoh:1.000 ikan ×50 g ×2,5%=1.250 g/hari →625 g per slot pada dua jam. Pagi23 °C/pH7 direkomendasikan500 g. Aktual pagi450 g tetap450 g; sore normal tetap625 g. Setelah grading menjadi60 g, rate2,2% dan kebutuhan1.320 g/hari: porsi sore menjadi660 g, tanpa menulis ulang pemberian pagi.

## 2. Penyimpanan dan pemulihan data lama

Migrasi **1–6→7** menambah kolom, tidak reset tabel/data. Definisi skema lama dan jurnal idempotensi dipertahankan; lockfile/dependency tidak diubah.

- `cycles.feeding_policy`: versi aturan aktif. Siklus aktif dengan kata `lele` pada label jenis ikan diaktifkan langsung. Kata dicocokkan tanpa kapitalisasi; nama seperti “Lelehan” atau spesies lain tidak dianggap lele. Siklus selesai tetap pada penandaan lama saat migrasi. Niat mulai siklus lama tetap memakai payload asal; jika jenisnya lele, kondisi aktif hasilnya menggunakan aturan otomatis.
- `cycle_slots.normal_auto_g`: porsi normal otomatis, nullable saat belum bisa dihitung. `planned_g` lama tetap untuk kompatibilitas; bukan fallback ketika rate otomatis belum tersedia. Porsi slot diberikan/dilewati tidak ditulis ulang ketika kondisi berubah.
- `feedings`: versi/acuan aturan, suhu0,1 °C, pH0,01, waktu catat, status suhu/pH, rekomendasi nullable, alasan, faktor dan pengurangan suhu. Porsi normal memakai snapshot porsi yang sudah tersedia, bersama aktual/rate/bobot/populasi/biomassa/harga/biaya lama. Kolom baru pada baris lama tetap NULL.
- `legacy_feeding_intents`: hanya ID pemberian **prepared sebelum migrasi** yang boleh mempertahankan input lama tanpa pengukuran baru. Payload, jenis dan target tetap diperiksa oleh jurnal. Retry eksplisit ID sama mengembalikan hasil commit lama atau mencoba transaksi yang sama; tidak ada retry otomatis/ID baru otomatis. Harga/rate, stok, tanggal dan slot tetap divalidasi. Snapshot hasil pemulihan ini bertanda legacy, tanpa suhu/pH buatan.

Pengecualian niat lama bukan jalur membuat pemberian otomatis baru tanpa pengukuran. Pemberian baru pada lele otomatis wajib membawa versi aturan, fingerprint pratinjau dan pengukuran yang valid.

Siklus lama yang jenis ikannya tidak dikenali sebagai lele tetap manual, dengan label jelas. Form pemberiannya tetap meminta pengukuran dan menampilkan biaya; tabel lele tidak diterapkan diam-diam pada spesies lain. Backup/restore belum tersedia dan tidak ditambahkan pada tahap ini; kontrak backup kelak perlu mencakup skema7 serta tabel pengecualian niat. Ekspor XLSX tetap Tahap5.

## 3. Berkas utama

| Area | Berkas dalam `app_m0/lib` | Dampak |
|---|---|---|
| Migrasi | `feeding_schema.dart`, `master_repository.dart` | Skema7, aktivasi lele dan daftar niat lama |
| Kebutuhan/rate | `cycle_repository.dart`, `cycle_rules.dart`, `cycle_ui.dart` | Rate otomatis, nilai nullable yang jujur, porsi per seluruh jadwal, start otomatis, larangan edit manual pada mode otomatis |
| Form | `water_feeding_ui.dart`, `feeding_input.dart`, `feed_ui.dart` | Pengukuran baru, parsing/validasi, biaya langsung, konfirmasi, recovery |
| Transaksi | `feed_repository.dart` | Pemeriksaan ulang, snapshot, stok/ledger atomik dan retry lama |
| Ringkasan/riwayat | `dashboard_ui.dart`, `activity_ui.dart`, `lifecycle_ui.dart`, `water_snapshot_ui.dart` | Rencana menunggu dan pengukuran historis tanpa nilai rekaan |
| Laporan | `report_repository.dart`, `report_ui.dart` | Snapshot pengukuran serta rate kondisi kini dari sumber yang sama |

Komentar mesin aturan Tahap3 diperbarui untuk menjelaskan bahwa kebijakan sekarang aktif pada siklus yang ditandai. `pubspec.yaml` menjadi0.9.0+12. Konfigurasi native, manifest, plugin dan pin dependency tidak diubah. Source sebelum revisi disalin untuk pembandingan di `tmp/feeding-stage4-before`, bukan salinan database pengguna atau SDK.

## 4. Hasil pemeriksaan

| Pemeriksaan | Hasil | Bukti |
|---|---|---|
| `flutter analyze` | **Lulus, tanpa issue** | `logs/feeding-stage4-analyze-final.log` |
| `flutter test --concurrency=1 --reporter expanded` | **106 tes lulus**, seluruh suite standar | `logs/feeding-stage4-flutter-test-final.log` |
| `flutter build apk --debug` | **Lulus** | `logs/feeding-stage4-build.log` |
| Identitas biner APK | **Lulus**:0.9.0+12, ID sama, minSdk24, target/compile36 | `logs/feeding-stage4-apk-badging.log`, `logs/feeding-stage4-artifact.json` |
| Render360dp/teks130% | **Lulus pada fixture**, gambar awal dan terisi diperiksa visual | `output/feeding-stage4/initial-360-text130.png`, `filled-360-text130.png` |
| SQLite native/upgrade/reopen di Android | **Belum dijalankan**;8 tes native baru disiapkan | `integration_test/automatic_feeding_transactions_test.dart`, masuk suite `all_database_test.dart` |
| Pemasangan/manual HP | **Belum dijalankan**;0 perangkat Android | `logs/feeding-stage4-android-devices.json` |

106 tes terdiri dari98 sebelumnya,7 tes parser/form/snapshot dan1 tes render baru. Tes form memakai repository palsu terisolasi, tidak membuka database produk. Render memakai font lokal untuk keterbacaan (Segoe UI pada laptop ini), bukan screenshot HP atau bukti font/keyboard Android. Pemeriksaan visual menunjukkan field, rekomendasi, biaya dan tombol dapat dibaca/digulir, tanpa overflow pada konfigurasi uji.

Tes awal menemukan satu asumsi tes lama: tombol form siklus sudah terpasang di layar. Tes diperbarui untuk menggulir ke tombol dan menguji bobot invalid pada alur otomatis sebagai pengganti field manual yang dihapus. Tes parser rate legacy tetap dipertahankan. Assertion tidak dihapus/dilemahkan agar lulus. Log diagnosis awal tetap pada `logs/feeding-stage4-targeted.log`/`feeding-stage4-analyze-initial.log`; hasil akhir ada pada log final.

Delapan skenario native baru mencakup:

1. Pagi dingin, aktual berbeda, sore tidak redistribusi; snapshot tetap setelah grading/restart, retry satu kali.
2. Suhu32 °C/pH di luar rentang: rekomendasi NULL tetapi aktual tersimpan.
3. Pengukuran hilang, stok kurang dan aktual berlebih tanpa konfirmasi ditolak utuh.
4. Harga/grading setelah pratinjau menolak snapshot stale.
5. Kegagalan teknis saat insert rollback, niat tetap prepared; retry ID sama setelah reopen memotong stok sekali.
6. Lewati tidak redistribusi; batal memulihkan stok; pemberian pengganti membutuhkan pengukuran baru.
7. Hari berganti atau waktu ukur lama ditolak tanpa menulis pemberian.
8. Migrasi6→7 pada lele aktif dengan pemberian pagi dan niat prepared lama: aktivasi langsung, payload asal dan snapshot pagi tetap, recovery tepat satu kali.

Tes native tersebut **belum termasuk angka106 lulus**. Kompilasi/analisis sumber tes bukan keberhasilan transaksi SQLite Android. Perbandingan snapshot pada tes mengecualikan indikator tampilan `is_last_operation` yang memang berubah setelah kegiatan baru; seluruh kolom historis bisnis tetap diperiksa.

Pemetaan: FR-02/03/04 dan tampilan FR-05/07; AT-47–50,55–58 pada lapisan aturan/form; AT-60–63 dan bagian database AT-05–07/15–17/25/31/36 masih menunggu native/HP. Tidak mengklaim seluruh AT lulus di perangkat.

## 5. Artifact dan uji HP berikutnya

APK stabil: **`artifacts/revisi-tahap4/fishcare-0.9.0-debug.apk`**. Salinan build: `app_m0/build/app/outputs/flutter-apk/app-debug.apk`. Ukuran **152.431.604 byte**, SHA-256 **EE54E104E795C58A11A2AE973120DC7770EFCD31F82A855C6C75B80FA7E2591D**. Salinan stabil diverifikasi sama dengan hasil build sesi ini. Warning native access Gradle tidak menghentikan build; tidak mengubah konfigurasi SDK global untuk menutup warning.

Langkah setelah HP terhubung:

1. Verifikasi perangkat/API aktual dan pasang APK sebagai pembaruan biasa, tanpa uninstall/clear data. Jangan menganggap identitas perangkat historis sebagai perangkat yang sedang tersambung.
2. Periksa data lama: nama kolam, populasi, bobot, stok dan snapshot biaya tetap. Siklus lele aktif langsung memakai rate bobot; pengukuran lama tetap Tidak tercatat.
3. Jalankan suite native terisolasi dari root `app_m0`: `flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>`. Jangan memakai/reset database produk sebagai fixture. Setelah suite, pasang kembali APK produk melalui upgrade biasa bila entrypoint uji menggantikannya.
4. Di data demonstrasi yang sesuai, ukur dan catat pemberian pagi/sore; periksa80%, peringatan32 °C/pH di luar acuan, harga/biaya awal, Lewati, grading, pembatalan dan stok bersama. Jangan membuat pengukuran dummy dalam data operasional untuk menyatakan API/pengukuran nyata berhasil.
5. Tutup/buka aplikasi, periksa persistensi, mode offline, recovery, keyboard, teks besar dan navigasi kembali. Verifikasi hasil ekspor pada Tahap5 kelak, bukan menganggap XLSX sudah tersedia.

Tahap4 implementasi selesai; **verifikasi native/HP masih terbuka**. Berhenti di sini, tidak otomatis lanjut ekspor Excel.
