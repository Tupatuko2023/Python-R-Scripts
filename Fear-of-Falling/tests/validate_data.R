#!/usr/bin/env Rscript

# tests/validate_data.R
#
# Validate a dataset against data/data_dictionary.csv (Fear-of-Falling)
#
# Usage:
#   Rscript tests/validate_data.R --data path/to/file.csv
#   Rscript tests/validate_data.R --data path/to/file.csv --dict data/data_dictionary.csv --layer raw
#   Rscript tests/validate_data.R --data path/to/file.csv --strict 1
#
# Exit codes:
#   0 = OK (no errors)
#   1 = validation errors found
#   2 = invalid usage / missing files

args <- commandArgs(trailingOnly = TRUE)

get_arg <- function(flag, default = NULL) {
  i <- match(flag, args)
  if (is.na(i)) return(default)
  if (i == length(args)) return(default)
  args[[i + 1]]
}

has_flag <- function(flag) flag %in% args

data_path <- get_arg("--data")
dict_path <- get_arg("--dict", "data/data_dictionary.csv")
layer     <- get_arg("--layer", "all")   # raw | analysis | derived | all
strict    <- as.integer(get_arg("--strict", "0")) # 1 = treat warnings as errors
optional  <- get_arg("--optional", "") # comma-separated optional variable names

if (is.null(data_path) || !nzchar(data_path)) {
  cat("ERROR: --data is required\n")
  cat("Usage: Rscript tests/validate_data.R --data path/to/file.csv ",
      "[--dict data/data_dictionary.csv] [--layer raw|analysis|derived|all] ",
      "[--strict 0|1]\n", sep = "")
  quit(status = 2)
}
if (!file.exists(data_path)) {
  cat("ERROR: data file not found: ", data_path, "\n", sep = "")
  quit(status = 2)
}
if (!file.exists(dict_path)) {
  cat("ERROR: dictionary file not found: ", dict_path, "\n", sep = "")
  quit(status = 2)
}

read_csv_base <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

dd <- read_csv_base(dict_path)
dat <- read_csv_base(data_path)

required_dd_cols <- c(
  "variable",
  "label_fi",
  "type",
  "allowed_values_or_coding",
  "unit",
  "timepoint",
  "role_in_model",
  "derivation_formula",
  "missingness_notes",
  "needs_confirmation"
)

missing_dd_cols <- setdiff(required_dd_cols, names(dd))
if (length(missing_dd_cols) > 0) {
  cat("ERROR: data_dictionary.csv is missing required columns:\n")
  cat("  - ", paste(missing_dd_cols, collapse = ", "), "\n", sep = "")
  quit(status = 2)
}

if (!"dataset_layer" %in% names(dd)) {
  dd$dataset_layer <- "all"
}

dd$dataset_layer <- tolower(trimws(dd$dataset_layer))
dd$variable <- trimws(dd$variable)
dd$type <- tolower(trimws(dd$type))
dd$allowed_values_or_coding <- trimws(dd$allowed_values_or_coding)
dd$timepoint <- tolower(trimws(dd$timepoint))

if (!layer %in% c("raw", "analysis", "derived", "all")) {
  cat("ERROR: --layer must be one of raw|analysis|derived|all\n")
  quit(status = 2)
}
if (layer != "all" && !"dataset_layer" %in% names(dd)) {
  cat("ERROR: --layer filtering requires dataset_layer in dictionary.\n")
  cat("Add a dataset_layer column with values: raw | analysis | derived.\n")
  quit(status = 2)
}
if (layer != "all" && all(!nzchar(dd$dataset_layer))) {
  cat("ERROR: --layer filtering is ineffective because dataset_layer is empty.\n")
  cat("Populate dataset_layer with raw | analysis | derived values.\n")
  quit(status = 2)
}

dd_use <- dd
if (layer != "all") dd_use <- dd_use[dd_use$dataset_layer == layer, , drop = FALSE]

# Drop empty variable rows (just in case)
dd_use <- dd_use[nzchar(dd_use$variable), , drop = FALSE]

