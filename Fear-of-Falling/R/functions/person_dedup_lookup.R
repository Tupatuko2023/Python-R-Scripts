#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(here)
})

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
  if (!nzchar(dr)) return(NA_character_)
  normalizePath(dr, winslash = "/", mustWork = FALSE)
}

normalize_id <- function(x) {
  out <- trimws(as.character(x))
  out[is.na(out) | out == "" | tolower(out) %in% c("na", "nan", "null")] <- NA_character_
  out
}

normalize_join_key <- function(x) {
  normalize_id(x)
}

normalize_ssn <- function(x) {
  out <- toupper(trimws(as.character(x)))
  out <- gsub("[[:space:][:punct:]]+", "", out)
  out[out == "" | out %in% c("NA", "NAN", "NULL")] <- NA_character_
  out
}

resolve_ssn_lookup_path <- function() {
  data_root <- resolve_data_root()
  if (is.na(data_root)) {
    stop("Person dedup lookup could not resolve DATA_ROOT for workbook lookup.", call. = FALSE)
  }
  lookup_path <- file.path(data_root, "paper_02", "KAAOS_data_sotullinen.xlsx")
  if (!file.exists(lookup_path)) {
    stop("Person dedup lookup could not resolve workbook lookup path: ", lookup_path, call. = FALSE)
  }
  normalizePath(lookup_path, winslash = "/", mustWork = TRUE)
}

is_bridge_candidate_name <- function(x) {
  grepl("(^id$|_id$|^nro$|_nro$|participant|record|study|subject|person)", x)
}

is_ssn_name <- function(x) {
  x %in% c("hetu", "sotu", "ssn", "socialsecuritynumber")
}

resolve_bridge_key <- function(canonical_names, lookup_names) {
  canonical_norm <- tolower(canonical_names)
  lookup_norm <- tolower(lookup_names)
  shared_norm <- intersect(canonical_norm, lookup_norm)
  bridge_norm <- shared_norm[is_bridge_candidate_name(shared_norm)]
  bridge_alias_map <- c(id = "nro")

  if (length(bridge_norm) == 1L) {
    return(list(
      canonical_col = canonical_names[match(bridge_norm[[1]], canonical_norm)],
      lookup_col = lookup_names[match(bridge_norm[[1]], lookup_norm)],
      bridge_norm = bridge_norm[[1]]
    ))
  }

  alias_hits <- names(bridge_alias_map)[
    names(bridge_alias_map) %in% canonical_norm &
      unname(bridge_alias_map) %in% lookup_norm
  ]

  if (length(alias_hits) != 1L) {
    stop(
      "Person dedup lookup could not verify exactly one shared bridge column between canonical input and identity lookup workbook.",
      call. = FALSE
    )
  }

  canonical_hit <- alias_hits[[1]]
  lookup_hit <- unname(bridge_alias_map[[canonical_hit]])

  list(
    canonical_col = canonical_names[match(canonical_hit, canonical_norm)],
    lookup_col = lookup_names[match(lookup_hit, lookup_norm)],
    bridge_norm = paste0(canonical_hit, "<->", lookup_hit)
  )
}

