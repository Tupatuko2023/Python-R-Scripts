import unittest
from pathlib import Path
import sys
import os

# Add scripts to path to import _io_utils
# Current file: Quantify-FOF-Utilization-Costs/tests/security/test_path_traversal.py
# PROJECT_ROOT: Quantify-FOF-Utilization-Costs/
PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.append(str(PROJECT_ROOT / "scripts"))

from _io_utils import safe_join_path

class TestPathTraversal(unittest.TestCase):
    def setUp(self):
        self.base = (PROJECT_ROOT / "data").resolve()

    def test_safe_join_valid(self):
        result = safe_join_path(self.base, "VARIABLE_STANDARDIZATION.csv")
        self.assertEqual(result, self.base / "VARIABLE_STANDARDIZATION.csv")

    def test_safe_join_nested_valid(self):
        # Create a dummy dir for testing
        nested_dir = self.base / "nested"
        result = safe_join_path(self.base, "nested", "file.txt")
        # resolve() will handle it even if it doesn't exist
        self.assertEqual(result, self.base / "nested" / "file.txt")

    def test_safe_join_traversal_fails(self):
        with self.assertRaises(ValueError) as cm:
            safe_join_path(self.base, "../README.md")
        self.assertEqual(str(cm.exception), "Security Violation: Path traversal detected or path outside restricted boundary.")

    def test_safe_join_absolute_traversal_fails(self):
        with self.assertRaises(ValueError):
            # pathlib.Path.joinpath('/base', '/etc/passwd') -> '/etc/passwd'
            safe_join_path(self.base, "/etc/passwd")

    def test_safe_join_complex_traversal_fails(self):
        with self.assertRaises(ValueError):
            safe_join_path(self.base, "normal/../../etc/passwd")

    def test_safe_join_sibling_directory_fails(self):
        # If base is /app/data, then /app/data_sensitive should be blocked
        # even though it starts with the same string.
        sibling_base = self.base.parent / (self.base.name + "_sensitive")
        with self.assertRaises(ValueError):
            # This simulates joined path becoming /app/data_sensitive
            # In our case, parts are joined to base.
            # So we try to join something that results in a sibling.
            safe_join_path(self.base, f"../{sibling_base.name}/file.txt")

    def test_no_absolute_path_leakage(self):
        secret_base = Path("/tmp/extremely_secret_data_root")
        # Even if the path doesn't exist, safe_join_path should fail securely
        try:
            safe_join_path(secret_base, "../../etc/passwd")
        except ValueError as e:
            msg = str(e)
            self.assertEqual(msg, "Security Violation: Path traversal detected or path outside restricted boundary.")
            self.assertNotIn("extremely_secret", msg)
            self.assertNotIn("/tmp", msg)
            self.assertNotIn("etc", msg)

if __name__ == "__main__":
    unittest.main()
