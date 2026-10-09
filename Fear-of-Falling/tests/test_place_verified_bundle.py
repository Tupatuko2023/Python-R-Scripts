"""Synthetic PLACE/1 tests using self-generated files and a local synthetic repo."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/termux/place_verified_bundle.py'
spec = importlib.util.spec_from_file_location('place', SCRIPT)
p = importlib.util.module_from_spec(spec)
spec.loader.exec_module(p)

RUN_ID = '20261009T120000Z-' + 'a' * 32


def canon(obj):
    return p.canonical(obj)


class PlaceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.home(), prefix='place-synthetic-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)

        # synthetic verified reception (FOF_KB_PULL/1)
        self.run = self.base / 'staging' / RUN_ID
        (self.run / 'payload' / 'kb' / 'd').mkdir(parents=True)
        self.doc = b'# synthetic\n'
        self.bin = bytes(range(256)) * 4
        (self.run / 'payload' / 'kb' / 'd' / 'a.md').write_bytes(self.doc)
        (self.run / 'payload' / 'kb' / 'd' / 'b.bin').write_bytes(self.bin)
        files = [
            {'staging_path': 'kb/d/a.md', 'size': len(self.doc), 'sha256': p.sha(self.doc)},
            {'staging_path': 'kb/d/b.bin', 'size': len(self.bin), 'sha256': p.sha(self.bin)},
        ]
        manifest = {'protocol': 'FOF_KB_PULL/1', 'content_digest': 'c' * 64, 'files': files}
        (self.run / 'manifest.json').write_bytes(canon(manifest))
        receipt = {'protocol': 'FOF_KB_PULL/1', 'status': 'VERIFIED', 'run_id': RUN_ID,
                   'content_digest': 'c' * 64, 'file_count': 2,
                   'return_receipt_status': 'NOT_DELIVERED'}
        (self.run / 'VERIFIED.json').write_bytes(canon(receipt))
        self.verified_before = (self.run / 'VERIFIED.json').read_bytes()

        # synthetic target git repo
        self.target = self.base / 'target'
        self.target.mkdir()
        subprocess.run(['git', 'init', '-q', str(self.target)], check=True)
        subprocess.run(['git', '-C', str(self.target), 'config', 'user.email', 't@example.invalid'], check=True)
        subprocess.run(['git', '-C', str(self.target), 'config', 'user.name', 't'], check=True)
        subprocess.run(['git', '-C', str(self.target), 'remote', 'add', 'origin',
                        'https://example.invalid/Python-R-Scripts.git'], check=True)
        (self.target / 'README.md').write_text('x', encoding='utf-8')
        subprocess.run(['git', '-C', str(self.target), 'add', '.'], check=True)
        subprocess.run(['git', '-C', str(self.target), 'commit', '-qm', 'init'], check=True)

        self.map = self.base / 'map.json'
        self.map.write_bytes(canon({'map': [
            {'staging_path': 'kb/d/a.md', 'target_path': 'docs/a.md'},
            {'staging_path': 'kb/d/b.bin', 'target_path': 'docs/b.bin'}]}))

    def plan(self):
        return p.build_plan(self.run, self.target, self.map)

    def test_create_new_success(self):
        plan = self.plan()
        self.assertTrue(all(r['state'] == 'ABSENT' for r in plan['files']))
        receipt = p.execute(self.run, self.target, self.map, plan['placement_digest'],
                            self.base / 'receipt.json')
        self.assertEqual(receipt['status'], 'PLACED')
        self.assertEqual((self.target / 'docs/a.md').read_bytes(), self.doc)
        self.assertEqual((self.target / 'docs/b.bin').read_bytes(), self.bin)
        self.assertTrue(all(r['state'] == 'CREATED' for r in receipt['files']))
        self.assertEqual((self.run / 'VERIFIED.json').read_bytes(), self.verified_before)

    def test_already_present(self):
        (self.target / 'docs').mkdir()
        (self.target / 'docs/a.md').write_bytes(self.doc)
        plan = self.plan()
        state = {r['target_path']: r['state'] for r in plan['files']}
        self.assertEqual(state['docs/a.md'], 'ALREADY_PRESENT')
        receipt = p.execute(self.run, self.target, self.map, plan['placement_digest'],
                            self.base / 'receipt.json')
        self.assertEqual(receipt['status'], 'PLACED')

    def test_conflict_no_overwrite(self):
        (self.target / 'docs').mkdir()
        (self.target / 'docs/a.md').write_bytes(b'different')
        with self.assertRaises(p.Reject) as ctx:
            p.execute(self.run, self.target, self.map, self.plan()['placement_digest'],
                      self.base / 'receipt.json')
        self.assertEqual(str(ctx.exception), 'CONFLICT')
        self.assertEqual((self.target / 'docs/a.md').read_bytes(), b'different')

    def test_wrong_digest(self):
        with self.assertRaises(p.Reject) as ctx:
            p.execute(self.run, self.target, self.map, 'f' * 64, self.base / 'receipt.json')
        self.assertEqual(str(ctx.exception), 'APPROVAL_MISMATCH')

    def test_dangerous_target_path(self):
        bad = self.base / 'bad.json'
        bad.write_bytes(canon({'map': [
            {'staging_path': 'kb/d/a.md', 'target_path': '../escape.md'},
            {'staging_path': 'kb/d/b.bin', 'target_path': 'docs/b.bin'}]}))
        with self.assertRaises(p.Reject):
            p.build_plan(self.run, self.target, bad)

    def test_hard_denied_target(self):
        bad = self.base / 'bad2.json'
        bad.write_bytes(canon({'map': [
            {'staging_path': 'kb/d/a.md', 'target_path': 'data/a.md'},
            {'staging_path': 'kb/d/b.bin', 'target_path': 'docs/b.bin'}]}))
        with self.assertRaises(p.Reject):
            p.build_plan(self.run, self.target, bad)

    def test_changed_payload_detected(self):
        (self.run / 'payload' / 'kb' / 'd' / 'a.md').write_bytes(b'tampered')
        with self.assertRaises(p.Reject) as ctx:
            self.plan()
        self.assertEqual(str(ctx.exception), 'PAYLOAD_MISMATCH')

    def test_unsupported_reception_form_rejected(self):
        legacy = self.base / 'legacy' / RUN_ID
        shutil.copytree(self.run, legacy)
        m = json.loads((legacy / 'manifest.json').read_text())
        m['protocol'] = 'LEGACY/1'
        (legacy / 'manifest.json').write_bytes(canon(m))
        with self.assertRaises(p.Reject) as ctx:
            p.verify_staging(legacy)
        self.assertEqual(str(ctx.exception), 'UNSUPPORTED_RECEPTION_FORM')

    def test_missing_receipt_rejected(self):
        (self.run / 'VERIFIED.json').unlink()
        with self.assertRaises((p.Reject, OSError)):
            self.plan()

    def test_link_ancestor_rejected(self):
        link = self.base / 'linkroot'
        try:
            if os.name == 'nt':
                result = subprocess.run(['cmd', '/c', 'mklink', '/J', str(link), str(self.target)],
                                        capture_output=True)
                if result.returncode != 0:
                    self.skipTest('junction privilege unavailable')
            else:
                link.symlink_to(self.target, target_is_directory=True)
        except OSError:
            self.skipTest('link creation unsupported')
        with self.assertRaises((p.Reject, OSError)):
            p.build_plan(self.run, link, self.map)


    def test_duplicate_map_source_rejected(self):
        bad = self.base / 'dupmap.json'
        bad.write_bytes(canon({'map': [
            {'staging_path': 'kb/d/a.md', 'target_path': 'docs/a.md'},
            {'staging_path': 'kb/d/a.md', 'target_path': 'docs/other.md'},
            {'staging_path': 'kb/d/b.bin', 'target_path': 'docs/b.bin'}]}))
        with self.assertRaises(p.Reject) as ctx:
            p.build_plan(self.run, self.target, bad)
        self.assertEqual(str(ctx.exception), 'MAP_SOURCE_DUP')

    def test_target_collision_rejected(self):
        bad = self.base / 'coll.json'
        bad.write_bytes(canon({'map': [
            {'staging_path': 'kb/d/a.md', 'target_path': 'docs/x.md'},
            {'staging_path': 'kb/d/b.bin', 'target_path': 'docs/x.md'}]}))
        with self.assertRaises(p.Reject) as ctx:
            p.build_plan(self.run, self.target, bad)
        self.assertEqual(str(ctx.exception), 'TARGET_COLLISION')

    def test_map_incomplete_rejected(self):
        bad = self.base / 'inc.json'
        bad.write_bytes(canon({'map': [{'staging_path': 'kb/d/a.md', 'target_path': 'docs/a.md'}]}))
        with self.assertRaises(p.Reject) as ctx:
            p.build_plan(self.run, self.target, bad)
        self.assertEqual(str(ctx.exception), 'MAP_INCOMPLETE')

    def test_receipt_exists_rejected(self):
        receipt = self.base / 'receipt.json'
        receipt.write_bytes(b'{}')
        with self.assertRaises(p.Reject) as ctx:
            p.execute(self.run, self.target, self.map, self.plan()['placement_digest'], receipt)
        self.assertEqual(str(ctx.exception), 'RECEIPT_EXISTS')
        self.assertFalse((self.target / 'docs/a.md').exists())
        self.assertFalse((self.target / 'docs/b.bin').exists())

    def test_oversized_existing_target_is_conflict(self):
        (self.target / 'docs').mkdir()
        with (self.target / 'docs/a.md').open('wb') as stream:
            stream.write(b'x' * (16 * 1024 * 1024 + 1))
        state = {r['target_path']: r['state'] for r in self.plan()['files']}
        self.assertEqual(state['docs/a.md'], 'CONFLICT')

    def test_duplicate_manifest_rejected(self):
        dup = self.base / 'duprun' / RUN_ID
        shutil.copytree(self.run, dup)
        manifest = json.loads((dup / 'manifest.json').read_text())
        manifest['files'].append(dict(manifest['files'][0]))
        (dup / 'manifest.json').write_bytes(canon(manifest))
        receipt = json.loads((dup / 'VERIFIED.json').read_text())
        receipt['file_count'] = 3
        (dup / 'VERIFIED.json').write_bytes(canon(receipt))
        with self.assertRaises(p.Reject) as ctx:
            p.verify_staging(dup)
        self.assertEqual(str(ctx.exception), 'MANIFEST_DUP')


    def _v2_run(self):
        run = self.base / 'v2' / RUN_ID
        (run / 'files' / 'kb' / 'd').mkdir(parents=True)
        (run / 'files' / 'kb' / 'd' / 'a.md').write_bytes(self.doc)
        (run / 'files' / 'kb' / 'd' / 'b.bin').write_bytes(self.bin)
        files = [
            {'sha256': p.sha(self.doc), 'size_bytes': len(self.doc),
             'source_path': 'x/a.md', 'staging_path': 'kb/d/a.md'},
            {'sha256': p.sha(self.bin), 'size_bytes': len(self.bin),
             'source_path': 'x/b.bin', 'staging_path': 'kb/d/b.bin'}]
        manifest = {'content_digest': 'd' * 64, 'files': files, 'profile_id': 'a4-general-fi',
                    'profile_sha256': 'e' * 64, 'profile_version': '1.0.0',
                    'protocol_version': 'FOF_ARTIFACT_HANDOFF/2', 'run_correlation_digest': 'f' * 64,
                    'run_id': RUN_ID, 'source_head': 'a' * 40,
                    'source_repository_id': 'Python-R-Scripts', 'workstream': 'A4'}
        (run / 'manifest.json').write_bytes(canon(manifest))
        receipt = {'content_digest': 'd' * 64, 'file_count': 2,
                   'protocol_version': 'FOF_ARTIFACT_HANDOFF/2', 'run_correlation_digest': 'f' * 64,
                   'run_id': RUN_ID, 'status': 'VERIFIED', 'verified_at': '2026-10-09T00:00:00Z'}
        (run / 'VERIFIED.json').write_bytes(canon(receipt))
        return run

    def test_v2_create_new_success(self):
        run = self._v2_run()
        plan = p.build_plan(run, self.target, self.map)
        self.assertTrue(all(r['state'] == 'ABSENT' for r in plan['files']))
        receipt = p.execute(run, self.target, self.map, plan['placement_digest'],
                            self.base / 'v2receipt.json')
        self.assertEqual(receipt['status'], 'PLACED')
        self.assertEqual((self.target / 'docs/a.md').read_bytes(), self.doc)
        self.assertEqual((self.target / 'docs/b.bin').read_bytes(), self.bin)

    def test_v2_digest_binds_map(self):
        run = self._v2_run()
        first = p.build_plan(run, self.target, self.map)['placement_digest']
        alt = self.base / 'altmap.json'
        alt.write_bytes(canon({'map': [
            {'staging_path': 'kb/d/a.md', 'target_path': 'docs/zzz.md'},
            {'staging_path': 'kb/d/b.bin', 'target_path': 'docs/b.bin'}]}))
        self.assertNotEqual(first, p.build_plan(run, self.target, alt)['placement_digest'])

    def test_source_changed_after_preview(self):
        plan = self.plan()
        (self.run / 'payload' / 'kb' / 'd' / 'b.bin').write_bytes(b'changed')
        with self.assertRaises(p.Reject) as ctx:
            p.execute(self.run, self.target, self.map, plan['placement_digest'],
                      self.base / 'r.json')
        self.assertEqual(str(ctx.exception), 'PAYLOAD_MISMATCH')

    def test_parent_changed_detected_no_receipt(self):
        from unittest.mock import patch
        plan = self.plan()
        with patch.object(p, '_parent_identity', side_effect=[[('a',)], [('b',)]]):
            with self.assertRaises(p.Reject) as ctx:
                p.execute(self.run, self.target, self.map, plan['placement_digest'],
                          self.base / 'r.json')
        self.assertEqual(str(ctx.exception), 'PARENT_CHANGED')
        self.assertFalse((self.base / 'r.json').exists())

    def test_interruption_preserves_partial_no_receipt(self):
        from unittest.mock import patch
        plan = self.plan()
        real = p.create_new
        calls = {'n': 0}

        def flaky(path, data):
            calls['n'] += 1
            if calls['n'] == 2:
                raise OSError('interrupted')
            return real(path, data)

        with patch.object(p, 'create_new', side_effect=flaky):
            with self.assertRaises(OSError):
                p.execute(self.run, self.target, self.map, plan['placement_digest'],
                          self.base / 'r.json')
        self.assertFalse((self.base / 'r.json').exists())

    def test_receipt_publish_error_no_success_receipt(self):
        from unittest.mock import patch
        plan = self.plan()
        with patch.object(p, '_write_receipt', side_effect=OSError('fs error')):
            with self.assertRaises(OSError):
                p.execute(self.run, self.target, self.map, plan['placement_digest'],
                          self.base / 'r.json')
        self.assertFalse((self.base / 'r.json').exists())

    def test_payload_exact_set_enforced(self):
        (self.run / 'payload' / 'kb' / 'd' / 'extra.md').write_bytes(b'extra')
        with self.assertRaises(p.Reject) as ctx:
            p.verify_staging(self.run)
        self.assertEqual(str(ctx.exception), 'PAYLOAD_EXACT_SET')


if __name__ == '__main__':
    unittest.main()
