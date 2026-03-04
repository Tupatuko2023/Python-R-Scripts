#!/usr/bin/env Rscript
# ==============================================================================
# K40 - Frailty Index (FI) builder (deterministic, non-performance)
# File tag: k40.r
# Purpose: Build deterministic FI = proportion of deficits (0-1), with FI_z as
#          derived standardized variable, using non-performance deficits only.
#          Patient-level outputs are externalized to DATA_ROOT.
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
project_root <- if (nzchar(script_path)) {
  dirname(dirname(dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE))))
} else {
  getwd()
}
setwd(project_root)

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "reporting.R"))

script_label <- "K40"
paths <- init_paths(script_label)
outputs_dir <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

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

md5_file <- function(path) unname(tools::md5sum(path))

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
  if (is.factor(x)) return(as.numeric(x))
  if (is.character(x)) {
    out <- suppressWarnings(as.numeric(x))
    if (sum(!is.na(out)) >= floor(0.7 * length(out[!is.na(x)]))) return(out)
    return(as.numeric(factor(x)))
  }
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

continuous_thresholds <- list(
  # Example only; keep empty until documented rules exist.
  # variable_name = list(cutoff = 0.0, direction = "lower_worse" | "higher_worse")
)

score_deficit <- function(x, var_name, var_type) {
  reverse_dir <- var_name %in% reverse_coded_by_lineage

  if (var_type == "binary") {
    vals <- sort(unique(x[!is.na(x)]))
    if (length(vals) != 2) return(rep(NA_real_, length(x)))
    xn <- coerce_numeric(x)
    valsn <- sort(unique(xn[!is.na(xn)]))
    out <- ifelse(is.na(xn), NA_real_, ifelse(xn == max(valsn), 1, 0))
    if (reverse_dir) out <- ifelse(is.na(out), NA_real_, 1 - out)
    return(out)
  }

  if (var_type == "ordinal") {
    xf <- if (is.factor(x)) x else factor(x)
    levs <- levels(xf)
    if (length(levs) < 3) return(rep(NA_real_, length(x)))
    r <- as.numeric(xf)
    out <- (r - 1) / (length(levs) - 1)
    out[is.na(xf)] <- NA_real_
    if (reverse_dir) out <- ifelse(is.na(out), NA_real_, 1 - out)
    return(out)
  }

  if (var_type == "continuous") {
    rule <- continuous_thresholds[[var_name]]
    if (is.null(rule)) return(rep(NA_real_, length(x)))
    xn <- coerce_numeric(x)
    if (rule$direction == "lower_worse") return(ifelse(is.na(xn), NA_real_, ifelse(xn <= rule$cutoff, 1, 0)))
    if (rule$direction == "higher_worse") return(ifelse(is.na(xn), NA_real_, ifelse(xn >= rule$cutoff, 1, 0)))
    return(rep(NA_real_, length(x)))
  }

  rep(NA_real_, length(x))
}

