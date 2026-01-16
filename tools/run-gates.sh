#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"

usage() {
  cat >&2 << 'EOF'
run-gates.sh

Deterministic "before analysis run" gate:
  - guardrails (no data/outputs/binaries committed)
  - renv lock sanity (no restore here)
  - metadata dump (git hash + sessionInfo/renv diagnostics)

Usage:
  tools/run-gates.sh --mode pre-push --smoke
  tools/run-gates.sh --mode analysis --project Fear-of-Falling --rscript "R-scripts/K05/K05.WIDE_ANCOVA.V1_main.R"

EOF
}

MODE="analysis"
SMOKE=0
PROJECT=""
RSCRIPT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --mode) MODE="$2"; shift 2 ;;
    --smoke) SMOKE=1; shift 1 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --rscript) RSCRIPT_PATH="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

# Always run guardrails (fast)
bash "${ROOT}/tools/forbid-large-or-sensitive.sh" --mode "${MODE}"
bash "${ROOT}/tools/check-renv.sh" --mode "${MODE}"

if [[ "${SMOKE}" -eq 1 ]]; then
  bash "${ROOT}/tools/check-r-syntax.sh" --mode "${MODE}"
  bash "${ROOT}/tools/check-python.sh" --mode "${MODE}"
  echo "OK: smoke gates (${MODE})" >&2
  exit 0
fi

if [[ -z "${PROJECT}" ]]; then
  echo "ERROR: --project is required for analysis mode" >&2
  exit 2
fi

PROJ_ROOT="${ROOT}/${PROJECT}"
if [[ ! -d "${PROJ_ROOT}" ]]; then
  echo "ERROR: project not found: ${PROJECT}" >&2
  exit 2
fi

# Metadata dump path (project-local, audit friendly)
TS="$(date +%Y%m%d_%H%M%S)"
GIT_HASH="$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo NA)"
META_DIR="${PROJ_ROOT}/manifest"
mkdir -p "${META_DIR}"

META_FILE="${META_DIR}/run_meta_${TS}.txt"
{
  echo "timestamp=${TS}"
  echo "git_hash=${GIT_HASH}"
  echo "project=${PROJECT}"
  echo "mode=${MODE}"
  echo "pwd=${PROJ_ROOT}"
  echo "script=${RSCRIPT_PATH:-}"
} > "${META_FILE}"

if command -v Rscript >/dev/null 2>&1; then
  Rscript -q -e "cat(capture.output(sessionInfo()), sep='\n')" \
    > "${META_DIR}/sessionInfo_${TS}.txt" || true
  if Rscript -q -e "if (requireNamespace('renv', quietly=TRUE)) renv::diagnostics() else quit(status=0)" \
      > "${META_DIR}/renv_diagnostics_${TS}.txt" 2>&1; then
    :
  fi
fi

echo "OK: metadata written to ${META_DIR}/(run_meta, sessionInfo, renv_diagnostics) ${TS}" >&2

SCRIPT_ABS=""
if [[ -n "${RSCRIPT_PATH}" ]]; then
  if [[ -f "${PROJ_ROOT}/${RSCRIPT_PATH}" ]]; then
    SCRIPT_ABS="${PROJ_ROOT}/${RSCRIPT_PATH}"
  elif [[ -f "${ROOT}/${RSCRIPT_PATH}" ]]; then
    SCRIPT_ABS="${ROOT}/${RSCRIPT_PATH}"
  else
    echo "ERROR: --rscript not found: ${RSCRIPT_PATH}" >&2
    exit 2
  fi

  echo "Running Rscript: ${RSCRIPT_PATH}" >&2
  (cd "${PROJ_ROOT}" && Rscript "${SCRIPT_ABS}")
fi
