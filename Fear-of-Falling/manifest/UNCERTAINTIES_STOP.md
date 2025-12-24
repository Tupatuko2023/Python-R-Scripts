# UNCERTAINTIES / STOP ITEMS REPORT

**Date:** 2025-12-21
**Purpose:** Document items requiring user clarification before K5-K16 scripts can execute successfully

---

## CRITICAL: MUST RESOLVE BEFORE EXECUTION

### 1. init_paths() Function Missing or Unverified

**Issue:** All standardized scripts now call `init_paths(script_label)` but this function's existence/location is unverified.

**Required resolution:**

- Confirm `init_paths()` exists in one of:
  - `R/functions/io.R` (or similar helper file)
  - Sourced from a project utilities script
  - Defined in renv/project setup

**Expected behavior:**

```r
paths <- init_paths("K11_MAIN")
# Should return list with:
# $outputs_dir  = "R-scripts/K11/outputs/K11_MAIN/"
# $manifest_path = "manifest/manifest.csv"
# (plus optional: fof.* project options)
```

**If missing:** Scripts will fail immediately at init. User must either:

- Create `init_paths()` function per project conventions
- Replace with explicit path construction in each script

---

### 2. manifest/manifest.csv Structure

**Issue:** Scripts append rows to `manifest/manifest.csv` but column structure is unverified.

**Required resolution:**

- Confirm or create `manifest/manifest.csv` with columns:
  - `file` (artifact filename)
  - `date` (timestamp)
  - `script` (SCRIPT_ID)
  - `git_hash` (optional, if git available)
  - Other project-specific columns?

**If missing:** Create empty manifest with header or provide append_manifest() helper function.

---

### 3. req_cols Verification (Script-by-Script)

**Issue:** Each script's intro lists Required Vars, but actual `req_cols <- c(...)` vectors in code body may not match 1:1.

**Required action (per script):**

- Open each K5-K16 script
- Find the `req_cols` vector definition
- Verify it matches the intro's Required Vars list exactly
- Run column-check assertion (e.g., `stopifnot(all(req_cols %in% names(raw_data)))`)

**Scripts needing verification:**

- K5.1, K5.2, K8, K10, K11, K12, K13, K14, K15, K16 (all 12)

**Consequence if mismatched:** Runtime errors or silent bugs from missing columns.

---

### 4. K16 Frailty Components (Unknown Variable List)

**Issue:** K16.R computes frailty index but frailty component variables are marked "list TBD from raw data."

**Required resolution:**

- Provide actual column names for frailty components (e.g., 30-40 deficit indicators)
- Update K16 intro Required Vars list with complete list
- Update K16 `req_cols` vector accordingly

**Dependency impact:** K8 and K10 cannot run until K16 successfully computes frailty indices.

---

### 5. Stratification Cutpoints (K13, K14)

**Issue:** K13 (BMI strata) and K14 (age strata) have "cutpoints TBD in code."

**Required resolution:**

- **K13:** Define BMI categories (e.g., <25, 25-30, >30 or WHO standard)
- **K14:** Define age groups (e.g., <70, 70-80, >80 or quartiles)

**If missing:** Scripts will need modification before execution; cutpoints affect power and interpretation.

---

### 6. Sex Coding Verification (K12)

**Issue:** Per CLAUDE.md line 221: "Sex: `sex` (coding TBD; do not label without verifying)"

**Required resolution:**

- Confirm sex coding in raw data:
  - Is it 0/1, 1/2, "M"/"F", or other?
  - Which value represents male vs female?
- Update K12 (and other scripts using sex) with explicit factor labeling

**If unverified:** Risk of sex groups being mislabeled in stratified analysis and reporting.

---

### 7. renv Setup Status

**Issue:** CLAUDE.md requires `renv::init()` + `renv::snapshot()` but renv status is unverified.

**Required resolution:**

- Check if `renv.lock` exists and is up-to-date
- If missing: Run `Rscript -e "renv::init()"` and `Rscript -e "renv::snapshot()"`
- Verify all required packages are installed (see CLAUDE.md line 254-273)

**Critical packages to verify:**

- tidyverse, lme4, lmerTest, emmeans, broom, mice, ggplot2

**If missing:** Scripts will fail at library() calls.

---

### 8. Raw Data File Path

**Issue:** Scripts reference raw data but path convention is unverified.

**Required resolution:**

- Confirm raw data location:
  - `data/raw/KaatumisenPelko.csv` (encrypted with git-crypt per git status)?
  - Other filename/location?
- Verify git-crypt is unlocked if data is encrypted
- Update each script's data load path if needed

**Git status shows:** `KaatumisenPelko.csv` exists and is encrypted

**Action:** Ensure git-crypt key is available before running scripts.

---

### 9. K1-K4 Scripts (Not Standardized)

**Issue:** K1-K4 may exist but were not modified in this standardization pass.

**Required resolution:**

- Determine if K1-K4 exist and what they do:
  - K1: Utility/helper functions?
  - K2: Data import/cleaning?
  - K3: QC checks?
  - K4: Variable transformations?
- Decide if STANDARD SCRIPT INTRO applies or if different conventions needed
- If they're prerequisites for K5-K16, run/verify them first

**Recommendation:** Separate review pass for K1-K4 (see todo task 5).

---

### 10. Git Hash Capture (Optional but Recommended)

**Issue:** Manifest logging includes git_hash but capture method is unverified.

**Required resolution:**

- Add helper function or system call to capture git hash:

```r
git_hash <- system("git rev-parse --short HEAD", intern = TRUE)
```

- Or set to NA if not in git repo / git unavailable
- Include in manifest append calls

**If missing:** Reproducibility is reduced but not fatal.

---

## RECOMMENDED PRE-FLIGHT CHECKLIST

Before running any K5-K16 script:

- [ ] Verify `init_paths()` function exists and works
- [ ] Verify `manifest/manifest.csv` exists with correct columns
- [ ] Run `renv::restore()` to install all packages
- [ ] Unlock git-crypt data if encrypted
- [ ] Verify raw data path and column names with `names(raw_data)` + `glimpse(raw_data)`
- [ ] Update K16 with actual frailty component list
- [ ] Define BMI cutpoints in K13
- [ ] Define age cutpoints in K14
- [ ] Verify sex coding and label explicitly
- [ ] Review K1-K4 if they exist

---

## STOP CONDITIONS (DO NOT RUN SCRIPTS IF...)

**STOP if:**

1. `init_paths()` does not exist → scripts will fail immediately
2. Raw data path is incorrect → scripts will fail at data load
3. Required columns are missing from data → scripts will fail at column checks
4. renv packages not installed → scripts will fail at library() calls
5. K16 frailty components list is incomplete → K8/K10 cannot run

**SAFE TO PROCEED when:**

- All items in PRE-FLIGHT CHECKLIST are verified ✓
- Dependency order is followed (K16 before K8/K10; K5.1 before K5.2)
- User has confirmed data structure matches VERIFIED VARIABLE MAP (CLAUDE.md lines 217-226)

---

## End of UNCERTAINTIES/STOP REPORT
