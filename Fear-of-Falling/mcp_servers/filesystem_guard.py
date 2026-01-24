import json
import os
import fnmatch
from pathlib import Path
from typing import List, Dict, Optional

class SecurityError(Exception):
    pass

class FileSystemGuard:
    def __init__(self, config_path: str, repo_root: str):
        self.repo_root = Path(repo_root).resolve()
        with open(config_path, 'r') as f:
            self.config = json.load(f)

    def _match_patterns(self, rel_path_str: str, patterns: List[str]) -> bool:
        """Checks if the relative path matches any of the glob patterns."""
        for pattern in patterns:
            # Handle recursive glob ** manually if fnmatch doesn't support it fully in all envs
            # But standard fnmatch usually works well enough for simple cases.
            # We will use fnmatch.fnmatch which is shell-style.
            # For strict recursive matching, we might need regex, but let's try fnmatch first.
            if fnmatch.fnmatch(rel_path_str, pattern):
                return True

            # Special handling for directory prefixes if pattern ends with /**
            if pattern.endswith("/**"):
                prefix = pattern[:-3]
                if rel_path_str.startswith(prefix + "/") or rel_path_str == prefix:
                    return True
        return False

    def get_role_policy(self, role: str) -> Dict:
        if role not in self.config["roles"]:
            raise ValueError(f"Unknown role: {role}")
        return self.config["roles"][role]

    def validate_path(self, path: str, role: str, operation: str) -> str:
        """
        Validates access to a path for a given role and operation ('read' or 'write').
        Returns the absolute path if allowed, raises SecurityError otherwise.
        """
        # 1. Resolve Path
        abs_path = (self.repo_root / path).resolve()

        # Ensure path is within repo root
        if not str(abs_path).startswith(str(self.repo_root)):
             raise SecurityError(f"Access denied: Path '{path}' attempts to escape repository root.")

        rel_path = abs_path.relative_to(self.repo_root)
        rel_path_str = str(rel_path)

        policy = self.get_role_policy(role)

        # 2. Check Never Touch (Blacklist)
        if self._match_patterns(rel_path_str, policy.get("never_touch", [])):
            raise SecurityError(f"Access denied: Path '{rel_path_str}' is in the 'never_touch' list for role '{role}'.")

        # 3. Check Operation Permissions
        allowed = False

        if operation == "write":
            if self._match_patterns(rel_path_str, policy.get("read_write", [])):
                allowed = True
        elif operation == "read":
            # Read allowed if in read_write OR read_only
            if self._match_patterns(rel_path_str, policy.get("read_write", [])):
                allowed = True
            elif self._match_patterns(rel_path_str, policy.get("read_only", [])):
                allowed = True
        else:
            raise ValueError(f"Unknown operation: {operation}")

        if not allowed:
            raise SecurityError(f"Access denied: Role '{role}' does not have '{operation}' permission for '{rel_path_str}'.")

        return str(abs_path)

    def validate_git_command(self, args: List[str], role: str):
        """
        Validates if a git command is allowed.
        args: list of command arguments, e.g. ["commit", "-m", "msg"] (excluding 'git')
        """
        if not args:
            raise SecurityError("Empty git command.")

        subcommand = args[0]
        allowlist = self.config.get("git_allowlist", [])

        if subcommand not in allowlist:
            raise SecurityError(f"Git subcommand '{subcommand}' is not allowed.")

        if subcommand == "checkout":
            if len(args) < 2 or args[1] != "-b":
                raise SecurityError("Only 'git checkout -b <branch>' is allowed.")

        # Enforce Read-Only roles cannot write via git
        # 'integrator' is the only role allowed to perform state-changing git operations
        # defined in the allowlist (add, commit, checkout).
        # 'architect' and 'quality_gate' are strictly read-only.

        write_git_commands = ["add", "commit", "checkout"]

        if role != "integrator" and subcommand in write_git_commands:
             raise SecurityError(f"Role '{role}' is read-only and cannot execute state-changing git command '{subcommand}'.")
