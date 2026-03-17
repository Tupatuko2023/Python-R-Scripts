suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
})

k51_sv_first_present <- function(nms, candidates) {
  hits <- candidates[candidates %in% nms]
  if (length(hits) == 0L) return(NA_character_)
  hits[[1]]
}

k51_sv_read_dataset <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    return(as_tibble(readr::read_csv(path, show_col_types = FALSE, progress = FALSE)))
  }
  if (ext == "xlsx" || ext == "xls") {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("K51 source verification requires readxl to inspect Excel candidates.", call. = FALSE)
    }
    return(as_tibble(readxl::read_excel(path, skip = 1, n_max = Inf)))
  }
  stop("Unsupported candidate source extension: ", ext, call. = FALSE)
}

k51_sv_parse_date <- function(x) {
  x_chr <- trimws(as.character(x))
  x_chr[x_chr %in% c("", "NA", "Na", "NULL")] <- NA_character_
  out <- suppressWarnings(as.Date(x_chr, format = "%Y-%m-%d"))
  need_alt <- is.na(out) & !is.na(x_chr)
  if (any(need_alt)) {
    out[need_alt] <- suppressWarnings(as.Date(x_chr[need_alt], format = "%d.%m.%Y"))
  }
  out
}

k51_sv_baseline_signal <- function(df) {
  nm <- names(df)
  signal <- rep(0L, nrow(df))

  visit_col <- k51_sv_first_present(nm, c("KAAOSVastaanottokäynti", "enter", "visit_date", "baseline_visit_date"))
  if (!is.na(visit_col)) {
    signal <- signal + ifelse(!is.na(k51_sv_parse_date(df[[visit_col]])), 1L, 0L)
  }

  pvm0_col <- k51_sv_first_present(nm, c("pvm0kk", "pvm0", "baseline_month"))
  if (!is.na(pvm0_col)) {
    pvm0 <- trimws(as.character(df[[pvm0_col]]))
    signal <- signal + ifelse(!is.na(pvm0) & grepl("^[0-9]+$", pvm0), 1L, 0L)
  }

  fof_col <- k51_sv_first_present(nm, c("kaatumisenpelkoOn", "FOF_status", "fof_status", "fof"))
  if (!is.na(fof_col)) {
    fof_num <- pd_normalize_fof(df[[fof_col]])
    signal <- signal + ifelse(!is.na(fof_num), 1L, 0L)
  }

  signal
}

k51_sv_row_non_missing <- function(df, cols) {
  cols <- cols[cols %in% names(df)]
  if (length(cols) == 0L) return(rep(0L, nrow(df)))
  rowSums(!is.na(as.data.frame(df[, cols, drop = FALSE])))
}

k51_sv_dedup_candidate_source <- function(df, attached_df, source_name) {
  if (!identical(source_name, "root_kaatumisenpelko_csv")) {
    person_counts <- attached_df %>%
      filter(!is.na(person_key)) %>%
      count(person_key, name = "n")
    return(list(
      data = attached_df,
      duplicate_keys_before = sum(person_counts$n > 1L),
      duplicate_keys_after = sum(person_counts$n > 1L),
      rows_removed = 0L,
      ambiguous_people = 0L
    ))
  }

  nm <- names(df)
  visit_col <- k51_sv_first_present(nm, c("KAAOSVastaanottokäynti", "enter", "visit_date", "baseline_visit_date"))
  critical_cols <- intersect(
    c("kaatumisenpelkoOn", "kaatumisenpelkoVAS", "age", "sex", "BMI", "tasapainovaikeus"),
    nm
  )

  person_counts_before <- attached_df %>%
    filter(!is.na(person_key)) %>%
    count(person_key, name = "n")

  dedup_df <- attached_df %>%
    mutate(
      .source_row = seq_len(n()),
      .baseline_signal = k51_sv_baseline_signal(df),
      .visit_date = if (!is.na(visit_col)) k51_sv_parse_date(df[[visit_col]]) else as.Date(NA),
      .critical_non_missing = k51_sv_row_non_missing(df, critical_cols)
    ) %>%
    arrange(
      person_key,
      desc(.baseline_signal),
      .visit_date,
      desc(.critical_non_missing),
      id
    ) %>%
    group_by(person_key) %>%
    slice(1L) %>%
    ungroup()

  person_counts_after <- dedup_df %>%
    filter(!is.na(person_key)) %>%
    count(person_key, name = "n")

  list(
    data = dedup_df %>% select(-.source_row, -.baseline_signal, -.visit_date, -.critical_non_missing),
    duplicate_keys_before = sum(person_counts_before$n > 1L),
    duplicate_keys_after = sum(person_counts_after$n > 1L),
    rows_removed = nrow(attached_df) - nrow(dedup_df),
    ambiguous_people = 0L
  )
}

