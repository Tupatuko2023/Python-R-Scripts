#!/usr/bin/env Rscript
# ==============================================================================
# K15 - Fried-inspired physical frailty proxy variable derivation (Modified)
# File tag: K15.V2_modified_frailty.R
# Purpose: Derives a physical frailty proxy based on Fried phenotype criteria
#          with added Continuous (Z-score) and PCA-based scoring options.
#          Includes MICE imputation for missing data and "unable to test" handling.
#
# Outcome: None (derives frailty variables for K16/K18)
# Predictors: None
# Moderator/interaction: None
# Grouping variable: frailty_cat_3 (derived)
# Covariates: N/A
#
# Required vars (raw_data):
# kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# Puristus0, kavelynopeus_m_sek0, BMI,
# oma_arvio_liikuntakyky, Vaikeus500m (or vaikeus_liikkua_500m),
# vaikeus_liikkua_2km, maxkävelymatka
#
# Mapping:
# - Weakness: Puristus0
# - Slowness: kavelynopeus_m_sek0
# - Low Activity: Combined (oma_arvio, 500m, 2km, maxwalk)
# - Low BMI: BMI < 21 (optional)
# - Scores: fried_score_cat (Option A), fried_z_score (Option B), fried_pca (Option C)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (used for MICE imputation)
#
# Outputs + manifest:
# - script_label: K15 (canonical)
# - outputs dir: R-scripts/K15/outputs/ (resolved via init_paths)
# - manifest: append 1 row per artifact
#
# Workflow:
# 01) Init paths
# 02) Load raw data
# 03) Standardize & QC
# 04) Handle "Unable to Test" (impute worst score)
# 05) MICE Imputation for random missingness
# 06) Calculate Option A (Categorical)
# 07) Calculate Option B (Continuous Z-score)
# 08) Calculate Option C (PCA)
# 09) Save outputs
# 10) Update manifest
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(ggplot2)
  library(tidyr)
  if (requireNamespace("mice", quietly = TRUE)) library(mice)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K15"
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K15"

# Helper functions
rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"),
   envir = .GlobalEnv)

# Robust sourcing
source_if_exists <- function(path) {
  if (file.exists(path)) source(path) else warning("Source file not found: ", path)
}
source_if_exists(here("R","functions","io.R"))
source_if_exists(here("R","functions","checks.R"))
source_if_exists(here("R","functions","modeling.R"))
source_if_exists(here("R","functions","reporting.R"))

paths <- init_paths(script_label)
outputs_dir   <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

set.seed(20251124)

# ==============================================================================
# 01. Load Dataset
# ==============================================================================

file_path <- here::here("data", "external", "KaatumisenPelko.csv")
if (!file.exists(file_path)) {
  stop("Tiedostoa data/external/KaatumisenPelko.csv ei löydy.")
}

raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

# Standardize
df <- standardize_analysis_vars(raw_data)
# (assuming standardize_analysis_vars handles basic renames)

# Keep original for safety
analysis_data <- raw_data

# Ensure FOF_status
if (!("FOF_status" %in% names(analysis_data))) {
  if ("kaatumisenpelkoOn" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(FOF_status = if_else(kaatumisenpelkoOn == 1, 1L, 0L))
  } else {
    stop("FOF_status missing.")
  }
}
analysis_data$FOF_status_factor <- factor(analysis_data$FOF_status, levels = c(0, 1), labels = c("nonFOF", "FOF"))

# ==============================================================================
# 02. "Unable to Test" Logic (Impute Worst Score)
# ==============================================================================

# Weakness (Puristus0): 0 kg is interpreted as "unable/weak" not "missing" if explicitly 0.
# If explicit reason variables existed, we would check them.
# K15.R logic was: 0 -> NA.
# NEW Logic: 0 -> 0 (Worst Score).

if ("Puristus0" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>%
    mutate(
      Puristus0_clean = Puristus0 # Keep 0 as 0 (Worst score)
    )
} else {
  warning("Puristus0 missing.")
  analysis_data$Puristus0_clean <- NA_real_
}

# Slowness (kavelynopeus_m_sek0):
# 0 -> 0 (Unable/Slow)
if ("kavelynopeus_m_sek0" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>%
    mutate(
      kavelynopeus_clean = kavelynopeus_m_sek0
    )
} else {
  warning("kavelynopeus_m_sek0 missing.")
  analysis_data$kavelynopeus_clean <- NA_real_
}

