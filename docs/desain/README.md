# Desain UI FishCare baru

15 Oktober 2026 · Draf visual 01, untuk ditinjau. Desain ini diturunkan dari PRD baru dan wireframe proyek, bukan desain aplikasi lama. Warna, bentuk komponen, dan susunan visual merupakan usulan; belum merupakan persetujuan desain final.

Buka [prototipe](index.html) di browser. Pilih layar melalui daftar, klik navigasi/tombol dalam HP, atau pilih **Lihat semua layar**. **Cetak desain** menyediakan tampilan cetak. Tidak memerlukan instalasi atau internet. Pratinjau menggambarkan aplikasi Android, bukan usulan platform web tambahan.

Template `TEMPLATE PROPOSAL PjBL PPB.docx` menyediakan bagian 3.5 Desain UI/UX (Wireframe). Hasil ini menjadi bahan desain sebelum penyusunan laporan. Isi contoh/petunjuk template tidak diperlakukan sebagai perintah menulis seluruh proposal. File template asli tidak diubah.

## Arah visual

Hijau tua `#12685D` untuk tindakan utama, latar terang `#F6F8F4`, teks `#173C39`, dan kartu putih. Warna status selalu disertai teks: Diberikan, Menunggu, Batal, atau Offline. Ikon garis sederhana dipadukan dengan label. Tidak ada foto/aset jaringan yang diperlukan.

Lebar acuan HP 390 px, pemeriksaan tambahan 360 px. Teks isi 15 px, label field 13 px, judul layar 23 px. Grid jarak dasar 4 px, margin isi 18 px, sudut kartu 18 px. Font pratinjau memakai font sistem; penerapan Android perlu memakai font lokal yang tersedia dan memeriksa ulang metriknya. Tombol utama dan input minimal 48 px. Navigasi utama memiliki empat label: Beranda, Kolam, Pakan, Laporan. Form dan konfirmasi memakai Kembali serta tombol utama di bagian bawah, tanpa navigasi utama.

Revisi pengguna20Oktober2026: urutan Beranda adalah header FishCare → kartu cuaca → pakan hari ini → kolam aktif → ringkasan lain. Cuaca tetap independen dari data lokal. Kartu cuaca menonjolkan nama lokasi/suhu udara/ikon kondisi, dengan waktu ramah/status/atribusi ringkas dan metadata lengkap pada detail. Detail kolam menyajikan identitas, kondisi kini, kegiatan dan riwayat yang dibedakan; nama cukup sekali pada header. Dua bagian Pakan membedakan pemberian hari ini dari saldo bersama. Laporan menyusun metrik label–nilai dan format Rp45.000, tanpa keuntungan bersih atau FCR.

