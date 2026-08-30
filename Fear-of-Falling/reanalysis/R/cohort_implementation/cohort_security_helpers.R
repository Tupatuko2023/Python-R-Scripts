# cohort_security_helpers.R
#
# Shared security helpers for cohort implementation output routing and atomic publication.
# Sourced by both the production producer and synthetic tests.
#
# These helpers implement:
#   - DATA_ROOT resolution (process env → .env fallback → fail-closed)
#   - Fail-closed worktree guard with ancestor-path and symlink resolution
#   - Ambiguous Git detection error handling
#   - Collision/integrity gate and atomic publication pipeline for restricted ledger outputs
#   - Strict exact-0600 permission validation on temporary and final restricted files
#   - Unambiguous TRUE requirements for all chmod operations (FALSE, NA, NULL fail closed)
#
# IMPORTANT: These functions control storage mechanics only and must NEVER
# modify cohort eligibility, scientific logic, or participant-level content.

# --- Core fail helper (may be overridden before sourcing) ---
if (!exists("fail", mode = "function")) {
  fail <- function(...) stop(paste0(...), call. = FALSE)
}

# --- .env parser (may be overridden before sourcing) ---
if (!exists("read_env_value", mode = "function")) {
  read_env_value <- function(path, key) {
    if (!file.exists(path)) fail("FAIL_CLOSED_ENV_MISSING")
    lines <- readLines(path, warn = FALSE)
    pattern <- paste0("^[[:space:]]*(export[[:space:]]+)?", key, "[[:space:]]*=")
    hit <- grep(pattern, lines, value = TRUE)
    if (length(hit) != 1L) fail("FAIL_CLOSED_", key, "_ROUTING_COUNT: ", length(hit))
    value <- trimws(sub("^[^=]*=", "", hit))
    if (nchar(value) >= 2L) {
      first <- substr(value, 1L, 1L)
      last <- substr(value, nchar(value), nchar(value))
      if (first == last && first %in% c("\"", "'")) value <- substr(value, 2L, nchar(value) - 1L)
    }
    if (!nzchar(value)) fail("FAIL_CLOSED_", key, "_EMPTY")
    value
  }
}

# --- SHA-256 helper (may be overridden before sourcing) ---
if (!exists("sha256_file", mode = "function")) {
  sha256_file <- function(path) {
    if (!file.exists(path)) fail("FAIL_CLOSED_MISSING_ARTIFACT: ", basename(path))
    out <- system2("sha256sum", shQuote(normalizePath(path, winslash = "/", mustWork = TRUE)), stdout = TRUE, stderr = TRUE)
    if (!identical(attr(out, "status"), NULL) || length(out) != 1L) {
      fail("FAIL_CLOSED_SHA256_UNAVAILABLE: ", basename(path))
    }
    sub("[[:space:]].*$", "", out)
  }
}

# --- Exact 0600 mode checkers ---
is_exact_mode_0600 <- function(path) {
  st <- suppressWarnings(file.info(path))
  if (is.null(st$mode) || is.na(st$mode)) return(FALSE)
  effective_bits <- bitwAnd(as.integer(st$mode), 511L) # 511L is 0777 octal
  effective_bits == 384L # 384L is 0600 octal (user read/write only)
}

get_octal_mode_str <- function(path) {
  st <- suppressWarnings(file.info(path))
  if (is.null(st$mode) || is.na(st$mode)) return("unknown")
  sprintf("%04o", bitwAnd(as.integer(st$mode), 511L))
}

# ======================================================================
# resolve_data_root(env_path)
# Resolves DATA_ROOT: process env first, then .env fallback, then fail.
# ======================================================================
resolve_data_root <- function(env_path) {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(data_root)) {
    data_root <- tryCatch(read_env_value(env_path, "DATA_ROOT"), error = function(e) "")
  }
  if (!nzchar(data_root)) {
    fail("FAIL_CLOSED_DATA_ROOT_NOT_SET: ",
         "DATA_ROOT is required. Set it in config/.env or the process environment. ",
         "Refusing to write participant-level outputs into repository.")
  }
  normalizePath(data_root, winslash = "/", mustWork = FALSE)
}

# ======================================================================
# resolve_existing_ancestor(path)
# Walk up from `path` until an existing directory is found.
# Fully resolves symlinks and relative constructs.
# ======================================================================
resolve_existing_ancestor <- function(path) {
  candidate <- tryCatch(normalizePath(path, winslash = "/", mustWork = FALSE), error = function(e) path)
  while (!dir.exists(candidate) && nzchar(candidate)) {
    parent <- dirname(candidate)
    if (identical(parent, candidate)) break
    candidate <- parent
  }
  if (!dir.exists(candidate)) {
    fail("FAIL_CLOSED_CANNOT_RESOLVE_ANCESTOR: ",
         "Could not find an existing ancestor directory for the restricted output path.")
  }
  normalizePath(candidate, winslash = "/", mustWork = TRUE)
}

