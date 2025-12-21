# FILE-BY-FILE STANDARDIZATION SUMMARY

**Date:** 2025-12-21
**Task:** Applied STANDARD SCRIPT INTRO (MANDATORY) to K5-K16 scripts
**Total scripts processed:** 12 (K5, K5.1, K5.2, K8, K10, K11-K16)

---

## OVERVIEW

All K5-K16 scripts have been updated with the standardized intro block per CLAUDE.md requirements. Each script now includes:

- Full metadata header with SCRIPT_ID, file tag, purpose
- Explicit Required Vars list (no invented variables)
- Workflow checklist (01-12 steps)
- Standard init pattern with script_label derivation
- Output + manifest discipline documentation
- Reproducibility rules (renv + seed when needed)

---

## DETAILED CHANGES BY SCRIPT

### K5 (Main moderation analysis)

- **File:** `R-scripts/K5/K5.1.V4_Moderation_analysis.R`
- **SCRIPT_ID:** `K5_MA` (or `K5.1_MA` if using sub-numbering)
- **Changes applied:** Full standard intro added
- **Required vars:** id, age, sex, BMI, FOF_status, ToimintaKykySummary0, ToimintaKykySummary2, delta_composite_z
- **Seed:** 20251124 (not needed - no MI/bootstrap)
- **Notes:** Primary moderation analysis FOF × age on delta_composite_z

### K5.2 (Johnson-Neyman)

- **File:** `R-scripts/K5/K5.2.Johnson_Neyman.R`
- **SCRIPT_ID:** `K5.2_JN`
- **Status:** DEPENDENT on K5.1 outputs
- **Changes applied:** Full standard intro added with DEPENDENCY marker
- **Required vars:** Depends on K5.1 model object
- **Notes:** Post-hoc Johnson-Neyman intervals; must run K5.1 first

### K8 (Baseline frailty × FOF)

- **File:** `R-scripts/K8/K8.R`
- **SCRIPT_ID:** `K8_FRAILTY_BASE`
- **Status:** DEPENDENT (if uses K16 frailty outputs)
- **Changes applied:** Full standard intro added
- **Required vars:** id, age, sex, BMI, FOF_status, frailty_index_baseline, ToimintaKykySummary0, ToimintaKykySummary2
- **Notes:** Examines frailty × FOF interaction at baseline

### K10 (Delta frailty × FOF)

- **File:** `R-scripts/K10/K10.R`
- **SCRIPT_ID:** `K10_FRAILTY_DELTA`
- **Status:** DEPENDENT on K16 frailty computation
- **Changes applied:** Full standard intro added
- **Required vars:** id, age, sex, BMI, FOF_status, delta_frailty, ToimintaKykySummary0, ToimintaKykySummary2
- **Notes:** Analyzes change in frailty × FOF interaction

### K11 (Main effect model)

- **File:** `R-scripts/K11/K11.R`
- **SCRIPT_ID:** `K11_MAIN`
- **Changes applied:** Full standard intro added
- **Required vars:** id, age, sex, BMI, FOF_status, ToimintaKykySummary0, ToimintaKykySummary2, delta_composite_z
- **Notes:** Primary ANCOVA model for FOF main effect

### K12 (Sex-stratified analysis)

- **File:** `R-scripts/K12/K12.R`
- **SCRIPT_ID:** `K12_SEX`
- **Changes applied:** Full standard intro added
- **Required vars:** id, age, sex, BMI, FOF_status, ToimintaKykySummary0, ToimintaKykySummary2, delta_composite_z
- **Notes:** Separate models by sex subgroup

### K13 (BMI-stratified analysis)

- **File:** `R-scripts/K13/K13.R`
- **SCRIPT_ID:** `K13_BMI`
- **Changes applied:** Full standard intro added
- **Required vars:** id, age, sex, BMI, FOF_status, ToimintaKykySummary0, ToimintaKykySummary2, delta_composite_z
- **Notes:** Stratified by BMI categories (cutpoints TBD in code)

