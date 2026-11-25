from pathlib import Path
import json,zipfile
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from PIL import Image,ImageOps,ImageDraw
import pypdfium2 as pdfium
from pypdf import PdfReader

root=Path(__file__).resolve().parents[2]
out=root/'output'/'desain'
items=json.loads((out/'daftar-layar.json').read_text(encoding='utf-8'))
pdf=out/'FishCare-Desain-UI-Baru.pdf'
c=canvas.Canvas(str(pdf));c.setTitle('FishCare Desain UI Baru');c.setAuthor('Tim FishCare')
for s in items:
    img=out/'png'/s['filename']
    w,h=Image.open(img).size
    dw=390;dh=h/w*dw
    ph=dh+160
    c.setPageSize((510,ph))
    c.setFillColor(HexColor('#173c39'));c.setFont('Helvetica-Bold',17)
    c.drawString(40,ph-35,f"{s['index']:02d}  {s['title']}")
    c.setFont('Helvetica',10);c.setFillColor(HexColor('#546e69'))
    c.drawString(40,ph-55,s['group'])
    c.drawImage(str(img),60,70,width=dw,height=dh,mask='auto')
    c.setFont('Helvetica',9)
    c.drawString(40,48,'Draf UI 01 | Data simulasi | Belum diterapkan ke aplikasi')
    c.drawString(40,32,'FishCare | 15 Oktober 2026')
    c.drawRightString(470,32,f"{s['index']} / {len(items)}")
    c.showPage()
c.save()
assert len(PdfReader(str(pdf)).pages)==len(items)
with zipfile.ZipFile(out/'FishCare-Desain-PNG.zip','w',zipfile.ZIP_DEFLATED) as z:
    for f in sorted((out/'png').glob('*.png')):z.write(f,'PNG/'+f.name)
    z.write(out/'FishCare-Empat-Menu-Utama.png','FishCare-Empat-Menu-Utama.png')
# Render actual PDF pages for visual inspection, in contact sheets.
qa=root/'tmp'/'pdfs'/'desain';qa.mkdir(parents=True,exist_ok=True)
doc=pdfium.PdfDocument(str(pdf))
for start in range(0,len(doc),12):
    sheet=Image.new('RGB',(1400,1400),'#e9eeea');draw=ImageDraw.Draw(sheet)
    for i in range(start,min(start+12,len(doc))):
        page=doc[i];im=page.render(scale=0.6).to_pil().convert('RGB')
        thumb=ImageOps.contain(im,(330,430))
        slot=i-start;x=(slot%4)*350+(350-thumb.width)//2;y=(slot//4)*465+24
        sheet.paste(thumb,(x,y));draw.text(((slot%4)*350+12,y-18),f"{i+1:02d} {items[i]['id']}",fill='#173c39')
        page.close()
    sheet.save(qa/f'controle-{start//12+1}.png')
doc.close()
print(f'PDF: {len(items)} halaman; ZIP: {len(items)+1} PNG; render QA: {(len(items)+11)//12} lembar')
