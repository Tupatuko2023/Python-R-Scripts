########################################################################################################
# KAAOS 3.3: R Script for Statistical Analysis & Group Comparisons of KaatumisenPelko Data
#
# [K3.3.statistical_analysis.R]
#
# "Performs detailed statistical analyses on KaatumisenPelko data: computes summary stats 
#  (mean, SD, CI) and executes paired & between-group t-tests based on the original Values."
########################################################################################################

########################################################################################################
#  Sequence list
########################################################################################################

# 1: (Optional) Compute Overall Summaries from Long Data
# 2: Baseline Analysis (Means, SD, CIs)
# 3: Change Analysis (Means, SD, CIs)
# 4: Follow-up Analysis (Means, SD, CIs)
# 5: Between-Group t-test for Baseline
# 6: Within-Group (Paired) t-test for Baseline vs. Follow-up
# 7: Between-Group t-test for Change (Follow_up - Baseline)
# 8: Between-Group t-test for Follow-up
# 9: (Optional) Other Statistical Calculations (e.g., ANOVA)
# 10: Print or Inspect Key Objects (Optional)
# 11: End of Script

########################################################################################################
########################################################################################################

# 1: (Optional) Compute Overall Summaries from Long Data
# Uncomment and adapt the code below to compute overall summary stats by group and timepoint:
# summary_df <- df_long %>%
#   group_by(kaatumisenpelkoOn, Timepoint, Test) %>%
#   summarise(
#     Mean = mean(Value, na.rm = TRUE),
#     SD   = sd(Value, na.rm = TRUE),
#     n    = sum(!is.na(Value)),
#     .groups = "drop"
#   ) %>%
#   mutate(
#     SE       = SD / sqrt(n),
#     CI_lower = Mean - 1.96 * SE,
#     CI_upper = Mean + 1.96 * SE
#   )
# print(summary_df)

# 2: Baseline Analysis (Means, SD, CIs)
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

# 3: Change Analysis (Means, SD, CIs)
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

# 4: Follow-up Analysis (Means, SD, CIs)
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

# 5: Between-Group t-test for Baseline
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

# 6: Within-Group (Paired) t-test for Baseline vs. Follow-up
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

# 7: Between-Group t-test for Change (Follow_up - Baseline)
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

# 8: Between-Group t-test for Follow-up
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

# 9: (Optional) Other Statistical Calculations, such as ANOVA
# Example (commented out by default):
# anova_results <- aov(Value ~ kaatumisenpelkoOn * Timepoint, data = df_long)
# summary(anova_results)

# 10: Print or Inspect Key Objects (Optional)
print(baseline_stats)
print(change_stats)
print(follow_up_stats)
print(p_values_baseline)
print(p_values_within)
print(df_change_p_value_between)
print(follow_up_p_value)

# 11: End of Script
cat("Statistical analyses completed.\n")
