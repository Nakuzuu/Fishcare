# Maskot dan perkenalan — 18 November 2026

Sumber **0.12.0+17**, skema tetap **7**. Ikon ikan umum, splash FishCare dan tiga halaman pengenalan tersedia. Lewati/Mulai menyimpan preferensi UI terpisah dari data kolam; pembukaan berikutnya melewati perkenalan.

**Analisis bersih,144 tes Flutter dan1 tes Android lulus; build dan pemasangan berhasil** pada Infinix X6879 Android16/API36. Ikon dan halaman1–3 diperiksa langsung. Perkenalan pada aplikasi utama dibiarkan belum selesai agar pengguna bisa mencoba. Data budidaya dan perhitungannya tetap; sidik database utama sebelum/sesudah instalasi dan navigasi perkenalan sama.

[APK0.12.0](artifacts/onboarding-2026-11-18/FishCare-0.12.0-maskot.apk) · [Pratinjau](output/onboarding-2026-11-18/Pratinjau-FishCare-0.12.0.png) · [Berkas, acuan dan batas pengujian](docs/PERKENALAN_DAN_IKON_2026-11-18.md).

# Penyesuaian tampilan — 18 November 2026

Sumber **0.11.1+16**, skema tetap **7**. Populasi/bobot dua kolom, form kolam, tombol kegiatan/siklus dan kartu jam memanjang mengikuti referensi desain pengguna. Backend, database dan aturan perhitungan tetap.

Analisis lulus, **134 tes standar lulus**, build APK lulus. Render pada 390dp/100% dan 360dp/130% diperiksa. **Pemasangan dan manual HP belum dijalankan** karena tidak ada Android terhubung. [APK desain](artifacts/ui-match-2026-11-18/FishCare-0.11.1-desain.apk) · [Pratinjau data uji](output/ui-match-2026-11-18/Pratinjau-FishCare.png) · [Perubahan dan verifikasi](docs/PENYESUAIAN_DESAIN_2026-11-18.md).

# FishCare V2 — hasil panen setelah biaya pakan

Sumber **0.11.0+15**, skema tetap **7**. Riwayat panen akhir dan Laporan siklus selesai menampilkan tabel pendapatan kotor, pakan terpakai, biaya pakan dan hasil setelah biaya pakan. Seluruh panen sebagian/akhir dan pemberian sah dalam satu siklus dihitung dari snapshot; transaksi batal dikecualikan, hasil negatif tetap negatif. Tidak menambahkan biaya lain atau menyebut hasilnya keuntungan bersih.

Analisis bersih, **120 tes standar dan54 tes Android lulus** pada aplikasi uji terpisah. Build produk berhasil dan0.11.0+15 sudah terpasang pada HP tanpa uninstall/reset. Pemeriksaan manual tabel pada data operasional belum dilakukan. [APK0.11.0+15](artifacts/hasil-panen/fishcare-0.11.0-debug.apk) · [Kebutuhan, perubahan dan batas pengujian](docs/HASIL_PANEN_BIAYA_PAKAN.md). Riwayat serta kontrak ekspor periode tetap berlaku.

## Riwayat regresi dan uji HP (Tahap 6)

Sumber **0.10.1+14**, skema **7**. Analisis bersih, **114 tes standar dan53 tes Android lulus** pada Infinix X6879 Android16/API36. APK produk dibangun dan dipasang sebagai pembaruan biasa. Migrasi data HP skema5→7 berhasil: data historis dan20 slot lama tetap,2 slot baru hari ini ditambahkan. Tes native memakai **FishCare Uji** dengan ID terpisah; jangan jalankan perintah native historis langsung pada aplikasi utama.

Alur batal/simpan Excel di pemilih file Android berhasil. **Isi file aktual di Excel/WPS diperiksa sendiri oleh pengguna** sesuai pilihannya; mode pesawat dan seluruh skenario manual belum dinyatakan lulus. [Laporan lengkap, bukti dan perintah tes aman](docs/REVISI_DOSEN_TAHAP_6_REGRESI.md) · [APK0.10.1+14 yang sudah terpasang](artifacts/revisi-tahap6/fishcare-0.10.1-debug.apk).

## Riwayat ekspor laporan Excel (Tahap 5)

Sumber **0.10.0+13**, skema tetap **7**. Laporan dapat diekspor sebagai Excel `.xlsx` sesuai filter periode/kolam, berisi Ringkasan dan Transaksi dengan harga/biaya snapshot serta suhu/pH. Transaksi batal tidak masuk total; pengukuran lama tetap Tidak tercatat. Lokasi simpan dipilih lewat pemilih dokumen Android; batal/gagal tidak dianggap sukses.

Analisis bersih, **110 tes standar lulus**, build APK lulus, dan fixture XLSX berhasil dibaca dengan pembaca terpisah. Pemilih file/pembacaan Excel di HP belum diuji karena Android tidak tersedia. [APK uji0.10.0+13](artifacts/revisi-tahap5/fishcare-0.10.0-debug.apk) · [Rincian Tahap5](docs/REVISI_DOSEN_TAHAP_5_EXCEL.md). Riwayat Tahap4 dan batas verifikasi migrasinya tetap berlaku.

