# R/functions/qc.R

suppressPackageStartupMessages({
  library(here)
  library(tibble)
  library(readr)
  library(dplyr)
})

# Load canonical init/manifest functions
source(here::here("R", "functions", "init.R"))

# --- QC Utilities --------------------------------------------------------------

qc_write_csv <- function(tbl, path, script, manifest_path, outputs_dir, notes = NA_character_) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(tbl, path, row.names = FALSE)
  
  # Use canonical manifest logic
  append_manifest(
    manifest_row(script = script, 
                 label = tools::file_path_sans_ext(basename(path)), 
                 path = get_relpath(path), 
                 kind = "qc_csv",
                 notes = notes),
    manifest_path
  )
  invisible(path)
}

qc_write_png <- function(path, script, manifest_path, outputs_dir, plot_fn, notes = NA_character_) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  grDevices::png(path, width = 1200, height = 900)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot_fn()
  
  # Use canonical manifest logic
  append_manifest(
    manifest_row(script = script, 
                 label = tools::file_path_sans_ext(basename(path)), 
                 path = get_relpath(path), 
                 kind = "qc_png",
                 notes = notes),
    manifest_path
  )
  invisible(path)
}

detect_shape <- function(df, mapping) {
  has_long <- all(mapping$long %in% names(df))
  has_wide <- all(mapping$wide %in% names(df))
  if (isTRUE(has_long)) return("LONG")
  if (isTRUE(has_wide)) return("WIDE")
  "UNKNOWN"
}

qc_types <- function(df, req_cols) {
  missing_cols <- setdiff(req_cols, names(df))
  types_df <- data.frame(
    variable = intersect(req_cols, names(df)),
    class = sapply(df[intersect(req_cols, names(df))], function(x) paste(class(x), collapse = "|")),
    stringsAsFactors = FALSE
  )
  status <- data.frame(
    check = "types",
    ok = length(missing_cols) == 0,
    missing_cols = paste(missing_cols, collapse = ";"),
    stringsAsFactors = FALSE
  )
  list(status = status, types = types_df, missing_cols = missing_cols)
}

qc_id_integrity_long <- function(df, id_col, time_col) {
  key <- paste(df[[id_col]], df[[time_col]], sep = "__")
  n_dup_keys <- sum(duplicated(key))
  tab <- with(df, table(df[[id_col]], df[[time_col]]))
  n_timepoints <- rowSums(tab > 0)
  coverage_dist <- as.data.frame(table(n_timepoints), stringsAsFactors = FALSE)
  names(coverage_dist) <- c("n_timepoints", "n_ids")
  coverage_dist$n_timepoints <- as.integer(as.character(coverage_dist$n_timepoints))

  summary <- data.frame(
    check = "id_integrity",
    n_rows = nrow(df),
    n_unique_id = length(unique(df[[id_col]])),
    n_dup_id_time = n_dup_keys,
    stringsAsFactors = FALSE
  )
  list(summary = summary, coverage = coverage_dist)
}

qc_time_levels <- function(df, time_col, expected_levels = NULL) {
  time_levels <- sort(unique(df[[time_col]]))
  ok <- TRUE
  expected <- ""
  if (!is.null(expected_levels) && length(expected_levels) > 0) {
    expected <- paste(expected_levels, collapse = ";")
    ok <- all(time_levels %in% expected_levels) && all(expected_levels %in% time_levels)
  }
  if (!ok) {
    ok <- all(time_levels %in% c(0, 1, "0", "1")) && length(time_levels) == 2
  }
  status <- data.frame(
    check = "time_levels",
    observed = paste(time_levels, collapse = ";"),
    expected = expected,
    ok = ok,
    stringsAsFactors = FALSE
  )
  list(levels = data.frame(time_level = time_levels), status = status)
}

qc_fof_levels <- function(df, fof_col, expected_levels = NULL) {
  vals <- sort(unique(df[[fof_col]]))
  ok <- length(vals) == 2
  if (!is.null(expected_levels) && length(expected_levels) > 0) {
    ok <- ok && all(vals %in% expected_levels)
  }
  data.frame(
    check = "fof_levels",
    observed_levels = paste(vals, collapse = ";"),
    n_levels = length(vals),
    ok = ok,
    stringsAsFactors = FALSE
  )
}

qc_missingness_overall <- function(df, req_cols) {
  data.frame(
    variable = req_cols,
    n = sapply(df[req_cols], length),
    n_missing = sapply(df[req_cols], function(x) sum(is.na(x))),
    pct_missing = round(100 * sapply(df[req_cols], function(x) sum(is.na(x))) /
                          sapply(df[req_cols], length), 1),
    stringsAsFactors = FALSE
  )
}

