# K21 Frailty-Balance Sensitivity Note

## Methods (Sensitivity Analysis)

We conducted a prespecified sensitivity analysis to compare two frailty proxy constructions for explaining 12-month change in physical performance (`delta_composite_z`) in the same complete-case sample.

- Model A (traditional proxy): `delta_composite_z ~ frailty_cat_3 + FOF_status + age + sex + BMI`
- Model B (balance-extended proxy): `delta_composite_z ~ frailty_cat_3_balance + FOF_status + age + sex + BMI`

`frailty_cat_3` is the traditional 3-component Fried-inspired proxy (weakness, slowness, low activity). `frailty_cat_3_balance` replaces low activity with single-leg stance balance (`frailty_balance`), yielding a balance-extended 3-component proxy. Because A and B use different frailty predictors, they were treated as non-nested; model fit was compared using AIC and adjusted R² on the same common-sample dataset.

## Results

Common-sample size was **N=239** for both models. In this matched sample:

- AIC: Model A **339.7903** vs Model B **346.8775** (lower is better)
- Adjusted R²: Model A **0.3188** vs Model B **0.2982** (higher is better)

Thus, the traditional proxy (`frailty_cat_3`) showed better fit than the balance-extended proxy (`frailty_cat_3_balance`) for `delta_composite_z`.

For frailty contrasts (reference = robust), both models retained significant frail-vs-robust effects:

- Model A `frailty_cat_3frail`: estimate **-0.6622**, 95% CI **[-0.8513, -0.4732]**, p **< 1e-10**
- Model B `frailty_cat_3_balancefrail`: estimate **-0.6295**, 95% CI **[-0.8051, -0.4538]**, p **< 2e-11**

## Figure Note (Forest Plot)

Common-sample **N=239**. Model A: **AIC=339.7903**, **adjR2=0.3188**. Model B: **AIC=346.8775**, **adjR2=0.2982**. **Delta AIC (B-A)=+7.0872** and **Delta adjR2 (B-A)=-0.0206**.

Fit indices favored the traditional proxy; adding balance into the frailty proxy did not improve model fit for `delta_composite_z` in this dataset.

## Interpretation

In this dataset and model setting, adding single-leg-stance balance into the frailty construction did **not** improve explanatory performance for `delta_composite_z` relative to the traditional 3-component frailty proxy.

This result should be interpreted as construct-level performance in this outcome context, not as evidence that balance is universally non-informative.

K21 addresses a frailty-construct question (proxy fit comparison: `frailty_cat_3` vs `frailty_cat_3_balance`), whereas K22 addresses an independent-predictor question (continuous baseline SLS in delta and ANCOVA models).

Therefore, the K21 conclusion remains unchanged: adding balance inside the categorical frailty proxy did not improve fit in that proxy-comparison setting.

## Table-to-Text Crosscheck

All numeric values above are taken directly from:

- `R-scripts/K21/outputs/compare_frailty_proxies_delta/compare_frailty_proxies_delta_composite_z.csv`
