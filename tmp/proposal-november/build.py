from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import math, json, hashlib
from PIL import Image, ImageDraw, ImageFont
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

ROOT=Path(__file__).resolve().parents[2]; TMP=Path(__file__).parent
OUT=ROOT/'output/laporan'; OUT.mkdir(exist_ok=True)
SRC=TMP/'reference.docx'; doc=Document(SRC)
for el in list(doc._element.body):
    if el.tag!=qn('w:sectPr'): doc._element.body.remove(el)
title=doc.styles['Title']; title.font.name='Aptos'; title.font.size=Pt(12); title.font.bold=True; title.font.color.rgb=RGBColor(0,0,0)
title.paragraph_format.space_after=Pt(8); title.paragraph_format.line_spacing=278/240
def p(t='',bold=False,size=12):
    x=doc.add_paragraph(); r=x.add_run(t); r.bold=bold; r.font.size=Pt(size); return x
def h(t,new=False):
    x=p(t,True); x.paragraph_format.keep_with_next=True; x.paragraph_format.space_before=Pt(6)
    if new:x.paragraph_format.page_break_before=True
    return x
def chapter(n,t): h('BAB '+str(n),True);h(t)
def prose(*texts):
    for t in texts:p(t)
def table(headers,rows,widths):
    t=doc.add_table(rows=1,cols=len(headers));t.alignment=WD_TABLE_ALIGNMENT.CENTER;t.autofit=False
    for c,w in zip(t.columns,widths):c.width=Inches(w)
    for c,s in zip(t.rows[0].cells,headers):c.text=s
    for row in rows:
        for c,s in zip(t.add_row().cells,row):c.text=str(s)
    for i,row in enumerate(t.rows):
        for j,c in enumerate(row.cells):
            c.width=Inches(widths[j]);c.vertical_alignment=WD_CELL_VERTICAL_ALIGNMENT.CENTER
            pr=c._tc.get_or_add_tcPr();mar=OxmlElement('w:tcMar')
            for side in ['top','left','bottom','right']:
                el=OxmlElement('w:'+side);el.set(qn('w:w'),'65');el.set(qn('w:type'),'dxa');mar.append(el)
            pr.append(mar)
            if i==0:
                sh=OxmlElement('w:shd');sh.set(qn('w:fill'),'E9ECEF');pr.append(sh)
            for q in c.paragraphs:
                q.paragraph_format.space_after=Pt(1);q.paragraph_format.line_spacing=1.04
                for r in q.runs:r.font.size=Pt(10);r.bold=(i==0)
        keep=OxmlElement('w:cantSplit');row._tr.get_or_add_trPr().append(keep)
    repeat=OxmlElement('w:tblHeader');t.rows[0]._tr.get_or_add_trPr().append(repeat)
    borders=OxmlElement('w:tblBorders')
    for side in ['top','left','bottom','right','insideH','insideV']:
        el=OxmlElement('w:'+side);el.set(qn('w:val'),'single');el.set(qn('w:sz'),'4');el.set(qn('w:color'),'D9D9D9');borders.append(el)
    t._tbl.tblPr.append(borders)
    for q in t.rows[-1].cells:
        for para in q.paragraphs:para.paragraph_format.keep_with_next=True
    if headers==['Tabel pendukung','Fungsi']:
        for row in t.rows:
            for c in row.cells:
                for para in c.paragraphs:para.paragraph_format.keep_with_next=True
    gap=p('',size=3);gap.paragraph_format.space_after=Pt(3);gap.paragraph_format.keep_with_next=True
def pic(file,caption,width=6.5):
    x=p('');x.alignment=WD_ALIGN_PARAGRAPH.CENTER;x.paragraph_format.keep_with_next=True
    s=x.add_run().add_picture(str(file),width=Inches(width));s._inline.docPr.set('descr',caption)
    q=p(caption,size=10);q.alignment=WD_ALIGN_PARAGRAPH.CENTER

# Diagram lokal: UML use case dengan asosiasi aktor, bukan diagram alur.
def font(n=28,b=False):return ImageFont.truetype('C:/Windows/Fonts/'+('arialbd.ttf' if b else 'arial.ttf'),n)
def txt(d,xy,t,n=28,b=False):d.multiline_text(xy,t,font=font(n,b),fill='#183c36',anchor='mm',align='center',spacing=8)
def actor(d,x,y,t):
    d.ellipse((x-24,y-70,x+24,y-22),outline='#183c36',width=4)
    d.line([(x,y-22),(x,y+65)],fill='#183c36',width=4);d.line([(x-45,y+8),(x+45,y+8)],fill='#183c36',width=4)
    d.line([(x-35,y+115),(x,y+65),(x+35,y+115)],fill='#183c36',width=4);txt(d,(x,y+150),t,25,True)
im=Image.new('RGB',(1600,1440),'white');d=ImageDraw.Draw(im)
d.rectangle((310,35,1230,1390),outline='#183c36',width=3);txt(d,(770,75),'Sistem FishCare Android',34,True)
actor(d,140,650,'Pengelola\nbudidaya');actor(d,1415,1190,'Open-Meteo')
ucs=['Kelola kolam dan siklus','Kelola pakan, harga dan stok','Lihat jadwal pemberian pakan','Catat suhu air dan pH\nserta tinjau rekomendasi','Catat pemberian aktual','Catat grading dan rencana','Catat kematian dan panen','Batalkan kegiatan yang sah','Lihat laporan dan hasil siklus','Ekspor laporan Excel','Atur lokasi dan lihat cuaca']
for i,t in enumerate(ucs):
    y=160+i*111;d.line([(185,658),(390,y)],fill='#9aaca6',width=2)
for i,t in enumerate(ucs):
    y=160+i*111;d.ellipse((390,y-44,1150,y+44),fill='#f4f7f5',outline='#355d51',width=3);txt(d,(770,y),t,29)
d.line([(1150,1270),(1370,1200)],fill='#355d51',width=3)
im.save(TMP/'usecase.png')

def box(d,xy,t,sub=''):
    d.rounded_rectangle(xy,radius=12,fill='#f4f7f5',outline='#355d51',width=3)
    x,y,x2,y2=xy;txt(d,((x+x2)/2,(y+y2)/2-18 if sub else (y+y2)/2),t,30,True)
    if sub:txt(d,((x+x2)/2,(y+y2)/2+30),sub,24)
def line(d,a,b,label=None):
    d.line([a,b],fill='#355d51',width=3)
    if label:txt(d,((a[0]+b[0])/2,(a[1]+b[1])/2-20),label,23)
im=Image.new('RGB',(1500,590),'white');d=ImageDraw.Draw(im)
for xy,t,s in [((30,30,1470,130),'UI dan state','Beranda, Kolam, Pakan, Laporan, form dan konfirmasi'),((30,200,1470,300),'Aturan bisnis bersama','Rate lele, porsi, validasi, biaya dan nilai panen'),((30,370,700,470),'Repository SQLite','Data lokal dan transaksi'),((800,370,1470,470),'Klien cuaca dan lokasi','API dan layanan perangkat')]:box(d,xy,t,s)
line(d,(750,130),(750,200));line(d,(365,300),(365,370));line(d,(1135,300),(1135,370));txt(d,(365,540),'SQLite pada HP',29,True);txt(d,(1135,540),'Open-Meteo melalui internet',29,True);line(d,(365,470),(365,510));line(d,(1135,470),(1135,510));im.save(TMP/'architecture.png')
im=Image.new('RGB',(1500,1030),'white');d=ImageDraw.Draw(im)
nodes=[((20,30,430,150),'ponds','PK id'),((550,30,960,150),'cycles','PK id · FK pond_id, feed_id'),((1080,30,1490,150),'feeds','PK id'),((20,420,430,540),'grading_plans','PK dan FK cycle_id'),((550,420,960,540),'cycle_slots','PK cycle_id, tanggal, menit'),((1080,420,1490,540),'operations','UNIQUE id · FK cycle_id'),((20,850,430,970),'stock_movements','FK feed_id, feeding_id'),((550,850,960,970),'feedings','UNIQUE id · FK slot, feed_id'),((1080,850,1490,970),'grading_records','PK operation_id · FK cycle_id')]
for xy,t,s in nodes:box(d,xy,t,s)
for a,b in [((430,90),(550,90)),((960,90),(1080,90)),((755,150),(755,420)),((600,150),(225,420)),((900,150),(1285,420)),((755,540),(755,850)),((1285,540),(1285,850)),((430,910),(550,910))]:line(d,a,b)
for xy,s in [((450,65),'1'),((525,65),'N'),((985,65),'N'),((1055,65),'1'),((790,180),'1'),((790,390),'N'),((560,185),'1'),((230,385),'0..1'),((940,185),'1'),((1280,385),'N'),((790,575),'1'),((790,815),'N'),((1330,575),'1'),((1335,815),'0..1'),((450,880),'N'),((525,880),'0..1')]:txt(d,xy,s,24)
im.save(TMP/'database.png')

