#' Bootstrap helper for Quantify-FOF-Utilization-Costs
#' Finds the project root and sources path_utils.R

get_project_dir <- function() {
  args_all <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args_all, value = TRUE)
  script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else NA_character_
  script_dir  <- if (!is.na(script_path)) dirname(normalizePath(script_path, mustWork = FALSE)) else getwd()
  
  project_dir <- script_dir
  # Traverse up until we are no longer in known subdirectories
  while (basename(project_dir) %in% c("R", "scripts", "tests", "security", "10_table1", "10_table1_patient_characteristics_by_fof")) {
    project_dir <- dirname(project_dir)
  }
  return(project_dir)
}

project_dir <- get_project_dir()
source(file.path(project_dir, "R", "path_utils.R"))
