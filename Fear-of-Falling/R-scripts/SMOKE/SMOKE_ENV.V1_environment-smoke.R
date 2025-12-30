#!/usr/bin/env Rscript
# ==============================================================================
# SMOKE_ENV - Smoke Test Environment
# File tag: SMOKE_ENV.V1_environment-smoke.R
# Purpose: Verify R environment, init paths, and manifest logic without data.
#
# Outcome: N/A
# Predictors: N/A
# Moderator/interaction: N/A
# Grouping variable: N/A
# Covariates: N/A
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# c()
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# N/A
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A
#
# Outputs + manifest:
# - script_label: SMOKE_ENV (canonical)
# - outputs dir: R-scripts/SMOKE_ENV/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load raw data (immutable; no edits) -> SKIPPED (Smoke test)
# 03) Standardize vars + QC (sanity checks early) -> SKIPPED
# 04) Derive/rename vars (document mapping) -> SKIPPED
# 05) Prepare analysis dataset (complete-case and/or MI flag) -> SKIPPED
# 06) Fit primary model (ANCOVA or mixed per project strategy) -> SKIPPED
# 07) Sensitivity models (if feasible; document) -> SKIPPED
# 08) Reporting tables (estimates + 95% CI; emmeans as needed) -> SKIPPED
# 09) Save artifacts -> R-scripts/SMOKE_ENV/outputs/
# 10) Append manifest row per artifact
# 11) Save sessionInfo / renv diagnostics to manifest/
# 12) EOF marker
# ==============================================================================
suppressPackageStartupMessages({
  library(here)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "SMOKE_ENV"  # interactive fallback
}

# Canonical SCRIPT_ID (e.g. K11_MAIN)
script_id_raw <- sub("\\.V.*$", "", script_base)
if (is.na(script_id_raw) || script_id_raw == "") script_id_raw <- "SMOKE_ENV"

# Derive script_label for folder mapping (e.g. K11_MAIN -> K11)
script_label <- "SMOKE_ENV"

# init_paths() must set outputs_dir + manifest_path (+ options fof.*)
# Ensure reporting.R or qc.R is loaded for init_paths
source(here::here("R", "functions", "init.R"))

paths <- init_paths(script_label)
outputs_dir   <- paths$outputs_dir
manifest_path <- paths$manifest_path

# seed (ONLY when needed):
# set.seed({{SEED}})

# --- SMOKE LOGIC -------------------------------------------------------------

# 1. Write sessionInfo to outputs
session_path <- file.path(outputs_dir, "sessionInfo.txt")
writeLines(capture.output(sessionInfo()), session_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "sessionInfo",
    path = get_relpath(session_path),
    kind = "text_file",
    notes = "Smoke test environment check"
  ),
  manifest_path
)

# 2. Write renv status to outputs
renv_path <- file.path(outputs_dir, "renv_status.txt")
renv_status_txt <- capture.output(if(requireNamespace("renv", quietly=TRUE)) renv::status() else cat("renv not installed"))
writeLines(renv_status_txt, renv_path)
append_manifest(
  manifest_row(
    script = script_label,
    label = "renv_status",
    path = get_relpath(renv_path),
    kind = "text_file",
    notes = "Smoke test renv status"
  ),
  manifest_path
)

cat("Smoke test complete. Artifacts saved to:", outputs_dir, "\n")
