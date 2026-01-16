#!/usr/bin/env Rscript
# ==============================================================================
# K06_MAIN - Delta ANCOVA moderation (baseline -> 12 months)
# File tag: K06_MAIN.V1_moderators-delta-ancova.R
# Purpose: FOF moderation models on 12-month change in composite function
#
# Outcome: Delta_Composite_Z (12-month change in composite function)
# Predictors: FOF_status_f
# Moderator/interaction: PainVAS0 (continuous + dichotomized), SRH_3class, SRM_3class
# Grouping variable: None (wide format)
# Covariates: Composite_Z0, age, sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, age, sex, BMI, kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# PainVAS0, SRH, oma_arvio_liikuntakyky
#
# Mapping example (raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn -> FOF_status -> FOF_status_f
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z12
# Delta_Composite_Z = Composite_Z12 - Composite_Z0
# PainVAS0 -> PainVAS0 (continuous) + PainVAS0_tertile + PainVAS0_G2
# SRH -> SRH_3class (0/1/2 -> good/intermediate/poor)
# oma_arvio_liikuntakyky -> SRM_3class (0/1/2 -> good/intermediate/poor)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K06_MAIN (canonical)
# - outputs dir: R-scripts/K06_MAIN/outputs/  (resolved via init_paths(script_label))
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
# 08) Save artifacts -> R-scripts/K06_MAIN/outputs/
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
# Derive script_label from --file, supporting file tags like: K06_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K06_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K06_MAIN"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K06 Moderators Delta ANCOVA\n")
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
  "PainVAS0",
  "SRH",
  "oma_arvio_liikuntakyky"
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
  "PainVAS0",
  "SRH",
  "oma_arvio_liikuntakyky"
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

qc_overall <- raw_data %>%
  summarise(
    n = dplyr::n(),
    miss_age = sum(is.na(age)),
    miss_sex = sum(is.na(sex)),
    miss_BMI = sum(is.na(BMI)),
    miss_z0 = sum(is.na(ToimintaKykySummary0)),
    miss_z12 = sum(is.na(ToimintaKykySummary2)),
    miss_pain = sum(is.na(PainVAS0)),
    miss_srh = sum(is.na(SRH)),
    miss_srm = sum(is.na(oma_arvio_liikuntakyky))
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
    miss_pain = sum(is.na(PainVAS0)),
    miss_srh = sum(is.na(SRH)),
    miss_srm = sum(is.na(oma_arvio_liikuntakyky)),
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
    PainVAS0 = PainVAS0,
    SRH = SRH,
    SRM = oma_arvio_liikuntakyky
  )

delta_diff <- dat$Delta_Composite_Z - (dat$Composite_Z12 - dat$Composite_Z0)
delta_diff <- delta_diff[!is.na(delta_diff)]
if (length(delta_diff) > 0 && any(abs(delta_diff) > 1e-8)) {
  stop("Delta check failed: Composite_Z12 - Composite_Z0 mismatch detected.")
}

bad_srh <- setdiff(stats::na.omit(unique(dat$SRH)), 0:2)
if (length(bad_srh) > 0L) {
  stop(
    "Unexpected SRH code(s) detected: ",
    paste(bad_srh, collapse = ", "),
    ". Expected values are 0, 1, 2 or NA."
  )
}

bad_srm <- setdiff(stats::na.omit(unique(dat$SRM)), 0:2)
if (length(bad_srm) > 0L) {
  stop(
    "Unexpected SRM code(s) detected: ",
    paste(bad_srm, collapse = ", "),
    ". Expected values are 0, 1, 2 or NA."
  )
}

if (all(is.na(dat$PainVAS0))) {
  stop("PainVAS0 is entirely missing; cannot compute tertiles for PainVAS0_G2.")
}

pain_tertiles <- quantile(dat$PainVAS0, probs = c(1 / 3, 2 / 3), na.rm = TRUE)

