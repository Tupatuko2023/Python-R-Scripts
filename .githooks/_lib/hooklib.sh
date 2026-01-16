#!/usr/bin/env bash
set -euo pipefail

hook_echo() { printf "%s\n" "$*" >&2; }
hook_fail() { hook_echo "ERROR: $*"; exit 1; }

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || true
}

in_repo_or_fail() {
  local root
  root="$(repo_root)"
  [[ -n "${root}" ]] || hook_fail "Not inside a git repository."
}

skip_if_requested() {
  # Emergency bypass: SKIP=1 git commit ...
  if [[ "${SKIP:-0}" == "1" ]]; then
    hook_echo "SKIP=1 set -> skipping hooks."
    exit 0
  fi
}

staged_files() {
  git diff --cached --name-only --diff-filter=ACMR
}

changed_r_files() {
  staged_files | grep -E '\.R$' || true
}

has_file() {
  [[ -f "$1" ]]
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_tool() {
  local root tool
  root="$(repo_root)"
  tool="$1"
  shift || true
  [[ -x "${root}/${tool}" ]] || hook_fail "Missing executable tool: ${tool}"
  "${root}/${tool}" "$@"
}

project_hint() {
  local files
  files="$(staged_files || true)"
  if echo "${files}" | grep -q '^Fear-of-Falling/'; then
    hook_echo "Detected staged changes under Fear-of-Falling/ (run gates from repo root)."
  fi
}
