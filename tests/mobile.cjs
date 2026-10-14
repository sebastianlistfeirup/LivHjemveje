/* Small-phone controls, all sixteen garden cells, home-screen help and offline resume. */
const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright');
const fs=require('node:fs');const assert=require('node:assert/strict');
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-dev-shm-usage']});
 const original=JSON.parse(fs.readFileSync('test-results/BB-complete.json'));
 for(const [width,height,dpr] of [[320,568,2],[812,375,3],[390,844,3]]){
  const context=await browser.newContext({viewport:{width,height},hasTouch:true,isMobile:true,deviceScaleFactor:dpr});
  await context.addInitScript(save=>{if(!localStorage.getItem('liv-hjemveje-v1'))localStorage.setItem('liv-hjemveje-v1',JSON.stringify(save));},original);
  const page=await context.newPage();const errors=[];
  page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  await page.goto(process.env.GAME_URL||'http://127.0.0.1:8765',{waitUntil:'networkidle'});
  await page.waitForFunction(()=>window.__livQA?.screen==='title',null,{timeout:60000});
  const state=()=>page.evaluate(()=>__livQA);
  assert.deepEqual((await state()).size,[width,height],'Game controls use CSS dimensions at every pixel density');
  const tap=async r=>{
   await page.touchscreen.tap(r[0]+r[2]/2,r[1]+r[3]/2);
   // Wait for rendered game frames, not a fixed delay: software rendering at
   // Retina density can take longer than 300 ms under concurrent test load.
   for(let frame=0;frame<2;frame++){
    await page.evaluate(()=>{window.__livPreviousSnapshot=window.__livQA;});
    await page.waitForFunction(()=>window.__livQA!==window.__livPreviousSnapshot,null,{timeout:10000});
   }
  };
  const button=async(text,index=0)=>{
   for(let i=0;i<8;i++){
    const b=(await state()).buttons.filter(b=>b.text===text||b.text.includes(text))[index];assert(b,'Missing '+text);
    if(b.rect[1]+b.rect[3]/2>height-32){await page.mouse.move(width/2,height/2);await page.mouse.wheel(0,190);await page.waitForTimeout(300);continue;}
    await tap(b.rect);return;
   }
   assert.fail('Cannot reveal '+text);
  };
  const action=async id=>{const a=(await state()).actions.find(a=>a.id===id);assert(a,id);assert(a.rect[2]>=48&&a.rect[3]>=48);await tap(a.rect);};
  await button('Fortsæt');await button('Leg i Mos');await button('Gem blomsterne');await button('Vis bed',2);await button('×');
  assert.equal((await state()).state.minigames.G01.level,2);
  for(let i=0;i<16;i++){
   const seed=(i+1)%3;await action('seed_'+seed);await action('cell_'+i);
   try{await page.waitForFunction(([cell,kind])=>__livQA.state.minigames.G01.plots[String(cell)]===kind,[i,seed],{timeout:5000});}
   catch(error){await page.screenshot({path:`test-results/mobile-${width}x${height}-failed-${i}.png`});throw error;}
   assert.equal((await state()).state.minigames.G01.plots[String(i)],seed,'Touch must reach cell '+i);
  }
  await action('pipe_0');await action('pipe_0');await action('grow');
  assert((await state()).state.minigames.G01.grown);
  if(width===390){
   await page.setViewportSize({width:844,height:390});
   await page.waitForFunction(()=>__livQA.size[0]===844&&__livQA.size[1]===390);
   await action('grow');assert((await state()).state.minigames.G01.grown);
   await page.setViewportSize({width,height});
   await page.waitForFunction(()=>__livQA.size[0]===390&&__livQA.size[1]===844);
  }
  await page.screenshot({path:`test-results/mobile-${width}x${height}-16-cells.png`});
  await button('☰');await button('Føj spillet');await page.locator('#install-help').waitFor({state:'visible'});await page.locator('#install-close').click();await button('×');
  await page.waitForFunction(()=>!!navigator.serviceWorker?.controller,null,{timeout:60000});
  const before=(await state()).state.minigames.G01;
  await context.setOffline(true);await page.reload({waitUntil:'networkidle'});
  await page.waitForFunction(()=>window.__livQA?.screen==='title',null,{timeout:60000});await button('Fortsæt');
  assert.equal((await state()).screen,'garden');assert.deepEqual((await state()).state.minigames.G01,before);
  assert.deepEqual(errors,[]);console.log(`PASS ${width}x${height} DPR ${dpr}: sixteen touch cells, pipes, grow, home-screen help, complete offline reload and saved garden`);
  await context.close();
 }
 await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
