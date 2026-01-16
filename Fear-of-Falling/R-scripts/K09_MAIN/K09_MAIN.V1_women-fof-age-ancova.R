#!/usr/bin/env Rscript
# ==============================================================================
# K09_MAIN - Women-only ANCOVA (FOF × age class) on functional change
# File tag: K09_MAIN.V1_women-fof-age-ancova.R
# Purpose: Women-only subgroup ANCOVA of 12-month change in composite function,
#          testing FOF × AgeClass_final with covariate adjustment.
#
# Outcome: DeltaComposite (12-month change in composite function)
# Predictors: FOF_status
# Moderator/interaction: AgeClass_final (65_84 vs 85plus)
# Grouping variable: None (wide format; women-only)
# Covariates: ToimintaKykySummary0, BMI, MOIindeksiindeksi, diabetes
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# age, sex, BMI, kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# MOIindeksiindeksi, diabetes, alzheimer, parkinson, AVH
#
# Mapping example (raw -> analysis; keep minimal + explicit):
# sex (0/1) -> sex_factor (female/male); women-only analysis
# kaatumisenpelkoOn -> FOF_status (nonFOF/FOF)
# age -> AgeClass (65_74/75_84/85plus) -> AgeClass_final (65_84/85plus)
# ToimintaKykySummary2 - ToimintaKykySummary0 -> DeltaComposite
# neuro_any = any(alzheimer/parkinson/AVH == 1) (used in optional model)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K09_MAIN (canonical)
# - outputs dir: R-scripts/K09_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Standardize vars + QC (sanity checks early)
# 04) Derive/rename vars (document mapping)
# 05) Prepare analysis dataset (women-only, complete-case)
# 06) Fit ANCOVA model (FOF × AgeClass_final)
# 07) Reporting tables (estimates + 95% CI; emmeans/contrasts)
# 08) Save artifacts -> R-scripts/K09_MAIN/outputs/
# 09) Append manifest row per artifact
# 10) Save sessionInfo / renv diagnostics to manifest/
# 11) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(broom)
  library(emmeans)
  library(car)
  library(forcats)
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K09_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K09_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K09_MAIN"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K09 Women-only FOF × AgeClass ANCOVA\n")
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
  "age",
  "sex",
  "BMI",
  "kaatumisenpelkoOn",
  "ToimintaKykySummary0",
  "ToimintaKykySummary2",
  "MOIindeksiindeksi",
  "diabetes",
  "alzheimer",
  "parkinson",
  "AVH"
)

