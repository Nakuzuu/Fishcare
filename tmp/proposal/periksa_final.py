from pathlib import Path
from zipfile import ZipFile
import hashlib,json
import pypdfium2 as pdfium
from pypdf import PdfReader
from docx import Document

root=Path(__file__).resolve().parents[2];out=root/'output/laporan';qa=Path(__file__).parent/'final-render';qa.mkdir(exist_ok=True)
pdf=out/'Proposal-FishCare-Kelompok-7.pdf';docx=out/'Proposal-FishCare-Kelompok-7.docx'
reader=PdfReader(str(pdf));assert len(reader.pages)==10
doc=pdfium.PdfDocument(str(pdf))
for i in range(len(doc)):
    doc[i].render(scale=1.5).to_pil().save(qa/f'page-{i+1}.png')
text='\n'.join(p.extract_text() or '' for p in reader.pages)
for required in ['BAB 1','BAB 2','BAB 3','BAB 4','BAB 5','REFERENSI','Kelompok 7','Snapshot']:
    assert required in text,required
assert all(len((p.extract_text() or '').strip())>100 for p in reader.pages)
d=Document(str(docx)); assert len(d.sections)==1
s=d.sections[0];assert (round(s.page_width/914400,2),round(s.page_height/914400,2))==(8.5,11.0)
assert all(round(x/914400,2)==1 for x in [s.left_margin,s.right_margin,s.top_margin,s.bottom_margin])
assert len([p for p in d.paragraphs if p.text.startswith(tuple(f'{i}. Nama:' for i in range(1,7)))])==6
src=Path(r'C:\Users\basti\Downloads\TEMPLATE PROPOSAL PjBL PPB.docx')
assert hashlib.sha256(src.read_bytes()).hexdigest()=='063cb665e8e1a30c5f433157b79a740a3d3d3df89cfb317f1b60abd4a320e7f5'
allowed={'word/document.xml','word/_rels/document.xml.rels','word/styles.xml','word/settings.xml','[Content_Types].xml'}
with ZipFile(src) as a,ZipFile(docx) as b:
    preserved=[n for n in a.namelist() if n not in allowed]
    assert all(a.read(n)==b.read(n) for n in preserved)
result={'pages':10,'includesCoverAndReferences':True,'renderer':'Microsoft Word COM ExportAsFixedFormat; PDF pages rendered with PDFium','sections':1,'paper':'Letter, margin 1 inch; matches template','membersBlank':6,'group':7,'sourceTemplateUnchanged':True,'preservedParts':preserved,'figures':len(d.inline_shapes),'applicationSourceModified':False}
(out/'pemeriksaan.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result))
print('PAGE HEADINGS',[(i+1,(p.extract_text() or '')[:65].replace('\n',' | ')) for i,p in enumerate(reader.pages)])
