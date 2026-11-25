# FishCare V2 — Percobaan M0 Android

Catatan historis diagnosis awal. Status terkini, bukti pengujian pengguna, APK yang ditemukan, dan M1 ada di [README utama](README.md). Pernyataan terhalang/belum tersedia di bawah menggambarkan sesi awal, bukan membatalkan bukti pengguna berikutnya.

Tanggal verifikasi: 13 Oktober 2026. **M0 belum terverifikasi; terhalang lingkungan.** Sumber percobaan tersedia di [app_m0](app_m0/), belum menghasilkan APK. Tidak ada fitur budidaya, database pengguna, skema lengkap, atau desain final yang diimplementasikan.

Acuan: [AGENTS.md](AGENTS.md), [PRD v0.1](docs/PRD_FishCare_Baru_v0.1.md), [skill fishcare-project](.agents/skills/fishcare-project/SKILL.md). Lingkup ini khusus PRD bagian 10: build/pasang, persistensi SQLite, dan HTTPS nyata. Percobaan mendukung fondasi FR-08 serta aspek offline/error AT-20 dan persistensi AT-25, tetapi **tidak membuktikan seluruh FR/AT tersebut lulus**. AT-01 lengkap juga belum diuji karena fitur budidaya belum dibuat.

## Identitas, pemisahan data, dan isi aplikasi

- Root aplikasi baru: `FishCare V2/app_m0`. Root `FishCare V2` tetap memuat dokumen dan log.
- Application ID/namespace baru: `id.ac.fishcare.m0`; label launcher **FishCare M0 (Uji)**. ID aplikasi lama yang dibaca dari `../FishCare/android/app/build.gradle.kts`: `com.example.fishcare`. Proyek lama tidak diubah atau disalin.
- Android saja: tidak ada root platform iOS/web/Windows. Host activity Java, Flutter UI; tidak menambah dependency Kotlin untuk kode host aplikasi.
- Database privat baru: `fishcare_m0_probe_v1.db`, versi uji 1, satu tabel `m0_probe(id=1, marker TEXT)`. Ini bukan versi/skema database produksi pada Rancangan Database. Android auto backup dimatikan untuk percobaan agar marker uji tidak dipulihkan otomatis sebagai data baru.
- Tidak ada marker otomatis. Pengguna menekan **Simpan marker M0 (sekali)**, lalu marker `DATA UJI M0 — <timestamp UTC>` disimpan atomik. Tombol ulang membaca marker yang sama, tanpa reset/menimpa data. Pembukaan aplikasi hanya membaca. Koneksi SQLite ditutup setelah operasi sehingga baca berikutnya membuka file lagi.
- Tombol **Buka percobaan API cuaca** membuka halaman terpisah. Permintaan baru terjadi setelah tombol **Pilih Jakarta uji dan minta API nyata** ditekan. Lokasi uji: Jakarta, lintang -6.2088, bujur 106.8456, zona API Asia/Jakarta; bukan lokasi kolam/pengguna. Tidak memakai geocoding atau izin GPS.
- Endpoint nyata: Open-Meteo `/v1/forecast`, `current=temperature_2m,weather_code`. Hasil menampilkan suhu udara/satuan, kode kondisi WMO, waktu penyedia dan pengambilan UTC. Null diberi label tidak tersedia; error ditampilkan, timeout total 10 detik, jeda percobaan 60 detik. Kembali tetap tersedia saat request; dispose membatalkan client dan hasil lama tidak memperbarui layar.
- Tidak ada dummy pada jalur aplikasi. Fixture hanya di tes widget/parser. Cuaca M0 belum mencakup peluang hujan, geocoding, cache persisten 30 menit atau seluruh FR-08. Data terakhir di halaman hanya ada di memori dan berlabel demikian saat pembaruan gagal. Tidak ada rumus/efek cuaca pada budidaya.

