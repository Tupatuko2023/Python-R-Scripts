# R Security Tests for path_utils.R

# Load utilities via bootstrap
# Search for bootstrap.R relative to this test script
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else NA_character_
curr_dir  <- if (!is.na(script_path)) dirname(normalizePath(script_path, mustWork = FALSE)) else getwd()

bootstrap_path <- file.path(curr_dir, "..", "..", "R", "bootstrap.R")
if (!file.exists(bootstrap_path)) {
  bootstrap_path <- "../../R/bootstrap.R"
}
source(bootstrap_path)

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
    msg <- conditionMessage(e)
    if (msg == "Failed to block traversal") stop(msg) # propagate if it didn't block
    if (!grepl("Security Violation", msg)) stop("Wrong error message: ", msg)
    # Check for leakage
    if (grepl("etc/passwd", msg)) stop("Leaked part of traversal path")
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
    msg <- conditionMessage(e)
    if (!grepl("Security Violation", msg)) stop("Wrong error message: ", msg)
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
    msg <- conditionMessage(e)
    if (!grepl("Security Violation", msg)) stop("Wrong error message: ", msg)
  })
})

# 5. Empty base
test_that("Empty base is blocked", {
  tryCatch({
    safe_join_path("", "test.csv")
    stop("Failed to block empty base")
  }, error = function(e) {
    msg <- conditionMessage(e)
    if (!grepl("Security Violation", msg)) stop("Wrong error message: ", msg)
  })
})

message("DONE: All R security tests passed.")
