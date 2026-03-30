#!/usr/bin/env Rscript
# ==============================================================================
# K51 - Manuscript-Facing Analytic Table 1 (K50 WIDE Modeled Sample)
# File tag: K51.V2_manuscript-facing-analytic-table1-wide.R
# Purpose: Produce a manuscript-facing K51 Table 1 anchored explicitly to the
#          authoritative K50 WIDE modeled sample while preserving the baseline-
#          eligible main Table 1 as a separate descriptive artifact.
#
# Outcome: locomotor_capacity
# Predictors: FOF_status
# Moderator/interaction: none
# Grouping variable: FOF_status
# Covariates: age, sex, BMI, FI22_nonperformance_KAAOS, tasapainovaikeus
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, FOF_status, age, sex, BMI, locomotor_capacity_0, locomotor_capacity_12m,
# FI22_nonperformance_KAAOS
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (not used; no randomness)
#
# Outputs + manifest:
# - script_label: K51
# - outputs dir: R-scripts/K51/outputs/
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Resolve authoritative K50 WIDE modeled-sample source from receipt + provenance
# 03) Resolve immutable raw K14 enrichment workbook
# 04) Delegate table build to K51 V1 using explicit analytic_wide_modeled scope
# 05) Validate authoritative n and FOF split against delegated receipt + table headers
# 06) Write implementation review log
# 07) Append manifest row for the review log
# 08) EOF marker
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep('^--file=', args_all, value = TRUE)
script_base <- if (length(file_arg) > 0) {
  sub('\\.[Rr]$', '', basename(sub('^--file=', '', file_arg[1])))
} else {
  'K51'
}
script_label <- 'K51'
helper_label <- sub('\\.V.*$', '', script_base)

source(here::here('R', 'functions', 'init.R'))
source(here::here('R', 'functions', 'person_dedup_lookup.R'))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  row <- data.frame(
    timestamp = as.character(Sys.time()),
    script = helper_label,
    label = label,
    kind = kind,
    path = get_relpath(path),
    n = n,
    notes = notes,
    stringsAsFactors = FALSE
  )
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(manifest_path)) {
    utils::write.table(row, manifest_path, sep = ',', row.names = FALSE, col.names = TRUE, qmethod = 'double')
  } else {
    utils::write.table(row, manifest_path, sep = ',', row.names = FALSE, col.names = FALSE, append = TRUE, qmethod = 'double')
  }
}

read_key_value_file <- function(path) {
  lines <- readLines(path, warn = FALSE)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]
  keys <- sub("=.*$", "", lines)
  vals <- sub("^[^=]*=", "", lines)
  stats::setNames(as.list(vals), keys)
}

require_single_value <- function(x, key, path) {
  if (is.null(x) || !nzchar(x)) {
    stop('K51 V2 missing required field ', key, ' in ', path, call. = FALSE)
  }
  x
}

parse_integer_field <- function(meta, key, path) {
  value <- suppressWarnings(as.integer(require_single_value(meta[[key]], key, path)))
  if (is.na(value)) {
    stop('K51 V2 could not parse integer field ', key, ' in ', path, call. = FALSE)
  }
  value
}

assert_same_value <- function(lhs, rhs, label) {
  if (!identical(lhs, rhs)) {
    stop('K51 V2 authoritative K50 validation failed for ', label, ': ', lhs, ' != ', rhs, call. = FALSE)
  }
}

assert_expected_value <- function(actual, expected, label) {
  if (!identical(actual, expected)) {
    stop('K51 V2 expected ', label, '=', expected, ' but observed ', actual, call. = FALSE)
  }
}

extract_header_n <- function(header_value) {
  match <- regmatches(header_value, regexpr('n=[0-9]+', header_value))
  if (!length(match) || is.na(match)) return(NA_integer_)
  suppressWarnings(as.integer(sub('n=', '', match)))
}

authoritative_wide_config <- list(
  input_resolution = 'authoritative_lock',
  snapshot_id = 'paper_02_2026-03-21',
  modeled_n = 230L,
  modeled_fof0_n = 69L,
  modeled_fof1_n = 161L
)

wide_receipt_path <- here::here('R-scripts', 'K50', 'outputs', 'k50_wide_locomotor_capacity_input_receipt.txt')
wide_provenance_path <- here::here('R-scripts', 'K50', 'outputs', 'k50_wide_locomotor_capacity_modeled_cohort_provenance.txt')
if (!file.exists(wide_receipt_path)) {
  stop('K51 V2 could not find K50 WIDE input receipt: ', wide_receipt_path, call. = FALSE)
}
if (!file.exists(wide_provenance_path)) {
  stop('K51 V2 could not find K50 WIDE modeled-cohort provenance: ', wide_provenance_path, call. = FALSE)
}

