#!/usr/bin/env Rscript
# ==============================================================================
# 00_setup.R
# Purpose: Initialize the R environment, check dependencies, and validate DATA_ROOT.
# usage: Rscript R/00_setup.R
# ==============================================================================

suppressPackageStartupMessages({
  library(utils)
})

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
  # Optional: install.packages(missing_packages)
  stop("Missing dependencies.")
}

message("All required packages are installed.")

# 2. Check DATA_ROOT
DATA_ROOT <- Sys.getenv("DATA_ROOT")
if (DATA_ROOT == "") {
  # Try to load from .env if possible (simple parser)
  if (file.exists("config/.env")) {
    lines <- readLines("config/.env")
    for (line in lines) {
      if (grepl("^DATA_ROOT=", line)) {
        DATA_ROOT <- sub("^DATA_ROOT=", "", line)
        Sys.setenv(DATA_ROOT = DATA_ROOT)
        message("Loaded DATA_ROOT from config/.env")
        break
      }
    }
  }
}

if (DATA_ROOT == "") {
  stop("DATA_ROOT environment variable is not set. Please set it or create config/.env.")
}

if (!dir.exists(DATA_ROOT)) {
  stop(paste("DATA_ROOT directory does not exist:", DATA_ROOT))
}

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
