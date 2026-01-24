#!/usr/bin/env python3
"""
repo_tools_server.py

Skeleton tool server that enforces filesystem RW/RO/never_touch scopes from
configs/tool_scopes.yaml and applies a git command allowlist.

Framework-agnostic: integrate the RepoTools methods into your MCP server library
of choice (stdio / http+sse). For now, this file includes a small CLI smoke
harness.
"""

from __future__ import annotations

import argparse
import dataclasses
import fnmatch
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

try:
    import yaml  # type: ignore
except Exception as e:  # pragma: no cover - startup dependency check
    raise RuntimeError("PyYAML is required. Install with: pip install pyyaml") from e


class PolicyError(Exception):
    """Raised when an operation violates tool_scopes policy."""


class ToolError(Exception):
    """Raised for tool execution failures (IO, git, etc.)."""


def jsonl_log(log_path: Path, event: Dict[str, Any]) -> None:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")


@dataclass(frozen=True)
class Scope:
    read_write: Tuple[str, ...] = ()
    read_only: Tuple[str, ...] = ()
    never_touch: Tuple[str, ...] = ()


@dataclass(frozen=True)
class RoleScopes:
    filesystem: Scope


@dataclass(frozen=True)
class ToolScopes:
    integrator: RoleScopes
    architect: RoleScopes
    quality_gate: RoleScopes


def _tupleize(xs: Optional[Iterable[str]]) -> Tuple[str, ...]:
    if not xs:
        return ()
    return tuple(xs)


def load_tool_scopes(yaml_path: Path) -> ToolScopes:
    data = yaml.safe_load(yaml_path.read_text(encoding="utf-8"))

    def read_role(role_name: str) -> RoleScopes:
        role = data.get(role_name, {})
        fs = role.get("filesystem", {})
        scope = Scope(
            read_write=_tupleize(fs.get("read_write")),
            read_only=_tupleize(fs.get("read_only")),
            never_touch=_tupleize(fs.get("never_touch")),
        )
        return RoleScopes(filesystem=scope)

    return ToolScopes(
        integrator=read_role("integrator"),
        architect=read_role("architect"),
        quality_gate=read_role("quality_gate"),
    )


def _normalize_repo_relative(repo_root: Path, user_path: str) -> Path:
    """
    Normalize user-supplied path to a repo-relative safe absolute path.
    Blocks path traversal outside repo_root.
    """
    if user_path is None:
        raise PolicyError("Path is required")

    clean = user_path.strip().lstrip("/").replace("\\", "/")
    target = (repo_root / clean).resolve()

    repo_root_resolved = repo_root.resolve()
    if repo_root_resolved not in target.parents and target != repo_root_resolved:
        raise PolicyError(f"Path traversal outside repo is not allowed: {user_path}")
    return target


def _repo_rel(repo_root: Path, abs_path: Path) -> str:
    return abs_path.resolve().relative_to(repo_root.resolve()).as_posix()


def _match_any(path_posix: str, patterns: Tuple[str, ...]) -> bool:
    for pat in patterns:
        pat_clean = pat.strip().lstrip("/").replace("\\", "/")
        if fnmatch.fnmatch(path_posix, pat_clean):
            return True
        try:
            if Path(path_posix).match(pat_clean):
                return True
        except Exception:
            pass
    return False


@dataclass
class PolicyEnforcer:
    repo_root: Path
    scopes: ToolScopes
    role: str
    log_file: Path

    def _role_scope(self) -> Scope:
        if self.role == "integrator":
            return self.scopes.integrator.filesystem
        if self.role == "architect":
            return self.scopes.architect.filesystem
        if self.role == "quality_gate":
            return self.scopes.quality_gate.filesystem
        raise PolicyError(f"Unknown role: {self.role}")

    def check_read(self, rel_path: str) -> None:
        scope = self._role_scope()
        if _match_any(rel_path, scope.never_touch):
            raise PolicyError(f"NEVER_TOUCH path: {rel_path}")
        if _match_any(rel_path, scope.read_write) or _match_any(
            rel_path, scope.read_only
        ):
            return
        raise PolicyError(f"Read not allowed by policy for role={self.role}: {rel_path}")

    def check_write(self, rel_path: str) -> None:
        scope = self._role_scope()
        if _match_any(rel_path, scope.never_touch):
            raise PolicyError(f"NEVER_TOUCH path: {rel_path}")
        if _match_any(rel_path, scope.read_write):
            return
        raise PolicyError(f"Write not allowed by policy for role={self.role}: {rel_path}")

    def log(self, event_type: str, **fields: Any) -> None:
        jsonl_log(
            self.log_file,
            {
                "event": event_type,
                "role": self.role,
                **fields,
            },
        )


