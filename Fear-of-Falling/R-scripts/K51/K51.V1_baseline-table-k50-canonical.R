#!/usr/bin/env Rscript
# ==============================================================================
# K51 - Baseline Table for K50 Canonical Cohorts
# File tag: K51.V1_baseline-table-k50-canonical.R
# Purpose: Build paper_02 Table 1 style summaries from canonical K50-ready data
#          using the shared person-dedup helper and the same participant gates
#          as the current deduplicated K50 cohort-flow path.
#
# Outcome: locomotor_capacity
# Predictors: FOF_status
# Moderator/interaction: none
# Grouping variable: FOF_status or analytic_flag (selection comparison only)
# Covariates: age, sex, BMI, FI22_nonperformance_KAAOS, tasapainovaikeus
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, time, FOF_status, age, sex, BMI, locomotor_capacity, locomotor_capacity_0,
# locomotor_capacity_12m, z3, z3_0, z3_12m, Composite_Z, Composite_Z_0,
# Composite_Z_12m, FI22_nonperformance_KAAOS, tasapainovaikeus
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (not used; no randomness)
#
# Outputs + manifest:
# - script_label: K51
# - outputs dir: R-scripts/K51/outputs/
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + dirs
# 02) Resolve canonical input path from CLI / verified upstream candidates
# 03) Load immutable analysis-ready data
# 04) Apply shared person-level dedup via person_dedup_lookup.R
# 05) Reuse K50-style participant gating to derive analytic ids
# 06) Extract one-row-per-id baseline frame
# 07) Optionally enrich baseline rows from immutable raw K14 source
# 08) Build requested table for the selected cohort scope/profile
# 09) Save CSV/HTML + receipt + decision log + sessionInfo
# 10) Append manifest rows
# 11) EOF marker
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.[Rr]$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K51"
}
script_label <- "K51"
helper_label <- sub("\\.V.*$", "", script_base)

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "person_dedup_lookup.R"))
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

write_table_csv <- function(tbl, label, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".csv"))
  readr::write_csv(tbl, out_path, na = "")
  append_manifest_safe(label, "table_csv", out_path, n = nrow(tbl), notes = notes)
  out_path
}

escape_html <- function(x) {
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub("\"", "&quot;", x, fixed = TRUE)
  x
}

write_table_html <- function(tbl, label, title, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".html"))
  header <- paste0("<th>", escape_html(names(tbl)), "</th>", collapse = "")
  rows <- apply(tbl, 1, function(row) {
    paste0("<tr>", paste0("<td>", escape_html(row), "</td>", collapse = ""), "</tr>")
  })
  html <- c(
    "<html><head><meta charset='UTF-8'><title>",
    escape_html(title),
    "</title></head><body>",
    "<h1>", escape_html(title), "</h1>",
    "<table border='1' cellspacing='0' cellpadding='4'>",
    "<thead><tr>", header, "</tr></thead>",
    "<tbody>",
    rows,
    "</tbody></table></body></html>"
  )
  writeLines(html, con = out_path, useBytes = TRUE)
  append_manifest_safe(label, "table_html", out_path, n = nrow(tbl), notes = notes)
  out_path
}

write_debug_csv <- function(tbl, label, notes) {
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

parse_shape <- function(x) {
  val <- toupper(trimws(ifelse(is.null(x), "", as.character(x))))
  if (!val %in% c("LONG", "WIDE")) {
    stop("K51 requires explicit --shape LONG|WIDE.", call. = FALSE)
  }
  val
}

parse_scope <- function(x) {
  val <- trimws(ifelse(is.null(x), "", as.character(x)))
  if (!val %in% c("analytic", "baseline_eligible", "selection_compare", "analytic_wide_modeled")) {
    stop("K51 requires --cohort-scope analytic|baseline_eligible|selection_compare|analytic_wide_modeled.", call. = FALSE)
  }
  val
}

parse_profile <- function(x) {
  val <- trimws(ifelse(is.null(x), "", as.character(x)))
  if (!val %in% c("minimal", "k14_extended", "analytic_k14_extended")) {
    stop("K51 requires --table-profile minimal|k14_extended|analytic_k14_extended.", call. = FALSE)
  }
  val
}

is_extended_profile <- function(profile) {
  identical(profile, "k14_extended") || identical(profile, "analytic_k14_extended")
}

resolve_existing <- function(candidates) {
  hits <- candidates[file.exists(candidates)]
  if (length(hits) == 0L) return(NA_character_)
  normalizePath(hits[[1]], winslash = "/", mustWork = TRUE)
}

resolve_data_root <- function() {
  load_data_root_from_env_file()
  dr <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(dr)) return(NA_character_)
  normalizePath(dr, winslash = "/", mustWork = FALSE)
}

