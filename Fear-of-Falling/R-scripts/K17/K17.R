#!/usr/bin/env Rscript
# ==============================================================================
# K17 - Baseline characteristics by FOF status (Table 1) + Frailty
# File tag: K17.R
# Purpose: Reproduces K14.R's Table 1 IDENTICALLY (same table-framework, same
#          packages, same muotoilu, same output/manifest) and adds frailty_cat_3
#          (robust/pre-frail/frail) derived from K15.R logic, FOF-stratified
#
# Outcome: None (descriptive table only, no modeling)
# Predictors: FOF_status (factor: "nonFOF"/"FOF", grouping variable for table)
# Moderator/interaction: None
# Grouping variable: FOF_status (table stratification)
# Covariates: N/A (all variables presented as descriptives)
#
# Required vars (raw_data - DO NOT INVENT; must match req_raw_cols check):
# kaatumisenpelkoOn, age, sex, BMI, diabetes, alzheimer, parkinson, AVH,
# koettuterveydentila (or SRH), MOIindeksiindeksi, tupakointi, alkoholi,
# oma_arvio_liikuntakyky, vaikeus_liikkua_500m (or Vaikeus500m), tasapainovaikeus,
# kaatuminen, murtumia, PainVAS0, ToimintaKykySummary0,
# Puristus0, kavelynopeus_m_sek0, maxkävelymatka, vaikeus_liikkua_2km
# (K15 frailty components)
#
# Required vars (analysis df - after recoding in script):
# FOF_status (factor: "nonFOF"/"FOF"), age, sex_factor, BMI, diabetes, alzheimer_dementia,
# parkinson, AVH, SRH_3class, MOI, smoking, alcohol_3class, SRM_3class,
# walk500m_3class, balance_diff, fallen, fractures, PainVAS0, Composite_Z0,
# frailty_cat_3 (factor: "robust"/"pre-frail"/"frail")
#
# Mapping (raw -> analysis; keep minimal + explicit):
# [Same as K14.R PLUS:]
# Frailty components (K15.R logic):
#   - frailty_weakness: from Puristus0 (sex-specific Q1)
#   - frailty_slowness: from kavelynopeus_m_sek0 (< 0.8 m/s)
#   - frailty_low_activity: from oma_arvio_liikuntakyky, Vaikeus500m, vaikeus_liikkua_2km, maxkävelymatka
# frailty_count_3 = weakness + slowness + low_activity
# frailty_cat_3: 0 -> "robust", 1 -> "pre-frail", >=2 -> "frail"
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (set for reproducibility, though no randomness in table generation)
#
# Outputs + manifest:
# - script_label: K17 (canonical)
# - outputs dir: R-scripts/K17/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits)
# 03) Check required raw columns (req_raw_cols)
# 04) Standardize vars + QC (standardize_analysis_vars + sanity_checks)
# 05) Recode categorical variables for table (FOF_status, sex, SRH, SRM, etc. - K14 logic)
# 06) Derive frailty components (K15 logic - minimal safe block)
# 07) Compute frailty_cat_3 (K15 categorization)
# 08) SANITY CHECK: frailty totals (42/126/82 expected) + cross-tab frailty x FOF
# 09) Build Table 1 with K14 framework + frailty_cat_3
# 10) Save Table 1 as CSV + HTML (K14 pattern)
# 11) Append manifest row per artifact
# 12) Save sessionInfo to manifest/
# 13) EOF marker
# ==============================================================================
#
# DOCUMENTATION OF K14.R INSPECTION (per plan requirements):
# - Input dataset: data/external/KaatumisenPelko.csv (raw_data, used directly)
# - FOF variable: kaatumisenpelkoOn (0/1) -> FOF_status factor(levels=c(0,1), labels=c("nonFOF","FOF"))
# - K14 filters: None explicit; Table 1 uses all rows with !is.na(FOF_status)
# - K14 table framework: Custom R functions (format_mean_sd, format_n_pct, make_binary_row,
#   make_multicat_rows, make_multicat_rows_with_level_p) - NO external table packages
# - K14 packages: here, dplyr (+ readr/tibble from helper functions)
# - K14 output formats: CSV + HTML via save_table_csv_html(tbl, label)
# - K14 output paths: R-scripts/K14/outputs/K14_baseline_by_FOF.{csv,html}
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K17.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K17"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
if (is.na(script_label) || script_label == "") script_label <- "K17"

# Source helper functions (io, checks, modeling, reporting)
rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"),
   envir = .GlobalEnv)

