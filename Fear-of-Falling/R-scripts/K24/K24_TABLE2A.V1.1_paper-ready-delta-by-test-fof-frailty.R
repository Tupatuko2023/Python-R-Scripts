#!/usr/bin/env Rscript
# ==============================================================================
# K24_TABLE2A - Paper-ready delta-by-test with joint FOF + frailty model
# File tag: K24_TABLE2A.V1.1_paper-ready-delta-by-test-fof-frailty.R
# Purpose: Produce paper-ready and audit versions of Table 2A from the same
#          model logic (no modeling changes vs V1).
#
# Canonical predictors/covariates:
# - FOF_status
# - frailty_cat_3 / frailty_score_3
# - tasapainovaikeus (optional)
# - age, sex, BMI
#
# Models:
# - delta = followup - baseline
# - delta ~ FOF_status + frailty + baseline + age + sex + BMI (+ balance optional)
# - HGS also reported stratified by sex (Women/Men); sex removed inside strata
#
# Outputs + manifest:
# - script_label: K24_TABLE2A
# - outputs dir: R-scripts/K24/outputs/K24_TABLE2A/
# - table2A_paper_ready_v1_1.html
# - table2A_paper_ready_v1_1.csv
# - table2A_audit_v1_1.csv
# - sessionInfo_v1_1.txt
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tibble)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K24_TABLE2A"
}
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K24_TABLE2A"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "modeling.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
manifest_path <- paths$manifest_path
outputs_dir <- here::here("R-scripts", "K24", "outputs", script_label)
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
options(fof.outputs_dir = outputs_dir, fof.manifest_path = manifest_path, fof.script = script_label)

parse_cli <- function(args) {
  out <- list(
    input = NA_character_,
    output_html = NA_character_,
    output_csv = NA_character_,
    output_audit = NA_character_,
    frailty_mode = "cat",
    include_balance = FALSE,
    balance_var = "tasapainovaikeus"
  )
  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--output_html=")) out$output_html <- sub("^--output_html=", "", arg)
    if (startsWith(arg, "--output_csv=")) out$output_csv <- sub("^--output_csv=", "", arg)
    if (startsWith(arg, "--output_audit=")) out$output_audit <- sub("^--output_audit=", "", arg)
    if (startsWith(arg, "--frailty_mode=")) out$frailty_mode <- tolower(sub("^--frailty_mode=", "", arg))
    if (startsWith(arg, "--include_balance=")) out$include_balance <- tolower(sub("^--include_balance=", "", arg)) %in% c("true", "1", "yes", "y")
    if (startsWith(arg, "--balance_var=")) out$balance_var <- sub("^--balance_var=", "", arg)
  }
  if (!out$frailty_mode %in% c("cat", "score")) stop("Invalid --frailty_mode. Use cat or score.")
  out
}

choose_input_path <- function(cli_input) {
  candidates <- c(
    if (!is.na(cli_input) && nzchar(cli_input)) cli_input else character(0),
    here::here("data", "external", "KaatumisenPelko.csv"),
    here::here("data", "external", "kaatumisenpelko.csv"),
    here::here("data", "kaatumisenpelko.csv")
  )
  hit <- candidates[file.exists(candidates)][1]
  if (is.na(hit) || !nzchar(hit)) {
    stop("Input data not found. Provide --input=/path/to/KaatumisenPelko.csv")
  }
  normalizePath(hit, winslash = "/", mustWork = TRUE)
}

normalize_sex <- function(x) {
  x_chr <- tolower(trimws(as.character(x)))
  female_set <- c("0", "2", "f", "female", "woman", "nainen")
  male_set <- c("1", "m", "male", "man", "mies")
  out <- rep(NA_character_, length(x_chr))
  out[x_chr %in% female_set] <- "Women"
  out[x_chr %in% male_set] <- "Men"
  factor(out, levels = c("Women", "Men"))
}

normalize_fof <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  if (is.numeric(x) || is.integer(x)) {
    return(factor(ifelse(x == 1, "FOF", "Ei FOF"), levels = c("Ei FOF", "FOF")))
  }
  xc <- tolower(trimws(as.character(x)))
  out <- ifelse(xc %in% c("1", "fof", "with fof"), "FOF",
                ifelse(xc %in% c("0", "ei fof", "nonfof", "without fof"), "Ei FOF", NA_character_))
  factor(out, levels = c("Ei FOF", "FOF"))
}

normalize_frailty_cat <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  xc <- tolower(trimws(as.character(x)))
  out <- dplyr::case_when(
    xc %in% c("robust", "0") ~ "robust",
    xc %in% c("pre-frail", "prefrail", "1") ~ "pre-frail",
    xc %in% c("frail", "2", "3") ~ "frail",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("robust", "pre-frail", "frail"))
}

