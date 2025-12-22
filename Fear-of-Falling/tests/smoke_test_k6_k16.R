#!/usr/bin/env Rscript
# Comprehensive Smoke Test Runner for K6-K16
# Purpose: Run all K6-K16 scripts and capture detailed error information
# Date: 2025-12-21

# ==============================================================================
# Configuration
# ==============================================================================

TIMEOUT_SECONDS <- 300  # 5 minutes per script
SCRIPTS_TO_TEST <- c("K6", "K7", "K8", "K9", "K10", "K11", "K12", "K13", "K14", "K15", "K16")

# ==============================================================================
# Helper Functions
# ==============================================================================

cat_header <- function(text, width = 80, char = "=") {
  cat("\n", strrep(char, width), "\n", sep = "")
  cat(text, "\n")
  cat(strrep(char, width), "\n\n", sep = "")
}

cat_section <- function(text, width = 80, char = "-") {
  cat("\n", strrep(char, width), "\n", sep = "")
  cat(text, "\n")
  cat(strrep(char, width), "\n\n", sep = "")
}

run_script_test <- function(script_name) {
  script_path <- file.path("R-scripts", script_name, paste0(script_name, ".R"))

  if (!file.exists(script_path)) {
    return(list(
      script = script_name,
      success = FALSE,
      error = paste("Script file not found:", script_path),
      elapsed = NA,
      outputs_created = 0
    ))
  }

  cat_section(paste("Testing:", script_name))
  cat("Script path:", script_path, "\n")
  cat("Starting at:", as.character(Sys.time()), "\n\n")

  # Capture outputs directory before running
  outputs_dir <- file.path("R-scripts", script_name, "outputs")
  outputs_before <- character(0)
  if (dir.exists(outputs_dir)) {
    outputs_before <- list.files(outputs_dir, recursive = TRUE)
  }

  # Run the script
  result <- tryCatch({
    start_time <- Sys.time()

    # Source the script in a new environment
    source(script_path, local = new.env(), echo = FALSE)

    end_time <- Sys.time()
    elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

    # Check outputs created
    outputs_after <- character(0)
    if (dir.exists(outputs_dir)) {
      outputs_after <- list.files(outputs_dir, recursive = TRUE)
    }
    outputs_new <- setdiff(outputs_after, outputs_before)

    cat("✓", script_name, "completed successfully in", sprintf("%.1f", elapsed), "seconds\n")
    cat("  New outputs created:", length(outputs_new), "\n")
    if (length(outputs_new) > 0 && length(outputs_new) <= 10) {
      cat("  Files:\n")
      for (f in outputs_new) {
        cat("    -", f, "\n")
      }
    }

    list(
      script = script_name,
      success = TRUE,
      error = NULL,
      elapsed = elapsed,
      outputs_created = length(outputs_new),
      new_files = outputs_new
    )
  },
  error = function(e) {
    cat("✗", script_name, "FAILED with error:\n")
    cat("  Error message:", e$message, "\n")

    # Try to get more context
    if (!is.null(e$call)) {
      cat("  Error in call:", deparse(e$call)[1], "\n")
    }

    list(
      script = script_name,
      success = FALSE,
      error = e$message,
      error_call = if (!is.null(e$call)) deparse(e$call)[1] else NA,
      elapsed = NA,
      outputs_created = 0
    )
  },
  warning = function(w) {
    cat("⚠", script_name, "completed with warnings:\n")
    cat("  Warning message:", w$message, "\n")

    list(
      script = script_name,
      success = TRUE,
      error = paste("Warning:", w$message),
      elapsed = NA,
      outputs_created = 0
    )
  })

  return(result)
}

