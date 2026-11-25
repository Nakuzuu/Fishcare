# Revisi dosen — Tahap 3: mesin aturan pakan

Tanggal: **26 Oktober 2026**. Sumber **0.8.3+11**, skema tetap **6**, application ID tetap `id.ac.fishcare.m0`.

**Tahap3 menyiapkan dan menguji mesin aturan bersama beserta pratinjau baca-saja. Aturan baru belum aktif pada UI atau transaksi pemberian produksi.** Aktivasi dilakukan utuh bersama input suhu/pH dan snapshot penyimpanan pada Tahap4. Dengan demikian tidak ada layar produksi yang memakai rate baru sementara layar lain masih menyimpan transaksi dengan aturan lama.

## 1. Keputusan yang dipakai

Acuan PRD15.8 dan15.10. Pengguna telah menjawab tiga keputusan pembagian porsi:

- Pagi normal500 g, dingin direkomendasikan400 g, aktual350 g → sore normal tetap500 g.
- Lewati tidak memindahkan porsi ke slot lain.
- Grading/perubahan populasi menghitung porsi normal dari kebutuhan terbaru dibagi **seluruh jadwal hari ini**, bukan sisa setelah aktual dibagi slot menunggu. Periksa aktual yang berlebih.

Keputusan ini mengganti usulan redistribusi `N−A−D` pada Tahap1 untuk kebijakan baru. Tidak menulis ulang riwayat atau mengubah implementasi legacy yang masih aktif sebelum Tahap4. Peninjauan acuan bioflok untuk kolam biasa oleh dosen tetap ditunda; pemilihan tabel dan batas kontinu sudah keputusan pengguna, bukan klaim sertifikasi.

## 2. Implementasi dan contoh

### Rate dan baseline normal

`lib/feeding_policy.dart` menjadi sumber aturan rate dan rekomendasi, memakai versi `lele_weight_2026_10_v1` dan referensi PRD15.8.

| Bobot rata-rata per ekor | Rate dari biomassa per hari |
|---|---:|
| 2–5 g | 5% |
| >5–10 g | 4% |
| >10–35 g | 3% |
| >35–50 g | 2,5% |
| >50–70 g | 2,2% |
| >70 g | 2% |

- Bobot dipilih dalam integer0,01 gram tanpa pembulatan ke gram utuh. Rate integer0,01 persen. Gunakan `dailyNeed`, `halfUp` dan `splitGrams` yang sudah ada; tidak menggandakan rumus pada layar.
- Bobot awal maupun bobot grading memakai tabel yang sama, tanpa override awal tebar1–3%.
- Populasi/bobot hilang dan bobot<2 g mempunyai status/alasan dengan rate atau kebutuhan **tidak tersedia**. Tidak menggantinya dengan nol, rate manual,5% atau contoh10%.
- Populasi benar-benar nol berbeda dari data belum lengkap. Hasil valid yang membulat nol juga dibedakan; tidak mengizinkan pemberian nol.
- Overflow input, biomassa untuk snapshot, hasil hitung dan akumulasi aktual diperiksa. Biomassa tidak dibulatkan sebelum kebutuhan harian.
- Contoh1.000 ikan ×50 g=50 kg; rate2,5% →1.250 g/hari. Dua slot masing-masing625 g. Pada1.001 ikan kebutuhan1.251 g menjadi626+625 g, dimulai dari jam paling awal.

### Pengukuran air per slot

- Model pengukuran manual membawa suhu dalam0,1 °C, pH dalam0,01 dan waktu pencatatan. Validasi teknis sementara yang dipilih untuk implementasi adalah suhu0–50 °C dan pH0–14, bukan rentang aman budidaya. Form/parser, peninjauan waktu dan pengikatan pengukuran ke tindakan simpan dikerjakan pada Tahap4.
- Suhu25–30 °C dan pH6,5–8 inklusif →100% porsi normal. Suhu<24 °C dengan pH sesuai →80% porsi normal slot, dibulatkan half-up.
- Suhu24–<25 °C, >30 °C, atau pH di luar rentang →peringatan tanpa angka rekomendasi. pH bukan pengali numerik.
- Tanpa pengukuran, rekomendasi belum tersedia. Mesin tidak menyimpan/cache pengukuran slot sebelumnya; tiap pemanggilan memerlukan pengukuran eksplisit. Memanggil perhitungan pagi tidak otomatis mengisi sore.
- Kondisi air di luar acuan tetap mengizinkan **peninjauan input aktual**, bukan otomatis mengizinkan commit. Stok, status siklus, tanggal, revision/pratinjau dan idempotensi tetap wajib diperiksa pada transaksi Tahap4.
- Contoh dua slot normal500+500 g: pagi23 °C/pH7 →400 g, sore27 °C/pH7 →500 g. Tidak ada perpindahan pengurangan100 g.

