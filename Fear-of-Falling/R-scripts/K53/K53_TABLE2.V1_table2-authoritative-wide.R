#!/usr/bin/env Rscript
# ==============================================================================
# K53 - Authoritative WIDE Table 2 generator
# File tag: K53_TABLE2.V1_table2-authoritative-wide.R
# Purpose: Generate a new Table 2 style output from the authoritative K50 WIDE
#          cohort using manuscript structure but current paper_02 modeled counts.
#
# Outcome: MWS, FTSST, SLS, HGS (women/men) baseline and 12-month change
# Predictors: FOF_status
# Moderator/interaction: None
# Grouping variable: None (wide format)
# Covariates: Model A = FOF only; Model B = FOF + baseline; Model C = FOF +
#             baseline + sex + age + BMI. P-values come from manuscript-style
#             ANCOVA on follow-up, while change columns remain observed
#             within-group deltas with t-based 95% CI.
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, FOF_status, age, sex, BMI, locomotor_capacity_0, locomotor_capacity_12m,
# NRO, SLS_right0, SLS_left0, SLS_right2, SLS_left2, FTSST0, FTSST2,
# HGS_right0, HGS_left0, HGS_right2, HGS_left2, MWS_seconds0, MWS_seconds2
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# TK/2SK workbook columns -> baseline/12m measure aliases; 10 m walk seconds ->
# MWS m/s via 10 / seconds; bilateral SLS/HGS -> row mean of left/right values.
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K53 (canonical)
# - outputs dir: R-scripts/K53/outputs/  (resolved via init_paths("K53"))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Parse CLI args and resolve authoritative K50 + raw measurement inputs
# 03) Load authoritative K50 WIDE cohort input (immutable; no edits)
# 04) Load workbook-derived raw performance measures and rename required vars
# 05) Derive modeled cohort from K50 authoritative contract
# 06) Join modeled cohort to test-level measures and derive MWS/SLS/HGS fields
# 07) Fit follow-up ANCOVA models A/B/C and collect model-wise N audit
# 08) Build Table 2 output + table-to-text crosscheck for authoritative counts
# 09) Save CSV/HTML/audit/provenance/sessionInfo -> R-scripts/K53/outputs/
# 10) Append manifest row per artifact
# 11) EOF marker
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tibble)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_label <- "K53"
script_path <- if (length(file_arg) > 0) {
  normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/", mustWork = TRUE)
} else {
  normalizePath(here::here("R-scripts", "K53", "K53_TABLE2.V1_table2-authoritative-wide.R"), winslash = "/", mustWork = TRUE)
}

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

options(
  fof.outputs_dir = outputs_dir,
  fof.manifest_path = manifest_path,
  fof.script = script_label
)

req_cols <- c(
  "id", "FOF_status", "age", "sex", "BMI", "locomotor_capacity_0", "locomotor_capacity_12m",
  "NRO", "SLS_right0", "SLS_left0", "SLS_right2", "SLS_left2", "FTSST0", "FTSST2",
  "HGS_right0", "HGS_left0", "HGS_right2", "HGS_left2", "MWS_seconds0", "MWS_seconds2"
)

parse_cli <- function(args) {
  out <- list(
    input = NA_character_,
    raw_excel = NA_character_,
    raw_csv = NA_character_,
    output_csv = NA_character_,
    output_html = NA_character_,
    output_audit = NA_character_,
    output_provenance = NA_character_,
    output_session = NA_character_
  )

  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--raw_excel=")) out$raw_excel <- sub("^--raw_excel=", "", arg)
    if (startsWith(arg, "--raw_csv=")) out$raw_csv <- sub("^--raw_csv=", "", arg)
    if (startsWith(arg, "--output_csv=")) out$output_csv <- sub("^--output_csv=", "", arg)
    if (startsWith(arg, "--output_html=")) out$output_html <- sub("^--output_html=", "", arg)
    if (startsWith(arg, "--output_audit=")) out$output_audit <- sub("^--output_audit=", "", arg)
    if (startsWith(arg, "--output_provenance=")) out$output_provenance <- sub("^--output_provenance=", "", arg)
    if (startsWith(arg, "--output_session=")) out$output_session <- sub("^--output_session=", "", arg)
  }

  out
}

