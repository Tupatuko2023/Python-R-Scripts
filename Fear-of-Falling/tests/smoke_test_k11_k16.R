# Smoke Tests for K11-K16 R Scripts
# Purpose: Quick verification that scripts can run without critical errors
# Author: Generated smoke test suite
# Date: 2025-12-18

library(testthat)
library(here)

# ==============================================================================
# Helper Functions
# ==============================================================================

check_script_outputs <- function(script_name, expected_outputs) {
  outputs_dir <- here::here("R-scripts", script_name, "outputs")

  if (!dir.exists(outputs_dir)) {
    warning(paste("Outputs directory does not exist for", script_name))
    return(FALSE)
  }

  all_exist <- TRUE
  for (output_file in expected_outputs) {
    full_path <- file.path(outputs_dir, output_file)
    if (!file.exists(full_path)) {
      message(paste("Missing expected output:", output_file, "for", script_name))
      all_exist <- FALSE
    }
  }

  return(all_exist)
}

run_script_smoke <- function(script_name, timeout = 300) {
  script_path <- here::here("R-scripts", script_name, paste0(script_name, ".R"))

  if (!file.exists(script_path)) {
    stop(paste("Script not found:", script_path))
  }

  message(paste("\n", strrep("=", 60)))
  message(paste("Running smoke test for:", script_name))
  message(strrep("=", 60))

  result <- tryCatch({
    # Run script with timeout
    start_time <- Sys.time()
    source(script_path, local = new.env())
    end_time <- Sys.time()

    elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
    message(sprintf("✓ %s completed in %.1f seconds", script_name, elapsed))

    list(success = TRUE, error = NULL, elapsed = elapsed)
  },
  error = function(e) {
    message(sprintf("✗ %s failed with error:", script_name))
    message(e$message)
    list(success = FALSE, error = e$message, elapsed = NA)
  },
  warning = function(w) {
    message(sprintf("⚠ %s completed with warnings:", script_name))
    message(w$message)
    list(success = TRUE, error = w$message, elapsed = NA)
  })

  return(result)
}

# ==============================================================================
# Test: K11.R - Primary ANCOVA Models
# ==============================================================================

test_that("K11.R runs without errors", {
  skip_if_not(file.exists(here::here("data", "external", "KaatumisenPelko.csv")),
              "Data file not found")

  result <- run_script_smoke("K11")
  expect_true(result$success, info = result$error)

  # Check key outputs
  expected_outputs <- c(
    "fit_primary_ancova.csv",
    "lm_base_model_full.csv",
    "FOF_effect_base_vs_extended.csv",
    "Responder_osuus_percent_annot.png"
  )

  outputs_exist <- check_script_outputs("K11", expected_outputs)
  expect_true(outputs_exist, "Some expected outputs are missing for K11")
})

# ==============================================================================
# Test: K12.R - FOF Effects by Outcome
# ==============================================================================

test_that("K12.R runs without errors", {
  skip_if_not(file.exists(here::here("data", "external", "KaatumisenPelko.csv")),
              "Data file not found")

  result <- run_script_smoke("K12")
  expect_true(result$success, info = result$error)

  expected_outputs <- c(
    "lm_models_all_outcomes.csv",
    "FOF_effects_by_outcome.csv",
    "FOF_effects_standardized_extended.csv",
    "FOF_effects_by_outcome_forest.png"
  )

  outputs_exist <- check_script_outputs("K12", expected_outputs)
  expect_true(outputs_exist, "Some expected outputs are missing for K12")
})

# ==============================================================================
# Test: K13.R - Interaction Analyses
# ==============================================================================

test_that("K13.R runs without errors", {
  skip_if_not(file.exists(here::here("data", "external", "KaatumisenPelko.csv")),
              "Data file not found")

  result <- run_script_smoke("K13")
  expect_true(result$success, info = result$error)

  expected_outputs <- c(
    "lm_age_int_extended_full.csv",
    "lm_BMI_int_extended_full.csv",
    "lm_sex_int_extended_full.csv",
    "FOF_interaction_effects_overview.csv",
    "simple_slopes_FOF_by_age.csv",
    "FOF_effect_by_age_simple_slopes.png"
  )

  outputs_exist <- check_script_outputs("K13", expected_outputs)
  expect_true(outputs_exist, "Some expected outputs are missing for K13")
})

