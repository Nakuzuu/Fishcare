# Wireframe FishCare

Tanggal: 13 Oktober 2026. Irisan UI M4 dibuat; rancangan visual penuh tetap untuk ditinjau.

## Revisi UI 20 Oktober 2026

Instruksi pengguna terbaru menggantikan penempatan cuaca pada rancangan15Oktober: **header FishCare → kartu cuaca → pakan hari ini → kolam aktif → ringkasan lain**. Cuaca memuat/gagal tidak menghalangi navigasi lokal. Nama lokasi di atas, suhu udara besar, ikon offline, kondisi, prakiraan hujan tanggal yang benar, status cache/pembaruan, waktu ramah serta Open-Meteo. Atur lokasi/Muat ulang/Detail cuaca mudah dijangkau; koordinat lengkap dan waktu asli masuk detail. Lokasi HP tetap label asli tanpa menebak kota. GPS tetap hanya lewat tombol eksplisit pada pengaturan lokasi. FR-08/AT-20–22/41–46.

Detail kolam: nama cukup sekali pada header; Kolam aktif/arsip terpisah dari Siklus aktif/belum ada siklus. Identitas dan Ubah identitas sekunder; jika belum ada siklus, Mulai siklus mendahului riwayat. Riwayat menampilkan jenis/tanggal/status/angka utama, dengan kondisi sebelum/sesudah dan snapshot pada Detail kegiatan. ID database panjang hanya pada detail. Arsipkan tetap terpisah dengan konfirmasi serta validasi penyimpanan lama.

Laporan: filter tanggal/kolam tetap jelas dan tersimpan; Transaksi periode, Kondisi saat ini, Seluruh siklus terpisah. Rupiah Rp45.000; angka dan tanggal ramah. Kartu siklus memakai nama kolam/ikan/tanggal/status dan metrik label–nilai; Detail siklus menyimpan akses ID. Transaksi batal tetap bisa ditelusuri tanpa masuk total. FR-01/02/07, AT-18/19/37–40/46. Lihat [catatan implementasi revisi](UI_RAPIKAN_2026-10-20.md) untuk bukti dan batas verifikasi.

## Desain visual baru 15 Oktober 2026

[Prototipe desain baru](desain/index.html) dan [catatan UI/UX](desain/README.md) menyajikan rancangan visual untuk ditinjau sebelum penyusunan bagian 3.5 proposal. Seluruh data dan tindakan merupakan simulasi desain; tidak mengubah kode aplikasi atau aturan PRD. Rancangan ini belum merupakan persetujuan desain final.

## Cuaca — pengambilan lokasi atas tindakan pengguna

14 Oktober 2026, FR-08/AT-41–45. Beranda kartu Cuaca terkini dan prakiraan: lokasi usaha tersimpan/nama/koordinat/perkiraan, suhu udara (bukan air), kondisi, prakiraan hujan harian/waktu/atribusi/status cache. Lokasi kosong tidak memakai kota contoh atau mengambil HP.

[Ambil lokasi saat ini] → izin foreground bila perlu → progress + [Batalkan pengambilan lokasi] → Calon lokasi (belum disimpan), koordinat/akurasi/perkiraan → [Simpan sebagai lokasi usaha] + [Batalkan calon lokasi] → dialog Batal/Konfirmasi simpan. [Pilih lokasi manual] membuka kota/kecamatan, Cari, hasil berwilayah; memilih hasil juga hanya calon. Field dan dialog scrollable/SafeArea; Kembali tetap tersedia.

Error GPS/izin/timeout punya penjelasan + Coba lagi pengambilan lokasi/manual; gagal simpan punya Periksa lokasi tersimpan. Calon/batal/gagal tidak menimpa lokasi lama. [Muat ulang cuaca] memakai koordinat tersimpan; tombol tidak mengambil HP, tidak ada background/pelacakan. Cache dan lokasi lama tidak tampil berlabel lokasi baru setelah konfirmasi. Rincian hasil uji [TAHAP_CUACA_LOKASI.md](TAHAP_CUACA_LOKASI.md).

## Pembaruan M5 — laporan produk

FR-07, AT-18/19/37–40. M4 belum terverifikasi HP; pemasangan/uji ditunda sampai M4+M5. [M5_IMPLEMENTASI.md](M5_IMPLEMENTASI.md).

```text
Laporan
Tanggal mulai [YYYY-MM-DD kalender]
Tanggal akhir [YYYY-MM-DD kalender]
Kolam [Semua, termasuk arsip v]
[Terapkan filter]
Transaksi periode
Tanggal mulai s.d. akhir (inklusif) · kolam
Pakan aktual    150g     > pendukung
Biaya pakan    Rp1500   > pendukung
Ikan mati      0ekor    > pendukung
Ikan panen     20ekor   > pendukung
Nilai panen    Rp100000 > pendukung
[Riwayat periode (termasuk batal)]
Kondisi saat ini (siklus aktif, bukan periode)
Seluruh siklus (semua tanggal, bukan periode)
```

