# M5 — perbaikan detail transaksi

Lingkup FR-07, AT-38/39. Pengguna melaporkan kegagalan tes `pendukung dan detail mempertahankan filter, batal terlihat`. Sumber penyebab ditemukan: factory row mengisi value_rp=0 untuk death, sedangkan UI menganggap value_rp non-NULL sebagai penanda panen dan melakukan cast harvest_weight_cg NULL ke int. Ini perbaikan implementasi/fixture, bukan perubahan PRD atau skema.

## Perubahan

- [report_ui.dart](../app_m0/lib/report_ui.dart): detail panen hanya untuk kind partial/final. Tidak mengisi data hilang dengan nol atau menghilangkan bagian panen sah karena nilai panen0 (nilai snapshot0 dapat sah setelah half-up).
- [report_test.dart](../app_m0/test/report_test.dart): field harvest_weight_cg/price_rp_kg/value_rp NULL untuk nonpanen; cost_snapshot NULL untuk nonfeeding sebagaimana LEFT JOIN SQLite. Panen wajib mendapat nilai snapshot eksplisit, tanpa default nilai0. Bobot/harga fixture positif dan tetap terlihat sebagai snapshot.
- Tes kematian batal mempertahankan assertion **Alasan batal: Uji**, menambah status batal/kondisi historis, tidak ada Bobot panen, dan tidak ada exception framework.
- Tambah tes detail partial/final sah: jumlah, populasi, bobot/harga/nilai snapshot, tidak ada exception, dan filter tetap dari pendukung ke detail. Final fixture memakai seluruh sisa dan populasi setelah0. Tambah tes kontrak nullable factory. Kasus jumlah dua nilai1 memakai bobot0,50g/harga1000 sehingga snapshot1 per transaksi konsisten dengan half-up.

File report_test kini memiliki **11 skenario terdefinisi**, bukan11 lulus. Tes alasan pembatalan tetap; tidak menghapus/melonggarkan assertion lama. Database/dependency/lockfile/versi sumber0.6.0+6 tetap.

## Verifikasi sebenarnya

| Pemeriksaan | Hasil |
|---|---|
| Kasus gagal sebelum perbaikan | Dilaporkan pengguna; penyebab dicocokkan pada sumber. Tidak diulang runtime dalam sesi agen |
| Format dua file | Lulus exit0; [log](../logs/m5-detail-fix-format.log), bukan analisis tipe/tes |
| `flutter analyze` jalur resmi | Eksekusi eskalasi diminta dari root app_m0; otomatis ditolak sebelum Flutter berjalan karena sandbox_approval=false |
| Seluruh `flutter test` | Terhalang, belum dijalankan. Cache SDK tetap tidak dapat diakses tulis |
| `flutter build apk --debug` gabungan M4+M5 | Belum dijalankan; analyze/test belum lulus dan SDK terhalang; APK baru belum dihasilkan |
| Native/HP M4+M5 | Belum dijalankan; tidak menyatakan M4 terverifikasi |

[Log verifikasi](../logs/m5-detail-fix-verification.log) berisi bukti preflight `UnauthorizedAccessException` untuk `C:\flutter\bin\cache\flutter.bat.lock` serta penolakan izin resmi. Perintah yang diminta: `C:\flutter\bin\flutter.bat analyze`, working directory app_m0, sandbox_permissions=require_escalated. Kebijakan otomatis menolak kategori sandbox_approval; tool permintaan izin filesystem lain tidak tersedia dalam sesi. Tidak mengubah izin, menyalin SDK, menghapus lock/cache, atau mengganti tes standar dengan harness.

APK yang tersedia masih artifact M3 versionCode4, bukan hasil build perbaikan. Kandidat setelah verifikasi harus versionName0.6.0/versionCode6, hash/waktu hasil build baru. Tidak memasang/mengklaim APK lama sebagai gabungan.

## Terminal Android Studio

Perintah berikut untuk terminal yang memiliki akses cache SDK; **belum dinyatakan dijalankan/lulus oleh agen**. Jalankan berurutan, berhenti dan perbaiki jika perintah gagal; build hanya setelah analyze dan seluruh test lulus:

```powershell
Set-Location 'C:\Users\basti\OneDrive\Lampiran\Documents\FishCare V2\app_m0'
flutter analyze
flutter test
flutter build apk --debug
```

APK produk: `build/app/outputs/flutter-apk/app-debug.apk`. Suite native dan uji HP gabungan tetap mengikuti [M5_IMPLEMENTASI.md](M5_IMPLEMENTASI.md). **Berhenti M5; tidak memulai M6.**
