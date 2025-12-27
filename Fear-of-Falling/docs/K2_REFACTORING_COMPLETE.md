# K2 Pipeline Refactoring - COMPLETE

**Date:** 2025-12-24
**Status:** ✅ All K2 scripts refactored and ready for testing

---

## Summary

The K2 pipeline (Z-Score Pivot & Transpose) has been successfully refactored to comply with CLAUDE.md standards. Both scripts now have:

- Standard headers with complete documentation
- Required columns checks (`req_cols`)
- Portable path management (no hardcoded paths)
- Manifest logging (via `save_table_csv_html()`)
- Clear progress messages
- Dependency verification

---

## Refactored Scripts

### 1. K2.Z_Score_C_Pivot_2G.R (Primary Script) ✅

**Size:** 6.6 KB
**Changes:**

- Added full CLAUDE.md standard header
- Implemented `script_label` derivation from `--file` argument
- Added `init_paths("K2")` call for portable paths
- **Replaced hardcoded path** `C:/Users/tomik/OneDrive/...` with `here::here()`
- Added dependency check: requires K1 output (`K1_Z_Score_Change_2G.csv`)
- Added manifest logging via `save_table_csv_html()`
- Added progress messages for each transformation step
- Added EOF marker

**Run command:** `Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R`

**Purpose:**

- Transposes K1 z-score change output from long to wide format
- Recodes test names to include FOF status (e.g., "MWS_Without_FOF", "MWS_With_FOF")
- Creates parameter-by-test transposed table for easier reporting

**Required columns:**

```r
req_cols <- c("kaatumisenpelkoOn", "Test")
```

**Input:** `R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv`
**Output:** `R-scripts/K2/outputs/K2_Z_Score_Change_2G_Transposed.csv`

**Transformation logic:**

1. Load K1 output (z-score change statistics by group and test)
2. Recode test names: "Kävelynopeus" → "MWS_Without_FOF" or "MWS_With_FOF" (based on kaatumisenpelkoOn)
3. Remove kaatumisenpelkoOn column (info now in test names)
4. Transpose: tests become columns, statistical parameters become rows
5. Rename columns for clarity (handle .1, .2 suffixes from duplicates)

### 2. K2.KAAOS-Z_Score_C_Pivot_2R.R (Legacy/Alternative) ✅

**Size:** 6.0 KB
**Changes:**

- Added full CLAUDE.md standard header
- Marked as **legacy/alternative version** (processes different input)
- Implemented `script_label` derivation (uses "K2_2R" to avoid conflicts)
- Added `init_paths("K2_2R")` call with separate output directory
- **Replaced hardcoded path** `C:/Users/korptom20/OneDrive/...`
- Added fallback logic for multiple possible input locations
- Added manifest logging via `save_table_csv_html()`
- Added note recommending K2.Z_Score_C_Pivot_2G.R for current pipelines

**Run command:** `Rscript R-scripts/K2/K2.KAAOS-Z_Score_C_Pivot_2R.R`

**Purpose:**

- Transposes KAAOS z-score change data (legacy format)
- Maintained for backward compatibility with older data
- Similar logic to primary script but different input source

**Required columns:**

```r
req_cols <- c("kaatumisenpelkoOn", "Testi")  # Note: "Testi" not "Test"
```

**Input:** `KAAOS-Z_Score_Change_2R.csv` (from legacy data locations)
**Output:** `R-scripts/K2_2R/outputs/KAAOS-Z_Score_Change_Transposed.csv`

**Note:** This script tries multiple fallback locations for the input file:

1. `data/processed/KAAOS-Z_Score_Change_2R.csv`
2. `vanha.P-Sote/taulukot/KAAOS-Z_Score_Change_2R.csv`
3. `tables/KAAOS-Z_Score_Change_2R.csv`

---

## Testing Instructions

### Prerequisites

```bash
# From repo root
cd Fear-of-Falling

# Restore R dependencies (if not already done)
Rscript -e "renv::restore(prompt = FALSE)"

# IMPORTANT: K2 requires K1 output to be generated first
# Run K1 pipeline if not already done:
Rscript R-scripts/K1/K1.7.main.R
```

### Run K2 Primary Script

```bash
# Execute primary K2 script (requires K1 output)
Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R
```

**Expected output:**

```
================================================================================
K2 Script - Z-Score Change Data Transpose (2 Groups)
================================================================================
Script label: K2
Outputs dir: /path/to/R-scripts/K2/outputs
Manifest: /path/to/manifest/manifest.csv
Project root: /path/to/Fear-of-Falling
================================================================================

Loading K1 output data...
  K1 data loaded: X rows, XX columns
  Required columns present: TRUE

Recoding test names by FOF status...
  Removing kaatumisenpelkoOn column (info now in test names)...

Transposing data frame...
  Transposed structure:
    Rows (parameters): XX
    Columns (tests + Parameter): 9

  Renaming columns for clarity...

Transposed table preview (first 10 rows):
  ...

Saving transposed output...

================================================================================
K2 Script completed successfully.
Output saved to: /path/to/R-scripts/K2/outputs/K2_Z_Score_Change_2G_Transposed.csv
Manifest updated: /path/to/manifest/manifest.csv
================================================================================
```

### Run K2 Legacy Script (Optional)

```bash
# Execute legacy K2 script (requires legacy input file)
Rscript R-scripts/K2/K2.KAAOS-Z_Score_C_Pivot_2R.R

# Note: This will fail if KAAOS-Z_Score_Change_2R.csv is not available
# The error message will guide you to alternative locations or suggest using the primary script
```

