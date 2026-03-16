#!/usr/bin/env Rscript
# ==============================================================================
# K32_VALIDATION - Final Validation Layer for K32 Latent Capacity Score
# File: k32_validation.r
#
# Scope:
# - Analysis/reporting only.
# - No model changes, no score-construction changes, no externalization changes.
# - Produces aggregate validation artifacts in repo outputs.
# ==============================================================================
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
})

# --- Standard init -------------------------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_base <- if (length(file_arg) > 0) {
  sub("\\.[Rr]$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K32_VALIDATION"
}
script_label_raw <- sub("\\..*$", "", sub("\\.V.*$", "", script_base))
script_label <- toupper(script_label_raw)
if (is.na(script_label) || script_label == "") script_label <- "K32_VALIDATION"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths("K32")
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

# --- Helpers ------------------------------------------------------------------
dir_create <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

write_csv_safely <- function(df, path) {
  dir_create(dirname(path))
  readr::write_csv(df, path, na = "")
  path
}

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
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

safe_num <- function(x) suppressWarnings(as.numeric(x))

safe_cor <- function(x, y, method = "pearson") {
  ok <- complete.cases(x, y)
  if (sum(ok) < 3) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok], method = method))
}

skewness_simple <- function(x) {
  x <- x[is.finite(x)]
  n <- length(x)
  if (n < 3) return(NA_real_)
  s <- sd(x)
  if (!is.finite(s) || s == 0) return(0)
  mean(((x - mean(x)) / s)^3)
}

resolve_input <- function() {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  candidates <- c()

  if (nzchar(data_root)) {
    candidates <- c(
      candidates,
      file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores_k32.rds"),
      file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores_k32.csv")
    )
  }

  candidates <- c(
    candidates,
    here::here("R-scripts", "K32", "outputs", "kaatumisenpelko_with_capacity_scores_k32.rds"),
    here::here("R-scripts", "K32", "outputs", "kaatumisenpelko_with_capacity_scores_k32.csv")
  )

  hit <- candidates[file.exists(candidates)][1]
  if (is.na(hit) || !nzchar(hit)) {
    stop(
      paste0(
        "Could not locate K32 dataset. Tried:\n- ",
        paste(candidates, collapse = "\n- ")
      ),
      call. = FALSE
    )
  }

  ext <- tolower(tools::file_ext(hit))
  kind <- if (ext == "rds") "rds" else "csv"
  list(kind = kind, path = normalizePath(hit))
}

resolve_k15_input <- function() {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(data_root)) {
    return(list(found = FALSE, reason = "DATA_ROOT not set", kind = NA_character_, path = NA_character_))
  }

  candidates <- c(
    file.path(data_root, "paper_01", "frailty", "kaatumisenpelko_with_frailty_scores.rds"),
    file.path(data_root, "paper_01", "frailty", "kaatumisenpelko_with_frailty_scores.csv"),
    file.path(data_root, "paper_01", "k15", "kaatumisenpelko_with_frailty_scores.rds"),
    file.path(data_root, "paper_01", "k15", "kaatumisenpelko_with_frailty_scores.csv"),
    file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores.rds"),
    file.path(data_root, "paper_01", "capacity_scores", "kaatumisenpelko_with_capacity_scores.csv")
  )
  hit <- candidates[file.exists(candidates)][1]

  if (is.na(hit) || !nzchar(hit)) {
    return(list(found = FALSE, reason = "No K15-derived external dataset found under DATA_ROOT/paper_01", kind = NA_character_, path = NA_character_))
  }

  ext <- tolower(tools::file_ext(hit))
  kind <- if (ext == "rds") "rds" else "csv"
  list(found = TRUE, reason = "found", kind = kind, path = normalizePath(hit))
}

resolve_col <- function(df_names, preferred) {
  for (nm in preferred) {
    if (nm %in% df_names) return(nm)
  }
  NA_character_
}

read_dataset <- function(input_obj) {
  if (input_obj$kind == "rds") {
    as_tibble(readRDS(input_obj$path))
  } else {
    as_tibble(readr::read_csv(input_obj$path, show_col_types = FALSE))
  }
}

prepare_k15_frailty <- function(k15_df) {
  frailty_col <- resolve_col(names(k15_df), c("frailty_cat", "frailtycat", "frailty_group"))
  if (is.na(frailty_col)) {
    return(list(ok = FALSE, df = NULL, reason = "frailty column not found in K15-derived dataset"))
  }

  # Prefer baseline rows if a recognizable time marker exists.
  time_col <- resolve_col(names(k15_df), c("time", "timepoint", "wave", "visit", "mittauskerta", "aika"))
  if (!is.na(time_col)) {
    tv <- k15_df[[time_col]]
    keep <- rep(TRUE, nrow(k15_df))
    if (is.numeric(tv) || is.integer(tv)) {
      keep <- (tv == 0) | is.na(tv)
    } else {
      tv_chr <- tolower(trimws(as.character(tv)))
      keep <- tv_chr %in% c("0", "baseline", "t0", "bl", "")
    }
    k15_df <- k15_df[keep, , drop = FALSE]
  }

  list(ok = TRUE, df = k15_df, frailty_col = frailty_col, time_col = time_col, reason = "ok")
}

