#!/usr/bin/env Rscript
# ==============================================================================
# K04_MAIN - Original Values Pivot & Transpose (2 Groups)
# File tag: K04_MAIN.V1_values-pivot-2g.R
# Purpose: Transpose K03 original values output from long to wide format by FOF status
#
# Input: K3_Values_2G.csv from K03 outputs
# Output: K4_Values_2G_Transposed.csv (transposed: parameters as rows, tests as columns)
#
# Required vars (from K03 output, DO NOT INVENT; must match req_cols):
# kaatumisenpelkoOn, Test (plus all statistical columns from K3.6)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: Not needed (no randomness; data transformation only)
#
# Outputs + manifest:
# - script_label: K04_MAIN (canonical)
# - outputs dir: R-scripts/K04_MAIN/outputs/  (resolved via init_paths(script_label))
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
  "K04_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K04_MAIN"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K04 Script - Original Values Data Transpose (2 Groups)\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# Required columns from K03 output
req_cols <- c("kaatumisenpelkoOn", "Test")

cat("Loading K03 output data...\n")
k03_out_path <- if (exists("paths") && is.list(paths) && ("root_dir" %in% names(paths))) {
  file.path(paths$root_dir, "R-scripts", "K03_MAIN", "outputs", "K3_Values_2G.csv")
} else {
  here::here("R-scripts", "K03_MAIN", "outputs", "K3_Values_2G.csv")
}
if (!file.exists(k03_out_path)) {
  stop("K03 output file not found: ", k03_out_path, "\n",
       "Please run K03_MAIN first: Rscript R-scripts/K03_MAIN/K03_MAIN.V1_original-values.R")
}

df <- read_csv(k03_out_path, show_col_types = FALSE)
cat("  K03 data loaded:", nrow(df), "rows,", ncol(df), "columns\n")

# Verify required columns exist
missing_cols <- setdiff(req_cols, names(df))
if (length(missing_cols) > 0) {
  stop("Missing required columns in K03 output: ", paste(missing_cols, collapse = ", "))
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
    TRUE ~ Test
  ))

# Rename Test column to Performance_Test for clarity
df <- df %>% rename(Performance_Test = Test)

# Remove kaatumisenpelkoOn column (info now in Performance_Test names)
cat("  Removing kaatumisenpelkoOn column (info now in test names)...\n")
df <- df %>% select(-kaatumisenpelkoOn)

# Ensure Performance_Test values are unique (fail-fast; do not mask upstream issues)
df <- df %>% mutate(Performance_Test = as.character(Performance_Test))
dup_tab <- df %>%
  dplyr::count(Performance_Test, name = "n") %>%
  dplyr::filter(.data$n > 1L)
if (nrow(dup_tab) > 0L) {
  stop(
    "Duplicate Performance_Test labels detected in K03-derived input. ",
    "Expected one row per test label. Duplicates: ",
    paste0(dup_tab$Performance_Test, " (n=", dup_tab$n, ")", collapse = "; ")
  )
}

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
cat("K04 Script completed successfully.\n")
cat("Output saved to:", file.path(outputs_dir, "K4_Values_2G_Transposed.csv"), "\n")
cat("Manifest updated:", manifest_path, "\n")
cat("================================================================================\n")

# EOF
