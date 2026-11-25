from pathlib import Path
from zipfile import ZipFile
from lxml import etree
from hashlib import sha256
import json
import pypdfium2 as pdfium
from docx import Document
p=Path(r'C:\Users\basti\Downloads\TEMPLATE PROPOSAL PjBL PPB.docx')
out=Path(__file__).parent
z=ZipFile(p); ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
for name in ['word/document.xml','word/styles.xml']:
 root=etree.fromstring(z.read(name))
 if name.endswith('styles.xml'):
  for el in root:
   if el.tag.endswith('docDefaults') or el.get('{'+ns['w']+'}styleId') in ['normal','Normal']:
    print(etree.tostring(el).decode())
 else:
  for i,el in enumerate(root.findall('.//w:body/w:p',ns)):
   text=''.join(el.xpath('.//w:t/text()',namespaces=ns))
   if i<7: print(i,text,etree.tostring(el.find('w:pPr',ns)))
inventory={n:{'size':len(z.read(n)),'sha256':sha256(z.read(n)).hexdigest()} for n in z.namelist()}
(out/'reference-parts.json').write_text(json.dumps(inventory,indent=2))
print('HASH',sha256(p.read_bytes()).hexdigest(),'MEMBERS',list(inventory))
doc=pdfium.PdfDocument(str(out/'template-reference.pdf'))
print('PAGES',len(doc))
for i in range(len(doc)):
 doc[i].render(scale=1.4).to_pil().save(out/f'template-{i+1}.png')
print('styles',[(s.name,s.font.name,s.font.size.pt if s.font.size else None) for s in Document(p).styles if s.name.lower()=='normal'])
