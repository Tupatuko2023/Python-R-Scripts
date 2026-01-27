import subprocess
import sys
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = PROJECT_ROOT / "scripts"
OUT_QC = PROJECT_ROOT / "outputs" / "qc"


class TestPipelineSmoke(unittest.TestCase):
    def test_qc_runs_on_sample(self) -> None:
        cmd = [sys.executable, str(SCRIPTS / "30_qc_summary.py"), "--use-sample"]
        p = subprocess.run(cmd, capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr or p.stdout)
        self.assertTrue((OUT_QC / "qc_overview.csv").exists())
        self.assertTrue((OUT_QC / "qc_missingness.csv").exists())
        self.assertTrue((OUT_QC / "qc_schema_drift.csv").exists())

    def test_inventory_help(self) -> None:
        cmd = [sys.executable, str(SCRIPTS / "00_inventory_manifest.py"), "--help"]
        p = subprocess.run(cmd, capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr or p.stdout)


if __name__ == "__main__":
    unittest.main()
