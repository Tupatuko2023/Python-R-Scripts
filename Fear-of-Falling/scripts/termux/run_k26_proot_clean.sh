#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# Canonical runner for K26. Forwards all args to the R script.
# Example:
# scripts/termux/run_k26_proot_clean.sh --input R-scripts/K15/outputs/K15_frailty_analysis_data.RData --include_balance TRUE --run_cat TRUE --run_score TRUE

proot-distro login debian --termux-home -- bash -lc '
  unset LD_PRELOAD LD_LIBRARY_PATH R_HOME R_LIBS R_LIBS_USER
  export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  cd ~/Python-R-Scripts/Fear-of-Falling
  exec /usr/bin/Rscript R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R "$@"
' bash "$@"