read_ssn_lookup <- function(path, canonical_names) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Person dedup lookup requires the readxl package.", call. = FALSE)
  }

  sheets <- readxl::excel_sheets(path)
  found <- list()
  read_specs <- list(
    list(skip = 0L, preferred_sheet = NA_character_),
    list(skip = 1L, preferred_sheet = "Taul1")
  )

  for (sheet in sheets) {
    for (spec in read_specs) {
      if (!is.na(spec$preferred_sheet) && !identical(sheet, spec$preferred_sheet)) next

      sheet_df <- tibble::as_tibble(
        readxl::read_excel(path, sheet = sheet, skip = spec$skip, n_max = Inf)
      )
      lookup_names <- names(sheet_df)
      lookup_norm <- tolower(lookup_names)
      ssn_hits <- which(is_ssn_name(lookup_norm))
      if (length(ssn_hits) != 1L) next

      bridge <- tryCatch(
        resolve_bridge_key(canonical_names, lookup_names),
        error = function(e) NULL
      )
      if (is.null(bridge)) next
      ssn_col <- lookup_names[[ssn_hits[[1]]]]

      clean_df <- sheet_df %>%
        transmute(
          bridge_value = normalize_join_key(.data[[bridge$lookup_col]]),
          normalized_ssn = normalize_ssn(.data[[ssn_col]])
        ) %>%
        filter(!is.na(bridge_value), !is.na(normalized_ssn)) %>%
        distinct()

      if (nrow(clean_df) == 0L) next

      bridge_conflicts <- clean_df %>%
        count(bridge_value, name = "n_ssn") %>%
        filter(n_ssn > 1L)

      if (nrow(bridge_conflicts) > 0) {
        stop(
          "Person dedup lookup bridge candidate is not 1:1 or 1:many from identity value to bridge value in the workbook lookup.",
          call. = FALSE
        )
      }

      found[[length(found) + 1L]] <- list(
        sheet = sheet,
        skip = spec$skip,
        bridge_col = bridge$canonical_col,
        lookup_bridge_col = bridge$lookup_col,
        lookup_df = clean_df
      )
    }
  }

  if (length(found) != 1L) {
    stop(
      "Person dedup lookup could not verify a unique workbook sheet with one identity column and one shared bridge key.",
      call. = FALSE
    )
  }

  found[[1L]]
}

attach_person_key <- function(analysis_df, lookup_info, id_col = "id") {
  attached_df <- analysis_df %>%
    left_join(lookup_info$lookup_df, by = "bridge_value") %>%
    mutate(
      person_key_source = if_else(!is.na(normalized_ssn), "verified_ssn", "id_fallback"),
      person_key = case_when(
        !is.na(normalized_ssn) ~ paste0("ssn:", normalized_ssn),
        !is.na(.data[[id_col]]) ~ paste0("id:", .data[[id_col]]),
        TRUE ~ NA_character_
      )
    )

  list(
    data = attached_df,
    diagnostics = list(
      matched_rows = sum(attached_df$person_key_source == "verified_ssn", na.rm = TRUE),
      unmatched_rows = sum(attached_df$person_key_source == "id_fallback", na.rm = TRUE)
    )
  )
}

pd_safe_num <- function(x) suppressWarnings(as.numeric(x))

pd_normalize_fof <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "nonfof", "ei fof", "no fof", "false")] <- 0L
  out[s %in% c("1", "fof", "true")] <- 1L
  suppressWarnings(num <- as.integer(s))
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 1L)
  out[use_num] <- num[use_num]
  factor(out, levels = c(0L, 1L))
}

pd_normalize_sex <- function(x) {
  out <- trimws(as.character(x))
  out[is.na(out) | out == ""] <- NA_character_
  factor(out)
}

pd_normalize_time <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "baseline", "base", "t0")] <- 0L
  out[s %in% c("12", "12m", "m12", "followup", "follow-up", "12_months")] <- 12L
  suppressWarnings(num <- as.integer(s))
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 12L)
  out[use_num] <- num[use_num]
  out
}

pd_first_present <- function(nms, candidates) {
  hits <- candidates[candidates %in% nms]
  if (length(hits) == 0) return(NA_character_)
  hits[[1]]
}

pd_resolve_long_col <- function(outcome, nms) {
  pd_first_present(nms, c(outcome))
}

pd_resolve_wide_cols <- function(outcome, nms) {
  if (identical(outcome, "Composite_Z")) {
    return(list(
      baseline = pd_first_present(nms, c("Composite_Z_0", "Composite_Z_baseline")),
      followup = pd_first_present(nms, c("Composite_Z_12m"))
    ))
  }
  list(
    baseline = pd_first_present(nms, c(paste0(outcome, "_0"))),
    followup = pd_first_present(nms, c(paste0(outcome, "_12m")))
  )
}

count_non_missing <- function(df, cols) {
  cols <- cols[cols %in% names(df)]
  if (length(cols) == 0L) return(0L)
  sum(!is.na(as.data.frame(df[, cols, drop = FALSE])))
}

