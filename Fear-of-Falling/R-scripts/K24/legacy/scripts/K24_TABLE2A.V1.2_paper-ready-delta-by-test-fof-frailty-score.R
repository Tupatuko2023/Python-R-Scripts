#!/usr/bin/env Rscript
# ==============================================================================
# K24_TABLE2A - Paper-ready delta-by-test with frailty score sensitivity
# File tag: K24_TABLE2A.V1.2_paper-ready-delta-by-test-fof-frailty-score.R
# Purpose: V1.2 sensitivity run using frailty_score_3 (+1 unit) and produce:
# - paper-ready score table (no pooled HGS)
# - audit score table (includes pooled HGS)
# - cat vs score comparison QC table (AIC + frailty effects + agreement flag)
#
# Canonical predictors/covariates:
# - FOF_status
# - frailty_cat_3 / frailty_score_3
# - tasapainovaikeus (optional)
# - age, sex, BMI
#
# Model:
# - delta = followup - baseline
# - score model: delta ~ FOF_status + frailty_score_3 + baseline + age + sex + BMI (+ optional balance)
# - HGS also reported stratified by sex (Women/Men); sex removed inside strata
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
    output_compare = NA_character_,
    include_balance = FALSE,
    balance_var = "tasapainovaikeus"
  )
  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--output_html=")) out$output_html <- sub("^--output_html=", "", arg)
    if (startsWith(arg, "--output_csv=")) out$output_csv <- sub("^--output_csv=", "", arg)
    if (startsWith(arg, "--output_audit=")) out$output_audit <- sub("^--output_audit=", "", arg)
    if (startsWith(arg, "--output_compare=")) out$output_compare <- sub("^--output_compare=", "", arg)
    if (startsWith(arg, "--include_balance=")) out$include_balance <- tolower(sub("^--include_balance=", "", arg)) %in% c("true", "1", "yes", "y")
    if (startsWith(arg, "--balance_var=")) out$balance_var <- sub("^--balance_var=", "", arg)
  }
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

fmt_num <- function(x, digits = 3) {
  if (is.na(x)) return("")
  sprintf(paste0("%.", digits, "f"), x)
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

frailty_cat_contrasts <- function(model) {
  sm <- summary(model)$coefficients
  rn <- rownames(sm)
  idx <- grep("^frailty_cat_3", rn)
  if (length(idx) == 0) return("")
  pcol <- grep("Pr\\(>|t\\|\\)", colnames(sm), value = TRUE)[1]
  ptxt <- vapply(sm[idx, pcol], fmt_p, character(1))
  paste(sprintf("%s: b=%.3f, p=%s", rn[idx], sm[idx, "Estimate"], ptxt), collapse = " | ")
}

score_dist_string <- function(x) {
  xs <- suppressWarnings(as.numeric(x))
  xs <- xs[!is.na(xs)]
  if (length(xs) == 0) return("none")
  keys <- c(0, 1, 2, 3)
  cnt <- vapply(keys, function(k) sum(xs == k, na.rm = TRUE), integer(1))
  other <- sum(!xs %in% keys)
  paste0("0=", cnt[1], ";1=", cnt[2], ";2=", cnt[3], ";3=", cnt[4], ";other=", other)
}

agreement_flag <- function(beta_score, p_score, beta_prefrail, p_prefrail, beta_frail, p_frail,
                           eps = 0.05) {
  cat_available <- !(is.na(beta_prefrail) && is.na(beta_frail))
  if (!cat_available) return("insufficient_levels")

  no_clear_score <- !is.na(p_score) && p_score >= 0.05
  no_clear_cat <- TRUE
  cat_ps <- c(p_prefrail, p_frail)
  cat_ps <- cat_ps[!is.na(cat_ps)]
  if (length(cat_ps) > 0) no_clear_cat <- all(cat_ps >= 0.05)

  if (no_clear_score && no_clear_cat) return("consistent_no_clear_association")

  dirs <- c(sign(beta_prefrail), sign(beta_frail))
  dirs <- dirs[!is.na(dirs) & dirs != 0]
  if (is.na(beta_score) || beta_score == 0 || length(dirs) == 0) return("insufficient_levels")

  if (all(dirs == sign(beta_score))) return("consistent")
  "inconsistent"
}

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(script = script_label, label = label, path = get_relpath(path), kind = kind, n = n, notes = notes),
    manifest_path
  )
}

