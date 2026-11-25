# M2 terbatas — siklus dan kebutuhan pakan

13 Oktober 2026. **Sumber implementasi tersedia; pemeriksaan standar/build/pemasangan M2 belum terverifikasi karena akses lingkungan agen.** Tidak lanjut ke tahap berikutnya.

Acuan: [PRD](PRD_FishCare_Baru_v0.1.md), [Alur](ALUR_SISTEM.md), [Database](RANCANGAN_DATABASE.md), [Wireframe](WIREFRAME.md), [README](../README.md). Pengguna melaporkan pengujian manual **M1 di HP berjalan lancar**. Ini dicatat sebagai hasil pengguna secara umum; tidak menyimpulkan daftar skenario M1 tertentu, cold restart, analyze/test atau perintah build lulus dari pernyataan tersebut.

## 1. Lingkup dan pemetaan

| Perubahan | FR/AT terkait | Batas |
|---|---|---|
| Mulai satu siklus aktif per kolam, input lengkap | FR-02; AT-01–03, AT-27 | Kolam/pakan harus aktif, harga pakan positif; tidak memerlukan stok karena ledger belum dibuat |
| Perhitungan kebutuhan dan pembagian porsi | FR-04; AT-02–03, AT-28 | Hanya rencana; tidak ada tombol Berikan, catatan aktual, atau pemotongan stok |
| Rate sekarang, template jam besok, slot unik | FR-02/04; AT-10, AT-26 | Rate tetap tersimpan dan dipakai satu fungsi; belum ada pemberian/sampling/pengurangan |
| Migrasi/persistensi/refresh | PRD bagian4/8/9; aspek AT-19/25 | Cold restart M2 belum dibuktikan di HP; reopen file integration bukan pengganti |
| Arsip tidak merusak siklus aktif | FR-01/03 | Ditolak atomik jika kolam/pakan masih dipakai aktif |

Tidak membuat pemberian, stok, sampling, kematian, panen, laporan perhitungan, backup/restore, atau fitur cuaca produk baru. Kolam bersiklus tetap dapat diubah identitasnya; data awal siklus dan pakan tidak memiliki jalur edit. Siklus aktif tidak dapat ditutup pada M2 karena panen/penutupan belum termasuk lingkup.

## 2. Berkas dan alur UI

- [cycle_rules.dart](../app_m0/lib/cycle_rules.dart): parser jumlah/bobot/rate, satu fungsi `dailyNeed`, half-up, pembagian gram dan tanggal usaha.
- [cycle_schema.dart](../app_m0/lib/cycle_schema.dart): SQL tambahan versi2.
- [cycle_repository.dart](../app_m0/lib/cycle_repository.dart): start/rate/template/slot, audit dan transaksi.
- [cycle_ui.dart](../app_m0/lib/cycle_ui.dart): panel detail, form mulai, ringkasan konfirmasi, rate dan jam besok.
- [master_repository.dart](../app_m0/lib/master_repository.dart): migrasi dan pengaman arsip; [product_app.dart](../app_m0/lib/product_app.dart)/[main.dart](../app_m0/lib/main.dart): integrasi pada detail kolam.

Kolam → detail aktif → Mulai siklus. Form mengisi label ikan, ekor bulat, bobot g/ikan dua desimal, pakan dari master, rate manual dua desimal dan 1–6 jam melalui time picker. Tidak mengisi angka acuan/rate atau jam secara otomatis. Nama pakan dalam detail mengikuti master melalui ID; bobot/jumlah awal/pakan siklus terkunci. Ringkasan sebelum start menampilkan jumlah/bobot/rate, kebutuhan, jam dan tanggal/zona.

Panel detail memisahkan jam hari ini, porsi menunggu, dan jam berlaku besok. Ubah rate menyimpan riwayat dan menghitung ulang porsi sekarang. Ubah jam hanya menulis template besok. Error perhitungan ditulis “Belum dapat dimuat/bukan kebutuhan nol”; kebutuhan sah yang membulat0 tetap menampilkan0 tanpa transaksi pemberian. Tidak ada tombol Berikan/Lewati yang berpura-pura berfungsi.

