#!/usr/bin/env Rscript
# ## STANDARD SCRIPT INTRO (MANDATORY)
# ==============================================================================
# K05_MAIN - Wide ANCOVA (baseline -> 12 months) for composite function
# File tag: K05_MAIN.V1_wide-ancova.R
# Purpose: Primary wide ANCOVA: follow-up composite (12m) ~ FOF + baseline composite + age + sex + BMI
#
# Outcome: Composite_Z12 (12-month composite; ToimintaKykySummary2)
# Predictors: FOF_status_f
# Moderator/interaction: None (additive ANCOVA)
# Grouping variable: None (wide format)
# Covariates: Composite_Z0, age, sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, age, sex, BMI, kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2
#
# Mapping example (raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn -> FOF_status -> FOF_status_f
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z12
# Delta_Composite_Z = Composite_Z12 - Composite_Z0
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K05_MAIN (canonical)
# - outputs dir: R-scripts/K05_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Standardize vars + QC (sanity checks early)
# 04) Derive/rename vars (document mapping)
# 05) Prepare analysis dataset (complete-case)
# 06) Fit primary model (ANCOVA)
# 07) Sensitivity models (if feasible; document)
# 08) Reporting tables (estimates + 95% CI; emmeans as needed)
# 09) Save artifacts -> R-scripts/K05_MAIN/outputs/
# 10) Append manifest row per artifact
# 11) Save sessionInfo / renv diagnostics to manifest/
# 12) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(broom)
  library(emmeans)
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K05_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K05_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K05_MAIN"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K05 Wide ANCOVA\n")
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
  "id",
  "age",
  "sex",
  "BMI",
  "kaatumisenpelkoOn",
  "ToimintaKykySummary0",
  "ToimintaKykySummary2"
)

missing_cols <- setdiff(req_cols, names(raw_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

# --- Column type checks ------------------------------------------------------
type_cols <- c("age", "BMI", "ToimintaKykySummary0", "ToimintaKykySummary2")
bad_types <- type_cols[!vapply(raw_data[type_cols], is.numeric, logical(1))]
if (length(bad_types) > 0) {
  stop("Expected numeric columns: ", paste(bad_types, collapse = ", "))
}

# --- Minimal QC --------------------------------------------------------------
if (anyDuplicated(raw_data$id)) {
  stop("Duplicate id rows detected; expected wide format.")
}

fof_vals <- unique(na.omit(raw_data$kaatumisenpelkoOn))
bad_fof <- setdiff(fof_vals, c(0, 1))
if (length(bad_fof) > 0) {
  stop("Unexpected kaatumisenpelkoOn values (expected 0/1): ", paste(bad_fof, collapse = ", "))
}

qc_overall <- raw_data %>%
  summarise(
    n = dplyr::n(),
    miss_age = sum(is.na(age)),
    miss_sex = sum(is.na(sex)),
    miss_BMI = sum(is.na(BMI)),
    miss_z0 = sum(is.na(ToimintaKykySummary0)),
    miss_z12 = sum(is.na(ToimintaKykySummary2))
  )

qc_overall_path <- file.path(outputs_dir, paste0(script_label, "_qc_missingness_overall.csv"))
save_table_csv(qc_overall, qc_overall_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_missingness_overall",
    path = get_relpath(qc_overall_path),
    kind = "table_csv",
    n = nrow(qc_overall)
  ),
  manifest_path
)

qc_tbl <- raw_data %>%
  mutate(FOF_status = kaatumisenpelkoOn) %>%
  group_by(FOF_status) %>%
  summarise(
    n = dplyr::n(),
    miss_age = sum(is.na(age)),
    miss_sex = sum(is.na(sex)),
    miss_BMI = sum(is.na(BMI)),
    miss_z0 = sum(is.na(ToimintaKykySummary0)),
    miss_z12 = sum(is.na(ToimintaKykySummary2)),
    .groups = "drop"
  )

qc_path <- file.path(outputs_dir, paste0(script_label, "_qc_missingness_by_fof.csv"))
save_table_csv(qc_tbl, qc_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_missingness_by_fof",
    path = get_relpath(qc_path),
    kind = "table_csv",
    n = nrow(qc_tbl)
  ),
  manifest_path
)

# --- Map variables for analysis ---------------------------------------------
dat <- raw_data %>%
  transmute(
    id = id,
    age = age,
    sex = sex,
    BMI = BMI,
    FOF_status = kaatumisenpelkoOn,
    FOF_status_f = factor(kaatumisenpelkoOn, levels = c(0, 1), labels = c("No FOF", "FOF")),
    Composite_Z0 = ToimintaKykySummary0,
    Composite_Z12 = ToimintaKykySummary2,
    Delta_Composite_Z = ToimintaKykySummary2 - ToimintaKykySummary0
  )

dat_cc <- dat %>%
  filter(
    !is.na(Composite_Z12),
    !is.na(FOF_status),
    !is.na(Composite_Z0),
    !is.na(age),
    !is.na(sex),
    !is.na(BMI)
  )

# --- Delta check -------------------------------------------------------------
delta_diff <- dat$Delta_Composite_Z - (dat$Composite_Z12 - dat$Composite_Z0)
delta_diff <- delta_diff[!is.na(delta_diff)]
if (length(delta_diff) > 0 && any(abs(delta_diff) > 1e-8)) {
  stop("Delta check failed: Composite_Z12 - Composite_Z0 mismatch detected.")
}

# --- Primary model: ANCOVA on follow-up -------------------------------------
fit <- lm(Composite_Z12 ~ FOF_status_f + Composite_Z0 + age + sex + BMI, data = dat_cc)

coef_tbl <- broom::tidy(fit, conf.int = TRUE) %>%
  mutate(model = "ANCOVA_followup")
coef_path <- file.path(outputs_dir, paste0(script_label, "_fit_ancova_followup_coefficients.csv"))
save_table_csv(coef_tbl, coef_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "fit_ancova_followup_coefficients",
    path = get_relpath(coef_path),
    kind = "table_csv",
    n = nrow(coef_tbl)
  ),
  manifest_path
)

emm <- emmeans::emmeans(fit, ~ FOF_status_f)
emm_tbl <- as.data.frame(emm)
emm_path <- file.path(outputs_dir, paste0(script_label, "_emmeans_adjusted_means.csv"))
save_table_csv(emm_tbl, emm_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "emmeans_adjusted_means",
    path = get_relpath(emm_path),
    kind = "table_csv",
    n = nrow(emm_tbl)
  ),
  manifest_path
)

ctr <- as.data.frame(emmeans::contrast(emm, method = "revpairwise"))
ctr_path <- file.path(outputs_dir, paste0(script_label, "_emmeans_contrast_fof_minus_nonfof.csv"))
save_table_csv(ctr, ctr_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "emmeans_contrast_fof_minus_nonfof",
    path = get_relpath(ctr_path),
    kind = "table_csv",
    n = nrow(ctr)
  ),
  manifest_path
)

# --- Short summary (table-to-text anchor) -----------------------------------
term_fof <- "FOF_status_fFOF"
table_to_text_crosscheck(coef_tbl, term_fof)
para <- results_paragraph_from_table(coef_tbl, term_fof, outcome_label = "Composite_Z12")

txt_path <- file.path(outputs_dir, paste0(script_label, "_summary.txt"))
writeLines(
  c(
    "K05_MAIN Wide ANCOVA summary",
    paste0("N complete-case: ", nrow(dat_cc)),
    "Model: Composite_Z12 ~ FOF_status_f + Composite_Z0 + age + sex + BMI",
    "",
    para,
    "",
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
