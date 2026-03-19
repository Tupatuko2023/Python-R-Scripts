#!/usr/bin/env Rscript

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
  "K52"
}
script_label <- "K52"
helper_label <- sub("\\.V.*$", "", script_base)

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "person_dedup_lookup.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

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

get_arg <- function(flag, default = NULL) {
  args <- commandArgs(trailingOnly = TRUE)
  idx <- match(flag, args)
  if (is.na(idx) || idx == length(args)) return(default)
  args[[idx + 1]]
}

parse_shape <- function(x) {
  val <- toupper(trimws(ifelse(is.null(x), "", as.character(x))))
  if (!val %in% c("LONG", "WIDE")) {
    stop("K52 requires explicit --shape LONG|WIDE.", call. = FALSE)
  }
  val
}

parse_profile <- function(x) {
  val <- trimws(ifelse(is.null(x), "extended", as.character(x)))
  if (!val %in% c("extended")) {
    stop("K52 requires --table-profile extended.", call. = FALSE)
  }
  val
}

resolve_existing <- function(candidates) {
  hits <- candidates[file.exists(candidates)]
  if (length(hits) == 0L) return(NA_character_)
  normalizePath(hits[[1]], winslash = "/", mustWork = TRUE)
}

resolve_data_root_local <- function() {
  load_data_root_from_env_file()
  dr <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(dr)) return(NA_character_)
  normalizePath(dr, winslash = "/", mustWork = FALSE)
}

resolve_input_path <- function(shape, cli_data) {
  if (!is.null(cli_data) && nzchar(cli_data)) {
    if (!file.exists(cli_data)) {
      stop("K52 --data file not found: ", cli_data, call. = FALSE)
    }
    return(normalizePath(cli_data, winslash = "/", mustWork = TRUE))
  }

  shape_lower <- tolower(shape)
  data_root <- resolve_data_root_local()
  candidates <- c()
  if (!is.na(data_root)) {
    candidates <- c(
      candidates,
      file.path(data_root, "paper_02", "analysis", paste0("fof_analysis_k50_", shape_lower, ".rds")),
      file.path(data_root, "paper_02", "analysis", paste0("fof_analysis_k50_", shape_lower, ".csv"))
    )
  }

  hit <- resolve_existing(candidates)
  if (is.na(hit)) {
    stop("K52 could not resolve an input dataset. Supply --data explicitly.", call. = FALSE)
  }
  hit
}

resolve_raw_input_path <- function(cli_data = NULL) {
  if (!is.null(cli_data) && nzchar(cli_data)) {
    if (!file.exists(cli_data)) {
      stop("K52 --raw-data file not found: ", cli_data, call. = FALSE)
    }
    return(normalizePath(cli_data, winslash = "/", mustWork = TRUE))
  }

  data_root <- resolve_data_root_local()
  candidates <- c(
    here::here("data", "external", "KAAOS_data_sotullinen.xlsx"),
    "/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/KAAOS_data_sotullinen.xlsx"
  )
  if (!is.na(data_root)) {
    candidates <- c(candidates, file.path(data_root, "paper_02", "KAAOS_data_sotullinen.xlsx"))
  }
  hit <- resolve_existing(unique(candidates))
  if (is.na(hit)) {
    stop("K52 could not resolve immutable baseline enrichment input `KAAOS_data_sotullinen.xlsx`.", call. = FALSE)
  }
  hit
}

resolve_override_map_path <- function() {
  path <- here::here("R-scripts", "K51", "K51_three_key_override_map.csv")
  if (!file.exists(path)) {
    stop("K52 override map not found: ", path, call. = FALSE)
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
      stop("K52 baseline enrichment found multiple matches for ", target, ".", call. = FALSE)
    }
  }
  stop("K52 baseline enrichment could not resolve column for ", target, ".", call. = FALSE)
}