Form dapat digulir ketika keyboard terbuka; dropdown dan time picker memakai label. Loading baca, error/retry, pakan kosong dan penyimpanan busy tersedia. Setelah simpan kembali ke detail yang memuat ulang. Tanggal dicek lagi di transaksi; form dari hari lama ditolak dan pengguna diminta buka ulang. Saat halaman aktif, timer lokal di batas tengah malam memuat hari baru; resume dari background juga membaca ulang, tanpa proses background/polling jaringan.

## 3. Presisi dan keputusan pembulatan

**Keputusan pengguna yang disepakati saat M2:** nilai nonnegatif menggunakan half-up, tepat setengah dibulatkan naik. PRD bagian4 dan AT-02 serta ketiga rancangan sudah diselaraskan. Keputusan ini hanya menyelesaikan pembulatan O-02, bukan seluruh bagian14/RV lainnya.

Bobot `weight_cg` adalah gram×100; rate `rate_bp` adalah persen×100. Parser menerima koma/titik dan maksimal dua digit desimal, tidak menerima pemisah ribuan, kosong/negatif/nonfinite atau overflow. Jumlah ikan int64 positif. Perkalian memakai BigInt, bukan double; hasil simpan diperiksa rentang signed64. Biomassa tidak dibulatkan antara.

```text
kebutuhan_g = half_up(populasi × weight_cg × rate_bp / 1_000_000)
porsi dasar = kebutuhan_g div jumlah_slot
kelebihan gram = kebutuhan_g mod jumlah_slot
```

Kelebihan satu gram dibagikan dari jam paling awal. 100×100g×3%=300g →150+150; rate3,01% pada kondisi sama menghasilkan301g →151+150. 1×50g×1%=0,5g →1g half-up; 49,99g pada kondisi sama →0g sah. Seluruh layar/repository memanggil fungsi perhitungan yang sama; tidak ada rate sementara hanya di kalkulator.

## 4. Migrasi dan transaksi

`fishcare_app.db` versi1→2: tabel `ponds`/`feeds` dan barisnya tetap. Upgrade menambah `business_settings`, `cycles`, `cycle_rates`, `cycle_schedules`, `cycle_times`, `cycle_slots`, `schedule_changes`, serta indeks aktif unik. Tidak DROP/reset/deleteDatabase atau mengganti database M0. `onCreate` versi2 membuat master lalu tambahan; sqflite menjalankan callback migrasi dalam transaksi. Versi upgrade lain/downgrade ditolak tanpa reset.

| Operasi | Data atomik dan pengaman |
|---|---|
| Start | Validasi input/hasil, baca kolam/pakan terbaru, pastikan belum aktif, lalu simpan cycle+rate+template+jam+slot awal+zona. Gagal di mana pun rollback seluruhnya |
| Rate | Cek aktif/tanggal/input, simpan rate_history dan porsi pending hari ini bersama; seq commit menentukan rate terbaru, bukan jam HP |
| Jam | Materialisasikan hari ini dari template efektif hari ini lebih dulu, lalu insert/update versi besok dan jamnya; audit sebelum/sesudah bersama. Update ulang mengganti versi besok yang sama |
| Baca detail | Dalam transaksi, materialisasi hari baru bila belum ada, lalu baca rate/slot/template besok konsisten. PK siklus/tanggal/menit mencegah duplikat |
| Arsip | Cek referensi siklus aktif dan perubahan arsip dalam transaksi sama; kolam/pakan terpakai ditolak |

Indeks parsial satu aktif per kolam menjadi pengaman tambahan. Jam awal selalu menghasilkan slot pada start, walaupun halaman jadwal belum pernah dibuka. Untuk hari berikutnya yang belum dibuka, perubahan jam mematerialisasikan hari itu dengan template lama sebelum menulis besok. Hari yang aplikasi tidak dibuka tidak dibuat sebagai sudah diberikan. Slot M2 hanya pending; status/entitas pemberian akan memerlukan migrasi dan keputusan fitur berikutnya.

