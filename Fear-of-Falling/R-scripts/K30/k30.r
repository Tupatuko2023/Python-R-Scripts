#!/usr/bin/env Rscript
# ==============================================================================
# K30_CAPACITY - Continuous Physical Capability / Locomotor Capacity Score
# File: k30.r
#
# Purpose
# - Implement a continuous physical capability (locomotor capacity) score from
#   KaatumisenPelko.csv using baseline indicators:
#     * Handgrip strength (puristus0_clean)
#     * Gait speed (kavelynopeus_m_sek0)
#     * Self-report mobility/physical function item (oma_arvio_liikuntakyky)
# - Primary scoring: defensible z-score composite (mean of z-indicators with NA handling).
# - Sensitivity scoring: 1-factor CFA (lavaan WLSMV) with ordered indicator.
# - Sensitivity: handle gait speed == 0 in two ways:
#     (A) Primary: treat 0 as missing (conservative non-performance assumption)
#     (B) Sensitivity: retain 0 as valid extreme
#
# How to run
# - Preferred (repo-relative search): /usr/bin/Rscript R-scripts/K30/k30.r
# - If input file is not found, set:
#     DATA_PATH=/path/to/KaatumisenPelko.csv /usr/bin/Rscript R-scripts/K30/k30.r
#
# Inputs
# - KaatumisenPelko.csv (read-only; do not edit raw data)
#
# Outputs (written under R-scripts/K30/outputs/; one manifest row per artifact)
# - Audit tables: missingness/descriptives, frequencies, correlations, red flags
# - Decision log
# - CFA summaries + standardized loadings (primary + sensitivity) + diagnostics table
# - Score summaries (primary composite + sensitivity composite + CFA sensitivity scores)
# - Analysis-ready dataset with appended variables (.csv + .rds)
# - Session info log
#
# Required Vars (post-janitor clean_names; do not invent)
# - puristus0_clean
# - kavelynopeus_m_sek0
# - oma_arvio_liikuntakyky
#
# Notes on estimator / identification
# - With 3 indicators and 1 factor, the CFA is effectively just-identified.
#   Do NOT overemphasize global fit indices; focus on loadings, residual
#   variances, warnings/convergence, and factor-score face validity.
#
# References
# - Frailty Model Copilot plan (authoritative scoring + red flags).
# ==============================================================================
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
  library(tibble)
  library(purrr)
  library(janitor)
  library(here)
  library(lavaan)
})

# --- Standard init (MANDATORY; align to CLAUDE.md) -----------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.[Rr]$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K30" # interactive fallback
}

# Canonical script label: force Kxx style even if filename is lowercase
script_label_raw <- sub("\\..*$", "", sub("\\.V.*$", "", script_base))
script_label <- toupper(script_label_raw)
if (is.na(script_label) || script_label == "") script_label <- "K30"

# Project helpers (paths + manifest append)
source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

# --- Small manual mapping block (edit only if needed) -------------------------
# Named character vector: names are target vars; values are actual df columns.
# Leave NA to auto-detect using closest-match suggestions.
manual_map <- c(
  puristus0_clean = "puristus0",
  kavelynopeus_m_sek0 = NA_character_,
  oma_arvio_liikuntakyky = NA_character_
)

# --- Config ------------------------------------------------------------------
GRIP_VERY_HIGH_KG <- 80

# --- Helpers -----------------------------------------------------------------
dir_create <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

write_lines_safely <- function(lines, path) {
  dir_create(dirname(path))
  writeLines(lines, con = path, useBytes = TRUE)
  path
}

write_csv_safely <- function(df, path) {
  dir_create(dirname(path))
  readr::write_csv(df, file = path, na = "")
  path
}

write_rds_safely <- function(obj, path) {
  dir_create(dirname(path))
  saveRDS(obj, file = path)
  path
}

