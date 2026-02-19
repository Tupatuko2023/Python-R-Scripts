#!/usr/bin/env Rscript
# ==============================================================================
# K15 - Frailty component search (variant V2)
# File tag: K15.V2_frailty_search.R
# Purpose: Evaluate frailty component combinations derived by K15 and rank them
#          by predictive performance for 12-month change.
#
# Outcome: Delta_Composite_Z (12-month change)
# Predictors: FOF_status, frailty_score (combo-specific)
# Moderator/interaction: None (main-effects comparison)
# Grouping variable: ID
# Covariates: Composite_Z0, age, sex, BMI
#
# Required vars (analysis_data; must match required checks in code):
# - Wide data: ID, FOF_status, Composite_Z0, Composite_Z12, Delta_Composite_Z,
#              age, sex, BMI, frailty_weakness, frailty_slowness,
#              frailty_low_activity, frailty_low_BMI
# - Long data: ID, FOF_status, Composite_Z, and at least one of time/time_f,
#              age, sex, BMI, frailty_weakness, frailty_slowness,
#              frailty_low_activity, frailty_low_BMI
#
# Mapping (K15 output -> analysis; keep minimal + explicit):
# Jnro/NRO -> ID (if ID missing)
# ToimintaKykySummary0 -> Composite_Z0 (if Composite_Z0 missing)
# ToimintaKykySummary2 -> Composite_Z12 (if Composite_Z12 missing)
# Delta_Composite_Z = Composite_Z12 - Composite_Z0
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (set for reproducibility; no randomness used)
#
# Outputs + manifest:
# - script_label: K15 (canonical)
# - outputs dir: R-scripts/K15/outputs/K15_V2_frailty_search/ (subdir via init_paths)
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load K15 frailty-augmented data (or run K15.R)
# 03) Harmonize key vars (ID, Composite_Z0/Z12, age/sex/BMI)
# 04) Detect wide vs long and validate required columns
# 05) QC: FOF_status, delta check, missingness by FOF group, outlier flags (aggregate)
# 05) Define component combinations (>=3 components)
# 06) Fit ANCOVA (wide) or LMM (long) per combo
# 07) Rank combos by AIC/BIC (+ R2)
# 08) Save ranking table + QC summary
# 09) Append manifest row per artifact
# 10) Save sessionInfo to manifest/
# 11) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(tibble)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K15"
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K15"

source(here("R", "functions", "init.R"))
source(here("R", "functions", "io.R"))
source(here("R", "functions", "checks.R"))
source(here("R", "functions", "reporting.R"))
source(here("R", "functions", "v2_helpers.R"))

paths <- init_paths(script_label)
outputs_dir   <- file.path(getOption("fof.outputs_dir"), "K15_V2_frailty_search")
manifest_path <- getOption("fof.manifest_path")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)

set.seed(20251124)

# ==============================================================================
# 01. Load K15 analysis_data
# ==============================================================================
k15_rdata <- here::here("R-scripts", "K15", "outputs", "K15_frailty_analysis_data.RData")
if (!exists("analysis_data")) {
  if (file.exists(k15_rdata)) {
    load(k15_rdata)
  } else {
    message("K15.V2: K15 RData missing; running K15.R to generate it.")
    source(here::here("R-scripts", "K15", "K15.R"))
  }
}

if (!exists("analysis_data")) {
  stop("analysis_data not found after loading K15 output.")
}

# ==============================================================================
# 02. Harmonize key variables
# ==============================================================================
if (!("ID" %in% names(analysis_data))) {
  if ("Jnro" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(ID = Jnro)
  } else if ("NRO" %in% names(analysis_data)) {
    analysis_data <- analysis_data %>% mutate(ID = NRO)
  } else {
    stop("ID missing and no Jnro/NRO fallback found.")
  }
}

is_long <- detect_is_long(analysis_data)

if (!is_long) {
  if (!("Composite_Z0" %in% names(analysis_data))) {
    if ("ToimintaKykySummary0" %in% names(analysis_data)) {
      analysis_data <- analysis_data %>% mutate(Composite_Z0 = ToimintaKykySummary0)
    } else {
      stop("Composite_Z0 missing and ToimintaKykySummary0 not found.")
    }
  }

  if (!("Composite_Z12" %in% names(analysis_data))) {
    if ("ToimintaKykySummary2" %in% names(analysis_data)) {
      analysis_data <- analysis_data %>% mutate(Composite_Z12 = ToimintaKykySummary2)
    } else {
      stop("Composite_Z12 missing and ToimintaKykySummary2 not found.")
    }
  }
}

