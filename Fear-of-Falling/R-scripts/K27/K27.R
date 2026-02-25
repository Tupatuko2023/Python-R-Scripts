#!/usr/bin/env Rscript
# ==============================================================================
# K27 - Baseline characteristics by FRAILTY status (Table 1) + optional FOF
# File tag: K27.R
# Purpose: Produces descriptive Table 1 stratified by frailty_cat_3 (robust,
#          pre-frail, frail) using the same K14/K17 custom table framework
#          (NO external table packages). Includes overall p-values for group
#          comparisons and level-specific p-values for multi-category rows.
#
# Outcome: None (descriptive table only, no modeling)
# Grouping variable: frailty_cat_3 (factor: "robust"/"pre-frail"/"frail")
# Optional print: Cross-tab frailty_cat_3 × FOF_status (counts)
#
# Required vars (raw_data - DO NOT INVENT; must match req_raw_cols check):
# kaatumisenpelkoOn, age, sex, BMI, diabetes, alzheimer, parkinson, AVH,
# koettuterveydentila, MOIindeksiindeksi, tupakointi, alkoholi,
# oma_arvio_liikuntakyky, vaikeus_liikkua_500m, tasapainovaikeus,
# kaatuminen, murtumia, PainVAS0, ToimintaKykySummary0,
# Puristus0, kavelynopeus_m_sek0, maxkävelymatka, vaikeus_liikkua_2km
#
# Frailty derivation (K15 minimal safe block):
#   - frailty_weakness: Puristus0 (sex-specific Q1), 0 treated as missing
#   - frailty_slowness: kavelynopeus_m_sek0 < 0.8 m/s (0 treated as slowness)
#   - frailty_low_activity: oma_arvio_liikuntakyky==0 OR walking 500m/2km difficulty
#                          OR maxkävelymatka<400m (if any info exists)
#   - frailty_count_3 = weakness + slowness + low_activity
#   - frailty_cat_3: 0=robust, 1=pre-frail, >=2=frail
#
# Table rows (same as K17/K14, no new invented variables):
# - Women, n (%)
# - Age, mean (SD)
# - Diseases, n (%) + subrows: Diabetes, Dementia, Parkinson's, Cerebrovascular
#   Accidents, Comorbidity (>1 disease)
# - Self-rated Health, n (%) (Good/Moderate/Bad)
# - Mikkeli Osteoporosis Index, mean (SD)
# - Body Mass Index, mean (SD)
# - Smoked, n (%)
# - Alcohol, n (%) (No/Moderate/Large)
# - Self-Rated Mobility, n (%) (Good/Moderate/Weak)
# - Walking 500 m, n (%) (No/Difficulties/Cannot)
# - Balance difficulties, n (%)
# - Fallen, n (%)
# - Fractures, n (%)
# - Pain (VAS), mean (SD)
#
# P-values:
# - Continuous: one-way ANOVA (aov), else NA on error
# - Categorical: chi-square (correct=FALSE), if expected<5 or error -> fisher.test
# - Multi-cat: overall p on header + level-specific p per row
# - Formatting: <0.001 else 3 decimals (K17 style)
#
# Outputs + manifest:
# - outputs dir: R-scripts/K27/outputs/ (via init_paths)
# - save_table_csv_html(baseline_table, "K27_baseline_by_frailty")
# - append manifest row(s)
# - save_sessioninfo_manifest()
# ==============================================================================

# Activate renv environment if not already loaded
if (Sys.getenv("RENV_PROJECT") == "") source("renv/activate.R")

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
})

# --- Standard init (MANDATORY) -----------------------------------------------
# Derive script_label from --file, supporting file tags like: K27.V1_name.R
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K27"  # interactive fallback
}

script_label <- sub("\\.V.*$", "", script_base)  # canonical SCRIPT_ID
if (is.na(script_label) || script_label == "") script_label <- "K27"

# Source helper functions (io, checks, modeling, reporting)
rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"),
   envir = .GlobalEnv)

source(here("R", "functions", "io.R"))
source(here("R", "functions", "checks.R"))
source(here("R", "functions", "modeling.R"))
source(here("R", "functions", "reporting.R"))

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

# K27 uses raw data (like K14/K17) for table-recoding
analysis_data <- raw_data

