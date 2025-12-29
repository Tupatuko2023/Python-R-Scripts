# SMOKE TEST REPORT: ALL REQUIRED K SCRIPTS (K1–K4, K6–K16)

**Date:** 2025-12-26 13:13:59.585743
**Scripts tested:** 15
**Passed:** 8 ✓
**Failed:** 7 ✗
**Per-script timeout (s):** 300
**Data file detected:** data/external/KaatumisenPelko.csv

---

## SUMMARY

| Script | Status | Exit | Time (s) | Outputs | Error (truncated) |
|--------|--------|------|----------|---------|-------------------|
| K1 | ✗ FAIL | 1 | 0.2 | - | Error: '\.' is an unrecognized escape in character string (<input>:2:9) Executio |
| K2 | ✗ FAIL | 1 | 0.7 | - | Error: K1 output file not found: /project/R-scripts/K1/outputs/K1_Z_Score_Change |
| K3 | ✗ FAIL | 1 | 0.2 | - | Error: '\.' is an unrecognized escape in character string (<input>:2:9) Executio |
| K4 | ✗ FAIL | 1 | 0.6 | - | Error: K3 output file not found: /project/R-scripts/K3/outputs/K3_Values_2G.csv  |
| K6 | ✓ PASS | 0 | 4.5 | 8 | Warning messages: 1: Removed 9 rows containing non-finite outside the scale rang |
| K7 | ✓ PASS | 0 | 7.0 | 10 | Warning messages: 1: In grid.Call.graphics(C_text, as.graphicsAnnot(x$label), x$ |
| K8 | ✓ PASS | 0 | 4.7 | 14 | Attaching package: ‘dplyr’  The following objects are masked from ‘package:stats |
| K9 | ✓ PASS | 0 | 3.1 | 11 | Created DeltaComposite as ToimintaKykySummary2 - ToimintaKykySummary0. Warning m |
| K10 | ✓ PASS | 0 | 2.3 | 2 | Attaching package: ‘dplyr’  The following objects are masked from ‘package:stats |
| K11 | ✓ PASS | 0 | 8.3 | 51 | Created DeltaComposite from Delta_Composite_Z. Warning message: One or more pars |
| K12 | ✗ FAIL | 1 | 2.0 | 3 | Error in ggplot(fof_plot_data, aes(x = estimate, y = outcome, xmin = conf.low,   |
| K13 | ✗ FAIL | 1 | 3.0 | 22 | Created DeltaComposite from Delta_Composite_Z. Error in emmeans(mod_age_int_ext, |
| K14 | ✓ PASS | 0 | 1.4 | 3 | K14: baseline table by FOF-status tallennettu ja manifest päivitetty. Warning me |
| K15 | ✗ FAIL | 1 | 1.9 | 16 | K15: Weakness-rajat (sex_Q1): K15: komponenttien jakaumat (table, useNA='ifany') |
| K16 | ✓ PASS | 0 | 7.9 | 24 | [conflicted] Will prefer dplyr::select over any other package. [conflicted] Will |

---

## DETAILED RESULTS

### K1

**Path:** R-scripts/K1/K1.7.main.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 0.2 seconds
**Outputs created:** 0

**STDERR:**

```
Error: '\.' is an unrecognized escape in character string (<input>:2:9)
Execution halted
```

---

### K2

**Path:** R-scripts/K2/K2.Z_Score_C_Pivot_2G.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 0.7 seconds
**Outputs created:** 0

**STDERR:**

```
Error: K1 output file not found: /project/R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv
Please run K1 pipeline first: Rscript R-scripts/K1/K1.7.main.R
Execution halted
```

**STDOUT (tail):**

```
================================================================================
K2 Script - Z-Score Change Data Transpose (2 Groups)
================================================================================
Script label: K2 
Outputs dir: /project/R-scripts/K2/outputs 
Manifest: /project/manifest/manifest.csv 
Project root: /project 
================================================================================

Loading K1 output data...
```

---

### K3

**Path:** R-scripts/K3/K3.7.main.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 0.2 seconds
**Outputs created:** 0

**STDERR:**

```
Error: '\.' is an unrecognized escape in character string (<input>:2:9)
Execution halted
```

---

### K4

**Path:** R-scripts/K4/K4.A_Score_C_Pivot_2G.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 0.6 seconds
**Outputs created:** 0

**STDERR:**

```
Error: K3 output file not found: /project/R-scripts/K3/outputs/K3_Values_2G.csv
Please run K3 pipeline first: Rscript R-scripts/K3/K3.7.main.R
Execution halted
```

**STDOUT (tail):**

```
================================================================================
K4 Script - Original Values Data Transpose (2 Groups)
================================================================================
Script label: K4 
Outputs dir: /project/R-scripts/K4/outputs 
Manifest: /project/manifest/manifest.csv 
Project root: /project 
================================================================================

Loading K3 output data...
```

---

### K6

**Path:** R-scripts/K6/K6.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 4.5 seconds
**Outputs created:** 8

**New files (max 25 shown):**

- K6_Age_effect.png
- K6_FOF_contrasts_forest.png
- K6_FOF_PainVAS0_G2_emmeans.png
- K6_FOF_SRH3_emmeans.png
- K6_FOF_SRM3_emmeans.png
- K6_main_main_results.csv
- K6_PainVAS0_continuous_effect.png
- K6_PainVAS0_G2_main_effect.png

---

### K7

**Path:** R-scripts/K7/K7.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 7.0 seconds
**Outputs created:** 10

**New files (max 25 shown):**

- K7_box_DeltaComposite_FOF.png
- K7_FTSST_comp_forest.png
- K7_FTSST_composite_interaction.png
- K7_FTSST_own_forest.png
- K7_MWS_composite_forest.png
- K7_MWS_composite_interaction.png
- K7_MWS_own_forest.png
- K7_SLS_comp_forest.png
- K7_SLS_composite_interaction.png
- K7_SLS_own_forest.png

---

### K8

**Path:** R-scripts/K8/K8.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 4.7 seconds
**Outputs created:** 14

**New files (max 25 shown):**

- cell_counts_FOF_by_Walk500m_3class.csv
- cell_counts_FOF_by_Walk500m_G_final.csv
- contrast_summary_withinG_nonFOF_minus_FOF.csv
- interaction_summary_FOFxG_ANCOVA.csv
- K8_Balance_problem_main_effect.png
- K8_Balance_vs_SLS0_boxplot.png
- K8_Balance_Walk_fourpanel.png
- K8_groupmeans_Balance_vs_SLS.csv
- K8_groupmeans_Walk500m_vs_MWS.csv
- K8_Spearman_subjective_vs_objective.csv
- K8_Walk500m_main_effect.png
- K8_Walk500m_vs_MWS0_boxplot.png
- plot_DeltaComposite_Balance.png
- plot_DeltaComposite_Walk500.png

---

### K9

**Path:** R-scripts/K9/K9.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 3.1 seconds
**Outputs created:** 11

**New files (max 25 shown):**

- DeltaComposite_FOF_Age_women.png
- K9_anova_composite_women_typeIII.csv
- K9_baseline_by_FOF_Age_women.csv
- K9_BMI_effect_women.png
- K9_cell_counts_men.csv
- K9_cell_counts_women_final.csv
- K9_contrast_composite_women.csv
- K9_desc_deltas_men.csv
- K9_desc_deltas_women.csv
- K9_MOI_effect_women.png
- K9_tidy_composite_women.csv

---

### K10

**Path:** R-scripts/K10/K10.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 2.3 seconds
**Outputs created:** 2

**New files (max 25 shown):**

- K10/K10_fof_delta_composite_adj_means.png
- K10/K10_fof_delta_composite_raw_means.png

---

### K11

**Path:** R-scripts/K11/K11.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 8.3 seconds
**Outputs created:** 51

**New files (max 25 shown):**

- Age_quartile_Age_counts.csv
- Age_quartile_Age_counts.html
- Age_quartile_summary.csv
- Age_quartile_summary.html
- BP_test_FOF_status.csv
- BP_test_FOF_status.html
- cross_FOF_AgeClass.csv
- cross_FOF_AgeClass.html
- emmeans_FOF_vs_nonFOF_by_agequartile.csv
- emmeans_FOF_vs_nonFOF_by_agequartile.html
- fit_primary_ancova_pvalues.csv
- fit_primary_ancova.csv
- FOF_effect_base_vs_extended.csv
- FOF_effect_base_vs_extended.html
- FOF_effect_MICE_base_vs_extended.csv
- FOF_effect_MICE_base_vs_extended.html
- freq_AgeClass.csv
- freq_AgeClass.html
- freq_FOF_status.csv
- freq_FOF_status.html
- gls_hom_vs_het_comparison.csv
- gls_hom_vs_het_comparison.html
- gls_residual_variance_by_FOF.csv
- gls_residual_variance_by_FOF.html
- lm_base_model_full.csv

---

### K12

**Path:** R-scripts/K12/K12.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 2.0 seconds
**Outputs created:** 3

**New files (max 25 shown):**

- FOF_effects_by_outcome.csv
- FOF_effects_standardized_extended.csv
- lm_models_all_outcomes.csv

**STDERR:**

```
Error in ggplot(fof_plot_data, aes(x = estimate, y = outcome, xmin = conf.low,  : 
  could not find function "ggplot"
Execution halted
```

**STDOUT (tail):**

```
# A tibble: 1 × 2
```

  n n_complete_primary

```
  <int>              <int>
1   276                276
$Composite
```

Min.  1st Qu.   Median     Mean  3rd Qu.     Max.

```
-2.93435 -0.30983  0.05731  0.03261  0.42540  1.78141 

$HGS
```

Min.  1st Qu.   Median     Mean  3rd Qu.     Max.

```
-30.5000  -1.5000   0.0000   0.3446   2.0000  16.0000 

$MWS
```

Min.  1st Qu.   Median     Mean  3rd Qu.     Max.

```
-2.94872 -0.10017  0.00000  0.01052  0.14885  1.16590 

$FTSST
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
-52.900  -1.275   1.355   1.286   4.475  40.000 

$SLS
```

Min.  1st Qu.   Median     Mean  3rd Qu.     Max.

```
-40.0000  -2.0000   0.0000  -0.3159   0.6500  36.5000 
```

---

### K13

**Path:** R-scripts/K13/K13.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 3.0 seconds
**Outputs created:** 22

**New files (max 25 shown):**

- FOF_interaction_effects_overview.csv
- FOF_interaction_effects_overview.html
- FOF_interaction_effects_standardized.csv
- FOF_interaction_effects_standardized.html
- FOF_interaction_effects_symptoms.csv
- FOF_interaction_effects_symptoms.html
- lm_age_int_extended_full.csv
- lm_age_int_extended_full.html
- lm_all_int_extended_full.csv
- lm_all_int_extended_full.html
- lm_BMI_int_extended_full.csv
- lm_BMI_int_extended_full.html
- lm_MOI_int_extended_full.csv
- lm_MOI_int_extended_full.html
- lm_Pain_int_extended_full.csv
- lm_Pain_int_extended_full.html
- lm_sex_int_extended_full.csv
- lm_sex_int_extended_full.html
- lm_SRH_int_extended_full.csv
- lm_SRH_int_extended_full.html
- lm_SRM_int_extended_full.csv
- lm_SRM_int_extended_full.html

**STDERR:**

```
Created DeltaComposite from Delta_Composite_Z.
Error in emmeans(mod_age_int_ext, ~FOF_status | age_c, at = list(age_c = age_c_values)) : 
  could not find function "emmeans"
Execution halted
```

**STDOUT (tail):**

```
# A tibble: 1 × 2
```

  n n_complete_primary

```
  <int>              <int>
1   276                276
 Factor w/ 2 levels "female","male": 1 1 1 1 1 1 1 1 1 1 ...

female   male 
   252     24 
tibble [266 × 21] (S3: tbl_df/tbl/data.frame)
 $ id                    : int [1:266] 553 198 648 806 451 208 791 292 406 645 ...
 $ Delta_Composite_Z     : num [1:266] -0.0219 0.0396 0.1481 0.0696 0.1913 ...
 $ Composite_Z0          : num [1:266] -0.04483 0.00366 0.26178 -0.19367 -0.78074 ...
 $ age                   : num [1:266] 78 81 72 77 76 96 75 76 76 73 ...
 $ BMI                   : num [1:266] 30.6 19.5 38 25.1 30.8 ...
 $ sex                   : Factor w/ 2 levels "female","male": 1 1 1 1 1 1 1 1 1 1 ...
 $ FOF_status            : Factor w/ 2 levels "nonFOF","FOF": 2 1 2 2 2 1 2 2 1 2 ...
 $ MOI_score             : num [1:266] 14 12 10 13 13 10 9 12 15 8 ...
 $ MOI_c                 : num [1:266] 2.849 0.849 -1.151 1.849 1.849 ...
 $ diabetes              : num [1:266] 0 0 1 0 1 0 0 0 0 0 ...
 $ alzheimer             : num [1:266] 0 0 0 0 0 0 0 0 0 0 ...
 $ parkinson             : num [1:266] 0 0 0 0 0 0 0 0 0 0 ...
 $ AVH                   : num [1:266] 0 1 0 0 0 0 0 0 0 0 ...
 $ previous_falls        : num [1:266] 1 1 1 1 1 1 1 1 1 0 ...
 $ psych_score           : num [1:266] 1 1 2 2 0 0 1 NA 2 1 ...
 $ PainVAS0              : num [1:266] 5 7 6.5 4 8 5 5 6 6 5 ...
 $ PainVAS0_c            : num [1:266] 1.0356 3.0356 2.5356 0.0356 4.0356 ...
 $ SRH                   : num [1:266] 1 1 2 2 1 0 1 0 1 0 ...
 $ SRH_3class            : Ord.factor w/ 3 levels "poor"<"fair"<..: 2 2 3 3 2 1 2 1 2 1 ...
 $ oma_arvio_liikuntakyky: num [1:266] 1 1 2 2 2 1 1 0 0 1 ...
 $ SRM_3class            : Ord.factor w/ 3 levels "poor"<"fair"<..: 2 2 3 3 3 2 2 1 1 2 ...
```

  Min.    1st Qu.     Median       Mean    3rd Qu.       Max.

```
-12.744361  -4.744361   0.255639  -0.001745   4.255639  18.255639 
```

 Min.   1st Qu.    Median      Mean   3rd Qu.      Max.

```
-13.06969  -3.01695  -0.05476   0.06508   3.03736  15.01336 
   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
-8.1513 -2.1513 -0.1513  0.1188  1.8487  6.8487 
```

Min.  1st Qu.   Median     Mean  3rd Qu.     Max.

```
-3.96442 -2.46442  1.03558  0.01026  2.03558  6.03558 
# A tibble: 0 × 2
# ℹ 2 variables: moderator <chr>, results_line <chr>
# A tibble: 4 × 9
  model  moderator term  estimate std.error statistic p.value conf.low conf.high
  <chr>  <chr>     <chr>    <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
1 SRH_i… SRH_3cla… FOF_…  -0.226      0.200    -1.13   0.260   -0.621      0.168
2 SRH_i… SRH_3cla… FOF_…  -0.0175     0.140    -0.125  0.900   -0.293      0.258
3 SRM_i… SRM_3cla… FOF_…   0.0563     0.181     0.310  0.757   -0.301      0.414
4 SRM_i… SRM_3cla… FOF_…   0.241      0.131     1.85   0.0663  -0.0163     0.499
# A tibble: 4 × 3
  moderator  term                       results_line                            
  <chr>      <chr>                      <chr>                                   
1 SRH_3class FOF_statusFOF:SRH_3class.L FOF × SRH_3class: β = -0.226, 95 % LV -…
2 SRH_3class FOF_statusFOF:SRH_3class.Q FOF × SRH_3class: β = -0.018, 95 % LV -…
3 SRM_3class FOF_statusFOF:SRM_3class.L FOF × SRM_3class: β = 0.056, 95 % LV -0…
4 SRM_3class FOF_statusFOF:SRM_3class.Q FOF × SRM_3class: β = 0.241, 95 % LV -0…
```

---

### K14

**Path:** R-scripts/K14/K14.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 1.4 seconds
**Outputs created:** 3

**New files (max 25 shown):**

- K14_baseline_by_FOF.csv
- K14_baseline_by_FOF.html
- sessioninfo_K14.txt

---

### K15

**Path:** R-scripts/K15/K15.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 1.9 seconds
**Outputs created:** 16

**New files (max 25 shown):**

- K15_chisq_FOF_by_frailty_cat3.csv
- K15_chisq_FOF_by_frailty_cat3.html
- K15_chisq_FOF_by_frailty_cat4.csv
- K15_chisq_FOF_by_frailty_cat4.html
- K15_frailty_cat_3_overall.csv
- K15_frailty_cat_3_overall.html
- K15_frailty_cat_4_overall.csv
- K15_frailty_cat_4_overall.html
- K15_frailty_cat3_by_FOF.csv
- K15_frailty_cat3_by_FOF.html
- K15_frailty_cat4_by_FOF.csv
- K15_frailty_cat4_by_FOF.html
- K15_frailty_count_3_overall.csv
- K15_frailty_count_3_overall.html
- K15_frailty_count_4_overall.csv
- K15_frailty_count_4_overall.html

**STDERR:**

```
K15: Weakness-rajat (sex_Q1):
K15: komponenttien jakaumat (table, useNA='ifany'):

K15: SENSITIIVISYYSVERSIOT - low_activity komponentit:

K15: SENSITIIVISYYSVERSIOT - frailty kategoriat:
Error in ggplot(analysis_data %>% filter(!is.na(FOF_status_factor), !is.na(frailty_cat_3)),  : 
  could not find function "ggplot"
Execution halted
```

**STDOUT (tail):**

```
# A tibble: 1 × 2
```

  n n_complete_primary

```
  <int>              <int>
1   276                276
# A tibble: 2 × 2
  sex_factor cut_Q1
  <fct>       <dbl>
1 female         14
2 male           23

   0    1 <NA> 
 212   61    3 

   0    1 <NA> 
 199   53   24 

  0   1 
 63 213 

   0    1 <NA> 
 243   23   10 

  0   1 
106 170 

  0   1 
158 118 

   robust pre-frail     frail      <NA> 
```

   42       126        82        26

```
   robust pre-frail     frail      <NA> 
```

   75        97        78        26

```
   robust pre-frail     frail      <NA> 
```

  109        76        65        26

```
```

---

### K16

**Path:** R-scripts/K16/K16.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 7.9 seconds
**Outputs created:** 24

**New files (max 25 shown):**

- K15_chisq_FOF_by_frailty_cat3.csv
- K15_chisq_FOF_by_frailty_cat3.html
- K15_chisq_FOF_by_frailty_cat4.csv
- K15_chisq_FOF_by_frailty_cat4.html
- K15_frailty_cat_3_overall.csv
- K15_frailty_cat_3_overall.html
- K15_frailty_cat_4_overall.csv
- K15_frailty_cat_4_overall.html
- K15_frailty_cat3_by_FOF.csv
- K15_frailty_cat3_by_FOF.html
- K15_frailty_cat3_by_FOF.png
- K15_frailty_cat4_by_FOF.csv
- K15_frailty_cat4_by_FOF.html
- K15_frailty_count_3_overall.csv
- K15_frailty_count_3_overall.html
- K15_frailty_count_4_overall.csv
- K15_frailty_count_4_overall.html
- K16_all_models.RData
- K16_frailty_effects_plot.png
- K16_frailty_models_tables.docx
- K16_predicted_trajectories.png
- K16_Results_EN.txt
- K16_Results_FI.txt
- sessioninfo_K16.txt

---

## RECOMMENDATIONS

### Failed scripts

- **K1** (exit 1): Error: '\.' is an unrecognized escape in character string (<input>:2:9)
Execution halted
- **K2** (exit 1): Error: K1 output file not found: /project/R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv
Please run K1 pipeline first: Rscript R-scripts/K1/K1.7.main.R
Execution halted
- **K3** (exit 1): Error: '\.' is an unrecognized escape in character string (<input>:2:9)
Execution halted
- **K4** (exit 1): Error: K3 output file not found: /project/R-scripts/K3/outputs/K3_Values_2G.csv
Please run K3 pipeline first: Rscript R-scripts/K3/K3.7.main.R
Execution halted
- **K12** (exit 1): Error in ggplot(fof_plot_data, aes(x = estimate, y = outcome, xmin = conf.low,  :
  could not find function "ggplot"
Execution halted
- **K13** (exit 1): Created DeltaComposite from Delta_Composite_Z.
Error in emmeans(mod_age_int_ext, ~FOF_status | age_c, at = list(age_c = age_c_values)) :
  could not find function "emmeans"
Execution halted
- **K15** (exit 1): K15: Weakness-rajat (sex_Q1):
K15: komponenttien jakaumat (table, useNA='ifany'):

K15: SENSITIIVISYYSVERSIOT - low_activity komponentit:

K15: SENSITIIVISYYSVERSIOT - frailty kategoriat:
Error in ggp

---

## END OF REPORT
