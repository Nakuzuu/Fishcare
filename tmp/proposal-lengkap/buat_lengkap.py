from pathlib import Path
from zipfile import ZipFile,ZIP_DEFLATED
from hashlib import sha256
import json

ROOT=Path(__file__).resolve().parents[2]
base=ROOT/'tmp/proposal/buat_proposal.py'
# Reuse pola asli template dan diagram yang telah diaudit; tidak menjalankan builder versi ringkas.
exec(compile(base.read_text(encoding='utf-8').split('# Halaman 1 mengikuti')[0],str(base),'exec'))
TMP=ROOT/'tmp/proposal-lengkap';OUT=ROOT/'output/laporan'
def prose(*texts):
    for text in texts:p(text)
def minor(text):return head(text)
def pair(a,b,caption):
    t=doc.add_table(rows=1,cols=2);t.alignment=WD_TABLE_ALIGNMENT.CENTER;t.autofit=False
    for cell,name in zip(t.rows[0].cells,[a,b]):
        cell.width=Inches(3.25);q=cell.paragraphs[0];q.alignment=WD_ALIGN_PARAGRAPH.CENTER;q.paragraph_format.space_after=Pt(0)
        sh=q.add_run().add_picture(str(ROOT/'tmp/proposal-lengkap'/f'{name}.png'),width=Inches(2.65));sh._inline.docPr.set('descr',caption)
    borders=OxmlElement('w:tblBorders')
    for tag in ['top','left','bottom','right','insideH','insideV']:
        e=OxmlElement('w:'+tag);e.set(qn('w:val'),'nil');borders.append(e)
    t._tbl.tblPr.append(borders)
    p(caption,size=10,align=WD_ALIGN_PARAGRAPH.CENTER)

q=p('PROPOSAL PROJECT',True);q.style=doc.styles['Title'];head('PENGEMBANGAN APLIKASI BERGERAK');p('',after=10)
head('Mata Kuliah');p('Pemrograman Perangkat Bergerak')
head('Judul Proyek');p('Pengembangan FishCare sebagai Aplikasi Android untuk Pencatatan Budidaya Ikan dan Informasi Cuaca')
head('Nama Aplikasi');p('FishCare')
head('Kelompok');p('Kelompok 7')
head('Anggota Kelompok')
for i in range(1,7):p(f'{i}. Nama: ....................................   NIM: ....................................',after=7)
head('Dosen Pengampu');p('................................................................................')
head('Program Studi dan Universitas');p('................................................................................');p('Oktober 2026')

newpage('BAB 1','PENDAHULUAN')
head('1.1 Latar Belakang')
prose('Pengelolaan budidaya pada beberapa kolam membutuhkan catatan yang saling berkaitan. Pengelola perlu mengetahui jumlah ikan yang masih dipelihara, perubahan bobot rata-rata, pakan yang sudah diberikan, saldo stok, dan hasil panen. Angka tersebut tidak berdiri sendiri. Sampling mengubah dasar kebutuhan pakan, kematian mengurangi populasi, dan pemberian pakan mengurangi persediaan yang dapat digunakan kolam lain.',
'Apabila data kegiatan dicatat secara terpisah, pengelola harus menghubungkan dan menghitung ulang catatan untuk memperoleh gambaran periode tertentu. Kesalahan jumlah atau pencatatan berulang juga dapat memengaruhi saldo dan ringkasan. Karena itu, kebutuhan proyek ini mencakup alur koreksi yang mempertahankan catatan asli, transaksi yang konsisten, serta laporan yang menunjukkan asal angka. Permasalahan tersebut merupakan dasar rancangan proyek, bukan hasil survei lapangan yang telah dilakukan.',
'FishCare diusulkan sebagai aplikasi Android untuk satu pengguna yang mengelola beberapa kolam. Pencatatan inti menggunakan database lokal agar tidak bergantung pada koneksi internet. Setiap siklus mengikat identitas ikan, populasi awal, bobot awal, jenis pakan, feeding rate manual, dan jam pemberian. Perubahan keadaan ikan kemudian dicatat melalui kegiatan yang mempunyai aturan dan jejak historis.',
'Informasi cuaca disediakan melalui API pihak ketiga untuk satu lokasi usaha. Cuaca membantu pengguna mengetahui kondisi sekitar, tetapi tidak dianggap sebagai suhu air kolam dan tidak mengubah pakan secara otomatis. Pemisahan ini menjaga aplikasi tetap berfungsi sebagai alat pencatatan yang dapat diperiksa, tanpa menawarkan acuan budidaya yang belum memiliki sumber.',
'Proyek ini merupakan penerapan mata kuliah Pemrograman Perangkat Bergerak. Rancangan baru mengacu pada PRD FishCare v0.1 dan keputusan pengembangan yang telah dicatat [5]. Prioritasnya adalah keandalan alur dan demonstrasi pada HP fisik sampai akhir Oktober 2026. Kode, data, dan desain lama tidak diperlakukan sebagai spesifikasi aplikasi baru.')
head('1.2 Rumusan Masalah')
for t in ['1. Bagaimana merancang aplikasi Android yang menghubungkan kolam, siklus, populasi, kebutuhan pakan, dan stok dalam satu sumber data lokal?',
'2. Bagaimana menjaga transaksi tetap konsisten ketika stok dipakai bersama, terjadi koreksi atau pembatalan, dan pengguna mengulangi tindakan simpan?',
'3. Bagaimana menyusun laporan dengan periode serta filter kolam yang sama dan menjaga angka historis setelah harga atau kondisi ikan berubah?',
'4. Bagaimana menyediakan informasi cuaca beserta pemilihan lokasi atas tindakan pengguna tanpa menghambat pencatatan saat jaringan gagal?',
'5. Bagaimana memverifikasi alur aplikasi melalui pengujian otomatis, build Android, dan percobaan pada perangkat fisik?']:p(t,after=6)
head('1.3 Tujuan Proyek')
prose('Tujuan umum proyek adalah mengembangkan FishCare sebagai aplikasi Android yang membantu pengelola mencatat budidaya beberapa kolam, menghitung kebutuhan pakan berdasarkan data tersimpan, dan menelusuri kegiatan serta hasil panen.',
'Tujuan khususnya mencakup pengelolaan kolam dan siklus, master pakan serta stok bersama, pencatatan aktual per slot, sampling dan pengurangan populasi, panen parsial/akhir, serta laporan periode. Aplikasi juga dirancang menyediakan cuaca dari API nyata dan mekanisme backup/restore sesuai tahap yang disetujui. Setiap kegiatan penting harus mempunyai validasi, konfirmasi, dan penanganan gagal yang dapat dipahami pengguna.',
'Keberhasilan teknis ditentukan melalui bukti terpisah untuk analisis kode, tes otomatis, build APK, instalasi, dan uji HP. Targetnya mencakup tidak adanya saldo/populasi negatif, transaksi ganda, kehilangan riwayat, atau pembekuan navigasi pada skenario penerimaan. Target tersebut belum merupakan klaim bahwa seluruh pemeriksaan sudah lulus.')
head('1.4 Manfaat Proyek')
prose('Bagi pengelola, FishCare diharapkan memudahkan pencatatan kegiatan harian dan pemeriksaan asal angka stok, populasi, serta laporan. Informasi tersimpan per kolam dan siklus sehingga pengguna tidak perlu mengubah riwayat untuk melihat keadaan terbaru.',
'Bagi mahasiswa, proyek memberikan pengalaman menerjemahkan kebutuhan menjadi antarmuka, aturan bisnis, database, integrasi API, dan pengujian Android. Bagi kegiatan pembelajaran, proyek menyediakan contoh keterkaitan validasi input, transaksi atomik, snapshot historis, dan penanganan jaringan. Peningkatan produksi atau penghematan usaha belum diukur sehingga tidak dinyatakan sebagai hasil proyek.')

