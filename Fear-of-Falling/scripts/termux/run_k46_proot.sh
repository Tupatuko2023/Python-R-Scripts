#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

proot-distro login debian --termux-home -- bash -lc '
  unset LD_PRELOAD LD_LIBRARY_PATH R_HOME R_LIBS R_LIBS_USER
  export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  cd ~/Python-R-Scripts/Fear-of-Falling
  set -a
  source config/.env
  set +a
  exec /usr/bin/Rscript R-scripts/K46/k46.r "$@"
' bash "$@"
