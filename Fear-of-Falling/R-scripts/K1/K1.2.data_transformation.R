# KAAOS 1.2: R Script for Data Transformation & Reshaping (Long/Wide Pivoting) of KaatumisenPelko Data

# [K1.2.data_transformation.R]

# "Transforms data to long format, creates new variables, reshapes it into a 
#  wide format, and previews both long and wide versions for analysis readiness." 

########################################################################################################
#  Sequence list
########################################################################################################

# 1: Assumptions - Dataset "data" has been imported by data_import.R
# 2: Convert Data into Long Format using pivot_longer
# 3: Create Additional Variables (Timepoint and Test)
# 4: Preview the Transformed Long Data
# 5: Prepare Data for Pivoting by adding a Row Index
# 6: Create a Pivot Table (Wide Format) with separate Baseline and Follow_up columns
# 7: Preview the Wide (Pivoted) Data

########################################################################################################
########################################################################################################

# 1: Assumptions - Dataset "data" has been imported by data_import.R

# 2: Convert Data into Long Format
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
  # 3: Create Additional Variables: Timepoint and Test
  mutate(
    Timepoint = case_when(
      str_detect(Variable, "0$") ~ "Baseline", 
      str_detect(Variable, "2$") ~ "Follow_up"
    ),
    Test = case_when(
      str_detect(Variable, "kavelynopeus") ~ "MWS",   # Maximal Walking Speed
      str_detect(Variable, "Tuoli") ~ "FTSST",        # Five Times Sit-to-Stand Test
      str_detect(Variable, "Seisominen") ~ "SLS",      # Single Leg Stance
      str_detect(Variable, "Puristus") ~ "HGS"         # Hand Grip Strength
    )
  )

# 4: Preview the Transformed Long Data
print(head(df_long, 10))

# 5: Prepare Data for Pivoting: Add a Row Index to Align Measurements
df_long <- df_long %>%
  group_by(kaatumisenpelkoOn, Test, Timepoint) %>%
  mutate(id = row_number()) %>%
  ungroup()

# 6: Create a Pivot Table (Wide Format) with Baseline and Follow_up in Separate Columns
df_wide <- df_long %>%
  select(-Variable) %>%    # Remove unnecessary column
  pivot_wider(
    names_from  = Timepoint, 
    values_from = Z_score
  ) %>%
  drop_na(Baseline, Follow_up)  # Ensure only complete pairs are kept

# 7: Preview the Wide (Pivoted) Data
print(df_wide)

