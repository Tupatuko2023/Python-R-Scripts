"""Synthetic stdio and sender outcome tests; never contacts an SSH endpoint."""

import base64
import importlib.util
import json
import subprocess
import unittest
from pathlib import Path

import test_artifact_transfer as protocol

ADAPTER = Path(__file__).resolve().parents[1] / 'scripts/termux/fof_v2_ssh_adapter.py'
spec = importlib.util.spec_from_file_location('adapter', ADAPTER)
adapter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(adapter)

FAKE_SSH = r'''#!/usr/bin/env python3
import sys,os,json,tarfile,io
from pathlib import Path
root=Path(os.environ['TEST_ROOT']);mode=os.environ.get('ADAPTER_TEST_MODE','verified')
with (root/'ssh-calls').open('a') as f:f.write('1\n')
(root/'ssh-args.json').write_text(json.dumps(sys.argv[1:]))
if mode in ('unknown-host','connect-fail'):
 sys.stderr.write('synthetic SSH rejection\n');sys.exit(255)
wire=sys.stdin.buffer.read();(root/'wire.bin').write_bytes(wire)
sys.stderr.write('synthetic diagnostic noise\n')
if mode=='echo':sys.stdout.buffer.write(wire);sys.exit(0)
if mode in ('empty','late-disconnect'):sys.exit(255 if mode=='late-disconnect' else 0)
if mode=='malformed':sys.stdout.buffer.write(b'not-json\n');sys.exit(0)
if mode=='nonzero':sys.exit(42)
with tarfile.open(fileobj=io.BytesIO(wire)) as archive:m=json.load(archive.extractfile('manifest.json'))
r={k:m[k] for k in ('protocol_version','run_id','content_digest','run_correlation_digest')}
r['file_count']=len(m['files'])
if mode=='failed':r.update(status='FAILED',error_code='HASH_MISMATCH');code=1
else:r.update(status='VERIFIED',verified_at='2026-09-16T00:00:00Z');code=0
out=(json.dumps(r)+'\n').encode();(root/'response.bin').write_bytes(out)
sys.stdout.buffer.write(out);sys.exit(code)
'''


