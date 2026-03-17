#!/usr/bin/env Rscript
# ==============================================================================
# K35 - Aggregate K32 Capacity Reporting
# File tag: K35.V1_capacity-behavior-report.R
# Purpose: Summarize aggregate behavior of the canonical K32 capacity outputs.
#
# Outcome: Aggregate K32 capacity summary tables
# Predictors: capacity_score_latent_primary, capacity_score_z3_primary
# Moderator/interaction: None
# Grouping variable: None
# Covariates: None
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id
# capacity_score_latent_primary
# capacity_score_z3_primary
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# capacity_score_z3_primary -> z-standardized fallback comparator
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: NA (set only when randomness is used: MI/bootstrap/resampling)
#
# Outputs + manifest:
# - script_label: K35 (canonical)
# - outputs dir: R-scripts/K35/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load aggregate K32 artifacts + patient-level externalized K32 dataset
# 03) Standardize vars + QC (sanity checks early)
# 04) Derive primary/fallback comparator labels
# 05) Prepare analysis dataset
# 06) Summarize score behavior
# 07) Save reporting tables
# 08) Save artifacts -> R-scripts/K35/outputs/
# 09) Append manifest row per artifact
# 10) Save sessionInfo / renv diagnostics to manifest/
# 11) EOF marker
# ==============================================================================
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
})

req_cols <- c("id", "capacity_score_latent_primary", "capacity_score_z3_primary")

script_label <- "K35"
source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(
      script = script_label,
      label = label,
      path = get_relpath(path),
      kind = kind,
      n = n,
      notes = notes
    ),
    manifest_path
  )
}

safe_cor <- function(x, y) {
  ok <- complete.cases(x, y)
  if (sum(ok) < 3) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok], method = "pearson"))
}

skewness_simple <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 3) return(NA_real_)
  s <- stats::sd(x)
  if (!is.finite(s) || s == 0) return(0)
  mean(((x - mean(x)) / s)^3)
}

resolve_k32 <- function() {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  candidates <- c()
  if (nzchar(data_root)) {
    candidates <- c(candidates,
      file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores_k32.rds"),
      file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores_k32.csv")
    )
  }
  candidates <- c(candidates,
    here::here("R-scripts", "K32", "outputs", "kaatumisenpelko_with_capacity_scores_k32.rds"),
    here::here("R-scripts", "K32", "outputs", "kaatumisenpelko_with_capacity_scores_k32.csv")
  )

  hit <- candidates[file.exists(candidates)][1]
  if (is.na(hit) || !nzchar(hit)) {
    stop(paste0("K35 could not locate K32 dataset. Tried:\n- ", paste(candidates, collapse = "\n- ")), call. = FALSE)
  }
  ext <- tolower(tools::file_ext(hit))
  list(path = normalizePath(hit), kind = ifelse(ext == "rds", "rds", "csv"))
}

read_dataset <- function(x) {
  if (x$kind == "rds") {
    as_tibble(readRDS(x$path))
  } else {
    as_tibble(readr::read_csv(x$path, show_col_types = FALSE))
  }
}

first_existing <- function(df, candidates) {
  hits <- candidates[candidates %in% names(df)]
  if (length(hits) == 0) return(NA_character_)
  hits[1]
}

k32_diag_path <- here::here("R-scripts", "K32", "outputs", "k32_cfa_diagnostics.csv")
k32_scores_path <- here::here("R-scripts", "K32", "outputs", "k32_scores_summary.csv")
if (!file.exists(k32_diag_path) || !file.exists(k32_scores_path)) {
  stop("Missing K32 diagnostics/scores outputs required for K35 summary.", call. = FALSE)
}

k32_diag <- readr::read_csv(k32_diag_path, show_col_types = FALSE)
k32_scores <- readr::read_csv(k32_scores_path, show_col_types = FALSE)

in_obj <- resolve_k32()
d <- read_dataset(in_obj)

primary_col <- first_existing(d, c("capacity_score_cfa_primary", "capacity_score_latent_primary"))
fallback_col <- first_existing(d, c("capacity_score_z3_primary", "capacity_score_z3_sensitivity", "capacity_score_z5_primary"))

if (is.na(primary_col) || is.na(fallback_col)) {
  stop(paste0("Missing required score columns in K32 dataset. primary=", primary_col, ", fallback=", fallback_col), call. = FALSE)
}

