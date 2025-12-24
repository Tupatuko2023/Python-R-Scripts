#!/usr/bin/env Rscript
# ==============================================================================
# K4 - Original Values Pivot & Transpose (2 Groups)
# File tag: K4.V1_values-pivot-2g.R
# Purpose: Transpose K3 original values output from long to wide format by FOF status
#
# Input: K3_Values_2G.csv from K3 outputs (wide statistical table by group and test)
# Output: K4_Values_2G_Transposed.csv (transposed: parameters as rows, tests as columns)
#
# Required vars (from K3 output, DO NOT INVENT; must match req_cols):
# kaatumisenpelkoOn, Test (plus all statistical columns from K3.6)
#
# Transformation logic:
# 1. Recode test names to include FOF status (e.g., "MWS" + FOF=0 → "MWS_Without_FOF")
# 2. Remove kaatumisenpelkoOn column (info now in test names)
# 3. Transpose data frame (tests become columns, parameters become rows)
# 4. Rename columns for clarity
#
# Note: This is identical to K2 logic but operates on K3 outputs (original values) instead of K1 (z-scores)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: Not needed (no randomness; data transformation only)
#
# Outputs + manifest:
# - script_label: K4 (canonical)
# - outputs dir: R-scripts/K4/outputs/ (resolved via init_paths("K4"))
# - manifest: append 1 row for CSV to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths) [DONE]
# 02) Load K3 output data (K3_Values_2G.csv)
# 03) Verify required columns exist
# 04) Recode test names by FOF status
# 05) Remove kaatumisenpelkoOn column
# 06) Transpose data frame
# 07) Rename columns for clarity
# 08) Save transposed output with manifest logging
# 09) EOF marker
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(tibble)
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K4.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K4"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
# Map K4.A_Score_C_Pivot_2G to "K4" for outputs directory
if (grepl("^K4", script_label)) script_label <- "K4"
if (is.na(script_label) || script_label == "") script_label <- "K4"

