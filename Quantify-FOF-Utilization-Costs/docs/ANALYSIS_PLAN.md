# Analysis Plan: Quantify FOF Utilization & Costs (Aim 2)

**Status:** Draft
**Context:** Aim 2 of the FOF Project
**Governance:** Option B (No raw data in repo)

## 1. Research Objectives

1. **Quantify Utilization:** Does baseline Fear of Falling (FOF) predict higher health service utilization (visits, days) over a 10-year follow-up?
2. **Quantify Costs:** Does baseline FOF predict higher direct healthcare costs?
3. **Attributable Fraction:** What proportion of costs is attributable to FOF vs. confounders (Age, Sex, Comorbidities)?

## 2. Study Population & Design

- **Cohort:** MFFP participants (N=~800?).
- **Linkage:** Register data from `DATA_ROOT` (Avohilmo, Hilmo).
- **Time Horizon:** 10 years (2010–2019) or from baseline interview date.
- **Groups:** FOF (1) vs. No-FOF (0) at baseline.

## 3. Data Variables & Standardization

- **Adherence:** All variables must be mapped via `data/VARIABLE_STANDARDIZATION.csv`.
- **Key Predictors:**
  - `FOF_status` (Binary)
  - `Age` (Baseline)
  - `Sex`
  - `Morbidity_Index` (Charlson or similar, derived from register diagnoses)
- **Outcomes (Dependent Vars):**
  - `Total_Visits_Primary` (Count)
  - `Total_Days_Inpatient` (Count)
  - `Total_Costs_EUR` (Continuous, skewed, zero-inflated)

## 4. Statistical Models

### 4.1 Utilization (Count Data)

Since visit counts are non-negative integers and likely over-dispersed:

- **Primary:** Negative Binomial Regression.
  - `Visits ~ FOF_status + Age + Sex + Comorbidities + offset(log(follow_up_time))`
- **Secondary:** Zero-Inflated Negative Binomial (ZINB) if excess zeros exist.

### 4.2 Costs (Continuous, Skewed)

Cost data is typically highly skewed with a mass at zero.

- **Approach A: Two-Part Model**
  1. Probit/Logit model for Probability of Any Cost (>0).
  2. GLM (Gamma family with Log link) for Cost amount (given Cost > 0).
- **Approach B: Generalized Linear Model (GLM)**
  - Gamma/Log or Tweedie distribution.

## 5. QC Gates (Quality Control)

Before analysis, run `scripts/30_qc_summary.py` (or R equivalent) to verify:

1. **Logical Consistency:** Costs >= 0, Visits >= 0.
2. **Completeness:** No missing FOF status.
3. **Linkage Rate:** % of cohort found in register data.
4. **Outliers:** Check for extreme cost outliers (top 1%) and decide on winsorization/truncation plan (documented).

## 6. Runbook & Reproducibility

1. **Environment:** Ensure `renv` (R) or `requirements.txt` (Python) is synced.
2. **Data Inventory:** Run `scripts/00_inventory_manifest.py` to index `DATA_ROOT`.
3. **QC Run:** Execute logic checks.
4. **Analysis:** Run modeling scripts (e.g., `Q20_models.R`).
5. **Output:** Check `outputs/` and `manifest/manifest.csv` for logged results.
