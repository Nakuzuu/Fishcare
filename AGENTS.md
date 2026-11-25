# FishCare — Aturan kerja agen

## Tujuan dan acuan

FishCare adalah proyek mata kuliah Android untuk satu pengguna yang mengelola beberapa kolam dengan database lokal dan API cuaca. Target tim adalah akhir Oktober 2026; keandalan alur dan demonstrasi pada HP fisik lebih penting daripada menambah fitur.

- Sumber kebutuhan: [PRD FishCare Baru v0.1](docs/PRD_FishCare_Baru_v0.1.md).
- Panduan pelaksanaan: [skill fishcare-project](.agents/skills/fishcare-project/SKILL.md). Baca ketika menyusun rencana, mengimplementasikan, memperbaiki build, menguji, atau mereview FishCare.
- PRD menetapkan perilaku produk; file ini menetapkan aturan kerja; skill menjelaskan cara menjalankan tugas. Dokumen lama dan kode lama adalah referensi, bukan spesifikasi rancangan baru.
- Ikuti instruksi pengguna terbaru dan batas lingkungan. Jangan menggunakan file ini untuk membatalkan izin yang sudah diberikan atau memperluas tugas yang diminta.
- PRD masih bertanda draf. Gunakan sebagai baseline kerja sesuai permintaan pengguna, tetapi jangan menyatakan usulan bagian 14 telah disetujui satu per satu. Catat asumsi yang memengaruhi tugas. Tanyakan hanya keputusan yang benar-benar menghalangi pekerjaan atau mengubah perilaku secara material; lanjutkan pekerjaan independen yang sudah jelas.
- Jika pengguna mengubah kebutuhan, selaraskan bagian PRD dan skenario penerimaan yang terdampak. Jangan mengubah PRD hanya agar mengikuti implementasi yang keliru.

## Batas pekerjaan

- Android saja; satu pengguna; tanpa login, backend sendiri, atau sinkronisasi cloud. Pencatatan inti harus tetap berfungsi offline.
- Flutter dan SQLite adalah arah awal, bukan bukti kompatibilitas versi. Tetapkan versi melalui milestone M0 PRD bagian 10.
- Cuaca menambah informasi, tidak otomatis mengubah pakan atau dianggap pengukuran suhu air.
- Jangan menambahkan FCR, estimasi keuntungan, notifikasi background, AI diagnosis, atau platform lain hanya karena ada di proyek lama. Ikuti lingkup pengguna dan PRD yang berlaku.
- Untuk pembangunan ulang, gunakan direktori proyek baru dan application ID berbeda. Periksa target sebelum membuat/mengubah kode; jangan menjalankan scaffold yang menimpa proyek FishCare lama. Permintaan dokumentasi/review tidak mengizinkan implementasi baru.
- Jangan menghapus proyek, mereset database, mengganti backup pengguna, atau menimpa perubahan orang lain tanpa otorisasi untuk tindakan tersebut. Jangan membuat ulang isi data demi membuat tes lulus.
- Periksa perubahan yang ada sebelum mengedit. Jangan menjalankan beberapa agen yang menulis file sama bersamaan; gunakan delegasi hanya jika diizinkan oleh instruksi sesi.

## Aturan produk yang perlu dijaga

Detail, rumus, dan contoh tetap di PRD bagian 4–7; baca bagian terkait sebelum mengubahnya.

- Validasi stok/populasi dan penulisannya dilakukan dalam transaksi. Cegah saldo negatif, pengurangan melebihi populasi, siklus aktif ganda, serta transaksi ganda akibat ketukan/permintaan ulang.
- Rate tidak tersedia adalah data belum lengkap, bukan kebutuhan nol. Rate yang disimpan harus dipakai bersama oleh kalkulator dan jadwal.
- Simpan snapshot pemberian/panen. Harga, rate, atau sampling baru tidak boleh mengubah transaksi terdahulu.
- Bedakan jam jadwal yang berlaku besok dari porsi menunggu hari ini yang dihitung ulang. Jangan menduplikasi slot atau mendistribusikan ulang porsi yang sudah diberikan.
- Ringkasan transaksi mengikuti satu periode/filter yang konsisten; kondisi terkini dan seluruh siklus diberi label terpisah.
- Cuaca gagal tidak boleh menghalangi data lokal; status cache, lokasi, dan waktu data harus jujur. Dummy hanya untuk tes terisolasi, bukan pengganti API nyata dalam aplikasi.
- Backup harus konsisten; restore yang gagal mempertahankan data lama. Batalkan pemilih file bukan backup berhasil.

