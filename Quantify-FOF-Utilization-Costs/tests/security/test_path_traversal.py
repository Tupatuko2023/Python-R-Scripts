import unittest
from pathlib import Path
import sys
import os

# Add scripts to path for import
PROJECT_ROOT = Path(__file__).resolve().parents[2]
sys.path.append(str(PROJECT_ROOT / "scripts"))

from _io_utils import safe_join_path

class TestPathTraversal(unittest.TestCase):
    def setUp(self):
        self.base_dir = (PROJECT_ROOT / "tests" / "temp_security_test").resolve()
        self.base_dir.mkdir(parents=True, exist_ok=True)
        
    def tearDown(self):
        if self.base_dir.exists():
            import shutil
            shutil.rmtree(self.base_dir)

    def test_safe_join_valid(self):
        # Valid relative path
        rel_path = "valid.csv"
        result = safe_join_path(self.base_dir, rel_path)
        self.assertEqual(result, self.base_dir / rel_path)

    def test_safe_join_traversal_denied(self):
        # Path traversal attempt
        rel_path = "../../../etc/passwd"
        with self.assertRaisesRegex(ValueError, "Security Violation: Path traversal detected"):
            safe_join_path(self.base_dir, rel_path)

    def test_safe_join_absolute_traversal_denied(self):
        # Absolute path traversal (even if technically under base if we are at root, but usually it's outside)
        # Note: safe_join_path uses (base / relative).resolve()
        # if relative is absolute, Path(base / "/etc/passwd") becomes Path("/etc/passwd") on Posix
        rel_path = "/etc/passwd"
        with self.assertRaisesRegex(ValueError, "Security Violation: Path traversal detected"):
            safe_join_path(self.base_dir, rel_path)

    def test_safe_join_no_leak(self):
        # Ensure base path is not in error message
        rel_path = "../forbidden"
        try:
            safe_join_path(self.base_dir, rel_path)
        except ValueError as e:
            self.assertNotIn(str(self.base_dir), str(e))

if __name__ == "__main__":
    unittest.main()
