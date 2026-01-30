# Task: Create R Analysis Scripts (Aim 2)

## Status

* **Source:** docs/analysis_plan.md
* **Target:** scripts/

## Instructions

Create the following R scripts in the `scripts/` directory. These scripts implement the pipeline defined in the Analysis Plan.

### 1. `scripts/00_setup_env.R`

(Helper to bootstrap dependencies)

```r
if (!require("renv", quietly = TRUE)) install.packages("renv")
# Initialize if not present, else restore
if (!file.exists("renv.lock")) {
  renv::init(bare = TRUE)
} else {
  renv::restore(prompt = FALSE)
}

# Install required packages
pkg_list <- c("tidyverse", "readr", "dplyr", "stringr", "MASS", "sandwich", "lmtest", "broom", "here")
renv::install(pkg_list, prompt = FALSE)
renv::snapshot(prompt = FALSE)
```

### 2. `scripts/10_build_panel_person_period.R`

(Reads raw data from DATA_ROOT, standardizes names, creates panel)

```r
#!/usr/bin/env Rscript
library(tidyverse)
library(readr)

# --- CONFIG ---
DATA_ROOT <- Sys.getenv("DATA_ROOT")
if (DATA_ROOT == "") stop("DATA_ROOT environment variable not set.")

# Load Standardization Map
std_map <- read_csv("data/VARIABLE_STANDARDIZATION.csv", show_col_types = FALSE)

# Helper to rename cols based on map
apply_standard_names <- function(df, dataset_label) {
  # Logic to map original_variable -> standard_variable for this dataset
  # Implementation placeholder: assumes df cols match 'original_variable' or similar
  # For now, simplistic rename or verify
  return(df)
}

message("Loading raw data from: ", DATA_ROOT)
# TODO: Add logic to read specific files (e.g. Hilmo, KAAOS) based on file map
# For this template, we assume input files are defined in a separate config or known paths

# Placeholder logic for panel construction
# 1. Load Baseline (MFFP)
# 2. Load Registry (Hilmo)
# 3. Create Person-Period frame (Yearly)
# 4. Join Outcomes & Covariates

# Save DERIVED dataset to DATA_ROOT (Secure location), NOT repo
derived_path <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")
dir.create(dirname(derived_path), showWarnings = FALSE, recursive = TRUE)
# write_csv(panel_df, derived_path)
message("Derived panel saved to: ", derived_path)
```

### 3. `scripts/20_qc_panel_summary.R`

(Reads derived panel, generates non-sensitive QC metadata to outputs/)

```r
#!/usr/bin/env Rscript
library(tidyverse)

DATA_ROOT <- Sys.getenv("DATA_ROOT")
panel_path <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")

if (!file.exists(panel_path)) stop("Panel data not found. Run script 10 first.")

panel <- read_csv(panel_path, show_col_types = FALSE)

# QC Metrics
qc_out <- list()
qc_out$n_ids <- n_distinct(panel$id)
qc_out$n_rows <- nrow(panel)
qc_out$missing_fof <- mean(is.na(panel$FOF_status))
qc_out$zeros_cost <- mean(panel$cost_total_eur == 0, na.rm = TRUE)

# Save QC Report (Safe for Repo)
write_lines(paste(names(qc_out), qc_out, sep=": "), "outputs/qc_summary_aim2.txt")
```

### 4. `scripts/30_models_panel_nb_gamma.R`

(The main analysis script as defined in Analysis Plan)

```r
#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(MASS)       # glm.nb
  library(sandwich)   # vcovCL
  library(lmtest)     # coeftest
  library(broom)      # tidy
})

# ... [Insert code content from docs/analysis_plan.md Section 6/Runbook] ...
# (Copy the specific R block from the Analysis Plan here)
```

## Action

1. Write these 4 files to the `scripts/` directory.
2. Ensure they are executable or runnable via `Rscript`.
