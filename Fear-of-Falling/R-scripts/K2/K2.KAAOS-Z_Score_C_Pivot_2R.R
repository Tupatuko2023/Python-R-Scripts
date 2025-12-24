#!/usr/bin/env Rscript
# ==============================================================================
# K2_2R - Z-Score Pivot & Transpose (2 Repeated Measures - Legacy)
# File tag: K2_2R.V1_zscore-pivot-2r.R
# Purpose: Transpose KAAOS z-score change output (legacy/alternative version)
#
# NOTE: This is an alternative version that processes KAAOS-Z_Score_Change_2R.csv
#       The primary K2 script is K2.Z_Score_C_Pivot_2G.R which processes K1 output.
#       This script is maintained for backward compatibility with legacy data.
#
# Input: KAAOS-Z_Score_Change_2R.csv (from vanha.P-Sote/taulukot/ or equivalent)
# Output: KAAOS-Z_Score_Change_Transposed.csv (transposed format)
#
# Required vars (from input CSV, DO NOT INVENT; must match req_cols):
# kaatumisenpelkoOn, Testi (note: "Testi" not "Test" in this version)
#
# Transformation logic:
# 1. Recode test names to include FOF status (e.g., "Kävelynopeus" + FOF=0 → "MWS_Without_FOF")
# 2. Remove kaatumisenpelkoOn column (info now in test names)
# 3. Transpose data frame (tests become columns, parameters become rows)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: Not needed (no randomness; data transformation only)
#
# Outputs + manifest:
# - script_label: K2_2R (canonical)
# - outputs dir: R-scripts/K2/outputs/ (resolved via init_paths("K2_2R"))
# - manifest: append 1 row for CSV to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths) [DONE]
# 02) Load input data (KAAOS-Z_Score_Change_2R.csv)
# 03) Verify required columns exist
# 04) Recode test names by FOF status
# 05) Remove kaatumisenpelkoOn column
# 06) Transpose data frame
# 07) Save transposed output with manifest logging
# 08) EOF marker
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(tibble)
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K2_2R.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K2_2R"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
# Map K2.KAAOS to "K2_2R" for outputs directory
if (grepl("KAAOS", script_label)) script_label <- "K2_2R"
if (is.na(script_label) || script_label == "") script_label <- "K2_2R"

# init_paths() must set outputs_dir + manifest_path
source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K2_2R Script - Z-Score Change Data Transpose (Legacy 2R Version)\n")
cat("================================================================================\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# Required columns from input CSV
req_cols <- c("kaatumisenpelkoOn", "Testi")

cat("Loading input data...\n")
# Try multiple possible locations for the input file
possible_paths <- c(
  here::here("data", "processed", "KAAOS-Z_Score_Change_2R.csv"),
  here::here("vanha.P-Sote", "taulukot", "KAAOS-Z_Score_Change_2R.csv"),
  here::here("tables", "KAAOS-Z_Score_Change_2R.csv")
)

input_path <- NULL
for (path in possible_paths) {
  if (file.exists(path)) {
    input_path <- path
    break
  }
}

if (is.null(input_path)) {
  stop("Input file not found. Tried the following locations:\n",
       paste("  -", possible_paths, collapse = "\n"), "\n",
       "Please ensure KAAOS-Z_Score_Change_2R.csv is available or use K2.Z_Score_C_Pivot_2G.R instead.")
}

cat("  Loading from:", input_path, "\n")
df <- read_csv(input_path, show_col_types = FALSE)
cat("  Data loaded:", nrow(df), "rows,", ncol(df), "columns\n")

# Verify required columns exist
missing_cols <- setdiff(req_cols, names(df))
if (length(missing_cols) > 0) {
  stop("Missing required columns in input file: ", paste(missing_cols, collapse = ", "))
}

cat("  Required columns present: TRUE\n")

# Recode test names by FOF status
cat("\nRecoding test names by FOF status...\n")
df <- df %>%
  mutate(Testi = case_when(
    Testi == "Kävelynopeus" & kaatumisenpelkoOn == 0 ~ "MWS_Without_FOF",
    Testi == "Kävelynopeus" & kaatumisenpelkoOn == 1 ~ "MWS_With_FOF",
    Testi == "Puristusvoima" & kaatumisenpelkoOn == 0 ~ "HGS_Without_FOF",
    Testi == "Puristusvoima" & kaatumisenpelkoOn == 1 ~ "HGS_With_FOF",
    Testi == "Seisominen" & kaatumisenpelkoOn == 0 ~ "SLS_Without_FOF",
    Testi == "Seisominen" & kaatumisenpelkoOn == 1 ~ "SLS_With_FOF",
    Testi == "Tuoliltanousu" & kaatumisenpelkoOn == 0 ~ "FTSST_Without_FOF",
    Testi == "Tuoliltanousu" & kaatumisenpelkoOn == 1 ~ "FTSST_With_FOF",
    TRUE ~ Testi  # Leave other names unchanged
  ))

# Remove kaatumisenpelkoOn column (info now in Testi names)
cat("  Removing kaatumisenpelkoOn column (info now in test names)...\n")
df <- df %>% select(-kaatumisenpelkoOn)

# Transpose the data frame
cat("\nTransposing data frame...\n")
df_transposed <- df %>%
  column_to_rownames(var = "Testi") %>%
  t() %>%
  as.data.frame() %>%
  rownames_to_column(var = "Parameter")

cat("  Transposed structure:\n")
cat("    Rows (parameters):", nrow(df_transposed), "\n")
cat("    Columns (tests + Parameter):", ncol(df_transposed), "\n")

# Preview transposed table
cat("\nTransposed table preview (first 10 rows):\n")
print(head(df_transposed, 10))

# Save transposed output with manifest logging
cat("\nSaving transposed output...\n")
save_table_csv_html(
  df_transposed,
  label = "KAAOS-Z_Score_Change_Transposed",
  n = nrow(df_transposed),
  write_html = FALSE
)

cat("\n================================================================================\n")
cat("K2_2R Script completed successfully.\n")
cat("Output saved to:", file.path(outputs_dir, "KAAOS-Z_Score_Change_Transposed.csv"), "\n")
cat("Manifest updated:", manifest_path, "\n")
cat("NOTE: This is the legacy 2R version. Consider using K2.Z_Score_C_Pivot_2G.R\n")
cat("      for processing current K1 pipeline outputs.\n")
cat("================================================================================\n")

# EOF
