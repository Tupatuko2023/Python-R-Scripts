# Fear-of-Falling Analysis Plan (K20)

**Version:** 1.0 (Draft)
**Date:** 2025-12-29
**Status:** Active

This document defines the authoritative analysis plan for the "Fear of Falling" (FOF) sub-project. It serves as the bridge between the research protocol and the technical implementation (R code).

## 1. Study Design & Research Question

**Objective:** To estimate the relative and independent effects of baseline Fear of Falling (FOF), frailty status (Fried-inspired proxy), and balance on 12-month trajectory/change in physical performance (Composite Z-score), adjusting for key confounders.

- **Design:** Longitudinal cohort study (Baseline -> 12-month follow-up).
- **Primary Comparison:**
  - **Independent effects:** In the same model, estimate `time:FOF_status`, `time:frailty_cat_3`, and `time:tasapainovaikeus` (or verified balance equivalent) to isolate each exposure's association with 12-month change.
  - **Relative effects:** Compare effect magnitudes on a common scale and, when needed, test contrasts between time-interaction terms (Wald / `linearHypothesis`) with 95% CI.

## 2. Data & Variables (Verified Map)

All analysis must use these **canonical variable names**. Do not invent aliases.

| Canonical Name       | Source / Derivation                 | Type          | Levels / Coding                       |
| :------------------- | :---------------------------------- | :------------ | :------------------------------------ |
| **id**               | `id` (from source)                  | Identifier    | Unique per participant                |
| **time**             | `time` / `time_months`              | Factor        | `0` (Baseline), `12` (Follow-up)      |
| **FOF_status**       | `kaatumisenpelkoOn`                 | Factor        | `0`="Ei FOF" (Ref), `1`="FOF"         |
| **frailty_cat_3**    | K15/K18 derived (`frailty_count_3`) | Factor        | `robust`, `pre-frail`, `frail`        |
| _frailty_score_3_    | K15/K18 derived (`frailty_count_3`) | Numeric       | 0-3 (continuous frailty proxy)        |
| **tasapainovaikeus** | Raw source / K08/K14 usage          | Binary/Factor | `0` = no difficulty, `1` = difficulty |
| _Seisominen\*_       | Raw source columns (K08/K12 usage)  | Numeric       | Objective balance candidate (TBD)     |
| **Composite_Z**      | `ToimintaKykySummary0` & `2`        | Numeric       | Continuous (Z-score)                  |
| **age**              | `age`                               | Numeric       | Years                                 |
| **sex**              | `sex`                               | Factor        | Verify: Male/Female                   |
| **BMI**              | `BMI`                               | Numeric       | kg/m²                                 |
| _SRH_ (Optional)     | `SRH` / `koettuterveydentila`       | Factor        | Verify: Good/Avg/Poor (1-3 or 0-2)    |

**Notes:**

- **Immutable Data:** Raw data in `data/` is strictly READ-ONLY. All transformations happen in R.
- **FOF Derivation:** Derived from binary `kaatumisenpelkoOn`. Ensure factor levels are explicit.
- **Frailty Derivation:** Use `frailty_cat_3` as primary frailty exposure; use `frailty_score_3` for sensitivity analyses.
- **Balance Variable:** Primary balance exposure is `tasapainovaikeus` unless a different canonical balance variable is verified in `data/data_dictionary.csv`.
- **Sensitivity row detail:** `_frailty_score_3_` corresponds to sensitivity analyses.
- **Objective balance candidate detail:** `_Seisominen*_` maps to raw `Seisominen0` / `Seisominen2` columns (SLS proxy in K08/K12); confirm final canonical analysis name in `data/data_dictionary.csv` (`Seisominen*` vs `SLS*`).
- **Timepoint:** Ensure "12" corresponds to the correct follow-up column (`ToimintaKykySummary2`).

## 3. Statistical Models

### 3.1 Primary Model: Longitudinal Mixed Model (LMM)

We analyze the _long-format_ dataset to maximize power and handle missing data under MAR.

```r
# Formula (lmer)
Composite_Z ~ time * FOF_status + time * frailty_cat_3 + time * tasapainovaikeus +
  age + sex + BMI + (1 | id)
```

- **Key Interest:** The interaction terms `time:FOF_status`, `time:frailty_cat_3`, and `time:tasapainovaikeus`.
- **Independent effects operationalization:** All exposure-by-time terms are estimated jointly in one model.
- **Relative effects operationalization:** Report estimates on a common scale with 95% CI and test targeted coefficient differences (e.g., `time:FOF_status` vs `time:frailty_cat_3`) via Wald / `linearHypothesis`.
- **Exploratory only (optional):** `time * FOF_status * frailty_cat_3` (and/or balance moderation) may be run as secondary analyses, clearly labeled exploratory.

### 3.2 Cross-Check: ANCOVA (Wide Format)

To verify robustness, we perform an ANCOVA on the wide dataset (complete cases for outcome).

```r
# Formula (lm)
Composite_Z_12m ~ Composite_Z_baseline + FOF_status + frailty_cat_3 +
  tasapainovaikeus + age + sex + BMI
```

- **Consistency Check:** The effect size and direction should align with the LMM interaction term.

## 4. QC Gates (Quality Control)

Before running the final models, the data must pass the strict QC gates defined in `QC_CHECKLIST.md`.

- **Gate 1 (Ingest):** No data corruption (row counts match, IDs unique).
- **Gate 2 (Logic):** `time` has exactly 2 levels; `FOF_status` has exactly 2 levels.
- **Gate 3 (Missingness):** Report missingness by Group x Time.
- **Gate 2.1 (Exposure Levels):** Verify valid levels/coding for `frailty_cat_3` and `tasapainovaikeus` (or verified balance equivalent).
- **Gate 3.1 (Exposure Missingness):** Extend missingness reporting to FOF x frailty x balance strata (or equivalent grouped summaries) and explicitly report frailty/balance missingness.
- **Gate 4 (Delta Check):** Ensure `Delta = FollowUp - Baseline` (tolerance 1e-8).

**Runner:** `R-scripts/K18/K18_QC.V1_qc-run.R` (or latest equivalent).

## 5. Analysis Runbook

Follow this sequence to reproduce the results.

1. **Environment Setup:**

   ```bash
   Rscript -e "renv::restore()"
   ```

2. **QC & Validation:**

   ```bash
   Rscript R-scripts/K18/K18_QC.V1_qc-run.R
   # Verify: outputs/qc_report.html says "PASS"
   ```

3. **Primary Analysis (Long):**

   ```bash
   # Placeholder: Rscript R-scripts/K20/K20_LMM.V1_primary.R
   ```

4. **Sensitivity Analysis (Wide):**

   ```bash
   # Placeholder: Rscript R-scripts/K20/K20_ANCOVA.V1_check.R
   ```

## 6. What Cannot Change (Non-Negotiables)

1. **Raw Data:** Never manually edit CSV/Excel files.
2. **Variable Names:** Use the map above. Do not rename `FOF_status` to `Group` or similar ambiguity.
3. **Reproducibility:** `set.seed(20251124)` only for bootstrapping/MI.
4. **Outputs:** All artifacts go to `R-scripts/Kxx/outputs/` and are logged in `manifest/manifest.csv`.

---

_Reference: See `data/data_dictionary.csv` and `data/Muuttujasanakirja.md` for full definitions._
