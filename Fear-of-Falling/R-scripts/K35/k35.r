#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
})

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

latent_col <- first_existing(d, c("capacity_score_cfa_primary", "capacity_score_latent_primary"))
z5_col <- first_existing(d, c("capacity_score_z5_primary"))
z4_col <- first_existing(d, c("capacity_score_z4_primary"))

if (is.na(latent_col) || is.na(z5_col)) {
  stop(paste0("Missing required score columns in K32 dataset. latent=", latent_col, ", z5=", z5_col), call. = FALSE)
}

latent <- suppressWarnings(as.numeric(d[[latent_col]]))
z5 <- suppressWarnings(as.numeric(d[[z5_col]]))
z4 <- if (!is.na(z4_col)) suppressWarnings(as.numeric(d[[z4_col]])) else rep(NA_real_, length(latent))

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
  latent_col = latent_col,
  z5_col = z5_col,
  admissible = admissible_flag,
  latent_non_missing_n = sum(!is.na(latent)),
  latent_missing_n = sum(is.na(latent)),
  latent_missing_share = mean(is.na(latent)),
  z5_non_missing_n = sum(!is.na(z5))
)

# 2) distribution
dist_tbl <- bind_rows(
  tibble(score = "latent_primary", value = latent),
  tibble(score = "z5_primary", value = z5),
  tibble(score = "z4_primary", value = z4)
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

# 3) latent vs z composite
ok <- complete.cases(latent, z5)
diff_vec <- latent[ok] - z5[ok]
vs_tbl <- tibble(
  metric = c("pearson_r", "bland_altman_mean_diff", "bland_altman_sd_diff", "n_complete"),
  value = c(
    safe_cor(latent, z5),
    ifelse(length(diff_vec) > 0, mean(diff_vec), NA_real_),
    ifelse(length(diff_vec) > 1, stats::sd(diff_vec), NA_real_),
    sum(ok)
  )
)

notes_path <- file.path(outputs_dir, "k35_capacity_reporting_notes.txt")
notes <- c(
  "K35 Capacity CFA Behavior Report",
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("input_path=", in_obj$path),
  paste0("admissible_flag=", as.character(admissible_flag)),
  "Scope: aggregate-only reporting; no K32/K26 model-logic modifications.",
  "Governance: patient-level data read from DATA_ROOT/external sources; no row-level repo exports."
)
writeLines(notes, notes_path)

p_behavior <- file.path(outputs_dir, "k35_capacity_behavior_summary.csv")
p_dist <- file.path(outputs_dir, "k35_capacity_distribution.csv")
p_vs <- file.path(outputs_dir, "k35_capacity_vs_z_composite.csv")

readr::write_csv(behavior_tbl, p_behavior, na = "")
readr::write_csv(dist_tbl, p_dist, na = "")
readr::write_csv(vs_tbl, p_vs, na = "")

append_manifest_safe("k35_capacity_behavior_summary", "table_csv", p_behavior, n = nrow(behavior_tbl), notes = "Aggregate K32 behavior summary")
append_manifest_safe("k35_capacity_distribution", "table_csv", p_dist, n = nrow(dist_tbl), notes = "Aggregate score distribution diagnostics")
append_manifest_safe("k35_capacity_vs_z_composite", "table_csv", p_vs, n = nrow(vs_tbl), notes = "Latent vs z5 aggregate comparison")
append_manifest_safe("k35_capacity_reporting_notes", "text", notes_path, notes = "K35 aggregate reporting notes")

session_path <- file.path(outputs_dir, "k35_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), session_path)
append_manifest_safe("k35_sessioninfo", "sessioninfo", session_path, notes = "K35 session info")

cat("K35 outputs written to:", outputs_dir, "\n")
