# Fear-of-Falling Analysis Plan (K50)

**Version:** 1.1 (Draft)
**Date:** 2026-03-12
**Status:** Active

This document defines the authoritative analysis plan for the "Fear of Falling" (FOF) sub-project. It serves as the bridge between the research protocol and the technical implementation (R code).

## Analysis Phase Context

This document corresponds to the K50 analysis stage of the Fear-of-Falling pipeline, where the primary locomotor capacity outcome and modeling rules are already defined. Earlier exploratory phases (K20-K40) covered variable derivation, CFA measurement modeling, and QC verification. This analysis plan therefore documents the confirmed modeling structure rather than an exploratory outcome definition.

### Document Scope Rule

This document defines the statistical modeling rules for the Fear-of-Falling K50 analysis stage.
It does not define upstream variable construction or QC procedures in detail. Those processes are documented in the measurement model and QC appendices.

## 1. Study Design & Research Question

**Study aim:** To estimate how baseline Fear of Falling (FOF) is associated with change in physical performance over 12 months, adjusting for key confounders and separating current primary analyses from legacy bridge analyses.

- **Design:** Longitudinal cohort study (Baseline -> 12-month follow-up).
- **Current analysis line:** The current primary outcome line is `locomotor_capacity`, defined from the CFA 3-item locomotor capacity construct. The deterministic `z3` composite is retained as a fallback / sensitivity measure for the same construct.
- **Legacy bridge line:** `Composite_Z` is not the default whole-sample primary outcome. It is retained only as a continuity / bridge analysis if the original `ToimintaKykySummary` definition is verified sufficiently.

## 2. Data & Variables (Verified Map)

All analysis must use these **canonical variable names**. Do not invent aliases or mix naming systems across scripts and reports.

| Canonical Name | Source / Derivation | Type | Levels / Coding |
| :--- | :--- | :--- | :--- |
| **id** | `id` (from source) | Identifier | Unique per participant |
| **time** | `time` / `time_months` | Factor | `0` (Baseline), `12` (Follow-up) |
| **FOF_status** | `kaatumisenpelkoOn` | Factor | `0`="Ei FOF" (Ref), `1`="FOF" |
| **age** | `age` | Numeric | Years |
| **sex** | `sex` | Factor | Verify: Male/Female |
| **BMI** | `BMI` | Numeric | kg/m2 |
| **locomotor_capacity** | CFA 3-item latent score | Numeric | Current primary outcome |
| **z3** | Standardized gait + chair rise + balance composite | Numeric | Deterministic fallback / sensitivity measure |
| **Composite_Z** | Legacy `ToimintaKykySummary0` & `ToimintaKykySummary2` mapping | Numeric | Legacy outcome only; bridge analysis if verified |
| **FI22_nonperformance_KAAOS** / **FI_22** | Locked FI22 variant | Numeric | Sensitivity index; not default primary predictor |
| **tasapainovaikeus** | Raw source / K08/K14 usage | Binary/Factor | Use only if modeled separately as covariate/predictor, not as outcome indicator |
| **grip_r0 / grip_l0 / grip_r2 / grip_l2** | Raw grip fields | Numeric | Subset-only auxiliary data |

**Notes:**

- **Immutable data:** Raw data in `data/` is strictly READ-ONLY. All transformations happen in code.
- **Canonical naming discipline:** Baseline/follow-up mappings must stay explicit. Uncontrolled aliasing such as `Composite_Z2`, `Composite_Z3`, or ad hoc outcome renames is not allowed.
- **Current primary outcome definition:** `locomotor_capacity` refers to the CFA 3-item locomotor capacity construct documented in the methods appendix and measurement model.
- **Fallback definition:** `z3` is the deterministic fallback / sensitivity representation of the same locomotor construct and should not be presented as a separate new primary score.
- **Legacy continuity rule:** `Composite_Z` may be analyzed only in a legacy bridge role if the original `ToimintaKykySummary` definition is verified for continuity purposes.

### 2.1 Baseline-Follow-up Naming Rule

Baseline and follow-up outcome variables must remain explicit in wide datasets.

Recommended canonical mapping:

- `locomotor_capacity_0` = baseline value
- `locomotor_capacity_12m` = follow-up value
- same convention applies to `z3`

### 2.2 Delta Definition (QC Reference)