p('PROPOSAL PROJECT',True).style=doc.styles['Title']
h('PENGEMBANGAN APLIKASI BERGERAK')
h('Judul Proyek')
p('FishCare Aplikasi Android Manajemen Pakan dan Hasil Panen Budidaya Lele Berbasis pH dan Suhu Air Kolam',True)
h('Mata Kuliah');p('Pemrograman Perangkat Bergerak')
h('Dosen Pengampu');p('Marisha Pertiwi, S.Tr.Kom., M.Kom.')
h('Disusun Oleh');p('Kelompok 7')
for name,nim in [('Gelia Rahma Nur Minda','2401020092'),('Salma Nusafira','2401020094'),('M. Dodi Bastian','2401020095'),('Monalisa Dwi Cantika','2401020100'),('Mikael Rejeki Situmorang','2401020105'),('Sarah Fauziyyah','2401020109')]:p(name+'  —  '+nim)
p('TEKNIK INFORMATIKA',True);p('FAKULTAS TEKNIK DAN TEKNOLOGI KEMARITIMAN',True);p('UNIVERSITAS MARITIM RAJA ALI HAJI',True);p('2026')

chapter(1,'PENDAHULUAN')
h('1.1 Latar Belakang')
prose('Pengelolaan pakan merupakan salah satu kegiatan rutin dalam budidaya ikan lele. Pengelola perlu mengetahui waktu pemberian, jumlah pakan yang direncanakan, jumlah yang benar-benar diberikan, ketersediaan stok, dan biaya yang timbul dari setiap kegiatan. Dasar perhitungan tersebut berubah ketika bobot rata-rata ikan bertambah atau populasi berkurang karena kematian dan panen. Karena itu, pencatatan pakan perlu dihubungkan dengan keadaan ikan pada masing-masing kolam.',
'Pencatatan yang terpisah dapat menyulitkan penelusuran hubungan antara kegiatan harian, persediaan pakan, dan hasil panen. Harga pakan yang berubah juga dapat membuat biaya kegiatan lama tidak konsisten apabila dihitung kembali menggunakan harga terbaru. FishCare dirancang untuk menghubungkan data tersebut melalui catatan transaksi yang menyimpan nilai pada saat kegiatan berlangsung. Dasar masalah ini berasal dari analisis kebutuhan proyek, bukan klaim hasil survei atau pengukuran kerugian pembudidaya [5].',
'Pengembangan FishCare berfokus pada aplikasi Android untuk satu pengguna yang dapat mengelola beberapa kolam. Data utama disimpan secara lokal sehingga kegiatan inti dapat dirancang tetap berjalan tanpa internet. Pengguna dapat mengelola kolam dan siklus, menentukan jadwal pemberian, mencatat grading, mengisi pengukuran suhu air serta pH, meninjau rekomendasi pakan, dan menyimpan jumlah aktual beserta biayanya. Rekomendasi merupakan bantuan pencatatan dan pengambilan keputusan, bukan pengganti pengamatan pengelola terhadap kondisi ikan.',
'Informasi cuaca melengkapi aplikasi melalui layanan Open-Meteo berdasarkan lokasi usaha yang dipilih. Informasi ini menggambarkan cuaca di sekitar area kolam, sedangkan suhu air dan pH berasal dari pengukuran yang dimasukkan pengguna. Pemisahan kedua sumber data diperlukan agar suhu udara tidak dianggap sebagai suhu air kolam. Hasil kegiatan kemudian dapat ditinjau melalui laporan dan diekspor sebagai berkas Excel untuk kebutuhan dokumentasi.',
'Proposal ini menjabarkan kebutuhan dan rancangan FishCare dengan memperhatikan perkembangan proyek yang tercatat pada Oktober 2026. Fokus pakan lele, revisi grading, pengukuran air, ekspor Excel, dan ringkasan hasil panen mengikuti keputusan terbaru dalam PRD serta catatan implementasi. Kesesuaian aturan pakan dengan konteks kolam biasa tetap perlu ditinjau bersama dosen bidang perikanan [5][6].')
h('1.2 Rumusan Masalah')
for s in ['Bagaimana merancang aplikasi Android yang menghubungkan kolam, siklus budidaya, populasi, bobot ikan, jadwal, dan persediaan pakan?', 'Bagaimana menyajikan rekomendasi pakan lele berdasarkan bobot dan pengukuran suhu air serta pH pada setiap pemberian?', 'Bagaimana mencatat harga pakan, biaya pemberian, harga panen, dan nilai panen tanpa mengubah transaksi terdahulu?', 'Bagaimana menyediakan laporan per periode dan kolam, ekspor Excel, serta informasi cuaca lokasi usaha dengan tetap menjaga fungsi pencatatan lokal?']:p(s)
h('1.3 Tujuan Proyek')
prose('Tujuan umum proyek adalah mengembangkan FishCare sebagai aplikasi Android untuk membantu pengelola budidaya lele mencatat pemberian pakan, memantau kondisi dasar budidaya, dan menelusuri hasil panen. Aplikasi menyatukan kegiatan yang berkaitan dalam satu database lokal agar data dapat digunakan kembali secara konsisten.',
'Secara khusus, proyek bertujuan menyediakan jadwal dan status pemberian; menghitung kebutuhan normal berdasarkan populasi serta bobot; menampilkan rekomendasi per jadwal berdasarkan pengukuran air; mencatat aktual, stok, dan biaya; mengelola grading, kematian, serta panen; dan menyajikan laporan beserta ekspor Excel. Integrasi cuaca ditujukan untuk menambah informasi lingkungan sekitar lokasi usaha tanpa menjadi syarat pencatatan.',
'Keandalan ditargetkan melalui validasi input, transaksi database, perlindungan terhadap penyimpanan berulang, serta pengujian pada perangkat Android. Penilaian keberhasilan memperhatikan ketepatan perhitungan dan keterlacakan data, bukan hanya banyaknya halaman atau fitur.')
h('1.4 Manfaat Proyek')
prose('Bagi pengelola budidaya, aplikasi diharapkan memudahkan pemeriksaan jadwal, jumlah aktual pakan, sisa stok, perkembangan bobot, dan riwayat panen. Biaya pakan serta pendapatan panen dapat dilihat berdasarkan periode atau seluruh siklus dengan cakupan yang jelas. Manfaat ini berupa dukungan pencatatan; peningkatan produksi atau penghematan usaha belum diukur.',
'Bagi mahasiswa, proyek menjadi sarana penerapan perancangan antarmuka, pemodelan data, perhitungan bisnis, integrasi API, dan pengujian aplikasi Android. Bagi kegiatan pembelajaran, FishCare menyediakan contoh bagaimana kebutuhan pengguna dan masukan dosen diterjemahkan menjadi aturan yang dapat diuji serta direvisi secara bertahap.')

