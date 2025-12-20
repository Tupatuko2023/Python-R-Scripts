# Quick Start: Smoke Tests for K11-K16

## TL;DR - Run Tests Now

```bash
# Navigate to project root
cd /data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling

# Run all smoke tests (simplest method)
Rscript tests/run_smoke_tests.R
```

## What Gets Tested

- ✓ K11: Primary ANCOVA models & FOF effects
- ✓ K12: Outcome-specific analyses (HGS, MWS, FTSST, SLS)
- ✓ K13: FOF interactions (age, BMI, sex, etc.)
- ✓ K14: Baseline characteristics table
- ✓ K15: Frailty proxy construction
- ✓ K16: Frailty-adjusted models

## Quick Commands

### Run All Tests
```bash
Rscript tests/run_smoke_tests.R
```

### Run Single Script Test
```r
# In R console
source("R-scripts/K11/K11.R")  # Replace K11 with target script
```

### Check Prerequisites Only
```r
# In R console
source("tests/run_smoke_tests.R")
# Will show what's missing without running full tests
```

### Use testthat Framework
```r
library(testthat)
test_file("tests/smoke_test_k11_k16.R")
```

## Expected Runtime

- **Individual script:** 10-60 seconds
- **Full suite:** 3-5 minutes
- **With data checks:** Add 1-2 minutes

## Success Indicators

✓ All scripts complete without errors
✓ Expected CSV/PNG/HTML files created
✓ No missing outputs reported
✓ Summary shows "All smoke tests passed!"

## Common Issues & Quick Fixes

### Issue: "Data file NOT found"
```bash
# Check data file exists
ls data/external/KaatumisenPelko.csv

# If missing, verify correct path
find . -name "KaatumisenPelko.csv"
```

### Issue: "Helper file NOT found"
```bash
# Check helper functions
ls R/functions/*.R

# Should see: io.R, checks.R, modeling.R, reporting.R
```

### Issue: "K16 requires K15 output"
```bash
# Run K15 first
Rscript R-scripts/K15/K15.R

# Then run K16 or full suite
Rscript tests/run_smoke_tests.R
```

### Issue: Package not found
```r
# Install missing packages
install.packages(c("here", "dplyr", "ggplot2", "broom", "lme4"))

# Or use renv (if configured)
renv::restore()
```

## Interpreting Results

### Full Pass
```
Total: 6 | Passed: 6 | Failed: 0
✓ All smoke tests passed!
```
**Action:** None needed. Pipeline is healthy.

### Partial Failure
```
Total: 6 | Passed: 5 | Failed: 1
✗ Some tests failed.
```
**Action:**
1. Check which script failed
2. Review error message
3. Run that script individually for details

### Missing Outputs
```
Outputs: 3 found, 2 missing
```
**Action:**
1. Check if script completed (might have warnings)
2. Verify outputs directory exists and is writable
3. Review script logs for errors

## File Locations

```
Fear-of-Falling/
├── tests/
│   ├── run_smoke_tests.R       ← Main test runner
│   ├── smoke_test_k11_k16.R    ← testthat version
│   ├── README.md                ← Full documentation
│   └── QUICK_START.md           ← This file
├── R-scripts/
│   ├── K11/K11.R               ← Scripts to test
│   ├── K12/K12.R
│   └── .../
└── data/
    └── external/
        └── KaatumisenPelko.csv ← Required data
```

## Next Steps After Tests Pass

1. **Review outputs**: Check `R-scripts/K*/outputs/` directories
2. **Validate results**: Spot-check key tables and figures
3. **Run full analysis**: If smoke tests pass, proceed with full pipeline
4. **Check manifest**: Review `manifest/manifest.csv` for output tracking

## When to Run Smoke Tests

- ✓ After pulling new code changes
- ✓ Before running full analysis pipeline
- ✓ After modifying any K11-K16 scripts
- ✓ After updating data files
- ✓ After package updates
- ✓ In CI/CD pipelines

## Getting Help

1. **Check test output** - Error messages usually indicate the problem
2. **Review README.md** - Full documentation with troubleshooting
3. **Run individually** - Test one script at a time for easier debugging
4. **Check CLAUDE.md** - Project-wide configuration and requirements

---

**One-Line Summary:** `Rscript tests/run_smoke_tests.R` checks if K11-K16 scripts run correctly.
