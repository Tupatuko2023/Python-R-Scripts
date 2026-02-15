#!/usr/bin/env Rscript
# scripts/30_models_panel_nb_gamma.R
# Placeholder script for panel models (Negative Binomial / Gamma)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) >= 2) {
  input_file <- args[1]
  output_file <- args[2]
} else {
  # Default paths if not provided
  out_root <- Sys.getenv("OUTPUT_DIR", unset = "outputs")
  input_file <- file.path(out_root, "intermediate", "analysis_ready.csv")
  output_file <- file.path(out_root, "panel_models_summary.csv")
}

if (!file.exists(input_file)) {
  stop(paste("Input file not found:", input_file))
}

message("Reading input data from: ", input_file)
# Read CSV (base R for minimal dependencies in this placeholder)
df <- read.csv(input_file)
message("Rows: ", nrow(df))

# Simulate model results
# In a real scenario, this would fit models (e.g., glmer.nb) and extract coefficients
summary_df <- data.frame(
  model = c("Negative Binomial (Count)", "Gamma (Cost)"),
  n_obs = c(nrow(df), nrow(df)),
  aic = c(1234.5, 5678.9),
  bic = c(1240.0, 5685.0),
  converged = c(TRUE, TRUE)
)

dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
write.csv(summary_df, output_file, row.names = FALSE)
message("Wrote model summary to: ", output_file)
