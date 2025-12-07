########################################################################################################
# KAAOS 3.6: R Script for Merging and Exporting Final Analytical Results (CSV) in KaatumisenPelko Data
#
# [K3.6.results_export.R]
#
# "Combines baseline, change, and follow-up statistics with effect sizes, reorders 
#  columns, exports the final table to CSV, and prints the file path.
#  All computations are based on the original Values"
########################################################################################################

########################################################################################################
#  Sequence list
########################################################################################################
# 1: Load necessary libraries
# 2: Ensure Directory Exists for Output
# 3: Define Significance Label Function (and assume skewness/kurtosis label functions exist)
# 4: Combine Baseline, Change, and Follow-Up Statistics into a Final Table
# 5: Convert p-values to Numeric and Add Initial Significance Labels to final_table
# 6: Merge Cohen's d Effect Sizes into the Final Table
# 7: Add Follow_up Effect Size and Its Label
# 8: Reorder and Finalize Columns for Clarity
# 9: Export the Final Table to a CSV File and Print the File Path
########################################################################################################

# 1: Load necessary libraries
library(dplyr)

# 2: Ensure Directory Exists for Output
output_dir <- "C:/Users/tomik/OneDrive/TUTKIMUS/Päijät-Sote/P-Sote/P-Sote/tables/"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# 3: Define Significance Label Function
significance_label <- function(p_value) {
  ifelse(is.na(p_value), "",
         ifelse(p_value < 0.001, "***",
                ifelse(p_value < 0.01, "**",
                       ifelse(p_value < 0.05, "*", "")
                )
         )
  )
}

# Note: The functions skewness_label() and kurtosis_label() are assumed to be defined elsewhere.

# 4: Combine Baseline, Change, and Follow-Up Statistics into a Final Table
final_table <- baseline_stats %>%
  left_join(p_values_baseline, by = "Test") %>%
  left_join(change_stats, by = c("kaatumisenpelkoOn", "Test")) %>%
  left_join(p_values_within, by = c("kaatumisenpelkoOn", "Test"), relationship = "many-to-many") %>%
  left_join(df_change_p_value_between, by = "Test") %>%
  left_join(follow_up_stats, by = c("kaatumisenpelkoOn", "Test")) %>%
  left_join(follow_up_p_value, by = "Test") %>%
  # 4.1: Convert p-values to numeric and add significance labels
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

# 5: Merge Cohen's d Effect Sizes into the Final Table
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

# 6: Add Follow_up Effect Size and Its Label
final_table <- final_table %>%
  left_join(follow_up_effect, by = "Test") %>%
  rowwise() %>%
  mutate(
    Follow_up_d_label = effect_size_label(Follow_up_d)
  ) %>%
  ungroup()

# 7: Reorder and Finalize Columns for Clarity
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

# Check the structure of the final table
str(final_table)

# 8: Export the Final Table to a CSV File
table_path <- paste0(output_dir, "K3_Values_2G.csv")
write.csv(final_table, table_path, row.names = FALSE)

# 9: Print the File Path to Confirm the Export
print(paste("File saved at:", table_path))
