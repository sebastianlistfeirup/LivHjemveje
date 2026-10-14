"""Package the exported game for home-screen launch and complete offline play."""
from pathlib import Path
import hashlib
import json
import os
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
web = Path(sys.argv[1]).resolve() if len(sys.argv)>1 else root / 'builds/web'
subprocess.run([os.environ.get('GODOT_BIN', 'godot'), '--headless', '--script',
                'tools/export_icons.gd', '--', str(web)], cwd=root, check=True)
manifest = {
    'id': './', 'name': 'Liv og de ti hjemveje', 'short_name': 'Livs hjemveje',
    'description': 'Find kompasset, hjælp Mos hjem og skab din egen dragefarm.',
    'lang': 'da', 'start_url': './', 'scope': './',
    'display': 'standalone', 'orientation': 'portrait-primary',
    'background_color': '#0a1917', 'theme_color': '#102b25',
    'categories': ['games'],
    'icons': [{'src': 'app-icon-192.png', 'sizes': '192x192', 'type': 'image/png', 'purpose': 'any'},
              {'src': 'app-icon.png', 'sizes': '512x512', 'type': 'image/png', 'purpose': 'any'},
              {'src': 'app-icon.png', 'sizes': '512x512', 'type': 'image/png', 'purpose': 'maskable'}],
}
(web / 'manifest.webmanifest').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
files = sorted(p.name for p in web.iterdir() if p.is_file() and not p.name.startswith('.') and p.name != 'sw.js')
# Worker changes also get a separate cache; an installation must never mutate
# the cache used by an older game that is still open.
digest = hashlib.sha256(Path(__file__).read_bytes())
for name in files:
    digest.update(name.encode())
    digest.update((web / name).read_bytes())
version = digest.hexdigest()[:16]
worker = """/* Generated: one complete, versioned game. Player saves are never cached here. */
const CACHE='liv-hjemveje-VERSION';
const FILES=FILES_JSON;
const base=new URL('./',self.location).href;
const urls=FILES.map(name=>new URL(name,base).href);
self.addEventListener('install',event=>event.waitUntil((async()=>{
  const cache=await caches.open(CACHE);
  await cache.addAll(urls.map(url=>new Request(url,{cache:'reload'})));
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
""".replace('VERSION', version).replace('FILES_JSON', json.dumps(files))
(web / 'sw.js').write_text(worker)
print(f'Home-screen / offline game: {len(files)} files, version {version}')
