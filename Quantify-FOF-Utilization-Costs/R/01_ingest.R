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
# Try loading common.R relative to script location or current directory
common_script_locations <- c(
  file.path("R", "common.R"),
  file.path(getwd(), "R", "common.R"),
  file.path("common.R")
)

found_common <- FALSE
for (loc in common_script_locations) {
  if (file.exists(loc)) {
    source(loc)
    found_common <- TRUE
    break
  }
}

if (!found_common) {
  stop("Could not find R/common.R. Please run from project root.")
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

cast_value <- function(val, type, format = NULL) {
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
     } else if (!is.null(format)) {
       as.Date(as.character(val), format = format)
     } else {
       as.Date(as.character(val)) # Try default ISO
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
      df_out_list[[target]] <- cast_value(val, col_def$type, col_def$format)
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