pd_choose_long_candidate <- function(person_df,
                                     id_col = "id",
                                     time_col = "time",
                                     fof_col = "FOF_status",
                                     outcome_cols = c("outcome_value"),
                                     covariate_cols = c("age", "sex", "BMI"),
                                     compare_cols = NULL) {
  candidate_groups <- split(person_df, person_df[[id_col]], drop = TRUE)
  if (length(candidate_groups) == 0L) {
    return(list(ambiguous = FALSE, candidate_idx = NA_integer_, candidates = list()))
  }
  if (is.null(compare_cols)) {
    compare_cols <- c(time_col, fof_col, covariate_cols, outcome_cols, "FI22_nonperformance_KAAOS")
  }

  candidates <- vector("list", length(candidate_groups))
  meta_rows <- vector("list", length(candidate_groups))
  signatures <- character(length(candidate_groups))
  idx <- 1L

  for (candidate_df in candidate_groups) {
    candidate_df <- candidate_df[order(candidate_df[[time_col]], na.last = TRUE), , drop = FALSE]
    time_values <- sort(unique(stats::na.omit(candidate_df[[time_col]])))
    branch_eligible <- nrow(candidate_df) == 2L &&
      length(time_values) == 2L &&
      identical(as.integer(time_values), c(0L, 12L))
    outcome_complete <- branch_eligible &&
      all(stats::complete.cases(candidate_df[, outcome_cols[outcome_cols %in% names(candidate_df)], drop = FALSE]))
    covariate_complete <- all(stats::complete.cases(candidate_df[, covariate_cols[covariate_cols %in% names(candidate_df)], drop = FALSE]))

    candidates[[idx]] <- candidate_df
      compare_cols_present <- compare_cols[compare_cols %in% names(candidate_df)]
      meta_rows[[idx]] <- tibble(
        candidate_idx = idx,
        canonical_id = sort(unique(candidate_df[[id_col]]))[1],
        branch_eligible = branch_eligible,
        outcome_complete = outcome_complete,
        covariate_complete = covariate_complete,
        non_missing_fields = count_non_missing(candidate_df, compare_cols_present)
      )
      signatures[[idx]] <- candidate_signature_long(candidate_df, compare_cols)
      idx <- idx + 1L
  }

  choice <- select_best_candidate(bind_rows(meta_rows), signatures)
  c(choice, list(candidates = candidates))
}

pd_choose_wide_candidate <- function(person_df,
                                     id_col = "id",
                                     fof_col = "FOF_status",
                                     value_cols = c("outcome_0", "outcome_12m"),
                                     covariate_cols = c("age", "sex", "BMI"),
                                     compare_cols = NULL) {
  candidates <- split(person_df, seq_len(nrow(person_df)))
  if (length(candidates) == 0L) {
    return(list(ambiguous = FALSE, candidate_idx = NA_integer_, candidates = list()))
  }
  if (is.null(compare_cols)) {
    compare_cols <- c(fof_col, covariate_cols, value_cols, "FI22_nonperformance_KAAOS")
  }

  meta_rows <- vector("list", length(candidates))
  signatures <- character(length(candidates))

  for (idx in seq_along(candidates)) {
    candidate_df <- candidates[[idx]]
    compare_cols_present <- compare_cols[compare_cols %in% names(candidate_df)]
    meta_rows[[idx]] <- tibble(
      candidate_idx = idx,
      canonical_id = candidate_df[[id_col]][[1]],
      branch_eligible = nrow(candidate_df) == 1L,
      outcome_complete = all(stats::complete.cases(candidate_df[, value_cols[value_cols %in% names(candidate_df)], drop = FALSE])),
      covariate_complete = all(stats::complete.cases(candidate_df[, covariate_cols[covariate_cols %in% names(candidate_df)], drop = FALSE])),
      non_missing_fields = count_non_missing(candidate_df, compare_cols_present)
    )
    signatures[[idx]] <- candidate_signature_wide(candidate_df, compare_cols)
  }

  choice <- select_best_candidate(bind_rows(meta_rows), signatures)
  c(choice, list(candidates = candidates))
}

