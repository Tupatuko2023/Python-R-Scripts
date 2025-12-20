#!/usr/bin/env Rscript
# Simple Smoke Test Runner for K11-K16
# Does not require testthat package
# Usage: Rscript tests/run_smoke_tests.R

library(here)

# ==============================================================================
# Configuration
# ==============================================================================

TIMEOUT_SECONDS <- 300  # 5 minutes per script
SCRIPTS_TO_TEST <- c("K11", "K12", "K13", "K14", "K15", "K16")

# Expected outputs for each script
EXPECTED_OUTPUTS <- list(
  K11 = c(
    "fit_primary_ancova.csv",
    "lm_base_model_full.csv",
    "FOF_effect_base_vs_extended.csv"
  ),
  K12 = c(
    "lm_models_all_outcomes.csv",
    "FOF_effects_by_outcome.csv"
  ),
  K13 = c(
    "lm_age_int_extended_full.csv",
    "FOF_interaction_effects_overview.csv"
  ),
  K14 = c(
    "K14_baseline_by_FOF.csv"
  ),
  K15 = c(
    "K15_frailty_count_3_overall.csv",
    "K15_frailty_analysis_data.RData"
  ),
  K16 = c(
    "K16_frailty_models_tables.docx",
    "K16_all_models.RData"
  )
)

# ==============================================================================
# Helper Functions
# ==============================================================================

check_prerequisites <- function() {
  cat("\n", strrep("=", 70), "\n", sep = "")
  cat("CHECKING PREREQUISITES\n")
  cat(strrep("=", 70), "\n\n", sep = "")

  # Check data file
  data_file <- here::here("data", "external", "KaatumisenPelko.csv")
  data_exists <- file.exists(data_file)

  if (data_exists) {
    cat("✓ Data file found: KaatumisenPelko.csv\n")
  } else {
    cat("✗ Data file NOT found: data/external/KaatumisenPelko.csv\n")
    cat("  Please ensure the data file is in the correct location.\n")
  }

  # Check helper function files
  helper_files <- c("io.R", "checks.R", "modeling.R", "reporting.R")
  helpers_exist <- TRUE

  for (helper_file in helper_files) {
    path <- here::here("R", "functions", helper_file)
    if (file.exists(path)) {
      cat("✓ Helper file found:", helper_file, "\n")
    } else {
      cat("✗ Helper file NOT found:", helper_file, "\n")
      helpers_exist <- FALSE
    }
  }

  return(data_exists && helpers_exist)
}

run_script_test <- function(script_name) {
  cat("\n", strrep("-", 70), "\n", sep = "")
  cat("Testing:", script_name, "\n")
  cat(strrep("-", 70), "\n", sep = "")

  script_path <- here::here("R-scripts", script_name, paste0(script_name, ".R"))

  if (!file.exists(script_path)) {
    cat("✗ Script file not found:", script_path, "\n")
    return(list(success = FALSE, error = "Script not found", elapsed = NA))
  }

  # Run script
  result <- tryCatch({
    start_time <- Sys.time()

    # Create new environment for script execution
    script_env <- new.env()
    source(script_path, local = script_env)

    end_time <- Sys.time()
    elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

    cat(sprintf("✓ Script completed successfully in %.1f seconds\n", elapsed))

    list(success = TRUE, error = NULL, elapsed = elapsed)
  },
  error = function(e) {
    cat("✗ Script failed with error:\n")
    cat("  ", e$message, "\n")
    list(success = FALSE, error = e$message, elapsed = NA)
  },
  warning = function(w) {
    cat("⚠ Script completed with warnings:\n")
    cat("  ", w$message, "\n")
    list(success = TRUE, error = w$message, elapsed = NA)
  })

  # Check outputs
  if (result$success && script_name %in% names(EXPECTED_OUTPUTS)) {
    cat("\nChecking expected outputs:\n")
    outputs_dir <- here::here("R-scripts", script_name, "outputs")

    if (!dir.exists(outputs_dir)) {
      cat("⚠ Outputs directory does not exist\n")
    } else {
      expected <- EXPECTED_OUTPUTS[[script_name]]
      found <- 0
      missing <- 0

      for (output_file in expected) {
        full_path <- file.path(outputs_dir, output_file)
        if (file.exists(full_path)) {
          cat("  ✓", output_file, "\n")
          found <- found + 1
        } else {
          cat("  ✗", output_file, "(missing)\n")
          missing <- missing + 1
        }
      }

      cat(sprintf("\nOutputs: %d found, %d missing\n", found, missing))
    }
  }

  return(result)
}

# ==============================================================================
# Main Test Runner
# ==============================================================================

main <- function() {
  cat("\n")
  cat(strrep("=", 70), "\n", sep = "")
  cat("SMOKE TESTS FOR K11-K16 R SCRIPTS\n")
  cat("Fear of Falling Analysis Pipeline\n")
  cat(strrep("=", 70), "\n", sep = "")

  # Check prerequisites
  prereqs_ok <- check_prerequisites()

  if (!prereqs_ok) {
    cat("\n✗ Prerequisites not met. Please fix issues above before running tests.\n\n")
    return(invisible(FALSE))
  }

  # Run tests
  results <- list()
  for (script_name in SCRIPTS_TO_TEST) {
    results[[script_name]] <- run_script_test(script_name)
  }

  # Summary
  cat("\n", strrep("=", 70), "\n", sep = "")
  cat("TEST SUMMARY\n")
  cat(strrep("=", 70), "\n\n", sep = "")

  total <- length(results)
  passed <- sum(sapply(results, function(r) r$success))
  failed <- total - passed

  for (script_name in names(results)) {
    r <- results[[script_name]]
    status <- if (r$success) "✓ PASS" else "✗ FAIL"
    time_str <- if (!is.na(r$elapsed)) {
      sprintf("(%.1fs)", r$elapsed)
    } else {
      ""
    }
    cat(sprintf("%-8s %s %s\n", status, script_name, time_str))
  }

  cat("\n")
  cat(sprintf("Total: %d | Passed: %d | Failed: %d\n", total, passed, failed))

  if (failed == 0) {
    cat("\n✓ All smoke tests passed!\n")
  } else {
    cat("\n✗ Some tests failed. See details above.\n")
  }

  cat(strrep("=", 70), "\n\n", sep = "")

  return(invisible(failed == 0))
}

# Run main
if (!interactive()) {
  success <- main()
  if (!success) {
    quit(status = 1)
  }
} else {
  main()
}
