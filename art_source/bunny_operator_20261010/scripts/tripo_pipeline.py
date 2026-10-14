#!/usr/bin/env python3
"""One-character official Tripo v3 workflow. Credentials stay in env/Keychain.
No automatic POST retries: ambiguous submissions must be reconciled manually.
"""
import argparse
import getpass
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
from urllib.parse import urlsplit, urlunsplit
import requests

ROOT = Path(__file__).resolve().parents[1]
CONFIG = json.loads((ROOT/'config.json').read_text())
SERVICE = 'neon-bastion-tripo-api'

class PipelineError(RuntimeError): pass

def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix+'.tmp')
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2)+'\n')
    temporary.replace(path)

def credential():
    value = os.environ.get('TRIPO_API_KEY','').strip()
    if not value:
        result = subprocess.run(['/usr/bin/security','find-generic-password','-a',getpass.getuser(),
                                 '-s',SERVICE,'-w'], capture_output=True, text=True)
        if result.returncode == 0: value = result.stdout.strip()
    if not value:
        raise PipelineError('No TRIPO_API_KEY or configured keychain item. Run configure_keychain.py yourself.')
    return value

def public_record(value):
    if isinstance(value, dict): return {k:public_record(v) for k,v in value.items() if k.lower() not in {'authorization','api_key','secret'}}
    if isinstance(value,list): return [public_record(v) for v in value]
    if isinstance(value,str) and value.startswith('https://'):
        parsed=urlsplit(value)
        return urlunsplit((parsed.scheme,parsed.netloc,parsed.path,'',''))
    return value

class Client:
    def __init__(self, key): self.key=key
    def call(self, method, path, **kwargs):
        try:
            response=requests.request(method,CONFIG['api_base']+path,
                                      headers={'Authorization':'Bearer '+self.key},timeout=90,**kwargs)
            if not response.ok:
                raise PipelineError('Tripo HTTP '+str(response.status_code)+' at '+path)
            payload=response.json()
        except (requests.RequestException,ValueError) as exc:
            # Do not stringify requests/errors: they can include URLs or headers.
            raise PipelineError('Tripo transport/JSON error at '+path+'; no POST retry performed.') from None
        if payload.get('code') != 0:
            message=str(payload.get('message', 'API rejected request')).replace(self.key,'[REDACTED]')
            raise PipelineError('Tripo code '+str(payload.get('code'))+': '+message)
        return payload['data']
    def balance(self): return self.call('GET','/account/balance')
    def upload(self,path):
        with path.open('rb') as image:
            return self.call('POST','/files',files={'file':(path.name,image,'image/png')})['file_token']

def record_for(run):
    path=run/'record.json'
    return json.loads(path.read_text()) if path.exists() else {'api_version':'v3','steps':{},'reference_sha256':json.loads((ROOT/'reference/manifest.json').read_text())['source_sha256']}

def total_committed():
    total=0
    for path in (ROOT/'runs').glob('*/record.json'):
        for step in json.loads(path.read_text()).get('steps',{}).values():
            result=step.get('result',{})
            if result.get('status') in ['failed','cancelled']: total+=float(result.get('credits_consumed',0))
            else: total+=float(result.get('credits_consumed',step.get('estimated_credits',0)))
    return total

def submit(client,run,record,name,endpoint,payload,cost,budget):
    step=record['steps'].get(name)
    if step and not step.get('task_id'):
        raise PipelineError('An earlier submission has unknown outcome. Check official Usage before another POST.')
    if step is None:
        if budget is None or total_committed()+cost>budget:
            raise PipelineError('Explicit total credit budget required; requested operation exceeds budget.')
        balance=client.balance()
        if float(balance['balance'])<cost: raise PipelineError('Insufficient API credits; no purchase performed.')
        step={'endpoint':endpoint,'request':payload,'estimated_credits':cost,'submission_started':True}
        record['steps'][name]=step
        write_json(run/'record.json',record)
        created=client.call('POST',endpoint,json=payload)
        step['task_id']=created['task_id']
        write_json(run/'record.json',record)
    # Temporary back-reference only; never serialized.
    task_id=step['task_id']
    deadline=time.monotonic()+1200
    while time.monotonic()<deadline:
        data=client.call('GET','/tasks/'+task_id)
        step['result']=public_record(data)
        write_json(run/'record.json',record)
        print(task_id,data.get('status'),data.get('progress'),flush=True)
        if data['status']=='success': return data
        if data['status'] in ['failed','cancelled']: raise PipelineError('Task failed: '+str(data.get('error_code','unknown')))
        time.sleep(10)
    raise PipelineError('Polling deadline exceeded. Rerun with the same --run to resume, not resubmit.')

