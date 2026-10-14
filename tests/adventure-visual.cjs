const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright');
const fs=require('node:fs');
const assert=require('node:assert/strict');
const source=JSON.parse(fs.readFileSync('content/runtime/chapter_01.json'));
const extra=JSON.parse(fs.readFileSync('content/runtime/adventure_01.json'));
const content=Object.fromEntries([...source.chapter.pages.map(p=>({...p,...extra.patches[p.id]})),...extra.extra].map(p=>[p.id,p]));
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:'/usr/bin/chromium',args:['--no-sandbox','--enable-unsafe-swiftshader','--use-angle=swiftshader','--disable-dev-shm-usage']});
 try {
 for(const [width,height,dpr] of [[1180,820,1],[844,390,2],[390,844,2],[568,320,1],[820,1180,1]]){
  if(process.env.ONLY_WIDTH&&width!==+process.env.ONLY_WIDTH)continue;
  const context=await browser.newContext({viewport:{width,height},deviceScaleFactor:dpr,hasTouch:true,isMobile:true,serviceWorkers:'block'});
  const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
  await page.goto('http://127.0.0.1:8766',{waitUntil:'networkidle'});
  const ready=()=>page.waitForFunction(()=>window.__livQA?.screen==='title',null,{timeout:45000});await ready();
  const tap=async text=>{const q=await page.evaluate(()=>__livQA);const b=q.buttons.find(x=>x.text.includes(text));assert(b,text);await page.touchscreen.tap(b.rect[0]+b.rect[2]/2,b.rect[1]+b.rect[3]/2);};
  for(const [id,action] of [['K01_S51',true],['K01_S01',false],['K01_S03',true],['K01_S04',true],['K01_S06',true],['K01_S45',true],['K01_S52',true],['K01_S44',true],['K01_S47',true],['K01_S53',true]]){
   if(process.env.ONLY_SCENE&&id!==process.env.ONLY_SCENE)continue;
   if(process.env.SCENES&&!process.env.SCENES.split(',').includes(id))continue;
   const save=JSON.parse(fs.readFileSync(`test-results/checkpoints/${id}.json`));save.data.node_progress[id].read=action?content[id].dialogue.length+1:0;save.data.settings.text_scale=+(process.env.TEXT_SCALE||1);
   await page.evaluate(save=>localStorage.setItem('liv-hjemveje-v1',JSON.stringify(save)),save);await page.reload({waitUntil:'networkidle'});await ready();await tap('Fortsæt');
   await page.waitForFunction(id=>__livQA.screen==='story'&&__livQA.node===id,id,{timeout:15000});await page.waitForTimeout(1500);
   await page.screenshot({path:`test-results/new-${width}-${id}.png`});console.log('SHOT',width,id);
  }
  if(errors.length)throw Error(errors.join('\n'));await context.close();
 }
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
