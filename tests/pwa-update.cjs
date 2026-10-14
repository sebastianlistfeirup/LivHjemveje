/* Exercise the exported worker against a fresh HTTP cache and an open old game. */
const {chromium}=require(process.env.PLAYWRIGHT_PATH||'playwright');
const fs=require('node:fs');const http=require('node:http');const assert=require('node:assert/strict');
(async()=>{
 const worker=fs.readFileSync('builds/web/sw.js','utf8');
 const current=worker.match(/const CACHE='([^']+)'/)[1];
 const previous='liv-hjemveje-test-previous';
 const eventually=async check=>{
  for(let attempt=0;attempt<100;attempt++){
   if(await check())return;
   await new Promise(resolve=>setTimeout(resolve,100));
  }
  assert.fail('Service worker did not complete its transition');
 };
 let version=1;
 const server=http.createServer((req,res)=>{
  const path=new URL(req.url,'http://localhost').pathname;
  if(process.env.DEBUG_PWA)console.log('HTTP',version,path);
  res.setHeader('Cache-Control',path==='/sw.js'?'no-cache':'public, max-age=3600');
  if(path==='/sw.js'){
   res.setHeader('Content-Type','application/javascript');
   res.end(version===1?worker.replace(current,previous):worker);
  }else if(path==='/'||path==='/index.html'){
   res.setHeader('Content-Type','text/html');
   res.end(`<body>Game version ${version}<script>navigator.serviceWorker.register('sw.js')</script></body>`);
  }else{
   // Small stand-ins isolate the real worker's update protocol from rendering.
   res.setHeader('Content-Type','application/octet-stream');res.end(`version ${version}: ${path}`);
  }
 });
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const url=`http://127.0.0.1:${server.address().port}/`;
 const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox']});
 try{
  const context=await browser.newContext();let page=await context.newPage();
  await page.goto(url);await page.waitForFunction(()=>navigator.serviceWorker.controller);
  await page.evaluate(()=>localStorage.setItem('liv-hjemveje-v1','saved garden'));
  assert.equal(await page.evaluate(async key=>(await (await caches.open(key)).match('index.pck')).text(),previous),'version 1: /index.pck');
  version=2;
  await page.evaluate(async()=>{await (await navigator.serviceWorker.getRegistration()).update();});
  await eventually(()=>page.evaluate(async()=> (await navigator.serviceWorker.getRegistration()).waiting?.state==='installed'));
  if(process.env.DEBUG_PWA)console.log(await page.evaluate(async()=>Promise.all((await caches.keys()).map(async key=>[key,(await (await caches.open(key)).keys()).map(r=>r.url)]))));
  assert.equal(await page.evaluate(async key=>(await (await caches.open(key)).match('index.pck')).text(),current),'version 2: /index.pck','New worker must bypass fresh HTTP cache');
  assert.equal(await page.evaluate(async()=>(await fetch('index.pck')).text()),'version 1: /index.pck','Open old game keeps its consistent old assets');
  await page.close();page=await context.newPage();await page.goto(url);
  await eventually(()=>page.evaluate(async()=>navigator.serviceWorker.controller&&!(await navigator.serviceWorker.getRegistration()).waiting));
  assert.equal(await page.evaluate(async()=>(await fetch('index.pck')).text()),'version 2: /index.pck');
  assert.equal(await page.evaluate(()=>localStorage.getItem('liv-hjemveje-v1')),'saved garden');
  await context.setOffline(true);await page.reload();
  assert.match(await page.textContent('body'),/Game version 2/);
  assert.equal(await page.evaluate(()=>localStorage.getItem('liv-hjemveje-v1')),'saved garden');
  console.log('PASS PWA update: fresh assets despite HTTP cache · old game stays consistent · saved garden survives · new version works offline');
  await context.close();
 }finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
})().catch(error=>{console.error(error);process.exit(1)});