newpage('BAB 2','TINJAUAN PUSTAKA')
head('2.1 Konsep Aplikasi Mobile')
prose('Aplikasi mobile menyajikan interaksi melalui perangkat bergerak yang digunakan langsung oleh pengguna. Ukuran layar, sentuhan, keyboard, perubahan orientasi perhatian, dan koneksi yang tidak selalu tersedia memengaruhi cara informasi disajikan. Pada FishCare, form satu kolom dan langkah singkat dipilih agar pencatatan dapat dilakukan melalui HP.',
'Pendekatan penyimpanan lokal menempatkan data budidaya pada perangkat pengguna. Membuka kolam, mencatat stok, dan merekam kegiatan tidak memerlukan server aplikasi. Layanan yang membutuhkan internet dibatasi pada pencarian lokasi serta cuaca. Konsekuensinya, pengelola tetap perlu mempunyai salinan cadangan di luar data privat aplikasi untuk menghadapi kerusakan atau kehilangan perangkat.',
'Satu pengguna dan satu lokasi usaha menjadi batas rancangan versi pertama. Kolam tetap dapat berjumlah lebih dari satu, tetapi tidak ada pembagian akun, pengelolaan hak akses, atau sinkronisasi antarperangkat. Batas tersebut menjaga perhatian proyek pada alur pencatatan yang dapat diverifikasi.')
head('2.2 Framework Flutter / Android')
prose('Flutter menyediakan antarmuka deklaratif berbasis widget; tampilan disusun berdasarkan state aplikasi [1]. FishCare menggunakan Flutter dengan bahasa Dart dan menargetkan Android. Pemilihan ini dipadukan dengan struktur sederhana agar mahasiswa dapat memahami hubungan layar, aturan, repository, dan penyimpanan.',
'Aturan perhitungan dipisahkan dari widget. Dengan demikian, kebutuhan pakan pada detail siklus dan halaman pemberian menggunakan perhitungan bersama. Perubahan data memicu pemuatan ulang state yang relevan, sedangkan hasil permintaan yang sudah tidak sesuai layar atau filter diabaikan. Integrasi layanan perangkat tetap mengikuti siklus hidup serta izin Android.',
'Kesesuaian teknologi tidak cukup dibuktikan oleh kode yang dapat dibaca. Toolchain Flutter/Dart, Java, Gradle, SDK, dan plugin harus menghasilkan APK yang benar-benar dapat dipasang. Karena itu, versi lingkungan yang berhasil dicatat dan dependency dikunci. Target kompatibilitas tidak disimpulkan dari nomor sistem yang belum diverifikasi.')
head('2.3 UI/UX dalam Aplikasi Mobile')
prose('UI mengatur komponen visual dan interaksi, sedangkan UX menekankan keterpahaman serta kelancaran alur pengguna. Pada FishCare, prinsip tersebut diterapkan melalui empat menu tetap, satuan di samping angka, label field yang selalu terlihat, serta ringkasan sebelum transaksi penting. Status Diberikan, Menunggu, Batal, dan Offline disertai teks agar tidak bergantung pada warna.',
'Form harus tetap dapat digunakan ketika keyboard muncul. Penyesuaian terhadap area keyboard diperlukan agar field fokus dan tindakan penting terjangkau [4]. Rancangan mengusulkan target sentuh utama minimal 48 dp, pengujian lebar 360 dp, serta pembesaran teks 130%. Ukuran tersebut merupakan acuan pemeriksaan antarmuka, bukan hasil uji pada seluruh perangkat.',
'Feedback membedakan proses membaca, menyimpan, berhasil, validasi gagal, dan hasil simpan belum pasti. Loading tidak mengganti data yang belum diketahui menjadi nol. Saat jaringan cuaca gagal, pengguna tetap dapat berpindah tab dan mencatat kegiatan lokal. Kesalahan form mempertahankan isian untuk diperbaiki.')
head('2.4 Teknologi Backend / API')
prose('FishCare tidak membangun backend sendiri. SQLite menjadi basis data lokal, sedangkan Open-Meteo menjadi layanan eksternal untuk informasi cuaca. Dukungan transaksi SQLite memungkinkan perubahan terkait diperlakukan sebagai satu kesatuan yang selesai seluruhnya atau tidak diterapkan [2]. Rancangan menggunakan sifat ini untuk menjaga stok, populasi, dan catatan kegiatan tetap selaras.',
'Snapshot menyimpan nilai penting pada saat transaksi, seperti harga pakan, rate, biomassa, atau harga dan bobot panen. Snapshot berbeda dari kondisi terkini. Harga master dapat berubah untuk transaksi berikutnya, tetapi laporan kegiatan lama tetap memakai nilai tersimpan. Tindakan juga menggunakan ID stabil agar pengulangan permintaan tidak membuat transaksi baru.',
'Open-Meteo mendokumentasikan pengambilan cuaca melalui koordinat serta parameter dengan satuan tertentu [3]. FishCare merancang tampilan suhu udara, kondisi, dan peluang hujan harian bila tersedia, beserta lokasi dan waktunya. Data yang tersimpan sementara diberi label cache/offline ketika tidak berhasil diperbarui. Nilai yang tidak tersedia tidak diubah menjadi angka nol.')