pd_is_ambiguous_long_person <- function(person_df,
                                        id_col = "id",
                                        time_col = "time",
                                        fof_col = "FOF_status",
                                        outcome_cols = c("outcome_value"),
                                        covariate_cols = c("age", "sex", "BMI"),
                                        compare_cols = NULL) {
  fof_values <- sort(unique(stats::na.omit(as.character(person_df[[fof_col]]))))
  if (length(fof_values) > 1L) return(TRUE)
  if (dplyr::n_distinct(stats::na.omit(person_df[[id_col]])) <= 1L) return(FALSE)

  isTRUE(pd_choose_long_candidate(
    person_df = person_df,
    id_col = id_col,
    time_col = time_col,
    fof_col = fof_col,
    outcome_cols = outcome_cols,
    covariate_cols = covariate_cols,
    compare_cols = compare_cols
  )$ambiguous)
}

candidate_signature_long <- function(df, compare_cols) {
  cmp_cols <- compare_cols[compare_cols %in% names(df)]
  ordered_df <- df[order(df$time, na.last = TRUE), cmp_cols, drop = FALSE]
  row_sig <- apply(
    ordered_df,
    1,
    function(row) paste(ifelse(is.na(row), "<NA>", as.character(row)), collapse = "|")
  )
  paste(row_sig, collapse = "||")
}

candidate_signature_wide <- function(df, compare_cols) {
  cmp_cols <- compare_cols[compare_cols %in% names(df)]
  row <- df[1, cmp_cols, drop = FALSE]
  paste(ifelse(is.na(row), "<NA>", as.character(row)), collapse = "|")
}

select_best_candidate <- function(meta_df, signatures) {
  ordered <- meta_df %>%
    arrange(desc(branch_eligible), desc(outcome_complete), desc(covariate_complete), desc(non_missing_fields), canonical_id)
  top <- ordered[1, , drop = FALSE]
  tied <- ordered %>%
    filter(
      branch_eligible == top$branch_eligible[[1]],
      outcome_complete == top$outcome_complete[[1]],
      covariate_complete == top$covariate_complete[[1]],
      non_missing_fields == top$non_missing_fields[[1]]
    )

  tied_idx <- tied$candidate_idx
  if (length(unique(signatures[match(tied_idx, meta_df$candidate_idx)])) > 1L) {
    return(list(ambiguous = TRUE, candidate_idx = NA_integer_))
  }

  list(ambiguous = FALSE, candidate_idx = tied_idx[[1]])
}

dedup_person_records_long <- function(df,
                                      id_col = "id",
                                      time_col = "time",
                                      fof_col = "FOF_status",
                                      outcome_cols = c("outcome_value"),
                                      covariate_cols = c("age", "sex", "BMI"),
                                      compare_cols = NULL) {
  if (is.null(compare_cols)) {
    compare_cols <- c(time_col, fof_col, covariate_cols, outcome_cols, "FI22_nonperformance_KAAOS")
  }

  verified_df <- df %>% filter(person_key_source == "verified_ssn", !is.na(person_key))
  fallback_df <- df %>% filter(person_key_source != "verified_ssn", !is.na(person_key))

  if (nrow(verified_df) == 0L) {
    return(list(
      data = bind_rows(fallback_df),
      diagnostics = list(ex_duplicate_ssn_rows = 0L, ex_person_conflict_ambiguous = 0L)
    ))
  }

  kept <- list()
  duplicate_rows <- 0L
  ambiguous_people <- 0L

  for (person_df in split(verified_df, verified_df$person_key, drop = TRUE)) {
    fof_values <- sort(unique(stats::na.omit(as.character(person_df[[fof_col]]))))
    if (length(fof_values) > 1L) {
      ambiguous_people <- ambiguous_people + 1L
      next
    }

    choice <- pd_choose_long_candidate(
      person_df = person_df,
      id_col = id_col,
      time_col = time_col,
      fof_col = fof_col,
      outcome_cols = outcome_cols,
      covariate_cols = covariate_cols,
      compare_cols = compare_cols
    )
    if (isTRUE(choice$ambiguous)) {
      ambiguous_people <- ambiguous_people + 1L
      next
    }

    chosen <- choice$candidates[[choice$candidate_idx]]
    duplicate_rows <- duplicate_rows + (nrow(person_df) - nrow(chosen))
    kept[[length(kept) + 1L]] <- chosen
  }

  list(
    data = bind_rows(fallback_df, bind_rows(kept)),
    diagnostics = list(
      ex_duplicate_ssn_rows = duplicate_rows,
      ex_person_conflict_ambiguous = ambiguous_people
    )
  )
}

