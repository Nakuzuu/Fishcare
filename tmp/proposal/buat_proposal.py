from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from hashlib import sha256
import json, math
from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT=Path(__file__).resolve().parents[2]; TMP=Path(__file__).parent
OUT=ROOT/'output'/'laporan'; OUT.mkdir(parents=True,exist_ok=True)
SRC=Path(r'C:\Users\basti\Downloads\TEMPLATE PROPOSAL PjBL PPB.docx')
assert sha256(SRC.read_bytes()).hexdigest()=='063cb665e8e1a30c5f433157b79a740a3d3d3df89cfb317f1b60abd4a320e7f5'
FONTS=Path(r'C:\Windows\Fonts')
def font(n=28,b=False): return ImageFont.truetype(str(FONTS/('arialbd.ttf' if b else 'arial.ttf')),n)
def center(draw,xy,text,size=28,b=False,fill='#173c39'):
    draw.multiline_text(xy,text,font=font(size,b),fill=fill,anchor='mm',align='center',spacing=7)
def box(draw,xy,title,body=None):
    draw.rounded_rectangle(xy,radius=15,fill='#f4f7f5',outline='#7e9990',width=2)
    x1,y1,x2,y2=xy
    center(draw,((x1+x2)/2,y1+33 if body else (y1+y2)/2),title,27,True)
    if body:center(draw,((x1+x2)/2,(y1+y2)/2+24),body,23)
def arrow(draw,a,b,label=None):
    draw.line([a,b],fill='#46675c',width=3)
    dx,dy=b[0]-a[0],b[1]-a[1]; ang=math.atan2(dy,dx)
    points=[b,(b[0]-14*math.cos(ang-.5),b[1]-14*math.sin(ang-.5)),(b[0]-14*math.cos(ang+.5),b[1]-14*math.sin(ang+.5))]
    draw.polygon(points,fill='#46675c')
    if label:center(draw,((a[0]+b[0])/2,(a[1]+b[1])/2-20),label,20)

# Gambar arsitektur berdasarkan lapisan PRD.
im=Image.new('RGB',(1500,330),'white');d=ImageDraw.Draw(im)
box(d,(10,70,330,230),'UI dan state','4 menu + form')
box(d,(410,70,750,230),'Aturan bisnis','Validasi dan perhitungan')
box(d,(830,70,1110,230),'Repository','Transaksi / klien API')
box(d,(1210,5,1490,145),'SQLite lokal','Sumber data utama')
box(d,(1210,180,1490,320),'Open-Meteo','Cuaca lewat HTTPS')
arrow(d,(330,150),(410,150));arrow(d,(750,150),(830,150));arrow(d,(1110,130),(1210,75));arrow(d,(1110,175),(1210,250))
im.save(TMP/'arsitektur.png')

# Diagram use case: asosiasi aktor, batas sistem, dan layanan eksternal.
im=Image.new('RGB',(1500,650),'white');d=ImageDraw.Draw(im)
d.rounded_rectangle((250,15,1220,635),radius=12,outline='#46675c',width=3)
center(d,(735,49),'FishCare Android',30,True)
def actor(x,y,label):
    d.ellipse((x-21,y-60,x+21,y-18),outline='#173c39',width=3)
    d.line([(x,y-18),(x,y+65)],fill='#173c39',width=3)
    d.line([(x-40,y+10),(x+40,y+10)],fill='#173c39',width=3)
    d.line([(x,y+65),(x-34,y+112)],fill='#173c39',width=3)
    d.line([(x,y+65),(x+34,y+112)],fill='#173c39',width=3)
    center(d,(x,y+150),label,23,True)
actor(105,260,'Pengelola')
uc=[(490,135,'Kelola kolam\ndan siklus'),(490,275,'Kelola master\ndan stok pakan'),(490,415,'Catat pemberian\ndan kegiatan ikan'),(490,555,'Lihat laporan\ndan riwayat'),(990,170,'Pilih lokasi usaha\ndan lihat cuaca'),(990,360,'Batalkan kegiatan\nyang memenuhi syarat'),(990,550,'Backup dan restore\n(rencana)')]
for x,y,t in uc:
    d.line([(150,285),(x-190,y)],fill='#9aaea5',width=2)
