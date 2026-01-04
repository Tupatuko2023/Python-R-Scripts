#!/usr/bin/env Rscript
# ==============================================================================
# K13_MAIN - FOF × Age/BMI/Sex interactions on functional change
# File tag: K13_MAIN.V1_fof-interactions.R
# Purpose: Test whether FOF association with 12-month change in composite
#          function varies by age, BMI, sex, MOI, pain, SRH, or SRM
#
# Outcome: Delta_Composite_Z (12-month change in composite function)
# Predictors: FOF_status_f (factor: "Ei FOF"/"FOF")
# Moderator/interaction: Age (age_c), BMI (BMI_c), Sex_f, MOI_c, PainVAS0_c,
#                        SRH_3class, SRM_3class
# Grouping variable: None (wide format ANCOVA with interactions)
# Covariates: Composite_Z0, MOI_score, diabetes, alzheimer, parkinson, AVH,
#             previous_falls, psych_score
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, age, sex, BMI, kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# MOIindeksiindeksi, diabetes, alzheimer, parkinson, AVH, kaatuminen, mieliala,
# PainVAS0, SRH, oma_arvio_liikuntakyky
#
# Mapping example (raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn (0/1) -> FOF_status -> FOF_status_f (factor: "Ei FOF"/"FOF")
# age -> Age
# sex (0/1) -> Sex -> Sex_f (factor: "female"/"male")
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z2
# Composite_Z2 - Composite_Z0 -> Delta_Composite_Z
# MOIindeksiindeksi -> MOI_score
# kaatuminen -> previous_falls
# mieliala -> psych_score
# PainVAS0 -> PainVAS0_c (centered)
# SRH (0/1/2) -> SRH_3class (poor/fair/good)
# oma_arvio_liikuntakyky (0/1/2) -> SRM_3class (poor/fair/good)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K13_MAIN (canonical)
# - outputs dir: R-scripts/K13_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Check required raw columns (req_raw_cols)
# 04) Standardize vars + QC (standardize_analysis_vars + sanity_checks)
# 05) Prepare analysis dataset (derive centered moderators)
# 06) Fit interaction models (FOF × moderator)
# 07) Save tables + simple slopes + plots
# 08) Append manifest row per artifact
# 09) Save sessionInfo / renv diagnostics to manifest/
# 10) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(broom)
  library(emmeans)
  library(ggplot2)
  library(effectsize)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K13_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K13_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K13_MAIN"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K13 FOF interaction models\n")
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
  "AVH", "kaatuminen", "mieliala",
  "PainVAS0", "SRH", "oma_arvio_liikuntakyky"
)