first_existing <- function(df, candidates) {
  hit <- candidates[candidates %in% names(df)]
  if (length(hit) == 0) return(NA_character_)
  hit[1]
}

fmt_mean_sd <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return("NA")
  sprintf("%.2f (%.2f)", mean(x), stats::sd(x))
}

fmt_mean_sd_n <- function(x, n) {
  sprintf("N=%d, %s", n, fmt_mean_sd(x))
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

fmt_delta_ci_n <- function(x, n) {
  sprintf("N=%d, %s", n, fmt_delta_ci(x))
}

fmt_p <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

extract_term <- function(model, term) {
  sm <- summary(model)$coefficients
  rn <- rownames(sm)
  idx <- grep(term, rn, fixed = TRUE)
  if (length(idx) == 0) return(list(beta = NA_real_, lcl = NA_real_, ucl = NA_real_, p = NA_real_))
  i <- idx[1]
  est <- sm[i, "Estimate"]
  se <- sm[i, "Std. Error"]
  p <- sm[i, grep("Pr\\(>|t\\|\\)", colnames(sm), value = TRUE)[1]]
  list(beta = est, lcl = est - 1.96 * se, ucl = est + 1.96 * se, p = p)
}

frailty_overall_p <- function(model, term_prefix) {
  if (requireNamespace("car", quietly = TRUE)) {
    sm <- summary(model)$coefficients
    rn <- rownames(sm)
    frail_terms <- rn[grepl(paste0("^", term_prefix), rn)]
    if (length(frail_terms) == 0) return(NA_real_)
    L <- tryCatch(car::linearHypothesis(model, frail_terms), error = function(e) NULL)
    if (is.null(L) || nrow(L) < 2) return(NA_real_)
    p_col <- grep("Pr\\(>F\\)", colnames(L), value = TRUE)[1]
    if (is.na(p_col) || is.null(p_col)) return(NA_real_)
    return(as.numeric(L[2, p_col]))
  }
  a <- stats::anova(model)
  p_col <- grep("Pr\\(>F\\)", names(a), value = TRUE)[1]
  idx <- which(rownames(a) == term_prefix)
  if (length(idx) == 0 || is.na(p_col)) return(NA_real_)
  as.numeric(a[idx[1], p_col])
}

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(script = script_label, label = label, path = get_relpath(path), kind = kind, n = n, notes = notes),
    manifest_path
  )
}

cli <- parse_cli(commandArgs(trailingOnly = TRUE))
input_path <- choose_input_path(cli$input)
output_html <- if (!is.na(cli$output_html) && nzchar(cli$output_html)) cli$output_html else file.path(outputs_dir, "table2A_paper_ready_v1_1.html")
output_csv <- if (!is.na(cli$output_csv) && nzchar(cli$output_csv)) cli$output_csv else file.path(outputs_dir, "table2A_paper_ready_v1_1.csv")
output_audit <- if (!is.na(cli$output_audit) && nzchar(cli$output_audit)) cli$output_audit else file.path(outputs_dir, "table2A_audit_v1_1.csv")
session_path <- file.path(outputs_dir, "sessionInfo_v1_1.txt")

raw_data <- readr::read_csv(input_path, show_col_types = FALSE)

# Canonical mapping block (prefer canonical, fallback to known raw columns)
col_id <- first_existing(raw_data, c("id", "NRO"))
col_age <- first_existing(raw_data, c("age"))
col_sex <- first_existing(raw_data, c("sex"))
col_bmi <- first_existing(raw_data, c("BMI"))
col_fof <- first_existing(raw_data, c("FOF_status", "kaatumisenpelkoOn"))
col_frailty_cat <- first_existing(raw_data, c("frailty_cat_3"))
col_frailty_score <- first_existing(raw_data, c("frailty_score_3", "frailty_count_3"))
col_balance <- if (!is.na(cli$balance_var) && nzchar(cli$balance_var) && cli$balance_var %in% names(raw_data)) cli$balance_var else first_existing(raw_data, c("tasapainovaikeus"))

if (any(is.na(c(col_id, col_age, col_sex, col_bmi, col_fof)))) {
  stop("Missing mandatory canonical inputs (id/age/sex/BMI/FOF_status mapping).")
}

if (is.na(col_frailty_cat) && is.na(col_frailty_score)) {
  # deterministic fallback: derive frailty_score_3 from three morbidity indicators if present
  morbidity_cols <- c("diabetes", "alzheimer", "parkinson")
  if (all(morbidity_cols %in% names(raw_data))) {
    raw_data <- raw_data %>%
      mutate(
        frailty_score_3 = rowSums(across(all_of(morbidity_cols), ~ as.numeric(.x == 1)), na.rm = TRUE),
        frailty_cat_3 = case_when(
          frailty_score_3 == 0 ~ "robust",
          frailty_score_3 == 1 ~ "pre-frail",
          frailty_score_3 >= 2 ~ "frail",
          TRUE ~ NA_character_
        )
      )
    col_frailty_cat <- "frailty_cat_3"
    col_frailty_score <- "frailty_score_3"
  } else {
    stop("Missing frailty canonical variables and fallback morbidity columns unavailable.")
  }
}