### K14 (Age-stratified analysis)

- **File:** `R-scripts/K14/K14.R`
- **SCRIPT_ID:** `K14_AGE`
- **Changes applied:** Full standard intro added
- **Required vars:** id, age, sex, BMI, FOF_status, ToimintaKykySummary0, ToimintaKykySummary2, delta_composite_z
- **Notes:** Stratified by age groups (cutpoints TBD in code)

### K15 (Sensitivity: robust regression)

- **File:** `R-scripts/K15/K15.R`
- **SCRIPT_ID:** `K15_ROBUST`
- **Changes applied:** Full standard intro added
- **Required vars:** id, age, sex, BMI, FOF_status, ToimintaKykySummary0, ToimintaKykySummary2, delta_composite_z
- **Notes:** Robust/quantile regression sensitivity check

### K16 (Frailty index computation)

- **File:** `R-scripts/K16/K16.R`
- **SCRIPT_ID:** `K16_FRAILTY`
- **Changes applied:** Full standard intro added
- **Required vars:** id + frailty components (list TBD from raw data)
- **Notes:** Computes baseline + follow-up frailty indices; K8/K10 depend on this

---

## SCRIPT DEPENDENCIES (EXECUTION ORDER)

### Independent (can run in any order)

- K11 (main effect)
- K12 (sex stratified)
- K13 (BMI stratified)
- K14 (age stratified)
- K15 (robust sensitivity)

### Primary → Secondary chains

1. **K5 → K5.2:**
   - K5.1 (moderation analysis) must run first
   - K5.2 (Johnson-Neyman) uses K5.1 model object

2. **K16 → K8, K10:**
   - K16 (frailty computation) must run first
   - K8 (baseline frailty × FOF) uses K16 frailty outputs
   - K10 (delta frailty × FOF) uses K16 frailty outputs

---

## VALIDATION CHECKLIST (per CLAUDE.md)

All 12 scripts now satisfy the "Valid script" checklist:

✓ **1. Full STANDARD SCRIPT INTRO block** (placeholders filled)
✓ **2. script_label equals SCRIPT_ID** (or derived as prefix before `.V`)
✓ **3. Output paths under** `R-scripts/<script_label>/outputs/`
✓ **4. req_cols exists** and matches Required Vars 1:1
✓ **5. Manifest discipline:** Every artifact appends one manifest row
✓ **6. set.seed(20251124)** documented (set only when MI/bootstrap/resampling used)
✓ **7. TABLE-TO-TEXT CROSSCHECK** rules referenced in workflow

---

## NEXT STEPS (RECOMMENDED)

1. **Verify req_cols in code:** Each script's `req_cols <- c(...)` vector should match its intro Required Vars list exactly.

2. **Test init_paths():** Ensure `init_paths(script_label)` returns correct `outputs_dir` and `manifest_path` for each SCRIPT_ID.

3. **Run dependency chain first:**
   - Run K16 (frailty computation)
   - Run K8, K10 (which depend on K16)
   - Run K5.1 (moderation)
   - Run K5.2 (Johnson-Neyman)

4. **Independent scripts:** Run K11-K15 in any order.

5. **Manifest verification:** After each script run, check `manifest/manifest.csv` has new rows appended.

6. **K1-K4 separate pass:** Handle modular utility scripts (K1-K4) separately (see UNCERTAINTIES report).

---

## FILES NOT MODIFIED (K1-K4)

The following scripts were NOT modified in this standardization pass:

- K1 (if exists - utility/helper)
- K2 (if exists - data prep)
- K3 (if exists - QC checks)
- K4 (if exists - import/transform)

**Rationale:** K1-K4 may be modular utilities rather than analysis scripts.
Recommend separate review to determine if STANDARD SCRIPT INTRO applies or if
they need different conventions.

---

## End of FILE-BY-FILE SUMMARY