missing_cols <- setdiff(req_cols, names(raw_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

# --- Column type checks ------------------------------------------------------
type_cols <- c(
  "age",
  "BMI",
  "ToimintaKykySummary0",
  "ToimintaKykySummary2",
  "MOIindeksiindeksi",
  "diabetes"
)
bad_types <- type_cols[!vapply(raw_data[type_cols], is.numeric, logical(1))]
if (length(bad_types) > 0) {
  stop("Expected numeric columns: ", paste(bad_types, collapse = ", "))
}

if ("id" %in% names(raw_data) && anyDuplicated(raw_data$id)) {
  stop("Duplicate id rows detected; expected wide format.")
}

fof_vals <- unique(na.omit(raw_data$kaatumisenpelkoOn))
bad_fof <- setdiff(fof_vals, c(0, 1))
if (length(bad_fof) > 0) {
  stop("Unexpected kaatumisenpelkoOn values (expected 0/1): ", paste(bad_fof, collapse = ", "))
}

sex_vals <- unique(na.omit(raw_data$sex))
bad_sex <- setdiff(sex_vals, c(0, 1))
if (length(bad_sex) > 0) {
  stop("Unexpected sex values (expected 0/1): ", paste(bad_sex, collapse = ", "))
}

neuro_vals <- unique(na.omit(unlist(raw_data[c("alzheimer", "parkinson", "AVH")])))
bad_neuro <- setdiff(neuro_vals, c(0, 1))
if (length(bad_neuro) > 0) {
  stop("Unexpected neuro codes (expected 0/1): ", paste(bad_neuro, collapse = ", "))
}

# --- Minimal QC --------------------------------------------------------------
qc_overall <- raw_data %>%
  summarise(
    n = dplyr::n(),
    miss_age = sum(is.na(age)),
    miss_sex = sum(is.na(sex)),
    miss_BMI = sum(is.na(BMI)),
    miss_z0 = sum(is.na(ToimintaKykySummary0)),
    miss_z12 = sum(is.na(ToimintaKykySummary2)),
    miss_moi = sum(is.na(MOIindeksiindeksi)),
    miss_diabetes = sum(is.na(diabetes)),
    miss_neuro = sum(is.na(alzheimer) | is.na(parkinson) | is.na(AVH))
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

qc_missingness <- raw_data %>%
  mutate(FOF_status = kaatumisenpelkoOn) %>%
  group_by(FOF_status) %>%
  summarise(
    n = dplyr::n(),
    miss_age = sum(is.na(age)),
    miss_sex = sum(is.na(sex)),
    miss_BMI = sum(is.na(BMI)),
    miss_z0 = sum(is.na(ToimintaKykySummary0)),
    miss_z12 = sum(is.na(ToimintaKykySummary2)),
    miss_moi = sum(is.na(MOIindeksiindeksi)),
    miss_diabetes = sum(is.na(diabetes)),
    miss_neuro = sum(is.na(alzheimer) | is.na(parkinson) | is.na(AVH)),
    .groups = "drop"
  )

qc_path <- file.path(outputs_dir, paste0(script_label, "_qc_missingness_by_fof.csv"))
save_table_csv(qc_missingness, qc_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_missingness_by_fof",
    path = get_relpath(qc_path),
    kind = "table_csv",
    n = nrow(qc_missingness)
  ),
  manifest_path
)

# --- Map variables for analysis ---------------------------------------------
dat <- raw_data %>%
  transmute(
    age = age,
    sex = sex,
    BMI = BMI,
    FOF_status = factor(kaatumisenpelkoOn, levels = c(0, 1), labels = c("nonFOF", "FOF")),
    ToimintaKykySummary0 = ToimintaKykySummary0,
    ToimintaKykySummary2 = ToimintaKykySummary2,
    DeltaComposite = ToimintaKykySummary2 - ToimintaKykySummary0,
    MOIindeksiindeksi = MOIindeksiindeksi,
    diabetes = diabetes,
    neuro_any = case_when(
      alzheimer == 1 | parkinson == 1 | AVH == 1 ~ "neuro",
      alzheimer == 0 & parkinson == 0 & AVH == 0 ~ "no_neuro",
      TRUE ~ NA_character_
    )
  )

delta_diff <- dat$DeltaComposite - (dat$ToimintaKykySummary2 - dat$ToimintaKykySummary0)
delta_diff <- delta_diff[!is.na(delta_diff)]
if (length(delta_diff) > 0 && any(abs(delta_diff) > 1e-8)) {
  stop("Delta check failed: ToimintaKykySummary2 - ToimintaKykySummary0 mismatch detected.")
}

dat <- dat %>%
  mutate(
    sex_factor = factor(sex, levels = c(0, 1), labels = c("female", "male")),
    AgeClass = case_when(
      age >= 65 & age <= 74 ~ "65_74",
      age >= 75 & age <= 84 ~ "75_84",
      age >= 85 ~ "85plus",
      age < 65 ~ NA_character_,
      TRUE ~ NA_character_
    ),
    AgeClass = factor(AgeClass, levels = c("65_74", "75_84", "85plus"), ordered = TRUE),
    neuro_any = factor(neuro_any, levels = c("no_neuro", "neuro"))
  )

data_women <- dat %>% filter(sex_factor == "female")
if (any(!is.na(dat$age) & dat$age < 65)) {
  warning("Age < 65 detected; AgeClass set to NA for these rows.")
}
cell_counts_women <- data_women %>%
  count(FOF_status, AgeClass) %>%
  arrange(AgeClass, FOF_status)
cell_counts_women_path <- file.path(outputs_dir, paste0(script_label, "_cell_counts_women_ageclass.csv"))
save_table_csv(cell_counts_women, cell_counts_women_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "cell_counts_women_ageclass",
    path = get_relpath(cell_counts_women_path),
    kind = "table_csv",
    n = nrow(cell_counts_women)
  ),
  manifest_path
)

data_women <- data_women %>%
  mutate(
    AgeClass_final = fct_collapse(
      AgeClass,
      "65_84" = c("65_74", "75_84"),
      "85plus" = "85plus"
    ),
    AgeClass_final = factor(AgeClass_final, levels = c("65_84", "85plus"), ordered = TRUE)
  )

cell_counts_women_final <- data_women %>%
  count(FOF_status, AgeClass_final) %>%
  arrange(AgeClass_final, FOF_status)
cell_counts_women_final_path <- file.path(outputs_dir, paste0(script_label, "_cell_counts_women_ageclass_final.csv"))
save_table_csv(cell_counts_women_final, cell_counts_women_final_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "cell_counts_women_ageclass_final",
    path = get_relpath(cell_counts_women_final_path),
    kind = "table_csv",
    n = nrow(cell_counts_women_final)
  ),
  manifest_path
)

