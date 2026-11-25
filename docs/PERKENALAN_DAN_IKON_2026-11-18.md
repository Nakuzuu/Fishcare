# Maskot, ikon dan perkenalan FishCare

18 November 2026. Versi 0.12.0+17, application ID `id.ac.fishcare.m0`, skema budidaya tetap 7.

## Perilaku

- Maskot ikan umum hijau–mint mengikuti pratinjau yang disetujui pengguna. Ikon launcher Android memakai foreground maskot dan latar hijau, dengan adaptive icon untuk Android 8+ serta fallback lama.
- Splash native memakai maskot dan latar aplikasi; tema Android 12+ disediakan tersendiri. Setelah Flutter siap, splash FishCare menampilkan tagline dan status membuka. Waktu tampilan minimum 700ms, baca preferensi dibatasi 5 detik.
- Tiga halaman perkenalan: kolam, pakan dan laporan. Lanjut/geser berpindah; Kembali pada halaman berikutnya kembali satu halaman; Lewati/Mulai menuju Beranda.
- Penanda selesai disimpan di `fishcare_introduction/completed_v1` menggunakan SharedPreferences privat Android, tanpa menyentuh database budidaya. Pengguna lama tanpa penanda melihat perkenalan sekali setelah update. Pembukaan berikutnya melewati perkenalan.
- Gagal baca tidak menahan splash tanpa akhir. Gagal simpan menyediakan Coba lagi dan Lanjut tanpa menyimpan; kemungkinan perkenalan muncul lagi dijelaskan. Ketukan berulang ketika simpan berlangsung tidak membuat permintaan ganda.
- Beranda dibangun setelah perkenalan selesai/dilewati. Tidak meminta izin baru, login, atau koneksi jaringan. Alur cuaca dan semua rumus/transaksi tetap.
- Konten bergulir pada layar pendek/teks besar; footer tetap dapat dicapai. Aset dibundel lokal, tidak diunduh saat membuka aplikasi.

## Berkas dan acuan

- `app_m0/lib/introduction_ui.dart`, `intro_store.dart`; wiring di `main.dart` dan `product_app.dart`.
- `IntroductionPreferences.java`: baca/simpan preferensi pada thread pekerja, hasil commit diperiksa. Registrasi channel satu baris di MainActivity; channel lokasi/ekspor tidak berubah.
- Resource Android: launcher legacy/adaptive, splash, tema siang/malam dan v31. Manifest memakai ikon baru. Dependency/lockfile tetap; pubspec menambahkan aset dan versi.
- `app_m0/assets/branding/{mascot,ponds,feed,reports}.png`; semua memiliki alpha transparan. Salinan maskot native berada pada `res/drawable-nodpi/fishcare_mascot.png`.
- Kebutuhan/AT-69–74 di [PRD bagian15.16](PRD_FishCare_Baru_v0.1.md). Identitas ikan umum tidak memperluas kebijakan budidaya lele.

Gambar dibuat dengan alat image generation bawaan berdasarkan papan pratinjau yang disetujui. Prompt aset: maskot ikan generik tanpa sungut, wajah mint/hijau, sirip kecil, ekor bercabang, senyum dan tiga aksen kuning, transparan; tiga ilustrasi mempertahankan karakter itu bersama (1) dua kolam, (2) jam08:00 dan pakan, (3) laporan dan simbol spreadsheet. Gambar dibuat sebagai ilustrasi terpisah; teks/tombol menggunakan widget Flutter, bukan gambar layar statis. Tidak menggunakan CLI/API key untuk pembuatan gambar.

Referensi native: [Splash Android](https://developer.android.com/develop/ui/views/launch/splash-screen), [SharedPreferences](https://developer.android.com/training/data-storage/shared-preferences), [commit dan apply](https://developer.android.com/reference/android/content/SharedPreferences.Editor).

## Hasil verifikasi

| Pemeriksaan | Hasil |
|---|---|
| Analisis | Lulus tanpa issue; `logs/onboarding-analyze.log` |
| Suite Flutter | 144 tes lulus; `logs/onboarding-tests-all.log` |
| Tes khusus perkenalan | 10 lulus termasuk gagal simpan, ketukan ganda, Kembali, buka ulang dengan store yang sama, dan render; `logs/onboarding-tests.log` |
| Render | 12 gambar splash/3 halaman pada390dp100%,360dp130%,640×360dp200%; `output/onboarding-2026-11-18/`. Pada landscape pendek, teks dapat digulir dan footer tetap terlihat. |
| Native Android | Satu tes lulus di FishCare Uji terpisah pada Infinix X6879, Android16/API36; menyimpan melalui channel native, membaca dari store baru dan membuka Beranda tanpa perkenalan. File preferensi disk diverifikasi berisi true. `logs/onboarding-native.log` |
| Build produk | Build produk final0.12.0+17 lulus setelah koreksi posisi tengah splash. `logs/onboarding-build.log` |
| Pemasangan/manual produk | Lulus `adb install -r` pada Infinix X6879 Android16/API36. Ikon, halaman1–3, Lanjut dan Kembali diperiksa langsung; perkenalan produk dibiarkan belum selesai untuk pengguna. Tidak uninstall/reset data. |

Tes native dijalankan dengan `FISHCARE_NATIVE_TEST=1`, `flutter test integration_test/introduction_test.dart -d <HP> --no-uninstall --reporter expanded`. Tidak membuka database budidaya; penanda yang ditulis hanya milik `id.ac.fishcare.m0.tests`. Ini tidak menggantikan pengujian seluruh fitur budidaya manual atau semua versi Android. APK yang dibagikan berasal dari build produk terakhir sesudah tes native, bukan APK FishCare Uji.


Bukti perangkat: `output/onboarding-2026-11-18/hp-intro-1.png`, `hp-intro-2.png`, `hp-intro-3.png`, `hp-app-icon.png`. Sidik SHA256 berkas database utama sebelum pemasangan dan setelah navigasi perkenalan sama (`logs/onboarding-db-before.txt`, `logs/onboarding-db-after.txt`); penanda perkenalan produk belum diisi. Bukan pengujian ulang seluruh transaksi budidaya atau cold restart produk setelah menekan Mulai.

APK: `artifacts/onboarding-2026-11-18/FishCare-0.12.0-maskot.apk`, SHA256 `211857C7AFA1DA46C2D27359A3522E835F7D4F6B1DA5DBDE22F0632E44E81989`. Versi dan package diverifikasi dari biner serta paket yang terpasang. Masih build debug untuk pengujian/demo.
