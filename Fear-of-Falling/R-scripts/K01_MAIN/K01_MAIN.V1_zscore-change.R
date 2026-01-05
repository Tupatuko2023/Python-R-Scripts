#!/usr/bin/env Rscript
# ==============================================================================
# K01_MAIN - Longitudinal Analysis Pipeline: Z-Score Change by FOF Status
# File tag: K01_MAIN.V1_zscore-change.R
# Purpose: Run the K1 pipeline in a repo-runner-ready wrapper with K01 outputs
#
# Outcome: Delta_Composite_Z (12-month change in composite z-score)
# Predictors: FOF_status (0/1), Age, Sex, BMI
# Moderator/interaction: None (main effects only)
# Grouping variable: FOF_status_f (Ei FOF, FOF)
# Covariates: Age, Sex, BMI, Composite_Z0 (baseline)
#
# Required vars (DO NOT INVENT; must match req_cols in K1 subscripts):
# id, ToimintaKykySummary0, ToimintaKykySummary2, kaatumisenpelkoOn, age, sex, BMI
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (set in K1.4.effect_sizes.R for bootstrap CI)
#
# Outputs + manifest:
# - script_label: K01_MAIN (canonical)
# - outputs dir: R-scripts/K01_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K01_MAIN"
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K01_MAIN"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K01 Pipeline - Longitudinal Analysis: Z-Score Change by FOF Status\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

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
cat("K01 Pipeline completed successfully.\n")
cat("Outputs saved to:", outputs_dir, "\n")
cat("Manifest updated:", manifest_path, "\n")
cat("================================================================================\n")

# EOF
