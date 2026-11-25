# Revisi dosen — Tahap 6: regresi dan uji Android

Tanggal: **26 Oktober 2026**. Tahap6 ditafsirkan sebagai pemeriksaan gabungan revisi Tahap2–5 dan pengujian HP, bukan penambahan fitur budidaya/backup. Acuan: FR-02–07, PRD15.8–15.12, AT-47–63 dan transaksi/rollback AT-05–10/15–19/25/31/36 yang terkait.

## Perubahan dan keamanan pengujian

- Tes native sekarang dibangun sebagai **`id.ac.fishcare.m0.tests`**, label **FishCare Uji**, saat proses build menerima `FISHCARE_NATIVE_TEST=1`. Aplikasi utama tetap `id.ac.fishcare.m0`, label FishCare V2. Namespace Java tidak berubah. Sandbox Android dan seluruh database uji terpisah dari data pengguna. Jendela aplikasi uji menjaga layar menyala saat aktif; tidak mengubah pengaturan waktu layar produk/HP.
- Runner Flutter yang terpasang mempunyai default `--uninstall=true` dan fallback uninstall bila pemasangan gagal. Karena itu, **jangan menjalankan perintah native historis langsung pada aplikasi utama**. Pakai flag lingkungan uji dan `--no-uninstall`. Catatan ini menggantikan petunjuk perintah native pada dokumen tahap lama; riwayatnya tetap disimpan.
- Pembaruan produk menggunakan `adb install -r` tanpa fallback uninstall/clear data. Bila gagal, berhenti dan diagnosis; tidak menghapus data demi tes lulus.
- Tiga tes standar tambahan mengecek ekspor semua kolam/arsip, grading/panen dan tidak memutasi snapshot; snapshot invalid/teks terlalu panjang; tombol ekspor tidak tersedia saat laporan memuat/gagal.
- Dua tes native tambahan menghubungkan grading → pemberian → laporan → XLSX → reopen, dan pembatalan → pemulihan stok → rincian historis tetap. Satu tes UI native mengisi suhu/pH/aktual, memeriksa biaya awal, menyimpan dan memeriksa SQLite.

## Temuan dan perbaikan

Putaran native awal: **50 lulus, 2 gagal** (`logs/regression-stage6-native.log`).

1. **Bug validasi angka nonfinite**: payload panen berisi NaN gagal pada serialisasi JSON dengan error teknis, sebelum pemeriksaan transaksi. `action_payload.dart` sekarang menolak NaN/Infinity secara rekursif sebagai `ValidationFailure`, sebelum menulis jurnal. Encoding payload valid tetap sama; tes kanonisasi/idempotensi lama dipertahankan. Tes regresi unit direproduksi gagal terlebih dahulu di `logs/regression-stage6-nonfinite-before.log`.
2. **Fixture migrasi skema5 belum lengkap**: insert kolam/pakan uji tidak mengisi kolom `revision` wajib. Fixture dilengkapi `revision:1`; tidak mengubah skema, database pengguna atau assertion. Penomoran grading lama/rencana kosong tetap diperiksa.

Perbaikan produk memakai sumber **0.10.1+14**, skema tetap **7**, dependency/lockfile tetap. Berkas utama: `lib/action_payload.dart`, `test/action_payload_test.dart`, `test/report_export_test.dart`, `integration_test/automatic_feeding_transactions_test.dart`, `integration_test/lifecycle_transactions_test.dart`, konfigurasi Gradle/manifest dan penjaga layar aplikasi uji pada `MainActivity.java`.

## Perangkat dan data lama

Perangkat terverifikasi: **Infinix X6879**, Android **16**, API **36**. Versi produk awal **0.8.1+9**, database **skema5**. Nomor perangkat tidak ditampilkan dalam laporan.

Pengguna secara eksplisit mengizinkan salinan lokal database untuk perbandingan sebelum/sesudah pembaruan. Salinan awal disimpan di `tmp/device-stage6-before`, terpisah dari artifact APK. Ini memuat data operasional pribadi; bukan file demonstrasi untuk dibagikan atau implementasi fitur backup produk. Tidak ada restore/penggantian database HP. Pemeriksaan awal `integrity_check=ok`:5 kolam,6 siklus,11 pemberian,21 operasi,14 pergerakan stok. Bukti agregat/hash kolom lama: `logs/regression-stage6-device-before.json`.

Sebelum ada izin tersebut, pemeriksaan otomatis menolak penyalinan. Tindakan dihentikan, izin khusus diminta dan diberikan, lalu jalur izin resmi dipakai ulang. Tidak membuat jalur alternatif untuk melewati penolakan.

## Cara menjalankan suite native dengan aman

Dari root `app_m0`, gunakan satu HP yang terhubung dan sudah diizinkan. Perintah ini membuat aplikasi uji terpisah; bukan menghapus aplikasi utama:

```powershell
$env:FISHCARE_NATIVE_TEST = '1'
try {
  flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL> --no-uninstall --reporter expanded
} finally {
  Remove-Item Env:FISHCARE_NATIVE_TEST -ErrorAction SilentlyContinue
}
```

Sebelum build produk pastikan variabel tersebut tidak aktif. Verifikasi identitas biner APK memakai `aapt dump badging`; produk harus `id.ac.fishcare.m0`, bukan `.tests`. APK hasil tes tidak boleh diserahkan sebagai APK produk. Aplikasi uji sengaja dipertahankan, tidak uninstall tanpa permintaan pengguna.

## Batas hasil

