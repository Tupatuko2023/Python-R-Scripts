#!/usr/bin/env Rscript
# ==============================================================================
# K23_TABLE2 - Table 2 model+population debug (V2.2)
# File tag: K23_TABLE2.V2.2_table2-paper01-model-population-debug.R
# Purpose: Diagnostic-only grid run for manuscript mismatch analysis.
#          Compares follow-up ANCOVA vs delta ANCOVA across population modes.
#
# Outcome: QC/debug only (does not modify V1/V2 production Table 2 logic)
# Models:
# - A: DV ~ FOF_status_f
# - B: DV ~ FOF_status_f + baseline
# - C: DV ~ FOF_status_f + baseline + age + BMI (+ Sex_f when applicable)
#
# Population modes:
# - raw
# - covariate_complete
# - all_outcomes_intersection
# - per_outcome_cc
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
    out_csv = NA_character_,
    out_txt = NA_character_
  )
  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--out_csv=")) out$out_csv <- sub("^--out_csv=", "", arg)
    if (startsWith(arg, "--out_txt=")) out$out_txt <- sub("^--out_txt=", "", arg)
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

safe_fit <- function(formula, data) {
  mf <- tryCatch(stats::model.frame(formula, data = data, na.action = stats::na.omit), error = function(e) NULL)
  if (is.null(mf) || nrow(mf) == 0) {
    return(list(p = NA_real_, n_without = NA_integer_, n_with = NA_integer_, n_total = 0L))
  }
  if (!("FOF_status_f" %in% names(mf)) || length(unique(mf$FOF_status_f)) < 2) {
    n_tbl <- table(mf$FOF_status_f)
    return(list(
      p = NA_real_,
      n_without = as.integer(ifelse("Ei FOF" %in% names(n_tbl), n_tbl[["Ei FOF"]], 0)),
      n_with = as.integer(ifelse("FOF" %in% names(n_tbl), n_tbl[["FOF"]], 0)),
      n_total = as.integer(nrow(mf))
    ))
  }
  fit <- tryCatch(stats::lm(formula, data = mf), error = function(e) NULL)
  if (is.null(fit)) {
    n_tbl <- table(mf$FOF_status_f)
    return(list(
      p = NA_real_,
      n_without = as.integer(ifelse("Ei FOF" %in% names(n_tbl), n_tbl[["Ei FOF"]], 0)),
      n_with = as.integer(ifelse("FOF" %in% names(n_tbl), n_tbl[["FOF"]], 0)),
      n_total = as.integer(nrow(mf))
    ))
  }
  n_tbl <- table(mf$FOF_status_f)
  list(
    p = extract_fof_p(fit),
    n_without = as.integer(ifelse("Ei FOF" %in% names(n_tbl), n_tbl[["Ei FOF"]], 0)),
    n_with = as.integer(ifelse("FOF" %in% names(n_tbl), n_tbl[["FOF"]], 0)),
    n_total = as.integer(nrow(mf))
  )
}

pick_n <- function(cand) {
  for (x in cand) if (!is.na(x)) return(as.integer(x))
  NA_integer_
}

cli <- parse_cli(commandArgs(trailingOnly = TRUE))
input_path <- choose_input_path(cli$input)
out_csv <- if (!is.na(cli$out_csv) && nzchar(cli$out_csv)) cli$out_csv else {
  file.path(outputs_dir, "table2_paper01_v2_2_debug_models.csv")
}
out_txt <- if (!is.na(cli$out_txt) && nzchar(cli$out_txt)) cli$out_txt else {
  file.path(outputs_dir, "table2_paper01_v2_2_debug_summary.txt")
}

dir.create(dirname(out_csv), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(out_txt), recursive = TRUE, showWarnings = FALSE)

raw_data <- readr::read_csv(input_path, show_col_types = FALSE)

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

pop_raw <- !is.na(base_dat$FOF_status_f)
pop_cov <- pop_raw & !is.na(base_dat$age) & !is.na(base_dat$BMI) & !is.na(base_dat$Sex_f)
cc_all_outcomes <- with(base_dat,
  !is.na(HGS0) & !is.na(HGS2) &
  !is.na(MWS0) & !is.na(MWS2) &
  !is.na(FTSST0) & !is.na(FTSST2) &
  !is.na(SLS0) & !is.na(SLS2)
)
pop_all_outcomes <- pop_cov & cc_all_outcomes

