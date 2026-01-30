#!/usr/bin/env Rscript
library(tidyverse)
library(readr)

# --- CONFIG ---

DATA_ROOT <- Sys.getenv("DATA_ROOT")
if (DATA_ROOT == "") stop("DATA_ROOT environment variable not set.")

# Load Standardization Map

std_path <- "data/VARIABLE_STANDARDIZATION.csv"
if (!file.exists(std_path)) stop("Missing data/VARIABLE_STANDARDIZATION.csv")
std_map <- read_csv(std_path, show_col_types = FALSE)

message("Loading raw data from: ", DATA_ROOT)

# TODO: Implement loading logic for Paper 02 (Hilmo, Avohilmo, KAAOS)

# TODO: Implement join logic for person-period panel

# Placeholder for output path

derived_path <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")

# dir.create(dirname(derived_path), showWarnings = FALSE, recursive = TRUE)

# write_csv(panel_df, derived_path)

message("Script 10: Placeholder execution complete.")
