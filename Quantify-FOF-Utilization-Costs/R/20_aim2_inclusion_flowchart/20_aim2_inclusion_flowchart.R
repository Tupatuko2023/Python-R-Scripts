#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(rlang)
  library(glue)
  library(readr)
  library(readxl)
})

load_local_env <- function(path = file.path("config", ".env")) {
  if (!file.exists(path)) {
    return(invisible(FALSE))
  }
  try(readRenviron(path), silent = TRUE)
  lines <- readLines(path, warn = FALSE)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]
  lines <- lines[!grepl("^#", lines)]
  lines <- sub("^export\\s+", "", lines)
  lines <- lines[grepl("^[A-Za-z_][A-Za-z0-9_]*=", lines)]
  if (length(lines) == 0) {
    return(invisible(TRUE))
  }
  keys <- sub("=.*$", "", lines)
  vals <- sub("^[^=]*=", "", lines)
  vals <- gsub("^['\"]|['\"]$", "", vals)
  for (i in seq_along(keys)) {
    do.call(Sys.setenv, setNames(list(vals[[i]]), keys[[i]]))
  }
  invisible(TRUE)
}

# Load local env config if present and environment is not already populated by shell.
load_local_env()

if (!requireNamespace("hgutils", quietly = TRUE)) {
  stop(
    paste(
      "Package 'hgutils' is required but not installed.",
      "Install it in project renv and rerun.",
      "Then capture session details with: sessionInfo()",
      sep = " "
    )
  )
}

id_var <- Sys.getenv("AIM2_ID_VAR", "id")
age_var <- Sys.getenv("AIM2_AGE_VAR", "age_years")
fof_var <- Sys.getenv("AIM2_FOF_VAR", "fof")
fof_yes_label <- Sys.getenv("AIM2_FOF_YES", "1")
fof_no_label <- Sys.getenv("AIM2_FOF_NO", "0")

starting_n_expected <- suppressWarnings(as.integer(Sys.getenv("AIM2_START_N_EXPECTED", "")))
final_n_expected <- suppressWarnings(as.integer(Sys.getenv("AIM2_FINAL_N_EXPECTED", "")))
fof_yes_expected <- suppressWarnings(as.integer(Sys.getenv("AIM2_FOF_YES_EXPECTED", "")))
fof_no_expected <- suppressWarnings(as.integer(Sys.getenv("AIM2_FOF_NO_EXPECTED", "")))

fof_missing_codes_env <- Sys.getenv("AIM2_FOF_MISSING_CODES", "2")
fof_missing_codes <- strsplit(fof_missing_codes_env, ",", fixed = TRUE)[[1]]
fof_missing_codes <- trimws(fof_missing_codes)
fof_missing_codes <- fof_missing_codes[nzchar(fof_missing_codes)]

reason_missing_fof <- "Missing Fear of Falling (FOF) response"
reason_age_lt65 <- "Age < 65 years"
reason_missing_invalid_fof <- "Missing or invalid FOF response"

data_root_env <- Sys.getenv("DATA_ROOT", unset = "")
default_data_root <- data_root_env
if (nzchar(default_data_root) && tolower(basename(default_data_root)) == "paper_02") {
  default_data_root <- dirname(default_data_root)
}
default_input <- if (nzchar(default_data_root)) {
  file.path(default_data_root, "derived", "aim2_panel.csv")
} else {
  ""
}
mock_input <- file.path("data", "sample", "DATA_ROOT_MOCK", "derived", "aim2_panel.csv")
aim2_input_env <- Sys.getenv("AIM2_INPUT_PATH", "")
is_abs_path <- function(path) grepl("^([A-Za-z]:[/\\\\]|/|\\\\\\\\)", path)
if (nzchar(aim2_input_env)) {
  if (is_abs_path(aim2_input_env)) {
    input_path <- aim2_input_env
  } else if (nzchar(data_root_env)) {
    # Preserve historical relative semantics from local .env files.
    input_path <- file.path(data_root_env, aim2_input_env)
  } else if (nzchar(default_data_root)) {
    input_path <- file.path(default_data_root, aim2_input_env)
  } else {
    input_path <- aim2_input_env
  }
  input_source_kind <- "AIM2_INPUT_PATH"
} else {
  input_path <- default_input
  input_source_kind <- "DATA_ROOT_DEFAULT"
}
if (!nzchar(input_path) || !file.exists(input_path)) {
  input_path <- mock_input
  input_source_kind <- "MOCK_FALLBACK"
}

if (!file.exists(input_path)) {
  stop(
    paste(
      "Input dataset not found.",
      "Set AIM2_INPUT_PATH or DATA_ROOT so that derived/aim2_panel.csv exists.",
      "TODO: confirm canonical Aim 2 source dataset and variable names."
    )
  )
}