domain_label <- function(var_name) {
  if (grepl("comorb|diag|disease|icd|sairaus", var_name, ignore.case = TRUE)) return("comorbidity")
  if (grepl("adl|iadl|toimintakyky|limitation|difficulty|rajoit", var_name, ignore.case = TRUE)) return("functional")
  if (grepl("fatigue|exhaust|uup|weight|appetite|pain|symptom|self_rated|energy", var_name, ignore.case = TRUE)) return("symptom")
  if (grepl("med|drug|rx|laake|medication", var_name, ignore.case = TRUE)) return("medication_proxy")
  paste0("other_", substr(var_name, 1, 20))
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

# If long, keep baseline deterministically.
time_col <- find_col(names(base_df), c("time", "timepoint", "visit", "aika"))
if (!is.na(time_col)) {
  tvals <- tolower(as.character(base_df[[time_col]]))
  base_levels <- c("baseline", "bl", "0", "0m", "m0", "t0")
  if (any(tvals %in% base_levels, na.rm = TRUE)) {
    base_df <- base_df[tvals %in% base_levels, , drop = FALSE]
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
admin_regex <- "^id$|^time$|^visit$|^aika$|capacity_score"

exclusion_reason <- function(vn) {
  if (grepl(perf_regex, vn, ignore.case = TRUE)) return("performance_test_pattern")
  if (grepl(exposure_regex, vn, ignore.case = TRUE)) return("primary_exposure")
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

candidate_inventory <- lapply(candidate_names, function(vn) {
  x <- base_df[[vn]]
  vtype <- infer_type(x)
  d <- score_deficit(x, vn, vtype)
  prev <- if (vtype == "binary") mean(d == 1, na.rm = TRUE) else NA_real_
  tibble(
    var_name = vn,
    type = vtype,
    n = length(x),
    n_miss = sum(is.na(x)),
    p_miss = mean(is.na(x)),
    prevalence = prev,
    n_levels = length(unique(x[!is.na(x)])),
    top_levels = mode_top_levels(x),
    direction_rule = ifelse(vn %in% reverse_coded_by_lineage, "reverse_by_codebook_lineage", "as_coded")
  )
}) %>% bind_rows()
write_agg_csv(candidate_inventory, "k40_candidate_inventory.csv", notes = "Candidate inventory after hard exclusions")

# -----------------------------------------------------------------------------
# 3) Deterministic screening + sensitivity + redundancy
# -----------------------------------------------------------------------------
eligibility_core <- function(df, miss_thr) {
  df %>%
    mutate(
      miss_ok = p_miss <= miss_thr,
      binary_ok = ifelse(type == "binary", !is.na(prevalence) & prevalence >= 0.01 & prevalence <= 0.80, TRUE),
      ordinal_ok = ifelse(type == "ordinal", n_levels >= 3, TRUE),
      continuous_ok = ifelse(type == "continuous", var_name %in% names(continuous_thresholds), TRUE),
      type_ok = type %in% c("binary", "ordinal", "continuous"),
      eligible = miss_ok & binary_ok & ordinal_ok & continuous_ok & type_ok
    )
}

primary_screen <- eligibility_core(candidate_inventory, miss_thr = 0.20)
primary_eligible <- primary_screen %>% filter(eligible)

use_sensitivity <- nrow(primary_eligible) < 10
active_screen <- if (use_sensitivity) eligibility_core(candidate_inventory, miss_thr = 0.30) else primary_screen
eligible <- active_screen %>% filter(eligible)

# Redundancy de-duplication with fixed priority order.
selected <- eligible %>%
  mutate(
    domain = vapply(var_name, domain_label, character(1)),
    priority = vapply(var_name, priority_rank, integer(1))
  ) %>%
  arrange(domain, priority, p_miss, var_name) %>%
  group_by(domain) %>%
  slice(1L) %>%
  ungroup() %>%
  arrange(priority, p_miss, var_name)

write_agg_csv(
  selected %>% select(var_name, type, p_miss, prevalence, domain, priority, direction_rule),
  "k40_selected_deficits.csv",
  notes = "Selected deficits after deterministic screening and redundancy rule"
)

write_agg_csv(
  selected %>% select(var_name, type, n_miss, p_miss, prevalence, n_levels),
  "k40_deficit_missingness_prevalence.csv",
  notes = "Per-deficit missingness/prevalence"
)

# -----------------------------------------------------------------------------
# 4) Compute FI (0-1) and FI_z with fixed thresholds
# -----------------------------------------------------------------------------
N_deficits_min <- 10L
coverage_min <- 0.60

score_df <- tibble(id = base_df[[id_col]])
for (vn in selected$var_name) {
  vtype <- selected$type[selected$var_name == vn]
  score_df[[paste0("d_", vn)]] <- score_deficit(base_df[[vn]], vn, vtype)
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

  fi_eligible <- coverage >= coverage_min & observed_counts >= N_deficits_min
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
  tibble(flag = "rows_below_coverage_or_min_deficits", value = sum(!score_df$fi_eligible, na.rm = TRUE), detail = sprintf("coverage_min=%.2f;N_deficits_min=%d", coverage_min, N_deficits_min)),
  tibble(flag = "selected_deficits_lt_10", value = as.integer(n_deficits < 10), detail = sprintf("selected_deficits=%d", n_deficits)),
  tibble(flag = "used_missingness_sensitivity_pmiss_0_30", value = as.integer(use_sensitivity), detail = ifelse(use_sensitivity, "primary eligible deficits < 10", "primary branch sufficient")),
  tibble(flag = "fi_all_na", value = as.integer(all(is.na(score_df$fi))), detail = "All rows NA after eligibility gate")
)
write_agg_csv(red_flags, "k40_red_flags.csv", notes = "Deterministic red flag checks")

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

receipt_lines <- c(
  sprintf("timestamp=%s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  sprintf("external_dir=%s", external_dir),
  sprintf("external_csv=%s", external_csv),
  sprintf("external_rds=%s", external_rds),
  sprintf("rows_exported=%d", nrow(patient_out)),
  sprintf("cols_exported=%d", ncol(patient_out)),
  sprintf("md5_csv=%s", md5_file(external_csv)),
  sprintf("md5_rds=%s", md5_file(external_rds)),
  sprintf("n_selected_deficits=%d", n_deficits),
  sprintf("coverage_min=%.2f", coverage_min),
  sprintf("N_deficits_min=%d", N_deficits_min),
  "governance=patient-level outputs written only under DATA_ROOT"
)
write_agg_txt(receipt_lines, "k40_patient_level_output_receipt.txt", notes = "External patient-level output receipt")

# Decision log
log_lines <- c(
  sprintf("timestamp=%s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  sprintf("data_root=%s", data_root),
  sprintf("k33_path=%s", base_path),
  sprintf("k32_path=%s", ifelse(is.na(resolved$k32), "NA", resolved$k32)),
  sprintf("primary_missingness_threshold=%.2f", 0.20),
  sprintf("sensitivity_missingness_threshold=%.2f", 0.30),
  sprintf("used_sensitivity=%s", as.character(use_sensitivity)),
  sprintf("eligible_deficits_primary=%d", nrow(primary_eligible)),
  sprintf("selected_deficits=%d", n_deficits),
  sprintf("N_deficits_min=%d", N_deficits_min),
  sprintf("coverage_min=%.2f", coverage_min),
  "direction_rule=no_correlation_driven_flipping;codebook_or_lineage_only",
  "redundancy_rule=diagnosis>functional_limitation>symptom_self_report>medication_proxy"
)
write_agg_txt(log_lines, "k40_decision_log.txt", notes = "Deterministic K40 decisions and thresholds")

session_path <- save_sessioninfo_manifest(outputs_dir = outputs_dir, manifest_path = manifest_path, script = script_label)
session_alias <- file.path(outputs_dir, "k40_sessioninfo.txt")
file.copy(session_path, session_alias, overwrite = TRUE)
append_artifact("k40_sessioninfo.txt", "sessioninfo", session_alias, notes = "K40 session info alias")

message("K40 completed.")