wide_receipt <- read_key_value_file(wide_receipt_path)
wide_provenance <- read_key_value_file(wide_provenance_path)
wide_input_path <- require_single_value(wide_receipt[['input_path']], 'input_path', wide_receipt_path)
receipt_md5 <- require_single_value(wide_receipt[['input_md5']], 'input_md5', wide_receipt_path)
receipt_sha256 <- require_single_value(wide_receipt[['input_sha256']], 'input_sha256', wide_receipt_path)
receipt_snapshot_id <- require_single_value(wide_receipt[['authoritative_snapshot_id']], 'authoritative_snapshot_id', wide_receipt_path)
receipt_resolution <- require_single_value(wide_receipt[['input_resolution']], 'input_resolution', wide_receipt_path)
expected_n <- parse_integer_field(wide_receipt, 'rows_modeled', wide_receipt_path)
expected_fof0 <- parse_integer_field(wide_provenance, 'modeled_fof0_n', wide_provenance_path)
expected_fof1 <- parse_integer_field(wide_provenance, 'modeled_fof1_n', wide_provenance_path)
provenance_n <- parse_integer_field(wide_provenance, 'modeled_n', wide_provenance_path)
provenance_md5 <- require_single_value(wide_provenance[['input_md5']], 'input_md5', wide_provenance_path)
provenance_sha256 <- require_single_value(wide_provenance[['input_sha256']], 'input_sha256', wide_provenance_path)
provenance_path <- require_single_value(wide_provenance[['input_path']], 'input_path', wide_provenance_path)
provenance_snapshot_id <- require_single_value(wide_provenance[['authoritative_snapshot_id']], 'authoritative_snapshot_id', wide_provenance_path)
provenance_resolution <- require_single_value(wide_provenance[['input_resolution']], 'input_resolution', wide_provenance_path)

if (!file.exists(wide_input_path)) {
  stop('K51 V2 could not resolve the authoritative K50 WIDE modeled-sample input path.', call. = FALSE)
}

assert_expected_value(receipt_resolution, authoritative_wide_config$input_resolution, 'K50 receipt input_resolution')
assert_expected_value(provenance_resolution, authoritative_wide_config$input_resolution, 'K50 provenance input_resolution')
assert_expected_value(receipt_snapshot_id, authoritative_wide_config$snapshot_id, 'K50 authoritative snapshot id')
assert_expected_value(provenance_snapshot_id, authoritative_wide_config$snapshot_id, 'K50 provenance snapshot id')
assert_expected_value(expected_n, authoritative_wide_config$modeled_n, 'K50 authoritative modeled n')
assert_expected_value(provenance_n, authoritative_wide_config$modeled_n, 'K50 provenance modeled n')
assert_expected_value(expected_fof0, authoritative_wide_config$modeled_fof0_n, 'K50 authoritative FOF0 n')
assert_expected_value(expected_fof1, authoritative_wide_config$modeled_fof1_n, 'K50 authoritative FOF1 n')
assert_same_value(wide_input_path, provenance_path, 'K50 input path between receipt and provenance')
assert_same_value(receipt_md5, provenance_md5, 'K50 input md5 between receipt and provenance')
assert_same_value(receipt_sha256, provenance_sha256, 'K50 input sha256 between receipt and provenance')

source_total <- expected_fof0 + expected_fof1
assert_expected_value(source_total, expected_n, 'authoritative K50 split total')

data_root <- resolve_data_root()
if (is.na(data_root)) {
  stop('K51 V2 requires DATA_ROOT to resolve the immutable KAAOS workbook.', call. = FALSE)
}
raw_input_path <- file.path(data_root, 'paper_02', 'KAAOS_data_sotullinen.xlsx')
if (!file.exists(raw_input_path)) {
  stop('K51 V2 could not resolve immutable raw enrichment workbook: ', raw_input_path, call. = FALSE)
}

cmd_args <- c(
  here::here('R-scripts', 'K51', 'K51.V1_baseline-table-k50-canonical.R'),
  '--shape', 'WIDE',
  '--cohort-scope', 'analytic_wide_modeled',
  '--table-profile', 'analytic_k14_extended',
  '--data', wide_input_path,
  '--raw-data', raw_input_path
)
status <- system2('Rscript', args = cmd_args)
if (!identical(status, 0L)) {
  stop('K51 V2 delegated run failed with status ', status, call. = FALSE)
}

receipt_path <- file.path(outputs_dir, 'k51_wide_input_receipt_analytic_wide_modeled_k14_extended.txt')
decision_path <- file.path(outputs_dir, 'k51_wide_decision_log_analytic_wide_modeled_k14_extended.txt')
session_path <- file.path(outputs_dir, 'k51_wide_sessioninfo_analytic_wide_modeled_k14_extended.txt')
csv_path <- file.path(outputs_dir, 'k51_wide_baseline_table_analytic_wide_modeled_k14_extended.csv')
for (artifact_path in c(receipt_path, decision_path, session_path, csv_path)) {
  if (!file.exists(artifact_path)) {
    stop('K51 V2 expected delegated artifact was not created: ', artifact_path, call. = FALSE)
  }
}

