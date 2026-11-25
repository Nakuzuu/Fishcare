const {chromium}=require('C:/Users/basti/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs'),path=require('path');
(async()=>{
 const out=path.resolve(__dirname,'../../output/desain');fs.mkdirSync(path.join(out,'png'),{recursive:true});
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:1200},deviceScaleFactor:2});
 await page.goto('file:///'+path.join(__dirname,'index.html').replaceAll('\\','/'));
 const list=await page.evaluate(()=>screens.map((s,i)=>({id:s.id,title:s.title,group:s.group,fr:s.fr,index:i+1})));
 await page.addStyleTag({content:'.phone.export{height:auto!important;max-height:none!important;min-height:830px!important;flex-shrink:0}.phone.export .content{overflow:visible!important;flex:none!important;padding-bottom:24px}.phone.export .nav{margin-top:auto}.skeleton{animation:none!important}'});
 for(const s of list){
  await page.selectOption('#picker',s.id);
  await page.locator('#phone').evaluate(el=>el.classList.add('export'));
  s.filename=`${String(s.index).padStart(2,'0')}-${s.id}.png`;
  await page.locator('#phone').screenshot({path:path.join(out,'png',s.filename)});
 }
 fs.writeFileSync(path.join(out,'daftar-layar.json'),JSON.stringify(list,null,2));
 fs.copyFileSync(path.join(__dirname,'empat-menu-utama.png'),path.join(out,'FishCare-Empat-Menu-Utama.png'));
 console.log(`PNG berhasil: ${list.length} layar lengkap + ikhtisar empat menu`);await browser.close();
})().catch(e=>{console.error(e);process.exitCode=1});
