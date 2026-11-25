from pathlib import Path
from pypdf import PdfReader
import pypdfium2 as pdfium
from PIL import Image,ImageDraw
import json
root=Path(__file__).parent
r=PdfReader(root/'proposal.pdf'); d=pdfium.PdfDocument(root/'proposal.pdf');out=root/'pages';out.mkdir(exist_ok=True)
texts=[]
for i,p in enumerate(r.pages):
    t=p.extract_text() or '';texts.append(t)
    d[i].render(scale=1.4).to_pil().save(out/f'page-{i+1}.png')
    print(i+1,len(t.split()),t[:70].replace('\n',' / '),'END:',t[-75:].replace('\n',' / '))
for start in range(0,len(d),6):
    sheet=Image.new('RGB',(1300,1800),'#dddddd');draw=ImageDraw.Draw(sheet)
    for j in range(start,min(start+6,len(d))):
        im=Image.open(out/f'page-{j+1}.png');im.thumbnail((620,550))
        x=(j-start)%2*650;y=(j-start)//2*600
        sheet.paste(im,(x,y+25));draw.text((x+15,y+5),f'PAGE {j+1}',fill='black')
    sheet.save(root/f'overview-{start//6+1}.png')
full='\n'.join(texts)
for token in ['BAB 1','BAB 2','BAB 3','BAB 4','BAB 5','5.2 Rencana Pengembangan Lanjutan','Gambar 3.7','2401020095','Marisha Pertiwi']:
    assert token in full,token
(root/'qa.json').write_text(json.dumps({'pages':len(d),'words':len(full.split()),'renderer':'Microsoft Word PDF and PDFium','checks':'headings, identities, figures present'},indent=2))
