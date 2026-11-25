# PRD FishCare — Rancangan Baru

Versi: 0.1 • Tanggal: 13 Oktober 2026 • Status: draf untuk ditinjau

Dokumen ini menetapkan kebutuhan produk dan kriteria penerimaan, bukan pernyataan bahwa aplikasi sudah dibangun atau diuji. Kebutuhan pengguna yang sudah dikonfirmasi dibedakan dari usulan pembatasan versi pertama. Jika disetujui, dokumen ini menjadi acuan implementasi baru; kode dan rancangan lama hanya menjadi referensi. Jangan menghapus proyek lama atau menimpa database pengguna sebagai bagian dari pembangunan ulang.

## 1. Tujuan dan konteks

FishCare membantu satu pengguna mencatat budidaya pada beberapa kolam: mengetahui populasi, menghitung dan mencatat pakan, menjaga catatan stok, serta melihat hasil panen. Informasi cuaca dari API pihak ketiga membantu pengguna mengetahui kondisi cuaca sekitar lokasi budidaya.

Proyek ditujukan untuk mata kuliah Android, dikerjakan enam mahasiswa dengan bantuan AI, dan ditargetkan selesai akhir Oktober 2026. Keberhasilan dinilai dari alur yang benar dan dapat didemonstrasikan pada HP fisik, bukan banyaknya fitur atau jumlah tes saja.

### Kebutuhan yang telah dikonfirmasi

- Android saja; tidak ada aplikasi web atau desktop dalam lingkup ini.
- Satu pengguna, beberapa kolam, database lokal di HP; tidak memerlukan login atau server sendiri.
- Menggunakan API pihak ketiga untuk informasi cuaca.
- Perangkat utama: Infinix Note 60, RAM 8 GB, penyimpanan 256 GB, menurut informasi pengguna.
- Laptop pengembangan: RAM 8 GB, SSD 512 GB. Utamakan HP fisik untuk pengujian.
- Versi sistem yang dilaporkan adalah 16.3.0. Versi Android dan API level sebenarnya belum diverifikasi; angka ini tidak boleh langsung dijadikan target kompatibilitas.
- Tim belum berpengalaman dengan Flutter maupun Kotlin. Instruksi implementasi, dokumentasi, dan hasil pengujian perlu mudah diperiksa.

### Usulan dasar versi pertama

- Flutter sebagai pilihan awal; penyimpanan SQLite lokal. Versi konkret dan plugin baru ditetapkan setelah pembuktian build pada perangkat.
- Pencatatan inti tersedia offline; hanya pencarian lokasi dan cuaca yang memerlukan internet.
- Feeding rate diisi manual oleh pengguna. Tidak menyediakan angka acuan budidaya yang belum memiliki sumber terverifikasi.
- Satu jenis ikan dan satu jenis pakan per siklus. Pergantian jenis pakan di tengah siklus ditunda.
- Entri operasional untuk hari ini saja. Impor riwayat dan pengisian transaksi mundur ditunda untuk menghindari perhitungan populasi serta stok historis yang ambigu.
- Lokasi cuaca ditetapkan satu kali untuk seluruh kolam dalam versi pertama. Kolam diasumsikan berada di area budidaya yang sama.

## 2. Ruang lingkup dan ukuran keberhasilan

### Fitur wajib

| ID | Fitur | Hasil yang dibutuhkan pengguna |
|---|---|---|
| FR-01 | Kolam | Membuat, mengubah identitas, mengarsipkan, dan melihat riwayat kolam |
| FR-02 | Siklus | Memulai budidaya dan mengetahui siklus yang sedang aktif |
| FR-03 | Pakan dan stok | Mencatat pakan, stok masuk, harga per kg, dan riwayat pergerakan stok |
| FR-04 | Kebutuhan dan pemberian pakan | Menghitung kebutuhan harian, membagi porsi, mencatat jumlah aktual, dan mengurangi stok dengan benar |
| FR-05 | Sampling dan populasi | Mencatat bobot rata-rata, kematian, dan panen parsial |
| FR-06 | Panen akhir | Menutup siklus dengan populasi serta hasil panen yang valid |
| FR-07 | Laporan | Menampilkan pemakaian pakan, biaya pakan, kematian, jumlah panen, dan nilai panen berdasarkan periode yang sama |
| FR-08 | Cuaca | Menampilkan data API, lokasi, waktu data, waktu pengambilan, dan status offline/gagal |
| FR-09 | Backup dan restore | Menyimpan salinan data ke file serta memulihkannya tanpa merusak data lama saat proses gagal |

### Di luar versi pertama — usulan pembatasan

Login, banyak pengguna, sinkronisasi cloud, pembayaran, IoT, AI diagnosis, rekomendasi pakan otomatis dari cuaca, notifikasi terjadwal/background, prediksi pertumbuhan, estimasi keuntungan, FCR, ekspor PDF laporan, multi-lokasi cuaca, serta migrasi otomatis backup aplikasi lama.

FCR dan keuntungan ditunda karena perlu definisi dan kelengkapan data tambahan. Nilai panen serta biaya pakan tetap tersedia secara terpisah. Penambahan fitur di luar lingkup harus memperbarui PRD, alur, data, dan pengujiannya terlebih dahulu.

### Kriteria produk selesai

1. APK kandidat presentasi berhasil dibangun, dipasang, dan menjalankan alur utama pada HP target.
2. Tidak ada masalah terbuka yang menyebabkan crash, aplikasi tidak dapat ditekan, hilangnya data, stok/populasi negatif, transaksi ganda, atau perhitungan salah pada skenario penerimaan.
3. Seluruh fitur wajib dapat didemonstrasikan; cuaca menggunakan API nyata saat online.
4. Pencatatan inti tetap berfungsi dalam mode pesawat, termasuk setelah aplikasi ditutup dan dibuka.
5. Analisis kode tidak memiliki error/warning. Lint yang tersisa dijelaskan; seluruh tes standar proyek lulus.
6. README memuat versi lingkungan, cara build, cara memasang APK, batasan fitur, dan skenario demo.
7. Klaim kompatibilitas dibatasi pada versi/perangkat yang benar-benar diuji.

## 3. Pengguna dan alur utama

Pengguna utama adalah pengelola budidaya skala kecil yang mencatat aktivitas sendiri. Ia tidak harus memahami istilah pemrograman atau mekanisme database.

Alur awal: buka aplikasi → buat data pakan dan stok → buat kolam → mulai siklus → periksa kebutuhan pakan → catat pemberian → lakukan sampling/pencatatan populasi → panen → lihat laporan.

Lokasi cuaca dapat diatur setelah masuk aplikasi dan tidak menghalangi pembuatan kolam. Tidak ada data contoh yang otomatis masuk ke database pengguna.

### Struktur navigasi usulan

- **Beranda:** header FishCare → kartu cuaca → pakan hari ini → kolam aktif → ringkasan lain yang relevan. Urutan ini diputuskan pengguna pada revisi UI 20 Oktober 2026; cuaca tetap tidak menjadi prasyarat navigasi atau pencatatan lokal.
- **Kolam:** daftar kolam; detail berisi siklus aktif, populasi, bobot, rate, sampling, dan panen.
- **Pakan:** dua bagian, Pemberian Hari Ini dan Stok Pakan.
- **Laporan:** filter tanggal dan kolam, ringkasan serta daftar transaksi pendukung.
- **Pengaturan:** melalui ikon di Beranda; lokasi, zona waktu, backup, restore, dan tentang aplikasi.

Jumlah langkah untuk kegiatan harian harus pendek. Form menampilkan satuan di samping input dan kesalahan di dekat field. Pengguna melihat ringkasan sebelum menyimpan transaksi penting atau menutup siklus.

## 4. Aturan data dan validasi bersama

### Angka, tanggal, dan status

- Jumlah ikan dan pakan aktual dalam gram adalah bilangan bulat; bobot rata-rata ikan menerima maksimal dua desimal gram; rate menerima maksimal dua desimal persen.
- Input angka mentah tidak menerima pemisah ribuan. Desimal boleh koma atau titik. Contoh ditampilkan: `1500` untuk seribu lima ratus, `12,5` untuk desimal. Format seperti `1.500` ditolak sebagai ambigu pada field desimal dan pada field bilangan bulat, bukan ditebak menjadi 1,5 atau 1500.
- Tolak angka negatif, NaN, infinity, nilai di luar batas penyimpanan, dan hasil perkalian yang melampaui kapasitas angka. Field wajib tidak boleh diganti diam-diam menjadi nol.
- Nilai uang berupa rupiah bulat; simpan perhitungan transaksi dengan pembulatan yang konsisten. Jangan membulatkan biomassa sebelum menghitung kebutuhan harian.
- Keputusan pengguna pada tahap M2 (13 Oktober 2026): pembulatan nilai nonnegatif menggunakan **half-up**, yaitu tepat setengah dibulatkan naik. Berlaku pada kebutuhan pakan, biaya pemberian, dan nilai panen. Bobot/rate tetap maksimal dua desimal; gunakan integer berskala dan aritmetika presisi, tanpa pembulatan biomassa antara. Keputusan ini menyelesaikan aturan pembulatan O-02; bukan persetujuan atas seluruh usulan bagian 14.
- Tanggal kegiatan disimpan sebagai tanggal usaha, timestamp sebagai waktu kejadian. Zona waktu usaha dipilih saat pengaturan awal (default zona perangkat); dikunci setelah transaksi pertama pada versi pertama.
- Entri siklus, sampling, kematian, panen, stok, dan pemberian baru memakai tanggal usaha hari ini. Tidak menerima tanggal masa depan atau sebelum tebar. Tanggal historis hanya dibaca.
- Hari berganti harus memuat tanggal baru ketika aplikasi dibuka kembali atau aktif dari background; tidak memerlukan proses background agar benar.
- Kolam aktif mempunyai maksimal satu siklus aktif. Siklus selesai tidak menerima kegiatan baru.
- Validasi kritis dilakukan pada lapisan penyimpanan dalam transaksi, selain validasi form. Pembacaan stok/populasi dan penulisan perubahan harus atomik.
- Tombol simpan dinonaktifkan saat menyimpan. Pengulangan permintaan atau ketukan ganda tidak boleh menggandakan transaksi.

### Data lama dan koreksi

- Riwayat tidak dihapus permanen melalui UI. Koreksi menyimpan hubungan ke transaksi asal serta alasan.
- Keputusan pengguna M4 menggantikan batas pembatalan M3: kandidat adalah **kegiatan sah terakhir di antara pemberian, sampling, kematian, dan panen parsial**, dalam siklus aktif pada tanggal usaha hari ini, dengan alasan wajib. Urutan memakai sequence commit bersama, bukan timestamp HP. Kegiatan lebih lama yang memiliki kegiatan operasional lanjutan ditolak dengan alasan jelas; validasi diulang dalam transaksi. Rate, perubahan jam, dan Lewati bukan penghalang. Pembatalan ganda ditolak; retry ID pembatalan yang sudah commit mengembalikan hasil lama. Setelah pembatalan, kegiatan sah terakhir berikutnya boleh ditinjau dengan aturan yang sama. Panen akhir dan siklus selesai tidak dapat dibatalkan.
- Pembatalan pemberian pakan memulihkan stok tepat sebesar jumlah aktual yang dahulu dipotong. Nilai biaya dan snapshot transaksi lama tidak ditulis ulang; transaksi batal dikecualikan dari agregasi laporan.
- Pembatalan kematian/panen parsial terakhir memulihkan populasi; pembatalan sampling terakhir memulihkan bobot sebelumnya. Seluruh pembatalan memicu perhitungan ulang porsi yang belum diberikan.
- Data awal tetap utuh. Kondisi terkini memakai populasi/bobot terbaru yang diperbarui atomik dengan kegiatan dan jejak kondisi sebelum/sesudah. Pembatalan tidak membatalkan rate/jam/Lewati atau mengubah snapshot pemberian/panen lama.
- Catatan siklus selesai, pemberian hari sebelumnya, dan penutupan siklus tidak dapat dibatalkan pada tahap ini. Stok masuk tidak dihapus/dibatalkan; koreksi beralasan diperbolehkan sesuai FR-03 dan tetap mempertahankan catatan asli.