join_frailty_from_k15 <- function(k32_df) {
  k15_input <- resolve_k15_input()
  if (!isTRUE(k15_input$found)) {
    return(list(df = k32_df, joined = FALSE, frailty_col = NA_character_, note = k15_input$reason))
  }

  k15_df <- read_dataset(k15_input)
  prep <- prepare_k15_frailty(k15_df)
  if (!isTRUE(prep$ok)) {
    return(list(df = k32_df, joined = FALSE, frailty_col = NA_character_, note = prep$reason))
  }
  k15_df <- prep$df

  join_key <- resolve_col(names(k32_df), c("id", "participant_id", "subject_id", "study_id", "record_id", "tunniste"))
  if (is.na(join_key) || !(join_key %in% names(k15_df))) {
    return(list(df = k32_df, joined = FALSE, frailty_col = NA_character_, note = "No deterministic shared join key between K32 and K15 datasets"))
  }

  k15_join <- k15_df %>%
    transmute(
      .join_key = trimws(as.character(.data[[join_key]])),
      frailty_cat_from_k15 = as.character(.data[[prep$frailty_col]])
    ) %>%
    filter(!is.na(.join_key), .join_key != "") %>%
    distinct(.join_key, .keep_all = TRUE)

  out <- k32_df %>%
    mutate(.join_key = trimws(as.character(.data[[join_key]]))) %>%
    left_join(k15_join, by = ".join_key")

  list(
    df = out,
    joined = TRUE,
    frailty_col = "frailty_cat_from_k15",
    note = paste0("Joined frailty from K15 external dataset: ", k15_input$path, " using key ", join_key)
  )
}

# --- Load ---------------------------------------------------------------------
input <- resolve_input()
d <- read_dataset(input)

join_res <- join_frailty_from_k15(d)
d <- join_res$df

latent_col <- resolve_col(names(d), c("capacity_score_latent_primary", "capacity_score_cfa_primary"))
z3_col <- resolve_col(names(d), c("capacity_score_z3_primary"))
gait_col <- resolve_col(names(d), c("indicator_gait_primary_0", "indicator_gait_primary", "kavelynopeus_m_sek0"))
chair_col <- resolve_col(names(d), c("indicator_chair_capacity_0", "indicator_chair_capacity", "tuoli0"))
balance_col <- resolve_col(names(d), c("indicator_balance_capacity_0", "indicator_balance_capacity", "seisominen0"))
frailty_col <- if (isTRUE(join_res$joined) && "frailty_cat_from_k15" %in% names(d)) {
  "frailty_cat_from_k15"
} else {
  resolve_col(names(d), c("frailty_group", "frailtycat", "frailty_cat"))
}

if (is.na(latent_col) || is.na(z3_col) || is.na(gait_col) || is.na(chair_col) || is.na(balance_col)) {
  stop(
    paste0(
      "Missing required columns for validation.\n",
      "latent=", latent_col,
      ", z3=", z3_col,
      ", gait=", gait_col,
      ", chair=", chair_col,
      ", balance=", balance_col
    ),
    call. = FALSE
  )
}

latent <- safe_num(d[[latent_col]])
z3 <- safe_num(d[[z3_col]])
gait <- safe_num(d[[gait_col]])
chair <- safe_num(d[[chair_col]])
balance <- safe_num(d[[balance_col]])

# --- 1) Convergent validity ---------------------------------------------------
corr_tbl <- tibble(
  metric = c("latent_vs_z3", "latent_vs_gait", "latent_vs_chair", "latent_vs_balance"),
  method = "pearson",
  n_complete = c(
    sum(complete.cases(latent, z3)),
    sum(complete.cases(latent, gait)),
    sum(complete.cases(latent, chair)),
    sum(complete.cases(latent, balance))
  ),
  r = c(
    safe_cor(latent, z3),
    safe_cor(latent, gait),
    safe_cor(latent, chair),
    safe_cor(latent, balance)
  ),
  latent_col = latent_col,
  comparator_col = c(z3_col, gait_col, chair_col, balance_col)
)
path_corr <- file.path(outputs_dir, "k32_validation_correlations.csv")
write_csv_safely(corr_tbl, path_corr)
append_manifest_safe("k32_validation_correlations", "table_csv", path_corr, n = nrow(d))

