/* Real touch input while rotating a phone/iPad during a puzzle and in the garden. */
const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright');
const fs=require('node:fs');const assert=require('node:assert/strict');
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-dev-shm-usage']});
 try{
  for(const [width,height,dpr] of [[568,320,2],[844,390,3],[1180,820,2]]){
   if(process.env.ONLY_WIDTH&&width!==Number(process.env.ONLY_WIDTH))continue;
   console.log(`START ${width}x${height} DPR ${dpr}`);
   const context=await browser.newContext({viewport:{width,height},hasTouch:true,isMobile:true,deviceScaleFactor:dpr});
   const page=await context.newPage();const errors=[];
   page.on('pageerror',error=>errors.push(error.message));page.on('console',message=>{if(message.type()==='error')errors.push(message.text());});
   const q=()=>page.evaluate(()=>__livQA);
   const wait=(fn,arg)=>page.waitForFunction(fn,arg,{timeout:15000});
   const fresh=async()=>{await page.evaluate(()=>{window.__previousQA=window.__livQA;});await wait(()=>__livQA!==window.__previousQA);};
   const tap=async rect=>{
    const viewport=page.viewportSize();
    assert(rect[0]>=0&&rect[1]>=0&&rect[0]+rect[2]<=viewport.width+1&&rect[1]+rect[3]<=viewport.height+1,'Touch target must fit the screen: '+rect);
    assert(rect[2]>=48&&rect[3]>=48,'Touch target must remain finger-sized');
    await page.touchscreen.tap(rect[0]+rect[2]/2,rect[1]+rect[3]/2);await fresh();
   };
   const button=async label=>{const item=(await q()).buttons.find(b=>b.text.includes(label));assert(item,label);await tap(item.rect);};
   const action=async id=>{const item=(await q()).actions.find(a=>a.id===id);assert(item,id);await tap(item.rect);};
   const distinctButtons=async()=>{
    const items=(await q()).buttons.filter(button=>button.text);
    for(let i=0;i<items.length;i++)for(let j=i+1;j<items.length;j++){
     const a=items[i].rect,b=items[j].rect;
     assert(!(a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1]),`Buttons overlap: ${items[i].text} / ${items[j].text}`);
    }
   };
   const rotate=async(w,h)=>{
    await page.setViewportSize({width:w,height:h});
    await wait(([w,h])=>__livQA.size[0]===w&&__livQA.size[1]===h,[w,h]);
    assert.equal((await q()).portrait,h>=w);
   };
   const read=async()=>{for(let i=0;i<3;i++){await button(i===2?'Se, hvad':'Læs videre');await wait(n=>__livQA.progress.read===n,i+1);}};
   await page.goto(process.env.GAME_URL||'http://127.0.0.1:8766',{waitUntil:'networkidle'});
   await wait(()=>window.__livQA?.screen==='title');assert.equal((await q()).portrait,false);
   const manifest=await page.evaluate(async()=> (await fetch('manifest.webmanifest')).json());assert.equal(manifest.orientation,'any');
   await page.screenshot({path:`test-results/orientation-${width}-title.png`});
   await button('Begynd');await read();await distinctButtons();await action('ring_1');
   await wait(()=>__livQA.progress.stages['0'].done.includes('ring_1'));
   await rotate(height,width);assert.deepEqual((await q()).progress.stages['0'].done,['ring_1']);
   await action('ring_2');await wait(()=>__livQA.progress.stages['0'].done.length===2);
   await rotate(width,height);await action('ring_3');await wait(()=>__livQA.progress.stage===1);
   await action('lift');await wait(()=>__livQA.progress.solved);await button('Videre');await read();
   for(let i=0;i<2;i++)await action('dial');await wait(()=>__livQA.progress.solved);
   await button('Videre');await read();await action('rope');
   await wait(()=>__livQA.progress.stages['0'].selected==='rope');await rotate(height,width);
   assert.equal((await q()).progress.stages['0'].selected,'rope');await action('bag');
   await wait(()=>__livQA.progress.stages['0'].done.includes('rope'));await rotate(width,height);
   await page.screenshot({path:`test-results/orientation-${width}-puzzle.png`});
   for(const item of ['spoon','lantern']){await action(item);await action('bag');await wait(id=>__livQA.progress.stages['0'].done.includes(id),item);}
   assert((await q()).progress.solved);
   console.log(`PASS ${width}x${height}: landscape story, compass, placement and selected object across rotation`);
   const save=JSON.parse(fs.readFileSync('test-results/BB-complete.json'));
   save.data.mode='MINIGAME';save.data.minigames.G01={...save.data.minigames.G01,level:2,plots:{},pipes:[0,0,0],grown:false};
   await page.evaluate(save=>localStorage.setItem('liv-hjemveje-v1',JSON.stringify(save)),save);
   await page.reload({waitUntil:'networkidle'});await wait(()=>window.__livQA?.screen==='title');await button('Fortsæt');await wait(()=>__livQA.screen==='garden');
   for(const i of (width===568?Array.from({length:16},(_,i)=>i):[0,3,5,10,12,15])){
    const seed=i%3;await action('seed_'+seed);await action('cell_'+i);
    await wait(([i,seed])=>__livQA.state.minigames.G01.plots[String(i)]===seed,[i,seed]);
   }
   const planted=(await q()).state.minigames.G01.plots;
   await rotate(height,width);assert.deepEqual((await q()).state.minigames.G01.plots,planted);
   await action('grow');await wait(()=>__livQA.state.minigames.G01.grown);await rotate(width,height);
   await distinctButtons();
   await page.screenshot({path:`test-results/orientation-${width}-garden.png`});
   assert((await q()).state.minigames.G01.grown);
   await page.reload({waitUntil:'networkidle'});await wait(()=>window.__livQA?.screen==='title');await button('Fortsæt');
   assert.deepEqual((await q()).state.minigames.G01.plots,planted);assert((await q()).state.minigames.G01.grown);
   assert.deepEqual(errors,[]);console.log(`PASS ${width}x${height} ↔ ${height}x${width}: garden input, growth, rotation and reload preserve the saved game`);
   await context.close();
  }
 }finally{await browser.close();}
})().catch(error=>{console.error(error);process.exit(1)});