# Helpers to parse simple allowed rules
parse_levels <- function(s) {
  # matches "levels {a,b,c}" (case-insensitive)
  m <- regexec("levels\\s*\\{([^}]*)\\}", s, ignore.case = TRUE)
  r <- regmatches(s, m)[[1]]
  if (length(r) >= 2) {
    parts <- unlist(strsplit(r[2], ","))
    return(trimws(parts))
  }
  character(0)
}

parse_range <- function(s) {
  # matches "0..10" or "0..3"
  m <- regexec("(-?\\d+(?:\\.\\d+)?)\\s*\\.\\.\\s*(-?\\d+(?:\\.\\d+)?)", s)
  r <- regmatches(s, m)[[1]]
  if (length(r) >= 3) {
    return(c(as.numeric(r[2]), as.numeric(r[3])))
  }
  c(NA_real_, NA_real_)
}

is_binary_rule <- function(s) {
  grepl("0\\s*=", s) && grepl("1\\s*=", s)
}

coerce_numeric_safely <- function(x) {
  if (is.numeric(x)) return(x)
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x)) x <- as.character(x)
  suppressWarnings(as.numeric(x))
}

errors <- character(0)
warnings <- character(0)

cat("Validate dataset against dictionary\n")
cat("  Data: ", data_path, "\n", sep = "")
cat("  Dict: ", dict_path, "\n", sep = "")
cat("  Rows: ", nrow(dat), "  Cols: ", ncol(dat), "\n", sep = "")
cat("  Layer: ", layer, "\n\n", sep = "")

# 1) Column presence
vars <- unique(dd_use$variable)
opt_vars <- character(0)
if (nzchar(optional)) {
  opt_vars <- trimws(unlist(strsplit(optional, ",")))
  opt_vars <- opt_vars[nzchar(opt_vars)]
}
missing_vars <- setdiff(setdiff(vars, names(dat)), opt_vars)

if (length(missing_vars) > 0) {
  errors <- c(errors, paste0("Missing columns in data: ", paste(missing_vars, collapse = ", ")))
}

# 2) Type/allowed checks for columns that exist
present_vars <- intersect(vars, names(dat))

