#!/usr/bin/env Rscript
# ==============================================================================
# K11_MAIN - FOF as independent predictor of 12-month functional change
# File tag: K11_MAIN.V1_fof-independent-ancova.R
# Purpose: ANCOVA models of Delta_Composite_Z with base and extended covariates
#
# Outcome: Delta_Composite_Z (12-month change in composite physical function)
# Predictors: FOF_status_f
# Moderator/interaction: None (main effects)
# Grouping variable: None (wide format ANCOVA)
# Covariates (base): Composite_Z0, Age, Sex, BMI
# Covariates (extended): MOI_score, diabetes, alzheimer, parkinson, AVH,
#                        previous_falls, psych_score
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, age, sex, BMI, kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# MOIindeksiindeksi, diabetes, alzheimer, parkinson, AVH, kaatuminen, mieliala
#
# Mapping example (raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn (0/1) -> FOF_status -> FOF_status_f ("Ei FOF"/"FOF")
# age -> Age; sex -> Sex -> Sex_f (female/male)
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z2
# Delta_Composite_Z = Composite_Z2 - Composite_Z0
# MOIindeksiindeksi -> MOI_score
# kaatuminen -> previous_falls
# mieliala -> psych_score
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K11_MAIN (canonical)
# - outputs dir: R-scripts/K11_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Check required raw columns (req_raw_cols)
# 04) Standardize vars + QC (standardize_analysis_vars + sanity_checks)
# 05) Prepare analysis dataset (complete-case)
# 06) Fit base and extended ANCOVA models
# 07) Reporting tables (estimates + 95% CI; emmeans)
# 08) Save artifacts -> R-scripts/K11_MAIN/outputs/
# 09) Append manifest row per artifact
# 10) Save sessionInfo / renv diagnostics to manifest/
# 11) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(broom)
  library(emmeans)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K11_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K11_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K11_MAIN"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K11 FOF Independent Predictor ANCOVA\n")
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
req_raw_cols <- c(
  "id", "age", "sex", "BMI", "kaatumisenpelkoOn",
  "ToimintaKykySummary0", "ToimintaKykySummary2",
  "MOIindeksiindeksi", "diabetes", "alzheimer", "parkinson",
  "AVH", "kaatuminen", "mieliala"
)
missing_raw_cols <- setdiff(req_raw_cols, names(raw_data))
if (length(missing_raw_cols) > 0) {
  stop("Missing required columns: ", paste(missing_raw_cols, collapse = ", "))
}

# --- Standardize variable names and QC --------------------------------------
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

# --- Analysis dataset --------------------------------------------------------
dat_fof <- df %>%
  mutate(
    MOI_score = as.numeric(MOIindeksiindeksi),
    psych_score = as.numeric(mieliala),
    previous_falls = as.numeric(kaatuminen)
  ) %>%
  {
    bad_sex <- setdiff(stats::na.omit(unique(.$Sex)), c(0, 1))
    if (length(bad_sex) > 0L) {
      stop("Unexpected Sex code(s): ", paste(bad_sex, collapse = ", "), ". Expected 0/1 or NA.")
    }
    bad_fof <- setdiff(stats::na.omit(unique(.$FOF_status)), c(0, 1))
    if (length(bad_fof) > 0L) {
      stop("Unexpected FOF_status code(s): ", paste(bad_fof, collapse = ", "), ". Expected 0/1 or NA.")
    }
    .
  } %>%
  mutate(
    Sex_f = factor(Sex, levels = c(0, 1), labels = c("female", "male")),
    FOF_status_f = factor(FOF_status, levels = c(0, 1), labels = c("Ei FOF", "FOF")),
    diabetes_f = factor(diabetes, levels = c(0, 1), labels = c("No", "Yes")),
    alzheimer_f = factor(alzheimer, levels = c(0, 1), labels = c("No", "Yes")),
    parkinson_f = factor(parkinson, levels = c(0, 1), labels = c("No", "Yes")),
    AVH_f = factor(AVH, levels = c(0, 1), labels = c("No", "Yes")),
    previous_falls_f = factor(previous_falls, levels = c(0, 1), labels = c("No", "Yes"))
  ) %>%
  filter(
    !is.na(Composite_Z0), !is.na(Composite_Z2), !is.na(Delta_Composite_Z),
    !is.na(FOF_status), !is.na(Age), !is.na(Sex), !is.na(BMI)
  )

if (!nrow(dat_fof)) {
  stop("No complete-case data available for K11 ANCOVA.")
}

# --- Base model --------------------------------------------------------------
mod_base <- lm(
  Delta_Composite_Z ~ FOF_status_f + Composite_Z0 + Age + Sex_f + BMI,
  data = dat_fof
)

tab_base <- broom::tidy(mod_base, conf.int = TRUE)
tab_base_path <- file.path(outputs_dir, paste0(script_label, "_lm_base_model.csv"))
save_table_csv(tab_base, tab_base_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "lm_base_model",
    path = get_relpath(tab_base_path),
    kind = "table_csv",
    n = nrow(tab_base)
  ),
  manifest_path
)

emm_base <- as.data.frame(emmeans::emmeans(mod_base, ~ FOF_status_f))
emm_base_path <- file.path(outputs_dir, paste0(script_label, "_emmeans_base.csv"))
save_table_csv(emm_base, emm_base_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "emmeans_base",
    path = get_relpath(emm_base_path),
    kind = "table_csv",
    n = nrow(emm_base)
  ),
  manifest_path
)

# --- Extended model ----------------------------------------------------------
mod_ext <- lm(
  Delta_Composite_Z ~ FOF_status_f + Composite_Z0 + Age + Sex_f + BMI +
    MOI_score + diabetes_f + alzheimer_f + parkinson_f + AVH_f + previous_falls_f + psych_score,
  data = dat_fof
)

tab_ext <- broom::tidy(mod_ext, conf.int = TRUE)
tab_ext_path <- file.path(outputs_dir, paste0(script_label, "_lm_extended_model.csv"))
save_table_csv(tab_ext, tab_ext_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "lm_extended_model",
    path = get_relpath(tab_ext_path),
    kind = "table_csv",
    n = nrow(tab_ext)
  ),
  manifest_path
)

# --- Summary text ------------------------------------------------------------
txt_path <- file.path(outputs_dir, paste0(script_label, "_summary.txt"))
writeLines(
  c(
    "K11_MAIN FOF independent predictor ANCOVA",
    paste0("N complete-case: ", nrow(dat_fof)),
    "Base model: Delta_Composite_Z ~ FOF_status + Composite_Z0 + Age + Sex + BMI",
    "Extended model adds MOI_score, diabetes, alzheimer, parkinson, AVH, previous_falls, psych_score",
    "See CSV outputs for coefficients and emmeans."
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

# --- Session info -----------------------------------------------------------
save_sessioninfo_manifest()