for x,y,t in uc:
    d.ellipse((x-195,y-48,x+195,y+48),fill='#f4f7f5',outline='#46675c',width=2);center(d,(x,y),t,25)
actor(1365,135,'Open-Meteo')
d.line([(1185,170),(1325,170)],fill='#46675c',width=2)
center(d,(1365,435),'API cuaca\nPihak ketiga',24)
im.save(TMP/'usecase.png')

# Diagram relasi inti, sengaja konseptual agar terbaca dalam proposal.
im=Image.new('RGB',(1500,710),'white');d=ImageDraw.Draw(im)
entities=[((25,30,410,155),'ponds','PK id | nama | arsip'),((550,30,950,155),'cycles','PK id | FK pond_id / feed_id'),((1100,30,1480,155),'feeds','PK id | nama | harga'),((550,280,950,405),'operations','PK seq | UNIQUE id | FK cycle_id'),((25,520,410,650),'cycle_slots','PK siklus / tanggal / jam'),((550,520,950,650),'feedings','PK seq | UNIQUE id'),((1100,520,1480,650),'stock_movements','PK seq | FK feed / feeding')]
for xy,t,b in entities:box(d,xy,t,b)
arrow(d,(410,90),(550,90),'1 : N');arrow(d,(1100,90),(950,90),'1 : N')
arrow(d,(750,155),(750,280),'1 : N')
d.line([(550,145),(220,145),(220,520)],fill='#46675c',width=3);center(d,(260,360),'siklus 1 : N slot',22)
arrow(d,(410,585),(550,585),'1 : N')
arrow(d,(950,585),(1100,585),'1 : N')
d.line([(1290,155),(1290,520)],fill='#46675c',width=3);center(d,(1370,330),'1 : N',23)
d.line([(750,405),(750,520)],fill='#46675c',width=2);center(d,(900,462),'ID tindakan bersama*',20)
im.save(TMP/'relasi.png')

doc=Document(SRC)
for child in list(doc._element.body):
    if child.tag!=qn('w:sectPr'):doc._element.body.remove(child)
# Pertahankan Normal dan docDefaults template. Title hanya untuk judul sampul.
title=doc.styles['Title'];title.font.name='Aptos';title.font.size=Pt(12);title.font.bold=True;title.font.color.rgb=RGBColor(0,0,0)
title.paragraph_format.space_after=Pt(8);title.paragraph_format.line_spacing=278/240
def p(text='',bold=False,size=None,after=None,align=None):
    q=doc.add_paragraph(style='Normal');r=q.add_run(text);r.bold=bold
    if size:r.font.size=Pt(size)
    if after is not None:q.paragraph_format.space_after=Pt(after)
    if align is not None:q.alignment=align
    return q
def head(text):
    q=p(text,True);q.paragraph_format.keep_with_next=True;q.paragraph_format.space_before=Pt(5);return q
def newpage(title,subtitle=None):
    q=head(title);q.paragraph_format.page_break_before=True
    if subtitle:head(subtitle)
def pic(file,width,caption=None):
    q=doc.add_paragraph();q.alignment=WD_ALIGN_PARAGRAPH.CENTER
    r=q.add_run();shape=r.add_picture(str(file),width=Inches(width))
    dp=shape._inline.docPr;dp.set('descr',caption or Path(file).stem)
    q.paragraph_format.space_after=Pt(3)
    if caption:p(caption,size=10,after=7,align=WD_ALIGN_PARAGRAPH.CENTER)
