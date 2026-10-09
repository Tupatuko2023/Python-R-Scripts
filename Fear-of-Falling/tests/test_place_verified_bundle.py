"""Synthetic PLACE/1 tests using self-generated files and a local synthetic repo."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import uuid
import errno

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/termux/place_verified_bundle.py'
spec = importlib.util.spec_from_file_location('place', SCRIPT)
p = importlib.util.module_from_spec(spec)
spec.loader.exec_module(p)

RUN_ID = '20261009T120000Z-' + 'a' * 32
BATCH_ID = 'b' * 32


def canon(obj):
    return p.canonical(obj)


class PlaceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.home(), prefix='place-synthetic-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.receipts = {}

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
        content = {'protocol': 'FOF_KB_PULL/1', 'files': files}
        manifest = dict(content, batch_id=BATCH_ID, content_digest=p.sha(canon(content)))
        (self.run / 'manifest.json').write_bytes(canon(manifest))
        receipt = {'protocol': 'FOF_KB_PULL/1', 'status': 'VERIFIED', 'run_id': RUN_ID,
                   'batch_id': BATCH_ID, 'content_digest': manifest['content_digest'],
                   'file_count': 2, 'return_receipt_status': 'NOT_DELIVERED'}
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

    def receipt(self, name='receipt.json'):
        if name not in self.receipts:
            # POSIX publication is allowed only directly in a non-relocatable
            # private anchor. These new synthetic receipt artifacts are retained.
            directory = self.base if os.name == 'nt' else p._posix_anchor(self.base)[0]
            self.receipts[name] = directory / ('place-synthetic-' + uuid.uuid4().hex + '-' + name)
        return self.receipts[name]

    def plan(self):
        return p.build_plan(self.run, self.target, self.map)

    def test_create_new_success(self):
        plan = self.plan()
        self.assertTrue(all(r['state'] == 'ABSENT' for r in plan['files']))
        receipt = p.execute(self.run, self.target, self.map, plan['placement_digest'],
                            self.receipt('receipt.json'))
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
                            self.receipt('receipt.json'))
        self.assertEqual(receipt['status'], 'PLACED')

    def test_conflict_no_overwrite(self):
        (self.target / 'docs').mkdir()
        (self.target / 'docs/a.md').write_bytes(b'different')
        with self.assertRaises(p.Reject) as ctx:
            p.execute(self.run, self.target, self.map, self.plan()['placement_digest'],
                      self.receipt('receipt.json'))
        self.assertEqual(str(ctx.exception), 'CONFLICT')
        self.assertEqual((self.target / 'docs/a.md').read_bytes(), b'different')

    def test_wrong_digest(self):
        with self.assertRaises(p.Reject) as ctx:
            p.execute(self.run, self.target, self.map, 'f' * 64, self.receipt('receipt.json'))
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
        receipt = self.receipt('receipt.json')
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
        content = {k: v for k, v in manifest.items() if k not in ('batch_id', 'content_digest')}
        manifest['content_digest'] = p.sha(canon(content))
        (dup / 'manifest.json').write_bytes(canon(manifest))
        receipt = json.loads((dup / 'VERIFIED.json').read_text())
        receipt['content_digest'] = manifest['content_digest']
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
        base = {'files': [{'sha256': r['sha256'], 'size_bytes': r['size_bytes'],
                           'source_path': r['source_path'], 'staging_path': r['staging_path']}
                          for r in sorted(files, key=lambda i: (i['source_path'], i['staging_path']))],
                'profile_id': 'a4-general-fi', 'profile_sha256': 'e' * 64,
                'profile_version': '1.0.0', 'protocol_version': 'FOF_ARTIFACT_HANDOFF/2',
                'source_head': 'a' * 40, 'source_repository_id': 'Python-R-Scripts',
                'workstream': 'A4'}
        content_digest = p.sha(canon(base))
        correlation = p.sha(canon({'content_digest': content_digest,
                                   'protocol_version': 'FOF_ARTIFACT_HANDOFF/2', 'run_id': RUN_ID}))
        manifest = dict(base, content_digest=content_digest,
                        run_correlation_digest=correlation, run_id=RUN_ID)
        (run / 'manifest.json').write_bytes(canon(manifest))
        receipt = {'content_digest': content_digest, 'file_count': 2,
                   'protocol_version': 'FOF_ARTIFACT_HANDOFF/2', 'run_correlation_digest': correlation,
                   'run_id': RUN_ID, 'status': 'VERIFIED', 'verified_at': '2026-10-09T00:00:00Z'}
        (run / 'VERIFIED.json').write_bytes(canon(receipt))
        return run

    def test_v2_create_new_success(self):
        run = self._v2_run()
        plan = p.build_plan(run, self.target, self.map)
        self.assertTrue(all(r['state'] == 'ABSENT' for r in plan['files']))
        receipt = p.execute(run, self.target, self.map, plan['placement_digest'],
                            self.receipt('v2receipt.json'))
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
                      self.receipt('r.json'))
        self.assertEqual(str(ctx.exception), 'PAYLOAD_MISMATCH')

    def test_parent_changed_detected_no_receipt(self):
        from unittest.mock import patch
        plan = self.plan()
        real_identity = p._parent_identity
        calls = []
        def changed(directory):
            if Path(directory) == self.target / 'docs':
                calls.append(directory)
                return [('a',)] if len(calls) == 1 else [('b',)]
            return real_identity(directory)
        with patch.object(p, '_parent_identity', side_effect=changed):
            with self.assertRaises(p.Reject) as ctx:
                p.execute(self.run, self.target, self.map, plan['placement_digest'],
                          self.receipt('r.json'))
        self.assertEqual(str(ctx.exception), 'PARENT_CHANGED')
        self.assertFalse((self.receipt('r.json')).exists())

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
                          self.receipt('r.json'))
        self.assertFalse((self.receipt('r.json')).exists())

    def test_receipt_publish_error_no_success_receipt(self):
        from unittest.mock import patch
        plan = self.plan()
        with patch.object(p, '_write_receipt', side_effect=OSError('fs error')):
            with self.assertRaises(OSError):
                p.execute(self.run, self.target, self.map, plan['placement_digest'],
                          self.receipt('r.json'))
        self.assertFalse((self.receipt('r.json')).exists())

    def test_payload_exact_set_enforced(self):
        (self.run / 'payload' / 'kb' / 'd' / 'extra.md').write_bytes(b'extra')
        with self.assertRaises(p.Reject) as ctx:
            p.verify_staging(self.run)
        self.assertEqual(str(ctx.exception), 'PAYLOAD_EXACT_SET')

    def test_manifest_digest_recomputed_rejects_tamper(self):
        m = json.loads((self.run / 'manifest.json').read_text())
        m['files'][0]['sha256'] = '0' * 64
        (self.run / 'manifest.json').write_bytes(canon(m))
        with self.assertRaises(p.Reject) as ctx:
            p.verify_staging(self.run)
        self.assertEqual(str(ctx.exception), 'MANIFEST_DIGEST')

    def test_wrong_batch_id_rejected(self):
        r = json.loads((self.run / 'VERIFIED.json').read_text())
        r['batch_id'] = 'a' * 32
        (self.run / 'VERIFIED.json').write_bytes(canon(r))
        with self.assertRaises(p.Reject) as ctx:
            p.verify_staging(self.run)
        self.assertEqual(str(ctx.exception), 'BATCH_ID_CORRELATION')

    def test_v2_wrong_run_correlation_rejected(self):
        run = self._v2_run()
        r = json.loads((run / 'VERIFIED.json').read_text())
        r['run_correlation_digest'] = '0' * 64
        (run / 'VERIFIED.json').write_bytes(canon(r))
        with self.assertRaises(p.Reject) as ctx:
            p.verify_staging(run)
        self.assertEqual(str(ctx.exception), 'RUN_CORRELATION')

    def test_v2_manifest_run_correlation_tamper_rejected(self):
        run = self._v2_run()
        m = json.loads((run / 'manifest.json').read_text())
        m['run_correlation_digest'] = '1' * 64
        (run / 'manifest.json').write_bytes(canon(m))
        with self.assertRaises(p.Reject) as ctx:
            p.verify_staging(run)
        self.assertEqual(str(ctx.exception), 'RUN_CORRELATION')

    def test_v2_manifest_content_digest_tamper_rejected(self):
        run = self._v2_run()
        m = json.loads((run / 'manifest.json').read_text())
        m['source_head'] = 'b' * 40
        (run / 'manifest.json').write_bytes(canon(m))
        with self.assertRaises(p.Reject) as ctx:
            p.verify_staging(run)
        self.assertEqual(str(ctx.exception), 'MANIFEST_DIGEST')

    def test_receipt_inside_target_rejected(self):
        (self.target / 'docs').mkdir()
        inside = self.target / 'docs' / 'receipt.json'
        with self.assertRaises(p.Reject) as ctx:
            p.execute(self.run, self.target, self.map, self.plan()['placement_digest'], inside)
        self.assertEqual(str(ctx.exception), 'RECEIPT_INSIDE_TARGET')
        self.assertFalse(inside.exists())
        self.assertFalse((self.target / 'docs/a.md').exists())

    def test_receipt_created_after_check_not_overwritten(self):
        from unittest.mock import patch
        plan = self.plan()
        receipt = self.receipt('race-receipt.json')
        existing = b'{"pre":"existing"}\n'
        real = p.build_plan

        def racer(*args, **kwargs):
            receipt.write_bytes(existing)
            return real(*args, **kwargs)

        with patch.object(p, 'build_plan', side_effect=racer):
            with self.assertRaises(p.Reject) as ctx:
                p.execute(self.run, self.target, self.map, plan['placement_digest'], receipt)
        self.assertEqual(str(ctx.exception), 'RECEIPT_EXISTS')
        self.assertEqual(receipt.read_bytes(), existing)
        self.assertFalse((self.target / 'docs/a.md').exists())

    def test_receipt_through_link_rejected(self):
        link = self.base / 'linkrecv'
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
        with self.assertRaises(p.Reject):
            p.execute(self.run, self.target, self.map, self.plan()['placement_digest'],
                      link / 'receipt.json')

    @unittest.skipIf(os.name == 'nt', 'POSIX anchor resolution only')
    def test_posix_anchor_is_user_owned_not_root(self):
        anchor, info = p._posix_anchor(Path.home())
        self.assertNotEqual(anchor, Path(anchor.anchor))
        self.assertEqual(info.st_uid, os.geteuid())
        fd = os.open(anchor, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        os.close(fd)

    @unittest.skipIf(os.name == 'nt', 'POSIX anchor resolution only')
    def test_posix_anchor_never_returns_root(self):
        for probe in (Path.home(), self.run, self.target):
            anchor, _ = p._posix_anchor(probe)
            self.assertNotEqual(anchor, Path(anchor.anchor), probe)

    @unittest.skipIf(os.name == 'nt', 'POSIX open path only')
    def test_reader_avoids_opening_filesystem_root(self):
        from unittest.mock import patch
        real_open = os.open

        def guard(target, *args, **kwargs):
            if str(target) in ('/', '/data', '/data/data'):
                raise PermissionError(13, 'EACCES')
            return real_open(target, *args, **kwargs)

        with patch.object(os, 'open', side_effect=guard):
            data = p.read_bytes(self.run / 'manifest.json')
        self.assertEqual(data, (self.run / 'manifest.json').read_bytes())

    def test_receipt_publish_unsupported_fails_closed(self):
        from unittest.mock import patch
        plan = self.plan()
        target = self.receipt('unsupported-receipt.json')
        with patch.object(p, '_receipt_publisher', side_effect=p.Reject('RECEIPT_PUBLISH_UNSUPPORTED')):
            with self.assertRaises(p.Reject) as ctx:
                p.execute(self.run, self.target, self.map, plan['placement_digest'], target)
        self.assertEqual(str(ctx.exception), 'RECEIPT_PUBLISH_UNSUPPORTED')
        self.assertFalse(target.exists())
        self.assertFalse((self.target / 'docs/a.md').exists())
        self.assertFalse((self.target / 'docs/b.bin').exists())

    def test_receipt_atomic_eexist_branch_preserves_existing(self):
        from unittest.mock import patch
        target = self.receipt('eexist-receipt.json')
        value = {'protocol': 'PLACE_RECEIPT/1', 'status': 'PLACED'}
        existing = b'{"racer":"keep"}\n'
        real = p._receipt_publisher()
        def racer(fd, directory, source, destination):
            if destination == target.name:
                (directory / destination).write_bytes(existing)
            return real(fd, directory, source, destination)
        with patch.object(p, '_receipt_publisher', return_value=racer):
            with p._receipt_context(target, self.target) as context:
                with self.assertRaises(p.Reject) as ctx:
                    p._write_receipt(target, value, context)
        self.assertEqual(str(ctx.exception), 'RECEIPT_EXISTS')
        self.assertEqual(target.read_bytes(), existing)

    @unittest.skipIf(os.name == 'nt', 'POSIX receipt capability restriction')
    def test_movable_receipt_parent_rejected_before_payload(self):
        from unittest.mock import patch
        target = self.base / 'movable-receipt.json'
        with patch.object(p, '_receipt_publisher') as publisher:
            with self.assertRaisesRegex(p.Reject, 'RECEIPT_PARENT_MOVABLE'):
                p.execute(self.run, self.target, self.map, self.plan()['placement_digest'], target)
        publisher.assert_not_called()
        self.assertFalse((self.target / 'docs/a.md').exists())
        self.assertFalse(target.exists())

    @unittest.skipIf(os.name == 'nt', 'POSIX ancestor relocation race')
    def test_actual_receipt_ancestor_relocated_inside_target_rejected(self):
        from unittest.mock import patch
        outer = self.base / 'movable'; (outer / 'receipts').mkdir(parents=True)
        target = outer / 'receipts/r.json'
        moved = self.target / 'moved-ancestor'
        real = p._posix_anchor
        def racer(directory):
            if Path(directory) == target.parent and outer.exists():
                outer.rename(moved)  # Real relocation, not a symlink-only mock.
            return real(directory)
        plan = self.plan()
        with patch.object(p, '_posix_anchor', side_effect=racer):
            with self.assertRaisesRegex(p.Reject, 'RECEIPT_PARENT_MOVABLE'):
                p.execute(self.run, self.target, self.map, plan['placement_digest'], target)
        self.assertTrue(moved.exists())
        self.assertFalse((moved / 'receipts/r.json').exists())
        self.assertFalse((self.target / 'docs/a.md').exists())

    @unittest.skipIf(os.name == 'nt', 'native POSIX syscall boundary proof')
    def test_boundary_move_into_descendant_denied_with_separate_trust_checks(self):
        from unittest.mock import patch
        target = self.receipt('boundary.json')
        anchor, _ = p._posix_anchor(target.parent)
        self.assertEqual(anchor, target.parent)
        # The trust guarantee comes from these preceding-chain checks; the
        # following rename-into-descendant attempt may independently fail EINVAL.
        for ancestor in anchor.parents:
            self.assertNotEqual(ancestor.stat().st_uid, os.geteuid())
            self.assertFalse(os.access(ancestor, os.W_OK))
        real = p._receipt_publisher()
        attempts = []
        def racer(fd, directory, source, destination):
            if destination == target.name:
                try:
                    directory.rename(self.target / 'moved-receipt-anchor')
                except OSError as exc:
                    attempts.append(exc.errno)
                else:
                    self.fail('anchor unexpectedly moved into its own descendant')
            return real(fd, directory, source, destination)
        with patch.object(p, '_receipt_publisher', return_value=racer):
            receipt = p.execute(self.run, self.target, self.map,
                                self.plan()['placement_digest'], target)
        self.assertEqual(receipt['status'], 'PLACED')
        self.assertEqual(len(attempts), 1)
        self.assertIn(attempts[0], (errno.EACCES, errno.EPERM, errno.EINVAL))
        self.assertFalse((self.target / 'moved-receipt-anchor').exists())
        self.assertEqual(p.read_json(target), receipt)

    def test_receipt_native_publish_error_preserves_temp_no_final(self):
        from unittest.mock import patch
        target = self.receipt('publish-error.json')
        real = p._receipt_publisher()
        temporary = []
        def failing(fd, directory, source, destination):
            if destination == target.name:
                temporary.append(directory / source)
                raise OSError(errno.EIO, 'synthetic publish failure')
            return real(fd, directory, source, destination)
        with patch.object(p, '_receipt_publisher', return_value=failing):
            with self.assertRaisesRegex(p.Reject, 'RECEIPT_PUBLISH_FAILED'):
                p.execute(self.run, self.target, self.map,
                          self.plan()['placement_digest'], target)
        self.assertFalse(target.exists())
        self.assertEqual(len(temporary), 1)
        self.assertEqual(p.read_json(temporary[0])['status'], 'PLACED')
        self.assertEqual((self.run / 'VERIFIED.json').read_bytes(), self.verified_before)

    def test_complete_receipt_stream_closed_before_native_publication(self):
        from unittest.mock import patch
        target = self.receipt('closed-before-publish.json')
        real_fdopen = os.fdopen
        real_publish = p._receipt_publisher()
        writes = []
        observed = []
        def fdopen(fd, mode, *args, **kwargs):
            stream = real_fdopen(fd, mode, *args, **kwargs)
            if mode == 'wb':
                writes.append(stream)
            return stream
        def publish(fd, directory, source, destination):
            if destination == target.name:
                self.assertTrue(writes[-1].closed)
                receipt = p.read_json(directory / source)
                self.assertEqual(receipt['status'], 'PLACED')
                self.assertEqual(len(receipt['files']), 2)
                observed.append(True)
            return real_publish(fd, directory, source, destination)
        with patch.object(os, 'fdopen', side_effect=fdopen), \
                patch.object(p, '_receipt_publisher', return_value=publish):
            p.execute(self.run, self.target, self.map, self.plan()['placement_digest'], target)
        self.assertEqual(observed, [True])

    @unittest.skipIf(os.name == 'nt', 'POSIX held parent permissions')
    def test_actual_chmod_parent_rejected_before_receipt_write(self):
        directory = self.base / 'chmod-parent'; directory.mkdir(mode=0o700)
        target = directory / 'receipt.json'
        with p._hold_dir(directory) as fd:
            context = {'fd': fd, 'directory': directory, 'name': target.name,
                       'identities': p._parent_identity(directory), 'target_root': self.target,
                       'publish': p._receipt_publisher()}
            directory.chmod(0o755)  # Real filesystem mode change, identity unchanged.
            with self.assertRaisesRegex(p.Reject, 'RECEIPT_PARENT_NOT_PRIVATE'):
                p._write_receipt(target, {'status': 'PLACED'}, context)
        self.assertFalse(target.exists())
        self.assertEqual(list(directory.iterdir()), [])

    @unittest.skipIf(os.name == 'nt', 'POSIX directory-fsync injection')
    def test_postpublish_fsync_uncertainty_preserves_complete_receipt(self):
        from unittest.mock import patch
        target = self.receipt('uncertain.json')
        real_fsync = os.fsync
        def fsync(fd):
            if target.exists() and os.fstat(fd).st_ino == target.parent.stat().st_ino:
                raise OSError(errno.EIO, 'synthetic directory fsync failure')
            return real_fsync(fd)
        with patch.object(os, 'fsync', side_effect=fsync):
            with self.assertRaisesRegex(p.ReceiptPublicationUncertain,
                                        'RECEIPT_VISIBLE_DURABILITY_UNCONFIRMED'):
                p.execute(self.run, self.target, self.map, self.plan()['placement_digest'], target)
        self.assertTrue(target.exists())
        receipt = p.read_json(target)
        self.assertEqual(receipt['status'], 'PLACED')
        self.assertEqual((self.target / 'docs/a.md').read_bytes(), self.doc)
        self.assertEqual((self.run / 'VERIFIED.json').read_bytes(), self.verified_before)


if __name__ == '__main__':
    unittest.main()