## Riwayat pemberian dengan suhu/pH (Tahap 4)

Sumber **0.9.0+12**, skema **7**, ID aplikasi tetap. Aturan pakan lele sudah aktif dalam APK baru: rate dari bobot, input suhu/pH setiap pemberian, rekomendasi per slot tanpa redistribusi, harga/kg dan biaya sebelum konfirmasi, serta snapshot pengukuran pada riwayat/laporan. Siklus lele aktif beralih langsung pada pemberian berikutnya sesuai keputusan pengguna; data lama dan input niat pemulihan lama dipertahankan.

Analisis lulus, **106 tes standar lulus**, build APK debug lulus; render360dp/teks130% diperiksa sebagai fixture. **Pemasangan, migrasi SQLite Android dan manual HP belum dijalankan** karena Android tidak terdeteksi. [Laporan perubahan, bukti, batas verifikasi dan langkah HP](docs/REVISI_DOSEN_TAHAP_4_PEMBERIAN.md). [APK uji0.9.0+12](artifacts/revisi-tahap4/fishcare-0.9.0-debug.apk). Ekspor Excel belum ditambahkan; berhenti Tahap4.

## Riwayat persiapan aturan pakan (Tahap 3)

Sumber **0.8.3+11**, skema tetap **6**, ID aplikasi tetap. Mesin rate bobot, rekomendasi suhu/pH per slot dan proyeksi harian tanpa redistribusi sudah disiapkan. **Belum diaktifkan pada layar/transaksi produksi**; aktivasi utuh bersama form pengukuran dan snapshot pada Tahap4. Grading Tahap2 tetap tersedia.

`flutter analyze` lulus, **98 tes Flutter standar lulus**, dan APK debug0.8.3+11 berhasil dibangun. **Tes SQLite native, pemasangan dan manual HP belum dilakukan** karena Android tidak terdeteksi. [Rincian aturan, keputusan pengguna, berkas, bukti dan batas tahap](docs/REVISI_DOSEN_TAHAP_3_PAKAN.md). Berhenti setelah persiapan Tahap3.

## Riwayat revisi Grading (Tahap 2)

Sumber **0.8.2+10**, skema **6**, ID aplikasi tetap. Sampling pada tampilan menjadi Grading dengan nomor per siklus, catatan bobot/tanggal terakhir, rencana berikutnya default7 hari yang bisa diubah, serta peringatan terlewat tanpa memblokir pakan. Data lama dipertahankan; tidak ada perubahan rumus pakan/suhu/pH/ekspor pada tahap ini.

Seluruh **70 tes Flutter standar lulus**, analisis kode lulus, dan APK debug berhasil dibangun melalui jalur standar. **Pemasangan, migrasi SQLite Android dan manual HP belum dijalankan** karena Android tidak terdeteksi. [Rincian perubahan, artifact, log dan langkah HP](docs/REVISI_DOSEN_TAHAP_2_GRADING.md). Berhenti pada Tahap2.

## Riwayat perapian UI dan cuaca utama

Sumber **0.8.1+9**, skema5 dan application ID tetap. Cuaca kini tepat setelah header Beranda, dengan suhu/ikon/kondisi dan waktu yang ramah; detail kolam, riwayat serta Laporan diringkas menjadi informasi terstruktur. [Rincian revisi, tes, render sebelum/sesudah dan langkah HP](docs/UI_RAPIKAN_2026-10-20.md).

Verifikasi agen: formatter lulus dan7pemeriksaan format Dart murni tambahan lulus; jalur standar analyze/test/build masih terhalang akses lock SDK. Screenshot render belum dihasilkan/diperiksa, jadi belum menyatakan tampilan rapi/stabil. HP Infinix X6879 Android16/API36 terhubung dengan package0.8.0; screencap saat layar Dozing tidak menjadi bukti tampilan aplikasi. Tidak ada pemasangan atau uji regresi revisi9 yang dinyatakan berhasil. Menunggu hasil terminal berakses SDK dan layar HP terbuka.

## Riwayat UI0.8.0

# FishCare V2 — UI baru statis

Sumber **0.8.0+8**, skema tetap **5**, application ID tetap `id.ac.fishcare.m0`. Tema, empat menu, form/detail/konfirmasi/riwayat, lokasi dan keadaan UI ditata mengikuti desain baru. Tidak mengubah data, aturan bisnis, dependency atau lockfile; belum menambah animasi dekoratif.

**Belum terverifikasi:** `flutter analyze`, seluruh `flutter test`, dan `flutter build apk --debug` dicoba tetapi terhalang bootstrap/akses SDK; eskalasi resmi ditolak otomatis. Formatter lulus, bukan analisis atau tes. Enam tes UI baru disiapkan tetapi belum berjalan. Tidak ada APK baru tahap ini; tidak ada HP/emulator terhubung, pemasangan/uji HP belum dilakukan. Rincian layar, perbedaan desain, log dan langkah HP: [IMPLEMENTASI_UI_BARU.md](docs/IMPLEMENTASI_UI_BARU.md).

## Riwayat tahap lokasi dan cuaca

