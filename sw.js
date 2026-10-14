/* Generated: one complete, versioned game. Player saves are never cached here. */
const CACHE='liv-hjemveje-da45b7390ebc062e';
const FILES=["app-icon-192.png", "app-icon.png", "index.apple-touch-icon.png", "index.audio.position.worklet.js", "index.audio.worklet.js", "index.html", "index.icon.png", "index.js", "index.pck", "index.png", "index.wasm", "manifest.webmanifest"];
const base=new URL('./',self.location).href;
const urls=FILES.map(name=>new URL(name,base).href);
self.addEventListener('install',event=>event.waitUntil((async()=>{
  const cache=await caches.open(CACHE);
  await cache.addAll(urls);
  // A new game waits until all open windows close, so engine and art stay in sync.
})()));
self.addEventListener('activate',event=>event.waitUntil((async()=>{
  for(const key of await caches.keys())if(key.startsWith('liv-hjemveje-')&&key!==CACHE)await caches.delete(key);
  await self.clients.claim();
})()));
self.addEventListener('fetch',event=>{
  if(event.request.method!=='GET')return;
  const url=new URL(event.request.url);
  if(url.origin!==self.location.origin||!url.href.startsWith(base))return;
  const target=event.request.mode==='navigate'?new URL('index.html',base).href:url.href;
  if(!urls.includes(target))return;
  event.respondWith((async()=>{
    const cache=await caches.open(CACHE);
    return (await cache.match(target))||fetch(event.request);
  })());
});
