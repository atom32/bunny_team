import urllib.request,json,pathlib,hashlib
base=pathlib.Path(__file__).parent
project=base/'project'; project.mkdir(exist_ok=True)
opener=urllib.request.build_opener(urllib.request.ProxyHandler({'https':'http://127.0.0.1:7897'}))
manifest=[]
for asset in ['steel_frame_shelves_01','metal_tool_chest']:
 try:
  info=json.load(opener.open('https://api.polyhaven.com/files/'+asset,timeout=60))
  entry=info['gltf']['1k']['gltf']; folder=project/'polyhaven'/asset; folder.mkdir(parents=True,exist_ok=True)
  files={asset+'.gltf':entry,**entry['include']}
  for name,f in files.items():
   dest=folder/name;dest.parent.mkdir(parents=True,exist_ok=True)
   data=opener.open(f['url'],timeout=120).read()
   assert hashlib.md5(data).hexdigest()==f['md5']
   dest.write_bytes(data); manifest.append({'path':str(dest.relative_to(base)),'url':f['url'],'sha256':hashlib.sha256(data).hexdigest()})
  print('DOWNLOADED',asset,flush=True)
 except Exception as e: print('FAILED',asset,str(e),flush=True); raise
(base/'polyhaven_sources.json').write_text(json.dumps(manifest,indent=2))
