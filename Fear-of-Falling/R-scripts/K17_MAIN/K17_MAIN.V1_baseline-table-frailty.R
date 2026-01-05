#!/usr/bin/env Rscript
# ==============================================================================
# K17_MAIN - Baseline characteristics by FOF status (Table 1) + Frailty
# File tag: K17_MAIN.V1_baseline-table-frailty.R
# Purpose: Reproduce K14 table structure and add frailty_cat_3 (robust/pre-frail/frail)
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# kaatumisenpelkoOn, age, sex, BMI, diabetes, alzheimer, parkinson, AVH,
# koettuterveydentila (or SRH), MOIindeksiindeksi, tupakointi, alkoholi,
# oma_arvio_liikuntakyky, vaikeus_liikkua_500m (or Vaikeus500m), tasapainovaikeus,
# kaatuminen, murtumia, PainVAS0, Puristus0, kavelynopeus_m_sek0,
# maxkävelymatka, vaikeus_liikkua_2km
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124
#
# Outputs + manifest:
# - script_label: K17_MAIN (canonical)
# - outputs dir: R-scripts/K17_MAIN/outputs/  (init_paths)
# - manifest: append 1 row per artifact to manifest/manifest.csv
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
  "K17_MAIN"
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K17_MAIN"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

cat("================================================================================\n")
cat("K17 Baseline Table by FOF + Frailty\n")
cat("Script label:", script_label, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("Project root:", here::here(), "\n")
cat("================================================================================\n\n")

set.seed(20251124)

# --- Load raw data (immutable) -----------------------------------------------
raw_path <- here::here("data", "external", "KaatumisenPelko.csv")
if (!file.exists(raw_path)) stop("Raw data not found: ", raw_path)

raw_data <- readr::read_csv(raw_path, show_col_types = FALSE)

# --- Required columns gate (DO NOT INVENT) ----------------------------------
req_cols <- c(
  "kaatumisenpelkoOn", "age", "sex", "BMI",
  "diabetes", "alzheimer", "parkinson", "AVH",
  "MOIindeksiindeksi", "tupakointi", "alkoholi",
  "oma_arvio_liikuntakyky", "tasapainovaikeus",
  "kaatuminen", "murtumia", "PainVAS0",
  "Puristus0", "kavelynopeus_m_sek0",
  "maxkävelymatka", "vaikeus_liikkua_2km"
)
missing_cols <- setdiff(req_cols, names(raw_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

walk500_var <- if ("vaikeus_liikkua_500m" %in% names(raw_data)) {
  "vaikeus_liikkua_500m"
} else if ("Vaikeus500m" %in% names(raw_data)) {
  "Vaikeus500m"
} else {
  NA_character_
}
if (is.na(walk500_var)) {
  stop("Missing required column: vaikeus_liikkua_500m (or Vaikeus500m).")
}

srh_source_var <- if ("koettuterveydentila" %in% names(raw_data)) {
  "koettuterveydentila"
} else if ("SRH" %in% names(raw_data)) {
  warning("Column 'koettuterveydentila' not found, falling back to 'SRH'.")
  "SRH"
} else {
  stop("Neither 'koettuterveydentila' nor 'SRH' found in the data.")
}

# --- Minimal QC: missingness by FOF -----------------------------------------
qc_missingness <- raw_data %>%
  mutate(FOF_status = kaatumisenpelkoOn) %>%
  group_by(FOF_status) %>%
  summarise(
    n = dplyr::n(),
    miss_age = sum(is.na(age)),
    miss_sex = sum(is.na(sex)),
    miss_BMI = sum(is.na(BMI)),
    miss_srh = sum(is.na(.data[[srh_source_var]])),
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

# --- Recodings (K14 logic) ---------------------------------------------------
analysis_data_rec <- raw_data %>%
  mutate(
    FOF_status = factor(
      kaatumisenpelkoOn,
      levels = c(0, 1),
      labels = c("nonFOF", "FOF")
    ),
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
    SRH_3class_table = factor(
      .data[[srh_source_var]],
      levels = c(2, 1, 0),
      labels = c("Good", "Moderate", "Bad"),
      ordered = TRUE
    ),
    SRM_3class_table = factor(
      oma_arvio_liikuntakyky,
      levels = c(2, 1, 0),
      labels = c("Good", "Moderate", "Weak"),
      ordered = TRUE
    ),
    Walk500m_3class_table = factor(
      .data[[walk500_var]],
      levels = c(0, 1, 2),
      labels = c("No", "Difficulties", "Cannot"),
      ordered = TRUE
    ),
    alcohol_3class_table = factor(
      alkoholi,
      levels = c(0, 1, 2),
      labels = c("No", "Moderate", "Large"),
      ordered = TRUE
    )
  ) %>%
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

# --- Frailty derivation (K15 logic, minimal block) ---------------------------
grip_cut_strategy <- "sex_Q1"
gait_cut_m_per_sec <- 0.8
maxwalk_low_cut_m <- 400

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    Puristus0_clean = if_else(
      !is.na(Puristus0) & Puristus0 <= 0,
      NA_real_,
      Puristus0
    )
  )

grip_cuts <- NULL
if (grip_cut_strategy == "sex_Q1") {
  grip_cuts <- analysis_data_rec %>%
    filter(!is.na(Puristus0_clean), !is.na(sex_factor)) %>%
    group_by(sex_factor) %>%
    summarise(
      cut_Q1 = quantile(Puristus0_clean, probs = 0.25, na.rm = TRUE),
      .groups = "drop"
    )
}
grip_cut_vec <- if (!is.null(grip_cuts)) {
  setNames(grip_cuts$cut_Q1, as.character(grip_cuts$sex_factor))
} else {
  NULL
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

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    frailty_slowness = case_when(
      is.na(kavelynopeus_m_sek0) ~ NA_integer_,
      kavelynopeus_m_sek0 == 0 ~ 1L,
      kavelynopeus_m_sek0 < gait_cut_m_per_sec ~ 1L,
      TRUE ~ 0L
    )
  )

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    walking500_code = .data[[walk500_var]],
    walking2km_code = vaikeus_liikkua_2km,
    flag_weak_SR = case_when(
      is.na(oma_arvio_liikuntakyky) ~ NA,
      oma_arvio_liikuntakyky == 0   ~ TRUE,
      oma_arvio_liikuntakyky %in% c(1, 2) ~ FALSE,
      TRUE ~ NA
    ),
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
      is.na(.data[["maxkävelymatka"]]) ~ NA,
      .data[["maxkävelymatka"]] < maxwalk_low_cut_m ~ TRUE,
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

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    frailty_count_3 = frailty_weakness + frailty_slowness + frailty_low_activity,
    frailty_cat_3 = case_when(
      is.na(frailty_count_3) ~ NA_character_,
      frailty_count_3 == 0 ~ "robust",
      frailty_count_3 == 1 ~ "pre-frail",
      frailty_count_3 >= 2 ~ "frail"
    ),
    frailty_cat_3 = factor(frailty_cat_3, levels = c("robust", "pre-frail", "frail"))
  )

# --- Sanity check: frailty distribution --------------------------------------
table1_sample <- analysis_data_rec %>% filter(!is.na(FOF_status))
frailty_totals <- table1_sample %>%
  count(frailty_cat_3) %>%
  mutate(percentage = round(100 * n / sum(n), 1))
print(frailty_totals)
print(table(table1_sample$FOF_status, table1_sample$frailty_cat_3, useNA = "ifany"))

# --- Group sizes -------------------------------------------------------------
if (!"FOF_status" %in% names(analysis_data_rec)) {
  stop("FOF_status missing from recoded data.")
}
fof_counts <- analysis_data_rec %>%
  filter(!is.na(FOF_status)) %>%
  count(FOF_status)

fof_levels <- levels(analysis_data_rec$FOF_status)
group0_lvl <- fof_levels[1]
group1_lvl <- fof_levels[2]

N_group0 <- fof_counts$n[fof_counts$FOF_status == group0_lvl]
N_group1 <- fof_counts$n[fof_counts$FOF_status == group1_lvl]

# --- Helper functions (K14 logic) -------------------------------------------
format_pvalue <- function(p) {
  if (is.null(p) || is.na(p)) return("")
  if (p < 0.001) "<0.001" else sprintf("%.3f", p)
}

format_mean_sd <- function(x, group, digits = 1) {
  lvls <- levels(group)
  out <- setNames(rep("", length(lvls)), lvls)
  idx <- !is.na(group) & !is.na(x)
  if (!any(idx)) return(out)
  x_use <- x[idx]
  g_use <- group[idx]
  for (lvl in lvls) {
    x_g <- x_use[g_use == lvl]
    if (length(x_g) == 0L) {
      out[lvl] <- ""
    } else {
      m <- mean(x_g)
      s <- stats::sd(x_g)
      out[lvl] <- paste0(round(m, digits = digits), "(", round(s, digits = digits), ")")
    }
  }
  out
}

format_n_pct <- function(x, group, event = 1L) {
  lvls <- levels(group)
  out <- setNames(rep("", length(lvls)), lvls)
  idx <- !is.na(group) & !is.na(x)
  if (!any(idx)) return(out)
  x_use <- x[idx]
  g_use <- group[idx]
  for (lvl in lvls) {
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
  if (length(unique(g_use)) < 2L) return(NA_real_)
  p <- tryCatch(stats::t.test(x_use ~ g_use)$p.value, error = function(e) NA_real_)
  p
}

fun_pvalue_cat <- function(x, group) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])
  if (length(unique(g_use)) < 2L || length(unique(x_use)) < 2L) return(NA_real_)
  tab <- table(g_use, x_use)
  chi_res <- tryCatch(
    suppressWarnings(stats::chisq.test(tab, correct = FALSE)),
    error = function(e) NULL
  )
  if (!is.null(chi_res)) {
    if (any(chi_res$expected < 5)) {
      stats::fisher.test(tab)$p.value
    } else {
      chi_res$p.value
    }
  } else {
    stats::fisher.test(tab)$p.value
  }
}