# FishCare V2 — lokasi usaha dan cuaca atas tindakan pengguna

Sumber **0.7.0+7**, skema produk **5**. Keputusan pengguna14Oktober2026: HP hanya diambil setelah [Ambil lokasi saat ini], izin foreground jika perlu dan fix sekali. Hasil HP/manual hanya calon; [Simpan sebagai lokasi usaha] perlu konfirmasi. Satu lokasi tersimpan untuk seluruh kolam; refresh cuaca tidak mengambil ulang HP. Batal/izin ditolak/GPS mati/fix gagal menjaga lokasi sebelumnya. Tidak melacak pengguna atau meminta lokasi background.

Rincian FR-08/AT-41–45, migrasi yang menjaga data M1–M5, source, bukti dan uji HP: [TAHAP_CUACA_LOKASI.md](docs/TAHAP_CUACA_LOKASI.md). Tidak menambah dependency; lockfile tetap. Produk tetap terpisah marker M0; tidak uninstall/reset. M4/M5 belum dinyatakan terverifikasi HP; manual M2+M3 tetap laporan pengguna.

| Pemeriksaan | Status |
|---|---|
| Format Dart | Lulus, bukan analisis tipe |
| Checker state lokasi/cuaca Dart murni | Lulus bukti tambahan dengan mock, bukan Flutter/native/HP |
| API nyata CLI Jakarta | Gagal koneksi sesi: SocketException errno1225 ke127.0.0.1:52605; bukan bukti API/HP sukses |
| Flutter analyze / seluruh flutter test / build APK | Terhalang; belum dijalankan, SDK/cache global tidak tersedia tulis dan izin eskalasi sebelumnya ditolak |
| Izin OS/GPS, persistensi SQLite native, pemasangan/uji HP | Belum dijalankan |

Android Java/manifest berubah, jadi kandidat wajib build Android. Terminal Android Studio root app_m0: `flutter analyze`, `flutter test`, `flutter build apk --debug`, `flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>`. APK produk setelah suite wajib **versionName0.7.0/versionCode7**, bukan artifact lama. Jangan uninstall/clear data. Backup/restore belum dibuat; belum menyatakan tahap cuaca terverifikasi penuh.

## Riwayat serah terima sebelumnya
# FishCare V2 — M5 laporan budidaya

## Perbaikan detail M5

Kegagalan detail kematian batal yang dilaporkan pengguna diperbaiki pada fixture dan UI: field panen nonpanen NULL, detail panen hanya partial/final. Assertion alasan batal tetap; tes detail kematian batal dan panen partial/final valid diperluas. Format lulus; analyze ditolak jalur izin otomatis, seluruh test/build belum berjalan, APK baru belum ada. [Rincian perbaikan dan bukti](docs/M5_PERBAIKAN_DETAIL.md). Tidak lanjut M6.

Sumber **0.6.0+6**, schema produk tetap **4**. Laporan periode inklusif dan satu/semua kolam termasuk arsip; total berasal dari snapshot sah. Pendukung/detail mempertahankan filter; Kondisi saat ini/Seluruh siklus terpisah; Beranda dan laporan memuat ulang setelah commit/batal tanpa restart. Tidak ada FCR/keuntungan bersih, backup/restore atau cuaca produk lengkap.

**M4 belum terverifikasi di HP.** Pengguna menunda pemasangan/uji sampai M4+M5 selesai. Manual M2+M3 sebelumnya berhasil menurut pengguna; tidak dianggap bukti otomatis M4/M5.

| Pemeriksaan M5 | Status |
|---|---|
| Flutter analyze / seluruh flutter test / build APK gabungan | Terhalang; belum dijalankan. Pembatasan SDK belum berubah; percobaan lock tidak diulang |
| SQLite native / pemasangan / uji HP M4+M5 | Belum dijalankan; pemasangan/manual dilakukan pengguna |
| Format Dart | Lulus, bukan analisis tipe |
| Checker Dart murni M5 dan regresi M4 | Lulus sebagai bukti tambahan, bukan Flutter/SQLite/HP |

Rincian FR-07/AT-18/19/37–40, source, tes, bukti dan langkah HP: [M5_IMPLEMENTASI.md](docs/M5_IMPLEMENTASI.md). Sumber kini memiliki11 tes laporan standar dan3 native terdefinisi, bukan jumlah lulus. Suite gabungan tetap memeriksa M0–M4 dan migrasi lama. M5 tidak menambah dependency atau migrasi; data schema4 dibaca langsung.

Dari Terminal Android Studio root `app_m0`, jalankan berurutan `flutter analyze`, `flutter test`, `flutter build apk --debug`, serta `flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>`. Setelah suite native, pengguna memasang APK produk satu kali tanpa uninstall/clear data. Wajib APK **versionName0.6.0/versionCode6**, bukan APK M3 yang tersedia. Perintah lengkap/bukti kegagalan lingkungan ada di dokumen M5. **Berhenti setelah M5.**

## Riwayat serah terima M0–M4
# FishCare V2 — M4

