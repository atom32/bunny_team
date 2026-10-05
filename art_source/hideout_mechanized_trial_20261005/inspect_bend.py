import json,struct,pathlib
p=pathlib.Path(r'D:/bunny_team/assets/environment/compact_hideout/pipes/modular_industrial_pipes_01_pipe04.glb');d=p.read_bytes();n=struct.unpack_from('<I',d,12)[0];j=json.loads(d[20:20+n]);pos=20+n;blen=struct.unpack_from('<I',d,pos)[0];b=d[pos+8:pos+8+blen]
print(j['nodes'])
def vals(i):
 a=j['accessors'][i];v=j['bufferViews'][a['bufferView']];off=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',12)
 return [struct.unpack_from('<fff',b,off+k*stride) for k in range(a['count'])]
for prim in j['meshes'][0]['primitives']:
 ps=vals(prim['attributes']['POSITION']);ns=vals(prim['attributes']['NORMAL'])
 for axis in range(3):
  for sign in [-1,1]:
   sel=[p for p,no in zip(ps,ns) if no[axis]*sign>.999]
   if sel:print(axis,sign,len(sel),'average',[sum(p[k] for p in sel)/len(sel) for k in range(3)],'bounds',[[min(p[k] for p in sel),max(p[k] for p in sel)] for k in range(3)])
