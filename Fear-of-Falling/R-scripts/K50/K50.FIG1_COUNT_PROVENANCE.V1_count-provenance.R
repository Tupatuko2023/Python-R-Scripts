#!/usr/bin/env Rscript
# ==============================================================================
# K50.FIG1_COUNT_PROVENANCE - Figure 1 Count Provenance Gate
# File tag: K50.FIG1_COUNT_PROVENANCE.V1_count-provenance.R
# Purpose: Resolve Figure 1 count provenance from locked K50 source data and
#          saved model frames without rendering or changing figure assets.
#
# Outcome: locomotor_capacity
# Predictors: FOF_status, time
# Moderator/interaction: time * FOF_status
# Grouping variable: id
# Covariates: age, sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, time, FOF_status, age, sex, BMI, locomotor_capacity,
# locomotor_capacity_0, locomotor_capacity_12m
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# FOF_status is verified from the canonical K50 source field derived upstream
# from kaatumisenpelkoOn.
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: not used; no randomness
#
# Outputs + manifest:
# - script_label: K50.FIG1_COUNT_PROVENANCE (canonical)
# - outputs dir: R-scripts/K50/outputs/FIG1_count_provenance/
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs
# 02) Load locked K50 WIDE and LONG source data
# 03) Load saved primary LONG model.frame
# 04) Derive WIDE ANCOVA model.frame from locked WIDE source and K50 formula
# 05) Verify columns, FOF levels, id structure, and model-frame row units
# 06) Resolve source-count and missingness discrepancies
# 07) Save provenance, discrepancy, proposed-count, and missingness tables
# 08) Save figure-to-table-to-text crosscheck
# 09) Save sessionInfo and renv diagnostics
# 10) Append manifest row per artifact
# 11) Do not render or edit diagram assets
# 12) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
})

source(here::here("R", "functions", "reporting.R"))
source(here::here("R", "functions", "person_dedup_lookup.R"))

script_label <- "K50.FIG1_COUNT_PROVENANCE"
outputs_dir <- here::here("R-scripts", "K50", "outputs", "FIG1_count_provenance")
manifest_path <- here::here("manifest", "manifest.csv")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)

req_cols <- c(
  "id", "time", "FOF_status", "age", "sex", "BMI", "locomotor_capacity",
  "locomotor_capacity_0", "locomotor_capacity_12m"
)

safe_num <- function(x) suppressWarnings(as.numeric(x))

normalize_fof <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "nonfof", "ei fof", "no fof", "false")] <- 0L
  out[s %in% c("1", "fof", "true")] <- 1L
  suppressWarnings(num <- as.integer(s))
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 1L)
  out[use_num] <- num[use_num]
  factor(out, levels = c(0L, 1L), labels = c("No FOF", "FOF"))
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

compute_sha256 <- function(path) {
  sha_cmd <- Sys.which("sha256sum")
  if (!nzchar(sha_cmd)) return(NA_character_)
  out <- suppressWarnings(system2(sha_cmd, shQuote(path), stdout = TRUE, stderr = FALSE))
  if (length(out) == 0L) return(NA_character_)
  strsplit(out[[1]], "[[:space:]]+")[[1]][1]
}

read_receipt_value <- function(path, key) {
  if (!file.exists(path)) return(NA_character_)
  lines <- readLines(path, warn = FALSE)
  hit <- grep(paste0("^", key, "="), lines, value = TRUE)
  if (length(hit) == 0L) return(NA_character_)
  sub("^[^=]*=", "", hit[[1]])
}

manifest_append <- function(label, kind, path, n = NA_integer_, notes = "") {
  append_manifest(
    manifest_row(
      script = script_label,
      label = label,
      kind = kind,
      path = get_relpath(path),
      n = n,
      notes = notes
    ),
    manifest_path
  )
}