ID draft start tetap saat retry; ID sama/input sama mengembalikan hasil tersimpan, input berbeda ditolak. Perubahan rate/jam mempunyai ID operasi unik dan audit. Ini pelindung untuk request yang mempertahankan ID; **pemulihan niat lintas restart RV-03 belum diselesaikan**. Jika hasil simpan belum diketahui, UI meminta kembali dan muat ulang kondisi, tidak menjanjikan retry otomatis dengan ID baru aman.

Zona usaha dipilih/dikonfirmasi pada start pertama dan terkunci setelah commit, termasuk seluruh siklus berikutnya. M2 menyediakan Asia/Jakarta, Asia/Makassar, Asia/Jayapura dan UTC (zona tanpa DST). Default usulan berdasarkan offset perangkat ditampilkan untuk dikonfirmasi; jika offset tidak didukung, pengguna wajib memilih. Identitas zona disimpan, bukan mengandalkan zona HP yang dapat berubah setelah tebar. Dukungan zona lain/DST belum tersedia; pemilihan melalui form start merupakan irisan pengaturan waktu, bukan halaman pengaturan lengkap. Definisi penguncian setelah stok masuk tetap perlu ditinjau O-06 ketika stok dibuat.

## 5. Hasil pemeriksaan

| Metode | Status dan bukti |
|---|---|
| `flutter analyze` | Terhalang lingkungan/belum dijalankan pada M2: pembukaan lock SDK ReadWrite ditolak. Tidak mengulang loop Flutter sesi M1 yang sama |
| Seluruh `flutter test` | Terhalang lingkungan/belum dijalankan; 20 tes standar terdefinisi, bukan20 lulus |
| `flutter build apk --debug` | Terhalang lingkungan/belum dijalankan; APK tersedia versiM1, bukanM2 |
| Format Dart | Lulus, [m2-format.log](../logs/m2-format.log); bukan analisis tipe |
| Checker Dart murni | Lulus, [m2-rules-extra.log](../logs/m2-rules-extra.log), exit0; 1866 pembagian total dan contoh/parser/half-up. Bukan flutter test/native SQLite/HP |
| Pemasangan, migrasi native dan cold restart M2 di HP | Belum dijalankan; tidak mengubah data HP agar tes lulus |

Penyebab persis yang diperiksa ulang: `UnauthorizedAccessException: Access to the path 'C:\flutter\bin\cache\flutter.bat.lock' is denied`. [Log M2](../logs/m2-standard-status.log). SDK global berada di luar writable root sesi, jalur eskalasi sandbox tidak tersedia. Aplikasi M1 yang berjalan pada terminal pengguna tidak berarti sandbox agen bisa membuka SDK/cache. Tidak memakai direct Dart untuk menjalankan Flutter snapshot, salinan SDK, reset cache, atau mengubah izin global.

[Tes aturan](../app_m0/test/cycle_rules_test.dart) mencakup contoh/half-up/parser/overflow/pembagian/keunikan jam/zona. [Tes UI](../app_m0/test/cycle_ui_test.dart) memeriksa jam kini/besok, tidak ada Berikan, dan input NaN tidak memanggil start. [Tes native](../app_m0/integration_test/cycle_repository_test.dart) memakai file terisolasi: retry start/siklus ganda/guard arsip; kegagalan insert-rate melalui trigger untuk rollback; template besok dan hari belum dibuka/riwayat rate/slot unik/reopen; migrasi master v1. Tes M0/M1 dipertahankan. Terdapat8 tes integration terdefinisi secara keseluruhan, belum hasil runtime.

## 6. APK yang tersedia dan langkah terminal Android Studio

APK versi M1 ditemukan berlabel FishCare V2, versionName0.2.0/versionCode2, compile/target36/min24. Salinan: [artifacts/m1/fishcare-m1-debug.apk](../artifacts/m1/fishcare-m1-debug.apk), ukuran152.100.979byte, waktu file asal13 Oktober2026 17:39:03. SHA-256 `44D11922AA5D3A5DF101FFCDCD876E66BB3FAA9EBF74FC82DD685780F4EFE59D`. Ini bukti artifact, bukan log perintah build M1 atau APK M2. Lockfile dipertahankan tanpa dependency baru, SHA-256 `5F58FFBDCCAB977D516CEA1A50AAA3BAF679AE979D94CC2DEB671F0E1EA71434`.

