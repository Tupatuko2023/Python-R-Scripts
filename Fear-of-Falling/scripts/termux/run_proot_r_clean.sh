#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Usage:
#   scripts/termux/run_proot_r_clean.sh -- -e 'sessionInfo()'
# Always runs Debian proot /usr/bin/Rscript with cleaned env.

if [ "${1:-}" = "--" ]; then
  shift
fi

proot-distro login debian --termux-home -- bash -lc '
  unset LD_PRELOAD LD_LIBRARY_PATH R_HOME R_LIBS R_LIBS_USER
  export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  exec /usr/bin/Rscript "$@"
' bash "$@"
