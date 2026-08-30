#!/usr/bin/env Rscript

# RGR1 P0 clean-room cohort implementation.
# Scientific rules are bound to the approved governance artifacts below.

suppressPackageStartupMessages(library(readxl))

approved <- list(
  source = "6616fae649aaa74e5454d858f45d5b2402d04e2a47de2f3096eb0dcbff7fc15e",
  linkage = "542ddfd0bc4ae8503b0ce1bc9c4ff53dba2ecbc982045b9e88a602436c1f08f9",
  variable_map = "1df2450fd039459c4dc382849fbc66267556306e0e376a7c5635c6c6aa097cf1",
  cohort_rules = "35337879e7befeaf3cd71d491b898145df26175bef9c6357b97bbaf71550e57d",
  adjudication_receipt = "b0743278b8f78546572f3eb72556cbecbaa56cb801bf01f37ae77a1ac1a7252e"
)

reviewed <- c(
  physical_rows = 630L,
  substantive_rows = 541L,
  template_rows = 89L,
  source_persons = 527L,
  repeated_row_excess = 14L,
  adjudicated_discards = 3L,
  post_adjudication_rows = 538L,
  excluded_rows = 98L,
  eligible_rows = 440L,
  eligible_persons = 433L
)

fail <- function(...) stop(paste0(...), call. = FALSE)

assert_equal <- function(actual, expected, label) {
  if (length(actual) != 1L || is.na(actual) || !identical(as.integer(actual), as.integer(expected))) {
    fail("FAIL_CLOSED_", toupper(label), ": expected ", expected, ", observed ", actual)
  }
}

sha256_file <- function(path) {
  if (!file.exists(path)) fail("FAIL_CLOSED_MISSING_ARTIFACT: ", basename(path))
  out <- system2("sha256sum", shQuote(normalizePath(path)), stdout = TRUE, stderr = TRUE)
  if (!identical(attr(out, "status"), NULL) || length(out) != 1L) {
    fail("FAIL_CLOSED_SHA256_UNAVAILABLE: ", basename(path))
  }
  sub("[[:space:]].*$", "", out)
}

assert_hash <- function(path, expected, label) {
  observed <- sha256_file(path)
  if (!identical(observed, expected)) {
    fail("FAIL_CLOSED_", label, "_HASH_MISMATCH: expected ", expected, ", observed ", observed)
  }
  observed
}

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

normalize_header <- function(x) {
  out <- tolower(trimws(as.character(x)))
  out <- gsub("[\r\n\t]+", " ", out)
  out <- gsub("[[:space:]]+", " ", out)
  gsub("[^[:alnum:]]+", "", out)
}

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
if (length(file_arg) != 1L) fail("FAIL_CLOSED_SCRIPT_IDENTITY_UNAVAILABLE")
script_path <- normalizePath(sub("^--file=", "", file_arg), mustWork = TRUE)
script_dir <- dirname(script_path)
project_root <- normalizePath(file.path(script_dir, "..", "..", ".."), mustWork = TRUE)
repo_root <- normalizePath(file.path(project_root, ".."), mustWork = TRUE)

# --- Security helpers: DATA_ROOT, worktree guard, collision gate ---
source(file.path(script_dir, "cohort_security_helpers.R"), local = FALSE)

env_path <- file.path(project_root, "config", ".env")
data_root <- resolve_data_root(env_path)
restricted_output_dir <- file.path(data_root, "derived")
assert_outside_worktree(restricted_output_dir)

paths <- list(
  env = env_path,
  linkage = file.path(project_root, "rgr1-state", "WP-RGR1-WP0-IDENTITY-LINKAGE-001.md"),
  variable_map = file.path(repo_root, "GPT", "Reanalysis Governance Reviewer (RGR1)", "knowledge", "VARIABLE_MAP.yml"),
  cohort_rules = file.path(repo_root, "GPT", "Reanalysis Governance Reviewer (RGR1)", "knowledge", "COHORT_RULES.yml"),
  adjudication_receipt = file.path(project_root, "rgr1-state", "WP-RGR1-WP0-COHORT-RULES-001-P0-CONFLICT-RUN-RECEIPT.md"),
  outputs = file.path(script_dir, "outputs"),
  restricted_outputs = restricted_output_dir
)

