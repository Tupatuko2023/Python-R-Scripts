# Spec: Privacy Utilities (SDC)

**Goal:** Create a generalized R function for statistical disclosure control (SDC), specifically designed to suppress small cell counts to protect privacy.

**Context:** Required for refactoring the Fear-of-Falling (FOF) project's reporting pipeline. This utility will be shared across projects.

## Requirements

1.  **Function Name:** `suppress_small_cells`
2.  **Parameters:**
    *   `df`: The input data frame or tibble.
    *   `columns`: A vector of column names to apply suppression to.
    *   `min_n`: The threshold for suppression (default: 5). Values strictly less than this will be suppressed.
    *   `placeholder`: The string to replace small values with (default: "n<5").
3.  **Logic:**
    *   Check if specified columns exist in the data frame.
    *   Iterate through specified columns.
    *   If a value is numeric and `< min_n`, replace it with `placeholder`.
    *   **Crucial:** This operation will convert numeric columns to character/factor type because the placeholder is a string. The function must handle this type conversion gracefully.
4.  **Output:** A modified tibble/data frame.
5.  **Standards:**
    *   Use `dplyr` / Tidyverse syntax.
    *   Use Roxygen2 documentation.
    *   Validate inputs (e.g., check `df` is a data frame).
6.  **Testing:**
    *   Test case 1: Numeric column with values < 5 -> check replacement and type conversion.
    *   Test case 2: Numeric column with all values >= 5 -> check no change (except possible type conversion if consistent return type is enforced, or keep numeric if no suppression happened? *Architect decision needed: usually safer to convert to char if ANY suppression happens, or always return char for consistency in reporting tables*).
    *   Test case 3: Non-existent column -> Error.
