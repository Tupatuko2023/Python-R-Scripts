#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(tibble)
  library(here)
})

source(here::here("R", "functions", "init.R"))
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

load_data_root_from_env_file <- function() {
  current <- Sys.getenv("DATA_ROOT", unset = "")
  if (nzchar(current)) return(current)

  env_path <- here::here("config", ".env")
  if (!file.exists(env_path)) return(current)

  env_lines <- readLines(env_path, warn = FALSE, encoding = "UTF-8")
  data_root_line <- grep("^\\s*export\\s+DATA_ROOT=", env_lines, value = TRUE)
  if (length(data_root_line) == 0L) return(current)

  value <- sub("^\\s*export\\s+DATA_ROOT=", "", data_root_line[[1]])
  value <- trimws(gsub('^"(.*)"$', "\\1", gsub("^'(.*)'$", "\\1", value)))
  if (!nzchar(value)) return(current)

  Sys.setenv(DATA_ROOT = value)
  value
}

resolve_data_root <- function() {
  load_data_root_from_env_file()
  dr <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(dr)) {
    stop("K20 duplicate diagnostics requires DATA_ROOT.", call. = FALSE)
  }
  normalizePath(dr, winslash = "/", mustWork = FALSE)
}

normalize_id <- function(x) {
  out <- trimws(as.character(x))
  out[out == "" | tolower(out) %in% c("na", "nan", "null")] <- NA_character_
  out
}

normalize_ssn <- function(x) {
  out <- toupper(trimws(as.character(x)))
  out <- gsub("[[:space:][:punct:]]+", "", out)
  out[out == "" | out %in% c("NA", "NAN", "NULL")] <- NA_character_
  out
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

normalize_fof <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "nonfof", "ei fof", "no fof", "false")] <- 0L
  out[s %in% c("1", "fof", "true")] <- 1L
  suppressWarnings(num <- as.integer(s))
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 1L)
  out[use_num] <- num[use_num]
  out
}

normalize_sex <- function(x) {
  out <- trimws(as.character(x))
  out[out == ""] <- NA_character_
  out
}

safe_num <- function(x) suppressWarnings(as.numeric(x))

is_ssn_name <- function(x) {
  x %in% c("hetu", "sotu", "ssn", "socialsecuritynumber")
}

resolve_bridge_key <- function(canonical_names, lookup_names) {
  canonical_norm <- tolower(canonical_names)
  lookup_norm <- tolower(lookup_names)
  shared_norm <- intersect(canonical_norm, lookup_norm)
  bridge_alias_map <- c(id = "nro")

  if ("id" %in% shared_norm) {
    return(list(canonical_col = canonical_names[match("id", canonical_norm)], lookup_col = lookup_names[match("id", lookup_norm)]))
  }

  alias_hits <- names(bridge_alias_map)[
    names(bridge_alias_map) %in% canonical_norm &
      unname(bridge_alias_map) %in% lookup_norm
  ]
  if (length(alias_hits) != 1L) {
    stop("K20 duplicate diagnostics could not verify the production bridge key.", call. = FALSE)
  }

  canonical_hit <- alias_hits[[1]]
  lookup_hit <- unname(bridge_alias_map[[canonical_hit]])
  list(
    canonical_col = canonical_names[match(canonical_hit, canonical_norm)],
    lookup_col = lookup_names[match(lookup_hit, lookup_norm)]
  )
}

read_lookup <- function(path, canonical_names) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("K20 duplicate diagnostics requires readxl.", call. = FALSE)
  }

  lookup_df <- tibble::as_tibble(readxl::read_excel(path, sheet = "Taul1", skip = 1L))
  bridge <- resolve_bridge_key(canonical_names, names(lookup_df))
  ssn_col <- names(lookup_df)[match("sotu", tolower(names(lookup_df)))]
  if (is.na(ssn_col)) stop("K20 duplicate diagnostics could not find Sotu column.", call. = FALSE)

  lookup_df %>%
    transmute(
      bridge_value = normalize_id(.data[[bridge$lookup_col]]),
      normalized_ssn = normalize_ssn(.data[[ssn_col]])
    ) %>%
    filter(!is.na(bridge_value), !is.na(normalized_ssn)) %>%
    distinct()
}

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
  fof_values <- sort(unique(stats::na.omit(as.character(person_df$FOF_status))))
  if (length(fof_values) > 1L) return(TRUE)

  candidate_groups <- split(person_df, person_df$id, drop = TRUE)
  if (length(candidate_groups) <= 1L) return(FALSE)

  meta_rows <- vector("list", length(candidate_groups))
  signatures <- character(length(candidate_groups))

  for (idx in seq_along(candidate_groups)) {
    candidate_df <- candidate_groups[[idx]]
    time_values <- sort(unique(stats::na.omit(candidate_df$time)))
    branch_eligible <- nrow(candidate_df) == 2L &&
      length(time_values) == 2L &&
      identical(as.integer(time_values), c(0L, 12L))
    outcome_complete <- branch_eligible && all(!is.na(candidate_df$outcome_value))
    covariate_complete <- all(!is.na(candidate_df$age)) &&
      all(!is.na(candidate_df$sex)) &&
      all(!is.na(candidate_df$BMI))

    meta_rows[[idx]] <- tibble(
      candidate_idx = idx,
      canonical_id = sort(unique(candidate_df$id))[1],
      branch_eligible = branch_eligible,
      outcome_complete = outcome_complete,
      covariate_complete = covariate_complete,
      non_missing_fields = count_non_missing(candidate_df, c("time", "FOF_status", "age", "sex", "BMI", "outcome_value", "FI22_nonperformance_KAAOS"))
    )
    signatures[[idx]] <- row_signature(candidate_df)
  }

  meta_df <- bind_rows(meta_rows) %>%
    arrange(desc(branch_eligible), desc(outcome_complete), desc(covariate_complete), desc(non_missing_fields), canonical_id)
  top <- meta_df[1, , drop = FALSE]
  tied <- meta_df %>%
    filter(
      branch_eligible == top$branch_eligible[[1]],
      outcome_complete == top$outcome_complete[[1]],
      covariate_complete == top$covariate_complete[[1]],
      non_missing_fields == top$non_missing_fields[[1]]
    )

  length(unique(signatures[match(tied$candidate_idx, meta_df$candidate_idx)])) > 1L
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
lookup_path <- file.path(data_root, "paper_02", "KAAOS_data_sotullinen.xlsx")

canonical_df <- as_tibble(readRDS(canonical_path)) %>%
  transmute(
    id = normalize_id(id),
    bridge_value = normalize_id(id),
    time = normalize_time(time),
    FOF_status = normalize_fof(FOF_status),
    age = safe_num(age),
    sex = normalize_sex(sex),
    BMI = safe_num(BMI),
    outcome_value = safe_num(locomotor_capacity),
    FI22_nonperformance_KAAOS = safe_num(FI22_nonperformance_KAAOS)
  ) %>%
  filter(!is.na(id))

lookup_df <- read_lookup(lookup_path, names(canonical_df))
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