qc_missingness_by_fof_time <- function(df, fof_col, time_col, outcome_col) {
  if (all(is.na(df[[fof_col]])) || all(is.na(df[[time_col]]))) {
    return(data.frame(
      FOF_status = character(0),
      time = character(0),
      n_rows = integer(0),
      n_missing_Composite_Z = integer(0),
      pct_missing_Composite_Z = numeric(0),
      stringsAsFactors = FALSE
    ))
  }
  n_rows <- as.data.frame(with(df, table(df[[fof_col]], df[[time_col]])), stringsAsFactors = FALSE)
  names(n_rows) <- c("FOF_status", "time", "n_rows")

  n_miss <- as.data.frame(with(df, table(df[[fof_col]], df[[time_col]], is.na(df[[outcome_col]]))),
                          stringsAsFactors = FALSE)
  names(n_miss) <- c("FOF_status", "time", "is_na_Composite_Z", "n")
  n_miss <- n_miss[n_miss$is_na_Composite_Z == "TRUE", c("FOF_status", "time", "n")]
  names(n_miss)[3] <- "n_missing_Composite_Z"

  merged <- merge(n_rows, n_miss, by = c("FOF_status", "time"), all.x = TRUE)
  merged$n_missing_Composite_Z[is.na(merged$n_missing_Composite_Z)] <- 0
  merged$pct_missing_Composite_Z <- round(100 * merged$n_missing_Composite_Z / merged$n_rows, 1)
  merged
}

qc_delta_check_optional <- function(df_wide, id_col, baseline_col, follow_col, delta_col, tol = 1e-8) {
  out <- data.frame(
    check = "delta",
    applicable = FALSE,
    reason = "delta not found",
    stringsAsFactors = FALSE
  )
  if (!delta_col %in% names(df_wide)) return(out)
  out <- data.frame(
    check = "delta",
    applicable = TRUE,
    n_ids = NA_integer_,
    n_missing_delta_reported = NA_integer_,
    n_mismatch = NA_integer_,
    max_abs_diff = NA_real_,
    tolerance = tol,
    stringsAsFactors = FALSE
  )
  if (!all(c(id_col, baseline_col, follow_col) %in% names(df_wide))) return(out)

  base <- data.frame(id = df_wide[[id_col]], Composite_Z_baseline = df_wide[[baseline_col]])
  foll <- data.frame(id = df_wide[[id_col]], Composite_Z_12m = df_wide[[follow_col]])
  w <- merge(base, foll, by = "id", all = FALSE)
  delta_calc <- w$Composite_Z_12m - w$Composite_Z_baseline
  d <- data.frame(id = df_wide[[id_col]], delta_reported = df_wide[[delta_col]])
  w2 <- merge(w, d, by = "id", all.x = TRUE)
  diff <- w2$delta_reported - delta_calc
  ok_vec <- is.na(diff) | abs(diff) <= tol

  out$n_ids <- nrow(w2)
  out$n_missing_delta_reported <- sum(is.na(w2$delta_reported))
  out$n_mismatch <- sum(!ok_vec, na.rm = TRUE)
  out$max_abs_diff <- max(abs(diff), na.rm = TRUE)
  out
}

qc_outcome_summary <- function(df, outcome_col) {
  x <- df[[outcome_col]]
  if (!is.numeric(x)) {
    x <- suppressWarnings(as.numeric(x))
  }
  data.frame(
    n = length(x),
    n_missing = sum(is.na(x)),
    n_nonfinite = sum(!is.finite(x), na.rm = TRUE),
    mean = mean(x, na.rm = TRUE),
    sd = stats::sd(x, na.rm = TRUE),
    q01 = as.numeric(stats::quantile(x, 0.01, na.rm = TRUE)),
    q05 = as.numeric(stats::quantile(x, 0.05, na.rm = TRUE)),
    q50 = as.numeric(stats::quantile(x, 0.50, na.rm = TRUE)),
    q95 = as.numeric(stats::quantile(x, 0.95, na.rm = TRUE)),
    q99 = as.numeric(stats::quantile(x, 0.99, na.rm = TRUE)),
    stringsAsFactors = FALSE
  )
}

qc_status_gatekeeper <- function(status_df, status_path, script, manifest_path, outputs_dir) {
  overall_pass <- all(status_df$ok)
  status_df$overall_pass <- overall_pass
  qc_write_csv(status_df, status_path, script, manifest_path, outputs_dir,
               notes = "QC status summary")
  list(overall_pass = overall_pass, status = status_df)
}