chapter(2,'TINJAUAN PUSTAKA')
h('2.1 Konsep Aplikasi Mobile')
prose('Aplikasi mobile digunakan melalui perangkat bergerak dengan interaksi sentuh, ruang tampilan terbatas, dan kondisi koneksi yang dapat berubah. Dalam FishCare, karakteristik tersebut diterjemahkan menjadi form satu kolom, navigasi yang konsisten, satuan angka yang jelas, serta konfirmasi sebelum tindakan yang memengaruhi stok atau populasi.',
'Penyimpanan lokal menempatkan data kegiatan pada perangkat pengguna. Android membahas pendekatan offline-first sebagai rancangan yang tetap menyediakan fungsi penting ketika jaringan tidak tersedia [1]. Pada FishCare, pencatatan kolam, stok, pemberian, grading, kematian, panen, dan laporan memakai database lokal. Pencarian lokasi serta pembaruan cuaca merupakan fungsi yang membutuhkan jaringan. Pemisahan ini menjadi pilihan arsitektur proyek, bukan klaim bahwa semua layanan eksternal dapat bekerja offline.',
'Lingkup satu pengguna berarti aplikasi tidak memerlukan login, pembagian hak akses, atau sinkronisasi cloud. Pengelolaan beberapa kolam tetap didukung dalam satu perangkat. Keamanan dan keutuhan data diarahkan pada validasi, penyimpanan transaksi, dan pemeliharaan riwayat. Backup dan restore tercantum dalam kebutuhan awal, tetapi belum tersedia pada implementasi yang menjadi acuan proposal [5][6].')
h('2.2 Framework Flutter / Android')
prose('Flutter merupakan perangkat pengembangan antarmuka yang menyusun tampilan melalui widget dan state. Dokumentasi arsitekturnya menjelaskan pemisahan antara framework, mesin perender, dan integrasi platform [2]. FishCare menggunakan Flutter dan bahasa Dart dengan sasaran Android. Widget digunakan untuk menyajikan halaman, sedangkan aturan pakan dan transaksi dipisahkan dari kode tampilan.',
'Pemisahan tersebut memungkinkan perhitungan yang sama digunakan pada detail kolam, jadwal, form pemberian, dan laporan. Ketika bobot atau populasi berubah, halaman membaca keadaan terbaru tanpa menulis ulang transaksi lama. Integrasi dengan Android digunakan untuk lokasi atas tindakan pengguna dan pemilih dokumen ketika menyimpan berkas Excel.',
'Pemilihan versi mengikuti lingkungan yang telah dicatat dalam proyek. Analisis kode dan tes otomatis merupakan bagian pemeriksaan, tetapi keduanya tidak menggantikan build APK atau pengujian pada HP. Kompatibilitas dibatasi pada konfigurasi dan perangkat yang telah mempunyai bukti, sehingga tidak disimpulkan berlaku untuk seluruh perangkat Android [6].')
h('2.3 UI/UX dalam Aplikasi Mobile')
prose('User interface mengatur bentuk tampilan dan komponen interaksi, sedangkan user experience berkaitan dengan kemudahan pengguna memahami serta menyelesaikan kegiatan. FishCare mengutamakan keterbacaan angka, satuan, status, dan dampak tindakan. Menu utama terdiri atas Beranda, Kolam, Pakan, dan Laporan. Form menampilkan label input yang tetap terlihat dan pesan kesalahan dekat isian terkait.',
'Pedoman Android menekankan keterbacaan, kontras, serta ukuran target sentuh yang memadai [3]. Rancangan FishCare menggunakan label teks bersama warna status dan mengarahkan pengujian pada layar sempit serta pembesaran teks. Pengguna perlu dapat membedakan porsi normal, rekomendasi, jumlah aktual, harga per kilogram, dan total biaya sebelum menyimpan.',
'Status memuat data, kosong, gagal, offline, dan berhasil perlu dibedakan. Data yang belum tersedia tidak ditampilkan sebagai angka nol. Saat ekspor dibatalkan, aplikasi menyampaikan bahwa berkas belum tersimpan. Ketika pengukuran air belum lengkap, rekomendasi belum ditampilkan. Prinsip tersebut membantu mencegah pengguna menafsirkan ketiadaan data sebagai kondisi normal.')
h('2.4 Teknologi Backend / API')
prose('FishCare tidak menggunakan backend buatan sendiri. SQLite menjadi penyimpanan data lokal, sedangkan Open-Meteo menyediakan informasi cuaca melalui API. SQLite mendukung transaksi yang menerapkan perubahan sebagai satu kesatuan [4]. Dalam rancangan FishCare, penyimpanan pemberian, pengurangan stok, perubahan status jadwal, dan hasil tindakan ditempatkan dalam transaksi agar kegagalan tidak meninggalkan data sebagian.',
'API cuaca menerima lokasi berbasis koordinat dan menyediakan variabel cuaca dengan waktu serta satuannya [7]. FishCare memakai satu lokasi usaha untuk seluruh kolam dalam area yang sama. Lokasi dapat diambil sekali dari HP atas tindakan pengguna atau dicari secara manual. Hasil calon lokasi baru baru menggantikan lokasi lama setelah disimpan. Cache dipisahkan berdasarkan lokasi dan ditampilkan dengan waktu yang sesuai.',
'Pada pengolahan data budidaya, snapshot menyimpan nilai penting saat transaksi, seperti harga pakan, biaya, bobot, populasi, suhu air, pH, dan harga panen. Konsep ini menjaga riwayat tetap konsisten walaupun data master berubah. Ekspor Excel membaca ringkasan dan rincian dari filter yang sama. Format .xlsx digunakan untuk menyimpan lembar Ringkasan dan Transaksi, bukan untuk menggantikan backup database [6].',
'Acuan aturan pakan merupakan kebijakan proyek yang tercatat dalam PRD. Tabel rate berasal dari pilihan sumber rancangan RSNI pembesaran lele bioflok yang dibahas dalam proyek, sedangkan penerapannya difokuskan pada kolam biasa. Batas kontinu bobot dan penyesuaian suhu merupakan keputusan yang dicatat pada revisi kebutuhan. Oleh sebab itu, proposal tidak menyebut penerapan tersebut sebagai sertifikasi standar atau validasi ilmiah untuk seluruh kondisi budidaya [5].')