@dataclass
class RepoTools:
    enforcer: PolicyEnforcer

    def read_text(self, path: str, max_bytes: int = 2_000_000) -> str:
        abs_path = _normalize_repo_relative(self.enforcer.repo_root, path)
        rel = _repo_rel(self.enforcer.repo_root, abs_path)
        self.enforcer.check_read(rel)

        self.enforcer.log("fs_read", path=rel)
        data = abs_path.read_bytes()
        if len(data) > max_bytes:
            raise ToolError(
                f"File too large ({len(data)} bytes). Increase max_bytes if needed."
            )
        return data.decode("utf-8", errors="replace")

    def list_dir(self, path: str = ".", max_entries: int = 500) -> List[Dict[str, Any]]:
        abs_path = _normalize_repo_relative(self.enforcer.repo_root, path)
        rel = _repo_rel(self.enforcer.repo_root, abs_path)
        self.enforcer.check_read(rel)

        if not abs_path.exists():
            raise ToolError(f"Directory not found: {rel}")
        if not abs_path.is_dir():
            raise ToolError(f"Not a directory: {rel}")

        items: List[Dict[str, Any]] = []
        for i, child in enumerate(sorted(abs_path.iterdir(), key=lambda p: p.name)):
            if i >= max_entries:
                break
            child_rel = _repo_rel(self.enforcer.repo_root, child)
            try:
                self.enforcer.check_read(child_rel)
                allowed = True
            except PolicyError:
                allowed = False
            items.append(
                {
                    "name": child.name,
                    "path": child_rel,
                    "is_dir": child.is_dir(),
                    "allowed": allowed,
                }
            )

        self.enforcer.log("fs_list", path=rel, returned=len(items))
        return items

    def write_text(
        self,
        path: str,
        content: str,
        create_dirs: bool = True,
        max_bytes: int = 2_000_000,
    ) -> Dict[str, Any]:
        abs_path = _normalize_repo_relative(self.enforcer.repo_root, path)
        rel = _repo_rel(self.enforcer.repo_root, abs_path)
        self.enforcer.check_write(rel)

        data = content.encode("utf-8")
        if len(data) > max_bytes:
            raise ToolError(
                f"Content too large ({len(data)} bytes). Increase max_bytes if needed."
            )

        if create_dirs:
            abs_path.parent.mkdir(parents=True, exist_ok=True)

        before = abs_path.read_text(encoding="utf-8", errors="replace") if abs_path.exists() else ""
        abs_path.write_bytes(data)
        after = abs_path.read_text(encoding="utf-8", errors="replace")

        diff_preview = unified_diff_preview(before, after, rel)

        self.enforcer.log("fs_write", path=rel, bytes=len(data))
        return {"path": rel, "bytes": len(data), "diff_preview": diff_preview}

    def replace_in_file(
        self,
        path: str,
        pattern: str,
        replacement: str,
        regex: bool = False,
        count: int = 0,
    ) -> Dict[str, Any]:
        abs_path = _normalize_repo_relative(self.enforcer.repo_root, path)
        rel = _repo_rel(self.enforcer.repo_root, abs_path)
        self.enforcer.check_write(rel)

        if not abs_path.exists() or not abs_path.is_file():
            raise ToolError(f"File not found: {rel}")

        before = abs_path.read_text(encoding="utf-8", errors="replace")

        if regex:
            try:
                new_text, n = re.subn(pattern, replacement, before, count=count)
            except re.error as e:
                raise ToolError(f"Invalid regex: {e}") from e
        else:
            if pattern == "":
                raise ToolError("Pattern must not be empty.")
            if count == 0:
                n = before.count(pattern)
                new_text = before.replace(pattern, replacement)
            else:
                n = 0
                new_text = before
                for _ in range(count):
                    idx = new_text.find(pattern)
                    if idx < 0:
                        break
                    new_text = new_text[:idx] + replacement + new_text[idx + len(pattern) :]
                    n += 1

        if new_text == before:
            self.enforcer.log("replace_noop", path=rel, replacements=0)
            return {"path": rel, "replacements": 0, "diff_preview": ""}

        abs_path.write_text(new_text, encoding="utf-8")
        diff_preview = unified_diff_preview(before, new_text, rel)

        self.enforcer.log("replace_in_file", path=rel, replacements=n, regex=regex)
        return {"path": rel, "replacements": n, "diff_preview": diff_preview}

    def git(self, args: List[str], timeout_sec: int = 30) -> Dict[str, Any]:
        if not args:
            raise ToolError("git args required")

        subcmd = args[0]
        if subcmd not in GIT_ALLOWLIST:
            raise PolicyError(f"git subcommand not allowed: {subcmd}")

        banned = {"--hard", "--force", "-f"}
        if any(a in banned for a in args):
            raise PolicyError(f"git flags not allowed: {args}")

        self.enforcer.log("git", args=args)

        try:
            proc = subprocess.run(
                ["git", *args],
                cwd=str(self.enforcer.repo_root),
                capture_output=True,
                text=True,
                timeout=timeout_sec,
                check=False,
            )
        except subprocess.TimeoutExpired as e:
            raise ToolError(f"git timeout: {e}") from e

        out = proc.stdout
        err = proc.stderr
        if proc.returncode != 0:
            raise ToolError(f"git failed rc={proc.returncode}\nSTDOUT:\n{out}\nSTDERR:\n{err}")

        return {"stdout": out, "stderr": err, "returncode": proc.returncode}