outcomes <- list(
  list(label = "Composite", base = "Composite0", foll = "Composite2", sex_filter = NA_character_),
  list(label = "HGS", base = "HGS0", foll = "HGS2", sex_filter = NA_character_),
  list(label = "HGS (female)", base = "HGS0", foll = "HGS2", sex_filter = "female"),
  list(label = "HGS (male)", base = "HGS0", foll = "HGS2", sex_filter = "male"),
  list(label = "MWS", base = "MWS0", foll = "MWS2", sex_filter = NA_character_),
  list(label = "FTSST", base = "FTSST0", foll = "FTSST2", sex_filter = NA_character_),
  list(label = "SLS", base = "SLS0", foll = "SLS2", sex_filter = NA_character_)
)

manuscript_refs <- tibble(
  Outcome = c("Composite", "HGS", "HGS (female)", "HGS (male)", "MWS", "FTSST", "SLS"),
  manuscript_p_A = c(NA_real_, NA_real_, NA_real_, NA_real_, 0.220, NA_real_, NA_real_),
  manuscript_p_B = c(NA_real_, NA_real_, NA_real_, NA_real_, NA_real_, NA_real_, NA_real_),
  manuscript_p_C = c(NA_real_, NA_real_, NA_real_, NA_real_, NA_real_, NA_real_, NA_real_)
)

rows <- list()

for (spec in outcomes) {
  outcome_df <- base_dat %>%
    transmute(
      id = id,
      FOF_status_f = FOF_status_f,
      age = age,
      BMI = BMI,
      Sex_f = Sex_f,
      baseline = .data[[spec$base]],
      followup = .data[[spec$foll]]
    )

  if (!is.na(spec$sex_filter)) {
    outcome_df <- outcome_df %>% filter(Sex_f == spec$sex_filter)
  }

  if (grepl("^FTSST", spec$label)) {
    x <- c(outcome_df$baseline, outcome_df$followup)
    x <- x[!is.na(x)]
    if (length(x) > 0) {
      cond <- (max(x) <= 0) || (mean(x <= 0) > 0.5)
      if (isTRUE(cond)) {
        outcome_df <- outcome_df %>% mutate(baseline = -baseline, followup = -followup)
      }
    }
  }

  outcome_df <- outcome_df %>% mutate(delta = followup - baseline)
  cc_outcome <- !is.na(outcome_df$baseline) & !is.na(outcome_df$followup)

  pop_defs <- list(
    raw = pop_raw[match(outcome_df$id, base_dat$id)],
    covariate_complete = pop_cov[match(outcome_df$id, base_dat$id)],
    all_outcomes_intersection = pop_all_outcomes[match(outcome_df$id, base_dat$id)],
    per_outcome_cc = pop_cov[match(outcome_df$id, base_dat$id)] & cc_outcome
  )

  for (pop_nm in names(pop_defs)) {
    dat_pop <- outcome_df %>% filter(pop_defs[[pop_nm]])
    if (nrow(dat_pop) == 0) next

    for (dv_mode in c("followup", "delta")) {
      dv <- dv_mode
      stratified <- !is.na(spec$sex_filter)

      fA <- as.formula(paste0(dv, " ~ FOF_status_f"))
      fB <- as.formula(paste0(dv, " ~ FOF_status_f + baseline"))
      use_sex <- (!stratified) && (nlevels(droplevels(dat_pop$Sex_f)) > 1)
      fC <- if (use_sex) {
        as.formula(paste0(dv, " ~ FOF_status_f + baseline + age + BMI + Sex_f"))
      } else {
        as.formula(paste0(dv, " ~ FOF_status_f + baseline + age + BMI"))
      }

      sA <- safe_fit(fA, dat_pop)
      sB <- safe_fit(fB, dat_pop)
      sC <- safe_fit(fC, dat_pop)

      rows[[length(rows) + 1L]] <- tibble(
        Outcome = spec$label,
        dv_mode = dv_mode,
        population_mode = pop_nm,
        p_A = sA$p,
        p_B = sB$p,
        p_C = sC$p,
        N_without_A = sA$n_without,
        N_with_A = sA$n_with,
        N_total_A = sA$n_total,
        N_without_B = sB$n_without,
        N_with_B = sB$n_with,
        N_total_B = sB$n_total,
        N_without_C = sC$n_without,
        N_with_C = sC$n_with,
        N_total_C = sC$n_total,
        N_without = pick_n(c(sC$n_without, sB$n_without, sA$n_without)),
        N_with = pick_n(c(sC$n_with, sB$n_with, sA$n_with)),
        N_total = pick_n(c(sC$n_total, sB$n_total, sA$n_total)),
        sex_stratum = ifelse(is.na(spec$sex_filter), "all", spec$sex_filter),
        model_C_includes_sex = use_sex
      )
    }
  }
}