Sumber **0.5.0+5**, skema produk **4**. Sampling, kematian, panen parsial/akhir dan pembatalan lintas kegiatan tersedia pada sumber. Data awal serta riwayat M1–M3 dipertahankan melalui migrasi, tanpa reset/uninstall. Detail, FR/AT, transaksi, bukti dan langkah uji: [M4_IMPLEMENTASI.md](docs/M4_IMPLEMENTASI.md).

**Pengguna mengonfirmasi seluruh percobaan manual gabungan M2+M3 yang diberikan berhasil tanpa kendala.** Dicatat sebagai hasil pengguna, bukan tes otomatis agen. APK v0.4.0+4 yang sekarang tersedia telah diperiksa identitas/hash-nya; bukan APK M4 atau bukti perintah build sesi ini. Pernyataan belum diuji di catatan M2/M3 bawah adalah status historis saat serah terima.

| Pemeriksaan M4 | Status |
|---|---|
| Flutter analyze / seluruh flutter test / build APK debug | Terhalang; belum dijalankan, akses tulis lock SDK ditolak |
| Native SQLite dan pemasangan/uji HP M4 | Belum dijalankan |
| Format Dart | Lulus, bukan analisis tipe |
| Checker Dart murni M4 serta regresi M3/M2 | Lulus sebagai bukti tambahan, bukan Flutter/SQLite/HP |

Bukti [lingkungan](logs/m4-standard-status.log), [artifact/lockfile](logs/m4-existing-evidence.log), [format](logs/m4-format.log), [rumus](logs/m4-rules-extra.log). Dependency/lockfile dan konfigurasi Android tetap. Terminal Android Studio dari root `app_m0`: `flutter analyze`, `flutter test`, `flutter build apk --debug`, lalu suite native dan upgrade produk tanpa uninstall. Pastikan APK **versionName0.5.0/versionCode5**; perintah lengkap di dokumen M4.

Kandidat batal: sah terakhir lintas feeding/sampling/death/partial dalam active/hari sama; rate/jam/Lewati bukan penghalang. Akhir/closed tidak batal. Pemulihan niat ID M3 diteruskan. Laporan penuh, backup/restore dan cuaca produk lengkap belum dibuat; pemulihan sesudah restore tetap keputusan tahap terkait. **Berhenti M4.**

## Riwayat serah terima M0–M3
# FishCare V2 — M3 dan kandidat gabungan M2+M3

Pembaruan M3, 13 Oktober 2026. **Sumber M2+M3 tersedia; analisis/tes standar dan build APK gabungan belum terverifikasi karena akses SDK sesi agen ditolak.** APK yang tersedia masih M1, bukan kandidat gabungan baru. Pengguna memilih uji HP M2 dan M3 digabung setelah tahap ini; **M2 belum terverifikasi di HP**. Berhenti setelah M3.

## Status terkini M3

Aturan pengguna telah dicatat pada PRD dan rancangan: stok bersama melalui ledger; koreksi lama/baru/alasan/selisih; pemberian dengan snapshot dan seluruh perubahan atomik; pembatalan pemberian sah terakhir hari ini meskipun ada rate/jam/Lewati; niat ber-ID persisten sebelum transaksi serta recovery memakai ID yang sama. Ketergantungan sampling/populasi tetap perlu aturan sebelum dibuat. Tidak menambah sampling/kematian/panen/laporan lengkap.

Database produk dimigrasikan **1/2→3**, menjaga master/siklus/rate/jam/slot; tidak reset/uninstall. Versi sumber **0.4.0+4**, application ID tetap `id.ac.fishcare.m0`. Dependency dan lockfile dipertahankan. Layar stok/koreksi ada di detail pakan; Berikan/Lewati dan riwayat/batal ada di detail kolam. Pemulihan tindakan tersedia dari Beranda/ikon toolbar, tanpa retry otomatis.

Rincian implementasi, FR/AT, transaksi/migrasi, hasil pemeriksaan, kontribusi ukuran, dan uji HP gabungan: **[M3_IMPLEMENTASI.md](docs/M3_IMPLEMENTASI.md)**.

| Verifikasi M3 | Status |
|---|---|
| Analisis Flutter, seluruh tes standar, build debug gabungan | Terhalang/belum dijalankan; [akses lock SDK ditolak](logs/m3-standard-status.log) |
| Format Dart | Lulus; bukan analisis tipe |
| Checker Dart murni M3 dan regresi rumus M2 | Lulus sebagai bukti tambahan, bukan tes Flutter/native/HP |
| Pemasangan, migrasi native dan uji gabungan HP | Belum dijalankan |

Terdapat **24 tes standar dan19 native terdefinisi**, bukan jumlah lulus. Satu suite native gabungan tersedia di `integration_test/all_database_test.dart`, memakai database terisolasi. Setelah lingkungan memungkinkan, jalankan `flutter analyze`, `flutter test`, `flutter build apk --debug` dari root app_m0; pastikan APK **v0.4.0+4** sebelum dipasang sebagai satu upgrade gabungan. Tidak memakai APK M1 sebagai bukti build baru. Perintah lengkap ada di dokumen M3.