### Pemulihan ID tindakan — keputusan pengguna M3

- Simpan ID tindakan acak yang stabil, jenis, target, input kanonik, dan tanggal usaha ke database sebagai **niat tersimpan** sebelum transaksi bisnis dijalankan. Jika niat belum berhasil disimpan, transaksi bisnis tidak boleh berjalan. Input/ID niat yang sudah tersimpan tidak ditulis ulang untuk retry.
- Dalam transaksi bisnis, periksa hasil berdasarkan ID yang sama terlebih dahulu. ID yang sudah commit mengembalikan hasil lama tanpa menulis ulang ledger/aktivitas. ID sama dengan input berbeda ditolak. Hasil commit dan perubahan bisnis ditulis atomik; kegagalan validasi bisnis menandai ditolak tanpa perubahan bisnis. Error teknis mempertahankan niat belum pasti untuk pemeriksaan ulang.
- Setelah restart, baca niat yang belum mempunyai hasil final; periksa hasil commit berdasarkan ID yang sama sebelum menawarkan retry. Tidak menjalankan ulang otomatis atau membuat ID baru otomatis. Pengguna dapat retry ID yang sama setelah status diperiksa, atau menutup niat yang terbukti belum commit; kegiatan baru yang dikonfirmasi pengguna merupakan niat baru.
- Crash sebelum niat commit: tidak ada transaksi bisnis. Crash setelah niat commit sebelum transaksi: niat dapat dipulihkan. Crash saat transaksi: perubahan utuh atau rollback. Crash setelah commit sebelum UI menerima hasil: pemeriksaan ID menemukan hasil commit, tanpa pemberian/pengurangan stok ganda.

## 5. Ketentuan fitur inti

### FR-01 dan FR-02 — Kolam dan siklus

- Nama kolam wajib unik tanpa membedakan kapitalisasi, setelah spasi tepi dibuang. Catatan dan ukuran kolam opsional; ukuran tidak digunakan dalam rumus pakan.
- Kolam dengan siklus aktif tidak bisa diarsipkan. Pengarsipan mempertahankan laporan dan riwayat.
- Mulai siklus memerlukan jenis ikan (label pengguna), jumlah awal > 0, bobot awal > 0, pakan yang tersedia pada master, feeding rate > 0 sampai 100%, serta 1–6 jam pemberian unik.
- Rentang rate adalah batas validasi teknis, bukan rekomendasi budidaya. UI menjelaskan rate harus mengikuti acuan pengguna/dosen.
- Rate disimpan pada siklus dan digunakan oleh kalkulator serta jadwal yang sama. Tidak ada rate manual yang hanya berlaku sementara di layar kalkulator.
- Jumlah, bobot awal, jenis ikan, dan pakan dikunci setelah mulai siklus. Perubahan bobot melalui sampling; perubahan populasi melalui catatan pengurangan.
- Rate boleh diubah pada siklus aktif dan langsung memengaruhi sisa porsi hari ini. Perubahannya dicatat untuk penelusuran.
- Siklus dan template jam tersimpan sekaligus, atau seluruh operasi dibatalkan jika gagal.

### FR-03 — Pakan, stok, dan biaya

- Setiap pakan mempunyai nama unik, stok gram, harga pencatatan rupiah/kg, serta status arsip.
- Stok awal dan setiap penambahan dicatat sebagai stok masuk dengan jumlah > 0. Stok tidak diedit dengan menimpa total secara langsung.
- Keputusan pengguna M3: koreksi stok masuk menyimpan referensi asal, jumlah efektif lama, jumlah baru, alasan wajib, timestamp/tanggal koreksi hari ini, dan pergerakan selisih `baru − lama`. Jumlah baru adalah gram bulat nonnegatif; nol berarti koreksi jumlah masuk menjadi nol, bukan menghapus asal. Koreksi dapat merujuk stok masuk terdahulu, dengan tanggal asal tetap. Koreksi ditolak jika jumlah efektif negatif, saldo bersama menjadi negatif, atau jumlah lama yang ditinjau sudah berubah. Koreksi tanpa selisih ditolak sebagai tidak ada perubahan. Koreksi berulang mengacu jumlah efektif terbaru; ledger asli dan seluruh koreksi tetap tersedia.
- Harga pencatatan wajib > 0 sebelum pakan dapat dipakai. Pembaruan harga berlaku untuk pemberian berikutnya.
- Usulan metode sederhana: biaya pemberian memakai harga pencatatan saat pemberian, bukan FIFO atau rata-rata harga pembelian. UI menyebutnya **Biaya pakan berdasarkan harga tercatat**; angka ini bukan laporan akuntansi pembelian atau keuntungan bersih.
- Stok dipakai bersama oleh seluruh kolam yang menggunakan pakan tersebut.
- Jika stok kurang dari porsi aktual, penyimpanan ditolak seluruhnya. Tawarkan jumlah aktual lebih kecil atau pencatatan stok masuk, tanpa otomatis menganggap kekurangan sebagai pakan yang telah diberikan.
- Pakan yang digunakan siklus aktif tidak dapat diarsipkan; perubahan nama tidak menghilangkan hubungan riwayat.

### FR-04 — Perhitungan dan kegiatan pakan

Rumus dasar:

```text
populasi = jumlah awal − kematian sah − panen parsial sah − panen akhir sah
biomassa gram = populasi × bobot rata-rata terakhir
kebutuhan harian gram = pembulatan terdekat(biomassa gram × rate / 100)
biaya pemberian rupiah = pembulatan terdekat(pakan aktual gram × snapshot harga per kg / 1000)
```

Jika belum ada sampling, gunakan bobot awal. Data bobot/rate yang tidak tersedia atau tidak valid menghasilkan status **Belum bisa dihitung**, bukan kebutuhan nol. Pemberian dinonaktifkan sampai data valid.

- Catatan harian unik berdasarkan siklus, tanggal, dan jam; pembukaan halaman berulang tidak membuat duplikat.
- Porsi dibagi merata dalam gram bulat; kelebihan gram dibagikan mulai jam paling awal. Contoh 301 gram pada dua slot menjadi 151 dan 150 gram.
- Snapshot jam hari ini tetap. Perubahan jam disimpan sebagai jadwal berlaku mulai besok; perubahan berulang hari yang sama mengganti jadwal besok. Aturan tetap berlaku walaupun halaman pakan hari ini belum pernah dibuka.
- Saat hari baru, gunakan template yang efektif hari tersebut. Jangan otomatis mencatat pemberian pada hari aplikasi tidak dibuka.
- Status slot: menunggu, diberikan, dilewati; pembatalan pemberian kembali menjadi menunggu dengan riwayat pembatalan tetap disimpan. Hari lampau tidak otomatis dianggap sudah diberikan.
- Porsi aktual boleh berbeda dari rencana, harus > 0 dan stok mencukupi. Tampilkan konfirmasi jika lebih besar daripada sisa kebutuhan. Porsi nol tidak dicatat sebagai pemberian; gunakan Lewati.
- Setiap pemberian menyimpan porsi aktual, harga, biaya, bobot/populasi atau biomassa, rate, timestamp, dan pakan yang dipakai saat itu. Perubahan harga, sampling, atau rate berikutnya tidak mengubah snapshot.

**Aturan setelah perubahan bobot/populasi/rate atau pemberian aktual:**

```text
total aktual hari ini = jumlah porsi aktual sah hari ini
sisa kebutuhan = maksimum(0, kebutuhan harian terbaru − total aktual hari ini)
porsi baru = sisa kebutuhan dibagi pada slot yang masih menunggu hari ini
```

- Distribusi menggunakan slot hari ini yang tersimpan, bukan template besok. Slot diberikan dan dilewati tidak diubah.
- Pada M3, Lewati memicu pembagian ulang sisa ke slot yang masih menunggu; tidak membuat pemberian nol atau stok keluar. Jika semua slot selesai/dilewati dan masih ada sisa, tampilkan Sisa belum diberikan tanpa slot tambahan.
- UI membedakan Kebutuhan terbaru, Sudah diberikan, dan Sisa kebutuhan. Jika aktual melebihi kebutuhan terbaru, tampilkan kelebihannya; jangan menarik kembali stok atau mengubah catatan lama.
- Jika semua slot selesai/dilewati tetapi masih ada sisa, tampilkan **Sisa belum diberikan**. Versi pertama tidak menambah pemberian di luar slot secara otomatis.
- Slot menunggu yang menjadi 0 gram menampilkan **Tidak ada sisa kebutuhan** dan tombol Berikan nonaktif. Jangan membuat transaksi nol.
- Contoh: 100 ikan × 100 g × 3% = 300 g/hari. Dua slot: 150 + 150. Setelah 150 g diberikan lalu bobot berubah menjadi 120 g, kebutuhan baru 360 g, sehingga slot menunggu menjadi 210 g. Transaksi 150 g tetap utuh.

### FR-05 dan FR-06 — Sampling, kematian, panen

- Sampling mencatat jumlah ikan sampel dan bobot rata-rata > 0. Jumlah sampel tidak melebihi populasi. Sampling tidak mengurangi populasi.
- Maksimal satu sampling sah per siklus per tanggal; bobot baru hanya berlaku untuk rencana yang belum diberikan.
- Kematian dan panen parsial: jumlah harus bilangan bulat > 0 dan tidak melebihi populasi saat transaksi. Panen parsial menyisakan minimal satu ikan; gunakan panen akhir untuk seluruh sisa.
- Kematian terakhir boleh membuat populasi nol. Jadwal berhenti menawarkan pemberian; pengguna dapat menutup siklus tanpa panen.
- Panen membutuhkan jumlah, bobot rata-rata panen > 0, dan harga jual/kg > 0. Bobot historis panen wajib disimpan; tidak mengambil bobot sampling masa depan sebagai pengganti.
- Nilai panen = pembulatan terdekat(jumlah × bobot rata-rata gram × harga jual/kg / 1000). Simpan snapshot input dan nilainya.
- Panen akhir memakai seluruh populasi tersisa, dihitung ulang dalam transaksi; field jumlah tidak dapat diedit. Selisih populasi harus diselesaikan lewat pencatatan kematian/panen parsial yang sah terlebih dahulu.
- Sebelum penutupan, tampilkan jumlah, biomassa panen, harga, dan nilai panen untuk dikonfirmasi.
- Jika populasi nol, izinkan penutupan tanpa catatan panen dan tanpa pendapatan rekaan.
- Penutupan, panen akhir bila ada, dan penghentian slot menunggu dilakukan atomik. Riwayat pemberian tetap tersedia. Ketukan penutupan berulang tidak membuat panen ganda.
- Keputusan teknis M4: penutupan menyimpan ID tindakan, menghentikan semua slot menunggu yang sudah tersimpan, dan mencegah pembuatan slot baru pada siklus selesai. Jika populasi berubah sejak ringkasan panen akhir dikonfirmasi, tolak utuh dan minta tinjau ulang; jumlah panen tetap berasal dari populasi terbaru di transaksi, bukan input pengguna. Pemulihan ID M3 berlaku pada seluruh kegiatan M4.