outcome_map <- list(
  MWS = list(base = first_existing(raw_data, c("MWS0", "kavelynopeus_m_sek0")), foll = first_existing(raw_data, c("MWS12", "MWS2", "kavelynopeus_m_sek2"))),
  FTSST = list(base = first_existing(raw_data, c("FTSST0", "Tuoli0", "tuoliltanousu0")), foll = first_existing(raw_data, c("FTSST12", "FTSST2", "Tuoli2", "tuoliltanousu2"))),
  SLS = list(base = first_existing(raw_data, c("SLS0", "Seisominen0")), foll = first_existing(raw_data, c("SLS12", "SLS2", "Seisominen2"))),
  HGS = list(base = first_existing(raw_data, c("HGS0", "Puristus0")), foll = first_existing(raw_data, c("HGS12", "HGS2", "Puristus2")))
)
bad_outcomes <- names(outcome_map)[vapply(outcome_map, function(x) any(is.na(c(x$base, x$foll))), logical(1))]
if (length(bad_outcomes) > 0) stop("Missing baseline/followup columns for outcomes: ", paste(bad_outcomes, collapse = ", "))

analysis_base <- raw_data %>%
  transmute(
    id = .data[[col_id]],
    age = suppressWarnings(as.numeric(.data[[col_age]])),
    BMI = suppressWarnings(as.numeric(.data[[col_bmi]])),
    sex = normalize_sex(.data[[col_sex]]),
    FOF_status = normalize_fof(.data[[col_fof]]),
    frailty_cat_3 = if (!is.na(col_frailty_cat)) normalize_frailty_cat(.data[[col_frailty_cat]]) else NA,
    frailty_score_3 = if (!is.na(col_frailty_score)) suppressWarnings(as.numeric(.data[[col_frailty_score]])) else NA_real_,
    tasapainovaikeus = if (!is.na(col_balance)) suppressWarnings(as.numeric(.data[[col_balance]])) else NA_real_
  )

if (nlevels(droplevels(analysis_base$FOF_status)) != 2) stop("FOF_status must have exactly two levels.")
if (cli$frailty_mode == "cat" && nlevels(droplevels(analysis_base$frailty_cat_3)) < 2) stop("frailty_cat_3 has <2 levels.")
if (cli$frailty_mode == "score" && all(is.na(analysis_base$frailty_score_3))) stop("frailty_score_3 unavailable for score mode.")