resolve_input_path <- function(shape, cli_data) {
  if (!is.null(cli_data) && nzchar(cli_data)) {
    if (!file.exists(cli_data)) {
      stop("K51 --data file not found: ", cli_data, call. = FALSE)
    }
    return(normalizePath(cli_data, winslash = "/", mustWork = TRUE))
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

  hit <- resolve_existing(candidates)
  if (is.na(hit)) {
    stop(
      paste0(
        "K51 could not resolve an input dataset. Supply --data explicitly.\n",
        "Tried:\n- ", paste(candidates, collapse = "\n- ")
      ),
      call. = FALSE
    )
  }
  hit
}

resolve_raw_input_path <- function(cli_data = NULL) {
  if (!is.null(cli_data) && nzchar(cli_data)) {
    if (!file.exists(cli_data)) {
      stop("K51 --raw-data file not found: ", cli_data, call. = FALSE)
    }
    return(normalizePath(cli_data, winslash = "/", mustWork = TRUE))
  }

  data_root <- resolve_data_root()
  candidates <- c(
    here::here("data", "external", "KAAOS_data_sotullinen.xlsx"),
    "/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/KAAOS_data_sotullinen.xlsx"
  )
  if (!is.na(data_root)) {
    candidates <- c(candidates, file.path(data_root, "paper_02", "KAAOS_data_sotullinen.xlsx"))
  }
  hit <- resolve_existing(unique(candidates))
  if (is.na(hit)) {
    stop("K51 could not resolve immutable baseline enrichment input `KAAOS_data_sotullinen.xlsx`.", call. = FALSE)
  }
  hit
}

resolve_override_map_path <- function() {
  path <- here::here("R-scripts", "K51", "K51_three_key_override_map.csv")
  if (!file.exists(path)) {
    stop("K51 override map not found: ", path, call. = FALSE)
  }
  normalizePath(path, winslash = "/", mustWork = TRUE)
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

normalize_header <- function(x) {
  out <- tolower(trimws(as.character(x)))
  out <- gsub("[\r\n\t]+", " ", out)
  out <- gsub("[[:space:]]+", " ", out)
  out <- gsub("[^[:alnum:]]+", "", out)
  out
}

pick_col_regex_first <- function(df_names, target, patterns) {
  norm_df <- normalize_header(df_names)
  for (pattern in patterns) {
    hits <- grepl(pattern, norm_df, perl = TRUE)
    if (sum(hits) == 1L) return(df_names[which(hits)[1]])
    if (sum(hits) > 1L) {
      stop("K51 baseline enrichment found multiple matches for ", target, ": ", paste(df_names[hits], collapse = ", "), call. = FALSE)
    }
  }
  stop("K51 baseline enrichment could not resolve column for ", target, ".", call. = FALSE)
}

pick_col_regex_optional <- function(df_names, patterns) {
  norm_df <- normalize_header(df_names)
  for (pattern in patterns) {
    hits <- grepl(pattern, norm_df, perl = TRUE)
    if (sum(hits) == 1L) return(df_names[which(hits)[1]])
  }
  NA_character_
}

read_bridge_probe <- function(path, sheet = NULL, skip = 0L) {
  if (!file.exists(path)) return(tibble())
  tbl <- tibble::as_tibble(readxl::read_excel(path, sheet = sheet, skip = skip, n_max = Inf))
  nm <- names(tbl)
  col_nro <- pick_col_regex_optional(nm, c("^nro$"))
  col_id <- pick_col_regex_optional(nm, c("^potilastunnus$", "^id$"))
  col_sotu <- pick_col_regex_optional(nm, c("^sotu$"))

  out <- tibble(
    probe_nro = if (!is.na(col_nro)) normalize_id(tbl[[col_nro]]) else NA_character_,
    probe_id = if (!is.na(col_id)) normalize_id(tbl[[col_id]]) else NA_character_,
    probe_sotu = if (!is.na(col_sotu)) normalize_ssn(tbl[[col_sotu]]) else NA_character_
  ) %>%
    distinct()

  out
}

normalize_sex_chr <- function(x) {
  out <- trimws(as.character(x))
  out[out == ""] <- NA_character_
  out
}

normalize_binary <- function(x) {
  suppressWarnings(as.integer(trimws(as.character(x))))
}

first_present <- function(nms, candidates) {
  hits <- candidates[candidates %in% nms]
  if (length(hits) == 0L) return(NA_character_)
  hits[[1]]
}

resolve_long_col <- function(outcome, nms) {
  first_present(nms, c(outcome))
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

format_pvalue <- function(p) {
  if (length(p) == 0L || is.na(p)) return("")
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

format_mean_sd <- function(x, group, group_levels = NULL, digits = 1) {
  keep <- !is.na(group)
  x <- x[keep]
  group <- group[keep]
  if (is.null(group_levels)) group_levels <- unique(as.character(group))
  out <- setNames(rep("", length(group_levels)), group_levels)
  for (lvl in group_levels) {
    xg <- x[as.character(group) == lvl & !is.na(x)]
    if (length(xg) == 0L) next
    out[[lvl]] <- paste0(
      format(round(mean(xg), digits), nsmall = digits),
      "(",
      format(round(stats::sd(xg), digits), nsmall = digits),
      ")"
    )
  }
  out
}

format_n_pct <- function(x, group, event = 1L, group_levels = NULL) {
  keep <- !is.na(group)
  x <- x[keep]
  group <- group[keep]
  if (is.null(group_levels)) group_levels <- unique(as.character(group))
  out <- setNames(rep("", length(group_levels)), group_levels)
  for (lvl in group_levels) {
    xg <- x[as.character(group) == lvl]
    xg <- xg[!is.na(xg)]
    denom <- length(xg)
    if (denom == 0L) next
    num <- sum(xg == event, na.rm = TRUE)
    out[[lvl]] <- paste0(num, "(", round(100 * num / denom), ")")
  }
  out
}

fun_pvalue_cont <- function(x, group) {
  keep <- !is.na(x) & !is.na(group)
  x <- x[keep]
  group <- as.factor(group[keep])
  if (length(levels(group)) != 2L) return(NA_real_)
  if (any(table(group) < 2L)) return(NA_real_)
  tryCatch(stats::t.test(x ~ group)$p.value, error = function(e) NA_real_)
}

fun_pvalue_cat <- function(x, group) {
  keep <- !is.na(x) & !is.na(group)
  x <- x[keep]
  group <- as.factor(group[keep])
  if (length(levels(group)) != 2L || length(unique(x)) < 2L) return(NA_real_)
  tbl <- table(x, group)
  if (nrow(tbl) < 2L || ncol(tbl) != 2L) return(NA_real_)
  tryCatch(suppressWarnings(stats::fisher.test(tbl)$p.value), error = function(e) {
    tryCatch(suppressWarnings(stats::chisq.test(tbl)$p.value), error = function(e2) NA_real_)
  })
}

fun_pvalue_cat_level <- function(factor_var, group, level_value) {
  ind <- ifelse(is.na(factor_var), NA_integer_, ifelse(as.character(factor_var) == level_value, 1L, 0L))
  fun_pvalue_cat(ind, group)
}

make_binary_row <- function(data, var_name, row_label, group_var, group_levels, event = 1L, cols = c("Variable", "Group0", "Group1", "P_value")) {
  x <- data[[var_name]]
  g <- data[[group_var]]
  vals <- format_n_pct(x, g, event = event, group_levels = group_levels)
  out <- tibble(
    Variable = row_label,
    Group0 = unname(vals[[group_levels[[1]]]]),
    Group1 = unname(vals[[group_levels[[2]]]]),
    P_value = format_pvalue(fun_pvalue_cat(x, g))
  )
  names(out) <- cols
  out
}

make_cont_row <- function(data, var_name, row_label, group_var, group_levels, digits = 1, cols = c("Variable", "Group0", "Group1", "P_value")) {
  x <- data[[var_name]]
  g <- data[[group_var]]
  vals <- format_mean_sd(x, g, group_levels = group_levels, digits = digits)
  out <- tibble(
    Variable = row_label,
    Group0 = unname(vals[[group_levels[[1]]]]),
    Group1 = unname(vals[[group_levels[[2]]]]),
    P_value = format_pvalue(fun_pvalue_cont(x, g))
  )
  names(out) <- cols
  out
}

make_multicat_rows_with_level_p <- function(data, var_name, header_label, group_var, group_levels, cols = c("Variable", "Group0", "Group1", "P_value")) {
  f <- data[[var_name]]
  g <- data[[group_var]]
  lvls <- levels(f)
  header_vals <- format_n_pct(ifelse(is.na(f), NA_integer_, 1L), g, event = 1L, group_levels = group_levels)
  header <- tibble(
    Variable = header_label,
    Group0 = unname(header_vals[[group_levels[[1]]]]),
    Group1 = unname(header_vals[[group_levels[[2]]]]),
    P_value = format_pvalue(fun_pvalue_cat(f, g))
  )
  level_rows <- lapply(lvls, function(lvl) {
    vals <- format_n_pct(ifelse(as.character(f) == lvl, 1L, 0L), g, event = 1L, group_levels = group_levels)
    tibble(
      Variable = paste0("  ", lvl),
      Group0 = unname(vals[[group_levels[[1]]]]),
      Group1 = unname(vals[[group_levels[[2]]]]),
      P_value = format_pvalue(fun_pvalue_cat_level(f, g, lvl))
    )
  })
  out <- bind_rows(header, bind_rows(level_rows))
  names(out) <- cols
  out
}

derive_k50_cohorts <- function(input_df, shape, outcome = "locomotor_capacity") {
  dedup_prep <- prepare_k50_person_dedup(input_df, shape, outcome)
  dedup_input <- dedup_prep$data
  analysis_person_df <- dedup_prep$analysis_df

  if (shape == "LONG") {
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
        fi22_complete = all(!is.na(FI22_nonperformance_KAAOS)),
        .groups = "drop"
      ) %>%
      mutate(
        fof_valid = fof_values %in% c("0", "1"),
        fof_value = if_else(fof_valid, fof_values, NA_character_)
      )

    baseline_df <- dedup_input %>%
      mutate(
        id = trimws(as.character(.data$id)),
        time = normalize_time(.data$time),
        FOF_status = normalize_fof(.data$FOF_status),
        age = safe_num(.data$age),
        sex = normalize_sex_chr(.data$sex),
        BMI = safe_num(.data$BMI),
        tasapainovaikeus = normalize_binary(.data$tasapainovaikeus),
        locomotor_capacity_baseline = safe_num(.data$locomotor_capacity),
        FI22_nonperformance_KAAOS = safe_num(.data$FI22_nonperformance_KAAOS)
      ) %>%
      filter(time == 0L) %>%
      select(id, FOF_status, age, sex, BMI, tasapainovaikeus, locomotor_capacity_baseline, FI22_nonperformance_KAAOS) %>%
      left_join(
        analysis_person_df %>%
          filter(time == 0L) %>%
          transmute(id = as.character(id), person_key = as.character(person_key)) %>%
          distinct(),
        by = "id"
      )

    dup_n <- baseline_df %>% count(id, name = "n") %>% filter(n > 1L) %>% nrow()
    if (dup_n > 0L) stop("K51 LONG baseline extraction found duplicate baseline rows per id after dedup.", call. = FALSE)
  } else {
    id_gate_df <- analysis_person_df %>%
      group_by(person_key) %>%
      summarise(
        canonical_id = sort(unique(stats::na.omit(id)))[1],
        fof_values = paste(sort(unique(stats::na.omit(as.character(FOF_status)))), collapse = ";"),
        branch_eligible = n() == 1L,
        outcome_complete = all(!is.na(outcome_0)) && all(!is.na(outcome_12m)),
        age_complete = all(!is.na(age)),
        sex_complete = all(!is.na(sex)),
        bmi_complete = all(!is.na(BMI)),
        fi22_complete = all(!is.na(FI22_nonperformance_KAAOS)),
        .groups = "drop"
      ) %>%
      mutate(
        fof_valid = fof_values %in% c("0", "1"),
        fof_value = if_else(fof_valid, fof_values, NA_character_)
      )

    baseline_df <- dedup_input %>%
      mutate(
        id = trimws(as.character(.data$id)),
        FOF_status = normalize_fof(.data$FOF_status),
        age = safe_num(.data$age),
        sex = normalize_sex_chr(.data$sex),
        BMI = safe_num(.data$BMI),
        tasapainovaikeus = normalize_binary(.data$tasapainovaikeus),
        locomotor_capacity_baseline = safe_num(.data$locomotor_capacity_0),
        FI22_nonperformance_KAAOS = safe_num(.data$FI22_nonperformance_KAAOS)
      ) %>%
      select(id, FOF_status, age, sex, BMI, tasapainovaikeus, locomotor_capacity_baseline, FI22_nonperformance_KAAOS) %>%
      left_join(
        analysis_person_df %>%
          transmute(id = as.character(id), person_key = as.character(person_key)) %>%
          distinct(),
        by = "id"
      )

    dup_n <- baseline_df %>% count(id, name = "n") %>% filter(n > 1L) %>% nrow()
    if (dup_n > 0L) stop("K51 WIDE baseline extraction found duplicate rows per id after dedup.", call. = FALSE)
  }

  branch_df <- id_gate_df %>% filter(fof_valid, branch_eligible)
  outcome_df <- branch_df %>% filter(outcome_complete)
  analytic_df <- outcome_df %>% filter(age_complete, sex_complete, bmi_complete)
  modeled_wide_df <- if (shape == "WIDE") {
    dedup_input %>%
      transmute(
        canonical_id = normalize_id(.data$id),
        FOF_status = normalize_fof(.data$FOF_status),
        age = safe_num(.data$age),
        sex = normalize_sex_chr(.data$sex),
        BMI = safe_num(.data$BMI),
        locomotor_capacity_0 = safe_num(.data$locomotor_capacity_0),
        locomotor_capacity_12m = safe_num(.data$locomotor_capacity_12m),
        FI22_nonperformance_KAAOS = safe_num(.data$FI22_nonperformance_KAAOS)
      ) %>%
      filter(
        !is.na(canonical_id),
        !is.na(FOF_status),
        !is.na(age),
        !is.na(sex),
        !is.na(BMI),
        !is.na(locomotor_capacity_0),
        !is.na(locomotor_capacity_12m),
        !is.na(FI22_nonperformance_KAAOS)
      ) %>%
      distinct(canonical_id, .keep_all = TRUE)
  } else {
    analytic_df[0, , drop = FALSE]
  }

  baseline_df <- baseline_df %>%
    mutate(
      analytic_flag = as.integer(id %in% analytic_df$canonical_id),
      baseline_eligible_flag = as.integer(id %in% branch_df$canonical_id),
      analytic_wide_modeled_flag = as.integer(id %in% modeled_wide_df$canonical_id)
    ) %>%
    filter(baseline_eligible_flag == 1L)

  list(
    baseline_df = baseline_df,
    analytic_ids = analytic_df$canonical_id,
    baseline_eligible_ids = branch_df$canonical_id,
    analytic_wide_modeled_ids = modeled_wide_df$canonical_id,
    counts = list(
      baseline_eligible_n = nrow(baseline_df),
      analytic_n = sum(baseline_df$analytic_flag == 1L, na.rm = TRUE),
      not_analytic_n = sum(baseline_df$analytic_flag == 0L, na.rm = TRUE),
      analytic_wide_modeled_n = sum(baseline_df$analytic_wide_modeled_flag == 1L, na.rm = TRUE)
    )
  )
}

load_k14_enrichment_baseline <- function(raw_path) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("K51 baseline enrichment requires the readxl package.", call. = FALSE)
  }

  raw_data <- tibble::as_tibble(readxl::read_excel(raw_path, sheet = "Taul1", skip = 1, n_max = Inf))
  nm <- names(raw_data)
  col_nro <- pick_col_regex_first(nm, "NRO", c("^nro$"))
  col_visit_date <- pick_col_regex_optional(nm, c("kaaosvastaanottokayntipvm", "^kaaosvastaanottokaynti$"))
  col_id <- pick_col_regex_optional(nm, c("^potilastunnus$", "^id$"))
  col_fof <- pick_col_regex_first(nm, "FOF", c("^kaatumisenpelko0eipelk"))
  col_sex <- pick_col_regex_first(nm, "sex", c("^sukupuoli0nainen1mies$"))
  col_diabetes <- pick_col_regex_first(nm, "diabetes", c("^diabetes0ei1kyll"))
  col_alzheimer <- pick_col_regex_first(nm, "alzheimer", c("^alzheimer0ei1kyll"))
  col_parkinson <- pick_col_regex_first(nm, "parkinson", c("^parkinson0ei1kyll"))
  col_avh <- pick_col_regex_first(nm, "AVH", c("^avh0ei1kyll"))
  col_srh <- pick_col_regex_first(nm, "SRH", c("^koettuterveydentila"))
  col_moi <- pick_col_regex_first(nm, "MOI", c("^moiindeksi"))
  col_bmi <- pick_col_regex_first(nm, "BMI", c("^bmikgm2e1eitietoa$"))
  col_smoking <- pick_col_regex_first(nm, "tupakointi", c("^tupakointi0eipolta1polttaa"))
  col_alcohol <- pick_col_regex_first(nm, "alkoholi", c("^alkoholi0ei1maltillinen"))
  col_srm <- pick_col_regex_first(nm, "oma_arvio_liikuntakyky", c("^omaarvioliikuntakyvyst"))
  col_walk500 <- pick_col_regex_first(nm, "vaikeus_liikkua_500m", c("^500mvaikeusliikkua0eivaikeuksia1vaikeuksia"))
  col_balance <- pick_col_regex_first(nm, "tasapainovaikeus", c("^tasapainovaikeudet0ei1kyll"))
  col_fall <- pick_col_regex_first(nm, "kaatuminen", c("^kaatuminen0ei1kyll"))
  col_fracture <- pick_col_regex_first(nm, "murtumia", c("^murtumia0ei1kyll"))
  col_pain <- pick_col_regex_first(nm, "PainVAS0", c("^tkvas"))

  raw_dedup <- raw_data %>%
    transmute(
      NRO = normalize_id(.data[[col_nro]]),
      visit_date = if (!is.na(col_visit_date)) as.Date(.data[[col_visit_date]]) else as.Date(NA),
      id = if (!is.na(col_id)) normalize_id(.data[[col_id]]) else normalize_id(.data[[col_nro]]),
      FOF_status = normalize_fof(.data[[col_fof]]),
      sex = .data[[col_sex]],
      diabetes = .data[[col_diabetes]],
      alzheimer = .data[[col_alzheimer]],
      parkinson = .data[[col_parkinson]],
      AVH = .data[[col_avh]],
      koettuterveydentila = .data[[col_srh]],
      MOIindeksiindeksi = .data[[col_moi]],
      BMI = .data[[col_bmi]],
      tupakointi = .data[[col_smoking]],
      alkoholi = .data[[col_alcohol]],
      oma_arvio_liikuntakyky = .data[[col_srm]],
      vaikeus_liikkua_500m = .data[[col_walk500]],
      tasapainovaikeus = .data[[col_balance]],
      kaatuminen = .data[[col_fall]],
      murtumia = .data[[col_fracture]],
      PainVAS0 = .data[[col_pain]]
    ) %>%
    filter(!is.na(NRO)) %>%
    arrange(NRO, visit_date) %>%
    group_by(NRO) %>%
    slice(1L) %>%
    ungroup()

  lookup_info <- read_ssn_lookup(resolve_ssn_lookup_path(), names(raw_dedup))
  raw_stage <- raw_dedup %>%
    transmute(
      id = trimws(as.character(.data$id)),
      workbook_nro = normalize_id(.data$NRO),
      bridge_value = normalize_join_key(.data[[lookup_info$bridge_col]]),
      FOF_status = .data$FOF_status,
      sex = .data$sex,
      diabetes = .data$diabetes,
      alzheimer = .data$alzheimer,
      parkinson = .data$parkinson,
      AVH = .data$AVH,
      koettuterveydentila = .data$koettuterveydentila,
      MOIindeksiindeksi = .data$MOIindeksiindeksi,
      BMI = .data$BMI,
      tupakointi = .data$tupakointi,
      alkoholi = .data$alkoholi,
      oma_arvio_liikuntakyky = .data$oma_arvio_liikuntakyky,
      vaikeus_liikkua_500m = .data$vaikeus_liikkua_500m,
      tasapainovaikeus = .data$tasapainovaikeus,
      kaatuminen = .data$kaatuminen,
      murtumia = .data$murtumia,
      PainVAS0 = .data$PainVAS0
    )
  raw_attached <- attach_person_key(raw_stage, lookup_info)$data
  raw_dedup <- dedup_person_records_wide(
    raw_attached,
    id_col = "id",
    fof_col = "FOF_status",
    value_cols = c("PainVAS0", "MOIindeksiindeksi"),
    covariate_cols = c("BMI", "sex"),
    compare_cols = c(
      "FOF_status", "sex", "BMI", "diabetes", "alzheimer", "parkinson", "AVH",
      "koettuterveydentila", "MOIindeksiindeksi", "tupakointi", "alkoholi",
      "oma_arvio_liikuntakyky", "vaikeus_liikkua_500m", "tasapainovaikeus",
      "kaatuminen", "murtumia", "PainVAS0"
    )
  )

  raw_base <- raw_dedup$data %>%
    transmute(
      id = trimws(as.character(.data$id)),
      person_key = as.character(.data$person_key),
      workbook_nro = normalize_id(.data$workbook_nro),
      sex = factor(case_when(
        safe_num(.data$sex) == 0 ~ "female",
        safe_num(.data$sex) == 1 ~ "male",
        TRUE ~ NA_character_
      ), levels = c("female", "male")),
      woman = case_when(
        sex == "female" ~ 1L,
        sex == "male" ~ 0L,
        TRUE ~ NA_integer_
      ),
      diabetes = normalize_binary(.data$diabetes),
      alzheimer = normalize_binary(.data$alzheimer),
      parkinson = normalize_binary(.data$parkinson),
      AVH = normalize_binary(.data$AVH),
      koettuterveydentila = safe_num(.data$koettuterveydentila),
      MOIindeksiindeksi = safe_num(.data$MOIindeksiindeksi),
      BMI = safe_num(.data$BMI),
      tupakointi = normalize_binary(.data$tupakointi),
      alkoholi = safe_num(.data$alkoholi),
      oma_arvio_liikuntakyky = safe_num(.data$oma_arvio_liikuntakyky),
      vaikeus_liikkua_500m = safe_num(.data$vaikeus_liikkua_500m),
      tasapainovaikeus = normalize_binary(.data$tasapainovaikeus),
      kaatuminen = normalize_binary(.data$kaatuminen),
      murtumia = normalize_binary(.data$murtumia),
      PainVAS0 = safe_num(.data$PainVAS0)
    ) %>%
    mutate(
      SRH_3class_table = factor(koettuterveydentila, levels = c(2, 1, 0), labels = c("Good", "Moderate", "Bad"), ordered = TRUE),
      SRM_3class_table = factor(oma_arvio_liikuntakyky, levels = c(2, 1, 0), labels = c("Good", "Moderate", "Weak"), ordered = TRUE),
      Walk500m_3class_table = factor(vaikeus_liikkua_500m, levels = c(0, 1, 2), labels = c("No", "Difficulties", "Cannot"), ordered = TRUE),
      alcohol_3class_table = factor(alkoholi, levels = c(0, 1, 2), labels = c("No", "Moderate", "Large"), ordered = TRUE)
    ) %>%
    mutate(
      disease_count = rowSums(cbind(diabetes == 1, alzheimer == 1, parkinson == 1, AVH == 1), na.rm = TRUE),
      disease_nonmiss = rowSums(cbind(!is.na(diabetes), !is.na(alzheimer), !is.na(parkinson), !is.na(AVH)), na.rm = TRUE),
      comorbidity = case_when(
        disease_nonmiss == 0 ~ NA_integer_,
        disease_count > 1 ~ 1L,
        TRUE ~ 0L
      )
    )

  dup_n <- raw_base %>% count(person_key, name = "n") %>% filter(!is.na(person_key), n > 1L) %>% nrow()
  if (dup_n > 0L) stop("K51 raw enrichment source has duplicate person keys; refusing ambiguous raw-backed join.", call. = FALSE)
  raw_base
}

load_k14_override_rows <- function(raw_path, override_map_path) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("K51 baseline enrichment override requires the readxl package.", call. = FALSE)
  }

  override_map <- readr::read_csv(override_map_path, show_col_types = FALSE) %>%
    transmute(
      id = normalize_id(.data$canonical_id),
      workbook_nro = normalize_id(.data$workbook_nro)
    )

  raw_data <- tibble::as_tibble(readxl::read_excel(raw_path, sheet = "Taul1", skip = 1, n_max = Inf))
  nm <- names(raw_data)
  col_nro <- pick_col_regex_first(nm, "NRO", c("^nro$"))
  col_sex <- pick_col_regex_first(nm, "sex", c("^sukupuoli0nainen1mies$"))
  col_diabetes <- pick_col_regex_first(nm, "diabetes", c("^diabetes0ei1kyll"))
  col_alzheimer <- pick_col_regex_first(nm, "alzheimer", c("^alzheimer0ei1kyll"))
  col_parkinson <- pick_col_regex_first(nm, "parkinson", c("^parkinson0ei1kyll"))
  col_avh <- pick_col_regex_first(nm, "AVH", c("^avh0ei1kyll"))
  col_srh <- pick_col_regex_first(nm, "SRH", c("^koettuterveydentila"))
  col_moi <- pick_col_regex_first(nm, "MOI", c("^moiindeksi"))
  col_bmi <- pick_col_regex_first(nm, "BMI", c("^bmikgm2e1eitietoa$"))
  col_smoking <- pick_col_regex_first(nm, "tupakointi", c("^tupakointi0eipolta1polttaa"))
  col_alcohol <- pick_col_regex_first(nm, "alkoholi", c("^alkoholi0ei1maltillinen"))
  col_srm <- pick_col_regex_first(nm, "oma_arvio_liikuntakyky", c("^omaarvioliikuntakyvyst"))
  col_walk500 <- pick_col_regex_first(nm, "vaikeus_liikkua_500m", c("^500mvaikeusliikkua0eivaikeuksia1vaikeuksia"))
  col_balance <- pick_col_regex_first(nm, "tasapainovaikeus", c("^tasapainovaikeudet0ei1kyll"))
  col_fall <- pick_col_regex_first(nm, "kaatuminen", c("^kaatuminen0ei1kyll"))
  col_fracture <- pick_col_regex_first(nm, "murtumia", c("^murtumia0ei1kyll"))
  col_pain <- pick_col_regex_first(nm, "PainVAS0", c("^tkvas"))

  raw_base <- raw_data %>%
    transmute(
      workbook_nro = normalize_id(.data[[col_nro]]),
      sex = factor(case_when(
        safe_num(.data[[col_sex]]) == 0 ~ "female",
        safe_num(.data[[col_sex]]) == 1 ~ "male",
        TRUE ~ NA_character_
      ), levels = c("female", "male")),
      woman = case_when(
        sex == "female" ~ 1L,
        sex == "male" ~ 0L,
        TRUE ~ NA_integer_
      ),
      diabetes = normalize_binary(.data[[col_diabetes]]),
      alzheimer = normalize_binary(.data[[col_alzheimer]]),
      parkinson = normalize_binary(.data[[col_parkinson]]),
      AVH = normalize_binary(.data[[col_avh]]),
      koettuterveydentila = safe_num(.data[[col_srh]]),
      MOIindeksiindeksi = safe_num(.data[[col_moi]]),
      BMI = safe_num(.data[[col_bmi]]),
      tupakointi = normalize_binary(.data[[col_smoking]]),
      alkoholi = safe_num(.data[[col_alcohol]]),
      oma_arvio_liikuntakyky = safe_num(.data[[col_srm]]),
      vaikeus_liikkua_500m = safe_num(.data[[col_walk500]]),
      tasapainovaikeus = normalize_binary(.data[[col_balance]]),
      kaatuminen = normalize_binary(.data[[col_fall]]),
      murtumia = normalize_binary(.data[[col_fracture]]),
      PainVAS0 = safe_num(.data[[col_pain]])
    ) %>%
    filter(!is.na(workbook_nro)) %>%
    left_join(override_map, by = "workbook_nro") %>%
    filter(!is.na(id)) %>%
    transmute(
      id = id,
      person_key = NA_character_,
      workbook_nro = workbook_nro,
      sex = sex,
      woman = woman,
      diabetes = diabetes,
      alzheimer = alzheimer,
      parkinson = parkinson,
      AVH = AVH,
      koettuterveydentila = koettuterveydentila,
      MOIindeksiindeksi = MOIindeksiindeksi,
      BMI = BMI,
      tupakointi = tupakointi,
      alkoholi = alkoholi,
      oma_arvio_liikuntakyky = oma_arvio_liikuntakyky,
      vaikeus_liikkua_500m = vaikeus_liikkua_500m,
      tasapainovaikeus = tasapainovaikeus,
      kaatuminen = kaatuminen,
      murtumia = murtumia,
      PainVAS0 = PainVAS0
    ) %>%
    mutate(
      SRH_3class_table = factor(koettuterveydentila, levels = c(2, 1, 0), labels = c("Good", "Moderate", "Bad"), ordered = TRUE),
      SRM_3class_table = factor(oma_arvio_liikuntakyky, levels = c(2, 1, 0), labels = c("Good", "Moderate", "Weak"), ordered = TRUE),
      Walk500m_3class_table = factor(vaikeus_liikkua_500m, levels = c(0, 1, 2), labels = c("No", "Difficulties", "Cannot"), ordered = TRUE),
      alcohol_3class_table = factor(alkoholi, levels = c(0, 1, 2), labels = c("No", "Moderate", "Large"), ordered = TRUE)
    ) %>%
    mutate(
      disease_count = rowSums(cbind(diabetes == 1, alzheimer == 1, parkinson == 1, AVH == 1), na.rm = TRUE),
      disease_nonmiss = rowSums(cbind(!is.na(diabetes), !is.na(alzheimer), !is.na(parkinson), !is.na(AVH)), na.rm = TRUE),
      comorbidity = case_when(
        disease_nonmiss == 0 ~ NA_integer_,
        disease_count > 1 ~ 1L,
        TRUE ~ 0L
      )
    ) %>%
    distinct(id, .keep_all = TRUE)

  if (nrow(raw_base) != nrow(override_map)) {
    stop("K51 override rows could not be resolved uniquely from the workbook.", call. = FALSE)
  }
  raw_base
}