# --- 2) Known-groups validity -------------------------------------------------
if (!is.na(frailty_col)) {
  g <- as.factor(d[[frailty_col]])
  ok <- complete.cases(latent, g)
  x <- latent[ok]
  grp <- droplevels(g[ok])

  kw <- kruskal.test(x ~ grp)
  n <- length(x)
  k <- nlevels(grp)
  eps2 <- if (n > k && k > 1) as.numeric((kw$statistic - k + 1) / (n - k)) else NA_real_

  med_tbl <- tibble(group = levels(grp)) %>%
    rowwise() %>%
    mutate(
      n_group = sum(grp == group, na.rm = TRUE),
      median_latent = median(x[grp == group], na.rm = TRUE)
    ) %>%
    ungroup()

  known_tbl <- bind_rows(
    tibble(
      section = "kruskal_wallis",
      frailty_col = frailty_col,
      statistic = as.numeric(kw$statistic),
      df = as.numeric(kw$parameter),
      p_value = as.numeric(kw$p.value),
      effect_size_epsilon2 = eps2,
      group = NA_character_,
      n_group = NA_real_,
      median_latent = NA_real_
    ) %>%
      mutate(note = join_res$note),
    med_tbl %>%
      transmute(
        section = "group_medians",
        frailty_col = frailty_col,
        statistic = NA_real_,
        df = NA_real_,
        p_value = NA_real_,
        effect_size_epsilon2 = NA_real_,
        group = as.character(group),
        n_group = as.numeric(n_group),
        median_latent = as.numeric(median_latent),
        note = join_res$note
      )
  )
} else {
  known_tbl <- tibble(
    section = "not_available",
    frailty_col = NA_character_,
    statistic = NA_real_,
    df = NA_real_,
    p_value = NA_real_,
    effect_size_epsilon2 = NA_real_,
    group = NA_character_,
    n_group = NA_real_,
    median_latent = NA_real_,
    note = paste0("Known-groups skipped deterministically. ", join_res$note)
  )
}

path_known <- file.path(outputs_dir, "k32_validation_known_groups.csv")
write_csv_safely(known_tbl, path_known)
append_manifest_safe("k32_validation_known_groups", "table_csv", path_known, n = nrow(d))

# --- 3) Distribution diagnostics ----------------------------------------------
lat_mu <- mean(latent, na.rm = TRUE)
lat_sd <- sd(latent, na.rm = TRUE)
low_thr <- lat_mu - 2 * lat_sd
high_thr <- lat_mu + 2 * lat_sd

dist_tbl <- tibble(
  score = "capacity_score_latent_primary",
  n_total = length(latent),
  n_non_missing = sum(!is.na(latent)),
  mean = lat_mu,
  sd = lat_sd,
  skewness = skewness_simple(latent),
  min = min(latent, na.rm = TRUE),
  max = max(latent, na.rm = TRUE),
  pct_lt_minus2sd = mean(latent < low_thr, na.rm = TRUE) * 100,
  pct_gt_plus2sd = mean(latent > high_thr, na.rm = TRUE) * 100
)

path_dist <- file.path(outputs_dir, "k32_validation_distribution.csv")
write_csv_safely(dist_tbl, path_dist)
append_manifest_safe("k32_validation_distribution", "table_csv", path_dist, n = nrow(d))

# --- 4) Latent vs z3 comparison -----------------------------------------------
ok_lz <- complete.cases(latent, z3)
diff_lz <- latent[ok_lz] - z3[ok_lz]

lz_tbl <- tibble(
  n_complete = sum(ok_lz),
  r_latent_z3 = safe_cor(latent, z3),
  bland_altman_mean_diff = mean(diff_lz, na.rm = TRUE),
  bland_altman_sd_diff = sd(diff_lz, na.rm = TRUE)
)

path_lz <- file.path(outputs_dir, "k32_validation_latent_vs_z3.csv")
write_csv_safely(lz_tbl, path_lz)
append_manifest_safe("k32_validation_latent_vs_z3", "table_csv", path_lz, n = nrow(d))

note_path <- file.path(outputs_dir, "k32_validation_upstream_dedup_note.txt")
note_lines <- c(
  "K32 validation upstream dedup note",
  "Validation reads the upstream K32 output as produced.",
  "Upstream `k32.r` now applies workbook-grounded person dedup before score derivation and canonical K50 export.",
  "This validation script does not run a second person-dedup pass."
)
writeLines(note_lines, con = note_path)
append_manifest_safe("k32_validation_upstream_dedup_note", "text", note_path, n = length(note_lines))

message("K32 validation complete. Outputs written to: ", outputs_dir)