Pendukung: AppBar Kembali, label tanggal/kolam yang sama, jenis/tanggal/jumlah/kolam arsip, status Sah atau Batal—dikecualikan dari total, Detail. Detail mempertahankan filter dan menampilkan ID/siklus serta snapshot before/after; pemberian aktual/harga/biaya/rate/biomassa, panen bobot/harga/nilai, dan alasan batal. Ini layar baca, tanpa tombol mengubah transaksi. Beranda menampilkan Transaksi hari ini dan Kondisi saat ini, tanpa placeholder laporan yang menutupi data nyata.

Mobile: ListView bergulir saat keyboard terbuka, input tanggal eksplisit dan picker, dropdown expanded untuk nama panjang. Filter tetap dapat diganti saat loading; loading membersihkan hasil lama, respons lama diabaikan. Kosong: Belum ada transaksi pada filter ini; jika semua batal, total sah0 diberi penjelasan. Gagal: angka bukan nol, Coba lagi. Offline tetap membaca lokal. Beranda/laporan/pendukung terbuka memuat ulang setelah commit/batal tanpa restart; filter laporan disimpan ketika pindah tab. Tidak menampilkan FCR/keuntungan bersih.

## Pembaruan M4 — layar operasional

Menggantikan batas M3 di bawah; uji gabungan M2+M3 lulus menurut pengguna, M4 belum diuji HP. FR-05/06, AT-08/11–17/31–36. [M4_IMPLEMENTASI.md](M4_IMPLEMENTASI.md).

```text
< Detail Kolam
Siklus aktif — kondisi terkini
Populasi100 · Bobot100,00g · Kebutuhan300g
Sudah150g · Sisa150g
[Sampling] [Kematian] [Panen parsial]
[Panen akhir / tutup siklus]
Riwayat kegiatan dan siklus selesai
Sampling · tanggal · Sah/Batal
Jumlah10 · Populasi100→100 · Bobot100→120
[Batalkan kegiatan terakhir] (hanya kandidat)
```

| Form | Field / ringkasan |
|---|---|
| Sampling | Sampel ekor, bobot rata-rata g/ikan; positif maksimal2desimal; ringkasan tidak mengurangi populasi |
| Kematian | Jumlah ekor, populasi terkini; seluruh sisa boleh mati |
| Parsial | Jumlah ekor, bobot rata-rata, harga Rp/kg; ringkasan sisa/biomassa/nilai; wajib menyisakan ikan |
| Akhir | Jumlah read-only seluruh sisa; bobot/harga jika>0; ringkasan penutupan tidak dapat batal. Sisa0 tanpa field bobot/harga/pendapatan |
| Batal | Jenis asal dan alasan wajib; hanya sah terakhir lintas jenis hari ini/active; transaksi memvalidasi lagi |

AppBar Kembali, SafeArea dan ListView mengikuti tinggi keyboard; satuan di field; Tinjau dan simpan→dialog scrollable→Kembali/Konfirmasi. Keyboard ditutup sebelum dialog. Disabled saat busy/hasil belum pasti. Invalid dekat field dan error transaksi; sukses snackbar lalu muat ulang kondisi/riwayat. Gagal teknis menawarkan Pemulihan tindakan, tanpa simpan ID baru otomatis. Offline tetap lokal. Riwayat loading progress, gagal Coba lagi, kosong Belum ada kegiatan operasional.

Riwayat mempertahankan jenis/tanggal/jumlah/kondisi sebelum-sesudah dan alasan batal. Panen menampilkan bobot/harga/nilai snapshot; pemberian harga/biaya snapshot. Closed: tanpa siklus aktif, Mulai siklus dan riwayat tetap, tanpa tombol operasional pada closed. Recovery menampilkan jenis/input/ID; Periksa hasil dahulu, Retry ID sama; committed hanya tutup hasil. Laporan penuh tetap belum tersedia. Contoh adalah ilustrasi AT, bukan acuan budidaya/data bawaan.

## Riwayat rancangan M0–M3

Acuan: [PRD v0.1](PRD_FishCare_Baru_v0.1.md), [alur sistem](ALUR_SISTEM.md), [database](RANCANGAN_DATABASE.md). Baseline usulan PRD bagian 14 masih terbuka; pembulatan O-02 telah diputuskan pengguna pada M2, entri O lainnya tetap terbuka. Nilai yang terlihat dalam contoh adalah ilustrasi AT terisolasi, bukan data bawaan aplikasi atau rekomendasi budidaya.