fun_pvalue_cat_level <- function(factor_var, group, level_value) {
  idx <- !is.na(factor_var) & !is.na(group)
  f_use <- droplevels(factor_var[idx])
  g_use <- droplevels(group[idx])
  if (length(unique(g_use)) < 2L) return(NA_real_)
  tab <- table(g_use, f_use == level_value)
  chi_res <- tryCatch(
    suppressWarnings(stats::chisq.test(tab, correct = FALSE)),
    error = function(e) NULL
  )
  if (!is.null(chi_res)) {
    if (any(chi_res$expected < 5)) {
      stats::fisher.test(tab)$p.value
    } else {
      chi_res$p.value
    }
  } else {
    stats::fisher.test(tab)$p.value
  }
}

make_binary_row <- function(data, var_name, row_label, event = 1L,
                            group0 = group0_lvl, group1 = group1_lvl) {
  x <- data[[var_name]]
  vals <- format_n_pct(x, data$FOF_status, event = event)
  p <- fun_pvalue_cat(x, data$FOF_status)
  tibble(
    Variable    = paste0("  ", row_label),
    Without_FOF = vals[group0],
    With_FOF    = vals[group1],
    P_value     = format_pvalue(p)
  )
}

make_multicat_rows_with_level_p <- function(data, var_name, header_label,
                                            group0 = group0_lvl, group1 = group1_lvl) {
  f <- data[[var_name]]
  g <- data$FOF_status
  df_full <- data %>% filter(!is.na(.data$FOF_status))
  idx <- !is.na(f) & !is.na(g)
  f_use <- droplevels(f[idx])
  g_use <- droplevels(g[idx])
  if (length(f_use) == 0L) {
    return(tibble(Variable = header_label, Without_FOF = "", With_FOF = "", P_value = ""))
  }
  levels_f <- levels(f_use)
  tab <- as.data.frame(table(g_use, f_use), stringsAsFactors = FALSE)
  colnames(tab) <- c("FOF_status", "level", "n")
  tab <- tab %>%
    group_by(FOF_status) %>%
    mutate(
      denom = sum(n),
      pct = ifelse(denom > 0, round(100 * n / denom), NA_real_)
    ) %>%
    ungroup()
  get_cell <- function(level_value, fof_value) {
    row <- tab %>% filter(level == level_value, FOF_status == fof_value)
    if (nrow(row) == 0L) {
      return("")
    }
    if (row$denom[1] == 0L) {
      return("0(0)")
    }
    paste0(row$n[1], "(", row$pct[1], ")")
  }
  header_sums <- df_full %>%
    dplyr::group_by(FOF_status) %>%
    dplyr::summarise(n_total = dplyr::n(), .groups = "drop")
  get_header_cell <- function(fof_value) {
    row <- header_sums %>% filter(FOF_status == fof_value)
    if (nrow(row) == 0L || is.na(row$n_total[1]) || row$n_total[1] == 0L) "" else paste0(row$n_total[1], "(100)")
  }
  header_without <- get_header_cell(group0)
  header_with <- get_header_cell(group1)
  p_overall <- fun_pvalue_cat(f, g)
  rows_list <- list(
    tibble(
      Variable    = header_label,
      Without_FOF = header_without,
      With_FOF    = header_with,
      P_value     = format_pvalue(p_overall)
    )
  )
  for (lvl in levels_f) {
    p_lvl <- fun_pvalue_cat_level(f, g, level_value = lvl)
    rows_list[[length(rows_list) + 1L]] <- tibble(
      Variable    = paste0("  ", lvl),
      Without_FOF = get_cell(lvl, group0),
      With_FOF    = get_cell(lvl, group1),
      P_value     = format_pvalue(p_lvl)
    )
  }
  bind_rows(rows_list)
}

