#' Safely join path parts to a base directory, preventing path traversal.
#' Raises an error if the resulting path is outside the base directory.
#' @param base The base directory (should be an absolute path).
#' @param ... Path components to join.
#' @return A normalized absolute path.
safe_join_path <- function(base, ...) {
  if (is.null(base) || base == "") {
    stop("Security Violation: Base directory for safe_join_path is empty.")
  }

  # Use normalizePath with mustWork=FALSE to handle non-existent paths (e.g. output dirs)
  resolved_base <- normalizePath(base, mustWork = FALSE)
  joined_path <- file.path(resolved_base, ...)
  resolved_path <- normalizePath(joined_path, mustWork = FALSE)

  # Robust boundary checking to avoid sibling directory vulnerabilities
  # (e.g., /app/data vs /app/data_sensitive).
  # Ensure resolved_base has a trailing separator for prefix matching.
  base_prefix <- resolved_base
  sep <- .Platform$file.sep
  if (!endsWith(base_prefix, sep)) {
    base_prefix <- paste0(base_prefix, sep)
  }

  # The resolved path is safe if it starts with the base_prefix OR is exactly the resolved_base.
  if (!(startsWith(resolved_path, base_prefix) || resolved_path == resolved_base)) {
    # Security: Do NOT leak absolute paths in the error message (Option B)
    stop("Security Violation: Path traversal detected or path outside restricted boundary.")
  }

  return(resolved_path)
}
