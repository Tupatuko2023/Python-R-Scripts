#!/usr/bin/env Rscript
# ==============================================================================
# K18_QC - Stop-the-line QC run for FOF_status x time pipeline
# File tag: K18_QC.V1_qc-run.R
# Purpose: Run QC checks from QC_CHECKLIST.md on analysis data (long preferred;
#          wide supported), write qc_* artifacts, and update manifest.
#
# Outcome: QC artifacts only (no modeling)
# Predictors: FOF_status, time
# Grouping variable: id
#
# Required vars (long; from data_dictionary.csv):
# id, time, FOF_status, Composite_Z
#
# Required vars (wide helper; from data_dictionary.csv):
# id, FOF_status, composite_z0, composite_z12
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (not used; no randomness)
#
# Outputs + manifest:
# - script_label: K18_QC (canonical)
# - outputs dir: R-scripts/K18/outputs/K18_QC/qc/  (resolved via init_paths("K18"))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load data (no in-place modification)
# 03) Detect shape LONG/WIDE (or --shape)
# 04) Run QC checks and write artifacts
# 05) Stop if any required checks fail
# ==============================================================================
#
# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K18_QC"
}

# Prefer script_label from parent directory (e.g., R-scripts/K18/...) to enforce output discipline.
script_label <- if (length(file_arg) > 0) {
  script_dir <- dirname(sub("^--file=", "", file_arg[1]))
  parent_dir <- basename(normalizePath(script_dir, winslash = "/", mustWork = FALSE))
  if (grepl("^K[0-9]+$", parent_dir)) {
    parent_dir
  } else {
    # Fallback: legacy behavior from filename (e.g., K18_QC.V1_qc-run -> K18_QC)
    label <- sub("\\.V.*$", "", script_base)
    if (is.na(label) || label == "") "K18_QC" else label
  }
} else {
  "K18_QC"
}

script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else ""
project_root <- if (nzchar(script_path)) {
  dirname(dirname(dirname(normalizePath(script_path))))
} else {
  getwd()
}
setwd(project_root)

rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$|qc_)"),
   envir = .GlobalEnv)

source(file.path(project_root, "R", "functions", "qc.R"))
source(file.path(project_root, "R", "functions", "init.R"))
source(file.path(project_root, "R", "functions", "variable_standardization.R"))

paths <- init_paths(script_label)
outputs_dir   <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

# For QC scripts, use K18_QC as manifest script label (canonical per header)
# but K18 for init_paths to get correct outputs_dir
manifest_script_label <- "K18_QC"

qc_dir <- file.path(outputs_dir, manifest_script_label, "qc")
dir.create(qc_dir, recursive = TRUE, showWarnings = FALSE)

get_arg <- function(flag, default = NULL) {
  args <- commandArgs(trailingOnly = TRUE)
  i <- match(flag, args)
  if (is.na(i)) return(default)
  if (i == length(args)) return(default)
  args[[i + 1]]
}

data_path <- get_arg("--data")
shape <- toupper(get_arg("--shape", "AUTO")) # AUTO | LONG | WIDE
dict_path <- get_arg("--dict", "data/data_dictionary.csv")

if (is.null(data_path) || !nzchar(data_path)) {
  stop("ERROR: --data is required (path to CSV).", call. = FALSE)
}
if (!file.exists(data_path)) {
  stop("ERROR: data file not found: ", data_path, call. = FALSE)
}
if (!file.exists(dict_path)) {
  stop("ERROR: dictionary file not found: ", dict_path, call. = FALSE)
}
if (!shape %in% c("AUTO", "LONG", "WIDE")) {
  stop("ERROR: --shape must be one of AUTO|LONG|WIDE.", call. = FALSE)
}

dd <- utils::read.csv(dict_path, stringsAsFactors = FALSE, check.names = FALSE)
# Update check to match data_dictionary.csv actual keys
required_vars <- c("id", "time", "FOF_status", "Composite_Z", "Composite_Z0",
                   "Composite_Z2", "Delta_Composite_Z")
missing_req <- setdiff(required_vars, dd$variable)
if (length(missing_req) > 0) {
  stop("ERROR: data_dictionary.csv is missing required variable rows: ",
       paste(missing_req, collapse = ", "), call. = FALSE)
}

mapping <- list(
  long = c("id", "time", "FOF_status", "Composite_Z"),
  wide = c("id", "FOF_status", "composite_z0", "composite_z12")
)

df_raw <- utils::read.csv(data_path, stringsAsFactors = FALSE, check.names = FALSE)

# --- Variable Standardization ------------------------------------------------
# Try to locate spec relative to project root or current dir
spec_candidates <- c(
  file.path(project_root, "data", "VARIABLE_STANDARDIZATION.csv"),
  file.path("data", "VARIABLE_STANDARDIZATION.csv")
)
spec_path <- spec_candidates[file.exists(spec_candidates)][1]

