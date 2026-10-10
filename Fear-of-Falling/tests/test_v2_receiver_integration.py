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