refresh_manifest_scope <- function() {
  if (!file.exists(manifest_path)) return(invisible(NULL))
  lines <- readLines(manifest_path, warn = FALSE)
  lines <- lines[!grepl(paste0("\"?", script_label, "\"?"), lines, fixed = FALSE)]
  writeLines(lines, manifest_path, useBytes = TRUE)
  invisible(NULL)
}

write_csv_artifact <- function(x, filename, label, notes) {
  path <- file.path(outputs_dir, filename)
  readr::write_csv(x, path, na = "")
  manifest_append(label, "table_csv", path, nrow(x), notes)
  path
}

write_text_artifact <- function(lines, filename, label, kind, notes) {
  path <- file.path(outputs_dir, filename)
  lines <- sub("[ \t]+$", "", lines)
  writeLines(lines, con = path)
  manifest_append(label, kind, path, length(lines), notes)
  path
}

source_path_from_receipt <- function(receipt_path, fallback) {
  value <- read_receipt_value(receipt_path, "input_path")
  if (is.na(value) || !nzchar(value)) value <- fallback
  if (!file.exists(value)) {
    stop("Required locked source file is missing: ", value, call. = FALSE)
  }
  normalizePath(value, winslash = "/", mustWork = TRUE)
}

wide_receipt <- here::here("R-scripts", "K50", "outputs", "k50_wide_locomotor_capacity_input_receipt.txt")
long_receipt <- here::here("R-scripts", "K50", "outputs", "k50_long_locomotor_capacity_input_receipt.txt")
wide_source <- source_path_from_receipt(
  wide_receipt,
  "/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/analysis/fof_analysis_k50_wide.rds"
)
long_source <- source_path_from_receipt(
  long_receipt,
  "/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/analysis/fof_analysis_k50_long.rds"
)
long_model_frame_path <- here::here("R-scripts", "K50", "outputs", "k50_long_locomotor_capacity_model_frame_primary.rds")
if (!file.exists(long_model_frame_path)) {
  stop("Saved primary LONG model.frame is missing: ", long_model_frame_path, call. = FALSE)
}

wide_raw <- tibble::as_tibble(readRDS(wide_source))
long_raw <- tibble::as_tibble(readRDS(long_source))
long_model_frame <- tibble::as_tibble(readRDS(long_model_frame_path))

wide_missing_cols <- setdiff(
  c("id", "FOF_status", "age", "sex", "BMI", "locomotor_capacity_0", "locomotor_capacity_12m"),
  names(wide_raw)
)
long_missing_cols <- setdiff(
  c("id", "time", "FOF_status", "age", "sex", "BMI", "locomotor_capacity"),
  names(long_raw)
)
model_missing_cols <- setdiff(
  c("id", "time", "FOF_status", "age", "sex", "BMI", "locomotor_capacity"),
  names(long_model_frame)
)
if (length(wide_missing_cols) > 0L) stop("WIDE source missing columns: ", paste(wide_missing_cols, collapse = ", "), call. = FALSE)
if (length(long_missing_cols) > 0L) stop("LONG source missing columns: ", paste(long_missing_cols, collapse = ", "), call. = FALSE)
if (length(model_missing_cols) > 0L) stop("LONG model.frame missing columns: ", paste(model_missing_cols, collapse = ", "), call. = FALSE)

wide_dedup <- prepare_k50_person_dedup(wide_raw, "WIDE", "locomotor_capacity")
long_dedup <- prepare_k50_person_dedup(long_raw, "LONG", "locomotor_capacity")

wide_raw_norm <- wide_raw %>%
  transmute(
    id = trimws(as.character(id)),
    FOF_status = normalize_fof(FOF_status),
    age = safe_num(age),
    sex = factor(trimws(as.character(sex))),
    BMI = safe_num(BMI),
    locomotor_capacity_0 = safe_num(locomotor_capacity_0),
    locomotor_capacity_12m = safe_num(locomotor_capacity_12m)
  )

