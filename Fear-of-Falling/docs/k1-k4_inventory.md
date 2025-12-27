# K1-K4 Scripts Inventory

**Date:** 2025-12-24
**Purpose:** Document existing K1-K4 scripts before refactoring to CLAUDE.md standards

## K1: Longitudinal Analysis Pipeline (Z-Score Change)

### K1 Scripts

| Script | Role | Input | Output | Dependencies | Run Command |
|--------|------|-------|--------|--------------|-------------|
| K1.1.data_import.R | Data import & preprocessing | dataset/KaatumisenPelko.csv | `data` object in memory | readr, dplyr, haven, here | Sourced by K1.7.main.R |
| K1.2.data_transformation.R | Data transformation | `data` from K1.1 | Transformed `data` | dplyr, tidyr | Sourced by K1.7.main.R |
| K1.3.statistical_analysis.R | Statistical tests | Transformed data | Statistical results | broom, dplyr | Sourced by K1.7.main.R |
| K1.4.effect_sizes.R | Effect size calculations | Statistical results | Effect sizes | boot, dplyr | Sourced by K1.7.main.R |
| K1.5.kurtosis_skewness.R | Distributional stats | Data | Skewness/kurtosis metrics | moments | Sourced by K1.7.main.R |
| K1.6.results_export.R | Export final table | All results | tables/K1_Z_Score_Change_2G.csv | - | Sourced by K1.7.main.R |
| **K1.7.main.R** | **Pipeline orchestrator** | - | Complete pipeline execution | All above | `Rscript R-scripts/K1/K1.7.main.R` |
| K1.Z_Score_Change_2G_v4.R | Monolithic version (all-in-one) | dataset/KaatumisenPelko.csv | tables/K1_Z_Score_Change_2G.csv | All libs | `Rscript R-scripts/K1/K1.Z_Score_Change_2G_v4.R` |

### K1 Current Issues

- ❌ Hardcoded paths (setwd, absolute file paths)
- ❌ No CLAUDE.md standard header
- ❌ No req_cols check
- ❌ No manifest logging
- ❌ Outputs to `tables/` instead of `R-scripts/K1/outputs/`
- ❌ No init_paths() usage
- ❌ No seed setting (if randomness exists)

### K1 Dependencies Chain

```
K1.7.main.R
  ├─ K1.1.data_import.R (reads raw CSV)
  ├─ K1.2.data_transformation.R
  ├─ K1.3.statistical_analysis.R
  ├─ K1.4.effect_sizes.R (bootstrap → needs seed)
  ├─ K1.5.kurtosis_skewness.R
  └─ K1.6.results_export.R (writes CSV)
```

---

## K2: Data Transformation (Z-Score Pivot/Transpose)

### K2 Scripts

| Script | Role | Input | Output | Dependencies | Run Command |
|--------|------|-------|--------|--------------|-------------|
| K2.KAAOS-Z_Score_C_Pivot_2R.R | Transpose z-score results | Unknown CSV | tables/K2_..._Transposed.csv | dplyr, tidyr, readr, tibble | `Rscript R-scripts/K2/K2.KAAOS-Z_Score_C_Pivot_2R.R` |
| K2.Z_Score_C_Pivot_2G.R | Transpose z-score change (2 groups) | tables/K1_Z_Score_Change_2G.csv | tables/K2_Z_Score_Change_2G_Transposed.csv | dplyr, tidyr, readr, tibble | `Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R` |

### K2 Current Issues

- ❌ Hardcoded absolute Windows paths (`C:/Users/tomik/OneDrive/...`)
- ❌ No CLAUDE.md standard header
- ❌ No req_cols check
- ❌ No manifest logging
- ❌ Outputs to `tables/` instead of `R-scripts/K2/outputs/`
- ❌ No init_paths() usage

### K2 Dependencies Chain

```
K2.Z_Score_C_Pivot_2G.R
  └─ Depends on K1 output: tables/K1_Z_Score_Change_2G.csv
```

---

## K3: Longitudinal Analysis Pipeline (Original Values)

### K3 Scripts

| Script | Role | Input | Output | Dependencies | Run Command |
|--------|------|-------|--------|--------------|-------------|
| K3.2.data_transformation.R | Data transformation (different from K1) | `data` from K1.1 | Transformed data | dplyr, tidyr | Sourced by K3.7.main.R |
| K3.3.statistical_analysis.R | Statistical tests | Transformed data | Statistical results | broom, dplyr | Sourced by K3.7.main.R |
| K3.4.effect_sizes.R | Effect size calculations | Statistical results | Effect sizes | boot, dplyr | Sourced by K3.7.main.R |
| K3.6.results_export.R | Export final table | All results | tables/K3_Values_2G.csv | - | Sourced by K3.7.main.R |
| **K3.7.main.R** | **Pipeline orchestrator** | - | Complete pipeline execution | K1.1, K1.5, K3.* | `Rscript R-scripts/K3/K3.7.main.R` |

### K3 Current Issues

