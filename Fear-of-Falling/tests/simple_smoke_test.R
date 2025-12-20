#!/usr/bin/env Rscript
# Simple Smoke Test - Minimal version without here() dependency
# Run from Fear-of-Falling directory

cat("\n")
cat(strrep("=", 70), "\n", sep = "")
cat("SIMPLE SMOKE TEST FOR K11-K16\n")
cat(strrep("=", 70), "\n\n", sep = "")

# Set working directory to project root (where this script is located)
script_path <- getwd()
cat("Working directory:", script_path, "\n\n")

# Check prerequisites
cat("Checking prerequisites...\n")
cat(strrep("-", 70), "\n", sep = "")

# Check data file
data_file <- file.path(script_path, "data", "external", "KaatumisenPelko.csv")
data_exists <- file.exists(data_file)
cat(if (data_exists) "✓" else "✗", "Data file:",
    if (data_exists) "FOUND" else "NOT FOUND", "\n")

# Check helper files
helper_files <- c("io.R", "checks.R", "modeling.R", "reporting.R")
helpers_ok <- TRUE
for (hf in helper_files) {
  path <- file.path(script_path, "R", "functions", hf)
  exists <- file.exists(path)
  helpers_ok <- helpers_ok && exists
  cat(if (exists) "✓" else "✗", "Helper:", hf,
      if (exists) "found" else "missing", "\n")
}

cat("\n")

if (!data_exists || !helpers_ok) {
  cat("✗ Prerequisites not met. Cannot run tests.\n\n")
  quit(status = 1)
}

cat("✓ All prerequisites met!\n\n")

# List of scripts to test
scripts <- c("K11", "K12", "K13", "K14", "K15", "K16")
results <- list()

# Run each script
for (script_name in scripts) {
  cat(strrep("=", 70), "\n", sep = "")
  cat("Testing:", script_name, "\n")
  cat(strrep("=", 70), "\n", sep = "")

  script_file <- file.path(script_path, "R-scripts", script_name,
                           paste0(script_name, ".R"))

  if (!file.exists(script_file)) {
    cat("✗ Script not found:", script_file, "\n\n")
    results[[script_name]] <- list(success = FALSE, error = "Script not found")
    next
  }

  # Try to run the script
  result <- tryCatch({
    start_time <- Sys.time()

    # Source the script in a new environment
    source(script_file, local = new.env(), echo = FALSE)

    end_time <- Sys.time()
    elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

    cat(sprintf("\n✓ %s completed successfully in %.1f seconds\n\n",
                script_name, elapsed))

    list(success = TRUE, error = NULL, elapsed = elapsed)
  },
  error = function(e) {
    cat("\n✗ Script failed with error:\n")
    cat("  ", conditionMessage(e), "\n\n")
    list(success = FALSE, error = conditionMessage(e), elapsed = NA)
  })

  results[[script_name]] <- result
}

# Summary
cat(strrep("=", 70), "\n", sep = "")
cat("TEST SUMMARY\n")
cat(strrep("=", 70), "\n\n", sep = "")

total <- length(results)
passed <- sum(sapply(results, function(r) r$success))
failed <- total - passed

for (sname in names(results)) {
  r <- results[[sname]]
  status <- if (r$success) "✓ PASS" else "✗ FAIL"
  time_str <- if (!is.na(r$elapsed)) sprintf("(%.1fs)", r$elapsed) else ""
  cat(sprintf("%-8s %s %s\n", status, sname, time_str))
}

cat("\n")
cat(sprintf("Total: %d | Passed: %d | Failed: %d\n\n", total, passed, failed))

if (failed == 0) {
  cat("✓ All smoke tests passed!\n")
  quit(status = 0)
} else {
  cat("✗ Some tests failed.\n")
  quit(status = 1)
}

cat(strrep("=", 70), "\n\n", sep = "")
