# Penerapan UI baru FishCare

Catatan ini adalah riwayat sumber0.8.0. Revisi pengguna20Oktober untuk cuaca di atas Beranda serta perapian detail/riwayat/Laporan ditangani pada [UI_RAPIKAN_2026-10-20.md](UI_RAPIKAN_2026-10-20.md), sumber0.8.1+9. Status hasil lama di bawah tidak menjadi bukti build/render revisi baru.

20 Oktober 2026. Sumber aplikasi `app_m0`, versi **0.8.0+8**. Implementasi statis tersedia; **belum terverifikasi dengan analisis, tes Flutter, render aplikasi, build APK, atau HP** karena batas lingkungan sesi ini. Bukan kandidat demo yang sudah lulus. Tidak melanjutkan animasi.

## Acuan dan batas

Mengikuti [PNG desain](../output/desain/png/), [PDF desain](../output/desain/FishCare-Desain-UI-Baru.pdf), [prototipe](desain/index.html), [catatan visual](desain/README.md), [wireframe](WIREFRAME.md), dan [PRD](PRD_FishCare_Baru_v0.1.md). PNG menjadi acuan visual; angka desain tidak dimasukkan ke database. PRD dan status usulan bagian14 tidak diubah.

Database, migrasi/skema5, application ID `id.ac.fishcare.m0`, repository, rumus, snapshot, payload transaksi, dan pemulihan ID tetap menggunakan implementasi yang ada. Tidak mengubah konfigurasi Android, dependency, atau lockfile. Nomor versi sumber dinaikkan agar hasil build berikutnya dapat dibedakan dari artifact lama. Tidak menjalankan reset, uninstall, clear data, instalasi, atau perubahan SDK.

## Layar yang diterapkan

| Area | Penerapan dan keterlacakan |
|---|---|
| Komponen bersama | Hijau#12685D, latar#F6F8F4, teks#173C39, kartu putih radius18, margin18, tombol/input48dp, header dan navigasi disesuaikan; badge berlabel, notice, baris nilai yang bertumpuk saat teks130%. PRD9/AT-27 |
| Beranda | Kartu hijau sisa pakan seluruh kolam, tanggal/zona usaha dari repository, slot menunggu, kartu kolam, ringkasan transaksi hari ini, cuaca paling akhir. FR-01/02/04/07/08; AT-01/19/26/39 |
| Kolam | Aktif/Arsip, tambah kolam, kartu kondisi populasi/bobot/siklus dari repository, detail serta identitas. FR-01/02; AT-01–03/19 |
| Pakan | Pemberian hari ini/Stok pakan; kebutuhan/aktual/sisa per kolam, slot dan status, Berikan/Lewati memakai kontrol transaksi lama, jam besok, riwayat. Daftar stok menampilkan saldo bersama nyata. FR-03/04; AT-04–10/15–17/26/28–31 |
| Detail dan kegiatan | Kartu kondisi kini, kebutuhan, jadwal; sampling, kematian, parsial, akhir, pembatalan serta riwayat tetap terhubung. FR-02/04–06; AT-08–17/32–35 |
| Form dan konfirmasi | Input berlabel/satuan, jarak antarkomponen, scroll mengikuti inset keyboard, ruang tambahan field fokus. Konfirmasi siklus/pemberian/stok/koreksi/kegiatan/rate/jam/lokasi berupa halaman scroll tanpa navigasi utama. Draft kegiatan meminta konfirmasi saat kembali; simpan yang sedang berjalan tidak dapat ditinggalkan lewat Kembali. Payload/ID bisnis tetap. AT-05/25/27/31 |
| Laporan | Filter periode ringkas yang dibuka lewat kartu Periode laporan, lima metrik dalam satu kartu; kondisi kini/seluruh siklus terpisah. Pendukung/detail tetap memakai filter dan snapshot lama. FR-07; AT-18/19/37–40 |
| Pengaturan/lokasi | Ikon Pengaturan Beranda; lokasi usaha, zona tersimpan, penanda backup belum tersedia. Kartu cuaca mempunyai Atur lokasi; pengambilan HP/manual dan calon ada pada layar lokasi, tetap melalui tombol eksplisit dan konfirmasi. FR-08; AT-20–22/41–45 |
| Keadaan | EmptyPanel dengan tindakan sesuai konteks, indikator loading, notice gagal baca/validasi/hasil belum pasti, status cuaca/cache/offline dan waktu asli, snackbar berhasil setelah penyimpanan lama, pemulihan ID tetap tersedia. Gagal baca kegiatan tidak menghasilkan kebutuhan0. |

