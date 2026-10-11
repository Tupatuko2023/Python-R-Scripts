"""Real sender-to-PowerShell-receiver contract tests.

The tests are skipped on hosts without PowerShell 7; Windows CI/runtime runs them.
"""
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SENDER = ROOT / "scripts/termux/export_artifacts_to_windows.sh"
RECEIVER = ROOT / "scripts/ps7/receive_artifact_bundle.ps1"
PWSH = shutil.which("pwsh")


def _canon_sha(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=True,
                                     separators=(",", ":")).encode("ascii")).hexdigest()


@unittest.skipUnless(PWSH, "PowerShell 7 is required for the real receiver contract test")
class RealReceiverContractTest(unittest.TestCase):
    def _run_contract(self, suffix):
        is_csv = suffix == ".csv"
        filename = "synthetic" + suffix
        payload = b"column\nvalue\n" if is_csv else b"synthetic contract payload\n"
        with tempfile.TemporaryDirectory(prefix="fof-v2-e2e-") as td:
            base = Path(td)
            repo = base / "repo"
            fof = repo / "Fear-of-Falling"
            (fof / "scripts/termux").mkdir(parents=True)
            (fof / "scripts/ps7").mkdir(parents=True)
            (fof / "config").mkdir()
            (fof / "outputs").mkdir()
            shutil.copyfile(SENDER, fof / "scripts/termux/export_artifacts_to_windows.sh")
            shutil.copyfile(RECEIVER, fof / "scripts/ps7/receive_artifact_bundle.ps1")
            source = fof / ("outputs/" + filename)
            source.write_bytes(payload)
            profile = {
                "protocol_version": "FOF_ARTIFACT_HANDOFF/2",
                "profile_id": "a4-general-fi",
                "profile_version": "1.0.0",
                "source_repository_id": "Python-R-Scripts",
                "workstream": "A4",
                "state": "APPROVED",
                "classification_policy": "EXPLICIT_APPROVAL_HARD_DENY_PRECEDENCE",
                "files": [{
                    "source_path": "Fear-of-Falling/outputs/" + filename,
                    "staging_path": filename,
                    "classification": "DISTRIBUTABLE_AS_IS",
                    "approval_reference": "SYNTHETIC-ONLY",
                    "csv_approval_reference": "SYNTHETIC-CSV" if is_csv else None,
                    "expected_sha256": hashlib.sha256(payload).hexdigest(),
                }],
            }
            (fof / "config/test-profile.json").write_text(json.dumps(profile), encoding="utf-8")
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "FOF test"], check=True)
            subprocess.run(["git", "-C", str(repo), "remote", "add", "origin", "https://github.com/Tupatuko2023/Python-R-Scripts.git"], check=True)
            subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-qm", "synthetic contract fixture"], check=True)
            staging = base / "staging"
            staging.mkdir()
            wrapper = base / "receiver-wrapper.py"
            wrapper.write_text(
                "#!/usr/bin/env python3\n"
                "import os, subprocess, sys\n"
                "cmd=[os.environ['PWSH'], '-NoLogo', '-NoProfile', '-NonInteractive', '-File', "
                "os.environ['RECEIVER'], '-StagingDir', os.environ['STAGING'], '-TransferId', "
                "os.environ['FOF_V2_TRANSFER_ID']]\n"
                "p=subprocess.run(cmd, stdin=sys.stdin.buffer, stdout=subprocess.PIPE, stderr=subprocess.PIPE)\n"
                "sys.stdout.buffer.write(p.stdout); sys.stderr.buffer.write(p.stderr); sys.exit(p.returncode)\n",
                encoding="utf-8",
            )
            wrapper.chmod(0o700)
            env = dict(os.environ, PWSH=PWSH, RECEIVER=str(fof / "scripts/ps7/receive_artifact_bundle.ps1"), STAGING=str(staging))
            run = subprocess.run(
                ["bash", str(fof / "scripts/termux/export_artifacts_to_windows.sh"), "--profile", "config/test-profile.json"],
                cwd=fof, env=env, text=True, capture_output=True, check=True,
            )
            preview = json.loads(run.stdout)
            execute = subprocess.run(
                ["bash", str(fof / "scripts/termux/export_artifacts_to_windows.sh"), "--profile", "config/test-profile.json",
                 "--execute", "--approved-content-digest", preview["content_digest"], "--local-receiver", str(wrapper)],
                cwd=fof, env=env, text=True, capture_output=True, check=False,
            )
            self.assertEqual(
                execute.returncode, 0,
                msg=f"receiver contract failed\nstdout={execute.stdout}\nstderr={execute.stderr}",
            )
            receipt = json.loads(execute.stdout)["receipt"]
            self.assertEqual(receipt["status"], "VERIFIED")
            self.assertRegex(receipt["run_id"], r"^[0-9]{8}T[0-9]{6}Z-[0-9a-f]{32}$")
            self.assertEqual(receipt["content_digest"], preview["content_digest"])
            self.assertEqual(receipt["file_count"], 1)
            run_dir = staging / "incoming" / receipt["run_id"]
            self.assertTrue((run_dir / "VERIFIED.json").is_file())
            self.assertEqual((run_dir / ("files/" + filename)).read_bytes(), payload)

    def test_sender_bundle_is_verified_by_real_receiver(self):
        self._run_contract(".md")

    def test_csv_source_with_filename_only_staging_is_verified(self):
        self._run_contract(".csv")

    def test_forward_slash_staging_is_verified(self):
        # Regression: the v2 adapter passes -StagingDir as a forward-slash path
        # (FOF_V2_STAGING_DIR); the receiver must normalise before containment.
        import io
        import tarfile
        files = [("a.txt", b"alpha\n"), ("b.bin", bytes(range(64)))]
        with tempfile.TemporaryDirectory(prefix="fof-v2-fwd-") as td:
            base = Path(td)
            staging = base / "staging"
            staging.mkdir(mode=0o700)
            run_id = "20261010T150000Z-" + "a" * 32
            rows = sorted(
                [{"sha256": hashlib.sha256(data).hexdigest(), "size_bytes": len(data),
                  "source_path": "Fear-of-Falling/outputs/" + name, "staging_path": name}
                 for name, data in files],
                key=lambda r: (r["source_path"], r["staging_path"]))
            base_obj = {"files": rows, "profile_id": "a4-general-fi", "profile_sha256": "e" * 64,
                        "profile_version": "1.0.0", "protocol_version": "FOF_ARTIFACT_HANDOFF/2",
                        "source_head": "a" * 40, "source_repository_id": "Python-R-Scripts", "workstream": "A4"}
            content = _canon_sha(base_obj)
            correlation = _canon_sha({"content_digest": content,
                                      "protocol_version": "FOF_ARTIFACT_HANDOFF/2", "run_id": run_id})
            manifest = dict(base_obj, content_digest=content, run_correlation_digest=correlation, run_id=run_id)
            bundle = base / "bundle.tar"
            with tarfile.open(bundle, mode="w", format=tarfile.USTAR_FORMAT) as archive:
                mb = json.dumps(manifest, sort_keys=True, ensure_ascii=True, separators=(",", ":")).encode("ascii")
                info = tarfile.TarInfo("manifest.json"); info.size = len(mb)
                archive.addfile(info, io.BytesIO(mb))
                for name, data in files:
                    info = tarfile.TarInfo("files/" + name); info.size = len(data)
                    archive.addfile(info, io.BytesIO(data))
            with bundle.open("rb") as stream:
                result = subprocess.run(
                    [PWSH, "-NoLogo", "-NoProfile", "-NonInteractive", "-File", str(RECEIVER),
                     "-StagingDir", str(staging).replace(os.sep, "/"), "-TransferId", run_id],
                    stdin=stream, capture_output=True)
            self.assertEqual(result.returncode, 0, msg=result.stdout + result.stderr)
            receipt = json.loads(result.stdout)
            self.assertEqual(receipt["status"], "VERIFIED")
            self.assertEqual(receipt["file_count"], len(files))
            run_dir = staging / "incoming" / run_id
            self.assertTrue((run_dir / "VERIFIED.json").is_file())
            for name, data in files:
                self.assertEqual((run_dir / "files" / name).read_bytes(), data)

    def test_traversal_member_rejected_by_receiver(self):
        import io
        import tarfile
        with tempfile.TemporaryDirectory(prefix="fof-v2-escape-") as td:
            base = Path(td)
            staging = base / "staging"
            staging.mkdir()
            bundle = base / "bundle.tar"
            with tarfile.open(bundle, mode="w", format=tarfile.USTAR_FORMAT) as archive:
                body = json.dumps({"probe": True}).encode()
                info = tarfile.TarInfo("manifest.json")
                info.size = len(body)
                archive.addfile(info, io.BytesIO(body))
                payload = b"escape\n"
                info = tarfile.TarInfo("files/../escape.txt")
                info.size = len(payload)
                archive.addfile(info, io.BytesIO(payload))
            transfer = "20261010T000000Z-" + "a" * 32
            with bundle.open("rb") as stream:
                result = subprocess.run(
                    [PWSH, "-NoLogo", "-NoProfile", "-NonInteractive", "-File", str(RECEIVER),
                     "-StagingDir", str(staging), "-TransferId", transfer],
                    stdin=stream, capture_output=True,
                )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn(b"Unsafe", result.stdout + result.stderr)
            self.assertFalse((staging / "incoming" / transfer / "files").exists())