resolve_data_root <- function() {
  dr <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(dr)) return(NA_character_)
  normalizePath(dr, winslash = "/", mustWork = FALSE)
}

resolve_existing <- function(paths) {
  hits <- paths[file.exists(paths)]
  if (length(hits) == 0) return(NA_character_)
  normalizePath(hits[[1]], winslash = "/", mustWork = TRUE)
}

choose_k50_input <- function(cli_input) {
  data_root <- resolve_data_root()
  candidates <- c(
    if (!is.na(cli_input) && nzchar(cli_input)) cli_input else character(0),
    if (!is.na(data_root)) file.path(data_root, "paper_02", "analysis", "fof_analysis_k50_wide.rds") else character(0),
    if (!is.na(data_root)) file.path(data_root, "paper_02", "analysis", "fof_analysis_k50_wide.csv") else character(0),
    "/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/analysis/fof_analysis_k50_wide.rds",
    "/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/analysis/fof_analysis_k50_wide.csv"
  )

  hit <- resolve_existing(candidates)
  if (is.na(hit)) {
    stop("K53 could not resolve authoritative K50 WIDE input. Supply --input explicitly.", call. = FALSE)
  }
  hit
}

choose_raw_excel <- function(cli_path) {
  data_root <- resolve_data_root()
  candidates <- c(
    if (!is.na(cli_path) && nzchar(cli_path)) cli_path else character(0),
    if (!is.na(data_root)) file.path(data_root, "paper_02", "KAAOS_data_sotullinen.xlsx") else character(0),
    "/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/KAAOS_data_sotullinen.xlsx"
  )

  hit <- resolve_existing(candidates)
  if (is.na(hit)) {
    stop("K53 could not resolve the raw measurement workbook. Supply --raw_excel explicitly.", call. = FALSE)
  }
  hit
}

read_k50_input <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") {
    return(as_tibble(readRDS(path)))
  }
  if (ext == "csv") {
    return(as_tibble(readr::read_csv(path, show_col_types = FALSE)))
  }
  stop("Unsupported K50 input extension: ", ext, call. = FALSE)
}

normalize_id <- function(x) {
  x_chr <- trimws(as.character(x))
  num <- suppressWarnings(as.integer(x_chr))
  out <- ifelse(!is.na(num), as.character(num), x_chr)
  ifelse(out %in% c("", "NA", "NaN"), NA_character_, out)
}

safe_num <- function(x) suppressWarnings(as.numeric(x))

normalize_fof <- function(x) {
  s <- trimws(as.character(x))
  out <- suppressWarnings(as.integer(s))
  out[!(out %in% c(0L, 1L))] <- NA_integer_
  out
}

normalize_sex <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_character_, length(s))
  out[s %in% c("female", "f", "0", "2", "woman", "nainen")] <- "female"
  out[s %in% c("male", "m", "1", "man", "mies")] <- "male"
  factor(out, levels = c("female", "male"))
}

normalize_header <- function(x) {
  x_ascii <- iconv(x, to = "ASCII//TRANSLIT")
  gsub("[^a-z0-9]+", "", tolower(x_ascii))
}

pick_first <- function(normalized_names, patterns, label) {
  hits <- unique(unlist(lapply(patterns, function(p) which(grepl(p, normalized_names)))))
  if (length(hits) == 0) {
    stop("K53 could not resolve workbook column for ", label, ".", call. = FALSE)
  }
  hits[[1]]
}

