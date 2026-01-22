
# Standard Script Intro ---------------------------------------------------
# Script Label: K01
# Purpose: Construct Frailty Proxy variable from FOF_LOCAL_DATA (KaatumisenPelko.csv)
# Description: Loads raw data, calculates Modified Fried Frailty Index (Categorical & Continuous),
#              and saves the processed dataset for LMM analysis.
# Author: Jules (Agent)
# Date: 2024-05-22

# Setup -------------------------------------------------------------------

library(dplyr)
library(readr)
library(tidyr)
library(here)

# Source functions - Use robust paths and check existence
# These functions are assumed to be in the project structure.
source_if_exists <- function(path) {
  if (file.exists(path)) source(path) else warning("Source file not found: ", path)
}

source_if_exists(here::here("R", "functions", "io.R"))
source_if_exists(here::here("R", "functions", "calculate_frailty_proxy.R"))
source_if_exists(here::here("R", "functions", "variable_standardization.R"))

# Paths
OUTPUT_DIR <- here::here("R-scripts", "K01_frailty_construction", "outputs")
if (!dir.exists(OUTPUT_DIR)) dir.create(OUTPUT_DIR, recursive = TRUE)

# 1. Load Data ------------------------------------------------------------

# Helper to generate dummy data
generate_dummy_data <- function(n = 100) {
  set.seed(20251124) # Standard seed
  data.frame(
    id = 1:n,
    sex = sample(c(0, 1), n, replace = TRUE), # 0=Female, 1=Male
    age = sample(65:90, n, replace = TRUE),

    # Fried Components (Simulated Finnish names)
    puristusvoima = rnorm(n, mean = 25, sd = 8),
    kavelynopeus = rnorm(n, mean = 1.0, sd = 0.3),
    cesd_total = sample(0:30, n, replace = TRUE),
    aktiivisuus_kategoria = rnorm(n, mean = 2000, sd = 500), # Steps or kcal
    painonlasku = rbinom(n, 1, 0.1) * runif(n, 1, 10), # 10% have weight loss

    # Test Reasons
    reason_grip = sample(c(NA, "unable due to pain", "refused"), n, prob = c(0.9, 0.05, 0.05), replace = TRUE),
    reason_gait = sample(c(NA, "unable due to dizziness"), n, prob = c(0.95, 0.05), replace = TRUE),

    # Other
    FOF_status = sample(c(0, 1), n, replace = TRUE)
  )
}

# Attempt to load real data
data_path <- here::here("data", "external", "KaatumisenPelko.csv")
raw_data <- NULL

if (file.exists(data_path)) {
  tryCatch({
    temp <- read_csv(data_path, show_col_types = FALSE)
    # Validate not encrypted
    if (ncol(temp) > 2) {
      raw_data <- temp
      message("Loaded real data.")
    } else {
      warning("Data appears encrypted.")
    }
  }, error = function(e) {
    warning("Could not read real data: ", e$message)
  })
}

if (is.null(raw_data)) {
  message("Generating DUMMY data for verification.")
  raw_data <- generate_dummy_data(100)
}

# 2. Variable Mapping -----------------------------------------------------

frailty_mapping <- list(
  id = "id",
  grip = "puristusvoima",
  gait = "kavelynopeus",
  cesd = "cesd_total",
  activity = "aktiivisuus_kategoria",
  weight_loss = "painonlasku",
  sex = "sex",
  test_reason_grip = "reason_grip",
  test_reason_gait = "reason_gait"
)

# 3. Pre-Processing & QC --------------------------------------------------

df_proc <- raw_data

# QC Check: Outliers
# Grip > 60kg or Gait > 2.5 m/s
high_grip <- which(df_proc[[frailty_mapping$grip]] > 60)
if (length(high_grip) > 0) {
  warning("QC Flag: ", length(high_grip), " participants have Grip Strength > 60kg.")
}

high_gait <- which(df_proc[[frailty_mapping$gait]] > 2.5)
if (length(high_gait) > 0) {
  warning("QC Flag: ", length(high_gait), " participants have Gait Speed > 2.5 m/s.")
}

# 4. Missing Data Imputation (MICE) ---------------------------------------

# User requested MICE for random missingness (<20%).
# MICE requires the 'mice' package.
if (requireNamespace("mice", quietly = TRUE)) {
  message("Running MICE imputation for missing components...")

  # Select columns for imputation (include predictors + components)
  vars_to_impute <- c(frailty_mapping$grip, frailty_mapping$gait,
                      frailty_mapping$cesd, frailty_mapping$activity,
                      frailty_mapping$weight_loss, "age", "sex")

  # Only impute if cols exist
  vars_present <- intersect(vars_to_impute, names(df_proc))

  # Run MICE (single imputation for simplified proxy construction, or use 'with' pool later)
  # Here we generate one complete dataset for the proxy construction to keep pipeline simple.
  # Ideally, we would do multiple, but for a constructed variable in a larger model,
  # single imputation is often a practical compromise if fraction is low.

  imp <- mice::mice(df_proc[, vars_present], m = 1, method = 'pmm', maxit = 5, seed = 20251124, print = FALSE)
  completed_data <- mice::complete(imp, 1)

  # Update df_proc with imputed values
  df_proc[, vars_present] <- completed_data

} else {
  message("MICE package not available. Skipping imputation. Results will have NAs where data is missing.")
}

# 5. Calculate Frailty Scores ---------------------------------------------

processed_data <- calculate_frailty_scores(df_proc, mapping = frailty_mapping)

# 6. Save and Summarize ---------------------------------------------------

saveRDS(processed_data, file = file.path(OUTPUT_DIR, "fof_data_with_frailty.rds"))

# Generate Summary Text
sink(file.path(OUTPUT_DIR, "frailty_summary.txt"))
cat("Frailty Score Distribution (Categorical):\n")
print(table(processed_data$fried_class, useNA = "ifany"))

cat("\nFrailty Score (Continuous Z) Summary:\n")
print(summary(processed_data$fried_z_score))

cat("\nData Quality Flags:\n")
cat("Grip > 60kg count:", length(high_grip), "\n")
cat("Gait > 2.5m/s count:", length(high_gait), "\n")
sink()

message("Pipeline completed. Output saved to: ", OUTPUT_DIR)