### Verify Outputs

```bash
# Check output files created (primary script)
ls -lh R-scripts/K2/outputs/

# Expected files:
# - K2_Z_Score_Change_2G_Transposed.csv (transposed table)

# Check manifest logging
tail -10 manifest/manifest.csv

# Expected manifest entries:
# - 1 row for K2_Z_Score_Change_2G_Transposed.csv (kind: table_csv)
```

### Verification Checklist

- [ ] K1 pipeline runs successfully first
- [ ] K2 primary script runs without errors
- [ ] Output file created: `R-scripts/K2/outputs/K2_Z_Score_Change_2G_Transposed.csv`
- [ ] Manifest has 1 new row for K2 output
- [ ] CSV file has transposed structure (parameters as rows, tests as columns)
- [ ] All progress messages appear correctly
- [ ] No hardcoded paths in error messages
- [ ] (Optional) Legacy script runs if input data available

---

## Key Improvements

### Before Refactoring

❌ Hardcoded paths (`C:/Users/tomik/...`, `C:/Users/korptom20/...`)
❌ No standard headers
❌ No req_cols checks
❌ No manifest logging
❌ Used `View()` (interactive only)
❌ No dependency verification

### After Refactoring

✅ Portable paths (`here::here()`, `init_paths()`)
✅ Complete CLAUDE.md standard headers
✅ Required columns verification
✅ Full manifest logging (1 row per artifact)
✅ Outputs to `R-scripts/K2/outputs/`
✅ Removed interactive `View()` calls
✅ Clear progress messages
✅ Dependency checks (K1 output required)
✅ Reproducible from any machine

---

## K2 Pipeline Details

### Purpose

K2 scripts transform K1 statistical output from "long" format (one row per group-test combination) to "wide" transposed format (one column per group-test combination, parameters as rows).

### Use Case

Transposed format is useful for:

- Creating summary tables for reports/papers
- Side-by-side comparison of test results across FOF groups
- Easier visual inspection of all parameters for each test

### Example Transformation

**K1 Output (Long Format):**

```
kaatumisenpelkoOn | Test         | B_Mean | B_SD | ... | Follow_up_d
0                 | Kävelynopeus | -0.15  | 0.92 | ... | 0.25
1                 | Kävelynopeus | -0.31  | 1.05 | ... | 0.42
0                 | Puristusvoima| 0.08   | 0.95 | ... | 0.18
1                 | Puristusvoima| -0.12  | 1.03 | ... | 0.35
...
```

**K2 Output (Wide/Transposed Format):**

```
Parameter    | MWS_Without_FOF | MWS_With_FOF | HGS_Without_FOF | HGS_With_FOF | ...
B_Mean       | -0.15           | -0.31        | 0.08            | -0.12        | ...
B_SD         | 0.92            | 1.05         | 0.95            | 1.03         | ...
...          | ...             | ...          | ...             | ...          | ...
Follow_up_d  | 0.25            | 0.42         | 0.18            | 0.35         | ...
```

### Test Name Mapping

| Original (Finnish) | FOF=0 (No FOF)    | FOF=1 (With FOF) |
|--------------------|-------------------|------------------|
| Kävelynopeus       | MWS_Without_FOF   | MWS_With_FOF     |
| Puristusvoima      | HGS_Without_FOF   | HGS_With_FOF     |
| Seisominen         | SLS_Without_FOF   | SLS_With_FOF     |
| Tuoliltanousu      | FTSST_Without_FOF | FTSST_With_FOF   |

---

## Dependency Chain

K2 depends on K1 completing successfully:

```
K1 Pipeline (K1.7.main.R)
  ├─ K1.1: Import data
  ├─ K1.2: Transform to z-scores
  ├─ K1.3: Statistical analysis
  ├─ K1.4: Effect sizes
  ├─ K1.5: Distribution checks
  └─ K1.6: Export results
      └─ OUTPUT: K1_Z_Score_Change_2G.csv
          ↓
K2 Script (K2.Z_Score_C_Pivot_2G.R)
  └─ INPUT: K1_Z_Score_Change_2G.csv
      └─ OUTPUT: K2_Z_Score_Change_2G_Transposed.csv
```

**Run order:**

1. Run K1 first: `Rscript R-scripts/K1/K1.7.main.R`
2. Then run K2: `Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R`

---

## Notes for K4 Refactoring

K4 is likely similar to K2 but processes K3 outputs (original values instead of z-scores):

- Should follow same transformation pattern
- Input: K3_Values_2G.csv from K3 outputs
- Output: K4_Values_2G_Transposed.csv
- Same test name recoding logic
- Same transpose operations

---

## Next Steps

1. **Test K2 pipeline** (if K1 data available)
   - Run K1 first: `Rscript R-scripts/K1/K1.7.main.R`
   - Run K2: `Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R`
   - Verify transposed output

2. **Proceed to K4 refactoring**
   - Find K4 scripts
   - Follow same pattern as K2
   - Process K3 outputs instead of K1

3. **Final documentation**
   - Update REFACTORING_STATUS.md
   - Create comprehensive summary
   - Document all K1-K4 dependencies

---

**K2 Refactoring Status:** ✅ COMPLETE
**Ready for:** Testing and K4 refactoring
**Time to complete:** ~1 hour actual work

---

**End of K2 Completion Report**
