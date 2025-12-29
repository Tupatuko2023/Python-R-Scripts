# SMOKE TEST REPORT: ALL REQUIRED K SCRIPTS (K1–K4, K6–K16)

**Date:** 2025-12-27 17:42:22.65675
**Scripts tested:** 15
**Passed:** 10 ✓
**Failed:** 5 ✗
**Per-script timeout (s):** 300
**Data file detected:** data/external/KaatumisenPelko.csv

---

## SUMMARY

| Script | Status | Exit | Time (s) | Outputs | Error (truncated) |
|--------|--------|------|----------|---------|-------------------|
| K1 | ✓ PASS | 0 | 1.4 | 2 | Warning message: There was 1 warning in `summarise()`. ℹ In argument: `p_value = |
| K2 | ✓ PASS | 0 | 0.8 | 1 | - |
| K3 | ✓ PASS | 0 | 1.4 | 2 | Warning message: There was 1 warning in `summarise()`. ℹ In argument: `p_value = |
| K4 | ✓ PASS | 0 | 0.8 | 1 | - |
| K6 | ✓ PASS | 0 | 5.0 | 8 | Warning message: In grid.Call.graphics(C_text, as.graphicsAnnot(x$label), x$x, x |
| K7 | ✓ PASS | 0 | 9.1 | 10 | Warning messages: 1: In grid.Call.graphics(C_text, as.graphicsAnnot(x$label), x$ |
| K8 | ✗ FAIL | 1 | 1.7 | - | Attaching package: ‘dplyr’  The following objects are masked from ‘package:stats |
| K9 | ✗ FAIL | 1 | 1.8 | - | Created DeltaComposite as ToimintaKykySummary2 - ToimintaKykySummary0. Error in  |
| K10 | ✓ PASS | 0 | 2.4 | 2 | Attaching package: ‘dplyr’  The following objects are masked from ‘package:stats |
| K11 | ✗ FAIL | 1 | 3.5 | - | Created DeltaComposite from Delta_Composite_Z. Error in `mutate()` at magrittr/R |
| K12 | ✗ FAIL | 1 | 1.5 | - | Error in `mutate()` at magrittr/R/pipe.R:136:3: ℹ In argument: `Delta_MWS = case |
| K13 | ✓ PASS | 0 | 5.7 | 48 | Created DeltaComposite from Delta_Composite_Z. Warning message: One or more pars |
| K14 | ✗ FAIL | 1 | 1.1 | - | Error in `mutate()` at magrittr/R/pipe.R:136:3: ℹ In argument: `SRH_3class_table |
| K15 | ✓ PASS | 0 | 2.6 | 19 | K15: Weakness-rajat (sex_Q1): K15: komponenttien jakaumat (table, useNA='ifany') |
| K16 | ✓ PASS | 0 | 6.9 | 7 | [conflicted] Will prefer dplyr::select over any other package. [conflicted] Will |

---

## DETAILED RESULTS

### K1

**Path:** R-scripts/K1/K1.7.main.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 1.4 seconds
**Outputs created:** 2

**New files (max 25 shown):**

- K1_Z_Score_Change_2G.csv
- sessioninfo_K1.txt

---

### K2

**Path:** R-scripts/K2/K2.Z_Score_C_Pivot_2G.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 0.8 seconds
**Outputs created:** 1

**New files (max 25 shown):**

- K2_Z_Score_Change_2G_Transposed.csv

---

### K3

**Path:** R-scripts/K3/K3.7.main.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 1.4 seconds
**Outputs created:** 2

**New files (max 25 shown):**

- K3_Values_2G.csv
- sessioninfo_K3.txt

---

### K4

**Path:** R-scripts/K4/K4.A_Score_C_Pivot_2G.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 0.8 seconds
**Outputs created:** 1

**New files (max 25 shown):**

- K4_Values_2G_Transposed.csv

---

### K6

**Path:** R-scripts/K6/K6.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 5.0 seconds
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
**Execution time:** 9.1 seconds
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
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 1.7 seconds
**Outputs created:** 0

**STDERR:**

```

Attaching package: ‘dplyr’

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union

Loading required package: carData

Attaching package: ‘car’

The following object is masked from ‘package:dplyr’:

    recode

Welcome to emmeans.
Caution: You lose important information if you filter this package's results.
See '? untidy'
Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric


Attaching package: ‘purrr’

The following object is masked from ‘package:car’:

    some

here() starts at /project
Error in `mutate()` at magrittr/R/pipe.R:136:3:
ℹ In argument: `Balance_problem = `%>%`(...)`.
Caused by error in `case_when()`:
! Failed to evaluate the left-hand side of formula 1.
Caused by error:
! object 'tasapainovaikeus' not found
Backtrace:
     ▆
  1. ├─analysis_data %>% ...
  2. ├─dplyr::mutate(...) at magrittr/R/pipe.R:136:3
  3. ├─dplyr:::mutate.data.frame(...) at dplyr/R/mutate.R:146:3
  4. │ └─dplyr:::mutate_cols(.data, dplyr_quosures(...), by) at dplyr/R/mutate.R:181:3
  5. │   ├─base::withCallingHandlers(...) at dplyr/R/mutate.R:268:3
  6. │   └─dplyr:::mutate_col(dots[[i]], data, mask, new_columns) at dplyr/R/mutate.R:273:7
  7. │     └─mask$eval_all_mutate(quo) at dplyr/R/mutate.R:380:9
  8. │       └─dplyr (local) eval() at dplyr/R/data-mask.R:94:7
  9. ├─... %>% ...
 10. ├─base::factor(., levels = c("no_balance_problem", "balance_problem")) at magrittr/R/pipe.R:136:3
 11. ├─dplyr::case_when(...)
 12. │ └─dplyr:::case_formula_evaluate(...) at dplyr/R/case-when.R:158:3
 13. │   ├─base::withCallingHandlers(...) at dplyr/R/case-when.R:218:3
 14. │   └─rlang::eval_tidy(pair$lhs, env = default_env) at dplyr/R/case-when.R:224:7
 15. └─base::.handleSimpleError(...) at rlang/R/eval-tidy.R:121:3
 16.   └─dplyr (local) h(simpleError(msg, call))
 17.     └─rlang::abort(message, parent = cnd, call = error_call) at dplyr/R/case-when.R:241:7
Execution halted
```

**STDOUT (tail):**

```
[1] TRUE
tibble [300 × 59] (S3: tbl_df/tbl/data.frame)
```

---

### K9

**Path:** R-scripts/K9/K9.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 1.8 seconds
**Outputs created:** 0

**STDERR:**

```
Created DeltaComposite as ToimintaKykySummary2 - ToimintaKykySummary0.
Error in `mutate()` at magrittr/R/pipe.R:136:3:
ℹ In argument: `Delta_MWS = case_when(...)`.
Caused by error in `case_when()`:
! Failed to evaluate the right-hand side of formula 1.
Caused by error:
! object 'Kävelymuutos' not found
Backtrace:
     ▆
  1. ├─analysis_data_rec %>% ...
  2. ├─dplyr::mutate(...) at magrittr/R/pipe.R:136:3
  3. ├─dplyr:::mutate.data.frame(...) at dplyr/R/mutate.R:146:3
  4. │ └─dplyr:::mutate_cols(.data, dplyr_quosures(...), by) at dplyr/R/mutate.R:181:3
  5. │   ├─base::withCallingHandlers(...) at dplyr/R/mutate.R:268:3
  6. │   └─dplyr:::mutate_col(dots[[i]], data, mask, new_columns) at dplyr/R/mutate.R:273:7
  7. │     └─mask$eval_all_mutate(quo) at dplyr/R/mutate.R:380:9
  8. │       └─dplyr (local) eval() at dplyr/R/data-mask.R:94:7
  9. ├─dplyr::case_when(...)
 10. │ └─dplyr:::case_formula_evaluate(...) at dplyr/R/case-when.R:158:3
 11. │   ├─base::withCallingHandlers(...) at dplyr/R/case-when.R:218:3
 12. │   └─rlang::eval_tidy(pair$rhs, env = default_env) at dplyr/R/case-when.R:227:7
 13. └─base::.handleSimpleError(...) at rlang/R/eval-tidy.R:121:3
 14.   └─dplyr (local) h(simpleError(msg, call))
 15.     └─rlang::abort(message, parent = cnd, call = error_call) at dplyr/R/case-when.R:241:7
Execution halted
```

**STDOUT (tail):**

```
  ..   oma_arvio_liikuntakyky = col_double(),
  ..   Walk500m = col_double(),
  ..   Vaikeus500m = col_double(),
  ..   maxkävelymatka = col_double(),
  ..   vaikeus_liikkua_2km = col_double(),
  ..   Balance_problem = col_double(),
  ..   weight_loss = col_double(),
  ..   exhaustion = col_double(),
  ..   slowness = col_double(),
  ..   low_activity = col_double(),
  ..   weakness = col_double()
  .. )
 - attr(*, "problems")=<externalptr> 
Rows: 300
Columns: 25
$ age                    <dbl> 71, 73, 80, 77, 83, 80, 78, 74, 83, 82, 85, 66,…
$ sex                    <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ BMI                    <dbl> 30.4, 17.7, 15.3, 24.7, 23.5, 19.5, 22.5, 21.7,…
$ MOIindeksiindeksi      <dbl> 10, 13, 14, 14, 10, 14, 9, 9, 14, 15, 7, 13, 13…
$ diabetes               <dbl> 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0,…
$ kaatumisenpelkoOn      <dbl> 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1,…
$ alzheimer              <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ parkinson              <dbl> 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ AVH                    <dbl> 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ ToimintaKykySummary0   <dbl> -0.390131181, 0.399747217, -0.893071443, -0.246…
$ ToimintaKykySummary2   <dbl> -0.28449055, 1.25360472, -0.19970932, 0.9880648…
$ Puristus0              <dbl> 23.6, 21.8, 30.1, 17.1, 25.9, 5.5, 18.4, 26.0, …
$ Puristus2              <dbl> 27.5, 26.1, 21.3, 39.3, 29.9, 24.3, 16.7, 30.2,…
$ PuristusMuutos         <dbl> -3.5, 3.1, -2.9, -1.5, -1.7, -1.9, 0.0, -2.5, 3…
$ kavelynopeus_m_sek0    <dbl> 0.98, 1.08, 1.27, 1.14, 1.43, 1.31, 0.83, 1.58,…
$ kavelynopeus_m_sek2    <dbl> 1.16, 1.65, 1.10, 1.32, 1.02, 1.43, 1.13, 1.07,…
$ tuoliltanousu0         <dbl> 14.1, 7.0, 11.1, 13.6, 17.3, 15.4, 10.4, 25.0, …
$ tuoliltanousu2         <dbl> 13.9, 11.2, 16.0, 13.0, 15.6, 17.0, 17.2, 10.4,…
$ Tuoli0                 <dbl> 16.0, 17.5, 19.2, 25.5, 12.6, 16.7, 20.4, 19.3,…
$ Tuoli2                 <dbl> 15.7, 16.2, 7.3, 17.1, 17.8, 20.0, 8.3, 21.8, 1…
$ Seisominen0            <dbl> 15.0, 4.7, 9.8, 10.6, 0.0, 0.0, 5.7, 4.2, 16.8,…
$ Seisominen2            <dbl> 11.3, 10.5, 8.4, 8.3, 10.7, 6.7, 5.4, 8.2, 12.1…
$ SRH                    <dbl> 1, 0, 2, 1, 1, 2, 1, 1, 1, 1, 2, 1, 0, 1, 1, 1,…
$ oma_arvio_liikuntakyky <dbl> 1, 0, 1, 2, 1, 1, 1, 2, 1, 2, 1, 2, 1, 1, 0, 1,…
$ PainVAS0               <dbl> 1.9, 2.9, 6.2, 9.0, 3.3, 7.0, 6.6, 4.2, 6.1, 3.…
# A tibble: 2 × 2
  FOF_status     n
  <fct>      <int>
1 nonFOF       179
2 FOF          121
# A tibble: 3 × 2
  AgeClass     n
  <ord>    <int>
1 65_74      126
2 75_84      153
3 85plus      21
# A tibble: 2 × 2
  Neuro_any     n
  <fct>     <int>
1 no_neuro    258
2 neuro        42
# A tibble: 6 × 3
  FOF_status AgeClass     n
  <fct>      <ord>    <int>
1 nonFOF     65_74       74
2 FOF        65_74       52
3 nonFOF     75_84       93
4 FOF        75_84       60
5 nonFOF     85plus      12
6 FOF        85plus       9
# A tibble: 12 × 4
   FOF_status AgeClass Neuro_any     n
   <fct>      <ord>    <fct>     <int>
 1 nonFOF     65_74    no_neuro     62
 2 nonFOF     65_74    neuro        12
 3 FOF        65_74    no_neuro     45
 4 FOF        65_74    neuro         7
 5 nonFOF     75_84    no_neuro     80
 6 nonFOF     75_84    neuro        13
 7 FOF        75_84    no_neuro     53
 8 FOF        75_84    neuro         7
 9 nonFOF     85plus   no_neuro     11
10 nonFOF     85plus   neuro         1
11 FOF        85plus   no_neuro      7
12 FOF        85plus   neuro         2
```

---

### K10

**Path:** R-scripts/K10/K10.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 2.4 seconds
**Outputs created:** 2

**New files (max 25 shown):**

- K10/K10_fof_delta_composite_adj_means.png
- K10/K10_fof_delta_composite_raw_means.png

---

### K11

**Path:** R-scripts/K11/K11.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 3.5 seconds
**Outputs created:** 0

**STDERR:**

```
Created DeltaComposite from Delta_Composite_Z.
Error in `mutate()` at magrittr/R/pipe.R:136:3:
ℹ In argument: `Delta_MWS = case_when(...)`.
Caused by error in `case_when()`:
! Failed to evaluate the right-hand side of formula 1.
Caused by error:
! object 'Kävelymuutos' not found
Backtrace:
     ▆
  1. ├─dat_fof %>% ...
  2. ├─dplyr::mutate(...) at magrittr/R/pipe.R:136:3
  3. ├─dplyr:::mutate.data.frame(...) at dplyr/R/mutate.R:146:3
  4. │ └─dplyr:::mutate_cols(.data, dplyr_quosures(...), by) at dplyr/R/mutate.R:181:3
  5. │   ├─base::withCallingHandlers(...) at dplyr/R/mutate.R:268:3
  6. │   └─dplyr:::mutate_col(dots[[i]], data, mask, new_columns) at dplyr/R/mutate.R:273:7
  7. │     └─mask$eval_all_mutate(quo) at dplyr/R/mutate.R:380:9
  8. │       └─dplyr (local) eval() at dplyr/R/data-mask.R:94:7
  9. ├─dplyr::case_when(...)
 10. │ └─dplyr:::case_formula_evaluate(...) at dplyr/R/case-when.R:158:3
 11. │   ├─base::withCallingHandlers(...) at dplyr/R/case-when.R:218:3
 12. │   └─rlang::eval_tidy(pair$rhs, env = default_env) at dplyr/R/case-when.R:227:7
 13. └─base::.handleSimpleError(...) at rlang/R/eval-tidy.R:121:3
 14.   └─dplyr (local) h(simpleError(msg, call))
 15.     └─rlang::abort(message, parent = cnd, call = error_call) at dplyr/R/case-when.R:241:7
Execution halted
```

**STDOUT (tail):**

```
$ Composite_Z0           <dbl> -0.390131181, 0.399747217, -0.893071443, -0.246…
$ Composite_Z2           <dbl> -0.28449055, 1.25360472, -0.19970932, 0.9880648…
$ Delta_Composite_Z      <dbl> 0.10564063, 0.85385750, 0.69336213, 1.23443106,…
$ FOF_status             <dbl> 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1,…
$ Age                    <dbl> 71, 73, 80, 77, 83, 80, 78, 74, 83, 82, 85, 66,…
$ Sex                    <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ FOF_status_f           <fct> Ei FOF, Ei FOF, Ei FOF, Ei FOF, Ei FOF, Ei FOF,…
$ Sex_f                  <fct> female, female, female, female, female, female,…
Rows: 300
Columns: 70
$ id                     <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, …
$ NRO                    <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, …
$ age                    <dbl> 71, 73, 80, 77, 83, 80, 78, 74, 83, 82, 85, 66,…
$ sex                    <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ BMI                    <dbl> 30.4, 17.7, 15.3, 24.7, 23.5, 19.5, 22.5, 21.7,…
$ kaatumisenpelkoOn      <dbl> 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1,…
$ ToimintaKykySummary0   <dbl> -0.390131181, 0.399747217, -0.893071443, -0.246…
$ ToimintaKykySummary2   <dbl> -0.28449055, 1.25360472, -0.19970932, 0.9880648…
$ z_kavelynopeus0        <dbl> 0.32113077, 0.47925397, 1.93737521, 0.09349845,…
$ z_kavelynopeus2        <dbl> -0.97003087, -0.34185218, 0.25787446, -2.348257…
$ z_Tuoli0               <dbl> 0.859500430, 0.182805056, 1.382465133, -0.65635…
$ z_Tuoli2               <dbl> 0.79073219, -1.29402239, -0.38118419, -1.140836…
$ z_Seisominen0          <dbl> 0.80338626, -0.99819978, 1.50461637, 0.05095785…
$ z_Seisominen2          <dbl> 0.38506690, -0.65694740, -1.28987552, 0.1404064…
$ z_Puristus0            <dbl> 0.82999676, 1.03093638, 0.75726970, 0.24934246,…
$ z_Puristus2            <dbl> -0.03685984, 1.61130759, -0.98542520, 0.1480162…
$ MWS0                   <dbl> 1.19, 1.17, 1.69, 0.96, 1.68, 1.83, 1.38, 1.41,…
$ MWS2                   <dbl> 1.09, 1.86, 1.54, 0.92, 1.36, 1.44, 1.09, 1.39,…
$ kavelynopeus_m_sek0    <dbl> 0.98, 1.08, 1.27, 1.14, 1.43, 1.31, 0.83, 1.58,…
$ kavelynopeus_m_sek2    <dbl> 1.16, 1.65, 1.10, 1.32, 1.02, 1.43, 1.13, 1.07,…
$ FTSST0                 <dbl> 22.7, 15.1, 17.2, 9.0, 12.2, 23.4, 11.9, 12.5, …
$ FTSST2                 <dbl> 25.7, 17.1, 17.4, 16.4, 15.7, 16.0, 10.1, 12.3,…
$ tuoliltanousu0         <dbl> 14.1, 7.0, 11.1, 13.6, 17.3, 15.4, 10.4, 25.0, …
$ tuoliltanousu2         <dbl> 13.9, 11.2, 16.0, 13.0, 15.6, 17.0, 17.2, 10.4,…
$ Tuoli0                 <dbl> 16.0, 17.5, 19.2, 25.5, 12.6, 16.7, 20.4, 19.3,…
$ Tuoli2                 <dbl> 15.7, 16.2, 7.3, 17.1, 17.8, 20.0, 8.3, 21.8, 1…
$ SLS0                   <dbl> 13.5, 15.5, 2.4, 14.9, 0.0, 2.9, 2.5, 10.2, 4.5…
$ SLS2                   <dbl> 6.0, 12.1, 11.8, 7.1, 7.5, 4.1, 2.8, 21.6, 8.5,…
$ Seisominen0            <dbl> 15.0, 4.7, 9.8, 10.6, 0.0, 0.0, 5.7, 4.2, 16.8,…
$ Seisominen2            <dbl> 11.3, 10.5, 8.4, 8.3, 10.7, 6.7, 5.4, 8.2, 12.1…
$ HGS0                   <dbl> 31.6, 31.0, 28.0, 20.9, 18.9, 26.5, 20.8, 20.8,…
$ HGS2                   <dbl> 25.0, 24.1, 27.8, 23.6, 18.4, 7.9, 21.2, 22.0, …
$ Puristus0              <dbl> 23.6, 21.8, 30.1, 17.1, 25.9, 5.5, 18.4, 26.0, …
$ Puristus2              <dbl> 27.5, 26.1, 21.3, 39.3, 29.9, 24.3, 16.7, 30.2,…
$ PuristusMuutos         <dbl> -3.5, 3.1, -2.9, -1.5, -1.7, -1.9, 0.0, -2.5, 3…
$ MOIindeksiindeksi      <dbl> 10, 13, 14, 14, 10, 14, 9, 9, 14, 15, 7, 13, 13…
$ diabetes               <dbl> 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0,…
$ alzheimer              <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ parkinson              <dbl> 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ AVH                    <dbl> 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ kaatuminen             <dbl> 0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1,…
$ mieliala               <dbl> 1, 2, 1, 1, 3, 3, 0, 2, 3, 0, 2, 3, 1, 2, 3, 3,…
$ PainVAS0               <dbl> 1.9, 2.9, 6.2, 9.0, 3.3, 7.0, 6.6, 4.2, 6.1, 3.…
$ PainVAS2               <dbl> 7.4, 5.0, 4.6, 8.3, 1.2, 3.6, 6.2, 6.1, 3.0, 2.…
$ SRH                    <dbl> 1, 0, 2, 1, 1, 2, 1, 1, 1, 1, 2, 1, 0, 1, 1, 1,…
$ oma_arvio_liikuntakyky <dbl> 1, 0, 1, 2, 1, 1, 1, 2, 1, 2, 1, 2, 1, 1, 0, 1,…
$ Walk500m               <dbl> 1, 1, 0, 3, 2, 1, 2, 1, 0, 2, 3, 1, 1, 3, 0, 2,…
$ Vaikeus500m            <dbl> 1, 0, 3, 2, 0, 2, 0, 1, 0, 0, 0, 3, 1, 0, 0, 2,…
$ maxkävelymatka         <dbl> 414, 889, 487, 935, 411, 579, 424, 561, 261, 86…
$ vaikeus_liikkua_2km    <dbl> 1, 2, 0, 0, 1, 2, 1, 2, 0, 0, 0, 0, 0, 0, 1, 2,…
$ Balance_problem        <dbl> 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ weight_loss            <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,…
$ exhaustion             <dbl> 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1,…
$ slowness               <dbl> 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0,…
$ low_activity           <dbl> 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0,…
$ weakness               <dbl> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0,…
$ Composite_Z0           <dbl> -0.390131181, 0.399747217, -0.893071443, -0.246…
$ Composite_Z2           <dbl> -0.28449055, 1.25360472, -0.19970932, 0.9880648…
$ Delta_Composite_Z      <dbl> 0.10564063, 0.85385750, 0.69336213, 1.23443106,…
$ FOF_status             <dbl> 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1,…
$ Age                    <dbl> 71, 73, 80, 77, 83, 80, 78, 74, 83, 82, 85, 66,…
$ Sex                    <int> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ FOF_status_f           <fct> Ei FOF, Ei FOF, Ei FOF, Ei FOF, Ei FOF, Ei FOF,…
$ Sex_f                  <fct> female, female, female, female, female, female,…
$ MOI_score              <dbl> 10, 13, 14, 14, 10, 14, 9, 9, 14, 15, 7, 13, 13…
$ psych_score            <dbl> 1, 2, 1, 1, 3, 3, 0, 2, 3, 0, 2, 3, 1, 2, 3, 3,…
$ previous_falls         <dbl> 0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1,…
$ AgeClass               <ord> 65_74, 65_74, 75_84, 75_84, 75_84, 75_84, 75_84…
$ Neuro_any_num          <int> 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
$ Neuro_any              <fct> no_neuro, neuro, neuro, no_neuro, no_neuro, no_…
```

---

### K12

**Path:** R-scripts/K12/K12.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 1.5 seconds
**Outputs created:** 0

**STDERR:**

```
Error in `mutate()` at magrittr/R/pipe.R:136:3:
ℹ In argument: `Delta_MWS = case_when(...)`.
Caused by error in `case_when()`:
! Failed to evaluate the right-hand side of formula 1.
Caused by error:
! object 'Kävelymuutos' not found
Backtrace:
     ▆
  1. ├─analysis_data_rec %>% ...
  2. ├─dplyr::mutate(...) at magrittr/R/pipe.R:136:3
  3. ├─dplyr:::mutate.data.frame(...) at dplyr/R/mutate.R:146:3
  4. │ └─dplyr:::mutate_cols(.data, dplyr_quosures(...), by) at dplyr/R/mutate.R:181:3
  5. │   ├─base::withCallingHandlers(...) at dplyr/R/mutate.R:268:3
  6. │   └─dplyr:::mutate_col(dots[[i]], data, mask, new_columns) at dplyr/R/mutate.R:273:7
  7. │     └─mask$eval_all_mutate(quo) at dplyr/R/mutate.R:380:9
  8. │       └─dplyr (local) eval() at dplyr/R/data-mask.R:94:7
  9. ├─dplyr::case_when(...)
 10. │ └─dplyr:::case_formula_evaluate(...) at dplyr/R/case-when.R:158:3
 11. │   ├─base::withCallingHandlers(...) at dplyr/R/case-when.R:218:3
 12. │   └─rlang::eval_tidy(pair$rhs, env = default_env) at dplyr/R/case-when.R:227:7
 13. └─base::.handleSimpleError(...) at rlang/R/eval-tidy.R:121:3
 14.   └─dplyr (local) h(simpleError(msg, call))
 15.     └─rlang::abort(message, parent = cnd, call = error_call) at dplyr/R/case-when.R:241:7
Execution halted
```

**STDOUT (tail):**

```
# A tibble: 1 × 2
      n n_complete_primary
  <int>              <int>
1   300                300
```

---

### K13

**Path:** R-scripts/K13/K13.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 5.7 seconds
**Outputs created:** 48

**New files (max 25 shown):**

- FOF_effect_by_age_simple_slopes.png
- FOF_effect_by_BMI_simple_slopes.png
- FOF_effect_by_MOI_simple_slopes.png
- FOF_effect_by_Pain_simple_slopes.png
- FOF_effect_by_sex_simple_slopes.png
- FOF_effect_by_SRH_simple_slopes.png
- FOF_effect_by_SRM_simple_slopes.png
- FOF_interaction_effects_interpretation.csv
- FOF_interaction_effects_interpretation.html
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

---

### K14

**Path:** R-scripts/K14/K14.R
**Status:** ✗ FAILED
**Exit code:** 1
**Execution time:** 1.1 seconds
**Outputs created:** 0

**STDERR:**

```
Error in `mutate()` at magrittr/R/pipe.R:136:3:
ℹ In argument: `SRH_3class_table = factor(...)`.
Caused by error:
! object 'koettuterveydentila' not found
Backtrace:
     ▆
  1. ├─analysis_data %>% ...
  2. ├─dplyr::mutate(...) at magrittr/R/pipe.R:136:3
  3. ├─dplyr:::mutate.data.frame(...) at dplyr/R/mutate.R:146:3
  4. │ └─dplyr:::mutate_cols(.data, dplyr_quosures(...), by) at dplyr/R/mutate.R:181:3
  5. │   ├─base::withCallingHandlers(...) at dplyr/R/mutate.R:268:3
  6. │   └─dplyr:::mutate_col(dots[[i]], data, mask, new_columns) at dplyr/R/mutate.R:273:7
  7. │     └─mask$eval_all_mutate(quo) at dplyr/R/mutate.R:380:9
  8. │       └─dplyr (local) eval() at dplyr/R/data-mask.R:94:7
  9. ├─base::factor(...)
 10. └─base::.handleSimpleError(...)
 11.   └─dplyr (local) h(simpleError(msg, call))
 12.     └─rlang::abort(message, class = error_class, parent = parent, call = error_call) at dplyr/R/conditions.R:235:5
Execution halted
```

**STDOUT (tail):**

```
# A tibble: 1 × 2
      n n_complete_primary
  <int>              <int>
1   300                300
```

---

### K15

**Path:** R-scripts/K15/K15.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 2.6 seconds
**Outputs created:** 19

**New files (max 25 shown):**

- K15_chisq_FOF_by_frailty_cat3.csv
- K15_chisq_FOF_by_frailty_cat3.html
- K15_chisq_FOF_by_frailty_cat4.csv
- K15_chisq_FOF_by_frailty_cat4.html
- K15_frailty_analysis_data.RData
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
- sessioninfo_K15.txt

---

### K16

**Path:** R-scripts/K16/K16.R
**Status:** ✓ PASSED
**Exit code:** 0
**Execution time:** 6.9 seconds
**Outputs created:** 7

**New files (max 25 shown):**

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

- **K8** (exit 1): Attaching package: ‘dplyr’

The following objects are masked from ‘package:stats’:

```text
filter, lag
```

The following objects are masked from ‘package:base’:

```text
intersect, setdiff, setequal, union
```

Loa

- **K9** (exit 1): Created DeltaComposite as ToimintaKykySummary2 - ToimintaKykySummary0.
Error in `mutate()` at magrittr/R/pipe.R:136:3:
ℹ In argument: `Delta_MWS = case_when(...)`.
Caused by error in `case_when()`:
!
- **K11** (exit 1): Created DeltaComposite from Delta_Composite_Z.
Error in `mutate()` at magrittr/R/pipe.R:136:3:
ℹ In argument: `Delta_MWS = case_when(...)`.
Caused by error in `case_when()`:
! Failed to evaluate the r
- **K12** (exit 1): Error in `mutate()` at magrittr/R/pipe.R:136:3:
ℹ In argument: `Delta_MWS = case_when(...)`.
Caused by error in `case_when()`:
! Failed to evaluate the right-hand side of formula 1.
Caused by error:
!
- **K14** (exit 1): Error in `mutate()` at magrittr/R/pipe.R:136:3:
ℹ In argument: `SRH_3class_table = factor(...)`.
Caused by error:
! object 'koettuterveydentila' not found
Backtrace:
     ▆
  1. ├─analysis_data %>% ..

---

## END OF REPORT