k51_sv_resolve_candidates <- function() {
  data_root <- resolve_data_root()
  if (is.na(data_root)) {
    stop("K51 source verification requires DATA_ROOT.", call. = FALSE)
  }

  tibble(
    source_name = c(
      "paper_02_kaaos_data_sotullinen_xlsx",
      "derived_kaatumisenpelko_csv",
      "root_kaatumisenpelko_csv",
      "data_kaatumisenpelko_csv",
      "derived_aim2_panel_csv",
      "paper_02_sotut_xlsx"
    ),
    path = c(
      file.path(data_root, "paper_02", "KAAOS_data_sotullinen.xlsx"),
      file.path(data_root, "derived", "kaatumisenpelko.csv"),
      file.path(data_root, "KaatumisenPelko.csv"),
      file.path(data_root, "data", "kaatumisenpelko.csv"),
      file.path(data_root, "derived", "aim2_panel.csv"),
      file.path(data_root, "paper_02", "sotut.xlsx")
    ),
    role = c(
      "primary_baseline_runko",
      "alternative_baseline_csv",
      "root_baseline_csv",
      "alternative_baseline_csv",
      "frailty_lookup_panel",
      "frailty_crosswalk"
    ),
    required_columns = c(
      "nro/sotu or bridge key; baseline table columns",
      "id/nro/sotu or bridge key; baseline table columns",
      "NRO/id plus baseline visit columns and kaatumisenpelkoOn",
      "id/nro/sotu or bridge key; baseline table columns",
      "id/nro + frailty_fried",
      "nro + sotu crosswalk"
    )
  ) %>%
    mutate(
      exists = file.exists(path),
      path = vapply(
        seq_along(path),
        function(i) {
          if (exists[[i]]) {
            normalizePath(path[[i]], winslash = "/", mustWork = TRUE)
          } else {
            path[[i]]
          }
        },
        character(1)
      )
    )
}

k51_sv_derive_current_analytic <- function(data_path) {
  input_df <- as_tibble(readRDS(data_path))
  dedup_prep <- prepare_k50_person_dedup(input_df, "LONG", "locomotor_capacity")
  analysis_person_df <- dedup_prep$analysis_df %>% arrange(person_key, id, time)

  id_gate_df <- analysis_person_df %>%
    group_by(person_key) %>%
    summarise(
      canonical_id = sort(unique(stats::na.omit(id)))[1],
      fof_values = paste(sort(unique(stats::na.omit(as.character(FOF_status)))), collapse = ";"),
      branch_eligible = n() == 2L && length(unique(stats::na.omit(time))) == 2L && all(sort(unique(stats::na.omit(time))) == c(0L, 12L)),
      outcome_complete = branch_eligible && all(!is.na(outcome_value)),
      age_complete = all(!is.na(age)),
      sex_complete = all(!is.na(sex)),
      bmi_complete = all(!is.na(BMI)),
      .groups = "drop"
    ) %>%
    mutate(
      fof_valid = fof_values %in% c("0", "1")
    )

  analytic_df <- id_gate_df %>%
    filter(fof_valid, branch_eligible, outcome_complete, age_complete, sex_complete, bmi_complete) %>%
    select(person_key, canonical_id)

  list(
    analytic_df = analytic_df,
    analytic_n = nrow(analytic_df),
    input_path = data_path
  )
}

