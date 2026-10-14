"""Offline regression for the client safety contract; performs NO API calls."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec=importlib.util.spec_from_file_location('pipeline',Path(__file__).with_name('tripo_pipeline.py'))
p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)

class FakeClient:
    def __init__(self, fail=False): self.calls=[];self.fail=fail
    def balance(self): return {'balance':1000,'frozen':0}
    def call(self,method,path,**kwargs):
        self.calls.append((method,path))
        if method=='POST':
            if self.fail: raise p.PipelineError('Simulated ambiguous transport error')
            return {'task_id':'task_test'}
        return {'task_id':'task_test','status':'success','progress':100,'credits_consumed':60,
                'output':{'model_url':'https://cdn.tripo3d.ai/model.glb?signature=test'}}

class Tests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.root_patch=patch.object(p,'ROOT',self.root);self.root_patch.start()
        self.run=self.root/'runs/v001';self.run.mkdir(parents=True)
        self.record={'steps':{}}
    def tearDown(self): self.root_patch.stop();self.temp.cleanup()
    def test_insufficient_budget_never_submits(self):
        client=FakeClient()
        with self.assertRaises(p.PipelineError):p.submit(client,self.run,self.record,'generate','/generation/multiview-to-model',{},60,59)
        self.assertFalse(client.calls)
    def test_one_multiview_task_and_resume(self):
        client=FakeClient();payload={'inputs':[{'front':'file_front'},{'back':'file_back'},{'right':'file_right'}]}
        p.submit(client,self.run,self.record,'generate','/generation/multiview-to-model',payload,60,150)
        p.submit(client,self.run,self.record,'generate','/generation/multiview-to-model',payload,60,150)
        self.assertEqual(sum(method=='POST' for method,path in client.calls),1)
        self.assertEqual(len(self.record['steps']['generate']['request']['inputs']),3)
    def test_ambiguous_post_not_retried(self):
        client=FakeClient(fail=True)
        for _ in range(2):
            with self.assertRaises(p.PipelineError):p.submit(client,self.run,self.record,'generate','/generation/multiview-to-model',{},60,150)
        self.assertEqual(len(client.calls),1)
        self.assertNotIn('task_id',self.record['steps']['generate'])
    def test_ledger_counts_all_runs(self):
        p.write_json(self.run/'record.json',{'steps':{'generate':{'estimated_credits':60}}})
        client=FakeClient();record={'steps':{}};run2=self.root/'runs/v002'
        with self.assertRaises(p.PipelineError):p.submit(client,run2,record,'generate','/generation/multiview-to-model',{},60,100)
        self.assertFalse(client.calls)
    def test_public_record_excludes_secrets_and_signed_queries(self):
        result=p.public_record({'api_key':'placeholder','output':{'model_url':'https://cdn.tripo3d.ai/a.glb?signature=sensitive'}})
        self.assertNotIn('api_key',result)
        self.assertEqual(result['output']['model_url'],'https://cdn.tripo3d.ai/a.glb')
    def test_http_error_does_not_log_credentials(self):
        class Response:
            ok=False;status_code=401
        with patch.object(p.requests,'request',return_value=Response()) as request:
            with self.assertRaises(p.PipelineError) as raised:p.Client('unit-test-placeholder').call('GET','/account/balance')
        self.assertNotIn('unit-test-placeholder',str(raised.exception))
        self.assertEqual(request.call_count,1)

if __name__=='__main__':unittest.main(verbosity=2)