rows <- list()
for (nm in c("MWS", "FTSST", "SLS", "HGS", "HGS (Women)", "HGS (Men)")) {
  base_name <- if (grepl("^HGS", nm)) outcome_map$HGS$base else outcome_map[[nm]]$base
  foll_name <- if (grepl("^HGS", nm)) outcome_map$HGS$foll else outcome_map[[nm]]$foll
  d <- analysis_base %>%
    mutate(
      baseline = suppressWarnings(as.numeric(raw_data[[base_name]])),
      followup = suppressWarnings(as.numeric(raw_data[[foll_name]])),
      delta = followup - baseline
    )

  if (nm == "HGS (Women)") d <- d %>% filter(sex == "Women")
  if (nm == "HGS (Men)") d <- d %>% filter(sex == "Men")

  if (nm == "FTSST") {
    x <- c(d$baseline, d$followup)
    x <- x[!is.na(x)]
    if (length(x) > 0) {
      cond <- (max(x) <= 0) || (mean(x <= 0) > 0.5)
      if (isTRUE(cond)) d <- d %>% mutate(baseline = -baseline, followup = -followup, delta = followup - baseline)
    }
  }

  g0 <- d %>% filter(FOF_status == "Ei FOF", !is.na(baseline), !is.na(followup))
  g1 <- d %>% filter(FOF_status == "FOF", !is.na(baseline), !is.na(followup))
  n_without <- nrow(g0)
  n_with <- nrow(g1)

  covars <- c("baseline", "age", "BMI")
  if (!(nm %in% c("HGS (Women)", "HGS (Men)"))) covars <- c(covars, "sex")
  if (cli$include_balance && !all(is.na(d$tasapainovaikeus))) covars <- c(covars, "tasapainovaikeus")

  frailty_term <- if (cli$frailty_mode == "cat") "frailty_cat_3" else "frailty_score_3"
  form <- as.formula(paste("delta ~ FOF_status +", frailty_term, "+", paste(covars, collapse = " + ")))
  model_df <- d %>% select(delta, FOF_status, all_of(frailty_term), all_of(covars))
  fit <- lm(form, data = model_df)
  n_model <- as.integer(stats::nobs(fit))

  fof_term <- extract_term(fit, "FOF_statusFOF")
  frailty_p <- if (cli$frailty_mode == "cat") frailty_overall_p(fit, "frailty_cat_3") else extract_term(fit, "frailty_score_3")$p

  frailty_contrasts <- if (cli$frailty_mode == "cat") {
    sm <- summary(fit)$coefficients
    rn <- rownames(sm)
    idx <- grep("^frailty_cat_3", rn)
    if (length(idx) == 0) "" else {
      pcol <- grep("Pr\\(>|t\\|\\)", colnames(sm), value = TRUE)[1]
      ptxt <- vapply(sm[idx, pcol], fmt_p, character(1))
      paste(sprintf("%s: b=%.3f, p=%s", rn[idx], sm[idx, "Estimate"], ptxt), collapse = " | ")
    }
  } else {
    fs <- extract_term(fit, "frailty_score_3")
    sprintf("frailty_score_3: b=%.3f, p=%s", fs$beta, fmt_p(fs$p))
  }

  rows[[length(rows) + 1L]] <- tibble(
    Outcome = nm,
    Frailty_Mode = cli$frailty_mode,
    Balance_Included = cli$include_balance,
    Without_FOF_Baseline = fmt_mean_sd_n(g0$baseline, n_without),
    With_FOF_Baseline = fmt_mean_sd_n(g1$baseline, n_with),
    Without_FOF_Delta = fmt_delta_ci_n(g0$delta, n_without),
    With_FOF_Delta = fmt_delta_ci_n(g1$delta, n_with),
    FOF_Beta_CI = ifelse(is.na(fof_term$beta), "", sprintf("%.3f [%.3f, %.3f]", fof_term$beta, fof_term$lcl, fof_term$ucl)),
    P_FOF = fmt_p(fof_term$p),
    P_Frailty_Overall = fmt_p(frailty_p),
    Frailty_Contrasts = frailty_contrasts,
    Model_N = n_model,
    N_without = n_without,
    N_with = n_with
  )
}

audit_df <- bind_rows(rows)
paper_df <- audit_df %>%
  filter(Outcome != "HGS") %>%
  select(
    Outcome, Frailty_Mode, Balance_Included,
    N_without, N_with,
    Without_FOF_Baseline, With_FOF_Baseline,
    Without_FOF_Delta, With_FOF_Delta,
    FOF_Beta_CI, P_FOF, P_Frailty_Overall, Model_N
  )

cat("K24 V1.1 audit preview:\n")
print(audit_df, n = nrow(audit_df), width = Inf)
cat("\nK24 V1.1 paper preview:\n")
print(paper_df, n = nrow(paper_df), width = Inf)

readr::write_csv(paper_df, output_csv)
readr::write_csv(audit_df, output_audit)
append_artifact(
  label = "table2A_paper_ready_v1_1_csv",
  kind = "table_csv",
  path = output_csv,
  n = nrow(paper_df),
  notes = "K24 Table 2A paper-ready CSV (no pooled HGS, contrasts omitted)"
)
append_artifact(
  label = "table2A_audit_v1_1_csv",
  kind = "qc_table_csv",
  path = output_audit,
  n = nrow(audit_df),
  notes = "K24 Table 2A audit CSV (includes pooled HGS + frailty contrasts)"
)

if (!requireNamespace("gt", quietly = TRUE)) stop("Package 'gt' required for HTML output.")
tbl_gt <- gt::gt(paper_df) %>%
  gt::tab_header(
    title = gt::md("**Table 2A (paper-ready) - Delta by test with FOF + frailty**"),
    subtitle = paste0(
      "No pooled HGS row. Group Ns shown in columns and cell text. ",
      "frailty_mode=", cli$frailty_mode, ", include_balance=", cli$include_balance
    )
  )
gt::gtsave(tbl_gt, filename = output_html)
append_artifact(
  label = "table2A_paper_ready_v1_1_html",
  kind = "table_html",
  path = output_html,
  n = nrow(paper_df),
  notes = "K24 Table 2A paper-ready HTML (no pooled HGS)"
)

session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = session_path)
append_artifact(
  label = "sessionInfo_v1_1",
  kind = "sessioninfo",
  path = session_path,
  notes = "K24 V1.1 sessionInfo + renv diagnostics"
)

cat("\nSaved:\n")
cat(" - ", output_html, "\n", sep = "")
cat(" - ", output_csv, "\n", sep = "")
cat(" - ", output_audit, "\n", sep = "")
cat(" - ", session_path, "\n", sep = "")
