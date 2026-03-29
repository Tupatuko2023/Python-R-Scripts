# K45 Sensitivity MICE for Missing Covariates Only

## Context

This K45 is an analysis-repo sensitivity task in `Fear-of-Falling`.
It is not a dissertation-repo writing task.

Primary analyses (K41/K42) remain complete-follow-up and unchanged.
K45 is a sensitivity analysis to evaluate whether missing baseline covariates/exposures materially affect conclusions.

Task-gate status: review-ready (`tasks/03-review/` after execution).

## Objective

Implement a deterministic, governance-safe MICE sensitivity workflow that imputes baseline covariates/exposures only and compares pooled estimates against complete-case estimates.

## Critical Scope Lock

In scope:

- MICE for baseline covariates/exposures only.
- Pooled model estimates via Rubin's rules.
- Side-by-side comparison tables (pooled vs complete-case).

Out of scope:

- Do not impute 12-month outcome (`Composite_Z_12m`) or other follow-up outcome measurements.
- Do not replace or rewrite primary complete-case analyses.
- No patient-level exports to repository.

## Inputs

Primary inputs from DATA_ROOT:

- K33 canonical long/wide analysis datasets.
- K32 capacity score dataset.
- K40 frailty index dataset.

Reference inputs from repository:

- K41/K42 complete-case aggregate outputs for comparison anchors.

## Deterministic Imputation Rules

- Use `mice` with fixed seed and fixed `m` (default `m = 20`).
- Impute only baseline covariates/exposures used by extended models, including:
  - age
  - sex
  - bmi
  - fof_status
  - frailty category / baseline frailty covariates (if used)
  - `capacity_score_latent_primary`
  - `frailty_index_fi_k40_z`
- Do not impute outcome-at-follow-up fields.
- Keep outcome availability rule unchanged from primary analyses.
- Log imputation method per variable and predictor matrix used.

## Models to Re-run as Sensitivity

- K42 BOTH-model sensitivity (long + wide where applicable).
- Optional aligned sensitivity reruns for K41/K36-style extended models if required by final manuscript table structure.

## Required Outputs (Aggregate-Only)

Under `R-scripts/K45/outputs/`:

- `k45_mice_missingness_summary.csv`
- `k45_mice_methods_and_predictor_matrix.txt`
- `k45_pooled_coefficients_k42_both.csv`
- `k45_complete_case_vs_pooled_comparison.csv`
- `k45_fraction_missing_information.csv`
- `k45_mice_diagnostics_traceplot.png`
- `k45_mice_diagnostics_density.png`
- `k45_decision_log.txt`
- `k45_external_input_receipt.txt`
- `k45_sessioninfo.txt`

Optional:

- `k45_model_comparison_summary.csv` (if K41/K36/K42 pooled comparisons are all included).

## Governance

- Read patient-level inputs from DATA_ROOT only.
- Repository outputs must be aggregate artifacts/logs/receipts only.
- No patient-level CSV/RDS in repository outputs.
- External input receipt must include paths + md5 + nrow/ncol for DATA_ROOT files used.

## Core Reporting Requirements

K45 must explicitly report:

- `N` before and after covariate-only imputation eligibility.
- Whether key terms retain direction and approximate magnitude.
- Whether conclusions are directionally consistent with complete-case analyses.

## Reproduction Commands

`[TERMUX]`

```sh
cd Python-R-Scripts/Fear-of-Falling
bash scripts/termux/run_k45_proot.sh
bash scripts/termux/run_qc_summarizer_proot.sh
bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling
```

## Acceptance Criteria

- K45 runs end-to-end with fixed seed and documented MICE setup.
- No follow-up outcome imputation is performed.
- Pooled estimates and complete-case estimates are reported side by side.
- Key head-to-head terms (`time×capacity`, `time×FI`) are explicitly compared for directional consistency.
- Outputs are aggregate-only; leak-check passes.
- QC summarizer and analysis gates pass.

## Definition of Done

- K45 outputs exist with full diagnostics and comparison tables.
- Manifest rows appended for K45 artifacts.
- Task moved to `tasks/03-review/` with PASS evidence.

## Log

- 2026-03-03 18:58 created K45 backlog card with covariates-only MICE scope lock.
- 2026-03-03 moved card `00-backlog -> 01-ready -> 02-in-progress`.
- 2026-03-03 implemented:
  - `R-scripts/K45/k45.r`
  - `scripts/termux/run_k45_proot.sh`
- 2026-03-03 execution commands:
  - `bash scripts/termux/run_k45_proot.sh` -> PASS (exit 0)
  - `bash scripts/termux/run_qc_summarizer_proot.sh` -> PASS (exit 0)
  - `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` -> PASS (exit 0)
  - `rg -n "^id,|participant|jnro|nro" R-scripts/K45/outputs/*.csv || true` -> no hits
- 2026-03-03 core evidence:
  - `n_wide_outcome_complete=276`, `n_wide_complete_case=236`, `n_wide_after_mice=276`
  - `n_long_outcome_rows=552`, `n_long_complete_case_rows=472`, `n_long_after_mice_rows=552`
  - `time:capacity_score_latent_primary` direction consistent (CC `0.01409` vs pooled `0.01327`)
  - `time:frailty_index_fi_k40_z` direction consistent (CC `-0.01024` vs pooled `-0.00707`)
  - Governance note in decision log: aggregate-only outputs, no patient-level exports
- 2026-03-03 manifest rows appended for all required K45 artifacts.
- 2026-03-03 manuscript-support docs added under `docs/reports/`:
  - `results.md` (head-to-head results narrative aligned with K42/K44)
  - `Reviewer_Defense_Summary.md` (8-point reviewer defense bullets)
  - note: documentation-only addition; no analysis model changes.
- 2026-03-03 scope lock reaffirmed:
  - no changes were made to model formulas or estimation procedures relative to K42
  - K45 evaluates baseline covariate missingness only.

## Blockers

- None.
