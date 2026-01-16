#!/usr/bin/env Rscript
# ==============================================================================
# K16_MAIN - Frailty-adjusted FOF models (ANCOVA + mixed models)
# File tag: K16_MAIN.V1_frailty-adjusted-ancova-mixed.R
# Purpose: Test whether FOF effects on functional change persist after adjusting
#          for frailty status derived in K15.
#
# Outcomes:
# - Delta_Composite_Z (ANCOVA; 12-month change)
# - Composite_Z over time (mixed models; time_f 0 vs 12)
#
# Required vars (from K15 output; DO NOT INVENT):
# - ID (or Jnro/NRO)
# - Composite_Z0, Composite_Z12 (or ToimintaKykySummary0/2)
# - FOF_status or FOF_status_factor (0/1 or factor)
# - age (or Age), sex (or Sex), BMI
# - frailty_cat_3 or frailty_count_3
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124
#
# Outputs + manifest:
# - script_label: K16_MAIN
# - outputs dir: R-scripts/K16_MAIN/outputs/  (init_paths)
# - manifest: append 1 row per artifact to manifest/manifest.csv
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(lme4)
  library(lmerTest)
  library(broom)
})

if (!requireNamespace("broom.mixed", quietly = TRUE)) {
  stop("Package 'broom.mixed' is required but not installed.")
}
library(broom.mixed)

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K16_MAIN"
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K16_MAIN"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "qc.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K16 Frailty-adjusted FOF models\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

set.seed(20251124)

# --- Load K15 output (frailty-augmented data) --------------------------------
k15_rdata <- here::here("R-scripts", "K15_MAIN", "outputs",
                        "K15_frailty_analysis_data.RData")
if (!file.exists(k15_rdata)) {
  stop("K15 output not found: ", k15_rdata,
       "\nRun K15_MAIN first to generate K15_frailty_analysis_data.RData.")
}
load(k15_rdata)
if (!exists("analysis_data")) stop("Expected object 'analysis_data' not found in K15 RData.")

# --- Harmonize required variables -------------------------------------------
if (!("ID" %in% names(analysis_data))) {
  if ("Jnro" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(ID = Jnro)
  } else if ("NRO" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(ID = NRO)
  } else {
    stop("Missing ID: expected ID or Jnro/NRO in K15 output.")
  }
}

if (!("Composite_Z0" %in% names(analysis_data))) {
  if ("ToimintaKykySummary0" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(Composite_Z0 = ToimintaKykySummary0)
  } else {
    stop("Missing Composite_Z0: expected Composite_Z0 or ToimintaKykySummary0.")
  }
}

if (!("Composite_Z12" %in% names(analysis_data))) {
  if ("ToimintaKykySummary2" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(Composite_Z12 = ToimintaKykySummary2)
  } else {
    stop("Missing Composite_Z12: expected Composite_Z12 or ToimintaKykySummary2.")
  }
}

if (!("age" %in% names(analysis_data)) && "Age" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>% mutate(age = Age)
}
if (!("sex" %in% names(analysis_data)) && "Sex" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>% mutate(sex = Sex)
}

if (!("FOF_status" %in% names(analysis_data)) &&
    !("FOF_status_factor" %in% names(analysis_data))) {
  stop("Missing required FOF column: expected either 'FOF_status' or ",
       "'FOF_status_factor' in analysis_data.")
}

fof_raw <- if ("FOF_status_factor" %in% names(analysis_data)) {
  analysis_data$FOF_status_factor
} else {
  analysis_data$FOF_status
}

analysis_data <- analysis_data %>%
  mutate(
    FOF_status = dplyr::case_when(
      is.na(fof_raw) ~ NA_character_,
      fof_raw %in% c(0, "0", "nonFOF", "Ei FOF", "No FOF") ~ "nonFOF",
      fof_raw %in% c(1, "1", "FOF") ~ "FOF",
      TRUE ~ as.character(fof_raw)
    ),
    FOF_status = factor(FOF_status, levels = c("nonFOF", "FOF")),
    sex = case_when(
      sex %in% c(0, "0", "female", "Female", "F") ~ "female",
      sex %in% c(1, "1", "male", "Male", "M") ~ "male",
      TRUE ~ as.character(sex)
    ),
    sex = factor(sex)
  )

if (!("frailty_score_3" %in% names(analysis_data))) {
  if ("frailty_count_3" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(frailty_score_3 = as.numeric(frailty_count_3))
  } else {
    stop("Missing frailty_score_3: expected frailty_score_3 or frailty_count_3.")
  }
}