build_row_registry <- function(profile) {
  base_rows_minimal <- tribble(
    ~row_label, ~source_var, ~source_type,
    "Women, n (%)", "woman", "canonical_direct",
    "Age, years", "age", "canonical_direct",
    "Body Mass Index, mean (SD)", "BMI", "canonical_direct",
    "Balance difficulties, n (%)", "tasapainovaikeus", "canonical_direct",
    "Locomotor capacity at baseline, mean (SD)", "locomotor_capacity_baseline", "canonical_direct",
    "Frailty Index (FI), mean (SD)", "FI22_nonperformance_KAAOS", "canonical_direct"
  )
  if (profile == "minimal") return(base_rows_minimal)

  bind_rows(
    tribble(
      ~row_label, ~source_var, ~source_type,
      "Women, n (%)", "woman", "canonical_direct",
      "Age, mean (SD)", "age", "canonical_direct",
      "Diseases, n (%)", "disease_any", "raw_backed",
      "  Diabetes", "diabetes", "raw_backed",
      "  Dementia", "alzheimer", "raw_backed",
      "  Parkinson's", "parkinson", "raw_backed",
      "  Cerebrovascular Accidents", "AVH", "raw_backed",
      "  Comorbidity (>1 disease)", "comorbidity", "raw_backed",
      "Self-rated Health, n (%)", "SRH_3class_table", "raw_backed",
      "  Good", "SRH_3class_table", "raw_backed",
      "  Moderate", "SRH_3class_table", "raw_backed",
      "  Bad", "SRH_3class_table", "raw_backed",
      "Mikkeli Osteoporosis Index, mean (SD)", "MOIindeksiindeksi", "raw_backed",
      "Body Mass Index, mean (SD)", "BMI", "canonical_direct",
      "Smoked, n (%)", "tupakointi", "raw_backed",
      "Alcohol, n (%)", "alcohol_3class_table", "raw_backed",
      "  No", "alcohol_3class_table", "raw_backed",
      "  Moderate", "alcohol_3class_table", "raw_backed",
      "  Large", "alcohol_3class_table", "raw_backed",
      "Self-Rated Mobility, n (%)", "SRM_3class_table", "raw_backed",
      "  Good", "SRM_3class_table", "raw_backed",
      "  Moderate", "SRM_3class_table", "raw_backed",
      "  Weak", "SRM_3class_table", "raw_backed",
      "Walking 500 m, n (%)", "Walk500m_3class_table", "raw_backed",
      "  No", "Walk500m_3class_table", "raw_backed",
      "  Difficulties", "Walk500m_3class_table", "raw_backed",
      "  Cannot", "Walk500m_3class_table", "raw_backed",
      "Body Mass Index, mean (SD)", "BMI", "canonical_direct",
      "Balance difficulties, n (%)", "tasapainovaikeus", "canonical_direct",
      "Fallen, n (%)", "kaatuminen", "raw_backed",
      "Fractures, n (%)", "murtumia", "raw_backed",
      "Pain (Visual Analog Scale), mm, mean (SD)", "PainVAS0", "raw_backed",
      "Locomotor capacity at baseline, mean (SD)", "locomotor_capacity_baseline", "canonical_direct",
      "Frailty Index (FI), mean (SD)", "FI22_nonperformance_KAAOS", "canonical_direct"
    )
  ) %>% distinct()
}