# --- Table 1 rows -----------------------------------------------------------
vals_women <- format_n_pct(analysis_data_rec$woman, analysis_data_rec$FOF_status, event = 1L)
p_women <- fun_pvalue_cat(analysis_data_rec$woman, analysis_data_rec$FOF_status)
tab_women <- tibble(
  Variable    = "Women, n (%)",
  Without_FOF = vals_women[group0_lvl],
  With_FOF    = vals_women[group1_lvl],
  P_value     = format_pvalue(p_women)
)

vals_age <- format_mean_sd(analysis_data_rec$age, analysis_data_rec$FOF_status, digits = 0)
p_age <- fun_pvalue_cont(analysis_data_rec$age, analysis_data_rec$FOF_status)
tab_age <- tibble(
  Variable    = "Age, mean (SD)",
  Without_FOF = vals_age[group0_lvl],
  With_FOF    = vals_age[group1_lvl],
  P_value     = format_pvalue(p_age)
)

disease_nonmiss <- with(
  analysis_data_rec,
  !is.na(diabetes) | !is.na(alzheimer) | !is.na(parkinson) | !is.na(AVH)
)
any_disease <- with(
  analysis_data_rec,
  ifelse(
    !disease_nonmiss,
    NA,
    (diabetes == 1) | (alzheimer == 1) | (parkinson == 1) | (AVH == 1)
  )
)
vals_any_disease <- format_n_pct(as.integer(any_disease), analysis_data_rec$FOF_status, event = 1L)
p_any_disease <- fun_pvalue_cat(as.integer(any_disease), analysis_data_rec$FOF_status)
tab_diseases_header <- tibble(
  Variable    = "Diseases, n (%)",
  Without_FOF = vals_any_disease[group0_lvl],
  With_FOF    = vals_any_disease[group1_lvl],
  P_value     = format_pvalue(p_any_disease)
)