resolve_data_root <- function() {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(data_root)) {
    stop(
      paste0(
        "DATA_ROOT is not set. Refusing to write patient-level outputs into repo.\n",
        "Set config/.env with: export DATA_ROOT=/absolute/path/to/local_data\n",
        "Run via runner that sources config/.env, e.g.:\n",
        "  bash scripts/termux/run_k30_proot.sh"
      ),
      call. = FALSE
    )
  }
  normalizePath(data_root, winslash = "/", mustWork = FALSE)
}

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  # Uses project helper append_manifest() from reporting.R
  n_chr <- if (is.na(n)) NA_character_ else as.character(n)
  append_manifest(
    manifest_row(
      script = script_label,
      label = label,
      path = get_relpath(path),
      kind = kind,
      n = n_chr,
      notes = notes
    ),
    manifest_path
  )
  invisible(TRUE)
}

find_data_file <- function(filename = "KaatumisenPelko.csv") {
  # Prefer repo-relative conventions; allow override via DATA_PATH env var.
  env_path <- Sys.getenv("DATA_PATH", unset = "")
  if (nzchar(env_path)) {
    if (!file.exists(env_path)) {
      stop("DATA_PATH is set but file does not exist: ", env_path,
           "\nSet DATA_PATH to a valid path to KaatumisenPelko.csv")
    }
    return(normalizePath(env_path))
  }

  candidates <- c(
    here::here("data", "raw", filename),
    here::here("data", "external", filename),
    here::here("data", filename),
    here::here("dataset", filename),
    here::here(filename)
  )
  hit <- candidates[file.exists(candidates)][1]
  if (is.na(hit) || !nzchar(hit)) {
    msg <- paste0(
      "Could not find ", filename, " in repo-relative candidate paths.\n",
      "Tried:\n- ", paste(candidates, collapse = "\n- "), "\n\n",
      "Fix: set DATA_PATH to the file location, e.g.:\n",
      "  DATA_PATH=/full/path/to/", filename, " /usr/bin/Rscript R-scripts/K30/k30.r\n"
    )
    stop(msg, call. = FALSE)
  }
  normalizePath(hit)
}

closest_match <- function(target, choices) {
  # base R edit distance
  d <- adist(target, choices, ignore.case = TRUE)
  choices[order(d)][1:min(5, length(choices))]
}

resolve_mapping <- function(df_names, manual_map) {
  target_vars <- names(manual_map)
  resolved <- manual_map

  for (tv in target_vars) {
    if (!is.na(resolved[[tv]]) && nzchar(resolved[[tv]])) next

    if (tv %in% df_names) {
      resolved[[tv]] <- tv
    } else {
      # try heuristic match by partial string
      hits <- df_names[str_detect(df_names, fixed(tv, ignore_case = TRUE))]
      if (length(hits) == 1) resolved[[tv]] <- hits[1]
    }
  }

  unresolved <- target_vars[is.na(resolved) | !nzchar(resolved)]
  list(resolved = resolved, unresolved = unresolved)
}

audit_cont <- function(x) {
  tibble(
    n = length(x),
    n_miss = sum(is.na(x)),
    p_miss = mean(is.na(x)),
    mean = mean(x, na.rm = TRUE),
    sd = sd(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE),
    p01 = as.numeric(quantile(x, 0.01, na.rm = TRUE, names = FALSE)),
    p99 = as.numeric(quantile(x, 0.99, na.rm = TRUE, names = FALSE)),
    min = suppressWarnings(min(x, na.rm = TRUE)),
    max = suppressWarnings(max(x, na.rm = TRUE))
  )
}

audit_cat <- function(x) {
  tab <- table(x, useNA = "ifany")
  prop <- prop.table(tab)
  tibble(
    level = names(tab),
    n = as.integer(tab),
    p = as.numeric(prop)
  ) %>%
    arrange(desc(n)) %>%
    mutate(flag_rare = p < 0.05)
}

na_row_mean <- function(mat) {
  # rowMeans but return NA if all components are NA
  nonmiss <- rowSums(!is.na(mat))
  out <- rowMeans(mat, na.rm = TRUE)
  out[nonmiss == 0] <- NA_real_
  out
}

safe_cor <- function(x, y, method = "spearman") {
  ok <- complete.cases(x, y)
  if (sum(ok) < 3) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok], method = method))
}

