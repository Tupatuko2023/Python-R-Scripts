#!/usr/bin/env Rscript
# ==============================================================================
# K20 - Duplicate Person Diagnostics
# File tag: K20_duplicate_person_diagnostics.R
# Purpose: Classify workbook-derived duplicate persons at aggregate-only level
#          after the verified K50 person-dedup bridge has been applied.
#
# Required vars (canonical K50 LONG input):
# id, time, FOF_status, age, sex, BMI, locomotor_capacity, FI22_nonperformance_KAAOS
#
# Outputs + manifest:
# - script_label: K20
# - outputs dir: R-scripts/K20/outputs/
# - manifest: append 1 row per artifact to manifest/manifest.csv
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(tibble)
  library(here)
})

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "person_dedup_lookup.R"))
paths <- init_paths("K20")
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  row <- data.frame(
    timestamp = as.character(Sys.time()),
    script = "K20",
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

normalize_time <- pd_normalize_time
normalize_fof <- function(x) as.integer(as.character(pd_normalize_fof(x)))
normalize_sex <- function(x) as.character(pd_normalize_sex(x))
safe_num <- pd_safe_num

row_signature <- function(df) {
  cols <- c("time", "FOF_status", "age", "sex", "BMI", "outcome_value", "FI22_nonperformance_KAAOS")
  ordered <- df[order(df$time, na.last = TRUE), cols, drop = FALSE]
  sig <- apply(ordered, 1, function(row) paste(ifelse(is.na(row), "<NA>", as.character(row)), collapse = "|"))
  paste(sig, collapse = "||")
}

count_non_missing <- function(df, cols) {
  if (length(cols) == 0L) return(0L)
  sum(!is.na(as.data.frame(df[, cols, drop = FALSE])))
}

detect_k50_ambiguous <- function(person_df) {
  pd_is_ambiguous_long_person(
    person_df = person_df,
    compare_cols = c("time", "FOF_status", "age", "sex", "BMI", "outcome_value", "FI22_nonperformance_KAAOS")
  )
}

has_conflict <- function(x) {
  vals <- unique(stats::na.omit(x))
  length(vals) > 1L
}

pair_conflict <- function(df, value_col) {
  if (!"time" %in% names(df)) return(FALSE)
  parts <- split(df[[value_col]], df$time)
  any(vapply(parts, has_conflict, logical(1)))
}

categorize_person <- function(person_df) {
  if (nrow(person_df) == 0L) {
    return(list(
      category = "UNKNOWN",
      k50_ambiguous = FALSE,
      fof_conflict = FALSE,
      outcome_pair_conflict = FALSE,
      covariate_conflict = FALSE,
      complementary_missingness = FALSE,
      ids_linked_n = 0L,
      canonical_rows_n = 0L
    ))
  }

  candidate_groups <- split(person_df, person_df$id, drop = TRUE)
  signatures <- vapply(candidate_groups, row_signature, character(1))
  k50_ambiguous <- detect_k50_ambiguous(person_df)

  fof_conflict <- has_conflict(person_df$FOF_status)
  outcome_pair_conflict <- pair_conflict(person_df, "outcome_value")
  covariate_conflict <- any(c(
    has_conflict(person_df$age),
    has_conflict(person_df$sex),
    has_conflict(person_df$BMI),
    has_conflict(person_df$FI22_nonperformance_KAAOS)
  ))

  complementary_missingness <- FALSE
  if (length(signatures) > 1L && !all(signatures == signatures[[1]]) && !(fof_conflict || outcome_pair_conflict || covariate_conflict)) {
    candidate_meta <- lapply(candidate_groups, function(df) {
      tibble(
        time = df$time,
        outcome_missing = is.na(df$outcome_value),
        age_missing = is.na(df$age),
        sex_missing = is.na(df$sex),
        bmi_missing = is.na(df$BMI),
        fi22_missing = is.na(df$FI22_nonperformance_KAAOS)
      )
    })
    missing_counts <- vapply(candidate_meta, function(df) sum(unlist(df[-1])), numeric(1))
    complementary_missingness <- length(unique(missing_counts)) > 1L || any(duplicated(vapply(candidate_meta, nrow, integer(1))))
  }

  category <- if (length(signatures) > 0L && all(signatures == signatures[[1]])) {
    "IDENTICAL_ROWS"
  } else if (fof_conflict || outcome_pair_conflict || covariate_conflict) {
    "TRUE_CONFLICT"
  } else if (complementary_missingness) {
    "COMPLEMENTARY_ROWS"
  } else {
    "UNKNOWN"
  }

  list(
    category = category,
    k50_ambiguous = k50_ambiguous,
    fof_conflict = fof_conflict,
    outcome_pair_conflict = outcome_pair_conflict,
    covariate_conflict = covariate_conflict,
    complementary_missingness = complementary_missingness,
    ids_linked_n = length(candidate_groups),
    canonical_rows_n = nrow(person_df)
  )
}

data_root <- resolve_data_root()
canonical_path <- file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_long.rds")

canonical_df <- as_tibble(readRDS(canonical_path)) %>%
  transmute(
    id = normalize_id(id),
    bridge_value = normalize_join_key(id),
    time = normalize_time(time),
    FOF_status = normalize_fof(FOF_status),
    age = safe_num(age),
    sex = normalize_sex(sex),
    BMI = safe_num(BMI),
    outcome_value = safe_num(locomotor_capacity),
    FI22_nonperformance_KAAOS = safe_num(FI22_nonperformance_KAAOS)
  ) %>%
  filter(!is.na(id))

lookup_df <- read_ssn_lookup(resolve_ssn_lookup_path(), names(canonical_df))$lookup_df
duplicate_lookup_df <- lookup_df %>%
  add_count(normalized_ssn, name = "lookup_rows_n") %>%
  filter(lookup_rows_n > 1L)

diagnostics_df <- canonical_df %>%
  inner_join(duplicate_lookup_df, by = "bridge_value") %>%
  group_by(normalized_ssn) %>%
  group_modify(function(.x, .y) {
    diag <- categorize_person(.x)
    tibble(
      workbook_rows_n = dplyr::first(.x$lookup_rows_n),
      ids_linked_n = diag$ids_linked_n,
      canonical_rows_n = diag$canonical_rows_n,
      category = diag$category,
      k50_ambiguous = diag$k50_ambiguous,
      fof_conflict = diag$fof_conflict,
      outcome_pair_conflict = diag$outcome_pair_conflict,
      covariate_conflict = diag$covariate_conflict,
      complementary_missingness = diag$complementary_missingness
    )
  }) %>%
  ungroup() %>%
  arrange(normalized_ssn)

all_duplicate_persons <- duplicate_lookup_df %>%
  distinct(normalized_ssn) %>%
  arrange(normalized_ssn)

diagnostics_df <- all_duplicate_persons %>%
  left_join(diagnostics_df, by = "normalized_ssn") %>%
  mutate(
    case_id = sprintf("dup_case_%03d", row_number()),
    workbook_rows_n = coalesce(workbook_rows_n, 0L),
    ids_linked_n = coalesce(ids_linked_n, 0L),
    canonical_rows_n = coalesce(canonical_rows_n, 0L),
    category = coalesce(category, "UNKNOWN"),
    k50_ambiguous = coalesce(k50_ambiguous, FALSE),
    fof_conflict = coalesce(fof_conflict, FALSE),
    outcome_pair_conflict = coalesce(outcome_pair_conflict, FALSE),
    covariate_conflict = coalesce(covariate_conflict, FALSE),
    complementary_missingness = coalesce(complementary_missingness, FALSE)
  ) %>%
  select(-normalized_ssn) %>%
  select(case_id, everything())

summary_tbl <- tibble(
  metric = c(
    "duplicate_persons_total",
    "identical_rows",
    "complementary_rows",
    "true_conflicts",
    "unknown",
    "mergeable_candidates",
    "k50_ambiguous_total",
    "k50_ambiguous_true_conflicts",
    "k50_ambiguous_complementary_rows"
  ),
  value = c(
    nrow(diagnostics_df),
    sum(diagnostics_df$category == "IDENTICAL_ROWS"),
    sum(diagnostics_df$category == "COMPLEMENTARY_ROWS"),
    sum(diagnostics_df$category == "TRUE_CONFLICT"),
    sum(diagnostics_df$category == "UNKNOWN"),
    sum(diagnostics_df$category == "COMPLEMENTARY_ROWS"),
    sum(diagnostics_df$k50_ambiguous),
    sum(diagnostics_df$k50_ambiguous & diagnostics_df$category == "TRUE_CONFLICT"),
    sum(diagnostics_df$k50_ambiguous & diagnostics_df$category == "COMPLEMENTARY_ROWS")
  )
)

summary_path <- write_table_with_manifest(summary_tbl, "k20_duplicate_person_summary", "Aggregate-only summary of workbook duplicate-person diagnostics")
diagnostics_path <- write_table_with_manifest(diagnostics_df, "k20_duplicate_person_diagnostics", "Anonymized case-level diagnostics for duplicate persons")

receipt_path <- file.path(outputs_dir, "k20_duplicate_person_receipt.txt")
writeLines(
  c(
    paste0("duplicate_persons_total=", nrow(diagnostics_df)),
    paste0("k50_ambiguous_total=", sum(diagnostics_df$k50_ambiguous)),
    "identity_exposure_guarantee=aggregate_only_and_anonymized_case_labels"
  ),
  receipt_path
)
append_manifest_safe("k20_duplicate_person_receipt", "text", receipt_path, n = nrow(diagnostics_df), notes = "K20 duplicate-person diagnostics receipt")

session_path <- file.path(outputs_dir, "k20_duplicate_person_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), session_path)
append_manifest_safe("k20_duplicate_person_sessioninfo", "sessioninfo", session_path, notes = "K20 duplicate-person diagnostics session info")

message("Summary: ", summary_path)
message("Diagnostics: ", diagnostics_path)
