# K35 Capacity CFA Behavior Report

## Context
K32 latent capacity score is now available and admissible, and K26 is canonical for primary modeling.
Before extending primary models, we need an aggregate-only reporting pack that makes K32 score behavior transparent for interpretation and manuscript reporting.

This task is reporting-only. No model-structure changes.

## Inputs
- `R-scripts/K32/outputs/k32_cfa_diagnostics.csv`
- `R-scripts/K32/outputs/k32_scores_summary.csv`
- `${DATA_ROOT}/paper_01/capacity_scores/kaatumisenpelko_with_capacity_scores_k32.rds`
- Existing K32 validation outputs under `R-scripts/K32/outputs/`

## Outputs
- Aggregate reporting artifacts under `R-scripts/K35/outputs/`:
  - `k35_capacity_behavior_summary.csv`
  - `k35_capacity_distribution.csv`
  - `k35_capacity_vs_z_composite.csv`
  - `k35_capacity_reporting_notes.txt`
- Manifest rows for these aggregate artifacts.

## Scope Rules
- Do not modify K32 measurement code, admissibility logic, or score orientation.
- Do not modify K26 models in this task.
- Do not write patient-level outputs into repo.
- Patient-level data reads are allowed from DATA_ROOT only for aggregation.

## Definition of Done (DoD)
- Reporting pack artifacts are generated and manifested.
- Outputs are aggregate-only (no row-level export to repo).
- `bash scripts/termux/run_qc_summarizer_proot.sh` and `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` remain PASS.

## Log
- 2026-03-01 18:08: Backlog task created and scoped as aggregate-only CFA behavior/reporting layer.
- 2026-03-01 18:11: Task moved `tasks/01-ready -> tasks/02-in-progress`.
- 2026-03-01 18:19: Implemented `R-scripts/K35/k35.r` (aggregate-only reporting script).
- 2026-03-01 18:19: Ran K35 via proot with env loaded:
  - `/usr/bin/Rscript R-scripts/K35/k35.r`
  - PASS, generated:
    - `R-scripts/K35/outputs/k35_capacity_behavior_summary.csv`
    - `R-scripts/K35/outputs/k35_capacity_distribution.csv`
    - `R-scripts/K35/outputs/k35_capacity_vs_z_composite.csv`
    - `R-scripts/K35/outputs/k35_capacity_reporting_notes.txt`
    - `R-scripts/K35/outputs/k35_sessioninfo.txt`
  - Manifest rows appended (`K35` labels).
- 2026-03-01 18:20: Post-validation:
  - `bash scripts/termux/run_qc_summarizer_proot.sh` PASS.
  - `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` PASS.
  - Leak-check for `with_capacity_scores*` and `analysis*` repo-output patterns: empty.

## Blockers
- None.

## Links
- `docs/ANALYSIS_PLAN.md`
- `R-scripts/K32/k32.r`
- `tasks/04-done/K32_extended_capacity_primary.md`
