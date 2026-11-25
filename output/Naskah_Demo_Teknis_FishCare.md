# Naskah teknis demo FishCare V2
## Enam penyaji · aplikasi versi 0.12.0+17

Gunakan satu HP dan satu **Kolam Demo**. Bagian **Ucapkan** adalah naskah utama. Instruksi **Tunjukkan** adalah urutan layar. Bagian **Bedah kode** bisa dibuka di laptop setelah aksi berhasil atau dipakai saat dosen meminta penjelasan teknis. Alokasikan sekitar 12 menit untuk naskah utama dan navigasi. Pembahasan kode lengkap memerlukan waktu tambahan.

Konteks yang berlaku untuk seluruh demo: Flutter menampilkan layar dan menerima input. Fungsi Dart menangani rumus dan validasi. Repository menghubungkan layar dengan SQLite untuk data budidaya. Jalur cuaca menggunakan API eksternal dan cache lokal. Angka budidaya dalam naskah adalah data simulasi yang kalian masukkan ke aplikasi.

### Data bersama untuk latihan

| Bagian | Isi | Hasil yang ditunjukkan |
|---|---|---|
| Pakan | Pelet Demo, Rp25.000/kg, stok masuk **10.000 g** | Saldo 10.000 g |
| Awal siklus | Kolam Demo, lele, 100 ekor, 100 g/ekor, 2 jam pemberian | Biomassa 10 kg, rate 2%, kebutuhan 200 g/hari, 100 g/slot |
| Pemberian | 1 slot, suhu air 28 °C, pH 7, aktual **100 g** | Rekomendasi 100 g, biaya Rp2.500, saldo 9.900 g |
| Grading | 10 ekor sampel, rata-rata 120 g/ekor | Populasi tetap 100, kebutuhan normal 240 g/hari |
| Kematian | 2 ekor | Populasi 98 ekor |
| Panen sebagian | 10 ekor, rata-rata 120 g/ekor, Rp25.000/kg | 1,20 kg, Rp30.000, sisa 88 ekor |
| Panen akhir | Jumlah otomatis 88 ekor, rata-rata 120 g/ekor, Rp25.000/kg | 10,56 kg, Rp264.000, siklus selesai |
| Ringkasan | 2 transaksi panen dan 1 pemberian aktual | Panen 98 ekor atau 11,76 kg, pendapatan Rp294.000, hasil setelah biaya pakan Rp291.500 |

Gunakan harga jual Rp25.000/kg sebagai contoh. Angka itu kebetulan sama dengan harga pakan, tetapi berasal dari input yang berbeda. Gunakan dua jam berbeda yang sudah diuji pada HP. Angka 100 g aktual menggantikan contoh 200 g sebelumnya supaya sesuai dengan satu dari dua slot.

---

## Anggota 1 · Pembukaan, Beranda, lokasi dan cuaca · 1,5 menit

**Tunjukkan di HP**

1. Buka **Beranda**. Tunjuk kartu cuaca, nama lokasi usaha, suhu udara, kondisi, dan waktu yang tampil. Jika data berstatus cache atau gagal dimuat, sebutkan status yang terlihat.
2. Buka **Lokasi usaha**. Tunjuk opsi **Ambil lokasi saat ini** dan pencarian lokasi. Perlihatkan langkah **Simpan sebagai lokasi usaha**. Kalau lokasi yang disiapkan sudah benar, cukup tampilkan layar dan kembali ke Beranda.
3. Buka tab **Pakan** sebelum menyerahkan HP.

**Ucapkan**

> “Selamat pagi, Bapak/Ibu. Kami akan memperagakan FishCare, aplikasi Android untuk mencatat budidaya ikan. Contohnya satu siklus lele, mulai dari stok pakan hingga laporan panen.”
>
> “Di Beranda ada informasi cuaca untuk lokasi usaha. Koordinatnya berasal dari pilihan pengguna. Pengguna bisa mencari nama tempat atau mengambil posisi HP, lalu mengonfirmasi lokasi yang akan disimpan. Saat cuaca dimuat ulang, aplikasi memakai koordinat lokasi usaha yang sudah disimpan.”
>
> “Data cuaca berasal dari Open-Meteo. Aplikasi mengirim lintang dan bujur, lalu menampilkan suhu udara dan kondisi cuaca dari respons API. Tanggal dan status pada kartu membantu pengguna mengetahui waktu dan keadaan data yang sedang ditampilkan. Pencatatan kolam tetap tersedia saat internet putus karena data kolam disimpan di SQLite pada perangkat.”
>
> “Selanjutnya, [nama anggota 2] akan menyiapkan pakan dan stok untuk kolam yang kita pakai.”

