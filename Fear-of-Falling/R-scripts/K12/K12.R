#!/usr/bin/env Rscript
# ==============================================================================
# K12 - FOF effects across individual physical performance tests
# File tag: K12.R
# Purpose: Tests whether FOF has stronger associations with specific physical
#          performance battery (PBT) components (HGS, MWS, FTSST, SLS) compared
#          to the overall composite physical function score
#
# ==============================================================================
#
# Activate renv environment if not already loaded
if (Sys.getenv("RENV_PROJECT") == "") source(here::here("renv/activate.R"))

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(ggplot2)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K12.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K12"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
if (is.na(script_label) || script_label == "") script_label <- "K12"

# Source helper functions (io, checks, modeling, reporting)
rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"),
   envir = .GlobalEnv)

source(here("R","functions","io.R"))
source(here("R","functions","checks.R"))
source(here("R","functions","modeling.R"))
source(here("R","functions","reporting.R"))

# init_paths() must set outputs_dir + manifest_path (+ options fof.*)
paths <- init_paths(script_label)

# seed: N/A (no randomness in this script)

# ==============================================================================
# 01. Load Dataset & Data Checking
# ==============================================================================

file_path <- here::here("data", "external", "KaatumisenPelko.csv")
raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

## Working copy so the original stays untouched
if (!exists("raw_data")) {
  stop("Object 'raw_data' not found. Please load your data as raw_data first.")
}

# --- Required raw columns check (DO NOT INVENT) ------------------------------
# Core variables (always required)
req_raw_cols_core <- c(
  "id", "age", "sex", "BMI", "kaatumisenpelkoOn",
  "ToimintaKykySummary0", "ToimintaKykySummary2",
  "MOIindeksiindeksi", "diabetes", "alzheimer", "parkinson",
  "AVH", "kaatuminen", "mieliala"
)

# PBT baseline+follow-up (check at least one PBT source exists)
# Flexible: accepts either baseline+follow-up OR pre-computed change columns
req_raw_cols_pbt <- c(
  "Puristus0", "Puristus2",
  "kavelynopeus_m_sek0", "kavelynopeus_m_sek2",
  "Tuoli0", "Tuoli2",
  "Seisominen0", "Seisominen2"
)

# Check core columns (mandatory)
missing_core_cols <- setdiff(req_raw_cols_core, names(raw_data))
if (length(missing_core_cols) > 0) {
  stop("Missing required core raw columns: ", paste(missing_core_cols, collapse = ", "))
}

# Check PBT columns (at least some baseline+follow-up pairs must exist)
# The code handles missing PBT gracefully via case_when(), but warn if ALL missing
missing_pbt_cols <- setdiff(req_raw_cols_pbt, names(raw_data))
if (length(missing_pbt_cols) == length(req_raw_cols_pbt)) {
  warning("All PBT baseline+follow-up columns missing. Derived Delta_* will be NA.")
}

# --- Standardize variable names and run sanity checks -----------------------
df <- standardize_analysis_vars(raw_data)
qc <- sanity_checks(df)
print(qc)

# --- Required analysis columns check -----------------------------------------
# Core analysis columns (after standardize_analysis_vars)
req_analysis_cols_core <- c(
  "id", "Age", "Sex", "BMI", "FOF_status",
  "Composite_Z0", "Composite_Z2", "Delta_Composite_Z",
  "MOIindeksiindeksi", "diabetes", "alzheimer", "parkinson",
  "AVH", "kaatuminen", "mieliala"
)

missing_analysis_cols <- setdiff(req_analysis_cols_core, names(df))
if (length(missing_analysis_cols) > 0) {
  stop("Missing required analysis columns: ", paste(missing_analysis_cols, collapse = ", "))
}

# Get paths from init_paths (already called in header)
outputs_dir   <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

# ==============================================================================
# 02. Prepare Analysis Dataset
# ==============================================================================