if (!("frailty_cat_3" %in% names(analysis_data))) {
  if ("frailty_count_3" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>%
      mutate(
        frailty_cat_3 = case_when(
          is.na(frailty_count_3) ~ NA_character_,
          frailty_count_3 == 0 ~ "robust",
          frailty_count_3 == 1 ~ "pre-frail",
          frailty_count_3 >= 2 ~ "frail"
        )
      )
  } else {
    stop("Missing frailty_cat_3 or frailty_count_3.")
  }
}

analysis_data <- analysis_data %>%
  mutate(
    frailty_cat_3 = factor(
      tolower(as.character(frailty_cat_3)),
      levels = c("robust", "pre-frail", "frail")
    )
  )

# --- Required columns gate ---------------------------------------------------
req_cols <- c("ID", "FOF_status", "Composite_Z0", "Composite_Z12",
              "age", "sex", "BMI", "frailty_cat_3", "frailty_score_3")
missing_cols <- setdiff(req_cols, names(analysis_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

# --- Column type checks ------------------------------------------------------
type_cols <- c("Composite_Z0", "Composite_Z12", "age", "BMI", "frailty_score_3")
bad_types <- type_cols[!vapply(analysis_data[type_cols], is.numeric, logical(1))]
if (length(bad_types) > 0) {
  stop("Expected numeric columns: ", paste(bad_types, collapse = ", "))
}

# --- Minimal QC --------------------------------------------------------------
qc_overall <- analysis_data %>%
  summarise(
    n = dplyr::n(),
    miss_id = sum(is.na(ID)),
    miss_fof = sum(is.na(FOF_status)),
    miss_z0 = sum(is.na(Composite_Z0)),
    miss_z12 = sum(is.na(Composite_Z12)),
    miss_age = sum(is.na(age)),
    miss_sex = sum(is.na(sex)),
    miss_BMI = sum(is.na(BMI)),
    miss_frailty_cat = sum(is.na(frailty_cat_3)),
    miss_frailty_score = sum(is.na(frailty_score_3))
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

# --- QC: FOF/frailty distributions -------------------------------------------
qc_fof <- analysis_data %>%
  count(FOF_status, name = "n")
qc_frailty <- analysis_data %>%
  count(frailty_cat_3, name = "n")

qc_fof_path <- file.path(outputs_dir, paste0(script_label, "_qc_fof_counts.csv"))
save_table_csv(qc_fof, qc_fof_path)
append_manifest(
  manifest_row(script = script_label, label = "qc_fof_counts",
               path = get_relpath(qc_fof_path), kind = "table_csv", n = nrow(qc_fof)),
  manifest_path
)

qc_frailty_path <- file.path(outputs_dir, paste0(script_label, "_qc_frailty_counts.csv"))
save_table_csv(qc_frailty, qc_frailty_path)
append_manifest(
  manifest_row(script = script_label, label = "qc_frailty_counts",
               path = get_relpath(qc_frailty_path), kind = "table_csv", n = nrow(qc_frailty)),
  manifest_path
)

# --- Prepare wide + long datasets --------------------------------------------
analysis_data <- analysis_data %>%
  mutate(Delta_Composite_Z = Composite_Z12 - Composite_Z0)

delta_diff <- analysis_data$Delta_Composite_Z - (analysis_data$Composite_Z12 - analysis_data$Composite_Z0)
delta_diff <- delta_diff[!is.na(delta_diff)]
if (length(delta_diff) > 0 && any(abs(delta_diff) > 1e-8)) {
  stop("Delta check failed: Composite_Z12 - Composite_Z0 mismatch detected.")
}

dat_delta <- analysis_data %>%
  dplyr::select(
    Delta_Composite_Z, FOF_status, frailty_cat_3, frailty_score_3,
    Composite_Z0, age, sex, BMI
  ) %>%
  filter(stats::complete.cases(.)) %>%
  droplevels()

if (nrow(dat_delta) == 0L) {
  stop("No complete-case data available for ANCOVA models (dat_delta).")
}

if (any(is.na(analysis_data$ID))) {
  stop("Missing ID values detected; cannot fit mixed models without ID.")
}

analysis_long <- analysis_data %>%
  dplyr::select(
    ID, FOF_status, frailty_cat_3, frailty_score_3,
    age, sex, BMI, Composite_Z0, Composite_Z12
  ) %>%
  pivot_longer(
    cols = c(Composite_Z0, Composite_Z12),
    names_to = "timepoint",
    values_to = "Composite_Z"
  ) %>%
  mutate(
    time_months = ifelse(timepoint == "Composite_Z0", 0, 12),
    time_f = factor(time_months, levels = c(0, 12), labels = c("0", "12"))
  )

bad_time <- setdiff(unique(stats::na.omit(analysis_long$time_months)), c(0, 12))
if (length(bad_time) > 0) {
  stop("Unexpected time_months values: ", paste(bad_time, collapse = ", "))
}

if (nrow(analysis_long) == 0L) {
  stop("No data available for mixed models (analysis_long).")
}

# --- ANCOVA models -----------------------------------------------------------
mod_delta_baseline <- lm(Delta_Composite_Z ~ FOF_status + Composite_Z0 + age + sex + BMI,
                         data = dat_delta)
mod_delta_frailty <- lm(Delta_Composite_Z ~ FOF_status + frailty_cat_3 + Composite_Z0 + age + sex + BMI,
                        data = dat_delta)
mod_delta_frailty_cont <- lm(Delta_Composite_Z ~ FOF_status + frailty_score_3 + Composite_Z0 + age + sex + BMI,
                             data = dat_delta)

ancova_results <- list(
  baseline = broom::tidy(mod_delta_baseline, conf.int = TRUE),
  frailty_cat = broom::tidy(mod_delta_frailty, conf.int = TRUE),
  frailty_cont = broom::tidy(mod_delta_frailty_cont, conf.int = TRUE)
)

save_table_csv_html(ancova_results$baseline, "ancova_baseline", n = nrow(ancova_results$baseline))
save_table_csv_html(ancova_results$frailty_cat, "ancova_frailty_cat", n = nrow(ancova_results$frailty_cat))
save_table_csv_html(ancova_results$frailty_cont, "ancova_frailty_cont", n = nrow(ancova_results$frailty_cont))

ancova_comp <- data.frame(
  Model = c("Baseline (no frailty)", "Frailty categorical", "Frailty continuous"),
  AIC = c(AIC(mod_delta_baseline), AIC(mod_delta_frailty), AIC(mod_delta_frailty_cont)),
  BIC = c(BIC(mod_delta_baseline), BIC(mod_delta_frailty), BIC(mod_delta_frailty_cont)),
  R2 = c(summary(mod_delta_baseline)$r.squared,
         summary(mod_delta_frailty)$r.squared,
         summary(mod_delta_frailty_cont)$r.squared),
  Adj_R2 = c(summary(mod_delta_baseline)$adj.r.squared,
             summary(mod_delta_frailty)$adj.r.squared,
             summary(mod_delta_frailty_cont)$adj.r.squared)
)
save_table_csv_html(ancova_comp, "ancova_model_comparison", n = nrow(ancova_comp))

# --- Mixed models ------------------------------------------------------------
mod_mixed_baseline <- lmer(
  Composite_Z ~ time_f * FOF_status + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)
mod_mixed_frailty <- lmer(
  Composite_Z ~ time_f * FOF_status + frailty_cat_3 + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)
mod_mixed_frailty_cont <- lmer(
  Composite_Z ~ time_f * FOF_status + frailty_score_3 + age + sex + BMI + (1 | ID),
  data = analysis_long,
  REML = TRUE
)

mixed_results <- list(
  baseline = broom.mixed::tidy(mod_mixed_baseline, conf.int = TRUE),
  frailty_cat = broom.mixed::tidy(mod_mixed_frailty, conf.int = TRUE),
  frailty_cont = broom.mixed::tidy(mod_mixed_frailty_cont, conf.int = TRUE)
)

save_table_csv_html(mixed_results$baseline, "mixed_baseline", n = nrow(mixed_results$baseline))
save_table_csv_html(mixed_results$frailty_cat, "mixed_frailty_cat", n = nrow(mixed_results$frailty_cat))
save_table_csv_html(mixed_results$frailty_cont, "mixed_frailty_cont", n = nrow(mixed_results$frailty_cont))

mixed_comp <- data.frame(
  Model = c("Baseline (no frailty)", "Frailty categorical", "Frailty continuous"),
  AIC = c(
    AIC(update(mod_mixed_baseline, REML = FALSE)),
    AIC(update(mod_mixed_frailty, REML = FALSE)),
    AIC(update(mod_mixed_frailty_cont, REML = FALSE))
  ),
  BIC = c(
    BIC(update(mod_mixed_baseline, REML = FALSE)),
    BIC(update(mod_mixed_frailty, REML = FALSE)),
    BIC(update(mod_mixed_frailty_cont, REML = FALSE))
  )
)
save_table_csv_html(mixed_comp, "mixed_model_comparison", n = nrow(mixed_comp))

# --- Session info ------------------------------------------------------------
save_sessioninfo_manifest()

message("K16 complete. Outputs saved to: ", outputs_dir)