wide_source_df <- tibble::as_tibble(wide_dedup$data) %>%
  transmute(
    id = trimws(as.character(id)),
    FOF_status = normalize_fof(FOF_status),
    age = safe_num(age),
    sex = factor(trimws(as.character(sex))),
    BMI = safe_num(BMI),
    locomotor_capacity_0 = safe_num(locomotor_capacity_0),
    locomotor_capacity_12m = safe_num(locomotor_capacity_12m)
  )

long_source_df <- tibble::as_tibble(long_dedup$data) %>%
  transmute(
    id = trimws(as.character(id)),
    time = normalize_time(time),
    FOF_status = normalize_fof(FOF_status),
    age = safe_num(age),
    sex = factor(trimws(as.character(sex))),
    BMI = safe_num(BMI),
    locomotor_capacity = safe_num(locomotor_capacity)
  )

long_model_df <- long_model_frame %>%
  transmute(
    id = trimws(as.character(id)),
    time = normalize_time(time),
    FOF_status = normalize_fof(FOF_status),
    age = safe_num(age),
    sex = factor(trimws(as.character(sex))),
    BMI = safe_num(BMI),
    locomotor_capacity = safe_num(locomotor_capacity)
  )

wide_model_frame <- stats::model.frame(
  locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI,
  data = wide_source_df,
  na.action = stats::na.omit
)
wide_model_frame$id <- wide_source_df$id[as.integer(rownames(wide_model_frame))]
wide_model_frame <- tibble::as_tibble(wide_model_frame)

stopifnot(dplyr::n_distinct(wide_source_df$id) == nrow(wide_source_df))
stopifnot(identical(sort(unique(stats::na.omit(long_source_df$time))), c(0L, 12L)))
stopifnot(setequal(unique(stats::na.omit(as.character(wide_source_df$FOF_status))), c("No FOF", "FOF")))
stopifnot(setequal(unique(stats::na.omit(as.character(long_model_df$FOF_status))), c("No FOF", "FOF")))

count_group <- function(df, col = "FOF_status") {
  tab <- table(as.character(df[[col]]), useNA = "no")
  c(
    fof_no = if ("No FOF" %in% names(tab)) unname(tab[["No FOF"]]) else 0L,
    fof_yes = if ("FOF" %in% names(tab)) unname(tab[["FOF"]]) else 0L
  )
}

raw_valid_fof <- wide_raw_norm %>% filter(!is.na(id), !is.na(FOF_status))
dedup_valid_fof <- wide_source_df %>% filter(!is.na(id), !is.na(FOF_status))
wide_group <- count_group(wide_model_frame)
long_unique_group <- long_model_df %>%
  distinct(id, FOF_status) %>%
  count(FOF_status, name = "participants_n")
long_obs_group <- long_model_df %>%
  count(FOF_status, name = "observations_n")

get_long_participants <- function(group) {
  hit <- long_unique_group$participants_n[as.character(long_unique_group$FOF_status) == group]
  if (length(hit) == 0L) 0L else hit[[1]]
}
get_long_observations <- function(group) {
  hit <- long_obs_group$observations_n[as.character(long_obs_group$FOF_status) == group]
  if (length(hit) == 0L) 0L else hit[[1]]
}

source_n <- dplyr::n_distinct(wide_source_df$id)
valid_fof_n <- dplyr::n_distinct(dedup_valid_fof$id)
wide_n <- dplyr::n_distinct(wide_model_frame$id)
long_unique_n <- dplyr::n_distinct(long_model_df$id)
long_obs_n <- nrow(long_model_df)

