#!/usr/bin/env Rscript
# ==============================================================================
# K50 - Paper 01 Cohort Flow Derivation Helper
# File tag: K50.1_COHORT_FLOW.V1_derive-cohort-flow.R
# Purpose: Derive sequential cohort-flow counts and DOT placeholders for the
#          K50 primary branch without changing the locked K50 model logic.
#
# Outcome: locomotor_capacity | z3 | Composite_Z
# Predictors: FOF_status, time
# Moderator/interaction: none (derivation/QC helper only)
# Grouping variable: id
# Covariates: age, sex, BMI, FI22_nonperformance_KAAOS (optional sensitivity note only)
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, time, FOF_status, age, sex, BMI, locomotor_capacity, locomotor_capacity_0,
# locomotor_capacity_12m, z3, z3_0, z3_12m, Composite_Z, Composite_Z_0,
# Composite_Z_12m, FI22_nonperformance_KAAOS, tasapainovaikeus
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# Composite_Z_baseline -> Composite_Z_0 (legacy bridge only; verified bridge)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (not used; no randomness)
#
# Outputs + manifest:
# - script_label: K50 (canonical output target for helper artifacts)
# - outputs dir: R-scripts/K50/outputs/  (resolved via init_paths("K50"))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Resolve input path from CLI / verified upstream candidates
# 03) Load analysis-ready data (immutable; no edits)
# 04) Enforce explicit shape + outcome gates and validate required columns
# 05) Recode canonical time/FOF levels and derive participant-level gates
# 06) Build sequential cohort-flow counts for the declared primary branch
# 07) Build Group x Time missingness placeholders matching K50 logic
# 08) Save aggregate artifacts -> R-scripts/K50/outputs/
# 09) Append manifest row per artifact
# 10) Save sessionInfo to manifest/
# 11) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(tibble)
  library(here)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.[Rr]$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K50"
}
script_label <- "K50"
helper_label <- sub("\\.V.*$", "", script_base)

source(here::here("R", "functions", "init.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

req_cols <- c(
  "id", "time", "FOF_status", "age", "sex", "BMI",
  "locomotor_capacity", "locomotor_capacity_0", "locomotor_capacity_12m",
  "z3", "z3_0", "z3_12m", "Composite_Z", "Composite_Z_0",
  "Composite_Z_12m", "FI22_nonperformance_KAAOS", "tasapainovaikeus"
)

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  row <- data.frame(
    timestamp = as.character(Sys.time()),
    script = helper_label,
    label = label,
    kind = kind,
    path = get_relpath(path),
    n = n,
    notes = notes,
    stringsAsFactors = FALSE
  )
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(manifest_path)) {
    utils::write.table(row, manifest_path, sep = ",", row.names = FALSE, col.names = TRUE, qmethod = "double")
  } else {
    utils::write.table(row, manifest_path, sep = ",", row.names = FALSE, col.names = FALSE, append = TRUE, qmethod = "double")
  }
}

write_table_with_manifest <- function(tbl, label, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".csv"))
  readr::write_csv(tbl, out_path, na = "")
  append_manifest_safe(label, "table_csv", out_path, n = nrow(tbl), notes = notes)
  out_path
}

get_arg <- function(flag, default = NULL) {
  args <- commandArgs(trailingOnly = TRUE)
  idx <- match(flag, args)
  if (is.na(idx) || idx == length(args)) return(default)
  args[[idx + 1]]
}

parse_toggle <- function(x, flag) {
  val <- tolower(trimws(ifelse(is.null(x), "", as.character(x))))
  if (!nzchar(val)) return(FALSE)
  if (val %in% c("1", "true", "yes", "on")) return(TRUE)
  if (val %in% c("0", "false", "no", "off")) return(FALSE)
  stop("Invalid value for ", flag, ": ", x, ". Use on/off.", call. = FALSE)
}