newpage('BAB 3','PERANCANGAN SISTEM')
head('3.1 Gambaran Umum Sistem')
prose('Pengguna utama adalah pengelola budidaya yang mencatat kegiatan sendiri. Alur awal dimulai dari membuat master pakan dan stok masuk, membuat kolam, lalu memulai siklus. Siklus aktif mengikat satu jenis ikan dan satu jenis pakan sesuai baseline versi pertama. Riwayat kolam tetap tersedia setelah siklus selesai atau kolam diarsipkan.',
'Pada penggunaan harian, pengelola membuka jadwal, meninjau kebutuhan, dan mengisi jumlah aktual pada slot yang sah. Sampling memperbarui bobot, sedangkan kematian atau panen mengubah populasi. Setiap perubahan yang relevan menghitung ulang porsi menunggu. Pemberian yang sudah selesai menyimpan snapshot dan tidak ditulis ulang.',
'Laporan menggunakan tanggal mulai/akhir inklusif dan satu atau semua kolam, termasuk kolam arsip. Cuaca dapat diatur tanpa menghalangi pembuatan data lokal. Tidak ada kota contoh yang otomatis menjadi lokasi usaha dalam aplikasi produk; seluruh contoh pada gambar proposal adalah data rancangan.')
head('3.2 Arsitektur Sistem')
pic(ROOT/'tmp/proposal/arsitektur.png',6.3,'Gambar 1 Arsitektur FishCare dan batas layanan eksternal')
prose('Lapisan UI/state menerima input dan menampilkan hasil. Lapisan aturan bisnis menangani parser angka, rumus, kelayakan tindakan, dan dampak perubahan. Repository menjadi batas akses data, lalu SQLite atau klien API melaksanakan pembacaan/penulisan. Validasi kritis diulang saat transaksi, bukan hanya pada form.',
'Database lokal menjadi sumber utama pencatatan. Klien cuaca memiliki batas tunggu dan state terpisah sehingga kegagalan jaringan tidak menahan fungsi kolam/pakan. Penanda permintaan membedakan respons terbaru dari respons yang datang terlambat setelah filter atau lokasi diganti.')

newpage('3.3 Use Case Diagram')
pic(ROOT/'tmp/proposal/usecase.png',6.3,'Gambar 2 Use case pengelola dan API Open-Meteo')
p('Pengelola menjalankan seluruh kegiatan lokal. Open-Meteo hanya terlibat pada cuaca/pencarian lokasi. Backup/restore ditampilkan sebagai kebutuhan yang masih direncanakan, bukan fitur yang sudah selesai.')
table(['Use case','Prasyarat dan hasil utama','Acuan'],[
('Kelola kolam / siklus / pakan','Nama unik; satu siklus aktif; stok ledger dan koreksi tidak membuat saldo negatif.','FR-01–03'),
('Catat pemberian','Slot sah, gram positif, stok cukup; snapshot, status, dan stok keluar atomik.','FR-04'),
('Sampling / populasi / panen','Sampling tidak mengurangi ikan; pengurangan valid; akhir memakai sisa atau tutup tanpa panen.','FR-05–06'),
('Lihat laporan','Satu filter periode/kolam pada seluruh metrik dan pendukung.','FR-07'),
('Pilih lokasi / cuaca','Calon dikonfirmasi menjadi satu lokasi usaha; cuaca tidak mengubah pakan.','FR-08'),
('Backup / restore','Rencana ekspor konsisten, validasi berkas, dan pemulihan aman saat gagal.','FR-09')
],[1.35,4.25,.9])
minor('Alur alternatif dan pembatalan')
p('Form yang belum disimpan dapat ditinggalkan dengan konfirmasi buang perubahan bila draft berubah. Gagal validasi tidak mengubah database. Kandidat pembatalan operasional adalah kegiatan sah terakhir pada siklus aktif dan hari yang sama; rate, perubahan jam, dan Lewati bukan penghalang. Kegiatan yang memiliki kegiatan operasional lanjutan ditolak untuk dibatalkan. Panen akhir dan siklus selesai tidak dapat dibatalkan.')

