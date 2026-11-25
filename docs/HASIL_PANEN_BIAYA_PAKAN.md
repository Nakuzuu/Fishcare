# Hasil panen setelah biaya pakan

26 Oktober2026. FR-06/07, PRD15.14, AT-64–68. Sumber **0.11.0+15**, skema tetap **7**.

Pengguna membatasi pengembangan pada pakan. Tabel baru berisi pendapatan kotor, total pakan terpakai, total biaya pakan, dan hasil setelah biaya pakan. Pendapatan menggabungkan panen sebagian serta akhir sah satu siklus. Biaya memakai snapshot pemberian aktual sah, bukan harga terbaru/pembelian stok. Selisih negatif tidak dijadikan nol. Label menyebut biaya lain belum diperhitungkan dan bukan keuntungan bersih.

Tabel tersedia setelah penutupan tersimpan, pada kartu/detail kegiatan akhir/tutup tanpa panen, kartu/detail siklus selesai di Laporan, dan detail transaksi akhir/tutup pada Laporan. Seluruh siklus diberi label tersendiri dari filter periode. Siklus selesai lama otomatis mendapat ringkasan dari transaksi yang tersedia; tidak mengarang snapshot baru. Konfirmasi panen dan ekspor XLSX periode tidak diubah. Tidak ada fitur biaya lain, perubahan database atau transaksi.

Sumber hitungan bersama `reportTotals` tetap dipakai. `report_rules.dart` menambahkan `HarvestFeedResult` dan pengayaan baris riwayat akhir; `harvest_result_ui.dart` berisi satu komponen tabel yang digunakan ulang. `lifecycle_ui.dart` membaca riwayat dalam satu transaksi konsisten, sementara `activity_ui.dart` dan `report_ui.dart` menampilkannya. Tidak menambah dependency atau mengubah lockfile.

Enam tes baru menguji gabungan panen, snapshot biaya berbeda, batal, pemisahan siklus, filter periode, tutup tanpa panen, nilai negatif, data tidak lengkap, tampilan360dp/teks130% serta detail kegiatan. Satu tes SQLite Android baru menguji panen akhir, laporan seluruh siklus, perubahan harga dan reopen. Tes memakai database terisolasi pada aplikasi FishCare Uji, tidak membuat panen akhir pada data pengguna.

| Pemeriksaan | Hasil | Bukti |
|---|---|---|
| `flutter analyze` | **Lulus**,tanpa issue | `logs/harvest-result-analyze.log` |
| `flutter test --concurrency=1 --reporter expanded` | **120 tes lulus** (114 sebelumnya +6 baru) | `logs/harvest-result-flutter-test.log` |
| Suite native, flag aplikasi uji dan `--no-uninstall` | **54 tes Android lulus** (53 sebelumnya +1 baru) | `logs/harvest-result-native.log` |
| `flutter build apk --debug` | **Lulus**,49,2detik | `logs/harvest-result-build.log` |
| Identitas biner | **Lulus**,ID utama0.11.0+15,minSdk24,target/compile36 | `logs/harvest-result-apk-identity.log` |
| `adb install -r`, verifikasi package terpasang | **Lulus**,0.11.0+15 terpasang pada HP | `logs/harvest-result-install.log` |

Native dijalankan pada Infinix X6879/API36 yang terdeteksi, dengan ID aplikasi uji terpisah sebagaimana prosedur Tahap6. Tes baru membuktikan pendapatan siklus Rp500.000, pakan150g,biayaRp1.500 dan hasilRp498.500, termasuk biaya pemberian sebelum tanggal filter; perubahan harga setelah selesai/reopen tidak mengubah hasilnya. Ini data fixture terisolasi, bukan panen baru pada kolam pengguna.

Pemeriksaan isi Excel aktual tetap pilihan pengguna sebagaimana Tahap6, bukan bagian revisi tabel ini. Tidak mengambil screenshot atau salinan data operasional tambahan. Pemeriksaan manual tampilan tabel di aplikasi utama pada HP belum dijalankan; UI tabel/detail diperiksa lewat tes widget, termasuk360dp/teks130%. Aplikasi dibuka setelah pembaruan; pembukaan ini bukan klaim seluruh alur manual lulus.

APK: [fishcare-0.11.0-debug.apk](../artifacts/hasil-panen/fishcare-0.11.0-debug.apk), **152.449.392byte**, SHA-256 **60F0C9C5B32130DC85E61E8B6653353CE2E32367CABB144AF85040D766286DBD**. Salinan artifact sama dengan build saat ini; metadata `logs/harvest-result-artifact.json`. Tidak ada perubahan dependency, skema atau reset data. Warning Gradle native access tidak menghentikan build.