parse_shape <- function(x) {
  val <- toupper(trimws(ifelse(is.null(x), "", as.character(x))))
  if (!val %in% c("LONG", "WIDE")) {
    stop("K50 cohort flow requires explicit --shape LONG|WIDE. AUTO is not allowed.", call. = FALSE)
  }
  val
}

parse_outcome <- function(x) {
  val <- trimws(ifelse(is.null(x), "", as.character(x)))
  if (!val %in% c("locomotor_capacity", "z3", "Composite_Z")) {
    stop("K50 cohort flow requires --outcome locomotor_capacity|z3|Composite_Z.", call. = FALSE)
  }
  val
}

resolve_existing <- function(candidates) {
  hits <- candidates[file.exists(candidates)]
  if (length(hits) == 0) return(NA_character_)
  normalizePath(hits[[1]], winslash = "/", mustWork = TRUE)
}

resolve_data_root <- function() {
  dr <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(dr)) return(NA_character_)
  normalizePath(dr, winslash = "/", mustWork = FALSE)
}

resolve_input_path <- function(shape, cli_data) {
  if (!is.null(cli_data) && nzchar(cli_data)) {
    if (!file.exists(cli_data)) {
      stop("K50 cohort flow --data file not found: ", cli_data, call. = FALSE)
    }
    return(normalizePath(cli_data, winslash = "/", mustWork = TRUE))
  }

  shape_lower <- tolower(shape)
  data_root <- resolve_data_root()
  candidates <- c()
  if (!is.na(data_root)) {
    candidates <- c(
      candidates,
      file.path(data_root, "paper_01", "analysis", paste0("fof_analysis_k50_", shape_lower, ".rds")),
      file.path(data_root, "paper_01", "analysis", paste0("fof_analysis_k50_", shape_lower, ".csv")),
      file.path(data_root, "paper_01", "analysis", paste0("fof_analysis_k33_", shape_lower, ".rds")),
      file.path(data_root, "paper_01", "analysis", paste0("fof_analysis_k33_", shape_lower, ".csv"))
    )
  }
  candidates <- c(
    candidates,
    here::here("R-scripts", "K50", "outputs", paste0("fof_analysis_k50_", shape_lower, ".rds")),
    here::here("R-scripts", "K50", "outputs", paste0("fof_analysis_k50_", shape_lower, ".csv"))
  )

  hit <- resolve_existing(candidates)
  if (is.na(hit)) {
    stop(
      paste0(
        "K50 cohort flow could not resolve an input dataset. Supply --data explicitly or create a verified upstream K50 dataset.\n",
        "Tried:\n- ", paste(candidates, collapse = "\n- ")
      ),
      call. = FALSE
    )
  }
  hit
}

read_dataset <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") return(as_tibble(readRDS(path)))
  if (ext == "csv") return(as_tibble(readr::read_csv(path, show_col_types = FALSE)))
  stop("Unsupported input extension: ", ext, call. = FALSE)
}

safe_num <- function(x) suppressWarnings(as.numeric(x))

normalize_id <- function(x) {
  out <- trimws(as.character(x))
  out[is.na(out) | out == "" | tolower(out) %in% c("na", "nan", "null")] <- NA_character_
  out
}

normalize_fof <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "nonfof", "ei fof", "no fof", "false")] <- 0L
  out[s %in% c("1", "fof", "true")] <- 1L
  suppressWarnings(num <- as.integer(s))
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 1L)
  out[use_num] <- num[use_num]
  factor(out, levels = c(0L, 1L))
}

normalize_sex <- function(x) {
  out <- trimws(as.character(x))
  out[is.na(out) | out == ""] <- NA_character_
  factor(out)
}

normalize_time <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "baseline", "base", "t0")] <- 0L
  out[s %in% c("12", "12m", "m12", "followup", "follow-up", "12_months")] <- 12L
  suppressWarnings(num <- as.integer(s))
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 12L)
  out[use_num] <- num[use_num]
  out
}

