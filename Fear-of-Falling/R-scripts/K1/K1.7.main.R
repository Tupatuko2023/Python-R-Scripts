#!/usr/bin/env Rscript
################################################################################
# KAAOS 1.7: Main Script for Longitudinal Analysis Pipeline of
# Fear of Falling & Functional Performance
# [K1.7.main.R]

# "Executes a full analysis pipeline: imports & preprocesses data,
#  transforms it, computes stats & effect sizes, merges results,
#  and exports CSV"

################################################################################
#  Sequence list
################################################################################
# 1: Set project paths using here
# 2: Data Import and Preliminary Processing
# 3: Data Transformation
# 4: Statistical Analysis
# 5: Effect Size Calculations and Helper Functions
# 6: Skewness and Kurtosis Helper Functions
# 7: Combining and Exporting Results
# 8: End of Main Script
################################################################################

# 1: Set project paths using here -----------------------------------------

suppressPackageStartupMessages({
  library(here)
})

# Debug print
cat("Project root detected by here():", here::here(), "\n")

# Siirrytään K1-kansioon suhteessa projektijuureen:
# C:/GitWork/Python-R-Scripts/Fear-of-Falling/R-scripts/K1
k1_dir <- here::here("R-scripts", "K1")
setwd(k1_dir)

cat("Working directory set to:", getwd(), "\n")


# 2: Data Import and Preliminary Processing -------------------------------

# K1.1.data_import.R imports and preprocesses the KaatumisenPelko data

source("K1.1.data_import.R")

# 3: Data Transformation ---------------------------------------------------

source("K1.2.data_transformation.R")

# 4: Statistical Analysis --------------------------------------------------

source("K1.3.statistical_analysis.R")

# 5: Effect Size Calculations and Helper Functions ------------------------

source("K1.4.effect_sizes.R")

# 6: Skewness and Kurtosis Helper Functions -------------------------------

source("K1.5.kurtosis_skewness.R")

# 7: Combining and Exporting Results --------------------------------------

source("K1.6.results_export.R")

# 8: End of Main Script ----------------------------------------------------

cat("Analysis pipeline completed successfully.\n")