When delta outcomes are used for QC or exploratory summaries:

- `delta_locomotor_capacity = locomotor_capacity_12m - locomotor_capacity_0`
- `delta_z3 = z3_12m - z3_0`

These delta values are not the default primary outcome in the ANCOVA branch but may be used for QC verification and descriptive reporting.

### 2.3 Outcome Provenance Rule

`locomotor_capacity` and `z3` are derived variables produced upstream in the measurement and QC pipeline.
This analysis plan assumes that these variables already passed their respective construction and validation steps in the locomotor capacity measurement documentation and QC appendices.

### 2.4 Upstream Dependencies

The following documents define upstream construction and validation of derived variables used in this analysis plan:

- CFA 3-item locomotor capacity measurement documentation
- locomotor capacity QC appendix
- FI22 methods appendix
- project QC pipeline documentation

These documents must be considered authoritative for variable construction.

## 3. Outcome, Predictor, and Covariate Roles

### 3.1 Primary Outcome

- **Current primary outcome:** `locomotor_capacity`
- **Method basis:** CFA 3-item locomotor capacity construct
- **Fallback / sensitivity outcome:** `z3`

### 3.2 Primary Predictors and Covariates

- **Primary exposure of interest:** `FOF_status`
- **Core covariates:** `age`, `sex`, `BMI`
- **Optional additional covariate:** `tasapainovaikeus`, only if treated explicitly as a separate covariate/predictor and not recycled from the locomotor outcome indicator set

### 3.3 Secondary / Sensitivity Indices

- `FI22_nonperformance_KAAOS` / `FI_22` is a locked **sensitivity index**. It should not be written as an undisputed primary predictor unless stronger documentation is found.
- `frailty_cat_3` may be analyzed as a secondary / sensitivity frailty structure. It is not the current primary anchor of the analysis plan.
- Numeric frailty variants such as `frailty_score_3` remain sensitivity-only unless a separate locked protocol states otherwise.

## 4. Grip Handling

Grip strength is kept separate from the whole-sample locomotor capacity primary score.

- The CFA 3-item locomotor capacity documentation excludes grip strength from the core model because grip data is not consistently available and the construct focus is locomotor performance.
- Functional test schema documentation shows a separate grip branch with Excel classification issues and `kg_candidate` handling.
- Grip can be used in separate subset analyses where valid kg data is available, but Excel grip classes and CSV kg values must not be pooled automatically into the main locomotor composite.

## 5. Statistical Models

### 5.1 Current Modeling Rule

The primary model depends on the structure of the analysis dataset.

Model structure defined here corresponds to the K50 analysis stage; upstream derivation of `locomotor_capacity` and `z3` is defined in measurement / QC appendices.

- **If the dataset is wide with two timepoints:** primary analysis is ANCOVA on follow-up outcome with baseline adjustment.
- **If the dataset is long / repeated:** primary analysis is a mixed model with `time * FOF_status`.

### 5.2 Primary Model for Wide Data: ANCOVA

Use the follow-up value of the current primary outcome with baseline adjustment.

```r
# Formula (lm)
locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI
```

- This is the default primary branch when the working dataset is two-timepoint wide.
- `tasapainovaikeus`, FI22, or frailty measures may be added only as clearly labeled covariate / sensitivity terms, not as assumed primary anchors.
- A parallel ANCOVA using `z3` may be used as a deterministic fallback / sensitivity check.

### 5.3 Primary Model for Long Data: Mixed Model

Use the repeated-measures outcome formulation when the working dataset is long.

```r
# Formula (lmer)
locomotor_capacity ~ time * FOF_status + age + sex + BMI + (1 | id)
```

- This is the default primary branch when the working dataset is long / repeated.
- `time * frailty_cat_3` is not the default primary formula.
- Secondary long-format checks may add frailty or FI22 terms only when explicitly labeled as secondary / sensitivity analyses.
- A parallel mixed model using `z3` may be used as a deterministic fallback / sensitivity check.

### 5.4 Secondary / Sensitivity Analyses

Examples of acceptable secondary analyses:

```r
# Secondary frailty sensitivity
locomotor_capacity ~ time * FOF_status + frailty_cat_3 + age + sex + BMI + (1 | id)

# FI22 sensitivity index
locomotor_capacity ~ time * FOF_status + FI22_nonperformance_KAAOS + age + sex + BMI + (1 | id)
```

