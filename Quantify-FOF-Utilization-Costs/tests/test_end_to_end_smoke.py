import os
import subprocess
import sys
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = PROJECT_ROOT / "scripts"

REPORT = PROJECT_ROOT / "outputs" / "reports" / "aim2_report.md"
ZIP = PROJECT_ROOT / "outputs" / "knowledge" / "knowledge_package.zip"
INDEX = PROJECT_ROOT / "outputs" / "knowledge" / "index.json"


class TestEndToEndSmoke(unittest.TestCase):
    def run_cmd(self, args, env):
        p = subprocess.run([sys.executable] + args, capture_output=True, text=True, env=env)
        self.assertEqual(p.returncode, 0, p.stderr or p.stdout)

    def test_sample_pipeline(self):
        env = os.environ.copy()
        env.pop("DATA_ROOT", None)
        env.pop("ALLOW_AGGREGATES", None)

        self.run_cmd([str(SCRIPTS / "30_qc_summary.py"), "--use-sample"], env)
        self.run_cmd([str(SCRIPTS / "10_preprocess_tabular.py"), "--use-sample"], env)

        if REPORT.exists():
            REPORT.unlink()
        self.run_cmd([str(SCRIPTS / "50_build_report.py")], env)
        self.assertTrue(REPORT.exists())

        if ZIP.exists():
            ZIP.unlink()
        if INDEX.exists():
            INDEX.unlink()
        self.run_cmd([str(SCRIPTS / "40_build_knowledge_package.py")], env)
        self.assertTrue(ZIP.exists())
        self.assertTrue(INDEX.exists())


if __name__ == "__main__":
    unittest.main()