cli <- parse_cli(commandArgs(trailingOnly = TRUE))
input_path <- choose_input_path(cli$input)
output_html <- if (!is.na(cli$output_html) && nzchar(cli$output_html)) cli$output_html else file.path(outputs_dir, "table2A_paper_ready_score_v1_2.html")
output_csv <- if (!is.na(cli$output_csv) && nzchar(cli$output_csv)) cli$output_csv else file.path(outputs_dir, "table2A_paper_ready_score_v1_2.csv")
output_audit <- if (!is.na(cli$output_audit) && nzchar(cli$output_audit)) cli$output_audit else file.path(outputs_dir, "table2A_audit_score_v1_2.csv")
output_compare <- if (!is.na(cli$output_compare) && nzchar(cli$output_compare)) cli$output_compare else file.path(outputs_dir, "table2A_cat_vs_score_compare_v1_2.csv")
session_path <- file.path(outputs_dir, "sessionInfo_v1_2.txt")

raw_data <- readr::read_csv(input_path, show_col_types = FALSE)

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
if (all(is.na(analysis_base$frailty_score_3))) stop("frailty_score_3 is all NA; cannot run score-mode sensitivity.")

all_score <- analysis_base$frailty_score_3[!is.na(analysis_base$frailty_score_3)]
if (length(all_score) == 0) stop("frailty_score_3 has no non-missing observations.")

rows <- list()
compare_rows <- list()

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

  model_df <- d %>%
    select(delta, FOF_status, frailty_score_3, frailty_cat_3, all_of(covars))

  score_keep <- c("delta", "FOF_status", "frailty_score_3", covars)
  model_df_score <- model_df %>% select(all_of(score_keep)) %>% tidyr::drop_na()

  form_score <- as.formula(paste("delta ~ FOF_status + frailty_score_3 +", paste(covars, collapse = " + ")))
  fit_score <- lm(form_score, data = model_df_score)
  n_model <- as.integer(stats::nobs(fit_score))

  fof_term <- extract_term(fit_score, "FOF_statusFOF")
  frailty_score_term <- extract_term(fit_score, "frailty_score_3")

  rows[[length(rows) + 1L]] <- tibble(
    Outcome = nm,
    Frailty_Mode = "score",
    Balance_Included = cli$include_balance,
    Without_FOF_Baseline = fmt_mean_sd_n(g0$baseline, n_without),
    With_FOF_Baseline = fmt_mean_sd_n(g1$baseline, n_with),
    Without_FOF_Delta = fmt_delta_ci_n(g0$delta, n_without),
    With_FOF_Delta = fmt_delta_ci_n(g1$delta, n_with),
    FOF_Beta_CI = ifelse(is.na(fof_term$beta), "", sprintf("%.3f [%.3f, %.3f]", fof_term$beta, fof_term$lcl, fof_term$ucl)),
    P_FOF = fmt_p(fof_term$p),
    Frailty_Score_Beta_CI = ifelse(is.na(frailty_score_term$beta), "", sprintf("%.3f [%.3f, %.3f]", frailty_score_term$beta, frailty_score_term$lcl, frailty_score_term$ucl)),
    P_Frailty_Overall = fmt_p(frailty_score_term$p),
    Model_N = n_model,
    N_without = n_without,
    N_with = n_with
  )

  cat_keep <- c("delta", "FOF_status", "frailty_cat_3", covars)
  model_df_cat <- model_df %>% select(all_of(cat_keep)) %>% tidyr::drop_na()

  fit_cat <- NULL
  aic_cat <- NA_real_
  frail_pre <- list(beta = NA_real_, lcl = NA_real_, ucl = NA_real_, p = NA_real_)
  frail_fra <- list(beta = NA_real_, lcl = NA_real_, ucl = NA_real_, p = NA_real_)
  frailty_cat_p <- NA_real_
  cat_contrasts <- ""
  cat_status <- "ok"

  if (nrow(model_df_cat) > 0 && nlevels(droplevels(model_df_cat$frailty_cat_3)) >= 2) {
    form_cat <- as.formula(paste("delta ~ FOF_status + frailty_cat_3 +", paste(covars, collapse = " + ")))
    fit_cat <- lm(form_cat, data = model_df_cat)
    aic_cat <- AIC(fit_cat)
    frail_pre <- extract_term(fit_cat, "frailty_cat_3pre-frail")
    frail_fra <- extract_term(fit_cat, "frailty_cat_3frail")
    frailty_cat_p <- frailty_overall_p(fit_cat, "frailty_cat_3")
    cat_contrasts <- frailty_cat_contrasts(fit_cat)
  } else {
    cat_status <- "insufficient_levels"
  }

  score_dist_all <- score_dist_string(model_df$frailty_score_3)
  score_dist_row <- score_dist_string(model_df_score$frailty_score_3)

  agree <- agreement_flag(
    beta_score = frailty_score_term$beta,
    p_score = frailty_score_term$p,
    beta_prefrail = frail_pre$beta,
    p_prefrail = frail_pre$p,
    beta_frail = frail_fra$beta,
    p_frail = frail_fra$p
  )
  if (cat_status == "insufficient_levels") agree <- "insufficient_levels"

  compare_rows[[length(compare_rows) + 1L]] <- tibble(
    Outcome = nm,
    N_model_score = n_model,
    N_model_cat = if (!is.null(fit_cat)) as.integer(stats::nobs(fit_cat)) else NA_integer_,
    AIC_score = AIC(fit_score),
    AIC_cat = aic_cat,
    FOF_beta_score = fmt_num(fof_term$beta),
    FOF_p_score = fmt_p(fof_term$p),
    Frailty_score_beta = fmt_num(frailty_score_term$beta),
    Frailty_score_lcl = fmt_num(frailty_score_term$lcl),
    Frailty_score_ucl = fmt_num(frailty_score_term$ucl),
    Frailty_score_p = fmt_p(frailty_score_term$p),
    Frailty_cat_prefrail_beta = fmt_num(frail_pre$beta),
    Frailty_cat_prefrail_lcl = fmt_num(frail_pre$lcl),
    Frailty_cat_prefrail_ucl = fmt_num(frail_pre$ucl),
    Frailty_cat_prefrail_p = fmt_p(frail_pre$p),
    Frailty_cat_frail_beta = fmt_num(frail_fra$beta),
    Frailty_cat_frail_lcl = fmt_num(frail_fra$lcl),
    Frailty_cat_frail_ucl = fmt_num(frail_fra$ucl),
    Frailty_cat_frail_p = fmt_p(frail_fra$p),
    Frailty_cat_overall_p = fmt_p(frailty_cat_p),
    Frailty_cat_contrasts = cat_contrasts,
    Frailty_score_dist_all = score_dist_all,
    Frailty_score_dist_model = score_dist_row,
    Frailty_score_min = suppressWarnings(min(model_df$frailty_score_3, na.rm = TRUE)),
    Frailty_score_max = suppressWarnings(max(model_df$frailty_score_3, na.rm = TRUE)),
    Agreement_Flag = agree
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
    FOF_Beta_CI, P_FOF,
    Frailty_Score_Beta_CI, P_Frailty_Overall,
    Model_N
  )

