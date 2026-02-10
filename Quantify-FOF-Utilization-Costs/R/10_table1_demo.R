#!/usr/bin/env Rscript
# ==============================================================================
# 10_table1_demo.R
# Purpose: Demonstrate analysis using the new data architecture (derived/table1_cohort.parquet).
# Outcome: Table 1 (Patient Characteristics)
#
# Data Source: DATA_ROOT/derived/table1_cohort.parquet
#
# Workflow:
# 01) Init paths
# 02) Load Derived Data (parquet)
# 03) Analysis / Reporting
# ==============================================================================

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
})

# Load common utilities
common_script <- file.path("R", "common.R")
if (!file.exists(common_script)) {
  common_script <- file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)[1])), "common.R")
}
if (file.exists(common_script)) {
  source(common_script)
} else {
  stop("common.R not found.")
}

DATA_ROOT <- ensure_data_root()

derived_path <- file.path(DATA_ROOT, "derived", "table1_cohort.parquet")
if (!file.exists(derived_path)) stop("derived/table1_cohort.parquet missing. Run ingest/build first.")

# --- Load Data ---
message("Loading derived cohort...")
df <- arrow::read_parquet(derived_path)

message("Data loaded: ", nrow(df), " rows.")

# --- Analysis (Simplified Demo) ---
# Check key variables
if (!all(c("FOF", "age", "sex", "frailty3") %in% names(df))) {
  stop("Missing expected columns in derived dataset.")
}

# Example Summary
message("\n--- Table 1 Summary (Demo) ---")
df %>%
  group_by(FOF) %>%
  summarise(
    N = n(),
    Age_Mean = mean(age, na.rm = TRUE),
    Sex_Prop_Female = mean(sex == 2, na.rm = TRUE), # Assuming 2=Female
    BMI_Mean = mean(bmi, na.rm = TRUE)
  ) %>%
  print()

message("\nFrailty Distribution by FOF:")
table(df$frailty3, df$FOF) %>% print()

message("\nAnalysis Complete.")