Karena bootstrap Flutter normal tertahan, berkas Android disusun dari template **SDK Flutter terpasang**, dengan ID baru dan batas memori Gradle untuk laptop 8 GB. Resource launcher/theme dan wrapper berasal dari template/artifact standar SDK, bukan proyek lama. `flutter create` belum berhasil dijalankan; scaffolding ini masih harus dibuktikan lewat jalur build normal, bukan dianggap hasil create/build sukses. Tidak menyalin SDK untuk menghindari lock.

## Inventaris lingkungan: teramati dan kandidat belum teruji

Bukti: [log inventaris](logs/m0-environment.log), [akses lock Flutter](logs/m0-flutter-lock.log), [stacktrace Gradle](logs/m0-gradle-native.log).

| Komponen | Hasil inventaris | Status bukti |
|---|---|---|
| Flutter | `C:\flutter`; metadata cache menunjukkan **3.47.5 stable**, revision `6a19cca56475dbfba1478ee68d7bd0c2ef891da1` | Dibaca dari flutter.version.json; `flutter --version` tertahan, bukan hasil CLI lulus |
| Dart | **3.13.4 stable**, Windows x64 | `C:\flutter\bin\cache\dart-sdk\bin\dart.exe --version` berjalan |
| Java di PATH | Oracle **1.8.0_401** | `java -version` berjalan; tidak cocok untuk kandidat AGP ini |
| Java Android Studio | OpenJDK **25.0.3**, `C:\Program Files\Android\Android Studio\jbr` | Versi executable terverifikasi; dipakai saat diagnosis Gradle melalui JAVA_HOME hanya pada proses shell. JDK build Flutter aktual belum dapat diverifikasi |
| Gradle | Distribusi **9.3.1** tersedia di `.gradle/wrapper/dists`; wrapper proyek menunjuk 9.3.1 | `gradle.bat --version --stacktrace` gagal sebelum menampilkan versi, saat native services |
| AGP / KGP | **9.1.0 / 2.4.0**, mengikuti konstanta template SDK terpasang; KGP deklarasi apply false | Kandidat konfigurasi, belum berhasil di-resolve/build |
| SDK Android | `C:\Users\basti\AppData\Local\Android\Sdk` | Direktori nyata dibaca |
| Platform SDK | Hanya `platforms/android-37.0` (metadata API 37.0, Android 17) | Tidak sama dengan API HP; platform **36 belum ada** |
| compileSdk / targetSdk / minSdk | Default Flutter terpasang **36 / 36 / 24**; app memakai flutter.* | Kandidat belum dibangun; minSdk 24 bukan klaim kompatibilitas teruji |
| Build Tools | **36.0.0** | source.properties dibaca |
| NDK | **28.2.13676358 (r28c)**; metadata dan direktori toolchain ada | Sama dengan kandidat default Flutter; belum dipakai build |
| Platform Tools | **37.0.1** | source.properties dibaca; ADB berjalan |
| Command-line Tools | Folder `cmdline-tools` tidak terlihat pada inventaris SDK | `sdkmanager` dan status lisensi belum terverifikasi |
| HP | `adb devices -l`: daftar kosong, tidak ada unauthorized/device | Model, Android/API level, USB debugging/RSA, pemasangan belum terverifikasi; angka 16.3.0 tidak ditafsirkan sebagai API |
| SQLite plugin | `sqflite: 2.4.4` dipin di pubspec; salinan versi ini ada di Pub Cache | Belum `flutter pub get`; transitif belum dikunci, **pubspec.lock belum tersedia** |

Versi teramati tidak sama dengan kombinasi yang sudah berhasil. Tidak menaikkan semua paket atau menetapkan SDK 37 hanya karena terpasang. `sqflite 2.4.4` dipilih karena tersedia, API minimal cukup, metadata mensyaratkan Dart >=3.12 dan Flutter >=3.44; kandidat SDK memenuhi batas itu. SQLite native tetap harus dibuktikan di Android. HTTP memakai `dart:io` sehingga tidak menambah paket HTTP/path hanya untuk M0.

