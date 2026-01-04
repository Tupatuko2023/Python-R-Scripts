#!/usr/bin/env Rscript
# ==============================================================================
# K08_MAIN - Delta ANCOVA moderation by balance problems and 500 m walking ability
# File tag: K08_MAIN.V1_balance-walk-moderators-delta-ancova.R
# Purpose: FOF moderation models on change in physical performance outcomes
#
# Outcomes: Delta_Composite_Z, Delta_HGS, Delta_MWS, Delta_FTSST, Delta_SLS
# Predictors: FOF_status_f
# Moderator/interaction: Balance_problem, Walk500m_G_final
# Grouping variable: None (wide format)
# Covariates: Composite_Z0 / baseline of each outcome, age, sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, age, sex, BMI, kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# tasapainovaikeus, Vaikeus500m
#
# Optional outcome vars (used only if present):
# Puristus0/2, kavelynopeus_m_sek0/2, Tuoli0/2, Seisominen0/2
#
# Mapping example (raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn -> FOF_status -> FOF_status_f
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z12
# Delta_Composite_Z = Composite_Z12 - Composite_Z0
# tasapainovaikeus (0/1) -> Balance_problem
# Vaikeus500m (0/1/2) -> Walk500m_3class -> Walk500m_G_final
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K08_MAIN (canonical)
# - outputs dir: R-scripts/K08_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Standardize vars + QC (sanity checks early)
# 04) Derive/rename vars (document mapping)
# 05) Prepare analysis datasets (complete-case)
# 06) Fit moderation models (FOF × moderator, delta outcomes)
# 07) Reporting tables (estimates + 95% CI; emmeans for moderators)
# 08) Save artifacts -> R-scripts/K08_MAIN/outputs/
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
# Derive script_label from --file, supporting file tags like: K08_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K08_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K08_MAIN"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K08 Balance/Walk Moderators Delta ANCOVA\n")
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
  "tasapainovaikeus",
  "Vaikeus500m"
)