**Ukuran M1 sekitar151MB adalah laporan pengguna.** Inventaris artifact M1 mencatat152.100.979byte; kontribusi engine/debug/kernel/Vulkan dan selisih fisik ZIP yang belum teratribusi dicatat di dokumen M3. Opsi release/ABI presentasi baru ditindaklanjuti setelah build gabungan dan uji berhasil; tidak menghapus aset/fitur atau mengklaim ukuran APK M3.

## Riwayat M2 sebelum M3

Bagian M2 dan M0/M1 berikut adalah riwayat serah terima. Status/perilaku M3 terbaru berada di atas; pernyataan keputusan review masih terbuka di bagian historis telah diperbarui untuk lingkup M3 pada dokumen keputusan review.

## Status terkini M2

Pengguna melaporkan **pengujian manual M1 di HP berjalan lancar**. Dicatat sebagai hasil pengguna secara umum; rincian skenario, cold restart, analyze/test dan perintah build tidak ditambahkan tanpa bukti. APK M1 yang tersedia disimpan di [artifacts/m1/fishcare-m1-debug.apk](artifacts/m1/fishcare-m1-debug.apk) dengan metadata/hash dalam [log](logs/m1-evidence-current.log); tidak disebut APK M2.

M2 menambah siklus aktif, form input ikan/populasi/bobot/pakan/rate/jam, kebutuhan dari satu fungsi presisi, pembagian gram tepat, rate berlaku sekarang, dan jam berlaku besok. Database produk dimigrasikan **1→2**, mempertahankan master M1. Tidak ada tombol Berikan, pemotongan stok, sampling/panen atau laporan perhitungan. Half-up nonnegatif telah diputuskan pengguna dan dicatat pada PRD/rancangan; RV-01–RV-03 tetap terbuka.

Rincian perubahan, FR/AT, migrasi, hasil pemeriksaan, konfigurasi dan langkah uji HP: **[M2_IMPLEMENTASI.md](docs/M2_IMPLEMENTASI.md)**. Versi sumber baru **0.3.0+3**, root `app_m0`, application ID tetap `id.ac.fishcare.m0`; dependency dan lockfile tidak diubah. Buat/pasang melalui upgrade biasa, jangan uninstall/clear data.

| Pemeriksaan M2 | Status |
|---|---|
| Analisis/seluruh tes/build Flutter standar | Terhalang lingkungan; belum dijalankan untuk M2. [Log akses lock](logs/m2-standard-status.log) |
| Format Dart | Lulus; [log](logs/m2-format.log), bukan analisis tipe |
| Checker Dart murni rumus/parser/half-up/pembagian | Lulus; [log](logs/m2-rules-extra.log), bukan flutter test/native SQLite/HP |
| Pemasangan, migrasi dan persistensi M2 di HP | Belum dijalankan |

Terdapat20 tes standar dan8 integration test terdefinisi seluruh proyek; jumlah lulus standar belum diketahui. Jalankan `flutter analyze`, `flutter test`, `flutter build apk --debug` dari root `app_m0` pada terminal Android Studio yang dapat mengakses SDK/cache; perintah lengkap dan pemeriksaan APK v0.3.0+3 ada pada dokumen M2. Tidak menggunakan SDK salinan/runner pengganti agar terlihat lulus.

## Riwayat verifikasi M0/M1

Bagian berikut mempertahankan catatan saat M1 diserahkan. Pernyataan belum tersedia di bagian historis tidak membatalkan laporan pengguna M1 atau artifact M1 yang kemudian ditemukan; status terkini berada di bagian M2 di atas.

Acuan: [AGENTS](AGENTS.md), [PRD v0.1](docs/PRD_FishCare_Baru_v0.1.md), [wireframe](docs/WIREFRAME.md), [skill fishcare-project](.agents/skills/fishcare-project/SKILL.md). [Diagnosis awal M0](README_M0_DIAGNOSIS_AWAL.md) adalah catatan historis; status terbaru di dokumen ini.

## M0 — bukti pengguna dan bukti berkas

Empat hasil berikut **dilaporkan pengguna**, bukan diulang/diklaim sebagai tes otomatis agen:

| Pengujian pengguna | Status dan batas |
|---|---|
| Aplikasi M0 berjalan di HP | Lulus menurut pengguna; paket terpasang juga terlihat melalui ADB |
| Marker SQLite berhasil disimpan/dibaca | Lulus menurut pengguna untuk simpan/baca |
| API Open-Meteo menampilkan cuaca Jakarta | Lulus menurut pengguna, API nyata; bukan fixture |
| Tanpa jaringan menampilkan error dan tombol Kembali tersedia | Lulus menurut pengguna untuk keadaan tersebut; tidak mengarang waktu respons atau skenario navigasi lain |
| Marker tetap sama sesudah tutup paksa/buka lagi | **Belum terverifikasi**: pengguna belum mengonfirmasi marker persis sama setelah force-stop. Simpan/baca biasa tidak membuktikan cold restart |

Bukti manual tersebut menjadi dasar melanjutkan **M1 terbatas yang secara eksplisit diminta pengguna**. Penutupan catatan verifikasi M0 tetap menyisakan cold restart dan pemeriksaan standar; M0 tidak disebut lulus penuh. Permintaan konfirmasi persistensi telah disampaikan, tanpa menunda pekerjaan M1 yang telah diizinkan.