### Aktivitas harian tanpa redistribusi

`lib/feeding_day.dart` membentuk proyeksi hari dari baseline normal terbaru, status slot dan catatan aktual sah/batal.

- Slot diberikan, dilewati atau dihentikan tidak menerima rekomendasi pemberian baru. Pending mempertahankan bagian normalnya, tanpa tambahan dari selisih aktual atau Lewati.
- Kebutuhan berubah1.000→1.200 g setelah pagi aktual400 g dan terdapat dua jadwal →porsi sore600 g. Kebutuhan turun menjadi500 g →porsi sore250 g. Snapshot pagi tidak dihitung ulang.
- Aktual yang melebihi rekomendasi, porsi normal slot, atau akumulasi normal harian terbaru menghasilkan penanda konfirmasi tambahan. Jika kebutuhan terbaru turun di bawah aktual, kelebihannya tersedia sebagai informasi; tidak ada pengembalian stok otomatis.
- Pembatalan dikecualikan dari total aktual; status slot yang kembali pending membutuhkan pengukuran baru. Catatan aktual batal tetap tersimpan pada input proyeksi dan tidak diubah. Validitas pembatalan serta perubahan stok tetap milik transaksi yang sudah ada/Tahap4.
- Status dan catatan yang bertentangan, catatan duplikat, dua pemberian sah dalam satu slot atau snapshot pemberian hilang ditolak. Tidak diam-diam menjumlah data rusak.
- Hasil aturan dan daftar slot bersifat immutable. Seluruh slot selesai/dilewati menghasilkan daftar pending kosong, bukan penambahan slot baru.

## 3. Integrasi baca-saja dan kompatibilitas

`SqliteCycleRepository` menyediakan:

- `previewWeightPlan`: baseline normal dari kondisi siklus aktif dan jam hari ini.
- `previewWeightPlanIn`: fungsi yang bisa dipanggil dalam transaksi pembaca/penyimpan pada Tahap4 agar tidak perlu membaca kondisi di luar transaksi.
- `previewWeightDay`: baseline dan kondisi slot/aktual/batal dalam satu pembacaan transaksi, tanpa materialisasi slot.

Jika slot hari ini sudah tersimpan, daftar jam itu dipakai; jika belum, baca template efektif tanggal itu tanpa membuat slot baru. Perubahan jam untuk besok tidak mengubah jam hari ini. Tanggal berbeda dari hari usaha saat ini dan siklus nonaktif ditolak.

API ini secara eksplisit pratinjau aturan lele pilihan proyek. Tidak otomatis mengalihkan siklus berlabel ikan lain ke rate lele. Pemilihan mode/aktivasi pada siklus baru dan lama masih bagian migrasi/alur Tahap4.

Rumus aktif lama, operasi start/changeRate/changeTimes/materialisasi, `feed_repository.dart` (commit/ledger), dan lockfile diperiksa identik terhadap salinan sebelum Tahap3. Tidak ada migrasi skema baru, penulisan rate otomatis ke siklus lama, perubahan payload prepared, atau snapshot historis yang diubah. Bukti: `logs/feeding-stage3-preservation.json`.

Snapshot model yang disiapkan mencakup versi/acuan aturan, bobot/populasi/biomassa, kebutuhan normal, porsi per jam, pengukuran, status suhu/pH, rekomendasi nullable, faktor suhu dan pengurangan slot. Ini **representasi data dalam kode**, belum field SQLite baru atau bukti snapshot pemberian baru sudah tersimpan.

