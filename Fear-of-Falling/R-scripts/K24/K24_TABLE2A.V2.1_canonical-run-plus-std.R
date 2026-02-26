#!/usr/bin/env Rscript
# ==============================================================================
# K24_TABLE2A Wrapper - Canonical Rerun + Standardization
# File tag: K24_TABLE2A.V2.1_canonical-run-plus-std.R
# Purpose: Ensures Table 2A canonical (V2) and its standardized audit (V3)
#          are always generated from the same source in sequence.
#
# Repository Standards:
# - Logs a sync_check.txt to manifest.
# - Verifies that Model_N and FOF_Beta_CI are identical between V2 and V3.
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(readr)
  library(dplyr)
})

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(name, default) {
  key <- paste0("--", name, "=")
  hit <- args[startsWith(args, key)]
  if (length(hit) == 0) return(default)
  sub(key, "", hit[[1]], fixed = TRUE)
}

input_rdata <- get_arg("input", "R-scripts/K15/outputs/K15_frailty_analysis_data.RData")
include_balance <- get_arg("include_balance", "FALSE")
frailty_mode <- get_arg("frailty_mode", "both")

# Use canonical reporting functions for manifest
source(here::here("R", "functions", "reporting.R"))
script_label <- "K24_TABLE2A"
paths <- init_paths(script_label)
manifest_path <- paths$manifest_path
outputs_dir <- here::here("R-scripts", "K24", "outputs", script_label)

# 1. Run Canonical V2
cat("\n[*] Phase 1: Running Canonical Table 2A (V2)...\n")
cmd1 <- c(
  "R-scripts/K24/K24_TABLE2A.V2_canonical-delta-by-test-fof-frailty.R",
  paste0("--input=", input_rdata),
  paste0("--frailty_mode=", frailty_mode),
  paste0("--include_balance=", include_balance)
)

status1 <- system2("Rscript", cmd1)
if (status1 != 0) stop("K24 V2 failed.")

# 2. Run Standardization Audit
cat("\n[*] Phase 2: Generating Standardized Audit (V3)...\n")
audit_v2_path <- file.path(outputs_dir, "table2A_audit_canonical_v2.csv")
audit_v3_path <- file.path(outputs_dir, "table2A_audit_canonical_v3_with_std.csv")

cmd2 <- c(
  "R-scripts/K24/K24_AUDIT_ADD_STD.V1.R",
  paste0("--input=", audit_v2_path),
  paste0("--output=", audit_v3_path)
)

status2 <- system2("Rscript", cmd2)
if (status2 != 0) stop("K24_AUDIT_ADD_STD failed.")

# 3. Synchronization Check (Forensic Audit)
cat("\n[*] Phase 3: Verifying synchronization...\n")
v2 <- readr::read_csv(audit_v2_path, show_col_types = FALSE)
v3 <- readr::read_csv(audit_v3_path, show_col_types = FALSE)

# Compare core statistical columns
core_cols <- c("Outcome", "Frailty_Mode", "Model_N", "FOF_Beta_CI", "P_FOF")
v2_core <- v2 %>% select(all_of(core_cols)) %>% arrange(Outcome, Frailty_Mode)
v3_core <- v3 %>% select(all_of(core_cols)) %>% arrange(Outcome, Frailty_Mode)

sync_ok <- isTRUE(all.equal(v2_core, v3_core))

sync_log_path <- file.path(outputs_dir, "K24_sync_check.txt")
log_lines <- c(
  "K24 Synchronization Check",
  paste0("Timestamp: ", Sys.time()),
  paste0("Input RData: ", input_rdata),
  paste0("Status: ", if(sync_ok) "PASS" else "FAIL"),
  "",
  "Verification details:",
  "- audit_v2 rows: ", nrow(v2),
  "- audit_v3 rows: ", nrow(v3),
  "- Core columns comparison (N, Beta, P): ", if(sync_ok) "Identical" else "Mismatch detected"
)

if (!sync_ok) {
  log_lines <- c(log_lines, "", "DIFFERENCES DETECTED:", capture.output(all.equal(v2_core, v3_core)))
}

writeLines(log_lines, con = sync_log_path)

# Log to manifest
append_manifest(
  manifest_row(script = script_label, label = "sync_check_txt", path = get_relpath(sync_log_path), kind = "qc_text", notes = "K24 V2/V3 synchronization verification"),
  manifest_path
)

if (sync_ok) {
  cat("\n[OK] Synchronization verified: v2 and v3_with_std are identical in core columns.\n")
} else {
  warning("[!] Synchronization FAILURE: check K24_sync_check.txt for details.")
}