Agen membaca bukti berikut pada sesi ini, tanpa menebak identitas perangkat:

- `adb shell getprop ro.product.model`: **Infinix X6879**; release **16**, API **36**. Nama pemasaran Note 60 dari PRD tidak dianggap hasil verifikasi getprop.
- `dumpsys package id.ac.fishcare.m0`: versionCode 1, versionName 0.1.0; pemasangan/pembaruan tercatat 13 Oktober 2026 17:06:06 menurut output perangkat. Ini bukan pemasangan M1.
- APK ditemukan di `app_m0/build/app/outputs/flutter-apk/app-debug.apk`: **78.835.359 byte**, waktu file 13 Oktober 2026 17:05:59 menurut filesystem. Salinan dipertahankan di [artifacts/m0/fishcare-m0-debug.apk](artifacts/m0/fishcare-m0-debug.apk) sebelum perubahan M1.
- SHA-256 APK M0: `FD91F6A7341E382712CD9F9976544A54D4A1836F4581C9DB210AA2E3DCF09177`.
- `aapt dump badging` membuktikan paket `id.ac.fishcare.m0`, v0.1.0+1, label FishCare M0 (Uji), compileSdk36, targetSdk36, minSdk24. APK ini tidak dipakai sebagai bukti build sumber M1 terbaru.
- Lockfile [pubspec.lock](app_m0/pubspec.lock) kini tersedia, tidak dibuat ulang secara manual. sqflite **2.4.4**, sqflite_android **2.4.4**, sqflite_common **2.5.13+1**, sqflite_platform_interface **2.4.2** tercatat. Tidak ada dependency baru M1.
- Daemon Gradle 9.3.1 yang mencatat build dari root `app_m0/android` pada 13 Oktober memperlihatkan `javaHome=C:\Program Files\Android\Android Studio\jbr`, `javaVersion=25`, heap2G/metaspace768m. JBR executable teramati 25.0.3. Konfigurasi proyek masih AGP9.1.0, KGP2.4.0 apply false, wrapper9.3.1, NDK default28.2.13676358. Bukti APK mengonfirmasi hasil build pernah tersedia di luar percobaan agen yang tertahan; perintah/log penuh build sukses pengguna belum diberikan.

[Log bukti terkini](logs/m0-evidence-current.log) menyimpan metadata/hash/SDK APK, getprop dan konteks daemon. Tidak mempublikasikan serial HP. Flutter metadata terpasang masih 3.47.5 stable/Dart3.13.4. Platform36 kini ada bersama37.0. Batas kompatibilitas hanya perangkat/konfigurasi yang dibuktikan, bukan semua Android24+.

## M1 — lingkup dan struktur

Root aplikasi tetap **app_m0**, mempertahankan konfigurasi yang pernah menghasilkan APK. Nama direktori/package Dart `fishcare_m0` dipertahankan untuk menghindari perpindahan proyek/lockfile; bukan berarti halaman percobaan menjadi produk. Application ID tetap **id.ac.fishcare.m0**, berbeda dari aplikasi lama `com.example.fishcare`, sehingga build M1 nanti memperbarui instalasi V2/M0 tanpa membuka database lama. Label M1 menjadi **FishCare V2**, versi sumber **0.2.0+2**.

- [main.dart](app_m0/lib/main.dart) menjalankan produk dengan navigasi Beranda, Kolam, Pakan, Laporan. Beranda dan Laporan menjelaskan kegiatan/perhitungan belum tersedia, tanpa angka rekaan atau tombol fitur yang belum dibuat.
- [product_app.dart](app_m0/lib/product_app.dart): daftar Aktif/Arsip, tambah, detail, ubah dan konfirmasi arsip. Daftar membaca ulang setelah kembali dari simpan/detail, saat tab dibuat ulang, saat aplikasi kembali aktif, atau melalui Muat ulang. Loading/daftar kosong/gagal/retry tersedia. Form dapat digulir dengan keyboard; Kembali meminta konfirmasi buang draft, tombol simpan/field dinonaktifkan saat menulis. Duplicate/backend validation muncul dekat field; kegagalan umum mempertahankan draft.
- Kolam: nama wajib, catatan dan ukuran/catatan dimensi opsional. Ukuran berupa teks mengikuti usulan O-08 wireframe, tidak dipakai rumus. Pakan: nama dan harga rupiah/kg positif. Tidak menampilkan saldo stok palsu.
- [master_data.dart](app_m0/lib/master_data.dart): model, normalisasi nama, parser harga, ID acak per draft. Nama unik setelah trim dan lowercase, termasuk arsip; nama kolam dan pakan berada pada namespace tabel berbeda. Harga hanya digit bulat positif, tanpa pemisah ribuan/desimal; menolak `1.500`, `1,5`, NaN/infinity/negatif/kosong dan overflow int64.
- [master_repository.dart](app_m0/lib/master_repository.dart): SQLite/repository, validasi dalam transaksi, UNIQUE name_key, create ID sama/payload sama tidak membuat baris kedua, revisi optimistis mencegah edit/arsip dari data lama. Tidak menghapus riwayat/baris melalui UI. Retry create dengan ID yang sama hanya melindungi draft yang masih tersedia; pemulihan niat lintas proses RV-03 belum diselesaikan.
- [m0_main.dart](app_m0/lib/m0_main.dart) mempertahankan percobaan M0 dengan database uji dan API nyata; hanya entrypoint khusus `flutter run -t lib/m0_main.dart`, bukan navigasi utama produk. Tidak menghapus marker pengguna M0 atau menyisipkannya ke produk.

