#!/usr/bin/env Rscript
# ==============================================================================
# 40_run_secure_panel_analysis.R
# Secure driver for Aim 2 panel analysis (FOF utilization & costs)
#
# Deterministic sequence (RUNBOOK_SECURE_EXECUTION.md):
#   1) 00_setup_env.R
#   2) (optional) frailty proxy integration
#   3) 20_qc_panel_summary.R
#   4) 30_models_panel_nb_gamma.R
#
# SECURITY (Option B):
# - Do not print or write row-level data under the repo.
# - DATA_ROOT is required; panel lives in DATA_ROOT/derived/aim2_panel.csv
# - Stdout/logs must never include absolute paths (redact/fail-closed).
# - Only export-safe, aggregated outputs may be copied to outputs/archive/<RUN_ID>/
# - Aggregates are double-gated: user intent + ALLOW_AGGREGATES=1
# ==============================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

# Load security utilities
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else NA_character_
script_dir  <- if (!is.na(script_path)) dirname(normalizePath(script_path, mustWork = FALSE)) else getwd()
project_dir <- script_dir
while (basename(project_dir) %in% c("R", "scripts", "10_table1", "10_table1_patient_characteristics_by_fof")) {
  project_dir <- dirname(project_dir)
}
source(file.path(project_dir, "R", "path_utils.R"))

# ========================
# A) Config & validations
# ========================

RUN_ID <- Sys.getenv("RUN_ID", unset = "")
if (RUN_ID == "") RUN_ID <- format(Sys.time(), "%Y%m%dT%H%M%S")

SEED   <- as.integer(Sys.getenv("SEED", unset = "20260130"))
B_BOOT <- as.integer(Sys.getenv("BOOTSTRAP_B", unset = "1000"))

RUN_QC_ONLY       <- tolower(Sys.getenv("RUN_QC_ONLY", unset = "false")) %in% c("1","true","yes")
RUN_MODELS_ONLY   <- tolower(Sys.getenv("RUN_MODELS_ONLY", unset = "false")) %in% c("1","true","yes")
DRY_RUN           <- tolower(Sys.getenv("DRY_RUN", unset = "false")) %in% c("1","true","yes")

ALLOW_AGGREGATES  <- Sys.getenv("ALLOW_AGGREGATES", unset = "") == "1"
USER_INTENDS_MODELS <- !RUN_QC_ONLY && !tolower(Sys.getenv("INTEND_AGGREGATES", unset = "false")) %in% c("0","false","no")

# Conservative QC gate thresholds (override via env vars if needed)
MAX_MISSING_SHARE_FOF     <- as.numeric(Sys.getenv("MAX_MISSING_SHARE_FOF", unset = "0.05"))
MAX_MISSING_SHARE_FRAILTY <- as.numeric(Sys.getenv("MAX_MISSING_SHARE_FRAILTY", unset = "0.10"))

DATA_ROOT <- Sys.getenv("DATA_ROOT", unset = "")
if (DATA_ROOT == "") stop("DATA_ROOT ei ole asetettu.")
if (!dir.exists(DATA_ROOT)) stop("DATA_ROOT-polku ei ole olemassa tai ei ole käytettävissä.")

panel_path <- safe_join_path(DATA_ROOT, "derived", "aim2_panel.csv")
if (!file.exists(panel_path)) stop("Paneeliaineisto puuttuu (odotettu: DATA_ROOT/derived/aim2_panel.csv).")
if (file.access(panel_path, 4) != 0) stop("Ei lukuoikeutta paneeliaineistoon (DATA_ROOT/derived/aim2_panel.csv).")

# Repo-relative outputs/logs (no absolute paths in messages)
dir.create("logs", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs", showWarnings = FALSE, recursive = TRUE)
dir.create(file.path("outputs", "archive", RUN_ID), showWarnings = FALSE, recursive = TRUE)
dir.create(file.path("outputs", "qc"), showWarnings = FALSE, recursive = TRUE)

logs_root    <- "logs"
outputs_root <- "outputs"
archive_root <- file.path("outputs", "archive", RUN_ID)

# ========================
# B) Secure logging helpers
# ========================

abs_path_regex <- "(^|[[:space:]])(/[^[:space:]]+)"
redact_paths <- function(x) {
  if (length(x) == 0) return(x)
  x <- gsub(DATA_ROOT, "<DATA_ROOT>", x, fixed = TRUE)
  x <- gsub(getwd(), "<REPO_ROOT>", x, fixed = TRUE)
  x <- gsub(abs_path_regex, "\\1<ABS_PATH>", x, perl = TRUE)
  x
}

write_log <- function(path, lines) {
  writeLines(redact_paths(lines), path, useBytes = TRUE)
}

log_msg <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste0(..., collapse = ""))
  # Ensure console output contains no absolute paths
  message(redact_paths(msg))
}