class AdapterTests(unittest.TestCase):
    save = protocol.SenderRuntimeTests.save
    preview = protocol.SenderRuntimeTests.preview
    run_sender = protocol.SenderRuntimeTests.run_sender

    def setUp(self):
        protocol.SenderRuntimeTests.setUp(self)
        self.env = {k: v for k, v in self.env.items() if not k.startswith('FOF_V2_')}
        self.env.update(FOF_V2_SSH_ALIAS='synthetic-host',
                        FOF_V2_RECEIVER_SCRIPT='C:/Synthetic Repo/scripts/receive_artifact_bundle.ps1')
        (self.bin / 'ssh').write_text(FAKE_SSH)
        (self.bin / 'ssh').chmod(0o700)

    def invoke(self, payload=b'\x00\xff\r\n', mode='echo', args=()):
        return subprocess.run([str(ADAPTER), *args], input=payload,
                              env=dict(self.env, ADAPTER_TEST_MODE=mode), capture_output=True, timeout=10)

    def test_binary_stdout_stderr_and_exact_ssh_flags(self):
        payload=bytes(range(256))*8192
        result=self.invoke(payload)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, payload)
        self.assertIn(b'diagnostic', result.stderr)
        args=json.loads((self.base/'ssh-args.json').read_text())
        for required in ['-T','BatchMode=yes','StrictHostKeyChecking=yes','ConnectionAttempts=1']:
            self.assertIn(required,args)
        script=base64.b64decode(args[-1].split()[-1]).decode('utf-16le')
        self.assertEqual(script, "& 'C:/Synthetic Repo/scripts/receive_artifact_bundle.ps1'; exit $LASTEXITCODE")
        self.assertEqual((self.base/'ssh-calls').read_text(), '1\n')

    def test_configuration_missing_rejected_before_ssh(self):
        for key in ['FOF_V2_SSH_ALIAS','FOF_V2_RECEIVER_SCRIPT']:
            env=dict(self.env)
            env.pop(key)
            p=subprocess.run([str(ADAPTER)],input=b'payload',env=env,capture_output=True)
            self.assertEqual(p.returncode,255)
            self.assertEqual(p.stdout,b'')
        self.assertFalse((self.base/'ssh-calls').exists())

    def test_invalid_configuration_does_not_consume_stdin(self):
        source = self.base / 'stdin-fixture.bin'
        source.write_bytes(b'untouched binary input')
        with source.open('rb') as stream:
            result = subprocess.run([str(ADAPTER)], stdin=stream, capture_output=True,
                                    env=dict(self.env, FOF_V2_SSH_ALIAS=''))
            self.assertEqual(result.returncode, 255)
            self.assertEqual(stream.tell(), 0)

    def test_receiver_json_and_malformed_stdout_remain_byte_identical(self):
        import io
        import tarfile
        manifest = json.loads(self.preview().stdout)
        payload = io.BytesIO()
        body = json.dumps(manifest).encode()
        with tarfile.open(fileobj=payload, mode='w', format=tarfile.USTAR_FORMAT) as archive:
            item = tarfile.TarInfo('manifest.json')
            item.size = len(body)
            archive.addfile(item, io.BytesIO(body))
        for mode, code in [('verified', 0), ('failed', 1)]:
            result = self.invoke(payload.getvalue(), mode=mode)
            self.assertEqual(result.returncode, code)
            self.assertEqual(result.stdout, (self.base / 'response.bin').read_bytes())
        result = self.invoke(mode='malformed')
        self.assertEqual(result.stdout, b'not-json\n')
        self.assertEqual(result.returncode, 0)

    def test_unsafe_configuration(self):
        cases={'FOF_V2_SSH_ALIAS':['-oProxyCommand=bad','user@host','host;evil','host\n'],
               'FOF_V2_RECEIVER_SCRIPT':['relative.ps1','C:/x/../scripts/receive_artifact_bundle.ps1',
                "C:/x';evil/scripts/receive_artifact_bundle.ps1",'C:/x$/scripts/receive_artifact_bundle.ps1',
                'C:/NUL/scripts/receive_artifact_bundle.ps1','C:/x./scripts/receive_artifact_bundle.ps1',
                'C:/x//scripts/receive_artifact_bundle.ps1','C:/x/scripts/other.ps1',
                'C:\\x\\scripts\\receive_artifact_bundle.ps1','//host/share/receiver.ps1'],
               'FOF_V2_SMOKE_SESSION':['../x','a'*31,'A'*32,'a'*32+';exit 0']}
        for key,values in cases.items():
            for value in values:
                with self.subTest(key=key,value=value):
                    with self.assertRaises(ValueError):
                        adapter.command(dict(self.env,**{key:value}))

    def test_smoke_route_explicit_and_default_production_invocation(self):
        script=base64.b64decode(adapter.command(dict(self.env,FOF_V2_SMOKE_SESSION='a'*32))[-1].split()[-1]).decode('utf-16le')
        self.assertIn("-SmokeTest -SmokeSession '"+'a'*32+"'",script)
        self.assertNotIn('-SmokeTest',base64.b64decode(adapter.command(self.env)[-1].split()[-1]).decode('utf-16le'))

    def test_check_never_consumes_payload_or_calls_receiver(self):
        result=self.invoke(b'not sent', args=['--check'])
        self.assertEqual(result.returncode,0)
        self.assertEqual((self.base/'wire.bin').read_bytes(),b'')
        script=base64.b64decode(json.loads((self.base/'ssh-args.json').read_text())[-1].split()[-1]).decode('utf-16le')
        self.assertIn('Test-Path',script)
        self.assertNotIn("& '",script)

    def test_unknown_host_connection_loss_nonzero_and_no_retry(self):
        for mode,code in [('unknown-host',255),('connect-fail',255),('late-disconnect',255),('nonzero',42)]:
            with self.subTest(mode=mode):
                before=len((self.base/'ssh-calls').read_text().splitlines()) if (self.base/'ssh-calls').exists() else 0
                p=self.invoke(mode=mode)
                self.assertEqual(p.returncode,code)
                self.assertEqual(p.stdout,b'')
                self.assertEqual(len((self.base/'ssh-calls').read_text().splitlines()),before+1)

    def test_sender_preview_never_invokes_adapter(self):
        self.preview()
        self.assertFalse((self.base/'ssh-calls').exists())

    def test_sender_end_to_end_outcomes_and_source_identity(self):
        digest=json.loads(self.preview().stdout)['content_digest']
        before={str(p):p.read_bytes() for p in self.root.rglob('*') if p.is_file()}
        for mode,code,outcome in [('verified',0,'SUCCESS'),('failed',1,'FAILED'),
                                  ('malformed',3,'UNKNOWN_REMOTE_STATE'),('empty',3,'UNKNOWN_REMOTE_STATE'),
                                  ('late-disconnect',3,'UNKNOWN_REMOTE_STATE'),('unknown-host',3,'UNKNOWN_REMOTE_STATE'),
                                  ('connect-fail',3,'UNKNOWN_REMOTE_STATE'),('nonzero',3,'UNKNOWN_REMOTE_STATE')]:
            with self.subTest(mode=mode):
                result=subprocess.run(['bash',str(self.sender),'--profile','config/test-profile.json',
                    '--execute','--approved-content-digest',digest,'--local-receiver',str(ADAPTER)],
                    env=dict(self.env,ADAPTER_TEST_MODE=mode),capture_output=True,timeout=15)
                self.assertEqual(result.returncode,code,result.stderr)
                self.assertIn(outcome.encode(),result.stdout if code==0 else result.stderr)
        self.assertEqual(before,{str(p):p.read_bytes() for p in self.root.rglob('*') if p.is_file()})
        self.assertEqual(len((self.base/'ssh-calls').read_text().splitlines()),8)

    def test_bad_approval_stops_before_network(self):
        result=subprocess.run(['bash',str(self.sender),'--profile','config/test-profile.json',
            '--execute','--approved-content-digest','0'*64,'--local-receiver',str(ADAPTER)],
            env=self.env,capture_output=True)
        self.assertEqual(result.returncode,1)
        self.assertFalse((self.base/'ssh-calls').exists())


if __name__=='__main__':
    unittest.main()
