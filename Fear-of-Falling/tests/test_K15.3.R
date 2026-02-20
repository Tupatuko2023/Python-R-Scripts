#!/usr/bin/env Rscript
# Smoke test for K15.3.frailty_n_balance.R

suppressPackageStartupMessages({
  library(here)
})

cat("=== K15.3 Smoke Test ===\n")

# 1. Check script exists
script_path <- here::here("R-scripts", "K15", "K15.3.frailty_n_balance.R")
if (!file.exists(script_path)) {
  stop("Script not found: ", script_path)
}
cat("Script found: ", script_path, "\n")

# 2. Run script
cat("Running script...\n")
res <- system2("Rscript", args = c(script_path), stdout = TRUE, stderr = TRUE)
status <- attr(res, "status")
if (!is.null(status) && status != 0) {
  cat(paste(res, collapse = "\n"))
  stop("Script execution failed with status: ", status)
}
cat("Script execution completed.\n")

# 3. Check outputs
# Outputs go to R-scripts/K15/outputs/ because we set script_label="K15"
output_dir <- here::here("R-scripts", "K15", "outputs")

expected_files <- c(
  "K15.3._frailty_count_3_overall.csv",
  "K15.3._frailty_cat_3_balance_overall.csv", # Balance output
  "K15.3._frailty_analysis_data.RData"
)

missing <- character(0)
for (f in expected_files) {
  fpath <- file.path(output_dir, f)
  if (file.exists(fpath)) {
    cat("OK: ", f, "\n")
  } else {
    cat("MISSING: ", f, "\n")
    missing <- c(missing, f)
  }
}

if (length(missing) > 0) {
  stop("Missing output files: ", paste(missing, collapse = ", "))
}

cat("=== Smoke Test PASSED ===\n")
