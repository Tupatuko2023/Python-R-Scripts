#!/usr/bin/env Rscript

# Synthetic tests for cohort_implementation.R output routing, security helpers,
# and real publication pipeline.
#
# IMPORTANT: These tests source the LIVE production helper module
# (cohort_security_helpers.R) and test the actual publication function
# (publish_restricted_ledger). They use only synthetic/non-sensitive data.

cat("=== cohort_implementation output-routing & security tests ===\n\n")

test_pass <- 0L
test_fail <- 0L
test_skip <- 0L
mandatory_skip <- 0L

security_suite_succeeds <- function(fail_count, mandatory_skip_count) fail_count == 0L && mandatory_skip_count == 0L

assert_test <- function(label, condition) {
  if (isTRUE(condition)) {
    cat("  PASS:", label, "\n")
    test_pass <<- test_pass + 1L
  } else {
    cat("  FAIL:", label, "\n")
    test_fail <<- test_fail + 1L
  }
}

skip_test <- function(label, reason, mandatory = FALSE) {
  cat("  SKIP:", label, "(", reason, ")\n")
  test_skip <<- test_skip + 1L
  if (isTRUE(mandatory)) mandatory_skip <<- mandatory_skip + 1L
}

# --- Locate production code ---
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
if (length(file_arg) != 1L) stop("Run with Rscript --file=...", call. = FALSE)
test_dir <- dirname(normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE))
impl_dir <- normalizePath(file.path(test_dir, ".."), mustWork = TRUE)
impl_path <- file.path(impl_dir, "cohort_implementation.R")
helpers_path <- file.path(impl_dir, "cohort_security_helpers.R")
if (!file.exists(impl_path)) stop("Cannot find cohort_implementation.R at: ", impl_path, call. = FALSE)
if (!file.exists(helpers_path)) stop("Cannot find cohort_security_helpers.R at: ", helpers_path, call. = FALSE)

# --- Source the LIVE production security helpers ---
fail <- function(...) stop(paste0(...), call. = FALSE)
source(helpers_path, local = FALSE)

# --- Shared temp directory for all tests ---
test_tmp <- tempfile("cohort_security_test_")
dir.create(test_tmp, showWarnings = FALSE, recursive = TRUE)
on.exit(unlink(test_tmp, recursive = TRUE), add = TRUE)

# ====================================================================
# TEST GROUP 1: DATA_ROOT resolution
# ====================================================================
cat("Test group 1: DATA_ROOT resolution\n")

fake_env <- file.path(test_tmp, ".env")
fake_data_root <- file.path(test_tmp, "fake_data_root")
dir.create(fake_data_root, showWarnings = FALSE)

writeLines(c(
  paste0('export DATA_ROOT="', fake_data_root, '"'),
  'export AUTH_SOURCE="/some/path"'
), fake_env)

# 1a: Resolution from .env file when DATA_ROOT env var is unset
old_data_root <- Sys.getenv("DATA_ROOT", unset = "")
Sys.unsetenv("DATA_ROOT")
resolved <- tryCatch(resolve_data_root(fake_env), error = function(e) NULL)
assert_test("DATA_ROOT resolves from .env file",
            !is.null(resolved) && grepl("fake_data_root", resolved))

# 1b: Process env takes precedence
Sys.setenv(DATA_ROOT = fake_data_root)
resolved2 <- tryCatch(resolve_data_root(fake_env), error = function(e) NULL)
assert_test("DATA_ROOT from process env takes precedence",
            !is.null(resolved2) && grepl("fake_data_root", resolved2))

