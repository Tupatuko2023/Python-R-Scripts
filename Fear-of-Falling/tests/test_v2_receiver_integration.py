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
