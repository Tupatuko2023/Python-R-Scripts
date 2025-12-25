#!/usr/bin/env Rscript
# ==============================================================================
# K3.4_EFFECT - Effect Size Calculations (Cohen's d, Original Values)
# File tag: K3.4_EFFECT.V1_effect-sizes.R
# Purpose: Compute Cohen's d effect sizes for baseline, change, and follow-up comparisons using original values
#
# Input: `df_wide`, `change_stats` objects from K3.2 and K3.3
# Output: Effect size objects (baseline_effect, change_effect, change_between_effect, follow_up_effect)
#
# Required vars (from df_wide, DO NOT INVENT; must match req_cols):
# kaatumisenpelkoOn, Test, Baseline, Follow_up
#
# Effect sizes computed:
# 1. Baseline Cohen's d (between-group comparison at baseline)
# 2. Change Cohen's d (within-group paired change: Follow_up - Baseline)
# 3. Change_between Cohen's d (between-group comparison of change)
# 4. Follow_up Cohen's d (between-group comparison at follow-up)
#
# Reproducibility:
# - No randomness currently used (formulaic Cohen's d calculations)
# - If bootstrap CI is added later, set seed: set.seed(20251124)
#
# Note: This is identical to K1.4 logic but operates on original values instead of z-scores
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
})

# Required columns from df_wide
req_cols <- c("kaatumisenpelkoOn", "Test", "Baseline", "Follow_up")

# Verify required objects and columns exist
if (!exists("df_wide")) {
  stop("df_wide object not found. Ensure K3.2.data_transformation.R has been sourced.")
}
if (!exists("change_stats")) {
  stop("change_stats object not found. Ensure K3.3.statistical_analysis.R has been sourced.")
}

missing_cols <- setdiff(req_cols, names(df_wide))
if (length(missing_cols) > 0) {
  stop("Missing required columns in df_wide: ", paste(missing_cols, collapse = ", "))
}

cat("Starting effect size calculations (original values)...\n")

# Function for calculating Cohen's d for independent groups
cohen_d_independent <- function(mean1, sd1, n1, mean2, sd2, n2) {
  # Calculate pooled standard deviation
  pooled_sd <- sqrt(((n1 - 1) * sd1^2 + (n2 - 1) * sd2^2) / (n1 + n2 - 2))
  # Compute Cohen's d as difference in means divided by pooled SD
  d <- (mean1 - mean2) / pooled_sd
  return(d)
}

# Function for calculating Cohen's d for paired tests (effect size for delta)
cohen_d_paired <- function(C_Mean, C_SD) {
  # Cohen's d = (mean change) / (SD of change)
  d <- C_Mean / C_SD
  return(d)
}

# Compute Baseline Cohen's d (Between-Group Baseline Comparison)
cat("  Computing baseline effect sizes (between-group)...\n")
baseline_effect <- df_wide %>%
  group_by(Test) %>%
  summarise(
    d = cohen_d_independent(
      mean(Baseline[kaatumisenpelkoOn == 0], na.rm = TRUE),
      sd(Baseline[kaatumisenpelkoOn == 0], na.rm = TRUE),
      sum(!is.na(Baseline[kaatumisenpelkoOn == 0])),
      mean(Baseline[kaatumisenpelkoOn == 1], na.rm = TRUE),
      sd(Baseline[kaatumisenpelkoOn == 1], na.rm = TRUE),
      sum(!is.na(Baseline[kaatumisenpelkoOn == 1]))
    ),
    .groups = "drop"
  ) %>%
  rename(Baseline_d = d)

# Compute Cohen's d for Change within Groups (Within-Group Follow_up Comparison)
cat("  Computing within-group change effect sizes (paired)...\n")
change_effect <- change_stats %>%
  mutate(Change_d = cohen_d_paired(C_Mean, C_SD)) %>%
  select(kaatumisenpelkoOn, Test, Change_d)

# Compute Cohen's d for Between-Group Change Comparison
cat("  Computing between-group change effect sizes...\n")
change_between_effect <- df_wide %>%
  group_by(Test) %>%
  summarise(
    d = cohen_d_independent(
      mean((Follow_up - Baseline)[kaatumisenpelkoOn == 0], na.rm = TRUE),
      sd((Follow_up - Baseline)[kaatumisenpelkoOn == 0], na.rm = TRUE),
      sum(!is.na(Follow_up[kaatumisenpelkoOn == 0]) & !is.na(Baseline[kaatumisenpelkoOn == 0])),
      mean((Follow_up - Baseline)[kaatumisenpelkoOn == 1], na.rm = TRUE),
      sd((Follow_up - Baseline)[kaatumisenpelkoOn == 1], na.rm = TRUE),
      sum(!is.na(Follow_up[kaatumisenpelkoOn == 1]) & !is.na(Baseline[kaatumisenpelkoOn == 1]))
    ),
    .groups = "drop"
  ) %>%
  rename(Change_d_between = d)

# Compute Cohen's d for Follow_up (Between-Group Follow_up Comparison)
cat("  Computing follow-up effect sizes (between-group)...\n")
follow_up_effect <- df_wide %>%
  group_by(Test) %>%
  summarise(
    Follow_up_d = cohen_d_independent(
      mean(Follow_up[kaatumisenpelkoOn == 0], na.rm = TRUE),
      sd(Follow_up[kaatumisenpelkoOn == 0], na.rm = TRUE),
      sum(!is.na(Follow_up[kaatumisenpelkoOn == 0])),
      mean(Follow_up[kaatumisenpelkoOn == 1], na.rm = TRUE),
      sd(Follow_up[kaatumisenpelkoOn == 1], na.rm = TRUE),
      sum(!is.na(Follow_up[kaatumisenpelkoOn == 1]))
    ),
    .groups = "drop"
  )

# Function for Labeling Effect Size
effect_size_label <- function(d_value) {
  if (is.na(d_value)) return("")   # If missing, return empty
  abs_d <- abs(d_value)             # Consider the magnitude for labeling
  if (abs_d >= 0.8) return("Large")
  else if (abs_d >= 0.5) return("Medium")
  else if (abs_d >= 0.2) return("Small")
  else return("Very Small")
}

# Label Effect Size for Follow_up Cohen's d
cat("  Adding effect size labels...\n")
follow_up_effect <- follow_up_effect %>%
  rowwise() %>%
  mutate(Follow_up_d_label = effect_size_label(Follow_up_d)) %>%
  ungroup()

# Preview results
cat("\nEffect size results (original values):\n")
cat("  Baseline effect sizes:\n")
print(baseline_effect)
cat("\n  Within-group change effect sizes:\n")
print(change_effect)
cat("\n  Between-group change effect sizes:\n")
print(change_between_effect)
cat("\n  Follow-up effect sizes:\n")
print(follow_up_effect)

cat("\nEffect size calculations (original values) completed successfully.\n")

# EOF