# ======================================================================
# run_git_rev_parse(check_dir)
# Wraps system2("git", ...) to allow mock overrides in synthetic tests.
# ======================================================================
run_git_rev_parse <- function(check_dir) {
  mock_override <- Sys.getenv("MOCK_GIT_DETECTION_RESULT", unset = "")
  if (nzchar(mock_override)) {
    if (mock_override == "ERROR_128_UNKNOWN") {
      out <- "fatal: unexpected git system error"
      attr(out, "status") <- 128L
      return(out)
    } else if (mock_override == "ERROR_1_FAIL") {
      out <- "error: git command failure"
      attr(out, "status") <- 1L
      return(out)
    } else if (mock_override == "UNEXPECTED_STDOUT") {
      out <- "ambiguous_result"
      return(out)
    }
  }
  suppressWarnings(
    system2("git", c("-C", shQuote(check_dir), "rev-parse", "--is-inside-work-tree"),
            stdout = TRUE, stderr = TRUE)
  )
}

# ======================================================================
# assert_outside_worktree(target_dir)
# Fail-closed: refuses to allow writing if:
#   - The target (or its nearest existing ancestor/symlink target) is inside a Git worktree
#   - Git detection returns an unexpected/ambiguous error
# ======================================================================
assert_outside_worktree <- function(target_dir) {
  check_dir <- resolve_existing_ancestor(target_dir)

  result <- run_git_rev_parse(check_dir)
  exit_status <- attr(result, "status")
  output_text <- if (length(result) >= 1L) trimws(result[1L]) else ""

  # Case 1: git succeeds (exit 0) and says "true" → inside worktree → REJECT
  if (is.null(exit_status) && output_text == "true") {
    fail("FAIL_CLOSED_RESTRICTED_OUTPUT_INSIDE_WORKTREE: ",
         "Resolved restricted-data destination is inside a Git worktree. ",
         "Participant-level outputs must be written outside all Git worktrees.")
  }

  # Case 2: git exits with 128 and stderr says "not a git repository" → safely outside
  if (!is.null(exit_status) && exit_status == 128L) {
    stderr_text <- paste(result, collapse = " ")
    if (grepl("not a git repository", stderr_text, ignore.case = TRUE)) {
      return(invisible(normalizePath(target_dir, winslash = "/", mustWork = FALSE)))
    }
    fail("FAIL_CLOSED_GIT_DETECTION_AMBIGUOUS: ",
         "Git worktree detection returned exit 128 with unexpected output: ", stderr_text, ". ",
         "Refusing to write restricted data without verified outside-worktree status.")
  }

  # Case 3: git succeeds (exit 0) and says "false" → inside .git dir
  if (is.null(exit_status) && output_text == "false") {
    fail("FAIL_CLOSED_RESTRICTED_OUTPUT_INSIDE_GIT_DIR: ",
         "Destination resolves inside a Git directory structure.")
  }

  # Case 4: Any other exit status or unexpected output → fail closed
  fail("FAIL_CLOSED_GIT_DETECTION_UNEXPECTED: ",
       "Git worktree detection returned unexpected result (exit=",
       if (is.null(exit_status)) "0" else as.character(exit_status),
       ", output='", output_text, "'). ",
       "Refusing to write restricted data without verified outside-worktree status.")
}

