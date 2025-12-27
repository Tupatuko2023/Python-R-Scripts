# K1-K4 Refactoring Plan

**Date:** 2025-12-24
**Scope:** Refactor K1-K4 scripts to comply with CLAUDE.md conventions
**Approach:** Minimal, reversible changes; preserve analysis logic and results

---

## Guiding Principles

1. **Do not edit raw data files** - all transformations in code
2. **Do not guess variable meanings** - verify with codebook or data inspection
3. **Every code change must be:**
   - Minimal and reversible
   - Logged (what/why)
   - Testable (before/after comparison)
4. **Reproducibility is mandatory:**
   - Use renv (already in place)
   - Use `set.seed(20251124)` where randomness exists
   - Save sessionInfo to manifest/
5. **Output discipline:**
   - All outputs → `R-scripts/<K>/outputs/<script_label>/`
   - One manifest row per artifact
6. **Every script MUST:**
   - Start with CLAUDE.md standard header
   - Define `script_label` and call `init_paths(script_label)`
   - Define `req_cols` matching Required Vars 1:1
   - Use helpers from `R/functions/`

---

## Implementation Strategy

### Phase 0: Verification (BEFORE refactoring)

**Goal:** Capture baseline state for before/after comparison

**Actions:**

1. Document current outputs:

   ```bash
   # List all current outputs
   find R-scripts/K1 R-scripts/K2 R-scripts/K3 R-scripts/K4 -name "*.csv" -o -name "*.html" > docs/baseline_outputs.txt

   # If K1-K4 can run, capture output samples
   # (Skip if hardcoded paths prevent execution)
   ```

2. Document expected variables:

   ```bash
   # Grep for all read_csv/write_csv to understand current I/O
   grep -n "read_csv\|write_csv\|read\.csv\|write\.csv" R-scripts/K*/**.R > docs/baseline_io.txt
   ```

3. Check if renv is consistent:

   ```bash
   Rscript -e "renv::status()"
   ```

**Deliverables:**

- docs/baseline_outputs.txt
- docs/baseline_io.txt
- Confirmation that renv is in sync

---

### Phase 1: Foundation (R/functions/ enhancements)

**Goal:** Ensure all helper functions are production-ready

**Current State:**

- ✅ `R/functions/io.R` has `standardize_analysis_vars()`
- ✅ `R/functions/checks.R` has `sanity_checks()`
- ✅ `R/functions/modeling.R` has `fit_primary_ancova()`, etc.
- ✅ `R/functions/reporting.R` has `init_paths()`, `append_manifest()`, `save_table_csv_html()`, `save_sessioninfo_manifest()`

**Actions:**

1. **Review and test existing helpers:**
   - Read each helper function
   - Verify they match CLAUDE.md conventions
   - Check that `init_paths()` creates correct directory structure

2. **Optional enhancement to io.R:**

   ```r
   # Add wrapper for consistent data loading
   load_raw_data <- function(file_name = "KaatumisenPelko.csv") {
     file_path <- here::here("data", "raw", file_name)
     if (!file.exists(file_path)) {
       # Fallback to dataset/ (legacy location)
       file_path <- here::here("dataset", file_name)
     }
     if (!file.exists(file_path)) stop("Raw data not found: ", file_name)
     readr::read_csv(file_path, show_col_types = FALSE)
   }
   ```

3. **Test init_paths() manually:**

   ```r
   source(here::here("R", "functions", "reporting.R"))
   paths <- init_paths("TEST")
   print(paths$outputs_dir)  # Should be: R-scripts/TEST/outputs
   print(paths$manifest_path) # Should be: manifest/manifest.csv
   ```

**Deliverables:**

- Optional: Enhanced `R/functions/io.R` with `load_raw_data()`
- Verified that all helpers work as expected

**Decision Point:** ✅ Helpers are ready → Proceed to Phase 2

---

### Phase 2: K1 Refactor (Foundation for K3)

**Goal:** Refactor K1 pipeline to use CLAUDE.md conventions

**Priority:** HIGH (K1 is foundation; K3 depends on K1.1 and K1.5)

#### 2.1: K1.1.data_import.R

**Changes:**

- Add CLAUDE.md standard header
- Define `req_cols` for raw data: `c("id", "ToimintaKykySummary0", "ToimintaKykySummary2", "kaatumisenpelkoOn", "age", "sex", "BMI")`
- Replace `here::here("dataset", "KaatumisenPelko.csv")` with portable path (use `load_raw_data()` or here::here("data", "raw", ...))
- Remove factor conversion (defer to `standardize_analysis_vars()`)
- Add column existence check

