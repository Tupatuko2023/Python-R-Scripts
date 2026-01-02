# K4 Pipeline Refactoring - COMPLETE

**Date:** 2025-12-24
**Status:** ✅ All K4 scripts refactored and ready for testing

---

## Summary

The K4 pipeline (Original Values Pivot & Transpose) has been successfully refactored to comply with CLAUDE.md standards. The script now has:

- Standard header with complete documentation
- Required columns checks (`req_cols`)
- Portable path management (no hardcoded paths)
- Manifest logging (via `save_table_csv_html()`)
- Clear progress messages
- Dependency verification

---

## Refactored Script

### K4.A_Score_C_Pivot_2G.R (Primary Script) ✅

**Size:** 7.4 KB
**Changes:**

- Added full CLAUDE.md standard header
- Implemented `script_label` derivation from `--file` argument
- Added `init_paths("K4")` call for portable paths
- **Replaced hardcoded path** `C:/Users/tomik/OneDrive/...` with `here::here()`
- Added dependency check: requires K3 output (`K3_Values_2G.csv`)
- Added manifest logging via `save_table_csv_html()`
- Added progress messages for each transformation step
- **Added VAS (Visual Analogue Scale) support** (K3 includes VAS, K1 does not)
- Removed commented `View()` call (not compatible with non-interactive execution)
- Added EOF marker

**Run command:** `Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R`

**Purpose:**

- Transposes K3 original values output from long to wide format
- Recodes test names to include FOF status (e.g., "MWS_Without_FOF", "MWS_With_FOF")
- Creates parameter-by-test transposed table for easier reporting
- **Similar to K2 but processes original test values instead of z-scores**

**Required columns:**

```r
req_cols <- c("kaatumisenpelkoOn", "Test")
```

**Input:** `R-scripts/K3/outputs/K3_Values_2G.csv`
**Output:** `R-scripts/K4/outputs/K4_Values_2G_Transposed.csv`

**Transformation logic:**

1. Load K3 output (original values statistics by group and test)
2. Recode test names: "Kävelynopeus"/"MWS" → "MWS_Without_FOF" or "MWS_With_FOF" (based on kaatumisenpelkoOn)
3. Remove kaatumisenpelkoOn column (info now in test names)
4. Transpose: tests become columns, statistical parameters become rows
5. Rename columns for clarity (handle .1, .2 suffixes from duplicates)

**Key difference from K2:** K4 also handles VAS (Visual Analogue Scale for pain) which is present in K3 but not in K1 output.

---

## Testing Instructions

### Prerequisites

```bash
# From repo root
cd Fear-of-Falling

# Restore R dependencies (if not already done)
Rscript -e "renv::restore(prompt = FALSE)"

# IMPORTANT: K4 requires K3 output to be generated first
# Run K3 pipeline if not already done:
Rscript R-scripts/K3/K3.7.main.R
```

### Run K4 Script

```bash
# Execute K4 script (requires K3 output)
Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R
```

**Expected output:**

```
================================================================================
K4 Script - Original Values Data Transpose (2 Groups)
================================================================================
Script label: K4
Outputs dir: /path/to/R-scripts/K4/outputs
Manifest: /path/to/manifest/manifest.csv
Project root: /path/to/Fear-of-Falling
================================================================================

Loading K3 output data...
  K3 data loaded: X rows, XX columns
  Required columns present: TRUE

Recoding test names by FOF status...
  Removing kaatumisenpelkoOn column (info now in test names)...

Transposing data frame...
  Transposed structure:
    Rows (parameters): XX
    Columns (tests + Parameter): 9 or 11 (depending on VAS presence)

  Renaming columns for clarity...

Transposed table preview (first 10 rows):
  ...

Saving transposed output...

================================================================================
K4 Script completed successfully.
Output saved to: /path/to/R-scripts/K4/outputs/K4_Values_2G_Transposed.csv
Manifest updated: /path/to/manifest/manifest.csv
================================================================================
```

### Verify Outputs