source_path <- read_env_value(paths$env, "AUTH_SOURCE")
if (!file.exists(source_path)) fail("FAIL_CLOSED_AUTH_SOURCE_MISSING")
source_hash <- assert_hash(source_path, approved$source, "AUTH_SOURCE")
linkage_hash <- assert_hash(paths$linkage, approved$linkage, "LINKAGE")
variable_map_hash <- assert_hash(paths$variable_map, approved$variable_map, "VARIABLE_MAP")
cohort_rules_hash <- assert_hash(paths$cohort_rules, approved$cohort_rules, "COHORT_RULES")
receipt_hash <- assert_hash(paths$adjudication_receipt, approved$adjudication_receipt, "ADJUDICATION_RECEIPT")
code_hash <- sha256_file(script_path)

id_column <- read_env_value(paths$env, "KAAOS_ID_COL")
raw <- readxl::read_excel(source_path, sheet = "Taul1", skip = 1L, .name_repair = "minimal")
assert_equal(nrow(raw), reviewed[["physical_rows"]], "physical_rows")

if (!id_column %in% names(raw)) fail("FAIL_CLOSED_CONFIGURED_ID_COLUMN_MISSING")
row_is_substantive <- !is.na(raw[[id_column]]) & nzchar(trimws(as.character(raw[[id_column]])))
substantive <- raw[row_is_substantive, , drop = FALSE]
assert_equal(nrow(substantive), reviewed[["substantive_rows"]], "substantive_rows")
assert_equal(sum(!row_is_substantive), reviewed[["template_rows"]], "template_rows")

if (!id_column %in% names(substantive)) fail("FAIL_CLOSED_CONFIGURED_ID_COLUMN_MISSING")
if (!"NRO" %in% names(substantive)) fail("FAIL_CLOSED_ADJUDICATION_ROW_COLUMN_MISSING")
if (any(is.na(substantive[[id_column]]) | !nzchar(trimws(as.character(substantive[[id_column]]))))) {
  fail("FAIL_CLOSED_SUBSTANTIVE_SOURCE_KEY_MISSING")
}

headers <- normalize_header(names(substantive))
age_hits <- which(grepl("^ik", headers))
fof_hits <- which(grepl("^kaatumisenpelko0eipelk", headers))
if (length(age_hits) != 1L) fail("FAIL_CLOSED_AGE_COLUMN_AMBIGUOUS")
if (length(fof_hits) != 1L) fail("FAIL_CLOSED_FOF_COLUMN_AMBIGUOUS")
age_column <- names(substantive)[age_hits]
fof_column <- names(substantive)[fof_hits]

source_persons <- length(unique(as.character(substantive[[id_column]])))
assert_equal(source_persons, reviewed[["source_persons"]], "source_persons")
assert_equal(nrow(substantive) - source_persons, reviewed[["repeated_row_excess"]], "repeated_row_excess")

# RGR1-DEC-024 approved these three source-record discards. NRO is a row
# provenance field, not the canonical person key; no protected key is logged.
discard_nro <- c(12L, 336L, 121L)
discard_mask <- substantive$NRO %in% discard_nro
if (!all(vapply(discard_nro, function(x) sum(substantive$NRO == x, na.rm = TRUE), integer(1L)) == 1L)) {
  fail("FAIL_CLOSED_ADJUDICATION_BINDING_CARDINALITY")
}
assert_equal(sum(discard_mask), reviewed[["adjudicated_discards"]], "adjudicated_discards")
adjudicated <- substantive[!discard_mask, , drop = FALSE]
assert_equal(nrow(adjudicated), reviewed[["post_adjudication_rows"]], "post_adjudication_rows")

adjudicated$parsed_age <- suppressWarnings(as.numeric(adjudicated[[age_column]]))
adjudicated$parsed_fof <- suppressWarnings(as.integer(adjudicated[[fof_column]]))

