# GitHub Actions Workflows

## Smoke Tests Workflow

### Overview

The `smoke-tests.yml` workflow automatically runs all K scripts (K1-K16) in a
Docker container to ensure they execute successfully without errors.

### Triggers

- **Push to main**: Runs on every push to the main branch that affects files in
  `Fear-of-Falling/`
- **Pull Requests**: Runs on PRs targeting main branch
- **Manual**: Can be triggered manually via GitHub Actions UI

### What it Does

1. **Builds Docker image**: Creates the `fof-r-analysis` Docker image with all
   required R packages and dependencies
2. **Runs smoke tests**: Executes `tests/smoke_test_all_k_scripts.R` which runs
   all 15 K scripts (K1-K4, K6-K16)
3. **Generates report**: Creates `SMOKE_TEST_REPORT_ALL_K_SCRIPTS.md` with
   detailed results
4. **Uploads artifacts**: Saves the smoke test report and logs as downloadable
   artifacts (retained for 30 days)
5. **Reports status**: Displays pass/fail status in the workflow summary and
   fails the job if any tests fail

### Expected Results

- **All 15 scripts should pass** (K1-K4, K6-K16)
- Total execution time: ~2-5 minutes for all scripts
- Each script generates outputs in `R-scripts/<K>/outputs/`

### Viewing Results

1. Go to the **Actions** tab in GitHub
2. Click on the latest **K Scripts Smoke Tests** run
3. View the summary showing passed/failed tests
4. Download the **smoke-test-report** artifact for detailed results

### Badge Status

The README displays a badge showing the current test status:

- ✅ Green badge = All tests passing
- ❌ Red badge = Some tests failing

### Troubleshooting

If tests fail:

1. Check the workflow run logs in GitHub Actions
2. Download the smoke test report artifact
3. Review the STDERR output for specific error messages
4. Common issues:
   - Missing library imports
   - Data file path problems
   - Package version conflicts
   - Regex pattern errors

### Local Testing

To run the same tests locally:

```bash
cd Fear-of-Falling
docker build -t fof-r-analysis:latest .
docker run --name fof-test fof-r-analysis:latest \
  Rscript tests/smoke_test_all_k_scripts.R
```

### Maintenance

- The workflow runs on Ubuntu latest with Docker support
- Timeout is set to 45 minutes (should complete in ~5 minutes)
- Artifacts are retained for 30 days
