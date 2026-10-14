from pathlib import Path
p=Path(__file__).resolve().parents[1]/'builds/web'
for name in ['index.html','index.js','index.pck','index.wasm','index.audio.worklet.js','index.audio.position.worklet.js','manifest.webmanifest','sw.js','app-icon.png']:
 assert (p/name).is_file(),f'Missing {name}'
html=(p/'index.html').read_text()
assert '$GODOT_' not in html,'Unexpanded Godot template'
assert 'lang="da"' in html
assert 'livExport' in html and 'livImport' in html
assert 'livInstall' in html and 'serviceWorker' in html
assert 'thread_support' not in html or 'true' not in html.split('thread_support')[1][:8]
print('Web export complete:',round(sum(x.stat().st_size for x in p.iterdir() if x.is_file())/1024**2,1),'MiB')
