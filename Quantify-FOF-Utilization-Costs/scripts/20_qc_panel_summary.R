#!/usr/bin/env Rscript
library(tidyverse)

DATA_ROOT <- Sys.getenv("DATA_ROOT")
panel_path <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")

if (!file.exists(panel_path)) {
  message("Panel data not found at: ", panel_path)
  message("Skipping QC summary (run script 10 first).")
  quit(save="no")
}

panel <- read_csv(panel_path, show_col_types = FALSE)

# QC Metrics

qc_out <- list()
qc_out$n_ids <- n_distinct(panel$id)
qc_out$n_rows <- nrow(panel)
qc_out$missing_fof <- mean(is.na(panel$FOF_status))
qc_out$zeros_cost <- mean(panel$cost_total_eur == 0, na.rm = TRUE)


# Save QC Report

dir.create("outputs", showWarnings = FALSE)
write_lines(paste(names(qc_out), qc_out, sep=": "), "outputs/qc_summary_aim2.txt")
