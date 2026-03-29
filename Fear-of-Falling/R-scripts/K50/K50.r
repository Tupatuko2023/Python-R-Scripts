#!/usr/bin/env Rscript
# ==============================================================================
# K50 - Confirmatory FOF Locomotor Capacity Analysis
# File tag: K50.V1_confirmatory-fof-locomotor-analysis.R
# Purpose: Run the K50 analysis with explicit shape/outcome gates using only
#          verified upstream analysis-ready outcomes and standard repo outputs.
#
# Outcome: locomotor_capacity | z3 | Composite_Z
# Predictors: FOF_status, time
# Moderator/interaction: time * FOF_status
# Grouping variable: id
# Covariates: age, sex, BMI, FI22_nonperformance_KAAOS (sensitivity only)
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
# - script_label: K50 (canonical)
# - outputs dir: R-scripts/K50/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Resolve input path from CLI / verified upstream candidates
# 03) Load analysis-ready data (immutable; no edits)
# 04) Enforce explicit shape + outcome gates and validate required columns
# 05) Recode canonical time/FOF levels and run QC gates
# 06) Fit primary model for selected branch
# 07) Fit z3 fallback / sensitivity model where contract requires it
# 08) Fit FI22 sensitivity only when explicitly enabled
# 09) Save aggregate artifacts -> R-scripts/K50/outputs/
# 10) Append manifest row per artifact
# 11) Save sessionInfo to manifest/
# 12) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(tibble)
  library(here)
  library(lme4)
  library(lmerTest)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.[Rr]$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K50"
}
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K50"

source(here::here("R", "functions", "reporting.R"))
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
    stop("K50 requires explicit --shape LONG|WIDE. AUTO is not allowed for primary runs.", call. = FALSE)
  }
  val
}

parse_outcome <- function(x) {
  val <- trimws(ifelse(is.null(x), "", as.character(x)))
  if (!val %in% c("locomotor_capacity", "z3", "Composite_Z")) {
    stop("K50 requires --outcome locomotor_capacity|z3|Composite_Z.", call. = FALSE)
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

read_key_value_file <- function(path) {
  lines <- readLines(path, warn = FALSE)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines)]
  keys <- sub("=.*$", "", lines)
  vals <- sub("^[^=]*=", "", lines)
  stats::setNames(as.list(vals), keys)
}

compute_sha256 <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)
  sha_cmd <- Sys.which("sha256sum")
  if (nzchar(sha_cmd)) {
    out <- suppressWarnings(system2(sha_cmd, shQuote(path), stdout = TRUE, stderr = FALSE))
    if (length(out) > 0L && nzchar(out[[1]])) return(strsplit(out[[1]], "[[:space:]]+")[[1]][1])
  }
  shasum_cmd <- Sys.which("shasum")
  if (nzchar(shasum_cmd)) {
    out <- suppressWarnings(system2(shasum_cmd, c("-a", "256", shQuote(path)), stdout = TRUE, stderr = FALSE))
    if (length(out) > 0L && nzchar(out[[1]])) return(strsplit(out[[1]], "[[:space:]]+")[[1]][1])
  }
  stop("K50 could not compute SHA-256 for input path: ", path, call. = FALSE)
}