first_present <- function(nms, candidates) {
  hits <- candidates[candidates %in% nms]
  if (length(hits) == 0) return(NA_character_)
  hits[[1]]
}

resolve_wide_cols <- function(outcome, nms) {
  if (identical(outcome, "Composite_Z")) {
    return(list(
      baseline = first_present(nms, c("Composite_Z_0", "Composite_Z_baseline")),
      followup = first_present(nms, c("Composite_Z_12m"))
    ))
  }
  list(
    baseline = first_present(nms, c(paste0(outcome, "_0"))),
    followup = first_present(nms, c(paste0(outcome, "_12m")))
  )
}

resolve_long_col <- function(outcome, nms) {
  first_present(nms, c(outcome))
}

format_pct <- function(num, denom) {
  if (is.na(denom) || denom <= 0 || is.na(num)) return("0.0")
  sprintf("%.1f", 100 * num / denom)
}

build_missing_placeholders <- function(missing_tbl) {
  keys <- expand.grid(
    fof = c("0", "1"),
    time = c("0", "12"),
    stringsAsFactors = FALSE
  ) %>%
    mutate(
      n_key = paste0("MISS_F", fof, "_T", time, "_N"),
      out_key = paste0("MISS_F", fof, "_T", time, "_OUT"),
      age_key = paste0("MISS_F", fof, "_T", time, "_AGE"),
      sex_key = paste0("MISS_F", fof, "_T", time, "_SEX"),
      bmi_key = paste0("MISS_F", fof, "_T", time, "_BMI")
    )

  rows <- vector("list", nrow(keys) * 5L)
  idx <- 1L
  for (i in seq_len(nrow(keys))) {
    hit <- missing_tbl %>%
      filter(as.character(FOF_status) == keys$fof[[i]], as.character(time) == keys$time[[i]])
    vals <- if (nrow(hit) == 0) {
      list(n = 0L, outcome_missing_n = 0L, age_missing_n = 0L, sex_missing_n = 0L, bmi_missing_n = 0L)
    } else {
      hit[1, c("n", "outcome_missing_n", "age_missing_n", "sex_missing_n", "bmi_missing_n")]
    }
    rows[[idx]] <- tibble(placeholder = keys$n_key[[i]], value = as.character(vals$n[[1]])); idx <- idx + 1L
    rows[[idx]] <- tibble(placeholder = keys$out_key[[i]], value = as.character(vals$outcome_missing_n[[1]])); idx <- idx + 1L
    rows[[idx]] <- tibble(placeholder = keys$age_key[[i]], value = as.character(vals$age_missing_n[[1]])); idx <- idx + 1L
    rows[[idx]] <- tibble(placeholder = keys$sex_key[[i]], value = as.character(vals$sex_missing_n[[1]])); idx <- idx + 1L
    rows[[idx]] <- tibble(placeholder = keys$bmi_key[[i]], value = as.character(vals$bmi_missing_n[[1]])); idx <- idx + 1L
  }
  bind_rows(rows)
}

shape <- parse_shape(get_arg("--shape"))
outcome <- parse_outcome(get_arg("--outcome", "locomotor_capacity"))
allow_composite_z <- identical(toupper(get_arg("--allow-composite-z", "off")), "VERIFIED")
fi22_enabled <- parse_toggle(get_arg("--fi22", "off"), "--fi22")
data_path <- resolve_input_path(shape, get_arg("--data"))

if (identical(outcome, "Composite_Z") && !allow_composite_z) {
  stop(
    "Composite_Z is legacy bridge only. Re-run with --allow-composite-z VERIFIED after verifying the original definition.",
    call. = FALSE
  )
}

input_df <- read_dataset(data_path)
id_col <- first_present(names(input_df), c("id"))
fof_col <- first_present(names(input_df), c("FOF_status"))
age_col <- first_present(names(input_df), c("age"))
sex_col <- first_present(names(input_df), c("sex"))
bmi_col <- first_present(names(input_df), c("BMI"))

