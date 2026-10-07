"""Synthetic local buffering regressions; no SSH or Windows connections."""
import importlib.util
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
def module(name, file):
    spec = importlib.util.spec_from_file_location(name, file)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value
k = module('fof_kb_pull', ROOT / 'scripts/termux/fof_kb_pull.py')
h = module('ssh_smoke', ROOT / 'scripts/termux/test_kb_pull_ssh_smoke.py')


class BufferingTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(dir=Path.home(), prefix='kb-buffering-')
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        source = self.base / 'source'; (source / 'docs').mkdir(parents=True)
        (source / 'docs/a.md').write_bytes(b'synthetic text')
        (source / 'docs/b.bin').write_bytes(bytes(range(256)) * 1024)
        self.profile = {'protocol': k.PROTOCOL, 'profile_id': 'kb-pull-synthetic-1',
            'enabled': True, 'source_repository_id': 'Python-R-Scripts', 'files': [
                {'source_path': 'docs/a.md', 'staging_path': 'kb/a.md',
                 'classification': 'DISTRIBUTABLE_AS_IS', 'approval_reference': 'synthetic'},
                {'source_path': 'docs/b.bin', 'staging_path': 'kb/b.bin',
                 'classification': 'DISTRIBUTABLE_AS_IS', 'approval_reference': 'synthetic'}]}
        self.profile_path = self.base / 'profile.json'
        self.profile_path.write_bytes(k.canonical(self.profile))
        batches = self.base / 'batches'; batches.mkdir(mode=0o700)
        self.staging = self.base / 'staging'; self.staging.mkdir(mode=0o700)
        self.evidence = self.base / 'evidence'; self.evidence.mkdir(mode=0o700)
        with patch.object(k, 'provenance', return_value={
                'head': 'a'*40, 'repository_id': 'Python-R-Scripts'}):
            self.manifest = k.preview(source, self.profile_path, batches, True)
            batch = batches / self.manifest['batch_id']
            k.approve(batch, self.manifest['content_digest'])
            self.wire = k.archive_bytes(batch, self.manifest['content_digest'])
        self.ident = '20261007T160000Z-' + 'b'*32

    def observe(self, stream, path, count, approved=None):
        return h.observe_wire(stream, path, count, k, self.profile,
            approved or self.manifest['content_digest'], self.manifest['batch_id'])

    def test_real_buffered_file_reproduces_bug_and_flush_exposes_exact_prefix(self):
        path = self.base / 'wire.tar'
        prefix = self.wire[:32768]
        with path.open('xb', buffering=131072) as stream:
            stream.write(prefix)
            # Actual buffered I/O, rather than a mocked disk-size mismatch.
            self.assertEqual(path.stat().st_size, 0)
            state = self.observe(stream, path, len(prefix))
            self.assertEqual(path.read_bytes(), prefix)
            self.assertEqual(state['received_bytes'], state['wire_bytes'])
            self.assertTrue(state['flush_performed'])
            self.assertEqual(state['durability'], 'NOT_PROVEN')
            self.assertGreater(state['payload_received_bytes'], 0)
            self.assertLess(state['payload_received_bytes'], state['payload_expected_bytes'])
            self.assertEqual(state['approved_wire_expected_bytes'], len(self.wire))

    def test_wrong_approved_manifest_rejected(self):
        path = self.base / 'wire.tar'
        with path.open('xb', buffering=131072) as stream:
            stream.write(self.wire[:32768])
            with self.assertRaises(k.Reject):
                self.observe(stream, path, 32768, 'f'*64)

    def test_flush_failure_never_claims_observation(self):
        class FailingStream:
            def flush(self):
                raise OSError('synthetic flush failure')
        with patch.object(k, 'read', side_effect=AssertionError('must not read after flush failure')):
            with self.assertRaisesRegex(OSError, 'flush failure'):
                self.observe(FailingStream(), self.base / 'absent-wire.tar', 32768)

    def test_worker_flushes_receiver_stream_and_preserves_failed_run(self):
        original_open = Path.open
        original_popen = subprocess.Popen
        children = []
        producer_wire = self.base / 'producer-wire.tar'
        producer_wire.write_bytes(self.wire[:131072])
        def local_transport(*args, **kwargs):
            code = 'from pathlib import Path;import sys,time;sys.stdout.buffer.write(Path(' + repr(str(producer_wire)) + ').read_bytes());sys.stdout.buffer.flush();time.sleep(30)'
            child = original_popen([sys.executable, '-c', code], **kwargs)
            children.append(child)
            return child
        target = self.staging / self.ident / 'wire.tar'
        def buffered_open(path, *args, **kwargs):
            if path == target and args and args[0] == 'xb':
                kwargs['buffering'] = 131072
            return original_open(path, *args, **kwargs)
        h.record(self.evidence / 'interrupt-request.json', {'expected_wire_bytes': len(self.wire)})
        argv = ['harness', '--interrupt-worker', '--profile', str(self.profile_path),
            '--batch-id', self.manifest['batch_id'], '--digest', self.manifest['content_digest'],
            '--staging-root', str(self.staging), '--evidence-root', str(self.evidence),
            '--reviewed-delivered-both-ends']
        with patch.dict(sys.modules, {'fof_kb_pull': k}), patch.object(sys, 'argv', argv), \
                patch.dict(os.environ, {'FOF_SMOKE_RUN_ID': self.ident,
                    'FOF_KB_SSH_ALIAS': 'synthetic-local',
                    'FOF_KB_REMOTE_SCRIPT': 'C:/Synthetic/scripts/termux/fof_kb_pull.py',
                    'FOF_KB_REMOTE_BATCH_ROOT': 'C:/Synthetic/batches'}), \
                patch.object(Path, 'open', buffered_open), \
                patch.object(subprocess, 'Popen', side_effect=local_transport), \
                patch.object(signal, 'raise_signal', side_effect=KeyboardInterrupt) as cut:
            with self.assertRaises(KeyboardInterrupt):
                h.main()
            cut.assert_called_once_with(signal.SIGINT)
        import json
        decision = json.loads((self.evidence / 'interrupt-decision.json').read_text())
        self.assertTrue(decision['proven_in_progress'])
        self.assertTrue(decision['ssh_live_at_interrupt_request'])
        self.assertEqual(decision['wire_bytes'], decision['received_bytes'])
        self.assertTrue(decision['flush_performed'])
        self.assertEqual(target.read_bytes(), self.wire[:decision['received_bytes']])
        self.assertFalse((target.parent / 'VERIFIED.json').exists())
        self.assertFalse(json.loads((target.parent / 'UNVERIFIED.json').read_text())['automatic_retry'])
        self.assertTrue(json.loads((self.evidence / 'interrupt-cleanup.json').read_text())['ssh_stopped'])
        self.assertEqual(len(children), 1)
        self.assertIsNotNone(children[0].poll())


if __name__ == '__main__':
    unittest.main()