resolve_authoritative_wide_input <- function() {
  lock_path <- here::here("R-scripts", "K50", "k50_wide_authoritative_input.lock")
  if (!file.exists(lock_path)) {
    stop("K50 WIDE authoritative input lock is missing: ", lock_path, call. = FALSE)
  }
  lock <- read_key_value_file(lock_path)
  required <- c("snapshot_role", "snapshot_id", "path", "md5", "sha256")
  missing <- required[!required %in% names(lock) | !nzchar(unlist(lock[required]))]
  if (length(missing) > 0L) {
    stop("K50 WIDE authoritative input lock is missing keys: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  if (!file.exists(lock$path)) {
    stop("K50 WIDE authoritative input path not found: ", lock$path, call. = FALSE)
  }
  resolved_path <- normalizePath(lock$path, winslash = "/", mustWork = TRUE)
  actual_md5 <- unname(tools::md5sum(resolved_path))
  actual_sha256 <- compute_sha256(resolved_path)
  if (!identical(actual_md5, lock$md5)) {
    stop(
      "K50 WIDE authoritative input md5 mismatch.\n",
      "Expected: ", lock$md5, "\n",
      "Actual: ", actual_md5, "\n",
      "Path: ", resolved_path,
      call. = FALSE
    )
  }
  if (!identical(actual_sha256, lock$sha256)) {
    stop(
      "K50 WIDE authoritative input sha256 mismatch.\n",
      "Expected: ", lock$sha256, "\n",
      "Actual: ", actual_sha256, "\n",
      "Path: ", resolved_path,
      call. = FALSE
    )
  }
  list(
    path = resolved_path,
    resolution = "authoritative_lock",
    lock_path = normalizePath(lock_path, winslash = "/", mustWork = TRUE),
    snapshot_role = lock$snapshot_role,
    snapshot_id = lock$snapshot_id,
    expected_md5 = lock$md5,
    expected_sha256 = lock$sha256,
    rows_loaded_expected = if ("rows_loaded_expected" %in% names(lock)) lock$rows_loaded_expected else NA_character_,
    selection_reason = if ("selection_reason" %in% names(lock)) lock$selection_reason else NA_character_
  )
}

resolve_input_path <- function(shape, cli_data) {
  if (!is.null(cli_data) && nzchar(cli_data)) {
    if (!file.exists(cli_data)) {
      stop("K50 --data file not found: ", cli_data, call. = FALSE)
    }
    path <- normalizePath(cli_data, winslash = "/", mustWork = TRUE)
    return(list(
      path = path,
      resolution = "cli_override",
      lock_path = NA_character_,
      snapshot_role = "cli_override",
      snapshot_id = basename(path),
      expected_md5 = unname(tools::md5sum(path)),
      expected_sha256 = compute_sha256(path),
      rows_loaded_expected = NA_character_,
      selection_reason = "explicit_cli_override"
    ))
  }

  if (identical(shape, "WIDE")) {
    return(resolve_authoritative_wide_input())
  }

  shape_lower <- tolower(shape)
  data_root <- resolve_data_root()
  candidates <- c()
  if (!is.na(data_root)) {
    candidates <- c(
      candidates,
      file.path(data_root, "paper_02", "analysis", paste0("fof_analysis_k50_", shape_lower, ".rds")),
      file.path(data_root, "paper_02", "analysis", paste0("fof_analysis_k50_", shape_lower, ".csv")),
      file.path(data_root, "paper_02", "analysis", paste0("fof_analysis_k33_", shape_lower, ".rds")),
      file.path(data_root, "paper_02", "analysis", paste0("fof_analysis_k33_", shape_lower, ".csv"))
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
        "K50 could not resolve an input dataset. Supply --data explicitly or create a verified upstream K50 dataset.\n",
        "Tried:\n- ", paste(candidates, collapse = "\n- ")
      ),
      call. = FALSE
    )
  }
  list(
    path = hit,
    resolution = "legacy_candidate_fallback",
    lock_path = NA_character_,
    snapshot_role = "legacy_candidate_fallback",
    snapshot_id = basename(hit),
    expected_md5 = unname(tools::md5sum(hit)),
    expected_sha256 = compute_sha256(hit),
    rows_loaded_expected = NA_character_,
    selection_reason = "legacy_candidate_search"
  )
}

read_dataset <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") return(as_tibble(readRDS(path)))
  if (ext == "csv") return(as_tibble(readr::read_csv(path, show_col_types = FALSE)))
  stop("Unsupported input extension: ", ext, call. = FALSE)
}

safe_num <- function(x) suppressWarnings(as.numeric(x))

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
  factor(trimws(as.character(x)))
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

tidy_lm <- function(model) {
  sm <- summary(model)$coefficients
  ci <- suppressWarnings(confint(model))
  tibble(
    term = rownames(sm),
    estimate = sm[, "Estimate"],
    std.error = sm[, "Std. Error"],
    statistic = sm[, grep("value", colnames(sm), value = TRUE)[1]],
    p.value = sm[, grep("Pr\\(", colnames(sm), value = TRUE)[1]],
    conf.low = ci[rownames(sm), 1],
    conf.high = ci[rownames(sm), 2]
  )
}

