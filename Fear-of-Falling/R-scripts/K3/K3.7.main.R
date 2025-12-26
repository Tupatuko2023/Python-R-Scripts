#!/usr/bin/env Rscript
# ==============================================================================
# K3_MAIN - Longitudinal Analysis Pipeline: Original Values by FOF Status
# File tag: K3_MAIN.V1_original-values.R
# Purpose: Complete analysis pipeline for original performance test values (not z-scores)
#
# Outcome: Original test values (MWS, FTSST, SLS, HGS) at baseline and 12-month follow-up
# Predictors: FOF_status (0/1), Age, Sex, BMI
# Moderator/interaction: None (main effects only)
# Grouping variable: FOF_status (kaatumisenpelkoOn: 0/1)
# Covariates: Age, Sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in subscripts):
# Same as K1 (shares K1.1.data_import.R):
# id, ToimintaKykySummary0, ToimintaKykySummary2, kaatumisenpelkoOn, age, sex, BMI
#
# Note: K3 differs from K1 by analyzing original values instead of z-scores
#       K3 shares K1.1 (data import) and K1.5 (skewness/kurtosis) with K1 pipeline
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: Not needed (no randomness in K3.4 effect sizes - formulaic Cohen's d)
#
# Outputs + manifest:
# - script_label: K3 (canonical)
# - outputs dir: R-scripts/K3/outputs/  (resolved via init_paths("K3"))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths) [DONE]
# 02) Load raw data (immutable; no edits) [K1.1 - SHARED]
# 03) Transform to original values (not z-scores) [K3.2]
# 04) Statistical tests on original values [K3.3]
# 05) Effect size calculations (Cohen's d) [K3.4]
# 06) Distributional checks (skewness/kurtosis) [K1.5 - SHARED]
# 07) Combine results and export table [K3.6]
# 08) Save artifacts -> R-scripts/K3/outputs/
# 09) Append manifest row per artifact [K3.6]
# 10) Save sessionInfo to manifest/ [K3.6]
# 11) EOF marker
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K3_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K3_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
# Map K3_MAIN or K3.7 to "K3" for outputs directory
if (grepl("^K3", script_label)) script_label <- "K3"
if (is.na(script_label) || script_label == "") script_label <- "K3"

# init_paths() must set outputs_dir + manifest_path (+ options fof.*)
source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K3 Pipeline - Longitudinal Analysis: Original Values by FOF Status\n")
cat("================================================================================\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# --- Pipeline Steps (absolute paths, no setwd) ------------------------------

cat("[Step 1/6] Data Import (SHARED from K1)...\n")
source(here::here("R-scripts", "K1", "K1.1.data_import.R"))

cat("[Step 2/6] Data Transformation (original values)...\n")
source(here::here("R-scripts", "K3", "K3.2.data_transformation.R"))

cat("[Step 3/6] Statistical Analysis...\n")
source(here::here("R-scripts", "K3", "K3.3.statistical_analysis.R"))

cat("[Step 4/6] Effect Size Calculations...\n")
source(here::here("R-scripts", "K3", "K3.4.effect_sizes.R"))

cat("[Step 5/6] Distributional Checks (SHARED from K1)...\n")
source(here::here("R-scripts", "K1", "K1.5.kurtosis_skewness.R"))

cat("[Step 6/6] Combine Results & Export...\n")
source(here::here("R-scripts", "K3", "K3.6.results_export.R"))

cat("\n================================================================================\n")
cat("K3 Pipeline completed successfully.\n")
cat("Outputs saved to:", outputs_dir, "\n")
cat("Manifest updated:", manifest_path, "\n")
cat("================================================================================\n")

# EOF
