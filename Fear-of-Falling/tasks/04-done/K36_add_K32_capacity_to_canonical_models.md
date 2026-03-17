# K36 Add K32 Capacity to Canonical Models

## Context

K26 is the canonical primary modeling path and K34 is deprecated.
Next extension is to add K32 latent capacity score into the canonical K26 pipeline as a pre-specified additional predictor/sensitivity layer, without changing ANALYSIS_PLAN core formulas.

This task must be implemented in K26 path only (never reactivating K34).

## Inputs

- `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R`
- `${DATA_ROOT}/paper_01/capacity_scores/kaatumisenpelko_with_capacity_scores_k32.rds`
- `docs/ANALYSIS_PLAN.md` (spec remains authoritative)
- K33/K15 externalized datasets under `${DATA_ROOT}/paper_01/`

## Outputs

- Extended-model artifacts under `R-scripts/K36/outputs/` (or K26 extension outputs if decided in implementation task):
  - fixed effects tables including K32 capacity term
  - model comparison table (baseline K26 vs K26+K32 extension)
  - interpretation notes
- Manifest rows for aggregate artifacts only.

## Scope Rules

- Keep ANALYSIS_PLAN statistical specification unchanged.
- Do not alter K32 measurement model, sign map, or admissibility gate.
- Do not reactivate K34; keep it deprecated stop-pointer.
- Preserve governance: patient-level data externalized in DATA_ROOT; repo stores only aggregate/receipt artifacts.

## Definition of Done (DoD)

- Canonical K26-based extended model runs end-to-end with K32 score integrated.
- Baseline K26 and extended K26+K32 results are both reported for comparison.
- QC summarizer and analysis gates pass after implementation.
- No patient-level leaks to repo outputs.

## Log

- 2026-03-01 18:08: Backlog task created and reserved for K26-based model extension with K32 capacity score.
- 2026-03-01 18:31: Moved `tasks/01-ready/K36_add_K32_capacity_to_canonical_models.md` -> `tasks/02-in-progress/K36_add_K32_capacity_to_canonical_models.md`.
- 2026-03-01 18:32: Implemented `R-scripts/K36/k36.r` (K26-canonical extension layer) and produced aggregate outputs under `R-scripts/K36/outputs/`.
- 2026-03-01 18:33: Validation PASS: `Rscript R-scripts/K36/k36.r` (via proot with `config/.env` sourced in-call).
- 2026-03-01 18:35: Validation PASS: `bash scripts/termux/run_k26_proot.sh` (canonical path, no manual `/tmp` bridging).
- 2026-03-01 18:36: Validation PASS: `bash scripts/termux/run_qc_summarizer_proot.sh`.
- 2026-03-01 18:36: Validation PASS: `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling`.
- 2026-03-01 18:36: Leak-check PASS for repo outputs (no patient-level `with_capacity_scores*`, `with_frailty*`, or `analysis*` files under `R-scripts/*/outputs/`).

## Blockers

- K35 may be preferred first if reporting-visibility layer is required before model extension.

## Links

- `docs/ANALYSIS_PLAN.md`
- `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R`
- `R-scripts/K34/k34.r`
- `tasks/04-done/KXX_deduplicate_K26_vs_K34_primary_models.md`