source(here("R","functions","io.R"))
source(here("R","functions","checks.R"))
source(here("R","functions","modeling.R"))
source(here("R","functions","reporting.R"))

# init_paths() must set outputs_dir + manifest_path (+ options fof.*)
paths <- init_paths(script_label)

# seed (set for reproducibility, though no randomness in table generation)
set.seed(20251124)

# ==============================================================================
# 01. Load Dataset & Data Checking
# ==============================================================================

file_path <- here::here("data", "external", "KaatumisenPelko.csv")
if (!file.exists(file_path)) {
  stop("Tiedostoa data/external/KaatumisenPelko.csv ei löydy.")
}

raw_data <- readr::read_csv(file_path, show_col_types = FALSE)

## Standardize variable names and run sanity checks
df <- standardize_analysis_vars(raw_data)
qc <- sanity_checks(df)
print(qc)

# K17 käyttää raakaa dataa (ei standardisoitua), kuten K14
analysis_data <- raw_data

# Get paths from init_paths (already called in header)
outputs_dir   <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

# ==============================================================================
# 02. Recodings: FOF-Status + Muut Table 1 -Muuttujat (K14 LOGIC)
# ==============================================================================

analysis_data_rec <- analysis_data %>%
  mutate(
    # FOF-status: sama määrittely kuin K14
    FOF_status = factor(
      kaatumisenpelkoOn,
      levels = c(0, 1),
      labels = c("nonFOF", "FOF")
    ),

    # Sukupuoli: 0 = female, 1 = male
    sex_factor = factor(
      sex,
      levels = c(0, 1),
      labels = c("female", "male")
    ),
    woman = case_when(
      sex_factor == "female" ~ 1L,
      sex_factor == "male"   ~ 0L,
      TRUE                   ~ NA_integer_
    ),

    # Self-rated Health (3-luokkainen taulukkoa varten, Good/Moderate/Bad)
    SRH_3class_table = factor(
      koettuterveydentila,
      levels = c(2, 1, 0),
      labels = c("Good", "Moderate", "Bad"),
      ordered = TRUE
    ),

    # Self-Rated Mobility (oma_arvio_liikuntakyky 0–2 -> Good/Moderate/Weak)
    SRM_3class_table = factor(
      oma_arvio_liikuntakyky,
      levels = c(2, 1, 0),
      labels = c("Good", "Moderate", "Weak"),
      ordered = TRUE
    ),

    # Walking 500 m: 0 = No difficulties, 1 = Difficulties, 2 = Cannot
    Walk500m_3class_table = factor(
      vaikeus_liikkua_500m,
      levels = c(0, 1, 2),
      labels = c("No", "Difficulties", "Cannot"),
      ordered = TRUE
    ),

    # Alkoholinkäyttö: oletus 0 = No, 1 = Moderate, 2 = Large
    alcohol_3class_table = factor(
      alkoholi,
      levels = c(0, 1, 2),
      labels = c("No", "Moderate", "Large"),
      ordered = TRUE
    )
  )

# Comorbidity computation (K14 logic)
analysis_data_rec <- analysis_data_rec %>%
  mutate(
    disease_count = rowSums(cbind(
      diabetes  == 1,
      alzheimer == 1,
      parkinson == 1,
      AVH       == 1
    ), na.rm = TRUE),
    disease_nonmiss = rowSums(cbind(
      !is.na(diabetes),
      !is.na(alzheimer),
      !is.na(parkinson),
      !is.na(AVH)
    ), na.rm = TRUE),
    comorbidity = dplyr::case_when(
      disease_nonmiss == 0 ~ NA_integer_,
      disease_count   > 1 ~ 1L,
      TRUE                 ~ 0L
    )
  )

# ==============================================================================
# 03. Derive Frailty Components and frailty_cat_3 (K15 LOGIC - MINIMAL BLOCK)
# ==============================================================================
# This block replicates K15.R frailty derivation logic for frailty_cat_3.
# Source: K15.R lines 155-469 (thresholds, components, categorization)
#
# Frailty thresholds (K15 defaults):
grip_cut_strategy <- "sex_Q1"
gait_cut_m_per_sec <- 0.8
low_BMI_threshold <- 21
maxwalk_low_cut_m <- 400

# 3.1 Weakness (frailty_weakness) - K15.R lines 175-273
# Uses Puristus0 (grip strength) with sex-specific Q1 cutoffs