read_measure_data <- function(raw_excel, raw_csv) {
  if (!is.na(raw_csv) && nzchar(raw_csv)) {
    raw_tbl <- suppressMessages(readr::read_csv(raw_csv, show_col_types = FALSE))
  } else {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("K53 requires either readxl for --raw_excel or a prepared --raw_csv fallback.", call. = FALSE)
    }
    raw_tbl <- tibble::as_tibble(readxl::read_excel(raw_excel, sheet = "Taul1", skip = 1, n_max = Inf))
  }

  norm <- normalize_header(names(raw_tbl))
  idx <- c(
    NRO = pick_first(norm, c("^nro$"), "NRO"),
    SLS_right0 = pick_first(norm, c("^tkyhdellajalallaseisominenoikea"), "SLS_right0"),
    SLS_left0 = pick_first(norm, c("^tkyhdellajalallaseisominenvasen"), "SLS_left0"),
    SLS_right2 = pick_first(norm, c("^2skyhdellajalallaseisominenoikea"), "SLS_right2"),
    SLS_left2 = pick_first(norm, c("^2skyhdellajalallaseisominenvasen"), "SLS_left2"),
    FTSST0 = pick_first(norm, c("^tktuoliltanousu5krt"), "FTSST0"),
    FTSST2 = pick_first(norm, c("^2sktuoliltanousu5krt"), "FTSST2"),
    HGS_right0 = pick_first(norm, c("^tkpuristusvoimaoikea"), "HGS_right0"),
    HGS_left0 = pick_first(norm, c("^tkpuristusvoimavasen"), "HGS_left0"),
    HGS_right2 = pick_first(norm, c("^2skpuristusvoimaoikea"), "HGS_right2"),
    HGS_left2 = pick_first(norm, c("^2skpuristusvoimavasen"), "HGS_left2"),
    MWS_seconds0 = pick_first(norm, c("^tk10metrinkavelynopeussek"), "MWS_seconds0"),
    MWS_seconds2 = pick_first(norm, c("^sk210metrinkavelynopeussek"), "MWS_seconds2")
  )

  renamed <- tibble(
    NRO = raw_tbl[[idx[["NRO"]]]],
    SLS_right0 = raw_tbl[[idx[["SLS_right0"]]]],
    SLS_left0 = raw_tbl[[idx[["SLS_left0"]]]],
    SLS_right2 = raw_tbl[[idx[["SLS_right2"]]]],
    SLS_left2 = raw_tbl[[idx[["SLS_left2"]]]],
    FTSST0 = raw_tbl[[idx[["FTSST0"]]]],
    FTSST2 = raw_tbl[[idx[["FTSST2"]]]],
    HGS_right0 = raw_tbl[[idx[["HGS_right0"]]]],
    HGS_left0 = raw_tbl[[idx[["HGS_left0"]]]],
    HGS_right2 = raw_tbl[[idx[["HGS_right2"]]]],
    HGS_left2 = raw_tbl[[idx[["HGS_left2"]]]],
    MWS_seconds0 = raw_tbl[[idx[["MWS_seconds0"]]]],
    MWS_seconds2 = raw_tbl[[idx[["MWS_seconds2"]]]]
  )

  missing_cols <- setdiff(req_cols[8:length(req_cols)], names(renamed))
  if (length(missing_cols) > 0) {
    stop("K53 renamed workbook data is missing required columns: ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }

  renamed
}

mean_pair <- function(a, b) {
  a_num <- safe_num(a)
  b_num <- safe_num(b)
  out <- (a_num + b_num) / 2
  out[is.na(a_num) & !is.na(b_num)] <- b_num[is.na(a_num) & !is.na(b_num)]
  out[!is.na(a_num) & is.na(b_num)] <- a_num[!is.na(a_num) & is.na(b_num)]
  out
}

seconds_to_speed <- function(x) {
  sec <- safe_num(x)
  out <- ifelse(!is.na(sec) & sec > 0, 10 / sec, NA_real_)
  out
}

fmt_mean_sd <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return("NA")
  sprintf("%.2f (%.2f)", mean(x), stats::sd(x))
}

fmt_delta_ci <- function(x) {
  x <- x[!is.na(x)]
  n <- length(x)
  if (n == 0) return("NA")
  m <- mean(x)
  s <- stats::sd(x)
  if (is.na(s)) s <- 0
  se <- s / sqrt(n)
  tcrit <- if (n > 1) stats::qt(0.975, df = n - 1) else NA_real_
  lo <- if (is.finite(tcrit)) m - tcrit * se else m
  hi <- if (is.finite(tcrit)) m + tcrit * se else m
  sprintf("%.2f, 95%% CI [%.2f, %.2f]", m, lo, hi)
}

