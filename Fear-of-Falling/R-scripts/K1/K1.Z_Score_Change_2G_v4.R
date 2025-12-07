#!/usr/bin/env Rscript
# KAAOS 1: Longitudinal Analysis of Fear of Falling and Functional Performance:
#          Data Processing
#          and Statistical Computation in R

###############################################################################
#  Sequence list (high level)
###############################################################################
# 1: Install and load required packages
# 2: Define the File Path
# 3: Load the Dataset
# 4: Inspect the Structure of the Dataset
# 5: Convert Categorical Variables to Factors
# 6: Convert Data into Long Format
# 7: Check the Transformed Data
# 8: Compute Means and 95% Confidence Intervals
# 9: Ensure Directory Exists for Output
# 10: Prepare Data for Pivoting and Add Row Index to Ensure Pivoting Works
#     Correctly
# 11: Pivot Data Without Losing Observations
# 12: Inspect the Pivoted Data
# 13: Perform Baseline Analysis
# 14: Perform Change Analysis
# 15: Perform Follow-up Analysis
# 16: Between- and within-group tests and p-values
# 17: Compute Cohen's d effect sizes and labels
# 18: Combine results into final table and save

## 1: Install and load required packages (uncomment to install)

library(ggplot2)
library(dplyr)
library(tidyr)
library(boot)
library(haven)
library(stringr)
library(broom)
library(here)

## 2: Define the File Path
# Adjust the path as necessary for your environment
file_path <- here::here("dataset", "KaatumisenPelko.csv")

## 3: Load the Dataset

data <- readr::read_csv(file_path)   # or utils::read.csv(file_path)

print(file_path)
if (!file.exists(file_path)) stop("File not found: ", file_path)

## 4: Inspect the Structure of the Dataset
str(data)
head(data)

## 5: Convert Categorical Variables to Factors | # 0 = no fear, 1 = fear
data$kaatumisenpelkoOn <- as.factor(data$kaatumisenpelkoOn)
data$sex <- as.factor(data$sex)  # 0 = female, 1 = male

## 6: Convert Data into Long Format
df_long <- data %>%
  select(
    NRO,
    kaatumisenpelkoOn,
    z_kavelynopeus0, z_kavelynopeus2,
    z_Tuoli0, z_Tuoli2,
    z_Seisominen0, z_Seisominen2,
    z_Puristus0, z_Puristus2
  ) %>%
  pivot_longer(
    cols = starts_with("z_"),
    names_to = "Variable",
    values_to = "Z_score"
  ) %>%
  mutate(
    Timepoint = case_when(
      str_detect(Variable, "0$") ~ "Baseline",
      str_detect(Variable, "2$") ~ "Follow_up"
    ),
    Test = case_when(
      str_detect(Variable, "kavelynopeus") ~ "MWS", # Maximal Walking Speed
      str_detect(Variable, "Tuoli") ~ "FTSST",      # Five Times Sit to Stand Test
      str_detect(Variable, "Seisominen") ~ "SLS",   # Single Leg Stance
      str_detect(Variable, "Puristus") ~ "HGS"      # Hand Grip Strength
    )
  )

## 7: Check the Transformed Data
print(head(df_long, 10))

## 8: Compute Means and 95% Confidence Intervals
summary_df <- df_long %>%
  group_by(kaatumisenpelkoOn, Timepoint, Test) %>%
  summarise(
    Mean = mean(Z_score, na.rm = TRUE),
    SD = sd(Z_score, na.rm = TRUE),
    n = sum(!is.na(Z_score)),
    .groups = "drop"
  ) %>%
  mutate(
    SE = SD / sqrt(n),
    CI_lower = Mean - 1.96 * SE,
    CI_upper = Mean + 1.96 * SE
  )

## 9: Ensure Directory Exists for Output

output_dir <- here::here("R-scripts", "K1", "outputs")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

## 10: Prepare Data for Pivoting and add row index to ensure pivoting works correctly
df_long <- df_long %>%
  group_by(kaatumisenpelkoOn, Test, Timepoint) %>%
  mutate(id = row_number()) %>%
  ungroup()

## 11: Pivot Data Without Losing Observations
df_wide <- df_long %>%
  select(-Variable) %>%                # Drop the 'Variable' column
  pivot_wider(
    names_from  = Timepoint,
    values_from = Z_score
  ) %>%
  drop_na(Baseline, Follow_up)

print(df_wide)