chapter(3,'PERANCANGAN SISTEM')
h('3.1 Gambaran Umum Sistem')
prose('FishCare dirancang untuk satu pengelola budidaya lele dengan beberapa kolam. Pengelola terlebih dahulu membuat data pakan dan stok, membuat kolam, lalu memulai siklus budidaya. Satu kolam hanya memiliki satu siklus aktif, sedangkan riwayat siklus yang telah selesai tetap dapat ditinjau. Siklus mengikat jenis ikan, populasi awal, bobot awal, pakan, dan jam pemberian.',
'Pada kegiatan harian, pengguna melihat jadwal dan memilih slot pemberian yang belum selesai. Pengguna memasukkan suhu air serta pH hasil pengukuran saat itu, meninjau rekomendasi, kemudian mengisi jumlah aktual. Harga per kilogram dan total biaya terlihat sebelum konfirmasi. Setelah penyimpanan berhasil, stok berkurang sesuai jumlah aktual, slot berubah status, dan catatan tersimpan bersama nilai historisnya.',
'Grading digunakan untuk mencatat bobot rata-rata, bukan menyortir atau memindahkan ikan. Kematian dan panen mengurangi populasi, sedangkan grading tidak. Panen sebagian menyisakan ikan dalam siklus; panen akhir memakai seluruh populasi tersisa dan menutup siklus. Laporan memisahkan total transaksi periode, kondisi terkini, dan ringkasan seluruh siklus [5].')
h('Dasar perhitungan pakan')
prose('Biomassa dihitung dari populasi dikalikan bobot rata-rata per ekor. Kebutuhan normal harian dalam gram dihitung sebagai populasi × bobot rata-rata dalam gram × rate / 100, kemudian dibulatkan half-up. Rate diambil dari kelompok bobot terbaru; bobot awal digunakan sebelum grading pertama. Hasil kebutuhan normal dibagi ke seluruh jadwal pada hari yang sama, dengan sisa gram pembulatan diberikan menurut urutan jam paling awal.')
table(['Bobot rata-rata per ekor','Rate normal per hari'],[('2–5 g','5%'),('>5–10 g','4%'),('>10–35 g','3%'),('>35–50 g','2,5%'),('>50–70 g','2,2%'),('>70 g','2%')],[3.9,2.6])
p('Tabel 3.1 Kebijakan rate lele dalam PRD bagian 15.8. Interval ini merupakan keputusan proyek; bobot di bawah 2 g belum memiliki acuan rate yang disepakati.',size=10)
table(['Kondisi pengukuran baru','Rekomendasi slot'],[('Suhu 25–30 °C dan pH 6,5–8','100% porsi normal slot.'),('Suhu <24 °C dan pH 6,5–8','80% porsi normal, dibulatkan half-up.'),('Suhu 24–<25 °C, suhu >30 °C, atau pH di luar 6,5–8','Peringatan; angka rekomendasi tidak tersedia.'),('Suhu atau pH belum lengkap/valid','Perbaiki pengukuran sebelum meninjau pemberian.')],[3.7,2.8])
p('Tabel 3.2 Perilaku rekomendasi berdasarkan PRD bagian 15.8–15.11.',size=10)
prose('Sebagai ilustrasi, 1.000 ekor dengan bobot 50 g dan rate 2,5% menghasilkan kebutuhan normal 1.250 g per hari. Dua jadwal memperoleh porsi normal masing-masing 625 g. Pada suhu 23 °C dan pH 7, rekomendasi untuk satu slot menjadi 500 g. Apabila suhu pada slot berikutnya kembali normal, rekomendasinya kembali 625 g; pengurangan atau selisih aktual sebelumnya tidak dipindahkan ke slot berikutnya.',
'Saat kondisi air berada di luar acuan, pengguna tetap dapat meninjau jumlah aktual jika data dasar dan pengukuran valid. Sistem tidak membuat rekomendasi rekaan. Grading atau perubahan populasi menghitung ulang porsi normal slot yang masih menunggu berdasarkan kondisi terbaru; catatan yang sudah diberikan tetap utuh. Cuaca tidak menjadi pengali perhitungan ini.')
h('3.2 Arsitektur Sistem',True)
pic(TMP/'architecture.png','Gambar 3.1 Arsitektur FishCare dan pemisahan layanan eksternal')
prose('Lapisan UI dan state mengelola navigasi, isian, proses memuat, serta penyajian hasil. Lapisan aturan bisnis menampung parser angka, pemilihan rate, pembagian porsi, perhitungan biaya, nilai panen, dan kelayakan tindakan. Repository menjalankan akses data dan transaksi. SQLite menyimpan catatan utama, sedangkan klien API membaca cuaca secara terpisah.',
'Data yang disimpan menjadi sumber untuk memperbarui halaman setelah kegiatan berhasil. Validasi penting diulang di dalam transaksi, termasuk stok mencukupi, populasi sah, siklus aktif, dan status jadwal. Setiap tindakan simpan memakai identitas stabil agar pengulangan permintaan tidak membuat transaksi ganda. Apabila harga atau kondisi ikan berubah setelah pratinjau, pengguna perlu meninjau ulang sebelum penyimpanan.',
'Kegagalan cuaca tidak menghambat navigasi maupun penulisan data lokal. Hasil API yang terlambat setelah perubahan lokasi tidak boleh menggantikan data lokasi yang sedang dipakai. Pengguna dapat membaca waktu data terakhir, status cache, dan informasi lokasi. Ekspor Excel menggunakan data lokal serta pemilih dokumen Android; pemilihan lokasi penyimpanan lokal diperlukan bila dilakukan tanpa jaringan [5][6].')
h('3.3 Use Case Diagram',True)
pic(TMP/'usecase.png','Gambar 3.2 Use case FishCare dengan pengelola dan layanan Open-Meteo',6.1)
prose('Pengelola merupakan aktor utama yang menjalankan seluruh kegiatan budidaya. Open-Meteo merupakan aktor sistem eksternal yang berhubungan dengan pencarian lokasi dan cuaca. Garis pada diagram menunjukkan asosiasi aktor dengan fungsi, bukan urutan proses. SQLite tidak ditampilkan sebagai aktor karena merupakan bagian penyimpanan internal. Integrasi sensor, login, notifikasi latar belakang, serta backup dan restore yang belum tersedia tidak dimasukkan sebagai fungsi aktif.')
h('Rincian use case dan alur pemberian')
table(['Fungsi','Prasyarat dan hasil utama','Acuan'],[
('Kolam dan siklus','Identitas valid dan maksimal satu siklus aktif per kolam. Riwayat siklus selesai dipertahankan.','FR-01/02'),
('Pakan, harga dan stok','Harga positif; stok masuk dan koreksi beralasan menghasilkan riwayat pergerakan.','FR-03'),
('Jadwal dan pemberian','Slot menunggu, pengukuran valid dan stok cukup. Aktual, biaya, status serta stok disimpan bersama.','FR-04'),
('Grading dan rencana','Jumlah sampel dan bobot valid; nomor grading bertambah; populasi tetap.','FR-05'),
('Kematian dan panen','Pengurangan tidak melampaui populasi. Panen akhir menutup siklus.','FR-05/06'),
('Pembatalan','Kegiatan sah terakhir pada hari yang sama dalam siklus aktif; alasan wajib.','FR-04–06'),
('Laporan dan Excel','Periode serta kolam sama pada ringkasan dan rincian; transaksi batal tidak masuk total.','FR-07'),
('Lokasi dan cuaca','Lokasi disimpan atas tindakan pengguna; waktu dan status data ditampilkan.','FR-08')],[1.35,4.2,.95])
p('Tabel 3.3 Ringkasan fungsi dan kaitannya dengan kebutuhan proyek.',size=10)
prose('Alur utama pemberian dimulai dengan memilih kolam dan jadwal, membaca keadaan ikan serta harga pakan, lalu memasukkan suhu air dan pH baru. Sistem menampilkan status kedua pengukuran dan rekomendasi bila tersedia. Pengguna menentukan aktual, meninjau biaya serta perubahan stok, kemudian menyimpan. Setelah transaksi berhasil, halaman terkait membaca keadaan terbaru.',
'Alur alternatif meliputi stok kurang, input tidak valid, kondisi air di luar acuan, perubahan harga atau kondisi ikan, pergantian hari, dan hasil simpan yang belum pasti. Isian dipertahankan ketika validasi gagal. Pemeriksaan hasil simpan menggunakan ID tindakan yang sama sebelum percobaan ulang. Pembatalan pemberian yang memenuhi syarat memulihkan stok sesuai aktual lama tanpa menghapus catatan asal. Panen akhir dan siklus selesai tidak dapat dibatalkan.')
h('3.4 Desain Database',True)
prose('Database produk menggunakan SQLite dengan skema versi 7 pada sumber 0.11.0+15. Rancangan berikut mengikuti tabel aktual yang dicatat pada implementasi, bukan seluruh entitas usulan awal yang belum dibuat. Diagram menyajikan relasi inti agar mudah dibaca; tabel pendukung dijelaskan setelahnya. PK berarti kunci utama dan FK berarti kunci asing [6][8].')
pic(TMP/'database.png','Gambar 3.3 Relasi inti database FishCare dengan kardinalitas',6.5)
prose('Satu kolam memiliki banyak siklus historis dan satu pakan dapat digunakan oleh banyak siklus. Siklus memiliki slot harian dan kegiatan. Satu slot dapat mempunyai beberapa catatan pemberian historis akibat pembatalan, tetapi maksimal satu pemberian sah. Grading mengacu pada kegiatan dan siklus; rencana grading menyimpan satu kondisi rencana per siklus.',
'Pergerakan stok mengacu pada pakan dan, untuk pengeluaran atau pemulihan pemberian, pada catatan pemberian. Stok masuk tidak harus terkait pemberian. operations dan feedings memakai ID tindakan yang sama melalui action_intents; keduanya tidak dihubungkan oleh FK langsung. Diagram tidak menggambarkan seluruh FK pendukung agar hubungan inti tetap terbaca.')
h('Kamus data utama')
table(['Tabel','Atribut utama dan fungsi'],[
('ponds dan feeds','Identitas, nama, status arsip; feeds menyimpan harga pencatatan rupiah/kg. Saldo stok tidak ditimpa langsung pada master.'),
('cycles','PK id; FK pond_id dan feed_id; ikan, populasi/bobot awal, populasi/bobot terkini, tanggal mulai, status, dan feeding_policy.'),
('cycle_schedules dan cycle_times','Versi jadwal efektif per siklus dan menit pemberian unik. Perubahan jam berlaku mulai besok.'),
('cycle_slots','PK gabungan cycle_id, business_date, minute; planned_g, normal_auto_g, status dan penanda penghentian.'),
('feedings','ID tindakan, FK siklus/slot/pakan; aktual gram; snapshot harga, biaya, bobot, populasi, rate, pengukuran dan rekomendasi.'),
('operations','Urutan commit, ID tindakan, siklus, jenis, tanggal, kondisi sebelum/sesudah, jumlah, snapshot panen dan pembatalan.'),
('stock_movements','Pergerakan masuk, keluar, koreksi dan pemulihan dalam delta gram. Mengacu pakan dan sumber transaksi.'),
('stock_corrections','Asal stok masuk, nilai lama/baru, alasan dan identitas koreksi; catatan asal tetap tersimpan.')],[1.9,4.6])
p('Tabel 3.4 Data utama dan perannya pada transaksi.',size=10)
table(['Tabel pendukung','Fungsi'],[
('grading_records','FK operation_id dan cycle_id; nomor ordinal unik per siklus serta keadaan rencana sebelum grading.'),
('grading_plans','PK/FK cycle_id; tanggal rencana berikutnya, sumber kegiatan dan revision.'),
('action_intents','ID, jenis, payload, target, status dan hasil tindakan; mendukung pemeriksaan setelah gangguan serta retry yang tidak menggandakan transaksi.'),
('legacy_feeding_intents','ID niat pemberian yang sudah ada sebelum migrasi; menjaga pemulihan data lama tanpa membuat pengukuran rekaan.'),
('cycle_rates dan schedule_changes','Riwayat rate manual lama serta perubahan jam. Rate otomatis lele mengikuti feeding_policy, bukan menimpa catatan lama.'),
('business_settings','Zona waktu usaha untuk penentuan tanggal kegiatan.'),
('weather_location dan weather_cache','Satu lokasi usaha tersimpan serta cache respons per koordinat dan waktu pengambilan.')],[1.9,4.6])
p('Tabel 3.5 Data pendukung, kompatibilitas riwayat, dan cuaca.',size=10)
h('Penyimpanan pengukuran dan integritas data')
prose('Jumlah ikan, pakan aktual, dan rupiah disimpan sebagai bilangan bulat. Bobot disimpan dalam seperseratus gram, suhu air dalam sepersepuluh derajat Celsius, dan pH dalam seperseratus satuan. Waktu pencatatan pengukuran disimpan bersama transaksi. Field rekomendasi dapat kosong ketika aturan tidak tersedia; kosong tidak dimaknai sebagai nol. Pengukuran pada transaksi lama yang belum memilikinya ditampilkan sebagai Tidak tercatat.',
'Harga dan biaya pemberian dihitung dari snapshot saat transaksi. Biaya pemberian adalah jumlah aktual gram × harga rupiah/kg / 1.000, dibulatkan half-up. Nilai panen menggunakan jumlah ikan × bobot panen gram/ekor × harga rupiah/kg / 1.000. Hasil setelah biaya pakan adalah seluruh pendapatan panen sah satu siklus dikurangi seluruh biaya pemberian sah pada siklus tersebut. Biaya lain tidak tercakup sehingga hasil ini tidak diberi label keuntungan bersih.',
'Validasi dan perubahan stok/populasi dilakukan dalam transaksi. Saldo negatif, pengurangan melebihi populasi, siklus aktif ganda, dan penyimpanan ulang harus dicegah. Migrasi mempertahankan data lama, sedangkan pembatalan menyimpan alasan serta jejak pemulihan. Backup dan restore memerlukan kontrak validasi tersendiri ketika kelak diimplementasikan; berkas Excel bukan salinan penuh database.')
h('3.5 Desain UI/UX (Wireframe)',True)
prose('Rancangan menggunakan empat menu utama dengan warna hijau, latar terang, kartu informasi, serta label status. Gambar disusun mendatar dalam kelompok tiga tampilan agar hubungan antarlayar dapat dibaca bersama. Seluruh angka pada gambar merupakan ilustrasi desain, bukan data budidaya atau bukti hasil pengujian. Form disederhanakan pada papan desain; kelengkapan isian dan perilakunya mengikuti uraian sistem.',
'Beranda menempatkan cuaca setelah identitas aplikasi, disusul ringkasan pakan dan kolam aktif. Halaman Kolam memisahkan siklus aktif, kolam tanpa siklus, dan arsip. Detail kolam menunjukkan populasi, bobot, grading terakhir, rencana berikutnya, serta tindakan kegiatan.')
UI=ROOT/'output/desain/revisi-2026-11-03'
pic(UI/'FishCare-Landscape-01-Beranda-dan-Kolam.png','Gambar 3.4 Beranda, daftar kolam, dan detail kolam')
prose('Cuaca ditampilkan sebagai informasi udara di lokasi usaha, lengkap dengan waktu. Ringkasan pakan membedakan normal harian dari aktual. Pada detail kolam, kondisi terkini dibedakan dari riwayat agar perubahan grading tidak dianggap mengubah kegiatan terdahulu.')
h('Grading dan pencatatan pemberian',True)
pic(UI/'FishCare-Landscape-02-Grading-dan-Pemberian.png','Gambar 3.5 Grading, jadwal pemberian, dan pengukuran air')
prose('Form grading pada alur lengkap mencakup jumlah ikan sampel, bobot rata-rata, dan rencana grading berikutnya. Saran rencana tujuh hari kemudian dapat diubah. Nomor grading menunjukkan urutan pencatatan dalam satu siklus, bukan kewajiban menunggu periode tertentu. Keterlambatan rencana ditampilkan tanpa menghentikan pemberian pakan.',
'Halaman Pakan membedakan Pemberian Hari Ini dan Stok. Jadwal menyajikan jam serta status, sedangkan form pemberian meminta suhu air dan pH baru setiap kali pengguna mencatat. Nilai pengukuran sebelumnya tidak diisi otomatis. Pengguna dapat memakai jumlah rekomendasi secara eksplisit, kemudian mengubah aktual bila diperlukan.',
'Jumlah aktual dan biaya mengikuti tahap isian sebelum konfirmasi. Perubahan pengukuran tidak diam-diam mengganti aktual yang sudah diketik. Kondisi di luar acuan diberi peringatan tanpa angka rekomendasi. Navigasi bawah pada papan desain menggambarkan struktur aplikasi; layar form operasional memakai Kembali dan tindakan utama.')
h('Konfirmasi stok dan laporan',True)
pic(UI/'FishCare-Landscape-03-Stok-dan-Laporan.png','Gambar 3.6 Konfirmasi pemberian, stok pakan, dan laporan')
prose('Konfirmasi pemberian menunjukkan aktual, harga per kilogram, biaya, pengukuran air, serta saldo stok sebelum dan sesudah. Pengguna dapat meninjau dampak tersebut sebelum menyimpan. Jika jumlah aktual melampaui rekomendasi atau batas normal yang relevan, aplikasi meminta konfirmasi tambahan sesuai aturan proyek.',
'Stok merupakan persediaan bersama seluruh kolam. Riwayat membedakan stok masuk, pemakaian, koreksi, dan pemulihan akibat pembatalan. Koreksi harus menyertakan alasan dan mempertahankan catatan asal. Pengubahan harga master tidak menghitung ulang biaya transaksi sebelumnya.',
'Halaman Laporan menyediakan periode dan pilihan kolam. Pemakaian pakan, biaya, kematian, jumlah panen, serta nilai panen mengikuti filter yang sama. Tombol Ekspor Excel menyimpan lembar Ringkasan dan Transaksi dari data laporan tersebut. Pembatalan dan kegagalan penyimpanan mendapat status yang berbeda dari keberhasilan.')
h('Hasil siklus lokasi dan keadaan khusus',True)
pic(UI/'FishCare-Landscape-04-Hasil-Panen-dan-Lokasi.png','Gambar 3.7 Hasil panen, lokasi usaha, dan contoh keadaan khusus')
prose('Hasil panen menampilkan pendapatan kotor, total pakan terpakai, total biaya pakan, dan hasil setelah biaya pakan. Bagian ini diberi label Seluruh siklus sehingga tidak tercampur dengan total transaksi pada periode laporan. Nilai negatif tetap ditampilkan apabila biaya pakan melebihi pendapatan yang tercatat.',
'Pemilihan lokasi dapat menggunakan koordinat HP sekali atau pencarian manual. Hasil baru masih berupa calon lokasi sampai pengguna menyimpannya. Pembatalan mempertahankan lokasi sebelumnya. Ketika cuaca tidak dapat diperbarui, data terakhir diberi waktu dan status cache; tanpa cache, cuaca dinyatakan belum tersedia.',
'Panel keadaan khusus merupakan kumpulan contoh pesan, bukan satu halaman operasional yang menampilkan semuanya sekaligus. Keadaan kosong, memuat, gagal, offline, data belum lengkap, stok kurang, dan ekspor dibatalkan perlu memiliki penjelasan yang berbeda. Uji antarmuka tetap diperlukan untuk keyboard, pembesaran teks, tombol kembali, dan keterbacaan pada HP.')

