# Fear-of-Falling R Environment Status

## Overview

This document describes the renv-managed R environment for the Fear-of-Falling (FOF) analysis project.

## Environment Configuration

| Component | Status | Location |
|-----------|--------|----------|
| renv.lock | Present | `Fear-of-Falling/renv.lock` |
| renv/ | Present | `Fear-of-Falling/renv/` |
| .Rprofile | Present | `Fear-of-Falling/.Rprofile` |
| R Version | 4.5.0 | Specified in renv.lock |
| Total Packages | 169 | Locked in renv.lock |

## How to Restore Environment

### First-time setup

```r
# From Fear-of-Falling/ directory
setwd("Fear-of-Falling")

# Restore packages from lockfile
renv::restore()

# Verify status
renv::status()
```

### After pulling changes

```r
# Check if lockfile changed
renv::status()

# Restore if needed
renv::restore()
```

### After installing new packages

```r
# Update lockfile
renv::snapshot()

# Commit renv.lock
```

## Key Analysis Packages

The following packages are critical for FOF analyses (all locked in renv.lock):

### Modeling

| Package | Version | Purpose |
|---------|---------|---------|
| lme4 | (locked) | Mixed-effects models |
| nlme | (locked) | Linear/nonlinear mixed-effects |
| emmeans | (locked) | Estimated marginal means |
| mice | (locked) | Multiple imputation |
| marginaleffects | (locked) | Marginal effects and contrasts |

### Data Processing

| Package | Version | Purpose |
|---------|---------|---------|
| dplyr | (locked) | Data manipulation |
| tidyr | (locked) | Data tidying |
| readr | (locked) | CSV/data import |
| here | (locked) | Project-relative paths |

### Reporting

| Package | Version | Purpose |
|---------|---------|---------|
| ggplot2 | (locked) | Visualization |
| knitr | (locked) | Dynamic documents |
| rmarkdown | (locked) | R Markdown rendering |
| broom | (locked) | Model tidying |
| broom.mixed | (locked) | Mixed model tidying |

### Model Diagnostics

| Package | Version | Purpose |
|---------|---------|---------|
| performance | (locked) | Model performance metrics |
| parameters | (locked) | Model parameters extraction |
| effectsize | (locked) | Effect size calculations |

## Known Issues

### Sync Status (from last diagnostics)

The renv diagnostics from `manifest/renv_diagnostics.txt` reported:

**Packages installed but not recorded in lockfile:**
- colorspace, curl, forecast, fracdiff, quadprog, quantmod
- RcppArmadillo, timeDate, tseries, TTR, urca, xts

**Packages used but not installed:**
- marginaleffects, partR2, R.utils, testthat

**Resolution:** Run `renv::snapshot()` to record installed packages, or `renv::restore()` to match lockfile.

## What NOT to Do

- Do NOT edit `renv.lock` manually
- Do NOT delete `renv/` directory without restoring
- Do NOT use `install.packages()` directly - use `renv::install()`
- Do NOT commit `renv/library/` to git (already in .gitignore)

## Reproducibility Notes

- All Kxx scripts should include `sessionInfo()` save at end
- Use `set.seed(20251124)` for any randomness (MI, bootstrap, resampling)
- Save `renv::diagnostics()` output to `manifest/renv_diagnostics.txt` periodically

## References

- [renv documentation](https://rstudio.github.io/renv/)
- [Fear-of-Falling/CLAUDE.md](../CLAUDE.md) - Project conventions
- [Fear-of-Falling/AGENTS.md](../AGENTS.md) - Agent guidelines