newpage('3.4 Desain Database')
prose('Skema sumber produk saat penyusunan tercatat versi 5. Database percobaan M0 terpisah dari database pengguna. Diagram memperlihatkan relasi inti; tabel pendukung rate, versi jadwal, koreksi, niat tindakan, dan cuaca dirinci pada tabel berikut. Migrasi menambah atau menyesuaikan struktur tanpa reset data [5].')
pic(ROOT/'tmp/proposal/relasi.png',5.7,'Gambar 3 Relasi inti kolam, kegiatan, pemberian, dan pergerakan stok')
p('operations dan feedings berbagi ID tindakan yang sama dan masing-masing mengacu action_intents; garis di antaranya menunjukkan keterkaitan logis, bukan foreign key langsung. Satu slot dapat memiliki beberapa riwayat pemberian batal, tetapi maksimal satu pemberian sah.',size=10)
table(['Tabel / kelompok','Data utama dan relasi'],[
('ponds','ID, nama unik, catatan, dan arsip. Satu kolam memiliki banyak siklus historis.'),
('feeds','ID, nama unik, harga tercatat rupiah/kg, dan arsip. Satu pakan dapat dipakai banyak siklus.'),
('cycles','FK pond_id/feed_id, ikan, data awal, kondisi terkini, tanggal, dan status. Maksimal satu aktif per kolam.'),
('cycle_rates','Riwayat rate manual dan waktu perubahan per siklus.'),
('cycle_schedules; cycle_times','Versi jadwal bertanggal efektif dan 1–6 menit pemberian unik.'),
('cycle_slots','PK gabungan siklus/tanggal usaha/menit; porsi rencana, status, dan penanda penghentian.'),
('feedings','Aktual, referensi slot/pakan, snapshot perhitungan/harga/biaya, dan pembatalan.'),
('operations','Urutan commit lintas jenis; kondisi sebelum/sesudah; snapshot panen dan status batal.')
],[1.6,4.9])
minor('Tabel pendukung dan bentuk angka')
table(['Tabel / nilai','Penyimpanan dan aturan'],[
('stock_movements','Ledger masuk, keluar, reversal, atau selisih koreksi; FK pakan dan sumber terkait.'),
('stock_corrections','Asal stok masuk, jumlah efektif lama/baru, alasan wajib, dan tanggal koreksi.'),
('action_intents','ID tindakan unik, jenis/target/payload tetap, state, hasil, dan pengakuan UI.'),
('business_settings','Zona usaha; ketentuan pengunci mengikuti keputusan proyek.'),
('weather_location','Satu baris lokasi usaha: nama, lintang, bujur, perkiraan, serta akurasi bila ada.'),
('weather_cache','Respons tervalidasi dan waktu pengambilan berdasarkan kunci koordinat.'),
('Jumlah dan uang','INTEGER: ikan dalam ekor, pakan dalam gram bulat, uang dalam rupiah bulat.'),
('Bobot dan rate','INTEGER berskala: seperseratus gram dan seperseratus persen; maksimal dua desimal input.'),
('Tanggal / waktu / koordinat','Tanggal usaha YYYY-MM-DD; timestamp epoch milidetik UTC; koordinat REAL terbatas dan finite.')
],[1.6,4.9])
minor('Constraint dan transaksi atomik')
prose('Nama kolam/pakan unik setelah normalisasi spasi tepi dan kapitalisasi. Indeks serta validasi mencegah siklus aktif ganda, jam duplikat, sampling sah kedua pada hari yang sama, dan pemberian sah ganda per slot. Stok atau populasi dibaca kembali dalam transaksi sebelum pengurangan. Angka negatif, NaN/infinity, nilai ambigu, dan hasil di luar kapasitas penyimpanan ditolak.',
'Pemberian menyimpan aktual, snapshot, stok keluar, status slot, hasil tindakan, dan perhitungan porsi menunggu sebagai satu transaksi. Penutupan siklus menyimpan panen bila ada, menutup siklus, dan menghentikan slot menunggu secara atomik. Error tidak boleh meninggalkan sebagian perubahan.',
'ID tindakan disimpan sebagai niat sebelum transaksi bisnis dijalankan. Jika aplikasi berhenti saat hasil belum diketahui, aplikasi memeriksa hasil memakai ID yang sama. Pengguna dapat melakukan retry eksplisit setelah pemeriksaan; aplikasi tidak membuat ID baru atau mengulang transaksi otomatis. ID yang sudah berhasil mengembalikan hasil lama tanpa pemotongan kedua.')
minor('Snapshot dan koreksi historis')
prose('Snapshot pemberian memuat harga, rate, populasi/bobot atau biomassa, dan biaya saat pemberian. Snapshot panen menyimpan jumlah, bobot, harga jual, serta nilai hasil. Perubahan harga, rate, atau sampling berikutnya tidak mengubah angka historis. Field panen hanya terisi pada panen parsial/akhir; transaksi kematian tidak diberi bobot atau nilai panen nol sebagai pengganti data yang tidak ada.',
'Koreksi stok masuk mempertahankan catatan asal dan menambah pergerakan sebesar baru dikurangi lama. Jumlah efektif dan saldo setelah koreksi tidak boleh negatif; koreksi dari pratinjau yang sudah berubah ditolak. Pembatalan pemberian membuat reversal stok tepat sebesar aktual lama; pembatalan kegiatan lain memulihkan populasi atau bobot sesuai jenisnya, lalu menghitung ulang pending.',
'Backup direncanakan membaca snapshot database yang konsisten dan menyertakan versi skema. Restore memvalidasi struktur serta hubungan sebelum mengganti data. Salinan pemulihan dibuat lebih dahulu; jika proses gagal, data lama dipertahankan. Pola pemulihan niat sesudah restore perlu dirinci sebelum fitur tersebut dibangun. Backup/restore belum dinyatakan selesai.')

newpage('3.5 Desain UI/UX (Wireframe)')
prose('Desain baru menggunakan empat menu utama: Beranda, Kolam, Pakan, dan Laporan. Pengaturan diakses dari Beranda. Palet hijau tua dan latar terang mendukung kontras, sementara status selalu memakai label. Gambar berikut adalah rancangan dengan data simulasi; tampilan ini belum diterapkan sebagai desain final pada aplikasi Flutter [6].')
pair('home','ponds','Gambar 4 Rancangan Beranda dan daftar kolam')
p('Beranda memprioritaskan tugas pakan dan kolam aktif. Informasi cuaca berada setelah data lokal dan dapat digulir. Kolam membedakan siklus aktif, belum ada siklus, serta arsip; pengguna dapat membuka detail atau memulai siklus yang memenuhi syarat (FR-01–02; AT-01/19).',size=11)

newpage('Desain detail kolam dan mulai siklus')
p('Detail kolam menyajikan kondisi saat ini, kebutuhan terbaru, serta akses kegiatan. Form mulai siklus memisahkan jumlah, bobot, pakan, rate manual, dan jam. Isian awal ditinjau sebelum disimpan; data awal tertentu dikunci setelah siklus dimulai.')
pair('pond','cycle','Gambar 5 Rancangan detail kolam dan form mulai siklus')
p('Form satu kolom dapat digulir. Label dan satuan tetap terlihat ketika keyboard terbuka; tombol utama mengikuti area aman. Rate wajib valid dan mengikuti acuan pengguna/dosen, bukan rekomendasi aplikasi. Kolam yang sedang bersiklus tidak dapat diarsipkan (FR-01–02/04; AT-02–03/27).',size=11)

newpage('Desain pemberian dan stok pakan')
p('Bagian Pemberian hari ini menampilkan kebutuhan, aktual, sisa, dan status slot. Bagian Stok pakan menunjukkan saldo yang dipakai bersama, harga tercatat, serta pergerakan. Tindakan stok masuk tidak menimpa saldo total.')
pair('feed','stock','Gambar 6 Rancangan pemberian harian dan stok bersama')
p('Berikan membuka form aktual dan konfirmasi biaya/stok. Stok kurang menolak seluruh perubahan. Rate baru berlaku sekarang untuk pending; jam baru berlaku besok. Lewati tidak membuat pemberian nol atau stok keluar. Koreksi beralasan mempertahankan asal (FR-03–04; AT-04–10/28–30).',size=11)

