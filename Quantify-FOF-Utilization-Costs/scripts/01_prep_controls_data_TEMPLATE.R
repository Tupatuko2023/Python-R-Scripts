#!/usr/bin/env Rscript
# ==============================================================================
# SECURE ETL TEMPLATE: Control Cohort Preparation (Table 3)
#
# PURPOSE: 
#   Transform raw controls data (e.g., Verrokit.XLSX) into analysis-ready 
#   pseudonymized CSV files. 
#
# ENVIRONMENT:
#   This script MUST be run in a secure environment with access to RAW PII.
#   Only the outputs (derived/) should be moved to the analysis pipeline.
#
# INPUTS (Secure Environment):
#   - Path to raw control cohort Excel (e.g., DATA_ROOT/paper_02/Verrokit.XLSX)
#
# OUTPUTS (Export-Safe):
#   - DATA_ROOT/derived/controls_link_table.csv (id, register_id)
#   - DATA_ROOT/derived/controls_panel.csv (id, case_status, FOF_status, age, sex, py)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(readxl)
  library(readr)
})

# --- CONFIGURATION (FILL THIS) ------------------------------------------------
DATA_ROOT <- Sys.getenv("DATA_ROOT")
if (DATA_ROOT == "") stop("DATA_ROOT environment variable not set.")

PATH_RAW_EXCEL  <- file.path(DATA_ROOT, "paper_02", "Verrokit.XLSX")
PATH_DERIVED    <- file.path(DATA_ROOT, "derived")

# Column names in RAW data:
COL_RAW_ID      <- "Tutk.henkilön / verrokin henkilötunnus" # Register identifier (PII)
DATE_START_COL  <- "seuranta_alku_pvm"  # FILL IN ACTUAL COLUMN NAME
DATE_END_COL    <- "seuranta_loppu_pvm"   # FILL IN ACTUAL COLUMN NAME

# Optional columns (set to NULL if they must be parsed from HETU)
COL_RAW_AGE     <- NULL 
COL_RAW_SEX     <- NULL

# Project defaults
FOF_CONTROL_VALUE <- 0 # Default status for control group
# ------------------------------------------------------------------------------

# 01) Load data
if (!file.exists(PATH_RAW_EXCEL)) stop("Raw data not found at: ", PATH_RAW_EXCEL)
df_raw <- read_excel(PATH_RAW_EXCEL, sheet = "Tulostiedot")

# 02) Pseudonymization
# Generate a new unique analysis ID for each control
set.seed(20260216)
df_controls <- df_raw %>%
  select(register_id = !!sym(COL_RAW_ID), everything()) %>%
  distinct(register_id, .keep_all = TRUE) %>%
  mutate(id = paste0("CTRL_", sprintf("%04d", row_number())))

# 03) Transformation Logic
df_processed <- df_controls %>%
  mutate(
    # --- SEX & AGE PARSING ---
    # Logic: if COL_RAW_SEX is NULL, parse from HETU (register_id)
    sex = if (is.null(COL_RAW_SEX)) {
      # Finnish SSN individual number (chars 8-10): odd=male(1), even=female(2)
      individual_num = as.numeric(substr(register_id, 8, 10))
      ifelse(individual_num %% 2 == 0, 2, 1)
    } else {
      as.numeric(!!sym(COL_RAW_SEX))
    },
    
    age = if (is.null(COL_RAW_AGE)) {
      # Parsing birth year from HETU (simplified example)
      # ddmmYY-XXXX -> century based on separator
      century = case_when(
        substr(register_id, 7, 7) == "+" ~ 1800,
        substr(register_id, 7, 7) == "-" ~ 1900,
        substr(register_id, 7, 7) == "A" ~ 2000,
        TRUE ~ 1900
      )
      birth_year = century + as.numeric(substr(register_id, 5, 6))
      2020 - birth_year # Example age calculation at study baseline
    } else {
      as.numeric(!!sym(COL_RAW_AGE))
    },

    # --- FOLLOW-UP (PY) ---
    # Ensure columns are Date type
    py = as.numeric(difftime(as.Date(!!sym(DATE_END_COL)), 
                             as.Date(!!sym(DATE_START_COL)), 
                             units = "days")) / 365.25,

    # --- CONSTANTS ---
    FOF_status  = FOF_CONTROL_VALUE,
    case_status = "control"
  )

# 04) Create LINK TABLE (id <-> register_id)
df_link <- df_processed %>%
  select(id, register_id)

# 05) Create PANEL (Safe for Export)
# STRICT SECURITY: drop register_id and any other PII columns before saving panel
df_panel <- df_processed %>%
  select(id, case_status, FOF_status, age, sex, py)

# 06) Save Outputs
if (!dir.exists(PATH_DERIVED)) dir.create(PATH_DERIVED, recursive = TRUE)

write_csv(df_link,  file.path(PATH_DERIVED, "controls_link_table.csv"))
write_csv(df_panel, file.path(PATH_DERIVED, "controls_panel.csv"))

cat("ETL Complete.
")
cat("Export-safe panel saved to: derived/controls_panel.csv
")
cat("Link table saved to:       derived/controls_link_table.csv
")