- ❌ Hardcoded absolute Windows paths (`C:/Users/tomik/OneDrive/...`)
- ❌ No CLAUDE.md standard header
- ❌ No req_cols check
- ❌ No manifest logging
- ❌ Outputs to `tables/` instead of `R-scripts/K3/outputs/`
- ❌ No init_paths() usage
- ❌ Reuses K1.1 and K1.5 (cross-folder dependency)

### K3 Dependencies Chain

```
K3.7.main.R
  ├─ K1.1.data_import.R (SHARED from K1)
  ├─ K3.2.data_transformation.R
  ├─ K3.3.statistical_analysis.R
  ├─ K3.4.effect_sizes.R (bootstrap → needs seed)
  ├─ K1.5.kurtosis_skewness.R (SHARED from K1)
  └─ K3.6.results_export.R (writes CSV)
```

---

## K4: Data Transformation (Score Pivot/Transpose)

### K4 Scripts

| Script | Role | Input | Output | Dependencies | Run Command |
|--------|------|-------|--------|--------------|-------------|
| K4.A_Score_C_Pivot_2G.R | Transpose score change (2 groups) | tables/K3_Values_2G.csv | tables/K4_Score_Change_2G_Transposed.csv | dplyr, tidyr, readr, tibble | `Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R` |

### K4 Current Issues

- ❌ Hardcoded absolute Windows paths (`C:/Users/tomik/OneDrive/...`)
- ❌ No CLAUDE.md standard header
- ❌ No req_cols check
- ❌ No manifest logging
- ❌ Outputs to `tables/` instead of `R-scripts/K4/outputs/`
- ❌ No init_paths() usage

### K4 Dependencies Chain

```
K4.A_Score_C_Pivot_2G.R
  └─ Depends on K3 output: tables/K3_Values_2G.csv
```

---

## Overall Pipeline Flow

```
Raw Data: dataset/KaatumisenPelko.csv
    │
    ├─────────────────────────────────────┐
    │                                     │
    v                                     v
K1 Pipeline (Z-scores)              K3 Pipeline (Original Values)
    │                                     │
    v                                     v
tables/K1_Z_Score_Change_2G.csv    tables/K3_Values_2G.csv
    │                                     │
    v                                     v
K2.Z_Score_C_Pivot_2G.R            K4.A_Score_C_Pivot_2G.R
    │                                     │
    v                                     v
tables/K2_..._Transposed.csv       tables/K4_..._Transposed.csv
```

---

## Existing R Helper Functions

Located in `R/functions/`:

| File | Functions | Current Usage |
|------|-----------|---------------|
| checks.R | `sanity_checks()` | ❌ Not used by K1-K4 |
| io.R | `standardize_analysis_vars()` | ❌ Not used by K1-K4 |
| modeling.R | (to be checked) | ❌ Not used by K1-K4 |
| reporting.R | (to be checked) | ❌ Not used by K1-K4 |

**Note:** K1-K4 scripts implement their own logic inline instead of using these centralized helpers.

---

## Summary of Refactoring Needs

### High Priority (All K1-K4)

1. **Add CLAUDE.md standard headers** to all scripts
2. **Remove hardcoded paths** and implement `init_paths(script_label)`
3. **Redirect outputs** from `tables/` to `R-scripts/<K>/outputs/<script_label>/`
4. **Add manifest logging** (1 row per artifact)
5. **Add req_cols checks** matching Required Vars list 1:1
6. **Add set.seed(20251124)** where randomness exists (K1.4, K3.4 bootstrap)

### Medium Priority

1. **Use existing R/functions/** helpers (`standardize_analysis_vars`, `sanity_checks`)
2. **Create new helpers** (`init_paths`, `append_manifest`, `save_table_csv_html`)
3. **Make paths portable** (remove Windows-specific C:/ paths)

### Low Priority

1. **Document variable mappings** (raw → analysis)
2. **Add sessionInfo/renv diagnostics** to manifest/
3. **Consider consolidating** K1.7/K1.Z monolithic duplication

---

## Refactoring Strategy

### Phase 1: Foundation (R/functions/)

- Create `R/functions/paths.R` with `init_paths(script_label)`
- Create `R/functions/manifest.R` with `append_manifest()`
- Enhance existing helpers

### Phase 2: K1 Refactor

- Refactor K1.7.main.R as primary entry point
- Add standard headers to all K1.*.R scripts
- Update paths, manifest, req_cols
- Deprecate or align K1.Z monolithic version

### Phase 3: K2 Refactor

- Refactor both K2 scripts
- Fix hardcoded paths
- Add standard headers

### Phase 4: K3 Refactor

- Refactor K3.7.main.R and subscripts
- Resolve cross-folder dependencies (K1.1, K1.5)

### Phase 5: K4 Refactor

- Refactor K4 script
- Fix hardcoded paths

### Phase 6: Verification

- Smoke tests for all K1-K4
- Before/after comparisons
- Update README with runbook

---

**End of Inventory**
