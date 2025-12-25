#!/usr/bin/env Rscript
# ==============================================================================
# K2 - Z-Score Pivot & Transpose (2 Groups)
# File tag: K2.V1_zscore-pivot-2g.R
# Purpose: Transpose K1 z-score change output from long to wide format by FOF status
#
# Input: K1_Z_Score_Change_2G.csv from K1 outputs (wide statistical table by group and test)
# Output: K2_Z_Score_Change_2G_Transposed.csv (transposed: parameters as rows, tests as columns)
#
# Required vars (from K1 output, DO NOT INVENT; must match req_cols):
# kaatumisenpelkoOn, Test (plus all statistical columns from K1.6)
#
# Transformation logic:
# 1. Recode test names to include FOF status (e.g., "MWS" + FOF=0 → "MWS_Without_FOF")
# 2. Remove kaatumisenpelkoOn column (info now in test names)
# 3. Transpose data frame (tests become columns, parameters become rows)
# 4. Rename columns for clarity
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: Not needed (no randomness; data transformation only)
#
# Outputs + manifest:
# - script_label: K2 (canonical)
# - outputs dir: R-scripts/K2/outputs/ (resolved via init_paths("K2"))
# - manifest: append 1 row for CSV to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths) [DONE]
# 02) Load K1 output data (K1_Z_Score_Change_2G.csv)
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
# Derive script_label from --file, supporting file tags like: K2.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K2"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
# Map K2.Z_Score_C_Pivot_2G to "K2" for outputs directory
if (grepl("^K2", script_label)) script_label <- "K2"
if (is.na(script_label) || script_label == "") script_label <- "K2"

# init_paths() must set outputs_dir + manifest_path
source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K2 Script - Z-Score Change Data Transpose (2 Groups)\n")
cat("================================================================================\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# Required columns from K1 output
req_cols <- c("kaatumisenpelkoOn", "Test")

cat("Loading K1 output data...\n")
# Load K1 output (should be in R-scripts/K1/outputs/)
k1_output_path <- here::here("R-scripts", "K1", "outputs", "K1_Z_Score_Change_2G.csv")

if (!file.exists(k1_output_path)) {
  stop("K1 output file not found: ", k1_output_path, "\n",
       "Please run K1 pipeline first: Rscript R-scripts/K1/K1.7.main.R")
}

df <- read_csv(k1_output_path, show_col_types = FALSE)
cat("  K1 data loaded:", nrow(df), "rows,", ncol(df), "columns\n")

# Verify required columns exist
missing_cols <- setdiff(req_cols, names(df))
if (length(missing_cols) > 0) {
  stop("Missing required columns in K1 output: ", paste(missing_cols, collapse = ", "))
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
# This renaming assumes standard K1 output with 4 tests × 2 groups = 8 columns

# Check which columns need renaming
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

# Preview transposed table
cat("\nTransposed table preview (first 10 rows):\n")
print(head(df_transposed, 10))

# Save transposed output with manifest logging
cat("\nSaving transposed output...\n")
save_table_csv_html(
  df_transposed,
  label = "K2_Z_Score_Change_2G_Transposed",
  n = nrow(df_transposed),
  write_html = FALSE
)

cat("\n================================================================================\n")
cat("K2 Script completed successfully.\n")
cat("Output saved to:", file.path(outputs_dir, "K2_Z_Score_Change_2G_Transposed.csv"), "\n")
cat("Manifest updated:", manifest_path, "\n")
cat("================================================================================\n")

# EOF