File utama: [design_system.dart](../app_m0/lib/design_system.dart), [dashboard_ui.dart](../app_m0/lib/dashboard_ui.dart), [product_app.dart](../app_m0/lib/product_app.dart), serta `cycle_ui.dart`, `feed_ui.dart`, `lifecycle_ui.dart`, `report_ui.dart`, dan `weather_ui.dart`.

State transaksi tetap pada pemilik sebelumnya. Kartu kolam/slot memakai key berdasarkan ID dan jam; hasil pembacaan lokal diabaikan oleh FutureBuilder ketika future diganti. Ringkasan baru mendengarkan sinyal commit dan pergantian hari/resume. Filter laporan tetap disimpan ketika berpindah tab. Belum menambahkan animasi dekoratif atau paket animasi; transisi dan interaksi Material bawaan masih ada.

## Perbedaan dari acuan dan yang belum tersedia

- Beranda menjumlahkan sisa dari semua kolam aktif karena pengguna dapat memiliki lebih dari satu kolam. Desain utama menggunakan contoh satu kolam. Tidak menampilkan kota, tanggal, stok, atau transaksi contoh.
- Form memakai label mengambang yang selalu terlihat dan tombol pada akhir konten yang dapat digulir, bukan footer yang selalu melekat. Konfirmasi memakai ringkasan teks nyata dalam kartu; belum seluruhnya disusun menjadi pasangan label/nilai seperti PNG. Font bawaan Android dan ikon Material lokal menggantikan metrik font/ikon browser.
- Filter laporan dibuka di tempat melalui kartu periode; bukan route filter tersendiri. Riwayat masih berada bersama kontrol kegiatan/detail agar fungsi yang ada tetap terjangkau. Detail kolam menampilkan jadwal langsung, sedangkan gambar memberi jalan pintas menuju jadwal.
- Cuaca dan pengaturan lokasi berbagi panel yang sama; halaman lokasi masih memuat informasi cuaca. Konfirmasi arsip dan Lewati tetap dialog pendek yang ditata tema bersama.
- Backup/restore belum dibangun dan hanya diberi keterangan; tidak ada tombol palsu. Tidak menambah budidaya baru, FCR, keuntungan, notifikasi, atau diagnosis.
- Kesesuaian piksel, overflow semua layar, keyboard Android, aksesibilitas, dan regresi fungsi belum dibuktikan melalui runtime. Semua perbedaan di atas perlu ditinjau bersama hasil render/HP setelah jalur Flutter dapat digunakan.

## Verifikasi sesi

| Pemeriksaan | Status dan bukti |
|---|---|
| Format sumber dan tes UI | Lulus parser/formatter Dart; bukan analisis tipe atau eksekusi Flutter. Lihat logs/ui-format.log |
| `flutter analyze` dari app_m0 | Terhalang lingkungan; bootstrap tidak menghasilkan keluaran. Akses ReadWrite ke C:\flutter\bin\cache\flutter.bat.lock ditolak. Dihentikan dengan Ctrl+C. Bukan0 error/warning |
| Seluruh `flutter test` dari app_m0 | Terhalang pada bootstrap yang sama, dihentikan dengan Ctrl+C. Runner belum mulai; jumlah lulus/gagal tidak diketahui |
| `flutter build apk --debug` dari app_m0 | Terhalang pada bootstrap, dihentikan dengan Ctrl+C. Tidak menghasilkan APK UI baru |
| Eskalasi resmi `flutter analyze` | Ditolak otomatis oleh kebijakan sandbox_approval:false; tidak ada jalur eskalasi yang dapat digunakan sesi ini |
| `dart.exe analyze app_m0/lib` tambahan | Terhalang; CreateFile failed5/Access denied saat memulai dartaotruntime/analysis_server_aot. Tidak menggantikan flutter analyze |
| `adb get-state` | Gagal: no devices/emulators found. Tidak ada model atau API level yang dapat diverifikasi |
| Render Flutter, pemasangan dan uji HP | Belum dijalankan |