if ("sex" %in% names(analysis_data_rec)) {
  if (is.factor(analysis_data_rec$sex_factor)) {
    # sex_factor already exists
  } else if (is.numeric(analysis_data_rec$sex)) {
    # Already created sex_factor above in K14 logic
  }
} else {
  warning("sex-muuttuja puuttuu: weakness-komponentti epäluotettava.")
  analysis_data_rec$sex_factor <- NA
}

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    Puristus0_clean = if_else(
      !is.na(Puristus0) & Puristus0 <= 0,
      NA_real_,
      Puristus0
    )
  )

grip_cuts <- NULL
if ("Puristus0" %in% names(analysis_data_rec)) {
  if (grip_cut_strategy == "sex_Q1") {
    grip_cuts <- analysis_data_rec %>%
      filter(!is.na(Puristus0_clean), !is.na(sex_factor)) %>%
      group_by(sex_factor) %>%
      summarise(
        cut_Q1 = quantile(Puristus0_clean, probs = 0.25, na.rm = TRUE),
        .groups = "drop"
      )
    message("K17: Weakness-rajat (sex_Q1):")
    print(grip_cuts)
  }

  grip_cut_vec <- NULL
  if (!is.null(grip_cuts)) {
    grip_cut_vec <- setNames(grip_cuts$cut_Q1, as.character(grip_cuts$sex_factor))
  }

  analysis_data_rec <- analysis_data_rec %>%
    mutate(
      frailty_weakness = case_when(
        is.null(grip_cut_vec) ~ NA_integer_,
        is.na(Puristus0_clean) | is.na(sex_factor) ~ NA_integer_,
        TRUE ~ if_else(
          Puristus0_clean < grip_cut_vec[as.character(sex_factor)],
          1L, 0L
        )
      )
    )
} else {
  analysis_data_rec <- analysis_data_rec %>%
    mutate(frailty_weakness = NA_integer_)
}

# 3.2 Slowness (frailty_slowness) - K15.R lines 276-297
if (!("kavelynopeus_m_sek0" %in% names(analysis_data_rec))) {
  warning("kavelynopeus_m_sek0 puuttuu: slowness-komponentti jää NA:ksi.")
  analysis_data_rec <- analysis_data_rec %>%
    mutate(frailty_slowness = NA_integer_)
} else {
  analysis_data_rec <- analysis_data_rec %>%
    mutate(
      frailty_slowness = case_when(
        is.na(kavelynopeus_m_sek0) ~ NA_integer_,
        kavelynopeus_m_sek0 == 0 ~ 1L,
        kavelynopeus_m_sek0 < gait_cut_m_per_sec ~ 1L,
        TRUE ~ 0L
      )
    )
}

# 3.3 Low Physical Activity (frailty_low_activity) - K15.R lines 300-405
var_500m <- NULL
if ("Vaikeus500m" %in% names(analysis_data_rec)) var_500m <- "Vaikeus500m"
if (is.null(var_500m) && "vaikeus_liikkua_500m" %in% names(analysis_data_rec)) var_500m <- "vaikeus_liikkua_500m"

has_oma <- "oma_arvio_liikuntakyky" %in% names(analysis_data_rec)
has_2km <- "vaikeus_liikkua_2km" %in% names(analysis_data_rec)
has_maxw <- "maxkävelymatka" %in% names(analysis_data_rec)

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    walking500_code = if (!is.null(var_500m)) .data[[var_500m]] else NA_integer_,
    walking2km_code = if (has_2km) vaikeus_liikkua_2km else NA_integer_,

    flag_weak_SR = if (has_oma) {
      case_when(
        is.na(oma_arvio_liikuntakyky) ~ NA,
        oma_arvio_liikuntakyky == 0   ~ TRUE,
        oma_arvio_liikuntakyky %in% c(1, 2) ~ FALSE,
        TRUE ~ NA
      )
    } else {
      NA
    },

    flag_500m_limit = case_when(
      is.na(walking500_code) ~ NA,
      walking500_code %in% c(1, 2) ~ TRUE,
      walking500_code == 0 ~ FALSE,
      TRUE ~ NA
    ),

    flag_2km_limit = case_when(
      is.na(walking2km_code) ~ NA,
      walking2km_code %in% c(1, 2) ~ TRUE,
      walking2km_code == 0 ~ FALSE,
      TRUE ~ NA
    ),

    flag_maxwalk_low = case_when(
      !has_maxw ~ NA,
      is.na(maxkävelymatka) ~ NA,
      maxkävelymatka < maxwalk_low_cut_m ~ TRUE,
      TRUE ~ FALSE
    ),

    any_low_activity_info = !is.na(flag_weak_SR) |
                            !is.na(flag_500m_limit) |
                            !is.na(flag_2km_limit) |
                            !is.na(flag_maxwalk_low),

    frailty_low_activity = case_when(
      !any_low_activity_info ~ NA_integer_,
      flag_weak_SR      %in% TRUE ~ 1L,
      flag_500m_limit   %in% TRUE ~ 1L,
      flag_2km_limit    %in% TRUE ~ 1L,
      flag_maxwalk_low  %in% TRUE ~ 1L,
      TRUE ~ 0L
    )
  )

