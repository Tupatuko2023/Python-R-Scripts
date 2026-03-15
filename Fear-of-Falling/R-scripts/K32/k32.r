#!/usr/bin/env Rscript
# ==============================================================================
# K32_CORE_LOCOMOTOR_CAPACITY - Deterministic 3-Indicator Capacity Model
# File: k32.r
#
# Purpose
# - Implement a controlled core locomotor capacity model from raw Excel with a
#   deterministic indicator set and admissibility gate.
# - Keep K30/K31 unchanged; K32 is a parallel script.
# - Always compute z-composite fallback scores.
# ==============================================================================
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(tidyr)
  library(tibble)
  library(purrr)
  library(janitor)
  library(here)
  library(lavaan)
})

# --- Standard init -------------------------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.[Rr]$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K32"
}
script_label_raw <- sub("\\..*$", "", sub("\\.V.*$", "", script_base))
script_label <- toupper(script_label_raw)
if (is.na(script_label) || script_label == "") script_label <- "K32"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

# --- Deterministic indicator defaults -----------------------------------------
column_candidates <- list(
  id = c("id", "nro"),
  fof_status = c("fof_status", "kaatumisen_pelko_0_ei_pelkaa_1_pelkaa_2_ei_tietoa"),
  age = c("age", "ika_a"),
  sex = c("sex", "sukupuoli_0_nainen_1_mies"),
  bmi = c("bmi", "bmi_kg_m_2_e1_ei_tietoa"),
  tasapainovaikeus = c("tasapainovaikeus", "tasapaino_vaikeudet_0_ei_1_kylla_2_ei_tietoa"),
  self_report = c(
    "oma_arvio_liikuntakyvysta_0_hyva_1_kohtalainen_2_heikko_3_ei_tietoa",
    "oma_arvio_liikuntakyvysta",
    "vaikeus_liikkua_500m",
    "vaikeus500m",
    "vaikeus_liikkua_2km"
  ),
  gait_0 = c(
    "kavelynopeus_m_sek0",
    "tk_10_metrin_kavelynopeus_sek_e_ei_pysty_kavella_e1_ei_tietoa"
  ),
  gait_2 = c(
    "kavelynopeus_m_sek2",
    "sk2_10_metrin_kavelynopeus_sek_e_ei_pysty_kavella_e1_ei_tietoa"
  ),
  chair_0 = c(
    "ftsst0",
    "tuoli0",
    "tuoliltanousu0",
    "tk_tuolilta_nousu_5_krt_sek_e_ei_pysty_nousta_e1_ei_tietoa"
  ),
  chair_2 = c(
    "ftsst2",
    "tuoli2",
    "tuoliltanousu2",
    "x2sk_tuolilta_nousu_5_krt_sek_e_ei_pysty_nousta_e1_ei_tietoa"
  ),
  balance_0 = c("sls_mean0", "seisominen0"),
  balance_2 = c("sls_mean2", "seisominen2"),
  balance_right_0 = c("sls_r0", "tk_yhdella_jalalla_seisominen_oikea_sek_e1_ei_tietoa"),
  balance_left_0 = c("sls_l0", "tk_yhdella_jalalla_seisominen_vasen_sek_e_ei_pysty_seista_e1_ei_tietoa"),
  balance_right_2 = c("sls_r2", "x2sk_yhdella_jalalla_seisominen_oikea_sek_e1_ei_tietoa"),
  balance_left_2 = c("sls_l2", "x2sk_yhdella_jalalla_seisominen_vasen_sek_e1_ei_tietoa")
)

required_scalar_keys <- c(
  "id", "fof_status", "age", "sex", "bmi", "gait_0", "gait_2", "chair_0", "chair_2"
)

SCORE_NA_SHARE_MAX <- 0.25
BALANCE_MAX_SECONDS <- 300
MIN_CANONICAL_SCORE_COMPLETENESS <- 0.40

# --- Helpers ------------------------------------------------------------------
dir_create <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

write_lines_safely <- function(lines, path) {
  dir_create(dirname(path))
  writeLines(lines, con = path, useBytes = TRUE)
  path
}

write_csv_safely <- function(df, path) {
  dir_create(dirname(path))
  readr::write_csv(df, file = path, na = "")
  path
}

write_rds_safely <- function(obj, path) {
  dir_create(dirname(path))
  saveRDS(obj, file = path)
  path
}

resolve_data_root <- function() {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(data_root)) {
    stop(
      paste0(
        "DATA_ROOT is not set. Refusing to write patient-level outputs into repo.\n",
        "Set config/.env with: export DATA_ROOT=/absolute/path/to/local_data\n",
        "Run via runner/pattern that sources config/.env."
      ),
      call. = FALSE
    )
  }
  normalizePath(data_root, winslash = "/", mustWork = FALSE)
}

load_fi22_external <- function(data_root) {
  fi22_path <- file.path(data_root, "paper_02", "frailty_vulnerability", "kaaos_with_frailty_index_k40.rds")
  if (!file.exists(fi22_path)) {
    stop(
      paste0(
        "K32 canonical export requires the external K40 frailty artifact to expose sensitivity-only FI22.\n",
        "Missing file: ", fi22_path, "\n",
        "Run the deterministic K40 FI builder first so canonical K50-ready inputs can carry FI22_nonperformance_KAAOS."
      ),
      call. = FALSE
    )
  }

  fi22_df <- readRDS(fi22_path)
  required_cols <- c("id", "frailty_index_fi")
  if (!all(required_cols %in% names(fi22_df))) {
    stop(
      paste0(
        "K40 frailty artifact is missing required columns for canonical FI22 export.\n",
        "Required: ", paste(required_cols, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  fi22_canonical <- fi22_df %>%
    transmute(
      id = trimws(as.character(.data$id)),
      FI22_nonperformance_KAAOS = safe_num(.data$frailty_index_fi)
    ) %>%
    distinct(id, .keep_all = TRUE)

  list(
    data = fi22_canonical,
    path = normalizePath(fi22_path, winslash = "/", mustWork = TRUE),
    n = nrow(fi22_canonical)
  )
}

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  n_chr <- if (is.na(n)) NA_character_ else as.character(n)
  append_manifest(
    manifest_row(
      script = script_label,
      label = label,
      path = get_relpath(path),
      kind = kind,
      n = n_chr,
      notes = notes
    ),
    manifest_path
  )
  invisible(TRUE)
}

safe_num <- function(x) suppressWarnings(as.numeric(x))

safe_cor <- function(x, y, method = "spearman") {
  ok <- complete.cases(x, y)
  if (sum(ok) < 3) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok], method = method))
}

