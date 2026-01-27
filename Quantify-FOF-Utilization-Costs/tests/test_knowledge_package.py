import os
import subprocess
import sys
import unittest
import zipfile
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = PROJECT_ROOT / "scripts"
OUT_ZIP = PROJECT_ROOT / "outputs" / "knowledge" / "knowledge_package.zip"
INDEX = PROJECT_ROOT / "outputs" / "knowledge" / "index.json"


class TestKnowledgePackage(unittest.TestCase):
    def test_build_package_ci_safe(self):
        env = os.environ.copy()
        env.pop("DATA_ROOT", None)

        if OUT_ZIP.exists():
            OUT_ZIP.unlink()
        if INDEX.exists():
            INDEX.unlink()

        p = subprocess.run(
            [sys.executable, str(SCRIPTS / "40_build_knowledge_package.py")],
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(p.returncode, 0, p.stderr or p.stdout)
        self.assertTrue(OUT_ZIP.exists())
        self.assertTrue(INDEX.exists())

        with zipfile.ZipFile(OUT_ZIP, "r") as z:
            names = set(z.namelist())

        self.assertIn("data/data_dictionary.csv", names)
        self.assertIn("data/VARIABLE_STANDARDIZATION.csv", names)
        self.assertIn("manifest/dataset_manifest.csv", names)
        self.assertIn("manifest/run_log.csv", names)
        self.assertIn("docs/aggregate_formats.md", names)
        self.assertIn("docs/reporting.md", names)
        self.assertIn("docs/knowledge_package.md", names)

        self.assertNotIn("config/.env", names)

        for n in names:
            self.assertFalse(n.startswith("outputs/"), f"Unexpected outputs content in zip: {n}")


if __name__ == "__main__":
    unittest.main()