## 12: Perform Baseline Analysis
baseline_stats <- df_wide %>%
  group_by(kaatumisenpelkoOn, Test) %>%
  summarise(
    B_Mean = mean(Baseline, na.rm = TRUE),
    B_SD   = sd(Baseline, na.rm = TRUE),
    B_n  = sum(!is.na(Baseline)),
    .groups = "drop"
  ) %>%
  mutate(
    B_SE       = B_SD / sqrt(B_n),
    B_CI_lower = B_Mean - 1.96 * B_SE,
    B_CI_upper = B_Mean + 1.96 * B_SE
  )

## 13: Perform Change Analysis
change_stats <- df_wide %>%
  group_by(kaatumisenpelkoOn, Test) %>%
  summarise(
    C_Mean = mean(Follow_up - Baseline, na.rm = TRUE),
    C_SD   = sd(Follow_up - Baseline, na.rm = TRUE),
    C_n    = sum(!is.na(Follow_up - Baseline)),
    .groups = "drop"
  ) %>%
  mutate(
    C_SE       = C_SD / sqrt(C_n),
    C_CI_lower = C_Mean - 1.96 * C_SE,
    C_CI_upper = C_Mean + 1.96 * C_SE
  )

## 14: Perform Follow-up Analysis
follow_up_stats <- df_wide %>%
  group_by(kaatumisenpelkoOn, Test) %>%
  summarise(
    F_Mean = mean(Follow_up, na.rm = TRUE),
    F_SD   = sd(Follow_up, na.rm = TRUE),
    F_n    = sum(!is.na(Follow_up)),
    .groups = "drop"
  ) %>%
  mutate(
    F_SE       = F_SD / sqrt(F_n),
    F_CI_lower = F_Mean - 1.96 * F_SE,
    F_CI_upper = F_Mean + 1.96 * F_SE
  )

## 15: Between-group tests for Baseline
p_values_baseline <- df_wide %>%
  group_by(Test) %>%
  summarise(
    p_value = ifelse(length(unique(kaatumisenpelkoOn)) == 2,
                     t.test(Baseline ~ kaatumisenpelkoOn)$p.value,
                     NA),
    .groups = "drop"
  ) %>%
  rename(Baseline_p_value = p_value)

## 16: Within-group paired tests (Baseline vs Follow-up)
p_values_within <- df_wide %>%
  drop_na(Baseline, Follow_up) %>%
  mutate(
    Baseline = as.numeric(Baseline),
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

print(p_values_within)

## 17: Between-group test for change
df_change_p_value_between <- df_wide %>%
  group_by(Test) %>%
  summarise(
    p_value = ifelse(length(unique(kaatumisenpelkoOn)) == 2,
                     t.test(Follow_up - Baseline ~ kaatumisenpelkoOn, data = cur_data(), na.action = na.omit)$p.value,
                     NA),
    .groups = "drop"
  ) %>%
  rename(Change_p_between = p_value)

print(df_change_p_value_between)

## 18: Between-group test for follow-up
follow_up_p_value <- df_wide %>%
  group_by(Test) %>%
  summarise(
    p_value = ifelse(length(unique(kaatumisenpelkoOn)) == 2,
                     t.test(Follow_up ~ kaatumisenpelkoOn, data = cur_data(), na.action = na.omit)$p.value,
                     NA),
    .groups = "drop"
  ) %>%
  rename(Follow_up_p_value = p_value)

print(follow_up_p_value)

## 19: Functions for Cohen's d
cohen_d_independent <- function(mean1, sd1, n1, mean2, sd2, n2) {
  pooled_sd <- sqrt(((n1 - 1) * sd1^2 + (n2 - 1) * sd2^2) / (n1 + n2 - 2))
  d <- (mean1 - mean2) / pooled_sd
  return(d)
}

cohen_d_paired <- function(C_Mean, C_SD) {
  d <- C_Mean / C_SD
  return(d)
}

## 20: Compute effect sizes
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

change_effect <- change_stats %>%
  mutate(Change_d = cohen_d_paired(C_Mean, C_SD)) %>%
  select(kaatumisenpelkoOn, Test, Change_d)

change_between_effect <- df_wide %>%
  group_by(Test) %>%
  summarise(
    d = cohen_d_independent(
      mean(Follow_up[kaatumisenpelkoOn == 0] - Baseline[kaatumisenpelkoOn == 0], na.rm = TRUE),
      sd(Follow_up[kaatumisenpelkoOn == 0] - Baseline[kaatumisenpelkoOn == 0], na.rm = TRUE),
      sum(!is.na(Follow_up[kaatumisenpelkoOn == 0]) & !is.na(Baseline[kaatumisenpelkoOn == 0])),
      mean(Follow_up[kaatumisenpelkoOn == 1] - Baseline[kaatumisenpelkoOn == 1], na.rm = TRUE),
      sd(Follow_up[kaatumisenpelkoOn == 1] - Baseline[kaatumisenpelkoOn == 1], na.rm = TRUE),
      sum(!is.na(Follow_up[kaatumisenpelkoOn == 1]) & !is.na(Baseline[kaatumisenpelkoOn == 1]))
    ),
    .groups = "drop"
  ) %>%
  rename(Change_d_between = d)

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

## 21: Effect size labels
effect_size_label <- function(d_value) {
  if (is.na(d_value)) return("")
  else if (d_value >= 0.8) return("Large")
  else if (d_value >= 0.5) return("Medium")
  else if (d_value >= 0.2) return("Small")
  else return("Very Small")
}

follow_up_effect <- follow_up_effect %>%
  rowwise() %>%
  mutate(Follow_up_d_label = effect_size_label(Follow_up_d)) %>%
  ungroup()

## 22: Combine results into final table
baseline_stats <- baseline_stats %>%
  left_join(p_values_baseline, by = "Test")

change_stats <- change_stats %>%
  left_join(p_values_within, by = c("kaatumisenpelkoOn","Test"))

final_table <- baseline_stats %>%
  left_join(change_stats, by = c("kaatumisenpelkoOn","Test")) %>%
  left_join(df_change_p_value_between, by = "Test") %>%
  left_join(follow_up_stats, by = c("kaatumisenpelkoOn","Test")) %>%
  left_join(follow_up_p_value, by = "Test")

## 23: Function to add significance labels - define before use
significance_label <- function(p_value) {
  if (is.na(p_value)) return("")
  else if (p_value < 0.001) return("***")
  else if (p_value < 0.01) return("**")
  else if (p_value < 0.05) return("*")
  else return("")
}

## 24: Reorder columns and add significance labels
final_table <- final_table %>%
  select(
    kaatumisenpelkoOn, Test,
    B_Mean, B_SD, B_n, B_SE, B_CI_lower, B_CI_upper,
    Baseline_p_value,
    C_Mean, C_SD, C_n, C_SE, C_CI_lower, C_CI_upper,
    Change_p_value,
    Change_p_between,
    F_Mean, F_SD, F_n, F_SE, F_CI_lower, F_CI_upper,
    Follow_up_p_value
  ) %>%
  rowwise() %>%
  mutate(
    Change_p_between = as.numeric(Change_p_between),
    Change_p_between_sig = significance_label(Change_p_between)
  ) %>%
  ungroup()

## 25: Convert p-values to numeric and add significance columns
final_table <- final_table %>%
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
    Follow_up_p_value_sig = significance_label(Follow_up_p_value)
  ) %>%
  ungroup()