fit_capacity_cfa <- function(df_in, ordered_var = "hyva_liikuntakyky") {
  model_cfa <- "
    Capacity =~ puristus0_clean + kavely + hyva_liikuntakyky
  "

  # use renamed columns inside
  df_model <- df_in %>%
    transmute(
      puristus0_clean = as.numeric(puristus0_clean),
      kavely = as.numeric(kavely),
      hyva_liikuntakyky = hyva_liikuntakyky
    )

  cfa_warnings <- character(0)
  fit <- withCallingHandlers(
    tryCatch(
      lavaan::cfa(
        model = model_cfa,
        data = df_model,
        estimator = "WLSMV",
        ordered = ordered_var,
        missing = "pairwise"
      ),
      error = function(e) e
    ),
    warning = function(w) {
      cfa_warnings <<- c(cfa_warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  if (inherits(fit, "error")) {
    return(list(
      fit = NULL,
      score = rep(NA_real_, nrow(df_model)),
      diagnostics = tibble(
        cfa_ok = FALSE,
        has_neg_resid_var = NA,
        has_std_loading_gt1 = NA,
        score_na_share = 1,
        warning_count = length(cfa_warnings),
        warnings = paste(cfa_warnings, collapse = " | "),
        error = conditionMessage(fit)
      )
    ))
  }

  fs <- tryCatch(
    lavaan::lavPredict(fit, method = "EBM"),
    error = function(e) NULL
  )
  score <- if (is.null(fs)) rep(NA_real_, nrow(df_model)) else as.numeric(fs[, 1])

  pe <- parameterEstimates(fit, standardized = TRUE) %>% as_tibble()
  resid_vars <- pe %>%
    filter(op == "~~", lhs == rhs, lhs %in% c("puristus0_clean", "kavely", "hyva_liikuntakyky"))
  loadings <- pe %>% filter(op == "=~")

  has_neg_resid_var <- any(resid_vars$est < 0, na.rm = TRUE)
  has_std_loading_gt1 <- any(abs(loadings$std.all) > 1, na.rm = TRUE)
  score_na_share <- mean(is.na(score))

  list(
    fit = fit,
    score = score,
    diagnostics = tibble(
      cfa_ok = !(has_neg_resid_var || has_std_loading_gt1),
      has_neg_resid_var = has_neg_resid_var,
      has_std_loading_gt1 = has_std_loading_gt1,
      score_na_share = score_na_share,
      warning_count = length(cfa_warnings),
      warnings = paste(unique(cfa_warnings), collapse = " | "),
      error = NA_character_
    )
  )
}

save_lavaan_outputs <- function(fit, prefix) {
  sum_path <- file.path(outputs_dir, paste0(prefix, "_summary.txt"))
  load_path <- file.path(outputs_dir, paste0(prefix, "_loadings.csv"))

  if (is.null(fit)) {
    write_lines_safely(c(
      paste0(prefix, " - lavaan CFA (WLSMV)"),
      "Model failed: no fit object available."
    ), sum_path)
    write_csv_safely(tibble(), load_path)
    append_manifest_safe(label = paste0(prefix, "_summary"), kind = "text", path = sum_path)
    append_manifest_safe(label = paste0(prefix, "_loadings"), kind = "table_csv", path = load_path)
    return(invisible(list(summary = sum_path, loadings = load_path)))
  }

  # Summary text (include caveat about just-identified)
  summ_lines <- c(
    paste0(prefix, " - lavaan CFA (WLSMV)"),
    "NOTE: With 3 indicators and 1 factor, the model is effectively just-identified; global fit indices are not used to judge adequacy.",
    "",
    capture.output(summary(fit, standardized = TRUE, fit.measures = TRUE))
  )
  write_lines_safely(summ_lines, sum_path)
  append_manifest_safe(label = paste0(prefix, "_summary"), kind = "text", path = sum_path)

  # Standardized loadings table
  pe <- parameterEstimates(fit, standardized = TRUE) %>%
    as_tibble() %>%
    filter(op %in% c("=~")) %>%
    select(lhs, op, rhs, est, se, z, pvalue, std.all)
  write_csv_safely(pe, load_path)
  append_manifest_safe(label = paste0(prefix, "_loadings"), kind = "table_csv", path = load_path)

  invisible(list(summary = sum_path, loadings = load_path))
}

# --- 1) Load + column discovery ----------------------------------------------
dir_create(outputs_dir)

data_path <- find_data_file("KaatumisenPelko.csv")
df_raw <- readr::read_csv(data_path, show_col_types = FALSE)

df <- df_raw %>% janitor::clean_names()

colnames_path <- file.path(outputs_dir, "k30_columns_after_clean_names.txt")
write_lines_safely(sort(names(df)), colnames_path)
append_manifest_safe(label = "k30_columns_after_clean_names", kind = "text", path = colnames_path)

message("Loaded data: ", basename(data_path), " (rows=", nrow(df), ", cols=", ncol(df), ")")

# --- 2) Variable mapping (robust) --------------------------------------------
res <- resolve_mapping(names(df), manual_map)
map <- res$resolved
unresolved <- res$unresolved

if (length(unresolved) > 0) {
  suggestion_lines <- c("Variable mapping unresolved. Suggestions (closest matches):")
  for (tv in unresolved) {
    suggestion_lines <- c(
      suggestion_lines,
      paste0("- target: ", tv),
      paste0("  closest: ", paste(closest_match(tv, names(df)), collapse = ", "))
    )
  }
  suggestion_lines <- c(
    suggestion_lines,
    "",
    "Fix: edit the manual_map block at the top of this script to map targets to actual column names."
  )
  suggest_path <- file.path(outputs_dir, "k30_mapping_suggestions.txt")
  write_lines_safely(suggestion_lines, suggest_path)
  append_manifest_safe(label = "k30_mapping_suggestions", kind = "text", path = suggest_path)

  stop("Required variables cannot be mapped: ",
       paste(unresolved, collapse = ", "),
       "\nSee mapping suggestions: ", suggest_path, call. = FALSE)
}

# Map into standard working names (exact targets)
ind <- df %>%
  transmute(
    puristus0_clean = .data[[map[["puristus0_clean"]]]],
    kavelynopeus_m_sek0 = .data[[map[["kavelynopeus_m_sek0"]]]],
    oma_arvio_liikuntakyky = .data[[map[["oma_arvio_liikuntakyky"]]]]
  )

# Ensure numeric types for continuous indicators when possible
ind <- ind %>%
  mutate(
    puristus0_clean = suppressWarnings(as.numeric(puristus0_clean)),
    kavelynopeus_m_sek0 = suppressWarnings(as.numeric(kavelynopeus_m_sek0))
  )

# --- 3) Data audit outputs ----------------------------------------------------
audit_cont_tbl <- bind_rows(
  audit_cont(ind$puristus0_clean) %>% mutate(var = "puristus0_clean"),
  audit_cont(ind$kavelynopeus_m_sek0) %>% mutate(var = "kavelynopeus_m_sek0")
) %>% select(var, everything())

cont_path <- file.path(outputs_dir, "k30_audit_continuous.csv")
write_csv_safely(audit_cont_tbl, cont_path)
append_manifest_safe(label = "k30_audit_continuous", kind = "table_csv", path = cont_path, n = nrow(df))

cat_tbl <- audit_cat(ind$oma_arvio_liikuntakyky)
cat_path <- file.path(outputs_dir, "k30_audit_self_report_freq.csv")
write_csv_safely(cat_tbl, cat_path)
append_manifest_safe(label = "k30_audit_self_report_freq", kind = "table_csv", path = cat_path, n = nrow(df))

cor_mat <- cor(ind %>% select(puristus0_clean, kavelynopeus_m_sek0),
               use = "pairwise.complete.obs")
cor_tbl <- as.data.frame(as.table(cor_mat)) %>%
  as_tibble() %>%
  rename(var1 = Var1, var2 = Var2, r = Freq)
cor_path <- file.path(outputs_dir, "k30_audit_correlations.csv")
write_csv_safely(cor_tbl, cor_path)
append_manifest_safe(label = "k30_audit_correlations", kind = "table_csv", path = cor_path, n = nrow(df))

flags <- tibble(
  flag_walkspeed_zero = mean(ind$kavelynopeus_m_sek0 == 0, na.rm = TRUE),
  flag_grip_very_high = mean(ind$puristus0_clean > GRIP_VERY_HIGH_KG, na.rm = TRUE),
  grip_very_high_threshold = GRIP_VERY_HIGH_KG
)
flags_path <- file.path(outputs_dir, "k30_red_flags.csv")
write_csv_safely(flags, flags_path)
append_manifest_safe(label = "k30_red_flags", kind = "table_csv", path = flags_path, n = nrow(df))

# --- 4) Coding decisions (explicit + sensitivity) -----------------------------
# Codebook-driven orientation rule (project standard from K15 docs):
# oma_arvio_liikuntakyky: 0=Weak, 1=Moderate, 2=Good.
# Capacity orientation: higher = better, therefore map {0}->0 and {1,2}->1.
hyva_selected <- case_when(
  is.na(ind$oma_arvio_liikuntakyky) ~ NA_real_,
  ind$oma_arvio_liikuntakyky == 0 ~ 0,
  ind$oma_arvio_liikuntakyky %in% c(1, 2) ~ 1,
  TRUE ~ NA_real_
)

df_scored <- df %>%
  mutate(
    puristus0_clean = ind$puristus0_clean,
    kavelynopeus_m_sek0 = ind$kavelynopeus_m_sek0,
    oma_arvio_liikuntakyky = ind$oma_arvio_liikuntakyky,
    hyva_liikuntakyky = hyva_selected,
    hyva_liikuntakyky = factor(
      hyva_liikuntakyky,
      levels = c(0, 1),
      ordered = TRUE
    ),
    gait_speed_primary = if_else(kavelynopeus_m_sek0 == 0, NA_real_, as.numeric(kavelynopeus_m_sek0)),
    gait_speed_sensitivity = as.numeric(kavelynopeus_m_sek0)
  )

decision_lines <- c(
  "K30 coding decisions / decision log",
  "",
  "Self-report recode: hyva_liikuntakyky (ordered factor 0<1)",
  "- Direction set by codebook-aligned project rule: 0=Weak, 1=Moderate, 2=Good (higher=better).",
  "- Applied mapping for capacity: {0}->0 (limitation), {1,2}->1 (better function).",
  "- NA preserved",
  "",
  "Gait speed zeros:",
  "- Primary: gait_speed_primary sets kavelynopeus_m_sek0 == 0 to NA (conservative non-performance assumption).",
  "- Sensitivity: gait_speed_sensitivity retains 0 as a valid extreme value.",
  "",
  paste0("Grip extreme threshold for red-flag: > ", GRIP_VERY_HIGH_KG, " kg")
)
dec_path <- file.path(outputs_dir, "k30_decision_log.txt")
write_lines_safely(decision_lines, dec_path)
append_manifest_safe(label = "k30_decision_log", kind = "text", path = dec_path, n = nrow(df))

direction_check <- tibble(
  coding = "codebook_rule_0weak_1moderate_2good_to_binary",
  cor_self_grip_spearman = safe_cor(as.numeric(df_scored$hyva_liikuntakyky), df_scored$puristus0_clean),
  cor_self_gait_primary_spearman = safe_cor(as.numeric(df_scored$hyva_liikuntakyky), df_scored$gait_speed_primary),
  cor_self_gait_sensitivity_spearman = safe_cor(as.numeric(df_scored$hyva_liikuntakyky), df_scored$gait_speed_sensitivity)
)
direction_check_path <- file.path(outputs_dir, "k30_direction_check.csv")
write_csv_safely(direction_check, direction_check_path)
append_manifest_safe(label = "k30_direction_check", kind = "table_csv", path = direction_check_path, n = nrow(df_scored))

# --- 5) Primary continuous score (z-composite) --------------------------------
# Primary score is composite to avoid instability from minimal 3-indicator CFA.
z_primary <- df_scored %>%
  transmute(
    z_grip = as.numeric(scale(puristus0_clean)),
    z_gait = as.numeric(scale(gait_speed_primary)),
    z_self = as.numeric(scale(as.numeric(hyva_liikuntakyky)))
  )

df_scored <- df_scored %>%
  mutate(
    capacity_score_z_primary = na_row_mean(as.matrix(z_primary)),
    capacity_score_primary = capacity_score_z_primary
  )

z_sens <- df_scored %>%
  transmute(
    z_grip = as.numeric(scale(puristus0_clean)),
    z_gait = as.numeric(scale(gait_speed_sensitivity)),
    z_self = as.numeric(scale(as.numeric(hyva_liikuntakyky)))
  )

df_scored <- df_scored %>%
  mutate(
    capacity_score_z_sensitivity = na_row_mean(as.matrix(z_sens)),
    capacity_score_primary_sensitivity = capacity_score_z_sensitivity
  )

# --- 6) CFA as sensitivity/diagnostic (lavaan WLSMV) --------------------------
# Primary (zeros->NA)
cfa_primary_in <- df_scored %>%
  transmute(
    puristus0_clean = puristus0_clean,
    kavely = gait_speed_primary,
    hyva_liikuntakyky = hyva_liikuntakyky
  )

cfa_primary <- fit_capacity_cfa(cfa_primary_in, ordered_var = "hyva_liikuntakyky")
df_scored <- df_scored %>% mutate(capacity_score_cfa_primary = cfa_primary$score)
save_lavaan_outputs(cfa_primary$fit, "k30_cfa_primary")

# Sensitivity (retain zeros)
cfa_sens_in <- df_scored %>%
  transmute(
    puristus0_clean = puristus0_clean,
    kavely = gait_speed_sensitivity,
    hyva_liikuntakyky = hyva_liikuntakyky
  )

cfa_sens <- fit_capacity_cfa(cfa_sens_in, ordered_var = "hyva_liikuntakyky")
df_scored <- df_scored %>% mutate(capacity_score_cfa_sensitivity = cfa_sens$score)
save_lavaan_outputs(cfa_sens$fit, "k30_cfa_sensitivity")

cfa_diag <- bind_rows(
  cfa_primary$diagnostics %>% mutate(model = "primary_zero_to_na"),
  cfa_sens$diagnostics %>% mutate(model = "sensitivity_zero_retained")
) %>%
  select(model, everything())
cfa_diag_path <- file.path(outputs_dir, "k30_cfa_diagnostics.csv")
write_csv_safely(cfa_diag, cfa_diag_path)
append_manifest_safe(label = "k30_cfa_diagnostics", kind = "table_csv", path = cfa_diag_path, n = nrow(df_scored))

score_summ <- tibble(
  score = c(
    "capacity_score_primary",
    "capacity_score_primary_sensitivity",
    "capacity_score_cfa_primary",
    "capacity_score_cfa_sensitivity",
    "capacity_score_z_primary",
    "capacity_score_z_sensitivity"
  ),
  n = c(
    sum(!is.na(df_scored$capacity_score_primary)),
    sum(!is.na(df_scored$capacity_score_primary_sensitivity)),
    sum(!is.na(df_scored$capacity_score_cfa_primary)),
    sum(!is.na(df_scored$capacity_score_cfa_sensitivity)),
    sum(!is.na(df_scored$capacity_score_z_primary)),
    sum(!is.na(df_scored$capacity_score_z_sensitivity))
  ),
  mean = c(
    mean(df_scored$capacity_score_primary, na.rm = TRUE),
    mean(df_scored$capacity_score_primary_sensitivity, na.rm = TRUE),
    mean(df_scored$capacity_score_cfa_primary, na.rm = TRUE),
    mean(df_scored$capacity_score_cfa_sensitivity, na.rm = TRUE),
    mean(df_scored$capacity_score_z_primary, na.rm = TRUE),
    mean(df_scored$capacity_score_z_sensitivity, na.rm = TRUE)
  ),
  sd = c(
    sd(df_scored$capacity_score_primary, na.rm = TRUE),
    sd(df_scored$capacity_score_primary_sensitivity, na.rm = TRUE),
    sd(df_scored$capacity_score_cfa_primary, na.rm = TRUE),
    sd(df_scored$capacity_score_cfa_sensitivity, na.rm = TRUE),
    sd(df_scored$capacity_score_z_primary, na.rm = TRUE),
    sd(df_scored$capacity_score_z_sensitivity, na.rm = TRUE)
  ),
  p01 = c(
    as.numeric(quantile(df_scored$capacity_score_primary, 0.01, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_primary_sensitivity, 0.01, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_cfa_primary, 0.01, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_cfa_sensitivity, 0.01, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z_primary, 0.01, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z_sensitivity, 0.01, na.rm = TRUE))
  ),
  p99 = c(
    as.numeric(quantile(df_scored$capacity_score_primary, 0.99, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_primary_sensitivity, 0.99, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_cfa_primary, 0.99, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_cfa_sensitivity, 0.99, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z_primary, 0.99, na.rm = TRUE)),
    as.numeric(quantile(df_scored$capacity_score_z_sensitivity, 0.99, na.rm = TRUE))
  )
)

scores_path <- file.path(outputs_dir, "k30_scores_summary.csv")
write_csv_safely(score_summ, scores_path)
append_manifest_safe(label = "k30_scores_summary", kind = "table_csv", path = scores_path, n = nrow(df_scored))

# --- 7) Output dataset --------------------------------------------------------
data_root <- resolve_data_root()
external_dir <- file.path(data_root, "paper_01", "capacity_scores")
dir_create(external_dir)

out_csv <- file.path(external_dir, "kaatumisenpelko_with_capacity_scores.csv")
out_rds <- file.path(external_dir, "kaatumisenpelko_with_capacity_scores.rds")

write_csv_safely(df_scored %>%
  mutate(
    # ensure requested variable names exist (aliases already set)
    gait_speed_primary = gait_speed_primary,
    gait_speed_sensitivity = gait_speed_sensitivity
  ) %>%
  select(
    everything(),
    hyva_liikuntakyky,
    gait_speed_primary,
    gait_speed_sensitivity,
    capacity_score_primary,
    capacity_score_primary_sensitivity,
    capacity_score_cfa_primary,
    capacity_score_cfa_sensitivity,
    capacity_score_z_primary,
    capacity_score_z_sensitivity
  ),
  out_csv
)
write_rds_safely(df_scored, out_rds)

csv_md5 <- unname(tools::md5sum(out_csv)[1])
rds_md5 <- unname(tools::md5sum(out_rds)[1])
receipt_path <- file.path(outputs_dir, "k30_patient_level_output_receipt.txt")
receipt_lines <- c(
  paste0("script=", script_label),
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("data_root=", data_root),
  paste0("external_dir=", external_dir),
  paste0("csv_path=", out_csv),
  paste0("csv_md5=", csv_md5),
  paste0("rds_path=", out_rds),
  paste0("rds_md5=", rds_md5),
  paste0("nrow=", nrow(df_scored)),
  paste0("ncol=", ncol(df_scored))
)
write_lines_safely(receipt_lines, receipt_path)
append_manifest_safe(
  label = "k30_patient_level_output_receipt",
  kind = "text",
  path = receipt_path,
  n = nrow(df_scored),
  notes = "Patient-level CSV/RDS written to DATA_ROOT external path."
)

# --- 8) Reproducibility + diagnostics ----------------------------------------
sess_path <- file.path(outputs_dir, "k30_sessioninfo.txt")
write_lines_safely(capture.output(sessionInfo()), sess_path)
append_manifest_safe(label = "k30_sessioninfo", kind = "text", path = sess_path)

message("K30 complete. Outputs written to: ", outputs_dir)
# ==============================================================================
# EOF
