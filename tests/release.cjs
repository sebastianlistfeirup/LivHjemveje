/* Release-only black-box smoke test. Pointer positions recorded from the 390×844 layout. */
const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright');
const fs=require('node:fs');const assert=require('node:assert/strict');
(async()=>{
 const url=process.env.GAME_URL||'http://127.0.0.1:8765';
 const landscape=process.env.RELEASE_ORIENTATION==='landscape';
 const controlsFile=landscape?'tests/release-controls-landscape.json':'tests/release-controls.json';
 const launch={headless:true,executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-dev-shm-usage']};
 if(url.startsWith('https:')&&(process.env.HTTPS_PROXY||process.env.HTTP_PROXY)){
  const proxy=new URL(process.env.HTTPS_PROXY||process.env.HTTP_PROXY);
  launch.proxy={server:proxy.protocol+'//'+proxy.host,username:decodeURIComponent(proxy.username),password:decodeURIComponent(proxy.password)};
 }
 const profile=fs.mkdtempSync('/tmp/liv-release-');
 const context=await chromium.launchPersistentContext(profile,{...launch,viewport:landscape?{width:844,height:390}:{width:390,height:844},hasTouch:true,isMobile:true,deviceScaleFactor:3});
 const page=await context.newPage();const errors=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 await page.goto(url,{waitUntil:'networkidle',timeout:120000});
 await page.waitForFunction(()=>!document.getElementById('loading'),null,{timeout:120000});await page.waitForTimeout(800);
 const tap=async r=>{await page.touchscreen.tap(r[0]+r[2]/2,r[1]+r[3]/2);await page.waitForTimeout(350);};
 if(process.env.CAPTURE_CONTROLS==='1'){
  const q=()=>page.evaluate(()=>__livQA);const controls={};
  controls.begin=(await q()).buttons.find(b=>b.text.includes('Begynd')).rect;await tap(controls.begin);
  controls.read=[];
  for(let i=0;i<3;i++){const r=(await q()).buttons.find(b=>b.text.includes('Læs videre')||b.text.includes('Se, hvad')).rect;controls.read.push(r);await tap(r);}
  controls.rings=[1,2].map(i=>null);const state=await q();controls.rings=state.actions.filter(a=>['ring_1','ring_2'].includes(a.id)).map(a=>a.rect);
  fs.writeFileSync(controlsFile,JSON.stringify(controls,null,2)+'\n');console.log('Recorded touch controls for release check');
 }else{
  assert.equal(await page.evaluate(()=>typeof window.__livQA),'undefined','Release must not expose diagnostics');
  const c=JSON.parse(fs.readFileSync(controlsFile));
  await tap(c.begin);for(const rect of c.read)await tap(rect);for(const rect of c.rings)await tap(rect);
  const saved=await page.evaluate(()=>JSON.parse(localStorage.getItem('liv-hjemveje-v1')));
  assert(saved.data.started);assert.equal(saved.data.node_progress.K01_S01.stages['0'].done.length,2);
  await page.waitForFunction(()=>!!navigator.serviceWorker?.controller,null,{timeout:120000});
  const cdp=await context.newCDPSession(page);
  assert.equal(await page.evaluate(async()=> (await (await fetch('manifest.webmanifest')).json()).orientation),'any');
  const installability=await cdp.send('Page.getInstallabilityErrors');
  assert.deepEqual(installability.installabilityErrors,[],'Home-screen manifest must be installable');
  // iPhone Safari offers the home-screen route when document fullscreen is absent.
  await page.evaluate(()=>{document.documentElement.requestFullscreen=undefined;document.documentElement.webkitRequestFullscreen=undefined;window.livFullscreen();});
  await page.locator('#install-help').waitFor({state:'visible'});await page.locator('#install-close').click();
  await page.screenshot({path:'test-results/release-mobile.png'});
  await context.setOffline(true);await page.reload({waitUntil:'networkidle'});
  await page.waitForFunction(()=>!document.getElementById('loading'),null,{timeout:60000});await page.waitForTimeout(800);await tap(c.begin);
  const restored=await page.evaluate(()=>JSON.parse(localStorage.getItem('liv-hjemveje-v1')));
  assert.equal(restored.data.node_progress.K01_S01.stages['0'].done.length,2);
  assert.deepEqual(errors,[]);console.log('PASS release: no debug API · real touch input · partial-scene save · full offline restart · zero browser errors');
 }
 await context.close();fs.rmSync(profile,{recursive:true,force:true});
})().catch(e=>{console.error(e);process.exit(1)});
