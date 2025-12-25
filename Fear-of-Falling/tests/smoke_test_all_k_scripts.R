#!/usr/bin/env Rscript
# ==============================================================================
# Comprehensive Smoke Test Runner for K1-K4 and K6-K16 (end-to-end)
# ==============================================================================
# Purpose: Run all required K scripts in dependency-safe order and generate
#          a markdown report.
#
# Order constraints:
#   - K1 must run before K2 (K2 depends on K1 outputs)
#   - K3 must run before K4 (K4 depends on K3 outputs)
#
# Execution strategy:
#   - Run each script in isolation using Rscript --vanilla via system2()
#   - Track outputs created under R-scripts/<K>/outputs (before/after)
#   - Fail (exit status 1) if ANY script fails
#
# Default per-script timeout: 300s (best-effort; uses R.utils::withTimeout if available)
#
# Date: 2025-12-25
# ==============================================================================

TIMEOUT_SECONDS <- 300

# Explicit script mapping with correct entry points for K1-K4
SCRIPTS_TO_TEST <- list(
  K1  = "R-scripts/K1/K1.7.main.R",
  K2  = "R-scripts/K2/K2.Z_Score_C_Pivot_2G.R",
  K3  = "R-scripts/K3/K3.7.main.R",
  K4  = "R-scripts/K4/K4.A_Score_C_Pivot_2G.R",
  K6  = "R-scripts/K6/K6.R",
  K7  = "R-scripts/K7/K7.R",
  K8  = "R-scripts/K8/K8.R",
  K9  = "R-scripts/K9/K9.R",
  K10 = "R-scripts/K10/K10.R",
  K11 = "R-scripts/K11/K11.R",
  K12 = "R-scripts/K12/K12.R",
  K13 = "R-scripts/K13/K13.R",
  K14 = "R-scripts/K14/K14.R",
  K15 = "R-scripts/K15/K15.R",
  K16 = "R-scripts/K16/K16.R"
)

REPORT_FILE <- "SMOKE_TEST_REPORT_ALL_K_SCRIPTS.md"

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

# Check for data file in multiple possible locations
find_data_file <- function() {
  candidates <- c(
    file.path("data", "external", "KaatumisenPelko.csv"),
    file.path("dataset", "KaatumisenPelko.csv"),
    file.path("data", "raw", "KaatumisenPelko.csv")
  )
  for (p in candidates) {
    if (file.exists(p)) return(p)
  }
  return(NA_character_)
}