Tidak membuat siklus, ledger/pergerakan stok, pemberian, sampling, kematian, panen, perhitungan laporan, backup/restore, ataupun cuaca produk penuh. Karena siklus belum ada, arsip master tidak mempunyai ketergantungan siklus saat M1. Sebelum FR-02 dibangun, larangan arsip master yang dipakai siklus aktif harus ditambahkan dalam transaksi yang sama. Tidak menawarkan pemulihan arsip yang belum ditentukan PRD.

## Database aplikasi M1

File **fishcare_app.db**, schema/user_version **1**, terpisah dari **fishcare_m0_probe_v1.db**. Pada instalasi pertama hanya membuat tabel, tanpa data contoh. Berkas M0 tidak dibaca atau dimigrasikan.

Tabel `ponds` dan `feeds` memuat `id TEXT PK`, `name`, `name_key UNIQUE`, `notes`, `size_description`, `price_rp_kg INTEGER`, `is_archived` (0/1), `revision`, `created_at_ms`, `updated_at_ms`. Harga harus null untuk kolam, integer >0 untuk pakan. Catatan/dimensi hanya dipakai form kolam. Timestamp epoch milidetik; belum membuat transaksi bertanggal usaha atau zona budidaya. Nama/angka divalidasi di form dan kembali pada batas transaksi, keunikan dijaga database. Arsip mengubah status/revisi tanpa hard-delete. Saldo stok/populasi tidak dibuat pada M1.

Upgrade versi berikutnya harus menambah migrasi menjaga data. Callback upgrade/downgrade sekarang menolak versi tak didukung, bukan reset/recreate. Foreign key diaktifkan untuk kesiapan relasi berikutnya, tetapi skema M1 hanya master dan belum memakai skema budidaya penuh pada dokumen desain. Auto backup Android tetap dinonaktifkan seperti M0; backup aplikasi belum tersedia.

## Pemetaan kebutuhan dan tes

M1 menangani bagian **FR-01** (master kolam) dan **FR-03** (master pakan), navigasi/state PRD bagian3/9, validasi bagian4. Mendukung bagian AT-01 (master offline), AT-19 (refresh master) dan AT-27 (parser harga), bukan mengklaim skenario lengkap budidaya lulus. Archive guard untuk siklus aktif, riwayat siklus, dan stok belum termasuk tahap ini.

- Tes standar yang disiapkan: 3 tes validasi M1, 4 tes widget M1 (navigasi jujur, retry baca, simpan ganda/refresh, error duplikat mempertahankan draft), serta 5 tes M0 yang dipertahankan: total **12 tes standar terdefinisi**, jumlah lulus belum diketahui.
- Native integration M1: 3 tes dalam [master_repository_test.dart](app_m0/integration_test/master_repository_test.dart) memeriksa unique termasuk arsip/rollback, idempotensi create/validasi harga/revisi stale, serta reopen file. Memakai file **m1_isolated_test_<ID>.db**, bukan database produk/M0. Tes M0 reopen koneksi tetap ada. Reopen koneksi bukan cold restart proses HP.
- [Pemeriksaan Dart murni tambahan](tools/m1_validation_check.dart) berhasil menjalankan normalisasi/parser produksi; bukti [log](logs/m1-validation-extra.log). Ini **bukan flutter test**, UI, SQL, atau bukti APK.

## Hasil verifikasi M1 dan hambatan sesi

| Pemeriksaan | Status | Bukti/batas |
|---|---|---|
| `flutter analyze` standar | **Terhalang lingkungan** | Dipanggil dari root app_m0 lewat cmd; tidak mencapai analyzer dalam15detik, lock SDK masih ditolak. [Log status](logs/m1-analyze-status.log) |
| `flutter test` standar | **Terhalang lingkungan; belum dijalankan** | Tidak mengulang bootstrap sama yang terbukti ditolak; tidak ada jumlah lulus/gagal runtime |
| `flutter build apk --debug` M1 | **Terhalang lingkungan; belum dijalankan** | Tidak ada APK baru v0.2.0+2; artifact M0 tidak dilabeli M1 |
| Pemasangan M1 | **Belum dijalankan** | HP terhubung tetapi belum tersedia APK M1 terbaru |
| Persistensi M1/cold restart HP | **Belum dijalankan** | Sumber memakai SQLite file, tetapi belum diuji dengan APK M1 |
| Dart analyze tambahan | **Terhalang lingkungan** | `dart analyze --fatal-infos` gagal menjalankan analysis_server_aot melalui dartaotruntime.exe: CreateFile failed5 / Access is denied. [Log](logs/m1-dart-analyze.log) |
| Format Dart | **Lulus** | [m1-format.log](logs/m1-format.log); bukan analisis tipe/runtime |
| Validasi Dart tambahan | **Lulus** | [m1-validation-extra.log](logs/m1-validation-extra.log), exit program0, bukan tes Flutter standar |