analysis_women <- data_women %>%
  select(
    DeltaComposite,
    ToimintaKykySummary0,
    FOF_status,
    AgeClass_final,
    BMI,
    MOIindeksiindeksi,
    diabetes,
    neuro_any
  ) %>%
  drop_na()

if (!nrow(analysis_women)) {
  stop("No complete-case women-only data for K09 ANCOVA.")
}

model_primary <- lm(
  DeltaComposite ~ FOF_status * AgeClass_final +
    ToimintaKykySummary0 + BMI + MOIindeksiindeksi + diabetes,
  data = analysis_women
)

aliased_coeffs <- names(which(is.na(coef(model_primary))))
if (length(aliased_coeffs) > 0) {
  warning(
    "Aliased coefficients detected: ", paste(aliased_coeffs, collapse = ", "),
    ". Falling back to Type II Anova."
  )
  anova_primary <- car::Anova(model_primary, type = "II")
} else {
  anova_primary <- car::Anova(model_primary, type = "III")
}

coef_primary <- broom::tidy(model_primary, conf.int = TRUE) %>%
  mutate(model = "primary")
anova_primary_tbl <- broom::tidy(anova_primary) %>%
  mutate(model = "primary")

emm_primary <- emmeans::emmeans(model_primary, ~ FOF_status | AgeClass_final)
emm_primary_tbl <- as.data.frame(emm_primary)
ctr_primary_tbl <- as.data.frame(emmeans::contrast(emm_primary, method = "revpairwise"))

coef_path <- file.path(outputs_dir, paste0(script_label, "_fit_primary_coefficients.csv"))
save_table_csv(coef_primary, coef_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "fit_primary_coefficients",
    path = get_relpath(coef_path),
    kind = "table_csv",
    n = nrow(coef_primary)
  ),
  manifest_path
)

anova_path <- file.path(outputs_dir, paste0(script_label, "_fit_primary_anova_typeIIorIII.csv"))
save_table_csv(anova_primary_tbl, anova_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "fit_primary_anova_typeIIorIII",
    path = get_relpath(anova_path),
    kind = "table_csv",
    n = nrow(anova_primary_tbl)
  ),
  manifest_path
)

emm_path <- file.path(outputs_dir, paste0(script_label, "_emmeans_primary.csv"))
save_table_csv(emm_primary_tbl, emm_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "emmeans_primary",
    path = get_relpath(emm_path),
    kind = "table_csv",
    n = nrow(emm_primary_tbl)
  ),
  manifest_path
)

ctr_path <- file.path(outputs_dir, paste0(script_label, "_emmeans_contrast_primary.csv"))
save_table_csv(ctr_primary_tbl, ctr_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "emmeans_contrast_primary",
    path = get_relpath(ctr_path),
    kind = "table_csv",
    n = nrow(ctr_primary_tbl)
  ),
  manifest_path
)

if (dplyr::n_distinct(analysis_women$neuro_any, na.rm = TRUE) > 1) {
  model_neuro <- lm(
    DeltaComposite ~ FOF_status * AgeClass_final +
      neuro_any +
      ToimintaKykySummary0 + BMI + MOIindeksiindeksi + diabetes,
    data = analysis_women
  )
  coef_neuro <- broom::tidy(model_neuro, conf.int = TRUE) %>%
    mutate(model = "neuro_adjusted")
  coef_neuro_path <- file.path(outputs_dir, paste0(script_label, "_fit_neuro_adjusted_coefficients.csv"))
  save_table_csv(coef_neuro, coef_neuro_path)
  append_manifest(
    manifest_row(
      script = script_label,
      label = "fit_neuro_adjusted_coefficients",
      path = get_relpath(coef_neuro_path),
      kind = "table_csv",
      n = nrow(coef_neuro)
    ),
    manifest_path
  )
} else {
  warning("Skipping neuro_any-adjusted model: neuro_any has <=1 distinct non-missing value in complete-case data.")
}

txt_path <- file.path(outputs_dir, paste0(script_label, "_summary.txt"))
writeLines(
  c(
    "K09_MAIN Women-only ANCOVA summary",
    paste0("N women complete-case: ", nrow(analysis_women)),
    "Model: DeltaComposite ~ FOF_status * AgeClass_final + ToimintaKykySummary0 + BMI + MOIindeksiindeksi + diabetes",
    "See CSV outputs for coefficients, ANOVA, and emmeans/contrasts."
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
