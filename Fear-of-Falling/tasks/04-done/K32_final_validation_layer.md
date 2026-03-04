# K32 Final Validation Layer

## Context
Finalize K32 with a strict, analysis-only validation layer after metric construction is complete.

This task must only add validation analyses and reporting artifacts. It must not alter the K32 model structure, scoring logic, orientation rules, governance mechanics, or K30/K31 scripts.

## Inputs
- Existing K32 outputs and dataset:
  - `R-scripts/K32/outputs/k32_cfa_diagnostics.csv`
  - `R-scripts/K32/outputs/k32_scores_summary.csv`
  - `${DATA_ROOT}/paper_01/capacity_scores/kaatumisenpelko_with_capacity_scores_k32.rds` (preferred)
  - `${DATA_ROOT}/paper_01/capacity_scores/kaatumisenpelko_with_capacity_scores_k32.csv` (fallback)
- Existing K32 implementation (read-only for logic):
  - `R-scripts/K32/k32.r`

## Outputs
Implementation target (after task is moved to `01-ready`):
- New script:
  - `R-scripts/K32/k32_validation.r`
- New validation artifacts (repo outputs, aggregate/reporting only):
  - `R-scripts/K32/outputs/k32_validation_correlations.csv`
  - `R-scripts/K32/outputs/k32_validation_known_groups.csv`
  - `R-scripts/K32/outputs/k32_validation_distribution.csv`
  - `R-scripts/K32/outputs/k32_validation_latent_vs_z5.csv`
- Manifest:
  - append one row per in-repo validation artifact

## Definition of Done (DoD)
- Script `k32_validation.r` produces all four validation artifacts:
  1. Convergent validity:
     - `cor(K32_latent, z5_composite)`
     - `cor(K32_latent, gait)`
     - `cor(K32_latent, grip)`
  2. Known-groups validity:
     - If `frailty_group` exists: Kruskal-Wallis, group medians, and epsilon^2 or eta^2.
  3. Distribution diagnostics:
     - mean, sd, skewness, min, max, `% < -2 SD`, `% > +2 SD`.
  4. Latent vs z5 comparison:
     - correlation r
     - Bland-Altman mean difference
     - sd of difference.
- `qc-summarizer` remains PASS after this validation layer run.
- Leak-check remains clean:
  - no patient-level `with_capacity_scores*.csv/.rds` in repo outputs.
- K32 measurement pipeline remains unchanged:
  - no CFA structure changes
  - no sign-map changes
  - no orientation rule changes
  - no externalization logic changes
  - no K30/K31 changes
  - no manifest helper logic changes.

## Log
- 2026-03-01 Created backlog task for K32 final validation layer (analysis/reporting only, no metric changes).
- 2026-03-01 Moved task: `tasks/00-backlog/K32_final_validation_layer.md` -> `tasks/01-ready/K32_final_validation_layer.md` -> `tasks/02-in-progress/K32_final_validation_layer.md`.
- 2026-03-01 Implemented validation-only script: `R-scripts/K32/k32_validation.r`.
- 2026-03-01 Validation command (PASS):
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd /data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling && set -a && [ -f config/.env ] && . config/.env && set +a && /usr/bin/Rscript R-scripts/K32/k32_validation.r'`
- 2026-03-01 Validation result:
  - Produced artifacts:
    - `k32_validation_correlations.csv`
    - `k32_validation_known_groups.csv`
    - `k32_validation_distribution.csv`
    - `k32_validation_latent_vs_z5.csv`
  - Manifest rows appended for all four validation artifacts.
  - `qc-summarizer` re-run PASS:
    - `bash scripts/termux/run_qc_summarizer_proot.sh`
  - Leak-check PASS:
    - no `with_capacity_scores*.csv/.rds` under repo `R-scripts/*/outputs/`.

## Blockers
- Pending human review/approval in `tasks/03-review/`.

## Links
- Related completed implementation:
  - `tasks/03-review/K32_extended_capacity_primary.md`
  - `tasks/03-review/K32_loading_sign_mismatch_resolution.md`
