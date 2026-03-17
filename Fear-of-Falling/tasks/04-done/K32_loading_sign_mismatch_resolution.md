# K32 Loading Sign Mismatch Resolution

## Context

K32 reviewer close-out found that CFA diagnostics are currently inadmissible because objective loading signs are mixed:

- `k32_cfa_diagnostics.csv`: `admissible=FALSE`
- `reason=loading_sign_mismatch` (both primary and sensitivity)
- `k32_scores_summary.csv`: latent score counts are `0` (all latent scores intentionally `NA`)

Because the acceptance gate for K32 primary latent score requires admissibility and populated latent scores, K32 cannot be moved to `04-done` yet.

## Inputs

- `R-scripts/K32/k32.r`
- `R-scripts/K32/outputs/k32_cfa_primary_loadings.csv`
- `R-scripts/K32/outputs/k32_cfa_diagnostics.csv`
- `R-scripts/K32/outputs/k32_scores_summary.csv`
- `data/Muuttujasanakirja.md`
- `data/data_dictionary.csv`

## Outputs

- Backlog task only in this phase:
  - `tasks/00-backlog/K32_loading_sign_mismatch_resolution.md`
- Future implementation (only after moving to `01-ready`):
  - minimal K32 sign-orientation correction at indicator construction stage
  - regenerated K32 outputs + manifest rows

## Definition of Done (DoD)

- Task contains deterministic implementation rules for when moved to `01-ready`:
  - verify indicator direction from codebook (not fit chasing)
  - apply orientation harmonization so objective indicators load in the same conceptual direction (higher capacity = better)
  - keep CFA model structure fixed (no MI-based residual covariance tuning)
  - retain admissibility gate unchanged
  - latent scores only released if gate passes
- Validation must show:
  - `k32_cfa_diagnostics.csv`: `admissible=TRUE` (primary at minimum)
  - `k32_scores_summary.csv`: latent score `n > 0`
  - externalization + receipt + leak-check remain compliant

## Log

- 2026-03-01 Created blocker task after K32 reviewer check found `loading_sign_mismatch` and latent `n=0`.
- 2026-03-01 Moved task: `tasks/00-backlog/K32_loading_sign_mismatch_resolution.md` -> `tasks/01-ready/K32_loading_sign_mismatch_resolution.md` -> `tasks/02-in-progress/K32_loading_sign_mismatch_resolution.md`.
- 2026-03-01 Implemented deterministic sign handling in `R-scripts/K32/k32.r`:
  - expected sign map: `grip:+; gait:+; chair:-; balance:+; self_report:+`
  - orientation rule: flip latent scores if gait loading is negative OR majority expected-positive indicators are negative
  - admissibility sign check now compares against expected map after deterministic orientation
- 2026-03-01 Validation command (PASS):
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd /data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling && set -a && [ -f config/.env ] && . config/.env && set +a && /usr/bin/Rscript R-scripts/K32/k32.r'`
- 2026-03-01 Validation result:
  - `k32_cfa_diagnostics.csv`: `admissible=TRUE` (primary + sensitivity), `reason=admissible`
  - `k32_scores_summary.csv`: `capacity_score_latent_primary` n=276
  - governance preserved: receipt updated, external outputs under `${DATA_ROOT}/paper_01/capacity_scores`, leak-check clean

## Blockers

- Pending human review/approval in `tasks/03-review/`.

## Links

- Blocked close-out task:
  - `tasks/03-review/K32_extended_capacity_primary.md`