# Safely list outputs directory (handles non-existent dirs)
safe_list_outputs <- function(outputs_dir) {
  if (!dir.exists(outputs_dir)) return(character(0))
  list.files(outputs_dir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
}

# Null coalescing operator
`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# Run a single script in isolation using Rscript --vanilla
run_one_script <- function(k_name, script_path, timeout_seconds = TIMEOUT_SECONDS) {
  if (!file.exists(script_path)) {
    return(list(
      script = k_name,
      path = script_path,
      success = FALSE,
      exit_code = 2,
      elapsed = NA_real_,
      outputs_created = 0L,
      new_files = character(0),
      stdout = "",
      stderr = paste("Script file not found:", script_path)
    ))
  }

  cat_section(paste("Testing:", k_name))
  cat("Script path:", script_path, "\n")
  cat("Starting at:", as.character(Sys.time()), "\n\n")

  # Track outputs before running
  outputs_dir <- file.path("R-scripts", k_name, "outputs")
  outputs_before <- safe_list_outputs(outputs_dir)

  start_time <- Sys.time()

  # Run isolated via Rscript --vanilla
  run_call <- function() {
    out <- tempfile(pattern = paste0("smoke_stdout_", k_name, "_"), fileext = ".log")
    err <- tempfile(pattern = paste0("smoke_stderr_", k_name, "_"), fileext = ".log")

    exit_code <- suppressWarnings(system2(
      command = "Rscript",
      args = c("--vanilla", script_path),
      stdout = out,
      stderr = err
    ))

    stdout_content <- ""
    stderr_content <- ""

    if (file.exists(out)) {
      stdout_content <- paste(readLines(out, warn = FALSE), collapse = "\n")
      unlink(out)
    }
    if (file.exists(err)) {
      stderr_content <- paste(readLines(err, warn = FALSE), collapse = "\n")
      unlink(err)
    }

    list(
      exit_code = exit_code,
      stdout = stdout_content,
      stderr = stderr_content
    )
  }

  timed_out <- FALSE
  res <- NULL

  # Best-effort timeout using R.utils if present; fallback otherwise
  if (requireNamespace("R.utils", quietly = TRUE)) {
    res <- tryCatch({
      R.utils::withTimeout(run_call(), timeout = timeout_seconds, onTimeout = "error")
    }, error = function(e) {
      timed_out <<- grepl("Timeout", conditionMessage(e), ignore.case = TRUE)
      list(
        exit_code = if (timed_out) 124 else 1,
        stdout = "",
        stderr = conditionMessage(e)
      )
    })
  } else {
    # No timeout support available; run without hard timeout
    res <- tryCatch(run_call(), error = function(e) {
      list(exit_code = 1, stdout = "", stderr = conditionMessage(e))
    })
  }

  end_time <- Sys.time()
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # Track outputs after running
  outputs_after <- safe_list_outputs(outputs_dir)
  outputs_new <- setdiff(outputs_after, outputs_before)

  success <- isTRUE(res$exit_code == 0)
  if (success) {
    cat("✓", k_name, "completed successfully in", sprintf("%.1f", elapsed), "seconds\n")
  } else {
    cat("✗", k_name, "FAILED (exit:", res$exit_code, ") in", sprintf("%.1f", elapsed), "seconds\n")
  }
  cat("  New outputs created:", length(outputs_new), "\n")

  list(
    script = k_name,
    path = script_path,
    success = success,
    exit_code = res$exit_code,
    elapsed = elapsed,
    outputs_created = length(outputs_new),
    new_files = outputs_new,
    stdout = res$stdout %||% "",
    stderr = res$stderr %||% ""
  )
}

# Generate comprehensive markdown report
generate_report <- function(results, report_file = REPORT_FILE, data_path = NA_character_) {
  passed <- sum(vapply(results, function(x) isTRUE(x$success), logical(1)))
  failed <- sum(vapply(results, function(x) !isTRUE(x$success), logical(1)))
  total <- length(results)

  header <- c(
    "# SMOKE TEST REPORT: ALL REQUIRED K SCRIPTS (K1–K4, K6–K16)",
    "",
    paste("**Date:**", as.character(Sys.time())),
    paste("**Scripts tested:**", total),
    paste("**Passed:**", passed, "✓"),
    paste("**Failed:**", failed, if (failed > 0) "✗" else ""),
    paste("**Per-script timeout (s):**", TIMEOUT_SECONDS),
    paste("**Data file detected:**", if (!is.na(data_path)) data_path else "NONE (warning)"),
    "",
    "---",
    "",
    "## SUMMARY",
    ""
  )

  table <- c("| Script | Status | Exit | Time (s) | Outputs | Error (truncated) |",
             "|--------|--------|------|----------|---------|-------------------|")

  for (res in results) {
    status_icon <- if (isTRUE(res$success)) "✓ PASS" else "✗ FAIL"
    time_str <- if (!is.na(res$elapsed)) sprintf("%.1f", res$elapsed) else "N/A"
    outputs_str <- if (res$outputs_created > 0) as.character(res$outputs_created) else "-"
    err_src <- trimws(res$stderr %||% "")
    err_trunc <- if (nchar(err_src) > 0) substr(err_src, 1, 80) else "-"

    table <- c(table, sprintf("| %s | %s | %s | %s | %s | %s |",
                             res$script, status_icon, res$exit_code, time_str,
                             outputs_str, gsub("\n", " ", err_trunc)))
  }

  details <- c("", "---", "", "## DETAILED RESULTS", "")
  for (res in results) {
    details <- c(details, paste("###", res$script), "")
    details <- c(details, paste("**Path:**", res$path))
    details <- c(details, paste("**Status:**", if (isTRUE(res$success)) "✓ PASSED" else "✗ FAILED"))
    details <- c(details, paste("**Exit code:**", res$exit_code))
    details <- c(details, paste("**Execution time:**", if (!is.na(res$elapsed)) sprintf("%.1f seconds", res$elapsed) else "N/A"))
    details <- c(details, paste("**Outputs created:**", res$outputs_created))

    if (length(res$new_files) > 0) {
      details <- c(details, "", "**New files (max 25 shown):**", "")
      for (f in head(res$new_files, 25)) details <- c(details, paste("-", f))
    }

    if (!isTRUE(res$success)) {
      details <- c(details, "", "**STDERR:**", "```", substr(res$stderr %||% "", 1, 4000), "```")
      # stdout can be huge; include short tail
      if (nchar(res$stdout %||% "") > 0) {
        details <- c(details, "", "**STDOUT (tail):**", "```")
        out_lines <- strsplit(res$stdout, "\n", fixed = TRUE)[[1]]
        details <- c(details, paste(tail(out_lines, 80), collapse = "\n"))
        details <- c(details, "```")
      }
    }
    details <- c(details, "", "---", "")
  }

  recs <- c("## RECOMMENDATIONS", "")
  if (is.na(data_path)) {
    recs <- c(recs, "### Data prerequisite missing", "",
              "- No KaatumisenPelko.csv was found in expected locations. Some scripts are expected to fail.",
              "- Provide one of: `data/external/KaatumisenPelko.csv`, `dataset/KaatumisenPelko.csv`, or `data/raw/KaatumisenPelko.csv`.",
              "")
  }

  if (failed > 0) {
    recs <- c(recs, "### Failed scripts", "")
    for (res in results[vapply(results, function(x) !isTRUE(x$success), logical(1))]) {
      recs <- c(recs, paste0("- **", res$script, "** (exit ", res$exit_code, "): ", substr(trimws(res$stderr %||% ""), 1, 200)))
    }
  } else {
    recs <- c(recs, "✓ All scripts passed! No issues detected.")
  }

  report <- c(header, table, details, recs, "", "---", "", "## END OF REPORT")
  writeLines(report, report_file)
  cat("\n✓ Report saved to:", report_file, "\n\n")
  report_file
}

