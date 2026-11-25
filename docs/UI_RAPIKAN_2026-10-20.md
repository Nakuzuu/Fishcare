# Revisi tampilan FishCare — 20 Oktober 2026

Sumber **0.8.1+9**, aplikasi Flutter yang sama, application ID `id.ac.fishcare.m0`, skema5. Perubahan UI tersedia pada kode. Analisis Flutter, seluruh tes, build APK dan render sesudah **belum terverifikasi** akibat akses SDK sesi agen. Tidak menganggap perbaikan sudah rapi/stabil hanya dari inspeksi sumber.

## Keputusan dan acuan

Instruksi pengguna terbaru menetapkan **header FishCare → cuaca → pakan hari ini → kolam aktif → ringkasan lain**. Menggantikan penempatan cuaca terakhir pada desain15Oktober dan tahap0.8.0. [PRD](PRD_FishCare_Baru_v0.1.md) bagian3/6, AT-46, [wireframe](WIREFRAME.md), [catatan desain](desain/README.md) dan [prototipe HTML](desain/index.html) diselaraskan. PNG/PDF di output/desain tetap arsip visual dasar; belum diregenerasi sebagai screenshot Flutter baru.

Referensi visual yang dipelajari: [Google Weather pada Android](https://blog.google/products-and-platforms/platforms/android/app-redesign-foldables/). Arah yang diadaptasi adalah informasi cuaca yang mudah dipindai, suhu dominan, ikon dan latar lembut. Tidak menyalin merek/maskot atau menambahkan prakiraan jam/angin/kelembapan.

Tiga screenshot yang disebut dalam pesan pengguna tidak terlihat sebagai lampiran pada sesi agen. Pemeriksaan memakai sumber saat tugas dimulai dan acuan desain lokal; tidak mengklaim sudah mencocokkan ketiga lampiran tersebut.

## Perubahan

| Area | Hasil pada kode | FR/AT |
|---|---|---|
| Tata letak bersama | Margin18dp, pasangan label–nilai tetap sejajar selama lebarnya cukup; angka besar berpindah susunan bila perlu, bukan semua baris otomatis menumpuk pada teks130%. Tombol diberi jarak dan tindakan primer/sekunder dibedakan. ListView tab tidak berbagi primary scroll controller | PRD9, AT-19/27/46 |
| Beranda | Cuaca menjadi anak pertama sesudah header, kemudian pakan/kolam/ringkasan. Posisi loading/error lokal tidak menggeser cuaca ke bawah | FR-01/04/08, AT-20–22/46 |
| Cuaca | Komponen tampilan murni WeatherCard: nama asli lokasi, suhu52sp, ikon80dp offline, kondisi, peluang hujan, status, waktu, atribusi. Gradasi lembut menurut kondisi. Atur lokasi/Muat ulang/Detail cuaca | FR-08, AT-20–22/41–46 |
| Waktu dan cache | Waktu penyedia memakai zona/offset dari payload tersimpan; waktu pengambilan dikonversi memakai offset penyedia. Tanpa metadata offset, pengambilan berlabel waktu perangkat; zona lokasi tidak ditebak. Prakiraan cache berbeda tanggal memakai tanggal asli, tidak disebut hari ini | FR-08, AT-22/46 |
| Lokasi | Pengambilan tetap hanya tombol Ambil lokasi saat ini; calon, konfirmasi, pembatalan dan controller lama dipertahankan. Tidak menamai ulang Lokasi HP menjadi kota. Koordinat ringkas pada layar lokasi; lengkap pada Detail cuaca | AT-41–45 |
| Detail kolam | Nama sekali di header; badge Kolam aktif/arsip terpisah dari status siklus. Identitas label–nilai dan Ubah identitas sekunder; Mulai siklus sebelum riwayat pada kolam tanpa siklus. Arsipkan terpisah dan tetap dikonfirmasi | FR-01/02, AT-01–03/19 |
| Riwayat | ActivityCard berisi jenis, tanggal, status, jumlah dan biaya/nilai utama. Detail kegiatan menampung kondisi sebelum/sesudah, snapshot dan alasan batal. ID tetap tersimpan dan dibuka lewat bagian identitas. Detail kolam tidak menggandakan riwayat pemberian karena riwayat kegiatan sudah mencakupnya; menu Pakan tetap mempunyai riwayat pemberian | FR-04–06, AT-15–17/34–35 |
| Laporan | Filter tanggal/kolam tetap tersimpan. Tiga scope tidak dicampur. Rupiah Rp45.000; angka/tanggal ramah. Kartu siklus memakai nama/ikan/tanggal/status dan metrik terstruktur; ID panjang pada Detail siklus. Detail transaksi tetap memakai snapshot/filter semula | FR-07, AT-18/19/37–40 |

File baru: [weather_card.dart](../app_m0/lib/weather_card.dart), [activity_ui.dart](../app_m0/lib/activity_ui.dart), [ui_format.dart](../app_m0/lib/ui_format.dart). Delapan file UI lama disesuaikan. [Perbandingan sumber](../logs/ui-polish-source-comparison.json) membuktikan28file asal lain identik byte-per-byte, termasuk repository, rumus, journal/payload, controller, skema dan migrasi. Satu query baca riwayat UI menambah proyeksi tanggal mulai/jenis ikan untuk label siklus; tidak mengubah baris, urutan, atau aturan kandidat pembatalan. Dependency/lockfile dan konfigurasi Android tidak diubah. Versi sumber dinaikkan untuk membedakan artifact baru.

Backup/restore tetap belum tersedia. Tidak menambah animasi dekoratif, fitur budidaya, metrik cuaca, data awal, reset, uninstall, atau perubahan ID aplikasi.

## Bukti verifikasi

| Pemeriksaan | Status |
|---|---|
| Format Dart sumber dan tes | Lulus formatter/parser; [log](../logs/ui-polish-format.log). Bukan analisis tipe |
| Format uang/angka/tanggal Dart murni |7 kasus lulus; [log tambahan](../logs/ui-polish-format-extra.log). Bukan flutter test |
| Sintaks JavaScript prototipe | Lulus kompilasi sintaks melalui Node; bukan inspeksi render browser |
| flutter analyze | Terhalang bootstrap SDK, tidak mencapai analyzer |
| seluruh flutter test | Terhalang bootstrap SDK, runner belum mulai; jumlah lulus/gagal tidak diketahui |
| flutter build apk --debug | Terhalang bootstrap SDK; tidak ada APK0.8.1+9 yang dihasilkan agen |
| Screenshot sebelum/sesudah Flutter | Tes render disiapkan; belum dieksekusi, sehingga belum ada PNG render sah untuk dinilai |
| Perangkat | ADB terhubung: Infinix X6879, Android16/API36. Package lama0.8.0/code8 terdeteksi; bukan pemasangan revisi9 |
| Tangkapan HP | Upaya membuka app lama dan screencap menghasilkan splash lalu hitam; dumpsys power Dozing. Tidak dihitung sebagai screenshot Beranda/detail/Laporan atau bukti aplikasi gagal |
| Pemasangan dan regresi HP revisi9 | Belum dilakukan |

[Log status lingkungan](../logs/ui-polish-standard-status.log). [Metadata/hash APK yang sudah ada dan lockfile](../logs/ui-polish-artifact-evidence.log). Akses ReadWrite `C:\flutter\bin\cache\flutter.bat.lock` ditolak; kebijakan sesi tidak menyediakan eskalasi sandbox. Perintah standar dihentikan dengan Ctrl+C ketika hanya mengulang bootstrap. Tidak mengubah SDK/cache/ACL, mengganti SDK, atau menjalankan snapshot Flutter sebagai bypass.

Pengguna sudah diminta menjalankan jalur standar dari terminal yang berakses SDK serta membuka kunci HP; hasil eksternal belum diterima saat catatan ini ditulis. Status tidak berubah menjadi lulus karena permintaan tersebut.

## Render sebelum/sesudah yang dapat direproduksi

Sumber sebelum perubahan disimpan pada `tmp/ui-review-before/lib`. Salinan khusus render `tmp/ui-review-before-render/lib` hanya menambah titik injeksi cuaca uji pada posisi lama. Semua sumber referensi tetap terpisah dari aplikasi produk.

[Tes render sesudah](../app_m0/test/ui_render_after_test.dart) menggunakan widget aplikasi nyata dengan repository/cuaca fixture di memori, tanpa SQLite/GPS/jaringan. Ada3layar ×2konfigurasi:390dp/100% dan360dp/130%. Setiap gambar diberi banner **DATA UJI RENDER**. Data tersebut tidak masuk ke aplikasi pengguna. Test sesudah memeriksa exception layout; tidak menghapus atau melonggarkan assertion fitur lama.

Dari root app_m0, pada terminal yang berakses SDK:

```powershell
flutter analyze
flutter test
flutter test ../tmp/ui-review-before-render/ui_render_before_test.dart
flutter build apk --debug
```

Seluruh flutter test mencakup render sesudah. Render sebelum adalah pembanding historis tambahan di luar suite aplikasi sekarang. Hasil yang diharapkan **setelah perintah benar-benar berhasil**, bukan berkas yang sudah tersedia:

```text
output/ui-review/before-render/beranda-390-text100.png
output/ui-review/before-render/detail-kolam-390-text100.png
output/ui-review/before-render/laporan-390-text100.png
output/ui-review/after-render/beranda-390-text100.png
output/ui-review/after-render/detail-kolam-390-text100.png
output/ui-review/after-render/laporan-390-text100.png
```

Varian tambahan memakai akhiran `360-text130.png`. Buka semua pasangan, periksa hierarki/margin/angka/ikon, konten awal dan overflow, lalu iterasikan bila perlu. Jangan menyebut tahap lolos visual sebelum gambar tersebut diperiksa. Tangkapan hitam diagnosis pada `before-device` bukan pasangan sebelum yang valid dan tidak boleh dipakai menggantikannya.

Tes baru [ui_polish_test.dart](../app_m0/test/ui_polish_test.dart) mencakup format besar/zona,6statecuaca360dp/130%, urutan cuaca, nama kolam sekali, ID tersembunyi, snapshot/alasan batal dan posisi gulir antartab. Tes keyboard/form yang sudah ada tetap dipertahankan. Tes snapshot panen lama hanya menyesuaikan format uang tampilan; nilai dan pemeriksaan filter tetap sama. Belum ada klaim tes runtime lulus.

APK baru yang diharapkan setelah build berhasil: `app_m0/build/app/outputs/flutter-apk/app-debug.apk`, versionName0.8.1/versionCode9. Verifikasi timestamp/hash/versi sebelum pemasangan. APK20Oktober13.09 yang terdeteksi saat tugas dimulai adalah artifact0.8.0; jangan menyatakannya sebagai APK revisi baru.

## Uji HP setelah build dan pemasangan terbukti

1. Pasang pembaruan tanpa uninstall/clear data. Cocokkan data aktif/arsip dan riwayat sebelum/sesudah; catat versi9.
2. Ambil screenshot Beranda, detail kolam dan Laporan pada100% dan130%; periksa juga lebar360dp pada tes widget. Pastikan cuaca tepat setelah header, nama kolam sekali, unit/angka/nama panjang tidak terpotong, tombol berjeda dan konten tidak tertutup navigasi.
3. Gulir setiap tab, pindah tab lalu kembali; periksa posisi awal yang benar dan filter Laporan tetap. Buka/tutup Detail cuaca/kegiatan/siklus; navigasi kembali tidak mengubah data.
4. Uji setiap form dengan keyboard terbuka, field terakhir, error input dan Kembali. Tombol/field/error dapat dijangkau; draft dipertahankan bila memilih Tetap mengisi. Uji daftar kosong memakai repository tes, bukan mengosongkan data produk.
5. Cuaca: loading, berhasil nyata, cache lama, mode pesawat dengan/tanpa cache, retry; navigasi dan pencatatan lokal tetap tersedia. Verifikasi waktu memakai zona lokasi yang benar; cache tanggal lama tidak disebut hari ini. Membuka/refresh tidak mengambil GPS. Ambil lokasi saat ini/manual/calon/batal/konfirmasi tetap mengikutiAT-41–45.
6. Pada data uji terisolasi, regresikan stok masuk, pemberian/ketuk ganda/stok kurang/batal, rate/jam/sampling, kematian dan panen. Cocokkan snapshot dan total lintas Beranda/Pakan/Laporan; transaksi batal terlihat tetapi tidak dijumlahkan. Jalankan suite native `flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>` sesuai prosedur proyek.

Catat setiap hasil terpisah sebagai lulus/gagal/terhalang/belum dijalankan, serta bedakan render fixture, pemeriksaan agen di HP dan konfirmasi pengguna. Tahap ini tetap belum selesai verifikasi sampai analisis/tes/build serta screenshot hasil benar-benar diperoleh dan diperiksa.