def table(headers,rows,widths):
    t=doc.add_table(rows=1,cols=len(headers));t.alignment=WD_TABLE_ALIGNMENT.CENTER;t.autofit=False
    for col,w in zip(t.columns,widths):col.width=Inches(w)
    for j,x in enumerate(headers):t.rows[0].cells[j].text=x
    for row in rows:
        for j,x in enumerate(row):t.add_row() if False else None
        cells=t.add_row().cells
        for j,x in enumerate(row):cells[j].text=x
    for i,row in enumerate(t.rows):
        for j,cell in enumerate(row.cells):
            cell.width=Inches(widths[j]);cell.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
            tcPr=cell._tc.get_or_add_tcPr();m=OxmlElement('w:tcMar')
            for side in ['top','left','bottom','right']:
                a=OxmlElement('w:'+side);a.set(qn('w:w'),'75');a.set(qn('w:type'),'dxa');m.append(a)
            tcPr.append(m)
            for q in cell.paragraphs:
                q.paragraph_format.space_after=Pt(0);q.paragraph_format.line_spacing=1.04
                for r in q.runs:r.font.size=Pt(10);r.bold=i==0
            if i==0:
                sh=OxmlElement('w:shd');sh.set(qn('w:fill'),'E9ECEF');tcPr.append(sh)
        cant=OxmlElement('w:cantSplit');row._tr.get_or_add_trPr().append(cant)
    tblpr=t._tbl.tblPr;border=OxmlElement('w:tblBorders')
    for tag in ['top','left','bottom','right','insideH','insideV']:
        a=OxmlElement('w:'+tag);a.set(qn('w:val'),'single');a.set(qn('w:sz'),'4');a.set(qn('w:color'),'D9D9D9');border.append(a)
    tblpr.append(border);repeat=OxmlElement('w:tblHeader');t.rows[0]._tr.get_or_add_trPr().append(repeat)
    p('',after=2,size=2)
    return t

# Halaman 1 mengikuti urutan label sampul template.
q=p('PROPOSAL PROJECT',True);q.style=doc.styles['Title']
head('PENGEMBANGAN APLIKASI BERGERAK')
p('',after=10)
head('Mata Kuliah');p('Pemrograman Perangkat Bergerak')
head('Judul Proyek');p('Pengembangan FishCare sebagai Aplikasi Android untuk Pencatatan Budidaya Ikan dan Informasi Cuaca')
head('Nama Aplikasi');p('FishCare')
head('Kelompok');p('Kelompok 7')
head('Anggota Kelompok')
for i in range(1,7):p(f'{i}. Nama: ....................................   NIM: ....................................',after=7)
head('Dosen Pengampu');p('................................................................................')
head('Program Studi dan Universitas');p('................................................................................')
p('Oktober 2026',after=0)

# Halaman 2.
newpage('BAB 1','PENDAHULUAN')
head('1.1 Latar Belakang')
p('Pengelolaan beberapa kolam membutuhkan catatan yang saling berkaitan, mulai dari jumlah ikan, pemberian pakan, stok, hingga panen. Jika catatan terpisah, pengelola harus menghitung ulang kebutuhan pakan dan menelusuri asal angka laporan. Perubahan bobot, populasi, atau harga juga perlu dicatat tanpa mengubah riwayat kegiatan sebelumnya.')
p('FishCare dirancang sebagai aplikasi Android untuk satu pengelola dengan beberapa kolam. Data kegiatan disimpan secara lokal agar pencatatan tetap dapat dilakukan tanpa internet. API cuaca memberikan informasi tambahan untuk satu lokasi usaha, sedangkan perhitungan pakan tetap memakai data ikan dan feeding rate manual dari pengguna. Proposal ini membahas rancangan aplikasi baru yang mengacu pada PRD FishCare [5].')
head('1.2 Rumusan Masalah')
for t in ['1. Bagaimana menghubungkan data kolam, siklus, populasi, dan kebutuhan pakan dalam satu aplikasi?', '2. Bagaimana menjaga pencatatan stok dan kegiatan tetap konsisten, termasuk saat koreksi, pembatalan, atau percobaan simpan ulang?', '3. Bagaimana menyajikan laporan periode yang dapat ditelusuri serta informasi cuaca yang jujur saat offline?']:p(t,after=5)
head('1.3 Tujuan Proyek')
p('Mengembangkan aplikasi Android yang mendukung pengelolaan kolam dan siklus, perhitungan serta pencatatan pakan, sampling, kematian, dan panen. Aplikasi ditujukan untuk menghasilkan laporan dari transaksi yang tersimpan, menjaga riwayat melalui snapshot, dan menyediakan cuaca dari layanan pihak ketiga tanpa menghambat kegiatan lokal.')
head('1.4 Manfaat Proyek')
p('Bagi pengelola, FishCare diharapkan memudahkan penelusuran stok, populasi, dan kegiatan setiap kolam. Bagi mahasiswa, proyek menjadi penerapan antarmuka mobile, SQLite, transaksi data, integrasi API, dan pengujian pada HP fisik. Manfaat tersebut merupakan sasaran proyek; peningkatan hasil budidaya belum diukur dan tidak dijanjikan.')

