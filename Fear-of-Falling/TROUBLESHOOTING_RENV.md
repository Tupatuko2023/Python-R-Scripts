# Troubleshooting Guide: renv Package Installation Issues

**Purpose:** Step-by-step solutions for common renv restoration problems
**Focus:** Windows environment with MSYS2/MinGW build tools
**Target:** Fear of Falling (FOF) R analysis project

---

## Quick Diagnosis

### Check Current Status

```r
# In R console
renv::status()
```

**Expected output if working:**

```text
* The project is already synchronized with the lockfile.
```

**Problem indicators:**

```text
* One or more packages recorded in the lockfile are not installed.
* The following package(s) are missing entries in the lockfile:
```

---

## Common Issues and Solutions

### Issue 1: "Package 'gdtools' Failed to Install"

**Error:**

```text
Can't locate Pod/Usage.pm in @INC
BEGIN failed--compilation aborted at /c/Strawberry/perl/bin/pkg-config
```

**Cause:** Missing Perl dependencies for pkg-config

**Solution A: Install Perl Module (If using Strawberry Perl)**

```bash
# Open Windows Terminal or Git Bash
cpan Pod::Usage

# Or if cpan doesn't work:
perl -MCPAN -e "install Pod::Usage"
```

**Solution B: Use MSYS2 Perl Instead**

```bash
# In MSYS2 terminal
pacman -S perl perl-Pod-Parser

# Then retry in R:
Rscript -e "renv::restore()"
```

**Solution C: Skip gdtools (Quick Fix)**

```r
# Install everything except problematic packages
# Create a custom restore script
packages_to_skip <- c("gdtools", "ragg", "systemfonts")

# Get all packages from lockfile
lockfile <- renv::lockfile_read()
all_packages <- names(lockfile$Packages)

# Filter out problematic ones
packages_to_install <- setdiff(all_packages, packages_to_skip)

# Install filtered list
install.packages(packages_to_install)
```

**Which solution to use:**

- **Solution A** - If you need flextable/ragg graphics
- **Solution B** - If comfortable with MSYS2
- **Solution C** - Fastest, works for most scripts

---

### Issue 2: "There is no package called 'dplyr'"

**Error:**

```text
Error in library(dplyr) : there is no package called 'dplyr'
```

**Cause:** Core tidyverse packages not installed

**Solution: Direct Installation**

```r
# Install critical packages directly
install.packages(c(
  # Core tidyverse
  "dplyr", "tidyr", "readr", "purrr", "tibble", "stringr",

  # Project utilities
  "here", "broom", "ggplot2",

  # Modeling
  "lme4", "lmerTest", "emmeans", "car",

  # Data handling
  "mice", "janitor",

  # Reporting
  "knitr", "rmarkdown"
))

# Verify installation
library(dplyr)
library(here)
```

**Expected time:** 5-10 minutes

---

### Issue 3: "renv::restore() Hangs or Times Out"

**Symptoms:**

- restore() runs for hours without completing
- Download speeds very slow
- R session becomes unresponsive

**Solution A: Use Binary Packages**

```r
# Set repository to use binary packages (faster)
options(repos = c(
  CRAN = "https://cloud.r-project.org",
  P3M = "https://packagemanager.posit.co/cran/latest"
))

# Try restore again
renv::restore(prompt = FALSE)
```

**Solution B: Parallel Installation**

```r
# Install in parallel (faster on multi-core systems)
options(Ncpus = 4)  # Use 4 cores
renv::restore(prompt = FALSE)
```

**Solution C: Clean Start**

```r
# Clear renv cache and retry
renv::purge()
renv::restore(clean = TRUE, prompt = FALSE)
```

---

### Issue 4: "Package Versions Conflict"

**Error:**

```text
Error: package 'X' is not available for this version of R
Error: dependency 'Y' is not available
```

**Solution: Update renv and R**

```r
# Check R version
R.version.string  # Should be >= 4.4.0

# Update renv itself
install.packages("renv")

# Clear and retry
renv::clean()
renv::restore(rebuild = TRUE)
```

---

### Issue 5: "Permission Denied" Errors

**Error:**

```text
Warning: cannot remove prior installation of package 'X'
Error: ERROR: cannot remove earlier installation
```

**Solution: Run as Administrator**

1. Close R/RStudio
2. Right-click R/RStudio icon → "Run as administrator"
3. Retry installation

**Or fix permissions:**

```bash
# In Git Bash (as Administrator)
cd "C:/GitWork/Python-R-Scripts/Fear-of-Falling"
chmod -R u+w renv/library
```

---

## Complete Package Installation Recipes

### Recipe 1: Minimal Working Environment

**Goal:** Get K6-K16 scripts running ASAP

```r
# Essential packages only (~10 minutes)
essential <- c(
  "here", "dplyr", "tidyr", "readr", "ggplot2",
  "broom", "lme4", "emmeans", "knitr"
)

install.packages(essential)

# Verify
sapply(essential, require, character.only = TRUE)
```

### Recipe 2: Full Project Environment

**Goal:** Complete renv restoration with workarounds

```bash
# Step 1: Fix system dependencies (Git Bash as Admin)
pacman -S perl-Pod-Parser

# Step 2: In R
Rscript -e "
  options(repos = c(CRAN = 'https://cloud.r-project.org'))
  options(Ncpus = 4)
  renv::restore(prompt = FALSE)
"
```

### Recipe 3: Emergency Bypass

**Goal:** Run scripts without renv

