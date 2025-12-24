#!/usr/bin/env Rscript
# ==============================================================================
# K1.2_TRANSFORM - Data Transformation & Reshaping (Long/Wide Pivoting)
# File tag: K1.2_TRANSFORM.V1_data-transform.R
# Purpose: Transform data to long format, create test/timepoint variables, reshape to wide format
#
# Input: `data` object from K1.1 (raw data in R environment)
# Output: `df_long` and `df_wide` objects (analysis-ready long and wide formats)
#
# Required vars (raw data, DO NOT INVENT; must match req_cols):
# NRO, kaatumisenpelkoOn, z_kavelynopeus0, z_kavelynopeus2, z_Tuoli0, z_Tuoli2,
# z_Seisominen0, z_Seisominen2, z_Puristus0, z_Puristus2
#
# Mapping (raw -> analysis):
# NRO -> id (participant ID in grouped data)
# kaatumisenpelkoOn -> FOF grouping variable (0/1)
# z_kavelynopeus0/2 -> MWS (Maximal Walking Speed) at Baseline/Follow_up
# z_Tuoli0/2 -> FTSST (Five Times Sit-to-Stand Test) at Baseline/Follow_up
# z_Seisominen0/2 -> SLS (Single Leg Stance) at Baseline/Follow_up
# z_Puristus0/2 -> HGS (Hand Grip Strength) at Baseline/Follow_up
#
# Output structure:
# - df_long: NRO, kaatumisenpelkoOn, Test, Timepoint, Z_score, id
# - df_wide: NRO, kaatumisenpelkoOn, Test, id, Baseline, Follow_up
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# Required columns for transformation
req_cols <- c("NRO", "kaatumisenpelkoOn",
              "z_kavelynopeus0", "z_kavelynopeus2",
              "z_Tuoli0", "z_Tuoli2",
              "z_Seisominen0", "z_Seisominen2",
              "z_Puristus0", "z_Puristus2")

# Verify required columns exist
missing_cols <- setdiff(req_cols, names(data))
if (length(missing_cols) > 0) {
  stop("Missing required columns for transformation: ", paste(missing_cols, collapse = ", "))
}

cat("Starting data transformation (long/wide pivoting)...\n")

# Convert Data into Long Format
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
  # Create Additional Variables: Timepoint and Test
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

cat("  Long format created:", nrow(df_long), "rows\n")

# Preview the Transformed Long Data
cat("  Long format preview (first 10 rows):\n")
print(head(df_long, 10))

# Prepare Data for Pivoting: Add a Row Index to Align Measurements
df_long <- df_long %>%
  group_by(kaatumisenpelkoOn, Test, Timepoint) %>%
  mutate(id = row_number()) %>%
  ungroup()

# Create a Pivot Table (Wide Format) with Baseline and Follow_up in Separate Columns
df_wide <- df_long %>%
  select(-Variable) %>%    # Remove unnecessary column
  pivot_wider(
    names_from  = Timepoint,
    values_from = Z_score
  ) %>%
  drop_na(Baseline, Follow_up)  # Ensure only complete pairs are kept

cat("  Wide format created:", nrow(df_wide), "rows (complete pairs only)\n")

# Preview the Wide (Pivoted) Data
cat("  Wide format preview:\n")
print(df_wide)

cat("Data transformation completed successfully.\n")

# EOF
