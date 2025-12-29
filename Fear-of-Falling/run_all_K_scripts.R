# Run all K scripts
scripts <- c(
  "R-scripts/K8/K8.R",
  "R-scripts/K9/K9.R",
  "R-scripts/K10/K10.R",
  "R-scripts/K11/K11.R",
  "R-scripts/K12/K12.R",
  "R-scripts/K13/K13.R",
  "R-scripts/K14/K14.R",
  "R-scripts/K15/K15.R",
  "R-scripts/K16/K16.R",
  "R-scripts/K17/K17.R",
  "R-scripts/K18/K18.R"
)

results <- list()
for (script in scripts) {
  script_name <- basename(dirname(script))
  cat("\n", rep("=", 70), "\n")
  cat("Running:", script_name, "\n")
  cat(rep("=", 70), "\n\n")
  
  start_time <- Sys.time()
  tryCatch({
    source(script)
    end_time <- Sys.time()
    results[[script_name]] <- list(
      status = "SUCCESS",
      time = as.numeric(difftime(end_time, start_time, units = "secs"))
    )
    cat("\n✓", script_name, "completed in", round(as.numeric(difftime(end_time, start_time, units = "secs")), 2), "seconds\n")
  }, error = function(e) {
    end_time <- Sys.time()
    results[[script_name]] <<- list(
      status = "FAILED",
      error = as.character(e),
      time = as.numeric(difftime(end_time, start_time, units = "secs"))
    )
    cat("\n✗", script_name, "FAILED:", as.character(e), "\n")
  })
}

# Print summary
cat("\n\n", rep("=", 70), "\n")
cat("SUMMARY\n")
cat(rep("=", 70), "\n\n")

for (name in names(results)) {
  status_symbol <- if(results[[name]]$status == "SUCCESS") "✓" else "✗"
  cat(sprintf("%s %-6s: %s (%.2fs)\n", 
              status_symbol, 
              name, 
              results[[name]]$status,
              results[[name]]$time))
}

# Count successes and failures
n_success <- sum(sapply(results, function(x) x$status == "SUCCESS"))
n_failed <- sum(sapply(results, function(x) x$status == "FAILED"))

cat("\nTotal:", length(results), "| Success:", n_success, "| Failed:", n_failed, "\n")