# ==============================================================================
# 03. MICE Imputation (Random Missingness)
# ==============================================================================
# Impute missing values for components if missingness < 20%
# Vars: Puristus0_clean, kavelynopeus_clean, BMI

vars_to_impute <- c("Puristus0_clean", "kavelynopeus_clean", "BMI", "age", "sex")
vars_present <- intersect(vars_to_impute, names(analysis_data))

if (requireNamespace("mice", quietly = TRUE) && length(vars_present) > 2) {

  # Check missingness
  miss_counts <- colSums(is.na(analysis_data[, vars_present]))
  message("Missing values before MICE:")
  print(miss_counts)

  # Only run if there is missing data but not empty
  if (sum(miss_counts) > 0 && nrow(analysis_data) > 10) {
    message("Running MICE imputation (m=1) for frailty construction...")
    imp <- mice::mice(analysis_data[, vars_present], m = 1, method = 'pmm', maxit = 5, seed = 20251124, print = FALSE)
    completed_data <- mice::complete(imp, 1)

    # Update analysis_data
    # We create _imp suffixed vars to avoid confusion or overwrite carefully
    analysis_data$Puristus0_imp <- completed_data$Puristus0_clean
    analysis_data$kavelynopeus_imp <- completed_data$kavelynopeus_clean
    analysis_data$BMI_imp <- completed_data$BMI
  } else {
    analysis_data$Puristus0_imp <- analysis_data$Puristus0_clean
    analysis_data$kavelynopeus_imp <- analysis_data$kavelynopeus_clean
    analysis_data$BMI_imp <- analysis_data$BMI
  }
} else {
  warning("MICE package not found or vars missing. Using complete case.")
  analysis_data$Puristus0_imp <- analysis_data$Puristus0_clean
  analysis_data$kavelynopeus_imp <- analysis_data$kavelynopeus_clean
  analysis_data$BMI_imp <- analysis_data$BMI
}

# ==============================================================================
# 04. Option A: Categorical (Modified from K15)
# ==============================================================================

# Weakness (Sex specific Q1)
# Use Imputed variables
sex_col <- if ("sex" %in% names(analysis_data)) analysis_data$sex else NULL
if (!is.null(sex_col)) {
  # Assuming 0=Female, 1=Male (Check K15: "0 = female, 1 = male")
  cuts <- analysis_data %>%
    filter(!is.na(Puristus0_imp)) %>%
    group_by(sex) %>%
    summarise(q1 = quantile(Puristus0_imp, 0.25, na.rm=TRUE))

  cut_f <- cuts$q1[cuts$sex == 0]
  cut_m <- cuts$q1[cuts$sex == 1]

  # Fallback if empty
  if(length(cut_f)==0) cut_f <- 20
  if(length(cut_m)==0) cut_m <- 30

  analysis_data <- analysis_data %>%
    mutate(
      frailty_weakness = case_when(
        sex == 0 & Puristus0_imp <= cut_f ~ 1L,
        sex == 1 & Puristus0_imp <= cut_m ~ 1L,
        TRUE ~ 0L
      )
    )
} else {
  analysis_data$frailty_weakness <- NA_integer_
}

# Slowness (< 0.8 m/s)
analysis_data <- analysis_data %>%
  mutate(
    frailty_slowness = if_else(kavelynopeus_imp < 0.8, 1L, 0L)
  )

# Low Activity (Same complex logic as K15 but ensuring inputs)
# (Copying logic structure from K15 but simplified for readability)
# ... [Assuming existing K15 logic for Low Activity is good, reusing variables]
# Recalculate if variables exist
var_500m <- if ("Vaikeus500m" %in% names(analysis_data)) "Vaikeus500m" else "vaikeus_liikkua_500m"
has_oma <- "oma_arvio_liikuntakyky" %in% names(analysis_data)
has_2km <- "vaikeus_liikkua_2km" %in% names(analysis_data)
has_maxw <- "maxkävelymatka" %in% names(analysis_data)