newpage('Desain laporan dan lokasi usaha')
p('Laporan memakai filter inklusif yang sama pada seluruh metrik dan pendukung. Halaman lokasi menampilkan lokasi tersimpan serta pilihan pengambilan HP atau pencarian manual. Keduanya menghasilkan calon yang harus dikonfirmasi.')
pair('report','location','Gambar 7 Rancangan laporan dan pengaturan lokasi usaha')
p('Ambil lokasi saat ini meminta izin foreground bila perlu dan mengambil sekali. Tidak ada pengambilan startup, pelacakan, atau akses background. Simpan sebagai lokasi usaha mengganti lokasi lama setelah konfirmasi berhasil. Cuaca diperbarui dari koordinat tersimpan (FR-07–08; AT-37–45).',size=11)
minor('Kontrak keadaan antarmuka')
table(['Keadaan','Respons yang dirancang'],[
('Kosong','Pesan sesuai konteks dan tindakan pertama; tidak memasukkan data contoh ke pengguna.'),
('Loading','Indikator pada area data; navigasi aktif, tidak menampilkan angka nol palsu.'),
('Menyimpan / berhasil','Tombol simpan nonaktif selama proses; sukses memuat ulang data halaman terkait.'),
('Gagal','Input dan filter dipertahankan; error dekat field atau Coba lagi sesuai penyebab.'),
('Offline','Pencatatan lokal berjalan; cuaca cache berlabel lokasi/waktu, tanpa cache belum tersedia.'),
('Hasil belum pasti','Periksa ID tindakan dahulu; retry hanya setelah hasil diketahui belum tersimpan.')
],[1.25,5.25])
p('Tampilan pendukung mencakup sampling, kematian, panen, konfirmasi penutupan, detail snapshot, alasan batal, dan pemeriksaan transaksi. Ukuran teks 130%, keyboard Android, serta interaksi izin tetap perlu diverifikasi pada HP; pemeriksaan browser prototipe tidak menggantikannya.')

