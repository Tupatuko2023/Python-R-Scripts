# K15 add frailty_score_3 to RData (canonical upstream fix)

## Objective
Add canonical continuous frailty score to K15 output dataset before RData save:
`frailty_score_3 = as.numeric(frailty_count_3)`.

This unblocks K26 canonical-only rerun (`cat+score`) without any fallback logic.

## Scope
- Patch only `R-scripts/K15/K15.R` with a minimal, deterministic block.
- Do not modify raw CSV.
- Do not introduce alternative frailty proxies.

## Required behavior
- If `frailty_count_3` is missing at derivation point: `stop()`.
- If `frailty_score_3` is absent: create it as numeric `frailty_count_3`.
- Keep existing K15 derivation logic unchanged otherwise.

## Run commands
1. Rerun K15 in clean proot env:
`proot-distro login debian --termux-home -- bash -lc 'unset LD_PRELOAD LD_LIBRARY_PATH R_HOME R_LIBS R_LIBS_USER; export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd ~/Python-R-Scripts/Fear-of-Falling; /usr/bin/Rscript R-scripts/K15/K15.R'`

2. Validate RData columns:
`proot-distro login debian --termux-home -- bash -lc 'unset LD_PRELOAD LD_LIBRARY_PATH R_HOME R_LIBS R_LIBS_USER; export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd ~/Python-R-Scripts/Fear-of-Falling; /usr/bin/Rscript -e "e<-new.env(parent=emptyenv()); load(\"R-scripts/K15/outputs/K15_frailty_analysis_data.RData\", envir=e); d<-get(\"analysis_data\", e); cat(\"frailty_cat_3:\", \"frailty_cat_3\" %in% names(d), \"\\n\"); cat(\"frailty_score_3:\", \"frailty_score_3\" %in% names(d), \"\\n\"); cat(\"score_equals_count:\", isTRUE(all.equal(as.numeric(d$frailty_count_3), d$frailty_score_3, check.attributes=FALSE)), \"\\n\")"'`

3. Rerun K26 canonical-only:
`scripts/termux/run_k26_proot_clean.sh --input R-scripts/K15/outputs/K15_frailty_analysis_data.RData --include_balance TRUE --run_cat TRUE --run_score TRUE`

## Acceptance criteria
- `R-scripts/K15/outputs/K15_frailty_analysis_data.RData` contains:
  - `frailty_count_3`
  - `frailty_cat_3`
  - `frailty_score_3`
- `frailty_score_3` equals `as.numeric(frailty_count_3)` (NA-safe).
- K26 rerun succeeds with canonical-only gate and no fallback.

## Status
- 2026-02-24: created in `tasks/01-ready`.
- 2026-02-24: patch applied to `R-scripts/K15/K15.R`:
  - fail-fast if `frailty_count_3` missing before save
  - add `frailty_score_3 = as.numeric(frailty_count_3)` if absent
- 2026-02-24: K15 rerun PASS in clean proot env.
- 2026-02-24: validation PASS:
  - `frailty_cat_3: TRUE`
  - `frailty_score_3: TRUE`
  - `score_equals_count: TRUE`
