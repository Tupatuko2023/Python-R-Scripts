#!/usr/bin/env Rscript
# ==============================================================================
# K02_MAIN - Z-Score Pivot & Transpose (2 Groups)
# File tag: K02_MAIN.V1_zscore-pivot-2g.R
# Purpose: Transpose K01 z-score change output from long to wide format by FOF status
#
# Input: K1_Z_Score_Change_2G.csv from K01 outputs
# Output: K2_Z_Score_Change_2G_Transposed.csv (transposed: parameters as rows, tests as columns)
#
# Required vars (from K01 output, DO NOT INVENT; must match req_cols):
# kaatumisenpelkoOn, Test (plus all statistical columns from K1.6)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: Not needed (no randomness; data transformation only)
#
# Outputs + manifest:
# - script_label: K02_MAIN (canonical)
# - outputs dir: R-scripts/K02_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row for CSV to manifest/manifest.csv
# ==============================================================================
#
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(tibble)
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K02_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K02_MAIN"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K02 Script - Z-Score Change Data Transpose (2 Groups)\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# Required columns from K01 output
req_cols <- c("kaatumisenpelkoOn", "Test")

cat("Loading K01 output data...\n")
k01_output_path <- here::here("R-scripts", "K01_MAIN", "outputs", "K1_Z_Score_Change_2G.csv")
if (!file.exists(k01_output_path)) {
  stop("K01 output file not found: ", k01_output_path, "\n",
       "Please run K01_MAIN first: Rscript R-scripts/K01_MAIN/K01_MAIN.V1_zscore-change.R")
}

df <- read_csv(k01_output_path, show_col_types = FALSE)
cat("  K01 data loaded:", nrow(df), "rows,", ncol(df), "columns\n")

# Verify required columns exist
missing_cols <- setdiff(req_cols, names(df))
if (length(missing_cols) > 0) {
  stop("Missing required columns in K01 output: ", paste(missing_cols, collapse = ", "))
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
    TRUE ~ Test
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

# Rename transposed columns for clarity (legacy naming)
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
cat("K02 Script completed successfully.\n")
cat("Output saved to:", file.path(outputs_dir, "K2_Z_Score_Change_2G_Transposed.csv"), "\n")
cat("Manifest updated:", manifest_path, "\n")
cat("================================================================================\n")

# EOF