na_row_mean <- function(mat) {
  nonmiss <- rowSums(!is.na(mat))
  out <- rowMeans(mat, na.rm = TRUE)
  out[nonmiss == 0] <- NA_real_
  out
}

audit_cont <- function(x) {
  tibble(
    n = length(x),
    n_miss = sum(is.na(x)),
    p_miss = mean(is.na(x)),
    mean = mean(x, na.rm = TRUE),
    sd = sd(x, na.rm = TRUE),
    median = median(x, na.rm = TRUE),
    p01 = as.numeric(quantile(x, 0.01, na.rm = TRUE, names = FALSE)),
    p99 = as.numeric(quantile(x, 0.99, na.rm = TRUE, names = FALSE)),
    min = suppressWarnings(min(x, na.rm = TRUE)),
    max = suppressWarnings(max(x, na.rm = TRUE))
  )
}

audit_cat <- function(x) {
  tab <- table(x, useNA = "ifany")
  prop <- prop.table(tab)
  tibble(
    level = names(tab),
    n = as.integer(tab),
    p = as.numeric(prop)
  ) %>%
    arrange(desc(n)) %>%
    mutate(flag_rare = p < 0.05)
}

closest_match <- function(target, choices) {
  if (length(choices) == 0) return(character(0))
  d <- adist(target, choices, ignore.case = TRUE)
  choices[order(d)][1:min(5, length(choices))]
}

resolve_one <- function(df_names, key) {
  cand <- column_candidates[[key]]
  hit <- cand[cand %in% df_names]
  list(
    value = if (length(hit) == 1) hit[1] else NA_character_,
    hits = hit,
    ambiguous = length(hit) > 1
  )
}

build_mapping <- function(df_names) {
  keys <- names(column_candidates)
  mapped <- setNames(rep(NA_character_, length(keys)), keys)
  ambiguity_tbl <- tibble(
    key = character(0),
    hits = character(0),
    n_hits = integer(0)
  )
  for (k in keys) {
    res <- resolve_one(df_names, k)
    mapped[[k]] <- res$value
    if (isTRUE(res$ambiguous)) {
      ambiguity_tbl <- bind_rows(
        ambiguity_tbl,
        tibble(key = k, hits = paste(res$hits, collapse = ";"), n_hits = length(res$hits))
      )
    }
  }

  balance_0_ok <- !is.na(mapped[["balance_0"]]) || (!is.na(mapped[["balance_right_0"]]) && !is.na(mapped[["balance_left_0"]]))
  balance_2_ok <- !is.na(mapped[["balance_2"]]) || (!is.na(mapped[["balance_right_2"]]) && !is.na(mapped[["balance_left_2"]]))

  unresolved_required <- required_scalar_keys[is.na(mapped[required_scalar_keys])]
  if (!balance_0_ok) unresolved_required <- c(unresolved_required, "balance_time0")
  if (!balance_2_ok) unresolved_required <- c(unresolved_required, "balance_time2")

  list(
    mapped = mapped,
    unresolved_required = unresolved_required,
    ambiguity_tbl = ambiguity_tbl,
    balance_0_ok = balance_0_ok,
    balance_2_ok = balance_2_ok
  )
}

find_input_dataset <- function() {
  tried <- character(0)

  env_path <- Sys.getenv("DATA_PATH", unset = "")
  if (nzchar(env_path)) {
    tried <- c(tried, env_path)
    if (!file.exists(env_path)) {
      stop("DATA_PATH is set but file does not exist: ", env_path, call. = FALSE)
    }
    ext <- tolower(tools::file_ext(env_path))
    kind <- dplyr::case_when(
      ext == "rds" ~ "rds",
      ext %in% c("xlsx", "xls") ~ "excel",
      TRUE ~ "csv"
    )
    return(list(kind = kind, path = normalizePath(env_path), tried = tried))
  }

  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (nzchar(data_root)) {
    raw_excel <- file.path(data_root, "paper_02", "KAAOS_data_sotullinen.xlsx")
    tried <- c(tried, raw_excel)
    if (file.exists(raw_excel)) {
      return(list(kind = "excel", path = normalizePath(raw_excel), tried = tried))
    }
  }

  stop(
    paste0(
      "Could not locate K32 raw input dataset.\n",
      "Tried paths:\n- ", paste(unique(tried), collapse = "\n- "), "\n\n",
      "Set one of:\n",
      "1) DATA_PATH=/absolute/path/to/input.(xlsx|xls|rds|csv)\n",
      "2) DATA_ROOT with paper_02/KAAOS_data_sotullinen.xlsx available."
    ),
    call. = FALSE
  )
}

inspect_excel_layouts <- function(path) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop(
      "Package 'readxl' is required to read K32 raw Excel input. Install or restore the project R environment before running K32.",
      call. = FALSE
    )
  }

  sheets <- readxl::excel_sheets(path)
  if (length(sheets) == 0) {
    stop("Excel workbook has no sheets: ", path, call. = FALSE)
  }

  layouts <- purrr::map_dfr(sheets, function(sheet_name) {
    purrr::map_dfr(c(0, 1), function(skip_n) {
      probe <- tryCatch(
        readxl::read_excel(path, sheet = sheet_name, skip = skip_n, n_max = 0, .name_repair = "minimal"),
        error = function(e) e
      )
      if (inherits(probe, "error")) {
        return(tibble(
          sheet = sheet_name,
          skip = skip_n,
          matched_required = NA_integer_,
          matched_total = NA_integer_,
          unresolved_required = "read_error",
          error = conditionMessage(probe)
        ))
      }

      clean_names <- janitor::make_clean_names(names(probe))
      map_res <- build_mapping(clean_names)
      tibble(
        sheet = sheet_name,
        skip = skip_n,
        matched_required = sum(!is.na(map_res$mapped[required_scalar_keys])) +
          as.integer(map_res$balance_0_ok) + as.integer(map_res$balance_2_ok),
        matched_total = sum(!is.na(map_res$mapped)),
        unresolved_required = paste(map_res$unresolved_required, collapse = ";"),
        error = NA_character_
      )
    })
  })

  layouts
}

