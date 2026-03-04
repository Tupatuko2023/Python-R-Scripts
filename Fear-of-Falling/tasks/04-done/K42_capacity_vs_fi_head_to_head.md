# K42 Capacity vs FI Head-to-Head (Extended Models, Common Sample)

## Context

This K42 is an analysis-repo R implementation task in `Fear-of-Falling`.
It is not a dissertation-repo writing task.

K32/K36 provide performance-leaning latent capacity (`capacity_score_latent_primary`).
K40/K41 provide non-performance frailty vulnerability (`frailty_index_fi_k40_z`) and FI-extended model checks.
K42 is the deterministic head-to-head model comparison that places capacity and FI in the same framework.

Task-gate status: implementation completed in `tasks/02-in-progress/`; ready for `tasks/03-review/` human approval.

## Objective

Run canonical primary models and three extended variants on identical common samples to answer:

- Is FI independently informative after capacity?
- Is capacity independently informative after FI?
- Which construct relates to level vs change (`time` interaction)?

## Inputs

Required external inputs from `${DATA_ROOT}` only:

- `${DATA_ROOT}/paper_01/analysis/`:
  `fof_analysis_k33_long.{rds,csv}` and `fof_analysis_k33_wide.{rds,csv}`
- `${DATA_ROOT}/paper_01/capacity_scores/`:
  K32/K36 capacity dataset including `capacity_score_latent_primary`
- `${DATA_ROOT}/paper_01/frailty_vulnerability/`:
  K40 FI dataset including `frailty_index_fi_k40_z`

Required repo references:

- `config/.env` (`DATA_ROOT` required)
- `manifest/manifest.csv`

## Scope

Implementation files (when ready):

- `R-scripts/K42/k42.r`
- `scripts/termux/run_k42_proot.sh`

Model policy:

- Canonical primary formulas remain unchanged.
- Capacity/FI are added only in extended models.
- All primary vs extended comparisons must use identical common sample within each family (long/wide).
- Interpretation priority:
  LMM primary interpretation focuses on `time:capacity_score_latent_primary` and `time:frailty_index_fi_k40_z`;
  ANCOVA primary interpretation focuses on main effects of `capacity_score_latent_primary` and `frailty_index_fi_k40_z` after baseline adjustment.

## Deterministic Models

Use canonical covariates and exposures (`FOF_status`, `frailty_cat_3`, `tasapainovaikeus`, `age`, `sex`, `BMI`).

LMM (long):

1. Primary (canonical)
2. `+ capacity`: add `capacity_score_latent_primary` and `time:capacity_score_latent_primary`
3. `+ FI`: add `frailty_index_fi_k40_z` and `time:frailty_index_fi_k40_z`
4. `+ both`: add both constructs and both time interactions

ANCOVA (wide):

1. Primary (canonical)
2. `+ capacity`: add `capacity_score_latent_primary`
3. `+ FI`: add `frailty_index_fi_k40_z`
4. `+ both`: add both constructs

## Common-Sample Gate (Mandatory)

For each model family (LMM and ANCOVA), derive a deterministic common-sample mask over all variables required by the four models.
Fit all four models on that same sample.

Report explicit counts:

- `n_long_primary`, `n_long_capacity`, `n_long_fi`, `n_long_both`, `n_long_common`
- `n_wide_primary`, `n_wide_capacity`, `n_wide_fi`, `n_wide_both`, `n_wide_common`
- corresponding unique-id counts

If a model family cannot satisfy minimum stability threshold (deterministic threshold to be defined in code, e.g. `<20 rows`), stop with informative error and decision log note.

## Collinearity and Red Flags

Required diagnostics (aggregate-only):

- Correlation: `corr(capacity_score_latent_primary, frailty_index_fi_k40_z)` on common sample (long and wide)
- High-correlation flag (deterministic threshold, e.g. `|r| >= 0.80`)
- VIF diagnostics for ANCOVA `both` model (or explicit fallback note if VIF package unavailable)
- Model convergence/singularity flags for LMM
- Collinearity fallback rule:
  if `|corr(capacity, FI)| >= 0.80`, write `high collinearity` explicitly to decision log, and prioritize model-comparison metrics and predicted trajectories over single-coefficient p-value interpretation in `+both` models.