PDF/PNG15Oktober tetap acuan visual dasar dan arsip rancangan; urutan cuaca di dalamnya digantikan instruksi terbaru di atas. Prototipe HTML diselaraskan; data tetap simulasi. Screenshot baru hanya boleh dilabeli hasil aplikasi setelah benar-benar dirender. Referensi arah visual cuaca: [Google Weather](https://blog.google/products-and-platforms/platforms/android/app-redesign-foldables/); hanya hierarki visual yang diadaptasi, tanpa merek/maskot atau metrik tambahan. [Catatan revisi](../UI_RAPIKAN_2026-10-20.md).

## Cakupan dan hubungan ke kebutuhan

| Kelompok layar | Isi rancangan | Acuan |
|---|---|---|
| Beranda | Kegiatan pakan, kolam, cuaca terpisah dari data lokal | FR-01–04/08; AT-01/19–22 |
| Kolam dan siklus | Daftar, identitas, detail, mulai dan tinjau siklus | FR-01–02; AT-01–03/27 |
| Pakan dan stok | Slot, aktual, konfirmasi, master, stok masuk, koreksi dan tinjau | FR-03–04; AT-04–10/15–16/28–31 |
| Kegiatan | Rate sekarang, jam besok, sampling, kematian, parsial, akhir, konfirmasi | FR-02/04–06; AT-08–17/26/32–35 |
| Laporan | Filter, lima metrik, pendukung, snapshot pemberian/panen, kematian batal, pembatalan | FR-07; AT-18–19/34/37–40 |
| Lokasi | Pengaturan, ambil sekali, pencarian manual, calon, konfirmasi simpan, penolakan izin | FR-08; AT-20–22/41–45 |
| Keadaan | Kosong, loading, gagal baca, stok kurang, offline, berhasil, pemeriksaan ID, ilustrasi keyboard | Lintas fitur; AT-01/06/19–22/25/27/31/40 |

Rancangan berisi 49 layar/varian, termasuk tahap konfirmasi dan keadaan. Catatan di samping setiap layar menyatakan aturan serta FR/AT terkait. Nomor tampilan bukan ID persyaratan. Ini bukan klaim seluruh AT sudah diuji.

## Aturan perilaku yang dipertahankan

- Rate berlaku sekarang untuk porsi menunggu. Jam berlaku besok dan tidak mengganti slot hari ini. Pemberian selesai tetap utuh.
- Konfirmasi penting menampilkan dampak stok, populasi, atau nilai sebelum simpan. Saat menyimpan, tombol tidak aktif. Validasi gagal mempertahankan draft, memberi pesan dekat field, dan tidak mengubah data. Kembali dari draft yang berubah pada aplikasi nyata meminta konfirmasi buang perubahan.
- Stok adalah saldo bersama semua kolam. Koreksi menunjukkan jumlah lama/baru, alasan, dan pergerakan selisih. Tidak ada field untuk menimpa saldo.
- Sampling tidak mengurangi populasi. Kematian boleh menghabiskan populasi. Parsial menyisakan ikan. Akhir memakai seluruh sisa secara otomatis; populasi nol ditutup tanpa panen rekaan. Penutupan tidak dapat dibatalkan.
- Pembatalan beralasan hanya untuk kegiatan operasional sah terakhir pada hari yang sama dalam siklus aktif; kelayakan diperiksa ulang. Perubahan rate/jam/Lewati bukan penghalang. Kegiatan lanjutan menghalangi pembatalan yang lebih lama.
- Hasil simpan belum pasti diarahkan ke pemeriksaan ID tindakan yang sama. Retry eksplisit ditawarkan setelah hasil diperiksa; tidak membuat ID baru otomatis.
- Laporan mempertahankan filter saat membuka pendukung/detail; seluruh metrik transaksi mengikuti periode inklusif serta kolam yang sama, termasuk arsip. Batal tetap terlihat dengan alasan tetapi tidak masuk total. Kondisi saat ini dan Seluruh siklus diberi scope berbeda. Jumlah biaya/nilai memakai snapshot per transaksi.
- Cuaca memakai satu lokasi usaha. Tombol Ambil lokasi saat ini pada aplikasi nyata meminta izin foreground bila perlu dan mengambil sekali; tidak ada pengambilan saat startup, tracking, atau background. Calon baru tidak mengganti lokasi lama sebelum Simpan sebagai lokasi usaha. Pembaruan memakai koordinat tersimpan; hasil lama diabaikan setelah pergantian. Penolakan/GPS mati/timeout menawarkan coba lagi/manual. Pembatalan mempertahankan lokasi lama.
- Loading cuaca tidak menahan navigasi lokal. Offline menampilkan waktu cache; tanpa cache menyatakan cuaca belum tersedia. Kosong berbeda dari gagal baca; kegagalan bukan angka nol.

## Data contoh dan batas interaksi

Semua angka, tanggal, Jakarta, koordinat, cuaca, serta status simpan adalah contoh desain. Tidak ada akses SQLite, GPS, izin Android, API, berkas pengguna, atau data aplikasi. Tombol berpindah antara layar contoh; perubahan input/filter tidak menghitung atau menyimpan data. Status berhasil diberi label simulasi. Ini bukan bukti keberhasilan implementasi atau pengujian HP.

Dataset utama: Kolam Utara 100 ikan, 100 g, rate 3%, kebutuhan 300 g, aktual 150 g, sisa 150 g. Stok awal contoh 5.000 g, setelah pemberian 4.850 g. Harga Rp10.000/kg membuat biaya 150 g sebesar Rp1.500. Form sampling/rate/kematian/panen adalah skenario alternatif, bukan perubahan berurutan pada dataset yang sama.

Dataset laporan: dua pemberian 150 g, masing-masing Rp1.500 pada 14 dan 15 Oktober; panen arsip 20 ikan × 200 g × Rp25.000/kg pada 10 Oktober = Rp100.000; kematian 2 ekor tanggal 15 Oktober dibatalkan dengan alasan. Total periode 300 g, Rp3.000, mati 0, panen 20, nilai Rp100.000. Detail kematian tidak memuat field panen. Skenario akhir terpisah memakai sisa 100 ekor; tidak mengasumsikan kelanjutan dari parsial 20.

## Pemeriksaan dan batas kesiapan

Pemeriksaan browser lokal menggunakan Playwright dan Chrome terpasang berhasil untuk seluruh layar: tidak ada error JavaScript, tujuan tombol yang hilang, atau overflow horizontal konten. Perpindahan Beranda → Pakan, alasan kematian batal, detail panen, lebar viewport 360 px, dan posisi tombol di atas ilustrasi keyboard diperiksa. Bukti terstruktur tersedia di [hasil-pemeriksaan.json](hasil-pemeriksaan.json); script pemeriksaan ada di [periksa.cjs](periksa.cjs). Browser bawaan Playwright tidak tersedia; pemeriksaan menggunakan Chrome terpasang tanpa mengunduh dependency.

Pratinjau visual utama diperiksa dari gambar hasil render. Pemeriksaan ini tidak menggantikan pengujian keyboard Android, pembesaran teks 130%, izin, API, persistensi, atau transaksi aplikasi nyata. Tidak menjalankan Flutter analyze/test/build karena tugas hanya membuat rancangan dan tidak mengubah kode aplikasi.

Sebelum penerapan visual: tinjau palet/hierarki, kepadatan detail kolam, dan pemisahan dua bagian Pakan. Batas pengunci zona waktu tetap mengikuti keputusan terbuka dokumen proyek, tidak diputuskan melalui desain. Backup/restore hanya penanda belum tersedia, bukan fitur yang selesai atau diimplementasikan dalam tugas ini. Tidak mengubah aturan PRD maupun status persetujuan usulan lain.

Rancangan siap ditinjau sebagai bahan bagian 3.5 proposal. Penulisan laporan dan penerapan desain ke Flutter belum dimulai.
