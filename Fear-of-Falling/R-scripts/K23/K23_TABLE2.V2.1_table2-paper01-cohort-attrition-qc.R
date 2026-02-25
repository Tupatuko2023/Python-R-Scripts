#!/usr/bin/env Rscript
# ==============================================================================
# K23_TABLE2 - Cohort attrition QC for Table 2 manuscript-mode
# File tag: K23_TABLE2.V2.1_table2-paper01-cohort-attrition-qc.R
# Purpose: Deterministically explain why manuscript-mode cohort shrinks from raw
#          FOF counts to fixed Table 2 cohort (all outcomes + covariates).
#
# Outcome: QC only (no model fitting, no Table 2 statistical logic changes)
# Required vars:
# id, kaatumisenpelkoOn, age, sex, BMI,
# Puristus0, Puristus2, kavelynopeus_m_sek0, kavelynopeus_m_sek2,
# Tuoli0, Tuoli2, Seisominen0, Seisominen2
#
# Outputs + manifest:
# - script_label: K23_TABLE2 (canonical)
# - outputs dir: R-scripts/K23/outputs/K23_TABLE2/
# - table2_paper01_cohort_attrition_qc.csv
# - table2_paper01_missingness_matrix_by_fof.csv
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
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
manifest_path <- paths$manifest_path
outputs_dir <- here::here("R-scripts", "K23", "outputs", script_label)
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
options(fof.outputs_dir = outputs_dir, fof.manifest_path = manifest_path, fof.script = script_label)