# Halaman 3.
newpage('BAB 2','TINJAUAN PUSTAKA')
head('2.1 Konsep Aplikasi Mobile')
p('Aplikasi mobile menyediakan interaksi melalui perangkat yang digunakan langsung oleh pengguna. Pada FishCare, penggunaan di area kolam menjadi dasar rancangan: langkah pencatatan dibuat singkat, angka memiliki satuan, dan penyimpanan lokal menjadi sumber utama. Ketersediaan internet hanya memengaruhi layanan cuaca dan pencarian lokasi, bukan pencatatan budidaya.')
head('2.2 Framework Flutter dan Android')
p('Flutter menyusun antarmuka melalui widget dan memperbarui tampilan mengikuti state aplikasi [1]. FishCare menggunakan Flutter dengan Dart dan menargetkan Android saja. Pemisahan tampilan dari aturan bisnis membantu memastikan rumus yang sama dipakai pada detail siklus, porsi harian, serta tampilan terkait. Akses perangkat, seperti lokasi, melalui layanan Android ketika pengguna menjalankan tindakan yang membutuhkannya.')
head('2.3 UI dan UX dalam Aplikasi Mobile')
p('Rancangan FishCare mengutamakan keterbacaan dan pencegahan kesalahan: empat menu utama, label tetap pada input, target sentuh utama minimal 48 dp, dan status yang tidak hanya mengandalkan warna. Form harus dapat digulir saat keyboard terbuka; penanganan area keyboard membantu menjaga input dan tombol tetap terjangkau [4]. Keadaan kosong, loading, gagal, dan berhasil dibedakan agar pengguna memahami hasil tindakannya.')
head('2.4 Teknologi Backend dan API')
p('FishCare tidak memakai backend sendiri, akun, atau sinkronisasi cloud. SQLite menyimpan data di HP; dukungan transaksi atomik memungkinkan satu rangkaian perubahan disimpan seluruhnya atau dibatalkan seluruhnya [2]. Pada pemberian pakan, prinsip ini diterapkan pada pencatatan aktual, stok keluar, snapshot, dan status slot.')
p('Open-Meteo menyediakan API prakiraan berbasis koordinat dengan parameter dan satuan yang terdokumentasi [3]. Aplikasi menampilkan suhu udara, kondisi, waktu data, dan prakiraan hujan bila tersedia. Data model cuaca tidak dianggap sebagai pengukuran suhu air kolam dan tidak digunakan untuk mengubah feeding rate secara otomatis.')