RV-01–RV-03 telah diputuskan pengguna pada M3. Layar koreksi menunjukkan lama/baru/alasan/selisih; pemulihan menampilkan hasil/niat tersimpan. Retry hanya sesudah Periksa hasil dan memakai ID sama. Ketergantungan sampling/populasi telah diputuskan pengguna M4 di bagian pembaruan. UI M0 tetap entrypoint uji terpisah.

Irisan M2 yang kini dibuat mengikuti layar detail kolam, mulai siklus, rate dan jam di bagian4/5. Kebutuhan dan porsi ditampilkan sebagai rencana, **tanpa tombol Berikan/Lewati** sampai fitur tersebut dibangun. Ringkasan memakai half-up yang sudah disepakati. Input jam memakai picker24jam, zona usaha dikonfirmasi saat start; rincian dan batas uji ada di [M2_IMPLEMENTASI.md](M2_IMPLEMENTASI.md). Layar lain tetap rancangan fitur mendatang, bukan klaim implementasi penuh.

## Keputusan M3 yang menggantikan baseline koreksi sebelumnya

Keputusan pengguna M3 telah dicatat pada PRD bagian 4/5 dan AT-29–31. Bagian rancangan di bawah yang masih menyebut stok masuk tidak dapat dikoreksi, rate/jam/Lewati sebagai penghalang, atau operation hanya hasil commit merupakan baseline historis yang digantikan aturan ini:

- Stok bersama memakai ledger. Koreksi stok masuk menyimpan asal, jumlah efektif lama/baru, alasan dan pergerakan selisih. Baru harus >=0 dan saldo akhir >=0; pratinjau lama yang stale ditolak. Asal tidak dihapus.
- Pemberian sah terakhir hari ini dalam siklus aktif boleh dibatalkan setelah rate/jam/Lewati. Stok dipulihkan tepat lewat reversal, catatan keluar asli tetap dijumlahkan, snapshot lama tidak diubah. M4 memperluas kandidat menjadi kegiatan sah terakhir lintas jenis; lihat bagian pembaruan M4.
- ID niat/payload disimpan sebelum transaksi bisnis. Hasil commit ditulis bersama perubahan bisnis. Setelah restart, baca ID yang sama dan periksa hasil sebelum menawarkan retry eksplisit; tidak memakai ID baru otomatis.
- Lewati membagi ulang sisa hanya ke pending. Jam hari ini tetap, template jam baru tetap besok. Tidak membuat pemberian nol.

Rincian skema versi3, transaksi, UI pemulihan dan uji ada di [M3_IMPLEMENTASI.md](M3_IMPLEMENTASI.md). Uji manual gabungan M2+M3 kemudian dikonfirmasi berhasil oleh pengguna; verifikasi standar tetap sesuai bukti. Pernyataan lama adalah riwayat rancangan, bukan aturan implementasi M3.

## 1. Navigasi dan komponen HP

```text
Beranda ── Pengaturan ── Zona / Lokasi / Backup / Restore / Tentang
   │
   ├── Kartu kolam ── Detail kolam
   └── Kartu slot ── Form pemberian
Kolam ── Daftar ── Form kolam / Detail
                         └── Mulai siklus / Rate / Jam / Sampling
                             Kematian / Panen parsial / Panen akhir
                             Riwayat siklus / Detail transaksi / Batalkan
Pakan ── Pemberian Hari Ini ── Slot ── Berikan / Lewati
      └─ Stok Pakan ── Master / Detail pakan / Stok masuk / Pergerakan
Laporan ── Filter ── Ringkasan ── Transaksi pendukung ── Detail
```

Bottom navigation mempunyai empat label: Beranda, Kolam, Pakan, Laporan. Pengaturan lewat ikon berlabel aksesibilitas di Beranda. Halaman anak mempunyai tombol Kembali dan judul jelas. Tidak ada drawer tambahan atau login. Kembali dari detail transaksi Laporan mempertahankan filter dan posisi daftar.

Aturan komponen (PRD bagian 9; AT-19, AT-27):