**Bedah kode dan sumber**

- Buka [weather_api.dart:86](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/weather_api.dart:86>). Tunjuk pemanggilan `Uri.https('api.open-meteo.com', '/v1/forecast', ...)`, parameter `latitude`, `longitude`, dan `current: temperature_2m,weather_code`. Respons diubah menjadi `ProductWeather`. Pencarian nama tempat menggunakan endpoint `/v1/search` pada Geocoding API.
- Buka [weather_controller.dart:189](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/weather_controller.dart:189>) dan [weather_store.dart:26](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/weather_store.dart:26>). Jelaskan bahwa hasil terkait lokasi disimpan pada `weather_cache`. Saat gagal mengambil data baru, pengguna dapat melihat cache untuk lokasi tersebut jika tersedia. Kartu menunjukkan status yang sesuai.
- Jika dosen bertanya apakah angka cuaca dipakai sebagai suhu air, jawab, “Kartu cuaca menampilkan suhu udara dari API. Pemberian pakan meminta suhu air kolam dan pH yang diisikan pengguna pada form.”
- Acuan [PRD bagian 6 / FR-08](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/docs/PRD_FishCare_Baru_v0.1.md:227>), [Open-Meteo Forecast API](https://open-meteo.com/en/docs), dan [Open-Meteo Geocoding API](https://open-meteo.com/en/docs/geocoding-api).

## Anggota 2 · Master pakan, harga, dan stok · 1,5 menit

**Tunjukkan di HP**

1. Pada tab **Pakan**, tambah **Pelet Demo** dengan harga **25000** pada isian harga per kg. Simpan dan buka detail pakan.
2. Pilih **Stok masuk**, isi **10000** pada field gram, lalu konfirmasi. Tunjuk saldo **10.000 g** dan baris stok masuk pada riwayat.
3. Jika ditanya, tunjukkan letak koreksi stok pada catatan yang relevan. Untuk skenario ini cukup tunjukkan letaknya agar angka yang dipakai anggota berikutnya tetap konsisten.

**Ucapkan**

> “Saya menambahkan Pelet Demo dengan harga Rp25.000 per kilogram. Nama dan harga disimpan sebagai data pakan. Untuk memasukkan barang yang tersedia, pengguna membuat catatan stok masuk.”
>
> “Karena satuan form ini gram, 10 kilogram saya masukkan sebagai 10.000 gram. Setelah disimpan, saldo bertambah. Di sini kita juga bisa melihat pergerakan stoknya.”
>
> “Saldo diperoleh dari penjumlahan pergerakan stok untuk jenis pakan ini. Stok masuk menambah saldo. Saat nanti pakan dipakai, pemakaian mengurangi saldo. Kalau ada kesalahan input stok masuk, koreksi menyimpan selisih dan alasannya, sehingga catatan lama masih bisa ditelusuri.”
>
> “Pakan sudah tersedia. Berikutnya [nama anggota 3] akan memilih pakan ini saat memulai siklus lele.”

**Bedah kode dan sumber**

- Buka [master_repository.dart:145](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/master_repository.dart:145>) untuk titik pembukaan database SQLite, lalu [feed_repository.dart:22](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/feed_repository.dart:22>). Pada `balanceIn()`, tunjuk `stock_movements`, filter `feed_id=?`, dan penjumlahan `delta_g`. Saldo mengikuti jenis pakan, sehingga jenis pakan yang sama bisa dipakai beberapa kolam.
- Buka [feed_repository.dart:316](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/feed_repository.dart:316>). Tunjuk bahwa stok masuk harus positif dan jenis pakan harus aktif sebelum `_movement(..., 'in', amount, ...)`. Koreksi memakai selisih dari jumlah yang dikoreksi, menyimpan alasan, dan memeriksa saldo hasil koreksi.
- Jika dosen bertanya kapan biaya masuk laporan, jawab, “Rp25.000/kg adalah harga master. Biaya pemakaian baru tercatat saat ada pemberian aktual. Contohnya akan dihitung pada giliran keempat.”
- Acuan **FR-03** pada [PRD FishCare](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/docs/PRD_FishCare_Baru_v0.1.md>).

## Anggota 3 · Kolam, siklus, dan kebutuhan pakan normal · 2 menit

**Tunjukkan di HP**

1. Buka **Kolam** → **Tambah kolam** → isi **Kolam Demo**, lalu simpan.
2. Buka detail kolam → **Mulai siklus**. Isi **lele**, **100 ekor**, bobot **100 g/ikan**, pilih **Pelet Demo**, isi dua jam yang telah diuji. Jika form meminta zona usaha untuk transaksi pertama, pilih zona sesuai lokasi demo.
3. Tinjau dan simpan. Tunjuk status siklus, populasi, bobot, kebutuhan **200 g/hari**, dan dua porsi normal **100 g**.

**Ucapkan**

> “Data kolam menyimpan identitas tempatnya. Siklus menyimpan data satu periode budidaya, seperti jenis ikan, populasi, bobot, pakan, dan jadwal. Dengan begitu, setelah satu siklus selesai, riwayatnya masih bisa dilihat dari kolam yang sama.”
>
> “Kita isi 100 ekor dengan bobot rata-rata 100 gram. Perkalian populasi dan bobot menghasilkan biomassa 10.000 gram. Untuk bobot di atas 70 gram, aturan FishCare memilih rate 2% per hari. Jadi kebutuhan normalnya 10.000 dikali 2%, yaitu 200 gram per hari. Dengan dua jadwal, porsi normalnya 100 gram per slot.”
>
> “Acuan tabel bobot berasal dari rancangan RSNI 6484-6:2024 tentang pembesaran lele bioflok, sebagaimana dicatat di PRD proyek. FishCare mengadaptasi batas intervalnya supaya bobot desimal masuk ke kelompok yang jelas.”
>
> “Ini porsi normal berdasarkan kondisi ikan dan jumlah jadwal. Selanjutnya [nama anggota 4] akan menunjukkan bagaimana kondisi air dipakai saat satu pemberian dicatat.”

**Bedah kode dan sumber**

- Buka [cycle_repository.dart:304](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/cycle_repository.dart:304>). `_startTransaction()` memvalidasi operasi, memastikan kolam memenuhi syarat untuk memulai siklus, lalu menyimpan siklus dan jadwal di dalam transaksi. Tunjuk penyimpanan `cycles` dan `cycle_times` sekitar baris 405–424.
- Buka [feeding_policy.dart:21](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/feeding_policy.dart:21>). `rateForWeight()` memakai bobot dalam perseratus gram. Pada kode, batas 70 g adalah 7000, dan nilai rate 200 berarti 2,00%. `normalFeedingPlan()` memanggil `dailyNeed()` dan `splitGrams()`.
- Buka [cycle_rules.dart:101](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/cycle_rules.dart:101>). Jelaskan bahwa kebutuhan harian dibulatkan ke gram. `splitGrams()` membagi gram bulat dan memberi sisa satu gram ke slot paling awal sampai habis. Contoh tambahan: 201 g dengan dua slot menjadi 101 g dan 100 g.
- Jika ditanya sumber asli, sebutkan bahwa PRD mencatat dokumen `rsni3_6484-6.pdf` bagian 5.4, 5.6 dan Tabel 1–2. Berkas asli dirujuk dalam catatan proyek. Interval kontinu dan pemakaiannya sejak awal siklus adalah keputusan implementasi yang didokumentasikan.
- Acuan **FR-01/02/04**, [PRD §15.8–15.10](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/docs/PRD_FishCare_Baru_v0.1.md:481>).

## Anggota 4 · Pengukuran air, rekomendasi, dan transaksi pemberian · 2 menit

**Tunjukkan di HP**

1. Pilih satu slot menunggu pada detail Kolam Demo, lalu tekan **Berikan**.
2. Isi suhu air **28 °C** dan **pH 7**. Tunjuk rekomendasi **100 g**. Isi aktual **100 g** atau gunakan tombol pengisian jumlah rekomendasi bila tersedia.
3. Tunjuk harga per kg dan biaya **Rp2.500** sebelum konfirmasi. Simpan, lalu tunjuk status **Diberikan** dan riwayat. Buka saldo **9.900 g** bila waktu cukup, lalu kembali ke detail kolam.

**Ucapkan**

> “Setiap pemberian meminta input suhu air kolam dan pH. Pada simulasi ini saya isi 28 derajat dan pH 7. Karena masuk rentang normal aturan proyek, rekomendasinya 100% dari porsi normal slot, yaitu 100 gram. Di form ini pengguna tetap mencatat jumlah aktualnya.”
>
> “Kalau suhu di bawah 24 derajat dan pH masih masuk acuan, program mengambil 80% dari porsi normal. Untuk slot 100 gram, rekomendasinya menjadi 80 gram. Kalau suhu 24 sampai sebelum 25 derajat, lebih dari 30 derajat, atau pH di luar 6,5 sampai 8, program memberi peringatan tanpa angka rekomendasi otomatis. Aktual yang memenuhi validasi tetap bisa ditinjau.”
>
> “Saya catat aktual 100 gram. Biayanya 100 dibagi 1.000, lalu dikali Rp25.000, hasilnya Rp2.500. Saat disimpan, aplikasi memeriksa stok, menyimpan transaksi pemberian, mengurangi stok 100 gram, dan menandai slot sebagai Diberikan.”
>
> “Berikutnya [nama anggota 5] akan memperbarui kondisi ikan dan memperagakan panen.”

**Bedah kode dan sumber**

- Buka [feeding_policy.dart:266](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/feeding_policy.dart:266>). `recommendFeedingSlot()` mengambil porsi normal slot, memeriksa pengukuran, lalu memakai faktor 80% atau 100% jika kondisi sesuai aturan. Slot lain mengikuti porsi dan pengukurannya sendiri. Selisih antara aktual dan rekomendasi atau slot dilewati tidak ditambahkan ke slot berikutnya.
- Buka [water_feeding_ui.dart:138](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/water_feeding_ui.dart:138>) untuk telaah data terakhir dan tampilan biaya. Di [cycle_rules.dart:55](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/cycle_rules.dart:55>), `feedingCost()` menghitung biaya dari gram aktual dan harga per kilogram.
- Buka [feed_repository.dart:550](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/feed_repository.dart:550>). Tunjuk pemeriksaan stok, penyimpanan `actual_g`, `price_snapshot`, `cost_snapshot` serta data suhu/pH, lalu gerakan stok `out` dan status `given`. Ketiganya ditangani dalam satu transaksi. Jika stok tidak cukup, perubahan transaksi ditolak. ID tindakan yang sama juga bisa diperiksa ketika percobaan diulang, sehingga satu konfirmasi tidak menggandakan catatan.
- Jika dosen bertanya apa itu snapshot, jawab, “Snapshot menyimpan kondisi dan harga yang berlaku saat pemberian. Kalau harga master berubah besok, transaksi hari ini tetap memperlihatkan biaya Rp2.500.”
- Acuan **FR-04**, [PRD §15.8, §15.10–15.11](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/docs/PRD_FishCare_Baru_v0.1.md:546>), dan [catatan implementasi pemberian](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/docs/REVISI_DOSEN_TAHAP_4_PEMBERIAN.md>).

## Anggota 5 · Grading, kematian, panen sebagian dan panen akhir · 3 menit

**Tunjukkan di HP**

1. Catat **Grading**. Isi jumlah sampel **10 ekor**, bobot rata-rata sampel **120 g/ikan**, lalu tunjukkan bobot baru, populasi **100**, dan tanggal rencana berikutnya.
2. Catat kematian **2 ekor**. Tunjuk perubahan **100 → 98 ekor**.
3. Catat panen sebagian **10 ekor**, bobot rata-rata panen **120 g/ikan**, harga jual **25000**. Tunjuk pratinjau **1,20 kg** dan **Rp30.000**, lalu simpan. Populasi tersisa **88 ekor**.
4. Pilih **Panen akhir / tutup siklus**. Biarkan jumlah diambil otomatis dari sisa populasi. Isi bobot rata-rata **120 g/ikan** dan harga jual **25000**. Tunjuk pratinjau **10,56 kg** dan **Rp264.000**, simpan pada Kolam Demo, lalu tunjuk status siklus selesai.

**Ucapkan**

> “Pertama, grading. Sepuluh ekor ini adalah jumlah sampel yang ditimbang. Saya masukkan bobot rata-rata hasil simulasi, 120 gram per ekor. Populasi tetap 100 karena kegiatan ini memperbarui bobot. Jadwal grading berikutnya disarankan tujuh hari dan bisa diubah. Sesudah bobot berubah, kebutuhan normal menjadi 100 dikali 120 gram dikali 2%, yaitu 240 gram per hari. Porsi pada slot menunggu mengikuti kondisi baru. Pemberian yang tadi sudah dicatat tetap 100 gram.”
>
> “Kematian mengurangi populasi dua ekor, sehingga tinggal 98. Lalu saya panen 10 ekor. Nilainya dihitung dari 10 dikali 120 gram, yaitu 1,2 kilogram, dikali harga Rp25.000 per kilogram. Pendapatan panen sebagian Rp30.000 dan populasi tersisa 88.”
>
> “Pada panen akhir, jumlahnya diambil dari sisa populasi. Delapan puluh delapan ekor dikali 120 gram menghasilkan 10,56 kilogram, senilai Rp264.000. Setelah saya konfirmasi, siklus selesai. [Nama anggota 6] akan menunjukkan bagaimana seluruh kegiatan ini muncul di laporan.”

**Bedah kode dan sumber**

- Buka [lifecycle_ui.dart:267](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/lifecycle_ui.dart:267>) untuk pratinjau kegiatan dan bobot/nilai panen. Buka [m4_operations.dart:74](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/m4_operations.dart:74>) dan tunjuk percabangan jenis kegiatan. `sampling` adalah nama operasi internal untuk Grading. Kode mengubah `afterWeight` untuk grading, dan mengurangi `after` untuk kematian atau panen sebagian. Satu grading sah per siklus di tanggal usaha yang sama.
- Pada panen sebagian, jumlah wajib menyisakan ikan. Saat panen akhir, kode membaca ulang populasi dan membandingkannya dengan jumlah saat konfirmasi. Jika berubah, pengguna diminta meninjau ulang. Saat berhasil, aplikasi menyimpan transaksi panen, menjadikan populasi nol, dan menutup siklus. Karena panen akhir tidak bisa dibatalkan, lakukan pada kolam khusus demo.
- Tunjuk [cycle_rules.dart:61](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/cycle_rules.dart:61>). `harvestValue()` menghitung nilai dari jumlah ikan, bobot rata-rata, dan harga per kg. Berat dan harga panen disimpan bersama transaksi.
- Jika dosen bertanya asal tujuh hari, jawab, “Tujuh hari adalah nilai bawaan pengingat grading pada rancangan FishCare. Pengguna bisa menetapkan tanggal berikutnya.” Fungsi bawaan ada di [grading.dart:22](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/grading.dart:22>).
- Acuan **FR-05/06**, [PRD §15.9](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/docs/PRD_FishCare_Baru_v0.1.md:505>), dan [catatan implementasi Grading](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/docs/REVISI_DOSEN_TAHAP_2_GRADING.md>).

## Anggota 6 · Laporan, hasil panen, Excel, dan penutup · 2 menit

**Tunjukkan di HP**

1. Buka **Laporan**. Pilih **Kolam Demo** dan tanggal yang mencakup kegiatan demo. Tunjuk pemberian **100 g**, biaya **Rp2.500**, kematian **2 ekor**, dan dua catatan panen. Buka satu detail jika ada waktu.
2. Buka **ringkasan siklus selesai**. Tunjuk pendapatan kotor **Rp294.000**, biaya pakan **Rp2.500**, serta hasil setelah biaya pakan **Rp291.500**.
3. Tekan **Ekspor Excel (.xlsx)**, pilih lokasi, simpan, lalu buka lembar **Ringkasan** dan **Transaksi**. Siapkan satu hasil ekspor latihan di HP jika membuka file saat presentasi memerlukan waktu.

**Ucapkan**

> “Di halaman Laporan saya pilih Kolam Demo dan tanggal kegiatan. Data yang tampil berasal dari catatan yang sudah disimpan anggota sebelumnya. Ada pemakaian pakan 100 gram dengan biaya Rp2.500, kematian dua ekor, serta dua panen.”
>
> “Ringkasan siklus selesai menjumlahkan panen sebagian Rp30.000 dan panen akhir Rp264.000, sehingga pendapatan kotornya Rp294.000. Setelah dikurangi biaya pakan yang dipakai Rp2.500, hasilnya Rp291.500. Perhitungan ini hanya mencakup biaya pakan. Biaya seperti bibit, listrik, dan tenaga kerja berada di luar hitungan ini.”
>
> “Laporan periode juga bisa diekspor ke Excel. Lembar Ringkasan memuat total sesuai filter, dan lembar Transaksi memuat catatan per kegiatan. Ini menyelesaikan alur dari stok masuk sampai laporan siklus. Terima kasih. Kami siap menjawab pertanyaan.”

**Bedah kode dan sumber**

- Buka [report_repository.dart:24](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/report_repository.dart:24>). Tunjuk penggabungan `operations`, `cycles`, dan `ponds`, serta `LEFT JOIN` ke `feedings` dan `grading_records`. Kondisi `business_date>=?` dan `business_date<=?` memasukkan kedua tanggal batas. `pond_id` membatasi kolam jika dipilih. Pembacaan seluruh siklus memakai data terpisah yang mencakup transaksi di luar periode filter.
- Buka [report_rules.dart:48](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/report_rules.dart:48>). `reportTotals()` melewati baris dengan tanda pembatalan dan menjumlahkan kolom sesuai metrik. Biaya menggunakan `cost_snapshot`; nilai panen menggunakan `value_rp`. Tunjuk `afterFeed => revenue - feedCost` sekitar baris 101. Nilai 10 kg stok pada harga contoh adalah Rp250.000. Biaya yang masuk ringkasan siklus ini Rp2.500 dari 100 g yang dipakai.
- Buka [report_export.dart:11](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/app_m0/lib/report_export.dart:11>). `reportXlsx(snapshot)` menyusun lembar **Ringkasan** dan **Transaksi** dari snapshot laporan periode. `ReportFileSaver` sekitar baris 225 mengirim byte melalui MethodChannel ke Android. `ReportExport.java` membuka pemilih dokumen dengan `ACTION_CREATE_DOCUMENT`. Pada lembar Transaksi, baris batal dapat tampil berlabel, sedangkan total mengecualikannya.
- Jika ditanya apakah Excel menyimpan semua data aplikasi, jawab, “Excel ini adalah hasil ekspor laporan sesuai filter. Isinya dipakai untuk membaca dan membagikan ringkasan serta rincian periode.”
- Acuan **FR-07**, [PRD §15.14](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/docs/PRD_FishCare_Baru_v0.1.md:582>), [catatan ekspor Excel](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/docs/REVISI_DOSEN_TAHAP_5_EXCEL.md>), dan [catatan hasil panen](<sandbox:/C:/Users/basti/OneDrive/Lampiran/Documents/FishCare V2/docs/HASIL_PANEN_BIAYA_PAKAN.md>).

## Cek saat gladi

- Pastikan nama pakan dan kolam bisa dipakai. Gunakan nama berakhiran **Latihan** saat gladi dan nama **Demo** ketika tampil.
- Siapkan lokasi cuaca, dua jam pemberian, serta semua angka pada tabel di ponsel atau kartu kecil. Jika cuaca gagal diperbarui, tunjukkan status yang tampil dan lanjutkan demo lokal.
- Pastikan anggota 4 mendapat slot menunggu, anggota 5 menyisakan 88 ekor sebelum panen akhir, dan anggota 6 menggunakan tanggal usaha yang sama.
- Simpan satu contoh Excel latihan dan buka di HP. Saat menyajikan kode, siapkan tab editor untuk enam bagian di atas.
- Dasar naskah adalah source FishCare versi 0.12.0+17 dan dokumentasi proyek. Angka tabel adalah hasil perhitungan skenario, sehingga dapat dicocokkan saat gladi di HP.