```bash
# Check output files created
ls -lh R-scripts/K4/outputs/

# Expected files:
# - K4_Values_2G_Transposed.csv (transposed table)

# Check manifest logging
tail -10 manifest/manifest.csv

# Expected manifest entries:
# - 1 row for K4_Values_2G_Transposed.csv (kind: table_csv)
```

### Verification Checklist

- [ ] K3 pipeline runs successfully first
- [ ] K4 script runs without errors
- [ ] Output file created: `R-scripts/K4/outputs/K4_Values_2G_Transposed.csv`
- [ ] Manifest has 1 new row for K4 output
- [ ] CSV file has transposed structure (parameters as rows, tests as columns)
- [ ] All progress messages appear correctly
- [ ] No hardcoded paths in error messages
- [ ] VAS columns present if K3 output includes VAS test

---

## Key Improvements

### Before Refactoring

❌ Hardcoded path (`C:/Users/tomik/OneDrive/...`)
❌ No standard header
❌ No req_cols checks
❌ No manifest logging
❌ Had commented `View()` call (interactive only)
❌ No dependency verification

### After Refactoring

✅ Portable paths (`here::here()`, `init_paths()`)
✅ Complete CLAUDE.md standard header
✅ Required columns verification
✅ Full manifest logging (1 row per artifact)
✅ Outputs to `R-scripts/K4/outputs/`
✅ Removed interactive-only code
✅ Clear progress messages
✅ Dependency checks (K3 output required)
✅ Reproducible from any machine
✅ VAS support added

---

## K4 Pipeline Details

### Purpose

K4 script transforms K3 statistical output from "long" format (one row per group-test combination) to "wide" transposed format (one column per group-test combination, parameters as rows).

### Use Case

Transposed format is useful for:

- Creating summary tables for reports/papers with original test values
- Side-by-side comparison of test results across FOF groups (in original units)
- Easier visual inspection of all parameters for each test
- Reporting actual performance values (seconds, m/s, kg, etc.) instead of z-scores

### Example Transformation

**K3 Output (Long Format - Original Values):**

```
kaatumisenpelkoOn | Test  | B_Mean | B_SD | C_Mean | ... | Follow_up_d
0                 | MWS   | 1.25   | 0.18 | 0.05   | ... | 0.25
1                 | MWS   | 1.15   | 0.22 | 0.03   | ... | 0.42
0                 | HGS   | 28.5   | 5.2  | 1.2    | ... | 0.18
1                 | HGS   | 26.3   | 6.1  | 0.8    | ... | 0.35
0                 | VAS   | 3.2    | 2.1  | -0.5   | ... | 0.15
1                 | VAS   | 4.5    | 2.8  | -0.8   | ... | 0.22
...
```

**K4 Output (Wide/Transposed Format - Original Values):**

```
Parameter    | MWS_Without_FOF | MWS_With_FOF | HGS_Without_FOF | HGS_With_FOF | VAS_Without_FOF | VAS_With_FOF | ...
B_Mean       | 1.25            | 1.15         | 28.5            | 26.3         | 3.2             | 4.5          | ...
B_SD         | 0.18            | 0.22         | 5.2             | 6.1          | 2.1             | 2.8          | ...
C_Mean       | 0.05            | 0.03         | 1.2             | 0.8          | -0.5            | -0.8         | ...
...          | ...             | ...          | ...             | ...          | ...             | ...          | ...
Follow_up_d  | 0.25            | 0.42         | 0.18            | 0.35         | 0.15            | 0.22         | ...
```

### Test Name Mapping

| Original (Finnish) | English | FOF=0 (No FOF)    | FOF=1 (With FOF) |
| ------------------ | ------- | ----------------- | ---------------- |
| Kävelynopeus       | MWS     | MWS_Without_FOF   | MWS_With_FOF     |
| Puristusvoima      | HGS     | HGS_Without_FOF   | HGS_With_FOF     |
| Seisominen         | SLS     | SLS_Without_FOF   | SLS_With_FOF     |
| Tuoliltanousu      | FTSST   | FTSST_Without_FOF | FTSST_With_FOF   |
| PainVAS            | VAS     | VAS_Without_FOF   | VAS_With_FOF     |

