# K46_reporting_pack_head_to_head_capacity_fi_mice

## Scope
Create a governance-safe reporting pack that consolidates:
- K42 head-to-head (Primary / +Capacity / +FI / +Both) results
- K44 BOTH-model gradient visualizations (main + supplementary)
- K45 MICE sensitivity (covariates-only; outcome not imputed)

This task produces *aggregate-only* reporting artifacts (tables + text snippets + figure callouts) suitable for manuscript/dissertation insertion.

## Explicit non-goals
- Do NOT refit any models (no new estimation).
- Do NOT change ANALYSIS_PLAN model formulas.
- Do NOT modify K42/K44/K45 code or outputs.
- Do NOT write patient-level data to the repository.
- Do NOT require DATA_ROOT paths in any repo text (no absolute filesystem paths).

## Inputs (read-only)
Read existing aggregate outputs from repo:
- `R-scripts/K42/outputs/*`:
  - `k42_lmm_model_comparison.csv`
  - `k42_ancova_model_comparison.csv`
  - `k42_capacity_fi_collinearity.csv`
  - (coefficients tables if present: primary/capacity/fi/both)
- `R-scripts/K44/outputs/*`:
  - `k44_both_gradients.png`
  - `k44_extreme_profiles.png`
  - `k44_figure_caption.txt`
  - `k44_decision_log.txt`
- `R-scripts/K45/outputs/*`:
  - `k45_complete_case_vs_pooled_comparison.csv`
  - `k45_pooled_coefficients_k42_both.csv`
  - `k45_fraction_missing_information.csv`
  - `k45_mice_missingness_summary.csv`

No DATA_ROOT reads are required for K46. K46 is a reporting-only consolidator.

## Implementation
Create:
- `R-scripts/K46/k46.r`
- Optional runner: `scripts/termux/run_k46_proot.sh` (recommended for reproducibility)

### Output location
Repo outputs only:
- `R-scripts/K46/outputs/`
No patient-level exports.

### Required repo artifacts (aggregate-only)
1) **Main results table** (Primary vs +Capacity vs +FI vs +Both), LMM + ANCOVA
- `k46_table_head_to_head_primary_capacity_fi_both.csv`
  - Columns (minimum):
    - model_set {primary, capacity, fi, both}
    - framework {LMM, ANCOVA}
    - N (common sample)
    - key_terms (time×capacity, time×FI, time×FOF if present; ANCOVA main effects)
    - estimate, SE, p_value (or CI if available; prefer p)
    - AIC (and/or ΔAIC vs primary)
    - notes (e.g., “fixed-effects predictions used for plots”)

2) **Figure callouts** (for K44)
- `k46_figure_callouts.txt`
  - Includes:
    - where to cite main K44 gradients plot
    - where to cite supplementary extreme-profiles plot
    - one-sentence non-causal interpretation
    - confirm “fixed-effect model predictions”

3) **Results snippet (paste-ready)** (EN)
- `k46_results_snippet.txt`
  - 120–200 words; descriptive non-causal.
  - Must mention:
    - common sample lock (n_wide=236, n_long=472 or as read from K42 outputs)
    - corr(capacity, FI) ≈ -0.51 and “not collinear”
    - BOTH model: time×capacity and time×FI directions and example estimates/p-values if present in K42 coefficients
    - refer to Figure X (K44 gradients)
    - avoid causal verbs (no “drives”, “determines”, “predicts decline”)

4) **Sensitivity snippet (MICE covariates-only)** (EN)
- `k46_sensitivity_snippet_mice.txt`
  - 70–130 words.
  - Must mention:
    - outcome not imputed
    - m and seed (from K45 methods artifact)
    - sample restored to outcome-complete (wide 276; long 552) and compare against complete-case (236 / 472)
    - direction preserved, modest attenuation (cite example terms from K45 comparison)

5) **Reviewer defense micro-bullets**
- `k46_reviewer_defense_8bullets.txt`
  - 8 bullets max:
    - pre-spec / primary preserved
    - common sample
    - construct separation (capacity vs FI)
    - collinearity check + result
    - visualization is coefficient-consistent, fixed-effects
    - missingness handled via covariate-only MI
    - governance safe (aggregate-only)
    - non-causal framing

6) **Decision log**
- `k46_decision_log.txt`
  - Record which input files were found, their hashes if feasible (optional), and what was summarized.

7) **Session info**
- `k46_sessioninfo.txt`

8) **Manifest**
Append rows to `manifest/manifest.csv` for all K46 artifacts.

## Governance requirements
- Absolutely no patient-level row dumps to repo outputs.
- No absolute filesystem paths in text outputs.
- Use repo-relative references (e.g., `R-scripts/K44/outputs/k44_both_gradients.png`).

## Validation / Gates (must pass)
- `Rscript R-scripts/K46/k46.r` exits 0.
- `bash scripts/termux/run_qc_summarizer_proot.sh` PASS.
- `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` PASS.
- Leak-check: ensure no `^id,|participant|jnro|nro` in any new CSV in `R-scripts/K46/outputs/`.

## Acceptance criteria
- All required artifacts produced (files listed above).
- Table includes both frameworks and clearly labels primary vs extended sets.
- Snippets are paste-ready, non-causal, consistent with K42/K44/K45.
- No changes to K42/K44/K45 outputs or any analysis model code.
