#!/usr/bin/env Rscript
# ## STANDARD SCRIPT INTRO (MANDATORY)
# ==============================================================================
# K40 - Frailty Index (FI) builder (deterministic, non-performance)
# File tag: K40.V2_frailty-index.R
# Purpose: Build deterministic FI = proportion of deficits (0-1), with FI_z as
#          derived standardized variable, using non-performance deficits only.
#
# Outcome: frailty_index_fi (plus frailty_index_fi_z)
# Predictors: non-performance deficit candidates from K33 (+ optional K15/K32 joins)
# Moderator/interaction: None
# Grouping variable: id (baseline row per participant)
# Covariates: age/sex only for plausibility diagnostics if found
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# id -> id
# d_<var_name> -> deficit score in [0, 1]
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K40 (canonical)
# - outputs dir: R-scripts/K40/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[[1]]) else ""
script_base <- if (nzchar(script_path)) sub("\\.R$", "", basename(script_path)) else "K40"
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K40"
script_dir <- if (nzchar(script_path)) dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE)) else here::here("R-scripts", "K40")

project_root <- if (nzchar(script_path)) {
  dirname(dirname(dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE))))
} else {
  getwd()
}
setwd(project_root)

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
outputs_dir <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

PRIMARY_MISSINGNESS_THR <- 0.20
SENS_MISSINGNESS_THR <- 0.30
PREV_MIN_BIN <- 0.01
PREV_MAX_BIN <- 0.80
N_DEFICITS_MIN <- 10L
COVERAGE_MIN <- 0.60
MAX_PER_DOMAIN <- Inf
RUN_AGE_TREND_DIAG <- TRUE
RUN_CEILING_DIAG <- TRUE
RUN_DOMAIN_BALANCE <- TRUE
STRICT_ORDINAL_REQUIRES_MAP <- FALSE

domain_overrides_path <- file.path(script_dir, "config", "k40_domain_overrides.csv")
domain_overrides <- NULL
if (file.exists(domain_overrides_path)) {
  domain_overrides <- readr::read_csv(domain_overrides_path, show_col_types = FALSE) %>%
    dplyr::mutate(var_name = tolower(var_name))
}

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(script = script_label, label = label, path = get_relpath(path), kind = kind, n = n, notes = notes),
    manifest_path
  )
}

write_agg_csv <- function(df, filename, label = filename, notes = NA_character_) {
  out_path <- file.path(outputs_dir, filename)
  readr::write_csv(df, out_path)
  append_artifact(label = label, kind = "table_csv", path = out_path, n = nrow(df), notes = notes)
  out_path
}

write_agg_txt <- function(lines, filename, label = filename, notes = NA_character_) {
  out_path <- file.path(outputs_dir, filename)
  writeLines(lines, out_path)
  append_artifact(label = label, kind = "text", path = out_path, n = length(lines), notes = notes)
  out_path
}

md5_if_exists <- function(path) {
  if (is.na(path) || !file.exists(path)) return(NA_character_)
  unname(tools::md5sum(path))
}

stop_if_missing_cols <- function(df, req_cols) {
  miss <- setdiff(req_cols, names(df))
  if (length(miss) > 0) {
    stop("Missing required columns: ", paste(miss, collapse = ", "), call. = FALSE)
  }
}

clean_names_simple <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  x
}

load_tabular <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") {
    obj <- readRDS(path)
    if (!is.data.frame(obj)) stop("RDS is not a data.frame: ", path, call. = FALSE)
    return(as_tibble(obj))
  }
  if (ext == "csv") return(readr::read_csv(path, show_col_types = FALSE))
  stop("Unsupported input extension: ", path, call. = FALSE)
}

infer_data_root <- function() {
  from_env <- Sys.getenv("DATA_ROOT", "")
  if (nzchar(from_env)) return(from_env)

  env_path <- file.path(project_root, "config", ".env")
  if (file.exists(env_path)) {
    env_lines <- readLines(env_path, warn = FALSE)
    hit <- grep("^DATA_ROOT\\s*=", env_lines, value = TRUE)
    if (length(hit) > 0) {
      value <- sub("^DATA_ROOT\\s*=\\s*", "", hit[[1]])
      value <- gsub('^"|"$', "", value)
      value <- gsub("^'|'$", "", value)
      if (nzchar(value)) return(value)
    }
  }

  stop(
    "DATA_ROOT is required but missing. Set DATA_ROOT env var or config/.env DATA_ROOT=...",
    call. = FALSE
  )
}

pick_first_existing <- function(paths_vec) {
  hits <- paths_vec[file.exists(paths_vec)]
  if (length(hits) == 0) return(NA_character_)
  hits[[1]]
}

