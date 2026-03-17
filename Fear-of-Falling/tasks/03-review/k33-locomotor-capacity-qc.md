# K33 locomotor_capacity primary alignment and K18 QC unblock

## Context

- Follow-up after `tasks/03-review/locomotor-capacity-primary.md`.
- Remaining active correctness gap: `K33` still exports legacy `Composite_Z`-shaped long/wide data and then fails in the `K18` QC handoff.
- Authoritative contract: `docs/ANALYSIS_PLAN.md`.
- Outcome roles:
  - `locomotor_capacity` = current primary outcome
  - `z3` = deterministic fallback / sensitivity outcome
  - `Composite_Z` = legacy bridge only
- Constraints: minimal reversible diffs, no raw-data edits, max 5 files changed this run, one manifest row per artifact, safe mode for legacy artifact cleanup.

## Inputs

- `docs/ANALYSIS_PLAN.md`
- `tasks/03-review/locomotor-capacity-primary.md`
- `R-scripts/K33/k33.r`
- `R-scripts/K18/K18_QC.V1_qc-run.R`

## Outputs

- K33 patient-level contract aligned to locomotor_capacity primary + z3 fallback
- K18 QC blocker fixed or narrowed to one precise reproducible failure point
- Review note with rerun status, outputs regenerated, and remaining blockers

## Definition of Done (DoD)

- Follow-up task moves only `01-ready -> 02-in-progress -> 03-review`
- K33 no longer exports active current-primary data only as `Composite_Z`
- K33 receipt/QC/manifest use outcome-explicit labels
- K33 rerun succeeds, or exact K18 blocker is isolated with file/function context
- K35 still reruns after corrected upstream contract

## Log

- 2026-03-17 16:41:22+0200 Follow-up task created for K33 locomotor_capacity contract alignment and K18 QC unblock
- 2026-03-17 16:42:31+0200 Read `docs/ANALYSIS_PLAN.md` and `tasks/03-review/locomotor-capacity-primary.md`; confirmed that K35-K38 were already aligned and this run only needs to close the remaining K33 + K18 gap.
- 2026-03-17 16:45:19+0200 Audited `R-scripts/K33/k33.r` and confirmed legacy `Composite_Z_baseline`, `Composite_Z_12m`, `delta_composite_z`, and long-column `Composite_Z` were still the active export contract.
- 2026-03-17 16:46:08+0200 Audited K18 QC failure path. Root cause was twofold: `K33` handed `K18` an `.rds` file while `K18` only used `read.csv()`, and QC also counted ordinary `NA` outcome gaps as `nonfinite`.
- 2026-03-17 16:53:14+0200 Patched `K33`, `K18_QC.V1_qc-run.R`, and `R/functions/qc.R` with outcome-explicit contract handling, robust input loading, and NA-safe nonfinite counting.
- 2026-03-17 16:59:32+0200 Reran `K33` successfully through K18 QC in Debian PRoot; `qc_status_summary.csv` reports `overall_pass=TRUE`.
- 2026-03-17 17:01:09+0200 Reran `K35` after corrected upstream handoff; status PASS.

## Blockers

- `tasks/_template.md` is not present under `Fear-of-Falling/tasks/`; using direct task instantiation again.
- Historical `fof_analysis_k33_long/wide.*` files remain under `DATA_ROOT/paper_01/analysis/`; they were not deleted in this safe-mode run and should be treated as superseded legacy bridge exports.

## Links

- Prior review: `tasks/03-review/locomotor-capacity-primary.md`
- Prompt packet: `prompts/3_6cafofv2.txt`

## Summary

- Files changed this run:
  - `R-scripts/K33/k33.r`
  - `R-scripts/K18/K18_QC.V1_qc-run.R`
  - `R/functions/qc.R`
- This run closed the last active correctness gap left after K35-K38 alignment: K33 now exports outcome-explicit locomotor_capacity-primary patient-level data and K18 QC can validate it end-to-end.

## Root Cause

- `K33` still wrote legacy bridge-shaped long/wide datasets (`Composite_Z_baseline`, `Composite_Z_12m`, `delta_composite_z`, long `Composite_Z`) and passed the long `.rds` file to `K18`.
- `K18` tried to read every input via `read.csv()`, so the `.rds` payload surfaced as embedded-null warnings and later broke the `qc_id_integrity_long` path.
- `R/functions/qc.R::qc_outcome_summary()` also counted missing outcomes (`NA`) as nonfinite, which falsely failed the QC gate even after the file-type issue was fixed.

## What Changed

- `K33` no longer builds active current-primary exports from K15 `Composite_Z` columns.
- `K33` now reads canonical `fof_analysis_k50_long/wide` inputs and writes outcome-explicit files:
  - `fof_analysis_k33_locomotor_capacity_primary_long.*`
  - `fof_analysis_k33_locomotor_capacity_primary_wide.*`
- `K33` receipt now states:
  - `primary_outcome=locomotor_capacity`
  - `fallback_outcome=z3`
  - `legacy_bridge_outcome=Composite_Z`
- `K18` now supports `.rds` and `.csv` input, resolves the active long/wide outcome branch from `locomotor_capacity`, `z3`, or legacy `Composite_Z`, and no longer hardcodes `Composite_Z` as the only valid current-primary QC outcome.
- `qc_id_integrity_long()` now builds `coverage_dist` robustly.
- `qc_outcome_summary()` now counts only true nonfinite values and does not treat plain `NA` as an integrity failure.

## Rerun Status

- `R-scripts/K33/k33.r`: PASS
- `R-scripts/K18/K18_QC.V1_qc-run.R` via K33 handoff: PASS
- `R-scripts/K35/k35.r`: PASS

## Outputs Regenerated

- `R-scripts/K33/outputs/k33_qc_gates.csv`
- `R-scripts/K33/outputs/k33_patient_level_output_receipt.txt`
- `R-scripts/K33/outputs/k33_sessioninfo.txt`
- `R-scripts/K18/outputs/K18_QC/qc/qc_status_summary.csv`
- `R-scripts/K18/outputs/K18_QC/qc/qc_uniqueness.csv`
- `R-scripts/K18/outputs/K18_QC/qc/qc_id_timepoint_coverage_dist.csv`
- `R-scripts/K18/outputs/K18_QC/qc/qc_outcome_summary.csv`
- `DATA_ROOT/paper_01/analysis/fof_analysis_k33_locomotor_capacity_primary_long.csv`
- `DATA_ROOT/paper_01/analysis/fof_analysis_k33_locomotor_capacity_primary_long.rds`
- `DATA_ROOT/paper_01/analysis/fof_analysis_k33_locomotor_capacity_primary_wide.csv`
- `DATA_ROOT/paper_01/analysis/fof_analysis_k33_locomotor_capacity_primary_wide.rds`

## Key Contract Check

- Active K33 exports are no longer `Composite_Z`-only.
- K18 QC `qc_status_summary.csv` now reports all checks `TRUE`, including `outcome_nonfinite=TRUE` with `n_nonfinite=0`.
- `K35` still reruns successfully after the upstream change.

## Manual Review

- Treat old `fof_analysis_k33_long/wide.*` files as superseded legacy bridge exports until a future cleanup run is explicitly approved.
- If the team wants legacy bridge support to stay rerunnable, that should be added as a separate labeled `Composite_Z` branch rather than reusing the active K33 current-primary contract.
