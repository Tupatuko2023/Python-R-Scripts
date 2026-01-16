#!/usr/bin/env bash
set -euo pipefail

MODE="${2:-generic}"
ROOT="$(git rev-parse --show-toplevel)"

note() { printf "%s\n" "$*" >&2; }

# Only run if repo indicates Python project structure.
HAS_PY=0
if [[ -f "${ROOT}/pyproject.toml" ]] || [[ -f "${ROOT}/requirements.txt" ]] || [[ -d "${ROOT}/src" ]]; then
  HAS_PY=1
fi

if [[ "${HAS_PY}" -eq 0 ]]; then
  note "OK: no Python project indicators found (${MODE})"
  exit 0
fi

if ! command -v python >/dev/null 2>&1; then
  note "WARN: python not found; skipping python checks (${MODE})"
  exit 0
fi

# Lightweight: compile staged .py (syntax)
FILES="$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.py$' || true)"
if [[ -z "${FILES}" ]]; then
  note "OK: no staged .py files (${MODE})"
  exit 0
fi

note "Python compile (${MODE}) for staged files:"
note "${FILES}"

python - << 'PY'
import os
import py_compile
import subprocess
import sys

files = subprocess.check_output(
    ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
    text=True,
).splitlines()
py_files = [f for f in files if f.endswith(".py")]
ok = True
for f in py_files:
    if not os.path.exists(f):
        continue
    try:
        py_compile.compile(f, doraise=True)
    except Exception as exc:
        ok = False
        print(f"ERROR: python syntax failed: {f}: {exc}", file=sys.stderr)
sys.exit(0 if ok else 2)
PY

note "OK: python checks (${MODE})"