if (!("age" %in% names(analysis_data)) && ("Age" %in% names(analysis_data))) {
  analysis_data <- analysis_data %>% mutate(age = Age)
}
if (!("sex" %in% names(analysis_data)) && ("Sex" %in% names(analysis_data))) {
  analysis_data <- analysis_data %>% mutate(sex = Sex)
}
if (!("BMI" %in% names(analysis_data)) && ("bmi" %in% names(analysis_data))) {
  analysis_data <- analysis_data %>% mutate(BMI = bmi)
}

if ("Composite_Z0" %in% names(analysis_data) && "Composite_Z12" %in% names(analysis_data)) {
  analysis_data <- analysis_data %>%
    mutate(Delta_Composite_Z = Composite_Z12 - Composite_Z0)
} else if (!("Delta_Composite_Z" %in% names(analysis_data))) {
  analysis_data$Delta_Composite_Z <- NA_real_
}

# ==============================================================================
# 03. Required columns check (req_cols parity with header)
# ==============================================================================
req_base <- c("ID", "FOF_status", "age", "sex", "BMI",
              "frailty_weakness", "frailty_slowness",
              "frailty_low_activity", "frailty_low_BMI")

req_wide <- c(req_base, "Composite_Z0", "Composite_Z12", "Delta_Composite_Z")
req_long <- c(req_base, "Composite_Z")

