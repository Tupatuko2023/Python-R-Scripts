# PR Summary: K1-K4 Refactoring to CLAUDE.md Standards

**Date:** 2025-12-24
**Status:** IN PROGRESS (Foundation complete, K1 partially done)
**Branch:** (to be created)

---

## Overview

This PR refactors K1-K4 R scripts to comply with project CLAUDE.md conventions while preserving all analysis logic and results. The refactoring focuses on:

- Standardizing script headers
- Implementing reproducible path management
- Adding manifest logging for all artifacts
- Ensuring seed setting for randomness
- Using centralized helper functions

---

## What Changed

### ✅ Completed Changes

#### 1. Foundation (R/functions/)

- **R/functions/io.R**: Added `load_raw_data()` wrapper with fallback logic
  - Primary location: `data/raw/KaatumisenPelko.csv`
  - Fallback: `dataset/KaatumisenPelko.csv` (legacy)
  - Clear error messages if file not found

- **Verified existing helpers:**
  - `init_paths(script_label)` - creates outputs dir + sets manifest path
  - `append_manifest()` + `manifest_row()` - logs artifacts
  - `save_table_csv_html()` - saves tables with manifest logging
  - `save_sessioninfo_manifest()` - saves R session info
  - `standardize_analysis_vars()` - transforms raw to analysis variables
  - `sanity_checks()` - validates data structure

#### 2. K1 Pipeline (Partial)

- **K1.7.main.R** - Orchestrator script:
  - ✅ Added full CLAUDE.md standard header
  - ✅ Implemented `script_label` derivation from `--file` argument
  - ✅ Added `init_paths("K1")` call before sourcing subscripts
  - ✅ Replaced `setwd()` + relative paths with absolute `source()` paths
  - ✅ Added clear progress messages and workflow documentation
  - ✅ Added EOF marker

- **K1.1.data_import.R** - Data import script:
  - ✅ Added full CLAUDE.md standard header
  - ✅ Defined `req_cols` for raw data (7 variables)
  - ✅ Uses `load_raw_data()` helper with fallback logic
  - ✅ Verifies required columns exist (stops with clear error if missing)
  - ✅ Defers factor conversion to K1.2 (pure data import)
  - ✅ Note: Shared by K3 pipeline

### ⏳ In Progress / Remaining

#### K1 Pipeline (Remaining)

- [ ] **K1.2.data_transformation.R**: Add standard header + req_cols check (needs review - see notes)
- [ ] **K1.3.statistical_analysis.R**: Add standard header
- [ ] **K1.4.effect_sizes.R**: Add standard header + `set.seed(20251124)` for bootstrap
- [ ] **K1.5.kurtosis_skewness.R**: Add standard header (note: shared by K3)
- [ ] **K1.6.results_export.R**: Refactor to use `save_table_csv_html()` + manifest logging

#### K3 Pipeline

- [ ] **K3.7.main.R**: Similar to K1.7, but sources K1.1 and K1.5 with absolute paths
- [ ] **K3.2, K3.3, K3.4, K3.6**: Similar to K1 equivalents
- [ ] **K3.4.effect_sizes.R**: Add `set.seed(20251124)` for bootstrap

#### K2 Pipeline

- [ ] **K2.Z_Score_C_Pivot_2G.R**: Standard header + dynamic input paths from K1 outputs
- [ ] **K2.KAAOS-Z_Score_C_Pivot_2R.R**: Standard header + dynamic input paths

#### K4 Pipeline

- [ ] **K4.A_Score_C_Pivot_2G.R**: Standard header + dynamic input path from K3 outputs

---

## Why These Changes

### Problem Statement

K1-K4 scripts had several issues preventing reproducibility and maintainability:

1. **Hardcoded paths**: Windows-specific absolute paths (`C:/Users/tomik/...`)
2. **No manifest logging**: Outputs not tracked in manifest/manifest.csv
3. **No standard headers**: Missing documentation of purpose, variables, mappings
4. **No req_cols checks**: Risk of silent failures if data structure changes
5. **Inconsistent randomness**: Bootstrap without seed setting (K1.4, K3.4)
6. **Scattered helper logic**: Same code repeated across scripts

### Solution Approach

Minimal, reversible refactoring following CLAUDE.md conventions:

- Add standard headers (documentation only, no logic change)
- Use existing R/functions/ helpers (already tested)
- Replace hardcoded paths with `here::here()` + `init_paths()`
- Add manifest logging for all outputs
- Set seed for reproducibility

---

## How to Run

### Prerequisites

```bash
# From repo root
cd Fear-of-Falling

# Restore R dependencies
Rscript -e "renv::restore(prompt = FALSE)"
```

### Run Pipelines (from repo root)

#### K1: Z-Score Change Analysis

```bash
Rscript R-scripts/K1/K1.7.main.R
```

**Outputs:** `R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv` (and others)

#### K3: Original Values Analysis

```bash
Rscript R-scripts/K3/K3.7.main.R
```

**Outputs:** `R-scripts/K3/outputs/K3_Values_2G.csv` (and others)

#### K2: Z-Score Pivot (requires K1 outputs)

```bash
Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R
```

**Outputs:** `R-scripts/K2/outputs/K2_Z_Score_Change_2G_Transposed.csv`

#### K4: Score Pivot (requires K3 outputs)

```bash
Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R
```

**Outputs:** `R-scripts/K4/outputs/K4_Score_Change_2G_Transposed.csv`

### Verify Manifest Logging

```bash
# Check manifest has new entries
tail -20 manifest/manifest.csv

# Count entries per script
grep -c '"K1"' manifest/manifest.csv
grep -c '"K2"' manifest/manifest.csv
grep -c '"K3"' manifest/manifest.csv
grep -c '"K4"' manifest/manifest.csv
```

