from pathlib import Path
import struct,json,math,hashlib
p=Path('art_source/hideout_idle');data=(p/'idle_loop.vrma').read_bytes();n=struct.unpack_from('<I',data,12)[0];g=json.loads(data[20:20+n]);buf=data[28+n:]
def accessor(i):
 a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];dim={'SCALAR':1,'VEC3':3,'VEC4':4}[a['type']];assert a['componentType']==5126
 offset=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',4*dim)
 return [struct.unpack_from('<'+'f'*dim,buf,offset+j*stride) for j in range(a['count'])]
def mul(a,b):
 x,y,z,w=a;X,Y,Z,W=b;return [w*X+x*W+y*Z-z*Y,w*Y-x*Z+y*W+z*X,w*Z+x*Y-y*X+z*W,w*W-x*X-y*Y-z*Z]
def slerp(a,b,t):
 d=sum(x*y for x,y in zip(a,b))
 if d<0:b=[-v for v in b];d=-d
 d=min(1,d)
 if d>.9995:r=[x+(y-x)*t for x,y in zip(a,b)];n=math.sqrt(sum(v*v for v in r));return [v/n for v in r]
 th=math.acos(d);return [(math.sin((1-t)*th)*x+math.sin(t*th)*y)/math.sin(th) for x,y in zip(a,b)]
parents={c:i for i,x in enumerate(g['nodes']) for c in x.get('children',[])};tracks={};duration=0
for ch in g['animations'][0]['channels']:
 if ch['target']['path']!='rotation':continue
 sp=g['animations'][0]['samplers'][ch['sampler']];assert sp.get('interpolation','LINEAR')=='LINEAR'
 ts=[v[0] for v in accessor(sp['input'])];vs=accessor(sp['output']);tracks[ch['target']['node']]=(ts,vs);duration=max(duration,ts[-1])
import bisect
bones=g['extensions']['VRMC_vrm_animation']['humanoid']['humanBones'];frames=[]
for f in range(round(duration*30)+1):
 t=min(f/30,duration);local={};glob={}
 for i,node in enumerate(g['nodes']):
  q=node.get('rotation',[0,0,0,1])
  if i in tracks:
   ts,vs=tracks[i];k=max(0,min(bisect.bisect_right(ts,t)-1,len(ts)-2));q=slerp(vs[k],vs[k+1],max(0,min(1,(t-ts[k])/(ts[k+1]-ts[k]))))
  local[i]=q
 def world(i):
  if i not in glob:glob[i]=mul(world(parents[i]),local[i]) if i in parents else local[i]
  return glob[i]
 frames.append({name:world(x['node']) for name,x in bones.items()})
out=Path('assets/animations/pixiv_idle');out.mkdir(exist_ok=True)
(out/'idle.json').write_text(json.dumps({'fps':30,'duration':duration,'frames':frames},separators=(',',':')))
(out/'LICENSE').write_bytes((p/'LICENSE').read_bytes())
print(duration,len(frames),'frames',len(bones),'bones')