### FR-07 — Laporan

- Filter tanggal mulai/akhir inklusif dan satu kolam atau semua kolam. Tanggal mulai tidak boleh setelah akhir.
- Seluruh angka pada ringkasan periode memakai rentang yang sama: gram pakan, biaya pakan, ikan mati, ikan panen, serta nilai panen. Panen parsial dan akhir sama-sama masuk pada tanggalnya.
- Kartu populasi/bobot/status adalah **Kondisi saat ini**, terpisah dari transaksi periode. Ringkasan seluruh siklus diberi label tersendiri.
- Biaya pakan dan nilai panen periode adalah penjumlahan snapshot per transaksi; jangan memakai harga/bobot/rate terkini atau membulatkan ulang hasil gabungan. Panen parsial dan akhir sama-sama dihitung pada tanggal usaha transaksinya.
- Transaksi batal dikecualikan dari total, tetapi tetap dapat dilihat dalam riwayat sebagai batal.
- Tidak ada label keuntungan bersih atau FCR pada versi pertama. Jangan menyamakan nilai panen dikurangi biaya pakan dengan keuntungan bersih.
- Pengguna dapat membuka transaksi pendukung dari ringkasan untuk menelusuri asal angka.
- Setiap penyimpanan yang berhasil membuat Beranda, detail, Pakan, dan Laporan memuat data terbaru saat ditampilkan. Tidak perlu menutup aplikasi untuk menyegarkan data.
- Keputusan pengguna M5: filter mencakup kolam arsip. Daftar pendukung dan detail mempertahankan tanggal mulai/akhir serta kolam dari ringkasan; transaksi batal tetap terlihat berlabel dan tidak masuk total. Keadaan kosong/loading/gagal tersedia; hasil/error pembacaan filter lama diabaikan setelah filter berubah. Beranda menampilkan transaksi hari ini dengan tanggal usaha yang jelas. Kondisi saat ini dan Seluruh siklus mengikuti kolam terpilih tetapi tidak dibatasi periode, dan diberi label terpisah. Tidak menghitung selisih pendapatan/biaya sebagai keuntungan bersih.

## 6. FR-08 — API cuaca

### Integrasi yang diusulkan

Open-Meteo Forecast API dan layanan pencarian lokasi Open-Meteo. Dokumentasi dan ketentuan akses diperiksa kembali ketika implementasi; akses nonkomersial tetap mengikuti batas layanan dan atribusinya.

- Pengguna mencari kota/kecamatan lalu memilih hasil dengan wilayah administratif agar nama lokasi tidak ambigu. Simpan nama dan koordinat; tidak memerlukan akses lokasi latar belakang.
- **Keputusan pengguna 14 Oktober 2026 — lokasi HP atas tindakan pengguna:** tombol **Ambil lokasi saat ini** meminta izin foreground jika diperlukan dan mengambil koordinat sekali. Tidak mengambil lokasi saat aplikasi dibuka, tidak melacak perpindahan, tidak meminta izin background. Lokasi perkiraan dapat dipakai dan diberi label; tidak meminta peningkatan ke presisi secara otomatis.
- Hasil HP maupun pilihan manual adalah **calon lokasi**, belum mengganti pengaturan. Pengguna mengonfirmasi **Simpan sebagai lokasi usaha**. Satu lokasi tersimpan dipakai untuk cuaca seluruh kolam; pembaruan cuaca selalu memakai koordinat tersimpan tanpa mengambil ulang HP.
- GPS/layanan lokasi mati, izin ditolak, koordinat gagal/timeout: jelaskan penyebab, sediakan coba lagi atau pilih manual. Batal/kembali/keluar saat pengambilan mengabaikan hasil terlambat dan tidak menyimpan calon. Lokasi lama tetap sampai pengganti dikonfirmasi dan tersimpan atomik; kegagalan simpan mempertahankan data lama. Jika hasil commit teknis belum pasti, periksa lokasi tersimpan sebelum menawarkan retry.
- Pencarian dikerjakan setelah pengguna menekan Cari atau setelah jeda pengetikan; permintaan lama tidak boleh menimpa hasil pencarian terbaru.
- Kartu cuaca menampilkan kondisi cuaca, suhu udara, dan peluang hujan hari ini jika tersedia. Peluang hujan harian diberi label sebagai prakiraan hari ini, bukan kondisi saat ini.
- Simpan timestamp data dari penyedia, waktu pengambilan berhasil, koordinat, dan satuan. Tampilkan atribusi/link Open-Meteo.
- Gunakan label **Cuaca terkini dan prakiraan**. Data model bukan pembacaan sensor kolam; jangan menjanjikan pengamatan real-time di kolam.
- Revisi UI 20 Oktober 2026: kartu cuaca berada tepat setelah header Beranda. Nama lokasi, suhu udara, ikon kondisi offline, kondisi dan prakiraan hujan menjadi hierarki utama; status cache, waktu penyedia/pengambilan dan atribusi tetap tersedia. Waktu diformat ramah dengan zona yang dapat dibuktikan dari respons; bila metadata zona tidak tersedia, jangan menebak zona lokasi. Koordinat lengkap dan timestamp asli tersedia pada Detail cuaca. Jangan mengarang nama kota untuk “Lokasi HP”, menambahkan metrik di luar PRD, atau menyebut prakiraan cache tanggal lama sebagai hari ini.
- Cuaca tidak mengubah feeding rate, porsi, atau rekomendasi kesehatan ikan secara otomatis.

### Perilaku jaringan

- Pembaruan saat Beranda dibuka jika cache lokasi berumur lebih dari 30 menit; tombol Muat ulang tersedia. Tidak melakukan polling background.
- Hanya satu permintaan aktif per lokasi; tombol refresh dibatasi minimal 60 detik setelah percobaan sebelumnya.
- Batas tunggu total permintaan 10 detik, lalu hentikan loading dan tampilkan Coba lagi. Jangan menghalangi navigasi atau pencatatan lokal.
- Tanpa cache dan offline/gagal: **Cuaca belum tersedia**. Dengan cache: tampilkan data terakhir beserta waktu; jika pembaruan gagal, label **Data tersimpan — pembaruan gagal/offline**. Data berumur lebih dari 30 menit tidak dilabeli baru diperbarui.
- Nilai null/field hilang ditampilkan sebagai tidak tersedia, bukan nol. Respons rusak tidak mengganti cache yang masih valid.
- Pergantian lokasi membatalkan/mengabaikan respons lokasi lama. Cache lama tidak ditampilkan sebagai cuaca lokasi baru.
- Lokasi belum dipilih tidak boleh menghasilkan cuaca kota contoh secara otomatis. Demonstrasi API memerlukan setidaknya satu permintaan nyata yang berhasil.