---

## What Was Tested

### ✅ Completed Testing

- [x] Verified R/functions/ helpers exist and have correct signatures
- [x] Verified `init_paths()` creates correct directory structure
- [x] Verified K1.7.main.R has proper header and init logic
- [x] Verified K1.1.data_import.R has req_cols check and fallback logic

### ⏳ Remaining Testing (After Completing Refactoring)

- [ ] Smoke test: K1 pipeline runs without errors
- [ ] Smoke test: K3 pipeline runs without errors
- [ ] Smoke test: K2 pipeline runs without errors (after K1)
- [ ] Smoke test: K4 pipeline runs without errors (after K3)
- [ ] Verify outputs appear in R-scripts/<K>/outputs/
- [ ] Verify manifest.csv has 1 row per output file
- [ ] Verify sessionInfo files created
- [ ] Before/after comparison (if baseline available):
  - Output dimensions match
  - Numeric values match (within 1e-6 tolerance)
  - set.seed ensures bootstrap results are deterministic

---

## Risks and Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Output path changes break downstream scripts | Medium | Medium | All paths use `here::here()` + documented in runbook |
| set.seed() changes bootstrap results slightly | Low | Low | Acceptable - ensures reproducibility going forward |
| Initial smoke tests fail (missing raw data) | Medium | Low | Documented fallback paths; check data/ and dataset/ dirs |
| Shared scripts (K1.1, K1.5) cause K3 issues | Medium | High | K3 tested immediately after K1 completion |
| Manifest.csv grows large | Low | Low | Can archive old rows if needed |
| K1.2 logic differs from helper | Medium | Medium | Review K1.2 before applying standardize_analysis_vars() |

### Rollback Plan

If issues arise:

1. `git revert` to last working commit
2. Review specific diff causing issue
3. Fix and retest (don't revert entire refactoring)
4. All changes are minimal and reversible by design

---

## Migration Notes

### For Users

**Old behavior:**

- Outputs went to `tables/` directory (hardcoded Windows paths)
- No manifest tracking
- Required manual path editing to run on different machines

**New behavior:**

- Outputs go to `R-scripts/<K>/outputs/` (portable paths)
- All outputs logged in `manifest/manifest.csv`
- Scripts run from repo root without modification
- Cross-platform compatible (uses `here::here()`)

### For Developers

**Adding new Kxx scripts:**

1. Copy standard header template from REFACTORING_IMPLEMENTATION_GUIDE.md
2. Call `init_paths("Kxx")` at start (for main scripts)
3. Use `save_table_csv_html()` for outputs
4. Add `set.seed(20251124)` if using randomness
5. Define `req_cols` and check them

**Modifying existing K1-K4:**

- Review REFACTORING_IMPLEMENTATION_GUIDE.md first
- Preserve analysis logic (don't change statistical computations)
- Update manifest logging if adding new outputs
- Test before/after if changing bootstrap or statistical code

---

## Documentation Updates

### New Documentation

1. **docs/k1-k4_inventory.md**: Complete inventory of K1-K4 scripts
2. **docs/k1-k4_differences_matrix.md**: Comparison matrix and patterns
3. **docs/k1-k4_refactor_plan.md**: Detailed 6-phase refactoring plan
4. **docs/REFACTORING_IMPLEMENTATION_GUIDE.md**: Templates and completion guide

### Updated Documentation

- **README.md**: Added K1-K4 runbook section (see below)
- **CLAUDE.md**: Already defines standards (no changes needed)

---

## Next Steps

### Immediate (Complete Refactoring)

1. Complete K1.2-K1.6 refactoring (see REFACTORING_IMPLEMENTATION_GUIDE.md)
2. Run K1 smoke test and verify outputs
3. Complete K3 refactoring (K3.2-K3.7)
4. Run K3 smoke test and verify outputs
5. Complete K2 refactoring
6. Complete K4 refactoring
7. Run full smoke test suite
8. Document before/after comparison results

### Future Enhancements

1. Apply same standards to K5-K16 (especially K11-K16 which are analysis-focused)
2. Consider deprecating K1.Z_Score_Change_2G_v4.R (monolithic duplicate of K1.7)
3. Add automated tests (testthat) for key functions
4. Consider creating shared FOF test recoding helper for K2/K4 (reduce duplication)

---

## Checklist for Reviewers

- [ ] Standard headers present in all modified scripts
- [ ] All hardcoded paths replaced with `here::here()` or `init_paths()`
- [ ] All output scripts use `save_table_csv_html()` + manifest logging
- [ ] set.seed(20251124) added to K1.4 and K3.4 (bootstrap scripts)
- [ ] req_cols defined and checked in data-loading scripts
- [ ] K1.7 and K3.7 source subscripts with absolute paths (no setwd)
- [ ] Smoke tests pass for all K1-K4 pipelines
- [ ] Outputs appear in R-scripts/<K>/outputs/ (not tables/)
- [ ] manifest/manifest.csv has entries for all outputs
- [ ] README.md has runbook section
- [ ] No regression in analysis results (before/after comparison)

---

## Summary

This refactoring brings K1-K4 scripts into compliance with CLAUDE.md standards without changing any statistical logic. The changes are minimal, reversible, and focused on:

- **Reproducibility** (renv + seed)
- **Portability** (no hardcoded paths)
- **Transparency** (manifest logging + standard headers)
- **Maintainability** (centralized helpers + documentation)

All changes follow the principle: "Do not break working analysis."

---

**Status:** Ready for review after completing remaining K1.2-K1.6, K2, K3, K4 refactoring

**Estimated completion:** Remaining work is ~6-8 scripts with similar patterns

**Questions/Discussion:** See REFACTORING_IMPLEMENTATION_GUIDE.md for implementation notes

---

**End of PR Summary**
