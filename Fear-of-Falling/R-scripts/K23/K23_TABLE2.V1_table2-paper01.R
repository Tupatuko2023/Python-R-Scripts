#!/usr/bin/env Rscript
# ==============================================================================
# K23_TABLE2 - Paper_01 Table 2 generator
# File tag: K23_TABLE2.V1_table2-paper01.R
# Purpose: Generate manuscript-style Table 2 for baseline/follow-up outcomes by
#          FOF group with ANCOVA p-values (Models A/B/C) and HGS sex-stratified.
#
# Outcome: Outcome-specific follow-up and delta (follow-up - baseline)
# Predictors: FOF_status
# Moderator/interaction: None
# Grouping variable: None (wide format)
# Covariates:
# - Model A: baseline + FOF
# - Model B: baseline + FOF + age + sex + BMI
# - Model C: baseline + FOF + age + sex + BMI + MOI + diabetes + alzheimer +
#            parkinson + AVH + previous falls + psych score
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, kaatumisenpelkoOn, age, sex, BMI, ToimintaKykySummary0, ToimintaKykySummary2,
# Puristus0, Puristus2, kavelynopeus_m_sek0, kavelynopeus_m_sek2, Tuoli0, Tuoli2,
# Seisominen0, Seisominen2, MOIindeksiindeksi, diabetes, alzheimer, parkinson,
# AVH, kaatuminen, mieliala
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# kaatumisenpelkoOn -> FOF_status (0/1)
# follow-up - baseline -> delta
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: N/A (no randomness)
#
# Outputs + manifest:
# - script_label: K23_TABLE2 (canonical)
# - outputs dir: R-scripts/K23/outputs/K23_TABLE2/
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Parse CLI args (--input/--output_html/--output_csv/--varmap_json)
# 03) Load raw data (immutable; no edits)
# 04) Standardize vars + QC (sanity checks early)
# 05) Derive outcomes and complete-case datasets per outcome
# 06) Fit ANCOVA models A/B/C and collect p-values
# 07) Build Table 2 dataframe + console print
# 08) Save HTML (gt) + CSV -> outputs
# 09) Append manifest row per artifact
# 10) Save sessionInfo / renv diagnostics
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

# Required by project convention even though K-folder output is nested.
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
    varmap_json = NA_character_
  )

  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--output_html=")) out$output_html <- sub("^--output_html=", "", arg)
    if (startsWith(arg, "--output_csv=")) out$output_csv <- sub("^--output_csv=", "", arg)
    if (startsWith(arg, "--varmap_json=")) out$varmap_json <- sub("^--varmap_json=", "", arg)
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

extract_fof_p <- function(model, fof_term = "FOF_status_fFOF") {
  coefs <- summary(model)$coefficients
  if (!fof_term %in% rownames(coefs)) return(NA_real_)
  as.numeric(coefs[fof_term, "Pr(>|t|)"])
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
  moi = "MOIindeksiindeksi",
  diabetes = "diabetes",
  alzheimer = "alzheimer",
  parkinson = "parkinson",
  avh = "AVH",
  previous_falls = "kaatuminen",
  psych_score = "mieliala",
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
output_html <- if (!is.na(cli$output_html) && nzchar(cli$output_html)) cli$output_html else file.path(outputs_dir, "table2_paper01.html")
output_csv <- if (!is.na(cli$output_csv) && nzchar(cli$output_csv)) cli$output_csv else file.path(outputs_dir, "table2_paper01.csv")
session_path <- file.path(outputs_dir, "sessionInfo.txt")

dir.create(dirname(output_html), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(output_csv), recursive = TRUE, showWarnings = FALSE)

cat("================================================================================\n")
cat("K23_TABLE2: paper_01 Table 2 generator\n")
cat("Script label:", script_label, "\n")
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
  default_varmap$moi,
  default_varmap$diabetes,
  default_varmap$alzheimer,
  default_varmap$parkinson,
  default_varmap$avh,
  default_varmap$previous_falls,
  default_varmap$psych_score,
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
    sex = as.numeric(.data[[default_varmap$sex]]),
    BMI = as.numeric(.data[[default_varmap$bmi]]),
    MOI_score = as.numeric(.data[[default_varmap$moi]]),
    diabetes = as.numeric(.data[[default_varmap$diabetes]]),
    alzheimer = as.numeric(.data[[default_varmap$alzheimer]]),
    parkinson = as.numeric(.data[[default_varmap$parkinson]]),
    AVH = as.numeric(.data[[default_varmap$avh]]),
    previous_falls = as.numeric(.data[[default_varmap$previous_falls]]),
    psych_score = as.numeric(.data[[default_varmap$psych_score]])
  ) %>%
  mutate(
    FOF_status_f = factor(fof, levels = c(0, 1), labels = c("Ei FOF", "FOF")),
    Sex_f = factor(sex, levels = c(0, 1), labels = c("female", "male"))
  )