- Target lebar awal 360 dp, satu kolom, diuji teks 130% dan HP target. Kartu dapat memanjang; angka penting tidak dipotong dengan ellipsis. Target sentuh usulan minimal 48 dp; status memakai teks dan ikon, bukan warna saja.
- Form full-screen dengan konten dapat digulir, label selalu terlihat, satuan di samping field, kesalahan tepat di bawah field. Tidak menggunakan placeholder sebagai satu-satunya label.
- Keyboard angka hanya mempermudah input; parser tetap memvalidasi. Contoh bantuan: “Tanpa pemisah ribuan: 1500”; desimal: “12,5 atau 12.5, maksimal 2 desimal”. Jumlah/gram/rupiah tidak menerima desimal. `1.500` ditolak semua field angka, tidak ditebak.
- Saat keyboard terbuka, layout mengikuti tinggi area tersisa; tombol utama berada dalam area aman di atas keyboard atau di akhir form yang dapat digulir. Field fokus dan error digulir ke tampilan. Tidak ada tombol penting tertutup bottom navigation/keyboard. Enter/Next memindahkan fokus; Done menutup keyboard, tidak langsung menutup siklus.
- Halaman form/konfirmasi tidak memerlukan bottom navigation. Kembali pertama dapat menutup keyboard; keluar dengan draft berubah meminta “Buang perubahan?” [Tetap mengisi] [Buang]. Batal sebelum simpan tidak menulis data.
- Ringkasan transaksi penting ditampilkan pada halaman konfirmasi yang dapat digulir, bukan dialog panjang terpotong. [Kembali mengubah] [Simpan/Konfirmasi] berlabel tindakan. Double tap dibatasi; storage idempotensi tetap wajib.
- Tidak ada indikator offline yang menghalangi form lokal. Label offline ada pada cuaca/pencarian; keberhasilan lokal tetap “Tersimpan”. Aset/font dibundel. Tidak meminta izin lokasi/notifikasi/penyimpanan luas.

## 2. Kontrak keadaan semua layar

Kontrak ini berlaku pada setiap layar bagian 3–12, ditambah variasi spesifik di bawahnya. FR-01–09; PRD bagian 9; AT-01, AT-19–25.

| Keadaan | Tampilan dan tindakan |
|---|---|
| Loading baca | Indikator pada area isi, header/Kembali aktif; tidak tampilkan nol palsu. Request lama tidak mengganti target/kolam/filter baru |
| Kosong | Pesan khusus konteks dan CTA yang sesuai; form baru = kosong siap diisi, bukan error |
| Berhasil baca | Isi lengkap beserta satuan/status/tanggal; kondisi kini dibedakan dari periode |
| Menyimpan | Teks “Menyimpan…”, tombol simpan nonaktif. Jika hasil belum pasti, cek ID operasi sebelum retry; tidak langsung menganggap gagal |
| Berhasil simpan | Pesan singkat, kembali ke detail/daftar yang telah dimuat ulang; layar terkait membaca data terbaru saat tampil |
| Gagal validasi | Error dekat field; pertahankan input dan fokus; tidak ada perubahan database |
| Gagal baca/simpan | Pesan tindakan yang bisa dilakukan + Coba lagi; draft tetap. Jika simpan sudah commit tetapi baca ulang gagal, sebut “Tersimpan — muat ulang tampilan” |
| Offline | Layar lokal bekerja normal; pencarian/cuaca menunjukkan belum tersedia atau data cache dengan waktu/status |
| Tidak lengkap/terkunci | Jelaskan sebab dan cara memperbaiki; tombol kegiatan nonaktif. Jangan menyamakan rate hilang dengan kebutuhan nol |

## 3. Pengaturan awal dan Beranda

FR-01–04/08; AT-01, AT-19–22, AT-26.

```text
Pengaturan awal
Zona waktu usaha [zona perangkat v]
Tanggal usaha: [hari ini]
Zona dikunci setelah pencatatan pertama*
[Simpan dan mulai]

FishCare                         [Pengaturan]
Hari ini: [tanggal dan zona usaha]
Kolam aktif
[Nama | populasi | bobot | Lihat detail]
Pakan hari ini
[Jam | Kolam | porsi/status | Buka]
Stok perlu diperiksa
[Pakan | saldo gram | Stok masuk]
Cuaca terkini dan prakiraan
[Lokasi | kondisi | suhu udara]
Prakiraan peluang hujan [tanggal]: [nilai/% atau —]
Waktu data: [...]  Diambil: [...]
[Status cache] [Muat ulang/Coba lagi]
[Atribusi Open-Meteo]
Beranda | Kolam | Pakan | Laporan
```

`*` Definisi pengunci zona mengikuti usulan O-06, belum final. Zona belum disimpan membuat penggunaan pertama tetap pada form awal, tetapi tidak membutuhkan internet.

Kosong: “Belum ada pakan” [Buat pakan], “Belum ada kolam” [Buat kolam], “Belum ada siklus aktif” [Buka Kolam]. Tidak membuat data contoh. Stok habis berlabel teks, bukan peringatan kekurangan yang diasumsikan telah diberikan. Kartu cuaca loading sendiri; ringkasan lokal tetap dapat ditekan. Lokasi belum dipilih: [Atur lokasi]. Tidak ada cache/offline: “Cuaca belum tersedia”. Cache gagal update: “Data tersimpan — pembaruan gagal/offline”, waktu tetap terlihat. Null bukan 0; prakiraan tanggal lampau diberi tanggal sebenarnya. Refresh mempunyai hitung mundur jeda 60 detik dan request maksimum 10 detik. Kembali/navigasi tetap aktif.

## 4. Kolam, form identitas, dan detail

FR-01–02/05–06; AT-01, AT-11–14, AT-19, AT-27.

