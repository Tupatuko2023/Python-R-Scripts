#!/usr/bin/env Rscript
# R/40_run_secure_panel_analysis.R
# Secure driver for Aim 2 panel analysis (FOF burden & costs)
# Sequence (RUNBOOK_SECURE_EXECUTION.md): setup -> frailty proxy -> QC -> models
# SECURITY: Do not print row-level data. Export only aggregated (export-safe) outputs.

#========================
# A) Config & validations
#========================

# ---- Tunable parameters (can be overridden via env vars) ----
RUN_ID <- Sys.getenv("RUN_ID", unset = "")
if (RUN_ID == "") RUN_ID <- format(Sys.time(), "%Y%m%dT%H%M%S")

SEED <- as.integer(Sys.getenv("SEED", unset = "20260130"))
B_BOOT <- as.integer(Sys.getenv("BOOTSTRAP_B", unset = "1000"))

RUN_QC_ONLY     <- tolower(Sys.getenv("RUN_QC_ONLY", unset = "false")) %in% c("1","true","yes")
RUN_MODELS_ONLY <- tolower(Sys.getenv("RUN_MODELS_ONLY", unset = "false")) %in% c("1","true","yes")
OVERWRITE_OUTPUTS <- tolower(Sys.getenv("OVERWRITE_OUTPUTS", unset = "false")) %in% c("1","true","yes")
DRY_RUN <- tolower(Sys.getenv("DRY_RUN", unset = "false")) %in% c("1","true","yes")

# QC gate thresholds (conservative defaults; adjust via env vars if needed)
MAX_MISSING_SHARE_FOF     <- as.numeric(Sys.getenv("MAX_MISSING_SHARE_FOF", unset = "0.05"))
MAX_MISSING_SHARE_FRAILTY <- as.numeric(Sys.getenv("MAX_MISSING_SHARE_FRAILTY", unset = "0.10"))

DATA_ROOT <- Sys.getenv("DATA_ROOT", unset = "")
if (DATA_ROOT == "") stop("DATA_ROOT ei ole asetettu (Sys.getenv('DATA_ROOT') on tyhjä).")
if (!dir.exists(DATA_ROOT)) stop(sprintf("DATA_ROOT-polku ei ole olemassa: %s", DATA_ROOT))

panel_path_default <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")
if (!file.exists(panel_path_default)) stop(sprintf("Paneeliaineisto puuttuu: %s", panel_path_default))
if (file.access(panel_path_default, 4) != 0) stop(sprintf("Ei lukuoikeutta paneeliaineistoon: %s", panel_path_default))

# Repo roots (no absolute hard-coding beyond /mnt/data fallback)
repo_root <- getwd()
outputs_root <- file.path(repo_root, "outputs")
logs_root    <- file.path(repo_root, "logs")
archive_root <- file.path(outputs_root, "archive", RUN_ID)
dir.create(outputs_root, showWarnings = FALSE, recursive = TRUE)
dir.create(logs_root,    showWarnings = FALSE, recursive = TRUE)
dir.create(archive_root, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_root, "qc"),    showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(outputs_root, "tables"), showWarnings = FALSE, recursive = TRUE)

#========================
# B) Logging & audit trail
#========================
log_file <- file.path(logs_root, paste0("run_", RUN_ID, ".log"))

# Secure logger: writes text only; never prints data frames.
.log_con <- file(log_file, open = "wt")
on.exit({
  try(close(.log_con), silent = TRUE)
}, add = TRUE)

log_msg <- function(...) {
  txt <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste0(..., collapse = ""))
  writeLines(txt, con = .log_con)
  message(txt)
}

log_sep <- function() log_msg(strrep("-", 90))

sink(.log_con, type = "output", split = FALSE)
sink(.log_con, type = "message", append = TRUE)

on.exit({
  try(sink(type = "message"), silent = TRUE)
  try(sink(type = "output"), silent = TRUE)
}, add = TRUE)