**Diff preview:**

```r
#!/usr/bin/env Rscript
# ==============================================================================
# K1.1_IMPORT - Data Import and Preliminary Processing
# File tag: K1.1_IMPORT.V1_data-import.R
# Purpose: Import raw KaatumisenPelko dataset and verify structure
# ...
# Required vars (raw data, DO NOT INVENT):
# id, ToimintaKykySummary0, ToimintaKykySummary2, kaatumisenpelkoOn, age, sex, BMI
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(here)
})

# Required columns check
req_cols <- c("id", "ToimintaKykySummary0", "ToimintaKykySummary2",
              "kaatumisenpelkoOn", "age", "sex", "BMI")

# Load raw data
file_path <- here::here("data", "raw", "KaatumisenPelko.csv")
if (!file.exists(file_path)) {
  file_path <- here::here("dataset", "KaatumisenPelko.csv")  # fallback
}
if (!file.exists(file_path)) stop("Raw data not found")

data <- readr::read_csv(file_path, show_col_types = FALSE)

# Verify required columns
missing_cols <- setdiff(req_cols, names(data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

cat("Data import successful:", nrow(data), "rows,", ncol(data), "columns\n")
```

**Verification:**

- Source the script and check that `data` object is created
- Verify `req_cols` check works

#### 2.2: K1.2.data_transformation.R

**Changes:**

- Add CLAUDE.md standard header
- Source `R/functions/io.R` and `R/functions/checks.R`
- Use `standardize_analysis_vars()` helper
- Use `sanity_checks()` helper
- Document variable mapping in header

**Diff preview:**

```r
#!/usr/bin/env Rscript
# ==============================================================================
# K1.2_TRANSFORM - Data Transformation for Analysis
# ...
# Mapping (raw -> analysis):
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z2
# Delta_Composite_Z = Composite_Z2 - Composite_Z0
# kaatumisenpelkoOn -> FOF_status (0/1), FOF_status_f (factor)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(here)
})

# Load helpers
source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))

# Transform using standardized helper
data <- standardize_analysis_vars(data)

# QC checks
qc_result <- sanity_checks(data)
print(qc_result)
```

#### 2.3: K1.3.statistical_analysis.R

**Changes:**

- Add CLAUDE.md standard header
- Minimal logic changes (just header + documentation)

#### 2.4: K1.4.effect_sizes.R

**Changes:**

- Add CLAUDE.md standard header
- **Add `set.seed(20251124)` before bootstrap** (CRITICAL for reproducibility)
- Document seed in header

**Diff preview:**

```r
# ==============================================================================
# K1.4_EFFECT - Effect Size Calculations with Bootstrap CI
# ...
# Reproducibility:
# - seed: 20251124 (set before boot::boot() calls)
# ==============================================================================

# REPRODUCIBILITY: Set seed for bootstrap resampling
set.seed(20251124)

# Bootstrap CI calculations
boot_result <- boot::boot(data, statistic = boot_fn, R = 1000)
```

#### 2.5: K1.5.kurtosis_skewness.R

**Changes:**

- Add CLAUDE.md standard header
- (This file is shared by K3, so changes affect both pipelines)

#### 2.6: K1.6.results_export.R

**Changes:**

- Add CLAUDE.md standard header
- **Source reporting.R and use helpers**
- Replace `write.csv()` with `save_table_csv_html()`
- Add `append_manifest()` for each saved file
- Add `save_sessioninfo_manifest()` at end

**Diff preview:**

```r
# ==============================================================================
# K1.6_EXPORT - Combine Results and Export
# ...
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
})

# Load reporting helpers (already initialized by K1.7)
source(here::here("R", "functions", "reporting.R"))

# Combine results into final_table
final_table <- ... # existing logic

# Save with manifest logging
save_table_csv_html(
  final_table,
  label = "K1_Z_Score_Change_2G",
  n = nrow(final_table),
  write_html = FALSE  # Optional: set TRUE if HTML needed
)

# Save sessionInfo
save_sessioninfo_manifest()

cat("Results exported successfully.\n")
```

#### 2.7: K1.7.main.R (Orchestrator)

**Changes:**

- Add CLAUDE.md standard header
- Define `script_label` from `--file` or fallback "K1"
- **Call `init_paths("K1")` before sourcing subscripts**
- Replace `setwd()` with absolute `source()` paths
- Source subscripts with `here::here("R-scripts", "K1", ...)`

**Diff preview:**