## 26: Arrange columns so that significance labels follow p-values
final_table <- final_table %>%
  select(
    kaatumisenpelkoOn, Test, B_Mean, B_SD, B_n, B_SE, B_CI_lower, B_CI_upper,
    Baseline_p_value, Baseline_p_value_sig,
    C_n, C_Mean, C_SD, C_SE, C_CI_lower, C_CI_upper,
    Change_p_value, Change_p_value_sig,
    Change_p_between, Change_p_between_sig,
    F_Mean, F_SD, F_n, F_SE, F_CI_lower, F_CI_upper,
    Follow_up_p_value, Follow_up_p_value_sig
  )

## 27: Merge Cohen's d effect sizes into the final table and label them
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

## 28: Add follow-up effect size and label
final_table <- final_table %>%
  left_join(follow_up_effect, by = "Test") %>%
  rowwise() %>%
  mutate(
    Follow_up_d_label = effect_size_label(Follow_up_d)
  ) %>%
  ungroup()

str(final_table)

## 29: Final column arrangement including Cohen's d next to follow-up p-value
final_table <- final_table %>%
  select(
    kaatumisenpelkoOn, Test, B_Mean, B_SD, B_n, B_SE, B_CI_lower, B_CI_upper,
    Baseline_p_value, Baseline_p_value_sig, Baseline_d, Baseline_d_label,
    C_n, C_Mean, C_SD, C_SE, C_CI_lower, C_CI_upper,
    Change_p_value, Change_p_value_sig, Change_d, Change_d_label,
    Change_p_between, Change_p_between_sig, Change_d_between, Change_d_between_label,
    F_Mean, F_SD, F_n, F_SE, F_CI_lower, F_CI_upper,
    Follow_up_p_value, Follow_up_p_value_sig, Follow_up_d, Follow_up_d_label
  )

View(final_table)

## 30: Save Final Results as a CSV File

table_path <- file.path(output_dir, "K1_Z_Score_Change_2G_4R.csv")
write.csv(final_table, table_path, row.names = FALSE)

## 31: Confirmation
cat("Tiedosto tallennettu: ", table_path, "\n")