#!/usr/bin/env Rscript
# ==============================================================================
# K3.2_TRANSFORM - Data Transformation & Reshaping (Original Values)
# File tag: K3.2_TRANSFORM.V1_data-transform.R
# Purpose: Transform data to long format using original test values, create variables, reshape to wide
#
# Input: `data` object from K1.1 (raw data in R environment)
# Output: `df_long` and `df_wide` objects (analysis-ready formats with original values)
#
# Required vars (raw data, DO NOT INVENT; must match req_cols):
# NRO, kaatumisenpelkoOn, tuoliltanousu0, tuoliltanousu2, kavelynopeus_m_sek0, kavelynopeus_m_sek2,
# Seisominen0, Seisominen2, Puristus0, Puristus2, PainVAS0, PainVAS2
#
# Mapping (raw -> analysis):
# NRO -> id (participant ID in grouped data)
# kaatumisenpelkoOn -> FOF grouping variable (0/1)
# tuoliltanousu0/2 -> FTSST (Five Times Sit-to-Stand Test) at Baseline/Follow_up
# kavelynopeus_m_sek0/2 -> MWS (Maximal Walking Speed) at Baseline/Follow_up
# Seisominen0/2 -> SLS (Single Leg Stance) at Baseline/Follow_up
# Puristus0/2 -> HGS (Hand Grip Strength) at Baseline/Follow_up
# PainVAS0/2 -> VAS (Visual Analogue Scale for pain) at Baseline/Follow_up
#
# Output structure:
# - df_long: NRO, kaatumisenpelkoOn, Test, Timepoint, Value, id
# - df_wide: NRO, kaatumisenpelkoOn, Test, id, Baseline, Follow_up
#
# Note: This differs from K1.2 by using original values instead of z-scores
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# Required columns for transformation (original test values)
req_cols <- c("NRO", "kaatumisenpelkoOn",
              "tuoliltanousu0", "tuoliltanousu2",
              "kavelynopeus_m_sek0", "kavelynopeus_m_sek2",
              "Seisominen0", "Seisominen2",
              "Puristus0", "Puristus2",
              "PainVAS0", "PainVAS2")

# Verify required columns exist
missing_cols <- setdiff(req_cols, names(data))
if (length(missing_cols) > 0) {
  stop("Missing required columns for transformation: ", paste(missing_cols, collapse = ", "))
}

cat("Starting data transformation (original values, long/wide pivoting)...\n")

# Convert Data into Long Format
df_long <- data %>%
  select(
    NRO,
    kaatumisenpelkoOn,
    tuoliltanousu0, tuoliltanousu2,
    kavelynopeus_m_sek0, kavelynopeus_m_sek2,
    Seisominen0, Seisominen2,
    Puristus0, Puristus2,
    PainVAS0, PainVAS2
  ) %>%
  pivot_longer(
    cols = c(
      tuoliltanousu0, tuoliltanousu2,
      kavelynopeus_m_sek0, kavelynopeus_m_sek2,
      Seisominen0, Seisominen2,
      Puristus0, Puristus2,
      PainVAS0, PainVAS2
    ),
    names_to  = "Variable",
    values_to = "Value"
  ) %>%
  # Create Additional Variables: Timepoint and Test
  mutate(
    Timepoint = case_when(
      str_detect(Variable, "0$") ~ "Baseline",
      str_detect(Variable, "2$") ~ "Follow_up"
    ),
    Test = case_when(
      str_detect(Variable, "tuoliltanousu") ~ "FTSST",  # Five Times Sit-to-Stand
      str_detect(Variable, "kavelynopeus")  ~ "MWS",    # Maximal Walking Speed
      str_detect(Variable, "Seisominen")    ~ "SLS",    # Single Leg Stance
      str_detect(Variable, "Puristus")      ~ "HGS",    # Hand Grip Strength
      str_detect(Variable, "PainVAS")       ~ "VAS"     # Visual Analogue Scale
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
  select(-Variable) %>%    # Remove the now-unnecessary column
  pivot_wider(
    names_from  = Timepoint,
    values_from = Value
  ) %>%
  # Optionally, drop rows where either Baseline or Follow_up is missing
  drop_na(Baseline, Follow_up)

cat("  Wide format created:", nrow(df_wide), "rows (complete pairs only)\n")

# Preview the Wide (Pivoted) Data
cat("  Wide format preview:\n")
print(head(df_wide, 10))

cat("Data transformation (original values) completed successfully.\n")

# EOF