compare_df <- bind_rows(compare_rows)

cat("K24 V1.2 audit preview:\n")
print(audit_df, n = nrow(audit_df), width = Inf)
cat("\nK24 V1.2 paper preview:\n")
print(paper_df, n = nrow(paper_df), width = Inf)
cat("\nK24 V1.2 compare preview:\n")
print(compare_df, n = nrow(compare_df), width = Inf)

readr::write_csv(paper_df, output_csv)
readr::write_csv(audit_df, output_audit)
readr::write_csv(compare_df, output_compare)

append_artifact(
  label = "table2A_paper_ready_score_v1_2_csv",
  kind = "table_csv",
  path = output_csv,
  n = nrow(paper_df),
  notes = "K24 Table 2A paper-ready score-mode CSV (no pooled HGS)"
)
append_artifact(
  label = "table2A_audit_score_v1_2_csv",
  kind = "qc_table_csv",
  path = output_audit,
  n = nrow(audit_df),
  notes = "K24 Table 2A audit score-mode CSV (includes pooled HGS)"
)
append_artifact(
  label = "table2A_cat_vs_score_compare_v1_2_csv",
  kind = "qc_table_csv",
  path = output_compare,
  n = nrow(compare_df),
  notes = "K24 cat vs score frailty comparison (AIC + effects + agreement flag)"
)

if (!requireNamespace("gt", quietly = TRUE)) stop("Package 'gt' required for HTML output.")
tbl_gt <- gt::gt(paper_df) %>%
  gt::tab_header(
    title = gt::md("**Table 2A (paper-ready, score sensitivity V1.2)**"),
    subtitle = paste0(
      "No pooled HGS row. Frailty modeled as continuous per +1 score. ",
      "Group Ns shown in columns and cell text. include_balance=", cli$include_balance
    )
  )
gt::gtsave(tbl_gt, filename = output_html)
append_artifact(
  label = "table2A_paper_ready_score_v1_2_html",
  kind = "table_html",
  path = output_html,
  n = nrow(paper_df),
  notes = "K24 Table 2A paper-ready score-mode HTML (no pooled HGS)"
)

session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = session_path)
append_artifact(
  label = "sessionInfo_v1_2",
  kind = "sessioninfo",
  path = session_path,
  notes = "K24 V1.2 sessionInfo + renv diagnostics"
)

cat("\nSaved:\n")
cat(" - ", output_html, "\n", sep = "")
cat(" - ", output_csv, "\n", sep = "")
cat(" - ", output_audit, "\n", sep = "")
cat(" - ", output_compare, "\n", sep = "")
cat(" - ", session_path, "\n", sep = "")