fmt_p <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

extract_fof_p <- function(model) {
  a <- tryCatch(drop1(model, test = "F"), error = function(e) NULL)
  if (is.null(a)) return(NA_real_)
  p_col <- grep("Pr\\(>F\\)", names(a), value = TRUE)[1]
  if (is.na(p_col) || is.null(p_col)) return(NA_real_)
  rn <- rownames(a)
  idx <- which(rn == "FOF_status_f")
  if (length(idx) == 0) idx <- grep("^FOF_status_f", rn)
  if (length(idx) == 0) return(NA_real_)
  as.numeric(a[idx[1], p_col])
}

fit_with_audit <- function(formula, dat, outcome_label, model_label, sex_stratum, include_sex_term) {
  mf <- tryCatch(stats::model.frame(formula, data = dat, na.action = stats::na.omit), error = function(e) NULL)
  if (is.null(mf) || nrow(mf) == 0) {
    return(list(
      p = NA_real_,
      audit = tibble(
        Outcome = outcome_label,
        sex_stratum = sex_stratum,
        model = model_label,
        formula = format(formula),
        include_sex_in_model = include_sex_term,
        nobs = 0L,
        n_without = 0L,
        n_with = 0L
      )
    ))
  }

  n_tbl <- table(mf$FOF_status_f)
  n_without <- as.integer(ifelse("Ei FOF" %in% names(n_tbl), n_tbl[["Ei FOF"]], 0L))
  n_with <- as.integer(ifelse("FOF" %in% names(n_tbl), n_tbl[["FOF"]], 0L))

  if (!("FOF_status_f" %in% names(mf)) || length(unique(mf$FOF_status_f)) < 2) {
    return(list(
      p = NA_real_,
      audit = tibble(
        Outcome = outcome_label,
        sex_stratum = sex_stratum,
        model = model_label,
        formula = format(formula),
        include_sex_in_model = include_sex_term,
        nobs = nrow(mf),
        n_without = n_without,
        n_with = n_with
      )
    ))
  }

  fit <- tryCatch(stats::lm(formula, data = mf), error = function(e) NULL)
  if (is.null(fit)) {
    return(list(
      p = NA_real_,
      audit = tibble(
        Outcome = outcome_label,
        sex_stratum = sex_stratum,
        model = model_label,
        formula = format(formula),
        include_sex_in_model = include_sex_term,
        nobs = nrow(mf),
        n_without = n_without,
        n_with = n_with
      )
    ))
  }

  list(
    p = extract_fof_p(fit),
    audit = tibble(
      Outcome = outcome_label,
      sex_stratum = sex_stratum,
      model = model_label,
      formula = format(formula),
      include_sex_in_model = include_sex_term,
      nobs = as.integer(stats::nobs(fit)),
      n_without = n_without,
      n_with = n_with
    )
  )
}

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(
      script = script_label,
      label = label,
      path = get_relpath(path),
      kind = kind,
      n = n,
      notes = notes
    ),
    manifest_path
  )
}

compute_sha256 <- function(path) {
  out <- tryCatch(system2("sha256sum", shQuote(path), stdout = TRUE, stderr = FALSE), error = function(e) character(0))
  if (length(out) == 0) return(NA_character_)
  trimws(strsplit(out[[1]], "\\s+")[[1]][1])
}

save_simple_html <- function(tbl, path, title, subtitle) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  header <- paste0(
    "<html><head><meta charset='UTF-8'><title>", title, "</title></head><body>",
    "<h3>", title, "</h3>",
    "<p>", subtitle, "</p><table border='1' style='border-collapse:collapse;'>"
  )
  cols <- paste0("<tr>", paste(sprintf("<th>%s</th>", names(tbl)), collapse = ""), "</tr>")
  rows <- apply(tbl, 1, function(r) {
    paste0("<tr>", paste(sprintf("<td>%s</td>", as.character(r)), collapse = ""), "</tr>")
  })
  footer <- "</table></body></html>"
  writeLines(c(header, cols, rows, footer), con = path)
  invisible(path)
}

