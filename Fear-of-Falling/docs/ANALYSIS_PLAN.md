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

**Study aim:** To estimate how baseline Fear of Falling (FOF) is associated with change in physical performance over 12 months, adjusting for key confounders and operationalizing frailty primarily with the K40-derived `frailty_index_fi` (`FI_22`) while retaining simpler frailty proxies only as fallback / sensitivity terms.

- **Design:** Longitudinal cohort study (Baseline -> 12-month follow-up).
- **Current analysis line:** The current primary outcome line is `locomotor_capacity`, defined from the CFA 3-item locomotor capacity construct. The deterministic `z3` composite is retained as a fallback / sensitivity measure for the same construct.
- **Legacy bridge line:** `Composite_Z` is not the default whole-sample primary outcome. It is retained only as a continuity / bridge analysis if the original `ToimintaKykySummary` definition is verified sufficiently.

## 2. Data & Variables (Verified Map)

All analysis must use these **canonical variable names**. Do not invent aliases or mix naming systems across scripts and reports.

| Canonical Name                            | Source / Derivation                                            | Type          | Levels / Coding                                                                 |
| :---------------------------------------- | :------------------------------------------------------------- | :------------ | :------------------------------------------------------------------------------ |
| **id**                                    | `id` (from source)                                             | Identifier    | Unique per participant                                                          |
| **time**                                  | `time` / `time_months`                                         | Factor        | `0` (Baseline), `12` (Follow-up)                                                |
| **FOF_status**                            | `kaatumisenpelkoOn`                                            | Factor        | `0`="Ei FOF" (Ref), `1`="FOF"                                                   |
| **age**                                   | `age`                                                          | Numeric       | Years                                                                           |
| **sex**                                   | `sex`                                                          | Factor        | Verify: Male/Female                                                             |
| **BMI**                                   | `BMI`                                                          | Numeric       | kg/m2                                                                           |
| **locomotor_capacity**                    | CFA 3-item latent score                                        | Numeric       | Current primary outcome                                                         |
| **z3**                                    | Standardized gait + chair rise + balance composite             | Numeric       | Deterministic fallback / sensitivity measure                                    |
| **Composite_Z**                           | Legacy `ToimintaKykySummary0` & `ToimintaKykySummary2` mapping | Numeric       | Legacy outcome only; bridge analysis if verified                                |
| **frailty_index_fi**                      | K40 `FI22_nonperformance_KAAOS` patient-level output           | Numeric       | Primary frailty measure (continuous FI_22, 0-1)                                 |
| **frailty_index_fi_z**                    | Standardized `frailty_index_fi`                                | Numeric       | Optional scaled primary frailty measure                                          |
| **n_deficits_observed**                   | K40 patient-level QC output                                    | Integer       | Number of observed FI deficits used in score calculation                         |
| **coverage**                              | K40 patient-level QC output                                    | Numeric       | Fraction of selected deficits observed for each participant                      |
| **fi_eligible**                           | K40 patient-level QC output                                    | Logical       | `TRUE` only when FI QC thresholds are met                                        |
| **tasapainovaikeus**                      | Raw source / K08/K14 usage                                     | Binary/Factor | Use only if modeled separately as covariate/predictor, not as outcome indicator |
| **grip_r0 / grip_l0 / grip_r2 / grip_l2** | Raw grip fields                                                | Numeric       | Subset-only auxiliary data                                                      |

**Notes:**

