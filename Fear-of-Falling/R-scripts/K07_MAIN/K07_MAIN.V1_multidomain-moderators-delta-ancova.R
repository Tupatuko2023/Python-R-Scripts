#!/usr/bin/env Rscript
# ==============================================================================
# K07_MAIN - Delta ANCOVA multi-domain moderators (baseline -> 12 months)
# File tag: K07_MAIN.V1_multidomain-moderators-delta-ancova.R
# Purpose: FOF moderation models on 12-month change in composite function across
#          neurological status, SRH, SRM, and 500m walk difficulty
#
# Outcome: Delta_Composite_Z (12-month change in composite function)
# Predictors: FOF_status_f
# Moderator/interaction: neuro_any, SRH_3class, SRM_3class, Walk500m_3class
# Grouping variable: None (wide format)
# Covariates: Composite_Z0, age, sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, age, sex, BMI, kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# alzheimer, parkinson, AVH, SRH (or koettuterveydentila), oma_arvio_liikuntakyky,
# Vaikeus500m
#
# Mapping example (raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn -> FOF_status -> FOF_status_f
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z12
# Delta_Composite_Z = Composite_Z12 - Composite_Z0
# neuro_any = any(alzheimer/parkinson/AVH == 1) -> yes/no
# SRH or koettuterveydentila -> SRH_3class (good/fair/poor)
# oma_arvio_liikuntakyky -> SRM_3class (good/fair/poor)
# Vaikeus500m -> Walk500m_3class (no difficulty/some difficulty/unable)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K07_MAIN (canonical)
# - outputs dir: R-scripts/K07_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Standardize vars + QC (sanity checks early)
# 04) Derive/rename vars (document mapping)
# 05) Prepare analysis datasets (complete-case)
# 06) Fit moderation models (FOF × moderator, delta outcome)
# 07) Reporting tables (estimates + 95% CI; emmeans for categorical moderators)
# 08) Save artifacts -> R-scripts/K07_MAIN/outputs/
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
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K07_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K07_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K07_MAIN"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K07 Multi-domain Moderators Delta ANCOVA\n")
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
  "ToimintaKykySummary2",
  "alzheimer",
  "parkinson",
  "AVH",
  "oma_arvio_liikuntakyky",
  "Vaikeus500m"
)