| Pemeriksaan akhir | Hasil | Bukti |
|---|---|---|
| `flutter analyze` | **Lulus**, tanpa issue | `logs/regression-stage6-analyze-final.log` |
| `flutter test --concurrency=1 --reporter expanded` | **114 tes lulus** | `logs/regression-stage6-flutter-test-final.log` |
| `flutter test integration_test/all_database_test.dart ... --no-uninstall` dengan flag aplikasi uji | **53 tes Android lulus** | `logs/regression-stage6-native-complete.log` |
| `flutter build apk --debug`, flag uji tidak aktif | **Lulus**,34detik | `logs/regression-stage6-build-product.log` |
| Identitas biner produk | **Lulus**,0.10.1+14,ID utama,minSdk24,target/compile36 | `logs/regression-stage6-product-identity.log` |
| `adb install -r` | **Lulus**, versi terpasang0.10.1+14 | `logs/regression-stage6-install.log`, `regression-stage6-artifact.json` |
| Migrasi data HP skema5→7 dan reopen produk | **Lulus**,integrity_check=ok, data historis tetap | `logs/regression-stage6-device-before.json`, `device-after.json`, `migration-detail.json` (semua dengan awalan `regression-stage6-`) |
| Pemilih file Android: batal | **Lulus**, pesan Ekspor dibatalkan, bukan sukses | `output/regression-stage6/export-cancelled.xml` |
| Pemilih file Android: simpan ke Unduhan lokal | **Lulus**, pesan Laporan Excel berhasil disimpan | `output/regression-stage6/export-saved.xml` |
| Membuka file aktual di WPS/Excel HP atau menariknya untuk verifikasi pembaca laptop | **Tidak dijalankan**, pengguna memilih memeriksa file sendiri | Konfirmasi terakhir pengguna |
| Mode pesawat, kegagalan penyedia file nyata, keyboard IME dan teks besar secara manual di HP | **Belum dijalankan** | Tes widget/fixture dan pengujian native bukan bukti seluruh skenario manual ini |

114 tes standar =110 Tahap5 +3 regresi ekspor +1 validasi nonfinite.53 tes native mencakup seluruh suite database serta3 tes native baru; bukan53 tes manual. Putaran perbaikan antara berisi52 lulus (`logs/regression-stage6-native-final.log`); putaran lengkap terakhir53 lulus mencakup tes form native. Layar HP sempat terkunci dan pengguna membukanya; sesudah itu suite lengkap dapat selesai.

Perbandingan data nyata mencakup seluruh kolom lama pada tabel kolam, pakan, siklus, pemberian, operasi, jurnal, rate, jam, pengaturan usaha, dan pergerakan stok: hash serta jumlah tetap.20 slot lama juga sama persis pada kolom lamanya, dengan2 slot baru hari berjalan (22 total). Cache cuaca tetap2 baris; `body` dan `fetched_ms` berubah saat pemuatan cuaca, lokasi tersimpan tetap. Tidak menyatakan cache cuaca identik. Data nyata tidak mempunyai siklus lele aktif yang ditandai otomatis pada saat pemeriksaan; aktivasi lele/migrasi serta riwayatnya dibuktikan pada fixture native terpisah, bukan mengubah jenis ikan pengguna.

Alur ekspor HP memakai filter **1–26 Oktober2026, semua kolam termasuk arsip**. Angka layar:6.092g pakan,Rp97.608 biaya,15 kematian,1.545 ikan panen,Rp16.529.060 nilai panen. Pemilih Android dibuka, dibatalkan, dibuka ulang dan disimpan. File ditujukan ke **Unduhan/FishCare_2026-10-01_2026-10-26.xlsx**. Isi file aktual belum dicocokkan dengan angka layar oleh agen: pengguna memilih memeriksanya sendiri. Keberhasilan pembaca XLSX Tahap5 tetap bukti fixture, tidak diganti menjadi klaim pembacaan file HP.

Screenshot dibuat sebelum pembacaan hierarki UI, sehingga sebagian gambar menangkap transisi/system overlay, sementara XML berikutnya sudah memuat hasil stabil. Bukti hasil batal/simpan di atas memakai **XML dengan pesan hasil**, bukan mengklaim gambar transisi sebagai tampilan final. Capture yang sempat memuat aplikasi lain dihapus; helper diperketat untuk membatasi foreground. Pengguna memberi izin khusus capture FishCare. Permintaan menyalin XLSX ke laptop ditolak pemeriksaan otomatis karena izin payload/tujuan khusus belum tersedia; ketika ditanya pengguna memilih cukup memakai hasil uji yang sudah lulus. **Tidak menyalin XLSX atau membuka WPS.** Capture tambahan juga dihentikan pemeriksaan otomatis mengikuti pilihan terakhir tersebut; tidak dilanjutkan dengan cara lain. Tidak mengirim pesan atau berbagi data ke layanan luar.

Keberhasilan tes database bukan bukti pemeriksaan semua keyboard native, API cuaca nyata menyeluruh, semua aplikasi pembaca Excel, seluruh versi Android, atau restore yang belum diimplementasikan. Peninjauan budidaya oleh dosen tetap terpisah. Tahap6 verifikasi otomatis, migrasi dan smoke test ekspor selesai; pemeriksaan isi Excel di HP diserahkan kepada pengguna sesuai pilihannya. Tidak menambah fitur tahap berikutnya.

## APK akhir

[APK FishCare0.10.1+14](../artifacts/revisi-tahap6/fishcare-0.10.1-debug.apk), **152.440.508 byte**. SHA-256 **AD2AE216031EB836EA6823887772725441371C03208A550331429D69D2DAFF64**. APK ini sudah terpasang pada HP. Aplikasi FishCare Uji tetap terpisah; APK produk bukan APK runner tes. Bukti: `logs/regression-stage6-artifact.json`.
