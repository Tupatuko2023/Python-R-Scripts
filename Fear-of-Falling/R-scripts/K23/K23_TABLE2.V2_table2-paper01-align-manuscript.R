#!/usr/bin/env Rscript
# ==============================================================================
# K23_TABLE2 - Paper_01 Table 2 generator (V2 manuscript alignment)
# File tag: K23_TABLE2.V2_table2-paper01-align-manuscript.R
# Purpose: Align Table 2 generation to manuscript conventions while preserving
#          V1 history and artifacts.
#
# Alignment changes in V2 (no broad refactor):
# - FTSST sign handling for reporting/modeling in raw-second scale
# - Follow-up ANCOVA p-values from manuscript A/B/C models
# - Default manuscript cohort (fixed N across rows)
# - Robust sex normalization for HGS stratification and model C
#
# Outcome: Outcome-specific baseline/follow-up and delta (follow-up - baseline)
# Predictors: FOF_status
# Moderator/interaction: None
# Grouping variable: None (wide format)
# Covariates (ANCOVA p-values, DV = follow-up):
# - Model A: followup ~ FOF_status_f
# - Model B: followup ~ FOF_status_f + baseline
# - Model C: followup ~ FOF_status_f + baseline + Sex_f + age + BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, kaatumisenpelkoOn, age, sex, BMI, ToimintaKykySummary0, ToimintaKykySummary2,
# Puristus0, Puristus2, kavelynopeus_m_sek0, kavelynopeus_m_sek2, Tuoli0, Tuoli2,
# Seisominen0, Seisominen2
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K23_TABLE2 (canonical)
# - outputs dir: R-scripts/K23/outputs/K23_TABLE2/
# - manifest: append 1 row per artifact to manifest/manifest.csv
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