# Get paths from init_paths (already called in header)
outputs_dir   <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

# ==============================================================================
# 02. Required raw columns check (DO NOT INVENT)
# ==============================================================================

req_raw_cols <- c(
  "kaatumisenpelkoOn", "age", "sex", "BMI",
  "diabetes", "alzheimer", "parkinson", "AVH",
  "koettuterveydentila", "MOIindeksiindeksi", "tupakointi", "alkoholi",
  "oma_arvio_liikuntakyky", "vaikeus_liikkua_500m", "tasapainovaikeus",
  "kaatuminen", "murtumia", "PainVAS0", "ToimintaKykySummary0",
  "Puristus0", "kavelynopeus_m_sek0", "maxkävelymatka", "vaikeus_liikkua_2km"
)

missing_cols <- setdiff(req_raw_cols, names(analysis_data))
if (length(missing_cols) > 0) {
  stop("Puuttuvat vaaditut raakadatan sarakkeet (req_raw_cols): ",
       paste(missing_cols, collapse = ", "))
}

# ==============================================================================
# 03. Recodings: Table variables (K14/K17 logic)
# ==============================================================================

analysis_data_rec <- analysis_data %>%
  mutate(
    # Optional FOF-status (for cross-tab sanity print; NOT stratification)
    FOF_status = factor(
      kaatumisenpelkoOn,
      levels = c(0, 1),
      labels = c("nonFOF", "FOF")
    ),

    # Sex: 0 = female, 1 = male
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

    # Self-rated Health (Good/Moderate/Bad)
    # Assumption (per K17): koettuterveydentila 0=bad, 1=moderate, 2=good
    SRH_3class_table = factor(
      koettuterveydentila,
      levels = c(2, 1, 0),
      labels = c("Good", "Moderate", "Bad"),
      ordered = TRUE
    ),

    # Self-Rated Mobility (Good/Moderate/Weak)
    SRM_3class_table = factor(
      oma_arvio_liikuntakyky,
      levels = c(2, 1, 0),
      labels = c("Good", "Moderate", "Weak"),
      ordered = TRUE
    ),

    # Walking 500 m (No/Difficulties/Cannot)
    Walk500m_3class_table = factor(
      vaikeus_liikkua_500m,
      levels = c(0, 1, 2),
      labels = c("No", "Difficulties", "Cannot"),
      ordered = TRUE
    ),

    # Alcohol (No/Moderate/Large)
    alcohol_3class_table = factor(
      alkoholi,
      levels = c(0, 1, 2),
      labels = c("No", "Moderate", "Large"),
      ordered = TRUE
    )
  ) %>%
  mutate(
    # Comorbidity (>1 disease) from diabetes/alzheimer/parkinson/AVH
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
      TRUE               ~ 0L
    )
  )

# ==============================================================================
# 04. Derive frailty_cat_3 (K15 minimal safe block; copy-edit from K17)
# ==============================================================================