pick_col_regex_optional <- function(df_names, patterns) {
  norm_df <- normalize_header(df_names)
  for (pattern in patterns) {
    hits <- grepl(pattern, norm_df, perl = TRUE)
    if (sum(hits) == 1L) return(df_names[which(hits)[1]])
  }
  NA_character_
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

format_same_stratum_pvalues <- function(p_without, p_with) {
  paste0(
    "Without FOF: ", format_pvalue(p_without),
    " | With FOF: ", format_pvalue(p_with)
  )
}

same_stratum_pvalue_cont <- function(excluded_df, analytic_df, var_name) {
  p_without <- fun_pvalue_cont(
    c(excluded_df %>% filter(FOF_status == 0L) %>% pull(all_of(var_name)),
      analytic_df %>% filter(FOF_status == 0L) %>% pull(all_of(var_name))),
    c(rep("excluded", sum(excluded_df$FOF_status == 0L, na.rm = TRUE)),
      rep("analytic", sum(analytic_df$FOF_status == 0L, na.rm = TRUE)))
  )
  p_with <- fun_pvalue_cont(
    c(excluded_df %>% filter(FOF_status == 1L) %>% pull(all_of(var_name)),
      analytic_df %>% filter(FOF_status == 1L) %>% pull(all_of(var_name))),
    c(rep("excluded", sum(excluded_df$FOF_status == 1L, na.rm = TRUE)),
      rep("analytic", sum(analytic_df$FOF_status == 1L, na.rm = TRUE)))
  )
  format_same_stratum_pvalues(p_without, p_with)
}

same_stratum_pvalue_binary <- function(excluded_df, analytic_df, var_name) {
  p_without <- fun_pvalue_cat(
    c(excluded_df %>% filter(FOF_status == 0L) %>% pull(all_of(var_name)),
      analytic_df %>% filter(FOF_status == 0L) %>% pull(all_of(var_name))),
    c(rep("excluded", sum(excluded_df$FOF_status == 0L, na.rm = TRUE)),
      rep("analytic", sum(analytic_df$FOF_status == 0L, na.rm = TRUE)))
  )
  p_with <- fun_pvalue_cat(
    c(excluded_df %>% filter(FOF_status == 1L) %>% pull(all_of(var_name)),
      analytic_df %>% filter(FOF_status == 1L) %>% pull(all_of(var_name))),
    c(rep("excluded", sum(excluded_df$FOF_status == 1L, na.rm = TRUE)),
      rep("analytic", sum(analytic_df$FOF_status == 1L, na.rm = TRUE)))
  )
  format_same_stratum_pvalues(p_without, p_with)
}

same_stratum_pvalue_multicat <- function(excluded_df, analytic_df, var_name) {
  p_without <- fun_pvalue_cat(
    c(as.character(excluded_df %>% filter(FOF_status == 0L) %>% pull(all_of(var_name))),
      as.character(analytic_df %>% filter(FOF_status == 0L) %>% pull(all_of(var_name)))),
    c(rep("excluded", sum(excluded_df$FOF_status == 0L, na.rm = TRUE)),
      rep("analytic", sum(analytic_df$FOF_status == 0L, na.rm = TRUE)))
  )
  p_with <- fun_pvalue_cat(
    c(as.character(excluded_df %>% filter(FOF_status == 1L) %>% pull(all_of(var_name))),
      as.character(analytic_df %>% filter(FOF_status == 1L) %>% pull(all_of(var_name)))),
    c(rep("excluded", sum(excluded_df$FOF_status == 1L, na.rm = TRUE)),
      rep("analytic", sum(analytic_df$FOF_status == 1L, na.rm = TRUE)))
  )
  format_same_stratum_pvalues(p_without, p_with)
}

same_stratum_pvalue_multicat_level <- function(excluded_df, analytic_df, var_name, level_value) {
  p_without <- fun_pvalue_cat_level(
    factor(c(
      as.character(excluded_df %>% filter(FOF_status == 0L) %>% pull(all_of(var_name))),
      as.character(analytic_df %>% filter(FOF_status == 0L) %>% pull(all_of(var_name)))
    )),
    c(rep("excluded", sum(excluded_df$FOF_status == 0L, na.rm = TRUE)),
      rep("analytic", sum(analytic_df$FOF_status == 0L, na.rm = TRUE))),
    level_value
  )
  p_with <- fun_pvalue_cat_level(
    factor(c(
      as.character(excluded_df %>% filter(FOF_status == 1L) %>% pull(all_of(var_name))),
      as.character(analytic_df %>% filter(FOF_status == 1L) %>% pull(all_of(var_name)))
    )),
    c(rep("excluded", sum(excluded_df$FOF_status == 1L, na.rm = TRUE)),
      rep("analytic", sum(analytic_df$FOF_status == 1L, na.rm = TRUE))),
    level_value
  )
  format_same_stratum_pvalues(p_without, p_with)
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
  }

  branch_df <- id_gate_df %>% filter(fof_valid, branch_eligible)
  outcome_df <- branch_df %>% filter(outcome_complete)
  analytic_df <- outcome_df %>% filter(age_complete, sex_complete, bmi_complete)

  baseline_df <- baseline_df %>%
    mutate(
      analytic_flag = as.integer(id %in% analytic_df$canonical_id),
      baseline_eligible_flag = as.integer(id %in% branch_df$canonical_id)
    ) %>%
    filter(baseline_eligible_flag == 1L)

  list(
    baseline_df = baseline_df,
    counts = list(
      full_population_n = nrow(baseline_df),
      analytic_population_n = sum(baseline_df$analytic_flag == 1L, na.rm = TRUE),
      excluded_population_n = sum(baseline_df$analytic_flag == 0L, na.rm = TRUE)
    )
  )
}