# 1c: Fail-closed when DATA_ROOT is empty and .env missing
Sys.unsetenv("DATA_ROOT")
failed <- tryCatch({
  resolve_data_root(file.path(test_tmp, "nonexistent_env"))
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_DATA_ROOT_NOT_SET", conditionMessage(e)))
assert_test("Fail-closed when DATA_ROOT unavailable", isTRUE(failed))

# Restore
if (nzchar(old_data_root)) Sys.setenv(DATA_ROOT = old_data_root) else Sys.unsetenv("DATA_ROOT")

# ====================================================================
# TEST GROUP 2: Worktree guard (existing & non-existing dirs)
# ====================================================================
cat("\nTest group 2: Worktree guard (existing & non-existing dirs)\n")

# 2a: Directory inside a Git worktree should trigger fail-closed
repo_dir <- normalizePath(file.path(impl_dir, "..", "..", ".."), mustWork = TRUE)
worktree_fail <- tryCatch({
  assert_outside_worktree(repo_dir)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_RESTRICTED_OUTPUT_INSIDE_WORKTREE", conditionMessage(e)))
assert_test("Fail-closed when target is inside Git worktree", isTRUE(worktree_fail))

# 2b: Directory outside Git worktree should succeed
outside_tmp <- file.path(test_tmp, "outside_worktree")
dir.create(outside_tmp, showWarnings = FALSE, recursive = TRUE)
outside_ok <- tryCatch({
  assert_outside_worktree(outside_tmp)
  TRUE
}, error = function(e) FALSE)
assert_test("Succeeds when target is outside Git worktree", isTRUE(outside_ok))

# 2c: Not-yet-created subdirectory beneath a Git worktree → reject before file creation
nonexistent_in_wt <- file.path(repo_dir, "nonexistent_test_dir_123")
wt_nonexist_fail <- tryCatch({
  assert_outside_worktree(nonexistent_in_wt)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_RESTRICTED_OUTPUT_INSIDE_WORKTREE", conditionMessage(e)))
assert_test("Fail-closed for not-yet-created dir inside worktree", isTRUE(wt_nonexist_fail))

# 2d: Not-yet-created subdirectory outside all worktrees → accept
nonexistent_outside <- file.path(outside_tmp, "sub1", "sub2", "sub3")
outside_nonexist_ok <- tryCatch({
  assert_outside_worktree(nonexistent_outside)
  TRUE
}, error = function(e) FALSE)
assert_test("Succeeds for not-yet-created dir outside worktree", isTRUE(outside_nonexist_ok))

# ====================================================================
# TEST GROUP 3: Ambiguous Git errors & Symlink bypass
# ====================================================================
cat("\nTest group 3: Ambiguous Git errors & Symlink bypass\n")

# 3a: Mock Git exit status 128 with non-standard message → FAIL_CLOSED_GIT_DETECTION_AMBIGUOUS
Sys.setenv(MOCK_GIT_DETECTION_RESULT = "ERROR_128_UNKNOWN")
git_ambiguous_fail <- tryCatch({
  assert_outside_worktree(outside_tmp)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_GIT_DETECTION_AMBIGUOUS", conditionMessage(e)))
assert_test("Fail-closed on exit 128 with unexpected Git stderr", isTRUE(git_ambiguous_fail))

# 3b: Mock Git exit status 1 → FAIL_CLOSED_GIT_DETECTION_UNEXPECTED
Sys.setenv(MOCK_GIT_DETECTION_RESULT = "ERROR_1_FAIL")
git_unexpected_fail <- tryCatch({
  assert_outside_worktree(outside_tmp)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_GIT_DETECTION_UNEXPECTED", conditionMessage(e)))
assert_test("Fail-closed on exit status 1", isTRUE(git_unexpected_fail))

# 3c: Mock Git unexpected stdout → FAIL_CLOSED_GIT_DETECTION_UNEXPECTED
Sys.setenv(MOCK_GIT_DETECTION_RESULT = "UNEXPECTED_STDOUT")
git_stdout_fail <- tryCatch({
  assert_outside_worktree(outside_tmp)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_GIT_DETECTION_UNEXPECTED", conditionMessage(e)))
assert_test("Fail-closed on unexpected Git stdout", isTRUE(git_stdout_fail))

Sys.unsetenv("MOCK_GIT_DETECTION_RESULT")

# 3d: Symlink bypass test — symlink in temp dir pointing to in-worktree repo_dir
symlink_dir <- file.path(outside_tmp, "symlink_to_worktree")
symlink_created <- suppressWarnings(file.symlink(repo_dir, symlink_dir))
if (isTRUE(symlink_created) || dir.exists(symlink_dir)) {
  symlink_rejected <- tryCatch({
    assert_outside_worktree(symlink_dir)
    FALSE
  }, error = function(e) grepl("FAIL_CLOSED_RESTRICTED_OUTPUT_INSIDE_WORKTREE", conditionMessage(e)))
  assert_test("Symlink pointing into Git worktree is rejected", isTRUE(symlink_rejected))
  unlink(symlink_dir)
} else {
  skip_test("Symlink pointing into Git worktree is rejected", "file.symlink not supported on this host environment", mandatory = TRUE)
}

# ====================================================================
# TEST GROUP 4: Permission Bitwise Helpers & Exact 0600 Validation
# ====================================================================
cat("\nTest group 4: Exact 0600 Bitwise Mode Validation\n")

mode_test_0600 <- file.path(test_tmp, "mode_0600.txt")
mode_test_0400 <- file.path(test_tmp, "mode_0400.txt")
writeLines("test", mode_test_0600)
writeLines("test", mode_test_0400)

Sys.chmod(mode_test_0600, mode = "0600")
Sys.chmod(mode_test_0400, mode = "0400")

assert_test("is_exact_mode_0600 accepts exact 0600 file", is_exact_mode_0600(mode_test_0600))
assert_test("is_exact_mode_0600 rejects 0400 file", !is_exact_mode_0600(mode_test_0400))

# ====================================================================
# TEST GROUP 5: Real Producer Finalization Path & Permissions
# ====================================================================
cat("\nTest group 5: Real Producer Finalization Path & Permissions\n")

synth_df <- data.frame(
  ID = c("SYNTH01", "SYNTH02"),
  AGE = c(70L, 82L),
  FOF = c(1L, 0L),
  stringsAsFactors = FALSE
)

ext_pub_dir <- file.path(outside_tmp, "derived_pub_test")
ext_ledger_path <- file.path(ext_pub_dir, "cohort_ledger.csv")

# 5a: Observe real temporary file permissions ON DISK before publication
temp_file_observed_0600 <- FALSE
hook_observed_temp <- function(tmp_path) {
  if (file.exists(tmp_path) && is_exact_mode_0600(tmp_path)) {
    temp_file_observed_0600 <<- TRUE
  }
}

res_absent <- tryCatch({
  publish_restricted_ledger(synth_df, ext_ledger_path, pre_publish_hook = hook_observed_temp)
}, error = function(e) e)

assert_test("Absent destination: publication succeeds",
            is.list(res_absent) && identical(res_absent$status, "CREATED") && file.exists(ext_ledger_path))

assert_test("Temporary restricted file observed on disk with exact 0600 mode before rename",
            isTRUE(temp_file_observed_0600))

if (is.list(res_absent)) {
  # Verify published file has exact 0600 permissions
  assert_test("Published ledger on disk has exact 0600 mode",
              is_exact_mode_0600(ext_ledger_path) && identical(res_absent$final_mode, "0600"))

  # Verify no temp files leftover
  tmp_leftovers <- list.files(ext_pub_dir, pattern = "\\.tmp$", full.names = TRUE)
  assert_test("No temporary files left in target directory", length(tmp_leftovers) == 0L)
}

# 5b: Rejection of non-0600 final mode (0400 on actual disk) with pre-cleanup observation
new_ledger_0400_path <- file.path(ext_pub_dir, "test_0400_ledger.csv")
observed_on_disk_mode_0400 <- NULL

chmod_set_0400 <- function(path, mode) {
  if (endsWith(path, ".tmp")) {
    Sys.chmod(path, mode = mode)
  } else {
    Sys.chmod(path, mode = "0400")
    # Independently record actual mode on disk right after setting it, before publication rejection & cleanup
    st <- suppressWarnings(file.info(path))
    if (!is.null(st$mode) && !is.na(st$mode)) {
      observed_on_disk_mode_0400 <<- sprintf("%04o", bitwAnd(as.integer(st$mode), 511L))
    }
    TRUE
  }
}

mode_0400_fail <- tryCatch({
  publish_restricted_ledger(synth_df, new_ledger_0400_path, chmod_fn = chmod_set_0400)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_CHMOD_FAILED", conditionMessage(e)))

assert_test("Canonical 0400 test independently observed actual on-disk mode 0400 before cleanup",
            identical(observed_on_disk_mode_0400, "0400"))
assert_test("Non-0600 final mode (0400 on disk) is explicitly rejected", isTRUE(mode_0400_fail))
assert_test("File with rejected 0400 mode is unlinked and not published", !file.exists(new_ledger_0400_path))

# ====================================================================
# TEST GROUP 6: Explicit Control Matrix for Temporary & Final chmod Returns
# ====================================================================
cat("\nTest group 6: Chmod Return Control Matrix (TRUE, FALSE, NA)\n")

# 6a: Temp chmod TRUE -> succeeds
t_path_true <- file.path(ext_pub_dir, "t_chmod_true.csv")
res_t_true <- tryCatch({
  publish_restricted_ledger(synth_df, t_path_true, chmod_fn = function(path, mode) Sys.chmod(path, mode))
}, error = function(e) e)
assert_test("Temp chmod TRUE: succeeds and produces CREATED status", is.list(res_t_true) && identical(res_t_true$status, "CREATED"))
unlink(t_path_true)

# 6b: Temp chmod FALSE -> fails closed
t_path_false <- file.path(ext_pub_dir, "t_chmod_false.csv")
err_t_false <- tryCatch({
  publish_restricted_ledger(synth_df, t_path_false, chmod_fn = function(path, mode) {
    if (endsWith(path, ".tmp")) FALSE else Sys.chmod(path, mode)
  })
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_CHMOD_FAILED", conditionMessage(e)))
assert_test("Temp chmod FALSE: fails closed", isTRUE(err_t_false))
assert_test("Temp chmod FALSE: target file not published", !file.exists(t_path_false))

# 6c: Temp chmod NA -> fails closed
t_path_na <- file.path(ext_pub_dir, "t_chmod_na.csv")
err_t_na <- tryCatch({
  publish_restricted_ledger(synth_df, t_path_na, chmod_fn = function(path, mode) {
    if (endsWith(path, ".tmp")) NA else Sys.chmod(path, mode)
  })
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_CHMOD_FAILED", conditionMessage(e)))
assert_test("Temp chmod NA: fails closed", isTRUE(err_t_na))
assert_test("Temp chmod NA: target file not published", !file.exists(t_path_na))

# 6d: Final chmod TRUE -> succeeds
f_path_true <- file.path(ext_pub_dir, "f_chmod_true.csv")
res_f_true <- tryCatch({
  publish_restricted_ledger(synth_df, f_path_true, chmod_fn = function(path, mode) Sys.chmod(path, mode))
}, error = function(e) e)
assert_test("Final chmod TRUE: succeeds and produces CREATED status", is.list(res_f_true) && identical(res_f_true$status, "CREATED"))
unlink(f_path_true)

# 6e: Final chmod FALSE -> fails closed
f_path_false <- file.path(ext_pub_dir, "f_chmod_false.csv")
err_f_false <- tryCatch({
  publish_restricted_ledger(synth_df, f_path_false, chmod_fn = function(path, mode) {
    if (endsWith(path, ".tmp")) Sys.chmod(path, mode) else FALSE
  })
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_CHMOD_FAILED", conditionMessage(e)))
assert_test("Final chmod FALSE: fails closed", isTRUE(err_f_false))
assert_test("Final chmod FALSE: target file unlinked and not published", !file.exists(f_path_false))

# 6f: Final chmod NA -> fails closed
f_path_na <- file.path(ext_pub_dir, "f_chmod_na.csv")
err_f_na <- tryCatch({
  publish_restricted_ledger(synth_df, f_path_na, chmod_fn = function(path, mode) {
    if (endsWith(path, ".tmp")) Sys.chmod(path, mode) else NA
  })
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_CHMOD_FAILED", conditionMessage(e)))
assert_test("Final chmod NA: fails closed", isTRUE(err_f_na))
assert_test("Final chmod NA: target file unlinked and not published", !file.exists(f_path_na))

# ====================================================================
# TEST GROUP 7: Collision & Failure Safety
# ====================================================================
cat("\nTest group 7: Collision & Failure Safety\n")

# 7a: Synthetic byte-identical existing destination -> idempotent without rename or timestamp change
mtime_before <- file.info(ext_ledger_path)$mtime
Sys.sleep(1) # Ensure time tick if mtime were to change

res_identical <- tryCatch({
  publish_restricted_ledger(synth_df, ext_ledger_path)
}, error = function(e) e)

mtime_after <- file.info(ext_ledger_path)$mtime

assert_test("Identical destination: returns IDEMPOTENT status",
            is.list(res_identical) && identical(res_identical$status, "IDEMPOTENT"))
assert_test("Identical destination: did NOT execute replacing file.rename()",
            is.list(res_identical) && isFALSE(res_identical$renamed))
assert_test("Identical destination: file mtime untouched",
            identical(mtime_before, mtime_after))

# 7b: Synthetic different existing destination -> fail closed, destination unchanged
different_df <- data.frame(
  ID = c("DIFFERENT_PERSON"),
  AGE = c(99L),
  FOF = c(0L),
  stringsAsFactors = FALSE
)
content_sha_before <- sha256_file(ext_ledger_path)

collision_error <- tryCatch({
  publish_restricted_ledger(different_df, ext_ledger_path)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_LEDGER_COLLISION", conditionMessage(e)))

content_sha_after <- sha256_file(ext_ledger_path)

assert_test("Different destination: fail-closed with LEDGER_COLLISION error", isTRUE(collision_error))
assert_test("Different destination: existing ledger content unchanged", identical(content_sha_before, content_sha_after))

# 7c: Forced final-publication (rename) failure -> fail closed, no false receipt
Sys.setenv(MOCK_RENAME_FAILURE = "1")
new_ledger_path <- file.path(ext_pub_dir, "new_uncreated_ledger.csv")

rename_fail_err <- tryCatch({
  publish_restricted_ledger(synth_df, new_ledger_path)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_RENAME_FAILED", conditionMessage(e)))

assert_test("Forced rename failure: detected and fails closed", isTRUE(rename_fail_err))
assert_test("Forced rename failure: file not published", !file.exists(new_ledger_path))

Sys.unsetenv("MOCK_RENAME_FAILURE")

# 7d: Byte-identical destinations with unsafe or unreadable modes fail closed
for (unsafe_mode in c("0400", "0644")) {
  mode_path <- file.path(ext_pub_dir, paste0("identical_mode_", unsafe_mode, ".csv"))
  utils::write.csv(synth_df, mode_path, row.names = FALSE, na = "")
  fixture_chmod <- system2("chmod", c(unsafe_mode, shQuote(mode_path)),
                           stdout = FALSE, stderr = FALSE)
  if (!identical(fixture_chmod, 0L)) stop("Failed to prepare unsafe-mode fixture", call. = FALSE)
  sha_before <- sha256_file(mode_path)
  mode_before <- get_octal_mode_str(mode_path)
  mode_error <- tryCatch({
    publish_restricted_ledger(synth_df, mode_path)
    FALSE
  }, error = function(e) grepl("FAIL_CLOSED_EXISTING_LEDGER_MODE", conditionMessage(e)))
  assert_test(paste0("Identical destination mode ", unsafe_mode, ": fails closed"), isTRUE(mode_error))
  assert_test(paste0("Identical destination mode ", unsafe_mode, ": destination unchanged"),
              identical(sha_before, sha256_file(mode_path)) && identical(mode_before, get_octal_mode_str(mode_path)))
}

inspection_path <- file.path(ext_pub_dir, "identical_mode_unknown.csv")
utils::write.csv(synth_df, inspection_path, row.names = FALSE, na = "")
Sys.chmod(inspection_path, mode = "0600")
inspection_sha <- sha256_file(inspection_path)
real_file_info <- file.info
file.info <- function(...) {
  info <- real_file_info(...)
  requested <- as.character(list(...)[[1L]])
  if (length(requested) == 1L && identical(requested, inspection_path)) info$mode <- NA
  info
}
inspection_error <- tryCatch({
  publish_restricted_ledger(synth_df, inspection_path)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_EXISTING_LEDGER_MODE", conditionMessage(e)))
file.info <- real_file_info
assert_test("Identical destination mode inspection failure: fails closed", isTRUE(inspection_error))
assert_test("Identical destination mode inspection failure: content unchanged",
            identical(inspection_sha, sha256_file(inspection_path)))

# 7e: Mandatory security skips produce a non-success disposition
assert_test("Mandatory SKIP makes security suite non-success",
            !security_suite_succeeds(0L, 1L))
assert_test("PASS/FAIL/SKIP dispositions remain independent",
            security_suite_succeeds(0L, 0L) && !security_suite_succeeds(1L, 0L))

# 7f: Atomic directory acquisition, contention, ownership, and cleanup
lock_atomic_results <- vapply(seq_len(25L), function(i) {
  atomic_path <- file.path(ext_pub_dir, paste0("atomic_", i, ".lock"))
  jobs <- lapply(seq_len(6L), function(j) {
    parallel::mcparallel(dir.create(atomic_path, mode = "0700", showWarnings = FALSE),
                         mc.set.seed = FALSE)
  })
  acquired <- unlist(parallel::mccollect(jobs), use.names = FALSE)
  valid <- sum(acquired) == 1L && is_exact_mode_0700(atomic_path)
  unlink(atomic_path, recursive = TRUE)
  valid
}, logical(1L))
assert_test("Atomic lock acquisition: exactly one winner in 25 contention rounds",
            all(lock_atomic_results))

contention_path <- file.path(ext_pub_dir, "lock_contention.csv")
held_lock <- acquire_restricted_lock(paste0(contention_path, ".lock"))
held_token <- readLines(held_lock$token_path, warn = FALSE)
assert_test("Held lock: directory is 0700 and owner token is 0600",
            is_exact_mode_0700(held_lock$path) && is_exact_mode_0600(held_lock$token_path) &&
              length(list.files(held_lock$path, all.files = TRUE, no.. = TRUE)) == 1L)
contention_error <- tryCatch({
  publish_restricted_ledger(synth_df, contention_path, lock_timeout_seconds = 0.05)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_LEDGER_LOCK_CONTENDED", conditionMessage(e)))
assert_test("Held lock: competing publisher fails closed after bounded wait", isTRUE(contention_error))
assert_test("Held lock: contender neither removes nor changes owner state",
            dir.exists(held_lock$path) && identical(readLines(held_lock$token_path, warn = FALSE), held_token))
wrong_owner <- held_lock
wrong_owner$token <- "not-the-owner"
ownership_error <- tryCatch({
  release_restricted_lock(wrong_owner)
  FALSE
}, error = function(e) grepl("FAIL_CLOSED_LOCK_OWNERSHIP", conditionMessage(e)))
assert_test("Lock cleanup: wrong owner cannot remove lock", isTRUE(ownership_error) && dir.exists(held_lock$path))
release_restricted_lock(held_lock)
assert_test("Lock cleanup: verified owner removes lock and token", !dir.exists(held_lock$path))

# 7g: Real concurrent publishers exercise the production critical section
run_concurrent_publishers <- function(data_frames, ledger_path, label) {
  barrier_dir <- file.path(ext_pub_dir, paste0("barrier_", label))
  dir.create(barrier_dir, recursive = TRUE, showWarnings = FALSE)
  barrier_hook <- function(path) {
    marker <- file.path(barrier_dir, paste0("ready_", Sys.getpid()))
    if (!isTRUE(file.create(marker))) stop("concurrency barrier marker failed", call. = FALSE)
    deadline <- Sys.time() + 10
    while (length(list.files(barrier_dir, pattern = "^ready_")) < length(data_frames)) {
      if (Sys.time() > deadline) stop("concurrency barrier timed out", call. = FALSE)
      Sys.sleep(0.01)
    }
  }
  jobs <- lapply(data_frames, function(candidate) {
    parallel::mcparallel(tryCatch(
      publish_restricted_ledger(candidate, ledger_path, pre_publish_hook = barrier_hook),
      error = function(e) list(status = "ERROR", message = conditionMessage(e))
    ), mc.set.seed = FALSE)
  })
  unname(parallel::mccollect(jobs))
}

candidate_hash <- function(candidate) {
  candidate_path <- tempfile(tmpdir = ext_pub_dir, fileext = ".csv")
  on.exit(unlink(candidate_path), add = TRUE)
  utils::write.csv(candidate, candidate_path, row.names = FALSE, na = "")
  sha256_file(candidate_path)
}
expected_hashes <- vapply(list(synth_df, different_df), candidate_hash, character(1L))
identical_rounds <- logical(10L)
different_rounds <- logical(10L)
artifact_rounds <- logical(10L)
for (race_round in seq_len(10L)) {
  identical_path <- file.path(ext_pub_dir, paste0("concurrent_identical_", race_round, ".csv"))
  identical_results <- run_concurrent_publishers(
    list(synth_df, synth_df), identical_path, paste0("identical_", race_round)
  )
  identical_statuses <- vapply(identical_results, function(x) x$status, character(1L))
  identical_rounds[race_round] <-
    identical(sort(identical_statuses), c("CREATED", "IDEMPOTENT")) &&
    identical(sha256_file(identical_path), expected_hashes[[1L]]) &&
    is_exact_mode_0600(identical_path)

  different_path <- file.path(ext_pub_dir, paste0("concurrent_different_", race_round, ".csv"))
  different_results <- run_concurrent_publishers(
    list(synth_df, different_df), different_path, paste0("different_", race_round)
  )
  different_statuses <- vapply(different_results, function(x) x$status, character(1L))
  different_messages <- vapply(different_results, function(x) {
    if (is.null(x$message)) "" else x$message
  }, character(1L))
  different_rounds[race_round] <-
    sum(different_statuses == "CREATED") == 1L &&
    sum(grepl("FAIL_CLOSED_LEDGER_COLLISION", different_messages)) == 1L &&
    sha256_file(different_path) %in% expected_hashes &&
    is_exact_mode_0600(different_path)

  artifact_rounds[race_round] <-
    length(list.files(ext_pub_dir, pattern = "(\\.tmp$|\\.lock$)", full.names = TRUE)) == 0L
}
assert_test("Concurrent identical candidates: 10 rounds yield CREATED plus IDEMPOTENT", all(identical_rounds))
assert_test("Concurrent different candidates: 10 rounds preserve winner and fail loser closed", all(different_rounds))
assert_test("Concurrent publication: no temporary or lock artifacts remain", all(artifact_rounds))

# ====================================================================
# TEST GROUP 8: Producer source integrity (no scientific logic change)
# ====================================================================
cat("\nTest group 8: Producer integrity & scientific constants\n")

impl_lines <- readLines(impl_path, warn = FALSE)

assert_test("cohort_implementation.R exists", file.exists(impl_path))
assert_test("eligible_rows = 440L present",
            any(grepl("eligible_rows\\s*=\\s*440L", impl_lines)))
assert_test("eligible_persons = 433L present",
            any(grepl("eligible_persons\\s*=\\s*433L", impl_lines)))
assert_test("adjudicated_discards = 3L present",
            any(grepl("adjudicated_discards\\s*=\\s*3L", impl_lines)))
assert_test("Producer calls publish_restricted_ledger()",
            any(grepl("publish_restricted_ledger", impl_lines)))
assert_test("Producer sources shared helper module",
            any(grepl("source.*cohort_security_helpers", impl_lines)))

# ====================================================================
# TEST GROUP 9: Verify no authentic cohort ledger in checkout
# ====================================================================
cat("\nTest group 9: No restricted data in checkout\n")

ledger_paths <- c(
  file.path(repo_dir, "reanalysis", "R", "cohort_implementation", "outputs", "cohort_ledger.csv"),
  file.path(repo_dir, "data", "COHORT_LEDGER.csv")
)
for (lp in ledger_paths) {
  assert_test(paste0("No restricted ledger at: ", basename(dirname(lp)), "/", basename(lp)),
              !file.exists(lp))
}

# ====================================================================
# SUMMARY
# ====================================================================
cat("\n=== RESULTS ===\n")
cat("PASS:", test_pass, "\n")
cat("FAIL:", test_fail, "\n")
cat("SKIP:", test_skip, "\n")

if (!security_suite_succeeds(test_fail, mandatory_skip)) {
  stop("Security suite unsuccessful: failures=", test_fail,
       ", mandatory_skips=", mandatory_skip, call. = FALSE)
} else {
  cat("All mandatory security tests passed successfully.\n")
}
