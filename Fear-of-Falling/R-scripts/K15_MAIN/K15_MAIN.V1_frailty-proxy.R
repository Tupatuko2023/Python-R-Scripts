#!/usr/bin/env Rscript
# ==============================================================================
# K15_MAIN - Fried-inspired frailty proxy derivation
# File tag: K15_MAIN.V1_frailty-proxy.R
# Purpose: Derive frailty indicators and categories for K16 analyses
#
# Outcome: None (derives frailty variables)
# Grouping variable: frailty_cat_3 ("robust"/"pre-frail"/"frail")
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# Puristus0, Puristus2, kavelynopeus_m_sek0, kavelynopeus_m_sek2,
# Tuoli0, Tuoli2, Seisominen0, Seisominen2, BMI, sex, age,
# PainVAS0, SRH or koettuterveydentila, oma_arvio_liikuntakyky, kaatuminen
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K15_MAIN (canonical)
# - outputs dir: R-scripts/K15_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
# - Primary output: K15_frailty_analysis_data.RData
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tidyr)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K15_MAIN"
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K15_MAIN"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K15 Fried-inspired frailty proxy\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

# --- Load raw data (immutable) -----------------------------------------------
raw_path <- here::here("data", "external", "KaatumisenPelko.csv")
if (!file.exists(raw_path)) stop("Raw data not found: ", raw_path)

raw_data <- readr::read_csv(raw_path, show_col_types = FALSE)

# --- Required columns gate (DO NOT INVENT) ----------------------------------
req_cols <- c(
  "kaatumisenpelkoOn", "ToimintaKykySummary0", "ToimintaKykySummary2",
  "Puristus0", "Puristus2", "kavelynopeus_m_sek0", "kavelynopeus_m_sek2",
  "Tuoli0", "Tuoli2", "Seisominen0", "Seisominen2",
  "BMI", "sex", "age", "PainVAS0", "oma_arvio_liikuntakyky", "kaatuminen"
)
missing_cols <- setdiff(req_cols, names(raw_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

# --- Standardize + QC --------------------------------------------------------
df <- standardize_analysis_vars(raw_data)
qc <- sanity_checks(df)
qc_path <- file.path(outputs_dir, paste0(script_label, "_qc_sanity_checks.csv"))
save_table_csv(qc, qc_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_sanity_checks",
    path = get_relpath(qc_path),
    kind = "table_csv",
    n = nrow(qc)
  ),
  manifest_path
)

# --- Frailty thresholds ------------------------------------------------------
gait_cut_m_per_sec <- 0.8
low_BMI_threshold <- 21

analysis_data <- df %>%
  mutate(
    FOF_status = case_when(
      is.na(kaatumisenpelkoOn) ~ NA_integer_,
      kaatumisenpelkoOn == 1 ~ 1L,
      kaatumisenpelkoOn == 0 ~ 0L,
      TRUE ~ NA_integer_
    ),
    FOF_status_factor = factor(FOF_status, levels = c(0, 1), labels = c("nonFOF", "FOF")),
    sex_factor = factor(sex, levels = c(0, 1), labels = c("female", "male")),
    Puristus0_clean = if_else(!is.na(Puristus0) & Puristus0 <= 0, NA_real_, Puristus0)
  )

grip_cuts <- analysis_data %>%
  filter(!is.na(Puristus0_clean), !is.na(sex_factor)) %>%
  group_by(sex_factor) %>%
  summarise(cut_Q1 = quantile(Puristus0_clean, probs = 0.25, na.rm = TRUE), .groups = "drop")

grip_cut_vec <- setNames(grip_cuts$cut_Q1, as.character(grip_cuts$sex_factor))

analysis_data <- analysis_data %>%
  mutate(
    frailty_weakness = case_when(
      is.na(Puristus0_clean) | is.na(sex_factor) ~ NA_integer_,
      Puristus0_clean <= grip_cut_vec[as.character(sex_factor)] ~ 1L,
      TRUE ~ 0L
    ),
    frailty_slowness = case_when(
      is.na(kavelynopeus_m_sek0) ~ NA_integer_,
      kavelynopeus_m_sek0 < gait_cut_m_per_sec ~ 1L,
      TRUE ~ 0L
    ),
    frailty_low_activity = case_when(
      is.na(oma_arvio_liikuntakyky) & is.na(kaatuminen) & is.na(PainVAS0) ~ NA_integer_,
      oma_arvio_liikuntakyky %in% c(0, 1) ~ 1L,
      kaatuminen == 1 ~ 1L,
      is.na(oma_arvio_liikuntakyky) | is.na(kaatuminen) | is.na(PainVAS0) ~ NA_integer_,
      TRUE ~ 0L
    ),
    frailty_low_BMI = case_when(
      is.na(BMI) ~ NA_integer_,
      BMI < low_BMI_threshold ~ 1L,
      TRUE ~ 0L
    ),
    frailty_count_3 = frailty_weakness + frailty_slowness + frailty_low_activity,
    frailty_cat_3 = case_when(
      is.na(frailty_count_3) ~ NA_character_,
      frailty_count_3 == 0 ~ "robust",
      frailty_count_3 == 1 ~ "pre-frail",
      frailty_count_3 >= 2 ~ "frail"
    ),
    frailty_cat_3 = factor(frailty_cat_3, levels = c("robust", "pre-frail", "frail"))
  )

tab_frailty_cat_3 <- analysis_data %>%
  count(frailty_cat_3)
save_table_csv_html(tab_frailty_cat_3, "frailty_cat_3_overall", n = nrow(tab_frailty_cat_3))

tab_frailty_cat3_by_FOF <- analysis_data %>%
  filter(!is.na(FOF_status_factor), !is.na(frailty_cat_3)) %>%
  count(FOF_status_factor, frailty_cat_3) %>%
  group_by(FOF_status_factor) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  ungroup()
save_table_csv_html(tab_frailty_cat3_by_FOF, "frailty_cat3_by_FOF", n = nrow(tab_frailty_cat3_by_FOF))

out_rdata <- file.path(outputs_dir, "K15_frailty_analysis_data.RData")
save(analysis_data, file = out_rdata)
append_manifest(
  manifest_row(
    script = script_label,
    label = "frailty_analysis_data_rdata",
    path = get_relpath(out_rdata),
    kind = "rdata",
    n = nrow(analysis_data)
  ),
  manifest_path
)

txt_path <- file.path(outputs_dir, paste0(script_label, "_summary.txt"))
writeLines(
  c(
    "K15_MAIN frailty proxy derivation",
    paste0("N total: ", nrow(analysis_data)),
    "Frailty categories: robust (0), pre-frail (1), frail (>=2)",
    "See CSV outputs for category distributions."
  ),
  con = txt_path
)
append_manifest(
  manifest_row(
    script = script_label,
    label = "summary_txt",
    path = get_relpath(txt_path),
    kind = "text",
    n = NA_integer_
  ),
  manifest_path
)

save_sessioninfo_manifest()
