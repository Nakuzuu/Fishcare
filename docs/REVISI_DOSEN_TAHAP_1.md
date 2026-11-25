# Revisi dosen — Tahap 1: pemeriksaan dan rancangan

Tanggal: 25 Oktober 2026. Status: analisis selesai; usulan di bawah belum disetujui dan belum diimplementasikan. Acuan kebutuhan: [PRD bagian 15](PRD_FishCare_Baru_v0.1.md#15-catatan-revisi-kebutuhan--25-oktober-2026-arahan-dosen). Tidak mengubah kode, database, SDK, dependency, atau data pengguna.

## 1. Kondisi yang ditemukan

| Area | Bukti yang dibaca | Kesimpulan |
|---|---|---|
| Target aplikasi | `app_m0/pubspec.yaml`, `android/app/build.gradle.kts` | Sumber 0.8.1+9, ID `id.ac.fishcare.m0`; lanjutkan aplikasi ini, tidak scaffold ulang |
| Penyimpanan | `master_repository.dart` | SQLite `fishcare_app.db`, skema 5; migrasi 1–4 ke 5 tersedia |
| Rate | `cycle_repository.dart`, `cycle_ui.dart` | Rate manual disimpan dalam `cycle_rates`; belum ada pemetaan bobot otomatis |
| Rumus | `cycle_rules.dart`, `day_actual.dart` | Integer berskala dan half-up; porsi pending dibagi dari kebutuhan dikurangi aktual sah |
| Jadwal | `cycle_repository.dart`, `_materialize` | Membuka siklus dapat menghitung ulang slot pending dalam transaksi; perubahan jam efektif besok |
| Pemberian | `feed_ui.dart`, `feed_repository.dart` | Harga/kg sudah terlihat pada kartu awal; total biaya dihitung pada konfirmasi. Belum ada input suhu/pH |
| Snapshot | `m3_schema.dart`, `feed_repository.dart` | Harga, biaya, rate, biomassa, porsi dan kebutuhan tersedia; belum ada pengukuran air atau pengurangan suhu |
| Grading | `m4_operations.dart`, `m4_schema.dart`, `lifecycle_ui.dart` | Masih bernama Sampling; jumlah sampel tidak mengurangi populasi; satu catatan sah per tanggal; pembatalan lintas kegiatan memakai urutan commit |
| Pemulihan tindakan | `action_journal.dart`, `action_payload.dart` | Payload kanonik persisten, ID stabil dan status prepared/committed; migrasi tidak boleh mengubah payload retry lama |
| Laporan | `report_repository.dart`, `report_rules.dart`, `report_ui.dart` | Pembacaan snapshot periode dan seluruh siklus tersedia; belum ada ekspor XLSX atau kolom pengukuran |
| Backup/restore | Inventaris `lib`, pencarian implementasi dan README | Belum ditemukan implementasi FR-09. Pemulihan tindakan bukan restore database |
| Dependency | `pubspec.yaml` | Runtime hanya Flutter dan sqflite; belum ada library XLSX/pemilih ekspor |
| Git | Pemeriksaan root dan `app_m0` dengan Git bawaan runtime | Keduanya bukan repository Git; tidak tersedia diff/status untuk membuktikan perubahan lokal. Tidak melakukan inisialisasi Git |

M0 mempunyai bukti historis dari pengguna untuk menjalankan aplikasi, SQLite simpan/baca, API nyata dan penanganan offline. README masih menyatakan persistensi marker setelah force-stop belum dikonfirmasi dan verifikasi standar beberapa tahap terhalang akses SDK. Ini batas bukti historis, bukan pengujian ulang sesi ini.

APK saat pemeriksaan ada di `app_m0/build/app/outputs/flutter-apk/app-debug.apk`, ukuran 79.115.171 byte, waktu filesystem 25 Oktober 2026 22:36:17. Metadata di `build/app/outputs/apk/debug/output-metadata.json` menyebut versi 0.8.1+9. Karena belum memeriksa identitas APK biner, hash silang, dan log build sukses, keberadaan file/metadata itu tidak dinyatakan sebagai build standar sukses pada sesi ini. README/log 20 Oktober perlu direkonsiliasi dengan hasil terminal pengguna yang lebih baru sebelum kandidat demo.

## 2. Masalah utama pembagian porsi

Kode saat ini menghitung `sisa = max(0, kebutuhan terbaru - aktual sah)`, lalu membagi ke pending. Dengan kebutuhan 1.000 g dan dua slot 500 g, pemberian pagi 400 g akan membuat sore 600 g. Ini bertentangan dengan kesepakatan pengurangan suhu tidak dipindahkan.

Usulan: simpan **pengurangan karena suhu** per pemberian sebagai snapshot terpisah. Tidak mencatat pengurangan sebagai pakan aktual, stok keluar, biaya atau transaksi nol.

```text
N = kebutuhan normal harian terbaru
A = total aktual pemberian sah hari ini
D = total pengurangan suhu dari snapshot pemberian sah hari ini
S = max(0, N - A - D)
porsi normal slot pending = pembagian S secara merata menurut urutan jam

Pada pemberian dengan suhu dingin dan pH sesuai:
R = half-up(porsi normal slot × 80 / 100)
pengurangan suhu slot = porsi normal slot - R
```

Usulan ini menjaga aturan lama untuk kekurangan aktual biasa, tetapi mengeluarkan pengurangan suhu dari sisa yang dibagi ulang. D dibekukan saat commit pemberian, bukan saat membuka form atau mengganti suhu. Jika tidak ada angka rekomendasi, D=0 dengan status rekomendasi tidak tersedia; bukan rekomendasi nol. Perhitungan pembulatan dilakukan per slot; D dihitung dari selisih angka bulat supaya konsisten.

| Rangkaian, dua slot dan N awal 1.000 g | Hasil usulan |
|---|---|
| Pagi normal 500, suhu 23 °C/pH 7, R400, aktual400 | D100, sisa sore500; bukan600 |
| Sore suhu normal, aktual500 | Total aktual900, pengurangan100; tidak ada sisa yang harus dikejar |
| Sore juga dingin | Porsi normal500 → R400; total aktual800 dan D200 |
| Pagi R400 tetapi aktual350 | D100; sore550. Yang dialihkan hanya kekurangan aktual50, bukan pengurangan suhu100 |
| Pagi R400 tetapi aktual450 | D100; sore450. Tambahan aktual50 mengurangi sisa |
| Setelah pagi aktual400/D100, grading menaikkan N menjadi1.200 | Sore700; snapshot pagi tidak dihitung ulang |
| Setelah pagi aktual400/D100, N turun menjadi450 | Sisa0; tampilkan aktual400, pengurangan100, dan kondisi target yang telah terlampaui, tanpa stok balik |
| Pagi dilewati tanpa pemberian | Tidak ada D baru; sisa dibagi ke pending sesuai aturan Lewati lama |
| Pagi dingin dibatalkan saat memenuhi syarat pembatalan | Stok aktual pulih; A dan D asal dikecualikan. Pending dihitung ulang; catatan lama tetap |
| Semua slot selesai/dilewati | Tidak membuat slot baru; tampilkan sisa setelah pengurangan bila ada |

Suhu dan pH diukur ulang untuk setiap pemberian baru. Retry ID yang sama memakai pengukuran/payload asli agar satu tindakan tetap identik; membuka kembali form untuk tindakan baru meminta pengukuran baru. Batal konfirmasi tidak menyimpan D atau mengurangi stok.

Usulan label: Kebutuhan normal, Aktual diberikan, Pengurangan karena suhu, Sisa untuk slot menunggu. Kebutuhan normal bukan target aktual yang wajib dihabiskan setelah penyesuaian. Rekomendasi yang belum tersedia tidak ditampilkan sebagai nol. Kasus porsi normal positif tetapi rekomendasi membulat nol perlu pesan dan Lewati, tanpa pemberian nol.

## 3. Keputusan yang perlu pengguna/dosen

### K1 — Batas rate dan awal tebar

Tabel sumber mempunyai celah untuk bobot desimal dan tepat71 g. Usulan interval kontinu: 2–5 g=5%; >5–10=4%; >10–35=3%; >35–50=2,5%; >50–70=2,2%; >70=2%. Bobot <2 g: rekomendasi rate belum tersedia, tanpa menebak kelompok. Ini usulan interpretasi, bukan transkripsi tabel yang telah disetujui.

Aturan awal tebar sumber memberikan rentang1–3%, bukan satu angka pasti. Pilihan perlu arahan dosen: memakai tabel bobot sejak awal sebagai aturan proyek, atau memakai aturan khusus hari awal dengan rate konkret dan definisi hari yang jelas. Jangan otomatis memilih3% atau menambah input manual baru tanpa keputusan. Pemilihan tabel untuk kolam biasa sudah disepakati; tidak perlu meminta persetujuan ulang untuk memilih tabel, tetapi kesesuaian agronominya tetap bukan klaim sertifikasi.

### K2 — Suhu24 sampai <25 °C

Usulan: tanpa angka rekomendasi otomatis, tampilkan peringatan bahwa aturan rentang ini belum tersedia; aktual tetap dapat dicatat. Suhu tepat24 bukan kategori80%. Keputusan perlu dikonfirmasi karena memengaruhi perilaku yang terlihat pengguna.

### K3 — Porsi, pembatalan dan siklus lama

Usulan bagian2 mempertahankan distribusi kekurangan aktual biasa dan Lewati; hanya pengurangan suhu yang dikeluarkan. Persetujuan diperlukan terutama untuk contoh aktual350 → sore550, agar tidak menyamakan seluruh kekurangan dengan pengurangan suhu.

Usulan aktivasi aturan baru pada siklus lama mulai tanggal usaha berikutnya setelah upgrade/aktivasi, dengan catatan versi aturan per hari. Hari berjalan tetap diselesaikan memakai aturan lamanya; aplikasi menjelaskan tanggal berlaku. Siklus baru memakai aturan baru. Langkah ini menghindari perubahan hitungan setengah hari dan mempertahankan prepared intent lama; tidak melakukan perubahan historis. Jika pengguna ingin langsung berlaku hari itu, perlu rancangan konversi slot dan niat belum pasti yang lebih rinci. Pilihan aktivasi adalah keputusan material, belum diterapkan.

## 4. Usulan teknis untuk implementasi berikutnya

Semua berikut berstatus rancangan. Tidak memerlukan keputusan budidaya baru, tetapi perlu dicatat eksplisit sebelum diterapkan.

- Suhu menerima maksimal satu desimal, rentang teknis0–50 °C; pH maksimal dua desimal,0–14 inklusif. Rentang teknis bukan rentang aman budidaya. Koma/titik desimal didukung, pemisah ribuan dan nonfinite ditolak. Simpan suhu ×10 dan pH ×100 sebagai integer. Jika alat pengguna punya presisi berbeda, sesuaikan sebelum implementasi.
- Waktu ukur awalnya waktu usaha/perangkat saat input lengkap untuk draft baru; beri label waktu pencatatan pengukuran manual, bukan waktu sensor otomatis. Hari berganti menuntut peninjauan ulang form. Tidak mengklaim umur pengukuran yang tidak diketahui.
- Nomor grading meningkat per siklus menurut urutan commit, mencakup catatan yang kemudian batal; nomor tidak dipakai ulang. Contoh Grading2 batal → catatan baru Grading3. Migrasi sampling lama diberi nomor dari `operations.seq` tanpa mengubah ID/kind/payload lama. Tampilan dan ekspor memakai nama Grading; kode internal boleh tetap sampling.
- Saat grading disimpan, rencana default tanggal grading+7 hari. Perubahan rencana menyimpan asal dan revision. Pembatalan grading memulihkan rencana sebelumnya hanya jika rencana belum diedit terpisah sejak grading tersebut; rencana edit terpisah dipertahankan dengan penjelasan. Tidak otomatis menciptakan rencana grading historis bagi catatan lama; tawarkan saran dari bobot terakhir dengan label saran.
- Buat versi kebijakan perhitungan agar rate manual lama dan rate otomatis dapat ditelusuri. Untuk aturan baru, perubahan rate manual biasa tidak tersedia; bobot grading mengubah hasil rate otomatis. Perhitungan dan laporan kondisi terkini tidak boleh membaca rate manual lama sebagai rate otomatis.
- Snapshot baru: suhu/pH/waktu, versi aturan, porsi normal, rekomendasi nullable, alasan tidak tersedia, faktor suhu nullable, pengurangan suhu, sumber rate/bobot, serta snapshot lama. Validasi keadaan lengkap dilakukan kembali di transaksi; suhu/pH tidak perlu ditambahkan ke riwayat lama.
- Perbandingan pratinjau mencakup revision bobot/populasi, slot, aturan, harga, dan tanggal; data berubah meminta tinjau ulang sebelum menulis. Stok dibaca saat transaksi. Jangan membuat ID baru untuk retry prepared.
- Migrasi bersifat tambahan, tidak reset. Nomor skema ditetapkan sesuai implementasi aktual setiap tahap, bukan diasumsikan satu loncatan. Data lama memiliki NULL pengukuran dan versi legacy; tidak menulis nilai normal buatan.
- Backup/restore belum tersedia; jangan membangun seluruh FR-09 diam-diam dalam revisi ini. Dokumentasikan entitas baru untuk implementasi backup kelak. Jika implementasi FR-09 muncul sebelum tahap berikutnya, tinjau kompatibilitas dan validasi sesuai versi aktual.
- XLSX: bekukan filter dan baca satu snapshot laporan untuk seluruh sheet. Sheet Ringkasan dan Transaksi memuat konteks periode/kolam; transaksi batal diberi status bila ikut rincian dan dikecualikan dari total. Kolom angka bertipe angka, tanggal berformat jelas, keterangan NULL bukan0. Pemilihan paket dan mekanisme pemilih file menunggu pemeriksaan resmi pada tahap ekspor.

## 5. Urutan pekerjaan dan pemetaan verifikasi

| Tahap berikutnya | Perubahan dan berkas utama yang diperkirakan | FR/AT |
|---|---|---|
| 2: Grading | lifecycle_ui, activity_ui, feed_ui (label), m4_operations, repository/schema, report_ui/rules untuk label | FR-05; AT-51; regresi AT-08/15/17/32/34/36 |
| 3: Aturan pakan | cycle_rules/repository/ui, day_actual, feed_repository, dashboard/report kondisi terkini; aturan baru boleh disiapkan tetapi jangan aktifkan alur produksi sebelum form lengkap tahap4 | FR-02/04; AT-48/54; regresi AT-02/03/08–10/15/28/30/34 |
| 4: Pengukuran dan harga | feed_ui/repository, action payload/recovery, snapshot dan migrasi; hubungkan aktivasi aturan baru secara utuh | FR-03/04; AT-47–50; regresi AT-04–07/15–17/25–27/31/36/38/39 |
| 5: Excel | report_repository/rules/ui/controller dan layanan ekspor baru | FR-07; AT-52/53; regresi AT-18/19/37–40 |
| 6: Kandidat demo | Regresi keseluruhan, README/log/artifact, HP fisik | AT-47–54 dan jalur lama terdampak |

Pengujian harus mencakup migrasi dari versi yang didukung, reopen, prepared intent sebelum upgrade, commit/rollback dan pembatalan. Tes lama yang memakai rate manual dapat dipertahankan untuk kebijakan legacy; tambah skenario kebijakan baru dan jelaskan perubahan ekspektasi, jangan menghapus assertion kegagalan agar lulus.

## 6. Verifikasi tahap ini dan batas hasil

- Selesai: pemeriksaan baca-saja source, skema, tes terdefinisi, README/log historis, metadata artifact dan PRD. Tidak menyatakan tes yang ditemukan sudah lulus.
- Tidak dijalankan: analyze, flutter test, build APK, pemasangan, dan uji HP; tahap ini perencanaan dan tidak mengubah aplikasi. Tidak mengulang percobaan lock SDK historis untuk pekerjaan baca-saja.
- Hanya dokumen ini ditambahkan. PRD tetap menjadi baseline; usulan K1–K3 tidak ditulis sebagai keputusan terkonfirmasi.
- Syarat berikutnya: selesaikan keputusan yang diperlukan masing-masing tahap, lalu jalankan tahap yang diminta. Kekurangan bukti M0/cold restart dicatat untuk verifikasi; bukan alasan mengulang izin atas pekerjaan analisis yang telah diminta.

## 7. Pembaruan setelah diskusi Tahap 1

Lihat [PRD bagian 15.8](PRD_FishCare_Baru_v0.1.md) untuk keputusan terbaru pengguna: tabel bobot langsung berlaku sejak awal tanpa rate awal tebar; interval kontinu ≥2 g disetujui; suhu24–<25 °C memakai peringatan tanpa angka rekomendasi. Persetujuan berasal dari pengguna, bukan bukti persetujuan dosen atas penafsiran interval.

**Rumus bagian2 dan K3 tetap usulan, belum disetujui.** Contoh aktual350 → sore550 telah dipertanyakan pengguna. Arah penjelasan lanjutan adalah sore normal tetap500 tanpa mengejar selisih aktual, tetapi kasus itu belum mendapat konfirmasi eksplisit. Jangan memakai dokumen ini untuk mengaktifkan rumus A+D sebagai keputusan final. Pengurangan suhu pagi tidak dipindahkan ke sore sudah disepakati; penyesuaian karena perubahan biomassa/kelebihan aktual/Lewati/pembatalan masih perlu dirinci. Aturan bobot<2 g dan aktivasi pada siklus lama juga belum diputuskan.

## 8. Keputusan pengganti — 26 Oktober 2026

Pengguna telah mengonfirmasi pada Tahap3: aktual pagi350 dari rekomendasi400 tidak menambah sore500; slot dilewati tidak dibagikan; perubahan kondisi ikan menghasilkan porsi normal dari kebutuhan terbaru dibagi seluruh slot hari ini. Dengan demikian **usulan rumus N−A−D di bagian2/K3 tidak dipakai untuk kebijakan baru**. Lihat PRD15.10 dan [laporan Tahap3](REVISI_DOSEN_TAHAP_3_PAKAN.md). Aktivasi pada siklus lama dan peninjauan budidaya tetap terpisah; belum ada penggantian alur pemberian produksi pada tahap persiapan mesin aturan.