Penyebab tepat Flutter: membuka `C:\flutter\bin\cache\flutter.bat.lock` dengan ReadWrite menghasilkan UnauthorizedAccessException/Access denied. SDK/cache berada di luar writable root sesi; eskalasi sandbox tidak tersedia. Upaya menghentikan pohon subprocess diagnosis dengan taskkill juga mendapat `ERROR: Access denied`; **penghentian tidak berhasil dibuktikan**, tidak diklaim sukses. Jangan menjalankan ulang perintah identik yang masih menunggu lock. Tidak menyalin SDK, menjalankan Flutter snapshot lewat Dart sebagai bypass, mengubah izin global atau menghapus lock.

M0 dapat berhasil pada terminal pengguna, sementara sandbox agen tetap tidak dapat memakai jalur yang sama. Perbedaan ini dijelaskan oleh bukti akses per sesi, bukan disimpulkan sebagai kegagalan aplikasi M0. Log kegagalan Gradle/API sesi awal tetap historis; bukan klaim bahwa pengujian pengguna gagal.

## Langkah verifikasi standar dan uji M1 di HP

Jalankan pada terminal pengembangan yang mempunyai akses SDK/cache melalui jalur lingkungan berizin. Semua perintah berikut **belum berhasil dijalankan untuk M1**, dan diperlukan sebelum tahap dinyatakan terverifikasi:

```powershell
Set-Location 'C:\Users\basti\OneDrive\Lampiran\Documents\FishCare V2\app_m0'
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
```

Dependency M1 tidak berubah; simpan lockfile yang ada. Jika Flutter meminta pub get, lakukan lewat jalur normal dan tinjau perubahan lockfile, bukan mengedit Pub Cache. APK baru yang diharapkan: `app_m0/build/app/outputs/flutter-apk/app-debug.apk`, v**0.2.0+2**, label **FishCare V2**. Periksa metadata/hash/waktu hasil baru sebelum memasang. Jangan memasang salinan artifacts/m0 sebagai M1.

```powershell
flutter install --debug -d <ID_HP_LOKAL>
flutter test integration_test/master_repository_test.dart -d <ID_HP_LOKAL>
```

Gunakan ID lokal, tanpa mempublikasikan serial. Jangan uninstall/clear data atau reset database agar tes lulus.

| Uji manual M1 | Hasil yang diharapkan |
|---|---|
| Buka dalam mode pesawat | Empat tab tersedia; Beranda/Laporan kosong dengan batas tahap jujur; tidak masuk halaman uji M0 |
| Tambah kolam dengan spasi tepi, catatan/dimensi | Nama trim, detail sesuai, daftar langsung berubah tanpa restart |
| Buat duplikat nama beda kapitalisasi | Ditolak; tidak ada baris tambahan |
| Ubah identitas kolam, kembali ke daftar/pindah tab | Detail/daftar menampilkan data baru |
| Tambah pakan harga1500, lalu harga invalid | Harga sah tersimpan; kosong/0/negatif/1.500/1,5/sangat besar ditolak, draft tetap |
| Ubah nama/harga pakan dan ketuk simpan berulang | Satu master, perubahan sesuai; tidak ada stok/biaya agregat rekaan |
| Batal dialog arsip, lalu konfirmasi arsip kolam/pakan | Batal tidak mengubah; konfirmasi memindahkan ke Arsip dengan detail read-only |
| Nama yang sudah diarsipkan dipakai lagi | Ditolak; arsip tetap tersimpan |
| Keyboard terbuka, 360dp dan teks130%, Kembali | Form bisa digulir, Simpan terjangkau; draft berubah meminta konfirmasi buang |
| Tutup paksa `id.ac.fishcare.m0`, buka launcher V2 | Kolam/pakan aktif/arsip dan harga/catatan tetap sama; catat screenshot sebelum/sesudah. Jangan menghapus data |
| Muat ulang setelah kegagalan lokal yang dapat direproduksi | Error tidak dianggap daftar kosong; retry tersedia; data lama tidak di-reset |

Catat hasil per skenario sebagai lulus/gagal/belum dijalankan dengan sumber pengguna/agen yang jelas. Persistensi M0 dan M1 adalah bukti berbeda. Setelah uji ini, tetap berhenti pada M1, tidak lanjut M2.

## Keputusan tetap terbuka

[KEPUTUSAN_REVIEW.md](docs/KEPUTUSAN_REVIEW.md): **RV-01** koreksi stok masuk salah, **RV-02** pembatalan setelah rate/jam/Lewati, **RV-03** pemulihan ID niat operasi lintas restart. Tidak mengubah PRD atau menyatakan ketiganya selesai melalui fitur master M1. Usulan O-05 (nama/harga pakan) dan O-08 (ukuran teks/arsip) tetap pilihan rancangan yang perlu dibekukan sebelum lingkup penuh; M1 mengikuti wireframe yang diminta pengguna.