# 3.4 Frailty count and categories - K15.R lines 432-469
analysis_data_rec <- analysis_data_rec %>%
  mutate(
    # 3-component proxy: weakness + slowness + low_activity
    frailty_count_3 = frailty_weakness +
      frailty_slowness +
      frailty_low_activity,

    frailty_cat_3 = case_when(
      is.na(frailty_count_3)       ~ NA_character_,
      frailty_count_3 == 0         ~ "robust",
      frailty_count_3 == 1         ~ "pre-frail",
      frailty_count_3 >= 2         ~ "frail"
    ),

    frailty_cat_3 = factor(
      frailty_cat_3,
      levels = c("robust", "pre-frail", "frail")
    )
  )

# ==============================================================================
# 04. SANITY CHECK: Frailty Totals + Cross-Tabulation
# ==============================================================================
# Expected frailty totals (from task spec): robust=42, pre-frail=126, frail=82
# This section validates frailty_cat_3 distribution in K14 Table 1 sample
# (i.e., after K14's FOF_status filter: !is.na(FOF_status))

message("\n=== K17 SANITY CHECK: Frailty Distribution ===")

# Sample used in K14 Table 1: all rows with valid FOF_status
table1_sample <- analysis_data_rec %>%
  filter(!is.na(FOF_status))

N_total <- nrow(table1_sample)
message("K17: Table 1 sample size (non-NA FOF_status): N = ", N_total)

# Frailty totals in Table 1 sample
frailty_totals <- table1_sample %>%
  count(frailty_cat_3) %>%
  mutate(percentage = round(100 * n / sum(n), 1))

message("\nK17: Frailty category totals in Table 1 sample:")
print(frailty_totals)

# Extract counts (ensure scalar)
n_robust_vec   <- frailty_totals$n[frailty_totals$frailty_cat_3 == "robust"]
n_prefrail_vec <- frailty_totals$n[frailty_totals$frailty_cat_3 == "pre-frail"]
n_frail_vec    <- frailty_totals$n[frailty_totals$frailty_cat_3 == "frail"]

# Handle NA (if any level is missing) - ensure scalar
n_robust   <- if (length(n_robust_vec) == 0) 0L else as.integer(n_robust_vec[1])
n_prefrail <- if (length(n_prefrail_vec) == 0) 0L else as.integer(n_prefrail_vec[1])
n_frail    <- if (length(n_frail_vec) == 0) 0L else as.integer(n_frail_vec[1])

# Expected totals
expected_robust <- 42L
expected_prefrail <- 126L
expected_frail <- 82L

# Check match
if (n_robust == expected_robust && n_prefrail == expected_prefrail && n_frail == expected_frail) {
  message("\n*** OK: frailty totals match expected (42/126/82) ***\n")
} else {
  message("\n*** WARNING: frailty totals DO NOT match expected ***")
  message("Expected: robust=42, pre-frail=126, frail=82")
  message("Observed: robust=", n_robust, ", pre-frail=", n_prefrail, ", frail=", n_frail)
  message("\nPossible reasons:")
  message("1. K14 complete-case filter (Table 1 uses !is.na(FOF_status) only)")
  message("2. Frailty components have missing values -> frailty_count_3 = NA")
  message("3. Different frailty derivation thresholds or logic")

  # Report missing frailty
  N_frailty_nonmissing <- sum(!is.na(table1_sample$frailty_cat_3))
  N_frailty_missing <- sum(is.na(table1_sample$frailty_cat_3))
  message("\nN_total (Table1 sample): ", N_total)
  message("N_frailty_nonmissing: ", N_frailty_nonmissing)
  message("N_frailty_missing: ", N_frailty_missing, "\n")
}

# Cross-tabulation: frailty_cat_3 x FOF_status (counts)
message("=== Cross-tabulation: frailty_cat_3 x FOF_status (counts) ===")
crosstab_frailty_FOF <- table(
  FOF = table1_sample$FOF_status,
  Frailty = table1_sample$frailty_cat_3,
  useNA = "ifany"
)
print(crosstab_frailty_FOF)
message("")

