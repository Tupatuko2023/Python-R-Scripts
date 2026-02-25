# TASK: K22 SLS additional checks (delta + ANCOVA + diagnostics)

## Context

- Targeted follow-up analysis to test whether baseline single-leg stance (SLS0 proxy) predicts:
  - 12-month change in physical performance (`delta_composite_z`)
  - follow-up level (`Composite_Z3`) with baseline adjustment (ANCOVA)
- Scope limited to K22; no pipeline bootstrap and no package installs.

## Inputs

- `Fear-of-Falling/R-scripts/K15/K15.3.frailty_n_balance.R` (alias logic reference)
- `Fear-of-Falling/R-scripts/K15/outputs/K15.3._frailty_analysis_data.RData`
- `Fear-of-Falling/data/external/KaatumisenPelko.csv`
- `Fear-of-Falling/manifest/manifest.csv`

## Outputs

- `Fear-of-Falling/R-scripts/K22/K22_sls_predicts_change_and_level.R`
- `Fear-of-Falling/R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_models_fixed_effects.csv`
- `Fear-of-Falling/R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_model_metrics.csv`
- `Fear-of-Falling/R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_evidence_note.md`
- `Fear-of-Falling/R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_delta_vs_sls.png`

## Definition of Done (DoD)

- [x] Delta linear model fitted with SLS + covariates and CI/p reported.
- [x] ANCOVA model fitted with baseline adjustment and CI/p reported.
- [x] Non-linearity check done (`ns(df=3)` vs linear) with ANOVA p.
- [x] SLS × FOF interaction model fitted.
- [x] Overadjustment/collinearity diagnostic run with `frailty_cat_3_balance`.
- [x] Missingness + floor/ceiling summary included.
- [x] SLS10 scaling reported (95% CI) and clinical ±Delta TODO noted.
- [x] MI not run (mice unavailable); TODO documented.
- [x] Artifacts generated and manifest rows appended.

## Log

- 2026-02-23 19:11: Created task from template and moved to `02-in-progress`.
- 2026-02-23 19:12: Confirmed required data and K15-derived analysis object available.
- 2026-02-23 19:16: Implemented and ran `K22_sls_predicts_change_and_level.R` using Termux `Rscript` fallback (no proot run).
- 2026-02-23 19:16: Wrote K22 outputs and appended 4 manifest rows.
- 2026-02-23 19:16: Key results (complete-case):
  - Delta linear (`N=256`): SLS est `0.0093`, 95% CI `[0.0038, 0.0149]`, p `0.0011`
  - ANCOVA (`N=256`): SLS est `0.0182`, 95% CI `[0.0110, 0.0254]`, p `1.05e-06`
  - Spline vs linear ANOVA p `0.00179` (non-linearity signal)
  - SLS × FOF interaction p `0.496` (no interaction signal)
  - Overadjustment diagnostics (`N=239`): corr(SLS, frailty_count_3_balance) `-0.4746`; SLS SE `0.002914 -> 0.002989`; condition number `825.84`
  - Missingness: SLS `3.62%`, delta `0.00%`; floor `25.94%`, ceiling `2.26%`
- 2026-02-23 19:24: Table-to-text crosscheck OK:
  - `K22_sls_models_fixed_effects.csv` and `K22_sls_model_metrics.csv` values match `K22_sls_evidence_note.md` and `docs/K22_sls_summary_note.md`.

## Blockers

- `mice` package unavailable in current environment; MI sensitivity deferred (TODO documented in evidence note).

## Links

- `Fear-of-Falling/R-scripts/K22/K22_sls_predicts_change_and_level.R`
- `Fear-of-Falling/R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_models_fixed_effects.csv`
- `Fear-of-Falling/R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_model_metrics.csv`
- `Fear-of-Falling/R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_evidence_note.md`
- `Fear-of-Falling/R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_delta_vs_sls.png`