debug_df <- bind_rows(rows) %>%
  left_join(manuscript_refs, by = "Outcome") %>%
  mutate(
    abs_diff_A = abs(p_A - manuscript_p_A),
    abs_diff_B = abs(p_B - manuscript_p_B),
    abs_diff_C = abs(p_C - manuscript_p_C),
    n_ref_available = rowSums(!is.na(cbind(manuscript_p_A, manuscript_p_B, manuscript_p_C))),
    overall_abs_diff = ifelse(
      n_ref_available > 0,
      rowMeans(cbind(abs_diff_A, abs_diff_B, abs_diff_C), na.rm = TRUE),
      NA_real_
    )
  ) %>%
  arrange(Outcome, population_mode, dv_mode)

readr::write_csv(debug_df, out_csv)

best_mws <- debug_df %>%
  filter(Outcome == "MWS", !is.na(manuscript_p_A), !is.na(abs_diff_A)) %>%
  arrange(abs_diff_A, p_A)

best_overall <- debug_df %>%
  filter(!is.na(overall_abs_diff)) %>%
  arrange(overall_abs_diff, Outcome, population_mode, dv_mode)

raw_counts <- base_dat %>%
  filter(pop_raw) %>%
  count(FOF_status_f, name = "n")
n_raw_without <- ifelse(any(raw_counts$FOF_status_f == "Ei FOF"), raw_counts$n[raw_counts$FOF_status_f == "Ei FOF"], 0)
n_raw_with <- ifelse(any(raw_counts$FOF_status_f == "FOF"), raw_counts$n[raw_counts$FOF_status_f == "FOF"], 0)

all_counts <- base_dat %>%
  filter(pop_all_outcomes) %>%
  count(FOF_status_f, name = "n")
n_all_without <- ifelse(any(all_counts$FOF_status_f == "Ei FOF"), all_counts$n[all_counts$FOF_status_f == "Ei FOF"], 0)
n_all_with <- ifelse(any(all_counts$FOF_status_f == "FOF"), all_counts$n[all_counts$FOF_status_f == "FOF"], 0)

summary_lines <- c(
  paste0("K23_TABLE2 V2.2 debug summary"),
  paste0("Timestamp: ", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("Input: ", input_path),
  "",
  "Population anchors:",
  paste0("- raw (non-missing FOF): ", n_raw_without, "/", n_raw_with),
  paste0("- all_outcomes_intersection (covariates + all 4 outcomes): ", n_all_without, "/", n_all_with),
  "",
  "Manuscript reference p-values included in this run:",
  "- Available anchors in repo/user packet are partial. Current hardcoded anchor:",
  "  * MWS Model A (crude) = 0.220",
  "- Other manuscript p-values are NA in this debug run (no verified source file in repo snapshot).",
  ""
)

if (nrow(best_mws) > 0) {
  bm <- best_mws[1, ]
  summary_lines <- c(
    summary_lines,
    "Best match for MWS crude p-value anchor (0.220):",
    paste0(
      "- population=", bm$population_mode, ", dv_mode=", bm$dv_mode,
      ", p_A=", sprintf("%.3f", bm$p_A),
      ", abs_diff_A=", sprintf("%.3f", bm$abs_diff_A),
      ", N=", bm$N_without, "/", bm$N_with
    )
  )
}

if (nrow(best_overall) > 0) {
  bo <- best_overall[1, ]
  summary_lines <- c(
    summary_lines,
    "",
    "Best overall among available manuscript anchors:",
    paste0(
      "- outcome=", bo$Outcome,
      ", population=", bo$population_mode,
      ", dv_mode=", bo$dv_mode,
      ", overall_abs_diff=", sprintf("%.3f", bo$overall_abs_diff)
    )
  )
}

summary_lines <- c(
  summary_lines,
  "",
  "Interpretation rule:",
  "- If delta DV combinations consistently minimize abs_diff vs manuscript anchors, manuscript likely used delta models.",
  "- If followup DV combinations minimize abs_diff, manuscript likely used follow-up ANCOVA.",
  "- If no close match even with model/population sweep, mismatch likely due to dataset extraction/cohort/timepoint differences."
)

writeLines(summary_lines, out_txt)

append_artifact(
  label = "table2_paper01_v2_2_debug_models_csv",
  kind = "qc_table_csv",
  path = out_csv,
  n = nrow(debug_df),
  notes = "V2.2 model+population debug grid (followup vs delta ANCOVA)"
)
append_artifact(
  label = "table2_paper01_v2_2_debug_summary_txt",
  kind = "qc_text",
  path = out_txt,
  notes = "V2.2 deterministic mismatch diagnostics summary"
)

cat("Saved V2.2 debug outputs:\n")
cat(" - ", out_csv, "\n", sep = "")
cat(" - ", out_txt, "\n", sep = "")