missing_raw_cols <- setdiff(req_raw_cols, names(raw_data))
if (length(missing_raw_cols) > 0) {
  stop("Missing required raw columns: ", paste(missing_raw_cols, collapse = ", "))
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
analysis_data_rec <- df %>%
  select(
    id, Age, Sex, BMI, FOF_status, FOF_status_f, Sex_f,
    Composite_Z0, Composite_Z2, Delta_Composite_Z,
    MOIindeksiindeksi, diabetes, alzheimer, parkinson, AVH,
    kaatuminen, mieliala
  ) %>%
  left_join(raw_data %>%
              select(id, PainVAS0, SRH, oma_arvio_liikuntakyky),
            by = "id") %>%
  mutate(
    MOI_score = as.numeric(MOIindeksiindeksi),
    previous_falls = as.numeric(kaatuminen),
    psych_score = as.numeric(mieliala),
    SRH_3class = factor(
      SRH,
      levels = c(0, 1, 2),
      labels = c("poor", "fair", "good"),
      ordered = TRUE
    ),
    SRM_3class = factor(
      oma_arvio_liikuntakyky,
      levels = c(0, 1, 2),
      labels = c("poor", "fair", "good"),
      ordered = TRUE
    )
  )

dat_fof <- analysis_data_rec %>%
  filter(
    !is.na(Delta_Composite_Z),
    !is.na(Composite_Z0),
    !is.na(Age),
    !is.na(BMI),
    !is.na(Sex_f),
    !is.na(FOF_status_f)
  ) %>%
  mutate(
    FOF_status_f = stats::relevel(FOF_status_f, ref = "Ei FOF")
  )

if (!nrow(dat_fof)) {
  stop("No complete-case data available for K13 interactions.")
}

vars_cc_demographic <- c(
  "Delta_Composite_Z", "Composite_Z0", "Age", "BMI", "Sex_f", "FOF_status_f", "MOI_score"
)
dat_int_cc_demographic <- dat_fof %>%
  filter(stats::complete.cases(dplyr::across(dplyr::all_of(vars_cc_demographic)))) %>%
  mutate(
    age_c = Age - mean(Age, na.rm = TRUE),
    BMI_c = BMI - mean(BMI, na.rm = TRUE),
    MOI_c = MOI_score - mean(MOI_score, na.rm = TRUE)
  )

if (!nrow(dat_int_cc_demographic)) {
  stop("No complete-case data available for K13 demographic interaction models.")
}

vars_cc_symptom_extra <- c(
  "diabetes", "alzheimer", "parkinson", "AVH", "previous_falls", "psych_score",
  "PainVAS0", "SRH", "oma_arvio_liikuntakyky"
)
vars_cc_symptom <- unique(c(vars_cc_demographic, vars_cc_symptom_extra))
dat_int_cc_symptom <- dat_fof %>%
  filter(stats::complete.cases(dplyr::across(dplyr::all_of(vars_cc_symptom)))) %>%
  mutate(
    age_c = Age - mean(Age, na.rm = TRUE),
    BMI_c = BMI - mean(BMI, na.rm = TRUE),
    MOI_c = MOI_score - mean(MOI_score, na.rm = TRUE),
    PainVAS0_c = PainVAS0 - mean(PainVAS0, na.rm = TRUE)
  )

fit_int_model <- function(formula_str, data, label) {
  fit <- lm(stats::as.formula(formula_str), data = data)
  tidy <- broom::tidy(fit, conf.int = TRUE) %>%
    mutate(model = label)
  list(fit = fit, tidy = tidy)
}

mod_age <- fit_int_model(
  "Delta_Composite_Z ~ FOF_status_f * age_c + BMI_c + Sex_f + Composite_Z0 + MOI_score + diabetes + alzheimer + parkinson + AVH + previous_falls + psych_score",
  dat_int_cc_demographic,
  "age_int_ext"
)
mod_BMI <- fit_int_model(
  "Delta_Composite_Z ~ FOF_status_f * BMI_c + age_c + Sex_f + Composite_Z0 + MOI_score + diabetes + alzheimer + parkinson + AVH + previous_falls + psych_score",
  dat_int_cc_demographic,
  "BMI_int_ext"
)
mod_sex <- fit_int_model(
  "Delta_Composite_Z ~ FOF_status_f * Sex_f + age_c + BMI_c + Composite_Z0 + MOI_score + diabetes + alzheimer + parkinson + AVH + previous_falls + psych_score",
  dat_int_cc_demographic,
  "sex_int_ext"
)
mod_all <- fit_int_model(
  "Delta_Composite_Z ~ FOF_status_f * age_c + FOF_status_f * BMI_c + FOF_status_f * Sex_f + Composite_Z0 + MOI_score + diabetes + alzheimer + parkinson + AVH + previous_falls + psych_score",
  dat_int_cc_demographic,
  "all_int_ext"
)
mod_MOI <- fit_int_model(
  "Delta_Composite_Z ~ FOF_status_f * MOI_c + age_c + BMI_c + Sex_f + Composite_Z0 + diabetes + alzheimer + parkinson + AVH + previous_falls + psych_score + PainVAS0_c + SRH_3class + SRM_3class",
  dat_int_cc_symptom,
  "MOI_int_ext"
)
mod_Pain <- fit_int_model(
  "Delta_Composite_Z ~ FOF_status_f * PainVAS0_c + age_c + BMI_c + Sex_f + Composite_Z0 + MOI_c + diabetes + alzheimer + parkinson + AVH + previous_falls + psych_score + SRH_3class + SRM_3class",
  dat_int_cc_symptom,
  "Pain_int_ext"
)
mod_SRH <- fit_int_model(
  "Delta_Composite_Z ~ FOF_status_f * SRH_3class + age_c + BMI_c + Sex_f + Composite_Z0 + MOI_c + PainVAS0_c + diabetes + alzheimer + parkinson + AVH + previous_falls + psych_score + SRM_3class",
  dat_int_cc_symptom,
  "SRH_int_ext"
)
mod_SRM <- fit_int_model(
  "Delta_Composite_Z ~ FOF_status_f * SRM_3class + age_c + BMI_c + Sex_f + Composite_Z0 + MOI_c + PainVAS0_c + diabetes + alzheimer + parkinson + AVH + previous_falls + psych_score + SRH_3class",
  dat_int_cc_symptom,
  "SRM_int_ext"
)

tidy_all <- bind_rows(
  mod_age$tidy, mod_BMI$tidy, mod_sex$tidy, mod_all$tidy,
  mod_MOI$tidy, mod_Pain$tidy, mod_SRH$tidy, mod_SRM$tidy
)
csv_path <- file.path(outputs_dir, "lm_interaction_models_all.csv")
save_table_csv(tidy_all, csv_path)
append_manifest(
  manifest_row(script = script_label, label = "lm_interaction_models_all",
               path = get_relpath(csv_path), kind = "table_csv", n = nrow(tidy_all)),
  manifest_path
)

extract_interactions <- function(tidy_tbl, moderator, model_label) {
  tidy_tbl %>%
    filter(grepl("FOF_status_f", term), grepl(moderator, term), grepl(":", term)) %>%
    mutate(moderator = moderator, model = model_label) %>%
    select(model, moderator, term, estimate, std.error, statistic, p.value, conf.low, conf.high)
}

tab_overview <- bind_rows(
  extract_interactions(mod_age$tidy, moderator = "age_c", model_label = "age_int_ext"),
  extract_interactions(mod_BMI$tidy, moderator = "BMI_c", model_label = "BMI_int_ext"),
  extract_interactions(mod_sex$tidy, moderator = "Sex_f", model_label = "sex_int_ext")
)
save_table_csv(tab_overview, file.path(outputs_dir, "FOF_interaction_effects_overview.csv"))
append_manifest(
  manifest_row(script = script_label, label = "FOF_interaction_effects_overview",
               path = get_relpath(file.path(outputs_dir, "FOF_interaction_effects_overview.csv")),
               kind = "table_csv", n = nrow(tab_overview)),
  manifest_path
)

tab_symptoms <- bind_rows(
  extract_interactions(mod_MOI$tidy, moderator = "MOI_c", model_label = "MOI_int_ext"),
  extract_interactions(mod_Pain$tidy, moderator = "PainVAS0_c", model_label = "Pain_int_ext")
)
save_table_csv(tab_symptoms, file.path(outputs_dir, "FOF_interaction_effects_symptoms.csv"))
append_manifest(
  manifest_row(script = script_label, label = "FOF_interaction_effects_symptoms",
               path = get_relpath(file.path(outputs_dir, "FOF_interaction_effects_symptoms.csv")),
               kind = "table_csv", n = nrow(tab_symptoms)),
  manifest_path
)

tab_srh_srm <- bind_rows(
  extract_interactions(mod_SRH$tidy, moderator = "SRH_3class", model_label = "SRH_int_ext"),
  extract_interactions(mod_SRM$tidy, moderator = "SRM_3class", model_label = "SRM_int_ext")
)
save_table_csv(tab_srh_srm, file.path(outputs_dir, "FOF_interaction_effects_SRH_SRM.csv"))
append_manifest(
  manifest_row(script = script_label, label = "FOF_interaction_effects_SRH_SRM",
               path = get_relpath(file.path(outputs_dir, "FOF_interaction_effects_SRH_SRM.csv")),
               kind = "table_csv", n = nrow(tab_srh_srm)),
  manifest_path
)

simple_slopes <- function(fit, moderator, at_list, label) {
  emm <- emmeans::emmeans(fit, as.formula(paste0("~ FOF_status_f | ", moderator)), at = at_list)
  ctr <- emmeans::contrast(emm, method = "revpairwise", by = moderator, adjust = "none")
  out <- as.data.frame(summary(ctr, infer = TRUE)) %>%
    mutate(effect = paste0("FOF (", contrast, ")"), moderator = moderator, label = label) %>%
    rename(conf.low = lower.CL, conf.high = upper.CL)
  out
}

age_c_values <- c(-10, 0, 10)
BMI_c_values <- c(-5, 0, 5)
MOI_c_values <- c(-2, 0, 2)
Pain_c_values <- c(-2, 0, 2)

slopes_age <- simple_slopes(mod_age$fit, "age_c", list(age_c = age_c_values), "age")
slopes_BMI <- simple_slopes(mod_BMI$fit, "BMI_c", list(BMI_c = BMI_c_values), "BMI")
slopes_sex <- simple_slopes(mod_sex$fit, "Sex_f", list(), "sex")
slopes_MOI <- simple_slopes(mod_MOI$fit, "MOI_c", list(MOI_c = MOI_c_values), "MOI")
slopes_Pain <- simple_slopes(mod_Pain$fit, "PainVAS0_c", list(PainVAS0_c = Pain_c_values), "Pain")
slopes_SRH <- simple_slopes(mod_SRH$fit, "SRH_3class", list(), "SRH")
slopes_SRM <- simple_slopes(mod_SRM$fit, "SRM_3class", list(), "SRM")

slopes_all <- bind_rows(slopes_age, slopes_BMI, slopes_sex, slopes_MOI, slopes_Pain, slopes_SRH, slopes_SRM)
save_table_csv(slopes_all, file.path(outputs_dir, "simple_slopes_all.csv"))
append_manifest(
  manifest_row(script = script_label, label = "simple_slopes_all",
               path = get_relpath(file.path(outputs_dir, "simple_slopes_all.csv")),
               kind = "table_csv", n = nrow(slopes_all)),
  manifest_path
)

plot_simple_slopes <- function(df, xvar, xlab, title, file_label) {
  p <- ggplot(df, aes(x = .data[[xvar]], y = estimate, ymin = conf.low, ymax = conf.high)) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_pointrange() +
    labs(x = xlab, y = "FOF effect (FOF vs nonFOF)", title = title) +
    theme_minimal()
  out_path <- file.path(outputs_dir, paste0(file_label, ".png"))
  ggsave(filename = out_path, plot = p, width = 7, height = 4, dpi = 300)
  append_manifest(
    manifest_row(script = script_label, label = file_label,
                 path = get_relpath(out_path), kind = "figure_png", n = NA_integer_),
    manifest_path
  )
}

plot_simple_slopes(slopes_age, "age_c", "Age (centered)", "FOF × age simple slopes", "FOF_effect_by_age_simple_slopes")
plot_simple_slopes(slopes_BMI, "BMI_c", "BMI (centered)", "FOF × BMI simple slopes", "FOF_effect_by_BMI_simple_slopes")
plot_simple_slopes(slopes_sex, "Sex_f", "Sex", "FOF × sex simple slopes", "FOF_effect_by_sex_simple_slopes")

txt_path <- file.path(outputs_dir, paste0(script_label, "_summary.txt"))
writeLines(
  c(
    "K13_MAIN FOF interaction models",
    paste0("N complete-case demographic: ", nrow(dat_int_cc_demographic)),
    paste0("N complete-case symptom: ", nrow(dat_int_cc_symptom)),
    "Models: FOF × age_c, FOF × BMI_c, FOF × Sex_f, FOF × MOI_c, FOF × PainVAS0_c, FOF × SRH_3class, FOF × SRM_3class",
    "See CSV outputs for interaction tables and simple slopes."
  ),
  con = txt_path
)
append_manifest(
  manifest_row(script = script_label, label = "summary_txt",
               path = get_relpath(txt_path), kind = "text", n = NA_integer_),
  manifest_path
)

# --- Session info -----------------------------------------------------------
save_sessioninfo_manifest()
