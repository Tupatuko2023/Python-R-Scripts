#!/usr/bin/env Rscript
library(tidyverse)

# Load security utilities
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else NA_character_
script_dir  <- if (!is.na(script_path)) dirname(normalizePath(script_path, mustWork = FALSE)) else getwd()
project_dir <- script_dir
while (basename(project_dir) %in% c("R", "scripts", "10_table1", "10_table1_patient_characteristics_by_fof")) {
  project_dir <- dirname(project_dir)
}
source(file.path(project_dir, "R", "path_utils.R"))

DATA_ROOT <- Sys.getenv("DATA_ROOT")
panel_path <- safe_join_path(DATA_ROOT, "derived", "aim2_panel.csv")

if (!file.exists(panel_path)) {
  message("Panel data not found at: ", panel_path)
  message("Skipping QC summary (run script 10 first).")
  quit(save="no")
}

# Load panel
panel <- read.csv(panel_path, stringsAsFactors = FALSE)

# QC Metrics

qc_out <- list()
qc_out$n_ids <- n_distinct(panel$id)
qc_out$n_rows <- nrow(panel)
qc_out$missing_fof <- mean(is.na(panel$FOF_status))
qc_out$zeros_cost <- mean(panel$cost_total_eur == 0, na.rm = TRUE)


# Save QC Report

dir.create("outputs", showWarnings = FALSE)
write_lines(paste(names(qc_out), qc_out, sep=": "), "outputs/qc_summary_aim2.txt")
