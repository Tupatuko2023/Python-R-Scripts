# Run K1-K7 scripts
scripts <- c(
  "R-scripts/K1/K1.7.main.R",
  "R-scripts/K2/K2.Z_Score_C_Pivot_2G.R",
  "R-scripts/K3/K3.7.main.R",
  "R-scripts/K4/K4.A_Score_C_Pivot_2G.R",
  "R-scripts/K5/K5.1.V4_Moderation_analysis.R",
  "R-scripts/K5/K5.2.Johnson_Neyman.R",
  "R-scripts/K6/K6.R",
  "R-scripts/K7/K7.R"
)

results <- list()
for (script in scripts) {
  script_name <- basename(dirname(script))
  if (grepl("K5", basename(script))) {
    script_name <- sub(".R$", "", basename(script))
  }
  
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
  cat(sprintf("%s %-30s: %s (%.2fs)\n", 
              status_symbol, 
              name, 
              results[[name]]$status,
              results[[name]]$time))
}

# Count successes and failures
n_success <- sum(sapply(results, function(x) x$status == "SUCCESS"))
n_failed <- sum(sapply(results, function(x) x$status == "FAILED"))

cat("\nTotal:", length(results), "| Success:", n_success, "| Failed:", n_failed, "\n")