base_required <- c(id_col, fof_col, age_col, sex_col, bmi_col)
if (any(is.na(base_required))) {
  miss <- c("id", "FOF_status", "age", "sex", "BMI")[is.na(base_required)]
  stop("K50 cohort flow input is missing required canonical covariates: ", paste(miss, collapse = ", "), call. = FALSE)
}

prefix <- paste("k50", tolower(shape), outcome, sep = "_")
cohort_prefix <- paste0(prefix, "_cohort_flow")

if (shape == "LONG") {
  time_col <- first_present(names(input_df), c("time"))
  outcome_col <- resolve_long_col(outcome, names(input_df))
  z3_col <- resolve_long_col("z3", names(input_df))
  fi22_col <- first_present(names(input_df), c("FI22_nonperformance_KAAOS"))

  if (is.na(time_col)) stop("K50 cohort flow LONG input requires canonical time column `time`.", call. = FALSE)
  if (is.na(outcome_col)) {
    stop("K50 cohort flow LONG input is missing canonical outcome column `", outcome, "`.", call. = FALSE)
  }
  if (identical(outcome, "locomotor_capacity") && is.na(z3_col)) {
    stop("K50 cohort flow requires canonical `z3` in LONG data for the locked fallback branch.", call. = FALSE)
  }
  if (fi22_enabled && is.na(fi22_col)) {
    stop("K50 cohort flow --fi22 on requires canonical `FI22_nonperformance_KAAOS`.", call. = FALSE)
  }

  analysis_df <- input_df %>%
    transmute(
      id = normalize_id(.data[[id_col]]),
      time = normalize_time(.data[[time_col]]),
      FOF_status = normalize_fof(.data[[fof_col]]),
      age = safe_num(.data[[age_col]]),
      sex = normalize_sex(.data[[sex_col]]),
      BMI = safe_num(.data[[bmi_col]]),
      outcome_value = safe_num(.data[[outcome_col]]),
      FI22_nonperformance_KAAOS = if (!is.na(fi22_col)) safe_num(.data[[fi22_col]]) else NA_real_
    ) %>%
    arrange(id, time)

  missing_tbl <- analysis_df %>%
    transmute(
      FOF_status = as.character(FOF_status),
      time = time,
      n = 1L,
      outcome_missing_n = as.integer(is.na(outcome_value)),
      age_missing_n = as.integer(is.na(age)),
      sex_missing_n = as.integer(is.na(sex)),
      bmi_missing_n = as.integer(is.na(BMI))
    ) %>%
    group_by(FOF_status, time) %>%
    summarise(
      n = sum(n),
      outcome_missing_n = sum(outcome_missing_n),
      age_missing_n = sum(age_missing_n),
      sex_missing_n = sum(sex_missing_n),
      bmi_missing_n = sum(bmi_missing_n),
      .groups = "drop"
    )

  raw_rows <- nrow(analysis_df)
  valid_id_df <- analysis_df %>% filter(!is.na(id))
  raw_id_n <- dplyr::n_distinct(valid_id_df$id)
  ex_id_missing <- raw_rows - nrow(valid_id_df)
  n_valid_id <- raw_id_n

  id_gate_df <- valid_id_df %>%
    group_by(id) %>%
    summarise(
      n_rows = n(),
      fof_values = paste(sort(unique(stats::na.omit(as.character(FOF_status)))), collapse = ";"),
      time_values = paste(sort(unique(stats::na.omit(time))), collapse = ";"),
      n_valid_time = sum(!is.na(time)),
      branch_eligible = n() == 2L && length(unique(stats::na.omit(time))) == 2L && all(sort(unique(stats::na.omit(time))) == c(0L, 12L)),
      outcome_complete = n() == 2L && length(unique(stats::na.omit(time))) == 2L && all(sort(unique(stats::na.omit(time))) == c(0L, 12L)) && all(!is.na(outcome_value)),
      age_complete = all(!is.na(age)),
      sex_complete = all(!is.na(sex)),
      bmi_complete = all(!is.na(BMI)),
      fi22_complete = all(!is.na(FI22_nonperformance_KAAOS)),
      .groups = "drop"
    ) %>%
    mutate(
      fof_valid = fof_values %in% c("0", "1"),
      fof_value = if_else(fof_valid, fof_values, NA_character_),
      time_invalid = !branch_eligible
    )

  ex_fof_invalid <- sum(!id_gate_df$fof_valid)
  n_with_fof <- sum(id_gate_df$fof_valid)
  with_fof_df <- id_gate_df %>% filter(fof_valid)

  ex_branch_structure <- sum(!with_fof_df$branch_eligible)
  ex_time_missing_or_invalid <- sum(with_fof_df$time_invalid)
  n_branch_eligible <- sum(with_fof_df$branch_eligible)
  branch_df <- with_fof_df %>% filter(branch_eligible)

  ex_outcome_missing <- sum(!branch_df$outcome_complete)
  n_outcome_complete <- sum(branch_df$outcome_complete)
  outcome_df <- branch_df %>% filter(outcome_complete)

  cov_complete <- outcome_df$age_complete & outcome_df$sex_complete & outcome_df$bmi_complete
  ex_covariate_missing <- sum(!cov_complete)
  analytic_df <- outcome_df[cov_complete, , drop = FALSE]
  if (fi22_enabled) {
    analytic_df <- analytic_df[analytic_df$fi22_complete, , drop = FALSE]
  }
} else {
  wide_outcome_cols <- resolve_wide_cols(outcome, names(input_df))
  wide_z3_cols <- resolve_wide_cols("z3", names(input_df))
  fi22_col <- first_present(names(input_df), c("FI22_nonperformance_KAAOS"))

  if (any(is.na(unlist(wide_outcome_cols)))) {
    stop(
      "K50 cohort flow WIDE input is missing canonical columns for `", outcome, "`: ",
      paste(names(wide_outcome_cols)[is.na(unlist(wide_outcome_cols))], collapse = ", "),
      call. = FALSE
    )
  }
  if (identical(outcome, "locomotor_capacity") && any(is.na(unlist(wide_z3_cols)))) {
    stop("K50 cohort flow requires canonical `z3_0` and `z3_12m` in WIDE data for the locked fallback branch.", call. = FALSE)
  }
  if (fi22_enabled && is.na(fi22_col)) {
    stop("K50 cohort flow --fi22 on requires canonical `FI22_nonperformance_KAAOS`.", call. = FALSE)
  }

  analysis_df <- input_df %>%
    transmute(
      id = normalize_id(.data[[id_col]]),
      FOF_status = normalize_fof(.data[[fof_col]]),
      age = safe_num(.data[[age_col]]),
      sex = normalize_sex(.data[[sex_col]]),
      BMI = safe_num(.data[[bmi_col]]),
      outcome_0 = safe_num(.data[[wide_outcome_cols$baseline]]),
      outcome_12m = safe_num(.data[[wide_outcome_cols$followup]]),
      FI22_nonperformance_KAAOS = if (!is.na(fi22_col)) safe_num(.data[[fi22_col]]) else NA_real_
    )

  missing_tbl <- bind_rows(
    analysis_df %>%
      transmute(
        FOF_status = as.character(FOF_status),
        time = 0L,
        n = 1L,
        outcome_missing_n = as.integer(is.na(outcome_0)),
        age_missing_n = as.integer(is.na(age)),
        sex_missing_n = as.integer(is.na(sex)),
        bmi_missing_n = as.integer(is.na(BMI))
      ),
    analysis_df %>%
      transmute(
        FOF_status = as.character(FOF_status),
        time = 12L,
        n = 1L,
        outcome_missing_n = as.integer(is.na(outcome_12m)),
        age_missing_n = as.integer(is.na(age)),
        sex_missing_n = as.integer(is.na(sex)),
        bmi_missing_n = as.integer(is.na(BMI))
      )
  ) %>%
    group_by(FOF_status, time) %>%
    summarise(
      n = sum(n),
      outcome_missing_n = sum(outcome_missing_n),
      age_missing_n = sum(age_missing_n),
      sex_missing_n = sum(sex_missing_n),
      bmi_missing_n = sum(bmi_missing_n),
      .groups = "drop"
    )

  raw_rows <- nrow(analysis_df)
  valid_id_df <- analysis_df %>% filter(!is.na(id))
  raw_id_n <- dplyr::n_distinct(valid_id_df$id)
  ex_id_missing <- raw_rows - nrow(valid_id_df)
  n_valid_id <- raw_id_n

  id_gate_df <- valid_id_df %>%
    group_by(id) %>%
    summarise(
      n_rows = n(),
      fof_values = paste(sort(unique(stats::na.omit(as.character(FOF_status)))), collapse = ";"),
      outcome_complete = all(!is.na(outcome_0)) && all(!is.na(outcome_12m)),
      age_complete = all(!is.na(age)),
      sex_complete = all(!is.na(sex)),
      bmi_complete = all(!is.na(BMI)),
      fi22_complete = all(!is.na(FI22_nonperformance_KAAOS)),
      .groups = "drop"
    ) %>%
    mutate(
      fof_valid = fof_values %in% c("0", "1"),
      fof_value = if_else(fof_valid, fof_values, NA_character_),
      branch_eligible = n_rows == 1L,
      time_invalid = FALSE
    )

  ex_fof_invalid <- sum(!id_gate_df$fof_valid)
  n_with_fof <- sum(id_gate_df$fof_valid)
  with_fof_df <- id_gate_df %>% filter(fof_valid)

  ex_branch_structure <- sum(!with_fof_df$branch_eligible)
  ex_time_missing_or_invalid <- 0L
  n_branch_eligible <- sum(with_fof_df$branch_eligible)
  branch_df <- with_fof_df %>% filter(branch_eligible)

  ex_outcome_missing <- sum(!branch_df$outcome_complete)
  n_outcome_complete <- sum(branch_df$outcome_complete)
  outcome_df <- branch_df %>% filter(outcome_complete)

  cov_complete <- outcome_df$age_complete & outcome_df$sex_complete & outcome_df$bmi_complete
  ex_covariate_missing <- sum(!cov_complete)
  analytic_df <- outcome_df[cov_complete, , drop = FALSE]
  if (fi22_enabled) {
    analytic_df <- analytic_df[analytic_df$fi22_complete, , drop = FALSE]
  }
}