get_k14_reference_rows <- function() {
  ref_path <- here::here("R-scripts", "K14", "outputs", "K14_baseline_by_FOF.csv")
  if (!file.exists(ref_path)) return(character())
  ref_tbl <- suppressMessages(readr::read_csv(ref_path, show_col_types = FALSE))
  first_col <- names(ref_tbl)[1]
  trimws(as.character(ref_tbl[[first_col]]))
}

build_minimal_table <- function(df, group_var, group_levels, labels) {
  bind_rows(
    make_cont_row(df, "age", "Age, years", group_var, group_levels, digits = 1, cols = c("Characteristic", "Group0", "Group1", "P_value")),
    make_binary_row(df, "woman", "Women, n (%)", group_var, group_levels, event = 1L, cols = c("Characteristic", "Group0", "Group1", "P_value")),
    make_cont_row(df, "BMI", "BMI, kg/m2", group_var, group_levels, digits = 1, cols = c("Characteristic", "Group0", "Group1", "P_value")),
    make_binary_row(df, "tasapainovaikeus", "Balance difficulties, n (%)", group_var, group_levels, event = 1L, cols = c("Characteristic", "Group0", "Group1", "P_value")),
    make_cont_row(df, "locomotor_capacity_baseline", "Locomotor capacity at baseline, mean (SD)", group_var, group_levels, digits = 2, cols = c("Characteristic", "Group0", "Group1", "P_value")),
    make_cont_row(df, "FI22_nonperformance_KAAOS", "Frailty Index (FI), mean (SD)", group_var, group_levels, digits = 2, cols = c("Characteristic", "Group0", "Group1", "P_value"))
  ) %>%
    setNames(c("Characteristic", labels[[1]], labels[[2]], "P_value"))
}