# Halaman 4.
newpage('BAB 3','PERANCANGAN SISTEM')
head('3.1 Gambaran Umum Sistem')
p('Satu pengelola membuat master pakan dan stok, menambah kolam, lalu memulai siklus. Siklus mengikat jenis ikan, pakan, populasi awal, bobot awal, rate manual, dan 1–6 jam unik. Kegiatan berikutnya memperbarui kondisi serta porsi menunggu; laporan membaca transaksi sah dengan periode yang konsisten (FR-01–08).',after=5)
head('3.2 Arsitektur Sistem')
pic(TMP/'arsitektur.png',6.3,'Gambar 1 Arsitektur FishCare dengan penyimpanan utama di HP')
p('UI/state menerima input, aturan bisnis memvalidasi dan menghitung, lalu repository mengakses SQLite atau API. Kegagalan cuaca tidak menahan navigasi maupun pencatatan lokal.',after=5)
head('3.3 Use Case Diagram')
pic(TMP/'usecase.png',6.3,'Gambar 2 Use case pengelola dan layanan cuaca eksternal')
p('Backup/restore pada diagram merupakan kebutuhan FR-09 yang masih direncanakan. Tidak ada aktor admin, login, atau server milik tim.',size=10,after=0)

# Halaman 5.
newpage('3.4 Desain Database')
p('Database produk dipisahkan dari percobaan M0. Skema sumber saat ini versi 5; migrasi harus menjaga data versi sebelumnya tanpa reset. Diagram berikut merangkum relasi inti, bukan seluruh kolom fisik [5].',after=5)
pic(TMP/'relasi.png',5.7,'Gambar 3 Relasi inti kolam, siklus, kegiatan, dan stok')
p('* operations dan feedings terhubung secara logis melalui ID tindakan yang sama; keduanya mengacu action_intents. Tidak menggambarkan foreign key langsung antar keduanya.',size=9,after=5)
table(['Entitas / kelompok','Kolom dan aturan penting'],[
 ('ponds; feeds','ID TEXT; nama unik; arsip 0/1. Harga pakan INTEGER rupiah/kg.'),
 ('cycles','FK kolam/pakan; jumlah INTEGER ekor; bobot INTEGER 0,01 g; satu siklus aktif per kolam.'),
 ('Rate dan jadwal','cycle_rates: 0,01%; cycle_schedules/times: tanggal efektif dan menit 0–1439; jam unik.'),
 ('cycle_slots; feedings','Slot unik siklus/tanggal/jam; aktual gram bulat; snapshot harga, rate, biomassa, biaya.'),
 ('operations','Jenis kegiatan, jumlah, kondisi sebelum/sesudah, snapshot panen; field panen NULL untuk nonpanen.'),
 ('Ledger dan koreksi','stock_movements mencatat ± gram; stock_corrections menyimpan asal, lama/baru, dan alasan.'),
 ('action_intents; cuaca','ID/payload/hasil untuk recovery; satu weather_location; cache berdasarkan koordinat.')
],[1.6,4.9])
p('Stok/populasi divalidasi dan ditulis atomik. ID tindakan disimpan sebelum transaksi dan diperiksa saat restart. Snapshot serta jejak batal tetap utuh. Bobot/rate maksimal dua desimal, pembulatan half-up nonnegatif. Satu slot dapat memiliki riwayat pemberian batal, tetapi hanya satu pemberian sah.',size=10,after=0)

# Halaman 6 dan 7: gambar dari desain yang telah ditinjau, bukan screenshot APK.
def ui_pair(a,b):
    t=doc.add_table(rows=1,cols=2);t.alignment=WD_TABLE_ALIGNMENT.CENTER;t.autofit=False
    for cell in t.rows[0].cells:cell.width=Inches(3.25)
    for cell,filename in zip(t.rows[0].cells,[a,b]):
        q=cell.paragraphs[0];q.alignment=WD_ALIGN_PARAGRAPH.CENTER
        q.paragraph_format.space_after=Pt(0)
        sh=q.add_run().add_picture(str(filename),width=Inches(2.65));sh._inline.docPr.set('descr',filename.stem)
    # Hanya wadah figur tanpa border; bukan tabel data atau callout.
    pr=t._tbl.tblPr;bs=OxmlElement('w:tblBorders')
    for tag in ['top','left','bottom','right','insideH','insideV']:
        x=OxmlElement('w:'+tag);x.set(qn('w:val'),'nil');bs.append(x)
    pr.append(bs)

