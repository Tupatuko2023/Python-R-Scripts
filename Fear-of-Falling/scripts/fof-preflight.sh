#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
FOF_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
PRECHECK="$FOF_ROOT/../.codex/skills/fof-preflight/scripts/preflight.py"

if [ ! -f "$PRECHECK" ]; then
  echo "FATAL: missing preflight checker: $PRECHECK" >&2
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "FATAL: python/python3 not found in PATH" >&2
  exit 1
fi

cd "$FOF_ROOT"
exec "$PY" "$PRECHECK" "$@"