chapter(4,'RENCANA IMPLEMENTASI')
h('4.1 Teknologi yang Digunakan')
table(['Teknologi','Peran dan dasar pemilihan'],[
('Flutter dan Dart','Pembuatan UI Android dan aturan bisnis. Lingkungan yang tercatat: Flutter 3.47.5 dan Dart 3.13.4; versi mengikuti catatan proyek, bukan rekomendasi versi terbaru.'),
('SQLite melalui sqflite 2.4.4','Database lokal dan transaksi. Skema produk terbaru yang menjadi acuan adalah versi 7.'),
('Android','Platform sasaran; konfigurasi APK terakhir minSdk 24 serta target/compile SDK 36. Bukti perangkat tersedia pada Infinix X6879 Android 16/API 36.'),
('Open-Meteo','API cuaca dan pencarian lokasi usaha; respons memuat data lokasi, waktu, dan variabel cuaca.'),
('Layanan lokasi Android','Mengambil koordinat sekali atas tindakan pengguna dengan izin saat digunakan; tanpa pelacakan latar belakang.'),
('SpreadsheetML dan pemilih dokumen Android','Pembuatan .xlsx berisi Ringkasan dan Transaksi. Berkas disimpan melalui pilihan lokasi pengguna.'),
('Pengujian Flutter dan Android','Tes aturan, widget, transaksi SQLite, migrasi, ekspor, build APK, serta pemeriksaan perangkat fisik.')],[1.7,4.8])
p('Tabel 4.1 Teknologi berdasarkan konfigurasi dan bukti implementasi yang tercatat [6][8].',size=10)
prose('Dependency dibatasi pada kebutuhan nyata dan versi yang sudah digunakan dipertahankan melalui lockfile. Kesesuaian versi tidak disimpulkan dari nomor versi saja, melainkan dari build serta hasil pengujian. Konfigurasi minSdk menunjukkan batas konfigurasi aplikasi, bukan bukti bahwa seluruh perangkat pada versi tersebut telah diuji.',
'Penerapan aturan pakan lele memakai satu sumber perhitungan bersama. Penambahan spesies atau sensor pada tahap berikutnya perlu menambah kebijakan serta pengujian yang sesuai, bukan menggunakan aturan lele untuk semua ikan.')
h('4.2 Struktur Aplikasi')
prose('Struktur aplikasi mengikuti empat tanggung jawab utama: antarmuka dan state, aturan bisnis, repository, serta penyimpanan atau klien API. Beranda menyajikan ringkasan; modul Kolam mengelola master, siklus, dan kegiatan; modul Pakan menangani jadwal serta persediaan; modul Laporan membaca agregat dan mengekspor data. Pengaturan lokasi diakses dari alur pengaturan aplikasi.',
'Modul aturan pakan menentukan rate berdasarkan bobot, kebutuhan normal, pembagian slot, dan penyesuaian pengukuran. Modul operasi siklus mengatur grading, kematian, panen, serta pembatalan. Modul jurnal tindakan menyimpan niat dan hasil operasi agar gangguan atau ketukan berulang dapat ditangani tanpa membuat transaksi baru.',
'Repository melakukan pembacaan dan penulisan melalui transaksi yang sesuai. Setelah commit berhasil, halaman terkait membaca ulang keadaan. Pengelolaan state cuaca dipisahkan sehingga menunggu jaringan tidak menahan pencatatan lokal. Migrasi database dilakukan bertahap dan harus menjaga catatan historis, termasuk data lama yang belum memiliki pengukuran air.')
h('4.3 Fitur Utama Aplikasi',True)
table(['Fitur','Perilaku yang disediakan'],[
('Pengelolaan kolam dan siklus','Membuat dan mengubah identitas kolam, arsip, memulai siklus, melihat keadaan aktif serta riwayat.'),
('Jadwal pakan','Menampilkan jam dan status pemberian setiap hari. Perubahan template jam berlaku besok; belum berupa notifikasi latar belakang.'),
('Kebutuhan dan rekomendasi pakan','Rate otomatis dari bobot lele, kebutuhan normal harian, pembagian per slot, serta penyesuaian berdasarkan suhu air dan pH baru.'),
('Harga dan biaya pemberian','Harga rupiah/kg serta biaya aktual terlihat sebelum konfirmasi; perubahan harga berikutnya tidak mengubah riwayat.'),
('Persediaan pakan','Master pakan, stok bersama, stok masuk, koreksi beralasan, serta riwayat pengeluaran dan pemulihan.'),
('Grading dan rencana','Nomor grading per siklus, bobot terkini, tanggal terakhir, rencana berikutnya yang dapat diubah, serta tanda rencana terlewat.'),
('Populasi dan kematian','Mencatat kematian dengan validasi jumlah; populasi tidak boleh negatif atau berkurang akibat grading.'),
('Harga dan nilai panen','Panen sebagian atau akhir dengan jumlah, bobot, harga per kg dan nilai transaksi. Panen akhir menutup siklus.'),
('Hasil setelah biaya pakan','Pendapatan sah seluruh siklus dikurangi biaya pakan terpakai; biaya lain belum diperhitungkan.'),
('Laporan dan riwayat','Filter periode dan kolam, total pemakaian/biaya pakan, kematian, jumlah serta nilai panen; rincian mempertahankan snapshot.'),
('Ekspor Excel','Berkas .xlsx berisi Ringkasan dan Transaksi sesuai filter, termasuk pengukuran air yang tersedia.'),
('Cuaca lokasi usaha','Cuaca API pada koordinat yang dipilih, status cache, lokasi dan waktu data; bukan sensor suhu air.'),
('Koreksi dan perlindungan transaksi','Pembatalan yang memenuhi syarat, alasan, pemulihan stok/populasi, serta ID tindakan untuk mencegah transaksi ganda.')],[1.75,4.75])
p('Tabel 4.2 Fitur utama sesuai PRD dan revisi implementasi [5][6].',size=10)
prose('Cakupan fitur di atas membedakan fungsi yang tercatat dari pengembangan lanjutan. Backup dan restore masih merupakan kebutuhan awal yang belum tersedia. Login, backend sendiri, sinkronisasi cloud, FCR, serta perhitungan keuntungan bersih tidak dimasukkan sebagai fitur produk saat ini. Ekspor Excel memindahkan laporan, bukan seluruh data yang diperlukan untuk memulihkan aplikasi.')
h('4.4 Timeline Pengembangan',True)
prose('Timeline disusun dalam kelompok minggu berdasarkan tanggal yang tercatat pada riwayat proyek. Catatan awal yang dapat ditelusuri dimulai pada 13 Oktober 2026. Kegiatan dalam minggu yang sama dapat dikerjakan pada hari berbeda; tabel ini tidak mengarang tanggal mulai sebelum bukti tersebut. Target awal akhir Oktober dibaca bersama status hasil yang benar-benar tercatat [5][6].')
table(['Minggu','Kegiatan dan bukti waktu','Keluaran'],[
('Minggu 1\n12–18 Oktober 2026','13 Oktober: perumusan PRD dan diagnosis M0; pengembangan master, siklus, jadwal, stok, kegiatan dan laporan. 14 Oktober: keputusan lokasi atas tindakan pengguna. 15 Oktober: rancangan UI serta bahan proposal.','Baseline kebutuhan, fondasi aplikasi, alur utama dan rancangan awal. Sebagian verifikasi pada catatan awal masih terhalang lingkungan.'),
('Minggu 2\n19–25 Oktober 2026','20 Oktober: perapian Beranda, detail kolam, Pakan dan Laporan. 25 Oktober: revisi dosen tentang fokus lele, grading, rate bobot, suhu/pH, harga dan ekspor; implementasi grading.','UI diperbarui dan grading bernomor dengan rencana fleksibel; aturan pakan baru dirinci sebelum aktivasi.'),
('Minggu 3\n26 Oktober–1 November 2026','26 Oktober: mesin aturan pakan, aktivasi input suhu/pH dan snapshot, ekspor Excel, regresi Android, serta ringkasan hasil setelah biaya pakan. Catatan pekerjaan pada minggu ini tersedia untuk 26 Oktober.','Sumber 0.11.0+15, skema 7; APK dibangun dan dipasang. Hasil uji terakhir serta keterbatasannya diringkas di bawah.'),
('Minggu 4\n2–8 November 2026','3 November: penyelarasan desain tiga tampilan per gambar dan proposal lima bab berdasarkan catatan terbaru.','Dokumen proposal dan gambar pendukung; pengembangan sensor dan spesies lain tetap rencana lanjutan.')],[1.15,3.3,2.05])
p('Tabel 4.3 Timeline mingguan berdasarkan riwayat, bukan pembagian waktu rekaan.',size=10)
h('Rencana verifikasi dan status acuan')
prose('Verifikasi dilakukan bertahap: analisis kode, tes aturan dan widget, pengujian transaksi SQLite pada Android, build APK, pemasangan, serta uji manual. Skenario utama meliputi pengukuran air wajib setiap pemberian, batas rate, stok kurang, aktual berlebih, pergantian hari, pembatalan, migrasi data, harga historis, ekspor, dan kegagalan cuaca. Skenario AT-47–68 dalam PRD menjelaskan perubahan revisi; keberadaan skenario tidak otomatis berarti semuanya sudah diuji.',
'Catatan terakhir 26 Oktober 2026 menyebut analisis tanpa issue, 120 tes Flutter standar lulus, 54 tes Android lulus, build APK berhasil, dan pemasangan versi 0.11.0+15 pada Infinix X6879. Angka tersebut merupakan hasil yang sudah dicatat, bukan pengujian baru dalam penyusunan proposal. Tes Android menggunakan aplikasi uji terpisah [6].',
'Pemeriksaan manual tabel hasil panen pada data operasional belum tercatat selesai. Pemeriksaan isi berkas Excel aktual di Excel/WPS diserahkan kepada pengguna, dan seluruh skenario manual serta mode pesawat belum dinyatakan lulus. Peninjauan acuan budidaya untuk kolam biasa juga tetap perlu dilakukan. Kegiatan tersebut menjadi tindak lanjut verifikasi, bukan hasil yang diklaim pada timeline.')

