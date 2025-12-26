#!/usr/bin/env Rscript
# ==============================================================================
# K1_MAIN - Longitudinal Analysis Pipeline: Z-Score Change by FOF Status
# File tag: K1_MAIN.V1_zscore-change.R
# Purpose: Complete analysis pipeline for z-score changes in physical performance tests
#
# Outcome: Delta_Composite_Z (12-month change in composite z-score)
# Predictors: FOF_status (0/1), Age, Sex, BMI
# Moderator/interaction: None (main effects only)
# Grouping variable: FOF_status_f (Ei FOF, FOF)
# Covariates: Age, Sex, BMI, Composite_Z0 (baseline)
#
# Required vars (DO NOT INVENT; must match req_cols check in subscripts):
# id, ToimintaKykySummary0, ToimintaKykySummary2, kaatumisenpelkoOn, age, sex, BMI
#
# Mapping example (raw -> analysis; handled in K1.2):
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z2
# Delta_Composite_Z = Composite_Z2 - Composite_Z0
# kaatumisenpelkoOn (0/1) -> FOF_status (numeric), FOF_status_f (factor)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (set in K1.4.effect_sizes.R for bootstrap CI)
#
# Outputs + manifest:
# - script_label: K1 (canonical)
# - outputs dir: R-scripts/K1/outputs/  (resolved via init_paths("K1"))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths) [DONE]
# 02) Load raw data (immutable; no edits) [K1.1]
# 03) Standardize vars + QC (sanity checks early) [K1.2]
# 04) Derive/rename vars (document mapping) [K1.2]
# 05) Prepare analysis dataset (complete-case) [K1.2]
# 06) Fit models and compute statistics [K1.3]
# 07) Effect size calculations (bootstrap CI) [K1.4 with set.seed]
# 08) Distributional checks (skewness/kurtosis) [K1.5]
# 09) Combine results and export table [K1.6]
# 10) Save artifacts -> R-scripts/K1/outputs/ [K1.6]
# 11) Append manifest row per artifact [K1.6]
# 12) Save sessionInfo to manifest/ [K1.6]
# 13) EOF marker
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K1_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K1_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
# Map K1_MAIN or K1.7 to "K1" for outputs directory
if (grepl("^K1", script_label)) script_label <- "K1"
if (is.na(script_label) || script_label == "") script_label <- "K1"

# init_paths() must set outputs_dir + manifest_path (+ options fof.*)
source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K1 Pipeline - Longitudinal Analysis: Z-Score Change by FOF Status\n")
cat("================================================================================\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# --- Pipeline Steps (absolute paths, no setwd) ------------------------------

cat("[Step 1/6] Data Import...\n")
source(here::here("R-scripts", "K1", "K1.1.data_import.R"))

cat("[Step 2/6] Data Transformation & QC...\n")
source(here::here("R-scripts", "K1", "K1.2.data_transformation.R"))

cat("[Step 3/6] Statistical Analysis...\n")
source(here::here("R-scripts", "K1", "K1.3.statistical_analysis.R"))

cat("[Step 4/6] Effect Size Calculations (bootstrap)...\n")
source(here::here("R-scripts", "K1", "K1.4.effect_sizes.R"))

cat("[Step 5/6] Distributional Checks (skewness/kurtosis)...\n")
source(here::here("R-scripts", "K1", "K1.5.kurtosis_skewness.R"))

cat("[Step 6/6] Combine Results & Export...\n")
source(here::here("R-scripts", "K1", "K1.6.results_export.R"))

cat("\n================================================================================\n")
cat("K1 Pipeline completed successfully.\n")
cat("Outputs saved to:", outputs_dir, "\n")
cat("Manifest updated:", manifest_path, "\n")
cat("================================================================================\n")

# EOF