```text
Kolam                            [+ Buat]
[Aktif/Arsip]
[Nama | Aktif/belum ada siklus/selesai | Buka]

< Buat/Ubah kolam
Nama* [................]
Ukuran/catatan dimensi [........] (opsional, O-08)
Catatan [......................] (opsional)
[Simpan kolam]

< Detail [nama]                   [Ubah identitas]
Kondisi saat ini: [status siklus]
[Jenis ikan] [Populasi ekor] [Bobot g/ikan]
[Pakan] [Rate %] [Tanggal tebar]
Kebutuhan terbaru [...] g
[Buka pakan hari ini]
[Sampling] [Kematian] [Panen parsial]
[Ubah rate] [Ubah jam untuk besok]
[Panen akhir/Tutup tanpa panen]
[Riwayat siklus] [Arsip kolam]
```

Daftar kosong memberi CTA Buat kolam; arsip kosong “Belum ada kolam arsip”. Nama duplikat ditolak dekat field. Identitas boleh diedit tanpa mengganti data siklus awal. Ukuran tidak masuk rumus.

Detail tanpa siklus aktif menawarkan [Mulai siklus] dan riwayat bila ada. Siklus aktif: Arsip nonaktif dengan alasan. Siklus selesai: semua kegiatan read-only, tombol Mulai siklus baru bila kolam tidak arsip, riwayat tetap tersedia. Arsip tidak menawarkan kegiatan baru; buka arsip kembali tidak dirancang sebelum O-08 diputuskan. Populasi nol: tombol pemberian nonaktif, CTA Tutup tanpa panen. Database gagal baca: Coba lagi tanpa mengganti data dengan kosong. Offline tidak mengubah perilaku lokal.

## 5. Mulai siklus, rate, dan jam

FR-02/04; AT-02–03, AT-08–10, AT-15, AT-26–27.

```text
< Mulai siklus [kolam]
Tanggal: [hari ini, read-only]
Jenis ikan* [label pengguna]
Jumlah awal* [      ] ekor
Bobot awal* [      ] g/ikan
Pakan* [pilih master v]   [Buat pakan]
Feeding rate* [     ] %
Gunakan acuan Anda/dosen; bukan saran budidaya
Jam pemberian* [HH:mm] [HH:mm] [+ Tambah] [Hapus]
1–6 jam unik
[Tinjau siklus]

< Konfirmasi siklus
[Kolam, ikan, awal, pakan, rate, tanggal, jam]
Kebutuhan [hasil atau Belum bisa dihitung]
Data awal dan pakan dikunci setelah simpan
[Kembali mengubah] [Mulai siklus]

< Ubah rate
Rate tersimpan [...] %
Rate baru* [    ] %
Kebutuhan terbaru [...] | Sudah diberikan [...]
Sisa kebutuhan [...] | Kelebihan [...] bila ada
Berlaku sekarang pada porsi yang masih menunggu
[Tinjau] → [Simpan rate]

< Ubah jam
Hari ini (tetap): [daftar jam]
Berlaku besok [tanggal]: [1–6 jam dapat diubah]
[Simpan jam untuk besok]
```

Pakan master kosong memberi Buat pakan lalu kembali ke draft. Stok nol tidak memblokir mulai siklus tetapi ditunjukkan. Rate kosong/0/negatif/>100/invalid ditolak; tidak menampilkan kebutuhan 0 akibat field kosong. Jam picker, keunikan divalidasi lagi saat simpan. Perubahan jam ulang memperbarui template besok, tidak membuat slot hari ini ganda; label tanggal besok harus aktual pada zona usaha. Jika hari berganti selama form terbuka, tampilkan “Hari sudah berganti — tinjau ulang”, jangan simpan draft bertanggal lama. Loading/sukses/gagal/offline mengikuti kontrak lokal bagian 2.

## 6. Pakan hari ini, pemberian, dan Lewati

FR-03–04; AT-02, AT-04–10, AT-15–16, AT-26–28.

```text
Pakan
[Pemberian Hari Ini] [Stok Pakan]
Tanggal usaha [hari ini]   Kolam [semua/pilih v]
[Kolam | Kebutuhan terbaru 300 g]
Sudah diberikan 150 g | Sisa 150 g
[Kelebihan ... g] bila aktual melebihi kebutuhan
Jam     Rencana    Status          Tindakan
08:00   150 g      Diberikan       [Detail]
16:00   150 g      Menunggu        [Berikan] [Lewati]
[Ubah jam untuk besok]

< Berikan [kolam, jam, tanggal]
Pakan [...] | Stok bersama [...] g
Rencana [...] g | Sisa kebutuhan [...] g
Aktual* [      ] g
Harga tercatat [...] Rp/kg
Biaya pakan berdasarkan harga tercatat [...] Rp
[Tinjau pemberian]

< Konfirmasi pemberian
[Aktual, pakan, jam, harga, biaya, saldo setelah]
[Peringatan melebihi sisa] hanya jika relevan
[Kembali mengubah] [Konfirmasi pemberian]

< Lewati slot
[Kolam, jam, tanggal, rencana]
Tidak mencatat pemberian atau mengurangi stok
[Kembali] [Lewati]
```

