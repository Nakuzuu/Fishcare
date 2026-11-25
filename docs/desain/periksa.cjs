const { chromium } = require('C:/Users/basti/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const path = require('path');
const fs = require('fs');
(async()=>{
 const browser=await chromium.launch({channel:'chrome',headless:true});
 const page=await browser.newPage({viewport:{width:1280,height:1100},deviceScaleFactor:1});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('file:///'+path.join(__dirname,'index.html').replaceAll('\\','/'));
 const ids=await page.locator('#picker option').evaluateAll(es=>es.map(e=>e.value));
 const checks=[];
 for(const id of ids){
  await page.selectOption('#picker',id);
  const missing=await page.locator('#phone [data-to]').evaluateAll(es=>es.map(e=>e.dataset.to).filter(id=>!document.querySelector(`#picker option[value="${id}"]`)));
  const overflow=await page.locator('#phone .content').evaluate(e=>e.scrollWidth>e.clientWidth+1);
  checks.push({id,missing,overflow});
 }
 for(const id of ['home','pond','feed','report','location','keyboard']){
  await page.selectOption('#picker',id);
  await page.locator('#phone').screenshot({path:path.join(__dirname,`${id}.png`)});
 }
 await page.selectOption('#picker','home');
 await page.locator('#phone [data-to="feed"]').first().click();
 if(await page.inputValue('#picker')!=='feed')throw Error('Navigasi Beranda → Pakan gagal');
 await page.selectOption('#picker','deathdetail');
 const death=await page.locator('#phone').innerText();
 if(!death.includes('Salah menghitung ikan mati.')||death.includes('Harga jual')||death.includes('Bobot rata-rata snapshot'))throw Error('Detail kematian batal tidak sesuai');
 await page.selectOption('#picker','harvestdetail');
 if(!(await page.locator('#phone').innerText()).includes('Rp100.000'))throw Error('Snapshot panen tidak tampil');
 await page.setViewportSize({width:360,height:800});
 for(const id of ids){await page.selectOption('#picker',id);if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1))throw Error('Overflow viewport 360: '+id)}
 await page.selectOption('#picker','keyboard');
 const button=await page.locator('#phone .footer').boundingBox();const keyboard=await page.locator('#phone .keyboard').boundingBox();
 if(button.y+button.height>keyboard.y+1)throw Error('Tombol tertutup ilustrasi keyboard');
 await page.setViewportSize({width:1600,height:1100});
 await page.locator('#gallery').click();
 await page.screenshot({path:path.join(__dirname,'ikhtisar.png')});
 await page.evaluate(()=>{document.getElementById('board').innerHTML=['home','ponds','feed','report'].map(id=>{const s=screens.find(s=>s.id===id);return `<article><h3 class="caption">${s.title}</h3><section class="phone">${phone(s)}</section></article>`}).join('')});
 await page.locator('#board').screenshot({path:path.join(__dirname,'empat-menu-utama.png')});
 const result={date:'2026-10-15',method:'Playwright Chromium pada prototipe HTML lokal; bukan uji Flutter/HP',screens:ids.length,errors,checks,navigation:'lulus',canceledDeathDetail:'lulus',harvestSnapshotDetail:'lulus',viewport360:'lulus',keyboardIllustration:'lulus'};
 fs.writeFileSync(path.join(__dirname,'hasil-pemeriksaan.json'),JSON.stringify(result,null,2));
 console.log(JSON.stringify(result));await browser.close();
 if(errors.length||checks.some(c=>c.missing.length||c.overflow))process.exitCode=1;
})().catch(e=>{console.error(e);process.exitCode=1});