- Report these as secondary or sensitivity analyses, not as replacements for the current primary line.
- If balance is modeled separately, use canonical naming and explain whether it is a covariate, predictor, or sensitivity term.

### 5.5 Legacy Bridge Analysis

`Composite_Z` is retained only for continuity / bridge analysis.

```r
# Legacy bridge example (run only if original definition is verified)
Composite_Z ~ time * FOF_status + age + sex + BMI + (1 | id)
```

- This branch is available only **if original definition is verified**.
- `Composite_Z` should be described as a historical / bridge outcome, not as the default current primary outcome for the whole dataset.
- `z3` should not be renamed to `Composite_Z` and no new composite score should be introduced under the `Composite_Z` label.

## 6. QC Gates (Quality Control)

Before running the final models, the data must pass the strict QC gates defined in `QC_CHECKLIST.md`.

- **Gate 1 (Ingest):** No data corruption (row counts match, IDs unique).
- **Gate 2 (Logic):** `time` has exactly 2 levels; `FOF_status` has exactly 2 levels.
- **Gate 3 (Missingness):** Report missingness by Group x Time.
- **Gate 4 (Outcome verification):** Confirm whether the run uses `locomotor_capacity`, `z3`, or legacy `Composite_Z`, and label outputs accordingly.
- **Gate 5 (Sensitivity index verification):** If FI22 is used, confirm the locked variant is `FI22_nonperformance_KAAOS` with role `sensitivity_index`.
- **Gate 6 (Grip separation):** Do not merge grip branches into the whole-sample locomotor capacity score.
- **Gate 7 (Table-to-text crosscheck):** Any textual interpretation of results must match the numerical values reported in model tables. If discrepancies appear between narrative text and model output tables, the tables take precedence and the text must be corrected.

**Runner:** `R-scripts/K18/K18_QC.V1_qc-run.R` (or latest equivalent).

### Outcome Labeling Rule (Outputs)

All statistical outputs must clearly state which outcome variable was used:

- `locomotor_capacity` (primary outcome)
- `z3` (fallback / sensitivity outcome)
- `Composite_Z` (legacy bridge outcome)

Output filenames and manifest entries must include the outcome name to prevent ambiguity.

## 7. Analysis Runbook

Follow this sequence to reproduce the results.

1. **Environment Setup:**

   ```bash
   Rscript -e "renv::restore()"
   ```

2. **QC & Validation:**

   ```bash
   Rscript R-scripts/K18/K18_QC.V1_qc-run.R \
     --data data/external/KaatumisenPelko.csv \
     --shape AUTO \
     --dict data/data_dictionary.csv
   # Verify: outputs/qc_report.html says "PASS"
   ```

3. **Primary Analysis:**

   ```bash
   # Wide data -> ANCOVA on follow-up outcome with baseline adjustment
   # Long data -> mixed model with time * FOF_status
   ```

4. **Sensitivity / Bridge Analyses:**

   ```bash
   # z3 fallback / sensitivity
   # frailty_cat_3 secondary analysis
   # FI22 sensitivity index analysis
   # Composite_Z legacy bridge analysis only if original definition is verified
   ```

### Downstream Outputs Reference

Results generated under this analysis plan are written to the standard project output structure:

`R-scripts/Kxx/outputs/<script_label>/`

Each artifact must be registered in:

`manifest/manifest.csv`

The outcome variable used in each analysis must appear in the output filename and manifest entry.

## 8. What Cannot Change (Non-Negotiables)

1. **Raw data:** Never manually edit CSV/Excel files.
2. **Canonical variable names:** Use the map above and keep baseline/follow-up logic explicit.
3. **Primary outcome line:** Do not present `frailty_cat_3` or `Composite_Z` as the undisputed current primary core.
4. **Reproducibility:** `set.seed(20251124)` only for bootstrapping/MI.
5. **Outputs:** All artifacts go to `R-scripts/Kxx/outputs/` and are logged in `manifest/manifest.csv`.

---

_Reference: See `data/data_dictionary.csv`, `data/Muuttujasanakirja.md`, CFA 3-item locomotor capacity documentation, and FI22 methods appendix for full definitions._