Kosong: tidak ada siklus aktif → Buka Kolam. Data rate/bobot tidak lengkap: “Belum bisa dihitung” dengan Buka detail. Slot rencana 0: “Tidak ada sisa kebutuhan”, Berikan nonaktif, Lewati tersedia sesuai baseline O-04. Slot diberikan/dilewati tidak bisa langsung diedit. Semua selesai/dilewati dan masih sisa: “Sisa belum diberikan”; tidak menawarkan slot baru.

Stok kurang: error menampilkan stok aktual saat transaksi, [Ubah jumlah] atau [Stok masuk]. Tidak menyimpan pemberian sebagian otomatis. Harga/perhitungan berubah sejak konfirmasi: tampilkan ringkasan baru untuk ditinjau. Ketukan ganda menghasilkan satu catatan. Lewati usulan O-03 membagi ulang sisa ke pending; status lain tetap. Setelah batal pemberian terakhir, slot kembali menunggu dengan riwayat batal tetap tersedia. Offline: seluruh kegiatan lokal tetap bisa dipakai.

## 7. Stok Pakan, master, dan pergerakan

FR-03; AT-01, AT-04, AT-06–07, AT-15–16, AT-27.

```text
Pakan > Stok Pakan               [+ Buat pakan]
[Pakan | saldo gram | harga Rp/kg | Buka]
[Lihat arsip]

< Buat/Ubah pakan
Nama* [.............]
Harga tercatat* [       ] Rp/kg
[Simpan pakan]

< Detail pakan
[Nama] [Saldo gram] [Harga tercatat Rp/kg]
[Ubah nama/harga] [Stok masuk] [Arsip]
Pergerakan stok
[Tanggal | Masuk/Keluar/Pembalikan | +/- gram | Buka]

< Stok masuk
Pakan [nama, read-only] | Saldo [...] g
Tanggal [hari ini, read-only]
Jumlah* [         ] g
[Tinjau] → [Saldo sesudah, Konfirmasi stok masuk]
```

Master dan stok masuk adalah tindakan terpisah (O-05). Daftar kosong menawarkan Buat pakan; pergerakan kosong menyatakan belum ada stok masuk, saldo 0 sah. Tidak ada field menimpa saldo. Harga wajib positif; pembaruan berlaku berikutnya, bukan metode pembelian/FIFO. Arsip ditolak jika dipakai siklus aktif. M3 menambahkan Tinjau/koreksi jumlah masuk: jumlah lama read-only, baru >=0, alasan wajib, pratinjau selisih, dan konfirmasi. Asal tidak dihapus; saldo/jumlah negatif atau pratinjau lama ditolak. Riwayat menunjukkan lama/baru/alasan. Gagal lokal/draft/offline mengikuti bagian 2.

## 8. Sampling, kematian, dan panen parsial

FR-05; AT-08–09, AT-11–12, AT-15–17, AT-27.

```text
< Sampling [kolam]
Tanggal [hari ini] | Populasi [...] ekor
Jumlah sampel* [     ] ekor
Bobot rata-rata* [     ] g/ikan
Sampling tidak mengurangi populasi
[Tinjau] → [Bobot lama/baru, dampak porsi, Simpan sampling]

< Kematian [kolam]
Tanggal [hari ini] | Populasi [...] ekor
Jumlah mati* [    ] ekor
Populasi sesudah [...] ekor
[Tinjau] → [Konfirmasi kematian]

< Panen parsial [kolam]
Tanggal [hari ini] | Populasi [...] ekor
Jumlah panen* [    ] ekor
Bobot rata-rata panen* [    ] g/ikan
Harga jual* [      ] Rp/kg
Biomassa [...] g | Nilai panen [...] Rp
Populasi sesudah [...] ekor
[Tinjau] → [Konfirmasi panen parsial]
```

Sampling kedua yang masih sah hari ini ditolak dengan tautan ke catatan sah; jika memenuhi aturan koreksi dapat dibatalkan dahulu, tidak ditimpa. Sampel >populasi ditolak. Kematian >populasi ditolak; seluruh populasi boleh mati lalu detail menawarkan Tutup tanpa panen. Panen parsial harus menyisakan minimal satu ikan; seluruh sisa diarahkan Panen akhir. Bobot/harga panen tidak direka dari sampling. Sesudah simpan porsi pending dan laporan diperbarui, transaksi terdahulu tetap. Kondisi kosong = field belum diisi, bukan nilai 0; tidak ada siklus/populasi membuat form kegiatan tidak tersedia. State lain mengikuti bagian 2.