load_input_dataset <- function(input_info) {
  if (input_info$kind == "rds") {
    df_raw <- readRDS(input_info$path)
    return(list(
      df = janitor::clean_names(as_tibble(df_raw)),
      source_kind = "rds",
      source_path = input_info$path,
      source_sheet = NA_character_,
      source_skip = NA_integer_
    ))
  }

  if (input_info$kind == "csv") {
    df_raw <- readr::read_csv(input_info$path, show_col_types = FALSE)
    return(list(
      df = janitor::clean_names(as_tibble(df_raw)),
      source_kind = "csv",
      source_path = input_info$path,
      source_sheet = NA_character_,
      source_skip = NA_integer_
    ))
  }

  layouts <- inspect_excel_layouts(input_info$path)
  layouts_path <- file.path(outputs_dir, "k32_excel_layout_candidates.csv")
  write_csv_safely(layouts, layouts_path)
  append_manifest_safe("k32_excel_layout_candidates", "table_csv", layouts_path)

  expected_required <- length(required_scalar_keys) + 2L
  candidates_ok <- layouts %>%
    filter(is.na(.data$error), .data$matched_required == expected_required)

  if (nrow(candidates_ok) != 1) {
    stop(
      paste0(
        "K32 raw Excel sheet/layout resolution failed for ", input_info$path, ". ",
        "Expected exactly one sheet+skip combination with gait/chair/balance mapping, found ", nrow(candidates_ok), ". ",
        "See: ", layouts_path
      ),
      call. = FALSE
    )
  }

  selected <- candidates_ok %>% slice(1)
  df_raw <- readxl::read_excel(
    input_info$path,
    sheet = selected$sheet[[1]],
    skip = selected$skip[[1]],
    .name_repair = "minimal"
  )

  list(
    df = janitor::clean_names(as_tibble(df_raw)),
    source_kind = "excel",
    source_path = input_info$path,
    source_sheet = selected$sheet[[1]],
    source_skip = selected$skip[[1]]
  )
}

recode_self_report_capacity <- function(x) {
  x_num <- safe_num(x)
  vals <- sort(unique(x_num[!is.na(x_num)]))
  if (length(vals) == 0) return(rep(NA_real_, length(x_num)))

  if (all(vals %in% c(0, 1, 2))) {
    return(case_when(
      is.na(x_num) ~ NA_real_,
      x_num == 0 ~ 2,
      x_num == 1 ~ 1,
      x_num == 2 ~ 0,
      TRUE ~ NA_real_
    ))
  }

  if (all(vals %in% c(1, 2, 3))) {
    return(case_when(
      is.na(x_num) ~ NA_real_,
      x_num == 1 ~ 2,
      x_num == 2 ~ 1,
      x_num == 3 ~ 0,
      TRUE ~ NA_real_
    ))
  }

  rep(NA_real_, length(x_num))
}

normalize_binary01 <- function(x) {
  x_num <- safe_num(x)
  out <- rep(NA_integer_, length(x_num))
  out[!is.na(x_num) & x_num %in% c(0, 1)] <- as.integer(x_num[!is.na(x_num) & x_num %in% c(0, 1)])
  out
}

normalize_sex_binary <- function(x) {
  x_num <- safe_num(x)
  out <- trimws(as.character(x))
  out[!is.na(x_num) & x_num == 0] <- "female"
  out[!is.na(x_num) & x_num == 1] <- "male"
  out[!nzchar(out) | out %in% c("2", "3", "-1")] <- NA_character_
  out
}

clean_nonnegative <- function(x, allow_zero = TRUE) {
  x_num <- safe_num(x)
  if (allow_zero) {
    x_num[x_num < 0] <- NA_real_
  } else {
    x_num[x_num <= 0] <- NA_real_
  }
  x_num
}

to_gait_speed <- function(x, source_name) {
  x_num <- clean_nonnegative(x, allow_zero = FALSE)
  source_label <- if (length(source_name) == 0 || is.na(source_name)) "" else source_name
  if (str_detect(source_label, "kavelynopeus_m_sek")) {
    return(x_num)
  }
  10 / x_num
}

build_balance_capacity <- function(summary_vec, right_vec, left_vec) {
  if (!all(is.na(summary_vec))) {
    balance <- clean_nonnegative(summary_vec, allow_zero = TRUE)
  } else {
    right_num <- clean_nonnegative(right_vec, allow_zero = TRUE)
    left_num <- clean_nonnegative(left_vec, allow_zero = TRUE)
    balance <- na_row_mean(cbind(right_num, left_num))
  }
  balance[balance > BALANCE_MAX_SECONDS] <- NA_real_
  balance
}

baseline_anchor_scores <- function(base, followup) {
  mu <- mean(base, na.rm = TRUE)
  sig <- sd(base, na.rm = TRUE)
  if (!is.finite(mu) || !is.finite(sig) || sig <= 0) {
    return(list(
      baseline = rep(NA_real_, length(base)),
      followup = rep(NA_real_, length(followup)),
      mean = mu,
      sd = sig
    ))
  }
  list(
    baseline = (base - mu) / sig,
    followup = (followup - mu) / sig,
    mean = mu,
    sd = sig
  )
}