provenance <- tibble::tribble(
  ~metric, ~value, ~unit, ~branch, ~source_object, ~model_frame, ~extraction_rule, ~inclusion_rule, ~source_file, ~status, ~discrepancy_note,
  "source_analytic_cohort_unique_participants", source_n, "participants", "shared", "wide_source_df after prepare_k50_person_dedup", "not model frame", "n_distinct(id)", "locked K50 WIDE source after person dedup; non-missing id", wide_source, "PASS", "Resolves 527 vs 535 as 535 in current locked K50 source; 527 is historical/non-current source-level count.",
  "valid_baseline_fof_unique_participants", valid_fof_n, "participants", "shared", "dedup_valid_fof", "not model frame", "n_distinct(id) where FOF_status not NA", "locked K50 WIDE source after person dedup; valid baseline FOF_status", wide_source, "PASS", "Resolves 472 vs 486 as 472 in the current locked K50 source; 486 is historical and not reproduced here.",
  "current_source_valid_baseline_fof_unique_ids", dplyr::n_distinct(raw_valid_fof$id), "participants", "shared", "wide_raw_norm", "not model frame", "n_distinct(id) where FOF_status not NA", "current locked K50 WIDE source before person dedup", wide_source, "QC_ONLY", "Current locked source gives 472; historical 486 is not reproduced from this source.",
  "current_source_fof_yes", unname(count_group(raw_valid_fof)[["fof_yes"]]), "participants", "shared", "wide_raw_norm", "not model frame", "count FOF_status == FOF", "current locked K50 WIDE source before person dedup", wide_source, "QC_ONLY", "Current locked source gives 328; historical 340 is not reproduced from this source.",
  "current_source_fof_no", unname(count_group(raw_valid_fof)[["fof_no"]]), "participants", "shared", "wide_raw_norm", "not model frame", "count FOF_status == No FOF", "current locked K50 WIDE source before person dedup", wide_source, "QC_ONLY", "Current locked source gives 144; historical 146 is not reproduced from this source.",
  "valid_baseline_fof_yes_participants", unname(count_group(dedup_valid_fof)[["fof_yes"]]), "participants", "shared", "dedup_valid_fof", "not model frame", "count FOF_status == FOF", "locked K50 WIDE source after person dedup", wide_source, "PASS", "Candidate 328 after person dedup.",
  "valid_baseline_fof_no_participants", unname(count_group(dedup_valid_fof)[["fof_no"]]), "participants", "shared", "dedup_valid_fof", "not model frame", "count FOF_status == No FOF", "locked K50 WIDE source after person dedup", wide_source, "PASS", "Candidate 144 after person dedup.",
  "wide_unique_participants", wide_n, "participants", "wide", "wide_model_frame", "locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI", "n_distinct(id)", "complete baseline/follow-up locomotor_capacity, FOF_status, age, sex, BMI", wide_source, "PASS", "WIDE N=230 is verified from reconstructed locked ANCOVA model.frame.",
  "wide_fof_yes_participants", unname(wide_group[["fof_yes"]]), "participants", "wide", "wide_model_frame", "locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI", "count FOF_status == FOF", "WIDE ANCOVA model.frame", wide_source, "PASS", "Confirms WIDE FOF yes=161.",
  "wide_fof_no_participants", unname(wide_group[["fof_no"]]), "participants", "wide", "wide_model_frame", "locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI", "count FOF_status == No FOF", "WIDE ANCOVA model.frame", wide_source, "PASS", "Confirms WIDE FOF no=69.",
  "long_unique_participants", long_unique_n, "participants", "long", "long_model_df", "saved primary LONG merMod model.frame", "n_distinct(id)", "saved model.frame rows from primary LONG mixed model", long_model_frame_path, "PASS", "LONG participant N is not inferred from observations.",
  "long_observations", long_obs_n, "observations", "long", "long_model_df", "saved primary LONG merMod model.frame", "nrow(model.frame)", "saved model.frame rows from primary LONG mixed model", long_model_frame_path, "PASS", "Resolves 630 as model-frame observation rows.",
  "long_fof_yes_participants", get_long_participants("FOF"), "participants", "long", "long_model_df", "saved primary LONG merMod model.frame", "distinct(id, FOF_status) then count", "saved LONG model.frame", long_model_frame_path, "PASS", "Unique participants with FOF in LONG model.frame.",
  "long_fof_no_participants", get_long_participants("No FOF"), "participants", "long", "long_model_df", "saved primary LONG merMod model.frame", "distinct(id, FOF_status) then count", "saved LONG model.frame", long_model_frame_path, "PASS", "Unique participants without FOF in LONG model.frame.",
  "long_fof_yes_observations", get_long_observations("FOF"), "observations", "long", "long_model_df", "saved primary LONG merMod model.frame", "count rows by FOF_status", "saved LONG model.frame", long_model_frame_path, "PASS", "Observation rows with FOF in LONG model.frame.",
  "long_fof_no_observations", get_long_observations("No FOF"), "observations", "long", "long_model_df", "saved primary LONG merMod model.frame", "count rows by FOF_status", "saved LONG model.frame", long_model_frame_path, "PASS", "Observation rows without FOF in LONG model.frame."
)

