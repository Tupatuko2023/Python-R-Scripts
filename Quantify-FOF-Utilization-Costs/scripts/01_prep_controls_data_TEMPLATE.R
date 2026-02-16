#!/usr/bin/env Rscript
# ==============================================================================
# SECURE ETL TEMPLATE: Matched Control Cohort Preparation (Table 3)
#
# PURPOSE: 
#   Transform raw controls data (e.g., Verrokit.XLSX) into analysis-ready 
#   pseudonymized CSV files based on a matched case-control design.
#
# REPRODUCIBILITY & SECURITY:
#   - Inherits FOF_status and Index Date from the matched Case.
#   - Calculates age at case index date using control's own birth date (HETU).
#   - Drops PII (HETU) before export to panel.
#
# INPUTS (Secure Environment):
#   - DATA_ROOT/paper_02/Verrokit.XLSX (Control Roster)
#   - DATA_ROOT/derived/aim2_analysis.csv (Processed Case Data)
#   - DATA_ROOT/derived/link_table.csv (Case ID -> Register ID mapping)
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

PATH_RAW_EXCEL   <- file.path(DATA_ROOT, "paper_02", "Verrokit.XLSX")
PATH_AIM2_CASE   <- file.path(DATA_ROOT, "derived", "aim2_analysis.csv")
PATH_CASE_LINK   <- file.path(DATA_ROOT, "derived", "link_table.csv")
PATH_DERIVED     <- file.path(DATA_ROOT, "derived")

# Roster column names (Verrokit.XLSX):
COL_CASE_REF     <- "Tutkimushenkilon_nro" # Link to matched case's register_id
COL_CTRL_ID      <- "Verrokin_nro"         # Control's own roster ID (e.g., register_id)
COL_CTRL_HETU    <- "Verrokin_HETU"        # Control's PII (for age/sex)

# Control follow-up end date column (e.g., death, move, or study end 2019-12-31)
DATE_CTRL_END    <- "seuranta_loppu_pvm" 

# Case index date source (usually the interview/baseline date)
# In aim2_analysis.csv, we might need to extract this if not present.
# For this template, we assume it's calculated or available.
# ------------------------------------------------------------------------------

# 01) Load Data
if (!file.exists(PATH_RAW_EXCEL)) stop("Roster not found: ", PATH_RAW_EXCEL)
if (!file.exists(PATH_AIM2_CASE)) stop("Case analysis data not found: ", PATH_AIM2_CASE)
if (!file.exists(PATH_CASE_LINK)) stop("Case link table not found: ", PATH_CASE_LINK)

df_roster <- read_excel(PATH_RAW_EXCEL, sheet = "Tulostiedot")
df_case   <- read_csv(PATH_AIM2_CASE)
df_clink  <- read_csv(PATH_CASE_LINK)

# 02) Prepare Case Reference
# We need to map case's analysis 'id' to roster's 'Tutkimushenkilon_nro' (register_id)
df_case_ref <- df_case %>%
  inner_join(df_clink, by = "id") %>%
  select(register_id, FOF_status, case_age = age, case_sex = sex) %>%
  # Note: in real study, index_date (baseline) should be extracted from case data
  # For now, we assume a placeholder if not present.
  mutate(index_date = as.Date("2010-01-01")) # FIXME: use actual case index date

# 03) Join Controls to matched Cases
df_joined <- df_roster %>%
  rename(register_id_case = !!sym(COL_CASE_REF), 
         register_id_ctrl = !!sym(COL_CTRL_ID),
         hetu_ctrl        = !!sym(COL_CTRL_HETU)) %>%
  inner_join(df_case_ref, by = c("register_id_case" = "register_id"))

# 04) Transformation Logic (Matched Design)
set.seed(20260216)
df_processed <- df_joined %>%
  mutate(
    # --- ANALYSIS ID ---
    # Create unique analysis ID: CASE_ID + _CTRL_ + control_seq
    # (Simplified for template)
    id = paste0("CTRL_", sprintf("%04d", row_number())),

    # --- SEX & BIRTH DATE FROM HETU ---
    # Individual number (chars 8-10): odd=male(1), even=female(2)
    sex = as.numeric(substr(hetu_ctrl, 8, 10)),
    sex = ifelse(sex %% 2 == 0, 2, 1),

    century = case_when(
      substr(hetu_ctrl, 7, 7) == "+" ~ 1800,
      substr(hetu_ctrl, 7, 7) == "-" ~ 1900,
      substr(hetu_ctrl, 7, 7) == "A" ~ 2000,
      TRUE ~ 1900
    ),
    birth_year = century + as.numeric(substr(hetu_ctrl, 5, 6)),
    birth_date = as.Date(paste0(birth_year, "-", substr(hetu_ctrl, 3, 4), "-", substr(hetu_ctrl, 1, 2))),

    # --- AGE AT CASE INDEX DATE ---
    age = as.numeric(difftime(index_date, birth_date, units = "days")) / 365.25,

    # --- FOLLOW-UP (PY) ---
    # Control follow-up starts at Case's index date
    py = as.numeric(difftime(as.Date(!!sym(DATE_CTRL_END)), index_date, units = "days")) / 365.25,

    # --- PROPAGATED CONSTANTS ---
    case_status = "control"
    # FOF_status is inherited from case (already in df_joined)
  ) %>%
  filter(py > 0) # Basic QC: must have follow-up

# 05) Create LINK TABLE (Anonymized ID -> Roster register ID)
df_link <- df_processed %>%
  select(id, register_id = register_id_ctrl)

# 06) Create PANEL (Safe for Export)
# STRICT SECURITY: drop HETU and case register IDs before export
df_panel <- df_processed %>%
  select(id, case_status, FOF_status, age, sex, py)

# 07) Save Outputs
if (!dir.exists(PATH_DERIVED)) dir.create(PATH_DERIVED, recursive = TRUE)

write_csv(df_link,  file.path(PATH_DERIVED, "controls_link_table.csv"))
write_csv(df_panel, file.path(PATH_DERIVED, "controls_panel.csv"))

cat("ETL Complete.\n")
cat("Matched design applied: FOF_status propagated from Case to Control.\n")
cat("Export-safe panel saved to: derived/controls_panel.csv\n")
cat("Link table saved to:       derived/controls_link_table.csv\n")
