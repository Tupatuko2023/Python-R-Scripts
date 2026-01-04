#!/usr/bin/env Rscript
# ==============================================================================
# K12_MAIN - FOF effects across individual physical performance tests
# File tag: K12_MAIN.V1_pbt-outcomes-fof-effects.R
# Purpose: Compare FOF associations across PBT components vs composite outcome
#
# Outcomes: Delta_Composite_Z, Delta_HGS, Delta_MWS, Delta_FTSST, Delta_SLS
# Predictors: FOF_status_f
# Moderator/interaction: None (main effects)
# Grouping variable: None (wide format ANCOVA)
# Covariates (base): Age, BMI, Sex_f, baseline measure
# Covariates (extended): MOI_score, diabetes, alzheimer, parkinson, AVH,
#                        previous_falls, psych_score
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, age, sex, BMI, kaatumisenpelkoOn, ToimintaKykySummary0, ToimintaKykySummary2,
# MOIindeksiindeksi, diabetes, alzheimer, parkinson, AVH, kaatuminen, mieliala
#
# PBT columns (optional; used if present):
# Puristus0/2, kavelynopeus_m_sek0/2, Tuoli0/2, Seisominen0/2
#
# Mapping example (raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn -> FOF_status -> FOF_status_f ("Ei FOF"/"FOF")
# ToimintaKykySummary0 -> Composite_Z0
# ToimintaKykySummary2 -> Composite_Z2
# Delta_Composite_Z = Composite_Z2 - Composite_Z0
# PBT deltas computed from baseline+follow-up if available
# MOIindeksiindeksi -> MOI_score; kaatuminen -> previous_falls; mieliala -> psych_score
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K12_MAIN (canonical)
# - outputs dir: R-scripts/K12_MAIN/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Check required raw columns (req_raw_cols)
# 04) Standardize vars + QC (standardize_analysis_vars + sanity_checks)
# 05) Prepare analysis datasets per outcome
# 06) Fit base and extended models per outcome
# 07) Save tables + forest plot
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
  library(ggplot2)
  library(effectsize)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K12_MAIN.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K12_MAIN"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K12_MAIN"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K12 FOF effects across PBT outcomes\n")
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
req_raw_cols_core <- c(
  "id", "age", "sex", "BMI", "kaatumisenpelkoOn",
  "ToimintaKykySummary0", "ToimintaKykySummary2",
  "MOIindeksiindeksi", "diabetes", "alzheimer", "parkinson",
  "AVH", "kaatuminen", "mieliala"
)

missing_core_cols <- setdiff(req_raw_cols_core, names(raw_data))
if (length(missing_core_cols) > 0) {
  stop("Missing required core raw columns: ", paste(missing_core_cols, collapse = ", "))
}