missing_cols <- setdiff(req_cols, names(raw_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

srh_var <- if ("SRH" %in% names(raw_data)) {
  "SRH"
} else if ("koettuterveydentila" %in% names(raw_data)) {
  "koettuterveydentila"
} else {
  ""
}
if (srh_var == "") {
  stop("Missing SRH variable: neither 'SRH' nor 'koettuterveydentila' found in raw_data.")
}

# --- Column type checks ------------------------------------------------------
type_cols <- c(
  "age",
  "BMI",
  "ToimintaKykySummary0",
  "ToimintaKykySummary2"
)
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

neuro_vars <- c("alzheimer", "parkinson", "AVH")
bad_neuro <- setdiff(stats::na.omit(unique(unlist(raw_data[neuro_vars]))), c(0, 1))
if (length(bad_neuro) > 0) {
  stop("Unexpected neuro codes (expected 0/1): ", paste(bad_neuro, collapse = ", "))
}

srh_vals_chr <- unique(as.character(stats::na.omit(raw_data[[srh_var]])))
allowed_srh <- c("0", "1", "2", "3", "Hyvä", "Keskinkertainen", "Huono", "good", "fair", "poor")
bad_srh <- setdiff(srh_vals_chr, allowed_srh)
if (length(bad_srh) > 0L) {
  stop(
    "Unexpected SRH code(s) detected: ",
    paste(bad_srh, collapse = ", "),
    ". Expected 0/1/2 or 1/2/3 or labeled values."
  )
}
has_zero_srh <- "0" %in% srh_vals_chr
has_three_srh <- "3" %in% srh_vals_chr
if (has_zero_srh && has_three_srh) {
  stop("SRH codes mix 0/1/2 and 1/2/3; please harmonize before running K07.")
}
srh_scheme <- if (has_zero_srh) "012" else if (has_three_srh) "123" else "text"

srm_vals_chr <- unique(as.character(stats::na.omit(raw_data$oma_arvio_liikuntakyky)))
allowed_srm <- c("0", "1", "2", "3", "Hyvä", "Kohtalainen", "Huono", "good", "fair", "poor")
bad_srm <- setdiff(srm_vals_chr, allowed_srm)
if (length(bad_srm) > 0L) {
  stop(
    "Unexpected SRM code(s) detected: ",
    paste(bad_srm, collapse = ", "),
    ". Expected 0/1/2 or 1/2/3 or labeled values."
  )
}
has_zero_srm <- "0" %in% srm_vals_chr
has_three_srm <- "3" %in% srm_vals_chr
if (has_zero_srm && has_three_srm) {
  stop("SRM codes mix 0/1/2 and 1/2/3; please harmonize before running K07.")
}
srm_scheme <- if (has_zero_srm) "012" else if (has_three_srm) "123" else "text"

walk_vals_chr <- unique(as.character(stats::na.omit(raw_data$Vaikeus500m)))
allowed_walk <- c(
  "0", "1", "2",
  "Ei vaikeuksia", "Jonkin verran", "Ei pysty",
  "no difficulty", "some difficulty", "unable"
)
bad_walk <- setdiff(walk_vals_chr, allowed_walk)
if (length(bad_walk) > 0L) {
  stop(
    "Unexpected Vaikeus500m code(s) detected: ",
    paste(bad_walk, collapse = ", "),
    ". Expected 0/1/2 or labeled values."
  )
}

qc_overall <- raw_data %>%
  summarise(
    n = dplyr::n(),
    miss_age = sum(is.na(age)),
    miss_sex = sum(is.na(sex)),
    miss_BMI = sum(is.na(BMI)),
    miss_z0 = sum(is.na(ToimintaKykySummary0)),
    miss_z12 = sum(is.na(ToimintaKykySummary2)),
    miss_neuro = sum(is.na(alzheimer) | is.na(parkinson) | is.na(AVH)),
    miss_srh = sum(is.na(.data[[srh_var]])),
    miss_srm = sum(is.na(oma_arvio_liikuntakyky)),
    miss_walk = sum(is.na(Vaikeus500m))
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
    miss_neuro = sum(is.na(alzheimer) | is.na(parkinson) | is.na(AVH)),
    miss_srh = sum(is.na(.data[[srh_var]])),
    miss_srm = sum(is.na(oma_arvio_liikuntakyky)),
    miss_walk = sum(is.na(Vaikeus500m)),
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
    id = id,
    age = age,
    sex = sex,
    BMI = BMI,
    FOF_status = kaatumisenpelkoOn,
    FOF_status_f = factor(kaatumisenpelkoOn, levels = c(0, 1), labels = c("No FOF", "FOF")),
    Composite_Z0 = ToimintaKykySummary0,
    Composite_Z12 = ToimintaKykySummary2,
    Delta_Composite_Z = ToimintaKykySummary2 - ToimintaKykySummary0,
    alzheimer = alzheimer,
    parkinson = parkinson,
    AVH = AVH,
    SRH_raw = .data[[srh_var]],
    SRM_raw = oma_arvio_liikuntakyky,
    Walk500m_raw = Vaikeus500m
  )

delta_diff <- dat$Delta_Composite_Z - (dat$Composite_Z12 - dat$Composite_Z0)
delta_diff <- delta_diff[!is.na(delta_diff)]
if (length(delta_diff) > 0 && any(abs(delta_diff) > 1e-8)) {
  stop("Delta check failed: Composite_Z12 - Composite_Z0 mismatch detected.")
}

dat <- dat %>%
  mutate(
    neuro_any = case_when(
      alzheimer == 1 | parkinson == 1 | AVH == 1 ~ "yes",
      alzheimer == 0 & parkinson == 0 & AVH == 0 ~ "no",
      TRUE ~ NA_character_
    ),
    neuro_any = factor(neuro_any, levels = c("no", "yes")),
    SRH_3class = case_when(
      srh_scheme == "012" & SRH_raw %in% c(0, "0") ~ "good",
      srh_scheme == "012" & SRH_raw %in% c(1, "1") ~ "fair",
      srh_scheme == "012" & SRH_raw %in% c(2, "2") ~ "poor",
      srh_scheme == "123" & SRH_raw %in% c(1, "1") ~ "good",
      srh_scheme == "123" & SRH_raw %in% c(2, "2") ~ "fair",
      srh_scheme == "123" & SRH_raw %in% c(3, "3") ~ "poor",
      SRH_raw %in% c("Hyvä", "good") ~ "good",
      SRH_raw %in% c("Keskinkertainen", "fair") ~ "fair",
      SRH_raw %in% c("Huono", "poor") ~ "poor",
      TRUE ~ NA_character_
    ),
    SRH_3class = factor(SRH_3class, levels = c("good", "fair", "poor")),
    SRM_3class = case_when(
      srm_scheme == "012" & SRM_raw %in% c(0, "0") ~ "good",
      srm_scheme == "012" & SRM_raw %in% c(1, "1") ~ "fair",
      srm_scheme == "012" & SRM_raw %in% c(2, "2") ~ "poor",
      srm_scheme == "123" & SRM_raw %in% c(1, "1") ~ "good",
      srm_scheme == "123" & SRM_raw %in% c(2, "2") ~ "fair",
      srm_scheme == "123" & SRM_raw %in% c(3, "3") ~ "poor",
      SRM_raw %in% c("Hyvä", "good") ~ "good",
      SRM_raw %in% c("Kohtalainen", "fair") ~ "fair",
      SRM_raw %in% c("Huono", "poor") ~ "poor",
      TRUE ~ NA_character_
    ),
    SRM_3class = factor(SRM_3class, levels = c("good", "fair", "poor")),
    Walk500m_3class = case_when(
      Walk500m_raw %in% c(0, "0", "Ei vaikeuksia", "no difficulty") ~ "no difficulty",
      Walk500m_raw %in% c(1, "1", "Jonkin verran", "some difficulty") ~ "some difficulty",
      Walk500m_raw %in% c(2, "2", "Ei pysty", "unable") ~ "unable",
      TRUE ~ NA_character_
    ),
    Walk500m_3class = factor(Walk500m_3class,
                             levels = c("no difficulty", "some difficulty", "unable"))
  )

cell_neuro <- dat %>%
  count(FOF_status_f, neuro_any) %>%
  tidyr::complete(FOF_status_f, neuro_any, fill = list(n = 0))
cell_neuro_path <- file.path(outputs_dir, paste0(script_label, "_qc_cell_counts_neuro_any.csv"))
save_table_csv(cell_neuro, cell_neuro_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_cell_counts_neuro_any",
    path = get_relpath(cell_neuro_path),
    kind = "table_csv",
    n = nrow(cell_neuro)
  ),
  manifest_path
)

cell_srh <- dat %>%
  count(FOF_status_f, SRH_3class) %>%
  tidyr::complete(FOF_status_f, SRH_3class, fill = list(n = 0))
cell_srh_path <- file.path(outputs_dir, paste0(script_label, "_qc_cell_counts_srh_3class.csv"))
save_table_csv(cell_srh, cell_srh_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_cell_counts_srh_3class",
    path = get_relpath(cell_srh_path),
    kind = "table_csv",
    n = nrow(cell_srh)
  ),
  manifest_path
)

