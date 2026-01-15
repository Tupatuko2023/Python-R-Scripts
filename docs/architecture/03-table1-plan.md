# Technical Plan: Table 1 Generator
**Status:** PROPOSED
**Spec:** docs/specs/03-table1-utils.spec.md
**Context:** Reusable Table 1 generation with built-in privacy guardrails.

## 1. R Module: 'src/analytics/table1_utils.R'

### Function: `create_table1`
- **Signature:** `create_table1(data, vars, strata = NULL, ...)`
- **Logic Flow:**
    1. **Preprocessing:** Source `src/analytics/privacy_utils.R`.
    2. **Stratification:** If `strata` is present, group data.
    3. **Iteration:** Loop through `vars` using `purrr::map`.
        - **Numeric:** Calculate Mean, SD. Format as "Mean (SD)".
        - **Categorical:** Calculate count (n) and percentage (%).
    4. **Privacy Enforcement (The Gate):**
        - Before formatting strings, apply `suppress_small_cells` to the raw counts.
        - If a count is suppressed ("n<5"), the percentage must also be hidden (set to NA or "-").
    5. **Output Structure:**
        - Returns a tibble with columns: `Variable`, `Level`, `Statistics`.
        - If stratified, columns will be: `Variable`, `Level`, `Group A`, `Group B`, `Overall`.

## 2. Testing Strategy: 'tests/testthat/test_table1.R'

### Test Case 1: Simple Numeric & Categorical
- Input: Mock data with Age (num) and Gender (cat).
- Verify structure of output tibble.

### Test Case 2: Stratified Analysis
- Input: Group by 'Treatment' (0 vs 1).
- Verify columns are split by group.

### Test Case 3: Privacy Trigger (Security Test)
- Input: A category with n=3 (e.g., "Rare Disease").
- **Verification:** The output table MUST show "n<5" for that cell, not "3 (1.5%)".

## 3. Policy Compliance
- **Dependencies:** `dplyr`, `tidyr`, `purrr`.
- **Style:** Tidyverse standards.