resolve_inputs <- function(data_root) {
  analysis_dir <- file.path(data_root, "paper_01", "analysis")
  capacity_dir <- file.path(data_root, "paper_01", "capacity_scores")
  frailty_dir <- file.path(data_root, "paper_01", "frailty")

  list(
    k33_wide = pick_first_existing(file.path(analysis_dir, c("fof_analysis_k33_wide.rds", "fof_analysis_k33_wide.csv"))),
    k33_long = pick_first_existing(file.path(analysis_dir, c("fof_analysis_k33_long.rds", "fof_analysis_k33_long.csv"))),
    k32 = pick_first_existing(file.path(capacity_dir, c("kaatumisenpelko_with_capacity_scores_k32.rds", "kaatumisenpelko_with_capacity_scores_k32.csv"))),
    k15 = pick_first_existing(file.path(frailty_dir, c("kaatumisenpelko_with_frailty_k15.rds", "kaatumisenpelko_with_frailty_k15.csv"))),
    analysis_dir = analysis_dir,
    capacity_dir = capacity_dir,
    frailty_dir = frailty_dir
  )
}

find_col <- function(nms, candidates) {
  hit <- intersect(candidates, nms)
  if (length(hit) == 0) return(NA_character_)
  hit[[1]]
}

coerce_numeric <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x)) return(suppressWarnings(as.numeric(as.character(x))))
  if (is.character(x)) return(suppressWarnings(as.numeric(x)))
  suppressWarnings(as.numeric(x))
}

infer_type <- function(x) {
  nn <- x[!is.na(x)]
  nlev <- length(unique(nn))
  if (nlev <= 1) return("constant")
  if (nlev == 2) return("binary")
  if (is.factor(x) || is.character(x)) {
    if (nlev <= 10) return("ordinal")
    return("categorical")
  }
  if (is.numeric(x)) {
    if (all(abs(nn - round(nn)) < 1e-9) && nlev <= 10) return("ordinal")
    return("continuous")
  }
  "other"
}

mode_top_levels <- function(x, k = 3) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_character_)
  tb <- sort(table(as.character(x)), decreasing = TRUE)
  top <- head(tb, k)
  paste(paste0(names(top), ":", as.integer(top)), collapse = " | ")
}

safe_cor <- function(x, y) {
  ok <- !is.na(x) & !is.na(y)
  if (sum(ok) < 10) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok]))
}

# Direction harmonization: deterministic and codebook/script-lineage only.
reverse_coded_by_lineage <- c(
  "self_rated_health", "energy_score", "quality_of_life", "general_health"
)

binary_map <- list(
  # var_name = list(deficit_values = c("yes", "1"), non_deficit_values = c("no", "0"))
)

ordinal_level_map <- list(
  # var_name = c("none", "mild", "moderate", "severe")
)

continuous_thresholds <- list(
  # var_name = list(cutoff = 0.0, direction = "lower_worse" | "higher_worse")
)

score_binary <- function(x, var_name) {
  reverse_dir <- var_name %in% reverse_coded_by_lineage

  if (var_name %in% names(binary_map)) {
    map <- binary_map[[var_name]]
    x_chr <- tolower(trimws(as.character(x)))
    out <- rep(NA_real_, length(x_chr))
    out[x_chr %in% tolower(map$deficit_values)] <- 1
    out[x_chr %in% tolower(map$non_deficit_values)] <- 0
    if (reverse_dir) out <- ifelse(is.na(out), NA_real_, 1 - out)
    return(list(score = out, status = "mapped"))
  }

  x_num <- suppressWarnings(as.numeric(as.character(x)))
  unique_num <- sort(unique(x_num[!is.na(x_num)]))
  if (length(unique(x[!is.na(x)])) == 2 && length(unique_num) == 2 && identical(unique_num, c(0, 1))) {
    out <- ifelse(is.na(x_num), NA_real_, x_num)
    if (reverse_dir) out <- ifelse(is.na(out), NA_real_, 1 - out)
    return(list(score = out, status = "native_01"))
  }

  list(score = rep(NA_real_, length(x)), status = "no_mapping")
}

score_ordinal <- function(x, var_name) {
  reverse_dir <- var_name %in% reverse_coded_by_lineage

  if (var_name %in% names(ordinal_level_map)) {
    levs <- ordinal_level_map[[var_name]]
    xf <- factor(as.character(x), levels = levs, ordered = TRUE)
    r <- as.numeric(xf)
    out <- (r - 1) / (length(levs) - 1)
    out[is.na(xf)] <- NA_real_
    if (reverse_dir) out <- ifelse(is.na(out), NA_real_, 1 - out)
    return(list(score = out, level_mode = "explicit_map", levels_used = paste(levs, collapse = " > "), valid = TRUE))
  }

  if (isTRUE(STRICT_ORDINAL_REQUIRES_MAP)) {
    return(list(score = rep(NA_real_, length(x)), level_mode = "missing_map_strict", levels_used = NA_character_, valid = FALSE))
  }

  xf <- if (is.factor(x)) x else factor(x)
  levs <- levels(xf)
  if (length(levs) < 3) {
    return(list(score = rep(NA_real_, length(x)), level_mode = "too_few_levels", levels_used = paste(levs, collapse = " > "), valid = FALSE))
  }
  r <- as.numeric(xf)
  out <- (r - 1) / (length(levs) - 1)
  out[is.na(xf)] <- NA_real_
  if (reverse_dir) out <- ifelse(is.na(out), NA_real_, 1 - out)
  list(score = out, level_mode = "default_factor_order", levels_used = paste(levs, collapse = " > "), valid = TRUE)
}

