# M3 — stok dan pemberian; kandidat gabungan M2+M3

13 Oktober 2026. **Sumber dibuat, tetapi M3 belum terverifikasi melalui Flutter standar/native HP. APK gabungan baru belum dapat dihasilkan karena akses SDK sesi agen ditolak.** Pengguna memilih satu uji HP gabungan setelah tahap ini; **M2 belum dinyatakan terverifikasi di HP**. Berhenti pada M3.

Acuan: [PRD](PRD_FishCare_Baru_v0.1.md), [Alur](ALUR_SISTEM.md), [Database](RANCANGAN_DATABASE.md), [Wireframe](WIREFRAME.md), [keputusan review](KEPUTUSAN_REVIEW.md), [README](../README.md). Pernyataan pengguna M1 berjalan lancar dan APK sekitar151MB adalah hasil/laporan pengguna, bukan rincian tes/build baru agen.

## 1. Aturan yang diputuskan dan pemetaan

| Area | Keputusan M3 | FR/AT |
|---|---|---|
| Stok bersama | Saldo dari seluruh ledger pakan; dipakai semua kolam. Stok masuk positif tidak menimpa saldo | FR-03; AT-04, AT-06–07 |
| Koreksi masuk | Asal utuh; simpan efektif lama/baru/alasan dan delta. Baru boleh0, tidak boleh negatif; saldo tidak negatif; old stale/no-op ditolak | FR-03; AT-29 |
| Pemberian | Aktual bulat >0, slot pending sah hari ini dengan porsi positif. Stok terbaru diperiksa di transaksi; actual>sisa perlu konfirmasi | FR-04; AT-04–07, AT-27–28 |
| Snapshot/atomik | Pemberian/harga/rate/populasi/bobot/biomassa/biaya, out, slot dan pending commit bersama | FR-03/04; AT-15, AT-25 |
| Pembatalan | Pemberian sah terakhir hari ini dalam siklus aktif; alasan wajib. Rate/jam/Lewati tidak menghalangi. Reversal tepat, pending dihitung ulang | FR-04; AT-16–17, AT-30 |
| Recovery | Niat tersimpan sebelum bisnis; hasil/bisnis atomic; restart memeriksa ID yang sama sebelum retry eksplisit | PRD bagian4/9; AT-05, AT-25, AT-31 |
| Regresi M2 | Jam hari ini utuh, template baru besok; hanya pending dibagi sisa; slot given/skipped tetap | FR-02/04; AT-02–03, AT-09–10, AT-26/28 |

PRD bagian4/5/14 diperbarui dan AT-29–31 ditambahkan; AT-17 diperjelas agar tidak bertentangan dengan pembatalan setelah rate/jam/Lewati. Half-up keputusan M2 tetap dipakai. Tidak membuat sampling/kematian/panen/laporan lengkap. Ketergantungan pembatalan terhadap sampling/populasi dan pemulihan setelah restore tetap perlu aturan sebelum fitur tersebut dibuat.

## 2. Berkas dan UI

- [action_payload.dart](../app_m0/lib/action_payload.dart): JSON kanonik dengan key map terurut, list/input tetap; urutan key tidak menyebabkan false mismatch saat retry.
- [action_journal.dart](../app_m0/lib/action_journal.dart): niat prepared, hasil committed/rejected/abandoned, target pending unik, inspect/retry/acknowledge.
- [m3_schema.dart](../app_m0/lib/m3_schema.dart), [master_repository.dart](../app_m0/lib/master_repository.dart): skema/migrasi1/2→3.
- [feed_repository.dart](../app_m0/lib/feed_repository.dart): saldo/koreksi/pemberian/pembatalan/Lewati/recovery dan snapshot dalam transaksi.
- [day_actual.dart](../app_m0/lib/day_actual.dart), [cycle_rules.dart](../app_m0/lib/cycle_rules.dart), [cycle_repository.dart](../app_m0/lib/cycle_repository.dart): actual sah hari ini, satu fungsi kebutuhan/biaya/remaining/pending. Start/rate/jam M2 juga menyimpan niat lebih dulu.
- [feed_ui.dart](../app_m0/lib/feed_ui.dart), [cycle_ui.dart](../app_m0/lib/cycle_ui.dart), [product_app.dart](../app_m0/lib/product_app.dart): stok dan riwayat pada detail pakan; Berikan/Lewati pada slot; riwayat/snapshot dan Batalkan terakhir; ikon Pemulihan tindakan dan banner Beranda.

