#!/usr/bin/env Rscript
# ==============================================================================
# K16 - Frailty model comparison (variant V2)
# File tag: K16.V2_model_compare.R
# Purpose: Compare baseline 3-component frailty model to top component combos
#          from K15.V2 using ANCOVA (12-month change).
#
# Outcome: Delta_Composite_Z (12-month change)
# Predictors: FOF_status, frailty_score (combo-specific)
# Moderator/interaction: None (main-effects comparison)
# Grouping variable: ID
# Covariates: Composite_Z0, age, sex, BMI
#
# Required vars (analysis_data; must match req_cols check in code):
# - Wide data: ID, FOF_status, Composite_Z0, Composite_Z12, Delta_Composite_Z,
#              age, sex, BMI, frailty_weakness, frailty_slowness,
#              frailty_low_activity, frailty_low_BMI
# - Long data: ID, FOF_status, Composite_Z, time/time_f,
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
# - script_label: K16 (canonical)
# - outputs dir: R-scripts/K16/outputs/K16_V2_model_compare/ (subdir via init_paths)
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load K15 frailty-augmented data (or run K15.R)
# 03) Harmonize key vars (ID, Composite_Z0/Z12, age/sex/BMI)
# 04) Detect wide vs long and validate required columns
# 05) QC: FOF_status, delta check, missingness by FOF group, outlier flags (aggregate)
# 05) Load K15.V2 ranking table and select top combos
# 06) Fit ANCOVA models for baseline vs top combos
# 07) Save model comparison table + report text
# 08) Append manifest row per artifact
# 09) Save sessionInfo to manifest/
# 10) EOF marker
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
  "K16"
}

script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K16"

source(here("R", "functions", "init.R"))
source(here("R", "functions", "io.R"))
source(here("R", "functions", "checks.R"))
source(here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir   <- file.path(getOption("fof.outputs_dir"), "K16_V2_model_compare")
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
    message("K16.V2: K15 RData missing; running K15.R to generate it.")
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

is_long <- anyDuplicated(analysis_data$ID) > 0 ||
  ("time" %in% names(analysis_data)) || ("time_f" %in% names(analysis_data))

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

if (any(!analysis_data$FOF_status %in% c(0, 1, NA))) {
  stop("FOF_status contains values outside {0,1,NA}.")
}

# ==============================================================================
# 04. QC summaries (aggregate only)
# ==============================================================================
qc_missing_by_group <- analysis_data %>%
  mutate(FOF_group = factor(FOF_status, levels = c(0, 1), labels = c("nonFOF", "FOF"))) %>%
  group_by(FOF_group) %>%
  summarise(
    n = n(),
    across(
      all_of(c(
        if (is_long) "Composite_Z" else c("Composite_Z0", "Composite_Z12"),
        "frailty_weakness", "frailty_slowness",
        "frailty_low_activity", "frailty_low_BMI"
      )),
      ~ sum(is.na(.)),
      .names = "missing_{.col}"
    ),
    .groups = "drop"
  )

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
# 05. Load K15.V2 ranking and select top combos
# ==============================================================================
ranking_path <- here::here("R-scripts", "K15", "outputs",
                           "K15_V2_frailty_search", "frailty_combo_ranking.csv")
if (!file.exists(ranking_path)) {
  stop("K15.V2 ranking not found. Run K15.V2_frailty_search first.")
}

ranking_tbl <- readr::read_csv(ranking_path, show_col_types = FALSE)
ranking_tbl <- ranking_tbl %>% arrange(aic)

top_n <- 5L
top_tbl <- ranking_tbl %>% slice_head(n = top_n)

parse_components <- function(x) {
  trimws(unlist(strsplit(x, ";")))
}

combo_list <- lapply(top_tbl$components, parse_components)
names(combo_list) <- top_tbl$combo

baseline_cols <- c("frailty_weakness", "frailty_slowness", "frailty_low_activity")
combo_list <- c(list(baseline_3_component = baseline_cols), combo_list)

# ==============================================================================
# 06. Fit ANCOVA models
# ==============================================================================
fit_combo_model <- function(df, cols) {
  score <- rowSums(df[, cols], na.rm = FALSE)

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

model_results <- lapply(names(combo_list), function(label) {
  cols <- combo_list[[label]]
  res <- fit_combo_model(analysis_data, cols)
  tibble::tibble(
    combo = label,
    components = paste(cols, collapse = ";"),
    n_complete = res$n,
    aic = res$aic,
    bic = res$bic,
    r2 = res$r2
  )
})

compare_tbl <- dplyr::bind_rows(model_results) %>%
  arrange(aic)

baseline_aic <- compare_tbl %>%
  filter(combo == "baseline_3_component") %>%
  pull(aic)
if (length(baseline_aic) != 1) baseline_aic <- NA_real_

compare_tbl <- compare_tbl %>%
  mutate(delta_aic_vs_baseline = aic - baseline_aic)

# ==============================================================================
# 07. Save outputs + manifest
# ==============================================================================
compare_path <- file.path(outputs_dir, "model_compare_table.csv")
save_table_csv(compare_tbl, compare_path)
append_manifest(
  manifest_row(script = script_label, label = "model_compare_table",
               path = get_relpath(compare_path), kind = "table_csv", n = nrow(compare_tbl)),
  manifest_path
)

qc_missing_path <- file.path(outputs_dir, "model_compare_qc_missing_by_group.csv")
save_table_csv(qc_missing_by_group, qc_missing_path)
append_manifest(
  manifest_row(script = script_label, label = "model_compare_qc_missing_by_group",
               path = get_relpath(qc_missing_path), kind = "table_csv", n = nrow(qc_missing_by_group)),
  manifest_path
)

qc_outliers_path <- file.path(outputs_dir, "model_compare_qc_outliers.csv")
save_table_csv(qc_outliers, qc_outliers_path)
append_manifest(
  manifest_row(script = script_label, label = "model_compare_qc_outliers",
               path = get_relpath(qc_outliers_path), kind = "table_csv", n = nrow(qc_outliers)),
  manifest_path
)

best_row <- compare_tbl %>% slice_head(n = 1)
report_lines <- c(
  "# K16.V2 model comparison summary",
  "",
  paste0("Baseline combo: baseline_3_component (", paste(baseline_cols, collapse = ";"), ")"),
  paste0("Best AIC combo: ", best_row$combo[[1]]),
  paste0("Best AIC delta vs baseline: ",
         sprintf("%.2f", best_row$delta_aic_vs_baseline[[1]]))
)

report_path <- file.path(outputs_dir, "model_compare_report.md")
writeLines(report_lines, con = report_path)
append_manifest(
  manifest_row(script = script_label, label = "model_compare_report",
               path = get_relpath(report_path), kind = "text"),
  manifest_path
)

save_sessioninfo_manifest(outputs_dir = outputs_dir,
                          manifest_path = manifest_path,
                          script = script_label)

message("K16.V2 model comparison complete. Outputs: ", outputs_dir)