# Lisätään tarvittavat kovariaatit
analysis_data_rec <- df %>%
  mutate(
    # Ikäluokat
    AgeClass = case_when(
      Age < 65                 ~ "65_74",
      Age >= 65 & Age <= 74    ~ "65_74",
      Age >= 75 & Age <= 84    ~ "75_84",
      Age >= 85                ~ "85plus",
      TRUE                     ~ NA_character_
    ),
    AgeClass = factor(AgeClass, levels = c("65_74", "75_84", "85plus"), ordered = TRUE),

    # Neuro
    Neuro_any_num = if_else(
      (alzheimer == 1 | parkinson == 1 | AVH == 1),
      1L, 0L,
      missing = 0L
    ),
    Neuro_any = factor(
      Neuro_any_num,
      levels = c(0, 1),
      labels = c("no_neuro", "neuro")
    )
  )

# ==============================================================================
# 03. PBT Changes (HGS, MWS, FTSST, SLS)
# ==============================================================================

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    # HGS: positiivinen = parannus
    Delta_HGS = case_when(
      "PuristusMuutos" %in% names(analysis_data_rec) ~ PuristusMuutos,
      "Puristus0" %in% names(analysis_data_rec) & "Puristus2" %in% names(analysis_data_rec) ~
        Puristus2 - Puristus0,
      TRUE ~ NA_real_
    ),

    # MWS: positiivinen = parannus
    Delta_MWS = case_when(
      "Kävelymuutos" %in% names(analysis_data_rec) ~ Kävelymuutos,
      "kavelynopeus_m_sek0" %in% names(analysis_data_rec) & "kavelynopeus_m_sek2" %in% names(analysis_data_rec) ~
        kavelynopeus_m_sek2 - kavelynopeus_m_sek0,
      TRUE ~ NA_real_
    ),

    # FTSST (Tuoli): pienempi aika = parempi -> muutoksen merkki käännetään
    Delta_FTSST = case_when(
      "Tuolimuutos" %in% names(.) & !is.na(Tuolimuutos) ~ Tuolimuutos * (-1),
      "Tuoli0" %in% names(.) & "Tuoli2" %in% names(.) & !is.na(Tuoli0) & !is.na(Tuoli2) ~
        (Tuoli0 - Tuoli2),  # positiivinen = nopeampi testi
      TRUE ~ NA_real_
    ),

    # SLS (Seisominen): suurempi aika = parempi
    Delta_SLS = case_when(
      "TasapainoMuutos" %in% names(analysis_data_rec) ~ TasapainoMuutos,
      "Seisominen0" %in% names(analysis_data_rec) & "Seisominen2" %in% names(analysis_data_rec) ~
        Seisominen2 - Seisominen0,
      TRUE ~ NA_real_
    ),

    # MOI-score lisätään
    MOI_score = MOIindeksiindeksi
  )

# ==============================================================================
# 04. Build Analysis Datasets per Outcome
# ==============================================================================

# 4.1 Helper function: build analysis dataset for given outcome + baseline

build_dat_outcome <- function(data,
                              outcome,
                              baseline_var) {
  data %>%
    dplyr::select(
      id,
      dplyr::all_of(c(outcome, baseline_var)),
      Age,
      BMI,
      Sex_f,
      FOF_status_f,
      MOI_score,
      diabetes,
      alzheimer,
      parkinson,
      AVH,
      previous_falls = kaatuminen,
      psych_score    = mieliala
    ) %>%
    # complete-case: outcome + baseline + keskeiset kovariaatit
    dplyr::filter(
      !is.na(.data[[outcome]]),
      !is.na(.data[[baseline_var]]),
      !is.na(Age),
      !is.na(BMI),
      !is.na(Sex_f),
      !is.na(FOF_status_f)
    ) %>%
    dplyr::mutate(
      FOF_status_f = stats::relevel(FOF_status_f, ref = "Ei FOF"),
      sex = Sex_f
    )
}

# 4.2 Build datasets for each outcome
dat_comp <- build_dat_outcome(
  analysis_data_rec,
  outcome      = "Delta_Composite_Z",
  baseline_var = "Composite_Z0"
)

# HGS (puristusvoima)
dat_hgs <- build_dat_outcome(
  analysis_data_rec,
  outcome      = "Delta_HGS",
  baseline_var = "Puristus0"
)

# MWS (maksimi kävelynopeus)
dat_mws <- build_dat_outcome(
  analysis_data_rec,
  outcome      = "Delta_MWS",
  baseline_var = "kavelynopeus_m_sek0"
)

