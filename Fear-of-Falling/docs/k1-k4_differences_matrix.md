# K1-K4 Differences Matrix

**Date:** 2025-12-24
**Purpose:** Compare K1-K4 implementations to identify refactoring patterns

## Implementation Comparison

| Feature | K1 | K2 | K3 | K4 |
|---------|----|----|----|----|
| **Structure** | Modular (7 scripts) + 1 monolithic | 2 standalone scripts | Modular (5 scripts) | 1 standalone script |
| **Entry Point** | K1.7.main.R | Direct execution | K3.7.main.R | Direct execution |
| **Purpose** | Z-score change analysis | Z-score data transformation | Original values analysis | Score data transformation |
| **Input Data** | Raw CSV (dataset/KaatumisenPelko.csv) | K1 output CSV | Raw CSV (reuses K1.1) | K3 output CSV |
| **Output Location** | `tables/` (legacy) | `tables/` (legacy) | `tables/` (legacy) | `tables/` (legacy) |
| **Path Management** | `here::here()` + `setwd()` | Hardcoded `C:/Users/...` | Hardcoded `C:/Users/...` | Hardcoded `C:/Users/...` |
| **Standard Header** | ❌ No | ❌ No | ❌ No | ❌ No |
| **init_paths()** | ❌ No | ❌ No | ❌ No | ❌ No |
| **req_cols check** | ❌ No | ❌ No | ❌ No | ❌ No |
| **Manifest logging** | ❌ No | ❌ No | ❌ No | ❌ No |
| **set.seed()** | ❌ No (but uses boot) | N/A (no randomness) | ❌ No (but uses boot) | N/A (no randomness) |
| **Uses R/functions/** | ❌ No | ❌ No | ❌ No | ❌ No |
| **Shared Scripts** | K1.1, K1.5 (sourced by K3) | None | Reuses K1.1, K1.5 | None |
| **Bootstrap CI** | ✅ Yes (K1.4) | ❌ No | ✅ Yes (K3.4) | ❌ No |
| **Libraries** | tidyverse, boot, moments, broom, haven | dplyr, tidyr, readr, tibble | tidyverse, boot, moments, broom | dplyr, tidyr, readr, tibble |

---

## Refactoring Priority Matrix

| Priority | Script | Complexity | Impact | Dependencies | Effort |
|----------|--------|------------|--------|--------------|--------|
| **1** | K1.7.main.R | Medium | High | None (K1 is foundation) | Medium |
| **2** | K1.1-K1.6 | Low-Medium | High | Used by K1.7 and K3.7 | Low-Medium |
| **3** | K3.7.main.R | Medium | Medium | Depends on K1.1, K1.5 | Medium |
| **4** | K3.2-K3.6 | Low-Medium | Medium | Used by K3.7 | Low-Medium |
| **5** | K2.Z_Score_C_Pivot_2G.R | Low | Low | Depends on K1 output | Low |
| **6** | K2.KAAOS-Z_Score_C_Pivot_2R.R | Low | Low | Independent | Low |
| **7** | K4.A_Score_C_Pivot_2G.R | Low | Low | Depends on K3 output | Low |
| **8** | K1.Z_Score_Change_2G_v4.R | High | Low | Duplicate of K1.7 pipeline | Consider deprecating |

---

## Code Patterns Identified

### 1. Data Import Pattern (K1.1, K3)
```r
# Current (hardcoded)
file_path <- here::here("dataset", "KaatumisenPelko.csv")
data <- readr::read_csv(file_path)
data$kaatumisenpelkoOn <- as.factor(data$kaatumisenpelkoOn)
data$sex <- as.factor(data$sex)

# Refactored (using helpers)
source(here::here("R", "functions", "io.R"))
raw_data <- readr::read_csv(here::here("data", "raw", "KaatumisenPelko.csv"))
data <- standardize_analysis_vars(raw_data)
sanity_checks(data)
```

### 2. Results Export Pattern (K1.6, K3.6)
```r
# Current (no manifest)
table_path <- "C:/Users/.../tables/K1_Z_Score_Change_2G.csv"
write.csv(final_table, table_path, row.names = FALSE)

# Refactored (with manifest)
source(here::here("R", "functions", "reporting.R"))
init_paths("K1")
save_table_csv_html(final_table, "K1_Z_Score_Change_2G",
                    n = nrow(final_table))
save_sessioninfo_manifest()
```

### 3. Bootstrap CI Pattern (K1.4, K3.4)
```r
# Current (no seed)
boot_result <- boot(data, boot_fn, R = 1000)

# Refactored (with seed)
set.seed(20251124)  # Documented in header
boot_result <- boot(data, boot_fn, R = 1000)
```

### 4. Pipeline Orchestration Pattern (K1.7, K3.7)
```r
# Current (setwd + relative source)
k1_dir <- here::here("R-scripts", "K1")
setwd(k1_dir)
source("K1.1.data_import.R")
source("K1.2.data_transformation.R")
# ...

# Refactored (absolute paths, no setwd)
source(here::here("R-scripts", "K1", "K1.1.data_import.R"))
source(here::here("R-scripts", "K1", "K1.2.data_transformation.R"))
# ...
```

### 5. Pivot/Transpose Pattern (K2, K4)
```r
# Current (hardcoded paths)
file_path <- "C:/Users/tomik/OneDrive/.../tables/K1_Z_Score_Change_2G.csv"
output_path <- "C:/Users/tomik/OneDrive/.../tables/K2_Z_Score_Change_2G_Transposed.csv"

# Refactored (dynamic paths)
init_paths("K2")
input_path <- here::here("R-scripts", "K1", "outputs", "K1_Z_Score_Change_2G.csv")
save_table_csv_html(df_transposed, "K2_Z_Score_Change_2G_Transposed",
                    n = nrow(df_transposed))
```

---

## Repetition Analysis (DRY Violations)

| Repeated Code | Location | Solution |
|---------------|----------|----------|
| Library loading (tidyverse, boot, etc.) | All K1.*, K3.* scripts | ✅ Already centralized in K1.7/K3.7 main scripts |
| Data import (KaatumisenPelko.csv) | K1.1, K3 (reuses K1.1) | ✅ Already shared via K1.1 |
| Kurtosis/skewness functions | K1.5, K3 (reuses K1.5) | ✅ Already shared via K1.5 |
| FOF recoding logic | K2, K4 (test name transformations) | Consider creating `recode_fof_tests()` helper |
| Transpose logic | K2, K4 | Consider creating `pivot_by_fof()` helper |
| write.csv + message pattern | K1.6, K3.6 | ✅ Use `save_table_csv_html()` from reporting.R |

---

## Standard Header Template Mapping

### K1.7.main.R Example Header

```r
#!/usr/bin/env Rscript
# ==============================================================================
# K1_MAIN - Longitudinal Analysis Pipeline: Z-Score Change by FOF Status
# File tag: K1_MAIN.V1_zscore-change.R
# Purpose: Complete analysis pipeline for z-score changes in physical performance tests
#
# Outcome: Delta_Composite_Z (12-month change in composite z-score)
# Predictors: FOF_status (0/1)
# Moderator/interaction: None (main effects only)
# Grouping variable: FOF_status_f (Ei FOF, FOF)
# Covariates: Age, Sex, BMI, Composite_Z0 (baseline)
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, ToimintaKykySummary0, ToimintaKykySummary2, kaatumisenpelkoOn, age, sex, BMI
#
# Mapping example (raw -> analysis):
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z2
# kaatumisenpelkoOn (0/1) -> FOF_status (numeric), FOF_status_f (factor)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (set in K1.4.effect_sizes.R for bootstrap CI)
#
# Outputs + manifest:
# - script_label: K1 (canonical)
# - outputs dir: R-scripts/K1/outputs/  (resolved via init_paths("K1"))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits) [K1.1]
# 03) Standardize vars + QC (sanity checks early) [K1.2]
# 04) Derive/rename vars (document mapping) [K1.2]
# 05) Prepare analysis dataset (complete-case) [K1.2]
# 06) Fit primary model (statistical tests) [K1.3]
# 07) Effect size calculations (bootstrap CI) [K1.4]
# 08) Distributional checks (skewness/kurtosis) [K1.5]
# 09) Combine results and export table [K1.6]
# 10) Save artifacts -> R-scripts/K1/outputs/
# 11) Append manifest row per artifact [K1.6]
# 12) Save sessionInfo to manifest/ [K1.6]
# 13) EOF marker
# ==============================================================================
```

---

## Shared Dependencies Resolution

### K1.1.data_import.R (shared by K3)

**Current situation:**
- K3.7.main.R sources `"K1.1.data_import.R"` with hardcoded relative path
- K3.7.main.R uses `setwd("C:/Users/tomik/...")`

**Refactored solution:**
1. Move K1.1.data_import.R logic to R/functions/io.R as `load_raw_data()`
2. Both K1 and K3 pipelines call `load_raw_data()` helper
3. OR: Keep K1.1 and source it with absolute path: `source(here::here("R-scripts", "K1", "K1.1.data_import.R"))`

**Recommendation:** Option 2 (absolute path sourcing) is simpler for now.

### K1.5.kurtosis_skewness.R (shared by K3)

**Current situation:**
- K3.7.main.R sources `"K1.5.kurtosis_skewness.R"` with hardcoded relative path

**Refactored solution:**
- Source with absolute path: `source(here::here("R-scripts", "K1", "K1.5.kurtosis_skewness.R"))`
- OR: Extract functions to R/functions/stats.R

**Recommendation:** Option 1 (absolute path sourcing) for consistency.

---

## Refactoring Checklist Per Script

### Template Checklist (apply to all K1-K4 scripts)

- [ ] Add CLAUDE.md standard header (with all sections)
- [ ] Define `script_label` from `--file` argument or fallback
- [ ] Call `init_paths(script_label)` to set outputs_dir, manifest_path
- [ ] Define `req_cols` vector matching Required Vars list 1:1
- [ ] Verify all `req_cols` exist in data (early in script)
- [ ] Replace hardcoded paths with `here::here()` or init_paths() results
- [ ] Replace `write.csv()` / `write_csv()` with `save_table_csv_html()`
- [ ] Add `append_manifest()` call for each saved artifact
- [ ] Add `set.seed(20251124)` if randomness exists (document in header)
- [ ] Remove `setwd()` calls (use absolute paths instead)
- [ ] Add `save_sessioninfo_manifest()` at end of script
- [ ] Add EOF marker comment

---

## Next Steps (Refactoring Plan)

Based on this differences matrix, the refactoring plan is:

1. **Foundation** (already exists!)
   - ✅ `R/functions/io.R` has `standardize_analysis_vars()`
   - ✅ `R/functions/checks.R` has `sanity_checks()`
   - ✅ `R/functions/reporting.R` has all needed helpers
   - ⚠️ Minor enhancement: add `load_raw_data()` wrapper in io.R (optional)

2. **K1 Refactor** (foundation for K3)
   - K1.1 → Add standard header, req_cols, use init_paths
   - K1.2 → Use standardize_analysis_vars(), sanity_checks()
   - K1.3 → Add standard header
   - K1.4 → Add set.seed(20251124), standard header
   - K1.5 → Add standard header (shared by K3)
   - K1.6 → Use save_table_csv_html(), save_sessioninfo_manifest()
   - K1.7.main → Add standard header, init_paths, absolute source paths

3. **K3 Refactor** (depends on K1.1, K1.5)
   - K3.2-K3.6 → Similar to K1.2-K1.6
   - K3.7.main → Absolute paths for sourcing K1.1, K1.5

4. **K2 Refactor** (simple transformation scripts)
   - Both scripts → Standard headers, init_paths, dynamic input paths from K1 outputs

5. **K4 Refactor** (simple transformation script)
   - K4.A → Standard header, init_paths, dynamic input path from K3 outputs

6. **Verification**
   - Smoke test each Kx pipeline
   - Verify outputs match (before/after)
   - Check manifest.csv populated correctly

---

**End of Differences Matrix**