newpage('3.5 Desain UI dan UX')
p('Empat menu utama adalah Beranda, Kolam, Pakan, dan Laporan. Desain baru menggunakan hijau tua, latar terang, label status, serta tombol utama yang konsisten. Gambar merupakan rancangan dengan data simulasi, bukan bukti pengujian aplikasi.',after=8)
ui_pair(ROOT/'docs/desain/home.png',ROOT/'tmp/proposal/ponds.png')
p('Gambar 4 Beranda dan daftar kolam',size=10,align=WD_ALIGN_PARAGRAPH.CENTER)
p('Beranda memprioritaskan pakan hari ini dan akses kolam; cuaca berada di bagian bawah yang dapat digulir. Daftar kolam membedakan siklus aktif, belum ada siklus, dan arsip. Detail mengarahkan ke kegiatan, sedangkan siklus aktif mencegah pengarsipan (FR-01–02; AT-01/19).',size=11,after=0)

newpage('3.5 Desain UI dan UX lanjutan')
p('Pakan membedakan rencana, aktual, dan sisa. Laporan mempertahankan filter periode/kolam serta memisahkan Transaksi periode, Kondisi saat ini, dan Seluruh siklus. Bagian di bawah layar dapat digulir.',after=8)
ui_pair(ROOT/'docs/desain/feed.png',ROOT/'docs/desain/report.png')
p('Gambar 5 Pakan harian dan laporan periode',size=10,align=WD_ALIGN_PARAGRAPH.CENTER)
p('Form lokal tetap tersedia offline. Rate berlaku sekarang pada porsi menunggu; perubahan jam berlaku besok. Lokasi HP hanya diambil melalui Ambil lokasi saat ini dan baru disimpan setelah konfirmasi. Loading, kosong, gagal, dan cache offline mendapat label tersendiri (FR-03–08; AT-10/20–22/37–45).',size=11,after=0)

# Halaman 8.
newpage('BAB 4','RENCANA IMPLEMENTASI')
head('4.1 Teknologi yang Digunakan')
table(['Teknologi','Peran dalam proyek'],[
 ('Flutter dan Dart','Antarmuka Android, state, parser, dan aturan bisnis bersama.'),
 ('SQLite melalui sqflite','Data lokal, transaksi, indeks unik, dan migrasi versi skema.'),
 ('Open-Meteo via HTTPS','Cuaca dan pencarian lokasi berdasarkan koordinat tersimpan.'),
 ('Android Studio dan HP fisik','Build APK, diagnosis lingkungan, instalasi, dan uji perangkat.')
],[1.7,4.8])
p('Sumber tercatat pada versi aplikasi 0.7.0+7 dengan skema 5. Nomor tersebut menunjukkan versi sumber, bukan bukti APK terbaru sudah dibangun. Versi toolchain dan kompatibilitas perangkat mengikuti catatan lingkungan proyek; tidak diasumsikan dari nomor sistem yang belum diverifikasi.',size=10)
head('4.2 Struktur Aplikasi')
p('Struktur dibagi menjadi UI/state, aturan bisnis, repository, dan akses SQLite/API. UI memuat ulang data setelah transaksi berhasil. Perhitungan memakai satu fungsi bersama agar kalkulator serta jadwal konsisten. Database percobaan M0 tetap terpisah dari data produk. Permintaan laporan/cuaca diberi identitas agar respons lama tidak menimpa filter atau lokasi baru.')
head('4.3 Fitur Utama Aplikasi')
p('FR-01–02 mencakup kolam dan siklus. FR-03–04 menangani stok bersama, koreksi, kebutuhan pakan, dan aktual per slot. FR-05–06 mencatat sampling, kematian, panen parsial, serta penutupan siklus. FR-07 menyediakan lima metrik periode beserta transaksi pendukung. FR-08 menyajikan cuaca; FR-09 merencanakan backup dan restore.')
p('Contoh hitung: 100 ikan × 100 g × 3% menghasilkan 300 g/hari, dibagi 150 + 150 g. Setelah aktual 150 g dan sampling menjadi 120 g, kebutuhan menjadi 360 g dan sisa 210 g. Panen 20 ikan × 200 g × Rp25.000/kg bernilai Rp100.000. Angka ini skenario penerimaan, bukan acuan budidaya.')
p('Lingkup tidak mencakup login, cloud, rekomendasi pakan otomatis, FCR, keuntungan bersih, atau notifikasi background. Nilai panen dan biaya pakan disajikan terpisah.',size=10,after=0)