# ==============================================================================
# 05. FOF-ryhmäkoot (K14 LOGIC)
# ==============================================================================

if (!"FOF_status" %in% names(analysis_data_rec)) {
  stop("FOF_status puuttuu recodetusta datasta – tarkista kaatumisenpelkoOn-muuttuja.")
}

fof_counts <- analysis_data_rec %>%
  filter(!is.na(FOF_status)) %>%
  count(FOF_status)

if (nrow(fof_counts) != 2L) {
  warning("FOF_status-tasoja ei ole täsmälleen kaksi; taulukko voi olla epätäydellinen.")
}

fof_levels <- levels(analysis_data_rec$FOF_status)
group0_lvl <- fof_levels[1] # "nonFOF"
group1_lvl <- fof_levels[2] # "FOF"

N_group0 <- fof_counts$n[fof_counts$FOF_status == group0_lvl]
N_group1 <- fof_counts$n[fof_counts$FOF_status == group1_lvl]

# ==============================================================================
# 06. Apufunktiot: mean(SD), n(%), P-Arvot (K14 LOGIC - EXACT COPY)
# ==============================================================================

format_pvalue <- function(p) {
  if (is.null(p) || is.na(p)) {
    return("")
  }
  if (p < 0.001) {
    "<0.001"
  } else {
    sprintf("%.3f", p)
  }
}

format_mean_sd <- function(x, group, digits = 1) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])

  if (length(x_use) == 0L) {
    return(setNames(c("", ""), levels(group)))
  }

  out <- setNames(character(length(levels(g_use))), levels(g_use))
  for (lvl in levels(g_use)) {
    x_g <- x_use[g_use == lvl]
    if (length(x_g) == 0L) {
      out[lvl] <- ""
    } else {
      m <- mean(x_g)
      s <- stats::sd(x_g)
      out[lvl] <- paste0(
        round(m, digits = digits),
        "(",
        round(s, digits = digits),
        ")"
      )
    }
  }
  out
}

format_n_pct <- function(x, group, event = 1L) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])

  out <- setNames(character(length(levels(g_use))), levels(g_use))

  for (lvl in levels(g_use)) {
    mask <- g_use == lvl
    denom <- sum(mask)
    if (denom == 0L) {
      out[lvl] <- ""
    } else {
      n_event <- sum(x_use[mask] == event, na.rm = TRUE)
      pct <- round(100 * n_event / denom)
      out[lvl] <- paste0(n_event, "(", pct, ")")
    }
  }
  out
}

fun_pvalue_cont <- function(x, group) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])

  if (length(unique(g_use)) < 2L) {
    return(NA_real_)
  }

  p <- tryCatch(
    {
      stats::t.test(x_use ~ g_use)$p.value
    },
    error = function(e) NA_real_
  )
  p
}

fun_pvalue_cat <- function(x, group) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])

  if (length(unique(g_use)) < 2L || length(unique(x_use)) < 2L) {
    return(NA_real_)
  }

  tab <- table(g_use, x_use)

  chi_res <- tryCatch(
    suppressWarnings(stats::chisq.test(tab, correct = FALSE)),
    error = function(e) NULL
  )

  if (!is.null(chi_res)) {
    if (any(chi_res$expected < 5)) {
      p <- stats::fisher.test(tab)$p.value
    } else {
      p <- chi_res$p.value
    }
  } else {
    p <- stats::fisher.test(tab)$p.value
  }

  p
}

make_binary_row <- function(data, var_name, row_label, event = 1L,
                            group0 = group0_lvl, group1 = group1_lvl) {
  x <- data[[var_name]]
  vals <- format_n_pct(x, data$FOF_status, event = event)
  p <- fun_pvalue_cat(x, data$FOF_status)

  tibble::tibble(
    Variable    = paste0("  ", row_label),
    Without_FOF = vals[group0],
    With_FOF    = vals[group1],
    P_value     = format_pvalue(p)
  )
}

fun_pvalue_cat_level <- function(factor_var, group, level_value) {
  idx <- !is.na(factor_var) & !is.na(group)
  f_use <- droplevels(factor_var[idx])
  g_use <- droplevels(group[idx])

  if (length(unique(g_use)) < 2L) {
    return(NA_real_)
  }

  tab <- table(g_use, f_use == level_value)

  chi_res <- tryCatch(
    suppressWarnings(stats::chisq.test(tab, correct = FALSE)),
    error = function(e) NULL
  )

  if (!is.null(chi_res)) {
    if (any(chi_res$expected < 5)) {
      p <- stats::fisher.test(tab)$p.value
    } else {
      p <- chi_res$p.value
    }
  } else {
    p <- stats::fisher.test(tab)$p.value
  }

  p
}

