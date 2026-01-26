# Smoke Tests for K11-K16 R Scripts

This directory contains smoke tests for the Fear of Falling analysis scripts (K11.R through K16.R).

## What are Smoke Tests?

Smoke tests are simple, quick tests that verify the basic functionality of code:

- ✓ Scripts can run without critical errors
- ✓ Required input files exist
- ✓ Expected output files are created
- ✓ Basic data processing completes successfully

These are NOT comprehensive unit tests, but rather quick sanity checks to ensure the pipeline is functional.

## Test Files

1. **`smoke_test_k11_k16.R`** - Full test suite using the `testthat` framework
2. **`run_smoke_tests.R`** - Standalone test runner (no `testthat` dependency required)

## Prerequisites

Before running smoke tests, ensure:

1. **Data file exists**: `data/external/KaatumisenPelko.csv`
2. **Helper functions exist**: `R/functions/io.R`, `checks.R`, `modeling.R`, `reporting.R`
3. **Required R packages are installed**:
   - `here`, `dplyr`, `tidyr`, `ggplot2`, `broom`, `lme4`, etc.
   - See individual scripts for full package requirements

## Running the Tests

### Option 1: Simple Standalone Runner (Recommended for Quick Checks)

To run a subset of tests (K11-K16):

```bash
# From the project root directory
Rscript tests/run_smoke_tests.R
```

To run the full pipeline test (K1-K16):

```bash
# From the project root directory
Rscript tests/smoke_test_all_k_scripts.R
```

This will:

- Check all prerequisites
- Run scripts in sequence (honoring dependencies)
- Verify expected outputs are created
- Display a summary report

#### MOCK_MODE for Standalone/CI Testing

When running tests in a standalone environment (e.g., Docker container with generated mock data), some statistical models in `K9.R` may fail due to aliasing or singularity issues inherent to the simplified mock data structure.

To prevent the entire test suite from failing in these scenarios, set the `MOCK_MODE` environment variable to `true`:

```bash
# Run with MOCK_MODE enabled (full suite)
MOCK_MODE=true Rscript tests/smoke_test_all_k_scripts.R
```

**Effect of MOCK_MODE=true:**

- **K9.R:** If the primary ANCOVA model fails (Type III and Type II), the script will generate a dummy result table with a warning instead of stopping execution. This ensures the pipeline continues for artifact verification purposes.
- Without `MOCK_MODE=true`, `K9.R` will stop with an error on model failure (fail-fast behavior for production/real data).

**Pros:**

- No additional dependencies required
- Simple, readable output
- Good for CI/CD pipelines

**Cons:**

- Less detailed error reporting
- No test isolation

### Option 2: testthat Framework (Recommended for Development)

```r
# In R console
library(testthat)
test_file("tests/smoke_test_k11_k16.R")
```

Or from command line:

```bash
Rscript -e "testthat::test_file('tests/smoke_test_k11_k16.R')"
```

**Pros:**

- Better test isolation
- Detailed error reports
- Can skip tests if prerequisites missing

**Cons:**

- Requires `testthat` package

## Test Coverage

### K11.R - Primary ANCOVA Models

- ✓ Script runs without errors
- ✓ ANCOVA model outputs created
- ✓ FOF effect tables generated
- ✓ Responder analysis plots created

### K12.R - FOF Effects by Outcome

- ✓ Script runs without errors
- ✓ Models for all outcomes (HGS, MWS, FTSST, SLS) completed
- ✓ Forest plot created
- ✓ Standardized effects table generated

### K13.R - Interaction Analyses

- ✓ Script runs without errors
- ✓ Interaction models (age, BMI, sex) fitted
- ✓ Simple slopes calculated
- ✓ Interaction plots generated

### K14.R - Baseline Table

- ✓ Script runs without errors
- ✓ Baseline characteristics table created
- ✓ CSV and HTML outputs generated

### K15.R - Frailty Proxy

- ✓ Script runs without errors
- ✓ Frailty components calculated
- ✓ Frailty categories created
- ✓ Analysis data saved for K16

### K16.R - Frailty-Adjusted Models

- ✓ Script runs without errors
- ✓ K15 output loaded successfully
- ✓ ANCOVA and mixed models fitted
- ✓ Results tables and plots generated
- ✓ English and Finnish results text created

## Understanding Test Results

### Successful Test Output