if (!is.na(spec_path)) {
  cat("Running variable standardization using spec:", spec_path, "\n")
  std_spec <- read_standardization_spec(spec_path)
  
  # Run standardization (stops on strict verify hits or conflicts)
  std_res <- standardize_names(df_raw, std_spec, strict_verify = TRUE)
  df_raw <- std_res$df
  
  # Log artifacts
  qc_write_csv(std_res$renames, file.path(qc_dir, "qc_variable_standardization_renames.csv"),
               script_label, manifest_path, outputs_dir, notes = "Variable standardization renames")
  qc_write_csv(std_res$verify_hits, file.path(qc_dir, "qc_variable_standardization_verify_hits.csv"),
               script_label, manifest_path, outputs_dir, notes = "Variable standardization verify hits")
  qc_write_csv(std_res$conflicts, file.path(qc_dir, "qc_variable_standardization_conflicts.csv"),
               script_label, manifest_path, outputs_dir, notes = "Variable standardization conflicts")
  
} else {
  warning("VARIABLE_STANDARDIZATION.csv not found. Skipping standardization step.")
}
# -----------------------------------------------------------------------------

shape_detected <- detect_shape(df_raw, mapping)
if (shape == "AUTO" && shape_detected == "UNKNOWN") {
  stop("ERROR: could not detect LONG or WIDE shape from dictionary mapping.", call. = FALSE)
}
shape_final <- if (shape == "AUTO") shape_detected else shape

df_long <- df_raw
if (shape_final == "WIDE") {
  if (!all(mapping$wide %in% names(df_raw))) {
    stop("ERROR: WIDE requested but required columns missing: ",
         paste(setdiff(mapping$wide, names(df_raw)), collapse = ", "),
         call. = FALSE)
  }
  base <- data.frame(
    id = df_raw$id,
    time = "baseline",
    FOF_status = df_raw$FOF_status,
    Composite_Z = df_raw$composite_z0,
    stringsAsFactors = FALSE
  )
  foll <- data.frame(
    id = df_raw$id,
    time = "12m",
    FOF_status = df_raw$FOF_status,
    Composite_Z = df_raw$composite_z12,
    stringsAsFactors = FALSE
  )
  df_long <- rbind(base, foll)
}

req_cols <- c("id", "time", "FOF_status", "Composite_Z")
for (cname in req_cols) {
  if (!cname %in% names(df_long)) df_long[[cname]] <- NA
}

profile <- data.frame(
  check = "profile",
  shape = shape_final,
  n_rows = nrow(df_long),
  n_cols = ncol(df_long),
  stringsAsFactors = FALSE
)
qc_write_csv(profile, file.path(qc_dir, "qc_profile.csv"), manifest_script_label, manifest_path, outputs_dir,
             notes = "QC profile")