- **Immutable data:** Raw data in `data/` is strictly READ-ONLY. All transformations happen in code.
- **Canonical naming discipline:** Baseline/follow-up mappings must stay explicit. Uncontrolled aliasing such as `Composite_Z2`, `Composite_Z3`, or ad hoc outcome renames is not allowed.
- **Current primary outcome definition:** `locomotor_capacity` refers to the CFA 3-item locomotor capacity construct documented in the methods appendix and measurement model.
- **Fallback definition:** `z3` is the deterministic fallback / sensitivity representation of the same locomotor construct and should not be presented as a separate new primary score.
- **Primary frailty operationalization:** Frailty is operationalized primarily as continuous `frailty_index_fi` (or `frailty_index_fi_z`) from the locked K40 `FI22_nonperformance_KAAOS` pipeline.
- **FI lineage note:** `FI22_nonperformance_KAAOS` / `FI_22` is the locked variant label and contract anchor, not a separate patient-level numeric analysis field.
- **Dataset integration TODO:** If `frailty_index_fi`, `frailty_index_fi_z`, `n_deficits_observed`, `coverage`, and `fi_eligible` are not already present in the analysis dataset, join the K40 patient-level output to the analysis dataset by `id` before modeling.
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
- `docs/FOF_UPSTREAM_LOCOMOTOR_OUTCOME_SPEC.md`

These documents must be considered authoritative for variable construction.

### 2.5 Variable Architecture / Outcome Roles

Current outcome architecture is locked to three outcome branches and separate
auxiliary branches:

- `locomotor_capacity` = current primary outcome
- `z3` = deterministic fallback / sensitivity outcome
- `Composite_Z` = legacy bridge only
- `frailty_index_fi` / `frailty_index_fi_z` = primary frailty branch, kept
  separate from the locomotor outcome branch
- `FI22_nonperformance_KAAOS` = locked variant label for the FI branch
- `frailty_cat_3` = fallback / sensitivity-only frailty proxy, not an active
  default modeling anchor
- `frailty_score_3` = fallback / sensitivity-only frailty proxy score
- `tasapainovaikeus` = separate auxiliary covariate/predictor, not an outcome
  indicator
- `grip_*` = auxiliary/subset-only branch, kept separate from the core
  locomotor outcome architecture
- `locomotor_capacity_0`, `locomotor_capacity_12m`, `z3_0`, `z3_12m`,
  `delta_locomotor_capacity`, and `delta_z3` are the canonical time-mapped
  names for wide/QC usage

No new ad hoc composite outcome names are permitted in the current plan.

## 3. Outcome, Predictor, and Covariate Roles

### 3.1 Primary Outcome

- **Current primary outcome:** `locomotor_capacity`
- **Method basis:** CFA 3-item locomotor capacity construct
- **Fallback / sensitivity outcome:** `z3`

### 3.2 Primary Predictors and Covariates

- **Primary exposure of interest:** `FOF_status`
- **Core covariates:** `age`, `sex`, `BMI`
- **Primary frailty measure:** `frailty_index_fi` (or `frailty_index_fi_z` in scaled models), derived from the locked K40 `FI22_nonperformance_KAAOS` contract
- **Optional additional covariate:** `tasapainovaikeus`, only if treated explicitly as a separate covariate/predictor and not recycled from the locomotor outcome indicator set
- **FI lineage / variant anchor:** `FI22_nonperformance_KAAOS`, documented to make the active FI contract explicit and to prevent drift to other frailty variants

### 3.3 Secondary / Sensitivity Indices

- `frailty_cat_3` is retained only as a fallback / sensitivity frailty proxy
  for comparison against the primary FI-based operationalization.
- `frailty_score_3` may be used in the same fallback / sensitivity role when a
  score-form proxy is preferred over the categorical version.
- `FI22_nonperformance_KAAOS` / `FI_22` names the locked K40 variant behind
  `frailty_index_fi`; use the patient-level FI outputs rather than the variant
  label itself as the primary model term.
- Categorical frailty structures such as `frailty_cat_3` must not displace
  `frailty_index_fi` as the primary frailty term in the active analysis plan.

## 4. Grip Handling

Grip strength is kept separate from the whole-sample locomotor capacity primary score.