Stok masuk/koreksi/pemberian membuka form scrollable, satuan gram, error, ringkasan lalu konfirmasi. Koreksi menampilkan jumlah lama read-only, jumlah baru dan alasan. Tidak ada input menimpa saldo total. Zona usaha default perangkat ditawarkan sebelum stok pertama bila belum ada siklus, lalu dikunci setelah commit; rollback stok gagal tidak mengunci zona. Koreksi dapat merujuk stok masuk historis, tanggal koreksi tetap hari ini.

Pemberian membaca harga/rate/rencana/stok/sisa untuk konfirmasi. Saat commit, harga/rate yang berubah membuat niat ditolak dan meminta ringkasan baru; stok kurang menolak seluruh bisnis. Setelah hasil belum pasti, tombol simpan ulang dinonaktifkan dan pengguna diarahkan ke pemulihan. Validation rejection yang pasti boleh diperbaiki melalui konfirmasi tindakan baru pengguna, bukan retry otomatis.

Detail membedakan kebutuhan terbaru, sudah diberikan, sisa dan kelebihan. Slot diberikan/dilewati tidak didistribusikan ulang; pending0 tidak menawarkan pemberian. Lewati tidak membuat transaksi nol atau stok keluar. Semua selesai/dilewati dengan sisa menampilkan Sisa belum diberikan tanpa slot tambahan. Perubahan harga/rate tidak mengubah snapshot lama. Riwayat batal tetap menunjukkan aktual/biaya/harga/rate/biomassa dan alasan; total actual hanya menghitung sah. Laporan penuh tetap kosong berlabel belum tersedia.

## 3. Skema3 dan migrasi

File produk tetap `fishcare_app.db`, application ID `id.ac.fishcare.m0`. M0 marker tetap file terpisah. Migrasi v1 menambah skema siklus v2 lalu v3; v2 langsung menambah v3. Tidak meminta uninstall/reset.

| Tabel | Kolom penting, relasi/constraint |
|---|---|
| `action_intents` | ID PK, kind, payload kanonik, target_key, state, result/error, acknowledged, created/completed timestamp. State prepared/committed/rejected/abandoned; target unik WHERE prepared |
| `feedings` | seq commit, ID unik FK niat; FK siklus/pakan/slot komposit tanggal+jam; actual_g>0, planned/price/rate/population/weight/biomass/cost/need snapshots, cancel_action_id unik FK niat dan reason. Unik slot WHERE belum batal |
| `stock_movements` | seq, ID unik FK niat, FK pakan, kind in/correction/out/reversal, delta_g signed, original_in_id FK stok asal, feeding_id FK pemberian, tanggal usaha/timestamp. Unik out/reversal per feeding; CHECK tanda dan referensi menurut kind |
| `stock_corrections` | ID PK/FK niat; source_id FK masuk, old_g/new_g>=0, reason wajib, tanggal/timestamp koreksi |
| `cycle_slots` | Kolom/PK siklus,tanggal,jam tetap; enum diperluas pending/given/skipped, gram nonnegatif |

SQLite tidak dapat mengganti CHECK enum slot langsung. Migrasi membuat `cycle_slots_v3`, menyalin **seluruh** baris lama, membandingkan jumlah baris, lalu mengganti tabel dalam transaksi callback migrasi. Ini rekonstruksi tabel dengan data dipertahankan, bukan reset database. Jika gagal, migrasi rollback; master/cycle/rate/template/jam/slot lama utuh. Tabel feeding baru dibuat setelah slot diganti, dengan FK aktif. Tes memakai file terisolasi dan memeriksa nilai M2 tetap.

Angka gram/rupiah disimpan int64; bobot/biomassa snapshot seperseratus gram, rate seperseratus persen. Perkalian dan penjumlahan saldo/actual memakai BigInt dan pemeriksaan hasil int64; tidak memakai float. Saldo bukan cache: jumlah semua delta, termasuk out asli yang telah dibatalkan dan reversal. Jangan sekaligus mengecualikan out batal, karena akan menggandakan pengembalian.

## 4. Batas transaksi