make_multicat_rows_with_level_p <- function(data, var_name, header_label,
                                            group0 = group0_lvl, group1 = group1_lvl) {
  f <- data[[var_name]]
  g <- data$FOF_status

  idx <- !is.na(f) & !is.na(g)
  f_use <- droplevels(f[idx])
  g_use <- droplevels(g[idx])

  if (length(f_use) == 0L) {
    return(
      tibble::tibble(
        Variable    = header_label,
        Without_FOF = "",
        With_FOF    = "",
        P_value     = ""
      )
    )
  }

  levels_f <- levels(f_use)

  tab <- as.data.frame(table(g_use, f_use), stringsAsFactors = FALSE)
  colnames(tab) <- c("FOF_status", "level", "n")

  tab <- tab %>%
    group_by(FOF_status) %>%
    mutate(
      denom = sum(n),
      pct   = ifelse(denom > 0, round(100 * n / denom), NA_real_)
    ) %>%
    ungroup()

  get_cell <- function(level_value, fof_value) {
    row <- tab %>%
      filter(level == level_value, FOF_status == fof_value)
    if (nrow(row) == 0L || row$denom[1] == 0L) {
      "0(0)"
    } else {
      paste0(row$n[1], "(", row$pct[1], ")")
    }
  }

  header_sums <- tab %>%
    group_by(FOF_status) %>%
    summarise(
      n_total = sum(n),
      .groups = "drop"
    )

  get_header_cell <- function(fof_value) {
    row <- header_sums %>% filter(FOF_status == fof_value)
    if (nrow(row) == 0L || is.na(row$n_total[1]) || row$n_total[1] == 0L) {
      ""
    } else {
      paste0(row$n_total[1], "(100)")
    }
  }

  header_without <- get_header_cell(group0)
  header_with    <- get_header_cell(group1)

  p_overall <- fun_pvalue_cat(f, g)

  rows_list <- list(
    tibble::tibble(
      Variable    = header_label,
      Without_FOF = header_without,
      With_FOF    = header_with,
      P_value     = format_pvalue(p_overall)
    )
  )

  for (lvl in levels_f) {
    p_lvl <- fun_pvalue_cat_level(f, g, level_value = lvl)

    rows_list[[length(rows_list) + 1L]] <- tibble::tibble(
      Variable    = paste0("  ", lvl),
      Without_FOF = get_cell(lvl, group0),
      With_FOF    = get_cell(lvl, group1),
      P_value     = format_pvalue(p_lvl)
    )
  }

  dplyr::bind_rows(rows_list)
}

# ==============================================================================
# 07. Taulukon Yksittäiset Lohkot (K14 LOGIC + NEW: Frailty)
# ==============================================================================

## 7.1 Women, n (%)
vals_women <- format_n_pct(analysis_data_rec$woman,
                           analysis_data_rec$FOF_status, event = 1L)
p_women <- fun_pvalue_cat(analysis_data_rec$woman,
                          analysis_data_rec$FOF_status)

tab_women <- tibble::tibble(
  Variable    = "Women, n (%)",
  Without_FOF = vals_women[group0_lvl],
  With_FOF    = vals_women[group1_lvl],
  P_value     = format_pvalue(p_women)
)

## 7.2 Age, mean (SD)
vals_age <- format_mean_sd(analysis_data_rec$age,
                           analysis_data_rec$FOF_status, digits = 0)
p_age <- fun_pvalue_cont(analysis_data_rec$age,
                         analysis_data_rec$FOF_status)

tab_age <- tibble::tibble(
  Variable    = "Age, mean (SD)",
  Without_FOF = vals_age[group0_lvl],
  With_FOF    = vals_age[group1_lvl],
  P_value     = format_pvalue(p_age)
)

## 7.3 Diseases, n (%)
any_disease <- with(
  analysis_data_rec,
  (diabetes == 1) | (alzheimer == 1) | (parkinson == 1) | (AVH == 1)
)

vals_any_disease <- format_n_pct(as.integer(any_disease),
                                 analysis_data_rec$FOF_status,
                                 event = 1L)
p_any_disease    <- fun_pvalue_cat(as.integer(any_disease),
                                   analysis_data_rec$FOF_status)