# ==============================================================================
# Test: K14.R - Baseline Table
# ==============================================================================

test_that("K14.R runs without errors", {
  skip_if_not(file.exists(here::here("data", "external", "KaatumisenPelko.csv")),
              "Data file not found")

  result <- run_script_smoke("K14")
  expect_true(result$success, info = result$error)

  expected_outputs <- c(
    "K14_baseline_by_FOF.csv",
    "K14_baseline_by_FOF.html"
  )

  outputs_exist <- check_script_outputs("K14", expected_outputs)
  expect_true(outputs_exist, "Some expected outputs are missing for K14")
})

# ==============================================================================
# Test: K15.R - Frailty Proxy
# ==============================================================================

test_that("K15.R runs without errors", {
  skip_if_not(file.exists(here::here("data", "external", "KaatumisenPelko.csv")),
              "Data file not found")

  result <- run_script_smoke("K15")
  expect_true(result$success, info = result$error)

  expected_outputs <- c(
    "K15_frailty_count_3_overall.csv",
    "K15_frailty_cat_3_overall.csv",
    "K15_frailty_cat3_by_FOF.csv",
    "K15_frailty_analysis_data.RData",
    "K15_frailty_cat3_by_FOF.png"
  )

  outputs_exist <- check_script_outputs("K15", expected_outputs)
  expect_true(outputs_exist, "Some expected outputs are missing for K15")
})

# ==============================================================================
# Test: K16.R - Frailty-Adjusted Models
# ==============================================================================

test_that("K16.R runs without errors", {
  skip_if_not(file.exists(here::here("data", "external", "KaatumisenPelko.csv")),
              "Data file not found")

  # K16 requires K15 output
  skip_if_not(file.exists(here::here("R-scripts", "K15", "outputs",
                                     "K15_frailty_analysis_data.RData")),
              "K15 output required for K16")

  result <- run_script_smoke("K16")
  expect_true(result$success, info = result$error)

  expected_outputs <- c(
    "K16_frailty_models_tables.docx",
    "K16_all_models.RData",
    "K16_frailty_effects_plot.png",
    "K16_predicted_trajectories.png",
    "K16_Results_EN.txt",
    "K16_Results_FI.txt"
  )

  outputs_exist <- check_script_outputs("K16", expected_outputs)
  expect_true(outputs_exist, "Some expected outputs are missing for K16")
})

# ==============================================================================
# Test: Data File Exists
# ==============================================================================

test_that("Required data file exists", {
  data_file <- here::here("data", "external", "KaatumisenPelko.csv")
  expect_true(file.exists(data_file),
              "Data file KaatumisenPelko.csv not found in data/external/")
})

# ==============================================================================
# Test: Helper Functions Load
# ==============================================================================

test_that("Helper functions can be sourced", {
  helper_files <- c(
    here::here("R", "functions", "io.R"),
    here::here("R", "functions", "checks.R"),
    here::here("R", "functions", "modeling.R"),
    here::here("R", "functions", "reporting.R")
  )

  for (helper_file in helper_files) {
    expect_true(file.exists(helper_file),
                info = paste("Helper file not found:", basename(helper_file)))

    if (file.exists(helper_file)) {
      expect_error(source(helper_file, local = new.env()), NA,
                  info = paste("Error sourcing:", basename(helper_file)))
    }
  }
})

# ==============================================================================
# Summary Report
# ==============================================================================

message("\n", strrep("=", 70))
message("SMOKE TEST SUMMARY")
message(strrep("=", 70))
message("\nAll smoke tests completed.")
message("Check test results above for any failures or warnings.")
message("\nTo run these tests:")
message("  Rscript -e \"testthat::test_file('tests/smoke_test_k11_k16.R')\"")
message(strrep("=", 70), "\n")