## Outputs (Repo Aggregate-Only)

Write only aggregate artifacts to `R-scripts/K42/outputs/`:

- `k42_common_sample_counts.csv`
- `k42_lmm_primary_coefficients.csv`
- `k42_lmm_capacity_coefficients.csv`
- `k42_lmm_fi_coefficients.csv`
- `k42_lmm_both_coefficients.csv`
- `k42_lmm_model_comparison.csv`
- `k42_ancova_primary_coefficients.csv`
- `k42_ancova_capacity_coefficients.csv`
- `k42_ancova_fi_coefficients.csv`
- `k42_ancova_both_coefficients.csv`
- `k42_ancova_model_comparison.csv`
- `k42_capacity_fi_collinearity.csv`
- `k42_red_flags.csv`
- `k42_decision_log.txt`
- `k42_sessioninfo.txt`
- `k42_external_input_receipt.txt`

Append manifest rows for each repo artifact.

## Governance

- Require `DATA_ROOT`; fail fast if missing.
- Read patient-level inputs only from `${DATA_ROOT}`.
- Write no patient-level output datasets to repository.
- K42 may write a repo input receipt (path + md5 + nrow/ncol) but no row-level dumps.

## Reproduction Commands

`[TERMUX]`

```sh
cd Python-R-Scripts/Fear-of-Falling
set -a && . config/.env && set +a && echo "DATA_ROOT=$DATA_ROOT"
bash scripts/termux/run_k42_proot.sh
bash scripts/termux/run_qc_summarizer_proot.sh
bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling
rg -n "^id,|participant|jnro|nro" R-scripts/K42/outputs/*.csv || true
```

`[PROOT:DEBIAN]`

```sh
# Use single Termux proot one-liner wrappers; no standalone proot login block needed.
```

## Acceptance Criteria

- K42 task card exists in `tasks/01-ready/` and clearly states this is analysis-repo R work.
- K42 defines deterministic 1-4 model sequence for both LMM and ANCOVA.
- K42 enforces common-sample rule with explicit counts reported.
- K42 requires head-to-head outputs enabling interpretation of capacity-only, FI-only, and both.
- K42 includes collinearity diagnostics (`corr` + high-correlation flag + VIF/fallback note).
- Governance is explicit: repo aggregate-only, no patient-level exports in repo.
- Validation expectations explicit: `run_k42_proot.sh`, qc summarizer, run-gates, leak-check.

## Definition of Done (Implementation Stage)

- `R-scripts/K42/k42.r` runs end-to-end in Debian proot with `DATA_ROOT` loaded.
- Manifest contains K42 artifact rows.
- All K42 outputs are aggregate-only and reproducible from externalized inputs.

## Log

- 2026-03-02 20:18:26 created K42 backlog card for deterministic capacity-vs-FI head-to-head modeling on common samples.
- 2026-03-02 20:54:11 moved card to `tasks/02-in-progress/`.
- 2026-03-02 20:58:18 ran `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` (exit 0) before implementation.
- 2026-03-02 21:00:22 implemented `R-scripts/K42/k42.r` and `scripts/termux/run_k42_proot.sh`.
- 2026-03-02 21:01:14 ran `bash scripts/termux/run_k42_proot.sh` (exit 0).
- 2026-03-02 21:01:49 ran `bash scripts/termux/run_qc_summarizer_proot.sh` (exit 0).
- 2026-03-02 21:01:28 ran `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` (exit 0).
- 2026-03-02 21:01:52 leak-check PASS:
  `rg -n "^id,|participant|jnro|nro" R-scripts/K42/outputs/*.csv` returned no hits.
- 2026-03-02 21:02:11 key deterministic evidence:
  `n_long_primary=n_long_capacity=n_long_fi=n_long_both=n_long_common=472`,
  `n_wide_primary=n_wide_capacity=n_wide_fi=n_wide_both=n_wide_common=236`,
  `corr(capacity, FI)=-0.5083` (long and wide), `high_collinearity=FALSE`.

## Blockers

- None at backlog stage.

## Links

- [K41_add_fi_extended_models.md](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/tasks/04-done/K41_add_fi_extended_models.md)
- [K40_build_frailty_index_fi.md](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/tasks/04-done/K40_build_frailty_index_fi.md)