newpage('BAB 4','RENCANA IMPLEMENTASI')
head('4.1 Teknologi yang Digunakan')
table(['Teknologi','Peran dan alasan pemakaian'],[
('Flutter dan Dart','Antarmuka Android dan aturan bisnis bersama; mudah memisahkan widget dari validasi/perhitungan.'),
('SQLite / sqflite','Penyimpanan lokal, foreign key/indeks, transaksi, dan migrasi yang mempertahankan data.'),
('Open-Meteo','Cuaca serta pencarian lokasi pihak ketiga tanpa backend milik tim.'),
('Layanan lokasi Android','Koordinat satu kali setelah tindakan pengguna dan izin foreground bila diperlukan.'),
('Android Studio / toolchain','Menjalankan analisis, tes, build APK, serta diagnosis Java/Gradle/SDK.'),
('HP fisik','Memverifikasi instalasi, input sentuh/keyboard, persistensi, izin, dan jaringan nyata.')
],[1.65,4.85])
prose('Versi sumber tercatat 0.7.0+7 dan versi skema produk 5. Angka ini menunjukkan isi sumber saat penyusunan, bukan bukti bahwa build APK terbaru telah berhasil. Lockfile serta konfigurasi yang telah memiliki bukti tetap dipertahankan. Versi lingkungan dan perangkat teruji dicatat pada README proyek, sedangkan klaim kompatibilitas dibatasi pada pengujian yang tersedia.',
'Dependency hanya digunakan bila kebutuhan fitur memang memerlukannya. Perubahan plugin, manifest, atau layanan native harus diperiksa dengan build Android. Keberhasilan tes aturan Dart tidak cukup untuk membuktikan integrasi Android atau penyimpanan SQLite pada HP.')
head('4.2 Struktur Aplikasi')
prose('UI/state mengelola navigasi, draft, filter, dan indikator proses. Aturan bisnis memuat parser angka, pembulatan, perhitungan kebutuhan, pembagian porsi, dan kelayakan kegiatan. Repository menangani transaksi serta pembacaan konsisten, sedangkan akses data menghubungkan SQLite atau layanan API. Pembagian ini menjaga perhitungan tidak tersebar sebagai rumus berbeda pada setiap layar.',
'Paket aplikasi baru ditempatkan terpisah dari proyek lama. Database produk terpisah dari marker percobaan M0. Pengembangan versi berikutnya dilakukan melalui migrasi, tanpa meminta uninstall atau menghapus data agar skema baru dapat digunakan. Sinyal perubahan setelah commit membuat Beranda, detail, Pakan, dan Laporan membaca ulang saat dibuka.',
'Satu penanggung jawab integrasi menggabungkan perubahan dari tim. Perubahan kebutuhan dicatat dahulu pada PRD serta skenario penerimaan yang terdampak. Versi teknologi atau fitur tidak dinaikkan sekaligus hanya karena tersedia versi lebih baru; perubahan harus mempunyai alasan dan pemeriksaan yang sesuai.')
head('4.3 Fitur Utama Aplikasi')
minor('Kolam dan siklus budidaya')
prose('Pengelola membuat dan mengubah identitas kolam, melihat detail/riwayat, serta mengarsipkan kolam tanpa siklus aktif. Mulai siklus memerlukan ikan, jumlah awal positif, bobot awal positif, master pakan, rate manual, dan 1–6 jam unik. Siklus, rate awal, dan jadwal disimpan sekaligus. Sistem menolak siklus aktif kedua pada kolam yang sama (FR-01–02).')
minor('Stok dan pemberian pakan')
prose('Saldo stok dipakai bersama seluruh kolam yang menggunakan pakan itu. Setiap penambahan berupa ledger masuk. Koreksi menyimpan jumlah lama, jumlah baru, alasan, dan selisih; saldo tidak boleh negatif. Harga tercatat berlaku untuk pemberian berikutnya, sedangkan riwayat mempertahankan harga sebelumnya (FR-03).',
'Kebutuhan harian dihitung dari populasi terkini × bobot rata-rata terbaru × rate/100. Bobot dan rate maksimal dua desimal disimpan sebagai integer berskala. Pembulatan nonnegatif memakai half-up, yaitu tepat setengah dibulatkan naik. Porsi gram dibagi merata dan kelebihan gram diberikan mulai jam paling awal. Rate yang belum valid berarti Belum bisa dihitung, bukan kebutuhan nol (FR-04).')
table(['Contoh penerimaan','Hasil yang diharapkan'],[
('100 ikan × 100 g × 3%','300 g/hari; dua slot masing-masing 150 g.'),
('301 g pada dua slot','151 g + 150 g; total tidak berubah.'),
('Aktual 150 g, lalu sampling 120 g','Kebutuhan 360 g dan sisa 210 g; riwayat aktual150 g tetap.'),
('Aktual150 g, hargaRp10.000/kg','Snapshot biayaRp1.500; stok keluar tepat150 g.'),
('Stok100 g, mencoba aktual150 g','Ditolak utuh; stok, status slot, dan riwayat tidak berubah.')
],[3.2,3.3])
prose('Setelah perubahan rate, bobot, atau populasi, sisa adalah maksimum nol dari kebutuhan terbaru dikurangi total aktual sah hari ini. Sisa dibagi hanya ke slot menunggu; slot diberikan dan dilewati tidak ditulis ulang. Jam yang diubah berlaku besok, termasuk bila halaman hari ini belum pernah dibuka. Jika semua slot selesai/dilewati dan masih sisa, tampilkan Sisa belum diberikan tanpa slot otomatis tambahan.')
minor('Sampling dan perubahan populasi')
prose('Sampling memerlukan jumlah sampel positif yang tidak melebihi populasi dan bobot rata-rata positif. Maksimal satu sampling sah per siklus per hari; sampling tidak mengurangi populasi. Kematian mengurangi jumlah ikan, boleh sampai seluruh sisa mati, tetapi tidak melebihi populasi terkini. Panen parsial harus menyisakan ikan dan memiliki bobot serta harga jual positif (FR-05).',
'Nilai panen berasal dari jumlah × bobot rata-rata gram × harga jual/kg dibagi1000, kemudian dibulatkan per transaksi. Contoh20 ikan ×200 g ×Rp25.000/kg menghasilkanRp100.000. Jumlah, bobot, harga, dan nilai disimpan agar sampling berikutnya tidak mengubah panen lama.')
minor('Panen akhir dan pembatalan lintas kegiatan')
prose('Panen akhir memakai seluruh populasi tersisa yang dibaca ulang dalam transaksi. Bobot dan harga wajib jika masih ada ikan. Jika populasi nol, sistem menutup siklus tanpa membuat panen fiktif. Penutupan menyimpan hasil, menghentikan slot menunggu, dan mencegah kegiatan baru secara atomik (FR-06).',
'Kandidat pembatalan adalah kegiatan sah terakhir di antara pemberian, sampling, kematian, dan panen parsial dalam siklus aktif pada hari yang sama. Alasan wajib dan kelayakan diperiksa ulang. Pembatalan memulihkan stok, populasi, atau bobot sesuai kegiatan, mempertahankan riwayat, dan menghitung ulang pending. Panen akhir serta siklus selesai tidak dapat dibatalkan.')
minor('Laporan budidaya')
prose('Laporan menampilkan pakan aktual, biaya pakan, ikan mati, ikan panen, dan nilai panen dengan satu rentang tanggal inklusif serta filter kolam yang sama. Panen parsial dan akhir dihitung pada tanggal transaksi. Transaksi batal terlihat dengan alasan tetapi tidak masuk total. Nilai uang dijumlahkan dari snapshot per transaksi, tanpa menggunakan master terkini atau pembulatan ulang total gabungan (FR-07).',
'Kartu Kondisi saat ini dan Seluruh siklus dipisahkan dari Transaksi periode. Daftar pendukung dan detail mempertahankan filter. Penyimpanan atau pembatalan memperbarui data tanpa restart. Permintaan dengan filter lama yang selesai terlambat diabaikan. Tidak ada FCR atau keuntungan bersih; nilai panen dikurangi biaya pakan tidak dilabeli sebagai keuntungan.')
minor('Cuaca dan satu lokasi usaha')
prose('Pengguna mencari lokasi manual atau menekan Ambil lokasi saat ini untuk memperoleh koordinat sekali. Izin foreground diminta bila perlu; aplikasi tidak mengambil lokasi saat dibuka, tidak melacak perpindahan, dan tidak meminta akses background. Calon lokasi disimpan setelah konfirmasi Simpan sebagai lokasi usaha dan dipakai untuk seluruh kolam (FR-08).',
'GPS mati, izin ditolak, atau pengambilan gagal ditanggapi dengan penjelasan dan pilihan coba lagi/manual. Lokasi lama dipertahankan sampai pengganti berhasil dikonfirmasi. Refresh cuaca memakai koordinat tersimpan. Respons lokasi lama diabaikan agar tidak mengganti hasil untuk lokasi baru.',
'Cuaca menampilkan lokasi, waktu model, waktu pengambilan, satuan, atribusi, dan status cache. Rancangan PRD menetapkan batas tunggu10detik, cache30menit, dan jeda refresh minimal60detik. Loading selalu berakhir; kegagalan jaringan tidak membekukan navigasi. Tidak tersedia ditulis sebagai tidak tersedia, bukan0.')
minor('Backup dan restore')
prose('FR-09 merencanakan ekspor seluruh data penting dalam snapshot konsisten dengan versi skema. Pengguna memilih tujuan melalui pemilih file sistem; membatalkan pemilih bukan backup berhasil. Restore mengganti seluruh data setelah ringkasan dan konfirmasi, bukan menggabungkannya. Berkas rusak atau versi tidak didukung ditolak sebelum penggantian, dan kegagalan mempertahankan data lama. Fitur ini belum dibangun dan tidak dinyatakan sudah teruji.')

