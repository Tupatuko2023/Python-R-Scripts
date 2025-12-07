# KAAOS 1: Longitudinal Analysis of Fear of Falling and Functional Performance: Data Processing 
#          and Statistical Computation in R

# [K1.Z_Score_Change_2G.R]

# "This R script processes longitudinal data on fear of falling, transforms it, 
#  computes statistical summaries, performs t-tests, and exports the results."

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Install and load required packages
# 2: Define the File Path
# 3: Load the Dataset
# 4: Inspect the Structure of the Dataset
# 5: Convert Categorical Variables to Factors
# 6: Convert Data into Long Format
# 7: Check the Transformed Data
# 8: Compute Means and 95% Confidence Intervals
# 9: Ensure Directory Exists for Output
# 10: Prepare Data for Pivoting
# 11: Check Data Structure Before Pivoting
# 12: Pivot Data Without Losing Observations
# 13: Check Pivoted Data
# 14: Perform Change Analysis
# 15: Check if More Observations Were Obtained
# 16: Conduct Paired t-test for Within-Group Comparison
# 17: Check p-values for Within-Group Comparison
# 18: Conduct Paired t-test for Between-Group Comparison for Performance Change
# 19: Check p-values for Between-Group Performance Change
# 20: Conduct Paired t-test for Between-Group Comparison for Follow_up Results
# 21: Check p-values for Between-Group Follow_up Results
# 22: Function for Calculating Cohen's d for Independent Groups
# 23: Function for Calculating Cohen's d for Paired Tests (Effect Size for Change)
# 24: Compute Baseline Cohen's d (Between-Group Baseline Comparison)
# 25: Compute Cohen's d for Change within Groups (Within-Group Follow_up Comparison)
# 26: Compute Cohen's d for Between-Group Change Comparison
# 27: Compute Cohen's d for Follow_up (Between-Group Follow_up Comparison)
# 28: Label Effect Size for Follow_up Cohen's d
# 29: Function for Labeling Effect Size
# 30: Combine All Results into Final Table
# 31: Function to Add Significance Labels for p-values
# 32: Convert p-values to Numeric and Add Significance Labels
# 33: Arrange Columns so that Significance Labels Follow p-values
# 34: Merge Cohen's d Effect Sizes into the Final Table
# 35: Add Follow_up Effect Size and Its Label to the Final Table
# 36: Arrange Columns to Place Cohen's d Next to Follow_up p-value
# 37: Save Final Results as a CSV File
# 38: Print File Path to Confirm Save

########################################################################################################
########################################################################################################

# 1: Install and load required packages
# install.packages("ggplot2")  # For visualization
# install.packages("dplyr")    # For data manipulation
# install.packages("tidyr")    # For transforming data into long format
# install.packages("boot")     # For calculating confidence intervals
# install.packages("haven")    # For reading .dta files
# install.packages("tidyverse") 
# install.packages("broom") 

library(ggplot2)
library(dplyr)
library(tidyr)
library(boot)
library(haven)
library(stringr)
library(broom)

# 2: Define the File Path
file_path <- "C:/Users/tomik/OneDrive/TUTKIMUS/Päijät-Sote/P-Sote/P-Sote/dataset/KaatumisenPelko.dta"

# 3: Load the Dataset
data <- read_dta(file_path)

# 4: Inspect the Structure of the Dataset
str(data)
head(data)

# 5: Convert Categorical Variables to Factors
data$kaatumisenpelkoOn <- as.factor(data$kaatumisenpelkoOn)  # 0 = no fear, 1 = fear
data$sex <- as.factor(data$sex)  # 0 = female, 1 = male

# 6: Convert Data into Long Format
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
      str_detect(Variable, "Puristus") ~ "HGS"      # Hand Grip Strenght
    )
  )

# 7: Check the Transformed Data
print(head(df_long, 10))

# 8: Compute Means and 95% Confidence Intervals
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

# 9: Ensure Directory Exists for Output
output_dir <- "C:/Users/tomik/OneDrive/TUTKIMUS/Päijät-Sote/P-Sote/P-Sote/tables/"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# 10: Prepare Data for Pivoting adn add row index to ensure pivoting works correctly
df_long <- df_long %>%
  group_by(kaatumisenpelkoOn, Test, Timepoint) %>%
  mutate(id = row_number()) %>%
  ungroup()

# 11: Pivot Data Without Losing Observations
df_wide <- df_long %>%
  select(-Variable) %>%                # Drop the 'Variable' column
  pivot_wider(
    names_from  = Timepoint, 
    values_from = Z_score
  ) %>%
  drop_na(Baseline, Follow_up)


df_wide <- df_wide %>%
  drop_na(Baseline, Follow_up)

print(df_wide)

# 12: Perform Baseline Analysis
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

# 13: Perform Change Analysis
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


# 14: Perform Follow-up Analysis
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

# : Conduct Paired t-test for Between-Group Comparison in Baseline
p_values_baseline <- df_wide %>%
  group_by(Test) %>%
  summarise(
    p_value = ifelse(length(unique(kaatumisenpelkoOn)) == 2,
                     t.test(Baseline ~ kaatumisenpelkoOn)$p.value,
                     NA),
    .groups = "drop"
  ) %>%
  rename(Baseline_p_value = p_value)

# 19: Check p-values
print(p_values_baseline)
print(Baseline_p_value)

# 16: Conduct Paired t-test for Within-Group Comparison
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
  rename(Change_p_value = p_value)   # For instance

# 17: Check p-values
print(p_values_within)