primary_score <- suppressWarnings(as.numeric(d[[primary_col]]))
fallback_score <- suppressWarnings(as.numeric(d[[fallback_col]]))

# 1) behavior summary
admissible_flag <- if ("admissible" %in% names(k32_diag)) {
  any(tolower(as.character(k32_diag$admissible)) %in% c("true", "1", "yes"))
} else {
  NA
}

behavior_tbl <- tibble(
  source_path = in_obj$path,
  source_kind = in_obj$kind,
  n_rows = nrow(d),
  n_cols = ncol(d),
  primary_col = primary_col,
  fallback_col = fallback_col,
  admissible = admissible_flag,
  primary_non_missing_n = sum(!is.na(primary_score)),
  primary_missing_n = sum(is.na(primary_score)),
  primary_missing_share = mean(is.na(primary_score)),
  fallback_non_missing_n = sum(!is.na(fallback_score))
)

# 2) distribution
dist_tbl <- bind_rows(
  tibble(score = "locomotor_capacity_primary", value = primary_score),
  tibble(score = "z3_fallback", value = fallback_score)
) %>%
  group_by(score) %>%
  summarise(
    n = sum(!is.na(value)),
    mean = mean(value, na.rm = TRUE),
    sd = stats::sd(value, na.rm = TRUE),
    skewness = skewness_simple(value),
    min = min(value, na.rm = TRUE),
    max = max(value, na.rm = TRUE),
    pct_lt_m2sd = ifelse(is.finite(sd) & sd > 0, mean(value < (mean - 2 * sd), na.rm = TRUE) * 100, NA_real_),
    pct_gt_p2sd = ifelse(is.finite(sd) & sd > 0, mean(value > (mean + 2 * sd), na.rm = TRUE) * 100, NA_real_),
    .groups = "drop"
  )

# 3) primary vs fallback
ok <- complete.cases(primary_score, fallback_score)
diff_vec <- primary_score[ok] - fallback_score[ok]
vs_tbl <- tibble(
  metric = c("pearson_r", "bland_altman_mean_diff", "bland_altman_sd_diff", "n_complete"),
  value = c(
    safe_cor(primary_score, fallback_score),
    ifelse(length(diff_vec) > 0, mean(diff_vec), NA_real_),
    ifelse(length(diff_vec) > 1, stats::sd(diff_vec), NA_real_),
    sum(ok)
  )
)

notes_path <- file.path(outputs_dir, "k35_capacity_reporting_notes.txt")
notes <- c(
  "K35 locomotor_capacity primary / z3 fallback behavior report",
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("input_path=", in_obj$path),
  paste0("primary_col=", primary_col),
  paste0("fallback_col=", fallback_col),
  paste0("admissible_flag=", as.character(admissible_flag)),
  "Scope: aggregate-only reporting; locomotor_capacity is primary and z3 is deterministic fallback/sensitivity.",
  "Governance: patient-level data read from DATA_ROOT/external sources; no row-level repo exports."
)
writeLines(notes, notes_path)

p_behavior <- file.path(outputs_dir, "k35_locomotor_capacity_behavior_summary.csv")
p_dist <- file.path(outputs_dir, "k35_locomotor_capacity_distribution.csv")
p_vs <- file.path(outputs_dir, "k35_locomotor_capacity_vs_z3_fallback.csv")

readr::write_csv(behavior_tbl, p_behavior, na = "")
readr::write_csv(dist_tbl, p_dist, na = "")
readr::write_csv(vs_tbl, p_vs, na = "")

append_manifest_safe("k35_locomotor_capacity_behavior_summary", "table_csv", p_behavior, n = nrow(behavior_tbl), notes = "Aggregate K32 primary/fallback behavior summary")
append_manifest_safe("k35_locomotor_capacity_distribution", "table_csv", p_dist, n = nrow(dist_tbl), notes = "Aggregate locomotor_capacity and z3 distribution diagnostics")
append_manifest_safe("k35_locomotor_capacity_vs_z3_fallback", "table_csv", p_vs, n = nrow(vs_tbl), notes = "locomotor_capacity primary vs z3 fallback comparison")
append_manifest_safe("k35_capacity_reporting_notes", "text", notes_path, notes = "K35 aggregate reporting notes")

session_path <- file.path(outputs_dir, "k35_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), session_path)
append_manifest_safe("k35_sessioninfo", "sessioninfo", session_path, notes = "K35 session info")

cat("K35 outputs written to:", outputs_dir, "\n")