## 4. Verifikasi

| Pemeriksaan | Status | Bukti |
|---|---|---|
| `flutter analyze` | **Lulus, tanpa issue** | `logs/feeding-stage3-analyze-final.log` |
| `flutter test --concurrency=1 --reporter expanded` | **98 tes standar lulus** (70 sebelumnya+28 baru) | `logs/feeding-stage3-flutter-test-final.log` |
| `flutter build apk --debug` | **Lulus**, APK0.8.3+11 dibuat pada sesi ini | `logs/feeding-stage3-build.log` |
| Identitas APK biner | Lulus `aapt dump badging`: `id.ac.fishcare.m0`,0.8.3+11, minSdk24, target/compile36 | `logs/feeding-stage3-artifact.json` dan metadata build |
| SQLite native/pratinjau pada HP | **Belum dijalankan**, empat skenario integrasi baru disiapkan | `integration_test/cycle_repository_test.dart`, `integration_test/lifecycle_transactions_test.dart` |
| Pemasangan/manual HP | **Belum dijalankan**,0 perangkat Android terdeteksi | `logs/feeding-stage3-android-devices.json` |

28 tes baru mencakup batas bobot desimal, contoh AT54, pembulatan, overflow, data tidak lengkap/di bawah acuan, batas suhu/pH, pengukuran baru, AT48 pada mesin aturan, snapshot immutable, serta rangkaian aktual/Lewati/grading/populasi/batal/kelebihan sesuai keputusan baru. Tes lama tetap menguji kebijakan legacy yang masih aktif.

Empat tes native tambahan memeriksa: pratinjau tidak mengganti rate/manual slot, pergantian template besok tanpa materialisasi, kondisi terbaru setelah grading/kematian/pembatalan tanpa mengubah snapshot pemberian, serta pembacaan aktual/batal/Lewati tanpa mengubah ledger/slot tersimpan. Tes native ini **bukan bagian98 tes yang telah lulus**, dan belum merupakan bukti SQLite Android berhasil.

Pemetaan: FR-02/FR-04; AT-48/54 dan AT-55–58 teruji pada lapisan aturan. AT-47/49/58 pada UI/commit serta AT-59 pada SQLite/HP belum dinyatakan lulus penuh. Regresi standar FR-03/05/07 tetap lulus; tidak menyatakan seluruh skenario PRD di HP lulus.

APK `app_m0/build/app/outputs/flutter-apk/app-debug.apk`: **152.395.544 byte**, SHA-256 **A95F022FCC98FD3ED89E6C34B554E20EB6DCFC380712CFC7738D11F786A8E5A8**. Identitas APK diverifikasi dari biner, bukan hanya nama file. APK ini masih menampilkan alur produksi sebelumnya karena aktivasi aturan menunggu Tahap4. Warning native access Gradle tidak menghentikan build dan tidak ditangani dengan perubahan SDK/konfigurasi global.

## 5. Batas tahap dan langkah berikutnya

Tahap3 persiapan mesin aturan selesai; **fitur rekomendasi baru belum aktif dan belum terverifikasi menyeluruh di HP**. Jangan mendemonstrasikan APK ini sebagai form pengukuran/rekomendasi otomatis yang sudah lengkap.

Tahap4 perlu menghubungkan semua layar dan commit ke sumber aturan yang sama, menambah input suhu/pH setiap pemberian, total harga sejak awal form, migrasi snapshot baru yang menjaga data, peninjauan ulang ketika data berubah, serta aktivasi kebijakan pada siklus lama tanpa merusak niat retry. Selesaikan keputusan waktu aktivasi dan siklus ikan selain lele berdasarkan data aktual sebelum mengubah perilakunya. Tidak mengisi pengukuran lama dengan angka rekaan.

Ketika HP tersedia, jalankan suite native terisolasi dari root `app_m0`: `flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>`, lalu pasang APK produk melalui upgrade biasa tanpa uninstall/clear data. Verifikasi persistensi dan data lama terpisah dari keberhasilan tes aturan. Tidak lanjut Tahap4 otomatis pada tugas ini.