for (v in present_vars) {
  row <- dd_use[dd_use$variable == v, , drop = FALSE]
  # If multiple entries (e.g., duplicates across layers), choose the first
  row <- row[1, , drop = FALSE]

  typ <- row$type[[1]]
  allowed <- row$allowed_values_or_coding[[1]]

  x <- dat[[v]]
  na_rate <- mean(is.na(x))
  if (is.nan(na_rate)) na_rate <- 1

  # Missingness summary as warning if extreme
  if (na_rate >= 0.95) {
    warnings <- c(warnings, paste0("High missingness (>=95%) in column: ", v))
  }

  if (typ %in% c("numeric", "numeric_or_integer")) {
    xn <- coerce_numeric_safely(x)
    introduced <- sum(is.na(xn) & !is.na(x))
    if (introduced > 0) {
      errors <- c(errors, paste0("Non-numeric values found in numeric column '", v,
                                 "' (", introduced, " values could not be parsed)"))
    }
    rng <- parse_range(allowed)
    if (!any(is.na(rng))) {
      ok <- xn[!is.na(xn)] >= rng[1] & xn[!is.na(xn)] <= rng[2]
      if (any(!ok)) warnings <- c(warnings, paste0("Values out of range ", rng[1], "..",
                                                   rng[2], " in column: ", v))
    }
  } else if (typ %in% c("integer", "integer_or_ordinal")) {
    xn <- coerce_numeric_safely(x)
    introduced <- sum(is.na(xn) & !is.na(x))
    if (introduced > 0) {
      errors <- c(errors, paste0("Non-integer values found in integer column '", v,
                                 "' (", introduced, " values could not be parsed)"))
    }
    non_int <- xn[!is.na(xn)] %% 1 != 0
    if (any(non_int)) warnings <- c(warnings, paste0("Non-integer numeric values detected in column: ", v))
    rng <- parse_range(allowed)
    if (!any(is.na(rng))) {
      ok <- xn[!is.na(xn)] >= rng[1] & xn[!is.na(xn)] <= rng[2]
      if (any(!ok)) warnings <- c(warnings, paste0("Values out of range ", rng[1], "..",
                                                   rng[2], " in column: ", v))
    }
  } else if (typ %in% c("binary_or_factor", "binary", "status_factor", "factor",
                        "categorical", "ordinal_or_categorical")) {
    # If allowed specifies levels {..}, enforce for character/factor
    levs <- parse_levels(allowed)
    if (length(levs) > 0) {
      vals <- x
      if (is.factor(vals)) vals <- as.character(vals)
      vals <- vals[!is.na(vals)]
      bad <- setdiff(unique(vals), levs)
      if (length(bad) > 0) {
        errors <- c(errors, paste0("Unexpected levels in column '", v, "': ", paste(bad, collapse = ", "),
                                   " (allowed: ", paste(levs, collapse = ", "), ")"))
      }
    } else if (is_binary_rule(allowed)) {
      xn <- coerce_numeric_safely(x)
      introduced <- sum(is.na(xn) & !is.na(x))
      if (introduced > 0) {
        errors <- c(errors, paste0("Non 0/1 values in binary column '", v, "' (",
                                   introduced, " values could not be parsed)"))
      } else {
        vals <- sort(unique(xn[!is.na(xn)]))
        if (length(vals) > 0 && any(!vals %in% c(0, 1))) {
          errors <- c(errors, paste0("Binary column '", v, "' contains values outside {0,1}: ",
                                     paste(vals, collapse = ", ")))
        }
      }
    } else {
      # No strict rule, but warn if numeric with many unique values
      if (is.numeric(x) || is.integer(x)) {
        vals <- unique(x[!is.na(x)])
        if (length(vals) > 10) warnings <- c(warnings, paste0("Column '", v,
                                                             "' is marked factor-like but has many numeric unique values (",
                                                             length(vals), ")"))
      }
    }
  } else if (typ %in% c("identifier")) {
    # Basic sanity
    if (all(is.na(x))) errors <- c(errors, paste0("Identifier column '", v, "' is entirely NA"))
  } else if (typ %in% c("text")) {
    # No validation, but warn about potential PII risk
    warnings <- c(warnings, paste0("Text column present: ", v,
                                   " (ensure it contains no PII and is not committed if sensitive)"))
  } else {
    # Unknown type: warn only
    warnings <- c(warnings, paste0("Unknown type '", typ, "' for column ", v, " (no strict checks applied)"))
  }
}

# 3) Summary
cat("Summary\n")
cat("  Missing columns: ",
    if (length(missing_vars) == 0) "0" else as.character(length(missing_vars)),
    "\n", sep = "")
cat("  Errors: ", length(errors), "\n", sep = "")
cat("  Warnings: ", length(warnings), "\n\n", sep = "")

if (length(errors) > 0) {
  cat("ERRORS\n")
  for (e in errors) cat("  - ", e, "\n", sep = "")
  cat("\n")
}

if (length(warnings) > 0) {
  cat("WARNINGS\n")
  for (w in warnings) cat("  - ", w, "\n", sep = "")
  cat("\n")
}

# 4) needs_confirmation list (informational)
if ("confirmation_notes" %in% names(dd_use)) {
  conf_notes <- dd_use$confirmation_notes
} else {
  conf_notes <- rep("", nrow(dd_use))
}
need_conf <- dd_use[dd_use$needs_confirmation %in% c(TRUE, "TRUE", "True", "1"),
                    c("variable"), drop = FALSE]
if (nrow(need_conf) > 0) {
  cat("Needs confirmation (from dictionary)\n")
  for (i in seq_len(nrow(need_conf))) {
    v <- need_conf$variable[[i]]
    n <- conf_notes[dd_use$variable == v]
    n <- if (length(n) > 0) n[[1]] else ""
    if (!nzchar(n)) n <- "(no note)"
    cat("  - ", v, ": ", n, "\n", sep = "")
  }
  cat("\n")
}

# Exit behavior
if (length(errors) > 0 || (strict == 1L && length(warnings) > 0)) {
  quit(status = 1)
}
quit(status = 0)
