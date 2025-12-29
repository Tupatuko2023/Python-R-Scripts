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
    n         = n,
    notes     = notes
  )
}

# Append row to manifest CSV
append_manifest <- function(row, manifest_path) {
  stopifnot(is.data.frame(row))
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  
  if (!file.exists(manifest_path)) {
    readr::write_csv(row, manifest_path)
  } else {
    # suppressMessages to avoid "New names: ..." noise
    old <- suppressMessages(readr::read_csv(manifest_path, show_col_types = FALSE))
    out <- dplyr::bind_rows(old, row)
    readr::write_csv(out, manifest_path)
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
