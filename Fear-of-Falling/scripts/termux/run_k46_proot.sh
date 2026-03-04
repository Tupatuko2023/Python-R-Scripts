#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Forward optional arguments to inner shell via env var.
K46_ARGS="${*:-}"

proot-distro login debian --termux-home -- bash -lc '
  set -euo pipefail
  unset LD_PRELOAD LD_LIBRARY_PATH R_HOME R_LIBS R_LIBS_USER
  export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  cd ~/Python-R-Scripts/Fear-of-Falling
  if [ -f config/.env ]; then
    set -a
    source config/.env
    set +a
  fi
  # shellcheck disable=SC2086
  exec /usr/bin/Rscript R-scripts/K46/k46.r ${K46_ARGS:-}
'
