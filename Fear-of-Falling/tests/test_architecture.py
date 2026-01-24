import unittest
import os
import shutil
import json
from pathlib import Path
import sys

# Add parent to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from mcp_servers.filesystem_guard import FileSystemGuard, SecurityError

class TestFileSystemGuard(unittest.TestCase):
    def setUp(self):
        # Prefer subproject root relative to this file for CI runs from repo root.
        self.repo_root = Path(__file__).resolve().parents[1]
        self.config_path = self.repo_root / "configs/tool_scopes.json"
        if not self.config_path.exists():
            fallback = Path(os.path.abspath(".")) / "Fear-of-Falling" / "configs/tool_scopes.json"
            if fallback.exists():
                self.repo_root = fallback.parents[1]
                self.config_path = fallback
            else:
                self.fail("Config file not found")

        self.guard = FileSystemGuard(str(self.config_path), str(self.repo_root))

    def test_integrator_allowed_write(self):
        # Integrator can write to R-scripts
        path = "R-scripts/test_script.R"
        abs_path = self.guard.validate_path(path, "integrator", "write")
        self.assertTrue(abs_path.endswith(path))

    def test_integrator_denied_write(self):
        # Integrator cannot write to data
        path = "data/raw.csv"
        with self.assertRaises(SecurityError):
            self.guard.validate_path(path, "integrator", "write")

    def test_architect_denied_write(self):
        # Architect cannot write anywhere
        path = "R-scripts/plan.md"
        with self.assertRaises(SecurityError):
            self.guard.validate_path(path, "architect", "write")

    def test_architect_allowed_read(self):
        # Architect can read everything
        path = "data/raw.csv"
        abs_path = self.guard.validate_path(path, "architect", "read")
        self.assertTrue(abs_path.endswith(path))

    def test_never_touch(self):
        # No one can touch .git
        path = ".git/HEAD"
        with self.assertRaises(SecurityError):
            self.guard.validate_path(path, "integrator", "read")
        with self.assertRaises(SecurityError):
            self.guard.validate_path(path, "architect", "read")

    def test_path_traversal(self):
        # Cannot escape root
        path = "../outside.txt"
        with self.assertRaises(SecurityError):
            self.guard.validate_path(path, "integrator", "read")

    def test_git_guard(self):
        # Integrator can commit
        try:
            self.guard.validate_git_command(["commit", "-m", "msg"], "integrator")
        except SecurityError:
            self.fail("Integrator should be able to commit")

        # Quality Gate cannot commit
        with self.assertRaises(SecurityError):
            self.guard.validate_git_command(["commit", "-m", "msg"], "quality_gate")

        # Quality Gate can status
        try:
            self.guard.validate_git_command(["status"], "quality_gate")
        except SecurityError:
             self.fail("Quality Gate should be able to status")

if __name__ == '__main__':
    unittest.main()