## 9. Panen akhir, riwayat, dan pembatalan

FR-04–07; AT-12–17, AT-25.

```text
< Panen akhir
Jumlah seluruh sisa [read-only] ekor
Bobot rata-rata panen* [    ] g/ikan
Harga jual* [    ] Rp/kg
[Tinjau penutupan]

< Konfirmasi penutupan
[Jumlah | Biomassa | Harga | Nilai]
Siklus akan selesai; slot menunggu dihentikan
Penutupan tidak dapat dibatalkan
[Kembali mengubah] [Panen dan tutup siklus]

< Tutup tanpa panen (populasi 0)
Tidak ada ikan tersisa; tidak ada nilai panen
[Kembali] [Tutup siklus]

< Riwayat siklus [kolam]
[Siklus aktif/selesai | tanggal | Buka]
[Seluruh siklus: total berlabel tersendiri]
[Kegiatan | tanggal/jam | Sah/Batal | Buka]

< Detail transaksi
[Jenis, tanggal, input/snapshot, biaya/nilai, status]
[Jika batal: alasan, waktu, transaksi asal/pembatalan]
[Batalkan kegiatan] jika memenuhi batas
atau [Alasan tidak dapat dibatalkan]

< Batalkan kegiatan
[Asal dan akibat pengembalian stok/populasi/bobot]
Alasan* [........................]
[Kembali] [Konfirmasi pembatalan]
```

Panen akhir tidak menyediakan edit jumlah atau pembatalan siklus selesai. Populasi berubah saat tinjau membuat ringkasan diperbarui sebelum commit. Populasi nol tidak menampilkan form panen atau pendapatan 0 sebagai transaksi panen. Panen ganda dicegah oleh penyimpanan, bukan hanya tombol.

Riwayat kosong “Belum ada kegiatan/siklus”. Semua catatan batal tetap terlihat. M3 memilih pemberian sah terakhir hari ini di siklus aktif; rate/jam/Lewati bukan penghalang. Tombol disertai alasan pembatasan untuk pemberian lebih lama/hari lalu/siklus selesai. Koreksi stok masuk memakai layar selisih, bukan pembatalan. Gagal validasi ulang tidak mengubah sebagian data. Setelah berhasil, detail/pending dimuat ulang; batal dikecualikan dari total aktual/biaya. Aturan lintas kegiatan M4 berlaku pada bagian pembaruan.

## 10. Laporan dan transaksi pendukung

FR-07; AT-18–19.

```text
Laporan
Mulai [tanggal v]  Akhir [tanggal v]
Kolam [Semua/kolam termasuk arsip v]
[Terapkan filter]
Transaksi periode [tanggal mulai–akhir, kolam]
[Pakan ... g] [Biaya pakan ... Rp]
[Ikan mati ... ekor] [Ikan panen ... ekor]
[Nilai panen ... Rp]
[Lihat transaksi pendukung]
Kondisi saat ini (terpisah)
[Kolam | populasi | bobot | status]

< Transaksi pendukung [filter tetap]
[Jenis | tanggal | kolam | jumlah/nilai | Detail]
[Tampilkan catatan batal: label dikecualikan dari total]
```

Tanggal mulai >akhir ditolak dekat filter. Kosong: “Tidak ada transaksi sah pada periode ini”, total 0 sah, tautan ubah filter; kondisi kini tetap diberi judul berbeda. Loading/gagal filter baru tidak merelabel hasil lama. Data hasil commit terbaru dibaca saat kembali/pindah tab, filter pengguna dipertahankan jika valid. Ringkasan biaya diberi penjelasan harga tercatat; tidak menampilkan FCR/keuntungan bersih. Total seluruh siklus berada di riwayat siklus dengan label berbeda. Offline normal.

## 11. Pengaturan, zona, lokasi, dan tentang

FR-08–09; AT-01, AT-20–22, AT-26.

```text
< Pengaturan
[Zona waktu usaha: ... | Terkunci/dapat diubah]
[Lokasi cuaca: belum dipilih/nama]
[Backup: Belum pernah backup/waktu berhasil]
[Buat backup] [Pulihkan dari file]
[Tentang]

< Zona waktu
[Pilih zona v] [Tanggal/jam usaha saat ini]
[Simpan zona] atau [Terkunci setelah transaksi pertama]

< Lokasi cuaca
Kota/kecamatan [................] [Cari]
[Nama | wilayah administratif | negara | Pilih]
[Simpan lokasi terpilih]

< Tentang
FishCare [versi aplikasi saat tersedia]
Data lokal; cuaca model, bukan sensor air kolam
[Atribusi/link Open-Meteo]
Uninstall/clear data dapat menghapus data lokal
Simpan file backup di luar penyimpanan privat aplikasi
```