# Receiver-only native Windows conformance is separate from the POSIX sender
# integration above and from the historical registry-based CrossEndReceiverTests.
PR203_RECEIVER_SHA256 = 'c04362a6d194330df458cf812e708e428acafbdeadc6b3746f985dde8f1c5661'
PR203_SOURCE_HEAD = 'aeb7e33b2d1e85f291b1fa8ee7faddd0b1a247e2'


def native_receiver_fixture(scope='fira1', source_path=None, identity=None, run_id=None):
    """Build an independent, entirely synthetic strict USTAR wire fixture."""
    import io
    import tarfile
    import uuid
    from datetime import datetime, timezone
    prefix = ('GPT/(FIRA1) Frailty Index Research Assistant/knowledge/'
              if scope == 'fira1' else 'Fear-of-Falling/outputs/')
    payload = b'native synthetic receiver fixture\n' + bytes(range(64))
    row = {'source_path': source_path or prefix + 'synthetic note.md',
           'staging_path': 'synthetic-note.bin', 'size_bytes': len(payload),
           'sha256': hashlib.sha256(payload).hexdigest()}
    content_base = {'protocol_version': 'FOF_ARTIFACT_HANDOFF/2',
                    'source_repository_id': 'Python-R-Scripts',
                    'source_head': PR203_SOURCE_HEAD, 'profile_version': '1.0.0',
                    'profile_sha256': hashlib.sha256(b'synthetic-only-profile').hexdigest(),
                    'profile_id': 'fira1-kb' if scope == 'fira1' else 'a4-general-fi',
                    'workstream': 'FIRA1' if scope == 'fira1' else 'A4', 'files': [row]}
    content_base.update(identity or {})
    content = _canon_sha(content_base)
    run_id = run_id or datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ-') + uuid.uuid4().hex
    manifest = dict(content_base, run_id=run_id, content_digest=content,
                    run_correlation_digest=_canon_sha({'protocol_version': 'FOF_ARTIFACT_HANDOFF/2',
                                                       'run_id': run_id, 'content_digest': content}))
    wire = io.BytesIO()
    with tarfile.open(fileobj=wire, mode='w', format=tarfile.USTAR_FORMAT) as archive:
        for name, data in [('manifest.json', json.dumps(manifest, sort_keys=True, ensure_ascii=True,
                                                       separators=(',', ':')).encode('ascii')),
                           ('files/' + row['staging_path'], payload)]:
            item = tarfile.TarInfo(name)
            item.size = len(data)
            archive.addfile(item, io.BytesIO(data))
    return manifest, payload, wire.getvalue()