out_dir <- file.path("R", "20_aim2_inclusion_flowchart", "outputs")
log_dir <- file.path("R", "20_aim2_inclusion_flowchart", "logs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
output_png <- file.path(out_dir, "aim2_inclusion_flowchart.png")

dat_raw <- readr::read_csv(input_path, show_col_types = FALSE, progress = FALSE)
required_vars <- c(id_var, age_var, fof_var)
missing_vars <- setdiff(required_vars, names(dat_raw))
if (length(missing_vars) > 0) {
  stop(glue("Missing required columns: {paste(missing_vars, collapse = ', ')}"))
}

# Raw cohort counts from canonical KAAOS source to show full cohort path in figure.
panel_id_source <- toupper(trimws(Sys.getenv("AIM2_PANEL_ID_SOURCE", "NRO")))
raw_xlsx_rel <- Sys.getenv("AIM2_RAW_XLSX_REL", "raw/KAAOS_data.xlsx")
raw_source_path <- if (nzchar(default_data_root)) file.path(default_data_root, raw_xlsx_rel) else ""
if (!file.exists(raw_source_path) && nzchar(default_data_root)) {
  # Backward-compatible fallback used by canonical builder.
  raw_source_path <- file.path(default_data_root, "paper_02", "KAAOS_data_sotullinen.xlsx")
}
raw_id_header <- Sys.getenv("AIM2_RAW_ID_HEADER", Sys.getenv("AIM2_ID_HEADER", if (panel_id_source == "SOTU") "Sotu" else "NRO"))
raw_age_header_env <- Sys.getenv("AIM2_RAW_AGE_HEADER", "")
n_raw_ids <- NA_integer_
n_after_fof_raw <- NA_integer_
n_excluded_fof <- NA_integer_
n_excluded_age <- NA_integer_
n_raw_age_ge65 <- NA_integer_
if (nzchar(raw_source_path) && file.exists(raw_source_path) && panel_id_source %in% c("NRO", "SOTU")) {
  raw_x <- readxl::read_excel(raw_source_path, skip = 1, .name_repair = "minimal")
  raw_names <- names(raw_x)
  if (!(raw_id_header %in% raw_names)) {
    stop(glue("RAW ID header not found: {raw_id_header}. Set AIM2_RAW_ID_HEADER explicitly."))
  }
  age_col <- if (nzchar(raw_age_header_env)) {
    raw_age_header_env
  } else {
    age_matches <- raw_names[grepl("ikä|age", raw_names, ignore.case = TRUE) & grepl("\\(a\\)", raw_names)]
    if (length(age_matches) == 1) {
      age_matches[[1]]
    } else {
      age_matches2 <- raw_names[grepl("ikä|age", raw_names, ignore.case = TRUE)]
      if (length(age_matches2) == 1) age_matches2[[1]] else NA_character_
    }
  }
  if (!is.na(age_col) && !(age_col %in% raw_names)) {
    stop(glue("RAW age header not found: {age_col}. Set AIM2_RAW_AGE_HEADER explicitly."))
  }
  if (is.na(age_col)) {
    stop("Could not uniquely identify RAW age column. Set AIM2_RAW_AGE_HEADER explicitly.")
  }

  id_raw <- as.character(raw_x[[raw_id_header]])
  fof_col <- if ("FOF_raw" %in% raw_names) {
    "FOF_raw"
  } else if (length(raw_names) >= 35) {
    raw_names[[35]]
  } else {
    NA_character_
  }
  if (is.na(fof_col)) {
    stop("Could not identify RAW FOF column.")
  }
  fof_raw <- suppressWarnings(as.numeric(raw_x[[fof_col]]))
  age_raw <- suppressWarnings(as.numeric(raw_x[[age_col]]))

  keep_id <- if (panel_id_source == "SOTU") {
    !is.na(id_raw) & grepl("-", id_raw, fixed = TRUE)
  } else {
    !is.na(suppressWarnings(as.numeric(id_raw)))
  }
  id_clean <- trimws(id_raw[keep_id])
  fof_clean <- fof_raw[keep_id]
  age_clean <- age_raw[keep_id]
  n_raw_ids <- dplyr::n_distinct(id_clean, na.rm = TRUE)
  n_raw_age_ge65 <- sum(age_clean >= 65, na.rm = TRUE)
  keep_fof <- fof_clean %in% c(0, 1)
  n_after_fof_raw <- dplyr::n_distinct(id_clean[keep_fof], na.rm = TRUE)
  n_excluded_fof <- n_raw_ids - n_after_fof_raw
  n_excluded_age <- sum(age_clean[keep_fof] < 65, na.rm = TRUE)
  message(glue("Raw cohort path: raw={n_raw_ids}, age_ge_65={n_raw_age_ge65}, after_fof={n_after_fof_raw}, excluded_fof={n_excluded_fof}, excluded_age_lt65={n_excluded_age}."))
} else {
  warning("Raw source unavailable for full-cohort path; figure will include only canonical flow text.")
}

# hgutils flowchart counts rows; deduplicate to one row per participant first.
dat0 <- dat_raw %>%
  distinct(!!sym(id_var), .keep_all = TRUE)

sym_id <- sym(id_var)
sym_fof <- sym(fof_var)

count_unique_ids <- function(df) dplyr::n_distinct(df[[id_var]], na.rm = TRUE)
count_missing_ids <- function(df) sum(is.na(df[[id_var]]))

n_start_rows <- nrow(dat0)
n_start_ids <- count_unique_ids(dat0)
n_start_id_na <- count_missing_ids(dat0)
message(glue("Input source kind: {input_source_kind}"))
message(glue("Starting dataset: {n_start_rows} rows; {n_start_ids} unique non-missing {id_var}; id_na={n_start_id_na}."))

if (!is.na(starting_n_expected) && n_start_ids != starting_n_expected) {
  warning(glue("Starting N discrepancy: expected {starting_n_expected}, found {n_start_ids}."))
}

flow <- hgutils::inclusion_flowchart(
  dataset = dat0,
  node_text = "%s eligible patients"
)

dat1 <- hgutils::exclude_patients(
  flowchart = flow,
  dataset = dat0,
  exclusion_criterium = is.na(get(fof_var)) | as.character(get(fof_var)) %in% fof_missing_codes,
  reason = reason_missing_fof,
  node_text = "%s eligible patients",
  excluded_text = "%s excluded"
)

dat2 <- hgutils::exclude_patients(
  flowchart = flow,
  dataset = dat1,
  exclusion_criterium = !is.na(get(age_var)) & get(age_var) < 65,
  reason = reason_age_lt65,
  node_text = "%s eligible patients",
  excluded_text = "%s excluded"
)

n_after_ex1 <- count_unique_ids(dat1)
n_after_ex2 <- count_unique_ids(dat2)
n_after_ex1_id_na <- count_missing_ids(dat1)
n_after_ex2_id_na <- count_missing_ids(dat2)
message(glue("After exclusion 1 ({reason_missing_fof}): {n_after_ex1} unique non-missing {id_var}; id_na={n_after_ex1_id_na}."))
message(glue("After exclusion 2 ({reason_age_lt65}): {n_after_ex2} unique non-missing {id_var}; id_na={n_after_ex2_id_na}."))

fof_counts <- dat2 %>%
  distinct(!!sym_id, .keep_all = TRUE) %>%
  mutate(fof_value_chr = as.character(!!sym_fof)) %>%
  mutate(
    fof_group = case_when(
      fof_value_chr == fof_yes_label ~ "FOF: Yes",
      fof_value_chr == fof_no_label ~ "FOF: No",
      TRUE ~ "FOF: Other/Unknown"
    )
  ) %>%
  count(fof_group, name = "n")

sum_split <- sum(fof_counts$n)
n_final_ids <- count_unique_ids(dat2)
message(glue("Final analytic cohort: {n_final_ids} unique non-missing {id_var}; id_na={n_after_ex2_id_na}."))
for (i in seq_len(nrow(fof_counts))) {
  message(glue("{fof_counts$fof_group[[i]]}: {fof_counts$n[[i]]}"))
}
message(glue("FOF split total: {sum_split}"))

if (!is.na(final_n_expected)) {
  stopifnot(n_final_ids == final_n_expected)
} else {
  warning("AIM2_FINAL_N_EXPECTED not set; final N assertion skipped.")
}
stopifnot(sum_split == n_final_ids)

n_yes <- sum(fof_counts$n[fof_counts$fof_group == "FOF: Yes"], na.rm = TRUE)
n_no <- sum(fof_counts$n[fof_counts$fof_group == "FOF: No"], na.rm = TRUE)
if (!is.na(fof_yes_expected)) {
  stopifnot(n_yes == fof_yes_expected)
}
if (!is.na(fof_no_expected)) {
  stopifnot(n_no == fof_no_expected)
}

# Build final text that goes into the exported PNG (full cohort path only).
lines <- c(
  "Full cohort path (from canonical KAAOS source):",
  if (!is.na(n_raw_ids)) glue("N = {n_raw_ids} patients in KAAOS dataset") else "N = NA patients in KAAOS dataset",
  if (!is.na(n_raw_age_ge65)) glue("  (Age >= 65 in raw dataset: {n_raw_age_ge65})") else "  (Age >= 65 in raw dataset: NA)",
  if (!is.na(n_excluded_fof)) glue("|-----> N = {n_excluded_fof} excluded [{reason_missing_invalid_fof}]") else glue("|-----> N = NA excluded [{reason_missing_invalid_fof}]"),
  if (!is.na(n_after_fof_raw)) glue("N = {n_after_fof_raw} patients with FOF data") else "N = NA patients with FOF data",
  if (!is.na(n_excluded_age)) glue("|-----> N = {n_excluded_age} excluded [{reason_age_lt65}]") else glue("|-----> N = NA excluded [{reason_age_lt65}]"),
  glue("N = {n_final_ids} eligible patients"),
  "",
  "FOF groups among final analytic cohort:",
  glue("- FOF: Yes = {n_yes}"),
  glue("- FOF: No  = {n_no}")
)

flow_text_full <- paste(lines, collapse = "\n")

png(filename = output_png, width = 3000, height = 2100, res = 300, bg = "white")
grid::grid.newpage()
grid::grid.text(
  flow_text_full,
  x = 0.02, y = 0.98,
  just = c("left", "top"),
  gp = grid::gpar(fontfamily = "mono", cex = 0.75)
)
invisible(dev.off())
message(glue("Saved flowchart: {output_png}"))