score_continuous <- function(x, var_name) {
  rule <- continuous_thresholds[[var_name]]
  if (is.null(rule)) return(list(score = rep(NA_real_, length(x)), status = "no_threshold_rule"))
  xn <- coerce_numeric(x)
  if (rule$direction == "lower_worse") return(list(score = ifelse(is.na(xn), NA_real_, ifelse(xn <= rule$cutoff, 1, 0)), status = "threshold_applied"))
  if (rule$direction == "higher_worse") return(list(score = ifelse(is.na(xn), NA_real_, ifelse(xn >= rule$cutoff, 1, 0)), status = "threshold_applied"))
  list(score = rep(NA_real_, length(x)), status = "invalid_threshold_direction")
}

domain_label <- function(var_name) {
  v <- tolower(var_name)

  if (!is.null(domain_overrides)) {
    hit <- domain_overrides$domain[match(v, domain_overrides$var_name)]
    if (!is.na(hit)) return(hit)
  }

  if (stringr::str_detect(v, "(adl|iadl|toimintakyky|functional|bathing|dressing|toilet|transfer|feeding|shopping|cooking|housework)")) {
    return("function_adl_iadl")
  }
  if (stringr::str_detect(v, "(mobility|gait|walk|walking|stairs|chair|stand|standing|balance|dizziness|vertigo|fall|falls|kaatu|tasapaino|huima)")) {
    return("mobility_balance_falls")
  }
  if (stringr::str_detect(v, "(dx_|diagnos|disease|comorbid|hypertens|heart|cardio|chf|mi|stroke|tia|af|copd|asthma|diabet|cancer|tumou?r|kidney|renal|ckd|arthritis|osteo|rheum|parkinson|dement|alzheimer)")) {
    return("disease_comorbidity")
  }
  if (stringr::str_detect(v, "(symptom|breath|dyspn|cough|nausea|vomit|constipat|diarr|incontinen|urinar|bowel|edema|swelling|appetite|anorex|weak|weakness|tremor|palpitat|chest_pain|fatigue|tired|exhaust|fever|selfrated|general_health)")) {
    return("symptoms_general")
  }
  if (stringr::str_detect(v, "(pain|ache|sore|kipu)")) {
    return("pain")
  }
  if (stringr::str_detect(v, "(depress|anx|anxiety|stress|panic|mood|apathy|lonely|loneliness|psychiat|mental|ghq|cesd|phq)")) {
    return("mood_mental")
  }
  if (stringr::str_detect(v, "(cognit|memory|mmse|mo?a?ca|clock|orientation|confus|dement|delir)")) {
    return("cognition")
  }
  if (stringr::str_detect(v, "(vision|visual|sight|blind|hearing|hear|deaf|ear|tinnitus|glasses|audi)")) {
    return("sensory")
  }
  if (stringr::str_detect(v, "(weight|bmi|underweight|malnutrition|nutrition|diet|protein|albumin|loss_of_weight|weight_loss|pudot|laihtu)")) {
    return("nutrition_weight")
  }
  if (stringr::str_detect(v, "(sleep|insomnia|nap|somnol|unett|väsymys)")) {
    return("sleep_fatigue")
  }
  if (stringr::str_detect(v, "(polypharm|medication|drug|rx_|prescrip|lääke)")) {
    return("medication")
  }
  return("other")
}

priority_rank <- function(var_name) {
  if (grepl("diag|doctor|icd|disease|sairaus|comorb", var_name, ignore.case = TRUE)) return(1L)
  if (grepl("adl|iadl|toimintakyky|limitation|difficulty|rajoit", var_name, ignore.case = TRUE)) return(2L)
  if (grepl("symptom|fatigue|exhaust|uup|weight|appetite|pain|self_rated|energy", var_name, ignore.case = TRUE)) return(3L)
  if (grepl("med|drug|rx|laake|medication", var_name, ignore.case = TRUE)) return(4L)
  5L
}

# -----------------------------------------------------------------------------
# 1) Resolve inputs and read base datasets
# -----------------------------------------------------------------------------
data_root <- infer_data_root()
resolved <- resolve_inputs(data_root)

if (is.na(resolved$k33_wide) && is.na(resolved$k33_long)) {
  stop("K40 requires K33 analysis dataset under DATA_ROOT/paper_01/analysis", call. = FALSE)
}

base_path <- if (!is.na(resolved$k33_wide)) resolved$k33_wide else resolved$k33_long
base_df <- load_tabular(base_path)
names(base_df) <- clean_names_simple(names(base_df))

id_col <- find_col(names(base_df), c("id", "participant_id", "subject_id", "study_id"))
if (is.na(id_col)) stop("Could not resolve id column in K33 input", call. = FALSE)
if (id_col != "id") names(base_df)[names(base_df) == id_col] <- "id"
id_col <- "id"

req_cols <- c(id_col)
stop_if_missing_cols(base_df, req_cols)

# If long, keep baseline deterministically.
time_col <- find_col(names(base_df), c("time", "timepoint", "visit", "aika", "measurement_time"))
baseline_logic <- "none"
if (!is.na(time_col)) {
  tvals <- tolower(as.character(base_df[[time_col]]))
  base_levels <- c("baseline", "bl", "0", "0m", "m0", "t0")
  if (any(tvals %in% base_levels, na.rm = TRUE)) {
    base_df <- base_df[tvals %in% base_levels, , drop = FALSE]
    baseline_logic <- sprintf("explicit_levels_in_%s", time_col)
  } else {
    baseline_logic <- sprintf("time_col_%s_present_no_explicit_baseline_level", time_col)
  }
}