class NativeReceiverFixtureTests(unittest.TestCase):
    def test_synthetic_wire_payload_exact_set_and_digest_bindings(self):
        import io
        import tarfile
        for scope in ('fof', 'fira1'):
            manifest, payload, wire = native_receiver_fixture(scope)
            with tarfile.open(fileobj=io.BytesIO(wire)) as archive:
                self.assertEqual(archive.getnames(), ['manifest.json', 'files/synthetic-note.bin'])
                self.assertTrue(all(m.isfile() for m in archive.getmembers()))
                with archive.extractfile('files/synthetic-note.bin') as stream:
                    actual = stream.read()
                with archive.extractfile('manifest.json') as stream:
                    embedded = json.load(stream)
            self.assertEqual(actual, payload)
            self.assertEqual(embedded, manifest)
            self.assertEqual(hashlib.sha256(actual).hexdigest(), manifest['files'][0]['sha256'])
            base = {k: v for k, v in manifest.items()
                    if k not in ('run_id', 'content_digest', 'run_correlation_digest')}
            self.assertEqual(_canon_sha(base), manifest['content_digest'])
            self.assertEqual(_canon_sha({'protocol_version': manifest['protocol_version'],
                                        'run_id': manifest['run_id'],
                                        'content_digest': manifest['content_digest']}),
                             manifest['run_correlation_digest'])