# Audit metadata (metadata-only; no absolute paths)
git_hash <- tryCatch(system("git rev-parse HEAD", intern = TRUE), error = function(e) NA_character_)
if (length(git_hash) == 0) git_hash <- NA_character_

meta_lines <- c(
  paste0("run_id: ", RUN_ID),
  paste0("timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("data_root_set: ", Sys.getenv("DATA_ROOT") != ""),
  paste0("panel_readable: ", file.exists(panel_path) && file.access(panel_path, 4) == 0),
  paste0("seed: ", SEED),
  paste0("bootstrap_B: ", B_BOOT),
  paste0("allow_aggregates_env: ", ALLOW_AGGREGATES),
  paste0("intend_aggregates_user: ", USER_INTENDS_MODELS),
  paste0("run_qc_only: ", RUN_QC_ONLY),
  paste0("run_models_only: ", RUN_MODELS_ONLY),
  paste0("dry_run: ", DRY_RUN),
  paste0("git_hash: ", ifelse(is.na(git_hash), "NA", git_hash)),
  paste0("R.version: ", R.version.string)
)
writeLines(meta_lines, file.path(logs_root, paste0(RUN_ID, "_run_metadata.txt")), useBytes = TRUE)

si <- redact_paths(capture.output(sessionInfo()))
writeLines(si, file.path(logs_root, paste0(RUN_ID, "_sessionInfo.txt")), useBytes = TRUE)

log_msg("Secure run started (40_run_secure_panel_analysis.R).")
log_msg("Validated DATA_ROOT + panel presence (no paths printed).")

# ========================
# C) Locate scripts (repo-relative)
# ========================

locate_script <- function(candidates) {
  for (p in candidates) {
    if (!is.na(p) && p != "" && file.exists(p)) return(p)
  }
  NA_character_
}

setup_script <- locate_script(c("R/00_setup_env.R", "00_setup_env.R", file.path("scripts", "00_setup_env.R")))
qc_script <- locate_script(c("R/20_qc_panel_summary.R", "20_qc_panel_summary.R", file.path("scripts", "20_qc_panel_summary.R")))
models_script <- locate_script(c("R/30_models_panel_nb_gamma.R", "30_models_panel_nb_gamma.R", file.path("scripts", "30_models_panel_nb_gamma.R")))

# Optional frailty proxy step (only if present)
frailty_script <- locate_script(c(
  "K15_MAIN.V1_frailty-proxy.R",
  file.path("scripts", "K15_MAIN.V1_frailty-proxy.R")
))

if (is.na(setup_script)) stop("Puuttuva skripti: 00_setup_env.R (aja repo-juuresta).")
if (is.na(qc_script)) stop("Puuttuva skripti: 20_qc_panel_summary.R (aja repo-juuresta).")
if (is.na(models_script)) stop("Puuttuva skripti: 30_models_panel_nb_gamma.R (aja repo-juuresta).")

# ========================
# D) Child-run wrapper (redacts logs)
# ========================

run_child_rscript <- function(label, expr = NULL, script = NULL) {
  log_path <- file.path(logs_root, paste0(RUN_ID, "_", label, ".log"))

  if (DRY_RUN) {
    write_log(log_path, c(paste0("DRY_RUN: skipped ", label)))
    log_msg("DRY_RUN: skipped ", label)
    return(invisible(TRUE))
  }

  if (!is.null(expr)) {
    args <- c("--vanilla", "-e", shQuote(expr))
  } else {
    args <- c("--vanilla", script)
  }

  out <- tryCatch(system2("Rscript", args = args, stdout = TRUE, stderr = TRUE), error = function(e) {
    c(paste0("ERROR: ", conditionMessage(e)))
  })

  write_log(log_path, out)

  status <- attr(out, "status")
  if (!is.null(status) && status != 0) {
    stop(paste0("Ajovaihe epäonnistui: ", label, " (katso logs/<RUN_ID>_", label, ".log)"))
  }

  # If we still detect obvious absolute paths after redaction, fail closed.
  raw_has_abs <- any(grepl(abs_path_regex, out, perl = TRUE))
  if (raw_has_abs) {
    # We already wrote a redacted log; abort to enforce policy.
    stop(paste0("Turvatarkistus epäonnistui: ", label, " tuotti absoluuttisia polkuja stdoutiin."))
  }

  log_msg("OK: ", label)
  invisible(TRUE)
}

# ========================
# E) (Optional) Frailty proxy integration
# ========================

# If panel already contains frailty, skip. Otherwise, run frailty proxy script if available.
panel_cols <- tryCatch(names(read.csv(panel_path, nrows = 0, stringsAsFactors = FALSE)),
                       error = function(e) character(0))
has_frailty <- any(panel_cols %in% c("frailty_fried", "frailty_score", "frailty"))

if (!has_frailty && !is.na(frailty_script) && !RUN_MODELS_ONLY) {
  log_msg("Frailty column missing in panel; running optional frailty proxy step.")
  Sys.setenv(RUN_ID = RUN_ID, SEED = as.character(SEED), DATA_ROOT = DATA_ROOT)
  run_child_rscript("K15_frailty_proxy", script = frailty_script)
} else if (!has_frailty && is.na(frailty_script)) {
  log_msg("Frailty column missing; no frailty proxy script found (continuing with QC/models as-is).")
} else {
  log_msg("Frailty column present or models-only mode; skipping frailty proxy step.")
}

# ========================
# F) Minimal in-driver QC gates (aggregated only)
# ========================

run_minimal_qc_gates <- function(panel_path_in) {
  required <- c("id","FOF_status","age","sex","period","person_time")
  frailty_any <- c("frailty_fried","frailty_score","frailty")

  cols <- names(read.csv(panel_path_in, nrows = 0, stringsAsFactors = FALSE))
  missing_req <- setdiff(required, cols)
  if (length(missing_req) > 0) stop(paste0("QC gate failed: puuttuvat sarakkeet: ", paste(missing_req, collapse = ", ")))
  if (!any(frailty_any %in% cols)) stop("QC gate failed: frailty-sarake puuttuu (frailty_fried/frailty_score/frailty).")

  panel <- read.csv(panel_path_in, stringsAsFactors = FALSE)

  any_dup <- any(duplicated(paste(panel$id, panel$period)))
  any_pt_le0 <- any(panel$person_time <= 0, na.rm = TRUE)

  share_missing_fof <- mean(is.na(panel$FOF_status))
  frailty_var <- intersect(frailty_any, names(panel))[1]
  share_missing_frailty <- mean(is.na(panel[[frailty_var]]))

  num_cols <- names(panel)[vapply(panel, is.numeric, logical(1))]
  count_like <- num_cols[grepl("(visits|episodes|contacts|days|util_)", num_cols, ignore.case = TRUE)]
  cost_like  <- num_cols[grepl("(cost|_eur|euro)", num_cols, ignore.case = TRUE)]

  any_neg_counts <- if (length(count_like) > 0) any(unlist(panel[count_like]) < 0, na.rm = TRUE) else FALSE
  any_neg_costs  <- if (length(cost_like) > 0) any(unlist(panel[cost_like]) < 0, na.rm = TRUE) else FALSE

  qc <- tibble::tibble(
    n_rows = nrow(panel),
    n_ids = dplyr::n_distinct(panel$id),
    any_duplicate_id_period = any_dup,
    any_person_time_le0 = any_pt_le0,
    share_missing_fof = share_missing_fof,
    share_missing_frailty = share_missing_frailty,
    any_negative_count_like = any_neg_counts,
    any_negative_cost_like = any_neg_costs,
    frailty_var_used = frailty_var
  )

  reasons <- character(0)
  if (isTRUE(any_dup)) reasons <- c(reasons, "duplicate id+period rows detected")
  if (isTRUE(any_pt_le0)) reasons <- c(reasons, "person_time <= 0 detected")
  if (share_missing_fof > MAX_MISSING_SHARE_FOF) {
    reasons <- c(reasons, sprintf("FOF missing share %.3f > %.3f", share_missing_fof, MAX_MISSING_SHARE_FOF))
  }
  if (share_missing_frailty > MAX_MISSING_SHARE_FRAILTY) {
    reasons <- c(reasons, sprintf("Frailty missing share %.3f > %.3f", share_missing_frailty, MAX_MISSING_SHARE_FRAILTY))
  }
  if (isTRUE(any_neg_counts)) reasons <- c(reasons, "negative values in count-like columns")
  if (isTRUE(any_neg_costs)) reasons <- c(reasons, "negative values in cost-like columns")

  list(qc = qc, reasons = reasons)
}

if (!RUN_MODELS_ONLY) {
  if (!DRY_RUN) {
    qc_driver <- run_minimal_qc_gates(panel_path)
    write.csv(qc_driver$qc, file.path(outputs_root, "qc", paste0("qc_summary_driver_", RUN_ID, ".csv")), row.names = FALSE)

    if (length(qc_driver$reasons) > 0) {
      stop(paste0("QC gate failed: ", paste(head(qc_driver$reasons, 3), collapse = " | ")))
    }
  }

  Sys.setenv(RUN_ID = RUN_ID, SEED = as.character(SEED), DATA_ROOT = DATA_ROOT)
  run_child_rscript("20_qc_panel_summary", script = qc_script)
} else {
  log_msg("RUN_MODELS_ONLY=TRUE: skipping QC stage.")
}

if (RUN_QC_ONLY) {
  log_msg("RUN_QC_ONLY=TRUE: stopping after QC as requested.")
}

# ========================
# G) Models (double-gated aggregates)
# ========================

if (!RUN_QC_ONLY) {
  if (!(ALLOW_AGGREGATES && USER_INTENDS_MODELS)) {
    stop("Aggregaatit eivät ole sallittuja: aseta ALLOW_AGGREGATES=1 ja INTEND_AGGREGATES=true ajaaksesi mallivaiheen.")
  }

  # Run models via expression wrapper to ensure seed + B are visible even if script doesn't read env vars.
  expr <- paste0(
    "Sys.setenv(RUN_ID='", RUN_ID, "');",
    "Sys.setenv(DATA_ROOT=Sys.getenv('DATA_ROOT'));",
    "Sys.setenv(SEED='", SEED, "');",
    "Sys.setenv(BOOTSTRAP_B='", B_BOOT, "');",
    "set.seed(as.integer(Sys.getenv('SEED')));",
    "B <- as.integer(Sys.getenv('BOOTSTRAP_B'));",
    "assign('B', B, envir = .GlobalEnv);",
    "assign('B_BOOT', B, envir = .GlobalEnv);",
    "source('", models_script, "', local = FALSE)"
  )

  Sys.setenv(RUN_ID = RUN_ID, SEED = as.character(SEED), DATA_ROOT = DATA_ROOT, BOOTSTRAP_B = as.character(B_BOOT))
  run_child_rscript("30_models_panel_nb_gamma", expr = expr)
}

# ========================
# H) Post-run: archive export-safe outputs + n<5 suppression (if applicable)
# ========================

apply_n5_suppression <- function(csv_path) {
  df <- tryCatch(read.csv(csv_path, stringsAsFactors = FALSE), error = function(e) NULL)
  if (is.null(df)) return(invisible(FALSE))
  if (!("n" %in% names(df))) return(invisible(FALSE))

  suppressed_rows <- which(!is.na(df$n) & df$n < 5)
  if (length(suppressed_rows) == 0) return(invisible(FALSE))

  if (!("suppressed" %in% names(df))) df$suppressed <- 0L
  df$suppressed[suppressed_rows] <- 1L

  # Blank numeric measure columns except n (keep identifiers as-is)
  num_cols <- names(df)[vapply(df, is.numeric, logical(1))]
  num_cols <- setdiff(num_cols, c("n", "suppressed"))
  for (cn in num_cols) df[[cn]][suppressed_rows] <- NA_real_

  write.csv(df, csv_path, row.names = FALSE)
  invisible(TRUE)
}

safe_candidates <- c(
  safe_join_path(outputs_root, "qc_summary_aim2.txt"),
  safe_join_path(outputs_root, "panel_models_summary.csv"),
  safe_join_path(outputs_root, "qc", paste0("qc_summary_driver_", RUN_ID, ".csv"))
)

to_archive <- safe_candidates[file.exists(safe_candidates)]
if (length(to_archive) > 0) {
  # Apply suppression to model summary before archiving (if it carries cell counts)
  if (file.exists(file.path(outputs_root, "panel_models_summary.csv"))) {
    apply_n5_suppression(file.path(outputs_root, "panel_models_summary.csv"))
  }

  for (f in to_archive) file.copy(f, archive_root, overwrite = TRUE)
  log_msg("Archived export-safe outputs to outputs/archive/<RUN_ID>/ (no paths printed).")
} else {
  log_msg("No expected export-safe outputs found to archive.")
}

# ========================
# I) End-of-run summary (secure)
# ========================

summary_lines <- c(
  paste0("run_id: ", RUN_ID),
  paste0("timestamp_end: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("expected_safe_qc_exists: ", file.exists(file.path(outputs_root, "qc_summary_aim2.txt"))),
  paste0("expected_safe_models_exists: ", file.exists(file.path(outputs_root, "panel_models_summary.csv"))),
  paste0("archive_dir: outputs/archive/<RUN_ID>/"),
  paste0("logs_dir: logs/")
)
writeLines(summary_lines, file.path(logs_root, paste0(RUN_ID, "_run_summary.txt")), useBytes = TRUE)

log_msg("Secure run completed.")
