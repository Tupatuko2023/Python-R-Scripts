# K26 rerun with canonical frailty variables (frailty_cat_3 / frailty_score_3)

## Context

Methodological gate for K26: fallback frailty derivations are explicitly rejected. K26 must be rerun only when canonical frailty columns exist in source data.

## Inputs

- K15 frailty-augmented RData (canonical upstream output), for example:
  - `R-scripts/K15/outputs/K15_frailty_analysis_data.RData`
  - or `R-scripts/K15_MAIN/outputs/K15_frailty_analysis_data.RData`
- Runner: `scripts/termux/run_k26_proot_clean.sh`

## Outputs

- `R-scripts/K26/outputs/K26/K26_LMM_MOD/` updated K26 runtime artifacts
- `manifest/manifest.csv` updated with new K26 rows
- `R-scripts/K26/outputs/K26/K26_LMM_MOD/K26_frailty_provenance.txt` showing canonical sources and fallback flags

## Definition of Done (DoD)

- K26 rerun executed with canonical frailty columns present.
- Provenance shows:
  - `frailty_score_source=K15_RData`
  - `frailty_cat_source=K15_RData`
  - `fallback_used=FALSE`
  - `crosscheck_ok=TRUE`
  - `placeholder_used=FALSE`
- Manifest has one row per produced K26 artifact key (`script,label,kind,path`) for rerun outputs.

## Log

- 2026-02-24 00:00:00 Task created in 00-backlog.
- 2026-02-24 00:01:00 Moved to 01-ready.
- 2026-02-24 00:10:00 Deterministic K15 input discovery:
  - `grep -n "K15" manifest/manifest.csv | grep -i "rdata" | tail -n 60`
  - Found manifest path: `R-scripts/K15_MAIN/outputs/K15_frailty_analysis_data.RData`
  - Found filesystem path: `R-scripts/K15/outputs/K15_frailty_analysis_data.RData`
- 2026-02-24 00:12:00 Preflight (proot clean env) loaded `analysis_data` from K15 RData:
  - `frailty_cat_3`: present
  - `frailty_score_3`: missing
  - baseline/follow-up outcome columns: present
- 2026-02-24 00:14:00 K26 rerun attempt with canonical input:
  - `scripts/termux/run_k26_proot_clean.sh --input R-scripts/K15/outputs/K15_frailty_analysis_data.RData --include_balance TRUE --run_cat TRUE --run_score TRUE`
  - Result: `Error: Missing required canonical frailty column(s): frailty_score_3`
- 2026-02-24 00:15:00 Cross-check all K15 RData variants:
  - `R-scripts/K15/outputs/K15_frailty_analysis_data.RData` -> has_cat=TRUE, has_score=FALSE
  - `R-scripts/K15_MAIN/outputs/K15_frailty_analysis_data.RData` -> has_cat=TRUE, has_score=FALSE
  - Conclusion: rerun remains blocked upstream until K15 output includes canonical `frailty_score_3`.
- 2026-02-24 00:20:00 Upstream K15 fix applied and rerun completed:
  - K15 now writes canonical `frailty_score_3 = as.numeric(frailty_count_3)` to `analysis_data` before RData save.
  - K15 validation PASS: `frailty_cat_3=TRUE`, `frailty_score_3=TRUE`, `score_equals_count=TRUE`.
- 2026-02-24 00:22:00 K26 canonical-only rerun PASS:
  - `scripts/termux/run_k26_proot_clean.sh --input R-scripts/K15/outputs/K15_frailty_analysis_data.RData --include_balance TRUE --run_cat TRUE --run_score TRUE`
  - Provenance PASS:
    - `frailty_score_source=K15_RData`
    - `frailty_cat_source=K15_RData`
    - `fallback_used=FALSE`
    - `crosscheck_ok=TRUE` in both modes
  - Outputs refreshed in `R-scripts/K26/outputs/K26/K26_LMM_MOD/`.
  - Manifest note: K26 artifact keys already existed; project append/dedupe flow retained single-key rows.

## Blockers

- None. Blocker cleared by upstream K15 canonical score fix.

## Links

- `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R`
- `tasks/03-review/K26_LMM_MOD_time-frailty-CompositeZ0_moderation.md`

## Canonical run command

- Find K15 RData path deterministically:
  - `grep -n "K15" manifest/manifest.csv | grep -i "rdata" | tail -n 40`
  - `find R-scripts/K15 R-scripts/K15_MAIN -maxdepth 4 -type f -name "*.RData" 2>/dev/null | sort`
- Run K26 with canonical K15 RData:
  - `scripts/termux/run_k26_proot_clean.sh --input <K15_RDATA_PATH> --include_balance TRUE --run_cat TRUE --run_score TRUE`
