#!/usr/bin/env Rscript
# ==============================================================================
# K1.1_IMPORT - Data Import and Preliminary Processing
# File tag: K1.1_IMPORT.V1_data-import.R
# Purpose: Import raw KaatumisenPelko dataset and verify structure
#
# Input: data/raw/KaatumisenPelko.csv (or dataset/KaatumisenPelko.csv fallback)
# Output: `data` object in R environment (raw, unprocessed)
#
# Required vars (raw data, DO NOT INVENT; must match req_cols):
# id, ToimintaKykySummary0, ToimintaKykySummary2, kaatumisenpelkoOn, age, sex, BMI
#
# Note: This script is shared by K3 pipeline (sourced from K3.7.main.R)
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(here)
})

# Required columns for raw data
req_cols <- c("id", "ToimintaKykySummary0", "ToimintaKykySummary2",
              "kaatumisenpelkoOn", "age", "sex", "BMI")

# Load raw data using helper with fallback logic
source(here::here("R", "functions", "io.R"))
data <- load_raw_data("KaatumisenPelko.csv")

# Verify required columns exist
missing_cols <- setdiff(req_cols, names(data))
if (length(missing_cols) > 0) {
  stop("Missing required columns in raw data: ", paste(missing_cols, collapse = ", "))
}

# Quick summary
cat("Raw data loaded successfully:\n")
cat("  Rows:", nrow(data), "\n")
cat("  Columns:", ncol(data), "\n")
cat("  Required columns present:", all(req_cols %in% names(data)), "\n")

# Note: Factor conversion is deferred to K1.2 (standardize_analysis_vars)
# This keeps K1.1 as a pure data import step

# EOF