tidy_lmer <- function(model) {
  if (requireNamespace("broom.mixed", quietly = TRUE)) {
    return(broom.mixed::tidy(model, effects = "fixed", conf.int = TRUE))
  }
  sm <- summary(model)$coefficients
  p_col <- grep("Pr\\(", colnames(sm), value = TRUE)
  stat_col <- grep("(t value|z value)", colnames(sm), value = TRUE)
  out <- tibble(
    term = rownames(sm),
    estimate = sm[, "Estimate"],
    std.error = sm[, "Std. Error"],
    statistic = if (length(stat_col) > 0) sm[, stat_col[1]] else NA_real_,
    p.value = if (length(p_col) > 0) sm[, p_col[1]] else NA_real_
  )
  ci <- tryCatch(confint(model, parm = "beta_", method = "Wald"), error = function(e) NULL)
  if (is.null(ci)) {
    out %>% mutate(conf.low = NA_real_, conf.high = NA_real_)
  } else {
    out %>% left_join(
      tibble(term = rownames(ci), conf.low = ci[, 1], conf.high = ci[, 2]),
      by = "term"
    )
  }
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

source(here::here("R", "functions", "person_dedup_lookup.R"))

fit_branch_model <- function(df, shape, outcome, fi22_enabled = FALSE) {
  fi22_term <- if (fi22_enabled) " + FI22_nonperformance_KAAOS" else ""
  if (shape == "WIDE") {
    formula_text <- paste0(
      outcome, "_12m ~ ", outcome, "_0 + FOF_status + age + sex + BMI", fi22_term
    )
    model <- stats::lm(stats::as.formula(formula_text), data = df)
    return(list(model = model, table = tidy_lm(model), formula = formula_text))
  }

  formula_text <- paste0(
    outcome, " ~ time * FOF_status + age + sex + BMI", fi22_term, " + (1 | id)"
  )
  model <- lmerTest::lmer(stats::as.formula(formula_text), data = df, REML = FALSE)
  list(model = model, table = tidy_lmer(model), formula = formula_text)
}

write_table_with_manifest <- function(tbl, prefix, suffix, notes) {
  out_path <- file.path(outputs_dir, paste0(prefix, "_", suffix, ".csv"))
  readr::write_csv(tbl, out_path, na = "")
  append_manifest_safe(
    label = paste0(prefix, "_", suffix),
    kind = "table_csv",
    path = out_path,
    n = nrow(tbl),
    notes = notes
  )
  out_path
}

# --- CLI ----------------------------------------------------------------------
shape <- parse_shape(get_arg("--shape"))
outcome <- parse_outcome(get_arg("--outcome", "locomotor_capacity"))
fi22_enabled <- parse_toggle(get_arg("--fi22", "off"), "--fi22")
allow_composite_z <- identical(toupper(get_arg("--allow-composite-z", "off")), "VERIFIED")
data_ref <- resolve_input_path(shape, get_arg("--data"))
data_path <- data_ref$path

if (identical(outcome, "Composite_Z") && !allow_composite_z) {
  stop(
    "Composite_Z is legacy bridge only. Re-run with --allow-composite-z VERIFIED after verifying the original definition.",
    call. = FALSE
  )
}

# --- Load ---------------------------------------------------------------------
raw_input_df <- read_dataset(data_path)
raw_rows_loaded <- nrow(raw_input_df)
input_md5 <- unname(tools::md5sum(data_path))
input_sha256 <- compute_sha256(data_path)
ddup <- prepare_k50_person_dedup(raw_input_df, shape, outcome)
input_df <- ddup$data
rows_after_person_dedup <- nrow(input_df)
source_ext <- tolower(tools::file_ext(data_path))
id_col <- first_present(names(input_df), c("id"))
fof_col <- first_present(names(input_df), c("FOF_status"))
age_col <- first_present(names(input_df), c("age"))
sex_col <- first_present(names(input_df), c("sex"))
bmi_col <- first_present(names(input_df), c("BMI"))

base_required <- c(id_col, fof_col, age_col, sex_col, bmi_col)
if (any(is.na(base_required))) {
  miss <- c("id", "FOF_status", "age", "sex", "BMI")[is.na(base_required)]
  stop("K50 input is missing required canonical covariates: ", paste(miss, collapse = ", "), call. = FALSE)
}

prefix <- paste("k50", tolower(shape), outcome, sep = "_")
decision_lines <- c(
  "K50 confirmatory run",
  paste0("input_path=", data_path),
  paste0("input_resolution=", data_ref$resolution),
  paste0("authoritative_lock_path=", ifelse(is.na(data_ref$lock_path), "NA", data_ref$lock_path)),
  paste0("authoritative_snapshot_role=", data_ref$snapshot_role),
  paste0("authoritative_snapshot_id=", data_ref$snapshot_id),
  paste0("input_md5=", input_md5),
  paste0("input_sha256=", input_sha256),
  paste0("shape=", shape),
  paste0("outcome=", outcome),
  paste0("rows_loaded_raw=", raw_rows_loaded),
  paste0("rows_after_person_dedup=", rows_after_person_dedup),
  paste0("n_raw_person_lookup=", ddup$diagnostics$n_raw_person_lookup),
  paste0("ex_duplicate_person_lookup=", ddup$diagnostics$ex_duplicate_person_lookup),
  paste0("ex_duplicate_person_rows=", ddup$diagnostics$ex_duplicate_person_rows),
  paste0("ex_person_conflict_ambiguous=", ddup$diagnostics$ex_person_conflict_ambiguous),
  paste0("fi22_enabled=", fi22_enabled),
  paste0("allow_composite_z_verified=", allow_composite_z),
  "Canonical naming discipline is enforced. K50 does not invent ad hoc outcome aliases."
)

# --- Prepare analysis frame ---------------------------------------------------
if (shape == "LONG") {
  time_col <- first_present(names(input_df), c("time"))
  outcome_col <- resolve_long_col(outcome, names(input_df))
  z3_col <- resolve_long_col("z3", names(input_df))
  fi22_col <- first_present(names(input_df), c("FI22_nonperformance_KAAOS"))

  if (is.na(time_col)) {
    stop("K50 LONG input requires canonical time column `time`.", call. = FALSE)
  }
  if (is.na(outcome_col)) {
    stop(
      "K50 LONG input is missing canonical outcome column `", outcome, "`.\n",
      "Refusing to substitute undocumented aliases. Upstream must provide the verified branch explicitly.",
      call. = FALSE
    )
  }
  if (identical(outcome, "locomotor_capacity") && is.na(z3_col)) {
    stop("K50 requires canonical `z3` in LONG data for the mandated fallback/sensitivity branch.", call. = FALSE)
  }
  if (fi22_enabled && is.na(fi22_col)) {
    stop("K50 --fi22 on requires canonical `FI22_nonperformance_KAAOS`.", call. = FALSE)
  }

  analysis_df <- input_df %>%
    transmute(
      id = trimws(as.character(.data[[id_col]])),
      time = normalize_time(.data[[time_col]]),
      FOF_status = normalize_fof(.data[[fof_col]]),
      age = safe_num(.data[[age_col]]),
      sex = normalize_sex(.data[[sex_col]]),
      BMI = safe_num(.data[[bmi_col]]),
      locomotor_capacity = if ("locomotor_capacity" %in% names(input_df)) safe_num(.data[["locomotor_capacity"]]) else NA_real_,
      z3 = if ("z3" %in% names(input_df)) safe_num(.data[["z3"]]) else NA_real_,
      Composite_Z = if ("Composite_Z" %in% names(input_df)) safe_num(.data[["Composite_Z"]]) else NA_real_,
      FI22_nonperformance_KAAOS = if (!is.na(fi22_col)) safe_num(.data[[fi22_col]]) else NA_real_,
      tasapainovaikeus = if ("tasapainovaikeus" %in% names(input_df)) .data[["tasapainovaikeus"]] else NA
    ) %>%
    arrange(id, time)

  long_counts <- analysis_df %>% count(id, name = "n_time")
  levels_ok <- identical(sort(unique(stats::na.omit(analysis_df$time))), c(0L, 12L))
  shape_ok <- dplyr::n_distinct(analysis_df$id) < nrow(analysis_df)
  pair_ok <- nrow(long_counts) > 0 && all(long_counts$n_time == 2L)

  missing_tbl <- analysis_df %>%
    transmute(
      FOF_status = as.character(FOF_status),
      time = time,
      outcome_missing = is.na(.data[[outcome]]),
      age_missing = is.na(age),
      sex_missing = is.na(sex),
      bmi_missing = is.na(BMI)
    ) %>%
    group_by(FOF_status, time) %>%
    summarise(
      n = n(),
      outcome_missing_n = sum(outcome_missing),
      age_missing_n = sum(age_missing),
      sex_missing_n = sum(sex_missing),
      bmi_missing_n = sum(bmi_missing),
      .groups = "drop"
    )

  model_df <- analysis_df %>%
    filter(!is.na(.data[[outcome]]), !is.na(time), !is.na(FOF_status), !is.na(age), !is.na(sex), !is.na(BMI))
  if (fi22_enabled) {
    model_df <- model_df %>% filter(!is.na(FI22_nonperformance_KAAOS))
  }
} else {
  wide_outcome_cols <- resolve_wide_cols(outcome, names(input_df))
  wide_z3_cols <- resolve_wide_cols("z3", names(input_df))
  fi22_col <- first_present(names(input_df), c("FI22_nonperformance_KAAOS"))

  if (any(is.na(unlist(wide_outcome_cols)))) {
    stop(
      "K50 WIDE input is missing canonical columns for `", outcome, "`: ",
      paste(names(wide_outcome_cols)[is.na(unlist(wide_outcome_cols))], collapse = ", "),
      ". Refusing undocumented substitutions.",
      call. = FALSE
    )
  }
  if (identical(outcome, "locomotor_capacity") && any(is.na(unlist(wide_z3_cols)))) {
    stop("K50 requires canonical `z3_0` and `z3_12m` in WIDE data for the mandated fallback/sensitivity branch.", call. = FALSE)
  }
  if (fi22_enabled && is.na(fi22_col)) {
    stop("K50 --fi22 on requires canonical `FI22_nonperformance_KAAOS`.", call. = FALSE)
  }

  analysis_df <- input_df %>%
    transmute(
      id = trimws(as.character(.data[[id_col]])),
      FOF_status = normalize_fof(.data[[fof_col]]),
      age = safe_num(.data[[age_col]]),
      sex = normalize_sex(.data[[sex_col]]),
      BMI = safe_num(.data[[bmi_col]]),
      locomotor_capacity_0 = if ("locomotor_capacity_0" %in% names(input_df)) safe_num(.data[["locomotor_capacity_0"]]) else NA_real_,
      locomotor_capacity_12m = if ("locomotor_capacity_12m" %in% names(input_df)) safe_num(.data[["locomotor_capacity_12m"]]) else NA_real_,
      z3_0 = if ("z3_0" %in% names(input_df)) safe_num(.data[["z3_0"]]) else NA_real_,
      z3_12m = if ("z3_12m" %in% names(input_df)) safe_num(.data[["z3_12m"]]) else NA_real_,
      Composite_Z_0 = if ("Composite_Z_0" %in% names(input_df)) safe_num(.data[["Composite_Z_0"]]) else if ("Composite_Z_baseline" %in% names(input_df)) safe_num(.data[["Composite_Z_baseline"]]) else NA_real_,
      Composite_Z_12m = if ("Composite_Z_12m" %in% names(input_df)) safe_num(.data[["Composite_Z_12m"]]) else NA_real_,
      FI22_nonperformance_KAAOS = if (!is.na(fi22_col)) safe_num(.data[[fi22_col]]) else NA_real_,
      tasapainovaikeus = if ("tasapainovaikeus" %in% names(input_df)) .data[["tasapainovaikeus"]] else NA
    )

  shape_ok <- dplyr::n_distinct(analysis_df$id) == nrow(analysis_df)
  levels_ok <- TRUE
  pair_ok <- TRUE

  missing_tbl <- bind_rows(
    analysis_df %>%
      transmute(FOF_status = as.character(FOF_status), time = 0L, outcome_missing = is.na(.data[[paste0(outcome, "_0")]]), age_missing = is.na(age), sex_missing = is.na(sex), bmi_missing = is.na(BMI)),
    analysis_df %>%
      transmute(FOF_status = as.character(FOF_status), time = 12L, outcome_missing = is.na(.data[[paste0(outcome, "_12m")]]), age_missing = is.na(age), sex_missing = is.na(sex), bmi_missing = is.na(BMI))
  ) %>%
    group_by(FOF_status, time) %>%
    summarise(
      n = n(),
      outcome_missing_n = sum(outcome_missing),
      age_missing_n = sum(age_missing),
      sex_missing_n = sum(sex_missing),
      bmi_missing_n = sum(bmi_missing),
      .groups = "drop"
    )

  model_df <- analysis_df %>%
    filter(
      !is.na(.data[[paste0(outcome, "_0")]]),
      !is.na(.data[[paste0(outcome, "_12m")]]),
      !is.na(FOF_status),
      !is.na(age),
      !is.na(sex),
      !is.na(BMI)
    )
  if (fi22_enabled) {
    model_df <- model_df %>% filter(!is.na(FI22_nonperformance_KAAOS))
  }
}

fof_values <- sort(unique(as.character(stats::na.omit(analysis_df$FOF_status))))
fof_levels_ok <- identical(fof_values, c("0", "1"))
gates_tbl <- tibble(
  check = c(
    "shape_matches_declared_branch",
    "time_exact_levels_0_12",
    "id_structure_matches_shape",
    "fof_status_levels_0_1",
    "outcome_branch_labeled",
    "fi22_gate",
    "composite_z_gate",
    "grip_excluded_from_core_branch"
  ),
  ok = c(
    shape_ok,
    levels_ok,
    pair_ok,
    fof_levels_ok,
    TRUE,
    !fi22_enabled || "FI22_nonperformance_KAAOS" %in% names(analysis_df),
    !identical(outcome, "Composite_Z") || allow_composite_z,
    TRUE
  ),
  detail = c(
    paste0("shape=", shape),
    if (shape == "LONG") paste(sort(unique(stats::na.omit(analysis_df$time))), collapse = ";") else "wide_branch",
    if (shape == "LONG") paste0("all_ids_have_two_rows=", pair_ok) else paste0("nrow=", nrow(analysis_df), "; n_distinct_id=", dplyr::n_distinct(analysis_df$id)),
    paste(fof_values, collapse = ";"),
    outcome,
    if (fi22_enabled) "enabled" else "disabled",
    if (identical(outcome, "Composite_Z")) "verified_bridge_enabled" else "not_requested",
    "K50 never merges grip into locomotor outcome construction."
  )
)

if (nrow(model_df) == 0) {
  stop("K50 model frame is empty after QC filtering.", call. = FALSE)
}
if (!all(gates_tbl$ok)) {
  gates_path <- write_table_with_manifest(gates_tbl, prefix, "qc_gates", "K50 QC gates")
  stop("K50 QC gates failed. See: ", gates_path, call. = FALSE)
}

# --- Models -------------------------------------------------------------------
primary_fit <- fit_branch_model(model_df, shape, outcome, fi22_enabled = FALSE)
primary_tbl <- primary_fit$table %>%
  mutate(branch = tolower(shape), outcome = outcome, model_role = "primary", formula = primary_fit$formula, n = nrow(model_df))

primary_model_path <- NA_character_
primary_frame_path <- NA_character_
if (shape == "LONG") {
  primary_model_path <- file.path(outputs_dir, paste0(prefix, "_model_primary.rds"))
  saveRDS(primary_fit$model, primary_model_path)
  append_manifest_safe(
    label = paste0(prefix, "_model_primary"),
    kind = "model_rds",
    path = primary_model_path,
    n = nrow(model_df),
    notes = "Exact primary fitted model object for downstream K50 predictions"
  )

  primary_frame_path <- file.path(outputs_dir, paste0(prefix, "_model_frame_primary.rds"))
  saveRDS(stats::model.frame(primary_fit$model), primary_frame_path)
  append_manifest_safe(
    label = paste0(prefix, "_model_frame_primary"),
    kind = "data_rds",
    path = primary_frame_path,
    n = nrow(stats::model.frame(primary_fit$model)),
    notes = "Exact analysis frame used for the primary K50 mixed model"
  )
}

fallback_tbl <- NULL
if (identical(outcome, "locomotor_capacity")) {
  fallback_df <- if (shape == "LONG") {
    model_df %>% filter(!is.na(z3))
  } else {
    model_df %>% filter(!is.na(z3_0), !is.na(z3_12m))
  }
  if (nrow(fallback_df) == 0) {
    stop("K50 z3 fallback branch has no complete cases after QC filtering.", call. = FALSE)
  }
  fallback_fit <- fit_branch_model(fallback_df, shape, "z3", fi22_enabled = FALSE)
  fallback_tbl <- fallback_fit$table %>%
    mutate(branch = tolower(shape), outcome = "z3", model_role = "fallback_sensitivity", formula = fallback_fit$formula, n = nrow(fallback_df))
  decision_lines <- c(decision_lines, "Fallback z3 branch executed in parallel with locomotor_capacity.")
}

fi22_tbl <- NULL
if (fi22_enabled) {
  fi22_fit <- fit_branch_model(model_df, shape, outcome, fi22_enabled = TRUE)
  fi22_tbl <- fi22_fit$table %>%
    mutate(branch = tolower(shape), outcome = outcome, model_role = "fi22_sensitivity", formula = fi22_fit$formula, n = nrow(model_df))
  decision_lines <- c(decision_lines, "FI22 sensitivity executed with FI22_nonperformance_KAAOS as a separate external index.")
} else {
  decision_lines <- c(decision_lines, "FI22 sensitivity disabled.")
}

if (identical(outcome, "Composite_Z")) {
  decision_lines <- c(decision_lines, "Composite_Z executed only as a verified legacy bridge branch.")
}

# --- Write outputs ------------------------------------------------------------
gates_path <- write_table_with_manifest(gates_tbl, prefix, "qc_gates", "K50 QC gates")
missing_path <- write_table_with_manifest(missing_tbl, prefix, "missingness_group_time", "Group x time missingness summary")
primary_path <- write_table_with_manifest(primary_tbl, prefix, "model_terms_primary", "K50 selected branch model terms")
if (!is.null(fallback_tbl)) {
  fallback_path <- write_table_with_manifest(fallback_tbl, paste("k50", tolower(shape), "z3", sep = "_"), "model_terms_fallback", "K50 z3 fallback model terms")
} else {
  fallback_path <- NA_character_
}
if (!is.null(fi22_tbl)) {
  fi22_path <- write_table_with_manifest(fi22_tbl, prefix, "model_terms_fi22", "K50 FI22 sensitivity model terms")
} else {
  fi22_path <- NA_character_
}

receipt_path <- file.path(outputs_dir, paste0(prefix, "_input_receipt.txt"))
receipt_lines <- c(
  paste0("script=", script_label),
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("input_path=", data_path),
  paste0("input_resolution=", data_ref$resolution),
  paste0("authoritative_lock_path=", ifelse(is.na(data_ref$lock_path), "NA", data_ref$lock_path)),
  paste0("authoritative_snapshot_role=", data_ref$snapshot_role),
  paste0("authoritative_snapshot_id=", data_ref$snapshot_id),
  paste0("input_md5=", input_md5),
  paste0("input_sha256=", input_sha256),
  paste0("input_ext=", source_ext),
  paste0("shape=", shape),
  paste0("outcome=", outcome),
  paste0("rows_loaded=", raw_rows_loaded),
  paste0("rows_after_person_dedup=", rows_after_person_dedup),
  paste0("n_raw_person_lookup=", ddup$diagnostics$n_raw_person_lookup),
  paste0("ex_duplicate_person_lookup=", ddup$diagnostics$ex_duplicate_person_lookup),
  paste0("ex_duplicate_person_rows=", ddup$diagnostics$ex_duplicate_person_rows),
  paste0("ex_person_conflict_ambiguous=", ddup$diagnostics$ex_person_conflict_ambiguous),
  paste0("rows_modeled=", nrow(model_df)),
  paste0("fi22_enabled=", fi22_enabled),
  paste0("allow_composite_z_verified=", allow_composite_z)
)
writeLines(receipt_lines, con = receipt_path)
append_manifest_safe(
  label = paste0(prefix, "_input_receipt"),
  kind = "text",
  path = receipt_path,
  n = nrow(model_df),
  notes = "K50 input provenance receipt"
)

modeled_counts <- table(as.character(stats::na.omit(model_df$FOF_status)))
modeled_fof0_n <- if ("0" %in% names(modeled_counts)) unname(modeled_counts[["0"]]) else 0L
modeled_fof1_n <- if ("1" %in% names(modeled_counts)) unname(modeled_counts[["1"]]) else 0L
provenance_path <- file.path(outputs_dir, paste0(prefix, "_modeled_cohort_provenance.txt"))
provenance_lines <- c(
  paste0("script=", script_label),
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("shape=", shape),
  paste0("outcome=", outcome),
  paste0("input_path=", data_path),
  paste0("input_resolution=", data_ref$resolution),
  paste0("authoritative_lock_path=", ifelse(is.na(data_ref$lock_path), "NA", data_ref$lock_path)),
  paste0("authoritative_snapshot_role=", data_ref$snapshot_role),
  paste0("authoritative_snapshot_id=", data_ref$snapshot_id),
  paste0("input_md5=", input_md5),
  paste0("input_sha256=", input_sha256),
  paste0("rows_loaded_raw=", raw_rows_loaded),
  paste0("rows_after_person_dedup=", rows_after_person_dedup),
  paste0("modeled_n=", nrow(model_df)),
  paste0("modeled_fof0_n=", modeled_fof0_n),
  paste0("modeled_fof1_n=", modeled_fof1_n),
  paste0(
    "modeled_filter_contract=",
    if (shape == "WIDE") {
      paste(
        c(
          paste0(outcome, "_0"),
          paste0(outcome, "_12m"),
          "FOF_status",
          "age",
          "sex",
          "BMI",
          if (fi22_enabled) "FI22_nonperformance_KAAOS" else NULL
        ),
        collapse = " | "
      )
    } else {
      paste(
        c(
          outcome,
          "time",
          "FOF_status",
          "age",
          "sex",
          "BMI",
          if (fi22_enabled) "FI22_nonperformance_KAAOS" else NULL
        ),
        collapse = " | "
      )
    }
  ),
  paste0("n_raw_person_lookup=", ddup$diagnostics$n_raw_person_lookup),
  paste0("ex_duplicate_person_lookup=", ddup$diagnostics$ex_duplicate_person_lookup),
  paste0("ex_duplicate_person_rows=", ddup$diagnostics$ex_duplicate_person_rows),
  paste0("ex_person_conflict_ambiguous=", ddup$diagnostics$ex_person_conflict_ambiguous)
)
writeLines(provenance_lines, con = provenance_path)
append_manifest_safe(
  label = paste0(prefix, "_modeled_cohort_provenance"),
  kind = "text",
  path = provenance_path,
  n = nrow(model_df),
  notes = "K50 modeled cohort provenance export from the same canonical run"
)

decision_lines <- c(
  decision_lines,
  paste0("primary_terms_path=", primary_path),
  paste0("primary_model_path=", ifelse(is.na(primary_model_path), "NA", primary_model_path)),
  paste0("primary_model_frame_path=", ifelse(is.na(primary_frame_path), "NA", primary_frame_path)),
  paste0("fallback_terms_path=", ifelse(is.na(fallback_path), "NA", fallback_path)),
  paste0("fi22_terms_path=", ifelse(is.na(fi22_path), "NA", fi22_path)),
  paste0("qc_gates_path=", gates_path),
  paste0("missingness_path=", missing_path)
)
decision_path <- file.path(outputs_dir, paste0(prefix, "_decision_log.txt"))
writeLines(decision_lines, con = decision_path)
append_manifest_safe(
  label = paste0(prefix, "_decision_log"),
  kind = "text",
  path = decision_path,
  n = nrow(model_df),
  notes = "K50 branch decisions and contract gates"
)

session_path <- file.path(outputs_dir, paste0(prefix, "_sessioninfo.txt"))
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest_safe(
  label = paste0(prefix, "_sessioninfo"),
  kind = "sessioninfo",
  path = session_path,
  notes = "K50 session info"
)

message("K50 outputs written to: ", outputs_dir)
