/* Full chapter through real touch, drag and timing input. Debug diagnostics are read-only. */
const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright');
const fs=require('node:fs'),assert=require('node:assert/strict');
const original=JSON.parse(fs.readFileSync('content/runtime/chapter_01.json')).chapter.pages;
const extra=JSON.parse(fs.readFileSync('content/runtime/adventure_01.json'));
const pages=Object.fromEntries([...original.map(p=>{const x=extra.patches[p.id]||{};return {...p,...x,runtime:{...p.runtime,stages:[...(x.stages||p.runtime.stages),...(x.append_stages||[])]}}}),...extra.extra].map(p=>[p.id,p]));
const route=process.env.ROUTE||'AA';
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:'/usr/bin/chromium',args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-dev-shm-usage']});
 try{
 const width=+(process.env.WIDTH||1180),height=+(process.env.HEIGHT||820);
 const context=await browser.newContext({viewport:{width,height},deviceScaleFactor:+(process.env.DPR||1),hasTouch:true,isMobile:true,serviceWorkers:'block',acceptDownloads:true});
 const page=await context.newPage(),errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error'){errors.push(m.text());console.error('GAME',m.text());}});
 const cdp=await context.newCDPSession(page);
 const q=()=>page.evaluate(()=>__livQA);
 const delay=ms=>page.waitForTimeout(ms||260);
 const ready=()=>page.waitForFunction(()=>window.__livQA?.screen==='title',null,{timeout:60000});
 const tap=async r=>{await page.touchscreen.tap(r[0]+r[2]/2,r[1]+r[3]/2);await delay();};
 const button=async text=>{for(let i=0;i<8;i++){const s=await q(),b=s.buttons.find(x=>x.text.includes(text));assert(b,`Button ${text} at ${s.node}`);if(b.rect[1]+b.rect[3]>height-10||b.rect[1]<0){await page.mouse.move(width/2,height/2);await page.mouse.wheel(0,b.rect[1]<0?-150:150);await delay();continue;}await tap(b.rect);return;}throw Error('Offscreen '+text)};
 const advance=async()=>{const s=await q(),b=s.buttons.find(x=>/^(Vis hele|Læs videre|Udforsk|Videre|Hjem til)/.test(x.text));assert(b,'Reading control at '+s.node);await tap(b.rect);};
 const action=async id=>{const s=await q(),a=s.actions.find(x=>x.id===id);assert(a,`Action ${id} at ${s.node}, ${s.kind}`);await tap(a.rect);};
 const drag=async (from,to)=>{const a=from.rect||from,b=to.rect||to;const x=a[0]+a[2]/2,y=a[1]+a[3]/2,tx=b[0]+b[2]/2,ty=b[1]+b[3]/2;await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y}]});for(let i=1;i<=10;i++)await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:x+(tx-x)*i/10,y:y+(ty-y)*i/10}]});await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await delay();};
 const shot=async name=>page.screenshot({path:`test-results/play-${route}-${width}-${name}.png`});
 await page.goto(process.env.GAME_URL||'http://127.0.0.1:8766',{waitUntil:'networkidle'});await ready();
 if(process.env.START){const save=JSON.parse(fs.readFileSync(`test-results/checkpoints/${process.env.START}.json`));await page.evaluate(s=>localStorage.setItem('liv-hjemveje-v1',JSON.stringify(s)),save);await page.reload({waitUntil:'networkidle'});await ready();await button('Fortsæt');}else await button('Begynd');
 const visited=[],seen=new Set();let steps=0,reloaded=false,negative=false,touchHeld=false;
 while((await q()).screen==='story'&&steps++<1400){
  const s=await q(),node=pages[s.node],p=s.progress,c=node.runtime.stages[p.stage],sp=p.stages[String(p.stage)]||{done:[],selected:''};
  if(steps%35===0){fs.writeFileSync('test-results/live-play.json',JSON.stringify(s,null,2));console.log('PROGRESS',s.node,c.kind,JSON.stringify(sp),JSON.stringify(s.view));}
  if(!visited.includes(s.node)){visited.push(s.node);console.log('SCENE',s.node,visited.length);}
  if(errors.length)throw Error(errors.join('\n'));
  if(p.solved){if(s.node==='K01_S45'&&!seen.has('potion-done')){seen.add('potion-done');await delay(1500);await shot('potion-done');}if(touchHeld){await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});touchHeld=false;}await advance();continue;}
  if(!s.actions.length){await advance();continue;}
  if(!seen.has(s.node+':'+p.stage)){seen.add(s.node+':'+p.stage);await shot(s.node+'-'+p.stage);}
  if(c.kind==='book'){
   if(!reloaded){await delay(1800);assert((await q()).view.word>0,'Book words advance');await button('Pause');const word=(await q()).view.word;await delay(600);assert.equal((await q()).view.word,word);await page.reload({waitUntil:'networkidle'});await ready();await button('Fortsæt');reloaded=true;}
   await action('turn');
  }else if(c.kind==='journey'){await delay(1800);assert((await q()).view.age>1);await action('depart');}
  else if(c.kind==='packing'){
   const places={book:0,spoon:3,lantern:2,rope:8,bottle:10,lens:12};const id=c.items.find(x=>!sp.done.includes(x.id)).id;
   await drag(s.actions.find(x=>x.id===id),s.actions.find(x=>x.id==='cell_'+places[id]));
   await page.waitForFunction(({id,stage})=>__livQA.progress.solved||__livQA.progress.stages[String(stage)]?.done.includes(id),{id,stage:p.stage},{timeout:3000}).catch(async e=>{fs.writeFileSync('test-results/failed-packing.json',JSON.stringify(await q(),null,2));await shot('failed-packing');throw e;});
  }else if(c.kind==='jigsaw'){
   const i=Array.from({length:6},(_,i)=>i).find(i=>!sp.done.includes('piece_'+i));await drag(s.actions.find(x=>x.id==='piece_'+i),s.actions.find(x=>x.id==='slot_'+i));
   assert((await q()).progress.solved||(await q()).progress.stages[String(p.stage)].done.includes('piece_'+i),'Touch drag joins map');
  }else if(c.kind==='search'){
   if(!s.view.lens){await action('lens');continue;}
   const clue=c.items.find(x=>!sp.done.includes(x.id));const r=s.actions.find(x=>x.id===clue.id).rect;
   await drag([s.play_rect[0],s.play_rect[1],2,2],r);await shot(s.node+'-lens');if(!(await q()).progress.stages[String(p.stage)].done.includes(clue.id))await action(clue.id);
  }else if(c.kind==='keymatch'){
   if(!negative){for(const id of ['key_0','key_1','key_2']){await action(id);await action('test_key');}assert.equal((await q()).progress.stages['0'].attempts,3);await shot('keys-three-attempts');await action('reset_keys');negative=true;}
   await action(c.answer);await action('test_key');
  }else if(c.kind==='riddle'||c.kind==='truth'){
   if(!sp.wrong?.length){await action(c.items.find(x=>x.id!==c.answer).id);assert(!(await q()).progress.solved,'Wrong card retains challenge');}await action(c.answer);
  }else if(c.kind==='potion'){
   if(sp.done.length===3){await delay(1500);await shot('potion-stir');}const expected=c.recipe[sp.done.length];if(expected==='stir')await action('cauldron');else await drag(s.actions.find(x=>x.id===expected),s.actions.find(x=>x.id==='cauldron'));
  }else if(c.kind==='runes'){
   await page.waitForFunction(()=>__livQA.view.age>=__livQA.view.reveal_until,null,{timeout:60000});const current=(await q()).progress.stages[String(p.stage)];await action(c.sequences[current.round||0][current.index||0]);
  }else if(['lock','balance','aim'].includes(c.kind)){
   await page.waitForFunction(()=>__livQA.kind==='aim'?Math.hypot(__livQA.view.aim[0]-.5,__livQA.view.aim[1]-.5)<.07:Math.abs(__livQA.view.marker-.5)<.055,null,{timeout:30000});await action(c.kind==='aim'?'send':'stop');
  }else if(c.kind==='elements')await action({fire:'water',water:'stone',stone:'fire'}[c.opponents[sp.done.length]]);
  else if(c.kind==='labyrinth'){
   const at=sp.cell||0,paths=[[at]],seen=new Set([at]);let path;
   while(paths.length){const a=paths.shift(),v=a.at(-1);if(v===c.maze.goal){path=a;break;}for(const e of c.maze.edges){const n=e[0]===v?e[1]:e[1]===v?e[0]:-1;if(n>=0&&!seen.has(n)){seen.add(n);paths.push([...a,n]);}}}
   const diff=path[1]-at;await action(diff===1?'right':diff===-1?'left':diff===9?'down':'up');
  }else if(c.kind==='memory_map'){
   await page.waitForFunction(()=>__livQA.view.age>=__livQA.view.reveal_until,null,{timeout:30000});await action(c.route[(sp.steps||[]).length]);
  }else if(c.kind==='runner'){
   const t=sp.elapsed||0;let lane=sp.lane??1;
   for(const [time,l] of [[2,0],[5,2],[8,1],[11,0],[14,2]])if(time>t&&time<=t+1)lane=l;
   for(const [time,l] of [[3.5,1],[6.5,0],[9.5,2],[12.5,1]])if(time>t&&time<=t+.8&&lane===l)lane=(lane+1)%3;
   if(lane!==sp.lane)await action('lane_'+lane);else await delay(200);
  }else if(c.kind==='stealth'){
   const phase=((sp.elapsed||0)%5.2)/5.2;const hold=phase<.58;
   if(hold!==!!sp.held){const r=s.actions.find(x=>x.id==='hold').rect;if(hold)await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x:r[0]+r[2]/2,y:r[1]+r[3]/2}]});else await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});touchHeld=hold;}await delay(150);
  }else if(c.kind==='choice'){
   const id=c.key==='k01_rute'?route[0]:c.key==='k01_redning'?route[1]:c.key==='k01_hjem'?(route[0]==='A'?'piledam':'moslund'):c.items[0].id;await action(id);
  }else if(c.kind==='album')await action('K01_S17');
  else if(c.kind==='rotate'||c.kind==='pipes'){const i=sp.rotations.findIndex((v,i)=>v!==c.goal[i]);await action(c.items[i].id);}
  else if(c.kind==='place'){const item=c.items.find(x=>!x.decoy&&!sp.done.includes(x.id)&&(!x.requires||sp.done.includes(x.requires)));await drag(s.actions.find(x=>x.id===item.id),s.actions.find(x=>x.id===item.target));}
  else if(c.kind==='decorate'){await action(c.items.find(x=>!sp.done.includes(x.id)).id);await action('zone');}
  else if(c.kind==='difference'){await action('compare');await action(node.puzzle_spec.targets.find(t=>!sp.done.includes(t.id)).id);}
  else await action(c.items.find(x=>!x.decoy&&!sp.done.includes(x.id)).id);
 }
 assert.equal((await q()).screen,'farm','Reach the permanent farm');if(!process.env.START)assert.equal(visited.length,49);
 await button('Bliv lidt');await shot('farm');await action('mos');await button('Leg i haven');
 for(let level=0;level<3;level++){
  for(let i=0;i<3;i++){await action('seed_'+i);await action('cell_'+i);}
  for(let i=0;i<3;i++){while((await q()).state.minigames.G01.pipes[i]!==0)await action('pipe_'+i);}
  await action('grow');assert((await q()).state.minigames.G01.grown);await shot('garden-'+level);await button('Gem blomsterne');await button('Gem i bed '+(level+1));
  if(level<2)await button('Prøv et større');else await button('Tilbage til farmen');
 }
 await button('☰');const download=page.waitForEvent('download');await button('Eksportér');const dl=await download;await dl.saveAs(`test-results/${route}-adventure-export.json`);
 assert(JSON.parse(fs.readFileSync(`test-results/${route}-adventure-export.json`)).data.chapters.chapter_01.complete);
 assert.deepEqual(errors,[]);console.log('PASS adventure',route,visited.length,'scenes, actual touch drag, timing, save/resume, farm, 3 gardens, export, no errors');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
