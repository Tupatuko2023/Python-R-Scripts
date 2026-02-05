import os
import subprocess
import sys
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = PROJECT_ROOT / "scripts"


class TestSecurityGuardrails(unittest.TestCase):
    def _run(self, rel_script: str, args: list[str]) -> subprocess.CompletedProcess:
        env = os.environ.copy()
        env.pop("DATA_ROOT", None)
        
        # Hide .env temporarily to force failure
        dot_env = PROJECT_ROOT / "config" / ".env"
        bak_env = PROJECT_ROOT / "config" / ".env.bak"
        hidden = False
        if dot_env.exists():
            dot_env.rename(bak_env)
            hidden = True
            
        try:
            cmd = [sys.executable, str(SCRIPTS / rel_script)] + args
            return subprocess.run(cmd, capture_output=True, text=True, env=env)
        finally:
            if hidden:
                bak_env.rename(dot_env)

    def test_inventory_refuses_without_data_root(self) -> None:
        p = self._run("00_inventory_manifest.py", ["--scan", "paper_02"])
        self.assertEqual(p.returncode, 0, p.stderr or p.stdout)
        self.assertIn("DATA_ROOT", (p.stdout + p.stderr))

    def test_preprocess_refuses_without_data_root(self) -> None:
        p = self._run("10_preprocess_tabular.py", [])
        self.assertEqual(p.returncode, 0, p.stderr or p.stdout)
        self.assertIn("DATA_ROOT", (p.stdout + p.stderr))

    def test_qc_refuses_without_data_root(self) -> None:
        p = self._run("30_qc_summary.py", [])
        self.assertEqual(p.returncode, 0, p.stderr or p.stdout)
        self.assertIn("DATA_ROOT", (p.stdout + p.stderr))


if __name__ == "__main__":
    unittest.main()