GIT_ALLOWLIST = {"status", "diff", "checkout", "add", "commit"}


def unified_diff_preview(
    before: str, after: str, rel_path: str, max_lines: int = 200
) -> str:
    import difflib

    diff = difflib.unified_diff(
        before.splitlines(True),
        after.splitlines(True),
        fromfile=f"a/{rel_path}",
        tofile=f"b/{rel_path}",
        lineterm="",
    )
    lines = list(diff)
    if len(lines) > max_lines:
        lines = lines[:max_lines] + ["(diff truncated)"]
    return "\n".join(lines)


def build_tools(repo_root: Path, scopes_path: Path, role: str, log_file: Path) -> RepoTools:
    scopes = load_tool_scopes(scopes_path)
    enforcer = PolicyEnforcer(
        repo_root=repo_root,
        scopes=scopes,
        role=role,
        log_file=log_file,
    )
    return RepoTools(enforcer=enforcer)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-root", default=".", help="Path to repo root")
    ap.add_argument(
        "--scopes", default="configs/tool_scopes.yaml", help="Path to tool_scopes.yaml"
    )
    ap.add_argument(
        "--role",
        default="integrator",
        choices=["integrator", "architect", "quality_gate"],
    )
    ap.add_argument(
        "--log",
        default="manifest/repo_tools.jsonl",
        help="JSONL log output (kept under manifest for auditability)",
    )
    args = ap.parse_args()

    repo_root = Path(args.repo_root).resolve()
    scopes_path = (repo_root / args.scopes).resolve()
    log_file = (repo_root / args.log).resolve()

    tools = build_tools(
        repo_root=repo_root,
        scopes_path=scopes_path,
        role=args.role,
        log_file=log_file,
    )

    print(f"Loaded scopes from: {scopes_path}")
    print(f"Role: {args.role}")
    try:
        items = tools.list_dir(".")
        print(json.dumps(items[:20], ensure_ascii=False, indent=2))
    except Exception as e:
        print(f"SMOKE ERROR: {e}", file=sys.stderr)
        sys.exit(1)

    print("OK (CLI harness).")


if __name__ == "__main__":
    main()