tab_diseases_header <- tibble::tibble(
  Variable    = "Diseases, n (%)",
  Without_FOF = vals_any_disease[group0_lvl],
  With_FOF    = vals_any_disease[group1_lvl],
  P_value     = format_pvalue(p_any_disease)
)

tab_diabetes <- make_binary_row(analysis_data_rec, "diabetes",    "Diabetes")
tab_dementia <- make_binary_row(analysis_data_rec, "alzheimer",   "Dementia")
tab_parkin   <- make_binary_row(analysis_data_rec, "parkinson",   "Parkinson's")
tab_cva      <- make_binary_row(analysis_data_rec, "AVH",         "Cerebrovascular Accidents")
tab_comorb   <- make_binary_row(analysis_data_rec, "comorbidity", "Comorbidity (>1 disease)")

tab_diseases <- dplyr::bind_rows(
  tab_diseases_header,
  tab_diabetes,
  tab_dementia,
  tab_parkin,
  tab_cva,
  tab_comorb
)

## 7.4 Self-rated Health, n (%)
tab_SRH <- make_multicat_rows_with_level_p(
  data         = analysis_data_rec,
  var_name     = "SRH_3class_table",
  header_label = "Self-rated Health, n (%)"
)

## 7.5 Mikkeli Osteoporosis Index, mean (SD)
vals_MOI <- format_mean_sd(analysis_data_rec$MOIindeksiindeksi,
                           analysis_data_rec$FOF_status, digits = 1)
p_MOI <- fun_pvalue_cont(analysis_data_rec$MOIindeksiindeksi,
                         analysis_data_rec$FOF_status)

tab_MOI <- tibble::tibble(
  Variable    = "Mikkeli Osteoporosis Index, mean (SD)",
  Without_FOF = vals_MOI[group0_lvl],
  With_FOF    = vals_MOI[group1_lvl],
  P_value     = format_pvalue(p_MOI)
)

## 7.6 Body Mass Index, mean (SD)
vals_BMI <- format_mean_sd(analysis_data_rec$BMI,
                           analysis_data_rec$FOF_status, digits = 1)
p_BMI <- fun_pvalue_cont(analysis_data_rec$BMI,
                         analysis_data_rec$FOF_status)

tab_BMI <- tibble::tibble(
  Variable    = "Body Mass Index, mean (SD)",
  Without_FOF = vals_BMI[group0_lvl],
  With_FOF    = vals_BMI[group1_lvl],
  P_value     = format_pvalue(p_BMI)
)

## 7.7 Smoked, n (%)
vals_smoked <- format_n_pct(analysis_data_rec$tupakointi,
                            analysis_data_rec$FOF_status, event = 1L)
p_smoked <- fun_pvalue_cat(analysis_data_rec$tupakointi,
                           analysis_data_rec$FOF_status)

tab_smoked <- tibble::tibble(
  Variable    = "Smoked, n (%)",
  Without_FOF = vals_smoked[group0_lvl],
  With_FOF    = vals_smoked[group1_lvl],
  P_value     = format_pvalue(p_smoked)
)

## 7.8 Alcohol, n (%)
tab_alcohol <- make_multicat_rows_with_level_p(
  data         = analysis_data_rec,
  var_name     = "alcohol_3class_table",
  header_label = "Alcohol, n (%)"
)

## 7.9 Self-Rated Mobility, n (%)
tab_SRM <- make_multicat_rows_with_level_p(
  data         = analysis_data_rec,
  var_name     = "SRM_3class_table",
  header_label = "Self-Rated Mobility, n (%)"
)

## 7.10 Walking 500 m, n (%)
tab_Walk500 <- make_multicat_rows_with_level_p(
  data         = analysis_data_rec,
  var_name     = "Walk500m_3class_table",
  header_label = "Walking 500 m, n (%)"
)

## 7.11 Balance difficulties, n (%)
vals_balance <- format_n_pct(analysis_data_rec$tasapainovaikeus,
                             analysis_data_rec$FOF_status, event = 1L)
p_balance <- fun_pvalue_cat(analysis_data_rec$tasapainovaikeus,
                            analysis_data_rec$FOF_status)

tab_balance <- tibble::tibble(
  Variable    = "Balance difficulties, n (%)",
  Without_FOF = vals_balance[group0_lvl],
  With_FOF    = vals_balance[group1_lvl],
  P_value     = format_pvalue(p_balance)
)

## 7.12 Fallen, n (%)
vals_fallen <- format_n_pct(analysis_data_rec$kaatuminen,
                            analysis_data_rec$FOF_status, event = 1L)
