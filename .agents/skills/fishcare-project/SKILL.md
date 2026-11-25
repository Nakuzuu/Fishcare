---
name: fishcare-project
description: Rencanakan, implementasikan, diagnosis build Android, uji, atau review FishCare berdasarkan PRD rancangan baru. Gunakan untuk pekerjaan proyek FishCare; bukan untuk tugas Flutter umum atau menjalankan seluruh pembangunan tanpa permintaan pengguna.
---

# FishCare Project

Gunakan skill ini sebagai panduan utama pelaksanaan FishCare. Kebutuhan produk tetap berada di PRD; skill tidak menyalin atau mengganti spesifikasi tersebut.

## Mulai dari konteks yang benar

1. Identifikasi maksud pengguna: perencanaan, desain, implementasi satu tahap, diagnosis build, atau review. Lakukan hanya pekerjaan yang termasuk tugas tersebut.
2. Baca [AGENTS.md](../../../AGENTS.md) dan [PRD FishCare Baru v0.1](../../../docs/PRD_FishCare_Baru_v0.1.md). Tautan relatif terhadap direktori skill yang terpasang di `.agents/skills/fishcare-project`. Jika paket dipindahkan, pertahankan struktur ini. Jika referensi hilang, cari file PRD yang disebut dalam AGENTS; jangan mengarang aturan pengganti.
3. Periksa root aplikasi yang akan dikerjakan dan perubahan yang sudah ada. Direktori berisi PRD bisa merupakan proyek lama. Untuk implementasi ulang, cari target baru yang sudah ditetapkan; jangan menganggap `lib` lama sebagai target pembangunan baru.
4. Petakan kebutuhan FR dan skenario AT yang terkait. Baca bagian detailnya, bukan hanya nama fitur. Saat pertama merancang arsitektur/alur lintas fitur, baca seluruh PRD; pada pekerjaan berikutnya cukup baca bagian yang berubah atau relevan.
5. Periksa keputusan PRD yang masih berupa usulan dan otorisasi pengguna yang sudah ada. Jangan meminta persetujuan ulang untuk keputusan yang telah diberikan. Nyatakan asumsi rutin; klarifikasi hanya konflik/ketidakjelasan material dan teruskan pekerjaan independen.

## Pilih alur tugas

### A. Rancangan dan desain

- Turunkan bagian 3–9 PRD menjadi alur pengguna, state layar, model data, serta hubungan antarfungsi. Rujuk ID FR/AT agar keputusan dapat ditelusuri.
- Untuk setiap operasi uang, stok, atau populasi, tentukan input, validasi, perubahan atomik, pembatalan, dan akibat ke laporan sebelum merancang tombolnya.
- Sertakan kondisi kosong, loading, gagal, offline, dan data belum lengkap. Hindari desain yang mengasumsikan semua data/jaringan selalu tersedia.
- Gunakan desain/referensi pengguna bila ada. Jika belum ada, hasilkan wireframe dan aturan komponen; jangan mengklaim desain disetujui atau mengerjakan redesign kode ketika hanya diminta rancangan.
- Perbarui dokumen yang diminta dan laporkan keputusan terbuka. Dokumen tidak boleh mengubah usulan PRD menjadi persetujuan fiktif.

### B. M0 atau diagnosis build Android

- Baca PRD bagian 10. Untuk diagnosis, mulai dari error pertama yang menghentikan build; bedakan warning dengan kegagalan. Jangan menerapkan semua saran otomatis di akhir log tanpa memeriksa sebabnya.
- Inventarisasi Flutter/Dart, Java yang benar-benar digunakan Gradle, AGP, wrapper Gradle, compile/target/min SDK, NDK, serta plugin. Periksa `pubspec.yaml`, lockfile, konfigurasi Gradle, dan lokasi SDK aktual sebelum memilih perbaikan.
- Verifikasi perangkat melalui `flutter devices` atau `adb` jika tersedia. Jangan mengganti target HP menjadi Windows desktop. Jangan menampilkan serial perangkat tanpa kebutuhan.
- Pilih perubahan terkecil yang menyelesaikan ketidakcocokan, berdasarkan dokumentasi resmi versi terkait. Jangan menebak versi terbaru pasti kompatibel.
- Jika versi dependency diubah, pastikan resolusi dependency berhasil dan lockfile sesuai sebelum menilai kesalahan API. Jika unduhan gagal, laporkan migrasi belum selesai; jangan terus mengubah kode untuk mengejar dua versi sekaligus.
- Jaringan/proxy gagal, instalasi NDK tidak lengkap, file terkunci, atau akses ditolak adalah masalah lingkungan yang harus dibuktikan. Jangan menghapus semua cache, menonaktifkan kebijakan approval, atau mengubah izin seluruh folder.
- Jalankan build sungguhan dari root aplikasi target. Hentikan pengulangan identik jika kegagalan lingkungan yang sama tidak berubah; lanjutkan diagnosis yang dapat menghasilkan bukti baru dan laporkan kebutuhan tindakan pengguna bila diperlukan.
- M0 selesai hanya setelah aplikasi dasar dibangun/dipasang, SQLite bertahan setelah aplikasi dibuka ulang, serta API nyata berhasil dan kegagalan jaringan ditangani. Catat versi teruji di README; jangan mengisi nomor versi yang belum diuji.
- Jika perangkat tidak tersedia, selesaikan bagian yang dapat diuji dan nyatakan pemasangan/uji HP belum dilakukan. Ini tidak menghalangi pekerjaan dokumentasi tetapi tidak memenuhi M0 secara penuh.