Referensi: [Forecast API](https://open-meteo.com/en/docs), [Geocoding API](https://open-meteo.com/en/docs/geocoding-api), [Ketentuan layanan](https://open-meteo.com/en/terms).

## 7. FR-09 — Backup dan pemulihan

- Format file mempunyai versi skema, waktu ekspor, zona waktu usaha, dan seluruh data yang diperlukan untuk memulihkan hubungan serta riwayat pembatalan.
- Ekspor membaca database dalam satu snapshot konsisten. Status backup hanya berubah setelah penyimpanan file berhasil dikonfirmasi; pembatalan pemilih file tidak dihitung sukses. Status awal: **Belum pernah backup**.
- Restore menggantikan seluruh data, bukan menggabungkannya. Pengguna mendapat ringkasan isi dan konfirmasi penggantian.
- Sebelum mengganti data, buat salinan pemulihan lokal. Jika pembuatan salinan gagal, jangan lanjutkan restore.
- Validasi versi, tabel wajib, tipe angka, relasi, keunikan, status, tanggal, snapshot, populasi dan saldo stok. Versi terlalu baru atau format backup FishCare lama yang belum didukung ditolak dengan pesan jelas.
- Terapkan restore dalam satu transaksi. Gagal di tahap apa pun harus meninggalkan data lama utuh. Jangan menafsirkan tabel hilang sebagai tabel kosong.
- Setelah sukses, kosongkan data UI yang tersimpan dalam memori lalu muat ulang seluruh halaman. Cache cuaca tidak wajib ikut backup; ambil ulang saat jaringan tersedia.
- Pengguna diberi penjelasan bahwa uninstall/clear data dapat menghapus data lokal; file backup perlu disimpan di luar penyimpanan privat aplikasi.

## 8. Kerangka data dan arsitektur

Model berikut adalah acuan konseptual; SQL, indeks, dan diagram relasi diturunkan pada dokumen teknis setelah PRD disetujui.

| Entitas | Isi penting |
|---|---|
| Kolam | Identitas, nama unik, catatan, status arsip |
| Siklus | Kolam, jenis ikan, populasi/bobot awal, pakan, tanggal/status |
| Riwayat rate | Siklus, rate, waktu berlaku; rate terkini dapat ditelusuri |
| Pakan | Identitas, nama, harga pencatatan, status arsip |
| Pergerakan stok | Pakan, gram masuk/keluar, jenis, waktu, referensi transaksi/pembatalan |
| Versi jadwal | Siklus, tanggal mulai berlaku, daftar jam unik |
| Slot harian | Siklus, tanggal, jam, porsi rencana, status; unik per slot |
| Pemberian | Slot, aktual, snapshot perhitungan/harga/biaya, status batal, waktu |
| Sampling | Siklus, jumlah sampel, rata-rata bobot, tanggal, status batal |
| Pengurangan/panen | Siklus, jenis, jumlah, snapshot panen, tanggal, status batal |
| Pengaturan | Zona waktu, lokasi cuaca, metadata backup |
| Cache cuaca | Lokasi, nilai terstruktur, timestamp data dan pengambilan |

- Saldo stok dapat dihitung dari pergerakan sah; jika disimpan sebagai cache, keduanya harus berubah dalam transaksi yang sama dan dapat direkonsiliasi.
- Struktur kode sederhana: layar/state UI → aturan bisnis → repository → SQLite atau klien cuaca. Jangan menaruh rumus yang berbeda pada beberapa layar.
- Data lokal adalah sumber utama untuk pencatatan; kegagalan API tidak mengubah transaksi budidaya.
- Nama/status tersimpan konsisten, tidak mencampur bentuk kapitalisasi. Skema database memiliki versi dan jalur migrasi sejak awal.
- Aset dasar serta font dibundel agar aplikasi tetap terbaca offline. Batasi plugin pada kebutuhan yang benar-benar digunakan.
- Jangan menyalin konfigurasi Gradle atau daftar dependency proyek lama tanpa verifikasi kompatibilitas.

## 9. Persyaratan pengalaman pengguna dan keandalan

- Setiap layar memiliki keadaan loading, kosong, berhasil, dan gagal dengan jalan pemulihan.
- Operasi database memakai transaksi singkat; kegagalan tidak meninggalkan loading selamanya. Bila hasil simpan belum pasti, periksa status/id operasi sebelum menawarkan simpan ulang.
- Hasil permintaan lama diabaikan ketika pengguna pindah layar, mengganti kolam, atau mengganti filter. Navigasi kembali tetap berfungsi selama permintaan cuaca.
- Pesan pengguna menyebut tindakan yang bisa dilakukan; stack trace hanya di log pengembangan.
- Sasaran respons pada HP target: halaman lokal tampil dalam 2 detik dan penyimpanan biasa selesai dalam 1 detik untuk dataset uji 10 kolam, 50 siklus, dan 10.000 transaksi. Angka ini target pengukuran, bukan klaim hasil.
- Form tetap dapat digulir saat keyboard terbuka; tombol utama dapat dijangkau. Uji lebar 360 dp, layar HP target, dan ukuran teks 130% tanpa teks penting terpotong.
- Warna bukan satu-satunya penanda status; gunakan label. Semua tombol penting mempunyai teks/label aksesibilitas.
- Aplikasi tidak meminta izin penyimpanan luas, notifikasi, atau lokasi jika fitur versi pertama tidak membutuhkannya. Pilih file melalui pemilih sistem.

## 10. Lingkungan dan syarat memulai implementasi

Sebelum fitur budidaya dibuat, kerjakan milestone M0 pada proyek baru yang terpisah dari proyek lama:

1. Verifikasi model perangkat, Android/API level, serta koneksi debugging USB.
2. Tentukan satu kombinasi Flutter/Dart, JDK, AGP, Gradle, Android SDK/NDK, dan versi plugin yang kompatibel berdasarkan dokumentasi resmi.
3. Bangun dan pasang aplikasi kosong di HP melalui alur normal Android Studio/Flutter.
4. Buktikan SQLite dapat menyimpan dan membaca ulang setelah aplikasi ditutup.
5. Buktikan satu permintaan cuaca HTTPS berhasil serta kegagalan jaringan tidak membekukan layar.
6. Catat versi dan perintah yang berhasil di README; simpan lockfile. Tetapkan application ID baru agar pengujian tidak menimpa instalasi lama.

Status versi teknologi, minSdk, targetSdk, dan nomor Android perangkat: **belum diputuskan/terverifikasi**. Selesaikan pada M0, lalu gunakan konfigurasi yang sama untuk semua anggota tim. Tidak ada klaim minimum Android sebelum ditetapkan dan diuji sesuai cakupan.

Jangan mengganti hasil build APK dengan hasil tes Dart. Jika akses download, proxy, SDK, atau sandbox menghalangi, laporkan sebagai hambatan lingkungan dan selesaikan melalui jalur yang berizin. Tidak memodifikasi Pub Cache global atau melewati kebijakan persetujuan sebagai solusi permanen.

## 11. Skenario penerimaan wajib

| ID | Skenario | Hasil yang harus dibuktikan |
|---|---|---|
| AT-01 | Instalasi baru tanpa internet | Bisa membuat pakan/kolam/siklus; cuaca menyatakan belum tersedia |
| AT-02 | 100 ikan, 100 g, rate 3%, dua slot; pembagian 301 g; kasus tepat setengah | Kebutuhan 300 g, porsi 150 + 150; 301 g menjadi 151 + 150; 1 ikan × 50 g × 1% = 0,5 g dibulatkan half-up menjadi 1 g |
| AT-03 | Rate kosong, 0, negatif, >100, NaN/infinity | Ditolak; tidak ada pemberian nol akibat data hilang |
| AT-04 | Simpan pemberian 150 g, harga Rp10.000/kg | Stok turun tepat 150 g; biaya Rp1.500 |
| AT-05 | Ketuk Berikan dua kali/ulang permintaan | Hanya satu pemberian dan satu pengurangan stok |
| AT-06 | Stok 100 g, mencoba pemberian 150 g | Semua perubahan ditolak; stok tetap 100 g |
| AT-07 | Dua kolam berebut stok yang sama | Tidak ada saldo negatif; pemeriksaan memakai stok saat transaksi |
| AT-08 | Sampling dari 100 ke 120 g setelah pemberian 150 g | Kebutuhan baru 360 g; sisa slot 210 g; riwayat 150 g utuh |
| AT-09 | Kebutuhan baru lebih kecil dari pakan aktual | Sisa nol, kelebihan jelas, tidak ada stok dikembalikan otomatis |
| AT-10 | Ubah jam sebelum/sesudah halaman hari ini dibuka | Hari ini tetap; besok berubah; tidak ada slot ganda |
| AT-11 | Populasi 100, catat mati 150 | Ditolak pada UI dan penyimpanan; populasi tetap 100 |
| AT-12 | Panen parsial lalu akhir | Jumlah sesuai sisa; nilai panen memakai bobot/harga snapshot |
| AT-13 | Tutup siklus dua kali atau tanpa bobot saat masih ada ikan | Penutupan ganda/tidak lengkap ditolak tanpa merusak data |
| AT-14 | Semua ikan mati lalu tutup siklus | Tidak membuat panen atau nilai panen fiktif |
| AT-15 | Ubah harga/rate/sampling setelah pemberian | Biaya dan snapshot pemberian terdahulu tidak berubah |
| AT-16 | Batalkan pemberian terakhir 150 g | Stok kembali tepat 150 g; biaya dikecualikan; jejak batal ada |
| AT-17 | Membatalkan kegiatan yang bukan sah terakhir lintas pemberian/sampling/kematian/panen parsial dalam siklus/hari atau pratinjau koreksi stok stale | Ditolak dengan penjelasan; tidak ada perubahan sebagian. Rate/jam/Lewati sendiri bukan penghalang pembatalan terakhir (AT-30/34) |
| AT-18 | Filter bulan/kolam berbeda | Semua total transaksi mengikuti filter yang sama |
| AT-19 | Pindah tab setelah pemberian/panen | Ringkasan otomatis mencerminkan data tersimpan terbaru |
| AT-20 | API timeout/HTTP gagal/JSON rusak | Loading berhenti; retry tersedia; pencatatan lokal tetap berjalan |
| AT-21 | Ganti lokasi saat permintaan cuaca lama berjalan | Respons lama tidak menimpa lokasi baru |
| AT-22 | Cuaca berhasil lalu mode pesawat | Data tersimpan berlabel waktu/status; tidak berpura-pura live |
| AT-23 | Backup valid lalu restore | Data dan total kembali sama; seluruh halaman diperbarui |
| AT-24 | Backup batal/file rusak/tabel hilang/relasi salah | Status tidak palsu; restore ditolak dan data lama utuh |
| AT-25 | Aplikasi dihentikan saat transaksi dan dibuka lagi | Transaksi utuh atau tidak terjadi; tidak ada setengah perubahan |
| AT-26 | Ganti hari saat aplikasi terbuka/background | Tanggal/slot hari baru benar; tidak mencatat hari terlewat sebagai diberikan |
| AT-27 | Input `1.500`, `1,5`, input kosong dan sangat besar | Parser mengikuti aturan field; tidak ada tebakan/nol diam-diam |
| AT-28 | Semua slot dilewati atau kebutuhan membulat ke nol | Tidak ada transaksi pemberian nol; status dan sisa jelas |
| AT-29 | Koreksi stok masuk berulang dan stok telah dipakai | Asal tetap; lama/baru/alasan/selisih tersimpan; jumlah efektif/saldo negatif atau pratinjau lama ditolak atomik |
| AT-30 | Pemberian lalu rate/jam/Lewati lalu pembatalan | Pemberian sah terakhir hari ini dapat dibatalkan; stok pulih tepat; snapshot/jejak batal utuh; pending dihitung ulang |
| AT-31 | Restart sebelum/sesudah commit saat UI belum tahu hasil | ID niat tersimpan ditemukan; commit diketahui lewat ID sama; retry eksplisit tidak menggandakan perubahan |
| AT-32 | Sampel 0, melebihi populasi, bobot tidak valid, atau sampling sah kedua hari sama | Ditolak atomik; sampling sah tidak mengurangi populasi; sampling batal tidak menghalangi sampling baru |
| AT-33 | Panen parsial 20 dari100, bobot200g hargaRp25.000/kg; sampling berikutnya | Populasi80, nilaiRp100.000; snapshot jumlah/bobot/harga/nilai tetap |
| AT-34 | Pemberian lalu sampling lalu kematian lalu parsial; batal lintas kegiatan setelah rate/jam/Lewati | Hanya kegiatan sah terakhir hari ini dapat batal; stok/populasi/bobot pulih tepat menurut jenis; riwayat dan skipped tetap; pending dihitung ulang |
| AT-35 | Panen akhir sisa terkini; ketuk ulang, pratinjau stale, kegagalan sebelum close commit | Satu hasil per ID; stale ditolak; close/panen/stop slot/result utuh atau rollback; siklus selesai tidak menerima operasi/batal |
| AT-36 | Upgrade M1/M2/M3 ke skema4 lalu restart | Master, siklus/rate/template/slot, saldo/snapshot/koreksi/batal/ID lama dipertahankan; urutan pemberian lama masuk urutan kegiatan bersama |
| AT-37 | Batas tanggal inklusif, satu/semua kolam termasuk arsip | Semua lima total dan pendukung mengikuti tanggal/kolam yang sama; mulai setelah akhir ditolak |
| AT-38 | Panen parsial/akhir, transaksi batal, harga/rate/sampling berubah | Snapshot lama tetap; batal terlihat namun dikecualikan; jumlah biaya/nilai adalah jumlah hasil per transaksi, tanpa pembulatan gabungan |
| AT-39 | Simpan/batal lalu buka Beranda/Laporan; filter berubah saat loading | Data terbaru tanpa restart, filter tetap saat membuka pendukung/detail dan pindah tab; respons/error lama diabaikan |
| AT-40 | Laporan dari database M1–M4, kosong/loading/gagal dan pemisahan scope | Data lama terjaga; kegagalan bukan total0; Transaksi periode/Kondisi saat ini/Seluruh siklus berlabel jelas; tidak ada FCR/keuntungan bersih |
| AT-41 | Buka/refresh cuaca, lalu tekan Ambil lokasi saat ini | Buka/refresh tidak meminta izin atau mengambil HP; tombol meminta izin foreground bila perlu dan hanya satu koordinat |
| AT-42 | GPS mati, izin ditolak/ditolak berulang, fix gagal atau timeout | Penjelasan dan coba lagi/manual tersedia; lokasi tersimpan lama tidak diganti; tidak ada akses background atau pelacakan |
| AT-43 | Batal pengambilan, batal konfirmasi, kembali dari manual; hasil HP terlambat | Calon dibuang/hasil diabaikan, lokasi lama dan cuacanya tetap; tidak ada simpan tanpa konfirmasi |
| AT-44 | Konfirmasi HP/manual lalu tutup aplikasi dan buka ulang | Nama/koordinat lokasi usaha tetap; semua kolam memakai satu lokasi; pembaruan tidak mengambil ulang HP |
| AT-45 | Ganti lokasi terkonfirmasi ketika cuaca lama berjalan; simpan pengganti gagal | Respons/cache lama tidak menjadi cuaca lokasi baru; kegagalan transaksi pengaturan menjaga lokasi sebelumnya |
| AT-46 | Beranda pada360dp/teks130%, cuaca loading/gagal/cache lama; pindah tab setelah menggulir | Cuaca tepat setelah header dan sebelum ringkasan lokal; navigasi tetap aktif; status/waktu jujur tanpa data rekaan, teks/angka tidak tertutup, posisi awal setiap tab benar. Screenshot render tes dibedakan dari bukti HP |

Tes otomatis mencakup rumus, transaksi database, rollback, idempotensi, parser, filter laporan, cache cuaca, serta alur UI. Uji perangkat mencakup instalasi, navigasi, keyboard, penyimpanan file, jaringan nyata, offline, dan persistensi setelah aplikasi ditutup. Tes memakai data contoh terisolasi; demonstrasi pengguna tidak diam-diam mengambil data fixture.

## 12. Rencana pengerjaan dan pembagian tim

Jadwal berikut adalah target perencanaan, bukan jaminan. Jika suatu tahap belum lolos syaratnya, laporkan dampak jadwal; jangan melewatkan pengujian agar terlihat selesai.

| Waktu usulan | Tahap | Syarat selesai |
|---|---|---|
| 13–15 Oktober | PRD, alur, wireframe awal, M0 | Aturan inti disepakati; aplikasi dasar + SQLite + cuaca berjalan di HP |
| 16–20 Oktober | Kolam, siklus, pakan, stok, pemberian | Satu alur dari form sampai penyimpanan lulus di HP dan tes |
| 21–23 Oktober | Sampling, pengurangan, panen, laporan | Perubahan populasi, snapshot, dan filter periode benar |
| 24–26 Oktober | Cuaca lengkap, backup/restore, konsistensi UI | Kondisi offline/gagal/pemulihan data teruji |
| 27–29 Oktober | Uji regresi, perbaikan, dokumentasi | APK kandidat demo dan skenario utama lulus |
| 30–31 Oktober | Buffer dan latihan presentasi | Tidak menambah fitur; simpan APK, laporan uji, dan backup demo |

Pembagian enam penanggung jawab: (1) kebutuhan dan koordinasi, (2) alur/desain, (3) integrasi kode serta build, (4) aturan data dan pengujian otomatis, (5) API serta pengujian HP, (6) dokumentasi dan presentasi. Ini pembagian tanggung jawab; semua tetap perlu memahami alur utama. Hindari beberapa sesi AI mengubah file yang sama bersamaan. Gunakan Git dan checkpoint tiap tahap; satu penanggung jawab mengintegrasikan hasil.

## 13. Aturan pengerjaan untuk Codex

- Kerjakan satu tahap dengan kriteria penerimaan yang disebutkan, lalu laporkan hasil sebelum memperluas lingkup.
- Jangan menyalin proyek lama seluruhnya; gunakan bug lama sebagai kasus regresi.
- Perubahan aturan bisnis harus disertai revisi PRD dan tes. Jangan mengisi kekosongan aturan dengan asumsi tersembunyi.
- Jangan menghapus tes gagal, melemahkan pemeriksaan, atau mengganti data nyata dengan dummy agar demonstrasi terlihat berhasil.
- Laporkan terpisah: analisis statis, tes otomatis, build APK, pemasangan perangkat, dan uji manual. Sebutkan jika ada yang belum dilakukan.
- Utamakan perintah standar pengujian/build. Harness alternatif hanya bukti tambahan, bukan pengganti verifikasi jalur normal sebelum rilis.
- Catat file yang berubah, alasan, perintah dan hasil verifikasi, serta masalah tersisa. Tidak menjanjikan bebas semua bug hanya karena tes lulus.
- Dilarang reset database, menghapus proyek lama, menaikkan semua dependency sekaligus, atau menambahkan fitur di luar tahap tanpa alasan dan kesepakatan perubahan lingkup.

## 14. Keputusan yang perlu ditinjau sebelum PRD dibekukan

| Keputusan | Usulan v0.1 | Mengapa perlu disepakati |
|---|---|---|
| Jenis pakan per siklus | Satu jenis, tetap sampai selesai | Menyederhanakan stok, snapshot, dan UI |
| Rate | Manual, wajib, dapat diperbarui | Menghindari kebutuhan nol akibat acuan yang belum tersedia |
| Tanggal pencatatan | Hari ini saja | Menghindari penghitungan ulang sejarah populasi dan stok |
| Koreksi | M3 stok masuk melalui selisih beralasan; M4 pembatalan sah terakhir lintas pemberian/sampling/kematian/parsial hari ini pada active, rate/jam/Lewati bukan penghalang | Diputuskan pengguna untuk M3/M4; backup/restore dan fitur berikutnya belum dibuat |
| Lokasi cuaca | Satu area untuk seluruh kolam | Cukup untuk demonstrasi API; belum mendukung kolam lintas daerah |
| Biaya pakan | Harga tercatat saat pemberian | Mudah ditelusuri; bukan perhitungan akuntansi persediaan |
| Fitur lanjutan | FCR, keuntungan, notifikasi ditunda | Menjaga fokus dan memberi waktu uji sebelum akhir Oktober |

Persetujuan PRD tidak berarti seluruh versi teknologi sudah terbukti cocok. M0 tetap wajib sebelum implementasi fitur penuh. Setelah dokumen ini ditinjau, hasil berikutnya adalah diagram alur, skema data rinci, wireframe, daftar versi lingkungan yang teruji, serta daftar tugas per tahap.

## 15. Catatan revisi kebutuhan — 25 Oktober 2026 (arahan dosen)

Status: hasil diskusi pengguna, belum diimplementasikan. Isi bagian 1–14 dipertahankan sebagai riwayat. Untuk topik yang bertentangan, keputusan terkonfirmasi pada bagian ini menggantikan aturan lama; aturan lain tetap berlaku. Catatan ini tidak menyatakan seluruh usulan lama telah disetujui atau aplikasi sudah memenuhi revisi.

### 15.1 Fokus dan acuan

- Fokus utama pengembangan rekomendasi pakan adalah ikan lele pada **kolam biasa**, bukan bioflok terlebih dahulu. Aturan bioflok lain tidak otomatis ditambahkan.
- Pengguna memilih tabel bobot pada RSNI 6484-6:2024 sebagai acuan rate dasar. Dokumen yang diberikan bertanda rancangan dan khusus pembesaran bioflok; pemilihannya untuk proyek ini tidak boleh diklaim sebagai sertifikasi atau bukti standar khusus kolam biasa.
- Dokumen sumber diskusi: `rsni3_6484-6.pdf`, bagian 5.4, 5.6, Tabel 1–2; dan `materi-6982e9adaa327.pdf`, halaman PDF 13–17. Berkas diberikan pengguna melalui percakapan, belum disalin ke repositori. Materi kedua berisi contoh rate 10% dan interval penimbangan dua minggu; angka tersebut tidak dicampur otomatis dengan tabel RSNI yang dipilih.
- Menurut konfirmasi pengguna atas arahan dosen perikanan, suhu **<24 °C** menggunakan **80% dari porsi normal** untuk konteks kolam biasa. Artinya pengurangan 20%, bukan pengurangan 80%. Penulisan `<24%` pada percakapan dimaknai sebagai suhu <24 °C.

### 15.2 FR-02/FR-04 — Rate dasar dan pemeriksaan air setiap pemberian

Aturan ini menggantikan arah rate manual sebagai satu-satunya sumber rekomendasi. Rate dasar rekomendasi ditentukan dari bobot rata-rata terbaru (bobot awal sebelum ada grading); aturan dan hasil yang sama harus digunakan kalkulator, jadwal, serta form pemberian.

Transkripsi Tabel 1 sumber, belum merupakan penyelesaian celah batas bobot:

| Bobot ikan pada sumber (g/ekor) | Rate dasar (% biomassa/hari) |
|---|---:|
| 2 sampai 5 | 5 |
| 6 sampai 10 | 4 |
| 11 sampai 35 | 3 |
| 36 sampai 50 | 2,5 |
| 51 sampai 70 | 2,2 |
| >71 | 2 |

Alur pemberian yang disepakati:

1. Pilih kolam dan slot pemberian.
2. **Setiap kali akan memberi pakan**, wajib memasukkan suhu air kolam dan pH hasil pengukuran saat itu; simpan waktu pengukuran. Nilai pagi tidak otomatis dipakai untuk pemberian sore. Suhu cuaca API bukan pengganti suhu air manual.
3. Tampilkan status suhu dan pH secara terpisah, saran kondisi air, lalu rekomendasi porsi slot bila aturannya tersedia.
4. Isi jumlah aktual; harga/kg dan total biaya langsung terlihat sebelum tombol Tinjau dan simpan.
5. Tinjau dan simpan transaksi. Stok keluar mengikuti jumlah aktual, dengan validasi stok, transaksi atomik, dan perlindungan permintaan ulang yang sudah berlaku.

| Kondisi pengukuran | Perilaku rekomendasi |
|---|---|
| Suhu 25–30 °C dan pH 6,5–8, batas inklusif | Rekomendasi porsi normal berdasarkan rate dasar dan slot |
| Suhu <24 °C dan pH 6,5–8 | Rekomendasi slot = pembulatan half-up(porsi normal slot × 80/100) |
| Suhu >30 °C, termasuk 32 °C, atau pH di luar 6,5–8 | Peringatan; angka rekomendasi otomatis tidak tersedia. Pengguna tetap boleh mencatat pemberian aktual |
| Suhu 24 sampai <25 °C | Belum ada aturan penyesuaian yang dikonfirmasi; usulan sementara adalah peringatan tanpa rekomendasi otomatis, menunggu keputusan |
| Suhu/pH belum diisi atau input tidak valid | Minta dilengkapi/diperbaiki; tidak menganggap nilainya nol atau kondisi normal |

- pH dipakai untuk status dan kelayakan rekomendasi, bukan pengali numerik pakan yang dibuat tanpa acuan. Jika suhu <24 °C tetapi pH di luar rentang, berlaku status tanpa rekomendasi otomatis.
- Tidak tersedianya rekomendasi karena kondisi air berbeda dari kebutuhan nol. Pencatatan aktual pada kondisi tersebut tetap membutuhkan suhu/pH valid, data dasar pemberian valid, jumlah >0, harga valid, dan stok mencukupi.
- Penyesuaian suhu berlaku **hanya pada slot yang akan diberikan**, bukan mengganti target seluruh hari menggunakan suhu satu kali pengukuran.
- Contoh: porsi normal pagi 500 g, suhu 23 °C dan pH sesuai rentang → rekomendasi pagi 400 g. Pengurangan 100 g karena suhu tidak otomatis dialihkan ke slot sore. Sore membutuhkan pengukuran suhu/pH baru untuk penyesuaian porsinya sendiri.
- Karena itu, rumus lama `kebutuhan harian terbaru − total aktual` tidak boleh diterapkan sendirian sehingga mengembalikan pengurangan suhu ke slot berikutnya. Aturan pembagian ulang setelah perubahan biomassa, aktual berbeda dari rekomendasi, Lewati, dan pembatalan harus dirinci sebelum implementasi; slot yang sudah diberikan dan snapshot lama tetap utuh.
- Simpan snapshot suhu, pH, waktu ukur, porsi normal slot, status/penyesuaian dan rekomendasi (boleh tidak tersedia dengan alasan), rate dasar beserta acuan, jumlah aktual, biomassa/bobot-populasi, harga, biaya, serta waktu pemberian. Perubahan grading/harga/aturan berikutnya tidak menulis ulang transaksi lama.

### 15.3 FR-03/FR-04 — Harga terlihat pada form awal

- Harga pakan rupiah/kg dan total biaya pemberian tampil sejak form pemberian, bukan hanya pada dialog konfirmasi.
- Total biaya diperbarui mengikuti jumlah aktual menggunakan rumus serta pembulatan biaya yang sudah berlaku. Contoh 1.125 g dengan harga Rp15.000/kg menghasilkan Rp16.875.
- Harga dan biaya tetap ditampilkan pada konfirmasi. Permintaan ini tidak menambahkan pengeditan harga/kg di form pemberian; sumbernya harga pencatatan pakan yang tersimpan. Jika harga berubah sebelum commit, angka yang dikonfirmasi harus tetap konsisten dengan snapshot yang disimpan.

### 15.4 FR-05 — Sampling menjadi Grading, dengan rencana fleksibel

- Nama yang dihadapkan kepada pengguna berubah dari **Sampling** menjadi **Grading**, sesuai arahan dosen. Dalam lingkup aplikasi ini grading berarti mencatat bobot, bukan sortir atau memindahkan ikan.
- Catatan ditampilkan sebagai **Grading 1, Grading 2, dan seterusnya dalam setiap siklus**, beserta tanggal, jumlah ikan yang ditimbang, dan bobot rata-rata. Nomor menunjukkan urutan pencatatan, bukan fase biologis atau jadwal wajib.
- Grading tidak mengurangi populasi. Bobot terbaru dipakai untuk rencana pemberian berikutnya; transaksi terdahulu tidak berubah. Validasi jumlah sampel, bobot, pembatalan, serta batas satu catatan sah per tanggal dari FR-05 tetap berlaku; fleksibel berarti tidak dipaksa menunggu interval tujuh hari.
- Setelah grading, tampilkan saran rencana berikutnya **7 hari kemudian**. Pengguna boleh mengubah tanggal rencana sesuai kesibukan. Rencana ini boleh berada di masa depan dan bukan tanggal transaksi grading.
- Jika terlewat, tampilkan keterangan rencana grading terlewat di detail kolam. Tetap gunakan bobot terakhir dan tampilkan tanggalnya; tidak memblokir pencatatan/pemberian dan tidak membuat grading otomatis.
- Catatan rencana cukup tersedia di aplikasi; tidak menambah notifikasi background. Penomoran setelah pembatalan serta pemulihan rencana ketika grading dibatalkan perlu dirinci sebelum implementasi agar riwayat tidak ambigu.

### 15.5 FR-07 — Ekspor laporan Excel

- Tambahkan ekspor **Excel `.xlsx`** (permintaan awal menyebut xcls). Ini tambahan lingkup laporan, bukan ekspor PDF atau pengganti backup/restore.
- Hasil mengikuti filter tanggal dan kolam yang sedang dipilih, dengan ringkasan serta rincian transaksi. Aturan agregasi periode, snapshot biaya/nilai dan pengecualian transaksi batal tetap berlaku.
- Rincian pemberian mencakup suhu, pH, jumlah aktual, harga/kg, serta biaya. Data lama yang belum memiliki pengukuran diberi keterangan tidak tercatat, bukan nol atau nilai buatan.
- Pembatalan pemilih lokasi/file bukan ekspor berhasil. Laporan kosong, kegagalan penyimpanan, dan ekspor offline harus ditangani dengan status jujur.

### 15.6 Tambahan skenario penerimaan (belum diuji)

AT lama tetap sebagai riwayat. Ekspektasi lama terkait rate manual, distribusi ulang, dan istilah Sampling mengikuti penggantian eksplisit di atas; skenario yang bergantung pada keputusan terbuka belum siap dinyatakan lulus.

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| AT-47 | Pemberian pagi lalu sore; suhu/pH kosong atau tidak valid | Setiap pemberian meminta pengukuran baru; nilai pagi/cuaca API tidak otomatis menggantikan input sore; input invalid tidak tersimpan |
| AT-48 | Porsi normal 500 g, suhu 23 °C, pH 7; lanjut slot sore | Rekomendasi pagi 400 g; pengurangan suhu 100 g tidak menjadi tambahan otomatis sore; sore dievaluasi dengan pengukuran baru |
| AT-49 | Suhu 25/30 °C, pH 6,5/8; suhu 32 °C; pH di luar rentang | Batas normal inklusif; kondisi di luar acuan menampilkan peringatan tanpa angka rekomendasi, tetapi aktual valid dapat dicatat; tidak menganggap rekomendasi kosong sebagai nol |
| AT-50 | Jumlah aktual 1.125 g, harga Rp15.000/kg; ubah jumlah | Harga/kg dan biaya Rp16.875 terlihat sebelum konfirmasi; biaya mengikuti jumlah; konfirmasi dan snapshot tersimpan konsisten |
| AT-51 | Grading berurutan, ubah tanggal rencana, rencana terlewat | Label berurutan per siklus; saran awal +7 hari bisa diubah; terlambat tidak memblokir; populasi dan transaksi lama tetap; bobot/tanggal terakhir terlihat |
| AT-52 | Ekspor satu/semua kolam pada periode tertentu, termasuk data lama/batal | XLSX sesuai filter dan total layar; batal tidak masuk total; suhu/pH lama yang kosong tidak dibuat-buat; dapat dibuka di pembaca spreadsheet |
| AT-53 | Ekspor kosong/offline, batal pemilih, atau simpan gagal | Data lokal tetap; file kosong mempunyai konteks periode; batal/gagal tidak dilaporkan sukses; tidak bergantung pada API cuaca |
| AT-54 | Bobot 50 g dan 1.000 ikan pada acuan tabel yang dipilih | Rate dasar 2,5%; kebutuhan normal 1.250 g/hari sebelum pembagian slot dan penyesuaian suhu; bukan otomatis memakai contoh 10% materi lain |

### 15.7 Keputusan terbuka sebelum implementasi revisi

1. Konfirmasi penerapan tabel rate bobot bioflok ke kolam biasa bersama dosen; pemilihan tabel oleh pengguna sudah disepakati, tetapi kesesuaiannya bukan klaim standar kolam biasa.
2. Tutup celah tabel untuk bobot desimal (misalnya 5,5 g), bobot <2 g dan tepat 71 g. Jangan membulatkan bobot atau memperluas interval diam-diam. Bagian 5.4 sumber juga mempunyai aturan khusus awal tebar (hari setelah tebar sampai hari ketujuh, 1–3%); prioritas serta rate konkretnya belum disepakati.
3. Putuskan kondisi suhu 24 sampai <25 °C, termasuk tepat 24 °C yang tidak memenuhi `<24 °C`. Jangan menganggapnya otomatis mendapat faktor 80%.
4. Rinci pembagian porsi normal dan pengurangan suhu saat ada grading/perubahan populasi di tengah hari, aktual kurang/lebih, Lewati, pembatalan, serta pembulatan; pengurangan karena suhu tidak boleh diam-diam dikejar pada slot berikutnya.
5. Tetapkan presisi/batas teknis suhu dan pH, penomoran serta rencana grading setelah pembatalan, dan kompatibilitas data/backup lama tanpa pengukuran. Jangan mewajibkan pengisian suhu/pH rekaan pada riwayat lama.

Pekerjaan pada revisi ini hanya pembaruan PRD. Implementasi, perubahan database, migrasi, pengujian aplikasi, dan build APK memerlukan tahap berikutnya sesuai permintaan pengguna.

### 15.8 Klarifikasi lanjutan Tahap 1 — 25 Oktober 2026

Tambahan ini mempertahankan catatan diskusi sebelumnya. Keputusan berikut menggantikan ketidakjelasan yang bersesuaian pada 15.2/15.7; bukan klaim validasi ilmiah baru dari dosen.

- Pengguna memilih **langsung memakai tabel bobot sejak awal siklus**, tanpa aturan khusus rate 1–3% pada minggu pertama. Sebelum grading gunakan bobot awal tebar; sesudahnya gunakan bobot rata-rata terbaru.
- Pengguna menyetujui batas kontinu berikut sebagai aturan proyek, untuk menutup celah bobot desimal dan tepat 71 g:

| Bobot rata-rata per ekor | Rate dasar harian dari biomassa |
|---|---:|
| 2 sampai 5 g, kedua batas termasuk | 5% |
| >5 sampai 10 g | 4% |
| >10 sampai 35 g | 3% |
| >35 sampai 50 g | 2,5% |
| >50 sampai 70 g | 2,2% |
| >70 g | 2% |

- Contoh batas: tepat 5 g memakai 5%; 5,01 g memakai 4%; tepat 10 g memakai 4%; 10,01 g memakai 3%; tepat 70 g memakai 2,2%; 70,01 g dan tepat 71 g memakai 2%. Bobot tidak dibulatkan ke gram bulat sebelum memilih kelompok. Bobot <2 g masih belum mempunyai rate yang disepakati.
- Suhu **24 sampai <25 °C** diputuskan menampilkan peringatan tanpa angka rekomendasi otomatis; pengguna tetap boleh mencatat aktual dengan syarat data/validasi lainnya terpenuhi. Tepat 24 °C tidak memakai faktor 80%; tepat 25 °C masuk rentang normal jika pH sesuai.
- Pengguna menegaskan bahwa ketika suhu kembali normal, rekomendasi kembali mengikuti feeding rate normal. Contoh yang jelas: kebutuhan normal 1.000 g/hari dengan dua slot → porsi normal masing-masing 500 g; pagi dingin direkomendasikan 400 g, sore normal direkomendasikan 500 g.
- Usulan Tahap 1 tentang mengejar kekurangan aktual biasa (rekomendasi pagi400, aktual350 → sore550) **belum disetujui**. Penjelasan terakhir mengusulkan sore tetap500 tanpa mengejar kekurangan, tetapi belum ada jawaban eksplisit untuk kasus itu. Jangan menerapkan salah satu rumus distribusi baru sebagai keputusan final. Perubahan bobot/populasi di tengah hari, aktual berlebih, Lewati dan pembatalan tetap perlu perincian.
- Untuk disampaikan ke dosen: batas kontinu dan penggunaan tabel sejak awal merupakan pilihan desain pengguna yang perlu ditinjau kesesuaian budidayanya, khususnya karena acuan asal membahas bioflok sedangkan fokus aplikasi kolam biasa. Jangan menyebut interpretasi interval ini sebagai teks asli RSNI atau menyatakan telah disetujui dosen.

Keputusan terbuka pada 15.7 dibaca bersama klarifikasi ini: rentang 24–<25 °C, celah interval bobot ≥2 g, dan pilihan tidak memakai rate awal tebar sudah diputuskan pengguna. Bobot <2 g, validasi budidaya untuk kolam biasa, serta rincian distribusi/aktivasi aturan pada data lama masih terbuka. Belum ada perubahan aplikasi.

### 15.9 Catatan implementasi Tahap 2 — Grading

Pengguna meminta melanjutkan Tahap2 sambil menunda konfirmasi perikanan. Implementasi dibatasi FR-05/AT-51: istilah Grading, nomor per siklus, bobot/tanggal terakhir, rencana default+7 hari yang dapat diubah, dan peringatan terlewat tanpa blokir. Aturan pakan baru belum diaktifkan.

Pilihan teknis: nomor commit tidak digunakan ulang setelah batal; satu grading sah per tanggal tetap. Tanggal rencana baru setelah hari ini. Rencana bawaan dipulihkan saat grading dibatalkan bila belum diedit terpisah; edit rencana terpisah dipertahankan. Data sampling lama tetap, diberi nomor tanpa pengukuran/rencana rekaan. Skema6 dan sumber0.8.2+10; rincian perubahan, tes dan batas bukti ada di [laporan Tahap2](REVISI_DOSEN_TAHAP_2_GRADING.md). Seluruh70 tes Flutter standar dan build APK lulus; migrasi SQLite Android/pemasangan/manual HP belum dijalankan karena Android tidak terdeteksi. Catatan implementasi ini tidak mengubah aturan budidaya yang masih menunggu dosen menjadi persetujuan.

### 15.10 Keputusan pembagian porsi Tahap 3 — 26 Oktober 2026

Pengguna menjawab tiga pertanyaan Tahap3 secara eksplisit:

1. Jika porsi normal pagi500 g, rekomendasi dingin400 g, tetapi aktual350 g, **sore normal tetap500 g**. Kekurangan aktual biasa maupun pengurangan karena suhu tidak otomatis dipindahkan.
2. Jika satu slot **dilewati**, porsinya **tidak dibagikan ke slot lain**.
3. Setelah grading atau perubahan populasi di tengah hari, **porsi normal dihitung dari kondisi terbaru dibagi jumlah jadwal harian**, dengan aktual berlebih tetap diperiksa.

Untuk kebijakan baru, keputusan ini menggantikan usulan `N − A − D` pada dokumen Tahap1 dan aturan redistribusi lama FR-04 yang bersesuaian. Riwayat dokumen lama dipertahankan, bukan izin memakai rumus yang sudah diganti. Aturan aktif aplikasi lama tetap sampai aktivasi utuh Tahap4.

Rincian perilaku kebijakan baru:

- Hitung kebutuhan normal harian dari populasi/bobot terbaru dan tabel bobot15.8, kemudian bagi gram bulat ke **seluruh slot hari ini** menurut urutan jam. Bukan hanya slot menunggu; sisa gram pembulatan ke jam paling awal.
- Hasil baru hanya dipakai untuk merekomendasikan **slot menunggu**. Nilai yang dihitung untuk jam yang sudah diberikan/dilewati tidak menulis ulang catatan atau membuka kembali slot tersebut. Template jam besok tidak mengganti daftar jam hari ini.
- Suhu/pH setiap pemberian menentukan rekomendasi slot itu. Porsi normal500 g pada suhu23 °C/pH7 menjadi400 g; sore pada suhu normal tetap500 g, baik aktual pagi400 maupun350 g.
- Contoh perubahan kondisi: kebutuhan normal awal1.000 g dengan dua slot, aktual pagi400 g, kemudian kondisi ikan membuat kebutuhan baru1.200 g → porsi normal sore600 g, bukan700/800 g. Jika kebutuhan baru500 g → porsi normal sore250 g.
- Jangan mengurangi/mengembalikan aktual atau stok lama secara otomatis. Bandingkan calon aktual dengan rekomendasi yang tersedia, porsi normal slot, serta total aktual sah hari itu terhadap kebutuhan normal terbaru. Kelebihan ditandai untuk konfirmasi tambahan, bukan disembunyikan dengan mengubah riwayat. Angka normal terbaru bukan kewajiban mengejar selisih.
- Pembatalan yang sah memulihkan stok/bobot/populasi sesuai jenisnya, mengecualikan aktual batal dari total dan mengembalikan status slot pemberian ke menunggu. Hitung ulang dari kondisi terbaru tanpa redistribusi; slot lain yang dilewati tetap dilewati. Pemberian pengganti meminta pengukuran baru; retry ID asli tetap memakai payload asli.
- Semua slot selesai/dilewati tidak membuat slot tambahan. UI kebijakan baru harus membedakan kebutuhan normal harian, aktual sah, rencana porsi menunggu dan kelebihan; jangan menyebut `kebutuhan normal − aktual` sebagai porsi yang wajib dibagikan lagi.
- Tanpa bobot/populasi atau untuk bobot<2 g, rekomendasi belum tersedia, bukan rate/kebutuhan nol. Populasi benar-benar nol atau porsi valid yang membulat nol merupakan kondisi terpisah; tidak membuat transaksi nol.

Tambahan skenario penerimaan, untuk kebijakan baru saat diaktifkan:

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| AT-55 | Porsi pagi500, rekomendasi400, aktual350; sore normal | Sore tetap500; selisih150 tidak dikejar; aktual350 tetap pada riwayat |
| AT-56 | Lewati satu dari dua slot normal500+500 | Slot lain tetap500, bukan1.000; tidak ada stok/aktual nol |
| AT-57 | Pagi aktual400, kebutuhan berubah1.000→1.200 atau500, dua slot tetap | Sore menjadi600 atau250; snapshot pagi dan jam hari ini tetap |
| AT-58 | Aktual melampaui rekomendasi/normal slot atau akumulasi melebihi normal harian terbaru | Ada penanda dan konfirmasi tambahan pada alur simpan; tidak mengubah stok/riwayat sebelum commit atau menarik stok kembali otomatis |
| AT-59 | Pratinjau kebijakan baru pada data lama, perubahan jam efektif besok, grading dan pembatalan | Satu sumber aturan membaca kondisi terbaru dan jam hari yang benar, tanpa menulis ulang rate/slot/ledger/payload lama; alur lama tetap konsisten sampai aktivasi |

Implementasi disiapkan sebagai mesin aturan bersama dan pratinjau baca-saja pada Tahap3. Form pengukuran, integrasi UI/commit, penyimpanan snapshot baru, pilihan aktivasi siklus lama dan uji Android tetap pekerjaan Tahap4/6. Lihat [laporan Tahap3](REVISI_DOSEN_TAHAP_3_PAKAN.md) untuk batas verifikasi. Peninjauan perikanan oleh dosen tetap ditunda sesuai permintaan pengguna.

Catatan hasil persiapan Tahap3: sumber0.8.3+11, skema tetap6; analisis kode dan98 tes Flutter standar lulus, build APK debug lulus. Aturan baru belum aktif di alur produksi. Empat skenario SQLite native baru disiapkan tetapi belum dijalankan, pemasangan/manual HP juga belum dilakukan karena tidak ada Android terdeteksi. Keberhasilan mesin aturan tidak dianggap bukti seluruh AT UI/database sudah lulus.

### 15.11 Aktivasi Tahap 4 — 26 Oktober 2026

Pengguna memilih aturan otomatis untuk siklus lele yang sudah berjalan **langsung hari ini, pada pemberian berikutnya**, bukan menunggu besok. Pemberian lama tetap utuh. Catatan ini menggantikan status belum aktif pada catatan Tahap3; tidak menghapus riwayat status tersebut.

- Sumber0.9.0+12 menambahkan migrasi skema1–6→7, tanpa reset atau perubahan application ID. Siklus aktif yang label jenis ikannya memuat kata `lele` (tidak membedakan kapitalisasi, termasuk “Ikan Lele Sangkuriang”) diaktifkan ke kebijakan baru. Label spesies lain atau nama yang tidak dapat dikenali tetap memakai rate manual lama; tidak otomatis dianggap lele. Siklus selesai tidak dialihkan sebagai bagian migrasi.
- Form siklus baru berfokus pada lele dan menampilkan rate dari bobot, bukan input rate manual. Sebelum grading gunakan bobot awal; sesudahnya gunakan kondisi terbaru. Identitas kebijakan dan bobot tersimpan menjadi dasar rate otomatis yang sama bagi jadwal/kebutuhan/form. Riwayat `cycle_rates` manual lama dipertahankan; snapshot pemberian menyimpan rate numerik yang benar-benar dipakai.
- Setiap form pemberian baru meminta suhu air serta pH hasil pengukuran saat itu, tanpa pengisian otomatis dari transaksi sebelumnya atau API cuaca. Suhu maksimal satu desimal dalam batas input0–50 °C, pH maksimal dua desimal dalam batas input0–14; koma/titik didukung dan pemisah ribuan/nonfinite ditolak. Batas teknis input bukan rentang aman budidaya. Waktu yang disimpan adalah waktu pencatatan pengukuran manual, bukan timestamp sensor.
- Rekomendasi numerik baru muncul setelah pengukuran lengkap/valid. Status suhu dan pH ditampilkan terpisah. Untuk lele, gunakan aturan25–30 °C/pH6,5–8 normal, suhu<24 °C menjadi80%, dan kondisi lain yang disepakati menampilkan peringatan tanpa rekomendasi numerik. Aktual tetap dapat ditinjau pada kondisi air di luar acuan jika data dasar valid. Bobot/rate belum memiliki acuan tidak diganti menjadi kebutuhan nol.
- Harga/kg tampil pada kartu awal. Total biaya diperbarui saat aktual diisi, sebelum konfirmasi, dan tetap tampil pada konfirmasi. Harga tidak diedit di form ini. Tombol Gunakan jumlah rekomendasi merupakan pilihan eksplisit; perubahan pengukuran tidak diam-diam menimpa aktual yang sudah diketik.
- Sebelum menulis, baca ulang kondisi ikan, jam/status/porsi slot, harga dan aktivitas hari itu. Perubahan dari pratinjau meminta peninjauan ulang; stok bersama tetap diperiksa saat transaksi. Jumlah aktual berlebih memakai penanda konfirmasi tambahan. Pengukuran dari tanggal usaha berbeda atau masa depan ditolak. Hari berganti meminta membuka kembali form hari yang benar.
- Pemberian baru menyimpan versi/acuan aturan, pengukuran/waktu, status suhu/pH, porsi normal, rekomendasi nullable beserta alasan, faktor/pengurangan suhu dan seluruh snapshot aktual/harga/biaya/bobot/populasi yang sudah ada. Riwayat, detail kegiatan dan laporan menampilkan pengukuran dari snapshot; nilai lama tanpa pengukuran bertanda **Tidak tercatat**, bukan0 atau angka normal rekaan.
- Kolom `normal_auto_g` pada slot menyimpan porsi normal otomatis nullable; NULL berarti belum bisa dihitung. Kolom `planned_g` lama tetap untuk kompatibilitas data/operasi lama, bukan sumber rekomendasi otomatis. UI membedakan kebutuhan normal, aktual dan rencana porsi menunggu tanpa redistribusi sebagaimana15.10. Rate manual tidak dapat ditimpa melalui layar lama ketika siklus sudah otomatis.
- **Pengecualian pemulihan niat lama:** hanya ID pemberian yang sudah berstatus prepared sebelum migrasi dicatat sebagai niat legacy. Retry eksplisit ID/payload yang sama tetap mengikuti input lama tanpa menambahkan pengukuran rekaan atau memotong stok dua kali. Tanggal, stok, harga/rate dan status tetap divalidasi; niat lama yang sudah tidak sah dapat ditolak. Ini bukan jalur membuat pemberian baru tanpa pengukuran pada siklus otomatis. ID/payload lama tidak ditulis ulang, dan tidak ada retry otomatis.
- Backup/restore belum tersedia pada implementasi saat ini. Skema dan tabel pengecualian niat perlu masuk kontrak backup kelak; tidak mengklaim dukungan restore versi baru yang belum dibuat. Ekspor XLSX masih Tahap5.

| ID | Tambahan skenario penerimaan | Hasil yang diharapkan |
|---|---|---|
| AT-60 | Upgrade6→7 pada lele aktif yang sudah diberi pakan pagi | Pemberian berikutnya langsung mengikuti kebijakan baru; snapshot pagi tetap, pengukuran lama NULL; siklus spesies lain tidak diam-diam dialihkan |
| AT-61 | Harga/grading/populasi/aktivitas berubah setelah form atau konfirmasi dibuka | Peninjauan ulang diperlukan; tidak ada stok/ledger/snapshot setengah tersimpan |
| AT-62 | ID prepared sebelum upgrade lalu retry eksplisit setelah upgrade/restart | Payload asal tetap; hasil satu kali per ID, tidak membuat suhu/pH rekaan; hanya ID yang dicatat saat migrasi mendapat jalur legacy |
| AT-63 | Hari berganti atau waktu pengukuran salah tanggal/masa depan | Ditolak tanpa pemberian baru; pesan menjelaskan perlunya pengukuran/form tanggal yang benar |

Status implementasi dan pemeriksaan tersedia pada [laporan Tahap4](REVISI_DOSEN_TAHAP_4_PEMBERIAN.md). Analisis serta tes Flutter standar tidak menggantikan tes SQLite native, pemasangan dan uji manual HP. Peninjauan budidaya oleh dosen tetap terpisah dari keputusan teknis aplikasi ini.

### 15.12 Implementasi ekspor Excel Tahap 5 — 26 Oktober 2026

Pengguna mengizinkan pembuatan ekspor Excel beserta tesnya. FR-07/15.5 dan AT-52–53 diterapkan melalui tombol Ekspor Excel pada Laporan: snapshot filter yang tampil menjadi lembar Ringkasan dan Transaksi. Ringkasan memakai agregasi layar; rincian menyertakan transaksi batal berlabel tanpa memasukkannya ke total. Pengukuran lama kosong tetap Tidak tercatat, rekomendasi tidak tersedia bukan nol. Kondisi saat ini/seluruh siklus tidak dicampur ke total periode.

Penyimpanan melalui pemilih dokumen Android, dengan status sukses hanya setelah penulisan ditutup berhasil; batal/gagal tidak dianggap sukses. Ekspor tidak mengubah database atau mengandalkan API cuaca. Sumber0.10.0+13, skema tetap7. Analisis dan110 tes standar lulus; fixture XLSX dapat dibaca pembaca terpisah. Pemilih file dan pembacaan Excel/WPS pada HP belum diuji karena Android belum tersedia pada tahap tersebut. Rincian serta batas verifikasi ada pada [laporan Tahap5](REVISI_DOSEN_TAHAP_5_EXCEL.md); catatan tahap sebelumnya dipertahankan sebagai riwayat.

### 15.13 Verifikasi gabungan Tahap 6 — 26 Oktober 2026

Pengguna meminta Tahap6 lalu tes HP. Tahap ini digunakan untuk regresi gabungan Tahap2–5, bukan fitur baru. Sumber0.10.1+14, skema tetap7: perbaikan validasi NaN/Infinity sebelum serialisasi jurnal, fixture migrasi lengkap, dan aplikasi native test terpisah dari aplikasi utama. Nilai payload valid dan aturan budidaya tidak diubah.

Analisis serta114 tes standar lulus. **53 tes Android lulus** pada Infinix X6879 Android16/API36, termasuk form pemberian dengan SQLite, grading/pakan/laporan/ekspor, pembatalan, rollback, retry dan migrasi. APK utama dipasang sebagai pembaruan tanpa uninstall/clear data; migrasi data HP nyata5→7 berhasil dengan snapshot historis tetap. Pemilih file Android diuji batal dan simpan ke Unduhan, dengan pesan hasil yang sesuai. **Pengguna memilih memeriksa isi file di Excel/WPS sendiri**; pembacaan file aktual itu, mode pesawat dan seluruh skenario manual tidak dinyatakan lulus. Rincian FR/AT, batas bukti, data lama dan perintah pengujian aman ada pada [laporan Tahap6](REVISI_DOSEN_TAHAP_6_REGRESI.md). Catatan tahap lama tetap menjadi riwayat, bukan status pengujian terkini.

### 15.14 FR-06/FR-07 — Hasil panen setelah biaya pakan — 26 Oktober 2026

Pengguna menyetujui tambahan tabel saat panen akhir dengan lingkup pakan saja. Ini memperluas ringkasan siklus selesai; bukan penambahan akuntansi biaya lain atau label keuntungan bersih pada bagian FR-07 lama.

- Tampilkan pada riwayat/detail panen akhir, penutupan populasi nol, kartu/detail siklus selesai di Laporan, serta detail transaksi panen akhir/penutupan pada Laporan.
- **Pendapatan kotor** = seluruh nilai snapshot panen sebagian + panen akhir sah dalam satu siklus.
- **Total pakan terpakai** = jumlah pemberian aktual sah selama siklus; **total biaya pakan** = jumlah biaya snapshot pemberian sah. Tidak memakai pembelian stok yang belum terpakai atau harga pakan terkini.
- **Hasil setelah biaya pakan** = pendapatan kotor − total biaya pakan. Nilai negatif tetap negatif. Tidak disebut keuntungan bersih karena biaya lain tidak dicatat/diperhitungkan.
- Semua transaksi batal dikecualikan. Jangan mencampurkan siklus/kolam lain. Ringkasan ini berlabel **Seluruh siklus**, tidak dibatasi filter tanggal Laporan, dan tidak mengubah agregat transaksi periode.
- Penutupan tanpa ikan/panen tetap dapat mempunyai biaya pakan atau pendapatan panen sebagian sebelumnya; jangan membuat pendapatan akhir rekaan atau menghilangkan biaya. Snapshot tidak lengkap adalah gagal dihitung, bukan biaya nol.
- Tabel merupakan hasil baca dari transaksi yang sudah tersimpan. Tidak mengubah stok, populasi, snapshot transaksi, skema database atau aturan penutupan. Siklus selesai lama dapat menampilkan hasil yang sama dari catatan yang tersedia. Form konfirmasi panen tetap menampilkan transaksi panen yang akan disimpan; tabel seluruh siklus tersedia setelah penutupan tersimpan.
- XLSX periode tetap mengikuti kontrak15.5; revisi ini menambah tabel di aplikasi, tidak mencampur total seluruh siklus ke ekspor periode.

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| AT-64 | Panen sebagian Rp100.000 + akhir Rp400.000; pemberian1.000g/Rp15.000 dan2.000g/Rp40.000 | Pendapatan Rp500.000; pakan3.000g; biaya Rp55.000; hasil Rp445.000; harga snapshot tiap pemberian dipakai |
| AT-65 | Pemberian/panen batal dan ada siklus lain | Batal dikecualikan dari total; siklus lain tidak tercampur; data historis tidak berubah |
| AT-66 | Filter tanggal hanya hari panen akhir | Ringkasan transaksi periode tetap sesuai filter; tabel hasil seluruh siklus tetap mencakup pemberian/panen sah sebelumnya dengan label jelas |
| AT-67 | Tutup populasi nol dengan biaya Rp15.000 dan tanpa penjualan | Pendapatan0,hasil−Rp15.000; biaya tidak hilang; tidak membuat pendapatan akhir |
| AT-68 | Harga pakan berubah setelah siklus selesai lalu reopen | Total biaya dan hasil tetap dari snapshot; tabel terbaca pada layar sempit; tidak ada penulisan ulang transaksi |

Rincian implementasi/verifikasi: [hasil panen setelah biaya pakan](HASIL_PANEN_BIAYA_PAKAN.md).

### 15.15 Arah pengembangan lanjutan proposal — 3 November 2026

Pengguna menetapkan arah bagian 5.2 proposal: fokus saat ini tetap pakan lele; tahap berikutnya direncanakan mendukung nila, mujair, dan gurame serta integrasi pengukuran pH dan suhu air otomatis untuk langsung menyajikan rekomendasi tanpa mengetik pengukuran manual. Ini arah pengembangan, bukan izin implementasi fitur baru dalam tugas penyusunan proposal.

- Kebijakan setiap spesies memerlukan acuan dan peninjauan tersendiri; aturan lele tidak otomatis berlaku pada spesies lain.
- Integrasi sensor belum tersedia. Perangkat, komunikasi, kalibrasi, pemetaan kolam, usia data, dan perilaku saat gagal perlu dirancang sebelum implementasi. Alur manual sebagai cadangan merupakan usulan rancangan dalam proposal.
- Otomatisasi masukan pengukuran dan rekomendasi tidak berarti pengendalian alat pemberi pakan. Pencatatan aktual serta transaksi stok tetap mengikuti aturan yang berlaku.
- AT saat ini tidak berubah dan tidak menjadi bukti pengujian sensor/spesies lain. Skenario penerimaan baru harus ditetapkan pada tahap perancangan fitur tersebut, termasuk data sensor tidak valid/kedaluwarsa dan pemilihan kebijakan per spesies.

### 15.16 Identitas visual dan perkenalan — 18 November 2026

Pengguna menyetujui pratinjau maskot ikan umum, ikon Android, layar pembuka dan tiga halaman pengenalan, lalu meminta implementasi. Maskot bukan lele agar identitas dapat digunakan pada pengembangan spesies lain; keputusan visual ini tidak memperluas kebijakan budidaya saat ini.

- Ikon memakai maskot ikan berwarna hijau–mint. Layar pembuka menampilkan FishCare dan “Kelola kolam, pantau pakan”.
- Perkenalan membahas kolam, pakan dan laporan. Lanjut/geser berpindah halaman; Lewati atau Mulai memasuki Beranda dan menandai perkenalan selesai.
- Penanda hanya preferensi lokal UI, terpisah dari SQLite budidaya. Setelah selesai, pembukaan berikutnya melewati perkenalan. Pengguna lama tanpa penanda melihatnya satu kali saat memperbarui ke versi ini. Tutup sebelum selesai tidak menandai selesai.
- Tidak menambahkan login, izin baru, internet sebagai prasyarat, atau perubahan transaksi/perhitungan.
- Jika preferensi gagal dibaca, perkenalan tetap dapat digunakan. Jika penyimpanan gagal, tampilkan retry dan pilihan lanjut sementara dengan pemberitahuan bahwa perkenalan mungkin muncul lagi. Jangan menghalangi pencatatan inti.
- Konten dapat digulir pada layar pendek/teks besar; tombol utama tetap terjangkau. Setelah masuk Beranda, tombol Kembali tidak membuka perkenalan kembali.

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| AT-69 | Buka tanpa penanda, termasuk upgrade pengguna lama | Splash lalu perkenalan; tidak menyentuh data kolam/riwayat |
| AT-70 | Lanjut sampai laporan lalu Mulai | Masuk Beranda dan penanda selesai tersimpan |
| AT-71 | Lewati dan tekan berulang ketika penyimpanan berlangsung | Satu permintaan simpan; Beranda dibuka satu kali |
| AT-72 | Buka ulang setelah Mulai/Lewati | Perkenalan dilewati berdasarkan preferensi persisten |
| AT-73 | Gagal baca/simpan preferensi | Tidak terjebak pada splash; retry/lanjut sementara jujur dan tersedia |
| AT-74 | Layar 360dp/teks130%, layar pendek/teks200%, Kembali halaman kedua | Tidak overflow; konten dapat digulir; tombol dapat dicapai; Kembali menuju halaman sebelumnya |

Hasil tes widget tidak menggantikan pembuktian persistensi setelah process restart Android. Lihat [catatan implementasi perkenalan](PERKENALAN_DAN_IKON_2026-11-18.md).