overall_counts <- analysis_data %>%
  filter(!is.na(FOF_status_f)) %>%
  count(FOF_status_f, name = "n")
cat("Sanity check FOF counts (raw groups):\n")
print(overall_counts)
cat("Expected manuscript anchor: Without FOF=77, With FOF=199\n\n")

collect_outcome_row <- function(data_in, outcome_label, baseline_var, followup_var, sex_filter = NULL) {
  dat <- data_in %>%
    mutate(
      baseline = as.numeric(raw_data[[baseline_var]]),
      followup = as.numeric(raw_data[[followup_var]])
    )

  if (!is.null(sex_filter)) {
    dat <- dat %>% filter(Sex_f == sex_filter)
  }

  dat <- dat %>%
    mutate(delta = followup - baseline) %>%
    filter(!is.na(FOF_status_f), !is.na(baseline), !is.na(followup))

  # Complete-case for model covariates (single complete-case set per outcome)
  dat_model <- dat %>%
    filter(
      !is.na(age), !is.na(Sex_f), !is.na(BMI),
      !is.na(MOI_score), !is.na(diabetes), !is.na(alzheimer),
      !is.na(parkinson), !is.na(AVH), !is.na(previous_falls), !is.na(psych_score)
    )

  if (nrow(dat_model) < 10) {
    return(tibble(
      Outcome = outcome_label,
      Without_FOF_Baseline = "", Without_FOF_Followup = "", Without_FOF_Delta = "",
      With_FOF_Baseline = "", With_FOF_Followup = "", With_FOF_Delta = "",
      P_Model_A = "", P_Model_B = "", P_Model_C = "",
      N_without = 0L, N_with = 0L, N_total = 0L
    ))
  }

  g0 <- dat_model %>% filter(FOF_status_f == "Ei FOF")
  g1 <- dat_model %>% filter(FOF_status_f == "FOF")

  include_sex <- nlevels(droplevels(dat_model$Sex_f)) > 1
  sex_term <- if (include_sex) " + Sex_f" else ""

  mA <- lm(followup ~ FOF_status_f + baseline, data = dat_model)
  mB <- lm(stats::as.formula(paste0("followup ~ FOF_status_f + baseline + age", sex_term, " + BMI")), data = dat_model)
  mC <- lm(
    stats::as.formula(
      paste0(
        "followup ~ FOF_status_f + baseline + age", sex_term, " + BMI + ",
        "MOI_score + diabetes + alzheimer + parkinson + AVH + previous_falls + psych_score"
      )
    ),
    data = dat_model
  )

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
    N_total = nrow(dat_model)
  )
}

outcome_rows <- list()
for (nm in names(default_varmap$outcomes)) {
  base_nm <- default_varmap$outcomes[[nm]]$baseline
  foll_nm <- default_varmap$outcomes[[nm]]$followup
  outcome_rows[[length(outcome_rows) + 1L]] <- collect_outcome_row(analysis_data, nm, base_nm, foll_nm)

  # HGS reported sex-stratified.
  if (nm == "HGS") {
    outcome_rows[[length(outcome_rows) + 1L]] <- collect_outcome_row(analysis_data, "HGS (female)", base_nm, foll_nm, sex_filter = "female")
    outcome_rows[[length(outcome_rows) + 1L]] <- collect_outcome_row(analysis_data, "HGS (male)", base_nm, foll_nm, sex_filter = "male")
  }
}

table2_df <- bind_rows(outcome_rows)

cat("Table 2 preview (console):\n")
print(table2_df, n = nrow(table2_df), width = Inf)

readr::write_csv(table2_df, output_csv)
append_artifact(
  label = "table2_paper01_csv",
  kind = "table_csv",
  path = output_csv,
  n = nrow(table2_df),
  notes = "Paper_01 Table 2 dataframe"
)

if (!requireNamespace("gt", quietly = TRUE)) {
  stop("Package 'gt' is required to save HTML output. Install it in renv and rerun.")
}

tbl_gt <- gt::gt(table2_df) %>%
  gt::tab_header(
    title = gt::md("**Paper_01 - Table 2**"),
    subtitle = "Baseline, follow-up, delta and ANCOVA p-values by FOF"
  )

gt::gtsave(data = tbl_gt, filename = output_html)
append_artifact(
  label = "table2_paper01_html",
  kind = "table_html",
  path = output_html,
  n = nrow(table2_df),
  notes = "gt HTML output"
)

session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = session_path)
append_artifact(
  label = "sessionInfo",
  kind = "sessioninfo",
  path = session_path,
  notes = "sessionInfo + renv diagnostics"
)

cat("\nSaved:\n")
cat(" - ", output_html, "\n", sep = "")
cat(" - ", output_csv, "\n", sep = "")
cat(" - ", session_path, "\n", sep = "")
