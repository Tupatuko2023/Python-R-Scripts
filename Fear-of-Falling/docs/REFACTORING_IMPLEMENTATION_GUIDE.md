# K1-K4 Refactoring Implementation Guide

**Status:** IN PROGRESS (Phases 0-1 complete, Phase 2 started)
**Date:** 2025-12-24

---

## Completed Work

### ✅ Phase 0: Documentation (DONE)

- [x] Created inventory (docs/k1-k4_inventory.md)
- [x] Created differences matrix (docs/k1-k4_differences_matrix.md)
- [x] Created refactoring plan (docs/k1-k4_refactor_plan.md)

### ✅ Phase 1: Foundation (DONE)

- [x] Verified existing R helpers (checks.R, io.R, modeling.R, reporting.R)
- [x] Enhanced R/functions/io.R with `load_raw_data()` wrapper
- [x] Confirmed `init_paths()`, `append_manifest()`, `save_table_csv_html()` are ready

### ⏳ Phase 2: K1 Refactor (IN PROGRESS)

- [x] Refactored K1.7.main.R (orchestrator)
- [x] Refactored K1.1.data_import.R (data import)
- [ ] Refactor K1.2.data_transformation.R (needs review - see notes below)
- [ ] Refactor K1.3.statistical_analysis.R
- [ ] Refactor K1.4.effect_sizes.R (add set.seed)
- [ ] Refactor K1.5.kurtosis_skewness.R
- [ ] Refactor K1.6.results_export.R (use save_table_csv_html)

---

## Standard Header Template (Apply to All Scripts)

```r
#!/usr/bin/env Rscript
# ==============================================================================
# {{SCRIPT_ID}} - {{TITLE}}
# File tag: {{SCRIPT_ID}}.V1_{{short-name}}.R
# Purpose: {{ONE_LINE_PURPOSE}}
#
# Input: {{INPUT_DESCRIPTION}}
# Output: {{OUTPUT_DESCRIPTION}}
#
# Required vars ({{DO NOT INVENT}}; must match req_cols):
# {{VAR1, VAR2, VAR3, ...}}
#
# {{Optional sections:}}
# Mapping example (raw -> analysis):
# {{raw_var1}} -> {{analysis_var1}} (description)
# {{raw_var2}} -> {{analysis_var2}} (description)
#
# Reproducibility (if randomness used):
# - seed: 20251124 (set before boot::boot() or similar)
# ==============================================================================

suppressPackageStartupMessages({
  library({{REQUIRED_LIBRARIES}})
})

# Required columns check (if loading/verifying data)
req_cols <- c("{{VAR1}}", "{{VAR2}}", ...)

# {{MAIN LOGIC HERE}}

# EOF
```

---

## Refactoring Checklist Per Script

For each K1-K4 script, apply these changes:

### 1. Header Section

- [ ] Add shebang: `#!/usr/bin/env Rscript`
- [ ] Add CLAUDE.md standard header with all sections
- [ ] Document Required vars (match 1:1 with req_cols check)
- [ ] Document mapping if variables are renamed/derived

### 2. Required Columns Check

- [ ] Define `req_cols` vector early in script
- [ ] Verify all req_cols exist in data (if loading/transforming data)
- [ ] Stop with clear error if columns missing

### 3. Path Management

- [ ] Replace hardcoded paths with `here::here()` or init_paths results
- [ ] For main scripts (K\*.7.main.R): Call `init_paths(script_label)` and source helpers
- [ ] For subscripts: Use paths from parent environment (set by main script)
- [ ] Remove all `setwd()` calls

### 4. Manifest Logging (for scripts that save outputs)

- [ ] Source `R/functions/reporting.R`
- [ ] Replace `write.csv()` / `write_csv()` with `save_table_csv_html()`
- [ ] Ensure `init_paths()` was called earlier (by main script)
- [ ] Add `save_sessioninfo_manifest()` at end (only in final export scripts)

### 5. Randomness Handling

- [ ] If script uses `boot()`, `sample()`, or any RNG: Add `set.seed(20251124)`
- [ ] Document seed in header under Reproducibility section

### 6. Use Helpers

- [ ] Use `load_raw_data()` for data loading (K1.1)
- [ ] Use `standardize_analysis_vars()` for variable transformation (K1.2 or equivalent)
- [ ] Use `sanity_checks()` for QC (K1.2 or equivalent)

---

## Script-Specific Notes

### K1.2.data_transformation.R

**Current logic:** Pivots individual performance tests to long/wide format
**Refactoring approach:**

- Review if `standardize_analysis_vars()` helper applies (it creates Composite_Z0/Z2, Delta, FOF_status)
- The current K1.2 logic seems to be working with individual test z-scores (`z_kavelynopeus0`, `z_Tuoli0`, etc.)
- **Decision needed:** Does K1 use composite scores OR individual test scores?
  - If composite: Use `standardize_analysis_vars()` helper
  - If individual: Keep existing logic but add standard header

**Recommended action:**