# 18: Conduct Paired t-test for Between-Group Comparison for Performance Change (Change_p_between)
df_change_p_value_between <- df_wide %>%
  group_by(Test) %>%
  summarise(
    p_value = ifelse(length(unique(kaatumisenpelkoOn)) == 2,
                     t.test(Follow_up - Baseline ~ kaatumisenpelkoOn, data = cur_data(), na.action = na.omit)$p.value,
                     NA),
    .groups = "drop"
  ) %>%
  rename(Change_p_between = p_value)

# 19: Check p-values
print(df_change_p_value_between)

# 20: Conduct Paired t-test for Between-Group Comparison for Follow_up Results (Follow_up_p_value)
follow_up_p_value <- df_wide %>%
  group_by(Test) %>%
  summarise(
    p_value = ifelse(length(unique(kaatumisenpelkoOn)) == 2,
                     t.test(Follow_up ~ kaatumisenpelkoOn, data = cur_data(), na.action = na.omit)$p.value,
                     NA),
    .groups = "drop"
  ) %>%
  rename(Follow_up_p_value = p_value)

# 21: Check p-values
print(follow_up_p_value)

# 22: Function for calculating Cohen's d for independent groups
cohen_d_independent <- function(mean1, sd1, n1, mean2, sd2, n2) {
  pooled_sd <- sqrt(((n1 - 1) * sd1^2 + (n2 - 1) * sd2^2) / (n1 + n2 - 2))  # Combined standard deviation
  d <- (mean1 - mean2) / pooled_sd
  return(d)
}

# 23: Function for Calculating Cohen's d for Paired Tests (Effect Size for Change)
cohen_d_paired <- function(C_Mean, C_SD) {
  d <- C_Mean / C_SD  # Cohen's d = Mean change / SD change
  return(d)
}

# 24: Compute Baseline Cohen's d (Between-Group Baseline Comparison)
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

# 25: Compute Cohen's d for Change within Groups (Within-Group Follow_up Comparison)
change_effect <- change_stats %>%
  mutate(Change_d = cohen_d_paired(C_Mean, C_SD)) %>%
  select(kaatumisenpelkoOn, Test, Change_d)

# 26: Compute Cohen's d for Between-Group Change Comparison
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

# 27: Compute Cohen's d for Follow_up (Between-Group Follow_up Comparison)
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

# 28: Function for Labeling Effect Size
effect_size_label <- function(d_value) {
  if (is.na(d_value)) return("")  # If missing, return empty
  else if (d_value >= 0.8) return("Large")
  else if (d_value >= 0.5) return("Medium")
  else if (d_value >= 0.2) return("Small")
  else return("Very Small")
}


# 29: Label Effect Size for Follow_up Cohen's d
follow_up_effect <- follow_up_effect %>%
  rowwise() %>%  # Ensures function works on each row separately
  mutate(Follow_up_d_label = effect_size_label(Follow_up_d)) %>%
  ungroup()  # Remove rowwise after use

# 30: Combine All Results into Final Table
baseline_stats <- baseline_stats %>%
  left_join(p_values_baseline, by = "Test")

change_stats <- change_stats %>%
  left_join(p_values_within, by = c("kaatumisenpelkoOn","Test"))

# 31: Merge Baseline, Change, and Follow-Up Statistics
final_table <- baseline_stats %>%
  left_join(change_stats, by = c("kaatumisenpelkoOn","Test"))

final_table <- final_table %>%
  left_join(df_change_p_value_between, by = "Test")

final_table <- final_table %>%
  left_join(follow_up_stats, by = c("kaatumisenpelkoOn","Test")) %>%
  left_join(follow_up_p_value, by = "Test")

# 32: Reorder Columns for Clarity
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

# 33: Function to Add Significance Labels for p-values
significance_label <- function(p_value) {
  if (is.na(p_value)) return("")  # Jos p-arvo on NA, palautetaan tyhjä
  else if (p_value < 0.001) return("***")
  else if (p_value < 0.01) return("**")
  else if (p_value < 0.05) return("*")
  else return("")
}

# 34: Convert p-values to Numeric and Add Significance Labels
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


# 35: Arrange Columns so that Significance Labels Follow p-values
final_table <- final_table %>%
  select(
    kaatumisenpelkoOn, Test, B_Mean, B_SD, B_n, B_SE, B_CI_lower, B_CI_upper,
    Baseline_p_value, Baseline_p_value_sig, 
    C_n, C_Mean, C_SD, C_SE, C_CI_lower, C_CI_upper,
    Change_p_value, Change_p_value_sig,
    Change_p_between, Change_p_between_sig,
    F_Mean, F_SD, F_n, F_SE, F_CI_lower, F_CI_upper,
    Follow_up_p_value,
    Follow_up_p_value, Follow_up_p_value_sig
  )


# 36: Merge Cohen's d Effect Sizes into the Final Table
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

# 37: Add Follow_up Effect Size and Its Label to the Final Table
final_table <- final_table %>%
  left_join(follow_up_effect, by = "Test") %>%
  rowwise() %>%
  mutate(
    Follow_up_d_label = effect_size_label(Follow_up_d)
  ) %>%
  ungroup()

str(final_table)

# 38: Arrange Columns to Place Cohen's d Next to Follow_up p-value
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

# 39: Save Final Results as a CSV File
table_path <- paste0(output_dir, "K1:Z_Score_Change_2R.csv")
write.csv(final_table, table_path, row.names = FALSE)

# 40: Print File Path to Confirm Save
print(paste("Tiedosto tallennettu: ", table_path))