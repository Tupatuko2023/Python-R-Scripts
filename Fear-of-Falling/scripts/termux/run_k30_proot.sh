#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Run K30 in Debian proot with repo config/.env loaded in the same shell.
# Usage:
#   scripts/termux/run_k30_proot.sh

proot-distro login debian --termux-home -- bash -lc '
  set -euo pipefail
  unset LD_PRELOAD LD_LIBRARY_PATH R_HOME R_LIBS R_LIBS_USER
  export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

  cd Python-R-Scripts/Fear-of-Falling
  if [ -f config/.env ]; then
    set -a
    . config/.env
    set +a
  fi

  : "${DATA_ROOT:=}"
  echo "DATA_ROOT=${DATA_ROOT:-<unset>}"
  exec /usr/bin/Rscript R-scripts/K30/k30.r
'