n_analytic_primary <- nrow(analytic_df)
fof_yes_analytic <- sum(analytic_df$fof_value == "1", na.rm = TRUE)
fof_no_analytic <- sum(analytic_df$fof_value == "0", na.rm = TRUE)
ex_fi22_missing_sens <- if (fi22_enabled) sum(!outcome_df$fi22_complete) else sum(!outcome_df$fi22_complete)

counts_tbl <- tibble(
  count = c(
    "N_RAW_ROWS",
    "N_RAW_ID",
    "EX_ID_MISSING",
    "N_VALID_ID",
    "EX_FOF_MISSING_OR_INVALID",
    "N_WITH_FOF",
    "EX_BRANCH_STRUCTURE",
    "EX_TIME_MISSING_OR_INVALID",
    "N_BRANCH_ELIGIBLE",
    "EX_OUTCOME_MISSING_PRIMARY",
    "N_OUTCOME_COMPLETE",
    "EX_COVARIATE_MISSING_PRIMARY",
    "EX_FI22_MISSING_SENS",
    "N_ANALYTIC_PRIMARY",
    "FOF_YES_ANALYTIC",
    "FOF_NO_ANALYTIC"
  ),
  value = c(
    raw_rows,
    raw_id_n,
    ex_id_missing,
    n_valid_id,
    ex_fof_invalid,
    n_with_fof,
    ex_branch_structure,
    ex_time_missing_or_invalid,
    n_branch_eligible,
    ex_outcome_missing,
    n_outcome_complete,
    ex_covariate_missing,
    ex_fi22_missing_sens,
    n_analytic_primary,
    fof_yes_analytic,
    fof_no_analytic
  ),
  denominator = c(
    NA_integer_,
    NA_integer_,
    raw_rows,
    raw_rows,
    n_valid_id,
    n_valid_id,
    n_with_fof,
    n_with_fof,
    n_with_fof,
    n_branch_eligible,
    n_branch_eligible,
    n_outcome_complete,
    n_outcome_complete,
    n_outcome_complete,
    n_analytic_primary,
    n_analytic_primary
  ),
  pct = c(
    NA_real_,
    NA_real_,
    if (raw_rows > 0) 100 * ex_id_missing / raw_rows else NA_real_,
    if (raw_rows > 0) 100 * n_valid_id / raw_rows else NA_real_,
    if (n_valid_id > 0) 100 * ex_fof_invalid / n_valid_id else NA_real_,
    if (n_valid_id > 0) 100 * n_with_fof / n_valid_id else NA_real_,
    if (n_with_fof > 0) 100 * ex_branch_structure / n_with_fof else NA_real_,
    if (n_with_fof > 0) 100 * ex_time_missing_or_invalid / n_with_fof else NA_real_,
    if (n_with_fof > 0) 100 * n_branch_eligible / n_with_fof else NA_real_,
    if (n_branch_eligible > 0) 100 * ex_outcome_missing / n_branch_eligible else NA_real_,
    if (n_branch_eligible > 0) 100 * n_outcome_complete / n_branch_eligible else NA_real_,
    if (n_outcome_complete > 0) 100 * ex_covariate_missing / n_outcome_complete else NA_real_,
    if (n_outcome_complete > 0) 100 * ex_fi22_missing_sens / n_outcome_complete else NA_real_,
    if (n_outcome_complete > 0) 100 * n_analytic_primary / n_outcome_complete else NA_real_,
    if (n_analytic_primary > 0) 100 * fof_yes_analytic / n_analytic_primary else NA_real_,
    if (n_analytic_primary > 0) 100 * fof_no_analytic / n_analytic_primary else NA_real_
  ),
  unit = c(
    "rows", "participants", "rows", "participants", "participants", "participants",
    "participants", "participants", "participants", "participants", "participants",
    "participants", "participants", "participants", "participants", "participants"
  )
)