# --- CLI parsing --------------------------------------------------------------
parse_cli <- function(args) {
  out <- list(
    input = NA_character_,
    output_html = NA_character_,
    output_csv = NA_character_,
    varmap_json = NA_character_,
    population = "manuscript"
  )

  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--output_html=")) out$output_html <- sub("^--output_html=", "", arg)
    if (startsWith(arg, "--output_csv=")) out$output_csv <- sub("^--output_csv=", "", arg)
    if (startsWith(arg, "--varmap_json=")) out$varmap_json <- sub("^--varmap_json=", "", arg)
    if (startsWith(arg, "--population=")) out$population <- tolower(sub("^--population=", "", arg))
  }
  if (!out$population %in% c("manuscript", "per_outcome")) {
    stop("Invalid --population value. Use manuscript or per_outcome.")
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

merge_varmap <- function(base_varmap, override_varmap) {
  merged <- base_varmap
  if (is.null(override_varmap)) return(merged)
  for (nm in names(override_varmap)) {
    if (nm == "outcomes" && is.list(override_varmap$outcomes)) {
      for (out_nm in names(override_varmap$outcomes)) {
        if (!out_nm %in% names(merged$outcomes)) next
        merged$outcomes[[out_nm]] <- modifyList(merged$outcomes[[out_nm]], override_varmap$outcomes[[out_nm]])
      }
    } else {
      merged[[nm]] <- override_varmap[[nm]]
    }
  }
  merged
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

fmt_mean_sd_ci <- function(x) {
  x <- x[!is.na(x)]
  n <- length(x)
  if (n == 0) return("NA")
  m <- mean(x)
  s <- stats::sd(x)
  if (is.na(s)) s <- 0
  se <- s / sqrt(n)
  tcrit <- if (n > 1) stats::qt(0.975, df = n - 1) else NA_real_
  ci_lo <- if (is.finite(tcrit)) m - tcrit * se else m
  ci_hi <- if (is.finite(tcrit)) m + tcrit * se else m
  sprintf("%.2f (%.2f), 95%% CI [%.2f, %.2f]", m, s, ci_lo, ci_hi)
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

default_varmap <- list(
  id = "id",
  fof = "kaatumisenpelkoOn",
  age = "age",
  sex = "sex",
  bmi = "BMI",
  outcomes = list(
    Composite = list(baseline = "ToimintaKykySummary0", followup = "ToimintaKykySummary2"),
    HGS = list(baseline = "Puristus0", followup = "Puristus2"),
    MWS = list(baseline = "kavelynopeus_m_sek0", followup = "kavelynopeus_m_sek2"),
    FTSST = list(baseline = "Tuoli0", followup = "Tuoli2"),
    SLS = list(baseline = "Seisominen0", followup = "Seisominen2")
  )
)

if (!is.na(cli$varmap_json) && nzchar(cli$varmap_json)) {
  if (requireNamespace("jsonlite", quietly = TRUE)) {
    varmap_override <- jsonlite::fromJSON(cli$varmap_json, simplifyVector = FALSE)
    default_varmap <- merge_varmap(default_varmap, varmap_override)
    message("Loaded varmap override from: ", cli$varmap_json)
  } else {
    warning("--varmap_json provided but jsonlite is not available in current renv; ignoring override.")
  }
}

input_path <- choose_input_path(cli$input)
output_html <- if (!is.na(cli$output_html) && nzchar(cli$output_html)) cli$output_html else file.path(outputs_dir, "table2_paper01_v2_align.html")
output_csv <- if (!is.na(cli$output_csv) && nzchar(cli$output_csv)) cli$output_csv else file.path(outputs_dir, "table2_paper01_v2_align.csv")
session_path <- file.path(outputs_dir, "sessionInfo_v2.txt")

dir.create(dirname(output_html), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)

cat("================================================================================\n")
cat("K23_TABLE2 V2: manuscript alignment\n")
cat("Script label:", script_label, "\n")
cat("Population mode:", cli$population, "\n")
cat("Input:", input_path, "\n")
cat("Outputs dir:", outputs_dir, "\n")
cat("Manifest:", manifest_path, "\n")
cat("================================================================================\n\n")

raw_data <- readr::read_csv(input_path, show_col_types = FALSE)
df_std <- standardize_analysis_vars(raw_data)
qc <- sanity_checks(df_std)
print(qc)

req_cols <- c(
  default_varmap$id,
  default_varmap$fof,
  default_varmap$age,
  default_varmap$sex,
  default_varmap$bmi,
  unlist(lapply(default_varmap$outcomes, unlist), use.names = FALSE)
)
missing_cols <- setdiff(unique(req_cols), names(raw_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

analysis_data <- raw_data %>%
  transmute(
    id = .data[[default_varmap$id]],
    fof = as.numeric(.data[[default_varmap$fof]]),
    age = as.numeric(.data[[default_varmap$age]]),
    BMI = as.numeric(.data[[default_varmap$bmi]]),
    Sex_f = normalize_sex(.data[[default_varmap$sex]]),
    FOF_status_f = factor(fof, levels = c(0, 1), labels = c("Ei FOF", "FOF"))
  )

overall_counts <- analysis_data %>%
  filter(!is.na(FOF_status_f)) %>%
  count(FOF_status_f, name = "n")
cat("Sanity check FOF counts (raw groups):\n")
print(overall_counts)
cat("Expected manuscript anchor: Without FOF=77, With FOF=199\n\n")

# Build manuscript cohort IDs: complete across all outcomes + model C covariates
if (cli$population == "manuscript") {
  manuscript_outcomes <- c("HGS", "MWS", "FTSST", "SLS")
  needed_outcomes <- unique(unlist(lapply(default_varmap$outcomes[manuscript_outcomes], unlist), use.names = FALSE))
  complete_outcome <- stats::complete.cases(raw_data[, needed_outcomes, drop = FALSE])
  complete_covars <- with(analysis_data, !is.na(FOF_status_f) & !is.na(age) & !is.na(BMI) & !is.na(Sex_f))
  keep_ids <- analysis_data$id[complete_outcome & complete_covars]
  analysis_data <- analysis_data %>% filter(id %in% keep_ids)
  raw_data <- raw_data %>% filter(.data[[default_varmap$id]] %in% keep_ids)

  cat("Manuscript cohort counts after fixed-cohort filter:\n")
  print(analysis_data %>% count(FOF_status_f, name = "n"))
  cat("\n")
}

collect_outcome_row <- function(data_in, outcome_label, baseline_var, followup_var, sex_filter = NULL) {
  dat <- data_in %>%
    mutate(
      baseline = as.numeric(raw_data[[baseline_var]]),
      followup = as.numeric(raw_data[[followup_var]])
    )

  if (!is.null(sex_filter)) {
    dat <- dat %>% filter(Sex_f == sex_filter)
  }

  # FTSST sign correction for raw-second reporting if values are predominantly non-positive.
  if (outcome_label %in% c("FTSST") || grepl("^FTSST", outcome_label)) {
    x <- c(dat$baseline, dat$followup)
    x <- x[!is.na(x)]
    if (length(x) > 0) {
      cond <- (max(x) <= 0) || (mean(x <= 0) > 0.5)
      if (isTRUE(cond)) {
        dat <- dat %>% mutate(baseline = -baseline, followup = -followup)
      }
    }
  }

  dat <- dat %>%
    mutate(delta = followup - baseline) %>%
    filter(!is.na(FOF_status_f), !is.na(baseline), !is.na(followup), !is.na(age), !is.na(BMI))

  if (cli$population == "per_outcome") {
    dat <- dat %>% filter(!is.na(Sex_f))
  }

  if (nrow(dat) < 10) {
    return(tibble(
      Outcome = outcome_label,
      Without_FOF_Baseline = "", Without_FOF_Followup = "", Without_FOF_Delta = "",
      With_FOF_Baseline = "", With_FOF_Followup = "", With_FOF_Delta = "",
      P_Model_A = "", P_Model_B = "", P_Model_C = "",
      N_without = 0L, N_with = 0L, N_total = 0L
    ))
  }

  g0 <- dat %>% filter(FOF_status_f == "Ei FOF")
  g1 <- dat %>% filter(FOF_status_f == "FOF")

  include_sex <- nlevels(droplevels(dat$Sex_f)) > 1
  form_A <- followup ~ FOF_status_f
  form_B <- followup ~ FOF_status_f + baseline
  form_C <- if (include_sex) {
    followup ~ FOF_status_f + baseline + Sex_f + age + BMI
  } else {
    followup ~ FOF_status_f + baseline + age + BMI
  }

  mA <- lm(form_A, data = dat)
  mB <- lm(form_B, data = dat)
  mC <- lm(form_C, data = dat)

  tibble(
    Outcome = outcome_label,
    Without_FOF_Baseline = fmt_mean_sd_ci(g0$baseline),
    Without_FOF_Followup = fmt_mean_sd_ci(g0$followup),
    Without_FOF_Delta = fmt_mean_sd_ci(g0$delta),
    With_FOF_Baseline = fmt_mean_sd_ci(g1$baseline),
    With_FOF_Followup = fmt_mean_sd_ci(g1$followup),
    With_FOF_Delta = fmt_mean_sd_ci(g1$delta),
    P_Model_A = fmt_p(extract_fof_p(mA)),
    P_Model_B = fmt_p(extract_fof_p(mB)),
    P_Model_C = fmt_p(extract_fof_p(mC)),
    N_without = nrow(g0),
    N_with = nrow(g1),
    N_total = nrow(dat)
  )
}

outcome_rows <- list()
for (nm in names(default_varmap$outcomes)) {
  base_nm <- default_varmap$outcomes[[nm]]$baseline
  foll_nm <- default_varmap$outcomes[[nm]]$followup
  outcome_rows[[length(outcome_rows) + 1L]] <- collect_outcome_row(analysis_data, nm, base_nm, foll_nm)

  if (nm == "HGS") {
    outcome_rows[[length(outcome_rows) + 1L]] <- collect_outcome_row(analysis_data, "HGS (female)", base_nm, foll_nm, sex_filter = "female")
    outcome_rows[[length(outcome_rows) + 1L]] <- collect_outcome_row(analysis_data, "HGS (male)", base_nm, foll_nm, sex_filter = "male")
  }
}

table2_df <- bind_rows(outcome_rows)

cat("Table 2 V2 preview (console):\n")
print(table2_df, n = nrow(table2_df), width = Inf)

readr::write_csv(table2_df, output_csv)
append_artifact(
  label = "table2_paper01_v2_csv",
  kind = "table_csv",
  path = output_csv,
  n = nrow(table2_df),
  notes = "Paper_01 Table 2 V2 aligned dataframe"
)

if (!requireNamespace("gt", quietly = TRUE)) {
  stop("Package 'gt' is required to save HTML output. Install it in renv and rerun.")
}

tbl_gt <- gt::gt(table2_df) %>%
  gt::tab_header(
    title = gt::md("**Paper_01 - Table 2 (V2 aligned)**"),
    subtitle = paste0("Baseline, follow-up, delta and ANCOVA p-values by FOF (population=", cli$population, ")")
  )

gt::gtsave(data = tbl_gt, filename = output_html)
append_artifact(
  label = "table2_paper01_v2_html",
  kind = "table_html",
  path = output_html,
  n = nrow(table2_df),
  notes = "gt HTML output V2"
)

session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = session_path)
append_artifact(
  label = "sessionInfo_v2",
  kind = "sessioninfo",
  path = session_path,
  notes = "sessionInfo + renv diagnostics (V2)"
)

cat("\nSaved:\n")
cat(" - ", output_html, "\n", sep = "")
cat(" - ", output_csv, "\n", sep = "")
cat(" - ", session_path, "\n", sep = "")