cell_srm <- dat %>%
  count(FOF_status_f, SRM_3class) %>%
  tidyr::complete(FOF_status_f, SRM_3class, fill = list(n = 0))
cell_srm_path <- file.path(outputs_dir, paste0(script_label, "_qc_cell_counts_srm_3class.csv"))
save_table_csv(cell_srm, cell_srm_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_cell_counts_srm_3class",
    path = get_relpath(cell_srm_path),
    kind = "table_csv",
    n = nrow(cell_srm)
  ),
  manifest_path
)

cell_walk <- dat %>%
  count(FOF_status_f, Walk500m_3class) %>%
  tidyr::complete(FOF_status_f, Walk500m_3class, fill = list(n = 0))
cell_walk_path <- file.path(outputs_dir, paste0(script_label, "_qc_cell_counts_walk500m_3class.csv"))
save_table_csv(cell_walk, cell_walk_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_cell_counts_walk500m_3class",
    path = get_relpath(cell_walk_path),
    kind = "table_csv",
    n = nrow(cell_walk)
  ),
  manifest_path
)

qc_delta <- dat %>%
  group_by(FOF_status_f) %>%
  summarise(
    n = sum(!is.na(Delta_Composite_Z)),
    mean = mean(Delta_Composite_Z, na.rm = TRUE),
    sd = sd(Delta_Composite_Z, na.rm = TRUE),
    min = min(Delta_Composite_Z, na.rm = TRUE),
    p25 = quantile(Delta_Composite_Z, 0.25, na.rm = TRUE),
    median = median(Delta_Composite_Z, na.rm = TRUE),
    p75 = quantile(Delta_Composite_Z, 0.75, na.rm = TRUE),
    max = max(Delta_Composite_Z, na.rm = TRUE),
    .groups = "drop"
  )