cli <- parse_cli(commandArgs(trailingOnly = TRUE))
run_timestamp <- as.character(Sys.time())

input_path <- choose_k50_input(cli$input)
raw_excel_path <- choose_raw_excel(cli$raw_excel)
raw_csv_path <- if (!is.na(cli$raw_csv) && nzchar(cli$raw_csv)) normalizePath(cli$raw_csv, winslash = "/", mustWork = TRUE) else NA_character_
output_csv <- if (!is.na(cli$output_csv) && nzchar(cli$output_csv)) cli$output_csv else file.path(outputs_dir, "k53_table2_authoritative_wide.csv")
output_html <- if (!is.na(cli$output_html) && nzchar(cli$output_html)) cli$output_html else file.path(outputs_dir, "k53_table2_authoritative_wide.html")
output_audit <- if (!is.na(cli$output_audit) && nzchar(cli$output_audit)) cli$output_audit else file.path(outputs_dir, "k53_table2_authoritative_wide_modeln_audit.csv")
output_provenance <- if (!is.na(cli$output_provenance) && nzchar(cli$output_provenance)) cli$output_provenance else file.path(outputs_dir, "k53_table2_authoritative_wide_input_provenance.txt")
output_session <- if (!is.na(cli$output_session) && nzchar(cli$output_session)) cli$output_session else file.path(outputs_dir, "sessioninfo_K53.txt")

dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)