tab_diseases <- bind_rows(
  tab_diseases_header,
  make_binary_row(analysis_data_rec, "diabetes", "Diabetes"),
  make_binary_row(analysis_data_rec, "alzheimer", "Dementia"),
  make_binary_row(analysis_data_rec, "parkinson", "Parkinson's"),
  make_binary_row(analysis_data_rec, "AVH", "Cerebrovascular Accidents"),
  make_binary_row(analysis_data_rec, "comorbidity", "Comorbidity (>1 disease)")
)

tab_SRH <- make_multicat_rows_with_level_p(
  data = analysis_data_rec,
  var_name = "SRH_3class_table",
  header_label = "Self-rated Health, n (%)"
)

vals_MOI <- format_mean_sd(analysis_data_rec$MOIindeksiindeksi, analysis_data_rec$FOF_status, digits = 1)
p_MOI <- fun_pvalue_cont(analysis_data_rec$MOIindeksiindeksi, analysis_data_rec$FOF_status)
tab_MOI <- tibble(
  Variable    = "Mikkeli Osteoporosis Index, mean (SD)",
  Without_FOF = vals_MOI[group0_lvl],
  With_FOF    = vals_MOI[group1_lvl],
  P_value     = format_pvalue(p_MOI)
)

vals_BMI <- format_mean_sd(analysis_data_rec$BMI, analysis_data_rec$FOF_status, digits = 1)
p_BMI <- fun_pvalue_cont(analysis_data_rec$BMI, analysis_data_rec$FOF_status)
tab_BMI <- tibble(
  Variable    = "Body Mass Index, mean (SD)",
  Without_FOF = vals_BMI[group0_lvl],
  With_FOF    = vals_BMI[group1_lvl],
  P_value     = format_pvalue(p_BMI)
)

