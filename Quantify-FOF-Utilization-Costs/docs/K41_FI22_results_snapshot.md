# FI22 sensitivity analysis: FOF association

Source-of-truth run: `20260306_140934`  
Frailty index variant: `FI22_nonperformance_KAAOS`

The analytic dataset included `n = 476` participants with complete data for the frailty index (FI), fear of falling (FOF), age, and sex. The observed prevalence of FOF in the model sample was approximately 70%.

In multivariable logistic regression (`FOF ~ FI + age + sex`), higher frailty was strongly associated with higher odds of fear of falling. The FI effect was statistically significant (OR 52.17 per 1.0 FI unit, 95% CI 8.28-328.74, p < 0.001), corresponding to an OR of 1.49 per 0.1 FI increase (95% CI 1.24-1.79).

Age showed an inverse association with FOF (OR 0.95 per year, 95% CI 0.92-0.98, p < 0.001), while male sex was associated with lower odds of FOF compared with female sex (OR 0.39, 95% CI 0.20-0.74, p = 0.004). Because age showed an inverse adjusted association, this coefficient should be interpreted in the context of covariate adjustment and the selected analytic sample.

Distributional QC outputs (FI histogram and FI vs age plot with linear trend) were generated successfully and showed a plausible right-skewed FI distribution. In the FI-vs-age trend summary, the FI slope on age was positive (beta 0.00415 per year, p < 0.001).

These results support the use of the `FI22_nonperformance_KAAOS` index as a sensitivity frailty measure within the KAAOS-based analysis pipeline.

## Artifacts

- `R/41_models/outputs/20260306_140934/k41_fi22_dataset_summary.csv`
- `R/41_models/outputs/20260306_140934/k41_fi22_fof_model_or.csv`
- `R/41_models/outputs/20260306_140934/k41_fi22_age_trend_summary.csv`
- `R/41_models/outputs/20260306_140934/k41_fi22_histogram.pdf`
- `R/41_models/outputs/20260306_140934/k41_fi22_vs_age.pdf`
