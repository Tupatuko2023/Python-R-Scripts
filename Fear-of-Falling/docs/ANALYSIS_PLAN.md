# Fear-of-Falling Analysis Plan (K20)

**Version:** 1.1 (Draft)
**Date:** 2025-12-29
**Status:** Active

This document defines the analysis plan for the Fear-of-Falling (FOF) subproject.
It is anchored to the project rules in `../CLAUDE.md` and the variable definitions
in `../data/data_dictionary.csv` and `../data/Muuttujasanakirja.md`.

## 1. Study Design and Research Question

**Objective:** Determine whether Fear of Falling (FOF) is associated with
12-month change in physical performance (Composite_Z), adjusting for key
covariates.

* **Design:** Longitudinal cohort (baseline -> follow-up)
* **Primary comparison:** FOF vs Ei FOF change over time

## 2. Sources of Truth and Verification

* **Variables and coding:** `../data/data_dictionary.csv`
* **Reference levels and delta rule:** `../data/Muuttujasanakirja.md`
* **QC gates:** `../QC_CHECKLIST.md`
* **Mappings in code:** search with `rg` in `R/` and `R-scripts/`

If a variable, coding, or timepoint is unclear, mark it **TODO** and cite the
source required for verification (data_dictionary, Muuttujasanakirja, or code).

## 3. Variable Map (Canonical Names Only)

All analysis must use these canonical names. Do not invent aliases.

| Canonical name | Source / derivation | Coding / units | Status | Notes |
| --- | --- | --- | --- | --- |
| id | data_dictionary.csv | Unique per participant | TODO | Confirm exact column name in data (data_dictionary). |
| time | data_dictionary.csv | baseline/m12 (preferred) or 0/1 | TODO | Confirm exact labels and reference (data_dictionary). |
| FOF_status | R/functions/io.R | 0=Ei FOF, 1=FOF | Verified | Derived from kaatumisenpelkoOn (0/1). |
| Composite_Z | data_dictionary.csv | Continuous (z-score) | TODO | Confirm construction and long-format source. |
| Composite_Z0 | R/functions/io.R | Continuous (z-score) | Verified | From ToimintaKykySummary0. |
| Composite_Z2 | R/functions/io.R | Continuous (z-score) | Verified | From ToimintaKykySummary2; TODO confirm that "2" is 12 kk. |
| Delta_Composite_Z | R/functions/io.R, R/functions/checks.R | Composite_Z2 - Composite_Z0 | Verified | TODO confirm follow-up timepoint. |
| age | data_dictionary.csv | Years | TODO | Confirm baseline-only vs time-varying. |
| sex | data_dictionary.csv | Unknown coding | TODO | Confirm coding and labels. |
| BMI | data_dictionary.csv | kg/m^2 | TODO | data_dictionary says kg/m^2; confirm in codebook/data. |
| SRH (optional) | data_dictionary.csv | Unknown scale | TODO | Confirm variable name and levels. |

**Non-negotiable:** Raw data under `data/` is read-only; all transformations are
in code.

## 4. Statistical Models

### 4.1 Primary Model (Long Mixed Model)

```r
Composite_Z ~ time * FOF_status + age + sex + BMI + (1 | id)
```

* **Key term:** `time:FOF_status`
* **Time coding:** TODO (use verified levels from data_dictionary)
* **FOF reference:** 0 = Ei FOF (verified in code)

### 4.2 Cross-Check (Wide ANCOVA)

```r
Composite_Z2 ~ FOF_status + Composite_Z0 + age + sex + BMI
```

* **Follow-up column:** Composite_Z2 (TODO confirm that "2" is 12 kk)
* **Baseline column:** Composite_Z0

## 5. QC Gates (Stop-the-line)

All data must pass the gates defined in `../QC_CHECKLIST.md` before modeling.
Required checks include:

* (id, time) uniqueness in long data
* Exactly 2 time levels and 2 FOF_status levels
* Missingness overall and by FOF_status x time
* Delta check if Delta_Composite_Z exists

**Runner:** `R-scripts/K18/K18_QC.V1_qc-run.R`

## 6. Outputs and Audit Trail

* Outputs must be written to: `R-scripts/<script_label>/outputs/`
* Append one row per artifact to `manifest/manifest.csv`
* Save `sessionInfo()` or `renv::diagnostics()` to `manifest/`

## 7. Runbook (Placeholders)

```bash
# 1) Setup
a) Rscript -e "renv::restore()"

# 2) QC
Rscript R-scripts/K18/K18_QC.V1_qc-run.R --data <PATH_TO_ANALYSIS_LONG>

# 3) Primary model (placeholder)
Rscript R-scripts/K20/K20_LMM.V1_primary.R --data <PATH_TO_ANALYSIS_LONG>

# 4) Cross-check (placeholder)
Rscript R-scripts/K20/K20_ANCOVA.V1_check.R --data <PATH_TO_WIDE>
```

## 8. What Cannot Change (Non-Negotiables)

1. **Raw data:** Never edit CSV/Excel files directly.
2. **Variable meanings:** Do not guess; use data_dictionary or codebook.
3. **Reproducibility:** `set.seed(20251124)` only when randomness is used.
4. **Output discipline:** All artifacts under `R-scripts/<script_label>/outputs/`.

---
**References:** `../data/data_dictionary.csv`, `../data/Muuttujasanakirja.md`,
`../QC_CHECKLIST.md`, `../CLAUDE.md`.