1. **Prepare niat:** transaksi tersendiri menyimpan ID/kind/target/payload. Jika gagal, bisnis tidak berjalan. ID sama/input beda ditolak; target yang masih prepared tidak menerima niat pengganti.
2. **Bisnis:** baca hasil ID terlebih dahulu. Sudah committed = kembalikan hasil, tidak menulis ulang. Untuk prepared, baca stok/status/populasi/rate/harga/old koreksi terbaru, validasi, tulis bisnis serta result/state committed atomik.
3. **Validasi gagal:** rollback seluruh bisnis lalu tandai rejected; jika crash sebelum penandaan, prepared tetap tersedia untuk pemeriksaan ulang. Error teknis tetap prepared karena hasil belum dapat dipastikan.

| Tindakan | Commit bersama |
|---|---|
| Stock in | Zona bila pertama, ledger masuk, hasil niat |
| Koreksi | Cek efektif lama terbaru, delta/saldo, audit old/new/reason, ledger correction, hasil |
| Feeding | Snapshot immutable+out tepat+slot given+recalculate pending+hasil |
| Cancel | Cek last valid seq/hari/active, FK batal/reason, reversal tepat, slot pending, recalculate pending, hasil |
| Skip | Slot skipped, recalculate pending, hasil; tanpa feeding/out |
| Cycle start/rate/times | Niat dulu; seluruh perubahan M2 dan hasil dalam transaksi bisnis yang sama |

Koreksi saldo/jumlah negatif, no-op dan pratinjau stale ditolak. Dua kolam dengan target slot berbeda diserialisasi oleh penulisan SQLite sehingga stok tidak negatif. Pemberian satu slot hanya satu sah; setelah batal, boleh membuat pemberian baru dengan ID baru yang dikonfirmasi pengguna, sementara riwayat batal tetap.

## 5. Restart dan pemulihan

Saat membuka produk, banner/halaman recovery membaca hasil/niat yang belum diakui. **Tidak ada retry otomatis.** Committed menampilkan hasil tersimpan dan hanya menawarkan tutup hasil; rejected menampilkan alasan; prepared memerlukan Periksa hasil sebelum Retry ID yang sama aktif. Menutup niat prepared dilakukan dalam transaksi setelah memastikan belum commit; tidak membatalkan transaksi yang sudah tersimpan. Hasil tetap di database meski sudah diakui.

Resume mendecode payload tersimpan dan memanggil dispatcher memakai ID asli. Target prepared unik melindungi klik baru pada target yang hasilnya belum diketahui. Tanggal niat tidak diganti otomatis; niat hari sebelumnya yang belum commit ditolak, bukan dicatat mundur. Jika commit sudah terjadi sebelum UI menerima respons, pemeriksaan ID menemukan committed sehingga tidak mengurangi stok lagi.

Crash sebelum prepare commit tidak menjalankan bisnis; setelah prepare sebelum bisnis meninggalkan prepared; saat bisnis SQLite menghasilkan semua atau rollback; setelah commit sebelum UI meninggalkan committed belum diakui. Cakupan niat M3 meliputi transaksi siklus dan stok/pakan di tabel atas; identitas master M1 tetap mekanisme ID/keunikan/revisi semula. Tidak merekayasa niat untuk operasi M2 lama yang sudah ada sebelum migrasi.

## 6. Pengujian dan hasil saat ini

[feed_transactions_test.dart](../app_m0/integration_test/feed_transactions_test.dart) menambah11 skenario native: stok bersama/kurang, dua request bersamaan, koreksi berulang dan negatif/stale, harga/rate snapshot, double tap/retry, cancel setelah rate/jam/Lewati, penolakan cancel lama/hari lalu, rollback lewat fault trigger dan reopen, prepare-before-business/restart, migrasi v2, dan UI recovery inspect sebelum retry. File uji `m3_isolated_<ID>.db`/`m3_migrate_<ID>.db`, bukan produk.

Fault trigger hanya dibuat/dihapus pada database terisolasi; assertion rollback tetap kuat. Reopen koneksi/repository merupakan simulasi restart penyimpanan, bukan bukti force-stop HP. [all_database_test.dart](../app_m0/integration_test/all_database_test.dart) mengelompokkan M0/M1/M2/M3 untuk satu sesi native berurutan.

Tes standar baru memeriksa biaya half-up/overflow, parser gram/koreksi0, remaining/pending, dan JSON kanonik. Seluruh tes M0/M1/M2 dipertahankan; tes migrasi mengikuti schemaVersion3 sambil tetap memeriksa isi lama. M2 rule checker dijalankan kembali.