qc_delta_path <- file.path(outputs_dir, paste0(script_label, "_qc_delta_summary_by_fof.csv"))
save_table_csv(qc_delta, qc_delta_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_delta_summary_by_fof",
    path = get_relpath(qc_delta_path),
    kind = "table_csv",
    n = nrow(qc_delta)
  ),
  manifest_path
)

dat_cc_base <- dat %>%
  filter(
    !is.na(Delta_Composite_Z),
    !is.na(Composite_Z0),
    !is.na(FOF_status_f),
    !is.na(age),
    !is.na(sex),
    !is.na(BMI)
  )

save_model_tbl <- function(tbl, label) {
  path <- file.path(outputs_dir, paste0(script_label, "_", label, ".csv"))
  save_table_csv(tbl, path)
  append_manifest(
    manifest_row(
      script = script_label,
      label = label,
      path = get_relpath(path),
      kind = "table_csv",
      n = nrow(tbl)
    ),
    manifest_path
  )
  invisible(path)
}

# --- Model 1: neuro_any -----------------------------------------------------
dat_cc_neuro <- dat_cc_base %>%
  filter(!is.na(neuro_any))

if (!nrow(dat_cc_neuro)) {
  stop("No complete-case data available for neuro_any model (dat_cc_neuro).")
}

fit_neuro <- lm(
  Delta_Composite_Z ~ FOF_status_f * neuro_any + Composite_Z0 + age + sex + BMI,
  data = dat_cc_neuro
)
coef_neuro <- broom::tidy(fit_neuro, conf.int = TRUE) %>%
  mutate(model = "delta_neuro_any")
save_model_tbl(coef_neuro, "fit_ancova_delta_neuro_any_coefficients")

emm_neuro <- as.data.frame(emmeans::emmeans(fit_neuro, ~ FOF_status_f | neuro_any))
save_model_tbl(emm_neuro, "emmeans_neuro_any")

ctr_neuro <- as.data.frame(emmeans::contrast(emmeans::emmeans(fit_neuro, ~ FOF_status_f | neuro_any),
                                             method = "revpairwise"))
save_model_tbl(ctr_neuro, "emmeans_contrast_neuro_any")

# --- Model 2: SRH 3-class ---------------------------------------------------
dat_cc_srh <- dat_cc_base %>%
  filter(!is.na(SRH_3class))

if (!nrow(dat_cc_srh)) {
  stop("No complete-case data available for SRH model (dat_cc_srh).")
}