# 4.1 Weakness (sex-specific Q1 for Puristus0; 0 treated as missing)
grip_cut_strategy <- "sex_Q1"

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    Puristus0_clean = dplyr::case_when(
      is.na(Puristus0) ~ NA_real_,
      Puristus0 <= 0   ~ NA_real_,
      TRUE             ~ as.numeric(Puristus0)
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
    message("K27: Weakness-rajat (sex_Q1):")
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

# 4.2 Slowness (kavelynopeus_m_sek0 < 0.8; 0 => slowness)
gait_cut_m_per_sec <- 0.8

if (!("kavelynopeus_m_sek0" %in% names(analysis_data_rec))) {
  warning("kavelynopeus_m_sek0 puuttuu: slowness-komponentti jää NA:ksi.")
  analysis_data_rec <- analysis_data_rec %>%
    mutate(frailty_slowness = NA_integer_)
} else {
  analysis_data_rec <- analysis_data_rec %>%
    mutate(
      frailty_slowness = case_when(
        is.na(kavelynopeus_m_sek0) ~ NA_integer_,
        kavelynopeus_m_sek0 == 0   ~ 1L,
        kavelynopeus_m_sek0 < gait_cut_m_per_sec ~ 1L,
        TRUE ~ 0L
      )
    )
}

# 4.3 Low physical activity / mobility limitation (K15 logic)
maxwalk_low_cut_m <- 400

has_oma <- "oma_arvio_liikuntakyky" %in% names(analysis_data_rec)
has_2km <- "vaikeus_liikkua_2km" %in% names(analysis_data_rec)
has_maxw <- "maxkävelymatka" %in% names(analysis_data_rec)

analysis_data_rec <- analysis_data_rec %>%
  mutate(
    walking500_code = vaikeus_liikkua_500m,
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

# 4.4 Frailty count and categories
analysis_data_rec <- analysis_data_rec %>%
  mutate(
    frailty_count_3 = frailty_weakness + frailty_slowness + frailty_low_activity,
    frailty_cat_3 = case_when(
      is.na(frailty_count_3) ~ NA_character_,
      frailty_count_3 == 0   ~ "robust",
      frailty_count_3 == 1   ~ "pre-frail",
      frailty_count_3 >= 2   ~ "frail"
    ),
    frailty_cat_3 = factor(frailty_cat_3, levels = c("robust", "pre-frail", "frail"))
  )

# ==============================================================================
# 05. SANITY CHECKS (per spec)
# ==============================================================================

message("\n=== K27 SANITY CHECK: Table 1 sample (frailty_cat_3 non-missing) ===")
table1_sample <- analysis_data_rec %>% filter(!is.na(frailty_cat_3))

N_total <- nrow(table1_sample)
message("K27: Table 1 sample size (non-NA frailty_cat_3): N = ", N_total)

frailty_totals <- table1_sample %>%
  count(frailty_cat_3) %>%
  mutate(percentage = round(100 * n / sum(n), 1))

message("\nK27: Frailty category totals in Table 1 sample:")
print(frailty_totals)

# Expected totals
expected_robust   <- 42L
expected_prefrail <- 126L
expected_frail    <- 82L

n_robust_vec   <- frailty_totals$n[frailty_totals$frailty_cat_3 == "robust"]
n_prefrail_vec <- frailty_totals$n[frailty_totals$frailty_cat_3 == "pre-frail"]
n_frail_vec    <- frailty_totals$n[frailty_totals$frailty_cat_3 == "frail"]

n_robust   <- if (length(n_robust_vec) == 0) 0L else as.integer(n_robust_vec[1])
n_prefrail <- if (length(n_prefrail_vec) == 0) 0L else as.integer(n_prefrail_vec[1])
n_frail    <- if (length(n_frail_vec) == 0) 0L else as.integer(n_frail_vec[1])

N_frailty_missing <- sum(is.na(analysis_data_rec$frailty_cat_3))
if (n_robust == expected_robust && n_prefrail == expected_prefrail && n_frail == expected_frail) {
  message("\n*** OK: frailty totals match expected (42/126/82) ***\n")
} else {
  message("\n*** WARNING: frailty totals DO NOT match expected ***")
  message("Expected: robust=42, pre-frail=126, frail=82")
  message("Observed: robust=", n_robust, ", pre-frail=", n_prefrail, ", frail=", n_frail)
  message("N_missing frailty_cat_3 (in full data): ", N_frailty_missing, "\n")
}

# Optional cross-tab: frailty_cat_3 x FOF_status (counts) - NOT stratification
message("=== Cross-tabulation: frailty_cat_3 x FOF_status (counts) ===")
crosstab_frailty_FOF <- table(
  Frailty = table1_sample$frailty_cat_3,
  FOF     = table1_sample$FOF_status,
  useNA   = "ifany"
)
print(crosstab_frailty_FOF)
message("")

# ==============================================================================
# 06. Table helpers (K17 style; generalized to 3 groups)
# ==============================================================================

format_pvalue <- function(p) {
  if (is.null(p) || is.na(p)) return("")
  if (p < 0.001) "<0.001" else sprintf("%.3f", p)
}

format_mean_sd <- function(x, group, digits = 1) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])

  if (length(x_use) == 0L) {
    return(setNames(rep("", length(levels(group))), levels(group)))
  }

  out <- setNames(character(length(levels(g_use))), levels(g_use))
  for (lvl in levels(g_use)) {
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

# Continuous p-value: one-way ANOVA (aov); NA on error/insufficient groups
fun_pvalue_cont <- function(x, group) {
  idx <- !is.na(x) & !is.na(group)
  x_use <- x[idx]
  g_use <- droplevels(group[idx])

  if (length(unique(g_use)) < 2L) return(NA_real_)

  p <- tryCatch(
    {
      fit <- stats::aov(x_use ~ g_use)
      stats::anova(fit)[["Pr(>F)"]][1]
    },
    error = function(e) NA_real_
  )
  p
}

# Categorical p-value: chi-square (no Yates), fallback to Fisher if expected<5 or error
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
      p <- tryCatch(stats::fisher.test(tab)$p.value, error = function(e) NA_real_)
    } else {
      p <- chi_res$p.value
    }
  } else {
    p <- tryCatch(stats::fisher.test(tab)$p.value, error = function(e) NA_real_)
  }
  p
}

