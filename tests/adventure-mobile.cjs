/* Rotation, zoom, large text and every garden cell through real mobile input. */
const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright');
const fs=require('node:fs'),assert=require('node:assert/strict');
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:'/usr/bin/chromium',args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-dev-shm-usage']});
 try{
 for(const [w,h,dpr] of [[390,844,3],[820,1180,2],[568,320,1]]){
  if(process.env.ONLY_WIDTH&&w!==+process.env.ONLY_WIDTH)continue;
  const context=await browser.newContext({viewport:{width:w,height:h},deviceScaleFactor:dpr,hasTouch:true,isMobile:true,serviceWorkers:'block'}),page=await context.newPage(),errors=[];
  page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  const q=()=>page.evaluate(()=>__livQA);
  const ready=()=>page.waitForFunction(()=>window.__livQA?.screen==='title',null,{timeout:90000});
  const frame=async()=>{await page.evaluate(()=>{window.__lastQA=__livQA;});await page.waitForFunction(()=>__livQA!==window.__lastQA,null,{timeout:20000});};
  const tap=async r=>{await page.touchscreen.tap(r[0]+r[2]/2,r[1]+r[3]/2);await frame();await frame();};
  const button=async text=>{for(let i=0;i<8;i++){const s=await q(),b=s.buttons.find(x=>x.text.includes(text));assert(b,text);const {height,width}=page.viewportSize();if(b.rect[1]+b.rect[3]/2>height-28){await page.mouse.move(width/2,height/2);await page.mouse.wheel(0,160);await frame();continue;}await tap(b.rect);return;}throw Error(text+' offscreen');};
  const action=async id=>{const s=await q(),a=s.actions.find(x=>x.id===id);assert(a,`${id} at ${s.node}`);await tap(a.rect);};
  const fixture=async(id,{scale=1,read=9}={})=>{const save=JSON.parse(fs.readFileSync(`test-results/checkpoints/${id}.json`));const n=save.data.node_progress[id];n.read=Math.min(read,id==='K01_S51'?1:id==='K01_S03'?4:id==='K01_S52'?3:4);save.data.settings.text_scale=scale;await page.evaluate(s=>localStorage.setItem('liv-hjemveje-v1',JSON.stringify(s)),save);await page.reload({waitUntil:'networkidle'});await ready();await button('Fortsæt');};
  const rotate=async()=>{const v=page.viewportSize();await page.setViewportSize({width:v.height,height:v.width});await page.waitForFunction(([w,h])=>__livQA.size[0]===w&&__livQA.size[1]===h,[v.height,v.width]);await frame();};
  await page.goto('http://127.0.0.1:8766',{waitUntil:'networkidle'});await ready();assert.deepEqual((await q()).size,[w,h]);
  await fixture('K01_S03');await action('piece_0');await rotate();assert.equal((await q()).progress.stages['0'].selected,'piece_0');await action('slot_0');assert((await q()).progress.stages['0'].done.includes('piece_0'));await rotate();
  await page.reload({waitUntil:'networkidle'});await ready();await button('Fortsæt');assert((await q()).progress.stages['0'].done.includes('piece_0'),'Rotation and reload preserve a joined piece');
  await fixture('K01_S52');await action('spoon');await action('turn');await rotate();assert.equal((await q()).progress.stages['0'].turn,1);await action('cell_0');assert((await q()).progress.stages['0'].done.includes('spoon'));await rotate();
  await fixture('K01_S47');await action('lens');assert((await q()).view.lens);const before=(await q()).progress.stages['0'].done.length;await action('seal');assert((await q()).progress.stages['0'].done.length>before);await page.screenshot({path:`test-results/mobile-${w}-magnifier.png`});
  const savedBeforeBook=await page.evaluate(()=>localStorage.getItem('liv-hjemveje-v1'));await button('Dagbog');await button('Åbn dragebogen');assert.equal((await q()).modal,'dragon_book');await page.waitForFunction(()=>__livQA.library.word>0);
  for(let spread=0;spread<3;spread++){assert.equal((await q()).library.spread,spread);await action('turn');}assert.equal((await q()).modal,'');assert.equal(await page.evaluate(()=>localStorage.getItem('liv-hjemveje-v1')),savedBeforeBook,'Library reading preserves the adventure');
  await fixture('K01_S51',{scale:1.5});await page.screenshot({path:`test-results/mobile-${w}-book-large.png`});await action('turn');assert.equal((await q()).progress.stages['0'].done.length,1);await rotate();await action('turn');assert.equal((await q()).progress.stages['0'].done.length,2);await rotate();
  const complete=JSON.parse(fs.readFileSync('test-results/BB-complete.json'));complete.data.mode='MINIGAME';complete.data.minigames.G01.level=2;complete.data.minigames.G01.plots={};complete.data.minigames.G01.grown=false;complete.data.minigames.G01.pipes=[1,2,3];
  await page.evaluate(s=>localStorage.setItem('liv-hjemveje-v1',JSON.stringify(s)),complete);await page.reload({waitUntil:'networkidle'});await ready();await button('Fortsæt');
  console.log('GARDEN',w,h,'sixteen cells');
  for(let i=0;i<16;i++){await action('seed_'+i%3);await action('cell_'+i);assert.equal((await q()).state.minigames.G01.plots[String(i)],i%3,`Cell ${i} receives its seed`);if(i===7)await rotate();}
  for(let i=0;i<3;i++)while((await q()).state.minigames.G01.pipes[i]%2!==0)await action('pipe_'+i);
  await action('grow');assert((await q()).state.minigames.G01.grown);await page.screenshot({path:`test-results/mobile-${w}-garden.png`});
  await button('Farm');await page.screenshot({path:`test-results/mobile-${w}-farm.png`});await action('mos');
  assert.deepEqual(errors,[]);console.log('PASS mobile',w,h,'DPR',dpr,'rotation, jigsaw save, packing rotation, magnifier, 150% book, sixteen garden cells');await context.close();
 }
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
