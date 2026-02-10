#!/usr/bin/env Rscript
# ==============================================================================
# 01_ingest.R
# Purpose: Ingest raw data from DATA_ROOT/raw/ into standardized Parquet files in DATA_ROOT/staging/.
# Usage: Rscript R/01_ingest.R
# ==============================================================================

suppressPackageStartupMessages({
  library(yaml)
  library(readxl)
  library(readr)
  library(dplyr)
  library(arrow)
  library(stringr)
  if (requireNamespace("digest", quietly = TRUE)) library(digest)
})

# Load common utilities
common_script <- file.path("R", "common.R")
if (!file.exists(common_script)) {
  # Try finding it relative to script location if ran from R/
  common_script <- file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly=FALSE), value=TRUE)[1])), "common.R")
}
if (file.exists(common_script)) {
  source(common_script)
} else {
  # Fallback if common.R not found (shouldn't happen in correct workflow)
  ensure_data_root <- function() Sys.getenv("DATA_ROOT")
  log_manifest <- function(...) message("Manifest logging unavailable (common.R missing)")
}

DATA_ROOT <- ensure_data_root()

CONFIG_PATH <- file.path("config", "ingest_config.yaml")
if (!file.exists(CONFIG_PATH)) stop("config/ingest_config.yaml not found.")

config <- yaml::read_yaml(CONFIG_PATH)
datasets <- config$datasets

staging_dir <- file.path(DATA_ROOT, "staging")
if (!dir.exists(staging_dir)) dir.create(staging_dir, recursive = TRUE)

# --- Helper Functions ---

normalize_header <- function(x) {
  x <- gsub("\u00A0", " ", x, fixed = TRUE)
  x <- gsub("[[:space:]]+", " ", x)
  trimws(x)
}

find_column <- function(df_names, pattern) {
  if (is.null(pattern)) return(NA)
  df_norm <- normalize_header(df_names)
  matches <- grep(pattern, df_norm, ignore.case = TRUE)
  if (length(matches) == 1) return(df_names[matches])
  if (length(matches) > 1) {
    warning(paste("Ambiguous pattern match for:", pattern, "Matches:", paste(df_names[matches], collapse=", ")))
    return(df_names[matches[1]])
  }
  return(NA)
}

cast_value <- function(val, type) {
  if (all(is.na(val))) {
    if (type == "integer") return(as.integer(val))
    if (type == "numeric") return(as.numeric(val))
    if (type == "text" || type == "character") return(as.character(val))
    if (type == "date") return(as.Date(val)) # simplistic
    return(val)
  }

  if (type == "integer") {
    suppressWarnings(as.integer(val))
  } else if (type == "numeric") {
    suppressWarnings(as.numeric(val))
  } else if (type == "text" || type == "character") {
    as.character(val)
  } else if (type == "date") {
     if (inherits(val, "POSIXt") || inherits(val, "Date")) {
       as.Date(val)
     } else {
       as.character(val) # Setup for later parsing or let it be
     }
  } else {
    val
  }
}

process_dataset <- function(name, ds_config) {
  message(paste("Processing dataset:", name))

  input_path <- file.path(DATA_ROOT, "raw", ds_config$filename)
  if (!file.exists(input_path)) {
    warning(paste("Input file not found:", input_path))
    return(FALSE)
  }

  # Read Data
  if (ds_config$format == "excel") {
    df <- readxl::read_excel(input_path, sheet = ds_config$sheet)
  } else if (ds_config$format == "csv") {
    df <- readr::read_csv(input_path, show_col_types = FALSE)
  } else {
    stop("Unknown format")
  }

  # Map Columns
  # Initialize with correct number of rows
  n_rows <- nrow(df)
  df_out_list <- list()

  for (col_def in ds_config$columns) {
    target <- col_def$target
    pattern <- col_def$source_pattern

    src_col <- find_column(names(df), pattern)

    if (is.na(src_col)) {
      if (isTRUE(col_def$required)) {
        stop(paste("Required column not found for target:", target, "Pattern:", pattern))
      } else {
        message(paste("Optional column not found:", target))
        # Create NA column of correct type
        df_out_list[[target]] <- cast_value(rep(NA, n_rows), col_def$type)
      }
    } else {
      val <- df[[src_col]]
      df_out_list[[target]] <- cast_value(val, col_def$type)
    }
  }

  df_out <- as.data.frame(df_out_list)

  # Write Parquet
  output_path <- file.path(staging_dir, paste0(name, ".parquet"))
  arrow::write_parquet(df_out, output_path)
  message(paste("Wrote:", output_path))

  # Update Manifest
  log_manifest(output_path, "01_ingest.R", DATA_ROOT)
  return(TRUE)
}

# --- Main Loop ---
results <- lapply(names(datasets), function(name) {
  tryCatch({
    process_dataset(name, datasets[[name]])
  }, error = function(e) {
    message(paste("Error processing", name, ":", e$message))
    return(FALSE)
  })
})

if (all(unlist(results))) {
  message("Ingestion complete.")
} else {
  message("Ingestion completed with errors.")
  quit(status = 1)
}
