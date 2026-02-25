# K22 SLS Summary Note

## Quantitative Summary

- Delta model (`delta_composite_z ~ single_leg_stance + FOF_status + age + sex + BMI`):
  - estimate `0.0093`, 95% CI `[0.0038, 0.0149]`, p `0.0011` (`N=256`)
- ANCOVA model (`Composite_Z3 ~ Composite_Z0 + single_leg_stance + FOF_status + age + sex + BMI`):
  - estimate `0.0182`, 95% CI `[0.0110, 0.0254]`, p `1.05e-06` (`N=256`)
- Spline vs linear (delta model): p `0.00179`
- SLS x FOF interaction (delta model): p `0.496`
- Overadjustment diagnostic:
  - corr(`single_leg_stance`, `frailty_count_3_balance`) `-0.4746`
  - condition number `825.84`
- MI sensitivity:
  - not run (`mice` unavailable; TODO if MI is required)

## Interpretation

SLS predicts change as a continuous independent predictor, but incorporating balance into a categorical frailty proxy does not improve overall model fit. These are distinct questions.

## Table-to-Text Crosscheck

All values above are copied from:

- `R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_models_fixed_effects.csv`
- `R-scripts/K22/outputs/sls_predicts_change_and_level/K22_sls_model_metrics.csv`
