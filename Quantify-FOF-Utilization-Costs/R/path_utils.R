#' Safely join path parts to a base directory, preventing path traversal.
#' Raises an error if the resulting path is outside the base directory.
#' @param base The base directory (should be an absolute path).
#' @param ... Path components to join.
#' @return A normalized absolute path.
safe_join_path <- function(base, ...) {
  if (is.null(base) || base == "") {
    stop("Security Violation: Base directory for safe_join_path is empty.")
  }

  # Block absolute paths in parts to prevent escaping the base
  parts <- list(...)
  for (p in parts) {
    if (is.character(p) && length(p) > 0 && grepl("^/|^[A-Za-z]:", p)) {
      stop("Security Violation: Absolute path detected in joined parts.")
    }
  }

  # Use normalizePath with mustWork=FALSE to handle non-existent paths (e.g. output dirs)
  resolved_base <- normalizePath(base, mustWork = FALSE, winslash = "/")
  
  # Ensure base is treated as a directory by normalizePath
  if (!endsWith(resolved_base, "/")) {
    resolved_base <- paste0(resolved_base, "/")
  }

  joined_path <- do.call(file.path, c(list(resolved_base), parts))
  
  # normalizePath(..., mustWork=FALSE) does NOT resolve ../ if the path doesn't exist
  # We need to manually resolve .. to prevent traversal on non-existent output paths.
  
  # 1. Split path into components
  path_parts <- strsplit(joined_path, "/|\\\\")[[1]]
  # 2. Process components (stack based resolution)
  stack <- character()
  for (part in path_parts) {
    if (part == "" || part == ".") next
    if (part == "..") {
      if (length(stack) > 0) stack <- stack[-length(stack)]
    } else {
      stack <- c(stack, part)
    }
  }
  # 3. Reconstruct
  # On Linux, leading / was lost in strsplit if joined_path was absolute
  prefix <- if (grepl("^/", joined_path)) "/" else ""
  resolved_path <- paste0(prefix, paste(stack, collapse = "/"))
  
  # Ensure resolved_path is normalized again
  resolved_path <- normalizePath(resolved_path, mustWork = FALSE, winslash = "/")

  # Robust boundary checking
  if (!startsWith(resolved_path, resolved_base)) {
    # Security: Do NOT leak absolute paths in the error message (Option B)
    stop("Security Violation: Path traversal detected or path outside restricted boundary.")
  }

  return(resolved_path)
}
