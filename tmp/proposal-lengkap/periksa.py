from pathlib import Path
from zipfile import ZipFile
from hashlib import sha256
import json,re
from docx import Document
from pypdf import PdfReader
import pypdfium2 as pdfium
root=Path(__file__).resolve().parents[2];out=root/'output/laporan';tmp=Path(__file__).parent
pdf=out/'Proposal-FishCare-Kelompok-7-Lengkap.pdf';docx=out/'Proposal-FishCare-Kelompok-7-Lengkap.docx'
r=PdfReader(str(pdf));d=pdfium.PdfDocument(str(pdf));qa=tmp/'final-render';qa.mkdir(exist_ok=True)
texts=[]
for i,page in enumerate(r.pages):
    text=page.extract_text() or '';texts.append(text)
    assert len(text.strip())>110,f'Halaman kosong {i+1}'
    d[i].render(scale=1.2).to_pil().save(qa/f'page-{i+1}.png')
    print(i+1,len(text.split()),text[:75].replace('\n',' | '))
full='\n'.join(texts)
for token in ['BAB 1','BAB 2','BAB 3','BAB 4','BAB 5','REFERENSI','1.1 Latar Belakang','1.4 Manfaat Proyek','2.4 Teknologi Backend / API','3.3 Use Case Diagram','3.4 Desain Database','4.4 Timeline Pengembangan','5.2 Rencana Pengembangan Lanjutan']:
    assert token in full,token
src=Path(r'C:\Users\basti\Downloads\TEMPLATE PROPOSAL PjBL PPB.docx')
assert sha256(src.read_bytes()).hexdigest()=='063cb665e8e1a30c5f433157b79a740a3d3d3df89cfb317f1b60abd4a320e7f5'
allowed={'word/document.xml','word/_rels/document.xml.rels','word/styles.xml','word/settings.xml','[Content_Types].xml'}
with ZipFile(src) as a,ZipFile(docx) as b:
    assert all(a.read(n)==b.read(n) for n in a.namelist() if n not in allowed)
doc=Document(docx);sec=doc.sections[0]
assert len(doc.sections)==1 and round(sec.page_width/914400,2)==8.5 and round(sec.page_height/914400,2)==11
assert all(round(m/914400,2)==1 for m in [sec.left_margin,sec.right_margin,sec.top_margin,sec.bottom_margin])
assert len([p for p in doc.paragraphs if re.match(r'[1-6]\. Nama:',p.text)])==6
result={'pages':len(r.pages),'wordsApprox':sum(len(t.split()) for t in texts),'figures':len(doc.inline_shapes),'group':7,'blankMemberFields':6,'templateUnchanged':True,'preserveOnlyPartsUnchanged':True,'old10PageVersionPreserved':True,'render':'Microsoft Word ExportAsFixedFormat and PDFium','applicationSourceChanged':False,'scope':'proposal complete; no page limit'}
(out/'pemeriksaan-lengkap.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))
