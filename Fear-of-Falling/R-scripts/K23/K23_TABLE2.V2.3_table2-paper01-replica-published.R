#!/usr/bin/env Rscript
# ==============================================================================
# K23_TABLE2 - Paper_01 Table 2 published replica (V2.3)
# File tag: K23_TABLE2.V2.3_table2-paper01-replica-published.R
# Purpose: Reproduce published-style Table 2 reporting:
# - raw population anchor N shown as fixed header (77/199 expected on manuscript data)
# - p-values from delta models A/B/C
# - transparent model-wise N in separate audit CSV
#
# Models (DV = delta = followup - baseline):
# - A: delta ~ FOF_status_f
# - B: delta ~ FOF_status_f + baseline
# - C: delta ~ FOF_status_f + baseline + age + BMI + Sex_f
#   * Sex_f included only when non-stratified and >1 level in model data
#
# Outputs + manifest:
# - table2_paper01_v2_3_replica.html
# - table2_paper01_v2_3_replica.csv
# - table2_paper01_v2_3_modelN_audit.csv
# - sessionInfo_v2_3.txt
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
  "K23_TABLE2"
}
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K23_TABLE2"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "checks.R"))
source(here::here("R", "functions", "modeling.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
manifest_path <- paths$manifest_path
outputs_dir <- here::here("R-scripts", "K23", "outputs", script_label)
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
options(fof.outputs_dir = outputs_dir, fof.manifest_path = manifest_path, fof.script = script_label)

parse_cli <- function(args) {
  out <- list(
    input = NA_character_,
    output_html = NA_character_,
    output_csv = NA_character_,
    output_audit = NA_character_
  )
  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--output_html=")) out$output_html <- sub("^--output_html=", "", arg)
    if (startsWith(arg, "--output_csv=")) out$output_csv <- sub("^--output_csv=", "", arg)
    if (startsWith(arg, "--output_audit=")) out$output_audit <- sub("^--output_audit=", "", arg)
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
    stop(
      "Input data not found. Tried:\n",
      paste0(" - ", unique(candidates), collapse = "\n"),
      "\nProvide --input=/path/to/KaatumisenPelko.csv"
    )
  }
  normalizePath(hit, winslash = "/", mustWork = TRUE)
}

normalize_sex <- function(x) {
  x_chr <- tolower(trimws(as.character(x)))
  female_set <- c("0", "2", "f", "female", "woman", "nainen")
  male_set <- c("1", "m", "male", "man", "mies")

  out <- rep(NA_character_, length(x_chr))
  out[x_chr %in% female_set] <- "female"
  out[x_chr %in% male_set] <- "male"

  unknown <- sort(unique(x_chr[!(x_chr %in% c(female_set, male_set, "", "na", "nan"))]))
  if (length(unknown) > 0) {
    warning("Unknown sex values mapped to NA: ", paste(unknown, collapse = ", "))
  }
  factor(out, levels = c("female", "male"))
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
  a <- stats::anova(model)
  p_col <- grep("Pr\\(>F\\)", names(a), value = TRUE)[1]
  if (is.na(p_col) || is.null(p_col)) return(NA_real_)
  rn <- rownames(a)
  idx <- which(rn == "FOF_status_f")
  if (length(idx) == 0) idx <- grep("^FOF_status_f", rn)
  if (length(idx) == 0) return(NA_real_)
  as.numeric(a[idx[1], p_col])
}

fit_with_audit <- function(formula, dat, outcome_label, model_label, dv_mode, pop_mode, sex_stratum, include_sex_term) {
  mf <- tryCatch(stats::model.frame(formula, data = dat, na.action = stats::na.omit), error = function(e) NULL)
  if (is.null(mf) || nrow(mf) == 0) {
    return(list(
      p = NA_real_,
      audit = tibble(
        Outcome = outcome_label,
        sex_stratum = sex_stratum,
        population_mode = pop_mode,
        dv_mode = dv_mode,
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
  n_without <- as.integer(ifelse("Ei FOF" %in% names(n_tbl), n_tbl[["Ei FOF"]], 0))
  n_with <- as.integer(ifelse("FOF" %in% names(n_tbl), n_tbl[["FOF"]], 0))

  if (!("FOF_status_f" %in% names(mf)) || length(unique(mf$FOF_status_f)) < 2) {
    return(list(
      p = NA_real_,
      audit = tibble(
        Outcome = outcome_label,
        sex_stratum = sex_stratum,
        population_mode = pop_mode,
        dv_mode = dv_mode,
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
        population_mode = pop_mode,
        dv_mode = dv_mode,
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
      population_mode = pop_mode,
      dv_mode = dv_mode,
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

cli <- parse_cli(commandArgs(trailingOnly = TRUE))
input_path <- choose_input_path(cli$input)
output_html <- if (!is.na(cli$output_html) && nzchar(cli$output_html)) cli$output_html else file.path(outputs_dir, "table2_paper01_v2_3_replica.html")
output_csv <- if (!is.na(cli$output_csv) && nzchar(cli$output_csv)) cli$output_csv else file.path(outputs_dir, "table2_paper01_v2_3_replica.csv")
output_audit <- if (!is.na(cli$output_audit) && nzchar(cli$output_audit)) cli$output_audit else file.path(outputs_dir, "table2_paper01_v2_3_modelN_audit.csv")
session_path <- file.path(outputs_dir, "sessionInfo_v2_3.txt")

dir.create(dirname(output_html), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(output_audit), recursive = TRUE, showWarnings = FALSE)

cat("================================================================================\n")
cat("K23_TABLE2 V2.3: published replica\n")
cat("Input:", input_path, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("================================================================================\n\n")

raw_data <- readr::read_csv(input_path, show_col_types = FALSE)
df_std <- standardize_analysis_vars(raw_data)
qc <- sanity_checks(df_std)
print(qc)

required <- c(
  "id", "kaatumisenpelkoOn", "age", "sex", "BMI",
  "ToimintaKykySummary0", "ToimintaKykySummary2",
  "Puristus0", "Puristus2",
  "kavelynopeus_m_sek0", "kavelynopeus_m_sek2",
  "Tuoli0", "Tuoli2",
  "Seisominen0", "Seisominen2"
)
missing_cols <- setdiff(required, names(raw_data))
if (length(missing_cols) > 0) stop("Missing required columns: ", paste(missing_cols, collapse = ", "))

base_dat <- raw_data %>%
  transmute(
    id = .data$id,
    fof = suppressWarnings(as.numeric(.data$kaatumisenpelkoOn)),
    FOF_status_f = factor(fof, levels = c(0, 1), labels = c("Ei FOF", "FOF")),
    age = suppressWarnings(as.numeric(.data$age)),
    BMI = suppressWarnings(as.numeric(.data$BMI)),
    Sex_f = normalize_sex(.data$sex),
    Composite0 = suppressWarnings(as.numeric(.data$ToimintaKykySummary0)),
    Composite2 = suppressWarnings(as.numeric(.data$ToimintaKykySummary2)),
    HGS0 = suppressWarnings(as.numeric(.data$Puristus0)),
    HGS2 = suppressWarnings(as.numeric(.data$Puristus2)),
    MWS0 = suppressWarnings(as.numeric(.data$kavelynopeus_m_sek0)),
    MWS2 = suppressWarnings(as.numeric(.data$kavelynopeus_m_sek2)),
    FTSST0 = suppressWarnings(as.numeric(.data$Tuoli0)),
    FTSST2 = suppressWarnings(as.numeric(.data$Tuoli2)),
    SLS0 = suppressWarnings(as.numeric(.data$Seisominen0)),
    SLS2 = suppressWarnings(as.numeric(.data$Seisominen2))
  )

raw_pop <- !is.na(base_dat$FOF_status_f)
raw_counts <- base_dat %>% filter(raw_pop) %>% count(FOF_status_f, name = "n")
reported_n_without <- ifelse(any(raw_counts$FOF_status_f == "Ei FOF"), as.integer(raw_counts$n[raw_counts$FOF_status_f == "Ei FOF"]), 0L)
reported_n_with <- ifelse(any(raw_counts$FOF_status_f == "FOF"), as.integer(raw_counts$n[raw_counts$FOF_status_f == "FOF"]), 0L)

cat("Reported fixed N anchor from raw population:\n")
cat(" - Without FOF:", reported_n_without, "\n")
cat(" - With FOF   :", reported_n_with, "\n\n")

outcome_specs <- list(
  list(label = "Composite", base = "Composite0", foll = "Composite2", sex_filter = NA_character_),
  list(label = "HGS", base = "HGS0", foll = "HGS2", sex_filter = NA_character_),
  list(label = "HGS (female)", base = "HGS0", foll = "HGS2", sex_filter = "female"),
  list(label = "HGS (male)", base = "HGS0", foll = "HGS2", sex_filter = "male"),
  list(label = "MWS", base = "MWS0", foll = "MWS2", sex_filter = NA_character_),
  list(label = "FTSST", base = "FTSST0", foll = "FTSST2", sex_filter = NA_character_),
  list(label = "SLS", base = "SLS0", foll = "SLS2", sex_filter = NA_character_)
)

table_rows <- list()
audit_rows <- list()

for (spec in outcome_specs) {
  d <- base_dat %>%
    transmute(
      id = id,
      FOF_status_f = FOF_status_f,
      age = age,
      BMI = BMI,
      Sex_f = Sex_f,
      baseline = .data[[spec$base]],
      followup = .data[[spec$foll]]
    ) %>%
    filter(raw_pop)

  if (!is.na(spec$sex_filter)) {
    d <- d %>% filter(Sex_f == spec$sex_filter)
  }

  if (grepl("^FTSST", spec$label)) {
    x <- c(d$baseline, d$followup)
    x <- x[!is.na(x)]
    if (length(x) > 0) {
      cond <- (max(x) <= 0) || (mean(x <= 0) > 0.5)
      if (isTRUE(cond)) {
        d <- d %>% mutate(baseline = -baseline, followup = -followup)
      }
    }
  }

  d <- d %>% mutate(delta = followup - baseline)
  d_sum <- d %>% filter(!is.na(baseline), !is.na(followup), !is.na(FOF_status_f))
  g0 <- d_sum %>% filter(FOF_status_f == "Ei FOF")
  g1 <- d_sum %>% filter(FOF_status_f == "FOF")

  stratified <- !is.na(spec$sex_filter)
  fA <- delta ~ FOF_status_f
  fB <- delta ~ FOF_status_f + baseline
  include_sex <- (!stratified) && (nlevels(droplevels(d$Sex_f)) > 1)
  fC <- if (include_sex) {
    delta ~ FOF_status_f + baseline + age + BMI + Sex_f
  } else {
    delta ~ FOF_status_f + baseline + age + BMI
  }

  fitA <- fit_with_audit(fA, d, spec$label, "A", "delta", "raw", ifelse(stratified, spec$sex_filter, "all"), FALSE)
  fitB <- fit_with_audit(fB, d, spec$label, "B", "delta", "raw", ifelse(stratified, spec$sex_filter, "all"), FALSE)
  fitC <- fit_with_audit(fC, d, spec$label, "C", "delta", "raw", ifelse(stratified, spec$sex_filter, "all"), include_sex)

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
    N_without = reported_n_without,
    N_with = reported_n_with,
    N_total = reported_n_without + reported_n_with
  )
}

table_df <- bind_rows(table_rows)
audit_df <- bind_rows(audit_rows)

cat("Table 2 V2.3 preview (console):\n")
print(table_df, n = nrow(table_df), width = Inf)

mws_row <- table_df %>% filter(Outcome == "MWS")
if (nrow(mws_row) == 1) {
  cat("\nCrosscheck MWS crude p (Model A): ", mws_row$P_Model_A, "\n", sep = "")
}

readr::write_csv(table_df, output_csv)
readr::write_csv(audit_df, output_audit)

append_artifact(
  label = "table2_paper01_v2_3_csv",
  kind = "table_csv",
  path = output_csv,
  n = nrow(table_df),
  notes = "Published replica Table 2 (raw pop + delta models + fixed N header)"
)
append_artifact(
  label = "table2_paper01_v2_3_modelN_audit_csv",
  kind = "qc_table_csv",
  path = output_audit,
  n = nrow(audit_df),
  notes = "Model-wise actual N audit for V2.3 (A/B/C, outcome/strata)"
)

if (!requireNamespace("gt", quietly = TRUE)) {
  stop("Package 'gt' is required to save HTML output. Install it in renv and rerun.")
}

tbl_gt <- gt::gt(table_df) %>%
  gt::tab_header(
    title = gt::md("**Paper_01 - Table 2 (V2.3 published replica)**"),
    subtitle = paste0(
      "Raw population fixed N header (Without FOF=", reported_n_without,
      ", With FOF=", reported_n_with, "); p-values from delta models A/B/C"
    )
  )
gt::gtsave(data = tbl_gt, filename = output_html)

append_artifact(
  label = "table2_paper01_v2_3_html",
  kind = "table_html",
  path = output_html,
  n = nrow(table_df),
  notes = "Published replica Table 2 HTML (V2.3)"
)

session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = session_path)
append_artifact(
  label = "sessionInfo_v2_3",
  kind = "sessioninfo",
  path = session_path,
  notes = "sessionInfo + renv diagnostics (V2.3)"
)

cat("\nSaved:\n")
cat(" - ", output_html, "\n", sep = "")
cat(" - ", output_csv, "\n", sep = "")
cat(" - ", output_audit, "\n", sep = "")
cat(" - ", session_path, "\n", sep = "")