missing_cols <- setdiff(req_cols, names(raw_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
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

balance_vals_chr <- unique(as.character(stats::na.omit(raw_data$tasapainovaikeus)))
bad_balance <- setdiff(balance_vals_chr, c("0", "1"))
if (length(bad_balance) > 0L) {
  stop(
    "Unexpected tasapainovaikeus value(s) detected: ",
    paste(bad_balance, collapse = ", "),
    ". Expected 0/1."
  )
}

walk_vals_chr <- unique(as.character(stats::na.omit(raw_data$Vaikeus500m)))
allowed_walk <- c(
  "0", "1", "2",
  "Ei vaikeuksia", "Jonkin verran", "Ei pysty",
  "no difficulty", "some difficulty", "unable"
)
bad_walk <- setdiff(walk_vals_chr, allowed_walk)
if (length(bad_walk) > 0L) {
  stop(
    "Unexpected Vaikeus500m value(s) detected: ",
    paste(bad_walk, collapse = ", "),
    ". Expected 0/1/2 or labeled values."
  )
}

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
    miss_balance = sum(is.na(tasapainovaikeus)),
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
    Balance_problem = case_when(
      tasapainovaikeus == 0 ~ "no_balance_problem",
      tasapainovaikeus == 1 ~ "balance_problem",
      TRUE ~ NA_character_
    ),
    Walk500m_raw = Vaikeus500m,
    HGS0 = if ("Puristus0" %in% names(raw_data)) Puristus0 else NA_real_,
    HGS2 = if ("Puristus2" %in% names(raw_data)) Puristus2 else NA_real_,
    MWS0 = if ("kavelynopeus_m_sek0" %in% names(raw_data)) kavelynopeus_m_sek0 else NA_real_,
    MWS2 = if ("kavelynopeus_m_sek2" %in% names(raw_data)) kavelynopeus_m_sek2 else NA_real_,
    FTSST0 = if ("Tuoli0" %in% names(raw_data)) Tuoli0 else NA_real_,
    FTSST2 = if ("Tuoli2" %in% names(raw_data)) Tuoli2 else NA_real_,
    SLS0 = if ("Seisominen0" %in% names(raw_data)) Seisominen0 else NA_real_,
    SLS2 = if ("Seisominen2" %in% names(raw_data)) Seisominen2 else NA_real_
  )

dat <- dat %>%
  mutate(
    Balance_problem = factor(Balance_problem, levels = c("no_balance_problem", "balance_problem")),
    Walk500m_3class = case_when(
      Walk500m_raw %in% c(0, "0", "Ei vaikeuksia", "no difficulty") ~ "no_difficulty",
      Walk500m_raw %in% c(1, "1", "Jonkin verran", "some difficulty") ~ "some_difficulty",
      Walk500m_raw %in% c(2, "2", "Ei pysty", "unable") ~ "unable",
      TRUE ~ NA_character_
    ),
    Walk500m_3class = factor(Walk500m_3class,
                             levels = c("no_difficulty", "some_difficulty", "unable")),
    Walk500m_G_final = case_when(
      Walk500m_3class %in% c("some_difficulty", "unable") ~ "difficulty_or_unable",
      Walk500m_3class == "no_difficulty" ~ "no_difficulty",
      TRUE ~ NA_character_
    ),
    Walk500m_G_final = factor(Walk500m_G_final,
                              levels = c("no_difficulty", "difficulty_or_unable")),
    Delta_HGS = ifelse(!is.na(HGS0) & !is.na(HGS2), HGS2 - HGS0, NA_real_),
    Delta_MWS = ifelse(!is.na(MWS0) & !is.na(MWS2), MWS2 - MWS0, NA_real_),
    # NOTE: FTSST lower (faster) is better; define delta as baseline - follow-up
    # so improvement is positive.
    Delta_FTSST = ifelse(!is.na(FTSST0) & !is.na(FTSST2), FTSST0 - FTSST2, NA_real_),
    Delta_SLS = ifelse(!is.na(SLS0) & !is.na(SLS2), SLS2 - SLS0, NA_real_)
  )

cell_balance <- dat %>%
  count(FOF_status_f, Balance_problem) %>%
  tidyr::complete(FOF_status_f, Balance_problem, fill = list(n = 0))
cell_balance_path <- file.path(outputs_dir, paste0(script_label, "_qc_cell_counts_balance_problem.csv"))
save_table_csv(cell_balance, cell_balance_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_cell_counts_balance_problem",
    path = get_relpath(cell_balance_path),
    kind = "table_csv",
    n = nrow(cell_balance)
  ),
  manifest_path
)

cell_walk3 <- dat %>%
  count(FOF_status_f, Walk500m_3class) %>%
  tidyr::complete(FOF_status_f, Walk500m_3class, fill = list(n = 0))
cell_walk3_path <- file.path(outputs_dir, paste0(script_label, "_qc_cell_counts_walk500m_3class.csv"))
save_table_csv(cell_walk3, cell_walk3_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_cell_counts_walk500m_3class",
    path = get_relpath(cell_walk3_path),
    kind = "table_csv",
    n = nrow(cell_walk3)
  ),
  manifest_path
)

cell_walk2 <- dat %>%
  count(FOF_status_f, Walk500m_G_final) %>%
  tidyr::complete(FOF_status_f, Walk500m_G_final, fill = list(n = 0))