base_df <- base_df %>%
  arrange(.data[[id_col]]) %>%
  group_by(.data[[id_col]]) %>%
  slice(1L) %>%
  ungroup()

# Optional joins for diagnostics only.
if (!is.na(resolved$k32)) {
  k32_df <- load_tabular(resolved$k32)
  names(k32_df) <- clean_names_simple(names(k32_df))
  k32_id <- find_col(names(k32_df), c("id", "participant_id", "subject_id", "study_id"))
  if (!is.na(k32_id)) {
    if (k32_id != id_col) names(k32_df)[names(k32_df) == k32_id] <- id_col
    keep <- unique(c(id_col, grep("capacity_score_latent_primary|capacity_score", names(k32_df), value = TRUE)))
    keep <- keep[keep %in% names(k32_df)]
    base_df <- base_df %>% left_join(k32_df[, keep, drop = FALSE], by = id_col)
  }
}

# Optional K15 join for additional non-performance deficit candidates.
if (!is.na(resolved$k15)) {
  k15_df <- load_tabular(resolved$k15)
  names(k15_df) <- clean_names_simple(names(k15_df))
  k15_id <- find_col(names(k15_df), c("id", "participant_id", "subject_id", "study_id"))
  if (!is.na(k15_id)) {
    if (k15_id != id_col) names(k15_df)[names(k15_df) == k15_id] <- id_col
    # Comparison-only join: retain only non-frailty, non-outcome, non-exposure fields.
    cmp_keep <- setdiff(names(k15_df), id_col)
    cmp_keep <- cmp_keep[!grepl("^frailty_|^frailty_index|^fi$|^fi_z$|^composite_z|^fof_status|kaatumisenpelko|tasapainovaikeus", cmp_keep, ignore.case = TRUE)]
    if (length(cmp_keep) > 0) {
      base_df <- base_df %>% left_join(k15_df[, c(id_col, cmp_keep), drop = FALSE], by = id_col, suffix = c("", "_k15cmp"))
    }
  }
}

# -----------------------------------------------------------------------------
# 2) Candidate inventory and exclusions
# -----------------------------------------------------------------------------
perf_regex <- "puristus|grip|kavely|gait|tuoli|chair|seisom|single_leg|balance|sls"
exposure_regex <- "^fof_status($|_)|^kaatumisenpelko|^tasapainovaikeus($|_)"
outcome_regex <- "^composite_z|toimintakykysummary|delta_composite_z"
derived_construct_regex <- "^frailty_|^frailty_index|^fi$|^fi_z$"
admin_regex <- "^id$|^time$|^visit$|^aika$|^measurement_time$|capacity_score"
demographic_regex <- "^sex($|_)|^gender($|_)|^agelka$|^age($|_)"
behavior_exposure_regex <- "^tupakointi$|^alkoholi$|^viinaon$|^smok|^alcohol"

exclusion_reason <- function(vn) {
  if (grepl(perf_regex, vn, ignore.case = TRUE)) return("performance_test_pattern")
  if (grepl(exposure_regex, vn, ignore.case = TRUE)) return("primary_exposure")
  if (grepl(behavior_exposure_regex, vn, ignore.case = TRUE)) return("behavior_exposure_not_deficit")
  if (grepl(demographic_regex, vn, ignore.case = TRUE)) return("demographic_not_deficit")
  if (grepl(outcome_regex, vn, ignore.case = TRUE)) return("outcome_or_component")
  if (grepl(derived_construct_regex, vn, ignore.case = TRUE)) return("derived_frailty_construct")
  if (grepl(admin_regex, vn, ignore.case = TRUE)) return("administrative_or_non_deficit")
  NA_character_
}

col_inventory <- tibble(
  var_name = names(base_df),
  class = vapply(base_df, function(x) class(x)[1], character(1)),
  n = nrow(base_df),
  n_miss = vapply(base_df, function(x) sum(is.na(x)), integer(1)),
  p_miss = n_miss / pmax(n, 1),
  n_levels = vapply(base_df, function(x) length(unique(x[!is.na(x)])), integer(1))
)
write_agg_csv(col_inventory, "k40_column_inventory.csv", notes = "K40 full column inventory")

excluded_vars <- tibble(var_name = names(base_df)) %>%
  mutate(reason = vapply(var_name, exclusion_reason, character(1))) %>%
  filter(!is.na(reason))
write_agg_csv(excluded_vars, "k40_excluded_vars.csv", notes = "Deterministic hard exclusions")

candidate_names <- setdiff(names(base_df), excluded_vars$var_name)

candidate_rows <- list()
binary_without_mapping <- list()
continuous_without_rule <- list()
ordinal_levels_used <- list()

