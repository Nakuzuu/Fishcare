# BAB II
# TINJAUAN PUSTAKA

## 2.1 Konsep Aplikasi Mobile

Aplikasi mobile merupakan perangkat lunak yang digunakan melalui perangkat bergerak untuk membantu pengguna melakukan kegiatan tertentu. Pada proyek FishCare, kegiatan tersebut berupa pencatatan budidaya lele, mulai dari pengelolaan kolam dan siklus hingga pencatatan pakan serta panen. Pemanfaatan perangkat Android memungkinkan pengguna mengakses catatan melalui perangkat yang sama ketika memeriksa kondisi kolam dan meninjau kegiatan budidaya.

Kebutuhan aplikasi tidak hanya berkaitan dengan penyediaan formulir, tetapi juga hubungan antara data yang dicatat. Kolam menjadi identitas tempat budidaya, sedangkan siklus menjadi batas satu periode pemeliharaan. Pemberian pakan, grading, kematian, dan panen dihubungkan dengan siklus yang sesuai agar kegiatan dari periode berbeda tidak tercampur. Dalam FishCare, satu pengguna dapat mengelola beberapa kolam, tetapi setiap kolam hanya memiliki paling banyak satu siklus aktif.

### 2.1.1 Penyimpanan Lokal dan Pencatatan Offline

FishCare menempatkan basis data lokal sebagai sumber utama pencatatan kegiatan. Data kolam, siklus, persediaan pakan, dan transaksi disimpan pada perangkat pengguna. Pendekatan ini dipilih agar penyimpanan kegiatan dan pembacaan laporan tidak harus menunggu respons layanan internet. Koneksi internet diperlukan untuk layanan tambahan berupa pencarian lokasi dan pembaruan informasi cuaca.

Pemisahan tersebut berpengaruh pada alur aplikasi. Kegagalan mengambil cuaca tidak boleh menghalangi pengguna mencatat pemberian pakan atau melihat riwayat kolam. Sebaliknya, informasi cuaca yang belum tersedia atau berasal dari penyimpanan sebelumnya perlu disertai keterangan yang sesuai. Ketersediaan data lokal dan ketersediaan layanan eksternal merupakan dua kondisi yang ditangani secara terpisah dalam rancangan FishCare.

### 2.1.2 Data Budidaya sebagai Dasar Perhitungan

Populasi dan bobot rata-rata merupakan dasar perhitungan biomassa dalam FishCare. Bobot awal digunakan ketika siklus dimulai, kemudian diperbarui melalui pencatatan Grading. Sesuai batasan pada Bab I, istilah grading dalam aplikasi berarti pencatatan hasil penimbangan sampel untuk memperbarui bobot rata-rata, bukan penyortiran atau pemindahan ikan. Grading tidak langsung mengurangi populasi; perubahan populasi dicatat melalui kegiatan kematian atau panen.

Hubungan dasar perhitungan yang digunakan dalam proyek dinyatakan sebagai berikut.

**Biomassa (gram) = populasi (ekor) × bobot rata-rata (gram/ekor)**

**Kebutuhan pakan normal (gram/hari) = biomassa (gram) × feeding rate (%) / 100**

Pada aturan FishCare terbaru, *feeding rate* ditentukan dari kelompok bobot lele. Kebutuhan normal dibagi menurut jadwal pemberian, kemudian rekomendasi setiap pemberian mempertimbangkan suhu air dan pH yang baru dimasukkan pengguna. Angka rekomendasi dibedakan dari jumlah aktual yang benar-benar dicatat. Porsi yang dilewati maupun selisih aktual tidak otomatis dialihkan ke jadwal berikutnya.

Rumus dan perilaku tersebut merupakan aturan operasional proyek sebagaimana dijelaskan dalam PRD dan dokumentasi revisi. Pembahasannya tidak dimaksudkan sebagai pembuktian bahwa rekomendasi telah sesuai untuk seluruh kondisi budidaya. Kondisi yang belum memiliki aturan ditampilkan sebagai belum dapat dihitung, bukan diberi kebutuhan nol. Pengujian ketepatan implementasi rumus juga dibedakan dari pengujian efektivitas pemberian pakan di lapangan.

## 2.2 Framework Flutter dan Android

### 2.2.1 Flutter dan Bahasa Dart