# Level-specific p-value for multi-category: group x indicator(level)
fun_pvalue_cat_level <- function(factor_var, group, level_value) {
  idx <- !is.na(factor_var) & !is.na(group)
  f_use <- droplevels(factor_var[idx])
  g_use <- droplevels(group[idx])

  if (length(unique(g_use)) < 2L) return(NA_real_)

  ind <- as.integer(f_use == level_value)
  fun_pvalue_cat(ind, g_use)
}

make_binary_row <- function(data, var_name, row_label, group_var = "frailty_cat_3", event = 1L) {
  g <- data[[group_var]]
  x <- data[[var_name]]
  vals <- format_n_pct(x, g, event = event)
  p <- fun_pvalue_cat(x, g)

  group_levels <- levels(droplevels(g[!is.na(g)]))
  row_list <- c(
    list(Variable = paste0("  ", row_label)),
    as.list(vals[group_levels]),
    list(P_value = format_pvalue(p))
  )
  tibble::as_tibble(row_list)
}

make_multicat_rows_with_level_p <- function(data, var_name, header_label, group_var = "frailty_cat_3") {
  g <- data[[group_var]]
  f <- data[[var_name]]

  # Overall p-value on header row
  p_overall <- fun_pvalue_cat(f, g)

  group_levels <- levels(droplevels(g[!is.na(g)]))

  # Header row: empty group cells + p-value
  header_list <- c(
    list(Variable = header_label),
    setNames(as.list(rep("", length(group_levels))), group_levels),
    list(P_value = format_pvalue(p_overall))
  )
  header_row <- tibble::as_tibble(header_list)

  # Level rows
  f_levels <- levels(droplevels(f[!is.na(f)]))
  if (length(f_levels) == 0L) {
    return(header_row)
  }

  level_rows <- lapply(f_levels, function(lvl) {
    ind <- as.integer(f == lvl)
    vals <- format_n_pct(ind, g, event = 1L)
    p_lvl <- fun_pvalue_cat_level(f, g, lvl)

    row_list <- c(
      list(Variable = paste0("  ", lvl)),
      as.list(vals[group_levels]),
      list(P_value = format_pvalue(p_lvl))
    )
    tibble::as_tibble(row_list)
  })

  dplyr::bind_rows(header_row, dplyr::bind_rows(level_rows))
}

# ==============================================================================
# 07. Build Table 1 (stratified by frailty_cat_3)
# ==============================================================================

group_var <- "frailty_cat_3"
g <- table1_sample[[group_var]]
group_levels <- levels(g)

# Group sizes for column headers
grp_counts <- table1_sample %>% count(.data[[group_var]])
N_robust   <- grp_counts$n[grp_counts[[group_var]] == "robust"]
N_prefrail <- grp_counts$n[grp_counts[[group_var]] == "pre-frail"]
N_frail    <- grp_counts$n[grp_counts[[group_var]] == "frail"]

N_robust   <- ifelse(length(N_robust) == 0, 0L, as.integer(N_robust[1]))
N_prefrail <- ifelse(length(N_prefrail) == 0, 0L, as.integer(N_prefrail[1]))
N_frail    <- ifelse(length(N_frail) == 0, 0L, as.integer(N_frail[1]))

# 7.1 Women, n (%)
vals_women <- format_n_pct(table1_sample$woman, g, event = 1L)
p_women <- fun_pvalue_cat(table1_sample$woman, g)
tab_women <- tibble::tibble(
  Variable = "Women, n (%)",
  `robust` = vals_women["robust"],
  `pre-frail` = vals_women["pre-frail"],
  `frail` = vals_women["frail"],
  P_value = format_pvalue(p_women)
)

