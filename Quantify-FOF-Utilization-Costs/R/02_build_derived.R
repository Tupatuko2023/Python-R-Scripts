#!/usr/bin/env Rscript
# ==============================================================================
# 02_build_derived.R
# Purpose: Build analysis-ready datasets from staging data.
# Usage: Rscript R/02_build_derived.R
# ==============================================================================

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(readr)
  library(stringr)
  if (requireNamespace("digest", quietly = TRUE)) library(digest)
})

# Load common utilities
common_script <- file.path("R", "common.R")
if (!file.exists(common_script)) {
  common_script <- file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)[1])), "common.R")
}
if (file.exists(common_script)) {
  source(common_script)
} else {
  stop("common.R not found. Please run from project root.")
}

DATA_ROOT <- ensure_data_root()

staging_dir <- file.path(DATA_ROOT, "staging")
derived_dir <- file.path(DATA_ROOT, "derived")
if (!dir.exists(derived_dir)) dir.create(derived_dir, recursive = TRUE)

# --- 1. Load Staging Data ---
kaaos_path <- file.path(staging_dir, "paper_02_kaaos.parquet")
if (!file.exists(kaaos_path)) stop("paper_02_kaaos.parquet missing in staging.")
df_kaaos <- arrow::read_parquet(kaaos_path)

sotut_path <- file.path(staging_dir, "paper_02_sotut.parquet")
# Use sotut if available
has_sotut <- file.exists(sotut_path)
if (has_sotut) {
  df_sotut <- arrow::read_parquet(sotut_path)
} else {
  warning("paper_02_sotut.parquet missing. Frailty lookup may fail if relying on it.")
}

# --- 2. Load Frailty Source (aim2_panel.csv) ---
# Assuming aim2_panel.csv is already in derived (from previous pipeline or external)
panel_path <- file.path(derived_dir, "aim2_panel.csv")
has_panel <- file.exists(panel_path)

# --- 3. Build Table 1 Cohort ---
# Standardize KAAOS
df_cohort <- df_kaaos %>%
  mutate(
    # Basic cleaning
    age = as.integer(age),
    sex = as.integer(sex),
    FOF = as.integer(FOF),
    bmi = as.numeric(bmi)
  )

# --- Frailty Lookup Logic (Simplified/Standardized) ---
if (has_panel && has_sotut) {
  message("Performing Frailty Lookup...")

  # Prepare panel frailty
  df_panel <- read_csv(panel_path, show_col_types = FALSE) %>%
    select(id, frailty_fried) %>%
    distinct(id, .keep_all = TRUE)

  # Prepare crosswalk
  df_cw <- df_sotut %>%
    select(nro, sotu) %>%
    mutate(nro = as.character(nro), sotu = as.character(sotu))

  df_cohort <- df_cohort %>%
    mutate(id_char = as.character(id)) %>%
    left_join(df_cw, by = c("id_char" = "nro")) %>%
    left_join(df_panel, by = c("sotu" = "id")) %>%
    mutate(
      frailty3 = case_when(
        frailty_fried %in% c("robust", "rob", "0") ~ "robust",
        frailty_fried %in% c("pre-frail", "prefrail", "1", "2") ~ "pre-frail",
        frailty_fried %in% c("frail", "3") ~ "frail",
        TRUE ~ "unknown"
      )
    )
} else {
  message("Skipping Frailty Lookup (missing dependencies).")
  df_cohort$frailty3 <- "unknown"
}

# --- 4. Save Derived ---
output_path <- file.path(derived_dir, "table1_cohort.parquet")
arrow::write_parquet(df_cohort, output_path)
log_manifest(output_path, "02_build_derived.R", DATA_ROOT)

message("Built derived/table1_cohort.parquet")