- The CFA 3-item locomotor capacity documentation excludes grip strength from the core model because grip data is not consistently available and the construct focus is locomotor performance.
- Functional test schema documentation shows a separate grip branch with Excel classification issues and `kg_candidate` handling.
- Grip can be used in separate subset analyses where valid kg data is available, but Excel grip classes and CSV kg values must not be pooled automatically into the main locomotor composite.

For implementation-layer harmonization and preprocessing details, see
`docs/FOF_UPSTREAM_LOCOMOTOR_OUTCOME_SPEC.md`.

## 5. Statistical Models

### 5.1 Current Modeling Rule

The primary model depends on the structure of the analysis dataset.

Model structure defined here corresponds to the K50 analysis stage; upstream derivation of `locomotor_capacity` and `z3` is defined in measurement / QC appendices.

- **If the dataset is wide with two timepoints:** primary analysis is ANCOVA on follow-up outcome with baseline adjustment.
- **If the dataset is long / repeated:** primary analysis is a mixed model with `time * FOF_status`.
- Frailty effect-modification and frailty-adjusted models must use
  `frailty_index_fi` (or `frailty_index_fi_z`) as the primary frailty term.
- `frailty_cat_3` is reserved for fallback / sensitivity analyses only.

### 5.1.1 Primary Branch Selection Rule

Primary branch selection must be deterministic and explicitly declared in the analysis run.

- **Wide branch** is used only when the analysis dataset has one row per `id` and explicit baseline/follow-up outcome columns such as `locomotor_capacity_0` and `locomotor_capacity_12m`. The same structural rule applies to fallback outcomes `z3_0` and `z3_12m`.
- **Long branch** is used only when the analysis dataset has repeated rows per `id`, one outcome column such as `locomotor_capacity` or `z3`, and `time` encodes the measurement occasion with `time in {0, 12}`.
- **Canonical long-format time rule:** The current analytical contract accepts only numeric canonical time-coding `0 = baseline` and `12 = 12-month follow-up` in the primary long-branch model. If upstream data use other time codes or labels, they must be recoded to canonical `0/12` before primary modeling.
- The selected branch must be declared explicitly in the run configuration via a documented selector such as `analysis_shape = wide|long` or an equivalent CLI flag such as `--shape WIDE|LONG`.
- `AUTO` is acceptable in QC to detect dataset shape, but primary-analysis branch selection must not rely on a silent ad hoc choice.

### 5.2 Primary Model for Wide Data: ANCOVA

Use the follow-up value of the current primary outcome with baseline adjustment.

```r
# Formula (lm)
locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + frailty_index_fi + age + sex + BMI
```

- This is the default primary branch when the working dataset is two-timepoint wide.
- If scaling improves interpretability, `frailty_index_fi_z` may replace `frailty_index_fi` in an otherwise identical model specification.
- If the intended balance-adjusted variant is used, keep the same FOF-centered
  structure and add FI without dropping balance:
  `locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + frailty_index_fi + tasapainovaikeus + age + sex + BMI`.
- `frailty_cat_3` and `frailty_score_3` do not belong in the default primary ANCOVA.
- A parallel ANCOVA using `z3` may be used as a deterministic fallback / sensitivity check.

### 5.3 Primary Model for Long Data: Mixed Model

Use the repeated-measures outcome formulation when the working dataset is long.

```r
# Formula (lmer)
locomotor_capacity ~ time * FOF_status + time * frailty_index_fi + age + sex + BMI + (1 | id)
```

- This is the default primary branch when the working dataset is long / repeated.
- If scaling improves interpretability, `time * frailty_index_fi_z` may replace
  `time * frailty_index_fi` in an otherwise identical primary long model.
- If the intended balance-adjusted long model is used, keep `time * FOF_status`
  unchanged and add FI plus `tasapainovaikeus` in the same model rather than
  substituting one for the other.
- A parallel mixed model using `z3` may be used as a deterministic fallback / sensitivity check.

### 5.4 Secondary / Sensitivity Analyses

Examples of acceptable secondary analyses:

```r
# Fallback frailty proxy
locomotor_capacity ~ time * FOF_status + time * frailty_cat_3 + age + sex + BMI + (1 | id)
```

```r
# Fallback frailty proxy score
locomotor_capacity ~ time * FOF_status + time * frailty_score_3 + age + sex + BMI + (1 | id)
```

- Report these as secondary or sensitivity analyses, not as replacements for the current primary FI-based line.
- If balance is modeled separately, use canonical naming and explain whether it is a covariate, predictor, or sensitivity term.

### 5.4.1 Frailty Index (FI_22) QC and Validity

Before any FI-adjusted primary model is interpreted, confirm that the active
frailty field follows the K40 `FI22_nonperformance_KAAOS` contract:

- `fi_eligible == TRUE` for rows entering the primary FI-based model.
- `coverage >= coverage_min` where the locked K40 threshold is `0.60`.
- `n_deficits_observed >= N_deficits_min` where the locked K40 minimum is `10`.
- The FI source excludes direct physical performance tests and related
  locomotor measures via the K40 non-performance exclusion pattern
  (`perf_regex`), preserving circularity safety relative to locomotor outcomes.
- QC outputs must retain the five patient-level K40 fields:
  `frailty_index_fi`, `frailty_index_fi_z`, `n_deficits_observed`, `coverage`,
  and `fi_eligible`.

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
- **Gate 5 (Frailty index verification):** If frailty is used in a primary model, confirm the locked K40 variant is `FI22_nonperformance_KAAOS`, the active patient-level fields are `frailty_index_fi` / `frailty_index_fi_z`, and `fi_eligible == TRUE`.
- **Gate 5b (FI QC thresholds):** Confirm `coverage >= 0.60`, `n_deficits_observed >= 10`, and preserve the K40 non-performance circularity exclusion (`perf_regex`) for the FI source.
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
   # Declare branch explicitly: analysis_shape=wide|long or --shape WIDE|LONG
   # Primary analysis output and manifest rows must include both branch
   # (wide/long) and outcome (locomotor_capacity/z3/Composite_Z).
   ```

   **Entrypoint Freeze Gap:** Primary model entrypoint scripts are not yet frozen in this document. The K50 contract currently freezes the branch-selection rule and model formulas; concrete script paths must match the eventual verified implementation entrypoints.

4. **Sensitivity / Bridge Analyses:**

   ```bash
   # z3 fallback / sensitivity
   # FI22 sensitivity index analysis
   # Composite_Z legacy bridge analysis only if original definition is verified
   ```

   **Entrypoint Freeze Gap:** Sensitivity and bridge entrypoint scripts are also not frozen here. Use only verified implementation-layer paths once they are locked, and include branch plus outcome labels in output filenames and manifest entries.

### Downstream Outputs Reference

Results generated under this analysis plan are written to the standard project output structure:

`R-scripts/Kxx/outputs/<script_label>/`

Each artifact must be registered in:

`manifest/manifest.csv`

The outcome variable used in each analysis must appear in the output filename and manifest entry.

## 8. What Cannot Change (Non-Negotiables)

1. **Raw data:** Never manually edit CSV/Excel files.
2. **Canonical variable names:** Use the map above and keep baseline/follow-up logic explicit.
3. **Primary outcome / frailty line:** Do not present `frailty_cat_3` or `Composite_Z` as the undisputed current primary core; frailty is operationalized primarily via `frailty_index_fi` / `frailty_index_fi_z`.
4. **Reproducibility:** `set.seed(20251124)` only for bootstrapping/MI.
5. **Outputs:** All artifacts go to `R-scripts/Kxx/outputs/` and are logged in `manifest/manifest.csv`.

---

_Reference: See `data/data_dictionary.csv`, `data/Muuttujasanakirja.md`, CFA 3-item locomotor capacity documentation, and FI22 methods appendix for full definitions._