cat("================================================================================\n")
cat("K53: authoritative WIDE Table 2 generator\n")
cat("K50 input:", input_path, "\n")
cat("Raw workbook:", raw_excel_path, "\n")
if (!is.na(raw_csv_path)) cat("Raw CSV override:", raw_csv_path, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("================================================================================\n\n")

k50_raw <- read_k50_input(input_path)

missing_k50 <- setdiff(req_cols[1:7], names(k50_raw))
if (length(missing_k50) > 0) {
  stop("K53 K50 input is missing required columns: ", paste(missing_k50, collapse = ", "), call. = FALSE)
}

measure_raw <- read_measure_data(raw_excel_path, raw_csv_path)

k50_modeled <- k50_raw %>%
  transmute(
    id = normalize_id(.data$id),
    FOF_status = normalize_fof(.data$FOF_status),
    age = safe_num(.data$age),
    sex = as.character(.data$sex),
    BMI = safe_num(.data$BMI),
    locomotor_capacity_0 = safe_num(.data$locomotor_capacity_0),
    locomotor_capacity_12m = safe_num(.data$locomotor_capacity_12m)
  ) %>%
  mutate(
    Sex_f = normalize_sex(.data$sex),
    FOF_status_f = factor(.data$FOF_status, levels = c(0L, 1L), labels = c("Ei FOF", "FOF"))
  ) %>%
  filter(
    !is.na(.data$id),
    !is.na(.data$FOF_status),
    !is.na(.data$age),
    !is.na(.data$BMI),
    !is.na(.data$Sex_f),
    !is.na(.data$locomotor_capacity_0),
    !is.na(.data$locomotor_capacity_12m)
  )

modeled_counts <- k50_modeled %>% count(FOF_status_f, name = "n")
reported_n_without <- ifelse(any(modeled_counts$FOF_status_f == "Ei FOF"), as.integer(modeled_counts$n[modeled_counts$FOF_status_f == "Ei FOF"]), 0L)
reported_n_with <- ifelse(any(modeled_counts$FOF_status_f == "FOF"), as.integer(modeled_counts$n[modeled_counts$FOF_status_f == "FOF"]), 0L)
reported_n_total <- nrow(k50_modeled)

receipt_expectations <- list(
  modeled_total = NA_integer_,
  modeled_fof0 = NA_integer_,
  modeled_fof1 = NA_integer_
)
receipt_path <- here::here("R-scripts", "K50", "outputs", "k50_wide_locomotor_capacity_modeled_cohort_provenance.txt")
if (file.exists(receipt_path)) {
  receipt_lines <- readLines(receipt_path, warn = FALSE)
  receipt_value <- function(key) {
    hit <- receipt_lines[grepl(paste0("^", key, "="), receipt_lines)][1]
    if (is.na(hit) || !nzchar(hit)) return(NA_integer_)
    suppressWarnings(as.integer(sub(paste0("^", key, "="), "", hit)))
  }
  receipt_expectations$modeled_total <- receipt_value("modeled_n")
  receipt_expectations$modeled_fof0 <- receipt_value("modeled_fof0_n")
  receipt_expectations$modeled_fof1 <- receipt_value("modeled_fof1_n")
}

measure_df <- measure_raw %>%
  transmute(
    id = normalize_id(.data$NRO),
    SLS0 = mean_pair(.data$SLS_right0, .data$SLS_left0),
    SLS2 = mean_pair(.data$SLS_right2, .data$SLS_left2),
    FTSST0 = safe_num(.data$FTSST0),
    FTSST2 = safe_num(.data$FTSST2),
    HGS0 = mean_pair(.data$HGS_right0, .data$HGS_left0),
    HGS2 = mean_pair(.data$HGS_right2, .data$HGS_left2),
    MWS0 = seconds_to_speed(.data$MWS_seconds0),
    MWS2 = seconds_to_speed(.data$MWS_seconds2)
  )

dup_measures <- measure_df %>%
  filter(!is.na(.data$id)) %>%
  count(.data$id, name = "n") %>%
  filter(.data$n > 1L)

if (nrow(dup_measures) > 0) {
  stop("Duplicate IDs detected in K53 measure table after workbook mapping.", call. = FALSE)
}

analysis_df <- k50_modeled %>%
  left_join(measure_df, by = "id")

if (!is.na(receipt_expectations$modeled_total) && reported_n_total != receipt_expectations$modeled_total) {
  stop(
    "K53 authoritative cohort total does not match K50 provenance. Observed ",
    reported_n_total, " but provenance says ", receipt_expectations$modeled_total, ".",
    call. = FALSE
  )
}
if (!is.na(receipt_expectations$modeled_fof0) && reported_n_without != receipt_expectations$modeled_fof0) {
  stop(
    "K53 FOF=0 cohort count does not match K50 provenance. Observed ",
    reported_n_without, " but provenance says ", receipt_expectations$modeled_fof0, ".",
    call. = FALSE
  )
}
if (!is.na(receipt_expectations$modeled_fof1) && reported_n_with != receipt_expectations$modeled_fof1) {
  stop(
    "K53 FOF=1 cohort count does not match K50 provenance. Observed ",
    reported_n_with, " but provenance says ", receipt_expectations$modeled_fof1, ".",
    call. = FALSE
  )
}

join_qc <- tibble(
  modeled_total = nrow(analysis_df),
  matched_any_measure = sum(
    rowSums(!is.na(analysis_df[, c("MWS0", "MWS2", "FTSST0", "FTSST2", "SLS0", "SLS2", "HGS0", "HGS2")])) > 0
  ),
  unmatched_all_measures = sum(
    rowSums(!is.na(analysis_df[, c("MWS0", "MWS2", "FTSST0", "FTSST2", "SLS0", "SLS2", "HGS0", "HGS2")])) == 0
  ),
  mws_pair_complete = sum(!is.na(analysis_df$MWS0) & !is.na(analysis_df$MWS2)),
  ftsst_pair_complete = sum(!is.na(analysis_df$FTSST0) & !is.na(analysis_df$FTSST2)),
  sls_pair_complete = sum(!is.na(analysis_df$SLS0) & !is.na(analysis_df$SLS2)),
  hgs_pair_complete = sum(!is.na(analysis_df$HGS0) & !is.na(analysis_df$HGS2))
)

outcome_specs <- list(
  list(label = "MWS", base = "MWS0", foll = "MWS2", sex_filter = NA_character_),
  list(label = "FTSST", base = "FTSST0", foll = "FTSST2", sex_filter = NA_character_),
  list(label = "SLS", base = "SLS0", foll = "SLS2", sex_filter = NA_character_),
  list(label = "HGS (female)", base = "HGS0", foll = "HGS2", sex_filter = "female"),
  list(label = "HGS (male)", base = "HGS0", foll = "HGS2", sex_filter = "male")
)

table_rows <- list()
audit_rows <- list()

for (spec in outcome_specs) {
  d <- analysis_df %>%
    transmute(
      id = .data$id,
      FOF_status_f = .data$FOF_status_f,
      age = .data$age,
      BMI = .data$BMI,
      Sex_f = .data$Sex_f,
      baseline = .data[[spec$base]],
      followup = .data[[spec$foll]]
    )

  if (!is.na(spec$sex_filter)) {
    d <- d %>% filter(.data$Sex_f == spec$sex_filter)
  }

  d <- d %>% mutate(delta = .data$followup - .data$baseline)
  d_sum <- d %>% filter(!is.na(.data$baseline), !is.na(.data$followup), !is.na(.data$FOF_status_f))
  g0 <- d_sum %>% filter(.data$FOF_status_f == "Ei FOF")
  g1 <- d_sum %>% filter(.data$FOF_status_f == "FOF")
  row_n_without <- nrow(g0)
  row_n_with <- nrow(g1)
  row_n_total <- nrow(d_sum)

  stratified <- !is.na(spec$sex_filter)
  fA <- followup ~ FOF_status_f
  fB <- followup ~ FOF_status_f + baseline
  include_sex <- (!stratified) && (nlevels(droplevels(d$Sex_f)) > 1)
  fC <- if (include_sex) {
    followup ~ FOF_status_f + baseline + age + BMI + Sex_f
  } else {
    followup ~ FOF_status_f + baseline + age + BMI
  }

  fitA <- fit_with_audit(fA, d, spec$label, "A", ifelse(stratified, spec$sex_filter, "all"), FALSE)
  fitB <- fit_with_audit(fB, d, spec$label, "B", ifelse(stratified, spec$sex_filter, "all"), FALSE)
  fitC <- fit_with_audit(fC, d, spec$label, "C", ifelse(stratified, spec$sex_filter, "all"), include_sex)

  audit_rows[[length(audit_rows) + 1L]] <- fitA$audit
  audit_rows[[length(audit_rows) + 1L]] <- fitB$audit
  audit_rows[[length(audit_rows) + 1L]] <- fitC$audit

  table_rows[[length(table_rows) + 1L]] <- tibble(
    Outcome = spec$label,
    Without_FOF_Baseline = fmt_mean_sd(g0$baseline),
    Without_FOF_Followup = fmt_mean_sd(g0$followup),
    Without_FOF_Delta = fmt_delta_ci(g0$delta),
    With_FOF_Baseline = fmt_mean_sd(g1$baseline),
    With_FOF_Followup = fmt_mean_sd(g1$followup),
    With_FOF_Delta = fmt_delta_ci(g1$delta),
    P_Model_A = fmt_p(fitA$p),
    P_Model_B = fmt_p(fitB$p),
    P_Model_C = fmt_p(fitC$p),
    N_without = row_n_without,
    N_with = row_n_with,
    N_total = row_n_total
  )
}

table_df <- bind_rows(table_rows)
audit_df <- bind_rows(audit_rows)

cat("K53 authoritative cohort crosscheck:\n")
cat(" - Without FOF:", reported_n_without, "\n")
cat(" - With FOF   :", reported_n_with, "\n")
cat(" - Total      :", reported_n_total, "\n\n")

print(table_df, n = nrow(table_df), width = Inf)

readr::write_csv(table_df, output_csv)
readr::write_csv(audit_df, output_audit)
save_simple_html(
  table_df,
  output_html,
  title = "K53 authoritative WIDE Table 2",
  subtitle = paste0(
    "Authoritative K50 modeled cohort header: Without FOF=", reported_n_without,
    ", With FOF=", reported_n_with,
    ", Total=", reported_n_total,
    "; manuscript 77/199 anchor intentionally not used. ",
    "P-values come from follow-up ANCOVA A/B/C; change columns are observed within-group mean change with t-based 95% CI."
  )
)

provenance_lines <- c(
  paste0("script=", script_label),
  paste0("timestamp=", run_timestamp),
  paste0("run_timestamp=", run_timestamp),
  paste0("script_path=", script_path),
  paste0("script_sha256=", compute_sha256(script_path)),
  paste0("script_mtime=", as.character(file.info(script_path)$mtime)),
  paste0("authoritative_k50_input=", input_path),
  paste0("raw_measure_excel=", raw_excel_path),
  paste0("raw_measure_csv_override=", ifelse(is.na(raw_csv_path), "", raw_csv_path)),
  "authoritative_receipt=R-scripts/K50/outputs/k50_wide_locomotor_capacity_input_receipt.txt",
  "authoritative_provenance=R-scripts/K50/outputs/k50_wide_locomotor_capacity_modeled_cohort_provenance.txt",
  paste0("modeled_total=", reported_n_total),
  paste0("modeled_fof0=", reported_n_without),
  paste0("modeled_fof1=", reported_n_with),
  "header_anchor_policy=derive_from_authoritative_k50_modeled_sample",
  "manuscript_anchor_not_used=77/199",
  "structure_anchor=manuscript_table2_layout_only",
  "pvalue_models=followup_ancova_a_b_c",
  "change_columns=observed_within_group_mean_change_t_based_95ci",
  "measure_mapping=TK->baseline; 2SK->12m; MWS=10/seconds; SLS/HGS=row mean of bilateral values",
  paste0("receipt_modeled_total=", receipt_expectations$modeled_total),
  paste0("receipt_modeled_fof0=", receipt_expectations$modeled_fof0),
  paste0("receipt_modeled_fof1=", receipt_expectations$modeled_fof1),
  paste0("join_qc_duplicate_measure_ids=", nrow(dup_measures)),
  paste0("join_qc_matched_any_measure=", join_qc$matched_any_measure[[1]]),
  paste0("join_qc_unmatched_all_measures=", join_qc$unmatched_all_measures[[1]]),
  paste0("availability_mws_pair_complete=", join_qc$mws_pair_complete[[1]]),
  paste0("availability_ftsst_pair_complete=", join_qc$ftsst_pair_complete[[1]]),
  paste0("availability_sls_pair_complete=", join_qc$sls_pair_complete[[1]]),
  paste0("availability_hgs_pair_complete=", join_qc$hgs_pair_complete[[1]]),
  "model_c_note=sex omitted in sex-stratified HGS rows because sex is constant within stratum",
  "repro_note=current_termux_runtime_lacks_readxl_dependency_stack_for_direct_workbook_run_validated_via_read_only_raw_csv_bridge"
)
writeLines(provenance_lines, con = output_provenance)

session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = output_session)

