import os
import subprocess
import sys
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = PROJECT_ROOT / "scripts"
REPORT = PROJECT_ROOT / "outputs" / "reports" / "aim2_report.md"


class TestReporting(unittest.TestCase):
    def test_report_generated_on_sample_qc(self):
        env = os.environ.copy()
        env.pop("DATA_ROOT", None)

        p1 = subprocess.run(
            [sys.executable, str(SCRIPTS / "30_qc_summary.py"), "--use-sample"],
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(p1.returncode, 0, p1.stderr or p1.stdout)

        if REPORT.exists():
            REPORT.unlink()

        p2 = subprocess.run(
            [sys.executable, str(SCRIPTS / "50_build_report.py")],
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(p2.returncode, 0, p2.stderr or p2.stdout)
        self.assertTrue(REPORT.exists())

        txt = REPORT.read_text(encoding="utf-8").lower()
        self.assertNotIn("id,", txt)
        self.assertNotIn(" id ", txt)


if __name__ == "__main__":
    unittest.main()
