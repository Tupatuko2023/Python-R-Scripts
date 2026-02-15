#!/usr/bin/env Rscript
# ==============================================================================
# 00_setup.R
# Purpose: Initialize the R environment, check dependencies, and validate DATA_ROOT.
# usage: Rscript R/00_setup.R
# ==============================================================================

suppressPackageStartupMessages({
  library(utils)
})

# Load common utilities
# Try loading common.R relative to script location or current directory
common_script_locations <- c(
  file.path("R", "common.R"),
  file.path(getwd(), "R", "common.R"),
  # If run from R directory
  file.path("common.R")
)

found_common <- FALSE
for (loc in common_script_locations) {
  if (file.exists(loc)) {
    source(loc)
    found_common <- TRUE
    break
  }
}

if (!found_common) {
  stop("Could not find R/common.R. Please run from project root.")
}

# 1. Check for required packages
required_packages <- c(
  "dplyr",
  "readr",
  "readxl",
  "arrow",
  "yaml",
  "testthat",
  "stringr",
  "tidyr"
)

missing_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]

if (length(missing_packages) > 0) {
  message("Missing required packages: ", paste(missing_packages, collapse = ", "))
  message("Please install them using renv::restore() or install.packages().")
  stop("Missing dependencies.")
}

message("All required packages are installed.")

# 2. Check DATA_ROOT (using common.R)
DATA_ROOT <- ensure_data_root()

message("DATA_ROOT is valid: ", DATA_ROOT)

# 3. Create directory structure in DATA_ROOT if missing (for dev/test convenience)
dirs <- c("raw", "staging", "derived", "manifest")
for (d in dirs) {
  path <- file.path(DATA_ROOT, d)
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
    message("Created directory: ", path)
  }
}

message("Setup complete.")