def download_model(data,path):
    url=data.get('output',{}).get('model_url')
    if not url: raise PipelineError('Success returned no documented model_url; inspect output field names.')
    if urlsplit(url).scheme!='https': raise PipelineError('Refusing a non-HTTPS result URL.')
    temporary=path.with_suffix('.download')
    # Never send the API Authorization header to the model CDN.
    with requests.get(url,stream=True,timeout=120) as response:
        response.raise_for_status()
        with temporary.open('wb') as stream:
            for chunk in response.iter_content(1024*1024): stream.write(chunk)
    with temporary.open('rb') as stream:
        if stream.read(4)!=b'glTF':
            temporary.unlink()
            raise PipelineError('Downloaded result is not a GLB; original task retained.')
    digest=hashlib.sha256(temporary.read_bytes()).hexdigest()
    if path.exists() and hashlib.sha256(path.read_bytes()).hexdigest()!=digest:
        temporary.unlink();raise PipelineError('Refusing to overwrite a different preserved raw result.')
    temporary.replace(path)
    write_json(path.with_suffix('.manifest.json'),{'task_id':data['task_id'],'sha256':digest,
               'bytes':path.stat().st_size,'credits_consumed':data.get('credits_consumed')})
    print('Downloaded',path.name,path.stat().st_size,'bytes')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('operation',choices=['balance','generate','rig-check','rig'])
    parser.add_argument('--run',default='v001')
    parser.add_argument('--max-credits',type=float,help='Human-approved total across all runs; required for new tasks')
    args=parser.parse_args()
    if not args.run.replace('-','').replace('_','').isalnum(): raise PipelineError('Invalid run name')
    client=Client(credential())
    if args.operation=='balance':
        print(json.dumps(client.balance()));return
    run=ROOT/'runs'/args.run;run.mkdir(parents=True,exist_ok=True);record=record_for(run)
    if args.operation=='generate':
        if 'generate' not in record['steps']:
            if args.max_credits is None or total_committed()+CONFIG['generation_estimated_credits']>args.max_credits:
                raise PipelineError('An explicit sufficient --max-credits is required before any upload.')
            uploads=record.setdefault('uploads',{})
            for view in CONFIG['reference_order']:
                if view not in uploads:
                    path=ROOT/'reference'/(view+'.png')
                    uploads[view]={'file_token':client.upload(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
                    write_json(run/'record.json',record)
            payload=dict(CONFIG['generation'],inputs=[{view:uploads[view]['file_token']} for view in CONFIG['reference_order']])
        else: payload=record['steps']['generate']['request']
        data=submit(client,run,record,'generate','/generation/multiview-to-model',payload,CONFIG['generation_estimated_credits'],args.max_credits)
        download_model(data,run/'source.glb')
    else:
        generation=record['steps'].get('generate',{})
        if generation.get('result',{}).get('status')!='success': raise PipelineError('Successful unified model required first.')
        if args.operation=='rig-check':
            data=submit(client,run,record,'rig-check','/animations/rig-check',{'input':generation['task_id']},0,args.max_credits)
            print(json.dumps(data.get('output',{})))
        else:
            result=record['steps'].get('rig-check',{}).get('result',{}).get('output',{})
            if result.get('riggable') is not True or result.get('rig_type')!='biped':
                raise PipelineError('Successful biped rig-check required before spending on rigging.')
            data=submit(client,run,record,'rig','/animations/rig',dict(CONFIG['rigging'],input=generation['task_id']),CONFIG['rigging_estimated_credits'],args.max_credits)
            download_model(data,run/'rigged_source.glb')

if __name__=='__main__':
    try: main()
    except (PipelineError,requests.RequestException) as error:
        # Requests exception text is intentionally excluded.
        print(str(error) if isinstance(error,PipelineError) else 'Result download transport error; task retained.',file=sys.stderr)
        raise SystemExit(1)