# FTSST (tuolista ylösnousu; positiivinen = nopeampi)
dat_fts <- build_dat_outcome(
  analysis_data_rec,
  outcome      = "Delta_FTSST",
  baseline_var = "Tuoli0"
)

# SLS (yhdellä jalalla seisominen)
dat_sls <- build_dat_outcome(
  analysis_data_rec,
  outcome      = "Delta_SLS",
  baseline_var = "Seisominen0"
)

# Lyhyt tarkistus, että kaikki datat näyttävät järkeviltä
purrr::map(
  list(
    Composite = dat_comp,
    HGS       = dat_hgs,
    MWS       = dat_mws,
    FTSST     = dat_fts,
    SLS       = dat_sls
  ),
  ~ summary(.x[[2]])  # 2. sarake = outcome
)

# ==============================================================================
# 05. Fit Models per Outcome
# ==============================================================================

# 5.1 Helper function: fit base and extended models
fit_models_for_outcome <- function(dat,
                                   outcome,
                                   baseline_var,
                                   outcome_label) {

  # Base-malli: FOF + baseline + Age + BMI + sex
  form_base <- stats::as.formula(
    paste0(
      outcome,
      " ~ FOF_status_f + ",
      baseline_var,
      " + Age + BMI + sex"
    )
  )

  # Extended-malli: lisätään kliiniset kovariaatit (kuten K11)
  form_ext <- stats::as.formula(
    paste0(
      outcome,
      " ~ FOF_status_f + ",
      baseline_var,
      " + Age + BMI + sex",
      " + MOI_score + diabetes + alzheimer + parkinson + AVH",
      " + previous_falls + psych_score"
    )
  )
  
  mod_base <- stats::lm(form_base, data = dat)
  mod_ext  <- stats::lm(form_ext,  data = dat)
  
  # tidy-taulukot + tunnisteet
  tab_base <- broom::tidy(mod_base, conf.int = TRUE) %>%
    dplyr::mutate(
      model   = "base",
      outcome = outcome_label
    )
  
  tab_ext <- broom::tidy(mod_ext, conf.int = TRUE) %>%
    dplyr::mutate(
      model   = "extended",
      outcome = outcome_label
    )
  
  # FOF-rivit
  fof_base <- tab_base %>%
    dplyr::filter(grepl("^FOF_status", term)) %>%
    dplyr::mutate(
      model   = "base",
      outcome = outcome_label
    )
  
  fof_ext <- tab_ext %>%
    dplyr::filter(grepl("^FOF_status", term)) %>%
    dplyr::mutate(
      model   = "extended",
      outcome = outcome_label
    )
  
  # Standardoidut kertoimet extended-mallille (vain FOF-rivi)
  # Käytetään method = "posthoc", joka EI refittaa mallia
  tab_std_ext <- tryCatch(
    {
      effectsize::standardize_parameters(
        mod_ext,
        method = "posthoc"  # ei refittiä -> vältetään aiempi virhe
      ) %>%
        as.data.frame() %>%
        # Filtteröidään FOF-status -parametri
        dplyr::filter(grepl("^FOF_status", .data$Parameter)) %>%
        dplyr::mutate(
          model   = "extended",
          outcome = outcome_label
        )
    },
    error = function(e) {
      message("Standardized parameters failed for outcome = ", outcome_label,
              ". Returning NA row for std_ext_fof.")
      tibble::tibble(
        Parameter       = "FOF_statusFOF",
        Std_Coefficient = NA_real_,
        CI_low          = NA_real_,
        CI_high         = NA_real_,
        model           = "extended",
        outcome         = outcome_label
      )
    }
  )
  
  list(
    mod_base    = mod_base,
    mod_ext     = mod_ext,
    tidy_base   = tab_base,
    tidy_ext    = tab_ext,
    fof_base    = fof_base,
    fof_ext     = fof_ext,
    std_ext_fof = tab_std_ext
  )
}


# Sovitetaan mallit kaikille outcomeille ------------------------

res_comp <- fit_models_for_outcome(
  dat_comp,
  outcome       = "Delta_Composite_Z",
  baseline_var  = "Composite_Z0",
  outcome_label = "Composite"
)

res_hgs <- fit_models_for_outcome(
  dat_hgs,
  outcome       = "Delta_HGS",
  baseline_var  = "Puristus0",
  outcome_label = "HGS"
)