load_k14_enrichment_baseline <- function(raw_path) {
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

  raw_dedup$data %>%
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
}

load_k14_override_rows <- function(raw_path, override_map_path) {
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

  raw_data %>%
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
}

build_k14_extended_table <- function(df, group_var, group_levels, labels, analytic_compare_df = NULL) {
  disease_any <- ifelse(
    rowSums(cbind(df$diabetes == 1, df$alzheimer == 1, df$parkinson == 1, df$AVH == 1), na.rm = TRUE) > 0,
    1L,
    0L
  )
  df <- df %>% mutate(disease_any = disease_any)
  if (!is.null(analytic_compare_df)) {
    analytic_compare_df <- analytic_compare_df %>%
      mutate(
        disease_any = ifelse(
          rowSums(cbind(diabetes == 1, alzheimer == 1, parkinson == 1, AVH == 1), na.rm = TRUE) > 0,
          1L,
          0L
        )
      )
  }

  rows <- list(
    make_binary_row(df, "woman", "Women, n (%)", group_var, group_levels),
    make_cont_row(df, "age", "Age, mean (SD)", group_var, group_levels, digits = 0),
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
    make_cont_row(df, "BMI", "Body Mass Index, mean (SD)", group_var, group_levels, digits = 1),
    make_binary_row(df, "tupakointi", "Smoked, n (%)", group_var, group_levels),
    make_multicat_rows_with_level_p(df, "alcohol_3class_table", "Alcohol, n (%)", group_var, group_levels),
    make_multicat_rows_with_level_p(df, "SRM_3class_table", "Self-Rated Mobility, n (%)", group_var, group_levels),
    make_multicat_rows_with_level_p(df, "Walk500m_3class_table", "Walking 500 m, n (%)", group_var, group_levels),
    make_binary_row(df, "tasapainovaikeus", "Balance difficulties, n (%)", group_var, group_levels),
    make_binary_row(df, "kaatuminen", "Fallen, n (%)", group_var, group_levels),
    make_binary_row(df, "murtumia", "Fractures, n (%)", group_var, group_levels),
    make_cont_row(df, "PainVAS0", "Pain (Visual Analog Scale), mm, mean (SD)", group_var, group_levels, digits = 1),
    make_cont_row(df, "locomotor_capacity_baseline", "Locomotor capacity at baseline, mean (SD)", group_var, group_levels, digits = 2),
    make_cont_row(df, "FI22_nonperformance_KAAOS", "Frailty Index (FI), mean (SD)", group_var, group_levels, digits = 2)
  )

  table_raw <- bind_rows(rows)
  names(table_raw) <- c("Variable", labels[[1]], labels[[2]], "P-value")

  if (!is.null(analytic_compare_df)) {
    same_stratum_vals <- c(
      same_stratum_pvalue_binary(df, analytic_compare_df, "woman"),
      same_stratum_pvalue_cont(df, analytic_compare_df, "age"),
      same_stratum_pvalue_binary(df, analytic_compare_df, "disease_any"),
      same_stratum_pvalue_binary(df, analytic_compare_df, "diabetes"),
      same_stratum_pvalue_binary(df, analytic_compare_df, "alzheimer"),
      same_stratum_pvalue_binary(df, analytic_compare_df, "parkinson"),
      same_stratum_pvalue_binary(df, analytic_compare_df, "AVH"),
      same_stratum_pvalue_binary(df, analytic_compare_df, "comorbidity"),
      same_stratum_pvalue_multicat(df, analytic_compare_df, "SRH_3class_table"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "SRH_3class_table", "Good"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "SRH_3class_table", "Moderate"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "SRH_3class_table", "Bad"),
      same_stratum_pvalue_cont(df, analytic_compare_df, "MOIindeksiindeksi"),
      same_stratum_pvalue_cont(df, analytic_compare_df, "BMI"),
      same_stratum_pvalue_binary(df, analytic_compare_df, "tupakointi"),
      same_stratum_pvalue_multicat(df, analytic_compare_df, "alcohol_3class_table"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "alcohol_3class_table", "No"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "alcohol_3class_table", "Moderate"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "alcohol_3class_table", "Large"),
      same_stratum_pvalue_multicat(df, analytic_compare_df, "SRM_3class_table"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "SRM_3class_table", "Good"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "SRM_3class_table", "Moderate"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "SRM_3class_table", "Weak"),
      same_stratum_pvalue_multicat(df, analytic_compare_df, "Walk500m_3class_table"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "Walk500m_3class_table", "No"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "Walk500m_3class_table", "Difficulties"),
      same_stratum_pvalue_multicat_level(df, analytic_compare_df, "Walk500m_3class_table", "Cannot"),
      same_stratum_pvalue_binary(df, analytic_compare_df, "tasapainovaikeus"),
      same_stratum_pvalue_binary(df, analytic_compare_df, "kaatuminen"),
      same_stratum_pvalue_binary(df, analytic_compare_df, "murtumia"),
      same_stratum_pvalue_cont(df, analytic_compare_df, "PainVAS0"),
      same_stratum_pvalue_cont(df, analytic_compare_df, "locomotor_capacity_baseline"),
      same_stratum_pvalue_cont(df, analytic_compare_df, "FI22_nonperformance_KAAOS")
    )
    table_raw[["P vs analytic (same FOF stratum)"]] <- same_stratum_vals
  }

  table_raw
}

