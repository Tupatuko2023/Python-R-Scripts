"""Synthetic stdio and sender outcome tests; never contacts an SSH endpoint."""

import base64
import importlib.util
import json
import os
import shutil
import subprocess
import tempfile
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
if mode=='timeout':
 import time;time.sleep(65);sys.exit(0)
if mode=='oversized':
 sys.stdout.buffer.write(b'x'*(1048576+1));sys.exit(0)
with tarfile.open(fileobj=io.BytesIO(wire)) as archive:m=json.load(archive.extractfile('manifest.json'))
r={k:m[k] for k in ('protocol_version','run_id','content_digest','run_correlation_digest')}
r['file_count']=len(m['files'])
if mode=='failed':r.update(status='FAILED',error_code='HASH_MISMATCH');code=1
elif mode=='secretfailed':r.update(status='FAILED',error_code='SECRETMARKERABC',leak='SECRET_MARKER_v2_diag_test');code=1
elif mode=='knownfailed':r.update(status='FAILED',error_code='SNAPSHOT_PARITY_FAILURE');code=1
elif mode=='notcorrelated':r['content_digest']='0'*64;r.update(status='VERIFIED',verified_at='2026-09-16T00:00:00Z');code=0
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
                        FOF_V2_RECEIVER_SCRIPT='C:/Synthetic Repo/scripts/ps7/receive_artifact_bundle.ps1',
                        FOF_V2_STAGING_DIR='C:/Synthetic Staging',
                        FOF_V2_TRANSFER_ID='20260916T000000Z-' + 'a'*32)
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
        self.assertEqual(script, "& 'C:/Synthetic Repo/scripts/ps7/receive_artifact_bundle.ps1' -StagingDir 'C:/Synthetic Staging' -TransferId '20260916T000000Z-" + 'a'*32 + "'; exit $LASTEXITCODE")
        self.assertEqual((self.base/'ssh-calls').read_text(), '1\n')

    def test_configuration_missing_rejected_before_ssh(self):
        for key in ['FOF_V2_SSH_ALIAS','FOF_V2_RECEIVER_SCRIPT','FOF_V2_STAGING_DIR','FOF_V2_TRANSFER_ID']:
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
               'FOF_V2_RECEIVER_SCRIPT':['relative.ps1','C:/x/scripts/receive_artifact_bundle.ps1','C:/x/../scripts/ps7/receive_artifact_bundle.ps1',
                "C:/x';evil/scripts/ps7/receive_artifact_bundle.ps1",'C:/x$/scripts/ps7/receive_artifact_bundle.ps1',
                'C:/NUL/scripts/ps7/receive_artifact_bundle.ps1','C:/x./scripts/ps7/receive_artifact_bundle.ps1',
                'C:/x//scripts/ps7/receive_artifact_bundle.ps1','C:/x/scripts/ps7/other.ps1',
                'C:\\x\\scripts\\receive_artifact_bundle.ps1','//host/share/receiver.ps1'],
               'FOF_V2_STAGING_DIR':['','relative','C:/x/../y',"C:/x';y",'C:/x$','C:/NUL','C:/x.','C:/x/','C:/','C:','C:\\x','//host/share','C:/x//y'],
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

    def test_v2_staging_bound_explicitly_and_no_legacy_fallback(self):
        env=dict(self.env,FOF_V2_STAGING_DIR='C:/V2 Own Staging',WINDOWS_STAGING_DIR='C:/Legacy Shared')
        script=base64.b64decode(adapter.command(env)[-1].split()[-1]).decode('utf-16le')
        self.assertIn("-StagingDir 'C:/V2 Own Staging'",script)
        self.assertNotIn('Legacy',script)

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

    def _diag_base(self):
        base = Path(tempfile.mkdtemp(prefix='v2diag-', dir=str(Path(self.base).parent)))
        self.addCleanup(shutil.rmtree, base, True)
        return base

    def _diag_dir(self, name='v2diag'):
        root = self._diag_base() / name
        root.mkdir(mode=0o700)
        return root

    def _run_diag(self, mode, diag=None):
        diag = diag or self._diag_dir('v2diag')
        digest = json.loads(self.preview().stdout)['content_digest']
        result = subprocess.run(['bash', str(self.sender), '--profile', 'config/test-profile.json',
            '--execute', '--approved-content-digest', digest, '--local-receiver', str(ADAPTER)],
            env=dict(self.env, FOF_V2_DIAG_ROOT=str(diag), ADAPTER_TEST_MODE=mode),
            capture_output=True, timeout=120)
        return result, diag

    def _diag_records(self, diag):
        return [json.loads(p.read_text()) for p in sorted(diag.glob('*.json'))] if diag.exists() else []

    def test_diagnostic_correlated_failed(self):
        result, diag = self._run_diag('failed')
        self.assertEqual(result.returncode, 1)
        records = self._diag_records(diag)
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]['outcome'], 'FAILED')
        self.assertEqual(records[0]['response_class'], 'CORRELATED_FAILED')
        self.assertIsNone(records[0]['error_code'])
        self.assertEqual(records[0]['error_code_class'], 'UNKNOWN')
        self.assertEqual(records[0]['adapter_exit'], 1)
        self.assertFalse(records[0]['timed_out'])

    def test_diagnostic_known_code_recorded(self):
        result, diag = self._run_diag('knownfailed', self._diag_dir('diag-known'))
        self.assertEqual(result.returncode, 1)
        records = self._diag_records(diag)
        self.assertEqual(records[0]['error_code'], 'SNAPSHOT_PARITY_FAILURE')
        self.assertEqual(records[0]['error_code_class'], 'KNOWN')

    def test_diagnostic_invalid_json_and_non_correlated(self):
        for mode, cls in (('malformed', 'INVALID_JSON'), ('notcorrelated', 'NON_CORRELATED')):
            with self.subTest(mode=mode):
                result, diag = self._run_diag(mode, self._diag_dir('diag-' + mode))
                self.assertEqual(result.returncode, 3)
                records = self._diag_records(diag)
                self.assertEqual(len(records), 1)
                self.assertEqual(records[0]['outcome'], 'UNKNOWN_REMOTE_STATE')
                self.assertEqual(records[0]['response_class'], cls)

    def test_diagnostic_oversized(self):
        result, diag = self._run_diag('oversized')
        self.assertEqual(result.returncode, 3)
        records = self._diag_records(diag)
        self.assertEqual(records[0]['response_class'], 'OVERSIZED')
        self.assertGreater(records[0]['response_bytes'], 1048576)

    def test_diagnostic_timeout(self):
        result, diag = self._run_diag('timeout')
        self.assertEqual(result.returncode, 3)
        records = self._diag_records(diag)
        self.assertEqual(records[0]['response_class'], 'TIMEOUT')
        self.assertTrue(records[0]['timed_out'])
        self.assertIsNone(records[0]['adapter_exit'])

    def test_diagnostic_contains_no_response_content(self):
        result, diag = self._run_diag('secretfailed')
        self.assertEqual(result.returncode, 1)
        text = sorted(diag.glob('*.json'))[0].read_text()
        self.assertNotIn('SECRET_MARKER', text)
        self.assertNotIn('SECRETMARKER', text)
        self.assertNotIn('leak', text)
        record = json.loads(text)
        self.assertIsNone(record['error_code'])
        self.assertEqual(record['error_code_class'], 'UNKNOWN')

    def test_diagnostic_existing_target_not_overwritten(self):
        diag = self._diag_dir('v2diag-keep')
        self._run_diag('failed', diag)
        first = sorted(diag.glob('*.json'))
        self.assertEqual(len(first), 1)
        original = first[0].read_bytes()
        self._run_diag('failed', diag)
        self.assertEqual(len(sorted(diag.glob('*.json'))), 2)
        self.assertEqual(first[0].read_bytes(), original)

    def test_diagnostic_write_error_does_not_change_outcome(self):
        diag = self._diag_base() / 'v2diag-as-file'
        diag.write_text('not a directory')
        result, _ = self._run_diag('failed', diag)
        self.assertEqual(result.returncode, 1)
        self.assertIn(b'FAILED', result.stderr)
        self.assertTrue(diag.is_file())

    def _sender_module(self):
        source = self.sender.read_text().split("<<'PY'\n", 1)[1].rsplit("\nPY", 1)[0]
        namespace = {}
        exec(compile(source.rsplit("\ntry:\n    main()", 1)[0], str(self.sender), "exec"), namespace)
        return namespace

    def test_diagnostic_error_code_exact_list(self):
        mod = self._sender_module()
        known = mod['v2_diag_record']('r', 'FAILED', 1, False, 'CORRELATED_FAILED', 3,
                                      {'status': 'FAILED', 'error_code': 'SNAPSHOT_PARITY_FAILURE'})
        self.assertEqual(known['error_code'], 'SNAPSHOT_PARITY_FAILURE')
        self.assertEqual(known['error_code_class'], 'KNOWN')
        secret = mod['v2_diag_record']('r', 'UNKNOWN_REMOTE_STATE', 1, False, 'NON_CORRELATED', 3,
                                       {'status': 'FAILED', 'error_code': 'SECRET_MARKER_abc'})
        self.assertIsNone(secret['error_code'])
        self.assertEqual(secret['error_code_class'], 'UNKNOWN')
        self.assertNotIn('SECRET_MARKER', json.dumps(secret))

    def test_diagnostic_same_run_id_not_overwritten(self):
        mod = self._sender_module()
        diag = self._diag_dir('diag-det')
        run_id = '20261010T000000Z-' + 'a'*32
        target = diag / (run_id + '.json')
        target.write_bytes(b'ORIGINAL\n'); target.chmod(0o600)
        record = mod['v2_diag_record'](run_id, 'FAILED', 1, False, 'CORRELATED_FAILED', 3, None)
        self.assertFalse(mod['v2_diag_write'](str(diag), str(self.root), run_id, record))
        self.assertEqual(target.read_bytes(), b'ORIGINAL\n')

    def test_diagnostic_link_root_rejected(self):
        mod = self._sender_module()
        base = self._diag_base()
        real = base / 'diag-real'; real.mkdir(mode=0o700)
        link = base / 'diag-link'; link.symlink_to(real, target_is_directory=True)
        run_id = '20261010T000000Z-' + 'a'*32
        record = mod['v2_diag_record'](run_id, 'FAILED', 1, False, 'CORRELATED_FAILED', 0, None)
        self.assertFalse(mod['v2_diag_write'](str(link), str(self.root), run_id, record))
        self.assertEqual(list(real.glob('*.json')), [])

    def test_diagnostic_non_private_root_rejected(self):
        mod = self._sender_module()
        diag = self._diag_dir('diag-open'); diag.chmod(0o755)
        run_id = '20261010T000000Z-' + 'a'*32
        record = mod['v2_diag_record'](run_id, 'FAILED', 1, False, 'CORRELATED_FAILED', 0, None)
        self.assertFalse(mod['v2_diag_write'](str(diag), str(self.root), run_id, record))
        self.assertEqual(list(diag.glob('*.json')), [])

    def test_diagnostic_ancestor_swap_symlink_rejected(self):
        mod = self._sender_module()
        holder = self._diag_base() / 'diag-holder'; holder.mkdir(mode=0o700)
        (holder / 'mid').mkdir(mode=0o700)
        away = holder.parent / 'diag-away'; (away / 'mid' / 'diag').mkdir(parents=True, mode=0o700)
        (holder / 'mid').rmdir()
        (holder / 'mid').symlink_to(away / 'mid', target_is_directory=True)
        run_id = '20261010T000000Z-' + 'a'*32
        record = mod['v2_diag_record'](run_id, 'FAILED', 1, False, 'CORRELATED_FAILED', 0, None)
        self.assertFalse(mod['v2_diag_write'](str(holder / 'mid' / 'diag'), str(self.root), run_id, record))
        self.assertEqual(list((away / 'mid' / 'diag').glob('*.json')), [])

    def test_diagnostic_race_ancestor_swap_after_check(self):
        from unittest.mock import patch
        mod = self._sender_module()
        base = self._diag_base()
        holder = base / 'holder'; holder.mkdir(mode=0o700)
        diag = holder / 'diag'; diag.mkdir(mode=0o700)
        moved = base / 'holder-moved'
        away = base / 'away'; away.mkdir(mode=0o700)
        sentinel = away / 'existing.json'; sentinel.write_bytes(b'ORIGINAL\n')
        run_id = '20261010T000000Z-' + 'a'*32
        record = mod['v2_diag_record'](run_id, 'FAILED', 1, False, 'CORRELATED_FAILED', 0, None)
        real_lstat = os.lstat
        swapped = {'done': False}

        def swapping_lstat(path, *args, **kwargs):
            if not swapped['done'] and os.path.abspath(str(path)) == os.path.abspath(str(diag)):
                swapped['done'] = True
                os.rename(holder, moved)
                holder.symlink_to(away, target_is_directory=True)
                return real_lstat(str(moved / 'diag'))
            return real_lstat(path, *args, **kwargs)

        with patch.object(mod['os'], 'lstat', side_effect=swapping_lstat):
            written = mod['v2_diag_write'](str(diag), str(self.root), run_id, record)
        self.assertTrue(swapped['done'])
        self.assertTrue(written)
        self.assertTrue((moved / 'diag' / (run_id + '.json')).is_file())
        self.assertEqual(sentinel.read_bytes(), b'ORIGINAL\n')
        self.assertFalse((away / (run_id + '.json')).exists())

    def test_diagnostic_inside_repository_rejected(self):
        from unittest.mock import patch
        mod = self._sender_module()
        diag = self.base / 'diag-inside-repo'; diag.mkdir(mode=0o700)
        run_id = '20261010T000000Z-' + 'a'*32
        record = mod['v2_diag_record'](run_id, 'FAILED', 1, False, 'CORRELATED_FAILED', 0, None)
        with patch.dict(os.environ, {'PATH': str(self.bin) + os.pathsep + os.environ['PATH'],
                                     'TEST_ROOT': str(self.base), 'TEST_ORIGIN': 'https://example.invalid/Python-R-Scripts.git'}):
            self.assertFalse(mod['v2_diag_write'](str(diag), str(self.root), run_id, record))
        self.assertEqual(list(diag.glob('*.json')), [])


if __name__=='__main__':
    unittest.main()