res_mws <- fit_models_for_outcome(
  dat_mws,
  outcome       = "Delta_MWS",
  baseline_var  = "kavelynopeus_m_sek0",
  outcome_label = "MWS"
)

res_fts <- fit_models_for_outcome(
  dat_fts,
  outcome       = "Delta_FTSST",
  baseline_var  = "Tuoli0",
  outcome_label = "FTSST"
)

res_sls <- fit_models_for_outcome(
  dat_sls,
  outcome       = "Delta_SLS",
  baseline_var  = "Seisominen0",
  outcome_label = "SLS"
)

# ==============================================================================
# 06. Save Tables
# ==============================================================================

# Kaikki mallikertoimet samassa taulukossa
lm_all_outcomes <- dplyr::bind_rows(
  res_comp$tidy_base, res_comp$tidy_ext,
  res_hgs$tidy_base,  res_hgs$tidy_ext,
  res_mws$tidy_base,  res_mws$tidy_ext,
  res_fts$tidy_base,  res_fts$tidy_ext,
  res_sls$tidy_base,  res_sls$tidy_ext
)

csv_path <- file.path(outputs_dir, "lm_models_all_outcomes.csv")
save_table_csv(lm_all_outcomes, csv_path)
append_manifest(
  manifest_row(script = script_label, label = "lm_models_all_outcomes",
               path = csv_path, kind = "table_csv", n = nrow(lm_all_outcomes)),
  manifest_path
)

# FOF_status-rivien kooste
fof_effects <- dplyr::bind_rows(
  res_comp$fof_base, res_comp$fof_ext,
  res_hgs$fof_base,  res_hgs$fof_ext,
  res_mws$fof_base,  res_mws$fof_ext,
  res_fts$fof_base,  res_fts$fof_ext,
  res_sls$fof_base,  res_sls$fof_ext
) %>%
  dplyr::select(
    outcome,
    model,
    term,
    estimate,
    std.error,
    statistic,
    p.value,
    conf.low,
    conf.high
  ) %>%
  dplyr::mutate(
    outcome = factor(
      outcome,
      levels = c("Composite", "HGS", "MWS", "FTSST", "SLS")
    ),
    model = factor(model, levels = c("base", "extended"))
  ) %>%
  dplyr::arrange(outcome, model)

csv_path <- file.path(outputs_dir, "FOF_effects_by_outcome.csv")
save_table_csv(fof_effects, csv_path)
append_manifest(
  manifest_row(script = script_label, label = "FOF_effects_by_outcome",
               path = csv_path, kind = "table_csv", n = nrow(fof_effects)),
  manifest_path
)

# Standardoidut FOF-kertoimet (extended-mallit)
fof_std_extended <- dplyr::bind_rows(
  res_comp$std_ext_fof,
  res_hgs$std_ext_fof,
  res_mws$std_ext_fof,
  res_fts$std_ext_fof,
  res_sls$std_ext_fof
)

csv_path <- file.path(outputs_dir, "FOF_effects_standardized_extended.csv")
save_table_csv(fof_std_extended, csv_path)
append_manifest(
  manifest_row(script = script_label, label = "FOF_effects_standardized_extended",
               path = csv_path, kind = "table_csv", n = nrow(fof_std_extended)),
  manifest_path
)

# ==============================================================================
# 07. Save Figures
# ==============================================================================

fof_plot_data <- fof_effects %>%
  dplyr::mutate(
    outcome = forcats::fct_rev(outcome)  # piirteen järjestys y-akselilla
  )

p_fof <- ggplot(fof_plot_data,
                aes(x = estimate,
                    y = outcome,
                    xmin = conf.low,
                    xmax = conf.high,
                    color = model)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_pointrange(position = position_dodge(width = 0.5)) +
  scale_x_continuous(name = "FOF_status (FOF vs nonFOF), kerroin (muutosyksikköä)") +
  ylab("Outcome") +
  theme_minimal()

plot_path <- file.path(outputs_dir, "FOF_effects_by_outcome_forest.png")
ggplot2::ggsave(filename = plot_path, plot = p_fof,
                width = 7, height = 4, dpi = 300)

# End of K12.R

save_sessioninfo_manifest()

