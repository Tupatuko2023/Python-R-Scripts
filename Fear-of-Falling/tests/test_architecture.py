import unittest
import os
from pathlib import Path
import sys

# Add parent to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from mcp_servers.filesystem_guard import FileSystemGuard, SecurityError
from mcp_servers.repo_tools_server import RepoToolsServer
from agents.codex_mcp import FakeCodexMCPServer

class TestFileSystemGuard(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(os.path.abspath("."))
        self.config_path = self.repo_root / "configs/tool_scopes.json"

        # Ensure config exists (it should from previous steps)
        if not self.config_path.exists():
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

    def test_git_allowlist_and_roles(self):
        server = RepoToolsServer()
        with self.assertRaises(SecurityError):
            server.run_git(["checkout", "main"], "integrator")
        with self.assertRaises(SecurityError):
            server.run_git(["add", "R-scripts/test_script.R"], "quality_gate")
        with self.assertRaises(SecurityError):
            server.run_git(["commit", "-m", "msg"], "integrator")

    def test_replace_in_file(self):
        server = RepoToolsServer()
        rel_path = "R-scripts/zz_replace_in_file_test.txt"
        abs_path = self.repo_root / rel_path
        try:
            with open(abs_path, "w", encoding="utf-8") as f:
                f.write("hello world\n")
            diff = server.replace_in_file(rel_path, "world", "there", "integrator")
            self.assertIn("there", diff)
            with open(abs_path, "r", encoding="utf-8") as f:
                self.assertEqual(f.read(), "hello there\n")
        finally:
            if abs_path.exists():
                abs_path.unlink()

    def test_fake_codex_mcp(self):
        server = FakeCodexMCPServer()
        server.start()
        try:
            response = server.send_request({"jsonrpc": "2.0", "id": 1, "method": "ping", "params": {}})
            self.assertEqual(response["result"]["content"][0]["text"], "stub-ok")
        finally:
            server.stop()

if __name__ == '__main__':
    unittest.main()
