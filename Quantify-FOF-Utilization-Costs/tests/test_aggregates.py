import csv
import os
import subprocess
import sys
import unittest
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = PROJECT_ROOT / "scripts"
AGG = PROJECT_ROOT / "outputs" / "aggregates" / "aim2_aggregates.csv"


class TestAggregates(unittest.TestCase):
    def _run(self, args):
        env = os.environ.copy()
        env.pop("DATA_ROOT", None)
        return subprocess.run(
            [sys.executable, str(SCRIPTS / "10_preprocess_tabular.py")] + args,
            capture_output=True,
            text=True,
            env=env,
        )

    def _remove_agg(self):
        if AGG.exists():
            AGG.unlink()

    def test_no_aggregates_by_default(self):
        self._remove_agg()
        p = self._run(["--use-sample"])
        self.assertEqual(p.returncode, 0, p.stderr or p.stdout)
        self.assertFalse(AGG.exists(), "Aggregates should not be written by default")

    def test_aggregates_require_env_gate(self):
        self._remove_agg()
        p = self._run(["--use-sample", "--allow-aggregates"])
        self.assertEqual(p.returncode, 0, p.stderr or p.stdout)
        self.assertFalse(AGG.exists(), "Aggregates should not be written without ALLOW_AGGREGATES=1")

    def test_aggregates_written_with_double_gate(self):
        self._remove_agg()
        env = os.environ.copy()
        env.pop("DATA_ROOT", None)
        env["ALLOW_AGGREGATES"] = "1"

        p = subprocess.run(
            [
                sys.executable,
                str(SCRIPTS / "10_preprocess_tabular.py"),
                "--use-sample",
                "--allow-aggregates",
            ],
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(p.returncode, 0, p.stderr or p.stdout)
        self.assertTrue(AGG.exists(), "Aggregates should be written with double gate enabled")

        with AGG.open("r", encoding="utf-8", newline="") as f:
            r = csv.reader(f)
            header = next(r)
            rows = list(r)

        self.assertNotIn("id", header, "Aggregates must not contain id column")
        self.assertIn("suppressed", header, "Aggregates must include suppression flag")

        suppressed_idx = header.index("suppressed")
        for row in rows:
            self.assertEqual(row[suppressed_idx], "1", "Sample groups should be suppressed (n<5)")


if __name__ == "__main__":
    unittest.main()