# 7.2 Age, mean (SD)
vals_age <- format_mean_sd(table1_sample$age, g, digits = 0)
p_age <- fun_pvalue_cont(table1_sample$age, g)
tab_age <- tibble::tibble(
  Variable = "Age, mean (SD)",
  `robust` = vals_age["robust"],
  `pre-frail` = vals_age["pre-frail"],
  `frail` = vals_age["frail"],
  P_value = format_pvalue(p_age)
)

# 7.3 Diseases header + subrows
any_disease <- with(
  table1_sample,
  (diabetes == 1) | (alzheimer == 1) | (parkinson == 1) | (AVH == 1)
)
vals_any_disease <- format_n_pct(as.integer(any_disease), g, event = 1L)
p_any_disease <- fun_pvalue_cat(as.integer(any_disease), g)

tab_diseases_header <- tibble::tibble(
  Variable = "Diseases, n (%)",
  `robust` = vals_any_disease["robust"],
  `pre-frail` = vals_any_disease["pre-frail"],
  `frail` = vals_any_disease["frail"],
  P_value = format_pvalue(p_any_disease)
)

tab_diabetes <- make_binary_row(table1_sample, "diabetes", "Diabetes", group_var = group_var)
tab_dementia <- make_binary_row(table1_sample, "alzheimer", "Dementia", group_var = group_var)
tab_parkin   <- make_binary_row(table1_sample, "parkinson", "Parkinson's", group_var = group_var)
tab_cva      <- make_binary_row(table1_sample, "AVH", "Cerebrovascular Accidents", group_var = group_var)
tab_comorb   <- make_binary_row(table1_sample, "comorbidity", "Comorbidity (>1 disease)", group_var = group_var)

tab_diseases <- dplyr::bind_rows(
  tab_diseases_header,
  tab_diabetes,
  tab_dementia,
  tab_parkin,
  tab_cva,
  tab_comorb
)

# 7.4 Self-rated Health, n (%)
tab_SRH <- make_multicat_rows_with_level_p(
  data = table1_sample,
  var_name = "SRH_3class_table",
  header_label = "Self-rated Health, n (%)",
  group_var = group_var
)

# 7.5 Mikkeli Osteoporosis Index, mean (SD)
vals_MOI <- format_mean_sd(table1_sample$MOIindeksiindeksi, g, digits = 1)
p_MOI <- fun_pvalue_cont(table1_sample$MOIindeksiindeksi, g)
tab_MOI <- tibble::tibble(
  Variable = "Mikkeli Osteoporosis Index, mean (SD)",
  `robust` = vals_MOI["robust"],
  `pre-frail` = vals_MOI["pre-frail"],
  `frail` = vals_MOI["frail"],
  P_value = format_pvalue(p_MOI)
)

# 7.6 BMI, mean (SD)
vals_BMI <- format_mean_sd(table1_sample$BMI, g, digits = 1)
p_BMI <- fun_pvalue_cont(table1_sample$BMI, g)
tab_BMI <- tibble::tibble(
  Variable = "Body Mass Index, mean (SD)",
  `robust` = vals_BMI["robust"],
  `pre-frail` = vals_BMI["pre-frail"],
  `frail` = vals_BMI["frail"],
  P_value = format_pvalue(p_BMI)
)

# 7.7 Smoked, n (%)
vals_smoked <- format_n_pct(table1_sample$tupakointi, g, event = 1L)
p_smoked <- fun_pvalue_cat(table1_sample$tupakointi, g)
tab_smoked <- tibble::tibble(
  Variable = "Smoked, n (%)",
  `robust` = vals_smoked["robust"],
  `pre-frail` = vals_smoked["pre-frail"],
  `frail` = vals_smoked["frail"],
  P_value = format_pvalue(p_smoked)
)

# 7.8 Alcohol, n (%)
tab_alcohol <- make_multicat_rows_with_level_p(
  data = table1_sample,
  var_name = "alcohol_3class_table",
  header_label = "Alcohol, n (%)",
  group_var = group_var
)

# 7.9 Self-Rated Mobility, n (%)
tab_SRM <- make_multicat_rows_with_level_p(
  data = table1_sample,
  var_name = "SRM_3class_table",
  header_label = "Self-Rated Mobility, n (%)",
  group_var = group_var
)

