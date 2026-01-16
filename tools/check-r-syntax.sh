#!/usr/bin/env bash
set -euo pipefail

MODE="${2:-generic}"
ROOT="$(git rev-parse --show-toplevel)"

note() { printf "%s\n" "$*" >&2; }
die() { printf "ERROR: %s\n" "$*" >&2; exit 1; }

FILES="$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.R$' || true)"
if [[ -z "${FILES}" ]]; then
  note "OK: no staged .R files (${MODE})"
  exit 0
fi

if ! command -v Rscript >/dev/null 2>&1; then
  note "WARN: Rscript not found; skipping R syntax parse (${MODE})"
  exit 0
fi

note "R syntax parse (${MODE}) for staged files:"
note "${FILES}"

while IFS= read -r f; do
  [[ -z "${f}" ]] && continue
  if [[ ! -f "${ROOT}/${f}" ]]; then
    continue
  fi
  Rscript -q -e "parse(file='${ROOT}/${f}')" \
    || die "R parse failed: ${f}"
done <<< "${FILES}"

note "OK: R syntax parse (${MODE})"
