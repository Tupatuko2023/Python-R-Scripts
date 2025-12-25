#!/usr/bin/env Rscript
# ==============================================================================
# K1.3_STATS - Statistical Analysis & Group Comparisons
# File tag: K1.3_STATS.V1_statistical-analysis.R
# Purpose: Compute summary statistics and perform t-tests for group comparisons
#
# Input: `df_wide` object from K1.2 (wide format with Baseline and Follow_up columns)
# Output: Multiple summary and p-value objects (baseline_stats, change_stats, follow_up_stats, p-values)
#
# Required vars (from df_wide, DO NOT INVENT; must match req_cols):
# kaatumisenpelkoOn, Test, Baseline, Follow_up
#
# Analyses performed:
# 1. Baseline summary stats (mean, SD, CI, skewness, kurtosis) by group and test
# 2. Change summary stats (Follow_up - Baseline) by group and test
# 3. Follow-up summary stats by group and test
# 4. Between-group t-test for Baseline (by test)
# 5. Within-group paired t-test for Baseline vs Follow_up
# 6. Between-group t-test for Change
# 7. Between-group t-test for Follow_up
#
# Note: Uses moments::skewness() and moments::kurtosis()
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(moments)
})

# Required columns from df_wide
req_cols <- c("kaatumisenpelkoOn", "Test", "Baseline", "Follow_up")

# Verify required columns exist
if (!exists("df_wide")) {
  stop("df_wide object not found. Ensure K1.2.data_transformation.R has been sourced.")
}

missing_cols <- setdiff(req_cols, names(df_wide))
if (length(missing_cols) > 0) {
  stop("Missing required columns in df_wide: ", paste(missing_cols, collapse = ", "))
}

cat("Starting statistical analyses...\n")

# Baseline Analysis (Means, SD, CIs, Skewness, Kurtosis)
cat("  Computing baseline statistics...\n")
baseline_stats <- df_wide %>%
  group_by(kaatumisenpelkoOn, Test) %>%
  summarise(
    B_Mean     = mean(Baseline, na.rm = TRUE),
    B_SD       = sd(Baseline, na.rm = TRUE),
    B_n        = sum(!is.na(Baseline)),
    B_Skew     = skewness(Baseline, na.rm = TRUE),
    B_Kurtosis = kurtosis(Baseline, na.rm = TRUE),
    .groups    = "drop"
  ) %>%
  mutate(
    B_SE       = B_SD / sqrt(B_n),
    B_CI_lower = B_Mean - 1.96 * B_SE,
    B_CI_upper = B_Mean + 1.96 * B_SE
  )

# Change Analysis (Means, SD, CIs)
cat("  Computing change statistics (Follow_up - Baseline)...\n")
change_stats <- df_wide %>%
  group_by(kaatumisenpelkoOn, Test) %>%
  summarise(
    C_Mean     = mean(Follow_up - Baseline, na.rm = TRUE),
    C_SD       = sd(Follow_up - Baseline, na.rm = TRUE),
    C_n        = sum(!is.na(Follow_up - Baseline)),
    C_Skew     = skewness(Follow_up - Baseline, na.rm = TRUE),
    C_Kurtosis = kurtosis(Follow_up - Baseline, na.rm = TRUE),
    .groups    = "drop"
  ) %>%
  mutate(
    C_SE       = C_SD / sqrt(C_n),
    C_CI_lower = C_Mean - 1.96 * C_SE,
    C_CI_upper = C_Mean + 1.96 * C_SE
  )

# Follow-up Analysis (Means, SD, CIs)
cat("  Computing follow-up statistics...\n")
follow_up_stats <- df_wide %>%
  group_by(kaatumisenpelkoOn, Test) %>%
  summarise(
    F_Mean     = mean(Follow_up, na.rm = TRUE),
    F_SD       = sd(Follow_up, na.rm = TRUE),
    F_n        = sum(!is.na(Follow_up)),
    F_Skew     = skewness(Follow_up, na.rm = TRUE),
    F_Kurtosis = kurtosis(Follow_up, na.rm = TRUE),
    .groups    = "drop"
  ) %>%
  mutate(
    F_SE       = F_SD / sqrt(F_n),
    F_CI_lower = F_Mean - 1.96 * F_SE,
    F_CI_upper = F_Mean + 1.96 * F_SE
  )

# Between-Group t-test for Baseline
cat("  Running between-group t-tests (Baseline)...\n")
p_values_baseline <- df_wide %>%
  group_by(Test) %>%
  summarise(
    p_value = ifelse(
      length(unique(kaatumisenpelkoOn)) == 2,
      t.test(Baseline ~ kaatumisenpelkoOn)$p.value,
      NA
    ),
    .groups = "drop"
  ) %>%
  rename(Baseline_p_value = p_value)

# Within-Group (Paired) t-test for Baseline vs. Follow-up
cat("  Running within-group paired t-tests (Baseline vs Follow_up)...\n")
p_values_within <- df_wide %>%
  drop_na(Baseline, Follow_up) %>%
  mutate(
    Baseline  = as.numeric(Baseline),
    Follow_up = as.numeric(Follow_up)
  ) %>%
  group_by(kaatumisenpelkoOn, Test) %>%
  summarise(
    n_pairs = sum(!is.na(Baseline) & !is.na(Follow_up)),
    p_value = ifelse(n_pairs > 1,
                     t.test(Baseline, Follow_up, paired = TRUE)$p.value,
                     NA),
    .groups = "drop"
  ) %>%
  select(-n_pairs) %>%
  rename(Change_p_value = p_value)

# Between-Group t-test for Change (Follow_up - Baseline)
cat("  Running between-group t-tests (Change)...\n")
df_change_p_value_between <- df_wide %>%
  group_by(Test) %>%
  summarise(
    p_value = ifelse(
      length(unique(kaatumisenpelkoOn)) == 2,
      t.test(Follow_up - Baseline ~ kaatumisenpelkoOn, data = cur_data(), na.action = na.omit)$p.value,
      NA
    ),
    .groups = "drop"
  ) %>%
  rename(Change_p_between = p_value)

# Between-Group t-test for Follow-up
cat("  Running between-group t-tests (Follow_up)...\n")
follow_up_p_value <- df_wide %>%
  group_by(Test) %>%
  summarise(
    p_value = ifelse(
      length(unique(kaatumisenpelkoOn)) == 2,
      t.test(Follow_up ~ kaatumisenpelkoOn, data = cur_data(), na.action = na.omit)$p.value,
      NA
    ),
    .groups = "drop"
  ) %>%
  rename(Follow_up_p_value = p_value)

# Preview results
cat("\nStatistical analysis results:\n")
cat("  Baseline stats:\n")
print(baseline_stats)
cat("\n  Change stats:\n")
print(change_stats)
cat("\n  Follow-up stats:\n")
print(follow_up_stats)
cat("\n  Baseline p-values:\n")
print(p_values_baseline)
cat("\n  Within-group (paired) p-values:\n")
print(p_values_within)
cat("\n  Change between-group p-values:\n")
print(df_change_p_value_between)
cat("\n  Follow-up p-values:\n")
print(follow_up_p_value)

cat("\nStatistical analyses completed successfully.\n")

# EOF