shape <- parse_shape(get_arg("--shape"))
table_profile <- parse_profile(get_arg("--table-profile", "extended"))
data_path <- resolve_input_path(shape, get_arg("--data"))
raw_data_path <- resolve_raw_input_path(get_arg("--raw-data"))

input_df <- read_dataset(data_path)
cohorts <- derive_k50_cohorts(input_df, shape, outcome = "locomotor_capacity")
baseline_df <- cohorts$baseline_df %>%
  mutate(
    sex = factor(tolower(sex), levels = c("female", "male")),
    woman = case_when(
      sex == "female" ~ 1L,
      sex == "male" ~ 0L,
      TRUE ~ NA_integer_
    )
  )

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

baseline_df <- candidate_df %>% select(-ends_with("_by_id"), -ends_with("_by_override"))

missing_enrichment_ids <- sum(rowSums(!is.na(as.data.frame(baseline_df[, enrich_value_cols, drop = FALSE]))) == 0L)
if (missing_enrichment_ids != 0L) {
  stop("K52 expected full enrichment coverage from approved K51 baseline logic but missing ids remain.", call. = FALSE)
}

full_df <- baseline_df
excluded_df <- baseline_df %>% filter(analytic_flag == 0L)
analytic_df <- baseline_df %>% filter(analytic_flag == 1L)
analysis_vs_excluded_df <- baseline_df %>% mutate(analysis_group = if_else(analytic_flag == 1L, "1", "0"))

full_labels <- c(
  paste0("Without FOF (n=", sum(full_df$FOF_status == 0L, na.rm = TRUE), ")"),
  paste0("With FOF (n=", sum(full_df$FOF_status == 1L, na.rm = TRUE), ")")
)
excluded_labels <- c(
  paste0("Without FOF (n=", sum(excluded_df$FOF_status == 0L, na.rm = TRUE), ")"),
  paste0("With FOF (n=", sum(excluded_df$FOF_status == 1L, na.rm = TRUE), ")")
)
analysis_labels <- c(
  paste0("Excluded (n=", sum(analysis_vs_excluded_df$analysis_group == "0", na.rm = TRUE), ")"),
  paste0("Analytic (n=", sum(analysis_vs_excluded_df$analysis_group == "1", na.rm = TRUE), ")")
)

full_tbl <- build_k14_extended_table(full_df, "FOF_status", c("0", "1"), full_labels)
excluded_tbl <- build_k14_extended_table(excluded_df, "FOF_status", c("0", "1"), excluded_labels, analytic_compare_df = analytic_df)
analysis_tbl <- build_k14_extended_table(analysis_vs_excluded_df, "analysis_group", c("0", "1"), analysis_labels)