conflict_count <- sum(vapply(
  split(adjudicated, as.character(adjudicated[[id_column]])),
  function(x) {
    age_values <- unique(x$parsed_age[!is.na(x$parsed_age)])
    fof_values <- unique(x$parsed_fof[!is.na(x$parsed_fof)])
    length(age_values) > 1L || length(fof_values) > 1L
  },
  logical(1L)
))
assert_equal(conflict_count, 0L, "unresolved_conflicts")

age_ok <- !is.na(adjudicated$parsed_age) & adjudicated$parsed_age >= 65
fof_ok <- !is.na(adjudicated$parsed_fof) & adjudicated$parsed_fof %in% c(0L, 1L)
eligible_mask <- age_ok & fof_ok
eligible <- adjudicated[eligible_mask, , drop = FALSE]
excluded_rows <- sum(!eligible_mask)
eligible_persons <- length(unique(as.character(eligible[[id_column]])))

assert_equal(excluded_rows, reviewed[["excluded_rows"]], "excluded_rows")
assert_equal(nrow(eligible), reviewed[["eligible_rows"]], "eligible_rows")
assert_equal(eligible_persons, reviewed[["eligible_persons"]], "eligible_persons")
assert_equal(nrow(adjudicated), nrow(eligible) + excluded_rows, "post_adjudication_conservation")

qc <- data.frame(
  metric = c(names(reviewed), "unresolved_conflicts"),
  observed = c(
    nrow(raw), nrow(substantive), sum(!row_is_substantive), source_persons,
    nrow(substantive) - source_persons, sum(discard_mask), nrow(adjudicated),
    excluded_rows, nrow(eligible), eligible_persons, conflict_count
  ),
  status = "PASS",
  stringsAsFactors = FALSE
)

# --- Write aggregate outputs to repo-local outputs/ (safe for Git) ---
dir.create(paths$outputs, recursive = TRUE, showWarnings = FALSE)
qc_path <- file.path(paths$outputs, "cohort_qc.csv")
manifest_path <- file.path(paths$outputs, "run_manifest.txt")
utils::write.csv(qc, qc_path, row.names = FALSE)

# --- Write participant-level ledger to external restricted location ---
ledger_path <- file.path(paths$restricted_outputs, "cohort_ledger.csv")
pub_res <- publish_restricted_ledger(eligible, ledger_path)
ledger_sha <- pub_res$sha256

# --- Write privacy-safe receipt to repo-local outputs/ ---
receipt_lines <- c(
  paste0("timestamp=", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")),
  "artifact=cohort_ledger.csv",
  "classification=PARTICIPANT_LEVEL_RESTRICTED",
  "destination=DATA_ROOT/derived/cohort_ledger.csv",
  paste0("sha256=", ledger_sha),
  paste0("rows=", nrow(eligible)),
  paste0("cols=", ncol(eligible)),
  paste0("file_bytes=", file.info(ledger_path)$size)
)
writeLines(receipt_lines,
           file.path(paths$outputs, "cohort_ledger_output_receipt.txt"),
           useBytes = TRUE)

manifest <- c(
  "status=PASS",
  "source_id=AUTH-SOURCE-001",
  paste0("source_sha256=", source_hash),
  paste0("linkage_sha256=", linkage_hash),
  paste0("variable_map_sha256=", variable_map_hash),
  paste0("cohort_rules_sha256=", cohort_rules_hash),
  paste0("adjudication_receipt_sha256=", receipt_hash),
  paste0("implementation_sha256=", code_hash),
  paste0("ledger_sha256=", ledger_sha),
  paste0("ledger_destination=DATA_ROOT/derived/cohort_ledger.csv"),
  paste0("qc_sha256=", sha256_file(qc_path)),
  paste0("eligible_observations=", nrow(eligible)),
  paste0("eligible_persons=", eligible_persons),
  paste0("unresolved_conflicts=", conflict_count)
)
writeLines(manifest, manifest_path, useBytes = TRUE)

cat("RGR1 P0 clean-room cohort run: PASS\n")
cat("Eligible observations:", nrow(eligible), "\n")
cat("Eligible persons:", eligible_persons, "\n")
cat("Unresolved conflicts:", conflict_count, "\n")
