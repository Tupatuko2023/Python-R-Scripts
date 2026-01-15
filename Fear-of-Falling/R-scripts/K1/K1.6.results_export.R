#!/usr/bin/env Rscript
# ==============================================================================
# K1.6_EXPORT - Combine Results and Export Final Table
# File tag: K1.6_EXPORT.V1_results-export.R
# Purpose: Merge all analysis results into final table and export with manifest logging
#
# Input: Multiple objects from K1.2-K1.5:
#   - baseline_stats, change_stats, follow_up_stats (from K1.3)
#   - p_values_baseline, p_values_within, df_change_p_value_between, follow_up_p_value (from K1.3)
#   - baseline_effect, change_effect, change_between_effect, follow_up_effect (from K1.4)
#   - skewness_label(), kurtosis_label() functions (from K1.5)
#   - effect_size_label() function (from K1.4)
#
# Output: final_table exported to R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv
#         with manifest logging and sessionInfo
#
# Final table columns (44 total):
# - kaatumisenpelkoOn, Test
# - Baseline: B_Mean, B_SD, B_n, B_SE, B_CI_lower, B_CI_upper, B_Skew, B_Skew_label,
#             B_Kurtosis, B_Kurtosis_label, Baseline_p_value, Baseline_p_value_sig,
#             Baseline_d, Baseline_d_label
# - Change: C_n, C_Mean, C_SD, C_SE, C_CI_lower, C_CI_upper, C_Skew, C_Skew_label,
#           C_Kurtosis, C_Kurtosis_label, Change_p_value, Change_p_value_sig,
#           Change_d, Change_d_label, Change_p_between, Change_p_between_sig,
#           Change_d_between, Change_d_between_label
# - Follow-up: F_Mean, F_SD, F_n, F_SE, F_CI_lower, F_CI_upper, F_Skew, F_Skew_label,
#              F_Kurtosis, F_Kurtosis_label, Follow_up_p_value, Follow_up_p_value_sig,
#              Follow_up_d, Follow_up_d_label
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(here)
})

# Load privacy utilities from the shared library
# Note: Path is relative to project root (Fear-of-Falling -> .. -> src)
shared_lib_path <- file.path("..", "src", "analytics", "privacy_utils.R")
if (file.exists(shared_lib_path)) {
  source(shared_lib_path)
} else {
  warning("Privacy utils not found at: ", shared_lib_path, ". SDC will not be applied.")
}

# Load reporting helpers (init_paths already called by K1.7.main.R)
source(here::here("R", "functions", "reporting.R"))

# Verify required objects exist
required_objects <- c("baseline_stats", "change_stats", "follow_up_stats",
                     "p_values_baseline", "p_values_within",
                     "df_change_p_value_between", "follow_up_p_value",
                     "baseline_effect", "change_effect",
                     "change_between_effect", "follow_up_effect")

missing_objects <- setdiff(required_objects, ls(envir = .GlobalEnv))
if (length(missing_objects) > 0) {
  stop("Missing required objects from previous steps: ", paste(missing_objects, collapse = ", "),
       "\nEnsure K1.2-K1.5 scripts have been sourced.")
}

# Verify helper functions exist
if (!exists("skewness_label") || !exists("kurtosis_label")) {
  stop("skewness_label() or kurtosis_label() not found. Ensure K1.5 has been sourced.")
}
if (!exists("effect_size_label")) {
  stop("effect_size_label() not found. Ensure K1.4 has been sourced.")
}

cat("Starting results export process...\n")

# Define Significance Label Function
significance_label <- function(p_value) {
  ifelse(is.na(p_value), "",
         ifelse(p_value < 0.001, "***",
                ifelse(p_value < 0.01, "**",
                       ifelse(p_value < 0.05, "*", "")
                )
         )
  )
}

# Combine Baseline, Change, and Follow-Up Statistics into a Final Table
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

# Merge Cohen's d Effect Sizes into the Final Table
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

# Add Follow_up Effect Size and Its Label
final_table <- final_table %>%
  left_join(follow_up_effect, by = "Test") %>%
  rowwise() %>%
  mutate(
    Follow_up_d_label = effect_size_label(Follow_up_d)
  ) %>%
  ungroup()

# Reorder and Finalize Columns for Clarity
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

cat("  Final table structure:\n")
cat("    Rows:", nrow(final_table), "\n")
cat("    Columns:", ncol(final_table), "\n")

# Apply Statistical Disclosure Control (SDC)
if (exists("suppress_small_cells")) {
  cat("  Applying SDC (suppressing small cells n < 5)...\n")
  final_table <- suppress_small_cells(final_table, ends_with("_n"), min_n = 5)
}

# Export with manifest logging (uses save_table_csv_html from reporting.R)
cat("  Saving final table to outputs directory...\n")
save_table_csv_html(
  final_table,
  label = "K1_Z_Score_Change_2G",
  n = nrow(final_table),
  write_html = FALSE  # Set TRUE if HTML output desired
)

# Save sessionInfo with manifest logging
cat("  Saving sessionInfo...\n")
save_sessioninfo_manifest()

cat("\nResults export completed successfully.\n")
cat("  Output file: R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv\n")
cat("  Manifest updated: manifest/manifest.csv\n")

# EOF