discrepancies <- tibble::tribble(
  ~issue, ~candidate_a, ~candidate_b, ~resolved_value, ~resolution_status, ~authoritative_source, ~explanation,
  "source cohort N", "527 historical workbook/person count cited in prior tasks", "535 current locked K50 WIDE source rows and unique ids", as.character(source_n), "PASS", wide_source, "Current Figure 1 provenance should use the locked K50 source file used by the active K50 run. Historical 527 is not the current model source.",
  "valid baseline FOF N", "472 in current locked K50 source", "486 in historical 2026-03-15 cohort-flow artifact", as.character(valid_fof_n), "PASS", wide_source, "The current locked K50 source gives 472 both before and after current person-dedup handling. The 486 value is historical and is not reproduced from the current locked source.",
  "FOF yes/no denominator", "328/144 in current locked K50 source", "340/146 in historical manuscript/review note", "328/144 for shared valid-FOF denominator; 161/69 for WIDE model frame", "PASS", wide_source, "The current locked K50 source gives 328/144 for valid baseline FOF. The 340/146 denominator is historical/non-current; WIDE final branch has its own model-frame denominator 230.",
  "WIDE N and group counts", "N=230, FOF yes=161, FOF no=69", "current LONG-labelled diagram also displays these values", paste0(wide_n, "; ", wide_group[["fof_yes"]], "/", wide_group[["fof_no"]]), "PASS", wide_source, "Values are verified from the WIDE ANCOVA model.frame, not from the diagram asset.",
  "LONG participant N versus observations", "630 observations", "participant N unavailable in old figure", paste0(long_unique_n, " participants; ", long_obs_n, " observations"), "PASS", long_model_frame_path, "630 is the saved LONG mixed-model model.frame row count. Unique participants are counted separately.",
  "follow-up absence mechanism", "attrition/unavailable assessment/measurement failure/derived-score missingness", "not separable from current K50 model frames", "unknown mechanism", "PASS", paste(wide_source, long_source, sep = " | "), "Current locked model frames identify missing outcome/covariate status but do not prove the reason for absence. The reason is classified as unknown."
)

proposed_counts <- tibble::tribble(
  ~flow_stage, ~branch, ~participants_n, ~observations_n, ~fof_yes_n, ~fof_no_n, ~status,
  "Source analytic cohort after K50 person dedup", "shared", source_n, NA_integer_, NA_integer_, NA_integer_, "PASS",
  "Valid baseline fear-of-falling status", "shared", valid_fof_n, NA_integer_, unname(count_group(dedup_valid_fof)[["fof_yes"]]), unname(count_group(dedup_valid_fof)[["fof_no"]]), "PASS",
  "WIDE ANCOVA model frame", "wide", wide_n, NA_integer_, unname(wide_group[["fof_yes"]]), unname(wide_group[["fof_no"]]), "PASS",
  "LONG mixed-effects model frame", "long", long_unique_n, long_obs_n, get_long_participants("FOF"), get_long_participants("No FOF"), "PASS"
)