# init_paths() must set outputs_dir + manifest_path
source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K4 Script - Original Values Data Transpose (2 Groups)\n")
cat("================================================================================\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# Required columns from K3 output
req_cols <- c("kaatumisenpelkoOn", "Test")

cat("Loading K3 output data...\n")
# Load K3 output (should be in R-scripts/K3/outputs/)
k3_output_path <- here::here("R-scripts", "K3", "outputs", "K3_Values_2G.csv")

if (!file.exists(k3_output_path)) {
  stop("K3 output file not found: ", k3_output_path, "\n",
       "Please run K3 pipeline first: Rscript R-scripts/K3/K3.7.main.R")
}

df <- read_csv(k3_output_path, show_col_types = FALSE)
cat("  K3 data loaded:", nrow(df), "rows,", ncol(df), "columns\n")

# Verify required columns exist
missing_cols <- setdiff(req_cols, names(df))
if (length(missing_cols) > 0) {
  stop("Missing required columns in K3 output: ", paste(missing_cols, collapse = ", "))
}

cat("  Required columns present: TRUE\n")

# Recode test names by FOF status
cat("\nRecoding test names by FOF status...\n")
df <- df %>%
  mutate(Test = case_when(
    Test == "Kävelynopeus" & kaatumisenpelkoOn == 0 ~ "MWS_Without_FOF",
    Test == "Kävelynopeus" & kaatumisenpelkoOn == 1 ~ "MWS_With_FOF",
    Test == "Puristusvoima" & kaatumisenpelkoOn == 0 ~ "HGS_Without_FOF",
    Test == "Puristusvoima" & kaatumisenpelkoOn == 1 ~ "HGS_With_FOF",
    Test == "Seisominen" & kaatumisenpelkoOn == 0 ~ "SLS_Without_FOF",
    Test == "Seisominen" & kaatumisenpelkoOn == 1 ~ "SLS_With_FOF",
    Test == "Tuoliltanousu" & kaatumisenpelkoOn == 0 ~ "FTSST_Without_FOF",
    Test == "Tuoliltanousu" & kaatumisenpelkoOn == 1 ~ "FTSST_With_FOF",
    Test == "FTSST" & kaatumisenpelkoOn == 0 ~ "FTSST_Without_FOF",
    Test == "FTSST" & kaatumisenpelkoOn == 1 ~ "FTSST_With_FOF",
    Test == "MWS" & kaatumisenpelkoOn == 0 ~ "MWS_Without_FOF",
    Test == "MWS" & kaatumisenpelkoOn == 1 ~ "MWS_With_FOF",
    Test == "SLS" & kaatumisenpelkoOn == 0 ~ "SLS_Without_FOF",
    Test == "SLS" & kaatumisenpelkoOn == 1 ~ "SLS_With_FOF",
    Test == "HGS" & kaatumisenpelkoOn == 0 ~ "HGS_Without_FOF",
    Test == "HGS" & kaatumisenpelkoOn == 1 ~ "HGS_With_FOF",
    Test == "VAS" & kaatumisenpelkoOn == 0 ~ "VAS_Without_FOF",
    Test == "VAS" & kaatumisenpelkoOn == 1 ~ "VAS_With_FOF",
    TRUE ~ Test  # Leave other names unchanged
  ))

# Rename Test column to Performance_Test for clarity
df <- df %>% rename(Performance_Test = Test)

# Remove kaatumisenpelkoOn column (info now in Performance_Test names)
cat("  Removing kaatumisenpelkoOn column (info now in test names)...\n")
df <- df %>% select(-kaatumisenpelkoOn)

# Ensure Performance_Test values are unique
df <- df %>% mutate(Performance_Test = make.unique(as.character(Performance_Test)))

# Transpose the data frame
cat("\nTransposing data frame...\n")
df_transposed <- df %>%
  column_to_rownames(var = "Performance_Test") %>%
  t() %>%
  as.data.frame() %>%
  rownames_to_column(var = "Parameter")

cat("  Transposed structure:\n")
cat("    Rows (parameters):", nrow(df_transposed), "\n")
cat("    Columns (tests + Parameter):", ncol(df_transposed), "\n")

# Rename transposed columns for clarity
cat("  Renaming columns for clarity...\n")
# Note: Column names may have .1, .2 suffixes if duplicates exist
# This renaming handles both Finnish and English test names

# Standard 4 tests (FTSST, HGS, MWS, SLS)
if ("FTSST" %in% names(df_transposed)) {
  df_transposed <- df_transposed %>%
    rename(
      FTSST_Without_FOF = "FTSST",
      HGS_Without_FOF   = "HGS",
      MWS_Without_FOF   = "MWS",
      SLS_Without_FOF   = "SLS"
    )
}

if ("FTSST.1" %in% names(df_transposed)) {
  df_transposed <- df_transposed %>%
    rename(
      FTSST_With_FOF = "FTSST.1",
      HGS_With_FOF   = "HGS.1",
      MWS_With_FOF   = "MWS.1",
      SLS_With_FOF   = "SLS.1"
    )
}

# VAS (if present in K3 output)
if ("VAS" %in% names(df_transposed)) {
  df_transposed <- df_transposed %>%
    rename(VAS_Without_FOF = "VAS")
}

if ("VAS.1" %in% names(df_transposed)) {
  df_transposed <- df_transposed %>%
    rename(VAS_With_FOF = "VAS.1")
}

# Preview transposed table
cat("\nTransposed table preview (first 10 rows):\n")
print(head(df_transposed, 10))

# Save transposed output with manifest logging
cat("\nSaving transposed output...\n")
save_table_csv_html(
  df_transposed,
  label = "K4_Values_2G_Transposed",
  n = nrow(df_transposed),
  write_html = FALSE
)

cat("\n================================================================================\n")
cat("K4 Script completed successfully.\n")
cat("Output saved to:", file.path(outputs_dir, "K4_Values_2G_Transposed.csv"), "\n")
cat("Manifest updated:", manifest_path, "\n")
cat("================================================================================\n")

# EOF
