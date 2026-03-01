# K15 Externalize Frailty Outputs

## Context
K32 known-groups validation currently skips because `frailty_cat` is not available in an external K15 patient-level dataset under `DATA_ROOT`.

This task must make K15 produce and externalize a patient-level frailty dataset (including `frailty_cat`) to:
- `${DATA_ROOT}/paper_01/frailty/`

This is a one-at-a-time prerequisite task before K32 known-groups can be fully populated.

## Inputs
- K15 scripts and current outputs:
  - `R-scripts/K15/K15.R` (observed canonical script path)
  - `R-scripts/K15/outputs/*`
- K32 validation consumer:
  - `R-scripts/K32/k32_validation.r`
- Environment:
  - `config/.env` with `DATA_ROOT`

## Outputs
- Future implementation artifacts (after task is moved to `01-ready`):
  - K15 external patient-level frailty dataset:
    - `${DATA_ROOT}/paper_01/frailty/kaatumisenpelko_with_frailty_k15.csv`
    - `${DATA_ROOT}/paper_01/frailty/kaatumisenpelko_with_frailty_k15.rds`
  - In-repo receipt artifact:
    - `R-scripts/K15/outputs/k15_patient_level_frailty_output_receipt.txt`
  - Manifest append:
    - receipt row only (no external file paths in manifest)
- Then downstream:
  - `R-scripts/K32/outputs/k32_validation_known_groups.csv` no longer skipped when re-run

## Definition of Done (DoD)
- K15 implementation (future `01-ready` step):
  - ensure final K15 patient-level analysis dataframe contains `frailty_cat` (and existing frailty score variables where available)
  - write patient-level `.csv` + `.rds` only to `${DATA_ROOT}/paper_01/frailty/`
  - if `DATA_ROOT` missing: stop with an informative error
  - write repo receipt with:
    - external paths
    - `nrow`/`ncol`
    - md5 checksums
  - append manifest row for receipt only
- Governance:
  - no patient-level frailty files under repo `R-scripts/K15/outputs/` except receipt text
  - repo outputs remain aggregate/diagnostic/receipt only
  - do not change K30/K31/K32 measurement logic or manifest helper logic in this task
- Validation requirements after implementation:
  - K15 run PASS
  - external files exist and contain `frailty_cat`
  - `bash scripts/termux/run_qc_summarizer_proot.sh` PASS
  - re-run `R-scripts/K32/k32_validation.r`; known-groups no longer emits deterministic skip

## Log
- 2026-03-01 Created backlog task from template.
- 2026-03-01 Reconnaissance:
  - K15 currently has many aggregate outputs in `R-scripts/K15/outputs/`.
  - Existing K15 patient-level `.RData` artifacts are in repo outputs and not externalized under `${DATA_ROOT}/paper_01/frailty/`.
  - `${DATA_ROOT}/paper_01/` currently shows `capacity_scores/`; no `frailty/` externalized dataset observed.
  - K15 entry script observed as `R-scripts/K15/K15.R` (uppercase filename).
- 2026-03-01 Moved task: `tasks/00-backlog/K15_externalize_frailty_outputs.md` -> `tasks/01-ready/K15_externalize_frailty_outputs.md` -> `tasks/02-in-progress/K15_externalize_frailty_outputs.md`.
- 2026-03-01 Implemented in `R-scripts/K15/K15.R`:
  - DATA_ROOT guard (stop with informative error if missing)
  - patient-level frailty dataset externalization to `${DATA_ROOT}/paper_01/frailty/`
  - files written:
    - `kaatumisenpelko_with_frailty_k15.csv/.rds`
    - compatibility aliases: `kaatumisenpelko_with_frailty_scores.csv/.rds`
  - canonical aliases added for downstream join:
    - `frailty_cat` (from `frailty_cat_3`)
    - `frailty_score` (from `frailty_score_3`)
  - receipt written in-repo:
    - `R-scripts/K15/outputs/k15_patient_level_frailty_output_receipt.txt`
  - manifest appended for receipt only.
  - legacy in-repo patient-level file `K15_frailty_analysis_data.RData` removed if present.
- 2026-03-01 Validation commands (PASS):
  - `proot-distro login debian --termux-home -- bash -lc '... /usr/bin/Rscript R-scripts/K15/K15.R'`
  - `proot-distro login debian --termux-home -- bash -lc '... /usr/bin/Rscript R-scripts/K32/k32_validation.r'`
  - `bash scripts/termux/run_qc_summarizer_proot.sh`
- 2026-03-01 Validation results:
  - external frailty files exist under `${DATA_ROOT}/paper_01/frailty/`
  - external RDS contains `frailty_cat=TRUE` and `frailty_score_3=TRUE`
  - `k32_validation_known_groups.csv` no longer skipped:
    - uses `frailty_cat_from_k15`
    - Kruskal-Wallis statistics and group medians populated
  - governance preserved:
    - receipt in repo outputs
    - no new in-repo patient-level frailty dataset output from K15 run
    - qc-summarizer PASS

## Blockers
- Pending human review/approval in `tasks/03-review/`.

## Links
- Dependent task:
  - `tasks/03-review/K32_validation_join_frailty_from_K15.md`
