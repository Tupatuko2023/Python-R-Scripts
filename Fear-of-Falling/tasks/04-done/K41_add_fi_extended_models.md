# K41 Add FI Extended Models (K26-Canonical + K40 FI)

## Context

This K41 is an analysis-repo R implementation task in `Fear-of-Falling`.
It is not a dissertation-repo writing task.

K40 is now completed and provides deterministic FI (`frailty_index_fi_k40`, `frailty_index_fi_k40_z`) without performance-test tautology or primary-exposure leakage.
K41 uses FI only as an extended layer on top of canonical models, preserving canonical primary models unchanged.

Task-gate status: implementation completed in `tasks/02-in-progress/`; this card is ready to move to `tasks/03-review/` for human approval.

## Objective

Run K26-equivalent canonical primary models and FI-extended variants side-by-side with a mandatory common-sample rule, to test whether vulnerability (FI) adds explanatory value beyond canonical baseline model structure.

## Inputs

- Required external inputs from `${DATA_ROOT}`:
  `${DATA_ROOT}/paper_01/analysis/` K33 canonical long/wide analysis datasets;
  `${DATA_ROOT}/paper_01/frailty_vulnerability/` K40 FI dataset.
- Required variables:
  `id`, canonical model variables from K26/K33, and `frailty_index_fi_k40_z`.
- Repo references:
  `manifest/manifest.csv`, `config/.env`.

## Scope

- Implemented files:
  `R-scripts/K41/k41.r`,
  `scripts/termux/run_k41_proot.sh`.
- Deterministic join strategy:
  join K40 FI to K33 by `id` using resolver logic consistent with K36.
- Model policy:
  canonical primary models are not altered;
  FI is added only in extended models.
- Deterministic model set:
  LMM (long):
  primary = canonical K26 structure;
  extended = primary + `frailty_index_fi_k40_z` + `time:frailty_index_fi_k40_z`.
  ANCOVA (wide):
  primary = canonical K26 structure;
  extended = primary + `frailty_index_fi_k40_z`.
- Mandatory common-sample rule:
  primary and extended comparisons must use identical sample for each model family.
  Report explicitly:
  `n_long_primary`, `n_long_extended`, `n_long_common`,
  `n_wide_primary`, `n_wide_extended`, `n_wide_common`.
- Governance:
  no patient-level exports to repo;
  repo outputs aggregate-only + receipt/sessioninfo/decision log/manifest rows.

## Implemented Deterministic Steps

1. Resolve `DATA_ROOT` and input paths from `config/.env`/env.
2. Load K33 long/wide and K40 FI external datasets.
3. Join by `id`, derive common-sample masks for long and wide comparisons.
4. Fit canonical primary models on common samples.
5. Fit FI-extended models on same common samples.
6. Produce coefficient tables, model-comparison tables, and decision log.
7. Write aggregate-only artifacts to `R-scripts/K41/outputs/` and append manifest rows.
8. Validate with:
   `bash scripts/termux/run_k41_proot.sh`,
   `bash scripts/termux/run_qc_summarizer_proot.sh`,
   `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling`,
   leak-check pass.

## Outputs

- Repo aggregate artifacts only under `R-scripts/K41/outputs/`:
  `k41_lmm_primary_coefficients.csv`,
  `k41_lmm_extended_coefficients.csv`,
  `k41_lmm_model_comparison.csv`,
  `k41_ancova_primary_coefficients.csv`,
  `k41_ancova_extended_coefficients.csv`,
  `k41_ancova_model_comparison.csv`,
  `k41_common_sample_counts.csv`,
  `k41_decision_log.txt`,
  `k41_sessioninfo.txt`,
  `k41_external_input_receipt.txt`.
- Manifest rows for every repo artifact.
- No patient-level dataset written to repo.

## Acceptance Criteria

- K41 card exists and clearly states canonical primary is preserved and FI added only in extended models.
- LMM/ANCOVA extended formulas include `frailty_index_fi_k40_z` (and `time:frailty_index_fi_k40_z` for LMM).
- Common-sample counts are explicitly reported for both long and wide.
- Output discipline: repo aggregate-only, no row-level dumps, manifest rows present.
- Validation commands pass:
  `run_k41_proot.sh`, `run_qc_summarizer_proot.sh`, `run-gates --mode analysis`.

## Definition of Done (DoD)

- `R-scripts/K41/k41.r` runs end-to-end in Debian proot with `DATA_ROOT` loaded.
- Canonical primary formulas are preserved; FI appears only in extended models.
- Common-sample counts are written and primary/extended model comparisons use identical sample.
- Repo outputs are aggregate-only under `R-scripts/K41/outputs/` and manifest rows are appended.
- `run_k41_proot.sh`, `run_qc_summarizer_proot.sh`, and `run-gates --mode analysis` pass.
- Leak-check confirms no patient-level dumps in `R-scripts/K41/outputs/`.

## Log

- 2026-03-02 19:54:40 created K41 backlog card for FI-extended canonical model comparisons with common-sample enforcement
- 2026-03-02 20:10:44 moved card to `tasks/02-in-progress/` and created `R-scripts/K41/k41.r` and `scripts/termux/run_k41_proot.sh`.
- 2026-03-02 20:11:13 executed `bash scripts/termux/run_k41_proot.sh` (exit 0). Generated all K41 aggregate artifacts + manifest rows.
- 2026-03-02 20:11:58 common sample evidence:
  `n_long_primary=472`, `n_long_extended=472`, `n_long_common=472`,
  `n_wide_primary=236`, `n_wide_extended=236`, `n_wide_common=236`.
- 2026-03-02 20:12:57 executed `bash scripts/termux/run_qc_summarizer_proot.sh` (exit 0).
- 2026-03-02 20:12:25 executed `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` (exit 0).
- 2026-03-02 20:12:32 leak-check PASS:
  `rg -n "^id,|participant|jnro|nro" R-scripts/K41/outputs/*.csv` returned no hits.

## Blockers

- None.

## Links

- [K40_build_frailty_index_fi.md](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/tasks/04-done/K40_build_frailty_index_fi.md)