chapter(5,'PENUTUP')
h('5.1 Kesimpulan')
prose('FishCare dirancang sebagai aplikasi Android untuk membantu satu pengelola budidaya lele menghubungkan data kolam, siklus, kondisi ikan, jadwal pakan, persediaan, biaya pemberian, dan hasil panen. Penyimpanan lokal mendukung pencatatan inti tanpa ketergantungan pada layanan cuaca. Informasi API tetap disajikan secara terpisah dari hasil pengukuran air.',
'Pengembangan rekomendasi pakan menggunakan bobot terbaru serta suhu air dan pH yang dicatat pada setiap pemberian. Jumlah aktual tetap menjadi dasar pengurangan stok dan perhitungan biaya. Snapshot transaksi, validasi, dan pembatalan beralasan menjaga keterlacakan riwayat ketika harga atau kondisi ikan berubah. Laporan dan ekspor Excel menyediakan ringkasan serta rincian dengan filter yang konsisten.',
'Rancangan dan rencana implementasi dalam proposal mengikuti kebutuhan serta perkembangan yang terdokumentasi. Bukti teknis terakhir menunjukkan hasil pengujian dan pemasangan yang telah dicatat, tetapi tidak menjadi bukti peningkatan hasil budidaya atau kelulusan seluruh pengujian lapangan. Evaluasi penggunaan nyata dan peninjauan aturan perikanan tetap diperlukan sebelum menarik kesimpulan mengenai manfaat produksi.')
h('5.2 Rencana Pengembangan Lanjutan')
prose('Tahap pengembangan saat ini difokuskan pada pengelolaan dan rekomendasi pakan ikan lele. Pengembangan berikutnya diarahkan untuk mendukung budidaya ikan air tawar lainnya, terutama ikan nila, mujair, dan gurame. Perluasan ini tidak cukup dilakukan dengan menambahkan pilihan nama ikan, tetapi membutuhkan acuan pakan, rentang bobot, kondisi air, dan cara evaluasi yang sesuai untuk setiap spesies.',
'Aturan untuk masing-masing jenis ikan direncanakan dipisahkan ke dalam kebijakan perhitungan tersendiri. Pengelola dapat memilih jenis ikan pada awal siklus, kemudian sistem menggunakan acuan yang sesuai. Rate lele tidak diterapkan otomatis pada nila, mujair, atau gurame. Penyusunan aturan perlu melibatkan peninjauan sumber dan masukan bidang perikanan, disertai pengujian batas nilai serta pencatatan versi aturan agar transaksi sebelumnya tetap dapat ditelusuri.',
'Pengembangan selanjutnya juga diarahkan pada integrasi perangkat pengukuran pH dan suhu air secara otomatis. Melalui integrasi tersebut, hasil pengukuran dari kolam dapat diterima oleh aplikasi sehingga pengguna tidak perlu mengetik nilai secara manual pada setiap pemberian. Setelah data valid dan sesuai dengan kolam yang dipilih, aplikasi dapat langsung menampilkan status kondisi air serta rekomendasi pakan untuk jadwal yang sedang ditinjau.',
'Rancangan integrasi perlu memastikan identitas perangkat dan kolam, waktu pengukuran, kalibrasi, serta penanganan data yang tidak tersedia atau sudah kedaluwarsa. Jika koneksi perangkat terganggu, aplikasi perlu memberi informasi yang jelas dan menyediakan alur pengukuran manual sebagai cadangan. Rekomendasi tidak boleh muncul dari data sensor yang tidak dapat dipercaya. Pemilihan perangkat, jalur komunikasi, dan batas usia data ditentukan melalui perancangan serta pengujian pada tahap berikutnya.',
'Integrasi sensor diarahkan untuk mengotomatisasi masukan pengukuran dan penyajian rekomendasi. Jumlah pakan yang benar-benar diberikan tetap perlu dicatat dan dikonfirmasi agar persediaan serta biaya mengikuti kegiatan aktual. Pengendalian alat pemberi pakan otomatis belum termasuk rencana yang ditetapkan dalam proposal ini.',
'Perluasan spesies dan integrasi pengukuran dilaksanakan secara bertahap setelah alur utama stabil dan acuan masing-masing fitur ditinjau. Evaluasi mencakup ketepatan data, kemudahan penggunaan, keandalan perangkat, serta konsistensi transaksi. Arah pengembangan tambahan dapat dibahas setelah kebutuhan kedua tahap tersebut lebih terukur, sehingga lingkup tetap sesuai tujuan FishCare.')