types_out <- qc_types(df_long, req_cols)
qc_write_csv(types_out$status, file.path(qc_dir, "qc_types_status.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "Required columns + types status")
qc_write_csv(types_out$types, file.path(qc_dir, "qc_types.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "Required columns types")

id_out <- qc_id_integrity_long(df_long, "id", "time")
qc_write_csv(id_out$summary, file.path(qc_dir, "qc_uniqueness.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "Uniqueness of (id,time)")
qc_write_csv(id_out$coverage, file.path(qc_dir, "qc_id_timepoint_coverage_dist.csv"),
             manifest_script_label, manifest_path, outputs_dir, notes = "ID timepoint coverage distribution")

time_allowed <- NULL
time_row <- dd[dd$variable == "time", , drop = FALSE]
if (nrow(time_row) > 0) {
  allowed <- time_row$allowed_values_or_coding[[1]]
  time_allowed <- unique(unlist(regmatches(allowed, gregexpr("[A-Za-z0-9]+", allowed))))
  time_allowed <- time_allowed[time_allowed %in% c("baseline", "12m", "m12")]
}
time_out <- qc_time_levels(df_long, "time", time_allowed)
qc_write_csv(time_out$levels, file.path(qc_dir, "qc_time_levels.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "Observed time levels")
qc_write_csv(time_out$status, file.path(qc_dir, "qc_time_levels_status.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "Time levels status")

fof_allowed <- NULL
fof_row <- dd[dd$variable == "FOF_status", , drop = FALSE]
if (nrow(fof_row) > 0) {
  allowed <- fof_row$allowed_values_or_coding[[1]]
  fof_allowed <- unique(unlist(regmatches(allowed, gregexpr("[A-Za-z0-9]+", allowed))))
  fof_allowed <- fof_allowed[fof_allowed %in% c("nonFOF", "FOF", "0", "1")]
}
fof_out <- qc_fof_levels(df_long, "FOF_status", fof_allowed)
qc_write_csv(fof_out, file.path(qc_dir, "qc_fof_levels.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "FOF_status levels")

if (nrow(time_out$status) == 0) {
  stop("QC FAIL: time_out$status is empty; cannot construct time_details.", call. = FALSE)
}
time_details <- paste0(
  "observed_raw=", time_out$status$observed_raw[[1]],
  ";observed_canonical=", time_out$status$observed_canonical[[1]],
  ";expected_raw=", time_out$status$expected_raw[[1]],
  ";expected_canonical=", time_out$status$expected_canonical[[1]]
)
if (nrow(fof_out) == 0) {
  stop("QC FAIL: fof_out is empty; cannot construct fof_details.", call. = FALSE)
}
fof_details <- paste0(
  "observed_raw=", fof_out$observed_raw[[1]],
  ";observed_canonical=", fof_out$observed_canonical[[1]],
  ";expected_raw=", fof_out$expected_raw[[1]],
  ";expected_canonical=", fof_out$expected_canonical[[1]]
)

miss_overall <- qc_missingness_overall(df_long, req_cols)
qc_write_csv(miss_overall, file.path(qc_dir, "qc_missingness_overall.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "Missingness overall")

miss_group <- qc_missingness_by_fof_time(df_long, "FOF_status", "time", "Composite_Z")
qc_write_csv(miss_group, file.path(qc_dir, "qc_missingness_by_fof_time.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "Missingness by FOF_status x time")

delta_out <- qc_delta_check_optional(df_raw, "id", "composite_z0", "composite_z12",
                                     "delta_composite_z", tol = 1e-8)
qc_write_csv(delta_out, file.path(qc_dir, "qc_delta_check.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "Delta check (optional)")

outcome_summary <- qc_outcome_summary(df_long, "Composite_Z")
qc_write_csv(outcome_summary, file.path(qc_dir, "qc_outcome_summary.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "Outcome summary")
qc_write_png(file.path(qc_dir, "qc_outcome_hist.png"), manifest_script_label,
             manifest_path, outputs_dir, plot_fn = function() {
               x <- df_long$Composite_Z
               if (!is.numeric(x)) x <- suppressWarnings(as.numeric(x))
               if (all(is.na(x))) {
                 graphics::plot.new()
                 graphics::title(main = "Composite_Z Distribution (not numeric)")
                 graphics::text(0.5, 0.5, "Composite_Z is not numeric or all NA")
               } else {
                 graphics::hist(x, main = "Composite_Z Distribution", xlab = "Composite_Z")
               }
             }, notes = "Outcome distribution histogram")

row_watch <- data.frame(
  step = "qc_input",
  n_rows = nrow(df_long),
  n_unique_id = length(unique(df_long$id)),
  n_missing_Composite_Z = sum(is.na(df_long$Composite_Z)),
  stringsAsFactors = FALSE
)
qc_write_csv(row_watch, file.path(qc_dir, "qc_row_id_watch.csv"), manifest_script_label,
             manifest_path, outputs_dir, notes = "Row/id watch")

status_df <- data.frame(
  check = c("types", "id_integrity", "time_levels", "fof_levels", "delta_check", "outcome_nonfinite"),
  ok = c(
    isTRUE(types_out$status$ok[[1]]) && is.numeric(df_long$Composite_Z),
    id_out$summary$n_dup_id_time[[1]] == 0,
    isTRUE(time_out$status$ok[[1]]),
    isTRUE(fof_out$ok[[1]]),
    if (isTRUE(delta_out$applicable[[1]])) delta_out$n_mismatch[[1]] == 0 else TRUE,
    outcome_summary$n_nonfinite[[1]] == 0
  ),
  details = c(
    if (length(types_out$missing_cols) > 0) paste(types_out$missing_cols, collapse = ";") else "",
    paste0("n_dup_id_time=", id_out$summary$n_dup_id_time[[1]]),
    time_details,
    fof_details,
    if (isTRUE(delta_out$applicable[[1]])) paste0("n_mismatch=", delta_out$n_mismatch[[1]]) else "not_applicable",
    paste0("n_nonfinite=", outcome_summary$n_nonfinite[[1]])
  ),
  stringsAsFactors = FALSE
)

gate <- qc_status_gatekeeper(status_df, file.path(qc_dir, "qc_status_summary.csv"),
                             script_label, manifest_path, outputs_dir)

session_path <- file.path(qc_dir, "qc_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest(manifest_row(manifest_script_label, "qc_sessioninfo",
                                   get_relpath(session_path),
                                   "sessionInfo"), manifest_path)

if (requireNamespace("renv", quietly = TRUE)) {
  renv_path <- file.path(qc_dir, "qc_renv_diagnostics.txt")
  writeLines(capture.output(renv::diagnostics()), con = renv_path)
  append_manifest(manifest_row(manifest_script_label, "qc_renv_diagnostics",
                                     get_relpath(renv_path),
                                     "renv diagnostics"), manifest_path)
}

if (!isTRUE(gate$overall_pass)) {
  stop("QC failed: one or more required checks failed. See qc_status_summary.csv", call. = FALSE)
}

cat("QC OK: all required checks passed.\n")