1. Add standard header to existing K1.2
2. Add req_cols check for the variables it actually uses
3. Keep pivot logic intact (don't break working analysis)

### K1.3.statistical_analysis.R

**Refactoring approach:**

- Add standard header
- Review if it uses helpers from `R/functions/modeling.R` (`fit_primary_ancova()`, etc.)
- If not using helpers, keep existing logic (preserve analysis)

### K1.4.effect_sizes.R

**CRITICAL:** Add `set.seed(20251124)` before bootstrap
**Refactoring approach:**

```r
# ==============================================================================
# K1.4_EFFECT - Effect Size Calculations with Bootstrap CI
# ...
# Reproducibility:
# - seed: 20251124 (set before boot::boot() calls)
# ==============================================================================

suppressPackageStartupMessages({
  library(boot)
  library(dplyr)
})

# REPRODUCIBILITY: Set seed for bootstrap resampling
set.seed(20251124)

# {{Existing bootstrap logic}}
```

### K1.5.kurtosis_skewness.R

**Note:** Shared by K3 (sourced from K3.7.main.R)
**Refactoring approach:**

- Add standard header
- Note in header that it's shared by K1 and K3
- Keep logic intact

### K1.6.results_export.R

**CRITICAL:** Use manifest logging
**Refactoring approach:**

```r
# ==============================================================================
# K1.6_EXPORT - Combine Results and Export
# ...
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(here)
})

# Load reporting helpers (init_paths already called by K1.7)
source(here::here("R", "functions", "reporting.R"))

# {{Existing logic to create final_table}}

# Save with manifest logging (replaces write.csv)
save_table_csv_html(
  final_table,
  label = "K1_Z_Score_Change_2G",
  n = nrow(final_table),
  write_html = FALSE  # Set TRUE if HTML output needed
)

# Save sessionInfo
save_sessioninfo_manifest()

cat("K1 results exported successfully.\n")
# EOF
```

---

## Template for K2, K3, K4

### K2 Scripts (Pivot/Transpose)

**Pattern:**

```r
#!/usr/bin/env Rscript
# ==============================================================================
# K2_PIVOT - {{DESCRIPTION}}
# ...
# ==============================================================================

# Standard init
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_base <- if (length(file_arg) > 0) {
  sub("\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K2_PIVOT"
}
script_label <- sub("\.V.*$", "", script_base)
if (grepl("^K2", script_label)) script_label <- "K2"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)

# Load input from K1 outputs (dynamic path)
input_file <- here::here("R-scripts", "K1", "outputs", "K1_Z_Score_Change_2G.csv")
if (!file.exists(input_file)) stop("K1 output not found: ", input_file)
df <- readr::read_csv(input_file, show_col_types = FALSE)

# {{Existing transformation logic}}

# Save with manifest
save_table_csv_html(df_transposed, "K2_Z_Score_Change_2G_Transposed", n = nrow(df_transposed))
save_sessioninfo_manifest()
```

### K3 Scripts

**Same pattern as K1**, but:

- K3.7.main.R sources K1.1 and K1.5 with absolute paths
- K3.2, K3.3, K3.4, K3.6 follow same structure as K1 equivalents
- K3.4 needs `set.seed(20251124)` if it uses bootstrap

### K4 Script

**Same pattern as K2**, but:

- Reads input from K3 outputs: `R-scripts/K3/outputs/K3_Values_2G.csv`

---

## Testing Strategy

### Smoke Test Commands (from repo root)

```bash
# Ensure renv is synced
Rscript -e "renv::restore(prompt = FALSE)"

# Test K1 pipeline
Rscript R-scripts/K1/K1.7.main.R

# Verify K1 outputs
ls -lh R-scripts/K1/outputs/
tail -20 manifest/manifest.csv | grep K1

# Test K3 pipeline (depends on K1.1, K1.5)
Rscript R-scripts/K3/K3.7.main.R

# Verify K3 outputs
ls -lh R-scripts/K3/outputs/
tail -20 manifest/manifest.csv | grep K3

# Test K2 pipeline (depends on K1 outputs)
Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R

# Verify K2 outputs
ls -lh R-scripts/K2/outputs/
tail -20 manifest/manifest.csv | grep K2

# Test K4 pipeline (depends on K3 outputs)
Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R

# Verify K4 outputs
ls -lh R-scripts/K4/outputs/
tail -20 manifest/manifest.csv | grep K4
```

### Before/After Comparison

If you have baseline outputs, compare:

1. Output file dimensions (rows/columns)
2. Numeric columns (tolerance 1e-6 for float differences)
3. Column names

If no baseline available, document new outputs as canonical.

---

## Remaining Work

### To Complete Phase 2 (K1):

1. Review K1.2 logic and decide approach (see notes above)
2. Add standard header to K1.3
3. Add standard header + set.seed to K1.4
4. Add standard header to K1.5 (note shared by K3)
5. Refactor K1.6 to use save_table_csv_html

### Phase 3 (K3):

1. Create K3.7.main.R similar to K1.7 but source K1.1 and K1.5 with absolute paths
2. Refactor K3.2, K3.3, K3.4, K3.6 similar to K1 equivalents

### Phase 4 (K2):

1. Refactor both K2 scripts with dynamic input paths from K1 outputs

### Phase 5 (K4):

1. Refactor K4 script with dynamic input path from K3 outputs

### Phase 6 (Documentation):

1. Create PR_SUMMARY.md
2. Update README with K1-K4 runbook

---

## Quick Reference: CLAUDE.md Rules

1. Do not edit raw data files
2. Do not guess variable meanings
3. Every change must be minimal, reversible, logged
4. Use renv + set.seed(20251124) where randomness exists
5. All outputs → `R-scripts/<K>/outputs/<script_label>/`
6. One manifest row per artifact
7. Every script MUST have standard header
8. Every script MUST define req_cols and check them

---

**End of Implementation Guide**
