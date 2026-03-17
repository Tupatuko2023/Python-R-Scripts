# K22 Evidence Note: Does baseline SLS predict 12-month change or level?

## Data and variable mapping

- Source used: `K15.3._frailty_analysis_data.RData`
- Selected SLS column/alias: `single_leg_stance` -> `single_leg_stance_clean`
- Outcomes: `delta_composite_z = Composite_Z3 - Composite_Z0` and ANCOVA level `Composite_Z3` with baseline adjustment (`Composite_Z0`).

## Core model results

- Delta linear model (`delta ~ SLS + FOF + age + sex + BMI`), N=256: est=0.0093, 95% CI [0.0038, 0.0149], p=0.001097
- ANCOVA model (`Composite_Z3 ~ Composite_Z0 + SLS + FOF + age + sex + BMI`), N=256: est=0.0182, 95% CI [0.0110, 0.0254], p=1.045e-06
- SLS per 10s (`SLS10`) in delta model, N=256: est=0.0931, 95% CI [0.0376, 0.1486], p=0.001097
- Non-linearity check (spline df=3 vs linear, same N): anova p=0.001791
- Interaction check (`SLS x FOF_status`) in delta model, N=256: est=0.0039, 95% CI [-0.0073, 0.0150], p=0.4963

## Overadjustment / collinearity diagnostic

- Status: diagnostic models fit
- Correlation(`single_leg_stance_clean`, `frailty_count_3_balance`) = -0.4746
- SLS SE change (sls-only -> both): 0.002914 -> 0.002989
- Condition number (both model): 825.84

## Missingness and distribution

- Missing single_leg_stance_clean: 3.62%
- Missing delta_composite_z: 0.00%
- Floor share (SLS == 0): 25.94%
- Ceiling share (SLS == max): 2.26%

## Interpretation (construct-level)

This K22 pass evaluates whether baseline SLS adds predictive information for 12-month change and follow-up level under the specified covariate set. Conclusions should be interpreted at model-construct level for this dataset and not generalized beyond this context.

## MI sensitivity

- MI package (mice) available in environment; MI sensitivity was not run in this targeted K22 pass.

## ROPE/equivalence placeholder

- TODO: define clinically meaningful +/-Delta threshold to interpret SLS10 CI in equivalence terms.

## Table-to-text crosscheck

All reported N, coefficients, CIs, p-values, and fit metrics are read from the generated CSV artifacts in this folder.