**Note:** K4 handles both Finnish and English test names, as well as VAS which is unique to K3/K4 pipelines.

---

## Dependency Chain

K4 depends on K3 completing successfully:

```
K3 Pipeline (K3.7.main.R)
  ├─ K1.1: Import data (SHARED)
  ├─ K3.2: Transform to original values
  ├─ K3.3: Statistical analysis
  ├─ K3.4: Effect sizes
  ├─ K1.5: Distribution checks (SHARED)
  └─ K3.6: Export results
      └─ OUTPUT: K3_Values_2G.csv
          ↓
K4 Script (K4.A_Score_C_Pivot_2G.R)
  └─ INPUT: K3_Values_2G.csv
      └─ OUTPUT: K4_Values_2G_Transposed.csv
```

**Run order:**

1. Run K3 first: `Rscript R-scripts/K3/K3.7.main.R`
2. Then run K4: `Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R`

---

## K2 vs K4 Comparison

| Aspect        | K2 (Z-Score Transpose)              | K4 (Original Values Transpose)        |
| ------------- | ----------------------------------- | ------------------------------------- |
| **Input**     | K1_Z_Score_Change_2G.csv            | K3_Values_2G.csv                      |
| **Data type** | Standardized z-scores               | Original test values (m/s, s, kg, mm) |
| **Tests**     | MWS, FTSST, SLS, HGS (4 tests)      | MWS, FTSST, SLS, HGS, VAS (5 tests)   |
| **Columns**   | 9 (Parameter + 4×2 groups)          | 11 (Parameter + 5×2 groups)           |
| **Use case**  | Comparing standardized performance  | Reporting actual performance values   |
| **Output**    | K2_Z_Score_Change_2G_Transposed.csv | K4_Values_2G_Transposed.csv           |
| **Logic**     | Identical transformation logic      | Identical transformation logic        |

**Key difference:** K4 includes VAS (pain scale) which is present in K3 but not in K1 output.

---

## Complete K1-K4 Pipeline Overview

### Analysis Pipelines (Main)

```
K1 Pipeline → K2 Transpose
  (Z-scores)    (Z-scores transposed)

K3 Pipeline → K4 Transpose
  (Original)    (Original transposed)
```

### Full Dependency Graph

```
Raw Data (KaatumisenPelko.csv)
  ├─ K1 Pipeline (Z-Score Analysis)
  │   ├─ K1.1: Import ────────────────┐ (SHARED)
  │   ├─ K1.2: Z-score transform      │
  │   ├─ K1.3: Stats                  │
  │   ├─ K1.4: Effect sizes           │
  │   ├─ K1.5: Distribution ──────────┤ (SHARED)
  │   └─ K1.6: Export → K1_Z_Score_Change_2G.csv
  │       └─ K2: Transpose → K2_Z_Score_Change_2G_Transposed.csv
  │
  └─ K3 Pipeline (Original Values Analysis)
      ├─ K1.1: Import (SHARED) ───────┘
      ├─ K3.2: Original values transform
      ├─ K3.3: Stats
      ├─ K3.4: Effect sizes
      ├─ K1.5: Distribution (SHARED) ─┘
      └─ K3.6: Export → K3_Values_2G.csv
          └─ K4: Transpose → K4_Values_2G_Transposed.csv
```

---

## Next Steps

1. **Test K4 pipeline** (if K3 data available)
   - Run K3 first: `Rscript R-scripts/K3/K3.7.main.R`
   - Run K4: `Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R`
   - Verify transposed output with original values

2. **Create final K1-K4 summary**
   - Update REFACTORING_STATUS.md with all completions
   - Document all dependencies
   - Create comprehensive testing guide

3. **Run smoke tests** (if data available)
   - Test complete K1 → K2 pipeline
   - Test complete K3 → K4 pipeline
   - Verify all manifest entries
   - Compare outputs with baseline (if available)

---

**K4 Refactoring Status:** ✅ COMPLETE
**Ready for:** Testing and final documentation
**Time to complete:** ~45 minutes actual work

---

**End of K4 Completion Report**