h('REFERENSI',True)
refs=[
'[1] Android Developers. Build an offline-first app. Dokumentasi resmi. https://developer.android.com/topic/architecture/data-layer/offline-first. Diakses 3 November 2026.',
'[2] Flutter. Flutter architectural overview. Dokumentasi resmi. https://docs.flutter.dev/resources/architectural-overview. Diakses 3 November 2026.',
'[3] Android Developers. Make apps more accessible. Dokumentasi resmi. https://developer.android.com/guide/topics/ui/accessibility/apps. Diakses 3 November 2026.',
'[4] SQLite. SQLite Is Transactional. Dokumentasi resmi. https://www.sqlite.org/transactional.html. Diakses 3 November 2026.',
'[5] Tim FishCare. PRD FishCare Rancangan Baru v0.1. Dokumen internal proyek, 13 Oktober 2026, dengan revisi kebutuhan dan keputusan bagian 15 tanggal 25–26 Oktober 2026 serta arah pengembangan lanjutan tanggal 3 November 2026.',
'[6] Tim FishCare. README proyek; catatan M0–M5; Tahap Cuaca Lokasi; UI Rapikan 20 Oktober 2026; Revisi Dosen Tahap 1–6; dan Hasil Panen Biaya Pakan. Catatan implementasi dan verifikasi internal, Oktober 2026. Bukti terakhir: versi 0.11.0+15, 26 Oktober 2026.',
'[7] Open-Meteo. Weather Forecast API Documentation. https://open-meteo.com/en/docs. Diakses 3 November 2026.',
'[8] Tim FishCare. Rancangan Database dan skema sumber aplikasi pada app_m0/lib, termasuk cycle_schema.dart, m3_schema.dart, m4_schema.dart, grading.dart, feeding_schema.dart, weather_schema.dart, dan master_repository.dart. Skema produk versi 7, diperiksa 3 November 2026.',
'[9] Kelompok 7. Rancangan UI FishCare revisi 3 November 2026. Dua belas tampilan dalam empat kelompok gambar horizontal. Dokumen desain internal proyek.'
]
for r in refs:p(r,size=11)