build_k14_extended_table <- function(df, group_var, group_levels, labels, include_raw = TRUE) {
  if (isTRUE(include_raw)) {
    disease_any <- ifelse(
      rowSums(cbind(df$diabetes == 1, df$alzheimer == 1, df$parkinson == 1, df$AVH == 1), na.rm = TRUE) > 0,
      1L,
      0L
    )
    df <- df %>% mutate(disease_any = disease_any)
  }

  rows <- list(
    make_binary_row(df, "woman", "Women, n (%)", group_var, group_levels),
    make_cont_row(df, "age", "Age, mean (SD)", group_var, group_levels, digits = 0)
  )

  if (isTRUE(include_raw)) {
    rows <- c(rows, list(
      bind_rows(
        make_binary_row(df, "disease_any", "Diseases, n (%)", group_var, group_levels),
        make_binary_row(df, "diabetes", "  Diabetes", group_var, group_levels),
        make_binary_row(df, "alzheimer", "  Dementia", group_var, group_levels),
        make_binary_row(df, "parkinson", "  Parkinson's", group_var, group_levels),
        make_binary_row(df, "AVH", "  Cerebrovascular Accidents", group_var, group_levels),
        make_binary_row(df, "comorbidity", "  Comorbidity (>1 disease)", group_var, group_levels)
      ),
      make_multicat_rows_with_level_p(df, "SRH_3class_table", "Self-rated Health, n (%)", group_var, group_levels),
      make_cont_row(df, "MOIindeksiindeksi", "Mikkeli Osteoporosis Index, mean (SD)", group_var, group_levels, digits = 1),
      make_binary_row(df, "tupakointi", "Smoked, n (%)", group_var, group_levels),
      make_multicat_rows_with_level_p(df, "alcohol_3class_table", "Alcohol, n (%)", group_var, group_levels),
      make_multicat_rows_with_level_p(df, "SRM_3class_table", "Self-Rated Mobility, n (%)", group_var, group_levels),
      make_multicat_rows_with_level_p(df, "Walk500m_3class_table", "Walking 500 m, n (%)", group_var, group_levels),
      make_binary_row(df, "kaatuminen", "Fallen, n (%)", group_var, group_levels),
      make_binary_row(df, "murtumia", "Fractures, n (%)", group_var, group_levels),
      make_cont_row(df, "PainVAS0", "Pain (Visual Analog Scale), mm, mean (SD)", group_var, group_levels, digits = 1)
    ))
  }

  rows <- c(rows, list(
    make_cont_row(df, "BMI", "Body Mass Index, mean (SD)", group_var, group_levels, digits = 1),
    make_binary_row(df, "tasapainovaikeus", "Balance difficulties, n (%)", group_var, group_levels),
    make_cont_row(df, "locomotor_capacity_baseline", "Locomotor capacity at baseline, mean (SD)", group_var, group_levels, digits = 2),
    make_cont_row(df, "FI22_nonperformance_KAAOS", "Frailty Index (FI), mean (SD)", group_var, group_levels, digits = 2)
  ))

  table_raw <- bind_rows(rows)
  names(table_raw) <- c("Variable", labels[[1]], labels[[2]], "P-value")
  table_raw
}

