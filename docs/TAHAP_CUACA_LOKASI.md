# Tahap cuaca — lokasi HP hanya atas tindakan pengguna

14 Oktober 2026. Sumber **0.7.0+7**, schema produk **5**, ID Android tetap `id.ac.fishcare.m0`. FR-08/AT-20–22/41–45. Permintaan terbaru mengizinkan irisan tahap cuaca ini; tidak memulai backup/restore atau memperluas budidaya. M4/M5 tetap belum dinyatakan terverifikasi HP. Hasil manual M2+M3 sebelumnya tetap hasil pengguna.

## Perubahan dan keputusan

Ambil lokasi saat ini adalah satu-satunya pemanggil acquire HP. Startup/resume/refresh membaca lokasi SQLite dan menggunakan koordinat tersimpan untuk API. Hasil HP/perkiraan maupun pencarian manual menjadi calon; perlu Simpan sebagai lokasi usaha dan dialog konfirmasi. Batal, kegagalan izin/GPS/fix atau kembali mempertahankan lokasi lama. Satu row pengaturan untuk seluruh kolam; tidak melacak perpindahan dan tidak ada permission/service background.

[MainActivity.java](../app_m0/android/app/src/main/java/id/ac/fishcare/m0/MainActivity.java) memakai MethodChannel: runtime coarse+fine foreground atas getCurrentLocation saja; izin perkiraan diterima tanpa otomatis meminta peningkatan presisi. GPS nonaktif menghasilkan service_off; izin perkiraan memakai network provider bila tersedia. Android30+ getCurrentLocation+cancellation,24–29 requestSingleUpdate;30detik setelah izin, hapus listener/timer saat fix/cancel/onStop/destroy. Tidak meminta koordinat pada configureFlutterEngine. [Manifest](../app_m0/android/app/src/main/AndroidManifest.xml) hanya menambah coarse/fine, tanpa background.