```r
# Disable renv for this session
Sys.setenv(RENV_CONFIG_ACTIVE = FALSE)

# Install packages to user library
.libPaths()  # Check where packages will go

# Install everything you need
install.packages(c(
  "tidyverse", "here", "lme4", "lmerTest",
  "emmeans", "mice", "broom", "car",
  "knitr", "rmarkdown", "janitor"
))

# Now run scripts
source("R-scripts/K11/K11.R")
```

---

## Verification Steps

### After Any Fix

**1. Check renv status:**

```r
renv::status()
# Should show: "The project is already synchronized"
```

**2. Test package loading:**

```r
# Test critical packages
library(dplyr)
library(here)
library(lme4)
library(ggplot2)

# Should load without errors
```

**3. Run smoke test:**

```bash
cd Fear-of-Falling
Rscript tests/smoke_test_k6_k16.R
```

**Expected:** All or most scripts should pass

---

## Advanced Troubleshooting

### Debug Package Installation

```r
# Install single package with verbose output
install.packages("gdtools", verbose = TRUE, INSTALL_opts = "--no-multiarch")

# Check what failed
trace(utils:::install.packages, tracer = browser)
install.packages("gdtools")
```

### Check System Libraries

```bash
# Windows: Check if system libraries are found
pkg-config --list-all | grep cairo
pkg-config --list-all | grep freetype

# If not found, install via MSYS2:
pacman -S mingw-w64-x86_64-cairo
pacman -S mingw-w64-x86_64-freetype
```

### Inspect renv Cache

```r
# See what's in the cache
renv::cache_path()
list.files(renv::cache_path())

# Clear if corrupted
renv::purge()
```

---

## Platform-Specific Notes

### Windows (MSYS2/MinGW)

**Common Issues:**

- Perl module conflicts (Strawberry vs MSYS2)
- Missing system libraries (Cairo, FreeType)
- Path issues with spaces in directory names

**Best Practices:**

```bash
# Use MSYS2 package manager for system libs
pacman -S mingw-w64-x86_64-cairo
pacman -S mingw-w64-x86_64-freetype
pacman -S perl perl-Pod-Parser

# Ensure Rtools is in PATH
export PATH="/c/rtools44/x86_64-w64-mingw32.static.posix/bin:$PATH"
```

### Linux

**Usually smoother, but check:**

```bash
# Ubuntu/Debian
sudo apt-get install libcurl4-openssl-dev libssl-dev libxml2-dev
sudo apt-get install libcairo2-dev libfontconfig1-dev

# Fedora/RHEL
sudo dnf install libcurl-devel openssl-devel libxml2-devel
sudo dnf install cairo-devel fontconfig-devel
```

### macOS

**Usually works well, but:**

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install system dependencies via Homebrew
brew install cairo
brew install pkg-config
```

---

## When All Else Fails

### Nuclear Option: Fresh Start

```bash
# Backup your work first!
cd Fear-of-Falling

# Remove renv completely
rm -rf renv/
rm .Rprofile

# Reinstall renv
Rscript -e "install.packages('renv')"

# Initialize fresh
Rscript -e "renv::init()"

# Try restore
Rscript -e "renv::restore()"
```

### Docker Alternative

```dockerfile
# Use pre-configured R environment
FROM rocker/tidyverse:4.4.2

# Copy project files
WORKDIR /project
COPY renv.lock .

# Restore packages in container
RUN Rscript -e "install.packages('renv'); renv::restore()"

# Run scripts
CMD ["Rscript", "R-scripts/K11/K11.R"]
```

---

## Prevention Tips

### 1. Document Your System

Create `SYSTEM_SETUP.md`:

```markdown
# My R Environment

- OS: Windows 11
- R Version: 4.4.2
- Build Tools: Rtools44
- MSYS2 packages: cairo, freetype, perl
- Known issues: gdtools requires Pod::Usage
```

### 2. Use Binary Packages

```r
# Add to .Rprofile
options(repos = c(
  CRAN = "https://cloud.r-project.org",
  P3M = "https://packagemanager.posit.co/cran/latest"
))
```

### 3. Test Before Committing

```bash
# Always test renv after changes
renv::snapshot()
renv::restore(clean = TRUE)  # Test restore works
```

### 4. Keep renv Updated

```r
# Update renv regularly
install.packages("renv")
renv::upgrade()
```

---

## Quick Reference

| Problem | Quick Fix | Time |
|---------|-----------|------|
| Missing dplyr/here | `install.packages(c("dplyr","here"))` | 2 min |
| gdtools fails | `install.packages(setdiff(all, "gdtools"))` | 5 min |
| Slow restore | `options(Ncpus=4); renv::restore()` | 15 min |
| Permission error | Run R as Administrator | 1 min |
| Total failure | Use Docker or Option 2 from main doc | 30 min |

---

## Getting Help

### Check These First

1. `renv::diagnostics()` - Full system report
2. `sessionInfo()` - R and package versions
3. `.libPaths()` - Library locations
4. `Sys.getenv("PATH")` - System PATH

### Report Format

When asking for help, include:

```r
# Run this and include output
cat("R Version:", R.version.string, "\n")
cat("renv Version:", as.character(packageVersion("renv")), "\n")
cat("OS:", Sys.info()["sysname"], Sys.info()["release"], "\n")
renv::diagnostics()
```

---

**Last Updated:** 2025-12-21
**Version:** 1.0
**Related:** ENVIRONMENT_SETUP_ISSUES.md, SMOKE_TEST_REPORT_K6_K16.md
