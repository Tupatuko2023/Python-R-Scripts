"""Only self-generated synthetic payloads; no real SSH, data, or credentials."""
import base64
import ctypes
import ctypes.wintypes
from types import SimpleNamespace
import importlib.util
import io
import json
import os
from pathlib import Path, PosixPath
import subprocess
import tempfile
import tarfile
import unittest
from unittest.mock import patch, MagicMock

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/termux/fof_kb_pull.py'
spec = importlib.util.spec_from_file_location('kb_pull', SCRIPT)
k = importlib.util.module_from_spec(spec)
spec.loader.exec_module(k)

class PullTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path.home(), prefix='fof-kb-synthetic-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.source = self.base / 'source'; self.source.mkdir()
        (self.source / 'docs').mkdir()
        self.text = 'Ääkköset, UTF-8.\r\nToinen rivi.\n'.encode('utf-8')
        self.binary = bytes(range(256)) * 100
        (self.source / 'docs/a.md').write_bytes(self.text)
        (self.source / 'docs/b.bin').write_bytes(self.binary)
        self.p = {'protocol': k.PROTOCOL, 'profile_id': 'kb-pull-synthetic-1', 'enabled': True,
            'source_repository_id': 'FOF-Dissertation-Project', 'files': [
                {'source_path': 'docs/a.md', 'staging_path': 'kb/a.md', 'classification': 'DISTRIBUTABLE_AS_IS', 'approval_reference': 'synthetic-only'},
                {'source_path': 'docs/b.bin', 'staging_path': 'kb/b.bin', 'classification': 'DISTRIBUTABLE_AS_IS', 'approval_reference': 'synthetic-only'}]}
        self.profile_path = self.base / 'profile.json'
        self.profile_path.write_bytes(k.canonical(self.p))
        self.batches = self.base / 'batches'; self.batches.mkdir(mode=0o700)
        self.staging = self.base / 'staging'; self.staging.mkdir(mode=0o700)
        self.origin = {'repository_id': 'FOF-Dissertation-Project', 'head': 'a' * 40}
        self.patch = patch.object(k, 'provenance', return_value=self.origin)
        self.patch.start(); self.addCleanup(self.patch.stop)
        self.run_id = '20261005T150000Z-' + 'b' * 32

    def test_private_home_walk_with_slash_open_denied(self):
        original = os.open
        calls = []
        def guarded(path, flags, *args, **kwargs):
            calls.append(str(path))
            if str(path) == '/':
                raise PermissionError(13, 'Permission denied', '/')
            return original(path, flags, *args, **kwargs)
        with patch.object(k.os, 'open', side_effect=guarded):
            self.assertEqual(k.read(self.source / 'docs/a.md'), self.text)
            self.assertEqual(k.read(self.source / 'docs/b.bin'), self.binary)
        self.assertNotIn('/', calls)

    def test_private_home_rejects_file_and_directory_links(self):
        file_link = self.base / 'file-link'
        file_link.symlink_to(self.source / 'docs/a.md')
        directory_link = self.base / 'directory-link'
        directory_link.symlink_to(self.source / 'docs', target_is_directory=True)
        for path in (file_link, directory_link / 'a.md'):
            with self.subTest(path=path), self.assertRaises((k.Reject, OSError)):
                k.read(path)

    def test_private_home_rejects_outside_traversal_and_root(self):
        for path in (Path('/etc/passwd'), self.base / '..' / self.base.name / 'profile.json', Path.home()):
            with self.subTest(path=path), self.assertRaises(k.Reject):
                k.read(path)

    def test_private_home_requires_private_owned_directory(self):
        self.source.chmod(0o755)
        with patch.object(k.Path, 'home', return_value=self.source):
            with self.assertRaisesRegex(k.Reject, 'PRIVATE_ROOT_REQUIRED'):
                k.read(self.source / 'docs/a.md')

    def test_private_home_ancestor_swap_rejected(self):
        # Swap an owned ancestor immediately before the anchor open. Even when
        # alternate HOME is owned/private, fd-relative walking rejects its link.
        controlled = self.base / 'controlled'; controlled.mkdir(mode=0o700)
        original_home = controlled / 'home'; original_home.mkdir(mode=0o700)
        (original_home / 'text.md').write_bytes(self.text)
        alternate = self.base / 'alternate'; alternate.mkdir(mode=0o700)
        (alternate / 'home').mkdir(mode=0o700)
        (alternate / 'home/text.md').write_bytes(b'wrong')
        original_open = os.open
        swapped = False
        def racing_open(path, flags, *args, **kwargs):
            nonlocal swapped
            if not swapped:
                controlled.rename(self.base / 'saved')
                controlled.symlink_to(alternate, target_is_directory=True)
                swapped = True
            return original_open(path, flags, *args, **kwargs)
        with patch.object(k.Path, 'home', return_value=original_home), \
                patch.object(k.os, 'open', side_effect=racing_open):
            with self.assertRaises((k.Reject, OSError)):
                k.read(original_home / 'text.md')
        self.assertTrue(swapped)

    def test_private_home_source_change_still_rejected(self):
        path = self.source / 'docs/a.md'
        with self.assertRaisesRegex(k.Reject, 'SOURCE_CHANGED'):
            with k.locked_read(path) as stream:
                self.assertEqual(stream.read(), self.text)
                path.write_bytes(self.text + b'changed')

    def prepare(self):
        self.m = k.preview(self.source, self.profile_path, self.batches, True)
        self.batch = self.batches / self.m['batch_id']; self.approved = self.m['content_digest']
        k.approve(self.batch, self.approved)
        self.wire = k.archive_bytes(self.batch, self.approved)

    def receive(self, wire=None):
        self.run = k.reserve_receive(self.staging, self.run_id)
        return k.verify_wire(self.run, self.wire if wire is None else wire, self.p, self.approved, self.m['batch_id'])

    def repack(self, change=None, missing=None, extra=None):
        output = io.BytesIO()
        with tarfile.open(fileobj=output, mode='w', format=tarfile.USTAR_FORMAT) as archive:
            rows = [('manifest.json', k.canonical(self.m)), ('payload/kb/a.md', self.text), ('payload/kb/b.bin', self.binary)]
            if extra: rows.append(extra)
            for name, data in rows:
                if name == missing: continue
                if change and name == change[0]: data = change[1]
                item = tarfile.TarInfo(name); item.size = len(data)
                archive.addfile(item, io.BytesIO(data))
        return output.getvalue()

    def rejected_wire(self, wire):
        with self.assertRaises((k.Reject, tarfile.TarError, OSError)): self.receive(wire)
        self.assertFalse((self.run / 'VERIFIED.json').exists())

    def test_success_utf8_binary_persistent_correlated_receipt(self):
        self.prepare(); receipt = self.receive()
        self.assertEqual((self.run / 'payload/kb/a.md').read_bytes(), self.text)
        self.assertEqual((self.run / 'payload/kb/b.bin').read_bytes(), self.binary)
        self.assertEqual(receipt, k.load(self.run / 'VERIFIED.json'))
        self.assertEqual(receipt['file_count'], 2)
        self.assertEqual(receipt['content_digest'], self.approved)
        self.assertEqual(receipt['batch_id'], self.m['batch_id'])
        self.assertEqual(receipt['return_receipt_status'], 'NOT_DELIVERED')

    def test_preview_no_transport_and_stable_digest(self):
        with patch.object(k.subprocess, 'Popen', side_effect=AssertionError('network')):
            a = k.preview(self.source, self.profile_path, self.batches, True)
            b = k.preview(self.source, self.profile_path, self.batches, True)
        self.assertEqual(a['content_digest'], b['content_digest'])
        self.assertNotEqual(a['batch_id'], b['batch_id'])

    def test_missing_approval_before_transport(self):
        with patch.object(k.subprocess, 'Popen', side_effect=AssertionError('network')):
            with self.assertRaises(k.Reject): k.pull(self.profile_path, 'a'*32, None, self.staging, self.run_id, True)
        self.assertEqual(list(self.staging.iterdir()), [])

    def test_serve_requires_approval(self):
        m = k.preview(self.source, self.profile_path, self.batches, True)
        with self.assertRaises(FileNotFoundError): k.archive_bytes(self.batches / m['batch_id'], m['content_digest'])

    def test_source_changed_after_preview(self):
        m = k.preview(self.source, self.profile_path, self.batches, True)
        (self.source / 'docs/a.md').write_bytes(b'changed')
        with self.assertRaises(k.Reject): k.approve(self.batches / m['batch_id'], m['content_digest'])

    def test_snapshot_changed_after_approval(self):
        self.prepare(); (self.batch / 'snapshots/0000').write_bytes(b'changed')
        with self.assertRaises(k.Reject): k.archive_bytes(self.batch, self.approved)

    def test_source_changed_after_approval(self):
        self.prepare(); (self.source / 'docs/a.md').write_bytes(b'changed')
        with self.assertRaises(k.Reject): k.archive_bytes(self.batch, self.approved)

    def test_head_changed(self):
        self.prepare()
        with patch.object(k, 'provenance', return_value=dict(self.origin, head='b'*40)):
            with self.assertRaises(k.Reject): k.archive_bytes(self.batch, self.approved)

    def test_bad_digest(self):
        self.prepare(); self.approved = 'f'*64; self.rejected_wire(self.wire)

    def test_bad_hash(self):
        self.prepare(); self.rejected_wire(self.repack(change=('payload/kb/a.md', b'X'*len(self.text))))

    def test_bad_size(self):
        self.prepare(); self.rejected_wire(self.repack(change=('payload/kb/a.md', self.text+b'!')))

    def test_missing_file(self):
        self.prepare(); self.rejected_wire(self.repack(missing='payload/kb/b.bin'))

    def test_extra_file(self):
        self.prepare(); self.rejected_wire(self.repack(extra=('payload/kb/extra.md', b'extra')))

    def test_duplicate_file(self):
        self.prepare(); self.rejected_wire(self.repack(extra=('payload/kb/a.md', self.text)))

    def test_traversal(self):
        self.prepare(); self.rejected_wire(self.repack(extra=('../escape.md', b'unsafe')))

    def test_symlink_hardlink_and_gnu_header(self):
        self.prepare()
        for index, kind in enumerate((tarfile.SYMTYPE, tarfile.LNKTYPE, tarfile.GNUTYPE_LONGNAME)):
            self.run_id = '20261005T150000Z-' + str(index)*32
            stream = io.BytesIO()
            with tarfile.open(fileobj=stream, mode='w', format=tarfile.USTAR_FORMAT) as archive:
                item = tarfile.TarInfo('manifest.json'); item.type = kind; item.linkname = 'target'
                archive.addfile(item)
            self.rejected_wire(stream.getvalue())

    def test_trailing_archive(self):
        self.prepare(); self.rejected_wire(self.wire + self.wire)

    def test_truncated_wire(self):
        self.prepare(); self.rejected_wire(self.wire[:-1])

    def test_existing_run(self):
        self.prepare(); self.receive(); before = (self.run / 'VERIFIED.json').read_bytes()
        with self.assertRaises(FileExistsError): k.reserve_receive(self.staging, self.run_id)
        self.assertEqual((self.run / 'VERIFIED.json').read_bytes(), before)

    def test_profile_closed_and_synthetic_separation(self):
        self.p['enabled'] = False
        with self.assertRaises(k.Reject): k.profile_object(self.p, True)
        self.p['enabled'] = True
        with self.assertRaises(k.Reject): k.profile_object(self.p, False)

    def test_paths_hard_denies_and_collisions(self):
        for value in ('../a.md', '/absolute.md', 'data/a.md', 'docs/secret.md', 'docs/a.db', 'docs/a.py', 'docs/NUL.md', 'docs/a?.md'):
            candidate = json.loads(json.dumps(self.p)); candidate['files'][0]['source_path'] = value
            with self.subTest(value=value), self.assertRaises(k.Reject): k.profile_object(candidate, True)
        for value in ('kb/A.md', 'kb/a.md/child.md'):
            candidate = json.loads(json.dumps(self.p)); candidate['files'][1]['staging_path'] = value
            with self.assertRaises(k.Reject): k.profile_object(candidate, True)

    def test_source_symlink_and_fifo(self):
        path = self.source / 'docs/a.md'; path.unlink(); path.symlink_to(self.source / 'docs/b.bin')
        with self.assertRaises(OSError): k.preview(self.source, self.profile_path, self.batches, True)
        path.unlink(); os.mkfifo(path)
        with self.assertRaises(k.Reject): k.preview(self.source, self.profile_path, self.batches, True)

    def test_runtime_symlink(self):
        link = self.base / 'linked-staging'; link.symlink_to(self.staging, target_is_directory=True)
        with self.assertRaises(k.Reject): k.reserve_receive(link, self.run_id)

    def test_safe_ssh_args_binary_bridge(self):
        env = {'FOF_KB_SSH_ALIAS': 'synthetic-host', 'FOF_KB_REMOTE_SCRIPT': 'C:/Synthetic Repo/Fear-of-Falling/scripts/termux/fof_kb_pull.py', 'FOF_KB_REMOTE_BATCH_ROOT': 'C:/Synthetic Batches'}
        argv = k.ssh_command(env, 'a'*32, 'b'*64)
        self.assertIn('StrictHostKeyChecking=yes', argv)
        self.assertIn('ConnectionAttempts=1', argv)
        command = base64.b64decode(argv[-1].split()[-1]).decode('utf-16le')
        self.assertIn('BaseStream.CopyTo([Console]::OpenStandardOutput())', command)
        for key in env:
            bad = dict(env); bad[key] += "';evil"
            with self.assertRaises(k.Reject): k.ssh_command(bad, 'a'*32, 'b'*64)

    def test_disconnect_preserved_no_retry(self):
        self.prepare(); child = ['python', '-c', 'import sys;sys.stdout.buffer.write(b"partial");sys.exit(255)']
        with patch.object(k, 'ssh_command', return_value=child):
            with self.assertRaises(k.Reject): k.pull(self.profile_path, self.m['batch_id'], self.approved, self.staging, self.run_id, True)
        run = self.staging / self.run_id
        self.assertEqual((run / 'wire.tar').read_bytes(), b'partial')
        self.assertFalse((run / 'VERIFIED.json').exists())
        self.assertFalse(k.load(run / 'UNVERIFIED.json')['automatic_retry'])
        self.assertEqual(len(list(self.staging.iterdir())), 1)

    def test_transport_process_success(self):
        self.prepare(); wirefile = self.base / 'wire.tar'; wirefile.write_bytes(self.wire)
        child = ['python', '-c', 'import sys;sys.stdout.buffer.write(open(sys.argv[1],"rb").read())', str(wirefile)]
        with patch.object(k, 'ssh_command', return_value=child):
            result = k.pull(self.profile_path, self.m['batch_id'], self.approved, self.staging, self.run_id, True)
        self.assertEqual(result['status'], 'VERIFIED')

    def test_stalled_process_deadline(self):
        self.prepare(); child = ['python', '-c', 'import time;time.sleep(30)']
        with patch.object(k, 'ssh_command', return_value=child), patch.object(k.select, 'select', return_value=([], [], [])):
            with self.assertRaises(k.Reject): k.pull(self.profile_path, self.m['batch_id'], self.approved, self.staging, self.run_id, True)
        self.assertTrue((self.staging / self.run_id / 'UNVERIFIED.json').exists())

    def test_actual_checkout_provenance_identity(self):
        self.patch.stop()
        repo = SCRIPT.parents[3]
        origin = k.provenance(repo, 'Python-R-Scripts')
        self.assertEqual(len(origin['head']), 40)
        with self.assertRaises(k.Reject):
            k.provenance(repo, 'FOF-Dissertation-Project')
        self.patch.start()

    def test_windows_open_osfhandle_failure_closes_every_native_handle(self):
        kernel = MagicMock()
        handles = []
        def create(*args):
            handle = 100 + len(handles)
            handles.append(handle)
            return handle
        kernel.CreateFileW.side_effect = create
        leaf = (self.source / 'docs/a.md').absolute()
        kernel.GetFileAttributesW.side_effect = lambda name: 0 if name == str(leaf) else 0x10
        crt = SimpleNamespace(open_osfhandle=MagicMock(side_effect=OSError('synthetic-failure')))
        with patch.object(k.os, 'name', 'nt'), patch.object(k, 'Path', PosixPath), \
                patch.object(ctypes, 'WinDLL', return_value=kernel, create=True), \
                patch.dict('sys.modules', {'msvcrt': crt}), patch.object(k.os, 'O_BINARY', 0, create=True):
            with self.assertRaises(OSError):
                with k.locked_read(leaf):
                    self.fail('unreachable')
        self.assertEqual([call.args[0] for call in kernel.CloseHandle.call_args_list], list(reversed(handles)))

    def test_windows_fdopen_failure_closes_transferred_crt_fd(self):
        kernel = MagicMock()
        handles = []
        def create(*args):
            handle = 100 + len(handles)
            handles.append(handle)
            return handle
        kernel.CreateFileW.side_effect = create
        leaf = (self.source / 'docs/a.md').absolute()
        kernel.GetFileAttributesW.side_effect = lambda name: 0 if name == str(leaf) else 0x10
        crt = SimpleNamespace(open_osfhandle=MagicMock(return_value=10000))
        with patch.object(k.os, 'name', 'nt'), patch.object(k, 'Path', PosixPath), \
                patch.object(ctypes, 'WinDLL', return_value=kernel, create=True), \
                patch.dict('sys.modules', {'msvcrt': crt}), patch.object(k.os, 'O_BINARY', 0, create=True), \
                patch.object(k.os, 'fdopen', side_effect=OSError('synthetic-failure')), \
                patch.object(k.os, 'close') as close:
            with self.assertRaises(OSError):
                with k.locked_read(leaf):
                    self.fail('unreachable')
        close.assert_called_once_with(10000)
        self.assertEqual([call.args[0] for call in kernel.CloseHandle.call_args_list], list(reversed(handles[:-1])))

    def test_atomic_file_fsync_failure_publishes_no_verified(self):
        target = self.base / 'VERIFIED.json'
        with patch.object(k.os, 'fsync', side_effect=OSError('synthetic-failure')):
            with self.assertRaises(OSError):
                k.atomic_new(target, {'status': 'VERIFIED'})
        self.assertFalse(target.exists())

    def injected_pull_fsync(self, after_publish):
        self.prepare()
        wirefile = self.base / 'wire.tar'; wirefile.write_bytes(self.wire)
        child = ['python', '-c', 'import sys;sys.stdout.buffer.write(open(sys.argv[1],"rb").read())', str(wirefile)]
        run = self.staging / self.run_id
        real_fsync = k.os.fsync
        injected = []
        def failing(fd):
            target = Path(os.readlink('/proc/self/fd/' + str(fd)))
            if not injected and target == run and (run / 'VERIFIED.json').exists() == after_publish:
                injected.append(True)
                raise OSError('synthetic-fsync-failure')
            return real_fsync(fd)
        with patch.object(k, 'ssh_command', return_value=child), patch.object(k.os, 'fsync', side_effect=failing):
            with self.assertRaises(k.PublicationUncertain if after_publish else OSError):
                k.pull(self.profile_path, self.m['batch_id'], self.approved, self.staging, self.run_id, True)
        self.assertTrue(injected)
        return run

    def test_prepublication_dir_fsync_failure_only_unverified(self):
        run = self.injected_pull_fsync(False)
        self.assertFalse((run / 'VERIFIED.json').exists())
        self.assertTrue((run / 'UNVERIFIED.json').exists())

    def test_postpublication_dir_fsync_failure_no_contradictory_unverified(self):
        run = self.injected_pull_fsync(True)
        self.assertEqual(k.load(run / 'VERIFIED.json')['status'], 'VERIFIED')
        self.assertFalse((run / 'UNVERIFIED.json').exists())
        self.assertEqual(k.load(run / 'PUBLICATION_UNCERTAIN.json')['status'], 'LOCAL_VERIFIED_DURABILITY_UNCONFIRMED')

    def test_cli_help_smoke(self):
        result = subprocess.run(['python', str(SCRIPT), '--help'], capture_output=True)
        self.assertEqual(result.returncode, 0)

if __name__ == '__main__': unittest.main()
