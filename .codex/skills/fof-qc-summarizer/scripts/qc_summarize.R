#!/usr/bin/env Rscript

usage <- function() {
  cat("QC summarizer (FOF)\n")
  cat("Usage: Rscript qc_summarize.R [--qc-dir PATH] [--out-dir PATH] [--script-label LABEL]\n")
  cat("Defaults are resolved from Fear-of-Falling project root.\n")
}

get_arg <- function(flag, default = NULL) {
  args <- commandArgs(trailingOnly = TRUE)
  i <- match(flag, args)
  if (is.na(i)) return(default)
  if (i == length(args)) return(default)
  args[[i + 1]]
}

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  usage()
  quit(status = 0)
}

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[1]) else ""

candidates <- c(getwd(), file.path(getwd(), "Fear-of-Falling"))
if (nzchar(script_path)) {
  repo_root <- normalizePath(file.path(dirname(script_path), "..", "..", "..", ".."),
                             mustWork = FALSE)
  candidates <- c(candidates, file.path(repo_root, "Fear-of-Falling"))
}

fof_root <- ""
for (cand in candidates) {
  if (file.exists(file.path(cand, "manifest", "manifest.csv")) &&
      dir.exists(file.path(cand, "R-scripts"))) {
    fof_root <- cand
    break
  }
}

if (!nzchar(fof_root)) {
  stop("ERROR: Could not locate Fear-of-Falling project root (manifest/R-scripts missing).",
       call. = FALSE)
}

setwd(fof_root)

find_init_path <- function(root) {
  candidates <- list.files(root, pattern = "^init\\.R$", recursive = TRUE, full.names = TRUE)
  if (length(candidates) == 0) return("")
  matches <- character(0)
  for (cand in candidates) {
    lines <- tryCatch(readLines(cand, warn = FALSE), error = function(e) NULL)
    if (is.null(lines)) next
    if (any(grepl("manifest_row", lines)) && any(grepl("append_manifest", lines))) {
      matches <- c(matches, cand)
    }
  }
  if (length(matches) == 1) return(matches[[1]])
  if (length(matches) > 1) return(list(matches = matches))
  ""
}

init_path <- find_init_path(fof_root)
if (is.list(init_path)) {
  stop("ERROR: Multiple init.R candidates with manifest helpers: ",
       paste(init_path$matches, collapse = "; "),
       call. = FALSE)
}
if (!nzchar(init_path)) {
  stop("ERROR: Could not locate init.R with manifest helpers; fail closed.", call. = FALSE)
}
source(init_path)

if (!exists("append_manifest") || !exists("manifest_row")) {
  stop("ERROR: Manifest helpers not available; fail closed.", call. = FALSE)
}

manifest_path <- file.path(fof_root, "manifest", "manifest.csv")
if (!file.exists(manifest_path)) {
  stop("ERROR: manifest/manifest.csv not found; cannot confirm format.", call. = FALSE)
}

header <- readLines(manifest_path, n = 1)
header_str <- if (length(header) > 0) header[[1]] else ""
expected_cols <- c("timestamp", "script", "label", "kind", "path", "n", "notes")
observed_cols <- if (nzchar(header_str)) strsplit(header_str, ",")[[1]] else character(0)
if (!identical(observed_cols, expected_cols)) {
  stop("ERROR: manifest header mismatch; observed: ", header_str, call. = FALSE)
}

qc_dir <- get_arg("--qc-dir",
                  file.path(fof_root, "R-scripts", "K18", "outputs", "K18_QC", "qc"))
if (!dir.exists(qc_dir)) {
  stop("ERROR: QC outputs not found; run K18 QC first.", call. = FALSE)
}

out_dir <- get_arg("--out-dir",
                   file.path(fof_root, "R-scripts", "K18", "outputs", "K18_QC", "qc_summary"))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

script_label <- get_arg("--script-label", "K18_QC_SUMMARY")

qc_files <- list.files(qc_dir, pattern = "\\.csv$", full.names = TRUE)
if (length(qc_files) == 0) {
  stop("ERROR: No QC CSV artifacts found in qc directory.", call. = FALSE)
}

skip_name <- function(fname) {
  lname <- tolower(fname)
  pattern <- "(^|[^a-z0-9])(ids|row_level|row_id|participant_level|participant|individual)([^a-z0-9]|$)"
  grepl(pattern, lname)
}

warnings <- character(0)
summary_rows <- list()

for (path in qc_files) {
  base <- basename(path)
  if (skip_name(base)) {
    warnings <- c(warnings, paste0("SKIP filename (privacy): ", base))
    next
  }

  df <- tryCatch(read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
                 error = function(e) NULL)
  if (is.null(df)) {
    warnings <- c(warnings, paste0("SKIP unreadable: ", base))
    next
  }

  cols_lower <- tolower(names(df))
  if (any(grepl("(^id$|_id$|participant)", cols_lower))) {
    warnings <- c(warnings, paste0("SKIP id columns: ", base))
    next
  }

  status <- "INFO"
  n_issues <- NA_integer_
  if ("ok" %in% cols_lower) {
    ok_col <- df[[which(cols_lower == "ok")[1]]]
    ok_str <- tolower(as.character(ok_col))
    ok_bool <- ok_str %in% c("true", "t", "1")
    status <- if (all(ok_bool)) "PASS" else "FAIL"
    n_issues <- sum(!ok_bool)
  }

  summary_rows[[length(summary_rows) + 1]] <- data.frame(
    check_name = tools::file_path_sans_ext(base),
    status = status,
    n_rows = nrow(df),
    n_issues = n_issues,
    notes = paste0("cols=", ncol(df)),
    stringsAsFactors = FALSE
  )
}

if (length(summary_rows) == 0) {
  stop("ERROR: No eligible aggregate QC artifacts to summarize.", call. = FALSE)
}

summary_df <- do.call(rbind, summary_rows)
summary_csv <- file.path(out_dir, "qc_summary.csv")
summary_txt <- file.path(out_dir, "qc_summary.txt")

write.csv(summary_df, summary_csv, row.names = FALSE)

lines <- c(
  "QC summary (aggregate only)",
  paste0("Artifacts summarized: ", nrow(summary_df)),
  ""
)
for (i in seq_len(nrow(summary_df))) {
  row <- summary_df[i, ]
  lines <- c(lines, paste0("- ", row$check_name, ": ", row$status,
                           " (n_rows=", row$n_rows, ", n_issues=", row$n_issues, ")"))
}
if (length(warnings) > 0) {
  lines <- c(lines, "", "Warnings:", paste0("- ", warnings))
}
writeLines(lines, con = summary_txt)

relpath <- if (exists("get_relpath")) get_relpath else function(p) p

append_manifest(
  manifest_row(script = script_label, label = "qc_summary",
               path = relpath(summary_csv), kind = "qc_summary_csv",
               n = nrow(summary_df), notes = "aggregate_only"),
  manifest_path
)
append_manifest(
  manifest_row(script = script_label, label = "qc_summary_notes",
               path = relpath(summary_txt), kind = "qc_summary_txt",
               n = nrow(summary_df), notes = "aggregate_only"),
  manifest_path
)