Flutter merupakan perangkat pengembangan antarmuka yang dapat digunakan pada beberapa platform. Antarmukanya disusun melalui *widget*, yaitu unsur pembentuk tampilan yang dapat digabungkan menjadi halaman aplikasi. Flutter menggunakan pendekatan deklaratif: tampilan dibentuk berdasarkan keadaan atau *state* aplikasi, kemudian diperbarui ketika keadaan tersebut berubah. Konsep ini mendukung penyajian tampilan yang mengikuti perubahan data. [Flutter, “Flutter architectural overview”](https://docs.flutter.dev/resources/architectural-overview).

FishCare menggunakan Flutter dan bahasa Dart untuk membangun antarmuka serta aturan aplikasi. Walaupun Flutter mendukung beberapa platform, ruang lingkup proyek ini tetap Android. Penggunaan Flutter tidak menjadi dasar untuk menyatakan bahwa FishCare telah tersedia atau diuji pada platform lain.

Pada FishCare, perubahan state terjadi ketika pengguna menyimpan kolam, menambahkan stok, mencatat grading, atau menyelesaikan pemberian pakan. Setelah penyimpanan berhasil, informasi yang berkaitan perlu diperbarui. Sebagai contoh, pemberian pakan memengaruhi status jadwal, jumlah stok, riwayat kegiatan, dan ringkasan laporan. Pembaruan tampilan harus mengikuti data yang telah tersimpan agar pengguna tidak melihat informasi yang saling bertentangan.

### 2.2.2 Pemisahan Tanggung Jawab Aplikasi

Struktur FishCare memisahkan antarmuka dan state, aturan bisnis, repository, serta penyimpanan atau akses layanan eksternal. Antarmuka menerima masukan dan menyajikan hasil. Aturan bisnis menjalankan perhitungan serta pemeriksaan nilai. Repository mengatur pembacaan dan penyimpanan data, sedangkan SQLite dan klien API menangani sumber data masing-masing.

Pemisahan tersebut membantu penggunaan satu aturan perhitungan pada beberapa bagian aplikasi. Perhitungan kebutuhan pakan pada detail siklus, jadwal pemberian, dan form pencatatan perlu memakai dasar yang sama. Jika setiap layar memiliki rumus tersendiri, perubahan aturan berisiko menghasilkan angka berbeda untuk kondisi ikan yang sama. Dalam FishCare, aturan bersama juga memudahkan pengujian perhitungan tanpa harus menjalankan seluruh interaksi layar.

### 2.2.3 Android sebagai Platform Pelaksanaan

Android menjadi platform pelaksanaan aplikasi sesuai ruang lingkup proyek. Integrasi dengan fasilitas perangkat diperlukan ketika pengguna mengambil lokasi saat ini atau memilih tujuan penyimpanan laporan. Penggunaan fasilitas tersebut mengikuti tindakan pengguna dan dibedakan dari pencatatan kegiatan yang berlangsung di basis data lokal.

Kemampuan aplikasi tidak cukup dinilai dari keberhasilan menjalankan perhitungan Dart. Hasil build Android, pemasangan, penyimpanan data, dan interaksi pada perangkat merupakan bagian verifikasi yang berbeda. Oleh karena itu, pembahasan hasil pengujian pada bab berikutnya perlu menyebutkan bukti masing-masing, tanpa menyamakan keberhasilan tes aturan dengan keberhasilan seluruh alur pada HP.

## 2.3 UI dan UX dalam Aplikasi Mobile

*User interface* (UI) berkaitan dengan unsur tampilan dan kendali yang digunakan untuk berinteraksi dengan aplikasi. *User experience* (UX) berkaitan dengan pengalaman pengguna dalam menyelesaikan kegiatan melalui alur tersebut. Pada FishCare, keduanya diarahkan untuk membantu pengguna memahami data, memasukkan angka dengan benar, dan mengetahui hasil tindakan penyimpanan.

Pedoman aksesibilitas Android menekankan keterbacaan teks melalui kontras yang memadai. Prinsip tersebut relevan bagi aplikasi yang menyajikan banyak angka, satuan, dan status. Informasi perlu dapat dibaca tanpa bergantung hanya pada perbedaan warna. [Android Developers, “Make apps more accessible”](https://developer.android.com/guide/topics/ui/accessibility/apps).

### 2.3.1 Navigasi dan Penyajian Informasi

FishCare membagi kegiatan utama ke dalam empat menu, yaitu Beranda, Kolam, Pakan, dan Laporan. Beranda menyajikan informasi awal, Kolam menghubungkan identitas kolam dengan siklus dan kegiatan pemeliharaan, Pakan menyediakan pencatatan pemberian serta persediaan, sedangkan Laporan menyajikan ringkasan dan rincian transaksi. Pembagian ini menjadi dasar pengelompokan fungsi agar pengguna dapat menuju kegiatan yang dibutuhkan.

Penyajian informasi juga perlu membedakan keadaan terkini dan riwayat. Bobot terakhir menunjukkan dasar perhitungan saat ini, sedangkan bobot yang tersimpan pada transaksi menunjukkan keadaan saat kegiatan tersebut dicatat. Demikian pula, ringkasan periode berbeda dari ringkasan seluruh siklus. Label yang jelas diperlukan agar angka dari konteks berbeda tidak ditafsirkan sebagai satu total yang sama.

### 2.3.2 Form, Validasi, dan Konfirmasi

Form FishCare menggunakan satuan yang sesuai dengan jenis data, seperti ekor, gram, derajat Celsius, dan rupiah. Validasi diperlukan untuk menolak nilai yang tidak sesuai, misalnya jumlah ikan negatif, pemberian melebihi stok, atau panen melebihi populasi. Pesan kesalahan perlu menjelaskan bagian yang harus diperbaiki sehingga pengguna dapat melanjutkan pencatatan.

Pada pemberian pakan, kebutuhan normal, rekomendasi, jumlah aktual, harga per kilogram, dan biaya memiliki arti berbeda. Form perlu memperlihatkan perbedaan tersebut sebelum pengguna mengonfirmasi transaksi. Input suhu air dan pH dimulai dari keadaan kosong pada setiap pemberian baru agar nilai sebelumnya tidak dianggap sebagai pengukuran saat ini. Perubahan rekomendasi juga tidak boleh diam-diam mengganti jumlah aktual yang telah diketik.

Konfirmasi memberi kesempatan kepada pengguna untuk memeriksa kegiatan yang akan disimpan. Namun, konfirmasi pada antarmuka tidak menggantikan validasi penyimpanan. Stok dan kondisi siklus tetap harus diperiksa ketika transaksi dijalankan, terutama apabila data berubah setelah pratinjau ditampilkan.

### 2.3.3 Umpan Balik dan Keadaan Aplikasi

Keadaan memuat, kosong, gagal, dan berhasil perlu dibedakan. Laporan tanpa transaksi bukan kegagalan membaca data, sedangkan rekomendasi yang belum tersedia bukan rekomendasi nol. Pada ekspor, pembatalan pemilih file juga tidak boleh ditampilkan sebagai keberhasilan menyimpan laporan.

Dalam FishCare, prinsip ini diterapkan melalui keterangan status dan hasil tindakan. Pengguna perlu mengetahui apakah data telah tersimpan, perlu diperiksa kembali, atau belum tersedia. Pencegahan ketukan berulang saat proses berlangsung membantu alur penggunaan, sedangkan pencegahan transaksi ganda tetap ditangani pada lapisan penyimpanan.

## 2.4 Teknologi Backend dan API

### 2.4.1 Pengolahan Data Tanpa Backend Sendiri

Backend pada aplikasi berbasis jaringan umumnya menangani pengolahan dan penyimpanan data di sisi server. FishCare tidak menggunakan backend milik proyek, layanan akun, atau sinkronisasi cloud. Pengolahan kegiatan utama dilakukan dalam aplikasi, dengan SQLite sebagai basis data lokal. Dengan demikian, keberadaan API cuaca tidak berarti seluruh data budidaya disimpan pada server layanan cuaca.

Data kolam dan siklus dihubungkan dengan kegiatan yang sesuai. Hubungan tersebut mendukung penelusuran riwayat, penghitungan populasi, pemakaian pakan, dan penyusunan laporan. Pada aplikasi ini, data yang dibutuhkan untuk menghitung transaksi dipertahankan bersama catatannya agar perubahan kondisi berikutnya tidak mengubah hasil kegiatan terdahulu.

### 2.4.2 SQLite, Transaksi, dan Konsistensi Data

SQLite mendukung transaksi yang bersifat atomik, konsisten, terisolasi, dan tahan simpan, atau dikenal sebagai ACID. Sifat atomik berarti perubahan dalam satu transaksi disimpan seluruhnya atau tidak disimpan sama sekali. Dukungan ini menjadi dasar penyimpanan beberapa perubahan yang harus tetap saling sesuai. [SQLite, “SQLite Is Transactional”](https://www.sqlite.org/transactional.html).

Dalam FishCare, pencatatan pemberian pakan berkaitan dengan jumlah aktual, pengurangan stok, pergerakan persediaan, dan status jadwal. Penyimpanan sebagian dapat menghasilkan kondisi yang keliru, misalnya stok berkurang tanpa catatan pemberian. Karena itu, validasi dan perubahan terkait ditempatkan dalam satu transaksi. Dukungan SQLite perlu disertai aturan aplikasi yang benar; basis data tidak menentukan sendiri batas populasi atau jumlah pakan yang diperbolehkan.

FishCare juga menyimpan snapshot, yaitu nilai yang menggambarkan keadaan saat transaksi dicatat. Snapshot pemberian mencakup informasi yang diperlukan untuk menelusuri perhitungan, seperti jumlah aktual, harga, biaya, dan pengukuran air. Harga baru atau grading berikutnya tidak digunakan untuk menghitung ulang biaya transaksi lama. Prinsip ini menjaga hubungan antara rincian kegiatan dan angka pada laporan.

### 2.4.3 Integrasi API Cuaca Open-Meteo

*Application Programming Interface* (API) menyediakan antarmuka pertukaran data antarsistem. FishCare memanfaatkan Open-Meteo sebagai sumber informasi cuaca berdasarkan koordinat lokasi usaha. Dokumentasi Open-Meteo menjelaskan parameter lokasi serta variabel cuaca, termasuk suhu udara, kode cuaca, dan probabilitas presipitasi. Layanan tersebut menggunakan data model cuaca. [Open-Meteo, “Weather Forecast API”](https://open-meteo.com/en/docs).

Pada FishCare, satu lokasi usaha digunakan untuk informasi cuaca seluruh kolam. Aplikasi perlu menunjukkan lokasi, waktu, serta status data agar pengguna memahami konteks informasi yang dibaca. Apabila pengambilan data gagal, informasi yang tersimpan sebelumnya harus dibedakan dari hasil pembaruan yang berhasil.

Informasi cuaca tidak menggantikan pengukuran air kolam. Suhu udara dari API dan suhu air yang dimasukkan pengguna merupakan data berbeda. Dalam aturan proyek, rekomendasi pemberian memakai masukan pengukuran air pada kegiatan tersebut, bukan perubahan cuaca secara otomatis. Pemisahan ini menjaga fungsi cuaca sebagai informasi tambahan sesuai batasan pada Bab I.

### 2.4.4 Laporan dan Ekspor Data

Laporan FishCare menyusun informasi berdasarkan periode dan pilihan kolam yang sama. Pakan aktual, biaya pakan, kematian, serta jumlah dan nilai panen dihitung dari transaksi yang sesuai dengan filter. Transaksi batal tetap dapat ditelusuri, tetapi tidak dimasukkan ke total kegiatan sah. Ringkasan seluruh siklus disajikan dengan konteks tersendiri.

Ekspor Excel menyediakan salinan laporan untuk diperiksa di luar aplikasi. Implementasi FishCare menghasilkan file `.xlsx` dengan lembar Ringkasan dan Transaksi berdasarkan snapshot laporan yang ditampilkan. Ekspor tersebut merupakan keluaran laporan, bukan pencadangan lengkap basis data dan bukan sarana pemulihan seluruh aplikasi.

Nilai keuangan yang disajikan juga mengikuti batas perhitungan proyek. Hasil setelah biaya pakan diperoleh dari pendapatan panen dikurangi biaya pakan tercatat dalam satu siklus. Karena biaya benih, tenaga kerja, listrik, dan biaya usaha lainnya belum diperhitungkan, hasil tersebut tidak disebut keuntungan bersih. Pembedaan ini diperlukan agar informasi yang disajikan sesuai dengan data yang benar-benar dicatat.

## Referensi Bab II

1. Flutter. Tanpa tahun. *Flutter architectural overview*. https://docs.flutter.dev/resources/architectural-overview. Diakses 1 November 2026.
2. Android Developers. Tanpa tahun. *Make apps more accessible*. https://developer.android.com/guide/topics/ui/accessibility/apps. Diakses 1 November 2026.
3. SQLite. Tanpa tahun. *SQLite Is Transactional*. https://www.sqlite.org/transactional.html. Diakses 1 November 2026.
4. Open-Meteo. Tanpa tahun. *Weather Forecast API*. https://open-meteo.com/en/docs. Diakses 1 November 2026.
5. Tim FishCare. 2026. *PRD FishCare — Rancangan Baru v0.1*, termasuk pembaruan kebutuhan pada bagian 15. Dokumen internal proyek, `docs/PRD_FishCare_Baru_v0.1.md`.
6. Tim FishCare. 2026. *Revisi dosen — Tahap 4: pemberian dengan pengukuran air*. Dokumen internal proyek, `docs/REVISI_DOSEN_TAHAP_4_PEMBERIAN.md`.
7. Tim FishCare. 2026. *Revisi dosen — Tahap 5: ekspor laporan Excel*. Dokumen internal proyek, `docs/REVISI_DOSEN_TAHAP_5_EXCEL.md`.

<!-- Catatan penyusunan: empat subbab utama mengikuti struktur proposal yang digunakan pada Bab I. Referensi internal menjelaskan perilaku FishCare, bukan bukti ilmiah efektivitas aturan pakan. Nomor referensi dapat diselaraskan ketika seluruh bab digabungkan. -->