Pemeriksaan sumber terakhir memperbaiki referensi `_unknown` yang tidak didefinisikan pada tombol tutup hasil di RecoveryPage; tombol tersebut sekarang mengikuti state `_busy` milik halaman. Tombol pembatalan pada FeedingControls mengikuti `_busy || _unknown`. Tes recovery yang sudah ada juga memeriksa tutup hasil mengakui ID, tidak membuat pemberian baru, dan tidak mengubah saldo. Tes UI ini belum dijalankan. Percobaan ulang checker awal memakai working directory aplikasi yang salah sehingga file `tools/...` tidak ditemukan; perintah kemudian diperbaiki ke root workspace dan hasil sebenarnya disimpan pada log tambahan.

| Pemeriksaan | Hasil |
|---|---|
| `flutter analyze` | Terhalang; belum berjalan pada M3. Akses `C:\flutter\bin\cache\flutter.bat.lock` ReadWrite menghasilkan UnauthorizedAccessException/Access denied |
| Seluruh `flutter test` | Terhalang; belum dijalankan, jumlah lulus tidak diketahui |
| `flutter build apk --debug` gabungan | Terhalang; **belum menghasilkan APK baru**. APK M1 tidak dilabeli M2+M3 |
| Tes integration/native | Belum dijalankan;19 skenario native terdefinisi, bukan19 lulus |
| Format Dart | Lulus; bukan analisis tipe/runtime |
| Checker Dart murni M3 + regresi M2 | Lulus sebagai bukti tambahan; bukan Flutter/native/HP |
| Pemasangan/uji HP gabungan M2+M3 | Belum dijalankan sesuai pilihan pengguna; M2 tidak disebut terverifikasi |

Bukti: [m3-standard-status.log](../logs/m3-standard-status.log), [m3-rules-extra.log](../logs/m3-rules-extra.log), [m3-m2-regression-extra.log](../logs/m3-m2-regression-extra.log). SDK berada di luar writable root sesi; eskalasi sandbox tidak tersedia. Tidak mengulang loop bootstrap yang sama, menyalin SDK, menghapus lock/cache atau menggunakan runner alternatif sebagai pengganti jalur standar.

## 7. Satu APK gabungan dan terminal Android Studio

Dependency/lockfile tetap. Versi sumber **0.4.0+4**, schema3, ID tetap sehingga upgrade mempertahankan data. Langkah berikut adalah **belum dijalankan**, untuk terminal Android Studio yang mempunyai akses SDK/cache:

```powershell
Set-Location 'C:\Users\basti\OneDrive\Lampiran\Documents\FishCare V2\app_m0'
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
```

Pastikan setiap perintah selesai/exit sukses dan simpan log. APK yang diharapkan `app_m0/build/app/outputs/flutter-apk/app-debug.apk`. Periksa `aapt dump badging` menunjukkan **versionName0.4.0/versionCode4** sebelum menyebut APK gabungan; catat hash/ukuran/waktu. Jangan mengirim APK lama atau meminta uninstall untuk melewati migrasi.

Sesi native opsional, setelah lingkungan mendukung, hanya database uji terisolasi:

```powershell
flutter test integration_test/all_database_test.dart -d <ID_HP_LOKAL>
```

Runner integration dapat memasang entrypoint tes ke paket V2. Setelah tes selesai, pasang **APK produk gabungan** untuk uji manual, bukan memasang tiap perubahan kecil:

```powershell
flutter install --debug -d <ID_HP_LOKAL>
```

Jangan clear data/uninstall. Verifikasi versi produk4 setelah runner; serial tidak dipublikasikan. Konfigurasi Android/Flutter tetap seperti M2, belum ada perubahan dependency/Gradle untuk mengejar ukuran.

## 8. Ukuran APK dan opsi presentasi

**Laporan pengguna: APK M1 sekitar151MB.** Artifact M1 yang diperiksa berukuran152.100.979byte (~152,1MB desimal/~145,1MiB). [Daftar ZIP](../logs/m1-apk-entries.json) dan [ringkasan](../logs/m1-apk-size-summary.json) adalah pembanding M1, bukan hasil analisis ukuran M3.