# Halaman 9.
newpage('4.4 Timeline Pengembangan')
p('Target akhir proyek adalah akhir Oktober 2026. Jadwal berikut merupakan rencana pada PRD, bukan pernyataan seluruh tahap telah lolos pengujian. Pekerjaan berikutnya mengikuti hasil verifikasi, bukan hanya tanggal.',after=6)
table(['Waktu Oktober 2026','Pekerjaan','Keluaran'],[
 ('13–15','Kebutuhan, rancangan, pembuktian dasar','PRD, alur, database, UI, bukti M0.'),
 ('16–20','Kolam, siklus, stok, dan pemberian','Alur pencatatan serta pengujian transaksi.'),
 ('21–23','Sampling, kematian, panen, laporan','Snapshot, filter, dan pembatalan konsisten.'),
 ('24–26','Cuaca, backup/restore, konsistensi UI','Kegagalan jaringan dan pemulihan teruji.'),
 ('27–29','Regresi, dokumentasi, latihan','APK kandidat dan daftar uji demonstrasi.'),
 ('30–31','Buffer perbaikan dan presentasi','Artifact final dan cadangan data demo.')
],[1.15,2.55,2.8])
head('Rencana Pengujian')
table(['Area','Pemeriksaan penerimaan'],[
 ('Rumus / jadwal','Half-up, pembagian 301→151+150, rate tidak valid, jam besok (AT-02/03/10/27).'),
 ('Transaksi / recovery','Stok kurang/bersama, snapshot, ketuk ganda, rollback, ID sama setelah restart (AT-04–07/15/25/29–31).'),
 ('Populasi / laporan','Sampling, panen, pembatalan lintas kegiatan, tanggal inklusif, arsip, snapshot dan refresh (AT-11–19/32–40).'),
 ('Perangkat / API','Keyboard, persistensi, offline, izin/lokasi sekali, cache dan respons lama (AT-20–22/41–45).'),
 ('Backup / restore','Validasi berkas, batal pemilih, data lama utuh saat gagal (AT-23–24).')
],[1.25,5.25])
head('Status Verifikasi Saat Penyusunan')
p('Pengguna melaporkan uji manual M1 serta seluruh percobaan gabungan M2+M3 yang diberikan berhasil. M0 juga dilaporkan berjalan, marker dapat disimpan/dibaca, dan cuaca Jakarta serta error offline tampil. Persistensi marker setelah ditutup paksa belum dikonfirmasi secara khusus.',size=10)
p('Sumber M4/M5 dan lokasi cuaca telah dikerjakan, tetapi uji HP M4/M5 belum dikonfirmasi. Analisis Flutter, seluruh tes standar, dan build terbaru masih tercatat terhalang akses tulis SDK/cache. Pemeriksaan tambahan tidak menggantikan bukti tersebut. Desain baru sudah diperiksa di browser; penerapannya ke Flutter belum dilakukan.',size=10,after=0)