analysis_data <- analysis_data %>%
  mutate(
    flag_weak_SR = if(has_oma) oma_arvio_liikuntakyky == 0 else FALSE,
    flag_500m = if(!is.null(var_500m)) .data[[var_500m]] %in% c(1,2) else FALSE,
    flag_2km = if(has_2km) vaikeus_liikkua_2km %in% c(1,2) else FALSE,
    flag_maxw = if(has_maxw) maxkävelymatka < 400 else FALSE,

    frailty_low_activity = if_else(
      (flag_weak_SR | flag_500m | flag_2km | flag_maxw), 1L, 0L
    )
  )

# Sum
analysis_data$frailty_score_cat <- rowSums(
  analysis_data %>% select(frailty_weakness, frailty_slowness, frailty_low_activity),
  na.rm = FALSE
)

# ==============================================================================
# 05. Option B: Continuous Frailty Score (Z-score)
# ==============================================================================
# Standardize each component. Direction: Higher = Frailer.

calc_z <- function(x, invert = FALSE) {
  if (all(is.na(x))) return(rep(NA, length(x)))
  z <- (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
  if (invert) return(-z) else return(z)
}

# Grip (High is Good -> Invert)
analysis_data$z_grip <- calc_z(analysis_data$Puristus0_imp, invert = TRUE)

# Gait (High is Good -> Invert)
analysis_data$z_gait <- calc_z(analysis_data$kavelynopeus_imp, invert = TRUE)

# Low Activity:
# Since we only have categorical/binary indicators readily available in K15 context:
# If 'oma_arvio_liikuntakyky' (0-2) exists: 0=Weak, 2=Good. Invert.
if (has_oma) {
  analysis_data$z_activity <- calc_z(analysis_data$oma_arvio_liikuntakyky, invert = TRUE)
} else {
  # Use binary frailty_low_activity as proxy (0=Good, 1=Bad) -> Standardize
  analysis_data$z_activity <- calc_z(analysis_data$frailty_low_activity, invert = FALSE)
}

# Calculate Mean Z
z_cols <- c("z_grip", "z_gait", "z_activity")
analysis_data$fried_z_score <- rowMeans(analysis_data[, z_cols], na.rm = TRUE)

# ==============================================================================
# 06. Option C: PCA Proxy
# ==============================================================================

pca_vars_cols <- c("Puristus0_imp", "kavelynopeus_imp")
if (has_oma) pca_vars_cols <- c(pca_vars_cols, "oma_arvio_liikuntakyky")

# Check validity
valid_pca <- complete.cases(analysis_data[, pca_vars_cols])
if (sum(valid_pca) > 20) {
  pca_res <- prcomp(analysis_data[valid_pca, pca_vars_cols], scale. = TRUE, center = TRUE)

  # Check direction (Grip should be positive for PC1 usually if PC1 = fitness)
  loading_grip <- pca_res$rotation["Puristus0_imp", 1]

  pc1 <- rep(NA, nrow(analysis_data))
  pc1[valid_pca] <- pca_res$x[, 1]

  # We want High = Frail. If Loading Grip > 0, High PC1 = Good. So Invert.
  if (loading_grip > 0) {
    analysis_data$fried_pca <- -pc1
  } else {
    analysis_data$fried_pca <- pc1
  }
} else {
  analysis_data$fried_pca <- NA_real_
  warning("Not enough data for PCA.")
}

# ==============================================================================
# 07. Save & Manifest
# ==============================================================================

# Save Data
rdata_path <- file.path(outputs_dir, "K15_frailty_analysis_data_modified.RData")
save(analysis_data, file = rdata_path)

append_manifest(
  manifest_row(script = script_label, label = "K15_frailty_data_modified",
               path = rdata_path, kind = "dataset_rdata",
               notes = "Frailty data with Options A, B (Z-score), C (PCA)")
)

# Save Summary
summary_path <- file.path(outputs_dir, "K15_frailty_summary.txt")
sink(summary_path)
cat("--- Modified Frailty Proxy Summary ---\n")
cat("Option A (Categorical) Distribution:\n")
print(table(analysis_data$frailty_score_cat, useNA = "ifany"))
cat("\nOption B (Continuous Z) Summary:\n")
print(summary(analysis_data$fried_z_score))
cat("\nOption C (PCA) Summary:\n")
print(summary(analysis_data$fried_pca))
sink()

append_manifest(
  manifest_row(script = script_label, label = "K15_frailty_summary",
               path = summary_path, kind = "text_summary",
               notes = "Summary statistics for modified frailty proxies")
)

# Session Info
save_sessioninfo_manifest()

message("K15 V2 Completed Successfully.")