### C. Implementasi satu tahap

- Pastikan M0 sudah memiliki bukti yang relevan untuk proyek baru. Kerjakan irisan fitur dari UI sampai penyimpanan, bukan banyak layar yang belum tersambung.
- Gunakan satu sumber aturan bisnis yang dipanggil kalkulator, jadwal, dan laporan. Lakukan validasi di form dan kembali di batas transaksi penyimpanan.
- Perubahan database mencakup versi/migrasi yang menjaga data, constraint, dan transaksi. Tidak melakukan reset agar skema baru terlihat bekerja.
- Uji ketukan ganda dan pengulangan permintaan; menonaktifkan tombol saja bukan jaminan idempotensi penyimpanan.
- Untuk pakan, baca PRD FR-03/04: harga snapshot, stok bersama, rate tersimpan, porsi tersisa, jam efektif besok, pembatalan, serta kondisi kebutuhan nol. Jangan memperbarui riwayat saat menghitung ulang rencana.
- Untuk populasi/panen, baca FR-05/06: sampling tidak mengurangi populasi, panen akhir memakai sisa yang dibaca dalam transaksi, dan siklus selesai tidak menerima aktivitas baru.
- Untuk laporan, baca FR-07: filter tanggal yang sama pada seluruh agregasi, transaksi batal dikecualikan, kondisi terkini diberi label terpisah.
- Untuk API, baca bagian 6: timeout, cache per lokasi, stempel waktu, respons lama, field null, dan atribusi. Panggilan API tidak boleh menjadi prasyarat transaksi lokal. Fixture digunakan dalam tes saja.
- Untuk backup, baca bagian 7: ekspor konsisten, pembatalan bukan sukses, validasi sebelum mutasi, rollback, dan pemuatan ulang UI setelah restore.
- Setelah menyimpan, pastikan halaman terkait menampilkan data terbaru. Uji navigasi kembali dan keyboard selain tombol sukses utama.

### D. Review dan verifikasi

- Review yang diminta sebagai analisis tidak otomatis mengizinkan mengedit kode. Laporkan temuan dengan pemicu, dampak, lokasi bukti, serta saran perbaikan.
- Cocokkan perubahan dengan PRD dan AT terkait. Jangan menyimpulkan semua 28 skenario lulus hanya dari beberapa tes yang relevan.
- Pada bug yang dapat direproduksi, tambahkan tes perilaku yang gagal sebelum perbaikan dan lulus setelahnya bila memungkinkan. Tes harus membuktikan hasil, bukan meniru implementasi atau mencocokkan nama fungsi.
- Jalankan `flutter analyze` dan tes yang relevan dari root aplikasi. Jalankan seluruh `flutter test` sebelum penyerahan tahap implementasi; jalankan `flutter build apk --debug` untuk perubahan native/dependency dan kandidat demo. Jika tahap hanya dokumentasi, cukup verifikasi dokumen.
- Setelah APK berhasil, verifikasi artifact berasal dari build saat ini; bedakan dengan APK lama. Uji pemasangan dan alur pada perangkat jika tersedia/diizinkan.
- Catat tes manual yang belum dilakukan. Tulis jumlah tes dari output nyata; perintah mulai berjalan atau exit sukses sebuah helper tidak membuktikan seluruh suite berhasil.
- Jika runner alternatif dipakai untuk diagnosis, beri label metode dan batasannya. Jangan mengganti bukti jalur standar sebelum penyerahan akhir aplikasi.

## Peta pemeriksaan cepat

Gunakan tabel untuk memilih bagian yang perlu dibaca; isi aturan dan ekspektasi berada di PRD.

| Area perubahan | Bagian PRD | Skenario awal yang relevan |
|---|---|---|
| Form/siklus/rate | 4, 5 FR-01/02/04 | AT-01–03, AT-15, AT-27 |
| Stok dan pemberian | 5 FR-03/04 | AT-04–10, AT-15–17, AT-25–26, AT-28 |
| Sampling/populasi/panen | 4, 5 FR-05/06 | AT-08–09, AT-11–17 |
| Laporan dan refresh UI | 5 FR-07, 9 | AT-18–19 |
| API cuaca | 6, 9 | AT-01, AT-20–22 |
| Backup/restore | 7, 8 | AT-23–25 |
| APK dan lingkungan | 10 | Bukti M0 dan pemasangan perangkat |

## Bukti dan serah terima

Laporkan ringkas dalam bahasa Indonesia: tahap/FR/AT yang ditangani, hasil perubahan, file utama, serta risiko atau keputusan tersisa. Gunakan status yang terpisah untuk:

- Analisis kode: perintah/metode, error/warning/lint.
- Tes otomatis: perintah/metode, jumlah lulus/gagal/terhalang, lokasi log jika disimpan.
- Build Android: perintah, status, path APK jika benar-benar dihasilkan.
- Perangkat: model dan Android/API level yang terverifikasi, status pemasangan dan skenario manual.

Status sah adalah lulus, gagal, terhalang lingkungan, atau belum dijalankan. Pilih hanya kategori yang relevan; jangan membuat laporan build untuk tugas dokumentasi. Kegagalan wajib yang belum terselesaikan tetap disebutkan, bukan disamarkan sebagai tahap selesai. Lanjutkan pekerjaan yang sudah diizinkan; jangan memperluas tahap atau mengirim/mempublikasikan hasil ke layanan luar tanpa otorisasi.