for (vn in candidate_names) {
  x <- base_df[[vn]]
  vtype <- infer_type(x)

  prevalence <- NA_real_
  binary_status <- NA_character_
  ordinal_status <- NA_character_
  ordinal_levels <- NA_character_
  continuous_status <- NA_character_

  if (vtype == "binary") {
    b <- score_binary(x, vn)
    prevalence <- mean(b$score == 1, na.rm = TRUE)
    binary_status <- b$status
    if (b$status == "no_mapping") {
      binary_without_mapping[[length(binary_without_mapping) + 1]] <- tibble(
        var_name = vn,
        n_levels = length(unique(x[!is.na(x)])),
        top_levels = mode_top_levels(x),
        reason = "binary_without_explicit_mapping_and_not_native_01"
      )
    }
  }

  if (vtype == "ordinal") {
    o <- score_ordinal(x, vn)
    ordinal_status <- o$level_mode
    ordinal_levels <- o$levels_used
    ordinal_levels_used[[length(ordinal_levels_used) + 1]] <- tibble(
      var_name = vn,
      level_mode = o$level_mode,
      levels_used = o$levels_used,
      red_flag = as.integer(o$level_mode == "default_factor_order")
    )
  }

  if (vtype == "continuous") {
    cscore <- score_continuous(x, vn)
    continuous_status <- cscore$status
    if (cscore$status == "no_threshold_rule") {
      continuous_without_rule[[length(continuous_without_rule) + 1]] <- tibble(
        var_name = vn,
        p_miss = mean(is.na(x)),
        n_levels = length(unique(x[!is.na(x)])),
        reason = "continuous_without_threshold_rule"
      )
    }
  }

  candidate_rows[[length(candidate_rows) + 1]] <- tibble(
    var_name = vn,
    type = vtype,
    n = length(x),
    n_miss = sum(is.na(x)),
    p_miss = mean(is.na(x)),
    prevalence = prevalence,
    n_levels = length(unique(x[!is.na(x)])),
    top_levels = mode_top_levels(x),
    binary_status = binary_status,
    ordinal_status = ordinal_status,
    ordinal_levels_used = ordinal_levels,
    continuous_status = continuous_status,
    direction_rule = ifelse(vn %in% reverse_coded_by_lineage, "reverse_by_codebook_lineage", "as_coded")
  )
}

candidate_inventory <- bind_rows(candidate_rows)
write_agg_csv(candidate_inventory, "k40_candidate_inventory.csv", notes = "Candidate inventory after hard exclusions")

write_agg_csv(
  if (length(binary_without_mapping) > 0) bind_rows(binary_without_mapping) else tibble(var_name = character(), n_levels = integer(), top_levels = character(), reason = character()),
  "k40_binary_without_mapping.csv",
  notes = "Binary variables excluded unless explicit mapping or native 0/1"
)

write_agg_csv(
  if (length(continuous_without_rule) > 0) bind_rows(continuous_without_rule) else tibble(var_name = character(), p_miss = numeric(), n_levels = integer(), reason = character()),
  "k40_continuous_without_threshold_rule.csv",
  notes = "Continuous candidates lacking threshold rule (debt list)"
)

write_agg_csv(
  if (length(ordinal_levels_used) > 0) bind_rows(ordinal_levels_used) else tibble(var_name = character(), level_mode = character(), levels_used = character(), red_flag = integer()),
  "k40_ordinal_levels_used.csv",
  notes = "Ordinal level ordering source and red flags"
)

# -----------------------------------------------------------------------------
# 3) Deterministic screening + sensitivity + redundancy
# -----------------------------------------------------------------------------
eligibility_core <- function(df, miss_thr) {
  df %>%
    mutate(
      miss_ok = p_miss <= miss_thr,
      binary_ok = ifelse(type == "binary", binary_status != "no_mapping" & !is.na(prevalence) & prevalence >= PREV_MIN_BIN & prevalence <= PREV_MAX_BIN, TRUE),
      ordinal_ok = ifelse(type == "ordinal", n_levels >= 3 & (!isTRUE(STRICT_ORDINAL_REQUIRES_MAP) | ordinal_status == "explicit_map"), TRUE),
      continuous_ok = ifelse(type == "continuous", continuous_status == "threshold_applied", TRUE),
      type_ok = type %in% c("binary", "ordinal", "continuous"),
      eligible = miss_ok & binary_ok & ordinal_ok & continuous_ok & type_ok
    )
}

primary_screen <- eligibility_core(candidate_inventory, miss_thr = PRIMARY_MISSINGNESS_THR)
primary_eligible <- primary_screen %>% filter(eligible)

use_sensitivity <- nrow(primary_eligible) < N_DEFICITS_MIN
active_screen <- if (use_sensitivity) eligibility_core(candidate_inventory, miss_thr = SENS_MISSINGNESS_THR) else primary_screen
eligible <- active_screen %>% filter(eligible)

selected_pre <- eligible %>%
  mutate(
    domain = vapply(var_name, domain_label, character(1)),
    priority = vapply(var_name, priority_rank, integer(1))
  ) %>%
  arrange(domain, priority, p_miss, var_name)

selected <- if (is.finite(MAX_PER_DOMAIN)) {
  selected_pre %>%
    group_by(domain) %>%
    slice_head(n = MAX_PER_DOMAIN) %>%
    ungroup() %>%
    arrange(priority, p_miss, var_name)
} else {
  selected_pre %>%
  arrange(priority, p_miss, var_name)
}

