# TASK: Compare Frailty Proxies on delta_composite_z (K21)

## Context

- Determine whether classic 3-component frailty proxy (`frailty_cat_3`) or
  balance-extended frailty proxy (`frailty_cat_3_balance`) explains
  `delta_composite_z` better on the same common sample.

## Inputs

- `R-scripts/K15/K15.3.frailty_n_balance.R`
- `R-scripts/K15/outputs/K15.3._frailty_analysis_data.RData`
- `data/external/KaatumisenPelko.csv`
- `manifest/manifest.csv`

## Outputs

- `R-scripts/K21/K21_compare_frailty_proxies_delta.R`
- `R-scripts/K21/outputs/compare_frailty_proxies_delta/compare_frailty_proxies_delta_composite_z.csv`
- `R-scripts/K21/outputs/compare_frailty_proxies_delta/compare_frailty_proxies_delta_composite_z.md`

## Definition of Done (DoD)

- [x] K15.3 run confirmed balance-extended proxy variables are present.
- [x] Model A vs B fitted on identical common-sample N.
- [x] Reported AIC, adjR2, N and frailty coefficient estimate/CI/p for both models.
- [x] Non-nested note included (no invalid nested test between A and B).
- [x] CSV+MD written and manifest rows appended.

## Log

- 2026-02-23 14:37: Proot `/usr/bin/Rscript` failed (runtime ELF issue), fallback used: Termux `Rscript` with `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`.
- 2026-02-23 14:37: Ran `R-scripts/K15/K15.3.frailty_n_balance.R`; confirmed `frailty_count_3_balance` and `frailty_cat_3_balance` derivation.
- 2026-02-23 14:38: Implemented and ran `R-scripts/K21/K21_compare_frailty_proxies_delta.R`.
- 2026-02-23 14:38: Generated K21 CSV+MD outputs and appended manifest rows.
- 2026-02-23 14:38: QC-minimum captured:
  - `frailty_cat_3_balance` missingness in full analysis_data = 10.14%
  - common-sample N (A and B) = 239
- 2026-02-23 14:38: Fit summary (same N):
  - AIC: A=339.79, B=346.88 (A better)
  - adjR2: A=0.3188, B=0.2982 (A better)
- 2026-02-23 14:52: Caption strengthened per review: N/AIC/adjR2/Delta reported in K21 note and K21 report MD.
- 2026-02-23 14:52: Table-to-text crosscheck OK: note/report values match CSV (N=239; AIC 339.7903 vs 346.8775; adjR2 0.3188 vs 0.2982; Delta AIC +7.0872; Delta adjR2 -0.0206).
- 2026-02-23 19:24: K22 shows SLS predicts change; K21 proxy-fit finding unchanged.

## Blockers

- Proot Debian R execution was unavailable in this session (ELF/linker issue); Termux R was used to complete analysis.

## Links

- `Fear-of-Falling/R-scripts/K21/K21_compare_frailty_proxies_delta.R`
- `Fear-of-Falling/R-scripts/K21/outputs/compare_frailty_proxies_delta/compare_frailty_proxies_delta_composite_z.csv`
- `Fear-of-Falling/R-scripts/K21/outputs/compare_frailty_proxies_delta/compare_frailty_proxies_delta_composite_z.md`