placeholder_tbl <- bind_rows(
  tibble(
    placeholder = c(
      "GRAPH_TITLE",
      "PRIMARY_BRANCH",
      "PRIMARY_OUTCOME",
      "N_RAW_ROWS",
      "N_RAW_ID",
      "EX_ID_MISSING",
      "EX_ID_MISSING_PCT",
      "N_VALID_ID",
      "N_VALID_ID_PCT",
      "EX_FOF_MISSING_OR_INVALID",
      "EX_FOF_MISSING_OR_INVALID_PCT",
      "N_WITH_FOF",
      "N_WITH_FOF_PCT",
      "EX_BRANCH_STRUCTURE",
      "EX_BRANCH_STRUCTURE_PCT",
      "EX_TIME_MISSING_OR_INVALID",
      "N_BRANCH_ELIGIBLE",
      "N_BRANCH_ELIGIBLE_PCT",
      "EX_OUTCOME_MISSING_PRIMARY",
      "EX_OUTCOME_MISSING_PRIMARY_PCT",
      "N_OUTCOME_COMPLETE",
      "N_OUTCOME_COMPLETE_PCT",
      "EX_COVARIATE_MISSING_PRIMARY",
      "EX_COVARIATE_MISSING_PRIMARY_PCT",
      "N_ANALYTIC_PRIMARY",
      "N_ANALYTIC_PRIMARY_PCT",
      "FOF_YES_ANALYTIC",
      "FOF_YES_ANALYTIC_PCT",
      "FOF_NO_ANALYTIC",
      "FOF_NO_ANALYTIC_PCT",
      "FI22_NOTE"
    ),
    value = c(
      "Fear-of-Falling paper_01 analytic cohort derivation",
      shape,
      outcome,
      as.character(raw_rows),
      as.character(raw_id_n),
      as.character(ex_id_missing),
      format_pct(ex_id_missing, raw_rows),
      as.character(n_valid_id),
      format_pct(n_valid_id, raw_rows),
      as.character(ex_fof_invalid),
      format_pct(ex_fof_invalid, n_valid_id),
      as.character(n_with_fof),
      format_pct(n_with_fof, n_valid_id),
      as.character(ex_branch_structure),
      format_pct(ex_branch_structure, n_with_fof),
      as.character(ex_time_missing_or_invalid),
      as.character(n_branch_eligible),
      format_pct(n_branch_eligible, n_with_fof),
      as.character(ex_outcome_missing),
      format_pct(ex_outcome_missing, n_branch_eligible),
      as.character(n_outcome_complete),
      format_pct(n_outcome_complete, n_branch_eligible),
      as.character(ex_covariate_missing),
      format_pct(ex_covariate_missing, n_outcome_complete),
      as.character(n_analytic_primary),
      format_pct(n_analytic_primary, n_outcome_complete),
      as.character(fof_yes_analytic),
      format_pct(fof_yes_analytic, n_analytic_primary),
      as.character(fof_no_analytic),
      format_pct(fof_no_analytic, n_analytic_primary),
      if (fi22_enabled) {
        paste0("FI22 sensitivity enabled; excluded for FI22 completeness: ", ex_fi22_missing_sens)
      } else {
        paste0("FI22 optional sensitivity only; excluded for FI22 completeness if enabled: ", ex_fi22_missing_sens)
      }
    )
  ),
  build_missing_placeholders(missing_tbl)
)