dedup_person_records_wide <- function(df,
                                      id_col = "id",
                                      fof_col = "FOF_status",
                                      value_cols = c("outcome_0", "outcome_12m"),
                                      covariate_cols = c("age", "sex", "BMI"),
                                      compare_cols = NULL) {
  if (is.null(compare_cols)) {
    compare_cols <- c(fof_col, covariate_cols, value_cols, "FI22_nonperformance_KAAOS")
  }

  verified_df <- df %>% filter(person_key_source == "verified_ssn", !is.na(person_key))
  fallback_df <- df %>% filter(person_key_source != "verified_ssn", !is.na(person_key))

  if (nrow(verified_df) == 0L) {
    return(list(
      data = bind_rows(fallback_df),
      diagnostics = list(ex_duplicate_ssn_rows = 0L, ex_person_conflict_ambiguous = 0L)
    ))
  }

  kept <- list()
  duplicate_rows <- 0L
  ambiguous_people <- 0L

  for (person_df in split(verified_df, verified_df$person_key, drop = TRUE)) {
    fof_values <- sort(unique(stats::na.omit(as.character(person_df[[fof_col]]))))
    if (length(fof_values) > 1L) {
      ambiguous_people <- ambiguous_people + 1L
      next
    }

    choice <- pd_choose_wide_candidate(
      person_df = person_df,
      id_col = id_col,
      fof_col = fof_col,
      value_cols = value_cols,
      covariate_cols = covariate_cols,
      compare_cols = compare_cols
    )
    if (isTRUE(choice$ambiguous)) {
      ambiguous_people <- ambiguous_people + 1L
      next
    }

    chosen <- choice$candidates[[choice$candidate_idx]]
    duplicate_rows <- duplicate_rows + (nrow(person_df) - nrow(chosen))
    kept[[length(kept) + 1L]] <- chosen
  }

  list(
    data = bind_rows(fallback_df, bind_rows(kept)),
    diagnostics = list(
      ex_duplicate_ssn_rows = duplicate_rows,
      ex_person_conflict_ambiguous = ambiguous_people
    )
  )
}