dat <- dat %>%
  mutate(
    PainVAS0_tertile = case_when(
      is.na(PainVAS0) ~ NA_character_,
      PainVAS0 <= pain_tertiles[1] ~ "T1",
      PainVAS0 <= pain_tertiles[2] ~ "T2",
      TRUE ~ "T3"
    ),
    PainVAS0_tertile = factor(PainVAS0_tertile, levels = c("T1", "T2", "T3")),
    PainVAS0_G2 = case_when(
      is.na(PainVAS0_tertile) ~ NA_character_,
      PainVAS0_tertile == "T1" ~ "low",
      PainVAS0_tertile %in% c("T2", "T3") ~ "high"
    ),
    PainVAS0_G2 = factor(PainVAS0_G2, levels = c("low", "high")),
    SRH_3class = case_when(
      SRH == 0 ~ "good",
      SRH == 1 ~ "intermediate",
      SRH == 2 ~ "poor",
      TRUE ~ NA_character_
    ),
    SRH_3class = factor(SRH_3class, levels = c("good", "intermediate", "poor")),
    SRM_3class = case_when(
      SRM == 0 ~ "good",
      SRM == 1 ~ "intermediate",
      SRM == 2 ~ "poor",
      TRUE ~ NA_character_
    ),
    SRM_3class = factor(SRM_3class, levels = c("good", "intermediate", "poor"))
  )

cell_pain_g2 <- dat %>%
  count(FOF_status_f, PainVAS0_G2) %>%
  tidyr::complete(FOF_status_f, PainVAS0_G2, fill = list(n = 0))
cell_pain_path <- file.path(outputs_dir, paste0(script_label, "_qc_cell_counts_pain_g2.csv"))
save_table_csv(cell_pain_g2, cell_pain_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_cell_counts_pain_g2",
    path = get_relpath(cell_pain_path),
    kind = "table_csv",
    n = nrow(cell_pain_g2)
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

# --- Model 1: PainVAS0 continuous -------------------------------------------
dat_cc_pain <- dat_cc_base %>%
  filter(!is.na(PainVAS0))

if (!nrow(dat_cc_pain)) {
  stop("No complete-case data available for PainVAS0 continuous model (dat_cc_pain).")
}

fit_pain <- lm(
  Delta_Composite_Z ~ FOF_status_f * PainVAS0 + Composite_Z0 + age + sex + BMI,
  data = dat_cc_pain
)
coef_pain <- broom::tidy(fit_pain, conf.int = TRUE) %>%
  mutate(model = "delta_pain_continuous")
save_model_tbl(coef_pain, "fit_ancova_delta_pain_continuous_coefficients")

# --- Model 2: PainVAS0 dichotomized -----------------------------------------
dat_cc_pain_g2 <- dat_cc_base %>%
  filter(!is.na(PainVAS0_G2))

if (!nrow(dat_cc_pain_g2)) {
  stop("No complete-case data available for PainVAS0 dichotomized model (dat_cc_pain_g2).")
}

fit_pain_g2 <- lm(
  Delta_Composite_Z ~ FOF_status_f * PainVAS0_G2 + Composite_Z0 + age + sex + BMI,
  data = dat_cc_pain_g2
)
coef_pain_g2 <- broom::tidy(fit_pain_g2, conf.int = TRUE) %>%
  mutate(model = "delta_pain_g2")
save_model_tbl(coef_pain_g2, "fit_ancova_delta_pain_g2_coefficients")

emm_pain_g2 <- as.data.frame(emmeans::emmeans(fit_pain_g2, ~ FOF_status_f | PainVAS0_G2))
save_model_tbl(emm_pain_g2, "emmeans_pain_g2")

ctr_pain_g2 <- as.data.frame(emmeans::contrast(emmeans::emmeans(fit_pain_g2, ~ FOF_status_f | PainVAS0_G2),
                                               method = "revpairwise"))
save_model_tbl(ctr_pain_g2, "emmeans_contrast_pain_g2")

# --- Model 3: SRH 3-class ---------------------------------------------------
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

# --- Model 4: SRM 3-class ---------------------------------------------------
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

# --- Summary text ------------------------------------------------------------
txt_path <- file.path(outputs_dir, paste0(script_label, "_summary.txt"))
writeLines(
  c(
    "K06_MAIN Moderators Delta ANCOVA summary",
    paste0("N base complete-case: ", nrow(dat_cc_base)),
    paste0("N pain continuous: ", nrow(dat_cc_pain)),
    paste0("N pain G2: ", nrow(dat_cc_pain_g2)),
    paste0("N SRH 3-class: ", nrow(dat_cc_srh)),
    paste0("N SRM 3-class: ", nrow(dat_cc_srm)),
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