full_csv <- write_table_csv(full_tbl, paste0("k52_", tolower(shape), "_full_population_table"), "K52 full population by FOF table")
full_html <- write_table_html(full_tbl, paste0("k52_", tolower(shape), "_full_population_table"), "K52 full population by FOF", "K52 full population by FOF table")
excluded_csv <- write_table_csv(excluded_tbl, paste0("k52_", tolower(shape), "_excluded_population_table"), "K52 excluded population by FOF table")
excluded_html <- write_table_html(excluded_tbl, paste0("k52_", tolower(shape), "_excluded_population_table"), "K52 excluded population by FOF", "K52 excluded population by FOF table")
analysis_csv <- write_table_csv(analysis_tbl, paste0("k52_", tolower(shape), "_analysis_vs_excluded_table"), "K52 analysis vs excluded comparison table")
analysis_html <- write_table_html(analysis_tbl, paste0("k52_", tolower(shape), "_analysis_vs_excluded_table"), "K52 analysis vs excluded comparison", "K52 analysis vs excluded comparison table")

decision_label <- paste0("k52_", tolower(shape), "_decision_log")
decision_path <- file.path(outputs_dir, paste0(decision_label, ".txt"))
decision_lines <- c(
  "K52 selection and excluded supplement tables run",
  paste0("input_path=", data_path),
  paste0("shape=", shape),
  paste0("table_profile=", table_profile),
  paste0("raw_enrichment_path=", raw_data_path),
  "K52 reuses K51-approved cohort and baseline enrichment logic plus the audited three-key override map.",
  "Population definitions: full_population = baseline-eligible; analytic_population = analytic_flag == 1; excluded_population = analytic_flag == 0.",
  paste0("raw_enrichment_status=", "full_coverage"),
  paste0("full_population_n=", cohorts$counts$full_population_n),
  paste0("analytic_population_n=", cohorts$counts$analytic_population_n),
  paste0("excluded_population_n=", cohorts$counts$excluded_population_n),
  paste0("full_population_without_fof_n=", sum(full_df$FOF_status == 0L, na.rm = TRUE)),
  paste0("full_population_with_fof_n=", sum(full_df$FOF_status == 1L, na.rm = TRUE)),
  paste0("excluded_population_without_fof_n=", sum(excluded_df$FOF_status == 0L, na.rm = TRUE)),
  paste0("excluded_population_with_fof_n=", sum(excluded_df$FOF_status == 1L, na.rm = TRUE)),
  paste0("analysis_vs_excluded_counts=", sum(analysis_vs_excluded_df$analysis_group == "1", na.rm = TRUE), " vs ", sum(analysis_vs_excluded_df$analysis_group == "0", na.rm = TRUE)),
  "excluded_population_table includes an extra column `P vs analytic (same FOF stratum)` with two same-stratum p-values per row: excluded vs analytic within Without FOF and within With FOF.",
  paste0("full_population_table_csv=", full_csv),
  paste0("excluded_population_table_csv=", excluded_csv),
  paste0("analysis_vs_excluded_table_csv=", analysis_csv)
)
writeLines(decision_lines, con = decision_path)
append_manifest_safe(decision_label, "text", decision_path, n = nrow(baseline_df), notes = "K52 decision log")

receipt_label <- paste0("k52_", tolower(shape), "_input_receipt")
receipt_path <- file.path(outputs_dir, paste0(receipt_label, ".txt"))
receipt_lines <- c(
  paste0("script=", helper_label),
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("input_path=", data_path),
  paste0("input_md5=", unname(tools::md5sum(data_path))),
  paste0("shape=", shape),
  paste0("table_profile=", table_profile),
  paste0("raw_enrichment_path=", raw_data_path),
  paste0("raw_enrichment_md5=", unname(tools::md5sum(raw_data_path))),
  paste0("override_map_path=", resolve_override_map_path()),
  paste0("override_map_md5=", unname(tools::md5sum(resolve_override_map_path()))),
  paste0("full_population_n=", cohorts$counts$full_population_n),
  paste0("analytic_population_n=", cohorts$counts$analytic_population_n),
  paste0("excluded_population_n=", cohorts$counts$excluded_population_n),
  paste0("full_population_table_csv=", full_csv),
  paste0("full_population_table_html=", full_html),
  paste0("excluded_population_table_csv=", excluded_csv),
  paste0("excluded_population_table_html=", excluded_html),
  paste0("analysis_vs_excluded_table_csv=", analysis_csv),
  paste0("analysis_vs_excluded_table_html=", analysis_html)
)
writeLines(receipt_lines, con = receipt_path)
append_manifest_safe(receipt_label, "text", receipt_path, n = nrow(baseline_df), notes = "K52 provenance receipt")

session_label <- paste0("k52_", tolower(shape), "_sessioninfo")
session_path <- file.path(outputs_dir, paste0(session_label, ".txt"))
utils::capture.output(sessionInfo(), file = session_path)
append_manifest_safe(session_label, "sessioninfo", session_path, notes = "K52 session info")
