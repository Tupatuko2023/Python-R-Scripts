# Results: FI22 sensitivity analysis

Source-of-truth run: `20260306_140934`  
Frailty index variant: `FI22_nonperformance_KAAOS`

## Sample characteristics

The analytic dataset included `n = 476` participants with complete data for FI, fear of falling (FOF), age, and sex. FOF prevalence in the model sample was approximately 70%.

## Frailty distribution

The `FI22_nonperformance_KAAOS` index showed a plausible right-skewed distribution, consistent with deficit-accumulation measures. Mean FI was 0.362 (SD 0.122).

A positive FI-age trend was observed in linear modeling (beta 0.00415 per year, p < 0.001).

## Association between frailty and fear of falling

In adjusted logistic regression (`FOF ~ FI + age + sex`), higher frailty was associated with higher odds of FOF.

- OR per 1.0 FI unit: 52.17 (95% CI 8.28-328.74, p < 0.001)
- OR per 0.1 FI increase: 1.49 (95% CI 1.24-1.79)

Age showed an inverse adjusted association with FOF (OR 0.95 per year, 95% CI 0.92-0.98, p < 0.001). Male sex was associated with lower odds of FOF compared with female sex (OR 0.39, 95% CI 0.20-0.74, p = 0.004).

Because age showed an inverse adjusted association, this coefficient should be interpreted in the context of covariate adjustment and the selected analytic sample.

## Figures

- Figure 2A: FI distribution (`k41_fi22_histogram.pdf`)
- Figure 2B: FI versus age (`k41_fi22_vs_age.pdf`)

## Model table

Table 2 reports the adjusted logistic model (`FOF ~ FI + age + sex`) with effect sizes and confidence intervals.

## Linked artifacts

- `R/41_models/outputs/20260306_140934/k41_fi22_dataset_summary.csv`
- `R/41_models/outputs/20260306_140934/k41_fi22_fof_model_or.csv`
- `R/41_models/outputs/20260306_140934/k41_fi22_age_trend_summary.csv`
- `R/41_models/outputs/20260306_140934/k41_fi22_histogram.pdf`
- `R/41_models/outputs/20260306_140934/k41_fi22_vs_age.pdf`
