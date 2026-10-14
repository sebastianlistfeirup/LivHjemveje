/* Real pointer input through the debug export; __livQA is read-only. */
const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright');
const fs=require('node:fs');const assert=require('node:assert/strict');
const pages=JSON.parse(fs.readFileSync('content/runtime/chapter_01.json')).chapter.pages;
const source=Object.fromEntries(pages.map(p=>[p.id,p]));
const route=process.env.ROUTE||'BB';const mobile=process.env.MOBILE==='1';
(async()=>{
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-dev-shm-usage']});
const context=await browser.newContext({viewport:mobile?{width:390,height:844}:{width:1440,height:900},deviceScaleFactor:mobile?3:1,hasTouch:mobile,isMobile:mobile,acceptDownloads:true});
const page=await context.newPage();const errors=[];
page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error'&&!m.text().includes('favicon')){errors.push(m.text());console.log('CONSOLE',m.text())}});
await page.goto(process.env.GAME_URL||'http://127.0.0.1:8765',{waitUntil:'networkidle'});
await page.waitForFunction(()=>window.__livQA?.buttons?.length>0,null,{timeout:60000});
const q=()=>page.evaluate(()=>__livQA);
const pause=()=>page.waitForTimeout(280);
const clickRect=async r=>{if(mobile)await page.touchscreen.tap(r[0]+r[2]/2,r[1]+r[3]/2);else await page.mouse.click(r[0]+r[2]/2,r[1]+r[3]/2);await pause();};
const button=async text=>{
 for(let attempt=0;attempt<10;attempt++){
  const state=await q();const b=state.buttons.find(x=>x.text.includes(text));assert(b,'Missing button '+text);
  const center=b.rect[1]+b.rect[3]/2;const h=page.viewportSize().height;
  if(center>h-32||center<0){await page.mouse.move(page.viewportSize().width/2,h/2);await page.mouse.wheel(0,center<0?-180:180);await pause();continue;}
  await clickRect(b.rect);return;
 }
 assert.fail('Cannot reveal button '+text);
};
const action=async id=>{const state=await q();const a=state.actions.find(x=>x.id===id);assert(a,'Missing action '+id+' in '+state.node);assert(a.rect[2]>=47&&a.rect[3]>=47,'Hit target too small '+id);await clickRect(a.rect);};
const shot=async name=>page.screenshot({path:'test-results/'+route+'-'+(mobile?'mobile':'desktop')+'-'+name+'.png'});
await shot('title');await button('Begynd');await shot('reading');
let visited=[];let safe=0;let interrupted=false;let dragged=false;
while((await q()).screen==='story'&&safe++<450){
 const state=await q();if(!visited.includes(state.node)){visited.push(state.node);console.log('SCENE',state.node,visited.length)}
 const node=source[state.node],p=state.progress;
 if(p.solved){if(['K01_S32','K01_S35','K01_S40'].includes(state.node))await shot(state.node+'-solved');await button(node.page===40?'Hjem til':'Videre');continue;}
 if(p.read<3){await button(p.read===2?'Se, hvad':'Læs videre');continue;}
 const c=node.runtime.stages[p.stage],sp=p.stages[String(p.stage)];
 if(state.node==='K01_S01'&&!interrupted&&sp?.done?.length===2){
   await page.reload({waitUntil:'networkidle'});await page.waitForFunction(()=>window.__livQA?.screen==='title',null,{timeout:60000});await button('Fortsæt');const restored=await q();assert.equal(restored.progress.stages['0'].done.length,2);interrupted=true;console.log('PASS interruption after two rings');continue;
 }
 if(['K01_S07','K01_S11','K01_S15','K01_S21','K01_S35'].includes(state.node)&&sp?.done?.length===0)await shot(state.node+'-puzzle');
 if(c.kind==='choice'){
  let id=c.items[0].id;if(c.key==='k01_rute')id=route[0];if(c.key==='k01_redning')id=route[1];if(c.key==='k01_hjem')id=route[0]==='A'?'piledam':'moslund';await action(id);
 }else if(c.kind==='album')await action('K01_S17');
 else if(c.kind==='maze'){
   const solution=['I','E','F','B','C','G','H','D'];await action(solution[solution.indexOf(sp.position)+1]);
 }else if(c.kind==='difference'){
   // Comparing is an actual view change; all five frozen targets remain stable.
   await action('compare');await action(node.puzzle_spec.targets.find(t=>!sp.done.includes(t.id)).id);
 }else if(c.kind==='rotate'||c.kind==='pipes'){
   const i=sp.rotations.findIndex((v,i)=>v!==c.goal[i]);await action(c.items[i].id);
 }else if(c.kind==='place'){
   const item=c.items.find(x=>!x.decoy&&!sp.done.includes(x.id)&&(!x.requires||sp.done.includes(x.requires)));
   if(!mobile&&!dragged&&state.node==='K01_S03'){
    const from=state.actions.find(x=>x.id===item.id).rect,to=state.actions.find(x=>x.id===item.target).rect;
    await page.mouse.move(from[0]+from[2]/2,from[1]+from[3]/2);await page.mouse.down();await page.mouse.move(to[0]+to[2]/2,to[1]+to[3]/2,{steps:14});await page.mouse.up();await pause();dragged=true;assert((await q()).progress.stages['0'].done.includes(item.id),'Drag must place object');
   }else{await action(item.id);await action(item.target);}
 }else if(c.kind==='decorate'){
   await action(c.items.find(x=>!sp.done.includes(x.id)).id);await action('zone');
 }else{await action(c.items.find(x=>!x.decoy&&!sp.done.includes(x.id)).id);}
}
assert.equal((await q()).screen,'farm','Must reach farm');assert.equal(visited.length,36);assert(interrupted);await shot('welcome');await button('Bliv lidt');await shot('farm');
const final=await q();assert.equal(final.state.houses.house_01.gift,route[0]==='A'?'vindblad':'dugkop');assert.equal(final.state.houses.house_01.rescue,route[1]);
await action('mos');await action('house');await shot('house');await button('Moslund');await button('×');
await button('Leg i Mos');
for(let level=0;level<3;level++){
 for(let i=0;i<3;i++){await action('seed_'+i);await action('cell_'+i);}
 let g=(await q()).state.minigames.G01;
 for(let i=0;i<3;i++)while(g.pipes[i]!==0){await action('pipe_'+i);g=(await q()).state.minigames.G01;}
 await action('grow');assert((await q()).state.minigames.G01.grown);await shot('garden-'+level);await button('Gem blomsterne');await button('Gem i bed '+(level+1));
 if(level<2)await button('Prøv et større');else await button('Tilbage til farmen');
}
await action('album');await shot('album');await button('×');
// Settings, persistence of quiet mode and large text, and responsive resize.
await button('☰');await shot('settings');await button('150 %');
let state=await q();let toggles=state.buttons.filter(b=>b.text==='Fra');await clickRect(toggles[0].rect);await button('×');
await page.reload({waitUntil:'networkidle'});await page.waitForFunction(()=>window.__livQA?.screen==='title',null,{timeout:60000});await button('Fortsæt');state=await q();assert.equal(state.screen,'farm');assert.equal(state.state.settings.text_scale,1.5);assert(state.state.settings.reduced_motion);assert.equal(state.state.houses.house_01.gift,route[0]==='A'?'vindblad':'dugkop');await shot('reloaded-farm');
// Export creates a usable JSON download.
await button('☰');const dlPromise=page.waitForEvent('download');await button('Eksportér');const dl=await dlPromise;await dl.saveAs('test-results/'+route+'-export.json');assert.equal(JSON.parse(fs.readFileSync('test-results/'+route+'-export.json')).data.houses.house_01.built,true);
assert.deepEqual(errors,[],'No browser or Godot errors');
console.log('PASS browser route '+route+' '+(mobile?'390x844 touch':'1440x900 mouse')+' · 36 scenes · resume · farm · garden · settings · export');
await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