newpage('4.4 Timeline Pengembangan')
p('Target penyelesaian adalah akhir Oktober2026. Tabel berikut mempertahankan rencana waktu PRD sebagai target kerja, bukan urutan bukti bahwa semua implementasi/tes sudah selesai. Bila pemeriksaan terhalang, tindak lanjut ditentukan dari masalah yang belum terselesaikan.')
table(['Waktu Oktober2026','Tahap','Keluaran yang ditargetkan'],[
('13–15','Kebutuhan, rancangan, M0','Dokumen kebutuhan; alur/data/UI; aplikasi dasar, SQLite, API nyata pada HP.'),
('16–20','Master, siklus, pakan, stok','Pencatatan aktual serta koreksi dengan transaksi dan migrasi.'),
('21–23','Populasi, panen, laporan','Kegiatan ikan, snapshot, pembatalan, dan laporan konsisten.'),
('24–26','Cuaca, backup/restore, UI','Izin/lokasi, jaringan gagal, perlindungan data dan tampilan konsisten.'),
('27–29','Regresi dan dokumentasi','APK kandidat, hasil uji, proposal, dan latihan demonstrasi.'),
('30–31','Buffer dan presentasi','Perbaikan akhir; artifact serta cadangan data demonstrasi.')
],[1.1,1.8,3.6])
minor('Pembagian tanggung jawab kelompok')
p('Enam anggota mengisi peran berikut sesuai kesepakatan kelompok. Pembagian ini adalah rencana tanggung jawab dan tidak mengarang nama, kemampuan, atau kontribusi individu yang belum dicatat.')
table(['Peran','Tanggung jawab'],[
('Anggota1','Koordinasi, kebutuhan, batas fitur, dan penelusuran FR/AT.'),
('Anggota2','Alur pengguna, desain layar, dan pemeriksaan keterpakaian.'),
('Anggota3','Integrasi aplikasi dan diagnosis build Android.'),
('Anggota4','Aturan data, transaksi, migrasi, dan tes otomatis.'),
('Anggota5','Integrasi cuaca/lokasi dan pengujian HP.'),
('Anggota6','Dokumentasi, artifact presentasi, dan skenario demonstrasi.')
],[1.1,5.4])
minor('Rencana pengujian dan kriteria selesai')
prose('Pengujian unit memeriksa parser angka, rumus, half-up, pembagian porsi, dan validasi domain. Pengujian transaksi memeriksa saldo/populasi, snapshot, rollback, pembatalan, serta retry ID. Pengujian widget memeriksa state, filter, dan navigasi. Integrasi native serta uji HP memeriksa migrasi, persistensi, keyboard, izin, dan jaringan nyata.',
'Jalur standar adalah flutter analyze, seluruh flutter test, dan flutter build apk --debug dari root aplikasi. APK yang dihasilkan kemudian diverifikasi versinya, dipasang tanpa uninstall/reset, dan diuji. Keberhasilan satu jenis pemeriksaan tidak menggantikan yang lain. Lingkungan yang menghalangi harus dicatat dengan penyebab dari log.')
table(['Kelompok skenario','Bukti yang diperlukan','Acuan'],[
('Rumus / angka','300 g, pembagian301g, tepat setengah, input ambigu/invalid ditolak.','AT-02/03/27'),
('Stok / retry','Stok bersama, kurang, koreksi, snapshot harga, ketuk ganda.','AT-04–07/15/29'),
('Jadwal / hari','Jam besok, pending hari ini, Lewati, pergantian tanggal.','AT-08–10/26/28'),
('Populasi / tutup','Sampling sah, kematian berlebih, parsial/akhir, nol tanpa panen.','AT-11–14/32–35'),
('Batal / recovery','Kandidat terakhir, alasan, reversal, rollback, ID tetap sesudah restart.','AT-16/17/25/30/31/34'),
('Laporan','Batas tanggal, arsip, batal, snapshot, scope, dan hasil filter lama.','AT-18/19/37–40'),
('Cuaca / lokasi','Timeout/offline, cache, lokasi sekali, penolakan, calon dan persistensi.','AT-20–22/41–45'),
('Data lama / backup','Migrasi menjaga data; backup/restore valid maupun gagal.','AT-23/24/36')
],[1.25,3.95,1.3])
prose('Kandidat demonstrasi dinyatakan siap setelah build, pemasangan, dan alur utama memiliki bukti; tidak ada masalah terbuka yang menyebabkan hilangnya data, transaksi ganda, saldo negatif, perhitungan salah, atau aplikasi tidak dapat digunakan. Sasaran respons PRD adalah halaman lokal dalam2detik dan simpan biasa dalam1detik pada dataset uji10kolam,50siklus,10.000transaksi. Ini target pengukuran, bukan angka hasil uji.')
minor('Risiko dan penanganan')
table(['Risiko','Penanganan yang direncanakan'],[
('SDK/Java/Gradle atau izin cache','Diagnosis dari log, gunakan jalur izin resmi; tidak menyalin SDK sebagai pengganti bukti build.'),
('Transaksi terganggu / retry','Niat ID persisten, atomisitas, pemeriksaan hasil sesudah restart.'),
('Jaringan / lokasi gagal','Timeout, cache berlabel, manual/retry, navigasi lokal tetap aktif.'),
('Data hilang saat upgrade','Migrasi bertransaksi, suite data lama, tidak reset/uninstall.'),
('Waktu terbatas / ruang lingkup bertambah','Kerjakan tahap yang diizinkan dan prioritaskan regresi serta demonstrasi.'),
('Keputusan rancangan belum final','Tandai usulan dan selesaikan aturan sebelum fitur terkait dibangun.')
],[1.7,4.8])
minor('Status pengembangan dan verifikasi')
prose('Pengguna melaporkan aplikasi M0 berjalan di HP, marker SQLite dapat disimpan/dibaca, API nyata menampilkan cuaca Jakarta, serta percobaan tanpa jaringan menampilkan error dengan tombol Kembali. Persistensi marker yang sama setelah ditutup paksa belum dikonfirmasi secara khusus. Pengguna juga melaporkan pengujian manual M1 dan seluruh percobaan gabungan M2+M3 yang diberikan berhasil.',
'Sumber M4/M5 beserta pengambilan lokasi atas tindakan pengguna telah dikerjakan, tetapi uji HP M4/M5 belum dikonfirmasi. README masih mencatat analisis Flutter, seluruh tes standar, dan build terbaru terhalang akses tulis SDK/cache. Format atau checker tambahan yang lulus tidak menggantikan pemeriksaan standar, build, atau pengujian native. Desain baru diperiksa melalui browser, dan penerapannya ke Flutter belum dikerjakan.',
'Keputusan stok masuk, pembatalan lintas kegiatan, pemulihan ID, dan pengambilan lokasi telah ditetapkan dalam lingkup tahap terkait. PRD tetap berstatus draf; usulan lain tidak dianggap disetujui satu per satu. Pengunci zona waktu, rincian pemulihan setelah restore, dan keputusan fitur masa depan ditinjau sebelum implementasinya. Proposal ini tidak mengubah aturan PRD.')