shape <- parse_shape(get_arg("--shape"))
cohort_scope <- parse_scope(get_arg("--cohort-scope", "baseline_eligible"))
table_profile <- parse_profile(get_arg("--table-profile", "minimal"))
data_path <- resolve_input_path(shape, get_arg("--data"))
raw_data_path <- if (is_extended_profile(table_profile)) resolve_raw_input_path(get_arg("--raw-data")) else NA_character_

input_df <- read_dataset(data_path)
cohorts <- derive_k50_cohorts(input_df, shape, outcome = "locomotor_capacity")
baseline_df <- cohorts$baseline_df

baseline_df <- baseline_df %>%
  mutate(
    sex = factor(tolower(sex), levels = c("female", "male")),
    woman = case_when(
      sex == "female" ~ 1L,
      sex == "male" ~ 0L,
      TRUE ~ NA_integer_
    )
  )

registry <- build_row_registry(if (is_extended_profile(table_profile)) "k14_extended" else table_profile)
drop_registry <- tibble(row_label = character(), source_var = character(), source_type = character())
k14_ref_rows <- get_k14_reference_rows()
raw_enrichment_status <- "not_requested"

if (is_extended_profile(table_profile)) {
  enrich_df <- load_k14_enrichment_baseline(raw_data_path)
  override_df <- load_k14_override_rows(raw_data_path, resolve_override_map_path())
  enrich_value_cols <- setdiff(names(enrich_df), c("id", "person_key", "workbook_nro"))
  enrich_by_person <- enrich_df %>% select(-id, -workbook_nro)
  enrich_by_id <- enrich_df %>%
    select(-person_key, -workbook_nro) %>%
    rename_with(~ paste0(.x, "_by_id"), -id)
  override_by_id <- override_df %>%
    select(-person_key, -workbook_nro) %>%
    rename_with(~ paste0(.x, "_by_override"), -id)

  candidate_df <- baseline_df %>%
    select(-sex, -BMI, -tasapainovaikeus) %>%
    left_join(enrich_by_person, by = "person_key") %>%
    left_join(enrich_by_id, by = "id") %>%
    left_join(override_by_id, by = "id")

  for (col in enrich_value_cols) {
    by_id_col <- paste0(col, "_by_id")
    by_override_col <- paste0(col, "_by_override")
    candidate_df[[col]] <- dplyr::coalesce(candidate_df[[col]], candidate_df[[by_id_col]], candidate_df[[by_override_col]])
  }

  candidate_df <- candidate_df %>% select(-ends_with("_by_id"), -ends_with("_by_override"))

  missing_enrichment_ids <- sum(rowSums(!is.na(as.data.frame(candidate_df[, enrich_value_cols, drop = FALSE]))) == 0L)
  missing_rows <- candidate_df %>%
    filter(rowSums(!is.na(as.data.frame(candidate_df[, enrich_value_cols, drop = FALSE]))) == 0L) %>%
    transmute(
      id = normalize_id(id),
      person_key = as.character(person_key),
      ssn_key = dplyr::if_else(grepl("^ssn:", person_key), sub("^ssn:", "", person_key), NA_character_),
      FOF_status = as.character(FOF_status)
    )

  if (nrow(missing_rows) > 0L) {
    data_root <- resolve_data_root()
    kaaos_sotullinen_probe <- read_bridge_probe(raw_data_path, sheet = "Taul1", skip = 1)
    kaaos_data_probe <- read_bridge_probe(file.path(data_root, "paper_02", "KAAOS_data.xlsx"), sheet = "Taul1", skip = 1)
    sotut_probe <- read_bridge_probe(file.path(data_root, "paper_02", "sotut.xlsx"), sheet = "Taul1", skip = 0)

    missing_debug <- missing_rows %>%
      left_join(
        kaaos_sotullinen_probe %>%
          transmute(id = probe_id, kaaos_sotullinen_nro = probe_nro, in_kaaos_sotullinen_by_id = !is.na(probe_nro)),
        by = "id"
      ) %>%
      left_join(
        kaaos_data_probe %>%
          transmute(id = probe_id, kaaos_data_nro = probe_nro, in_kaaos_data_by_id = !is.na(probe_nro)),
        by = "id"
      ) %>%
      left_join(
        sotut_probe %>%
          transmute(id = probe_id, sotut_nro_by_id = probe_nro, in_sotut_by_id = !is.na(probe_nro)),
        by = "id"
      ) %>%
      left_join(
        sotut_probe %>%
          transmute(ssn_key = probe_sotu, sotut_nro_by_ssn = probe_nro, in_sotut_by_ssn = !is.na(probe_nro)),
        by = "ssn_key"
      ) %>%
      mutate(
        resolution_hint = case_when(
          coalesce(in_kaaos_sotullinen_by_id, FALSE) ~ "present_in_kaaos_data_sotullinen_by_id",
          coalesce(in_kaaos_data_by_id, FALSE) ~ "present_in_kaaos_data_by_id_only",
          coalesce(in_sotut_by_id, FALSE) ~ "present_in_sotut_by_id_only",
          coalesce(in_sotut_by_ssn, FALSE) ~ "present_in_sotut_by_ssn_only",
          TRUE ~ "not_found_in_bridge_probes"
        )
      )

    missing_debug_path <- write_debug_csv(
      missing_debug,
      "k51_missing_person_keys_baseline_eligible",
      "Baseline-eligible people still unresolved in KAAOS workbook linkage after deterministic baseline enrichment pass"
    )
  } else {
    missing_debug_path <- NA_character_
  }

  if (missing_enrichment_ids == 0L) {
    baseline_df <- candidate_df
    raw_enrichment_status <- "full_coverage"
  } else {
    raw_enrichment_status <- paste0("partial_coverage_missing_person_keys=", missing_enrichment_ids)
    drop_registry <- registry %>%
      filter(source_type == "raw_backed") %>%
      mutate(source_type = paste0(source_type, ":source_mismatch_with_available_raw_population"))
  }
}

