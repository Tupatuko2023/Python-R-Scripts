#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/config/.env"

if [ ! -f "${ENV_FILE}" ]; then
  echo "Missing config/.env (copy from config/.env.example)" >&2
  exit 1
fi

# Load without printing values
set -a
# shellcheck disable=SC1090
. "${ENV_FILE}"
set +a

# Fail-closed without leaking paths
if [ -z "${DATA_ROOT:-}" ]; then
  echo "DATA_ROOT missing (set it in config/.env)" >&2
  exit 1
fi
if [ ! -d "${DATA_ROOT}" ]; then
  echo "DATA_ROOT invalid (directory missing)" >&2
  exit 1
fi