| Isi M1 yang terdaftar | Ukuran entry mentah / tersimpan |
|---|---|
| libflutter.so arm64-v8a | 38.828.704 /38.828.704byte |
| Vulkan validation layer arm64-v8a | 15.240.080 /15.240.080byte |
| kernel_blob.bin debug | 44.825.560 /15.262.588byte |
| isolate_snapshot_data | 11.647.016 /4.405.748byte |
| classes.dex | 10.653.224 /4.196.634byte |
| MaterialIcons font | 1.645.184 /593.046byte |

ZIP M1 memuat150 entry, total tersimpan78.800.520byte, sedangkan file fisik152.100.979byte. Selisih73.300.459byte **belum teratribusi oleh inventaris entry ini**; tidak langsung dianggap aset, ABI tambahan, padding, atau data duplikat. Yang terdaftar hanya ABI arm64-v8a, sehingga multi-ABI tidak dinyatakan sebagai penyebab ukuran M1. Perlu perbandingan artifact baru/build lengkap untuk menjelaskan selisih fisik.

Setelah debug gabungan berhasil dan alur HP lulus, opsi presentasi adalah build release untuk ABI HP yang benar-benar diverifikasi, dengan signing yang sesuai dan uji ulang. Ukur release melalui `--analyze-size` pada satu target platform; split-per-ABI berguna bila artifact baru memang memuat beberapa ABI. Jangan menghapus font, aset, Vulkan library atau fitur secara manual; tooling mode release yang menentukan isi. Ukuran akhir dan kompatibilitas release belum diklaim. Dasar resmi: [build APK/release Flutter](https://docs.flutter.dev/deployment/android), [pengukuran ukuran Flutter](https://docs.flutter.dev/perf/app-size). Tahap ini tidak membuat release/signing atau publikasi.

## 9. Uji HP gabungan M2+M3

1. Catat master M1/siklus M2 bila ada, upgrade ke versi4 tanpa uninstall. Nama, arsip, harga, cycle/rate/jam/slot lama tetap. Pastikan database produk berbeda dari marker M0.
2. Offline: mulai siklus100 ikan×100g×3%, dua jam. Kebutuhan300, porsi150+150. Rate3,01%→301→151+150. Input invalid/jam duplikat/siklus kedua ditolak. Ubah jam berkali-kali, hari ini tetap dan besok versi terakhir, termasuk hari belum dibuka. Semua ini **belum hasil uji HP**.
3. Tambah500g stok pakan, dua kolam memakai pakan sama. Berikan150g dengan hargaRp10.000/kg; saldo350, biayaRp1.500. Pemberian lain yang melampaui saldo ditolak utuh. Ketuk ganda tidak menambah dua out.
4. Koreksi jumlah masuk500→400 dengan alasan: delta−100, saldo250, asal500 tetap. Koreksi menjadi jumlah yang menyebabkan saldo negatif/old stale/angka negatif ditolak. Koreksi menjadi0 hanya sah bila saldo tetap nonnegatif.
5. Ubah harga/rate setelah pemberian: snapshot lama tetap, hanya pending dihitung ulang; jika kebutuhan turun di bawah actual, sisa0/kelebihan jelas tanpa pengembalian otomatis.
6. Setelah pemberian, ubah rate/jam atau Lewati slot lain; batalkan pemberian sah terakhir dengan alasan. Stok pulih tepat, out+reversal utuh, slot kembali pending, skipped tetap. Pemberian bukan terakhir/hari lalu ditolak.
7. Tutup paksa/buka lagi pada file uji M3 atau gunakan fault-injection integration terisolasi untuk titik sebelum/sesudah commit. Recovery menampilkan ID tersimpan, Periksa hasil dahulu; committed tidak menawarkan retry, prepared hanya retry ID sama setelah pemeriksaan. Saldo/feedings tidak ganda. Jangan mematikan/mengubah data pengguna demi tes.
8. Buka semua tab/setelah simpan, keyboard terbuka/teks130%/360dp, loading/error/retry, mode pesawat dan persistensi setelah force-stop. Tidak perlu jaringan untuk transaksi lokal. Riwayat batal/koreksi bisa ditelusuri; laporan penuh tetap belum tersedia.

Catat hasil tiap langkah, model/Android/API aktual, versiAPK, screenshot/log dan sumber pengguna/agen. M2 dan M3 baru dinilai terverifikasi sesuai bukti yang benar-benar diperoleh. Jangan lanjut sampling/kematian/panen/laporan lengkap setelah M3.
