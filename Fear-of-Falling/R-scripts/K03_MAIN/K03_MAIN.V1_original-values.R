#!/usr/bin/env Rscript
# ==============================================================================
# K03_MAIN - Longitudinal Analysis Pipeline: Original Values by FOF Status
# File tag: K03_MAIN.V1_original-values.R
# Purpose: Run the K3 pipeline in a repo-runner-ready wrapper with K03 outputs
#
# Outcome: Original test values (MWS, FTSST, SLS, HGS) at baseline and 12-month follow-up
# Predictors: FOF_status (0/1), Age, Sex, BMI
# Moderator/interaction: None (main effects only)
# Grouping variable: FOF_status (kaatumisenpelkoOn: 0/1)
# Covariates: Age, Sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in subscripts):
# id, ToimintaKykySummary0, ToimintaKykySummary2, kaatumisenpelkoOn, age, sex, BMI
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: Not needed (no randomness in K3.4 effect sizes - formulaic Cohen's d)
#
# Outputs + manifest:
# - script_label: K03_MAIN (canonical)
# - outputs dir: R-scripts/K03_MAIN/outputs/  (resolved via init_paths(script_label))
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
  "K03_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K03_MAIN"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K03 Pipeline - Longitudinal Analysis: Original Values by FOF Status\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

cat("[Step 1/6] Data Import (shared from K1)...\n")
source(here::here("R-scripts", "K1", "K1.1.data_import.R"))

cat("[Step 2/6] Data Transformation (original values)...\n")
source(here::here("R-scripts", "K3", "K3.2.data_transformation.R"))

cat("[Step 3/6] Statistical Analysis...\n")
source(here::here("R-scripts", "K3", "K3.3.statistical_analysis.R"))

cat("[Step 4/6] Effect Size Calculations...\n")
source(here::here("R-scripts", "K3", "K3.4.effect_sizes.R"))

cat("[Step 5/6] Distributional Checks (shared from K1)...\n")
source(here::here("R-scripts", "K1", "K1.5.kurtosis_skewness.R"))

cat("[Step 6/6] Combine Results & Export...\n")
source(here::here("R-scripts", "K3", "K3.6.results_export.R"))

cat("\n================================================================================\n")
cat("K03 Pipeline completed successfully.\n")
cat("Outputs saved to:", outputs_dir, "\n")
cat("Manifest updated:", manifest_path, "\n")
cat("================================================================================\n")

# EOF
