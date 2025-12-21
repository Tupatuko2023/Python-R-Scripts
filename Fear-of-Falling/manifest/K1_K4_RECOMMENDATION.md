# K1-K4 MODULAR SCRIPTS RECOMMENDATION

**Date:** 2025-12-21
**Status:** K1-K4 scripts do not currently exist in R-scripts/ directory

---

## FINDING

Search for K1-K4 scripts in `R-scripts/K[1-4]/**/*.R` returned no matches.

**Conclusion:** No K1-K4 scripts exist in the current repository structure.

---

## RECOMMENDATION

Given that K5-K16 are now standardized analysis scripts, consider creating K1-K4 as modular utility scripts if needed:

### Suggested K1-K4 Organization (Optional)

**K1: Helper Functions** (if needed)

- Purpose: Shared utility functions (io, checks, modeling helpers)
- Structure: R functions library (not analysis script)
- STANDARD SCRIPT INTRO: NOT applicable (this is a function library)
- Location alternative: `R/functions/` (may already exist)

**K2: Data Import & Preprocessing** (if needed)

- Purpose: Load raw encrypted data, initial transforms
- Structure: Pipeline script that outputs processed data
- STANDARD SCRIPT INTRO: CONDITIONALLY applicable
- Output: `data/processed/analysis_ready.rds` (or similar)

**K3: Quality Control Checks** (if needed)

- Purpose: Comprehensive QC report on raw/processed data
- Structure: Analysis script producing QC report
- STANDARD SCRIPT INTRO: APPLICABLE (generates outputs)
- Output: QC report, diagnostic plots, missingness patterns

**K4: Derived Variables** (if needed)

- Purpose: Compute delta_composite_z, frailty indices, etc.
- Structure: Pipeline script
- STANDARD SCRIPT INTRO: APPLICABLE if generates outputs
- Note: This might duplicate K16 (frailty); consider merging

---

## CURRENT STATUS: NO ACTION NEEDED

Since K1-K4 do not exist and K5-K16 are self-contained analysis scripts:

- ✓ No immediate action required for K1-K4
- ✓ K5-K16 standardization is complete
- ✓ If utility scripts are needed in future, follow recommendations above

---

## IF K1-K4 ARE CREATED IN FUTURE

Apply these decision rules:

### When to use STANDARD SCRIPT INTRO

- Script generates output artifacts (tables, figures, models, reports)
- Script runs as standalone analysis (not just function definitions)
- Script needs manifest tracking for reproducibility

### When NOT to use STANDARD SCRIPT INTRO

- Pure function library (no execution, just definitions)
- Interactive helper scripts (not meant for `Rscript` execution)
- One-off exploration scripts (not part of reproducible pipeline)

### Alternative conventions for modular scripts

- Create separate documentation: `K1_FUNCTIONS.md` (function reference)
- Use roxygen2 documentation for function libraries
- Use lightweight headers for pipeline scripts (adapt STANDARD INTRO)

---

## End of K1-K4 RECOMMENDATION