# Suntingan kepadatan setelah render pertama: pertahankan ukuran huruf template,
# hilangkan halaman yang hanya berisi satu atau dua baris sisa.
revisions={
'Bagi mahasiswa, proyek menjadi sarana': 'Bagi mahasiswa, proyek menjadi sarana penerapan perancangan antarmuka, pemodelan data, perhitungan bisnis, integrasi API, dan pengujian Android. FishCare juga menunjukkan bagaimana kebutuhan pengguna serta masukan dosen diterjemahkan menjadi aturan yang dapat diuji.',
'Penyimpanan lokal menempatkan data kegiatan': 'Penyimpanan lokal menempatkan data pada perangkat pengguna. Pendekatan offline-first menyediakan fungsi penting ketika jaringan tidak tersedia [1]. Pada FishCare, kolam, stok, pemberian, grading, kematian, panen, dan laporan memakai database lokal. Pencarian lokasi serta pembaruan cuaca membutuhkan jaringan. Pemisahan ini tidak berarti seluruh layanan eksternal bekerja offline.',
'Lingkup satu pengguna berarti': 'Lingkup satu pengguna tidak memerlukan login, pembagian hak akses, atau sinkronisasi cloud. Beberapa kolam dapat dikelola dalam satu perangkat. Keutuhan data dijaga melalui validasi, transaksi, dan pemeliharaan riwayat. Backup dan restore tercantum dalam kebutuhan awal, tetapi belum tersedia pada implementasi acuan [5][6].',
'Pemisahan tersebut memungkinkan perhitungan': 'Perhitungan bersama dipakai pada detail kolam, jadwal, form pemberian, dan laporan. Perubahan bobot atau populasi memperbarui keadaan terkini tanpa menulis ulang transaksi lama. Integrasi Android menyediakan lokasi atas tindakan pengguna dan pemilih dokumen untuk menyimpan Excel.',
'Pemilihan versi mengikuti lingkungan': 'Versi mengikuti lingkungan yang tercatat. Analisis kode dan tes otomatis tidak menggantikan build APK atau uji HP. Kompatibilitas hanya dinyatakan untuk konfigurasi dan perangkat yang mempunyai bukti [6].',
'User interface mengatur bentuk': 'User interface mengatur tampilan dan interaksi, sedangkan user experience berkaitan dengan kemudahan menyelesaikan kegiatan. FishCare mengutamakan angka, satuan, status, dan dampak tindakan melalui menu Beranda, Kolam, Pakan, dan Laporan. Form memakai label tetap dan pesan kesalahan dekat isian.',
'Status memuat data, kosong': 'Status memuat, kosong, gagal, offline, dan berhasil harus dibedakan. Ketiadaan data bukan angka nol. Ekspor yang dibatalkan tidak dianggap tersimpan, sedangkan pengukuran air yang belum lengkap tidak menghasilkan rekomendasi.',
'API cuaca menerima lokasi': 'API cuaca menerima koordinat dan menyediakan variabel beserta waktu serta satuannya [7]. FishCare memakai satu lokasi usaha untuk seluruh kolam di area yang sama. Koordinat HP diambil sekali atas tindakan pengguna atau lokasi dicari manual. Calon lokasi menggantikan lokasi lama setelah disimpan. Cache dibedakan menurut lokasi dan waktu.',
'Timeline disusun dalam kelompok': 'Timeline dikelompokkan per minggu berdasarkan riwayat proyek, dengan catatan awal pada 13 Oktober 2026. Tidak ada tanggal mulai sebelum itu yang diasumsikan. Kegiatan dalam satu minggu dapat berlangsung pada hari berbeda; target awal akhir Oktober dibaca bersama bukti hasil yang tersedia [5][6].',
'Verifikasi dilakukan bertahap:': 'Verifikasi mencakup analisis kode, tes aturan dan widget, transaksi SQLite Android, build APK, pemasangan, dan uji manual. Skenario utama meliputi pengukuran baru, batas rate, stok kurang, aktual berlebih, pergantian hari, pembatalan, migrasi, harga historis, ekspor, dan cuaca gagal. AT-47–68 merinci revisi; keberadaan skenario tidak berarti semuanya lulus.',
'Catatan terakhir 26 Oktober': 'Catatan 26 Oktober 2026 menyebut analisis tanpa issue, 120 tes Flutter dan 54 tes Android lulus, build berhasil, serta pemasangan versi 0.11.0+15 pada Infinix X6879. Tes Android memakai aplikasi uji terpisah. Ini hasil historis, bukan pengujian baru saat penyusunan proposal [6].',
'Pemeriksaan manual tabel hasil': 'Pemeriksaan manual tabel hasil panen, isi Excel aktual di Excel/WPS, mode pesawat, dan seluruh skenario manual belum dinyatakan selesai. Peninjauan acuan budidaya kolam biasa juga masih diperlukan. Semuanya menjadi tindak lanjut, bukan hasil yang diasumsikan lulus.',
'Cakupan fitur di atas': 'Backup dan restore belum tersedia. Login, backend sendiri, sinkronisasi cloud, FCR, serta keuntungan bersih tidak termasuk fitur saat ini. Ekspor Excel berisi laporan dan tidak menggantikan backup database.'
}
for q in doc.paragraphs:
    for prefix,newtext in revisions.items():
        if q.text.startswith(prefix):
            q.runs[0].text=newtext
            for r in q.runs[1:]:r.text=''
    if q.text=='2.3 UI/UX dalam Aplikasi Mobile':q.paragraph_format.page_break_before=True
    if q.text=='4.3 Fitur Utama Aplikasi':q.paragraph_format.page_break_before=False
    if q.text.startswith('Rancangan menggunakan empat menu utama'):
        q.runs[-1].text += ' Sumber visual: rancangan UI revisi 3 November 2026 [9].'

footer=doc.sections[0].footer.paragraphs[0];footer.alignment=WD_ALIGN_PARAGRAPH.RIGHT
f=OxmlElement('w:fldSimple');f.set(qn('w:instr'),'PAGE');footer._p.append(f)
upd=OxmlElement('w:updateFields');upd.set(qn('w:val'),'true');doc.settings._element.append(upd)
work=TMP/'working.docx';doc.save(work)
allowed={'word/document.xml','word/_rels/document.xml.rels','word/styles.xml','word/settings.xml','[Content_Types].xml'}
final=OUT/'Proposal-FishCare-Kelompok-7-2026.docx'
with ZipFile(SRC) as a,ZipFile(work) as b,ZipFile(final,'w',ZIP_DEFLATED) as dest:
    for name in a.namelist():dest.writestr(name,b.read(name) if name in allowed and name in b.namelist() else a.read(name))
    for name in b.namelist():
        if name not in a.namelist() and not name.startswith('docProps/'):dest.writestr(name,b.read(name))
with ZipFile(SRC) as a,ZipFile(final) as b:assert all(a.read(n)==b.read(n) for n in a.namelist() if n not in allowed)
assert hashlib.sha256(SRC.read_bytes()).hexdigest()=='063cb665e8e1a30c5f433157b79a740a3d3d3df89cfb317f1b60abd4a320e7f5'
print(final)
