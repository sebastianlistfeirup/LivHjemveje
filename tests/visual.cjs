const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright');const fs=require('fs');const assert=require('node:assert/strict');
(async()=>{
const browser=await chromium.launch({headless:true,executablePath:'/usr/bin/chromium',args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-dev-shm-usage']});
const save=JSON.parse(fs.readFileSync('test-results/BB-complete.json'));save.data.settings.text_scale=1;save.data.settings.reduced_motion=false;
for(const [w,h] of [[1440,900],[390,844],[768,1024],[812,375],[320,568]]){
 const context=await browser.newContext({viewport:{width:w,height:h},deviceScaleFactor:1});
 await context.addInitScript(s=>{localStorage.setItem('liv-hjemveje-v1',JSON.stringify(s));},save);
 const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
 await page.goto(process.env.GAME_URL||'http://127.0.0.1:8765',{waitUntil:'networkidle'});await page.waitForFunction(()=>window.__livQA?.screen==='title',null,{timeout:60000});
 const click=async text=>{let b=(await page.evaluate(()=>__livQA.buttons)).find(b=>b.text.includes(text));assert(b,'Button '+text);await page.mouse.click(b.rect[0]+b.rect[2]/2,b.rect[1]+b.rect[3]/2);await page.waitForTimeout(500);};
 await page.screenshot({path:`test-results/visual-${w}x${h}-title.png`});await click('Fortsæt');await page.screenshot({path:`test-results/visual-${w}x${h}-farm.png`});
 await click('Leg i Mos');await page.screenshot({path:`test-results/visual-${w}x${h}-garden.png`});
 assert.equal((await page.evaluate(()=>__livQA)).screen,'garden');assert.deepEqual(errors,[]);console.log('PASS visual '+w+'x'+h);
 await context.close();
}
await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
