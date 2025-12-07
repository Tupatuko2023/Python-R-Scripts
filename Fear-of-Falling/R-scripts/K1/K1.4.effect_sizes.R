# KAAOS 1.4: R Script for Computing and Labeling Effect Sizes (Cohen's d) in KaatumisenPelko Data
# [K1.4.effect_sizes.R]

# "Calculates Cohen’s d effect sizes for baseline, within-group, between-group, 
#  and follow-up comparisons, with effect size labeling."

# This script computes effect sizes (Cohen's d) for various comparisons:
#   - Between-group baseline comparison
#   - Within-group (paired) change
#   - Between-group change
#   - Between-group follow-up comparison
# It also includes functions for calculating Cohen's d and labeling effect sizes.

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Function for calculating Cohen's d for independent groups
# 2: Function for calculating Cohen's d for paired tests (effect size for change)
# 3: Compute Baseline Cohen's d (Between-Group Baseline Comparison)
# 4: Compute Cohen's d for Change within Groups (Within-Group Follow_up Comparison)
# 5: Compute Cohen's d for Between-Group Change Comparison
# 6: Compute Cohen's d for Follow_up (Between-Group Follow_up Comparison)
# 7: Function for Labeling Effect Size
# 8: Label Effect Size for Follow_up Cohen's d
# 9: End of Script Message

########################################################################################################
########################################################################################################

# 1: Function for calculating Cohen's d for independent groups
cohen_d_independent <- function(mean1, sd1, n1, mean2, sd2, n2) {
  # Calculate pooled standard deviation
  pooled_sd <- sqrt(((n1 - 1) * sd1^2 + (n2 - 1) * sd2^2) / (n1 + n2 - 2))
  # Compute Cohen's d as difference in means divided by pooled SD
  d <- (mean1 - mean2) / pooled_sd
  return(d)
}

# 2: Function for calculating Cohen's d for paired tests (effect size for change)
cohen_d_paired <- function(C_Mean, C_SD) {
  # Cohen's d = (mean change) / (SD of change)
  d <- C_Mean / C_SD
  return(d)
}

# 3: Compute Baseline Cohen's d (Between-Group Baseline Comparison)
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

# 4: Compute Cohen's d for Change within Groups (Within-Group Follow_up Comparison)
change_effect <- change_stats %>%
  mutate(Change_d = cohen_d_paired(C_Mean, C_SD)) %>%
  select(kaatumisenpelkoOn, Test, Change_d)

# 5: Compute Cohen's d for Between-Group Change Comparison
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

# 6: Compute Cohen's d for Follow_up (Between-Group Follow_up Comparison)
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

# 7: Function for Labeling Effect Size
effect_size_label <- function(d_value) {
  if (is.na(d_value)) return("")   # If missing, return empty
  abs_d <- abs(d_value)             # Consider the magnitude for labeling
  if (abs_d >= 0.8) return("Large")
  else if (abs_d >= 0.5) return("Medium")
  else if (abs_d >= 0.2) return("Small")
  else return("Very Small")
}

# 8: Label Effect Size for Follow_up Cohen's d
follow_up_effect <- follow_up_effect %>%
  rowwise() %>%
  mutate(Follow_up_d_label = effect_size_label(Follow_up_d)) %>%
  ungroup()

# 9: Print or Inspect Key Objects
print(baseline_effect)
print(change_effect)
print(change_between_effect)
print(follow_up_effect)

# 10: End of Script Message
cat("Effect size calculations completed.\n")