if (cohort_scope == "analytic") {
  table_df <- baseline_df %>% filter(analytic_flag == 1L)
  labels <- c(
    paste0("Without FOF (n=", sum(table_df$FOF_status == 0L, na.rm = TRUE), ")"),
    paste0("With FOF (n=", sum(table_df$FOF_status == 1L, na.rm = TRUE), ")")
  )
} else if (cohort_scope == "analytic_wide_modeled") {
  table_df <- baseline_df %>% filter(analytic_wide_modeled_flag == 1L)
  labels <- c(
    paste0("Without FOF (n=", sum(table_df$FOF_status == 0L, na.rm = TRUE), ")"),
    paste0("With FOF (n=", sum(table_df$FOF_status == 1L, na.rm = TRUE), ")")
  )
} else if (cohort_scope == "baseline_eligible") {
  table_df <- baseline_df
  labels <- c(
    paste0("Without FOF (n=", sum(table_df$FOF_status == 0L, na.rm = TRUE), ")"),
    paste0("With FOF (n=", sum(table_df$FOF_status == 1L, na.rm = TRUE), ")")
  )
} else {
  table_df <- baseline_df %>% mutate(in_analytic = analytic_flag)
  labels <- c(
    paste0("Not analytic (n=", sum(table_df$in_analytic == 0L, na.rm = TRUE), ")"),
    paste0("Analytic (n=", sum(table_df$in_analytic == 1L, na.rm = TRUE), ")")
  )
}

