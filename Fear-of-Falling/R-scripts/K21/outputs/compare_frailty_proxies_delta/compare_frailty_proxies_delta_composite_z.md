# Compare frailty proxies on delta_composite_z

Data source: `R-scripts/K15/outputs/K15.3._frailty_analysis_data.RData`
Common-sample N used in both models: 239
frailty_cat_3_balance missing in full analysis_data: 10.14%

## Models

A: `delta_composite_z ~ frailty_cat_3 + FOF_status + age + sex + BMI`
B: `delta_composite_z ~ frailty_cat_3_balance + FOF_status + age + sex + BMI`

## Fit metrics (same N)

AIC: A=339.7903, B=346.8775 (lower better; winner=A)
adjR2: A=0.3188, B=0.2982 (higher better; winner=A)

## Frailty coefficients (reference=robust)

Model A terms:

- frailty_cat_3pre-frail: est=-0.2112, 95% CI [-0.3852, -0.0372], p=0.0176
- frailty_cat_3frail: est=-0.6622, 95% CI [-0.8513, -0.4732], p=0.0000
Model B terms:
- frailty_cat_3_balancepre-frail: est=-0.2344, 95% CI [-0.3890, -0.0797], p=0.0031
- frailty_cat_3_balancefrail: est=-0.6295, 95% CI [-0.8051, -0.4538], p=0.0000

## Method note

A vs B are non-nested (different frailty predictors), so no nested anova test is used.

## Table-to-text crosscheck

All values above are read back from the generated CSV.