req_raw_cols_pbt <- c(
  "Puristus0", "Puristus2",
  "kavelynopeus_m_sek0", "kavelynopeus_m_sek2",
  "Tuoli0", "Tuoli2",
  "Seisominen0", "Seisominen2"
)
missing_pbt_cols <- setdiff(req_raw_cols_pbt, names(raw_data))
if (length(missing_pbt_cols) == length(req_raw_cols_pbt)) {
  warning("All PBT baseline+follow-up columns missing. Derived Delta_* will be NA.")
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

# --- Build analysis dataset --------------------------------------------------
pbt_cols <- c(
  "Puristus0", "Puristus2",
  "kavelynopeus_m_sek0", "kavelynopeus_m_sek2",
  "Tuoli0", "Tuoli2",
  "Seisominen0", "Seisominen2",
  "PuristusMuutos", "Kävelymuutos", "Tuolimuutos", "TasapainoMuutos"
)

analysis_data_rec <- df %>%
  select(id, Age, Sex, BMI, FOF_status, FOF_status_f, Sex_f,
         Composite_Z0, Composite_Z2, Delta_Composite_Z,
         MOIindeksiindeksi, diabetes, alzheimer, parkinson, AVH, kaatuminen, mieliala) %>%
  left_join(raw_data %>% select(any_of(c("id", pbt_cols))), by = "id") %>%
  mutate(
    Delta_HGS = case_when(
      "PuristusMuutos" %in% names(.) ~ PuristusMuutos,
      "Puristus0" %in% names(.) & "Puristus2" %in% names(.) ~ Puristus2 - Puristus0,
      TRUE ~ NA_real_
    ),
    Delta_MWS = case_when(
      "Kävelymuutos" %in% names(.) ~ Kävelymuutos,
      "kavelynopeus_m_sek0" %in% names(.) & "kavelynopeus_m_sek2" %in% names(.) ~
        kavelynopeus_m_sek2 - kavelynopeus_m_sek0,
      TRUE ~ NA_real_
    ),
    Delta_FTSST = case_when(
      "Tuolimuutos" %in% names(.) & !is.na(Tuolimuutos) ~ Tuolimuutos * (-1),
      "Tuoli0" %in% names(.) & "Tuoli2" %in% names(.) & !is.na(Tuoli0) & !is.na(Tuoli2) ~
        Tuoli0 - Tuoli2,
      TRUE ~ NA_real_
    ),
    Delta_SLS = case_when(
      "TasapainoMuutos" %in% names(.) ~ TasapainoMuutos,
      "Seisominen0" %in% names(.) & "Seisominen2" %in% names(.) ~ Seisominen2 - Seisominen0,
      TRUE ~ NA_real_
    ),
    MOI_score = as.numeric(MOIindeksiindeksi),
    previous_falls = as.numeric(kaatuminen),
    psych_score = as.numeric(mieliala)
  )

build_dat_outcome <- function(data, outcome, baseline_var) {
  if (!outcome %in% names(data) || !baseline_var %in% names(data)) {
    warning("Skipping outcome ", outcome, ": missing outcome/baseline columns.")
    return(NULL)
  }

dat <- data %>%
    select(
      id,
      all_of(c(outcome, baseline_var)),
      Age,
      BMI,
      Sex_f,
      FOF_status_f,
      MOI_score,
      diabetes,
      alzheimer,
      parkinson,
      AVH,
      previous_falls,
      psych_score
    ) %>%
    filter(
      !is.na(.data[[outcome]]),
      !is.na(.data[[baseline_var]]),
      !is.na(Age),
      !is.na(BMI),
      !is.na(Sex_f),
      !is.na(FOF_status_f)
    ) %>%
    mutate(FOF_status_f = stats::relevel(FOF_status_f, ref = "Ei FOF"))

  if (!nrow(dat)) {
    warning("Skipping outcome ", outcome, ": no complete-case rows.")
    return(NULL)
  }
  dat
}

fit_models_for_outcome <- function(dat, outcome, baseline_var, outcome_label) {
  if (is.null(dat)) return(NULL)

  form_base <- stats::as.formula(
    paste0(outcome, " ~ FOF_status_f + ", baseline_var, " + Age + BMI + Sex_f")
  )
  form_ext <- stats::as.formula(
    paste0(
      outcome, " ~ FOF_status_f + ", baseline_var, " + Age + BMI + Sex_f",
      " + MOI_score + diabetes + alzheimer + parkinson + AVH",
      " + previous_falls + psych_score"
    )
  )

  mod_base <- stats::lm(form_base, data = dat)
  mod_ext <- stats::lm(form_ext, data = dat)

  tab_base <- broom::tidy(mod_base, conf.int = TRUE) %>%
    mutate(model = "base", outcome = outcome_label)
  tab_ext <- broom::tidy(mod_ext, conf.int = TRUE) %>%
    mutate(model = "extended", outcome = outcome_label)

  fof_base <- tab_base %>% filter(grepl("^FOF_status", term))
  fof_ext <- tab_ext %>% filter(grepl("^FOF_status", term))

  tab_std_ext <- tryCatch(
    {
      effectsize::standardize_parameters(mod_ext, method = "posthoc") %>%
        as.data.frame() %>%
        filter(grepl("^FOF_status", .data$Parameter)) %>%
        mutate(model = "extended", outcome = outcome_label)
    },
    error = function(e) {
      tibble::tibble(
        Parameter = "FOF_status_fFOF",
        Std_Coefficient = NA_real_,
        CI_low = NA_real_,
        CI_high = NA_real_,
        model = "extended",
        outcome = outcome_label
      )
    }
  )

  list(
    tidy_base = tab_base,
    tidy_ext = tab_ext,
    fof_base = fof_base,
    fof_ext = fof_ext,
    std_ext_fof = tab_std_ext
  )
}

specs <- list(
  Composite = list(outcome = "Delta_Composite_Z", baseline = "Composite_Z0"),
  HGS = list(outcome = "Delta_HGS", baseline = "Puristus0"),
  MWS = list(outcome = "Delta_MWS", baseline = "kavelynopeus_m_sek0"),
  FTSST = list(outcome = "Delta_FTSST", baseline = "Tuoli0"),
  SLS = list(outcome = "Delta_SLS", baseline = "Seisominen0")
)

datasets <- lapply(names(specs), function(name) {
  build_dat_outcome(analysis_data_rec, specs[[name]]$outcome, specs[[name]]$baseline)
})
names(datasets) <- names(specs)

results <- lapply(names(specs), function(name) {
  fit_models_for_outcome(
    datasets[[name]],
    outcome = specs[[name]]$outcome,
    baseline_var = specs[[name]]$baseline,
    outcome_label = name
  )
})
names(results) <- names(specs)

results <- Filter(Negate(is.null), results)

if (length(results) == 0) {
  stop("No outcomes available for K12 models.")
}

lm_all_outcomes <- do.call(
  rbind,
  lapply(results, function(r) rbind(r$tidy_base, r$tidy_ext))
)
csv_path <- file.path(outputs_dir, "lm_models_all_outcomes.csv")
save_table_csv(lm_all_outcomes, csv_path)
append_manifest(
  manifest_row(script = script_label, label = "lm_models_all_outcomes",
               path = get_relpath(csv_path), kind = "table_csv", n = nrow(lm_all_outcomes)),
  manifest_path
)

fof_effects <- do.call(
  rbind,
  lapply(results, function(r) rbind(r$fof_base, r$fof_ext))
)
csv_path <- file.path(outputs_dir, "FOF_effects_by_outcome.csv")
save_table_csv(fof_effects, csv_path)
append_manifest(
  manifest_row(script = script_label, label = "FOF_effects_by_outcome",
               path = get_relpath(csv_path), kind = "table_csv", n = nrow(fof_effects)),
  manifest_path
)

fof_std_extended <- do.call(
  rbind,
  lapply(results, function(r) r$std_ext_fof)
)
csv_path <- file.path(outputs_dir, "FOF_effects_standardized_extended.csv")
save_table_csv(fof_std_extended, csv_path)
append_manifest(
  manifest_row(script = script_label, label = "FOF_effects_standardized_extended",
               path = get_relpath(csv_path), kind = "table_csv", n = nrow(fof_std_extended)),
  manifest_path
)

if (nrow(fof_effects) > 0) {
  fof_plot_data <- fof_effects %>%
    mutate(
      outcome = factor(outcome, levels = c("Composite", "HGS", "MWS", "FTSST", "SLS"))
    )

  p_fof <- ggplot(fof_plot_data,
                  aes(x = estimate, y = outcome, xmin = conf.low, xmax = conf.high, color = model)) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_pointrange(position = position_dodge(width = 0.5)) +
    scale_x_continuous(name = "FOF_status (FOF vs nonFOF), coefficient") +
    ylab("Outcome") +
    theme_minimal()

  plot_path <- file.path(outputs_dir, "FOF_effects_by_outcome_forest.png")
  ggplot2::ggsave(filename = plot_path, plot = p_fof, width = 7, height = 4, dpi = 300)
  append_manifest(
    manifest_row(script = script_label, label = "FOF_effects_by_outcome_forest",
                 path = get_relpath(plot_path), kind = "figure_png", n = NA_integer_),
    manifest_path
  )
}

txt_path <- file.path(outputs_dir, paste0(script_label, "_summary.txt"))
writeLines(
  c(
    "K12_MAIN FOF effects across PBT outcomes",
    paste0("Outcomes modeled: ", paste(names(results), collapse = ", ")),
    "Base model: outcome ~ FOF_status + baseline + Age + BMI + Sex",
    "Extended model adds MOI_score, diabetes, alzheimer, parkinson, AVH, previous_falls, psych_score",
    "See CSV outputs for coefficients and forest plot."
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
