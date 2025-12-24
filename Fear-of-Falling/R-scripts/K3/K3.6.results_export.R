#!/usr/bin/env Rscript
# ==============================================================================
# K3.6_EXPORT - Results Export & Manifest Logging (Original Values)
# File tag: K3.6_EXPORT.V1_results-export.R
# Purpose: Combine baseline, change, and follow-up statistics with effect sizes, export final table
#
# Input: Statistical objects from K3.2, K3.3, K3.4 (baseline_stats, change_stats, follow_up_stats,
#        p-values, effect sizes) and helper functions from K1.5 (skewness_label, kurtosis_label)
# Output: Final combined table saved as CSV with manifest logging
#
# Required vars (objects from prior scripts, DO NOT INVENT):
# From K3.3: baseline_stats, change_stats, follow_up_stats, p_values_baseline, p_values_within,
#            df_change_p_value_between, follow_up_p_value
# From K3.4: baseline_effect, change_effect, change_between_effect, follow_up_effect, effect_size_label()
# From K1.5: skewness_label(), kurtosis_label()
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: Not needed (no randomness; data merging only)
#
# Outputs + manifest:
# - script_label: K3 (canonical; set by K3.7.main.R)
# - outputs dir: R-scripts/K3/outputs/ (resolved via init_paths in K3.7.main.R)
# - manifest: append 1 row for CSV + 1 row for sessionInfo to manifest/manifest.csv
#
# Note: This is identical to K1.6 logic but operates on original values instead of z-scores
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(here)
})

# Source reporting helpers (save_table_csv_html, save_sessioninfo_manifest)
source(here::here("R", "functions", "reporting.R"))

cat("Starting results export process...\n")

# Verify required objects exist (from K3.2, K3.3, K3.4)
required_objects <- c(
  "baseline_stats", "change_stats", "follow_up_stats",
  "p_values_baseline", "p_values_within", "df_change_p_value_between", "follow_up_p_value",
  "baseline_effect", "change_effect", "change_between_effect", "follow_up_effect"
)

missing_objects <- setdiff(required_objects, ls(envir = .GlobalEnv))
if (length(missing_objects) > 0) {
  stop("Missing required objects: ", paste(missing_objects, collapse = ", "),
       "\nEnsure K3.2, K3.3, and K3.4 have been sourced successfully.")
}

# Verify helper functions exist (from K3.4 and K1.5)
required_functions <- c("effect_size_label", "skewness_label", "kurtosis_label")
missing_functions <- sapply(required_functions, function(fn) !exists(fn, mode = "function"))
if (any(missing_functions)) {
  stop("Missing required functions: ", paste(names(missing_functions)[missing_functions], collapse = ", "),
       "\nEnsure K3.4 and K1.5 have been sourced successfully.")
}

# Define significance label function (local helper)
significance_label <- function(p_value) {
  ifelse(is.na(p_value), "",
         ifelse(p_value < 0.001, "***",
                ifelse(p_value < 0.01, "**",
                       ifelse(p_value < 0.05, "*", "")
                )
         )
  )
}

# Merge baseline, change, and follow-up statistics
cat("  Merging baseline, change, and follow-up statistics...\n")
final_table <- baseline_stats %>%
  left_join(p_values_baseline, by = "Test") %>%
  left_join(change_stats, by = c("kaatumisenpelkoOn", "Test")) %>%
  left_join(p_values_within, by = c("kaatumisenpelkoOn", "Test"), relationship = "many-to-many") %>%
  left_join(df_change_p_value_between, by = "Test") %>%
  left_join(follow_up_stats, by = c("kaatumisenpelkoOn", "Test")) %>%
  left_join(follow_up_p_value, by = "Test") %>%
  # Convert p-values to numeric and add significance labels
  mutate(
    Baseline_p_value = as.numeric(Baseline_p_value),
    Change_p_value = as.numeric(Change_p_value),
    Change_p_between = as.numeric(Change_p_between),
    Follow_up_p_value = as.numeric(Follow_up_p_value)
  ) %>%
  rowwise() %>%
  mutate(
    Baseline_p_value_sig = significance_label(Baseline_p_value),
    Change_p_value_sig = significance_label(Change_p_value),
    Change_p_between_sig = significance_label(Change_p_between),
    Follow_up_p_value_sig = significance_label(Follow_up_p_value),
    # Add skewness and kurtosis interpretation labels
    B_Skew_label = skewness_label(B_Skew),
    B_Kurtosis_label = kurtosis_label(B_Kurtosis),
    C_Skew_label = skewness_label(C_Skew),
    C_Kurtosis_label = kurtosis_label(C_Kurtosis),
    F_Skew_label = skewness_label(F_Skew),
    F_Kurtosis_label = kurtosis_label(F_Kurtosis)
  ) %>%
  ungroup()

# Merge effect sizes
cat("  Merging effect sizes...\n")
final_table <- final_table %>%
  left_join(baseline_effect, by = "Test") %>%
  left_join(change_effect, by = c("kaatumisenpelkoOn", "Test")) %>%
  left_join(change_between_effect, by = "Test") %>%
  rowwise() %>%
  mutate(
    Baseline_d_label = effect_size_label(Baseline_d),
    Change_d_label = effect_size_label(Change_d),
    Change_d_between_label = effect_size_label(Change_d_between)
  ) %>%
  ungroup()

# Add follow-up effect sizes
final_table <- final_table %>%
  left_join(follow_up_effect, by = "Test") %>%
  rowwise() %>%
  mutate(
    Follow_up_d_label = effect_size_label(Follow_up_d)
  ) %>%
  ungroup()

# Reorder columns for clarity
cat("  Reordering columns...\n")
final_table <- final_table %>%
  select(
    kaatumisenpelkoOn, Test,
    B_Mean, B_SD, B_n, B_SE, B_CI_lower, B_CI_upper,
    B_Skew, B_Skew_label, B_Kurtosis, B_Kurtosis_label,
    Baseline_p_value, Baseline_p_value_sig, Baseline_d, Baseline_d_label,
    C_n, C_Mean, C_SD, C_SE, C_CI_lower, C_CI_upper,
    C_Skew, C_Skew_label, C_Kurtosis, C_Kurtosis_label,
    Change_p_value, Change_p_value_sig, Change_d, Change_d_label,
    Change_p_between, Change_p_between_sig, Change_d_between, Change_d_between_label,
    F_Mean, F_SD, F_n, F_SE, F_CI_lower, F_CI_upper,
    F_Skew, F_Skew_label, F_Kurtosis, F_Kurtosis_label,
    Follow_up_p_value, Follow_up_p_value_sig, Follow_up_d, Follow_up_d_label
  )

# Preview final table structure
cat("  Final table structure:\n")
cat("    Rows:", nrow(final_table), "\n")
cat("    Columns:", ncol(final_table), "\n")

# Save final table with manifest logging
cat("  Saving final table to outputs directory...\n")
save_table_csv_html(
  final_table,
  label = "K3_Values_2G",
  n = nrow(final_table),
  write_html = FALSE
)

# Save sessionInfo with manifest logging
cat("  Saving sessionInfo...\n")
save_sessioninfo_manifest()

cat("\nResults export completed successfully.\n")
cat("  Output file:", file.path(outputs_dir, "K3_Values_2G.csv"), "\n")
cat("  Manifest updated:", manifest_path, "\n")

# EOF