counts_path <- write_table_with_manifest(counts_tbl, paste0(cohort_prefix, "_counts"), "Sequential participant-level cohort flow counts")
placeholders_path <- write_table_with_manifest(placeholder_tbl, paste0(cohort_prefix, "_placeholders"), "DOT placeholder values for paper_01 cohort flow")
missing_path <- write_table_with_manifest(missing_tbl, paste0(cohort_prefix, "_missingness_group_time"), "Group x time missingness summary reused for cohort flow rendering")

receipt_path <- file.path(outputs_dir, paste0(cohort_prefix, "_input_receipt.txt"))
receipt_lines <- c(
  paste0("script=", helper_label),
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("input_path=", data_path),
  paste0("input_md5=", unname(tools::md5sum(data_path))),
  paste0("shape=", shape),
  paste0("outcome=", outcome),
  paste0("rows_loaded=", raw_rows),
  paste0("participants_modeled=", n_analytic_primary),
  paste0("fi22_enabled=", fi22_enabled),
  paste0("allow_composite_z_verified=", allow_composite_z)
)
writeLines(receipt_lines, con = receipt_path)
append_manifest_safe(paste0(cohort_prefix, "_input_receipt"), "text", receipt_path, n = n_analytic_primary, notes = "Cohort flow provenance receipt")

session_path <- file.path(outputs_dir, paste0(cohort_prefix, "_sessioninfo.txt"))
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest_safe(paste0(cohort_prefix, "_sessioninfo"), "sessioninfo", session_path, notes = "K50 cohort flow session info")

message("Cohort flow outputs written to: ", outputs_dir)
message("Counts: ", counts_path)
message("Placeholders: ", placeholders_path)
message("Missingness: ", missing_path)