# Halaman 10.
newpage('BAB 5','PENUTUP')
head('5.1 Kesimpulan')
p('FishCare dirancang untuk menyatukan pencatatan beberapa kolam dalam aplikasi Android dengan database lokal. Hubungan kolam, siklus, pakan, kegiatan, dan laporan menjaga asal angka tetap dapat ditelusuri. Transaksi atomik, snapshot historis, dan ID tindakan menjadi dasar untuk mencegah perubahan sebagian maupun pencatatan ganda. Desain baru menyediakan empat menu utama serta keadaan gagal/offline yang jelas.')
head('5.2 Rencana Pengembangan Lanjutan')
p('Prioritas berikutnya adalah menyelesaikan verifikasi standar dan uji gabungan M4/M5 pada HP, menerapkan desain yang telah ditinjau, serta memverifikasi cuaca dan izin lokasi melalui perangkat. Backup/restore dibangun pada tahap yang diizinkan berikutnya dengan perlindungan data lama. Kandidat presentasi diserahkan setelah build, instalasi, regresi, dan demonstrasi utama memiliki bukti. Pengembangan tetap dibatasi pada PRD, tanpa penambahan FCR atau keuntungan bersih.')
head('REFERENSI')
refs=[
 '[1] Flutter. Flutter architectural overview. https://docs.flutter.dev/resources/architectural-overview',
 '[2] SQLite. SQLite Is Transactional. https://www.sqlite.org/transactional.html',
 '[3] Open-Meteo. Weather Forecast API Documentation. https://open-meteo.com/en/docs',
 '[4] Android Developers. Handle input method visibility. https://developer.android.com/develop/ui/views/touch-and-input/keyboard-input/visibility',
 '[5] Tim FishCare. PRD FishCare Rancangan Baru v0.1; Alur Sistem; Rancangan Database; Wireframe; dan catatan tahap pengembangan. Dokumen proyek, pembaruan 13–15 Oktober 2026.',
 '[6] Kelompok 7. Rancangan UI FishCare baru. Prototipe dan ekspor PNG/PDF, 15 Oktober 2026.'
]
for ref in refs:p(ref,size=10,after=6)
p('Sumber daring diakses pada 15 Oktober 2026.',size=10,after=0)

# Footer hanya nomor halaman; satu section dan geometri template tidak diubah.
f=doc.sections[0].footer.paragraphs[0];f.alignment=WD_ALIGN_PARAGRAPH.RIGHT
r=f.add_run();r.font.size=Pt(10)
field=OxmlElement('w:fldSimple');field.set(qn('w:instr'),'PAGE');rr=OxmlElement('w:r');tt=OxmlElement('w:t');tt.text='1';rr.append(tt);field.append(rr);f._p.append(field)
settings=doc.settings._element
update=OxmlElement('w:updateFields');update.set(qn('w:val'),'true');settings.append(update)
doc.core_properties.title='Proposal Pengembangan Aplikasi FishCare';doc.core_properties.author='Kelompok 7';doc.core_properties.subject='Pemrograman Perangkat Bergerak'
work=TMP/'working.docx';doc.save(work)
# Pertahankan byte seluruh bagian template yang tidak diedit.
allowed={'word/document.xml','word/_rels/document.xml.rels','word/styles.xml','word/settings.xml','[Content_Types].xml'}
final=OUT/'Proposal-FishCare-Kelompok-7.docx'
with ZipFile(SRC) as src,ZipFile(work) as new,ZipFile(final,'w',ZIP_DEFLATED) as dest:
    for name in src.namelist():dest.writestr(name,new.read(name) if name in allowed and name in new.namelist() else src.read(name))
    for name in new.namelist():
        if name not in src.namelist() and name!='docProps/core.xml' and name!='docProps/app.xml':dest.writestr(name,new.read(name))
with ZipFile(SRC) as src,ZipFile(final) as dst:
    unchanged=[n for n in src.namelist() if n not in allowed and src.read(n)==dst.read(n)]
    assert len(unchanged)==len(set(src.namelist())-allowed)
assert sha256(SRC.read_bytes()).hexdigest()=='063cb665e8e1a30c5f433157b79a740a3d3d3df89cfb317f1b60abd4a320e7f5'
(TMP/'fidelity.json').write_text(json.dumps({'sourceHashUnchanged':True,'preservedParts':unchanged,'explicitPageBreaks':9,'sections':len(doc.sections),'members':6},indent=2))
print(final)