cell_walk2_path <- file.path(outputs_dir, paste0(script_label, "_qc_cell_counts_walk500m_g_final.csv"))
save_table_csv(cell_walk2, cell_walk2_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_cell_counts_walk500m_g_final",
    path = get_relpath(cell_walk2_path),
    kind = "table_csv",
    n = nrow(cell_walk2)
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

delta_desc <- dat %>%
  select(FOF_status_f, Delta_Composite_Z, Delta_HGS, Delta_MWS, Delta_FTSST, Delta_SLS) %>%
  pivot_longer(cols = -FOF_status_f, names_to = "outcome", values_to = "delta") %>%
  group_by(FOF_status_f, outcome) %>%
  summarise(
    n = sum(!is.na(delta)),
    mean = mean(delta, na.rm = TRUE),
    sd = sd(delta, na.rm = TRUE),
    .groups = "drop"
  )
delta_desc_path <- file.path(outputs_dir, paste0(script_label, "_qc_delta_summary_all_outcomes.csv"))
save_table_csv(delta_desc, delta_desc_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "qc_delta_summary_all_outcomes",
    path = get_relpath(delta_desc_path),
    kind = "table_csv",
    n = nrow(delta_desc)
  ),
  manifest_path
)

dat_cc_base <- dat %>%
  filter(
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

run_ancova <- function(data, outcome, baseline, moderator) {
  dat_model <- data %>%
    select(FOF_status_f, all_of(c(outcome, baseline, moderator, "age", "sex", "BMI"))) %>%
    filter(
      !is.na(.data[[outcome]]),
      !is.na(.data[[baseline]]),
      !is.na(.data[[moderator]])
    )

  if (!nrow(dat_model)) {
    warning(
      "Skipping outcome ", outcome, " with moderator ", moderator,
      ": no complete-case rows after filtering on outcome/moderator."
    )
    return(NULL)
  }

  formula_txt <- paste0(
    outcome, " ~ FOF_status_f * ", moderator, " + ", baseline, " + age + sex + BMI"
  )
  fit <- lm(as.formula(formula_txt), data = dat_model)

  coef_tbl <- broom::tidy(fit, conf.int = TRUE)
  emm_spec <- as.formula(paste0("~ FOF_status_f | ", moderator))
  emm_obj <- emmeans::emmeans(fit, emm_spec)
  emm_tbl <- as.data.frame(emm_obj)
  ctr_tbl <- as.data.frame(emmeans::contrast(emm_obj, method = "revpairwise"))

  list(coef = coef_tbl, emmeans = emm_tbl, contrast = ctr_tbl)
}

baseline_map <- list(
  Delta_Composite_Z = "Composite_Z0",
  Delta_HGS = "HGS0",
  Delta_MWS = "MWS0",
  Delta_FTSST = "FTSST0",
  Delta_SLS = "SLS0"
)

available_outcomes <- names(baseline_map)[
  names(baseline_map) %in% names(dat_cc_base) &
    sapply(names(baseline_map), function(o) sum(!is.na(dat_cc_base[[o]])) > 0)
]

G_vars <- c("Balance_problem", "Walk500m_G_final")

for (G in G_vars) {
  for (out in available_outcomes) {
    bl <- baseline_map[[out]]
    res <- run_ancova(dat_cc_base, outcome = out, baseline = bl, moderator = G)
    if (is.null(res)) {
      next
    }

    save_model_tbl(res$coef, paste0("fit_ancova_", out, "_", G, "_coefficients"))
    save_model_tbl(res$emmeans, paste0("emmeans_", out, "_", G))
    save_model_tbl(res$contrast, paste0("emmeans_contrast_", out, "_", G))
  }
}

txt_path <- file.path(outputs_dir, paste0(script_label, "_summary.txt"))
writeLines(
  c(
    "K08_MAIN Balance/Walk Moderators Delta ANCOVA summary",
    paste0("N base complete-case: ", nrow(dat_cc_base)),
    paste0("Outcomes modeled: ", paste(available_outcomes, collapse = ", ")),
    "Moderators: Balance_problem, Walk500m_G_final",
    "Models: Delta_outcome ~ FOF_status * moderator + baseline + age + sex + BMI",
    "Note: FTSST delta is baseline − follow-up (improvement = positive).",
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