vals_smoked <- format_n_pct(analysis_data_rec$tupakointi, analysis_data_rec$FOF_status, event = 1L)
p_smoked <- fun_pvalue_cat(analysis_data_rec$tupakointi, analysis_data_rec$FOF_status)
tab_smoked <- tibble(
  Variable    = "Smoked, n (%)",
  Without_FOF = vals_smoked[group0_lvl],
  With_FOF    = vals_smoked[group1_lvl],
  P_value     = format_pvalue(p_smoked)
)

tab_alcohol <- make_multicat_rows_with_level_p(
  data = analysis_data_rec,
  var_name = "alcohol_3class_table",
  header_label = "Alcohol, n (%)"
)

tab_SRM <- make_multicat_rows_with_level_p(
  data = analysis_data_rec,
  var_name = "SRM_3class_table",
  header_label = "Self-Rated Mobility, n (%)"
)

tab_Walk500 <- make_multicat_rows_with_level_p(
  data = analysis_data_rec,
  var_name = "Walk500m_3class_table",
  header_label = "Walking 500 m, n (%)"
)

vals_balance <- format_n_pct(analysis_data_rec$tasapainovaikeus, analysis_data_rec$FOF_status, event = 1L)
p_balance <- fun_pvalue_cat(analysis_data_rec$tasapainovaikeus, analysis_data_rec$FOF_status)
tab_balance <- tibble(
  Variable    = "Balance difficulties, n (%)",
  Without_FOF = vals_balance[group0_lvl],
  With_FOF    = vals_balance[group1_lvl],
  P_value     = format_pvalue(p_balance)
)

vals_fallen <- format_n_pct(analysis_data_rec$kaatuminen, analysis_data_rec$FOF_status, event = 1L)
p_fallen <- fun_pvalue_cat(analysis_data_rec$kaatuminen, analysis_data_rec$FOF_status)
tab_fallen <- tibble(
  Variable    = "Fallen, n (%)",
  Without_FOF = vals_fallen[group0_lvl],
  With_FOF    = vals_fallen[group1_lvl],
  P_value     = format_pvalue(p_fallen)
)

vals_fract <- format_n_pct(analysis_data_rec$murtumia, analysis_data_rec$FOF_status, event = 1L)
p_fract <- fun_pvalue_cat(analysis_data_rec$murtumia, analysis_data_rec$FOF_status)
tab_fractures <- tibble(
  Variable    = "Fractures, n (%)",
  Without_FOF = vals_fract[group0_lvl],
  With_FOF    = vals_fract[group1_lvl],
  P_value     = format_pvalue(p_fract)
)

vals_pain <- format_mean_sd(analysis_data_rec$PainVAS0, analysis_data_rec$FOF_status, digits = 1)
p_pain <- fun_pvalue_cont(analysis_data_rec$PainVAS0, analysis_data_rec$FOF_status)
tab_pain <- tibble(
  Variable    = "Pain (Visual Analog Scale), mm, mean (SD)",
  Without_FOF = vals_pain[group0_lvl],
  With_FOF    = vals_pain[group1_lvl],
  P_value     = format_pvalue(p_pain)
)

tab_frailty <- make_multicat_rows_with_level_p(
  data = analysis_data_rec,
  var_name = "frailty_cat_3",
  header_label = "Frailty (Fried-inspired proxy), n (%)"
)

baseline_table_raw <- bind_rows(
  tab_women,
  tab_age,
  tab_diseases,
  tab_SRH,
  tab_MOI,
  tab_BMI,
  tab_smoked,
  tab_alcohol,
  tab_SRM,
  tab_Walk500,
  tab_balance,
  tab_fallen,
  tab_fractures,
  tab_pain,
  tab_frailty
)

col_without <- paste0("Without FOF\nn=", N_group0)
col_with <- paste0("With FOF\nn=", N_group1)

baseline_table <- baseline_table_raw %>%
  rename(
    " " = Variable,
    !!col_without := Without_FOF,
    !!col_with := With_FOF,
    "P-value" = P_value
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

save_table_csv_html(baseline_table, "baseline_by_fof_with_frailty", n = nrow(baseline_table))

# --- Session info -----------------------------------------------------------
save_sessioninfo_manifest()