# 7.10 Walking 500 m, n (%)
tab_Walk500 <- make_multicat_rows_with_level_p(
  data = table1_sample,
  var_name = "Walk500m_3class_table",
  header_label = "Walking 500 m, n (%)",
  group_var = group_var
)

# 7.11 Balance difficulties, n (%)
vals_balance <- format_n_pct(table1_sample$tasapainovaikeus, g, event = 1L)
p_balance <- fun_pvalue_cat(table1_sample$tasapainovaikeus, g)
tab_balance <- tibble::tibble(
  Variable = "Balance difficulties, n (%)",
  `robust` = vals_balance["robust"],
  `pre-frail` = vals_balance["pre-frail"],
  `frail` = vals_balance["frail"],
  P_value = format_pvalue(p_balance)
)

# 7.12 Fallen, n (%)
vals_fallen <- format_n_pct(table1_sample$kaatuminen, g, event = 1L)
p_fallen <- fun_pvalue_cat(table1_sample$kaatuminen, g)
tab_fallen <- tibble::tibble(
  Variable = "Fallen, n (%)",
  `robust` = vals_fallen["robust"],
  `pre-frail` = vals_fallen["pre-frail"],
  `frail` = vals_fallen["frail"],
  P_value = format_pvalue(p_fallen)
)

# 7.13 Fractures, n (%)
vals_fract <- format_n_pct(table1_sample$murtumia, g, event = 1L)
p_fract <- fun_pvalue_cat(table1_sample$murtumia, g)
tab_fractures <- tibble::tibble(
  Variable = "Fractures, n (%)",
  `robust` = vals_fract["robust"],
  `pre-frail` = vals_fract["pre-frail"],
  `frail` = vals_fract["frail"],
  P_value = format_pvalue(p_fract)
)

# 7.14 Pain VAS, mean (SD)
vals_pain <- format_mean_sd(table1_sample$PainVAS0, g, digits = 1)
p_pain <- fun_pvalue_cont(table1_sample$PainVAS0, g)
tab_pain <- tibble::tibble(
  Variable = "Pain (Visual Analog Scale), mm, mean (SD)",
  `robust` = vals_pain["robust"],
  `pre-frail` = vals_pain["pre-frail"],
  `frail` = vals_pain["frail"],
  P_value = format_pvalue(p_pain)
)

# Bind rows in K17 order (no extra invented rows)
baseline_table_raw <- dplyr::bind_rows(
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
  tab_pain
)

# ==============================================================================
# 08. Final column names + footnote
# ==============================================================================

col_robust   <- paste0("Robust\nn=", N_robust)
col_prefrail <- paste0("Pre-frail\nn=", N_prefrail)
col_frail    <- paste0("Frail\nn=", N_frail)

baseline_table <- baseline_table_raw %>%
  rename(
    " " = Variable,
    !!col_robust := `robust`,
    !!col_prefrail := `pre-frail`,
    !!col_frail := `frail`,
    "P-value" = P_value
  )

table_footnote <- paste(
  "Abbreviations: BMI = Body Mass Index; SD = Standard Deviation; VAS = Visual Analog Scale.",
  "Frailty: Fried-inspired 3-component proxy (weakness + slowness + low activity).",
  "Weakness: sex-specific lowest quartile of grip strength (Puristus0; 0 treated as missing).",
  "Slowness: baseline gait speed <0.8 m/s (0 treated as slowness).",
  "Low activity: weak self-rated mobility (oma_arvio_liikuntakyky==0) and/or walking limitation (500 m/2 km) and/or max walking distance <400 m (if any info available).",
  "P-values: one-way ANOVA for continuous variables; chi-square tests for categorical variables (Fisher's exact used when expected counts <5 or chi-square fails).",
  sep = " "
)
attr(baseline_table, "footnote") <- table_footnote

# ==============================================================================
# 09. Print, Save, Manifest
# ==============================================================================

print(baseline_table)

basename_out <- "K27_baseline_by_frailty"
save_table_csv_html(baseline_table, basename_out, n = N_total)

message("K27: baseline table by frailty_cat_3 tallennettu ja manifest päivitetty.")

save_sessioninfo_manifest()

# End of K27.R 