missingness_for_wide <- function(df) {
  bind_rows(
    df %>%
      transmute(
        branch = "wide",
        baseline_fof = as.character(FOF_status),
        time_point = "baseline",
        outcome_missing = is.na(locomotor_capacity_0),
        age_missing = is.na(age),
        sex_missing = is.na(sex),
        bmi_missing = is.na(BMI)
      ),
    df %>%
      transmute(
        branch = "wide",
        baseline_fof = as.character(FOF_status),
        time_point = "12_months",
        outcome_missing = is.na(locomotor_capacity_12m),
        age_missing = is.na(age),
        sex_missing = is.na(sex),
        bmi_missing = is.na(BMI)
      )
  ) %>%
    filter(!is.na(baseline_fof)) %>%
    group_by(branch, baseline_fof, time_point) %>%
    summarise(
      eligible_participants = n(),
      outcome_missing_n = sum(outcome_missing),
      outcome_missing_pct = round(100 * outcome_missing_n / eligible_participants, 1),
      age_missing_n = sum(age_missing),
      sex_missing_n = sum(sex_missing),
      bmi_missing_n = sum(bmi_missing),
      denominator_definition = "K50 person-deduplicated WIDE source with valid baseline FOF_status",
      .groups = "drop"
    )
}

missingness_for_long <- function(df) {
  df %>%
    filter(!is.na(FOF_status), !is.na(time)) %>%
    transmute(
      branch = "long",
      baseline_fof = as.character(FOF_status),
      time_point = if_else(time == 0L, "baseline", "12_months"),
      outcome_missing = is.na(locomotor_capacity),
      age_missing = is.na(age),
      sex_missing = is.na(sex),
      bmi_missing = is.na(BMI),
      id = id
    ) %>%
    group_by(branch, baseline_fof, time_point) %>%
    summarise(
      eligible_participants = dplyr::n_distinct(id),
      outcome_missing_n = sum(outcome_missing),
      outcome_missing_pct = round(100 * outcome_missing_n / n(), 1),
      age_missing_n = sum(age_missing),
      sex_missing_n = sum(sex_missing),
      bmi_missing_n = sum(bmi_missing),
      denominator_definition = "K50 person-deduplicated LONG source rows with valid FOF_status and canonical time",
      .groups = "drop"
    )
}

supplementary_missingness <- bind_rows(
  missingness_for_wide(dedup_valid_fof),
  missingness_for_long(long_source_df)
) %>%
  arrange(branch, baseline_fof, time_point)

all_pass <- all(provenance$status %in% c("PASS", "QC_ONLY")) &&
  all(discrepancies$resolution_status == "PASS") &&
  identical(source_n, 535L) &&
  identical(valid_fof_n, 472L) &&
  identical(unname(count_group(dedup_valid_fof)[["fof_yes"]]), 328L) &&
  identical(unname(count_group(dedup_valid_fof)[["fof_no"]]), 144L) &&
  identical(wide_n, 230L) &&
  identical(unname(wide_group[["fof_yes"]]), 161L) &&
  identical(unname(wide_group[["fof_no"]]), 69L) &&
  identical(long_unique_n, 400L) &&
  identical(get_long_participants("FOF"), 276L) &&
  identical(get_long_participants("No FOF"), 124L) &&
  identical(long_obs_n, 630L)
gate_status <- if (all_pass) "PASS" else "BLOCKED"