write_agg_csv(
  selected %>% select(var_name, type, p_miss, prevalence, domain, priority, direction_rule, binary_status, ordinal_status, continuous_status),
  "k40_selected_deficits.csv",
  notes = "Selected deficits after deterministic screening and configurable domain cap"
)

write_agg_csv(
  selected %>% select(var_name, type, n_miss, p_miss, prevalence, n_levels, domain),
  "k40_deficit_missingness_prevalence.csv",
  notes = "Per-deficit missingness/prevalence"
)

other_vars <- eligible %>%
  mutate(domain = vapply(var_name, domain_label, character(1))) %>%
  filter(domain == "other") %>%
  select(var_name, type, p_miss, prevalence, n_levels, top_levels) %>%
  arrange(p_miss, var_name)
write_agg_csv(
  other_vars,
  "k40_other_vars_to_classify.csv",
  notes = "Eligible deficits classified as 'other' - use to build domain overrides"
)

prop_other <- NA_real_
if (RUN_DOMAIN_BALANCE) {
  domain_balance <- selected %>%
    mutate(domain = vapply(var_name, domain_label, character(1))) %>%
    count(domain, sort = TRUE) %>%
    mutate(prop = n / sum(n))
  write_agg_csv(domain_balance, "k40_domain_balance.csv", notes = "Selected deficits count by methodological domain")
  prop_other <- domain_balance$prop[domain_balance$domain == "other"]
  if (length(prop_other) == 0) prop_other <- 0
}

# -----------------------------------------------------------------------------
# 4) Compute FI (0-1) and FI_z with fixed thresholds
# -----------------------------------------------------------------------------
score_df <- tibble(id = base_df[[id_col]])
for (vn in selected$var_name) {
  vtype <- selected$type[selected$var_name == vn][1]
  if (vtype == "binary") {
    score_df[[paste0("d_", vn)]] <- score_binary(base_df[[vn]], vn)$score
  } else if (vtype == "ordinal") {
    score_df[[paste0("d_", vn)]] <- score_ordinal(base_df[[vn]], vn)$score
  } else if (vtype == "continuous") {
    score_df[[paste0("d_", vn)]] <- score_continuous(base_df[[vn]], vn)$score
  } else {
    score_df[[paste0("d_", vn)]] <- NA_real_
  }
}

deficit_cols <- grep("^d_", names(score_df), value = TRUE)
n_deficits <- length(deficit_cols)

if (n_deficits == 0) {
  score_df$fi <- NA_real_
  score_df$fi_z <- NA_real_
  score_df$n_deficits_observed <- 0L
  score_df$coverage <- NA_real_
  score_df$fi_eligible <- FALSE
} else {
  observed_counts <- rowSums(!is.na(score_df[, deficit_cols, drop = FALSE]))
  coverage <- observed_counts / n_deficits
  fi_raw <- rowMeans(score_df[, deficit_cols, drop = FALSE], na.rm = TRUE)
  fi_raw[!is.finite(fi_raw)] <- NA_real_

  fi_eligible <- coverage >= COVERAGE_MIN & observed_counts >= N_DEFICITS_MIN
  fi <- ifelse(fi_eligible, fi_raw, NA_real_)
  fi_z <- as.numeric(scale(fi))

  score_df$n_deficits_observed <- observed_counts
  score_df$coverage <- coverage
  score_df$fi_eligible <- fi_eligible
  score_df$fi <- fi
  score_df$fi_z <- fi_z
}

composite_col <- find_col(names(base_df), c("composite_z_baseline", "composite_z0", "composite_z", "toimintakykysummary0"))
capacity_col <- find_col(names(base_df), c("capacity_score_latent_primary", "capacity_score"))
age_col <- find_col(names(base_df), c("age", "ika", "age_years"))
sex_col <- find_col(names(base_df), c("sex", "gender", "sukupuoli"))

fi_summary <- tibble(
  metric = c("n_rows", "n_selected_deficits", "n_rows_fi_eligible", "n_rows_fi_na", "fi_mean", "fi_sd", "fi_min", "fi_max", "fi_z_mean", "fi_z_sd"),
  value = c(
    nrow(score_df),
    n_deficits,
    sum(score_df$fi_eligible, na.rm = TRUE),
    sum(is.na(score_df$fi)),
    mean(score_df$fi, na.rm = TRUE),
    sd(score_df$fi, na.rm = TRUE),
    suppressWarnings(min(score_df$fi, na.rm = TRUE)),
    suppressWarnings(max(score_df$fi, na.rm = TRUE)),
    mean(score_df$fi_z, na.rm = TRUE),
    sd(score_df$fi_z, na.rm = TRUE)
  )
)
write_agg_csv(fi_summary, "k40_fi_distribution_summary.csv", notes = "FI and FI_z aggregate distribution summary")

fi_vs_comp <- tibble(
  metric = "fi_vs_composite_z_baseline",
  correlation = if (!is.na(composite_col)) safe_cor(score_df$fi, coerce_numeric(base_df[[composite_col]])) else NA_real_,
  composite_col = ifelse(is.na(composite_col), NA_character_, composite_col)
)
write_agg_csv(fi_vs_comp, "k40_fi_vs_compositez_correlation.csv", notes = "FI correlation with Composite_Z baseline")