append_artifact(
  label = "k53_table2_authoritative_wide_csv",
  kind = "table_csv",
  path = output_csv,
  n = nrow(table_df),
  notes = "Authoritative K50 wide Table 2 style output with 69/161 cohort header."
)
append_artifact(
  label = "k53_table2_authoritative_wide_html",
  kind = "table_html",
  path = output_html,
  n = nrow(table_df),
  notes = "Review render for authoritative K50 wide Table 2 output."
)
append_artifact(
  label = "k53_table2_authoritative_wide_modeln_audit_csv",
  kind = "qc_table_csv",
  path = output_audit,
  n = nrow(audit_df),
  notes = "Model-wise actual N audit for K53 A/B/C fits."
)
append_artifact(
  label = "k53_table2_authoritative_wide_input_provenance_txt",
  kind = "qc_text",
  path = output_provenance,
  notes = "Input/provenance receipt for K53 authoritative cohort and raw measure sources."
)
append_artifact(
  label = "sessioninfo_K53",
  kind = "sessioninfo",
  path = output_session,
  notes = "sessionInfo and renv diagnostics for K53."
)

cat("\nSaved:\n")
cat(" - ", output_csv, "\n", sep = "")
cat(" - ", output_html, "\n", sep = "")
cat(" - ", output_audit, "\n", sep = "")
cat(" - ", output_provenance, "\n", sep = "")
cat(" - ", output_session, "\n", sep = "")

# EOF
