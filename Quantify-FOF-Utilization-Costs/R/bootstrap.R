# R Bootstrap script for Quantify-FOF-Utilization-Costs
# Purpose: Robustly detect project root and source common utilities

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else NA_character_
script_dir  <- if (!is.na(script_path)) dirname(normalizePath(script_path, mustWork = FALSE)) else getwd()

# Detect project root by traversing upwards until we find a characteristic directory/file
project_dir <- script_dir
while (basename(project_dir) %in% c("R", "scripts", "10_table1", "10_table1_patient_characteristics_by_fof", "outputs", "logs", "security")) {
  project_dir <- dirname(project_dir)
}

# Ensure project_dir is correctly set (e.g., if we started at repo root)
if (!dir.exists(file.path(project_dir, "R"))) {
    # Fallback to current directory if discovery failed
    project_dir <- getwd()
}

# Source security utilities
source(file.path(project_dir, "R", "path_utils.R"))

# Export project_dir to global environment
assign("project_dir", project_dir, envir = .GlobalEnv)