fi_vs_cap <- tibble(
  metric = "fi_vs_capacity_score_latent_primary",
  correlation = if (!is.na(capacity_col)) safe_cor(score_df$fi, coerce_numeric(base_df[[capacity_col]])) else NA_real_,
  capacity_col = ifelse(is.na(capacity_col), NA_character_, capacity_col)
)
write_agg_csv(fi_vs_cap, "k40_fi_vs_capacity_correlation.csv", notes = "FI correlation with capacity score")

red_flags <- bind_rows(
  tibble(flag = "rows_below_coverage_or_min_deficits", value = sum(!score_df$fi_eligible, na.rm = TRUE), detail = sprintf("coverage_min=%.2f;N_deficits_min=%d", COVERAGE_MIN, N_DEFICITS_MIN)),
  tibble(flag = "selected_deficits_lt_10", value = as.integer(n_deficits < 10), detail = sprintf("selected_deficits=%d", n_deficits)),
  tibble(flag = "selected_deficits_lt_30_warn", value = as.integer(n_deficits < 30), detail = sprintf("selected_deficits=%d", n_deficits)),
  tibble(flag = "used_missingness_sensitivity_pmiss_0_30", value = as.integer(use_sensitivity), detail = ifelse(use_sensitivity, "primary eligible deficits < N_DEFICITS_MIN", "primary branch sufficient")),
  tibble(flag = "fi_all_na", value = as.integer(all(is.na(score_df$fi))), detail = "All rows NA after eligibility gate"),
  tibble(flag = "ordinal_default_factor_order_used", value = sum(candidate_inventory$ordinal_status == "default_factor_order", na.rm = TRUE), detail = "Count of ordinal vars using default factor order"),
  tibble(flag = "domain_other_prop_gt_0_25_warn", value = as.integer(is.finite(prop_other) && prop_other > 0.25), detail = sprintf("prop_other=%.4f", ifelse(is.finite(prop_other), prop_other, NA_real_)))
)
write_agg_csv(red_flags, "k40_red_flags.csv", notes = "Deterministic red flag checks")

write_agg_csv(
  tibble(
    check = c("selected_deficits_lt_30_warn", "selected_deficits_lt_10_fail"),
    value = c(as.integer(n_deficits < 30), as.integer(n_deficits < 10)),
    threshold = c(30, 10),
    n_selected_deficits = n_deficits
  ),
  "k40_selected_deficits_warnings.csv",
  notes = "Deficit count plausibility warning/fail checks"
)

if (RUN_CEILING_DIAG) {
  fi_non_na <- score_df$fi[!is.na(score_df$fi)]
  ceiling_diag <- tibble(
    metric = c("fi_p50", "fi_p95", "fi_p99", "fi_max", "prop_fi_gt_0_66", "prop_fi_gt_0_70", "n_nonmissing"),
    value = c(
      ifelse(length(fi_non_na) > 0, as.numeric(stats::quantile(fi_non_na, 0.50, na.rm = TRUE)), NA_real_),
      ifelse(length(fi_non_na) > 0, as.numeric(stats::quantile(fi_non_na, 0.95, na.rm = TRUE)), NA_real_),
      ifelse(length(fi_non_na) > 0, as.numeric(stats::quantile(fi_non_na, 0.99, na.rm = TRUE)), NA_real_),
      ifelse(length(fi_non_na) > 0, max(fi_non_na, na.rm = TRUE), NA_real_),
      ifelse(length(fi_non_na) > 0, mean(fi_non_na > 0.66, na.rm = TRUE), NA_real_),
      ifelse(length(fi_non_na) > 0, mean(fi_non_na > 0.70, na.rm = TRUE), NA_real_),
      length(fi_non_na)
    )
  )
  write_agg_csv(ceiling_diag, "k40_fi_ceiling_checks.csv", notes = "FI plausibility ceiling diagnostics")
}

if (RUN_AGE_TREND_DIAG) {
  if (!is.na(age_col)) {
    age_num <- coerce_numeric(base_df[[age_col]])
    diag_df <- tibble(fi = score_df$fi, age = age_num)
    if (!is.na(sex_col)) diag_df$sex <- as.factor(base_df[[sex_col]])
    diag_df <- diag_df[is.finite(diag_df$fi) & is.finite(diag_df$age), , drop = FALSE]
    if (nrow(diag_df) >= 20) {
      fit <- if ("sex" %in% names(diag_df)) stats::lm(fi ~ age + sex, data = diag_df) else stats::lm(fi ~ age, data = diag_df)
      coef_df <- as.data.frame(summary(fit)$coefficients)
      coef_df$term <- rownames(coef_df)
      names(coef_df) <- c("estimate", "std_error", "t_value", "p_value", "term")
      coef_df <- coef_df[, c("term", "estimate", "std_error", "t_value", "p_value")]
      write_agg_csv(as_tibble(coef_df), "k40_fi_age_trend_lm.csv", notes = "Face-validity FI age trend linear model")
    } else {
      write_agg_csv(
        tibble(term = "model_not_fit", estimate = NA_real_, std_error = NA_real_, t_value = NA_real_, p_value = NA_real_),
        "k40_fi_age_trend_lm.csv",
        notes = "Insufficient rows for FI~age diagnostic"
      )
    }
  } else {
    write_agg_csv(
      tibble(term = "age_column_not_found", estimate = NA_real_, std_error = NA_real_, t_value = NA_real_, p_value = NA_real_),
      "k40_fi_age_trend_lm.csv",
      notes = "Age trend skipped: age column not found"
    )
  }
}

