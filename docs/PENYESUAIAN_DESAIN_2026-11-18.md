# Penyesuaian desain FishCare — 18 November 2026

Target: aplikasi baru `app_m0`, sumber 0.11.1+16. Acuan visual: dua gambar pengguna, `output/desain/png/03-pondform.png`, dan desain kolam/siklus yang sudah tersedia. Perubahan hanya pada UI; bukan migrasi atau penambahan fitur budidaya.

## Hasil per area

| Area | Perubahan dan validasi |
|---|---|
| Ringkasan Beranda dan daftar kolam | Populasi dan bobot berdampingan dengan angka besar dan satuan kecil. Komponen `ConditionSummary` yang sama dipakai pada Beranda dan Kolam. Pada ruang sangat sempit/teks sangat besar, metrik bertumpuk agar terbaca. |
| Tambah/ubah kolam | Label di atas input, petunjuk ukuran dan catatan, bidang catatan lebih lapang, informasi nama unik, tombol Simpan di bawah yang tetap terjangkau ketika keyboard terbuka. |
| Detail kolam | Kondisi siklus ditempatkan sebelum identitas kolam; populasi/bobot dua kolom; kebutuhan menonjol dengan satuan lebih kecil; pintasan menuju pakan hari ini. Identitas dan pengarsipan tetap tersedia di bawah. |
| Kegiatan dan pengaturan siklus | Grading/Kematian dan Panen parsial/Riwayat berupa pasangan tombol sama lebar. Pengaturan rate/jam sejajar; tutup siklus selebar konten. Pintasan Riwayat menggulir ke riwayat yang sudah ada. |
| Mulai siklus | Data awal serta pakan/kebutuhan dipisahkan dengan judul bagian dan informasi rate. Input, validator, konfirmasi dan pemanggilan penyimpanan dipertahankan. |
| Jam | Chip kecil diganti kartu jam selebar form, nomor urut, ikon jam, serta tombol hapus berlabel. Tambah jam dan validasi 1–6 jam unik tetap menggunakan alur lama. |
| Pemberian | Tombol Berikan/Lewati sama lebar dan dapat membungkus pada teks besar. Callback dan syarat aktifnya tetap. |
| Form panjang | Wadah gulir mempertahankan semua field agar validasi tidak hilang ketika field berada di luar viewport. Uji bobot NaN dan keyboard tetap lulus. |

Istilah **Grading** menggantikan tulisan Sampling pada gambar lama sesuai kebutuhan terbaru. Tombol Ubah rate hanya tersedia pada siklus manual lama; siklus otomatis tetap mengikuti bobot. Angka serta ikan Nila pada sebagian render adalah fixture untuk membandingkan desain/siklus lama, bukan data produksi atau perluasan dukungan siklus baru. Siklus baru tetap khusus lele. Suhu/pH, riwayat snapshot, harga dan seluruh aturan pakan tidak diubah.

Perbaikan UI terkait: form Jam kini dapat dibuka saat rate belum tersedia; field rate yang tidak digunakan tidak lagi melakukan pemaksaan nilai null. Tidak menetapkan rate atau kebutuhan menjadi nol.

## Batas perubahan

Enam berkas aplikasi berubah: `design_system.dart`, `dashboard_ui.dart`, `product_app.dart`, `cycle_ui.dart`, `lifecycle_ui.dart`, `feed_ui.dart`. Versi pada `pubspec.yaml` dinaikkan menjadi 0.11.1+16 untuk membedakan APK. Tidak menambah dependency.

Perbandingan dengan salinan sebelum pengerjaan tersedia di `tmp/ui-match-before` dan diff di `logs/ui-match-*.diff`. Sebanyak 43 berkas Dart lainnya tetap sama, termasuk repository, skema, mesin perhitungan, ekspor, controller dan API. Skema tetap 7; application ID tetap `id.ac.fishcare.m0`. Tidak ada reset database, uninstall, atau perubahan data pengguna.

Keterlacakan: FR-01/02/04/05/06; alur AT-01–03, AT-15/19/27, AT-51, dan AT-59 terkait tampilan serta akses tindakan. Tidak mengklaim seluruh AT tersebut telah diuji di HP.

## Verifikasi

| Pemeriksaan | Status |
|---|---|
| `flutter analyze` | Lulus, tidak ada issue pada pemeriksaan kode; log `logs/ui-match-analyze.log`. |
| `flutter test --reporter expanded` | Lulus 134 tes, log `logs/ui-match-tests-final.log`. Mencakup regresi aturan lama, form, validasi, render dan navigasi pintasan. |
| Render Flutter | 18 gambar dari 6 permukaan pada 390dp/100% serta 360dp/130%; ditinjau visual, tanpa overflow yang terdeteksi. `output/ui-match-2026-11-18/`. Data uji terisolasi, bukan screenshot HP. |
| Build APK | Lulus `flutter build apk --debug`; APK `artifacts/ui-match-2026-11-18/FishCare-0.11.1-desain.apk`. Log `logs/ui-match-build.log`. |
| Pemasangan dan manual HP | Belum dijalankan: `adb devices` tidak menemukan Android terhubung pada sesi ini. |

Tes baru `test/design_match_test.dart` memeriksa keselarasan metrik, lebar kartu jam, penghapusan jam tanpa mengubah jam lain, pembukaan form jam tanpa rate, render enam permukaan, serta pintasan pakan dan riwayat. Tes identitas kolam diperbarui untuk menggulir ke lokasi barunya; assertion isi/tindakan tetap dipertahankan.

Validasi perangkat berikutnya: pasang sebagai pembaruan tanpa uninstall/reset, periksa data lama, buka setiap form dan keyboard pada HP, uji tombol kegiatan/pintasan serta perubahan jam yang efektif besok. Tidak ada klaim kesamaan piksel untuk seluruh 49 gambar desain lama; bentuk utama mengikuti referensi, sedangkan konten dan aturan tetap mengikuti aplikasi terbaru.