newpage('BAB 5','PENUTUP')
head('5.1 Kesimpulan')
prose('FishCare dirancang sebagai aplikasi Android untuk satu pengelola dengan beberapa kolam dan penyimpanan lokal. Rancangan menghubungkan master pakan, stok, siklus, kegiatan ikan, dan laporan melalui data yang dapat ditelusuri. Cuaca menjadi informasi tambahan untuk satu lokasi usaha tanpa memengaruhi perhitungan pakan secara otomatis.',
'Keandalan pencatatan dibangun melalui validasi, transaksi atomik, snapshot historis, serta ID tindakan persisten. Pembatalan mempertahankan jejak dan memulihkan kondisi menurut jenis kegiatan. Laporan menggunakan periode/filter yang konsisten, sementara kondisi terkini dan seluruh siklus diberi label terpisah.',
'Desain baru memberikan susunan empat menu utama dan form yang ditujukan untuk HP, termasuk keadaan gagal/offline. Penyelesaian proyek tetap membutuhkan bukti analisis, tes standar, build, instalasi, dan pengujian perangkat sesuai cakupan. Proposal ini menyajikan arah pengembangan serta kriteria pemeriksaannya, bukan menyatakan seluruh aplikasi telah selesai atau bebas masalah.')
head('5.2 Rencana Pengembangan Lanjutan')
prose('Tindak lanjut terdekat adalah menyelesaikan pemeriksaan standar dan uji gabungan M4/M5 pada HP, memverifikasi izin serta persistensi lokasi, lalu menerapkan desain yang telah ditinjau. Kegiatan dilakukan tanpa menghapus data pengguna atau melewati migrasi. Masalah yang ditemukan dipetakan ke skenario penerimaan sebelum kandidat baru diserahkan.',
'Backup/restore dibangun pada tahap yang diizinkan setelah aturan pemulihannya dirinci. Pengujian meliputi pembatalan pemilih file, validasi versi/relasi, salinan pemulihan, dan kegagalan restore yang menjaga data lama. Penyelesaian tersebut tetap dalam lingkup kebutuhan awal, bukan penambahan sinkronisasi cloud atau migrasi otomatis aplikasi lama.',
'Menjelang presentasi, kelompok menyiapkan APK yang benar-benar diuji, data demonstrasi terpisah, catatan lingkungan, hasil pemeriksaan, dan salinan cadangan. FCR, keuntungan bersih, AI diagnosis, notifikasi background, serta platform lain tidak ditambahkan ke versi ini. Perluasan di masa mendatang memerlukan kebutuhan serta persetujuan ruang lingkup tersendiri.')

newpage('REFERENSI')
refs=[
'[1] Flutter. Flutter architectural overview. Dokumentasi resmi. https://docs.flutter.dev/resources/architectural-overview. Diakses15Oktober2026.',
'[2] SQLite. SQLite Is Transactional. Dokumentasi resmi. https://www.sqlite.org/transactional.html. Diakses15Oktober2026.',
'[3] Open-Meteo. Weather Forecast API Documentation. https://open-meteo.com/en/docs. Diakses15Oktober2026.',
'[4] Android Developers. Handle input method visibility. Dokumentasi resmi Android. https://developer.android.com/develop/ui/views/touch-and-input/keyboard-input/visibility. Diakses15Oktober2026.',
'[5] Tim FishCare. PRD FishCare Rancangan Baru v0.1; Alur Sistem; Rancangan Database; Wireframe; Keputusan Review; serta catatan implementasi dan verifikasi. Dokumen proyek, pembaruan13–15Oktober2026.',
'[6] Kelompok7. Rancangan UI FishCare baru. Prototipe, catatan UI/UX, dan ekspor desain PNG/PDF. Dokumen proyek,15Oktober2026.'
]
for ref in refs:p(ref,after=12)

# Rapikan spasi angka yang sengaja ringkas pada data builder, tanpa mengubah ID/tanggal/URL.
import re
all_paragraphs=list(doc.paragraphs)+[q for t in doc.tables for row in t.rows for cell in row.cells for q in cell.paragraphs]
for q in all_paragraphs:
    for r in q.runs:
        if not r.text:continue
        text=r.text
        text=re.sub(r'(Diakses|pembaruan|dibagi|Contoh|Anggota|batas tunggu|cache|minimal|aktual|Aktual|Stok|stok|tepat|uji)(?=\d)',r'\1 ',text)
        text=re.sub(r'(\d)(?=(?:g\b|detik\b|menit\b|kolam\b|siklus\b|Oktober|transaksi\b|ikan\b))',r'\1 ',text)
        text=text.replace('Kelompok7','Kelompok 7').replace('Oktober2026','Oktober 2026')
        text=re.sub(r'(?<=[a-z])(?=Rp\d)',' ',text)
        text=re.sub(r'(?<=[a-z]),(?=\d)',', ',text)
        r.text=text

footer=doc.sections[0].footer.paragraphs[0];footer.alignment=WD_ALIGN_PARAGRAPH.RIGHT
f=OxmlElement('w:fldSimple');f.set(qn('w:instr'),'PAGE');rr=OxmlElement('w:r');tt=OxmlElement('w:t');tt.text='1';rr.append(tt);f.append(rr);footer._p.append(f)
upd=OxmlElement('w:updateFields');upd.set(qn('w:val'),'true');doc.settings._element.append(upd)
work=TMP/'working-lengkap.docx';doc.save(work)
allowed={'word/document.xml','word/_rels/document.xml.rels','word/styles.xml','word/settings.xml','[Content_Types].xml'}
final=OUT/'Proposal-FishCare-Kelompok-7-Lengkap.docx'
with ZipFile(SRC) as a,ZipFile(work) as b,ZipFile(final,'w',ZIP_DEFLATED) as dest:
    for name in a.namelist():dest.writestr(name,b.read(name) if name in allowed and name in b.namelist() else a.read(name))
    for name in b.namelist():
        if name not in a.namelist() and not name.startswith('docProps/'):dest.writestr(name,b.read(name))
with ZipFile(SRC) as a,ZipFile(final) as b:
    assert all(a.read(n)==b.read(n) for n in a.namelist() if n not in allowed)
assert sha256(SRC.read_bytes()).hexdigest()=='063cb665e8e1a30c5f433157b79a740a3d3d3df89cfb317f1b60abd4a320e7f5'
print(final)
