# Kontrak proposal FishCare

Referensi tetap: C:/Users/basti/Downloads/TEMPLATE PROPOSAL PjBL PPB.docx
SHA256: 063cb665e8e1a30c5f433157b79a740a3d3d3df89cfb317f1b60abd4a320e7f5
Referensi mempunyai 3 halaman, 1 section portrait Letter 8,5 x 11 inci, margin 1 inci pada semua sisi. Header/footer default 0,5 inci; tidak ada header/footer atau nomor halaman yang terlihat. Bukti: template-reference.pdf, template-1.png sampai template-3.png, reference-parts.json dan template-style.json pada direktori ini. Renderer LibreOffice tidak tersedia; Microsoft Word melalui COM berhasil mengekspor referensi ke PDF tanpa menyimpan perubahan.

Normal memakai docDefaults Aptos 12 pt, hitam, spasi sesudah 8 pt, line spacing 278/240 atau 1,1583. Judul/label/headings referensi adalah Normal dengan bold langsung, kiri, tanpa indent atau garis. Sampul seluruhnya kiri. Tidak ada tabel, gambar, konten kontrol, komentar, footnote atau field dalam body referensi. Audit XML juga mencakup seluruh bagian paket; tidak ada header/footer/text box yang memuat slot lain.

Slot berurutan word/document.xml / w:document/w:body/w:p: paragraf0–9 sampul;11–16 BAB1;18–23 BAB2;25–31 BAB3;33–38 BAB4;40–43 BAB5;45 REFERENSI. Semuanya dapat diisi/ditambah dengan klon pola paragraf Normal. Pertahankan nama/urutan 5 bab, subbagian 1.1–5.2 serta referensi. Contoh nama aplikasi pada paragraf5/7 diganti dengan judul FishCare. Paragraf9 diperluas menjadi Kelompok7 serta enam baris Nama dan NIM kosong menurut instruksi pengguna. Tambah dosen, prodi, universitas sebagai kolom isi; tidak mengarang identitas.

Pengguna meminta maksimal10halaman dan memasukkan desain baru. Isi diperluas menjadi10halaman dengan page break eksplisit, tanpa mengecilkan font normal12. Dua halaman memuat empat gambar layar utama. Diagram arsitektur, usecase dan relasi database ditambahkan sebagai figur konseptual. Tabel untuk entitas, teknologi/tahap/tes memakai font10–10,5, border abu, padding cukup, header hitam pada abu terang. Tidak ada tabel dekoratif/callout. Nomor halaman footer diperlukan untuk memeriksa batas10; satu section tetap. Title style hanya untuk judul sampul12boldhitam; heading lain mengikuti Normal bold referensi.

Alokasi halaman:1sampul;2BAB1;3BAB2;4BAB3 3.1–3.3;5 3.4;6–7 3.5;8BAB4 4.1–4.3;9 4.4 serta rencana verifikasi;10BAB5 dan referensi. Slot boleh diperluas dengan paragraf/list/figur/tabel terkait; tidak mengisi templat dengan klaim pengujian tanpa bukti.

Preserve-only: seluruh bagian paket referensi pada reference-parts.json kecuali word/document.xml, word/_rels/document.xml.rels, word/styles.xml, word/settings.xml, [Content_Types].xml. Bagian tersebut boleh berubah untuk isi, figur, Title style, updateFields, dan footer. Bagian lain termasuk customXML, font tertanam, theme, numbering dan relationshipfont harus tetap byte-identik. Bagian gambar/footer baru diperbolehkan. Sumber asli tetap hash identik.

Pemeriksaan akhir: ekspor dokumen final melalui Word, jumlah halaman<=10, seluruh halaman dirender PNG dan diperiksa, tidak ada clipping/overlap, cek bab dan angka, verifikasi preserve-only, section geometry, dan identitas kosong yang disengaja. PDF final berasal dari DOCX yang sama. Referensi teknis primer Flutter/SQLite/Android/Open-Meteo diperiksa15Oktober2026; tidak mengarang acuan budidaya.