prepare_k50_person_dedup <- function(input_df, shape, outcome) {
  id_col <- pd_first_present(names(input_df), c("id"))
  fof_col <- pd_first_present(names(input_df), c("FOF_status"))
  age_col <- pd_first_present(names(input_df), c("age"))
  sex_col <- pd_first_present(names(input_df), c("sex"))
  bmi_col <- pd_first_present(names(input_df), c("BMI"))

  base_required <- c(id_col, fof_col, age_col, sex_col, bmi_col)
  if (any(is.na(base_required))) {
    miss <- c("id", "FOF_status", "age", "sex", "BMI")[is.na(base_required)]
    stop("K50 person dedup input is missing required canonical covariates: ", paste(miss, collapse = ", "), call. = FALSE)
  }

  lookup_path <- resolve_ssn_lookup_path()
  lookup_info <- read_ssn_lookup(lookup_path, names(input_df))
  staged_df <- input_df %>% mutate(.row_id = dplyr::row_number())
  fi22_col <- pd_first_present(names(input_df), c("FI22_nonperformance_KAAOS"))

  if (identical(shape, "LONG")) {
    time_col <- pd_first_present(names(input_df), c("time"))
    outcome_col <- pd_resolve_long_col(outcome, names(input_df))
    if (is.na(time_col) || is.na(outcome_col)) {
      stop("K50 person dedup LONG input is missing canonical time or outcome columns.", call. = FALSE)
    }

    analysis_df <- staged_df %>%
      transmute(
        .row_id,
        id = normalize_id(.data[[id_col]]),
        bridge_value = normalize_join_key(.data[[lookup_info$bridge_col]]),
        time = pd_normalize_time(.data[[time_col]]),
        FOF_status = pd_normalize_fof(.data[[fof_col]]),
        age = pd_safe_num(.data[[age_col]]),
        sex = pd_normalize_sex(.data[[sex_col]]),
        BMI = pd_safe_num(.data[[bmi_col]]),
        outcome_value = pd_safe_num(.data[[outcome_col]]),
        FI22_nonperformance_KAAOS = if (!is.na(fi22_col)) pd_safe_num(.data[[fi22_col]]) else NA_real_
      ) %>%
      arrange(id, time)

    analysis_df <- attach_person_key(analysis_df, lookup_info)$data
    valid_id_df <- analysis_df %>% filter(!is.na(id))
    dedup_result <- dedup_person_records_long(valid_id_df)
  } else {
    wide_cols <- pd_resolve_wide_cols(outcome, names(input_df))
    if (any(is.na(unlist(wide_cols)))) {
      stop("K50 person dedup WIDE input is missing canonical baseline/follow-up columns.", call. = FALSE)
    }

    analysis_df <- staged_df %>%
      transmute(
        .row_id,
        id = normalize_id(.data[[id_col]]),
        bridge_value = normalize_join_key(.data[[lookup_info$bridge_col]]),
        FOF_status = pd_normalize_fof(.data[[fof_col]]),
        age = pd_safe_num(.data[[age_col]]),
        sex = pd_normalize_sex(.data[[sex_col]]),
        BMI = pd_safe_num(.data[[bmi_col]]),
        outcome_0 = pd_safe_num(.data[[wide_cols$baseline]]),
        outcome_12m = pd_safe_num(.data[[wide_cols$followup]]),
        FI22_nonperformance_KAAOS = if (!is.na(fi22_col)) pd_safe_num(.data[[fi22_col]]) else NA_real_
      )

    analysis_df <- attach_person_key(analysis_df, lookup_info)$data
    valid_id_df <- analysis_df %>% filter(!is.na(id))
    dedup_result <- dedup_person_records_wide(valid_id_df)
  }

  raw_rows <- nrow(analysis_df)
  valid_id_rows <- nrow(valid_id_df)
  raw_id_n <- dplyr::n_distinct((analysis_df %>% filter(!is.na(id)))$id)
  raw_person_by_ssn <- analysis_df %>%
    filter(person_key_source == "verified_ssn", !is.na(person_key)) %>%
    summarise(n = dplyr::n_distinct(person_key)) %>%
    pull(n)
  if (length(raw_person_by_ssn) == 0L) raw_person_by_ssn <- 0L
  verified_id_n <- analysis_df %>%
    filter(person_key_source == "verified_ssn", !is.na(id)) %>%
    summarise(n = dplyr::n_distinct(id)) %>%
    pull(n)
  if (length(verified_id_n) == 0L) verified_id_n <- 0L

  analysis_person_df <- dedup_result$data
  keep_row_ids <- sort(unique(analysis_person_df$.row_id))
  deduped_input <- staged_df %>%
    filter(.row_id %in% keep_row_ids) %>%
    arrange(.row_id) %>%
    select(-.row_id)

  list(
    data = deduped_input,
    analysis_df = analysis_person_df,
    lookup_info = lookup_info,
    diagnostics = list(
      ex_id_missing = raw_rows - valid_id_rows,
      n_raw_person_lookup = raw_person_by_ssn,
      ex_duplicate_person_lookup = max(verified_id_n - raw_person_by_ssn, 0L),
      ex_duplicate_person_rows = dedup_result$diagnostics$ex_duplicate_ssn_rows,
      ex_person_conflict_ambiguous = dedup_result$diagnostics$ex_person_conflict_ambiguous,
      raw_rows = raw_rows,
      raw_id_n = raw_id_n
    )
  )
}