p_fallen <- fun_pvalue_cat(analysis_data_rec$kaatuminen,
                           analysis_data_rec$FOF_status)

tab_fallen <- tibble::tibble(
  Variable    = "Fallen, n (%)",
  Without_FOF = vals_fallen[group0_lvl],
  With_FOF    = vals_fallen[group1_lvl],
  P_value     = format_pvalue(p_fallen)
)

## 7.13 Fractures, n (%)
vals_fract <- format_n_pct(analysis_data_rec$murtumia,
                           analysis_data_rec$FOF_status, event = 1L)
p_fract <- fun_pvalue_cat(analysis_data_rec$murtumia,
                          analysis_data_rec$FOF_status)

tab_fractures <- tibble::tibble(
  Variable    = "Fractures, n (%)",
  Without_FOF = vals_fract[group0_lvl],
  With_FOF    = vals_fract[group1_lvl],
  P_value     = format_pvalue(p_fract)
)

## 7.14 Pain VAS, mean (SD)
vals_pain <- format_mean_sd(analysis_data_rec$PainVAS0,
                            analysis_data_rec$FOF_status, digits = 1)
p_pain <- fun_pvalue_cont(analysis_data_rec$PainVAS0,
                          analysis_data_rec$FOF_status)

tab_pain <- tibble::tibble(
  Variable    = "Pain (Visual Analog Scale), mm, mean (SD)",
  Without_FOF = vals_pain[group0_lvl],
  With_FOF    = vals_pain[group1_lvl],
  P_value     = format_pvalue(p_pain)
)

## 7.15 NEW: Frailty (frailty_cat_3), n (%)
# Use make_multicat_rows_with_level_p to match K14 style
tab_frailty <- make_multicat_rows_with_level_p(
  data         = analysis_data_rec,
  var_name     = "frailty_cat_3",
  header_label = "Frailty (Fried-inspired proxy), n (%)"
)

# ==============================================================================
# 08. Bind Rows & Nimeä Sarakkeet Table 1 -Muotoon
# ==============================================================================

baseline_table_raw <- dplyr::bind_rows(
  tab_women,      # 1
  tab_age,        # 2
  tab_diseases,   # 3) header + 5 diagnoosiriviä
  tab_SRH,        # 4) Self-rated Health (header + 3 riviä)
  tab_MOI,        # 5
  tab_BMI,        # 6
  tab_smoked,     # 7
  tab_alcohol,    # 8) header + 3 riviä
  tab_SRM,        # 9) header + 3 riviä
  tab_Walk500,    # 10) header + 3 riviä
  tab_balance,    # 11
  tab_fallen,     # 12
  tab_fractures,  # 13
  tab_pain,       # 14
  tab_frailty     # 15) NEW: header + 3 riviä (robust/pre-frail/frail)
)

col_without <- paste0("Without FOF\nn=", N_group0)
col_with    <- paste0("With FOF\nn=", N_group1)

baseline_table <- baseline_table_raw %>%
  rename(
    " "               = Variable,
    !!col_without     := Without_FOF,
    !!col_with        := With_FOF,
    "P-value"         := P_value
  )

table_footnote <- paste(
  "Abbreviations: FOF = Fear of Falling; BMI = Body Mass Index;",
  "SD = Standard Deviation; VAS = Visual Analog Scale.",
  "Frailty: Fried-inspired 3-component proxy (weakness + slowness + low activity).",
  "P-values calculated using t-tests for continuous variables",
  "and chi-square tests for categorical variables.",
  sep = " "
)
attr(baseline_table, "footnote") <- table_footnote

# ==============================================================================
# 09. Tulostus, Tallennus ja Manifestin Päivitys
# ==============================================================================

print(baseline_table)

basename_out <- "K17_baseline_by_FOF_with_frailty"
save_table_csv_html(baseline_table, basename_out)

manifest_rows <- tibble::tibble(
  script      = script_label,
  type        = "table",
  filename    = file.path(script_label, paste0(basename_out, ".csv")),
  description = "Baseline characteristics by FOF-status (Table 1) + frailty_cat_3 (robust/pre-frail/frail)."
)

if (!file.exists(manifest_path)) {
  utils::write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = TRUE,
    append    = FALSE,
    qmethod   = "double"
  )
} else {
  utils::write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = FALSE,
    append    = TRUE,
    qmethod   = "double"
  )
}

message("K17: baseline table by FOF-status (with frailty) tallennettu ja manifest päivitetty.")

# End of K17.R

save_sessioninfo_manifest()