```r
#!/usr/bin/env Rscript
# ==============================================================================
# K1_MAIN - Longitudinal Analysis Pipeline: Z-Score Change by FOF Status
# File tag: K1_MAIN.V1_zscore-change.R
# Purpose: Complete analysis pipeline for z-score changes in physical performance tests
# ...
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K1_MAIN"  # interactive fallback
}

script_label <- sub("\.V.*$", "", script_base)  # canonical SCRIPT_ID
if (is.na(script_label) || script_label == "") script_label <- "K1"

# Initialize paths and options
source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("K1 Pipeline - Outputs:", outputs_dir, "\n")

# --- Pipeline Steps (absolute paths, no setwd) ------------------------------

source(here::here("R-scripts", "K1", "K1.1.data_import.R"))
source(here::here("R-scripts", "K1", "K1.2.data_transformation.R"))
source(here::here("R-scripts", "K1", "K1.3.statistical_analysis.R"))
source(here::here("R-scripts", "K1", "K1.4.effect_sizes.R"))
source(here::here("R-scripts", "K1", "K1.5.kurtosis_skewness.R"))
source(here::here("R-scripts", "K1", "K1.6.results_export.R"))

cat("K1 pipeline completed successfully.\n")
# EOF
```

**Verification:**

1. Run from repo root: `Rscript R-scripts/K1/K1.7.main.R`
2. Check that outputs appear in `R-scripts/K1/outputs/`
3. Check that manifest/manifest.csv has new rows
4. Compare output CSVs to baseline (if available)

#### 2.8: K1.Z_Score_Change_2G_v4.R (Monolithic - Optional)

**Decision:**

- **Option A:** Refactor similarly to K1.7 (full standard header, init_paths, etc.)
- **Option B:** Add deprecation notice and recommend using K1.7.main.R instead
- **Option C:** Leave as-is (legacy backup)

**Recommendation:** Option B (add deprecation notice) to avoid duplication

**Deliverables (Phase 2):**

- ✅ All K1 scripts have standard headers
- ✅ K1 uses init_paths() and manifest logging
- ✅ K1.4 has set.seed(20251124)
- ✅ K1 outputs to R-scripts/K1/outputs/
- ✅ Smoke test passes
- ✅ Before/after comparison documented

---

### Phase 3: K3 Refactor (Shares K1.1 and K1.5)

**Goal:** Refactor K3 pipeline similar to K1

**Dependencies:** K1.1 and K1.5 must be refactored first (done in Phase 2)

#### 3.1: Shared Script Sourcing

**K3.7.main.R must source K1 scripts with absolute paths:**

```r
# K3.7.main.R (excerpt)
# Shared from K1:
source(here::here("R-scripts", "K1", "K1.1.data_import.R"))
source(here::here("R-scripts", "K1", "K1.5.kurtosis_skewness.R"))

# K3-specific:
source(here::here("R-scripts", "K3", "K3.2.data_transformation.R"))
source(here::here("R-scripts", "K3", "K3.3.statistical_analysis.R"))
source(here::here("R-scripts", "K3", "K3.4.effect_sizes.R"))
source(here::here("R-scripts", "K3", "K3.6.results_export.R"))
```

#### 3.2: Script-by-Script Refactoring

Apply same pattern as K1:

- K3.2 → Similar to K1.2 (header, helpers)
- K3.3 → Similar to K1.3 (header)
- K3.4 → Similar to K1.4 (header, **set.seed(20251124)**)
- K3.6 → Similar to K1.6 (header, save_table_csv_html, manifest)
- K3.7.main → Similar to K1.7.main (init_paths("K3"), absolute source paths)

**Deliverables (Phase 3):**

- ✅ All K3 scripts have standard headers
- ✅ K3 uses init_paths("K3") and manifest logging
- ✅ K3.4 has set.seed(20251124)
- ✅ K3 outputs to R-scripts/K3/outputs/
- ✅ Smoke test passes

---

### Phase 4: K2 Refactor (Simple Transformation Scripts)

**Goal:** Refactor K2 pivot/transpose scripts

**Priority:** MEDIUM (K2 depends on K1 outputs but is simpler)

#### 4.1: K2.Z_Score_C_Pivot_2G.R

**Changes:**

- Add CLAUDE.md standard header
- Define `script_label = "K2"` and call `init_paths("K2")`
- **Replace hardcoded input path** with dynamic path from K1 outputs:

  ```r
  # Old:
  file_path <- "C:/Users/tomik/.../tables/K1_Z_Score_Change_2G.csv"

  # New:
  file_path <- here::here("R-scripts", "K1", "outputs", "K1_Z_Score_Change_2G.csv")
  ```