Lokasi kosong menjelaskan pencarian membutuhkan internet, tetapi kolam tetap dapat dibuat. Cari adalah pilihan desain yang memenuhi alternatif PRD tanpa debounce tambahan. Query kosong ditolak; loading hanya daftar hasil, Kembali aktif. Hasil kosong: “Lokasi tidak ditemukan — ubah kata pencarian”. Gagal/offline: pertahankan lokasi lama, Coba lagi. Pilihan baru hanya disimpan setelah konfirmasi; hasil request lama diabaikan. Zona terkunci mengikuti O-06 dan tidak dapat diubah lewat form; restore memulihkan zona dataset, tidak menafsirkan ulang tanggal lama. Tentang berupa informasi statis lokal; link memerlukan jaringan, tanpa memblokir membaca teks.

## 12. Backup dan restore

FR-09; AT-23–25.

```text
< Backup
Terakhir berhasil: [Belum pernah backup/waktu]
Seluruh data dan riwayat pembatalan akan disalin
[Buat file backup] → pemilih sistem
[Membuat/Menyimpan...] → [Backup tersimpan]

< Restore
Mengganti seluruh data, bukan menggabungkan
[Pilih file] → pemilih sistem
[Memeriksa file...]
Ringkasan: versi, waktu ekspor, zona,
jumlah kolam/siklus/transaksi
[Kembali] [Tinjau penggantian]

< Konfirmasi restore
Data saat ini akan diganti oleh isi file ini
Salinan pemulihan lokal dibuat sebelum penggantian
[Batal] [Ganti data dan pulihkan]
[Menyiapkan salinan/Memulihkan...]
→ [Pemulihan berhasil] [Kembali ke Beranda]
```

Backup kosong berarti belum pernah backup, bukan gagal. Batal pemilih kembali tanpa status sukses. Gagal tulis mempertahankan metadata lama dan menawarkan Coba lagi. File tersimpan tetapi metadata lokal gagal ditampilkan dengan dua status terpisah.

Restore tanpa file menonaktifkan konfirmasi. File rusak/tabel hilang/versi tak didukung/relasi salah memberi pesan penolakan dan Pilih file lain; data aktif tetap. Salinan pemulihan gagal menghentikan restore. Selama fase mutasi, operasi tulis lain diblokir dengan pesan “Sedang memulihkan data”; tidak ada tombol Batal yang berpura-pura dapat membatalkan commit. Kembali sebelum mutasi boleh batal; setelah hasil belum pasti periksa status dan muat ulang. Gagal transaksi rollback; sukses menghapus state UI lama dan memuat ulang seluruh halaman. Backup/restore file lokal berfungsi offline; cache cuaca setelah restore boleh belum tersedia.

## 13. Cakupan, keputusan terbuka, dan pemeriksaan berikutnya

| Layar | FR | AT yang didukung rancangan |
|---|---|---|
| Awal/Beranda | FR-01–04, FR-08 | AT-01, AT-19–22, AT-26 |
| Kolam/siklus/rate/jam | FR-01–02, FR-04 | AT-02–03, AT-10, AT-13–15, AT-27 |
| Pakan/pemberian/stok | FR-03–04 | AT-04–10, AT-15–16, AT-25–28 |
| Sampling/kematian/panen/riwayat | FR-05–06, FR-04/07 | AT-08–09, AT-11–17, AT-25 |
| Laporan | FR-07 | AT-18–19 |
| Lokasi/cuaca | FR-08 | AT-01, AT-20–22 |
| Backup/restore | FR-09 | AT-23–25 |

O-01 menentukan pesan/tombol koreksi; O-02 angka ringkasan (half-up telah disepakati); O-03 redistribusi Lewati; O-04 tombol Berikan porsi nol; O-05 master; O-06 zona terkunci; O-07 status slot saat tutup; O-08 ukuran/arsip; O-09 status provisional. Peninjauan bagian 14 PRD tetap diperlukan. Keputusan half-up pengguna M2 telah diselaraskan pada PRD; rancangan lain tidak menambah fitur di luar lingkup.

Pemeriksaan rancangan: jalur dari awal sampai laporan tersedia; semua form memakai kontrak state bagian 2; snapshot biaya/panen tidak dipengaruhi input baru; jam besok dan porsi hari ini dipisahkan; data lokal tidak bergantung cuaca. AT dipetakan sebagai cakupan desain, belum hasil uji aplikasi.

Saat implementasi kelak, uji tiap form pada 360 dp, teks 130%, keyboard terbuka, tombol Kembali, draft saat ganti hari, double tap, navigasi setelah simpan, dan dataset target PRD. Sasaran 2 detik halaman/1 detik simpan harus diukur pada HP, belum diklaim tercapai. Rancangan siap ditinjau sebagai masukan M0; tidak ada implementasi/M0 dijalankan dalam tugas ini.