req_cols <- if (is_long) req_long else req_wide
missing_cols <- setdiff(req_cols, names(analysis_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}
if (is_long && !any(c("time", "time_f") %in% names(analysis_data))) {
  stop("Missing required time column for long data: need time or time_f.")
}

if (any(!analysis_data$FOF_status %in% c(0, 1, NA))) {
  stop("FOF_status contains values outside {0,1,NA}.")
}

# ==============================================================================
# 04. QC summaries (aggregate only)
# ==============================================================================
qc_metrics <- c(
  if (is_long) "Composite_Z" else c("Composite_Z0", "Composite_Z12"),
  "frailty_weakness", "frailty_slowness",
  "frailty_low_activity", "frailty_low_BMI"
)
qc_missing_by_group <- v2_qc_missing_by_group(analysis_data,
                                              group_col = "FOF_status",
                                              metrics = qc_metrics)

flag_outliers <- function(x, sd_cut = 4) {
  if (!is.numeric(x)) return(NA_integer_)
  mu <- mean(x, na.rm = TRUE)
  sig <- stats::sd(x, na.rm = TRUE)
  if (is.na(sig) || sig == 0) return(0L)
  sum(abs(x - mu) > sd_cut * sig, na.rm = TRUE)
}

qc_outliers <- if (is_long) {
  tibble::tibble(
    metric = "Composite_Z",
    outlier_count = flag_outliers(analysis_data$Composite_Z)
  )
} else {
  tibble::tibble(
    metric = c("Composite_Z0", "Composite_Z12"),
    outlier_count = c(
      flag_outliers(analysis_data$Composite_Z0),
      flag_outliers(analysis_data$Composite_Z12)
    )
  )
}

# ==============================================================================
# 05. Frailty component combinations
# ==============================================================================
component_cols <- c(
  "frailty_weakness",
  "frailty_slowness",
  "frailty_low_activity",
  "frailty_low_BMI"
)

combo_sizes <- c(3, 4)
combo_list <- list()
for (k in combo_sizes) {
  combo_list <- c(combo_list, combn(component_cols, k, simplify = FALSE))
}

combo_label <- function(cols) paste(cols, collapse = "+")

# Baseline 3-component definition (current K15 default)
baseline_cols <- c("frailty_weakness", "frailty_slowness", "frailty_low_activity")

fit_combo_model <- function(df, cols) {
  if (!all(cols %in% names(df))) {
    missing <- setdiff(cols, names(df))
    stop("Missing frailty component columns: ", paste(missing, collapse = ", "))
  }
  score <- df %>%
    dplyr::select(dplyr::all_of(cols)) %>%
    as.matrix() %>%
    rowSums(na.rm = FALSE)

  if (is_long) {
    if ("time_f" %in% names(df)) {
      df <- df %>% mutate(time_f = time_f)
    } else if ("time" %in% names(df)) {
      df <- df %>% mutate(time_f = factor(time))
    } else {
      stop("Long-format data detected but no time/time_f column found.")
    }

    model_df <- df %>%
      mutate(frailty_score = score) %>%
      select(Composite_Z, time_f, FOF_status, age, sex, BMI, frailty_score, ID) %>%
      filter(stats::complete.cases(.))

    if (nrow(model_df) < 20) {
      return(list(n = nrow(model_df), aic = NA_real_, bic = NA_real_, r2 = NA_real_))
    }

    if (!requireNamespace("lme4", quietly = TRUE)) {
      stop("Package 'lme4' is required for long-format models.")
    }
    fit <- lme4::lmer(
      Composite_Z ~ time_f + FOF_status + age + sex + BMI + frailty_score + (1 | ID),
      data = model_df
    )

    r2_val <- NA_real_
    if (requireNamespace("performance", quietly = TRUE)) {
      r2_val <- performance::r2_nakagawa(fit)$R2_marginal
    }

    list(
      n = nrow(model_df),
      aic = stats::AIC(fit),
      bic = stats::BIC(fit),
      r2 = r2_val
    )
  } else {
    model_df <- df %>%
      mutate(frailty_score = score) %>%
      select(Delta_Composite_Z, Composite_Z0, FOF_status, age, sex, BMI, frailty_score) %>%
      filter(stats::complete.cases(.))

    if (nrow(model_df) < 20) {
      return(list(n = nrow(model_df), aic = NA_real_, bic = NA_real_, r2 = NA_real_))
    }

    fit <- stats::lm(
      Delta_Composite_Z ~ Composite_Z0 + FOF_status + age + sex + BMI + frailty_score,
      data = model_df
    )

    list(
      n = nrow(model_df),
      aic = stats::AIC(fit),
      bic = stats::BIC(fit),
      r2 = summary(fit)$r.squared
    )
  }
}

combo_results <- lapply(combo_list, function(cols) {
  res <- fit_combo_model(analysis_data, cols)
  score <- analysis_data %>%
    dplyr::select(dplyr::all_of(cols)) %>%
    as.matrix() %>%
    rowSums(na.rm = FALSE)
  cor_delta_val <- if (is_long) NA_real_ else {
    stats::cor(score, analysis_data$Delta_Composite_Z, use = "complete.obs")
  }
  cor_baseline_val <- if (is_long) NA_real_ else {
    stats::cor(score, analysis_data$Composite_Z0, use = "complete.obs")
  }
  tibble::tibble(
    combo = combo_label(cols),
    components = paste(cols, collapse = ";"),
    n_complete = res$n,
    missing_pct = mean(is.na(score)) * 100,
    aic = res$aic,
    bic = res$bic,
    r2 = res$r2,
    cor_delta = cor_delta_val,
    cor_baseline = cor_baseline_val
  )
})

ranking_tbl <- dplyr::bind_rows(combo_results) %>%
  arrange(aic)

baseline_row <- ranking_tbl %>% filter(combo == combo_label(baseline_cols))
baseline_aic <- if (nrow(baseline_row) == 1) baseline_row$aic[[1]] else NA_real_

ranking_tbl <- ranking_tbl %>%
  mutate(delta_aic_vs_baseline = aic - baseline_aic)

# ==============================================================================
# 06. Save outputs + manifest
# ==============================================================================
ranking_path <- file.path(outputs_dir, "frailty_combo_ranking.csv")
save_table_csv(ranking_tbl, ranking_path)
append_manifest(
  manifest_row(script = script_label, label = "frailty_combo_ranking",
               path = get_relpath(ranking_path), kind = "table_csv", n = nrow(ranking_tbl)),
  manifest_path
)

qc_missing_path <- file.path(outputs_dir, "frailty_combo_qc_missing_by_group.csv")
save_table_csv(qc_missing_by_group, qc_missing_path)
append_manifest(
  manifest_row(script = script_label, label = "frailty_combo_qc_missing_by_group",
               path = get_relpath(qc_missing_path), kind = "table_csv", n = nrow(qc_missing_by_group)),
  manifest_path
)

qc_outliers_path <- file.path(outputs_dir, "frailty_combo_qc_outliers.csv")
save_table_csv(qc_outliers, qc_outliers_path)
append_manifest(
  manifest_row(script = script_label, label = "frailty_combo_qc_outliers",
               path = get_relpath(qc_outliers_path), kind = "table_csv", n = nrow(qc_outliers)),
  manifest_path
)

summary_txt <- c(
  "K15.V2 frailty combo search summary",
  paste0("Combos evaluated: ", nrow(ranking_tbl)),
  paste0("Baseline combo: ", combo_label(baseline_cols)),
  paste0("Best AIC combo: ", ranking_tbl$combo[[1]]),
  paste0("Best AIC (delta vs baseline): ",
         sprintf("%.2f", ranking_tbl$delta_aic_vs_baseline[[1]]))
)

summary_path <- file.path(outputs_dir, "frailty_combo_summary.txt")
writeLines(summary_txt, con = summary_path)
append_manifest(
  manifest_row(script = script_label, label = "frailty_combo_summary",
               path = get_relpath(summary_path), kind = "text"),
  manifest_path
)

save_sessioninfo_manifest(outputs_dir = outputs_dir,
                          manifest_path = manifest_path,
                          script = script_label)

message("K15.V2 frailty combo search complete. Outputs: ", outputs_dir)