k51_sv_attach_candidate_keys <- function(df) {
  lookup_info <- read_ssn_lookup(resolve_ssn_lookup_path(), names(df))
  id_col <- k51_sv_first_present(names(df), c("id", "ID", "Id", "nro", "NRO", "jnro", "Jnro"))
  if (is.na(id_col)) {
    id_col <- lookup_info$bridge_col
  }

  staged_df <- df %>%
    transmute(
      id = normalize_id(.data[[id_col]]),
      bridge_value = normalize_join_key(.data[[lookup_info$bridge_col]])
    )

  attached <- attach_person_key(staged_df, lookup_info)$data
  list(
    data = attached,
    bridge_col = lookup_info$bridge_col,
    id_col = id_col
  )
}

k51_sv_evaluate_candidate <- function(source_name, path, role, required_columns, analytic_df) {
  if (!file.exists(path)) {
    return(tibble(
      source_name = source_name,
      path = path,
      role = role,
      required_columns = required_columns,
      rows_total = NA_integer_,
      unique_person_keys = NA_integer_,
      matched_analytic_ids = 0L,
      coverage_ratio = 0,
      duplicate_keys = NA_integer_,
      duplicate_keys_after_dedup = NA_integer_,
      rows_removed_by_dedup = NA_integer_,
      acceptable_source = FALSE,
      status = "missing_file",
      bridge_col = NA_character_,
      id_col = NA_character_
    ))
  }

  out <- tryCatch({
    df <- k51_sv_read_dataset(path)
    attached <- k51_sv_attach_candidate_keys(df)
    person_counts <- attached$data %>%
      filter(!is.na(person_key)) %>%
      count(person_key, name = "n")
    unique_person_keys <- nrow(person_counts)
    deduped <- k51_sv_dedup_candidate_source(df, attached$data, source_name)
    dedup_counts <- deduped$data %>%
      filter(!is.na(person_key)) %>%
      count(person_key, name = "n")
    matched_analytic_ids <- analytic_df %>%
      filter(person_key %in% dedup_counts$person_key) %>%
      nrow()
    coverage_ratio <- if (nrow(analytic_df) > 0L) matched_analytic_ids / nrow(analytic_df) else 0

    tibble(
      source_name = source_name,
      path = normalizePath(path, winslash = "/", mustWork = TRUE),
      role = role,
      required_columns = required_columns,
      rows_total = nrow(df),
      unique_person_keys = unique_person_keys,
      matched_analytic_ids = matched_analytic_ids,
      coverage_ratio = coverage_ratio,
      duplicate_keys = deduped$duplicate_keys_before,
      duplicate_keys_after_dedup = deduped$duplicate_keys_after,
      rows_removed_by_dedup = deduped$rows_removed,
      acceptable_source = coverage_ratio >= 0.9 && deduped$duplicate_keys_after == 0L,
      status = "evaluated",
      bridge_col = attached$bridge_col,
      id_col = attached$id_col
    )
  }, error = function(e) {
    tibble(
      source_name = source_name,
      path = path,
      role = role,
      required_columns = required_columns,
      rows_total = NA_integer_,
      unique_person_keys = NA_integer_,
      matched_analytic_ids = 0L,
      coverage_ratio = 0,
      duplicate_keys = NA_integer_,
      duplicate_keys_after_dedup = NA_integer_,
      rows_removed_by_dedup = NA_integer_,
      acceptable_source = FALSE,
      status = paste0("error:", conditionMessage(e)),
      bridge_col = NA_character_,
      id_col = NA_character_
    )
  })

  out
}