Jalankan pada **terminal Android Studio** yang mempunyai akses SDK/cache:

```powershell
Set-Location 'C:\Users\basti\OneDrive\Lampiran\Documents\FishCare V2\app_m0'
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
```

Jangan menyimpulkan sukses dari log awal/perintah masih berjalan. Simpan log output/exit setiap perintah. Jika Pub meminta resolve, gunakan `flutter pub get` normal lalu tinjau lockfile. Konfigurasi tetap Flutter3.47.5/Dart3.13.4, AGP9.1.0/wrapper9.3.1, SDK36/NDK28.2.13676358 dan sqflite2.4.4; tidak menaikkan paket. Java build M0 teramati JBR25 pada daemon; verifikasi lagi lewat doctor/build ketika menjalankan M2.

APK M2 yang diharapkan: `app_m0/build/app/outputs/flutter-apk/app-debug.apk`, versi **0.3.0+3**. Periksa version/hash/waktu sebelum memasang. Application ID tetap `id.ac.fishcare.m0`, sehingga upgrade biasa mempertahankan file M1/M0. **Jangan uninstall/clear data** untuk uji migrasi.

```powershell
flutter install --debug -d <ID_HP_LOKAL>
flutter test integration_test/cycle_repository_test.dart -d <ID_HP_LOKAL>
```

Integration test memakai database `m2_isolated_<ID>.db`/`m2_migration_<ID>.db`; tidak menghapus data produk. Model/API HP terakhir yang benar-benar dibaca pada sesi M1 adalah Infinix X6879, Android16/API36; jangan mengarang identitas baru atau menganggap M2 sudah terpasang.

## 7. Langkah uji M2 di HP

1. Catat/screenshot master M1 aktif/arsip dan harga/catatan. Pasang APK M2 sebagai upgrade. Pastikan semuanya tetap; schema berubah menjadi2, bukan database kosong.
2. Dalam mode pesawat buat siklus dari kolam aktif tanpa siklus, pilih pakan aktif, input100 ikan, bobot100g, rate3%, jam08:00 dan16:00. Ringkasan300g; detail150+150; data awal/pakan tidak dapat diedit.
3. Ubah rate3,01%; kebutuhan301g, porsi151+150. Rate3% kembali300g. Tolak kosong/0/negatif/>100/NaN/infinity, tiga desimal, inputambigu1.500 dan angka sangat besar. Tidak menulis rate invalid sebagai0.
4. Tolak jam duplikat, daftar kosong/>6 jam, siklus aktif kedua, serta arsip kolam/pakan yang sedang dipakai. Ketuk simpan berulang tidak menggandakan cycle/rate/template untuk ID yang sama.
5. Ubah jam09:00/17:00 lalu10:00/18:00 pada hari yang sama; hari ini tetap08:00/16:00, besok memakai versi terakhir. Ulang buka detail/tab, tidak ada slot tambahan. Tes native terisolasi juga mencakup perubahan jam ketika hari aktif belum dimaterialisasi.
6. Pada pergantian hari nyata/resume background, tanggal/jam baru sesuai zona usaha; tidak ada pemberian hari lampau. Jangan memundurkan tanggal data pengguna untuk membuat tes lulus.
7. Tutup paksa paketV2, buka kembali, cocokkan master/siklus/rate/template/slot dengan screenshot sebelum. Catat hasil per skenario; laporan M1 lancar tidak otomatis membuktikan cold restart M2.
8. Uji keyboard, tombol Kembali, lebar360dp/teks130%, dan loading/error/retry. Tidak ada tombol Berikan; tidak ada stok/panen/laporan perhitungan yang seolah tersedia.

[RV-01–RV-03](KEPUTUSAN_REVIEW.md) tetap terbuka: koreksi stok masuk, pembatalan setelah rate/jam/Lewati, dan pemulihan ID niat. Half-up yang telah disepakati tidak menutup ketiga keputusan tersebut. Berhenti pada M2.
