# Spec: Standardized Table 1 Generator
**Goal:** Create a reusable R function to generate 'Table 1' (Baseline Characteristics).
**Context:** Standard requirement for clinical trials. Must be privacy-safe.

## Requirements
1. **Function Signature:** create_table1(data, vars, strata = NULL, ...)

2. **Logic:**
   - **Type Detection:** Automatically detect if a variable is numeric or categorical.
   - **Numeric:** Calculate Mean (SD) by default. Support Median (IQR) via config.
   - **Categorical:** Calculate n (%).
   - **Stratification:** If 'strata' is provided, group results by that column (e.g., Intervention vs Control).

3. **Privacy Integration (MANDATORY):**
   - Must import and use 'suppress_small_cells' from 'privacy_utils.R'.
   - Any cell count < 5 must be suppressed in the final output string.

4. **Output:**
   - A clean 'tibble' ready for 'knitr::kable'.
   - Columns: 'Variable', 'Level', 'Overall', (and Group columns if stratified).

5. **Testing:**
   - Test with mixed numeric/categorical data.
   - Test with and without stratification.
   - Verify that small counts are masked.