# ==============================================================================
# Main Execution
# ==============================================================================

cat_header("SMOKE TEST SUITE: ALL REQUIRED K SCRIPTS")
cat("Scripts to test (ordered):", paste(names(SCRIPTS_TO_TEST), collapse = ", "), "\n")
cat("Timeout per script:", TIMEOUT_SECONDS, "seconds\n")
cat("Started at:", as.character(Sys.time()), "\n")

cat("\nChecking prerequisites...\n")
data_path <- find_data_file()
if (!is.na(data_path)) {
  cat("✓ Data file found at:", data_path, "\n")
} else {
  cat("✗ WARNING: No data file found in expected locations.\n")
  cat("  Some scripts may fail without this file.\n")
}

# Run all scripts in order
results <- list()
for (k in names(SCRIPTS_TO_TEST)) {
  results[[k]] <- run_one_script(k, SCRIPTS_TO_TEST[[k]], timeout_seconds = TIMEOUT_SECONDS)
  Sys.sleep(0.5)  # Small delay between scripts
}

# Generate summary
cat_header("TEST SUMMARY")
passed <- sum(vapply(results, function(x) isTRUE(x$success), logical(1)))
failed <- sum(vapply(results, function(x) !isTRUE(x$success), logical(1)))
total <- length(results)
cat("Total scripts:", total, "\n")
cat("Passed:", passed, "✓\n")
cat("Failed:", failed, if (failed > 0) "✗" else "", "\n\n")

# Generate detailed report
report_file <- generate_report(results, report_file = REPORT_FILE, data_path = data_path)
cat("See detailed report:", report_file, "\n")

# Exit with appropriate status code
if (failed > 0) quit(status = 1) else quit(status = 0)