```text
======================================================================
SMOKE TESTS FOR K11-K16 R SCRIPTS
======================================================================

✓ Data file found: KaatumisenPelko.csv
✓ Helper file found: io.R
✓ Helper file found: checks.R
✓ Helper file found: modeling.R
✓ Helper file found: reporting.R

----------------------------------------------------------------------
Testing: K11
----------------------------------------------------------------------
✓ Script completed successfully in 45.2 seconds

Checking expected outputs:
  ✓ fit_primary_ancova.csv
  ✓ lm_base_model_full.csv
  ✓ FOF_effect_base_vs_extended.csv

======================================================================
TEST SUMMARY
======================================================================

✓ PASS   K11 (45.2s)
✓ PASS   K12 (38.7s)
✓ PASS   K13 (52.1s)
✓ PASS   K14 (12.3s)
✓ PASS   K15 (28.9s)
✓ PASS   K16 (41.5s)

Total: 6 | Passed: 6 | Failed: 0

✓ All smoke tests passed!
```

### Failed Test Output

```text
----------------------------------------------------------------------
Testing: K11
----------------------------------------------------------------------
✗ Script failed with error:
   Error in lm(...): object 'Delta_Composite_Z' not found

✗ FAIL   K11

Total: 6 | Passed: 5 | Failed: 1
```

## Troubleshooting

### "Data file NOT found"

**Problem:** `data/external/KaatumisenPelko.csv` is missing

**Solution:**

- Ensure data file is in the correct location
- Check file permissions
- Verify file name spelling (case-sensitive on Linux)

### "Helper file NOT found"

**Problem:** Required R function files are missing

**Solution:**

- Ensure `R/functions/` directory exists
- Check that `io.R`, `checks.R`, `modeling.R`, `reporting.R` are present
- Verify file paths match project structure

### "K16 requires K15 output"

**Problem:** K16 needs frailty data from K15

**Solution:**

1. Run K15 first: `Rscript R-scripts/K15/K15.R`
2. Verify `R-scripts/K15/outputs/K15_frailty_analysis_data.RData` exists
3. Then run K16 or the full smoke test

### Script runs but outputs are missing

**Problem:** Script completes but doesn't create expected files

**Possible causes:**

- Permissions issues in `outputs/` directory
- Script logic errors (check for warnings)
- Data quality issues preventing model fitting

**Solution:**

- Check script console output for warnings
- Verify `R-scripts/K*/outputs/` directories exist and are writable
- Run script interactively to debug: `source("R-scripts/K11/K11.R")`

### Long execution time / timeout

**Problem:** Script takes longer than expected

**Solution:**

- Increase `TIMEOUT_SECONDS` in `run_smoke_tests.R`
- Check system resources (memory, CPU)
- Consider running individual scripts instead of full suite

## Adding New Tests

To add smoke tests for new scripts:

1. **Update `run_smoke_tests.R`**:

   ```r
   SCRIPTS_TO_TEST <- c("K11", "K12", ..., "K17", "K18")

   EXPECTED_OUTPUTS <- list(
     ...
     K17 = c("output1.csv", "output2.png"),
     K18 = c("results.docx")
   )
   ```

2. **Update `smoke_test_k11_k16.R`**:

   ```r
   test_that("K17.R runs without errors", {
     skip_if_not(file.exists(...), "Prerequisites not met")
     result <- run_script_smoke("K17")
     expect_true(result$success)
     # ... check outputs
   })
   ```

## CI/CD Integration

For automated testing in CI/CD pipelines:

```bash
#!/bin/bash
# .github/workflows/smoke-tests.yml or similar

# Exit on first failure
set -e

# Run smoke tests
Rscript tests/run_smoke_tests.R

# Check exit code
if [ $? -eq 0 ]; then
  echo "✓ All smoke tests passed"
  exit 0
else
  echo "✗ Smoke tests failed"
  exit 1
fi
```

## Performance Benchmarks

Typical execution times (may vary by system):

| Script    | Expected Time | Notes                    |
| --------- | ------------- | ------------------------ |
| K11       | 30-60s        | Includes MICE imputation |
| K12       | 25-45s        | Multiple outcome models  |
| K13       | 40-70s        | Many interaction models  |
| K14       | 10-20s        | Table generation only    |
| K15       | 20-40s        | Frailty calculations     |
| K16       | 35-60s        | Requires K15 output      |
| **Total** | **~3-5 min**  | Full suite               |

## Support

For issues or questions:

1. Check script-specific documentation in `R-scripts/K*/`
2. Review `CLAUDE.md` for project configuration
3. Check individual script comments for requirements
4. Verify `renv.lock` for package versions

## Maintenance

These tests should be updated when:

- New scripts are added (K17, K18, etc.)
- Expected outputs change
- New dependencies are introduced
- Data structure changes significantly

---

**Last Updated:** 2025-12-18
**Maintainer:** Fear of Falling Analysis Team