# ======================================================================
# publish_restricted_ledger(data_df, ledger_path, chmod_fn, pre_publish_hook)
# Actual production atomic publication path for restricted ledger outputs.
#   - Validates target directory is outside any Git worktree
#   - Ensures directory exists with return-value checking
#   - Writes temporary file and explicitly sets restrictive mode 0600 BEFORE publication
#   - Checks unambiguous TRUE return from temporary chmod and exact 0600 mode
#   - Optional pre_publish_hook to observe real temporary file in tests
#   - Checks SHA-256 for collision:
#       - Absent: atomic file.rename() to ledger_path, verify unambiguous TRUE return from final chmod and exact 0600 mode
#       - Identical: idempotent success WITHOUT renaming or modifying destination
#       - Different: fail closed without overwriting destination
#   - Fail-safe cleanup on error without leaving improperly permitted files
# ======================================================================
publish_restricted_ledger <- function(data_df, ledger_path, chmod_fn = Sys.chmod, pre_publish_hook = NULL) {
  target_dir <- dirname(ledger_path)
  assert_outside_worktree(target_dir)

  if (!dir.exists(target_dir)) {
    dir_res <- dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
    if (!dir.exists(target_dir)) {
      fail("FAIL_CLOSED_DIR_CREATE_FAILED: Failed to create target directory ", target_dir)
    }
  }

  ledger_tmp <- tempfile(pattern = "ledger_", tmpdir = target_dir, fileext = ".tmp")

  # On-exit cleanup: ensure temp file is removed if it still exists (e.g. on error)
  # IMPORTANT: Never remove ledger_path!
  on.exit({
    if (file.exists(ledger_tmp)) {
      unlink(ledger_tmp)
    }
  }, add = TRUE)

  # Write data to temporary file
  write_err <- tryCatch({
    utils::write.csv(data_df, ledger_tmp, row.names = FALSE, na = "")
    NULL
  }, error = function(e) e)

  if (!is.null(write_err) || !file.exists(ledger_tmp)) {
    fail("FAIL_CLOSED_TEMP_WRITE_FAILED: ", if (is.null(write_err)) "Temp file not created" else conditionMessage(write_err))
  }

  # Set mode 0600 on temporary file BEFORE final publication — require unambiguous TRUE
  chmod_tmp_res <- suppressWarnings(chmod_fn(ledger_tmp, mode = "0600"))
  if (!isTRUE(chmod_tmp_res) || !is_exact_mode_0600(ledger_tmp)) {
    fail("FAIL_CLOSED_CHMOD_FAILED: Failed to set exact 0600 mode on temporary restricted file (got ", get_octal_mode_str(ledger_tmp), ").")
  }

  temp_mode_octal <- get_octal_mode_str(ledger_tmp)

  # Run pre-publication hook if provided (e.g. synthetic test observing real temp file on disk)
  if (is.function(pre_publish_hook)) {
    pre_publish_hook(ledger_tmp)
  }

  candidate_sha <- sha256_file(ledger_tmp)

  # Collision / Idempotency Gate
  if (file.exists(ledger_path)) {
    existing_sha <- sha256_file(ledger_path)
    if (identical(existing_sha, candidate_sha)) {
      # Idempotent match: clean up temp file and return IDEMPOTENT status
      # Crucial: DO NOT call file.rename() over existing file!
      unlink(ledger_tmp)
      existing_mode <- get_octal_mode_str(ledger_path)
      return(list(
        status = "IDEMPOTENT",
        sha256 = candidate_sha,
        path = ledger_path,
        file_bytes = file.info(ledger_path)$size,
        renamed = FALSE,
        temp_mode = temp_mode_octal,
        final_mode = existing_mode
      ))
    } else {
      # Different content: fail closed before any mutation
      unlink(ledger_tmp)
      fail("FAIL_CLOSED_LEDGER_COLLISION: Destination ledger already exists with different content. ",
           "Existing SHA-256: ", existing_sha, " vs candidate SHA-256: ", candidate_sha, ". ",
           "Refusing to silently overwrite restricted participant-level data.")
    }
  }

  # Test hook: check if forced rename failure is requested
  if (Sys.getenv("MOCK_RENAME_FAILURE", unset = "") == "1") {
    unlink(ledger_tmp)
    fail("FAIL_CLOSED_RENAME_FAILED: Forced final publication rename failure simulation.")
  }

  # Destination absent: proceed with atomic rename
  rename_res <- suppressWarnings(file.rename(ledger_tmp, ledger_path))
  if (!isTRUE(rename_res) || !file.exists(ledger_path)) {
    unlink(ledger_tmp)
    fail("FAIL_CLOSED_RENAME_FAILED: Could not rename temporary file to destination ", ledger_path)
  }

  # Re-apply mode 0600 to published file and explicitly check unambiguous TRUE result
  chmod_final_res <- suppressWarnings(chmod_fn(ledger_path, mode = "0600"))

  if (!isTRUE(chmod_final_res) || !is_exact_mode_0600(ledger_path)) {
    last_mode <- get_octal_mode_str(ledger_path)
    unlink(ledger_path)
    fail("FAIL_CLOSED_CHMOD_FAILED: Published ledger mode is ", last_mode, ", expected exact 0600.")
  }

  final_mode_octal <- get_octal_mode_str(ledger_path)

  return(list(
    status = "CREATED",
    sha256 = candidate_sha,
    path = ledger_path,
    file_bytes = file.info(ledger_path)$size,
    renamed = TRUE,
    temp_mode = temp_mode_octal,
    final_mode = final_mode_octal
  ))
}