generate_report <- function(results, report_file = "SMOKE_TEST_REPORT_K6_K16.md") {
  passed <- sum(sapply(results, function(x) x$success))
  failed <- sum(sapply(results, function(x) !x$success))
  total <- length(results)

  report <- c(
    "# SMOKE TEST REPORT: K6-K16 R SCRIPTS",
    "",
    paste("**Date:**", Sys.time()),
    paste("**Scripts tested:**", total),
    paste("**Passed:**", passed, "✓"),
    paste("**Failed:**", failed, if (failed > 0) "✗" else ""),
    "",
    "---",
    "",
    "## SUMMARY",
    ""
  )

  # Summary table
  report <- c(report, "| Script | Status | Time (s) | Outputs | Error |")
  report <- c(report, "|--------|--------|----------|---------|-------|")

  for (res in results) {
    status_icon <- if (res$success) "✓ PASS" else "✗ FAIL"
    time_str <- if (!is.na(res$elapsed)) sprintf("%.1f", res$elapsed) else "N/A"
    outputs_str <- if (res$outputs_created > 0) as.character(res$outputs_created) else "-"
    error_str <- if (!is.null(res$error)) substr(res$error, 1, 50) else "-"

    report <- c(report, sprintf("| %s | %s | %s | %s | %s |",
                                res$script, status_icon, time_str, outputs_str, error_str))
  }

  report <- c(report, "", "---", "")

  # Detailed results
  report <- c(report, "## DETAILED RESULTS", "")

  for (res in results) {
    report <- c(report, paste("###", res$script))
    report <- c(report, "")

    if (res$success) {
      report <- c(report, paste("**Status:** ✓ PASSED"))
      if (!is.na(res$elapsed)) {
        report <- c(report, paste("**Execution time:**", sprintf("%.1f seconds", res$elapsed)))
      }
      if (res$outputs_created > 0) {
        report <- c(report, paste("**Outputs created:**", res$outputs_created))
        if (!is.null(res$new_files) && length(res$new_files) > 0 && length(res$new_files) <= 20) {
          report <- c(report, "", "**New files:**", "")
          for (f in res$new_files) {
            report <- c(report, paste("-", f))
          }
        }
      }
    } else {
      report <- c(report, paste("**Status:** ✗ FAILED"))
      report <- c(report, "", "**Error:**")
      report <- c(report, paste("```", res$error, "```", sep = "\n"))
      if (!is.null(res$error_call) && !is.na(res$error_call)) {
        report <- c(report, "", paste("**Error in call:**", res$error_call))
      }
    }

    report <- c(report, "", "---", "")
  }

  # Recommendations
  report <- c(report, "## RECOMMENDATIONS", "")

  if (failed > 0) {
    report <- c(report, "### Failed Scripts", "")
    for (res in results[!sapply(results, function(x) x$success)]) {
      report <- c(report, paste("**", res$script, "**"))
      report <- c(report, paste("- Error:", res$error))
      report <- c(report, "")
    }
  } else {
    report <- c(report, "✓ All scripts passed! No issues detected.")
  }

  report <- c(report, "", "---", "", "## END OF REPORT")

  # Write report
  writeLines(report, report_file)
  cat("\n✓ Report saved to:", report_file, "\n\n")

  return(report_file)
}

# ==============================================================================
# Main Execution
# ==============================================================================

cat_header("SMOKE TEST SUITE: K6-K16 R SCRIPTS")

cat("Scripts to test:", paste(SCRIPTS_TO_TEST, collapse = ", "), "\n")
cat("Timeout per script:", TIMEOUT_SECONDS, "seconds\n")
cat("Started at:", as.character(Sys.time()), "\n")

# Check prerequisites
cat("\nChecking prerequisites...\n")
data_file <- file.path("data", "external", "KaatumisenPelko.csv")
if (file.exists(data_file)) {
  cat("✓ Data file found\n")
} else {
  cat("✗ WARNING: Data file not found at", data_file, "\n")
  cat("  Some scripts may fail without this file.\n")
}

# Run tests
results <- list()
for (script in SCRIPTS_TO_TEST) {
  results[[script]] <- run_script_test(script)

  # Small delay between scripts
  Sys.sleep(0.5)
}

# Generate summary
cat_header("TEST SUMMARY")

passed <- sum(sapply(results, function(x) x$success))
failed <- sum(sapply(results, function(x) !x$success))
total <- length(results)

cat("Total scripts:", total, "\n")
cat("Passed:", passed, "✓\n")
cat("Failed:", failed, if (failed > 0) "✗" else "", "\n\n")

if (failed == 0) {
  cat("✓ ALL SMOKE TESTS PASSED!\n\n")
} else {
  cat("✗ SOME TESTS FAILED\n\n")
  cat("Failed scripts:\n")
  for (res in results[!sapply(results, function(x) x$success)]) {
    cat("  -", res$script, ":", res$error, "\n")
  }
  cat("\n")
}

# Generate detailed report
report_file <- generate_report(results)
cat("See detailed report:", report_file, "\n")

# Exit with appropriate code
if (failed > 0) {
  quit(status = 1)
} else {
  quit(status = 0)
}