fit_capacity_cfa <- function(df_baseline, df_followup) {
  rhs <- c("gait", "chair", "balance")
  model_cfa <- paste0("Capacity =~ ", paste(rhs, collapse = " + "))
  ordered_vars <- character(0)
  estimator <- "MLR"
  score_method <- "regression"
  df_baseline <- as_tibble(df_baseline) %>%
    mutate(across(everything(), ~ {
      x <- as.numeric(.x)
      x[!is.finite(x)] <- NA_real_
      x
    }))
  df_followup <- as_tibble(df_followup) %>%
    mutate(across(everything(), ~ {
      x <- as.numeric(.x)
      x[!is.finite(x)] <- NA_real_
      x
    }))
  baseline_complete <- complete.cases(df_baseline[, rhs])
  followup_complete <- complete.cases(df_followup[, rhs])

  if (sum(baseline_complete) < 10) {
    return(list(
      fit = NULL,
      baseline_score = rep(NA_real_, nrow(df_baseline)),
      followup_score = rep(NA_real_, nrow(df_followup)),
      diagnostics = tibble(
        converged_ok = FALSE,
        has_neg_resid_var = NA,
        has_std_loading_gt1 = NA,
        baseline_score_na_share = 1,
        followup_score_na_share = 1,
        score_na_share = 1,
        loading_signs_ok = NA,
        score_method = score_method,
        admissible = FALSE,
        reason = "too_few_baseline_complete_cases",
        warning_count = 0,
        warnings = NA_character_
      )
    ))
  }

  df_fit <- df_baseline[baseline_complete, rhs, drop = FALSE]

  cfa_warn <- character(0)
  fit <- withCallingHandlers(
    tryCatch(
      lavaan::cfa(
        model = model_cfa,
        data = df_fit,
        estimator = estimator,
        ordered = ordered_vars,
        missing = "listwise"
      ),
      error = function(e) e
    ),
    warning = function(w) {
      cfa_warn <<- c(cfa_warn, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  if (inherits(fit, "error")) {
    return(list(
      fit = NULL,
      baseline_score = rep(NA_real_, nrow(df_baseline)),
      followup_score = rep(NA_real_, nrow(df_followup)),
      diagnostics = tibble(
        converged_ok = FALSE,
        has_neg_resid_var = NA,
        has_std_loading_gt1 = NA,
        baseline_score_na_share = 1,
        followup_score_na_share = 1,
        score_na_share = 1,
        loading_signs_ok = NA,
        score_method = score_method,
        admissible = FALSE,
        reason = paste0("cfa_error: ", conditionMessage(fit)),
        warning_count = length(cfa_warn),
        warnings = paste(unique(cfa_warn), collapse = " | ")
      )
    ))
  }

  pe <- lavaan::parameterEstimates(fit, standardized = TRUE) %>% as_tibble()
  loadings <- pe %>% filter(op == "=~")
  resid_vars <- pe %>%
    filter(op == "~~", lhs == rhs, lhs %in% c("gait", "chair", "balance"))

  baseline_fs <- tryCatch(lavaan::lavPredict(fit, method = score_method), error = function(e) NULL)
  followup_fs <- tryCatch(
    lavaan::lavPredict(fit, newdata = df_followup[followup_complete, rhs, drop = FALSE], method = score_method),
    error = function(e) e
  )

  baseline_score <- rep(NA_real_, nrow(df_baseline))
  if (!is.null(baseline_fs)) {
    baseline_score[baseline_complete] <- as.numeric(baseline_fs[, 1])
  }
  followup_score <- rep(NA_real_, nrow(df_followup))
  if (!inherits(followup_fs, "error") && !is.null(followup_fs) && sum(followup_complete) > 0) {
    followup_score[followup_complete] <- as.numeric(followup_fs[, 1])
  }

  converged_ok <- isTRUE(lavaan::lavInspect(fit, "converged"))
  has_neg_resid_var <- any(resid_vars$est < 0, na.rm = TRUE)
  has_std_loading_gt1 <- any(abs(loadings$std.all) > 1, na.rm = TRUE)
  baseline_score_na_share <- mean(is.na(baseline_score))
  followup_score_na_share <- mean(is.na(followup_score))
  score_na_share <- mean(c(is.na(baseline_score), is.na(followup_score)))

  expected_sign_map <- c(
    gait = 1,
    chair = 1,
    balance = 1
  )

  load_sign_tbl <- loadings %>%
    transmute(
      indicator = rhs,
      std.all = std.all,
      actual_sign = sign(std.all),
      expected_sign = expected_sign_map[indicator]
    )

  gait_loading <- load_sign_tbl %>% filter(indicator == "gait") %>% pull(std.all)
  gait_loading <- if (length(gait_loading) > 0) gait_loading[1] else NA_real_

  pos_expected <- load_sign_tbl %>% filter(expected_sign == 1, !is.na(std.all))
  pos_negative_count <- sum(pos_expected$std.all < 0, na.rm = TRUE)
  pos_total <- nrow(pos_expected)
  majority_expected_positive_negative <- (pos_total > 0) && (pos_negative_count > (pos_total / 2))

  orientation_flip_applied <- (!is.na(gait_loading) && gait_loading < 0) || majority_expected_positive_negative
  if (isTRUE(orientation_flip_applied)) {
    baseline_score <- -1 * baseline_score
    followup_score <- -1 * followup_score
  }

  load_sign_tbl <- load_sign_tbl %>%
    mutate(oriented_sign = if (isTRUE(orientation_flip_applied)) -1 * actual_sign else actual_sign)

  comparable <- load_sign_tbl %>%
    filter(!is.na(expected_sign), !is.na(oriented_sign), oriented_sign != 0)
  loading_signs_ok <- if (nrow(comparable) == 0) FALSE else all(comparable$oriented_sign == comparable$expected_sign)

  admissible <- isTRUE(converged_ok) && !has_neg_resid_var && !has_std_loading_gt1 &&
    isTRUE(loading_signs_ok) && (baseline_score_na_share <= SCORE_NA_SHARE_MAX)

  reason <- c()
  if (!converged_ok) reason <- c(reason, "not_converged")
  if (has_neg_resid_var) reason <- c(reason, "neg_resid_var")
  if (has_std_loading_gt1) reason <- c(reason, "std_loading_gt1")
  if (!isTRUE(loading_signs_ok)) reason <- c(reason, "loading_sign_mismatch")
  if (baseline_score_na_share > SCORE_NA_SHARE_MAX) reason <- c(reason, "baseline_score_na_share_high")
  if (inherits(followup_fs, "error")) reason <- c(reason, "followup_scoring_error")
  if (length(reason) == 0) reason <- "admissible"

  list(
    fit = fit,
    baseline_score = baseline_score,
    followup_score = followup_score,
    diagnostics = tibble(
      converged_ok = converged_ok,
      has_neg_resid_var = has_neg_resid_var,
      has_std_loading_gt1 = has_std_loading_gt1,
      baseline_score_na_share = baseline_score_na_share,
      followup_score_na_share = followup_score_na_share,
      score_na_share = score_na_share,
      loading_signs_ok = loading_signs_ok,
      orientation_flip_applied = orientation_flip_applied,
      gait_loading_std_all = gait_loading,
      expected_sign_map = "gait:+;chair:+;balance:+",
      score_method = score_method,
      admissible = admissible,
      reason = paste(reason, collapse = ";"),
      warning_count = length(cfa_warn),
      warnings = paste(unique(c(cfa_warn, if (inherits(followup_fs, "error")) conditionMessage(followup_fs) else NULL)), collapse = " | ")
    )
  )
}

save_lavaan_outputs <- function(fit, prefix) {
  sum_path <- file.path(outputs_dir, paste0(prefix, "_summary.txt"))
  load_path <- file.path(outputs_dir, paste0(prefix, "_loadings.csv"))

  if (is.null(fit)) {
    write_lines_safely(c(paste0(prefix, " - cfa failed (no fit object)")), sum_path)
    write_csv_safely(tibble(), load_path)
    append_manifest_safe(label = paste0(prefix, "_summary"), kind = "text", path = sum_path)
    append_manifest_safe(label = paste0(prefix, "_loadings"), kind = "table_csv", path = load_path)
    return(invisible(list(summary = sum_path, loadings = load_path)))
  }

  lines <- c(
    paste0(prefix, " - lavaan CFA"),
    capture.output(summary(fit, standardized = TRUE, fit.measures = TRUE))
  )
  write_lines_safely(lines, sum_path)
  append_manifest_safe(label = paste0(prefix, "_summary"), kind = "text", path = sum_path)

  pe <- parameterEstimates(fit, standardized = TRUE) %>%
    as_tibble() %>%
    filter(op == "=~") %>%
    select(lhs, op, rhs, est, se, z, pvalue, std.all)
  write_csv_safely(pe, load_path)
  append_manifest_safe(label = paste0(prefix, "_loadings"), kind = "table_csv", path = load_path)

  invisible(list(summary = sum_path, loadings = load_path))
}

# --- 1) Load input -------------------------------------------------------------
dir_create(outputs_dir)
input_info <- find_input_dataset()
loaded_input <- load_input_dataset(input_info)
df <- loaded_input$df

colnames_path <- file.path(outputs_dir, "k32_columns_after_clean_names.txt")
write_lines_safely(sort(names(df)), colnames_path)
append_manifest_safe(label = "k32_columns_after_clean_names", kind = "text", path = colnames_path)

message(
  "Loaded input: ", basename(loaded_input$source_path),
  " (sheet=", ifelse(is.na(loaded_input$source_sheet), "NA", loaded_input$source_sheet),
  ", skip=", ifelse(is.na(loaded_input$source_skip), "NA", as.character(loaded_input$source_skip)),
  ", rows=", nrow(df), ", cols=", ncol(df), ")"
)

# --- 2) Resolve indicator mapping ---------------------------------------------
map_res <- build_mapping(names(df))
map <- map_res$mapped

if (length(map_res$unresolved_required) > 0) {
  lines <- c(
    "K32 mapping unresolved.",
    paste0("Missing required: ", paste(map_res$unresolved_required, collapse = ", "))
  )
  for (k in names(map)) {
    if (is.na(map[[k]]) && k %in% names(column_candidates)) {
      lines <- c(lines, paste0("- target: ", k), paste0("  closest: ", paste(closest_match(k, names(df)), collapse = ", ")))
    }
  }
  suggest_path <- file.path(outputs_dir, "k32_mapping_suggestions.txt")
  write_lines_safely(lines, suggest_path)
  append_manifest_safe(label = "k32_mapping_suggestions", kind = "text", path = suggest_path)
  stop("K32 mapping failed. See: ", suggest_path, call. = FALSE)
}

mapping_audit <- tibble(
  key = names(map),
  resolved = unname(map),
  status = case_when(
    names(map) %in% map_res$unresolved_required ~ "missing_required",
    names(map) %in% map_res$ambiguity_tbl$key ~ "ambiguous",
    is.na(map) ~ "optional_missing",
    TRUE ~ "resolved"
  )
)
mapping_audit_path <- file.path(outputs_dir, "k32_mapping_audit.csv")
write_csv_safely(mapping_audit, mapping_audit_path)
append_manifest_safe("k32_mapping_audit", "table_csv", mapping_audit_path, n = nrow(mapping_audit))

if (nrow(map_res$ambiguity_tbl) > 0) {
  ambiguity_path <- file.path(outputs_dir, "k32_mapping_ambiguity.csv")
  write_csv_safely(map_res$ambiguity_tbl, ambiguity_path)
  append_manifest_safe("k32_mapping_ambiguity", "table_csv", ambiguity_path, n = nrow(map_res$ambiguity_tbl))
  stop("K32 mapping failed due to ambiguous candidate matches. See: ", ambiguity_path, call. = FALSE)
}

pick_num <- function(key) {
  if (is.na(map[[key]])) return(rep(NA_real_, nrow(df)))
  safe_num(df[[map[[key]]]])
}

pick_chr <- function(key) {
  if (is.na(map[[key]])) return(rep(NA_character_, nrow(df)))
  as.character(df[[map[[key]]]])
}

self_raw <- if (!is.na(map[["self_report"]])) df[[map[["self_report"]]]] else rep(NA_real_, nrow(df))
self_capacity <- recode_self_report_capacity(self_raw)
self_capacity_ord <- factor(self_capacity, levels = c(0, 1, 2), ordered = TRUE)

balance_0 <- build_balance_capacity(
  summary_vec = pick_num("balance_0"),
  right_vec = pick_num("balance_right_0"),
  left_vec = pick_num("balance_left_0")
)
balance_2 <- build_balance_capacity(
  summary_vec = pick_num("balance_2"),
  right_vec = pick_num("balance_right_2"),
  left_vec = pick_num("balance_left_2")
)

wide_export <- tibble(
  id = pick_chr("id"),
  FOF_status = normalize_binary01(pick_num("fof_status")),
  age = pick_num("age"),
  sex = normalize_sex_binary(pick_chr("sex")),
  BMI = pick_num("bmi"),
  tasapainovaikeus = normalize_binary01(pick_num("tasapainovaikeus")),
  indicator_gait_raw_0 = pick_num("gait_0"),
  indicator_gait_raw_2 = pick_num("gait_2"),
  indicator_chair_raw_0 = pick_num("chair_0"),
  indicator_chair_raw_2 = pick_num("chair_2"),
  indicator_balance_raw_0 = balance_0,
  indicator_balance_raw_2 = balance_2,
  indicator_self_report_raw = safe_num(self_raw),
  indicator_self_report_capacity = self_capacity,
  indicator_self_report_ordered = self_capacity_ord
) %>%
  mutate(
    indicator_gait_primary_0 = to_gait_speed(indicator_gait_raw_0, map[["gait_0"]]),
    indicator_gait_primary_12m = to_gait_speed(indicator_gait_raw_2, map[["gait_2"]]),
    indicator_chair_capacity_0 = -1 * clean_nonnegative(indicator_chair_raw_0, allow_zero = FALSE),
    indicator_chair_capacity_12m = -1 * clean_nonnegative(indicator_chair_raw_2, allow_zero = FALSE),
    indicator_balance_capacity_0 = indicator_balance_raw_0,
    indicator_balance_capacity_12m = indicator_balance_raw_2
  ) %>%
  filter(!is.na(id), nzchar(id))

long_primary <- bind_rows(
  wide_export %>%
    transmute(id, time = 0L, FOF_status, age, sex, BMI, tasapainovaikeus,
              gait = indicator_gait_primary_0, chair = indicator_chair_capacity_0,
              balance = indicator_balance_capacity_0),
  wide_export %>%
    transmute(id, time = 12L, FOF_status, age, sex, BMI, tasapainovaikeus,
              gait = indicator_gait_primary_12m, chair = indicator_chair_capacity_12m,
              balance = indicator_balance_capacity_12m)
) %>% arrange(id, time)

# --- 3) Audits ----------------------------------------------------------------
cont_audit <- bind_rows(
  audit_cont(long_primary$gait) %>% mutate(var = "indicator_gait_primary_long"),
  audit_cont(long_primary$chair) %>% mutate(var = "indicator_chair_capacity_long"),
  audit_cont(long_primary$balance) %>% mutate(var = "indicator_balance_capacity_long")
) %>% select(var, everything())
cont_path <- file.path(outputs_dir, "k32_audit_continuous.csv")
write_csv_safely(cont_audit, cont_path)
append_manifest_safe(label = "k32_audit_continuous", kind = "table_csv", path = cont_path, n = nrow(long_primary))

self_tbl <- audit_cat(wide_export$indicator_self_report_raw)
self_path <- file.path(outputs_dir, "k32_audit_self_report_freq.csv")
write_csv_safely(self_tbl, self_path)
append_manifest_safe(label = "k32_audit_self_report_freq", kind = "table_csv", path = self_path, n = nrow(wide_export))

corr_vars <- wide_export %>% transmute(
  gait_0 = indicator_gait_primary_0,
  chair_0 = indicator_chair_capacity_0,
  balance_0 = indicator_balance_capacity_0,
  gait_12m = indicator_gait_primary_12m,
  chair_12m = indicator_chair_capacity_12m,
  balance_12m = indicator_balance_capacity_12m
)
cor_mat <- suppressWarnings(cor(corr_vars, use = "pairwise.complete.obs"))
cor_tbl <- as.data.frame(as.table(cor_mat)) %>%
  as_tibble() %>%
  rename(var1 = Var1, var2 = Var2, r = Freq)
cor_path <- file.path(outputs_dir, "k32_audit_correlations.csv")
write_csv_safely(cor_tbl, cor_path)
append_manifest_safe(label = "k32_audit_correlations", kind = "table_csv", path = cor_path, n = nrow(wide_export))

flags <- tibble(
  flag_missing_fof = mean(is.na(wide_export$FOF_status)),
  flag_missing_covariates = mean(!complete.cases(wide_export %>% select(age, sex, BMI))),
  flag_walkspeed_missing_0 = mean(is.na(wide_export$indicator_gait_primary_0)),
  flag_walkspeed_missing_12m = mean(is.na(wide_export$indicator_gait_primary_12m))
)
flags_path <- file.path(outputs_dir, "k32_red_flags.csv")
write_csv_safely(flags, flags_path)
append_manifest_safe(label = "k32_red_flags", kind = "table_csv", path = flags_path, n = nrow(wide_export))

primary_complete <- complete.cases(long_primary$gait, long_primary$chair, long_primary$balance)

decision_lines <- c(
  "K32 decisions (core performance-based locomotor capacity model)",
  paste0("Input source: ", loaded_input$source_path),
  paste0("Input kind: ", loaded_input$source_kind),
  paste0("Input sheet: ", ifelse(is.na(loaded_input$source_sheet), "NA", loaded_input$source_sheet)),
  paste0("Input skip: ", ifelse(is.na(loaded_input$source_skip), "NA", as.character(loaded_input$source_skip))),
  paste0("Rows loaded: ", nrow(df)),
  "Time-map locked for locomotor CFA source variables: 0 = baseline, 2 = 12 months.",
  paste0("- gait baseline source: ", map[["gait_0"]]),
  paste0("- gait follow-up source: ", map[["gait_2"]]),
  paste0("- chair baseline source: ", map[["chair_0"]]),
  paste0("- chair follow-up source: ", map[["chair_2"]]),
  paste0("- balance baseline source: ", ifelse(!is.na(map[["balance_0"]]), map[["balance_0"]], paste(map[c("balance_right_0", "balance_left_0")], collapse = " + "))),
  paste0("- balance follow-up source: ", ifelse(!is.na(map[["balance_2"]]), map[["balance_2"]], paste(map[c("balance_right_2", "balance_left_2")], collapse = " + "))),
  "Longitudinal export touchpoint: K32 producing layer writes canonical K50-ready wide and long datasets.",
  "Primary factor is fit on the baseline frame and scored with regression factor scores for both baseline and 12-month rows.",
  "Expected loading sign map after indicator reorientation: gait(+), chair(+), balance(+).",
  "Factor score orientation rule: if gait loading is negative OR majority expected-positive indicators load negative, multiply latent score by -1.",
  paste0("Hard CFA gate: primary admissibility must be TRUE and each canonical score column must satisfy completeness >= ", MIN_CANONICAL_SCORE_COMPLETENESS, "."),
  "z3 is baseline-anchored using baseline indicator mean/sd for both baseline and 12-month values.",
  "Composite_Z is not used in this export step. FI22 is joined only as a separate sensitivity-only external index and remains outside locomotor construction.",
  paste0("Rows retained in primary core model: ", sum(primary_complete))
)
dec_path <- file.path(outputs_dir, "k32_decision_log.txt")
write_lines_safely(decision_lines, dec_path)
append_manifest_safe(label = "k32_decision_log", kind = "text", path = dec_path, n = nrow(wide_export))

# --- 4) CFA -------------------------------------------------------------------
cfa_primary <- fit_capacity_cfa(
  wide_export %>% transmute(gait = indicator_gait_primary_0, chair = indicator_chair_capacity_0, balance = indicator_balance_capacity_0),
  wide_export %>% transmute(gait = indicator_gait_primary_12m, chair = indicator_chair_capacity_12m, balance = indicator_balance_capacity_12m)
)

wide_export <- wide_export %>% mutate(
  locomotor_capacity_0 = cfa_primary$baseline_score,
  locomotor_capacity_12m = cfa_primary$followup_score
)

save_lavaan_outputs(cfa_primary$fit, "k32_cfa_primary")

cfa_diag <- cfa_primary$diagnostics %>%
  mutate(model = "primary_baseline_fit_regression_scores", core_model = TRUE) %>%
  select(model, core_model, everything())
cfa_diag_path <- file.path(outputs_dir, "k32_cfa_diagnostics.csv")
write_csv_safely(cfa_diag, cfa_diag_path)
append_manifest_safe(label = "k32_cfa_diagnostics", kind = "table_csv", path = cfa_diag_path, n = nrow(cfa_diag))

# --- 5) Baseline-anchored z3 composites --------------------------------------
gait_z <- baseline_anchor_scores(wide_export$indicator_gait_primary_0, wide_export$indicator_gait_primary_12m)
chair_z <- baseline_anchor_scores(wide_export$indicator_chair_capacity_0, wide_export$indicator_chair_capacity_12m)
balance_z <- baseline_anchor_scores(wide_export$indicator_balance_capacity_0, wide_export$indicator_balance_capacity_12m)

wide_export <- wide_export %>%
  mutate(
    z3_0 = na_row_mean(cbind(gait_z$baseline, chair_z$baseline, balance_z$baseline)),
    z3_12m = na_row_mean(cbind(gait_z$followup, chair_z$followup, balance_z$followup))
  )

data_root <- resolve_data_root()
fi22_external <- load_fi22_external(data_root)
wide_export <- wide_export %>%
  mutate(id = trimws(as.character(.data$id))) %>%
  left_join(fi22_external$data, by = "id")

canonical_wide <- wide_export %>%
  transmute(
    id, FOF_status, age, sex, BMI, tasapainovaikeus,
    FI22_nonperformance_KAAOS,
    locomotor_capacity_0,
    locomotor_capacity_12m,
    z3_0, z3_12m
  )

canonical_long <- bind_rows(
  canonical_wide %>%
    transmute(id, time = 0L, FOF_status, age, sex, BMI, tasapainovaikeus,
              FI22_nonperformance_KAAOS,
              locomotor_capacity = locomotor_capacity_0, z3 = z3_0),
  canonical_wide %>%
    transmute(id, time = 12L, FOF_status, age, sex, BMI, tasapainovaikeus,
              FI22_nonperformance_KAAOS,
              locomotor_capacity = locomotor_capacity_12m, z3 = z3_12m)
) %>% arrange(id, time)

baseline_aliases <- canonical_long %>%
  filter(time == 0L) %>%
  transmute(
    id,
    capacity_score_latent_primary = locomotor_capacity,
    capacity_score_z3_primary = z3,
    capacity_score_z3_sensitivity = z3
  )

df_scored <- wide_export %>% left_join(baseline_aliases, by = "id")

score_summ <- tibble(
  score = c(
    "locomotor_capacity_0",
    "locomotor_capacity_12m",
    "z3_0",
    "z3_12m"
  ),
  n = c(
    sum(!is.na(canonical_wide$locomotor_capacity_0)),
    sum(!is.na(canonical_wide$locomotor_capacity_12m)),
    sum(!is.na(canonical_wide$z3_0)),
    sum(!is.na(canonical_wide$z3_12m))
  ),
  mean = c(
    mean(canonical_wide$locomotor_capacity_0, na.rm = TRUE),
    mean(canonical_wide$locomotor_capacity_12m, na.rm = TRUE),
    mean(canonical_wide$z3_0, na.rm = TRUE),
    mean(canonical_wide$z3_12m, na.rm = TRUE)
  ),
  sd = c(
    sd(canonical_wide$locomotor_capacity_0, na.rm = TRUE),
    sd(canonical_wide$locomotor_capacity_12m, na.rm = TRUE),
    sd(canonical_wide$z3_0, na.rm = TRUE),
    sd(canonical_wide$z3_12m, na.rm = TRUE)
  )
)
scores_path <- file.path(outputs_dir, "k32_scores_summary.csv")
write_csv_safely(score_summ, scores_path)
append_manifest_safe(label = "k32_scores_summary", kind = "table_csv", path = scores_path, n = nrow(score_summ))

export_qc <- tibble(
  check = c(
    "primary_cfa_admissible",
    "wide_id_unique",
    "wide_canonical_cols_present",
    "fi22_present_sensitivity_only",
    "locomotor_capacity_content_share_ok",
    "z3_content_share_ok",
    "long_time_exact_levels_0_12",
    "long_two_rows_per_id",
    "long_values_match_wide",
    "composite_z_not_exported"
  ),
  ok = c(
    isTRUE(cfa_primary$diagnostics$admissible[[1]]),
    n_distinct(canonical_wide$id) == nrow(canonical_wide),
    all(c("FI22_nonperformance_KAAOS", "locomotor_capacity_0", "locomotor_capacity_12m", "z3_0", "z3_12m") %in% names(canonical_wide)),
    "FI22_nonperformance_KAAOS" %in% names(canonical_wide) &&
      "FI22_nonperformance_KAAOS" %in% names(canonical_long) &&
      !("FI22_nonperformance_KAAOS" %in% c("locomotor_capacity_0", "locomotor_capacity_12m", "z3_0", "z3_12m")),
    all(c(
      mean(!is.na(canonical_wide$locomotor_capacity_0)),
      mean(!is.na(canonical_wide$locomotor_capacity_12m))
    ) >= MIN_CANONICAL_SCORE_COMPLETENESS),
    all(c(
      mean(!is.na(canonical_wide$z3_0)),
      mean(!is.na(canonical_wide$z3_12m))
    ) >= MIN_CANONICAL_SCORE_COMPLETENESS),
    identical(sort(unique(canonical_long$time)), c(0L, 12L)),
    all((canonical_long %>% count(id, name = "n"))$n == 2L),
    identical(
      canonical_long %>%
        arrange(id, time) %>%
        transmute(id, time, FI22_nonperformance_KAAOS, locomotor_capacity, z3),
      bind_rows(
        canonical_wide %>% transmute(id, time = 0L, FI22_nonperformance_KAAOS, locomotor_capacity = locomotor_capacity_0, z3 = z3_0),
        canonical_wide %>% transmute(id, time = 12L, FI22_nonperformance_KAAOS, locomotor_capacity = locomotor_capacity_12m, z3 = z3_12m)
      ) %>% arrange(id, time)
    ),
    !("Composite_Z" %in% names(canonical_wide)) && !("Composite_Z" %in% names(canonical_long))
  ),
  detail = c(
    paste0("admissible=", cfa_primary$diagnostics$admissible[[1]], "; reason=", cfa_primary$diagnostics$reason[[1]]),
    paste0("nrow=", nrow(canonical_wide), "; n_distinct_id=", n_distinct(canonical_wide$id)),
    paste(names(canonical_wide), collapse = ";"),
    paste0("fi22_source_rows=", fi22_external$n, "; fi22_nonmissing_share=", round(mean(!is.na(canonical_wide$FI22_nonperformance_KAAOS)), 3), "; role=sensitivity_only"),
    paste0("lc0=", round(mean(!is.na(canonical_wide$locomotor_capacity_0)), 3), "; lc12=", round(mean(!is.na(canonical_wide$locomotor_capacity_12m)), 3)),
    paste0("z30=", round(mean(!is.na(canonical_wide$z3_0)), 3), "; z312=", round(mean(!is.na(canonical_wide$z3_12m)), 3)),
    paste(sort(unique(canonical_long$time)), collapse = ";"),
    paste((canonical_long %>% count(id, name = "n") %>% count(n, name = "freq") %>% transmute(x = paste0(n, ":", freq)))$x, collapse = ";"),
    "long locomotor_capacity/z3 values must equal their wide counterparts exactly after reshaping.",
    "Composite_Z branch remains verification-only and absent from K32 export."
  )
)
export_qc_path <- file.path(outputs_dir, "k32_canonical_export_qc.csv")
write_csv_safely(export_qc, export_qc_path)
append_manifest_safe(label = "k32_canonical_export_qc", kind = "table_csv", path = export_qc_path, n = nrow(export_qc))

if (!all(export_qc$ok)) {
  stop("K32 canonical export QC failed. See: ", export_qc_path, call. = FALSE)
}

# --- 6) Save datasets + reproducibility ---------------------------------------
capacity_dir <- file.path(data_root, "paper_01", "capacity_scores")
analysis_dir <- file.path(data_root, "paper_01", "analysis")
dir_create(capacity_dir)
dir_create(analysis_dir)

out_csv <- file.path(capacity_dir, "kaatumisenpelko_with_capacity_scores_k32.csv")
out_rds <- file.path(capacity_dir, "kaatumisenpelko_with_capacity_scores_k32.rds")
wide_csv <- file.path(analysis_dir, "fof_analysis_k50_wide.csv")
wide_rds <- file.path(analysis_dir, "fof_analysis_k50_wide.rds")
long_csv <- file.path(analysis_dir, "fof_analysis_k50_long.csv")
long_rds <- file.path(analysis_dir, "fof_analysis_k50_long.rds")

write_csv_safely(df_scored, out_csv)
write_rds_safely(df_scored, out_rds)
write_csv_safely(canonical_wide, wide_csv)
write_rds_safely(canonical_wide, wide_rds)
write_csv_safely(canonical_long, long_csv)
write_rds_safely(canonical_long, long_rds)

append_manifest_safe("k32_capacity_scores_csv", "table_csv", out_csv, n = nrow(df_scored), notes = "Baseline aliases retained for K32 compatibility.")
append_manifest_safe("k32_capacity_scores_rds", "table_rds", out_rds, n = nrow(df_scored), notes = "Baseline aliases retained for K32 compatibility.")
append_manifest_safe("k32_canonical_k50_wide_csv", "table_csv", wide_csv, n = nrow(canonical_wide), notes = "Canonical K50-ready wide upstream export with sensitivity-only FI22 covariate.")
append_manifest_safe("k32_canonical_k50_wide_rds", "table_rds", wide_rds, n = nrow(canonical_wide), notes = "Canonical K50-ready wide upstream export with sensitivity-only FI22 covariate.")
append_manifest_safe("k32_canonical_k50_long_csv", "table_csv", long_csv, n = nrow(canonical_long), notes = "Canonical K50-ready long upstream export with sensitivity-only FI22 covariate.")
append_manifest_safe("k32_canonical_k50_long_rds", "table_rds", long_rds, n = nrow(canonical_long), notes = "Canonical K50-ready long upstream export with sensitivity-only FI22 covariate.")

receipt_path <- file.path(outputs_dir, "k32_patient_level_output_receipt.txt")
receipt_lines <- c(
  paste0("script=", script_label),
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("data_root=", data_root),
  paste0("input_source=", loaded_input$source_path),
  paste0("input_kind=", loaded_input$source_kind),
  paste0("input_sheet=", ifelse(is.na(loaded_input$source_sheet), "NA", loaded_input$source_sheet)),
  paste0("input_skip=", ifelse(is.na(loaded_input$source_skip), "NA", as.character(loaded_input$source_skip))),
  paste0("fi22_source_path=", fi22_external$path),
  paste0("fi22_source_md5=", unname(tools::md5sum(fi22_external$path)[1])),
  paste0("capacity_dir=", capacity_dir),
  paste0("analysis_dir=", analysis_dir),
  paste0("k32_capacity_csv_path=", out_csv),
  paste0("k32_capacity_csv_md5=", unname(tools::md5sum(out_csv)[1])),
  paste0("k32_capacity_rds_path=", out_rds),
  paste0("k32_capacity_rds_md5=", unname(tools::md5sum(out_rds)[1])),
  paste0("k50_wide_csv_path=", wide_csv),
  paste0("k50_wide_csv_md5=", unname(tools::md5sum(wide_csv)[1])),
  paste0("k50_wide_rds_path=", wide_rds),
  paste0("k50_wide_rds_md5=", unname(tools::md5sum(wide_rds)[1])),
  paste0("k50_long_csv_path=", long_csv),
  paste0("k50_long_csv_md5=", unname(tools::md5sum(long_csv)[1])),
  paste0("k50_long_rds_path=", long_rds),
  paste0("k50_long_rds_md5=", unname(tools::md5sum(long_rds)[1])),
  paste0("wide_nrow=", nrow(canonical_wide)),
  paste0("long_nrow=", nrow(canonical_long))
)
write_lines_safely(receipt_lines, receipt_path)
append_manifest_safe(
  label = "k32_patient_level_output_receipt",
  kind = "text",
  path = receipt_path,
  n = nrow(canonical_wide),
  notes = "Patient-level K32 compatibility and canonical K50 datasets written to DATA_ROOT."
)

sess_path <- file.path(outputs_dir, "k32_sessioninfo.txt")
write_lines_safely(capture.output(sessionInfo()), sess_path)
append_manifest_safe(label = "k32_sessioninfo", kind = "text", path = sess_path)

message("K32 complete. Outputs written to: ", outputs_dir)
