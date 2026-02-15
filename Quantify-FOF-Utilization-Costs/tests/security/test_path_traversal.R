# R Security Tests for path_utils.R

# Source the utility
# Assuming run from Quantify-FOF-Utilization-Costs/tests/security/
source("../../R/path_utils.R")

test_that <- function(desc, code) {
  message("Testing: ", desc)
  tryCatch({
    code
    message("  SUCCESS")
  }, error = function(e) {
    message("  FAILED: ", e)
    stop(e)
  })
}

# 1. Valid join
test_that("Valid path joins stay within boundary", {
  base <- normalizePath(".", mustWork = FALSE)
  res <- safe_join_path(base, "data", "test.csv")
  if (!startsWith(res, base)) stop("Resulting path does not start with base")
})

# 2. Traversal attempt
test_that("Path traversal is blocked", {
  base <- normalizePath(".", mustWork = FALSE)
  tryCatch({
    safe_join_path(base, "../../../etc/passwd")
    stop("Failed to block traversal")
  }, error = function(e) {
    if (!grepl("Security Violation", e)) stop("Wrong error message: ", e)
    # Check for leakage
    if (grepl("etc/passwd", e)) stop("Leaked part of traversal path")
  })
})

# 3. Absolute path attempt
test_that("Absolute paths are blocked if they leave boundary", {
  base <- normalizePath(".", mustWork = FALSE)
  tryCatch({
    # In R, file.path(base, "/etc/passwd") produces base//etc/passwd
    # normalizePath(base//etc/passwd) resolves to /etc/passwd on Linux
    safe_join_path(base, "/etc/passwd")
    stop("Failed to block absolute path traversal")
  }, error = function(e) {
    if (!grepl("Security Violation", e)) stop("Wrong error message: ", e)
  })
})

# 4. Sibling directory attempt
test_that("Sibling directories are blocked", {
  base <- normalizePath(".", mustWork = FALSE)
  # Create a name that starts with 'base' but is a sibling
  # e.g. if base is /app/data, sibling is /app/data_sensitive
  sibling_name <- paste0(basename(base), "_sensitive")
  tryCatch({
    safe_join_path(base, "..", sibling_name, "file.txt")
    stop("Failed to block sibling directory traversal")
  }, error = function(e) {
    if (!grepl("Security Violation", e$message)) stop("Wrong error message: ", e$message)
  })
})

# 5. Empty base
test_that("Empty base is blocked", {
  tryCatch({
    safe_join_path("", "test.csv")
    stop("Failed to block empty base")
  }, error = function(e) {
    if (!grepl("Security Violation", e)) stop("Wrong error message: ", e)
  })
})

message("DONE: All R security tests passed.")
