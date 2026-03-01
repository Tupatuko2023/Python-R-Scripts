# K32 Extended Capacity Primary (Secondary Model)

## Context
Create a new controlled task for a deterministic 4-5 indicator extended latent Capacity model as a new script `R-scripts/K32/k32.r`.

No code changes are allowed until this task is moved to `tasks/01-ready/`, then to `tasks/02-in-progress/`.

K30 and K31 must remain unchanged.

## Inputs
- Source dataset:
  - Prefer analysis-ready input from K30/K31 flow when available.
  - Support deterministic loader strategy during implementation phase.
- Deterministic indicator set:
  - `puristus0_clean` (or rebuilt from `puristus0` if missing)
  - `kavelynopeus_m_sek0` (primary: `0 -> NA`; sensitivity: `0` retained)
  - `tuoli0`
  - `seisominen0`
  - `vaikeus_liikkua_500m` (ordered self-report; max one self-report indicator)

## Outputs
- Backlog task spec only in this phase:
  - `tasks/00-backlog/K32_extended_capacity_primary.md`
- Future implementation artifacts (only after task is 01-ready):
  - `R-scripts/K32/k32.r`
  - `R-scripts/K32/outputs/*`
  - `manifest/manifest.csv` appended with one row per in-repo artifact

## Definition of Done (DoD)
- Backlog task exists and clearly specifies:
  - fixed indicator set above
  - CFA estimator: `lavaan` with `WLSMV` (ordered mobility variable)
  - deterministic admissibility gate:
    - no negative residual variances
    - no `Std.all > 1`
    - convergence successful
    - low factor score NA share
    - coherent loading signs
  - fallback policy:
    - always compute 4-5 indicator z-composites
    - if latent inadmissible, latent score stays `NA` and composite is recommended
- No changes made to `K30`/`K31` scripts in backlog phase.
- No execution of `k32.r` in backlog phase.

## Log
- 2026-03-01 Created backlog task from template with deterministic K32 extended CFA specification.
- 2026-03-01 Moved task: `tasks/00-backlog/K32_extended_capacity_primary.md` -> `tasks/01-ready/K32_extended_capacity_primary.md` -> `tasks/02-in-progress/K32_extended_capacity_primary.md`.
- 2026-03-01 Implemented `R-scripts/K32/k32.r` as deterministic 4-5 indicator extended CFA + admissibility gate + z-composite fallback.
- 2026-03-01 Validation command (PASS):
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd /data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling && set -a && . config/.env && set +a && /usr/bin/Rscript R-scripts/K32/k32.r'`
- 2026-03-01 Validation result:
  - K32 outputs created under `R-scripts/K32/outputs/`
  - external patient-level files written to `${DATA_ROOT}/paper_01/capacity_scores/`:
    - `kaatumisenpelko_with_capacity_scores_k32.csv`
    - `kaatumisenpelko_with_capacity_scores_k32.rds`
  - manifest rows appended for K32 in-repo artifacts (including receipt + sessioninfo)
- 2026-03-01 Reviewer close-out check: governance PASS (receipt + md5 + leak-check), but model gate FAIL (`k32_cfa_diagnostics.csv`: `admissible=FALSE`, `reason=loading_sign_mismatch`; latent score `n=0` in `k32_scores_summary.csv`). Created blocker backlog task `K32_loading_sign_mismatch_resolution`.
- 2026-03-01 Blocker resolved via `K32_loading_sign_mismatch_resolution` implementation:
  - expected sign map + deterministic orientation rule added in `k32.r`
  - latest `k32_cfa_diagnostics.csv`: `admissible=TRUE`
  - latest `k32_scores_summary.csv`: latent `n=276`

## Blockers
- No active technical blocker. Pending human approval to move task to `04-done`.

## Links
- Planned implementation target: `R-scripts/K32/k32.r`
- Related prior tasks:
  - `K30_capacity_score`
  - `K30_extended_capacity_latent_secondary`
