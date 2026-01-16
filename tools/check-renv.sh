#!/usr/bin/env bash
set -euo pipefail

MODE="${2:-generic}"
ROOT="$(git rev-parse --show-toplevel)"

note() { printf "%s\n" "$*" >&2; }
die() { printf "ERROR: %s\n" "$*" >&2; exit 1; }

# Only enforce presence/sanity where renv.lock exists.
if [[ -f "${ROOT}/Fear-of-Falling/renv.lock" ]]; then
  LOCK="${ROOT}/Fear-of-Falling/renv.lock"
elif [[ -f "${ROOT}/renv.lock" ]]; then
  LOCK="${ROOT}/renv.lock"
else
  note "OK: renv.lock not found (skipping) (${MODE})"
  exit 0
fi

note "renv: found lockfile at: ${LOCK}"

# Light validation: lockfile must be readable by renv::lockfile_read.
if command -v Rscript >/dev/null 2>&1; then
  Rscript -e "ok <- TRUE; tryCatch({ if (!requireNamespace('renv', quietly=TRUE)) stop('renv not installed'); renv::lockfile_read('${LOCK}'); }, error=function(e){ message(e\$message); ok <- FALSE }); if (!ok) quit(status=2)" \
    || die "renv lockfile read failed. Fix renv.lock or install renv."
else
  note "WARN: Rscript not available; cannot validate renv.lock read."
fi

note "OK: renv check (${MODE})"