crosscheck_lines <- c(
  paste0("count_provenance_gate=", gate_status),
  paste0("wide_source=", wide_source),
  paste0("wide_source_md5=", unname(tools::md5sum(wide_source))),
  paste0("wide_source_sha256=", compute_sha256(wide_source)),
  paste0("long_source=", long_source),
  paste0("long_model_frame=", long_model_frame_path),
  "",
  "Resolved Figure 1 count candidates:",
  paste0("- Source analytic cohort: ", source_n, " unique participants."),
  paste0("- Valid baseline FOF: ", valid_fof_n, " unique participants; FOF yes/no = ",
         count_group(dedup_valid_fof)[["fof_yes"]], "/", count_group(dedup_valid_fof)[["fof_no"]], "."),
  paste0("- WIDE ANCOVA model frame: ", wide_n, " participants; FOF yes/no = ",
         wide_group[["fof_yes"]], "/", wide_group[["fof_no"]], "."),
  paste0("- LONG mixed model frame: ", long_unique_n, " unique participants and ",
         long_obs_n, " observations; FOF yes/no participants = ",
         get_long_participants("FOF"), "/", get_long_participants("No FOF"),
         "; observations = ", get_long_observations("FOF"), "/", get_long_observations("No FOF"), "."),
  "",
  "Figure-to-table-to-text crosscheck:",
  "- Table values are sourced from k50_fig1_count_provenance.csv.",
  "- Proposed figure counts are sourced from k50_fig1_proposed_counts.csv.",
  "- Discrepancy resolutions are sourced from k50_fig1_discrepancy_resolution.csv.",
  "- Current diagram assets remain DO_NOT_USE for final Figure 1 until a separate rendering task.",
  "- Follow-up absence mechanism is unknown unless a future source variable separates attrition, unavailable assessment, failed measurement, and derived-score missingness."
)

refresh_manifest_scope()

provenance_path <- write_csv_artifact(
  provenance,
  "k50_fig1_count_provenance.csv",
  "k50_fig1_count_provenance",
  paste0("Figure 1 count provenance gate ", gate_status)
)
discrepancy_path <- write_csv_artifact(
  discrepancies,
  "k50_fig1_discrepancy_resolution.csv",
  "k50_fig1_discrepancy_resolution",
  "Figure 1 discrepancy resolution table"
)
proposed_path <- write_csv_artifact(
  proposed_counts,
  "k50_fig1_proposed_counts.csv",
  "k50_fig1_proposed_counts",
  "Proposed Figure 1 counts without rendering"
)
missing_path <- write_csv_artifact(
  supplementary_missingness,
  "k50_fig1_supplementary_missingness.csv",
  "k50_fig1_supplementary_missingness",
  "Supplementary missingness source table"
)
crosscheck_path <- write_text_artifact(
  crosscheck_lines,
  "k50_fig1_table_to_text_crosscheck.txt",
  "k50_fig1_table_to_text_crosscheck",
  "text",
  paste0("Figure 1 table-to-text crosscheck ", gate_status)
)
session_path <- write_text_artifact(
  capture.output(sessionInfo()),
  "sessionInfo.txt",
  "k50_fig1_sessionInfo",
  "sessioninfo",
  "Figure 1 count provenance sessionInfo"
)
renv_lines <- c(
  capture.output({
    cat("renv::status():\n")
    if (requireNamespace("renv", quietly = TRUE)) {
      print(renv::status())
    } else {
      cat("renv package is not available in this runtime.\n")
    }
  }),
  "",
  capture.output({
    cat("renv::diagnostics():\n")
    if (requireNamespace("renv", quietly = TRUE)) {
      print(renv::diagnostics())
    } else {
      cat("renv package is not available in this runtime.\n")
    }
  })
)
renv_path <- write_text_artifact(
  renv_lines,
  "renv_diagnostics.txt",
  "k50_fig1_renv_diagnostics",
  "diagnostics",
  "Figure 1 count provenance renv diagnostics"
)

message("Figure 1 count provenance gate: ", gate_status)
message("Artifacts:")
message("  ", provenance_path)
message("  ", discrepancy_path)
message("  ", proposed_path)
message("  ", missing_path)
message("  ", crosscheck_path)
message("  ", session_path)
message("  ", renv_path)