parse_cli <- function(args) {
  out <- list(
    input = NA_character_,
    output_csv1 = NA_character_,
    output_csv2 = NA_character_
  )
  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--output_csv1=")) out$output_csv1 <- sub("^--output_csv1=", "", arg)
    if (startsWith(arg, "--output_csv2=")) out$output_csv2 <- sub("^--output_csv2=", "", arg)
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
output_csv1 <- if (!is.na(cli$output_csv1) && nzchar(cli$output_csv1)) {
  cli$output_csv1
} else {
  file.path(outputs_dir, "table2_paper01_cohort_attrition_qc.csv")
}
output_csv2 <- if (!is.na(cli$output_csv2) && nzchar(cli$output_csv2)) {
  cli$output_csv2
} else {
  file.path(outputs_dir, "table2_paper01_missingness_matrix_by_fof.csv")
}

dir.create(dirname(output_csv1), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(output_csv2), recursive = TRUE, showWarnings = FALSE)

raw_data <- readr::read_csv(input_path, show_col_types = FALSE)

req_cols <- c(
  "id", "kaatumisenpelkoOn", "age", "sex", "BMI",
  "Puristus0", "Puristus2",
  "kavelynopeus_m_sek0", "kavelynopeus_m_sek2",
  "Tuoli0", "Tuoli2",
  "Seisominen0", "Seisominen2"
)
missing_cols <- setdiff(req_cols, names(raw_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

dat <- raw_data %>%
  transmute(
    id = .data$id,
    fof_raw = suppressWarnings(as.numeric(.data$kaatumisenpelkoOn)),
    FOF_status_f = factor(fof_raw, levels = c(0, 1), labels = c("Ei FOF", "FOF")),
    age = suppressWarnings(as.numeric(.data$age)),
    BMI = suppressWarnings(as.numeric(.data$BMI)),
    Sex_f = normalize_sex(.data$sex),
    HGS0 = suppressWarnings(as.numeric(.data$Puristus0)),
    HGS2 = suppressWarnings(as.numeric(.data$Puristus2)),
    MWS0 = suppressWarnings(as.numeric(.data$kavelynopeus_m_sek0)),
    MWS2 = suppressWarnings(as.numeric(.data$kavelynopeus_m_sek2)),
    FTSST0 = suppressWarnings(as.numeric(.data$Tuoli0)),
    FTSST2 = suppressWarnings(as.numeric(.data$Tuoli2)),
    SLS0 = suppressWarnings(as.numeric(.data$Seisominen0)),
    SLS2 = suppressWarnings(as.numeric(.data$Seisominen2))
  )

base_eligible <- !is.na(dat$FOF_status_f)
cov_complete <- !is.na(dat$age) & !is.na(dat$BMI) & !is.na(dat$Sex_f)
cc_MWS <- !is.na(dat$MWS0) & !is.na(dat$MWS2)
cc_FTSST <- !is.na(dat$FTSST0) & !is.na(dat$FTSST2)
cc_SLS <- !is.na(dat$SLS0) & !is.na(dat$SLS2)
cc_HGS <- !is.na(dat$HGS0) & !is.na(dat$HGS2)
cc_all_outcomes <- cc_MWS & cc_FTSST & cc_SLS & cc_HGS

count_by_group <- function(mask) {
  x <- dat %>% filter(base_eligible & mask) %>% count(FOF_status_f, name = "n")
  n_without <- x$n[x$FOF_status_f == "Ei FOF"]
  n_with <- x$n[x$FOF_status_f == "FOF"]
  if (length(n_without) == 0) n_without <- 0L
  if (length(n_with) == 0) n_with <- 0L
  c(as.integer(n_without), as.integer(n_with))
}

step_defs <- list(
  list(step = "Step0_raw", definition = "Non-missing FOF group", mask = rep(TRUE, nrow(dat))),
  list(step = "Step1_covariates", definition = "Raw ∩ covariates complete (age, sex_mapped, BMI)", mask = cov_complete),
  list(step = "Step2_MWS_cc", definition = "Step1 ∩ MWS baseline+followup complete", mask = cov_complete & cc_MWS),
  list(step = "Step2_FTSST_cc", definition = "Step1 ∩ FTSST baseline+followup complete", mask = cov_complete & cc_FTSST),
  list(step = "Step2_SLS_cc", definition = "Step1 ∩ SLS baseline+followup complete", mask = cov_complete & cc_SLS),
  list(step = "Step2_HGS_cc", definition = "Step1 ∩ HGS baseline+followup complete", mask = cov_complete & cc_HGS),
  list(step = "Step3_all_outcomes", definition = "Step1 ∩ all outcomes complete (MWS+FTSST+SLS+HGS)", mask = cov_complete & cc_all_outcomes)
)

rows <- lapply(step_defs, function(s) {
  n_pair <- count_by_group(s$mask)
  tibble(
    step = s$step,
    definition = s$definition,
    N_without = n_pair[1],
    N_with = n_pair[2],
    N_total = n_pair[1] + n_pair[2]
  )
})
attrition_df <- bind_rows(rows) %>%
  mutate(
    Delta_prev_without = N_without - lag(N_without),
    Delta_prev_with = N_with - lag(N_with),
    Delta_prev_total = N_total - lag(N_total)
  )

missing_flags <- list(
  age_missing = is.na(dat$age),
  sex_missing = is.na(dat$Sex_f),
  bmi_missing = is.na(dat$BMI),
  MWS0_missing = is.na(dat$MWS0),
  MWS2_missing = is.na(dat$MWS2),
  FTSST0_missing = is.na(dat$FTSST0),
  FTSST2_missing = is.na(dat$FTSST2),
  SLS0_missing = is.na(dat$SLS0),
  SLS2_missing = is.na(dat$SLS2),
  HGS0_missing = is.na(dat$HGS0),
  HGS2_missing = is.na(dat$HGS2)
)

group_denoms <- dat %>%
  filter(base_eligible) %>%
  count(FOF_status_f, name = "group_n")
n_without_denom <- group_denoms$group_n[group_denoms$FOF_status_f == "Ei FOF"]
n_with_denom <- group_denoms$group_n[group_denoms$FOF_status_f == "FOF"]
if (length(n_without_denom) == 0) n_without_denom <- 0L
if (length(n_with_denom) == 0) n_with_denom <- 0L

missing_df <- bind_rows(lapply(names(missing_flags), function(nm) {
  m <- missing_flags[[nm]]
  cts <- count_by_group(m)
  tibble(
    flag = nm,
    missing_without = cts[1],
    missing_with = cts[2],
    missing_total = cts[1] + cts[2],
    pct_without = if (n_without_denom > 0) round(100 * cts[1] / n_without_denom, 1) else NA_real_,
    pct_with = if (n_with_denom > 0) round(100 * cts[2] / n_with_denom, 1) else NA_real_
  )
}))

readr::write_csv(attrition_df, output_csv1)
readr::write_csv(missing_df, output_csv2)

append_artifact(
  label = "table2_cohort_attrition_qc_csv",
  kind = "qc_table_csv",
  path = output_csv1,
  n = nrow(attrition_df),
  notes = "K23 Table2 manuscript cohort attrition steps (raw -> covariates -> outcomes -> intersection)"
)
append_artifact(
  label = "table2_missingness_matrix_qc_csv",
  kind = "qc_table_csv",
  path = output_csv2,
  n = nrow(missing_df),
  notes = "K23 Table2 variable missingness matrix by FOF group"
)

cat("Saved attrition QC outputs:\n")
cat(" - ", output_csv1, "\n", sep = "")
cat(" - ", output_csv2, "\n", sep = "")
cat("\nKey anchor rows:\n")
print(attrition_df %>% filter(step %in% c("Step0_raw", "Step3_all_outcomes")))