- Replace `write_csv()` with `save_table_csv_html()`
- Add manifest logging

**Diff preview:**

```r
#!/usr/bin/env Rscript
# ==============================================================================
# K2_PIVOT - Transpose Z-Score Change Data by FOF Status
# File tag: K2_PIVOT.V1_zscore-pivot.R
# Purpose: Recode and transpose z-score change results from K1 for presentation
# ...
# Required vars (from K1 output):
# Test, kaatumisenpelkoOn, [statistical metrics]
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(tibble)
  library(here)
})

# --- Standard init ---
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_base <- if (length(file_arg) > 0) {
  sub("\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K2_PIVOT"
}
script_label <- sub("\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K2"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)

# --- Load K1 output ---
file_path <- here::here("R-scripts", "K1", "outputs", "K1_Z_Score_Change_2G.csv")
if (!file.exists(file_path)) stop("K1 output not found: ", file_path)
df <- read_csv(file_path, show_col_types = FALSE)

# Required columns check
req_cols <- c("Test", "kaatumisenpelkoOn")  # Add other expected columns
missing <- setdiff(req_cols, names(df))
if (length(missing) > 0) stop("Missing columns in K1 output: ", paste(missing, collapse = ", "))

# --- Transformation logic (unchanged) ---
df <- df %>%
  mutate(Test = case_when(
    Test == "Kävelynopeus" & kaatumisenpelkoOn == 0 ~ "MWS_Without_FOF",
    Test == "Kävelynopeus" & kaatumisenpelkoOn == 1 ~ "MWS_With_FOF",
    # ... (rest of existing logic)
    TRUE ~ Test
  )) %>%
  rename(Performance_Test = Test) %>%
  select(-kaatumisenpelkoOn) %>%
  mutate(Performance_Test = make.unique(as.character(Performance_Test)))

df_transposed <- df %>%
  column_to_rownames(var = "Performance_Test") %>%
  t() %>%
  as.data.frame() %>%
  rownames_to_column(var = "Parameter")

# Rename columns (existing logic)
df_transposed <- df_transposed %>%
  rename(
    FTSST_Without_FOF = "FTSST",
    HGS_Without_FOF   = "HGS",
    MWS_Without_FOF   = "MWS",
    SLS_Without_FOF   = "SLS",
    FTSST_With_FOF    = "FTSST.1",
    HGS_With_FOF      = "HGS.1",
    MWS_With_FOF      = "MWS.1",
    SLS_With_FOF      = "SLS.1"
  )

# --- Save with manifest ---
save_table_csv_html(
  df_transposed,
  label = "K2_Z_Score_Change_2G_Transposed",
  n = nrow(df_transposed),
  write_html = FALSE
)

save_sessioninfo_manifest()
cat("K2 pivot completed successfully.\n")
# EOF
```

#### 4.2: K2.KAAOS-Z_Score_C_Pivot_2R.R

**Changes:** Similar pattern as K2.Z_Score_C_Pivot_2G.R

**Deliverables (Phase 4):**

- ✅ Both K2 scripts have standard headers
- ✅ K2 uses dynamic input paths (from K1 outputs)
- ✅ K2 uses init_paths("K2") and manifest logging
- ✅ K2 outputs to R-scripts/K2/outputs/

---

### Phase 5: K4 Refactor (Simple Transformation Script)

**Goal:** Refactor K4 pivot/transpose script

**Priority:** LOW (K4 depends on K3 outputs)

#### 5.1: K4.A_Score_C_Pivot_2G.R

**Changes:**

- Add CLAUDE.md standard header
- Define `script_label = "K4"` and call `init_paths("K4")`
- Replace hardcoded input path with dynamic path from K3 outputs:

  ```r
  file_path <- here::here("R-scripts", "K3", "outputs", "K3_Values_2G.csv")
  ```

- Replace `write_csv()` with `save_table_csv_html()`
- Add manifest logging

**Pattern:** Same as K2 (see Phase 4.1)

**Deliverables (Phase 5):**

- ✅ K4 script has standard header
- ✅ K4 uses dynamic input path (from K3 outputs)
- ✅ K4 uses init_paths("K4") and manifest logging
- ✅ K4 outputs to R-scripts/K4/outputs/

---

### Phase 6: Verification & Documentation

**Goal:** Verify all refactoring is correct and document changes

#### 6.1: Smoke Tests

Run all pipelines from repo root:

```bash
# Test K1
Rscript R-scripts/K1/K1.7.main.R

# Test K3 (depends on K1.1, K1.5)
Rscript R-scripts/K3/K3.7.main.R

# Test K2 (depends on K1 outputs)
Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R

# Test K4 (depends on K3 outputs)
Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R
```

#### 6.2: Before/After Comparison

For each Kx pipeline:

1. Compare output file dimensions:

   ```bash
   wc -l R-scripts/K1/outputs/*.csv
   # vs baseline (if available)
   ```

2. Compare key summary statistics:

   ```r
   # Read baseline and new output
   baseline <- read_csv("baseline/K1_Z_Score_Change_2G.csv")
   new_output <- read_csv("R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv")

   # Check dimensions
   all.equal(dim(baseline), dim(new_output))

   # Check numeric columns (tolerance for small float differences)
   numeric_cols <- names(baseline)[sapply(baseline, is.numeric)]
   for (col in numeric_cols) {
     diff <- max(abs(baseline[[col]] - new_output[[col]]), na.rm = TRUE)
     if (diff > 1e-6) cat("WARNING:", col, "differs by", diff, "\n")
   }
   ```

3. Verify manifest.csv:

   ```bash
   # Check that manifest has new rows for K1-K4
   tail -20 manifest/manifest.csv

   # Count rows per script
   grep -c '"K1"' manifest/manifest.csv
   grep -c '"K2"' manifest/manifest.csv
   grep -c '"K3"' manifest/manifest.csv
   grep -c '"K4"' manifest/manifest.csv
   ```

#### 6.3: Update README

Add K1-K4 runbook section to README.md:

```markdown
## Running K1-K4 Analysis Pipelines

### Prerequisites
- R environment with renv
- Run `renv::restore()` to install dependencies

### K1: Z-Score Change Analysis
```bash
Rscript R-scripts/K1/K1.7.main.R
```

Outputs: `R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv`

### K3: Original Values Analysis

```bash
Rscript R-scripts/K3/K3.7.main.R
```

Outputs: `R-scripts/K3/outputs/K3_Values_2G.csv`

### K2: Z-Score Pivot

```bash
Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R
```

Requires: K1 outputs
Outputs: `R-scripts/K2/outputs/K2_Z_Score_Change_2G_Transposed.csv`

### K4: Score Pivot

```bash
Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R
```

Requires: K3 outputs
Outputs: `R-scripts/K4/outputs/K4_Score_Change_2G_Transposed.csv`

### Migration Notes

- Old outputs were in `tables/` (legacy)
- New outputs are in `R-scripts/<K>/outputs/` (CLAUDE.md standard)
- All outputs logged to `manifest/manifest.csv`

```

#### 6.4: Create PR Summary

Create `PR_SUMMARY.md` with:
- What changed (refactoring scope)
- Why (CLAUDE.md compliance)
- How to run (commands above)
- What was tested (smoke tests, before/after)
- Risks (minimal; logic preserved)
- Next steps (K5-K16, deprecate monolithic scripts)

**Deliverables (Phase 6):**
- ✅ All smoke tests pass
- ✅ Before/after comparison documented (or N/A if baseline not available)
- ✅ README updated with K1-K4 runbook
- ✅ PR_SUMMARY.md created

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Output paths change breaks downstream scripts | Medium | Medium | Update all hardcoded paths to use here::here() |
| set.seed() changes bootstrap results | Low | Low | Document and accept minor float differences |
| Manifest gets too large | Low | Low | Archive old manifest rows if needed |
| Shared scripts (K1.1, K1.5) break K3 | Medium | High | Test K3 immediately after K1 refactor |
| Hardcoded paths prevent initial run | High | Low | Document that initial smoke test may fail; fix paths first |

---

## Rollback Plan

If refactoring causes issues:
1. Git revert to last working commit
2. Review diffs carefully
3. Fix specific issue (don't revert all changes)
4. Retest

---

## Success Criteria

- ✅ All K1-K4 scripts have CLAUDE.md standard headers
- ✅ All scripts use `init_paths(script_label)`
- ✅ All outputs go to `R-scripts/<K>/outputs/`
- ✅ All artifacts logged to `manifest/manifest.csv` (1 row per file)
- ✅ `set.seed(20251124)` set where randomness exists (K1.4, K3.4)
- ✅ `req_cols` defined and checked in all data-loading scripts
- ✅ No hardcoded Windows paths (`C:/Users/...`)
- ✅ Smoke tests pass for all K1-K4 pipelines
- ✅ Before/after comparison shows no unexpected differences
- ✅ README has runbook for K1-K4
- ✅ PR_SUMMARY.md documents all changes

---

**End of Refactoring Plan**