fit_srh <- lm(
  Delta_Composite_Z ~ FOF_status_f * SRH_3class + Composite_Z0 + age + sex + BMI,
  data = dat_cc_srh
)
coef_srh <- broom::tidy(fit_srh, conf.int = TRUE) %>%
  mutate(model = "delta_srh_3class")
save_model_tbl(coef_srh, "fit_ancova_delta_srh_3class_coefficients")

emm_srh <- as.data.frame(emmeans::emmeans(fit_srh, ~ FOF_status_f | SRH_3class))
save_model_tbl(emm_srh, "emmeans_srh_3class")

ctr_srh <- as.data.frame(emmeans::contrast(emmeans::emmeans(fit_srh, ~ FOF_status_f | SRH_3class),
                                           method = "revpairwise"))
save_model_tbl(ctr_srh, "emmeans_contrast_srh_3class")

# --- Model 3: SRM 3-class ---------------------------------------------------
dat_cc_srm <- dat_cc_base %>%
  filter(!is.na(SRM_3class))

if (!nrow(dat_cc_srm)) {
  stop("No complete-case data available for SRM model (dat_cc_srm).")
}

fit_srm <- lm(
  Delta_Composite_Z ~ FOF_status_f * SRM_3class + Composite_Z0 + age + sex + BMI,
  data = dat_cc_srm
)
coef_srm <- broom::tidy(fit_srm, conf.int = TRUE) %>%
  mutate(model = "delta_srm_3class")
save_model_tbl(coef_srm, "fit_ancova_delta_srm_3class_coefficients")

emm_srm <- as.data.frame(emmeans::emmeans(fit_srm, ~ FOF_status_f | SRM_3class))
save_model_tbl(emm_srm, "emmeans_srm_3class")

ctr_srm <- as.data.frame(emmeans::contrast(emmeans::emmeans(fit_srm, ~ FOF_status_f | SRM_3class),
                                           method = "revpairwise"))
save_model_tbl(ctr_srm, "emmeans_contrast_srm_3class")

# --- Model 4: Walk500m 3-class -----------------------------------------------
dat_cc_walk <- dat_cc_base %>%
  filter(!is.na(Walk500m_3class))

if (!nrow(dat_cc_walk)) {
  stop("No complete-case data available for Walk500m model (dat_cc_walk).")
}

fit_walk <- lm(
  Delta_Composite_Z ~ FOF_status_f * Walk500m_3class + Composite_Z0 + age + sex + BMI,
  data = dat_cc_walk
)
coef_walk <- broom::tidy(fit_walk, conf.int = TRUE) %>%
  mutate(model = "delta_walk500m_3class")
save_model_tbl(coef_walk, "fit_ancova_delta_walk500m_3class_coefficients")

emm_walk <- as.data.frame(emmeans::emmeans(fit_walk, ~ FOF_status_f | Walk500m_3class))
save_model_tbl(emm_walk, "emmeans_walk500m_3class")

ctr_walk <- as.data.frame(emmeans::contrast(emmeans::emmeans(fit_walk, ~ FOF_status_f | Walk500m_3class),
                                            method = "revpairwise"))
save_model_tbl(ctr_walk, "emmeans_contrast_walk500m_3class")

# --- Summary text ------------------------------------------------------------
txt_path <- file.path(outputs_dir, paste0(script_label, "_summary.txt"))
writeLines(
  c(
    "K07_MAIN Multi-domain Moderators Delta ANCOVA summary",
    paste0("N base complete-case: ", nrow(dat_cc_base)),
    paste0("N neuro_any: ", nrow(dat_cc_neuro)),
    paste0("N SRH 3-class: ", nrow(dat_cc_srh)),
    paste0("N SRM 3-class: ", nrow(dat_cc_srm)),
    paste0("N Walk500m 3-class: ", nrow(dat_cc_walk)),
    "Models: Delta_Composite_Z ~ FOF_status * moderator + Composite_Z0 + age + sex + BMI",
    "See CSV outputs for coefficients and emmeans/contrasts."
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
