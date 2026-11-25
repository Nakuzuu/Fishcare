# Keputusan Review FishCare

Pembaruan M4, 13 Oktober 2026. Aturan M3 dan perluasan lintas kegiatan M4 **diputuskan pengguna**, diselaraskan pada [PRD](PRD_FishCare_Baru_v0.1.md), alur, database, wireframe dan sumber. Pengguna mengonfirmasi seluruh percobaan manual gabungan M2+M3 berhasil tanpa kendala; tidak mengarang hasil standar. M4 belum terverifikasi standar/native/HP: [M4_IMPLEMENTASI.md](M4_IMPLEMENTASI.md).

Pembaruan M5: pengguna menunda pemasangan/uji HP M4 sampai M5 selesai; **M4 belum terverifikasi**. Laporan FR-07 dan AT-37–40 dibuat tanpa migrasi baru; verifikasi gabungan, snapshot/filter/refresh ada di [M5_IMPLEMENTASI.md](M5_IMPLEMENTASI.md). Aturan transaksi M3/M4 tetap; backup/restore/cuaca produk lengkap belum dibangun.

| ID | Temuan awal | Keputusan M3 dan implementasi | Status |
|---|---|---|---|
| RV-01 | Stok masuk salah sebelumnya tidak dapat diperbaiki | Koreksi selisih mempertahankan asal, old/new/reason. Baru >=0, saldo >=0; old yang stale/no-op ditolak. Ledger bersama append-only | Aturan selesai; sumber dibuat; verifikasi native belum berjalan |
| RV-02 | Rate/jam/Lewati dan ketergantungan bobot/populasi belum jelas | M4 last sah lintas pemberian/sampling/kematian/parsial pada active/hari sama; rate/jam/Lewati bukan penghalang. Validasi seq bersama dalam transaksi; pulihkan stok/populasi/bobot tepat; pending ulang dan jejak utuh. Akhir/closed tidak batal | Aturan diselesaikan pengguna M4; sumber dibuat, verifikasi M4 belum berjalan |
| RV-03 | ID hanya di memori hilang saat hasil simpan belum diketahui | action_intents menyimpan ID/jenis/target/payload kanonik sebelum transaksi M2/M3. Commit/result dan bisnis atomik. prepared/hasil belum diakui dibaca saat startup. Periksa hasil dahulu, retry eksplisit ID sama; tidak retry otomatis | Aturan selesai; sumber ActionJournal/recovery dibuat; tes crash/native belum dijalankan |

Lingkup niat persisten yang diterapkan: start siklus, rate/jam, stok masuk/koreksi, pemberian, Lewati, pembatalan. Slot yang dimaterialisasi saat membaca hari baru adalah rencana turunan idempoten, bukan pemberian otomatis. CRUD identitas master M1 dipertahankan dengan ID/keunikan/revisi sebelumnya; tidak mengklaim seluruh fitur masa depan atau backup/restore sudah memakai pemulihan M3. Operasi M2 lama sebelum migrasi yang tidak memiliki niat tidak direka ulang menjadi catatan niat.

Sampling/kematian/panen ditambahkan pada M4; lingkup niat persisten meliputi seluruh kegiatan M4 termasuk penutupan/batal. Backup/restore belum dibuat; pemulihan niat setelah restore tetap perlu aturan sebelum tahap tersebut. Ukuran APK M1 sekitar151MB tetap laporan pengguna, bukan ukuran M4. Kandidat M4 belum dibangun dalam sesi karena akses SDK ditolak.