[Log status](../logs/ui-standard-status.log). [Metadata/hash artifact dan lockfile](../logs/ui-artifact-evidence.log). APK lama di lokasi build bertanggal15Oktober2026, bukan hasil tahap UI20Oktober2026; jangan menganggap keberadaan berkas itu sebagai build baru.

Enam tes baru [design_ui_test.dart](../app_m0/test/design_ui_test.dart) disiapkan untuk: kembali/draft, ringkasan360dp/130% setelah commit, gagal baca/retry tanpa nol palsu, keyboard dan validasi, konfirmasi panjang/batal, serta navigasi lokal ketika cuaca tertunda tanpa mengambil HP. Fixture hanya berada pada test. Tes lokasi yang ada diarahkan ke permukaan settings; tes laporan membuka filter baru sebelum berinteraksi. Assertion bisnis tidak dihapus. Semua ini **belum dijalankan**, bukan enam tes lulus.

## Langkah verifikasi berikutnya

Dari terminal Android Studio/PowerShell yang mempunyai akses SDK, root app_m0:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Perbaiki kegagalan yang nyata sebelum memasang. APK yang diharapkan setelah build berhasil: `app_m0/build/app/outputs/flutter-apk/app-debug.apk`, versionName0.8.0/versionCode8. Catat hash/waktu baru dan hasil perintah. Berkas tersebut **belum dihasilkan tahap ini**.

Untuk regresi penyimpanan pada perangkat uji, jalankan suite native terisolasi yang sudah ada:

```powershell
flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>
flutter install --debug -d <ID_HP_LOKAL>
```

Jangan uninstall atau clear data produk. Verifikasi bahwa model/Android/API aktual telah dicatat; jangan memakai angka16.3.0 sebagai API level.

| Uji HP | Yang harus diperiksa |
|---|---|
| Lebar360dp, teks100% lalu130% | Empat label navigasi, judul panjang, nama kolam panjang, status, angka dan satuan terbaca; tidak overflow/terpotong. Semua kartu/form/riwayat dapat digulir, target sentuh cukup |
| Keyboard setiap form | Isi field terakhir, munculkan error input, gunakan Next/Done, gulir ke tombol. Field fokus/error dan tombol dapat dijangkau di atas keyboard; Kembali menutup keyboard, kembali lagi menjaga/membuang draft sesuai pilihan |
| Navigasi dan offline | Beranda→Pakan→Kolam→Laporan tetap berfungsi saat cuaca loading/gagal/mode pesawat. Tanpa cache tidak ada kota/cuaca palsu; cache menampilkan waktu/status jujur |
| Kolam/pakan lama | Data aktif/arsip/harga/catatan tetap sama setelah upgrade dan cold restart. Jangan membuat ulang data agar tampilan terlihat terisi |
| Stok/pemberian | Catat stok masuk, berikan pakan, ketuk konfirmasi berulang; hanya satu pengurangan. Stok kurang ditolak utuh, draft tetap. Beranda/Pakan/Laporan menampilkan hasil terbaru; batal memulihkan stok tepat |
| Rate/jam/sampling | Rate hanya menghitung ulang pending; jam berlaku besok; sampling tidak mengurangi populasi. Snapshot pemberian lama tetap. Lewati tidak membuat pemberian0 |
| Populasi/panen | Kematian berlebih ditolak; parsial menyisakan ikan; akhir memakai seluruh sisa dan tidak dapat dibatalkan. Cek riwayat/pembatalan sah terakhir serta filter laporan dan detail panen/kematian batal |
| Lokasi | Membuka/refresh tidak meminta GPS. Ambil lokasi saat ini baru meminta foreground/fix sekali. Batal/izin ditolak menjaga lokasi lama; calon hanya tersimpan setelah konfirmasi; restart mempertahankan lokasi |
| Pemulihan | Pada perangkat/data uji, hentikan aplikasi sekitar pencatatan lalu periksa ID yang sama sebelum retry; jangan mengulang otomatis atau menghapus niat |

Catat setiap baris lulus/gagal/belum dijalankan dan sumber buktinya. Hasil tahap UI tidak membuktikan seluruh AT atau fitur lama telah lulus.