# -----------------------------------------------------------------------------
# 5) Externalize patient-level outputs + receipt
# -----------------------------------------------------------------------------
external_dir <- file.path(data_root, "paper_01", "frailty_vulnerability")
dir.create(external_dir, recursive = TRUE, showWarnings = FALSE)

external_csv <- file.path(external_dir, "kaatumisenpelko_with_frailty_index_k40.csv")
external_rds <- file.path(external_dir, "kaatumisenpelko_with_frailty_index_k40.rds")

patient_out <- score_df %>%
  select(id, fi, fi_z, n_deficits_observed, coverage, fi_eligible) %>%
  rename(frailty_index_fi = fi, frailty_index_fi_z = fi_z)

readr::write_csv(patient_out, external_csv)
saveRDS(patient_out, external_rds)

export_sel <- file.path(external_dir, "k40_selected_deficits.csv")
readr::write_csv(selected, export_sel, na = "")
append_artifact(
  label = "selected_deficits",
  kind = "table_csv",
  path = export_sel,
  n = nrow(selected),
  notes = "Selected deficit inventory for K40 (externalized to DATA_ROOT)"
)

receipt_lines <- c(
  sprintf("timestamp=%s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  sprintf("external_dir=%s", external_dir),
  sprintf("external_csv=%s", external_csv),
  sprintf("external_rds=%s", external_rds),
  sprintf("rows_exported=%d", nrow(patient_out)),
  sprintf("cols_exported=%d", ncol(patient_out)),
  sprintf("md5_csv=%s", md5_if_exists(external_csv)),
  sprintf("md5_rds=%s", md5_if_exists(external_rds)),
  sprintf("n_selected_deficits=%d", n_deficits),
  sprintf("coverage_min=%.2f", COVERAGE_MIN),
  sprintf("N_deficits_min=%d", N_DEFICITS_MIN),
  "governance=patient-level outputs written only under DATA_ROOT"
)
write_agg_txt(receipt_lines, "k40_patient_level_output_receipt.txt", notes = "External patient-level output receipt")

# Decision log
log_lines <- c(
  sprintf("timestamp=%s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  sprintf("data_root=%s", data_root),
  sprintf("k33_path=%s", base_path),
  sprintf("k32_path=%s", ifelse(is.na(resolved$k32), "NA", resolved$k32)),
  sprintf("k15_path=%s", ifelse(is.na(resolved$k15), "NA", resolved$k15)),
  sprintf("k33_md5=%s", md5_if_exists(base_path)),
  sprintf("k32_md5=%s", md5_if_exists(resolved$k32)),
  sprintf("k15_md5=%s", md5_if_exists(resolved$k15)),
  sprintf("primary_missingness_threshold=%.2f", PRIMARY_MISSINGNESS_THR),
  sprintf("sensitivity_missingness_threshold=%.2f", SENS_MISSINGNESS_THR),
  sprintf("used_sensitivity=%s", as.character(use_sensitivity)),
  sprintf("eligible_deficits_primary=%d", nrow(primary_eligible)),
  sprintf("selected_deficits=%d", n_deficits),
  sprintf("N_deficits_min=%d", N_DEFICITS_MIN),
  sprintf("coverage_min=%.2f", COVERAGE_MIN),
  sprintf("max_per_domain=%s", ifelse(is.finite(MAX_PER_DOMAIN), as.character(MAX_PER_DOMAIN), "Inf")),
  sprintf("baseline_logic=%s", baseline_logic),
  sprintf("time_col_used=%s", ifelse(is.na(time_col), "NA", time_col)),
  sprintf("strict_ordinal_requires_map=%s", as.character(STRICT_ORDINAL_REQUIRES_MAP)),
  "direction_rule=no_correlation_driven_flipping;codebook_or_lineage_only",
  "binary_rule=explicit_mapping_or_native_0_1_only",
  "ordinal_rule=explicit_map_preferred;default_factor_order_flagged"
)
write_agg_txt(log_lines, "k40_decision_log.txt", notes = "Deterministic K40 decisions and thresholds")

session_path <- save_sessioninfo_manifest(outputs_dir = outputs_dir, manifest_path = manifest_path, script = script_label)
session_alias <- file.path(outputs_dir, "k40_sessioninfo.txt")
file.copy(session_path, session_alias, overwrite = TRUE)
append_artifact("k40_sessioninfo.txt", "sessioninfo", session_alias, notes = "K40 session info alias")

if (n_deficits < 10) {
  stop("K40 fail condition: selected deficits < 10. See k40_selected_deficits_warnings.csv and k40_red_flags.csv", call. = FALSE)
}

message("K40.V2 completed.")