set.seed(SEED)

git_hash <- tryCatch(system("git rev-parse HEAD", intern = TRUE), error = function(e) NA_character_)
if (length(git_hash) == 0) git_hash <- NA_character_

meta_lines <- c(
  paste0("run_id: ", RUN_ID),
  paste0("timestamp: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("data_root: ", DATA_ROOT),
  paste0("repo_root: ", repo_root),
  paste0("seed: ", SEED),
  paste0("bootstrap_B: ", B_BOOT),
  paste0("run_qc_only: ", RUN_QC_ONLY),
  paste0("run_models_only: ", RUN_MODELS_ONLY),
  paste0("overwrite_outputs: ", OVERWRITE_OUTPUTS),
  paste0("dry_run: ", DRY_RUN),
  paste0("git_hash: ", ifelse(is.na(git_hash), "NA", git_hash)),
  paste0("R.version: ", R.version.string)
)

writeLines(meta_lines, file.path(logs_root, paste0(RUN_ID, "_run_metadata.txt")))
writeLines(capture.output(sessionInfo()), file.path(logs_root, paste0(RUN_ID, "_sessionInfo.txt")))

log_sep()
log_msg("Secure run started.")
log_msg("DATA_ROOT validated; panel found at: ", panel_path_default)
log_sep()

#========================
# C) Source project scripts
#========================
locate_script <- function(candidates) {
  for (p in candidates) if (!is.na(p) && p != "" && file.exists(p)) return(normalizePath(p, winslash = "/"))
  NA_character_
}

setup_script <- locate_script(c(
  file.path(repo_root, "00_setup_env.R"),
  file.path(repo_root, "scripts", "00_setup_env.R"),
  "/mnt/data/00_setup_env.R"
))
qc_script <- locate_script(c(
  file.path(repo_root, "20_qc_panel_summary.R"),
  file.path(repo_root, "scripts", "20_qc_panel_summary.R"),
  "/mnt/data/20_qc_panel_summary.R"
))
models_script <- locate_script(c(
  file.path(repo_root, "30_models_panel_nb_gamma.R"),
  file.path(repo_root, "scripts", "30_models_panel_nb_gamma.R"),
  "/mnt/data/30_models_panel_nb_gamma.R"
))
frailty_script <- locate_script(c(
  file.path(repo_root, "K15_MAIN.V1_frailty-proxy.R"),
  file.path(repo_root, "scripts", "K15_MAIN.V1_frailty-proxy.R"),
  "/mnt/data/K15_MAIN.V1_frailty-proxy.R"
))

if (is.na(setup_script))   stop("Puuttuva skripti: 00_setup_env.R (ei löytynyt repo_rootista eikä /mnt/data:sta).")
if (is.na(qc_script))      stop("Puuttuva skripti: 20_qc_panel_summary.R (ei löytynyt repo_rootista eikä /mnt/data:sta).")
if (is.na(models_script))  stop("Puuttuva skripti: 30_models_panel_nb_gamma.R (ei löytynyt repo_rootista eikä /mnt/data:sta).")
if (is.na(frailty_script)) stop("Puuttuva skripti: K15_MAIN.V1_frailty-proxy.R (ei löytynyt repo_rootista eikä /mnt/data:sta).")

log_msg("Sourcing setup script: ", setup_script)
if (!DRY_RUN) source(setup_script, local = FALSE)

# Minimal dependencies for secure driver (safe; no data printing)
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

#========================
# D) Frailty_score integration
#========================
# Frailty proxy is computed from DATA_ROOT inputs (as defined in K15_MAIN.V1_frailty-proxy.R).
# Integration rule:
#   - If panel already contains 'frailty_fried' (or 'frailty_score'), do not recompute.
#   - Else compute frailty (id-level) and merge into panel in secure area (DATA_ROOT/derived),
#     producing aim2_panel_with_frailty.csv; optionally replace aim2_panel.csv only if OVERWRITE_OUTPUTS=TRUE.
#
# IMPORTANT: Never export row-level panel outside DATA_ROOT. Only aggregated outputs go to outputs/.

panel_cols <- tryCatch(names(readr::read_csv(panel_path_default, n_max = 0, show_col_types = FALSE)),
                       error = function(e) character(0))

has_frailty <- any(panel_cols %in% c("frailty_fried", "frailty_score", "frailty"))
panel_path_for_analysis <- panel_path_default

if (!has_frailty) {
  log_msg("Frailty column not found in panel. Computing frailty proxy via: ", frailty_script)
  
  frailty_env <- new.env(parent = baseenv())
  if (!DRY_RUN) source(frailty_script, local = frailty_env)
  
  # Try to discover a callable function from the frailty script.
  fn_candidates <- c(
    "compute_frailty_proxy", "compute_frailty_score", "calc_frailty_proxy",
    "calc_frailty_score", "make_frailty_proxy", "build_frailty_proxy",
    "frailty_proxy", "frailty_score_fn"
  )
  
  fn_found <- NULL
  for (nm in fn_candidates) {
    if (exists(nm, envir = frailty_env, inherits = FALSE) && is.function(get(nm, envir = frailty_env))) {
      fn_found <- get(nm, envir = frailty_env)
      log_msg("Frailty function detected: ", nm)
      break
    }
  }
  
  frailty_df <- NULL
  
  if (!is.null(fn_found)) {
    # Call using most likely signatures without printing data:
    # - fn(DATA_ROOT = ..., data_root = ..., root = ...)
    # - fn(...) should return a data.frame with at least id + frailty score
    call_ok <- FALSE
    for (arg_name in c("DATA_ROOT", "data_root", "root", "path")) {
      try({
        res <- fn_found(setNames(list(DATA_ROOT), arg_name))
        if (is.data.frame(res) || inherits(res, "tbl_df")) {
          frailty_df <- res
          call_ok <- TRUE
        }
      }, silent = TRUE)
      if (call_ok) break
    }
    if (!call_ok) {
      # Try no-arg call (script may read DATA_ROOT internally)
      res <- tryCatch(fn_found(), error = function(e) NULL)
      if (is.data.frame(res) || inherits(res, "tbl_df")) frailty_df <- res
    }
  } else {
    # Script may have created an object directly (frailty_score / frailty_df / frailty)
    obj_candidates <- c("frailty_df", "frailty_score", "frailty_proxy", "frailty")
    for (nm in obj_candidates) {
      if (exists(nm, envir = frailty_env, inherits = FALSE)) {
        res <- get(nm, envir = frailty_env)
        if (is.data.frame(res) || inherits(res, "tbl_df")) {
          frailty_df <- res
          log_msg("Frailty object detected: ", nm)
          break
        }
      }
    }
  }
  
  if (is.null(frailty_df)) {
    stop("Frailty-proxy -integraatio epäonnistui: skripti ei palauttanut data.framea eikä löytänyt tunnistettavaa funktiota/objektia. Korjaa K15_MAIN.V1_frailty-proxy.R:ltä ulospäin (palauta id + frailty).")
  }
  
  # Standardize expected columns
  # Require 'id' and a frailty score column -> map to 'frailty_fried'
  if (!("id" %in% names(frailty_df))) {
    stop("Frailty data.frame: puuttuu pakollinen sarake 'id'.")
  }
  frailty_col <- intersect(names(frailty_df), c("frailty_fried", "frailty_score", "frailty"))
  if (length(frailty_col) == 0) {
    stop("Frailty data.frame: puuttuu frailty-sarake (odotettu yksi: 'frailty_fried', 'frailty_score', 'frailty').")
  }
  frailty_col <- frailty_col[1]
  
  # Read panel (row-level, secure) and merge frailty
  if (!DRY_RUN) {
    panel <- readr::read_csv(panel_path_default, show_col_types = FALSE)
    panel2 <- panel %>%
      left_join(frailty_df %>% transmute(id = .data$id, frailty_fried = .data[[frailty_col]]), by = "id")
    
    # Validate merge success (aggregate only)
    share_missing_frailty <- mean(is.na(panel2$frailty_fried))
    log_msg(sprintf("Frailty merge completed. share_missing_frailty=%.4f", share_missing_frailty))
    
    # Write updated panel within DATA_ROOT only (secure)
    panel_path_with_frailty <- file.path(DATA_ROOT, "derived", "aim2_panel_with_frailty.csv")
    readr::write_csv(panel2, panel_path_with_frailty)
    panel_path_for_analysis <- panel_path_with_frailty
    
    # If scripts are hard-wired to aim2_panel.csv, allow controlled replacement only if requested
    if (OVERWRITE_OUTPUTS) {
      backup_path <- file.path(DATA_ROOT, "derived", paste0("aim2_panel_backup_", RUN_ID, ".csv"))
      file.copy(panel_path_default, backup_path, overwrite = TRUE)
      file.copy(panel_path_with_frailty, panel_path_default, overwrite = TRUE)
      panel_path_for_analysis <- panel_path_default
      log_msg("OVERWRITE_OUTPUTS=TRUE: replaced aim2_panel.csv with frailty-enhanced version; backup at: ", backup_path)
    } else {
      log_msg("OVERWRITE_OUTPUTS=FALSE: created panel with frailty at: ", panel_path_with_frailty)
      log_msg("Will attempt to point downstream scripts via env PANEL_PATH; if scripts ignore, set OVERWRITE_OUTPUTS=TRUE.")
      Sys.setenv(PANEL_PATH = panel_path_with_frailty)
    }
  } else {
    log_msg("DRY_RUN: skipped reading/writing panel; frailty script sourced and validated interface only.")
  }
} else {
  log_msg("Frailty column already present in panel. Skipping frailty computation.")
}

#========================
# E) QC gates (secure)
#========================
# Run minimal in-driver gates (hard stop) + run repo QC script (expected to write outputs/qc_summary_aim2.txt).
# NOTE: All QC outputs must be aggregated only.

run_minimal_qc_gates <- function(panel_path) {
  required <- c("id","FOF_status","age","sex","period","person_time")
  # frailty is required for planned models
  required_frailty <- c("frailty_fried","frailty_score","frailty")
  panel_cols <- names(readr::read_csv(panel_path, n_max = 0, show_col_types = FALSE))
  
  missing_req <- setdiff(required, panel_cols)
  if (length(missing_req) > 0) stop(paste0("QC gate failed: puuttuvat sarakkeet: ", paste(missing_req, collapse = ", ")))
  
  if (!any(required_frailty %in% panel_cols)) {
    stop("QC gate failed: frailty-sarake puuttuu (odotettu yksi: frailty_fried / frailty_score / frailty).")
  }
  
  panel <- readr::read_csv(panel_path, show_col_types = FALSE)
  
  # duplicates id+period
  any_dup <- any(duplicated(paste(panel$id, panel$period)))
  # person_time
  any_pt_le0 <- any(panel$person_time <= 0, na.rm = TRUE)
  
  share_missing_fof <- mean(is.na(panel$FOF_status))
  frailty_var <- intersect(required_frailty, names(panel))[1]
  share_missing_frailty <- mean(is.na(panel[[frailty_var]]))
  
  # Identify likely count and cost columns (conservative patterns)
  num_cols <- names(panel)[vapply(panel, is.numeric, logical(1))]
  count_like <- num_cols[grepl("(visits|episodes|contacts|days|util_)", num_cols, ignore.case = TRUE)]
  cost_like  <- num_cols[grepl("(cost|_eur|euro)", num_cols, ignore.case = TRUE)]
  
  # Ensure non-negativity for these
  any_neg_counts <- if (length(count_like) > 0) any(unlist(panel[count_like]) < 0, na.rm = TRUE) else FALSE
  any_neg_costs  <- if (length(cost_like) > 0) any(unlist(panel[cost_like]) < 0, na.rm = TRUE) else FALSE
  
  # Aggregate QC summary (export-safe)
  qc_summary <- tibble::tibble(
    n_rows = nrow(panel),
    n_ids = dplyr::n_distinct(panel$id),
    any_duplicate_id_period = any_dup,
    any_person_time_le0 = any_pt_le0,
    share_missing_fof = share_missing_fof,
    share_missing_frailty = share_missing_frailty,
    any_negative_count_like = any_neg_counts,
    any_negative_cost_like = any_neg_costs,
    frailty_var_used = frailty_var,
    n_count_like_cols = length(count_like),
    n_cost_like_cols = length(cost_like)
  )
  
  # Additional zero share for one prominent cost var if present
  cost_total_candidates <- intersect(names(panel), c("cost_total_eur","total_cost_eur","total_costs_eur"))
  if (length(cost_total_candidates) > 0) {
    v <- cost_total_candidates[1]
    qc_summary$share_zero_cost_total <- mean(panel[[v]] == 0, na.rm = TRUE)
  } else {
    qc_summary$share_zero_cost_total <- NA_real_
  }
  
  list(qc_summary = qc_summary,
       gate_flags = list(
         any_duplicate_id_period = any_dup,
         any_person_time_le0 = any_pt_le0,
         share_missing_fof = share_missing_fof,
         share_missing_frailty = share_missing_frailty,
         any_negative_count_like = any_neg_counts,
         any_negative_cost_like = any_neg_costs
       ))
}

qc_driver <- NULL
if (!RUN_MODELS_ONLY) {
  log_sep()
  log_msg("Running minimal in-driver QC gates (secure).")
  if (!DRY_RUN) {
    qc_driver <- run_minimal_qc_gates(panel_path_for_analysis)
    
    # Write aggregated QC summary (export-safe)
    qc_out_path <- file.path(outputs_root, "qc", paste0("qc_summary_driver_", RUN_ID, ".csv"))
    readr::write_csv(qc_driver$qc_summary, qc_out_path)
    log_msg("Wrote aggregated QC summary (driver) to: ", qc_out_path)
    
    # Gate decisions (hard stops; max 3 reasons)
    reasons <- character(0)
    if (isTRUE(qc_driver$gate_flags$any_duplicate_id_period)) reasons <- c(reasons, "duplicate id+period rows detected")
    if (isTRUE(qc_driver$gate_flags$any_person_time_le0))     reasons <- c(reasons, "person_time <= 0 detected")
    if (qc_driver$gate_flags$share_missing_fof > MAX_MISSING_SHARE_FOF) {
      reasons <- c(reasons, sprintf("FOF missing share %.3f > %.3f", qc_driver$gate_flags$share_missing_fof, MAX_MISSING_SHARE_FOF))
    }
    if (qc_driver$gate_flags$share_missing_frailty > MAX_MISSING_SHARE_FRAILTY) {
      reasons <- c(reasons, sprintf("Frailty missing share %.3f > %.3f", qc_driver$gate_flags$share_missing_frailty, MAX_MISSING_SHARE_FRAILTY))
    }
    if (isTRUE(qc_driver$gate_flags$any_negative_count_like)) reasons <- c(reasons, "negative values in count-like columns")
    if (isTRUE(qc_driver$gate_flags$any_negative_cost_like))  reasons <- c(reasons, "negative values in cost-like columns")
    
    if (length(reasons) > 0) {
      reasons <- head(reasons, 3)
      log_msg("QC gate failed (driver): ", paste(reasons, collapse = " | "))
      stop(paste0("QC gate failed: ", paste(reasons, collapse = " | ")))
    }
  } else {
    log_msg("DRY_RUN: skipped minimal QC computation.")
  }
  
  log_msg("Sourcing repo QC script: ", qc_script)
  if (!DRY_RUN) {
    # Ensure scripts see DATA_ROOT and (if supported) PANEL_PATH
    Sys.setenv(DATA_ROOT = DATA_ROOT)
    Sys.setenv(RUN_ID = RUN_ID)
    source(qc_script, local = FALSE)
  }
} else {
  log_msg("RUN_MODELS_ONLY=TRUE: skipping QC stage.")
}

if (RUN_QC_ONLY) {
  log_sep()
  log_msg("RUN_QC_ONLY=TRUE: stopping after QC as requested.")
  # Archive safe outputs if present
  safe_files <- c(
    file.path(outputs_root, "qc_summary_aim2.txt"),
    file.path(outputs_root, "qc", paste0("qc_summary_driver_", RUN_ID, ".csv"))
  )
  for (f in safe_files) if (file.exists(f)) file.copy(f, archive_root, overwrite = TRUE)
  quit(save = "no", status = 0)
}

#========================
# F) Models + export-safe outputs
#========================
# Before sourcing models, set seed and bootstrap B in multiple ways
# to maximize compatibility with repo script conventions.
assign("B_BOOT", B_BOOT, envir = .GlobalEnv)
assign("BOOT_B", B_BOOT, envir = .GlobalEnv)
assign("B", B_BOOT, envir = .GlobalEnv)  # if the models script checks/uses a global B
options(fof.bootstrap_B = B_BOOT)
Sys.setenv(BOOTSTRAP_B = as.character(B_BOOT))
Sys.setenv(SEED = as.character(SEED))

log_sep()
log_msg("Sourcing models script: ", models_script)
if (!DRY_RUN) {
  Sys.setenv(DATA_ROOT = DATA_ROOT)
  Sys.setenv(RUN_ID = RUN_ID)
  source(models_script, local = FALSE)
} else {
  log_msg("DRY_RUN: skipped model execution.")
}

# Expected export-safe outputs (per RUNBOOK)
qc_safe      <- file.path(outputs_root, "qc_summary_aim2.txt")
models_safe  <- file.path(outputs_root, "panel_models_summary.csv")

# Also allow for alternative model output names if repo evolves
alt_models_safe <- c(
  file.path(outputs_root, "tables", "panel_models_summary.csv"),
  file.path(outputs_root, "panel_models_coef_robust.csv"),
  file.path(outputs_root, "panel_recycled_predictions_counts.csv"),
  file.path(outputs_root, "panel_recycled_predictions_costs_two_part.csv")
)

# Copy to archive (export-safe only; do not copy any row-level files)
to_archive <- character(0)
for (f in c(qc_safe, models_safe, alt_models_safe,
            file.path(outputs_root, "qc", paste0("qc_summary_driver_", RUN_ID, ".csv")))) {
  if (file.exists(f)) to_archive <- c(to_archive, f)
}
to_archive <- unique(to_archive)

if (length(to_archive) > 0) {
  for (f in to_archive) file.copy(f, archive_root, overwrite = TRUE)
  log_msg("Archived export-safe outputs to: ", archive_root)
} else {
  log_msg("No expected export-safe outputs found to archive. Check upstream scripts/logs.")
}

#========================
# G) End-of-run summary (secure)
#========================
summary_path <- file.path(logs_root, paste0(RUN_ID, "_run_summary.txt"))
summary_lines <- c(
  paste0("run_id: ", RUN_ID),
  paste0("timestamp_end: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("outputs_root: ", outputs_root),
  paste0("archive_root: ", archive_root),
  paste0("expected_safe_qc: ", qc_safe, " (exists=", file.exists(qc_safe), ")"),
  paste0("expected_safe_models: ", models_safe, " (exists=", file.exists(models_safe), ")"),
  paste0("log_file: ", log_file)
)
writeLines(summary_lines, summary_path)

log_sep()
log_msg("Secure run completed.")
log_msg("Run summary written to: ", summary_path)
log_sep()