Dasar pemeriksaan resmi (13 Oktober 2026): [setup Android Flutter](https://docs.flutter.dev/platform-integration/android/setup), [sqflite 2.4.4](https://pub.dev/packages/sqflite/versions/2.4.4), [rilis AGP 9.1](https://developer.android.com/build/releases/agp-9-1-0-release-notes), [kompatibilitas Java/Gradle](https://docs.gradle.org/current/userguide/compatibility.html). Halaman AGP mendokumentasikan seri 9.1 dengan Gradle 9.3.1, Build Tools 36.0.0, NDK 28.2.13676358 dan minimum JDK 17; template lokal memakai 9.1.0, belum bukti patch tertentu berhasil. Tabel Gradle mencakup Java 25 sejak Gradle 9.1, tetapi startup lokal gagal karena akses file sebelum uji build. Dokumentasi bukan pengganti build pada HP.

API: [Forecast API](https://open-meteo.com/en/docs), [ketentuan layanan](https://open-meteo.com/en/terms). Percobaan mata kuliah memakai akses nonkomersial tanpa API key, mematuhi batas layanan; atribusi terlihat pada aplikasi. Akses/ketentuan perlu diperiksa lagi bila tujuan penggunaan berubah.

## Hasil verifikasi terpisah

| Pemeriksaan | Status | Perintah/metode dan bukti |
|---|---|---|
| Analisis Flutter | **Terhalang lingkungan** | `flutter analyze` belum dapat dijalankan: bootstrap Flutter tidak bisa membuka lock SDK. Tidak ada klaim error/warning =0 |
| Tes otomatis standar | **Terhalang lingkungan** | `flutter test` belum dijalankan; 3 tes parser +2 tes widget disiapkan, **jumlah lulus standar belum diketahui** |
| Build APK | **Terhalang lingkungan** | `flutter build apk --debug` belum dijalankan karena bootstrap/cache dan SDK36 belum siap; tidak ada APK artifact |
| Pemasangan HP | **Belum dijalankan** | ADB berjalan, `adb devices -l` kosong; belum ada APK atau HP terverifikasi |
| Persistensi SQLite di HP | **Belum dijalankan** | Repository native dan integration test disiapkan; reopen koneksi maupun cold restart HP belum dijalankan |
| API nyata di HP | **Belum dijalankan** | Halaman/API source siap; tidak ada respons nyata dari aplikasi HP |
| API HTTPS laptop | **Terhalang lingkungan** | PowerShell gagal kredensial TLS Windows; Dart source yang sama gagal koneksi endpoint loopback jaringan lingkungan. Tidak ada respons cuaca nyata berhasil |
| Pemeriksaan tambahan parser Dart | **Lulus, bukti tambahan** | `dart tools/m0_weather_check.dart` memeriksa null dan 3 bentuk invalid sebelum mencoba HTTPS; **bukan flutter test standar**, tidak menguji UI/native SQLite |
| Format sumber Dart | **Lulus** | Dart formatter berjalan pada lib/test/integration_test/tools; parsing sintaks bukan analisis tipe atau tes aplikasi |

### Penyebab persis dan batas diagnosis

1. Flutter: `C:\flutter\bin\internal\shared.bat` membuka `bin\cache\flutter.bat.lock` untuk penulisan sebelum menjalankan tool. Loop bootstrap menekan stderr sehingga perintah tampak diam. Pemeriksaan membuka lock yang ada dengan ReadWrite (tanpa menulis isi) menghasilkan `UnauthorizedAccessException: Access to the path 'C:\flutter\bin\cache\flutter.bat.lock' is denied.` `flutter --version` dihentikan setelah tertahan; `flutter doctor -v` dan `flutter devices` dalam antrean perintah awal tidak tercapai. Tidak ada bukti bahwa proses Flutter lain memegang lock; bukti yang tersedia adalah akses ditolak dalam lingkungan ini.
2. Gradle: dengan JAVA_HOME JBR25, `gradle.bat --version --stacktrace` gagal `Could not initialize native services` → `Failed to load native library 'native-platform.dll'` → `FileNotFoundException/AccessDeniedException` pada `C:\Users\basti\.gradle\native\660c5614fbf4a5f2a75b1949f50a0caf5cd603558e7d8a26e50b933a0cfb79d1\windows-amd64\native-platform.dll.lock (Access is denied)`. Ini bukan error kode aplikasi atau bukti JDK tidak kompatibel.
3. SDK: default Flutter meminta platform36, tetapi inventaris hanya platform37.0. Build belum mencapai pemeriksaan SDK; kekurangan ini adalah prasyarat yang belum terpenuhi, bukan error build yang direka.
4. API PowerShell: `Invoke-WebRequest -TimeoutSec 10` ke endpoint Jakarta gagal `The underlying connection was closed` dengan inner `Win32Exception: No credentials are available in the security package`. [Log lengkap](logs/m0-api-laptop-error.log).
5. API Dart: source `OpenMeteoProbe` nyata dijalankan di laptop; parser tambahan lulus, request gagal `SocketException: The remote computer refused the network connection`, errno **1225**, address **127.0.0.1**. Ini koneksi jaringan/proxy lingkungan, bukan respons HTTP penolakan Open-Meteo; tidak menentukan sebab konfigurasi proxy tanpa bukti tambahan. [Log](logs/m0-dart-weather.log). Exit probe Dart=1; exit helper shell 0 karena Tee-Object tidak boleh disamakan dengan probe lulus.
6. Skrip PowerShell diagnosis sempat ditolak karena execution policy melarang file `.ps1`. Tidak mengubah execution policy; helper yang belum dapat dipakai itu telah dihapus. Diagnosis/log diperoleh lewat perintah shell biasa yang tersedia.

Sandbox sesi mengizinkan tulis workspace, tetapi bukan SDK Flutter/Gradle global; jalur eskalasi sandbox tidak tersedia. Tidak meminta izin berulang atau mengakali batas ini dengan salinan SDK, direct Dart untuk menjalankan Flutter snapshot, menghapus lock/cache, atau menonaktifkan validasi TLS/proxy. Program Dart parser/API tambahan hanya menguji modul Dart murni dan tidak menggantikan jalur Flutter.

## Perintah lanjutan setelah lingkungan tersedia

Berikut adalah panduan **belum dijalankan**, bukan laporan keberhasilan. Jalankan pada terminal pengembangan normal yang dapat mengakses SDK/cache atau sesi dengan izin lingkungan yang sesuai. Jangan mengubah hak akses seluruh drive.

1. Pastikan Flutter SDK/cache dan Gradle native/cache dapat ditulis melalui jalur lingkungan berizin. Install SDK platform **36** dan Android Command-line Tools melalui Android Studio SDK Manager; periksa lisensi. Jangan menghapus platform37 atau NDK yang ada.
2. Sambungkan HP dengan kabel data, aktifkan USB debugging, terima RSA pada HP. Verifikasi model/Android/API; jika tidak terdeteksi periksa kabel, mode USB dan driver OEM. Jangan memakai emulator berat sebagai pengganti bukti HP target.
3. Dari root `app_m0`, periksa toolchain, resolve paket dan simpan lockfile yang benar-benar dihasilkan. `android/local.properties` saat ini berisi lokasi SDK mesin ini dan diabaikan Git; sesuaikan di mesin lain. Wrapper/resource disiapkan, jangan menjalankan scaffold yang menimpa sumber ini.

```powershell
Set-Location 'C:\Users\basti\OneDrive\Lampiran\Documents\FishCare V2\app_m0'
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
flutter --version
flutter doctor -v
flutter devices
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Pastikan doctor/build melaporkan Java yang benar-benar digunakan; JAVA_HOME sendiri belum bukti Flutter memilihnya. Wrapper Gradle 9.3.1/AGP9.1.0/SDK36/NDK28.2 dan sqflite dipertahankan sebagai kandidat sampai build diuji. Jika gagal, mulai dari error pertama dan periksa dokumentasi resmi, bukan menaikkan semua versi. Sesudah build berhasil, catat hash/waktu `app_m0/build/app/outputs/flutter-apk/app-debug.apk`; jangan memakai APK lama sebagai bukti.

4. Pakai ID perangkat lokal dari `flutter devices` tanpa mempublikasikan serial. Dari root aplikasi:

```powershell
flutter install --debug -d <ID_PERANGKAT_LOKAL>
flutter test integration_test/sqlite_probe_test.dart -d <ID_PERANGKAT_LOKAL>
```

Integration test memakai database M0 saja dan membuka ulang koneksi tanpa menghapus marker. Tes ini bukan cold restart proses. Catat hasil tes aktual; instalasi dan pengujian UI tidak terbukti hanya oleh build.

## Prosedur uji HP dan bukti yang wajib dicatat

| Urutan | Tindakan | Ekspektasi/bukti |
|---|---|---|
| 1 | Buka FishCare M0 (Uji), tanpa internet | Marker kosong jika belum pernah disimpan; UI dapat ditekan; tidak ada data budidaya contoh |
| 2 | Simpan marker sekali | Catat marker persis/screenshot dan timestamp; nilai dibaca dari SQLite; tekan ulang tidak menimpa |
| 3 | Tutup paksa **hanya** paket M0 (`adb shell am force-stop id.ac.fishcare.m0`), buka launcher M0 kembali | Marker persis sama dari file; jangan clear data/uninstall. Catat model/Android/API dan hasil |
| 4 | Sambungkan internet, buka API, tekan lokasi uji Jakarta | Hasil nyata suhu/kode/satuan/waktu data/fetched tampil; catat screenshot dan waktu. Tidak menyatakan cuaca real-time/suhu air |
| 5 | Sesudah jeda60 detik aktifkan mode pesawat pada HP, coba API kembali | Error jelas atau data terakhir berlabel memori/gagal; loading berhenti <=10detik. Kembali ke SQLite dan Baca ulang tetap bekerja |
| 6 | Saat request berlangsung tekan Kembali, lanjut kegiatan lokal | Navigasi responsif, hasil request lama tidak mengubah layar SQLite. Kembalikan jaringan HP ke keadaan awal sesudah uji |
| 7 | Periksa perangkat/log | Tidak ada crash atau loading yang tertinggal; semua hasil diberi status lulus/gagal, bukan asumsi |

M0 selesai hanya setelah build/pasang, cold restart SQLite dan API nyata beserta error/offline terbukti di HP. Screenshot/hasil manual, log analyze/test/build, lockfile dan versi toolchain sukses harus ditambahkan ke README. Saat ini semua bukti wajib tersebut masih belum lengkap.

## Keputusan review sebelum fitur dibangun

[KEPUTUSAN_REVIEW.md](docs/KEPUTUSAN_REVIEW.md) mencatat tiga temuan terbuka yang diminta:

- **RV-01:** koreksi stok masuk salah, sementara PRD melarang pembatalannya.
- **RV-02:** pembatalan setelah rate/jam/Lewati; O-01 pada rancangan terdahulu masih usulan, bukan keputusan.
- **RV-03:** pemulihan ID niat operasi setelah restart saat hasil simpan belum diketahui; tabel hasil commit saja belum menyelesaikannya.

PRD tidak diubah dan mekanisme tersebut belum diimplementasikan. Marker primary key tetap M0 bukan solusi idempotensi umum. Setelah M0, tetap berhenti pada tahap ini sampai tugas berikutnya diminta; review aturan harus diselesaikan sebelum fitur terkait dibangun.

## Berkas utama

[main.dart](app_m0/lib/main.dart): dua layar uji, state loading/error dan navigasi. [probe_store.dart](app_m0/lib/probe_store.dart): SQLite native minimal. [weather_probe.dart](app_m0/lib/weather_probe.dart): API nyata, parser, timeout/cancel. [tes](app_m0/test/): parser dan navigasi saat jaringan tertunda/gagal. [integration test](app_m0/integration_test/sqlite_probe_test.dart): native reopen koneksi. [pubspec](app_m0/pubspec.yaml): dependency minimal. [log](logs/): bukti inventaris/hambatan. [pemeriksa Dart tambahan](tools/m0_weather_check.dart): modul parser/API laptop, bukan Flutter runner.
