# ==============================================================================
# common.R
# Purpose: Shared utilities for environment loading and logging.
# ==============================================================================

# Function to ensure DATA_ROOT is set
ensure_data_root <- function() {
  DATA_ROOT <- Sys.getenv("DATA_ROOT")
  if (DATA_ROOT == "") {
    # Try to load from .env
    # We assume the script is run from project root, or we look for config/.env relative to getwd()
    config_path <- file.path(getwd(), "config", ".env")
    if (!file.exists(config_path)) {
      # Try relative to script location if we can (hard in Rscript)
      # Assume project root execution for now as per WORKFLOW.md
    } else {
      lines <- readLines(config_path)
      for (line in lines) {
        # Simple parser: key=value
        if (grepl("^DATA_ROOT=", line)) {
          val <- sub("^DATA_ROOT=", "", line)
          # remove quotes if present
          val <- gsub("^['\"]|['\"]$", "", val)
          Sys.setenv(DATA_ROOT = val)
          DATA_ROOT <- val
          break
        }
      }
    }
  }

  if (DATA_ROOT == "") {
    stop("DATA_ROOT environment variable is not set. Please set it or create config/.env.")
  }

  if (!dir.exists(DATA_ROOT)) {
    stop(paste("DATA_ROOT directory does not exist:", DATA_ROOT))
  }

  return(DATA_ROOT)
}

# Function to log to manifest
log_manifest <- function(filepath, script_name, data_root) {
  if (!file.exists(filepath)) return(FALSE)

  manifest_path <- file.path(data_root, "manifest", "manifest.csv")
  if (!dir.exists(dirname(manifest_path))) dir.create(dirname(manifest_path), recursive = TRUE)

  # Check digest availability
  if (!requireNamespace("digest", quietly = TRUE)) {
    warning("digest package missing, skipping hash calculation")
    hash <- "UNKNOWN"
  } else {
    hash <- digest::digest(file = filepath, algo = "sha256")
  }

  rel_path <- sub(paste0("^", data_root, "/?"), "", filepath)
  entry <- data.frame(
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"),
    file = rel_path,
    hash = hash,
    script = script_name,
    stringsAsFactors = FALSE
  )

  write.table(entry, file = manifest_path, append = file.exists(manifest_path),
              sep = ",", row.names = FALSE, col.names = !file.exists(manifest_path),
              quote = FALSE)
  message(paste("Manifest updated for:", rel_path))
}