@unittest.skipUnless(PWSH, 'Native receiver execution NOT_RUN: PowerShell 7.4 required')
class NativeReceiverContractTests(unittest.TestCase):
    """Direct pwsh only: no Bash/shebang sender, SSH, real FIRA data or retry.

    FOF_TEST_NATIVE_RECEIVER_EVIDENCE must name a pre-approved private,
    repository-external directory. Every test gets a new retained fixture.
    """
    def setUp(self):
        evidence = os.environ.get('FOF_TEST_NATIVE_RECEIVER_EVIDENCE')
        if not evidence:
            self.skipTest('Native receiver execution NOT_RUN: approved evidence directory required')
        root = Path(evidence)
        self.assertTrue(root.is_absolute() and root.is_dir())
        for part in [root, *root.parents]:
            self.assertFalse(part.is_symlink(), 'fixture ancestor link forbidden')
            self.assertFalse(getattr(part.stat(), 'st_file_attributes', 0) & 0x400,
                             'fixture ancestor reparse forbidden')
        self.assertFalse(root.resolve().is_relative_to(ROOT.parent.resolve()),
                         'fixture evidence must be repository external')
        self.assertEqual(hashlib.sha256(RECEIVER.read_bytes()).hexdigest(), PR203_RECEIVER_SHA256,
                         'exact receiver bytes required; CRLF conversion is not silently accepted')
        self.base = Path(tempfile.mkdtemp(prefix='native-receiver-', dir=root))
        self.staging = self.base / 'staging'
        self.staging.mkdir()
        version = subprocess.run([PWSH, '-NoLogo', '-NoProfile', '-NonInteractive', '-Command',
                                  '$PSVersionTable.PSVersion.ToString()'], capture_output=True, timeout=15)
        self.assertEqual(version.returncode, 0)
        parts = version.stdout.decode().strip().split('.')
        self.assertGreaterEqual(tuple(int(p) for p in parts[:2]), (7, 4))

    def invoke(self, manifest, wire, scope='fira1', label=None):
        label = label or manifest['run_id']
        (self.base / (label + '.manifest.json')).write_text(json.dumps(manifest, indent=2), encoding='utf-8')
        (self.base / (label + '.tar')).write_bytes(wire)
        command = [PWSH, '-NoLogo', '-NoProfile', '-NonInteractive', '-File', str(RECEIVER),
                   '-StagingDir', str(self.staging).replace(os.sep, '/'), '-TransferId', manifest['run_id']]
        if scope == 'fira1':
            command += ['-SourceScope', 'fira1']
        result = subprocess.run(command, input=wire, capture_output=True, timeout=45)
        (self.base / (label + '.stdout')).write_bytes(result.stdout)
        (self.base / (label + '.stderr')).write_bytes(result.stderr)
        (self.base / (label + '.result.json')).write_text(json.dumps({'exit': result.returncode,
                        'scope': scope, 'receiver_sha256': PR203_RECEIVER_SHA256}), encoding='utf-8')
        return result

    def verified(self, scope):
        manifest, payload, wire = native_receiver_fixture(scope)
        result = self.invoke(manifest, wire, scope)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        receipt = json.loads(result.stdout)
        self.assertEqual(receipt['status'], 'VERIFIED')
        for key in ('protocol_version', 'run_id', 'content_digest', 'run_correlation_digest'):
            self.assertEqual(receipt[key], manifest[key])
        self.assertEqual(receipt['file_count'], 1)
        run = self.staging / 'incoming' / manifest['run_id']
        self.assertEqual(json.loads((run / 'VERIFIED.json').read_bytes()), receipt)
        self.assertEqual((run / 'files/synthetic-note.bin').read_bytes(), payload)
        return manifest, wire, run

    def reject(self, manifest, wire, scope='fira1'):
        result = self.invoke(manifest, wire, scope)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.staging / 'incoming' / manifest['run_id'] / 'VERIFIED.json').exists())

    def test_native_fof_default_positive(self):
        self.verified('fof')

    def test_native_fira_spaces_positive(self):
        self.verified('fira1')

    def test_native_wrong_scope_rejected(self):
        manifest, _, wire = native_receiver_fixture()
        self.reject(manifest, wire, 'fof')

    def test_native_wrong_identity_rejected(self):
        for identity in [{'profile_id': 'a4-general-fi'}, {'workstream': 'A4'},
                         {'source_repository_id': 'other'}]:
            manifest, _, wire = native_receiver_fixture(identity=identity)
            self.reject(manifest, wire)

    def test_native_outside_prefix_and_traversal_rejected(self):
        for path in ['GPT/other/synthetic.md', 'GPT/(FIRA1) Frailty Index Research Assistant/../escape.md']:
            manifest, _, wire = native_receiver_fixture(source_path=path)
            self.reject(manifest, wire)

    def test_native_protected_code_registry_changelog_rejected(self):
        prefix = 'GPT/(FIRA1) Frailty Index Research Assistant/'
        for tail in ['data/synthetic.md', 'knowledge/test.py', 'knowledge/test.R',
                     'knowledge/test.sh', 'knowledge/test.ps1',
                     'knowledge/registry/FI_CANDIDATE_REGISTRY.csv', 'knowledge/registry/FI_CHANGELOG.md']:
            manifest, _, wire = native_receiver_fixture(source_path=prefix + tail)
            self.reject(manifest, wire)

    def test_native_existing_run_replay_preserves_original(self):
        manifest, wire, run = self.verified('fira1')
        before = {str(p.relative_to(run)): p.read_bytes() for p in run.rglob('*') if p.is_file()}
        result = self.invoke(manifest, wire, label='replay')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual({str(p.relative_to(run)): p.read_bytes() for p in run.rglob('*') if p.is_file()}, before)

    def test_native_reparse_staging_rejected_when_available(self):
        target = self.base / 'synthetic-target'
        target.mkdir()
        link = self.base / 'staging-link'
        try:
            os.symlink(target, link, target_is_directory=True)
        except OSError as exc:
            # winerror 1314 = symlink privilege absent; a junction is a reparse point without it.
            import subprocess
            made = subprocess.run(['cmd', '/c', 'mklink', '/J', str(link), str(target)],
                                  capture_output=True, text=True)
            if made.returncode != 0:
                self.skipTest('native symlink/reparse creation unavailable: winerror='
                              + str(getattr(exc, 'winerror', None)) + ' errno=' + str(exc.errno))
        self.assertTrue(getattr(os.lstat(link), 'st_file_attributes', 0) & 0x400,
                        'fixture is not a reparse point')
        self.staging = link
        manifest, _, wire = native_receiver_fixture()
        self.reject(manifest, wire)
        self.assertEqual(list(target.iterdir()), [])