## Pelaksanaan dan lingkungan

- Kerjakan satu tahap yang diminta sampai selesai. M0 harus terbukti sebelum implementasi penuh fitur budidaya baru; perencanaan, desain, dan diagnosis tidak perlu menunggu M0.
- Gunakan struktur sederhana: UI/state, aturan bisnis, repository, lalu SQLite/klien API. Jangan menggandakan rumus pada layar yang berbeda.
- Batasi dependency pada kebutuhan nyata; periksa dokumentasi resmi dan persyaratan Android sebelum memilih/mengubah versi. Simpan lockfile dan catat versi lingkungan yang berhasil.
- Jangan mengedit Pub Cache atau SDK global sebagai solusi permanen, menghapus file lock Gradle sembarangan, atau menaikkan semua paket sekaligus.
- Bila akses jaringan, proxy, SDK, atau sandbox gagal, identifikasi penyebab dari log. Gunakan jalur izin yang tersedia; jangan mengakali penolakan approval atau membuat salinan SDK untuk menggantikan bukti build standar.
- Laptop RAM 8 GB: hindari banyak build/tes berat bersamaan; utamakan HP fisik. Verifikasi perangkat dan API level aktual, jangan mengasumsikan angka 16.3.0 adalah API level Android.
- Gunakan Git jika tersedia untuk meninjau perubahan; commit, push, dan publikasi tetap mengikuti otorisasi pengguna. Jangan mengasumsikan repo atau remote sudah ada.

## Pengujian dan definisi selesai

- Petakan perubahan ke ID FR dan AT pada PRD. Pilih tes yang menguji perilaku: rumus, validasi, transaksi, rollback, state UI, dan integrasi yang benar-benar terdampak.
- Untuk perbaikan bug, tunjukkan kasus gagal dan hasil setelah perbaikan jika dapat direproduksi. Jangan menghapus tes gagal atau melemahkan assertion untuk menyembunyikan masalah.
- Jalur normal: `flutter analyze`, `flutter test`, `flutter build apk --debug` dari root aplikasi target. Jalankan yang relevan selama pengembangan; seluruh suite dan APK wajib sebelum penyerahan kandidat demo.
- Perubahan Gradle/plugin/manifest wajib diverifikasi dengan build Android. Tes Dart/Flutter tidak menggantikan build APK, dan build APK tidak menggantikan pemasangan serta uji di HP.
- Harness alternatif hanya bukti tambahan dan harus diberi label; jangan menyatakannya sebagai keberhasilan `flutter test` standar.
- Perubahan dokumentasi/skill saja tidak memerlukan build aplikasi. Periksa tautan, konsistensi aturan, serta format skill.
- Status hasil: lulus, gagal, terhalang lingkungan, atau belum dijalankan. Tahap dengan pemeriksaan wajib yang belum selesai dilaporkan belum terverifikasi; jangan menyebut seluruh aplikasi bebas bug.

## Komunikasi dan serah terima

Gunakan bahasa Indonesia yang mudah dipahami. Jelaskan perubahan dan dampaknya, bukan hanya daftar file. Jangan meminta persetujuan berulang untuk pekerjaan yang sudah diizinkan.

Laporan tugas implementasi mencakup:

1. Tahap dan kebutuhan FR/AT yang ditangani.
2. Perubahan utama dan file yang terdampak.
3. Hasil terpisah untuk analisis, tes, build APK, pemasangan, serta uji manual; sebutkan perintah dan lokasi log/artifact bila tersedia.
4. Masalah atau keputusan tersisa dan langkah berikutnya.

Tentukan keluaran sesuai tugas: review menghasilkan temuan berbukti; perencanaan menghasilkan rancangan; implementasi menghasilkan perubahan dan verifikasi. Jangan memulai tahap berikutnya di luar tugas yang diberikan hanya karena tahap sekarang selesai.