if (table_profile == "minimal") {
  out_label <- if (cohort_scope == "analytic") {
    paste0("k51_", tolower(shape), "_baseline_table_analytic")
  } else if (cohort_scope == "analytic_wide_modeled") {
    paste0("k51_", tolower(shape), "_baseline_table_analytic_wide_modeled")
  } else if (cohort_scope == "baseline_eligible") {
    paste0("k51_", tolower(shape), "_baseline_table_baseline_eligible")
  } else {
    paste0("k51_", tolower(shape), "_selection_table_analytic_vs_not_analytic")
  }
  output_tbl <- if (cohort_scope == "selection_compare") {
    build_minimal_table(table_df, "in_analytic", c("0", "1"), labels)
  } else {
    build_minimal_table(table_df, "FOF_status", c("0", "1"), labels)
  }
} else {
  out_label <- if (cohort_scope == "analytic") {
    paste0("k51_", tolower(shape), "_baseline_table_analytic_k14_extended")
  } else if (cohort_scope == "analytic_wide_modeled") {
    paste0("k51_", tolower(shape), "_baseline_table_analytic_wide_modeled_k14_extended")
  } else if (cohort_scope == "baseline_eligible") {
    paste0("k51_", tolower(shape), "_baseline_table_baseline_eligible_k14_extended")
  } else {
    paste0("k51_", tolower(shape), "_selection_table_analytic_vs_not_analytic_k14_extended")
  }
  output_tbl <- if (cohort_scope == "selection_compare") {
    build_k14_extended_table(table_df, "in_analytic", c("0", "1"), labels, include_raw = identical(raw_enrichment_status, "full_coverage"))
  } else {
    build_k14_extended_table(table_df, "FOF_status", c("0", "1"), labels, include_raw = identical(raw_enrichment_status, "full_coverage"))
  }
}

title <- paste("K51 baseline table:", cohort_scope, table_profile)
csv_path <- write_table_csv(output_tbl, out_label, paste0("K51 table output for cohort scope ", cohort_scope, " and profile ", table_profile))
html_path <- write_table_html(output_tbl, out_label, title, paste0("K51 HTML table output for cohort scope ", cohort_scope, " and profile ", table_profile))

scope_suffix <- paste0("_", cohort_scope, if (is_extended_profile(table_profile)) "_k14_extended" else "")
decision_label <- paste0("k51_", tolower(shape), "_decision_log", scope_suffix)
decision_path <- file.path(outputs_dir, paste0(decision_label, ".txt"))

current_rows <- trimws(as.character(output_tbl[[1]]))
included_from_registry <- registry %>% filter(row_label %in% current_rows)
missing_from_registry <- registry %>% filter(!row_label %in% current_rows)
missing_vs_k14 <- if (length(k14_ref_rows) > 0L) setdiff(k14_ref_rows, current_rows) else character()
extra_vs_k14 <- if (length(k14_ref_rows) > 0L) setdiff(current_rows, k14_ref_rows) else character()

decision_lines <- c(
  "K51 baseline table run",
  paste0("input_path=", data_path),
  paste0("shape=", shape),
  paste0("cohort_scope=", cohort_scope),
  paste0("table_profile=", table_profile),
  if (!is.na(raw_data_path)) paste0("raw_enrichment_path=", raw_data_path) else "raw_enrichment_path=NA",
  paste0("raw_enrichment_status=", raw_enrichment_status),
  paste0("baseline_eligible_n=", cohorts$counts$baseline_eligible_n),
  paste0("analytic_n=", cohorts$counts$analytic_n),
  paste0("not_analytic_n=", cohorts$counts$not_analytic_n),
  paste0("analytic_wide_modeled_n=", cohorts$counts$analytic_wide_modeled_n),
  if (exists("missing_debug_path") && !is.na(missing_debug_path)) paste0("missing_person_keys_debug_path=", missing_debug_path) else "missing_person_keys_debug_path=NA",
  "K51 main Table 1 now follows the baseline-eligible cohort; analytic and analytic-vs-not-analytic outputs are supplementary comparison tables.",
  if (cohort_scope == "analytic_wide_modeled") "This run targets the manuscript-facing K50 WIDE modeled sample, not the baseline-eligible descriptive cohort." else NULL,
  "Baseline cohort is one row per id after shared person-level dedup and can differ from repeated-measures K50 model rows.",
  "K51 reuses shared person_dedup_lookup.R plus KAAOS baseline enrichment for K14-style rows instead of a parallel chooser.",
  paste0("canonical_direct_rows=", paste(included_from_registry$row_label[included_from_registry$source_type == 'canonical_direct'], collapse = " | ")),
  paste0("raw_backed_rows=", paste(included_from_registry$row_label[included_from_registry$source_type == 'raw_backed'], collapse = " | ")),
  paste0("drop_pending_verification_rows=", paste(drop_registry$row_label, collapse = " | ")),
  paste0("registry_rows_not_rendered=", paste(missing_from_registry$row_label, collapse = " | ")),
  paste0("k14_reference_rows_missing_in_current_output=", paste(missing_vs_k14, collapse = " | ")),
  paste0("current_rows_not_in_k14_reference=", paste(extra_vs_k14, collapse = " | "))
)
writeLines(decision_lines, con = decision_path)
append_manifest_safe(decision_label, "text", decision_path, n = nrow(table_df), notes = "K51 scope/profile-specific decision log")

receipt_label <- paste0("k51_", tolower(shape), "_input_receipt", scope_suffix)
receipt_path <- file.path(outputs_dir, paste0(receipt_label, ".txt"))
receipt_lines <- c(
  paste0("script=", helper_label),
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("input_path=", data_path),
  paste0("input_md5=", unname(tools::md5sum(data_path))),
  paste0("shape=", shape),
  paste0("cohort_scope=", cohort_scope),
  paste0("table_profile=", table_profile),
  if (!is.na(raw_data_path)) paste0("raw_enrichment_path=", raw_data_path) else "raw_enrichment_path=NA",
  if (!is.na(raw_data_path)) paste0("raw_enrichment_md5=", unname(tools::md5sum(raw_data_path))) else "raw_enrichment_md5=NA",
  paste0("raw_enrichment_status=", raw_enrichment_status),
  paste0("baseline_eligible_n=", cohorts$counts$baseline_eligible_n),
  paste0("analytic_n=", cohorts$counts$analytic_n),
  paste0("not_analytic_n=", cohorts$counts$not_analytic_n),
  paste0("analytic_wide_modeled_n=", cohorts$counts$analytic_wide_modeled_n),
  paste0("table_csv=", csv_path),
  paste0("table_html=", html_path)
)
writeLines(receipt_lines, con = receipt_path)
append_manifest_safe(receipt_label, "text", receipt_path, n = nrow(table_df), notes = "K51 scope/profile-specific provenance receipt")

session_label <- paste0("k51_", tolower(shape), "_sessioninfo", scope_suffix)
session_path <- file.path(outputs_dir, paste0(session_label, ".txt"))
utils::capture.output(sessionInfo(), file = session_path)
append_manifest_safe(session_label, "sessioninfo", session_path, notes = "K51 scope/profile-specific session info")