Dasar resmi: izin diminta dalam konteks interaksi fitur dan approximate boleh diberikan menurut [Android runtime location permissions](https://developer.android.com/develop/sensors-and-location/location/permissions/runtime); API sekali jalan dan cancellation menurut [LocationManager](https://developer.android.com/reference/android/location/LocationManager). Tidak menambah plugin/dependency/Gradle/SDK global; implementasi Java mengikuti proyek Android yang sudah ada.

[business_location.dart](../app_m0/lib/business_location.dart), [device_location.dart](../app_m0/lib/device_location.dart), [weather_controller.dart](../app_m0/lib/weather_controller.dart), [weather_ui.dart](../app_m0/lib/weather_ui.dart) memisahkan domain/adapter/state/UI. Generation ID mengabaikan hasil lokasi terlambat dan cuaca lama. Native cancellation dan batas timeout melengkapi guard state, bukan sekadar disable tombol.

[weather_store.dart](../app_m0/lib/weather_store.dart), [weather_schema.dart](../app_m0/lib/weather_schema.dart) menambah satu weather_location global dan cache perkoordinat. Confirm atomik; error simpan membaca hasil terkini sebelum retry. Raw cache hanya data yang sudah diparsing; dibaca dengan validasi lagi. SaveCache memeriksa koordinat aktif di transaksi. Migrasi1/2/3→4→5 serta4→5 menjaga master/siklus/rate/jam/ledger/snapshot/ID lama, tanpa reset. Marker M0 tidak dipakai. Data lokasi calon tidak ditulis sebelum konfirmasi.

[weather_api.dart](../app_m0/lib/weather_api.dart): klien Open-Meteo nyata, pencarian manual kota/wilayah, timeout total10detik/batas256KiB, current suhu/kode dan daily peluang hujan. Cache30menit dan throttle60detik per lokasi; unit/null ditampilkan jujur, error offline navigasi/lokal tetap tersedia. Attribusi/link ada pada kartu. Dasar [Forecast API](https://open-meteo.com/en/docs) dan [Geocoding API](https://open-meteo.com/en/docs/geocoding-api). API tidak mengambil lokasi HP, tidak mengubah feeding rate/porsi, dan suhu bukan sensor air. Kota Jakarta hanya uji CLI eksplisit, bukan lokasi bawaan produk.

## Tes dan hasil sebenarnya

- `test/business_weather_test.dart`:8 skenario terdefinisi (termasuk2 kasus widget izin/GPS): startup/refresh tanpa acquire, calon/cancel/fail-save, callback HP terlambat, respons cuaca lama, mock channel permission denied, UI ambil/batal/konfirmasi/buka ulang, denial/GPS dengan manual. Belum dinyatakan8 lulus.
- `integration_test/weather_location_test.dart`:2 skenario terdefinisi: upgrade4→5 menjaga master dan persistensi lokasi/coarse/akurasi setelah reopen; fault trigger pada database terisolasi membuktikan rollback pengganti dan cache stale diabaikan. Fixture `weather_upgrade_*`/`weather_rollback_*`, bukan database pengguna. Tes sebelumnya tetap dalam suite gabungan; assertion versi mengikuti schemaVersion, isi lama tetap diuji.

| Pemeriksaan | Hasil |
|---|---|
| Format Dart | Lulus, [log](../logs/weather-format.log); bukan analisis tipe |
| Checker Dart murni state/kontrak | Lulus exit0, [log](../logs/weather-location-extra.log); mocked storage/device/API, bukan Flutter/SQLite native/izin Android/HP |
| API nyata CLI Jakarta−6.2088,106.8456 | Gagal koneksi lingkungan, exit255: SocketException errno1225, koneksi127.0.0.1:52605 ditolak. [Log](../logs/weather-api-real.log). Tidak menyatakan provider/HP gagal atau uji nyata berhasil |
| `flutter analyze`, seluruh `flutter test` | Terhalang lingkungan, belum dijalankan |
| Android build APK debug | Terhalang, belum dijalankan; perubahan manifest/native belum terverifikasi |
| GPS, izin OS, cancel fix dan persistensi SQL di HP | Belum dijalankan; tidak mengarang koordinat/identitas HP atau hasil |

SDK/cache global di luar writable root; izin resmi sebelumnya ditolak sandbox_approval=false: [bukti](../logs/m5-detail-fix-verification.log). Kondisi izin sesi tidak berubah; tidak mengulang bootstrap/lock loop atau mengganti SDK. Status [weather-standard-status.log](../logs/weather-standard-status.log). API CLI SocketException adalah bukti rute sesi, bukan bukti sukses kode/HP; tidak menghapus konfigurasi proxy atau melewati pembatasan jaringan.

## Verifikasi terminal dan HP

Perintah berikut **belum dijalankan/lulus oleh agen**; dari Terminal Android Studio yang memiliki akses SDK:

```powershell
Set-Location 'C:\Users\basti\OneDrive\Lampiran\Documents\FishCare V2\app_m0'
flutter analyze
flutter test
flutter build apk --debug
flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>
```

Setelah suite native, pasang APK produk versionName0.7.0/versionCode7, hash/waktu build baru, tanpa uninstall/clear data. APK lama bukan bukti tahap cuaca. Pemeriksaan native/manifest membutuhkan build Android, bukan hanya tes Dart.

1. Instal/upgrade, buka Beranda dan refresh sebelum/sesudah lokasi tersimpan: **tidak ada dialog izin/fix HP**. Kosong tetap Lokasi belum dipilih, tanpa kota contoh.
2. Tekan Ambil lokasi saat ini; izinkan foreground/perkiraan. Tepat satu hasil calon; belum tersimpan. Batal dialog/calonnya/kembali/background saat fix: lokasi lama tetap, callback terlambat tidak muncul/tersimpan.
3. Matikan GPS, tolak izin, tolak berulang, biarkan timeout: penjelasan, Coba lagi/manual tersedia; tidak mengganti lokasi lama. Jika izin permanent denial, manual tetap bisa digunakan; izin dapat diubah sendiri di Pengaturan Android, tanpa permintaan background.
4. Pilih HP atau kota manual, konfirmasi Simpan sebagai lokasi usaha: nama/koordinat tersimpan untuk seluruh kolam. Force-stop/reopen tetap sama; pindah posisi HP lalu refresh tidak mengambil ulang dan tetap acuan koordinat tersimpan. Koordinat aktual hanya dicatat pengguna bila diperlukan, bukan direka agen.
5. Ganti calon ketika cuaca lama masih berjalan; setelah konfirmasi hanya data/cache baru dengan label lokasi baru. Offline dengan cache, tanpa cache, field null, serta request gagal tidak membekukan navigasi/lokal. Cache/error/waktu dan atribusi jujur. Cek persistensi native melalui fixture/reopen dan manual HP terpisah; rollback trigger hanya fixture.

PRD/Alur/Database/Wireframe/AT telah diselaraskan. Backup/restore belum dibangun. Tahap ini **belum terverifikasi penuh** sampai Flutter/native/HP dan API nyata produk mempunyai bukti.
