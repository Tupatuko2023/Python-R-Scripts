#!/usr/bin/env bash
set -euo pipefail

MODE="${2:-generic}"
ROOT="$(git rev-parse --show-toplevel)"

die() { printf "ERROR: %s\n" "$*" >&2; exit 1; }
note() { printf "%s\n" "$*" >&2; }

STAGED="$(git diff --cached --name-only --diff-filter=ACMR || true)"

if [[ -z "${STAGED}" ]]; then
  exit 0
fi

# Policy: do not commit raw-ish data / outputs / archives by accident.
FORBID_DIR_REGEX='^(Fear-of-Falling/)?(data/external|out|outputs|tables)/'
FORBID_EXT_REGEX='(\.xlsx$|\.xls$|\.sav$|\.dta$|\.rds$|\.RData$|\.pkl$|\.zip$|\.7z$|\.tar$|\.gz$|\.bz2$)'

# Size guardrail (bytes). Default 5 MB.
MAX_BYTES="${MAX_BYTES:-5242880}"

while IFS= read -r f; do
  [[ -z "${f}" ]] && continue

  if echo "${f}" | grep -Eq "${FORBID_DIR_REGEX}"; then
    die "Staged file under forbidden directory: ${f} (move it out or gitignore it)"
  fi

  if echo "${f}" | grep -Eqi "${FORBID_EXT_REGEX}"; then
    die "Staged forbidden/binary/archive file type: ${f}"
  fi

  # Large file check (only if file exists in working tree)
  if [[ -f "${ROOT}/${f}" ]]; then
    sz="$(wc -c < "${ROOT}/${f}" | tr -d ' ')"
    if [[ "${sz}" -gt "${MAX_BYTES}" ]]; then
      die "Staged file too large (${sz} bytes > ${MAX_BYTES}): ${f}"
    fi
  fi
done <<< "${STAGED}"

note "OK: guardrails (${MODE})"
