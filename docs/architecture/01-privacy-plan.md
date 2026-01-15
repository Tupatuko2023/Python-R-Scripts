# Technical Plan: Privacy Utilities (SDC)
**Status:** PROPOSED
**Spec:** docs/specs/01-privacy-utils.spec.md
**Context:** General purpose Statistical Disclosure Control (SDC) for R.

## 1. R Module: 'src/analytics/privacy_utils.R'

### Function: `suppress_small_cells`
- **Signature:** `suppress_small_cells(data, ..., min_n = 5, placeholder = "n<5")`
- **Parameters:**
    - `data`: A data frame or tibble.
    - `...`: Tidy-selection of columns to apply logic to (e.g., `where(is.numeric)` or specific names).
    - `min_n`: Threshold (default 5). Values < this are suppressed.
    - `placeholder`: String to replace values with (default "n<5").
- **Logic:**
    1. Check inputs.
    2. Iterate over selected columns using `dplyr::across`.
    3. **CRITICAL:** Convert column to `character` first if suppression occurs, to mix numbers and strings.
    4. Apply replacement logic: `if (x < min_n) return(placeholder) else return(as.character(x))`.
- **Dependencies:** `dplyr`.
- **Documentation:** Roxygen2 tags (`@param`, `@return`, `@export`, `@examples`).

## 2. Testing Strategy: 'tests/testthat/test_privacy.R'

### Test Case 1: Basic Suppression
- Input: Vector `c(2, 10, 20)`.
- Expected: `c("n<5", "10", "20")`.

### Test Case 2: No Suppression
- Input: Vector `c(10, 20, 30)`.
- Expected: Unchanged (but verify type, might remain numeric if implementation allows, otherwise char). *Decision: For consistency, output columns should always be coerced to character if they are targeted for suppression.*

### Test Case 3: Tidy Selection
- Verify it works with `where(is.numeric)`.

## 3. Policy Compliance
- Follows Tidyverse style guide.
- Uses Roxygen2 for documentation.