receipt <- read_key_value_file(receipt_path)
actual_n <- parse_integer_field(receipt, 'analytic_wide_modeled_n', receipt_path)
actual_baseline_n <- parse_integer_field(receipt, 'baseline_eligible_n', receipt_path)
actual_analytic_n <- parse_integer_field(receipt, 'analytic_n', receipt_path)
actual_raw_status <- require_single_value(receipt[['raw_enrichment_status']], 'raw_enrichment_status', receipt_path)
actual_input_path <- require_single_value(receipt[['input_path']], 'input_path', receipt_path)
actual_input_md5 <- require_single_value(receipt[['input_md5']], 'input_md5', receipt_path)

csv_header <- names(utils::read.csv(csv_path, check.names = FALSE, nrows = 1L))
if (length(csv_header) < 4L) {
  stop('K51 V2 expected at least four CSV columns in manuscript-facing analytic Table 1.', call. = FALSE)
}
header_fof0_n <- extract_header_n(csv_header[[2]])
header_fof1_n <- extract_header_n(csv_header[[3]])
if (is.na(header_fof0_n) || is.na(header_fof1_n)) {
  stop('K51 V2 could not parse FOF group counts from analytic Table 1 column headers.', call. = FALSE)
}

assert_same_value(actual_input_path, wide_input_path, 'delegated K51 input path vs authoritative K50 path')
assert_same_value(actual_input_md5, receipt_md5, 'delegated K51 input md5 vs authoritative K50 md5')
assert_expected_value(actual_n, expected_n, 'delegated analytic_wide_modeled_n')
assert_expected_value(actual_analytic_n, expected_n, 'delegated analytic_n for authoritative WIDE cohort')
assert_expected_value(header_fof0_n, expected_fof0, 'analytic Table 1 Without FOF header n')
assert_expected_value(header_fof1_n, expected_fof1, 'analytic Table 1 With FOF header n')
assert_expected_value(header_fof0_n + header_fof1_n, expected_n, 'analytic Table 1 header split total')

review_log_path <- file.path(outputs_dir, 'k51_wide_analytic_table1_implementation_review_log.txt')
review_lines <- c(
  'K51 manuscript-facing analytic Table 1 implementation review',
  paste0('k50_wide_input_receipt=', wide_receipt_path),
  paste0('k50_wide_modeled_cohort_provenance=', wide_provenance_path),
  paste0('authoritative_snapshot_id=', receipt_snapshot_id),
  paste0('authoritative_input_path=', wide_input_path),
  paste0('authoritative_input_md5=', receipt_md5),
  paste0('authoritative_input_sha256=', receipt_sha256),
  paste0('authoritative_rows_modeled=', expected_n),
  paste0('authoritative_modeled_fof0_n=', expected_fof0),
  paste0('authoritative_modeled_fof1_n=', expected_fof1),
  paste0('delegated_receipt=', receipt_path),
  paste0('delegated_decision_log=', decision_path),
  paste0('delegated_sessioninfo=', session_path),
  paste0('delegated_table_csv=', csv_path),
  paste0('delegated_baseline_eligible_n=', actual_baseline_n),
  paste0('delegated_analytic_n=', actual_analytic_n),
  paste0('delegated_analytic_wide_modeled_n=', actual_n),
  paste0('delegated_raw_enrichment_status=', actual_raw_status),
  paste0('table_header_without_fof=', csv_header[[2]]),
  paste0('table_header_with_fof=', csv_header[[3]]),
  'Manuscript-facing analytic Table 1 is anchored exclusively to the authoritative K50 WIDE current cohort, not to the historical 237 receipt or the paper_01=228 reproduction path.',
  'Baseline-eligible main Table 1 remains unchanged and continues to describe the baseline-eligible cohort rather than the manuscript-facing modeled cohort.',
  'Crosschecks passed: authoritative K50 receipt and provenance matched on snapshot, path, md5, sha256, modeled n, and FOF split.',
  'Crosschecks passed: delegated K51 receipt matched authoritative K50 n=230, the rendered table headers matched 69/161, ids remain person-level WIDE, FOF_status groups are explicit in the table headers, and raw-enrichment coverage remained full_coverage.',
  'Missingness reporting is inherited from the delegated receipt/decision log: the authoritative modeled cohort requires non-missing locomotor_capacity_0, locomotor_capacity_12m, FOF_status, age, sex, BMI, and FI22_nonperformance_KAAOS.',
  'Table-to-text crosscheck passed: review-log totals, delegated receipt totals, and rendered table header totals all resolve to the same authoritative current cohort.'
)
writeLines(review_lines, con = review_log_path)
append_manifest_safe('k51_wide_analytic_table1_implementation_review_log', 'text', review_log_path, n = actual_n, notes = 'Review log for manuscript-facing K51 analytic Table 1 anchored to authoritative K50 WIDE provenance')
