#!/usr/bin/env Rscript
# ==============================================================================
# K15_MAIN - modified 3-item physical frailty proxy (motor-oriented)
# File tag: K15_MAIN.V1_frailty-proxy.R
# Purpose: Derive frailty indicators and categories for K16 analyses
#
# Outcome: None (derives frailty variables)
# Grouping variable: frailty_cat_3_A ("robust"/"pre-frail"/"frail")
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# Puristus0, Puristus2, kavelynopeus_m_sek0, kavelynopeus_m_sek2,
# Tuoli0, Tuoli2, Seisominen0, Seisominen2,
# BMI, sex, age, PainVAS0, oma_arvio_liikuntakyky
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
cat("K15 modified 3-item physical frailty proxy (motor-oriented)\n")
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
  "BMI", "sex", "age", "PainVAS0", "oma_arvio_liikuntakyky"
)
missing_cols <- setdiff(req_cols, names(raw_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

# --- Column type checks ------------------------------------------------------
type_cols <- c(
  "ToimintaKykySummary0",
  "ToimintaKykySummary2",
  "Puristus0",
  "Puristus2",
  "kavelynopeus_m_sek0",
  "kavelynopeus_m_sek2",
  "Tuoli0",
  "Tuoli2",
  "Seisominen0",
  "Seisominen2",
  "BMI",
  "sex",
  "age",
  "PainVAS0",
  "oma_arvio_liikuntakyky"
)
bad_types <- type_cols[!vapply(raw_data[type_cols], is.numeric, logical(1))]
if (length(bad_types) > 0) {
  stop("Expected numeric columns: ", paste(bad_types, collapse = ", "))
}

# --- Standardize + QC --------------------------------------------------------
qc_overall <- raw_data %>%
  summarise(
    n = dplyr::n(),
    miss_age = sum(is.na(age)),
    miss_sex = sum(is.na(sex)),
    miss_BMI = sum(is.na(BMI)),
    miss_z0 = sum(is.na(ToimintaKykySummary0)),
    miss_z12 = sum(is.na(ToimintaKykySummary2)),
    miss_grip0 = sum(is.na(Puristus0)),
    miss_grip2 = sum(is.na(Puristus2)),
    miss_walk0 = sum(is.na(kavelynopeus_m_sek0)),
    miss_walk2 = sum(is.na(kavelynopeus_m_sek2)),
    miss_chair0 = sum(is.na(Tuoli0)),
    miss_chair2 = sum(is.na(Tuoli2)),
    miss_balance0 = sum(is.na(Seisominen0)),
    miss_balance2 = sum(is.na(Seisominen2)),
    miss_srm = sum(is.na(oma_arvio_liikuntakyky)),
    miss_pain = sum(is.na(PainVAS0))
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
    # CHANGELOG: 2026-02-25 - Removed falls from low activity to avoid circularity/collider risk.
    frailty_low_activity = case_when(
      is.na(oma_arvio_liikuntakyky) ~ NA_integer_,
      oma_arvio_liikuntakyky %in% c(0, 1) ~ 1L,
      TRUE ~ 0L
    ),
    frailty_low_BMI = case_when(
      is.na(BMI) ~ NA_integer_,
      BMI < low_BMI_threshold ~ 1L,
      TRUE ~ 0L
    ),
    frailty_count_3_A = case_when(
      is.na(frailty_weakness) | is.na(frailty_slowness) | is.na(frailty_low_activity) ~ NA_integer_,
      TRUE ~ (frailty_weakness + frailty_slowness + frailty_low_activity)
    ),
    frailty_cat_3_A = case_when(
      is.na(frailty_count_3_A) ~ NA_character_,
      frailty_count_3_A == 0 ~ "robust",
      frailty_count_3_A == 1 ~ "pre-frail",
      frailty_count_3_A >= 2 ~ "frail"
    ),
    # Pragmatic path fallback: unable-codes not detected in current K15 recode rules.
    frailty_count_3_B = frailty_count_3_A,
    frailty_cat_3_B = frailty_cat_3_A,
    # Backward-compatible aliases for downstream scripts.
    frailty_count_3 = frailty_count_3_A,
    frailty_cat_3 = frailty_cat_3_A,
    frailty_cat_3_A = factor(frailty_cat_3_A, levels = c("robust", "pre-frail", "frail")),
    frailty_cat_3_B = factor(frailty_cat_3_B, levels = c("robust", "pre-frail", "frail")),
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

# Modified 3-item physical frailty proxy (motor-oriented);
# does not include exhaustion or weight loss.
qc_components_missing_overall <- tibble::tibble(
  group = "overall",
  component = c("frailty_weakness", "frailty_slowness", "frailty_low_activity"),
  n_missing = c(
    sum(is.na(analysis_data$frailty_weakness)),
    sum(is.na(analysis_data$frailty_slowness)),
    sum(is.na(analysis_data$frailty_low_activity))
  )
) %>%
  mutate(pct_missing = 100 * n_missing / nrow(analysis_data))

if ("FOF_status_factor" %in% names(analysis_data)) {
  qc_components_missing_by_fof <- analysis_data %>%
    group_by(FOF_status_factor) %>%
    summarise(
      n_group = n(),
      frailty_weakness_missing = sum(is.na(frailty_weakness)),
      frailty_slowness_missing = sum(is.na(frailty_slowness)),
      frailty_low_activity_missing = sum(is.na(frailty_low_activity)),
      .groups = "drop"
    ) %>%
    tidyr::pivot_longer(
      cols = c(frailty_weakness_missing, frailty_slowness_missing, frailty_low_activity_missing),
      names_to = "component",
      values_to = "n_missing"
    ) %>%
    mutate(
      group = as.character(FOF_status_factor),
      component = gsub("_missing$", "", component),
      pct_missing = 100 * n_missing / n_group
    ) %>%
    select(group, component, n_missing, pct_missing)
} else {
  qc_components_missing_by_fof <- tibble::tibble(
    group = "FOF_status_unavailable",
    component = "all",
    n_missing = NA_integer_,
    pct_missing = NA_real_
  )
}

qc_components_missing <- bind_rows(
  qc_components_missing_overall,
  qc_components_missing_by_fof
)
save_table_csv_html(
  qc_components_missing,
  "K15_frailty_components_missingness",
  n = nrow(qc_components_missing),
  write_html = FALSE
)

qc_score_missing <- tibble::tibble(
  score = c("frailty_count_3_A", "frailty_count_3_B"),
  n_missing = c(
    sum(is.na(analysis_data$frailty_count_3_A)),
    sum(is.na(analysis_data$frailty_count_3_B))
  )
) %>%
  mutate(pct_missing = 100 * n_missing / nrow(analysis_data))
save_table_csv_html(
  qc_score_missing,
  "K15_frailty_score_missingness",
  n = nrow(qc_score_missing),
  write_html = FALSE
)

if ("kaatuminen" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>%
    mutate(
      frailty_low_activity_legacy = case_when(
        is.na(oma_arvio_liikuntakyky) & is.na(kaatuminen) & is.na(PainVAS0) ~ NA_integer_,
        oma_arvio_liikuntakyky %in% c(0, 1) ~ 1L,
        kaatuminen == 1 ~ 1L,
        is.na(oma_arvio_liikuntakyky) | is.na(kaatuminen) | is.na(PainVAS0) ~ NA_integer_,
        TRUE ~ 0L
      ),
      frailty_count_3_legacy = case_when(
        is.na(frailty_weakness) | is.na(frailty_slowness) | is.na(frailty_low_activity_legacy) ~ NA_integer_,
        TRUE ~ (frailty_weakness + frailty_slowness + frailty_low_activity_legacy)
      ),
      frailty_cat_3_legacy = case_when(
        is.na(frailty_count_3_legacy) ~ NA_character_,
        frailty_count_3_legacy == 0 ~ "robust",
        frailty_count_3_legacy == 1 ~ "pre-frail",
        frailty_count_3_legacy >= 2 ~ "frail"
      ),
      frailty_cat_3_legacy = factor(frailty_cat_3_legacy, levels = c("robust", "pre-frail", "frail"))
    )
  qc_legacy_vs_new <- analysis_data %>%
    count(frailty_cat_3_legacy, frailty_cat_3_A, .drop = FALSE) %>%
    arrange(frailty_cat_3_legacy, frailty_cat_3_A)
} else {
  qc_legacy_vs_new <- tibble::tibble(
    note = "legacy_not_available: column 'kaatuminen' not present at this step."
  )
}
save_table_csv_html(
  qc_legacy_vs_new,
  "K15_frailty_legacy_vs_new",
  n = nrow(qc_legacy_vs_new),
  write_html = FALSE
)

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
    "Exposure: modified 3-item physical frailty proxy (motor-oriented).",
    "Constraint: does not include exhaustion or weight loss.",
    "Frailty categories: robust (0), pre-frail (1), frail (>=2).",
    "Paths: conservative A and pragmatic B (B=A when unable-codes not detected)."
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

# Lightweight self-checks for A/B paths.
stopifnot(all(is.na(analysis_data$frailty_count_3_A) | analysis_data$frailty_count_3_A %in% 0:3))
stopifnot(all(is.na(analysis_data$frailty_count_3_B) | analysis_data$frailty_count_3_B %in% 0:3))
stopifnot(identical(levels(analysis_data$frailty_cat_3_A), c("robust", "pre-frail", "frail")))
stopifnot(identical(levels(analysis_data$frailty_cat_3_B), c("robust", "pre-frail", "frail")))
stopifnot(all(is.na(analysis_data$frailty_cat_3_A) == is.na(analysis_data$frailty_count_3_A)))
stopifnot(all(is.na(analysis_data$frailty_cat_3_B) == is.na(analysis_data$frailty_count_3_B)))

save_sessioninfo_manifest()
