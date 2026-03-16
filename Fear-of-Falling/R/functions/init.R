# R/functions/init.R
# ==============================================================================
# Canonical initialization and manifest logic for Fear-of-Falling pipeline.
# Sources: Originally split between qc.R and reporting.R.
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(tibble)
  library(readr)
  library(dplyr)
})

is_termux_runtime <- function() {
  prefix <- Sys.getenv("PREFIX", unset = "")
  home <- Sys.getenv("HOME", unset = "")
  grepl("/com\\.termux/", prefix) || grepl("/com\\.termux/", home)
}

read_manifest_csv <- function(path) {
  if (is_termux_runtime()) {
    return(utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE))
  }
  suppressMessages(readr::read_csv(path, show_col_types = FALSE))
}

write_manifest_csv <- function(df, path) {
  if (is_termux_runtime()) {
    utils::write.csv(df, path, row.names = FALSE, na = "")
  } else {
    readr::write_csv(df, path)
  }
}

# --- 1) Initialize paths for script --------------------------------------------
init_paths <- function(script_label) {
  # script_label example: "K11" (canonical folder name)
  
  # Ensure we are at project root or know where it is via 'here'
  outputs_dir   <- here::here("R-scripts", script_label, "outputs")
  manifest_path <- here::here("manifest", "manifest.csv")
  
  # Create directories if missing
  dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  
  # Set global options for convenience
  options(
    fof.outputs_dir   = outputs_dir,
    fof.manifest_path = manifest_path,
    fof.script        = script_label
  )
  
  # Return list for explicit usage
  list(outputs_dir = outputs_dir, manifest_path = manifest_path)
}

# --- 2) Manifest utilities -----------------------------------------------------

# Canonical manifest row constructor
manifest_row <- function(script, label, path, kind,
                         n = NA_integer_, notes = NA_character_) {
  tibble::tibble(
    timestamp = as.character(Sys.time()),
    script    = script,
    label     = label,
    kind      = kind,      # "table_csv", "table_html", "figure_png", "sessioninfo", "qc"
    path      = path,
    n         = as.character(n),
    notes     = as.character(notes)
  )
}

normalize_manifest_df <- function(df) {
  tibble::as_tibble(df) %>%
    mutate(
      timestamp = as.character(.data$timestamp),
      script = as.character(.data$script),
      label = as.character(.data$label),
      kind = as.character(.data$kind),
      path = as.character(.data$path),
      n = as.character(.data$n),
      notes = as.character(.data$notes)
    )
}

# Append row to manifest CSV
append_manifest <- function(row, manifest_path) {
  stopifnot(is.data.frame(row))
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  row <- dplyr::mutate(row, dplyr::across(dplyr::everything(), as.character))
  
  if (!file.exists(manifest_path)) {
    write_manifest_csv(normalize_manifest_df(row), manifest_path)
  } else {
    if (is_termux_runtime()) {
      old <- normalize_manifest_df(read_manifest_csv(manifest_path))
      out <- dplyr::bind_rows(old, normalize_manifest_df(row))
      write_manifest_csv(out, manifest_path)
    } else {
      old <- suppressMessages(
        readr::read_csv(
          manifest_path,
          show_col_types = FALSE,
          col_types = readr::cols(.default = readr::col_character())
        )
      )
      out <- dplyr::bind_rows(old, row)
      readr::write_csv(out, manifest_path)
    }
  }
  invisible(manifest_path)
}

# Helper to get relative path for manifest (if absolute path provided)
get_relpath <- function(path) {
  # Try to make it relative to project root
  root <- here::here()
  if (startsWith(normalizePath(path, winslash = "/", mustWork = FALSE), 
                 normalizePath(root, winslash = "/", mustWork = FALSE))) {
    return(sub(paste0("^", normalizePath(root, winslash = "/", mustWork = FALSE), "/"), "", 
               normalizePath(path, winslash = "/", mustWork = FALSE)))
  }
  path
}
