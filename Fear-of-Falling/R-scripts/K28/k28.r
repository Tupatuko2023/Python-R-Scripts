#!/usr/bin/env Rscript
# ==============================================================================
# K28 - time × FOF × frailty interaction (long-data mixed model)
# File tag: K28.V1_time-fof-frailty-interaction.R
# Purpose: Fit 3-way interaction mixed models for Composite_Z using long data:
#          time × FOF_status_f × frailty_score_3 (primary, continuous) and
#          optional time × FOF_status_f × frailty_cat_3 (sensitivity).
#
# Outcome: Composite_Z (long)
# Predictors: time, FOF_status_f, frailty_score_3
# Moderator/interaction: time × FOF_status_f × frailty_score_3
# Grouping variable: id (random intercept)
# Covariates: none
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, time, Composite_Z, FOF_status, frailty_score_3
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# FOF_status (0/1) -> FOF_status_f (nonFOF/FOF)
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: not required (no stochastic methods)
#
# Outputs + manifest:
# - script_label: K28 (canonical)
# - outputs dir: R-scripts/K28/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load analysis_long (object and optional input fallback)
# 03) Standardize vars + QC (required columns, duplicates, factor levels)
# 04) Fit primary model (time × FOF × frailty_score_3)
# 05) Extract fixed 3-way terms + save CSV/RDS
# 06) Compute emmeans change (follow-up - baseline) by frailty score
# 07) Fit optional sensitivity model (frailty_cat_3) + save outputs
# 08) Generate report text directly from output tables (table-to-text crosscheck)
# 09) Save outputs into R-scripts/K28/outputs/
# 10) Append manifest row for each artifact
# 11) Save sessionInfo_K28.txt into manifest/ + manifest row
# 12) EOF marker
# ==============================================================================

if (Sys.getenv("RENV_PROJECT") == "") source("renv/activate.R")

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(lme4)
  library(broom.mixed)
  library(emmeans)
})

if (requireNamespace("lmerTest", quietly = TRUE)) {
  suppressPackageStartupMessages(library(lmerTest))
}

source(here::here("R", "functions", "reporting.R"))

script_label <- "K28"
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
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
}

write_csv_and_manifest <- function(df, path, label, kind = "table_csv", notes = NA_character_) {
  readr::write_csv(df, path)
  append_artifact(label = label, kind = kind, path = path, n = nrow(df), notes = notes)
}

write_rds_and_manifest <- function(obj, path, label, kind = "model_rds", notes = NA_character_) {
  saveRDS(obj, path)
  n_val <- if (is.data.frame(obj)) nrow(obj) else NA_integer_
  append_artifact(label = label, kind = kind, path = path, n = n_val, notes = notes)
}

write_lines_and_manifest <- function(lines, path, label, kind = "text", notes = NA_character_) {
  writeLines(lines, con = path)
  append_artifact(label = label, kind = kind, path = path, n = length(lines), notes = notes)
}

normalize_file_string <- function(x) {
  out <- gsub("\\\\", "/", as.character(x))
  out <- gsub("/+", "/", out)
  out <- sub("^\\./", "", out)
  out
}

strip_project_prefix <- function(x, project_root) {
  x_norm <- normalize_file_string(x)
  root_norm <- normalize_file_string(project_root)
  prefix <- paste0(root_norm, "/")
  ifelse(startsWith(x_norm, prefix), substring(x_norm, nchar(prefix) + 1), x_norm)
}

manifest_remove_rows_for_files <- function(manifest_path, script_label, files) {
  if (!file.exists(manifest_path)) return(invisible(NULL))

  mf <- suppressMessages(readr::read_csv(manifest_path, show_col_types = FALSE))
  if (nrow(mf) == 0) return(invisible(NULL))

  nm_lower <- tolower(names(mf))
  script_col <- names(mf)[match("script", nm_lower)]
  file_col <- names(mf)[match("file", nm_lower)]
  if (is.na(file_col)) file_col <- names(mf)[match("path", nm_lower)]
  if (is.na(script_col) || is.na(file_col)) return(invisible(NULL))

  root <- here::here()
  target_aliases <- unique(unlist(lapply(files, function(f) {
    c(
      as.character(f),
      normalize_file_string(f),
      normalize_file_string(get_relpath(f)),
      strip_project_prefix(f, root),
      strip_project_prefix(get_relpath(f), root)
    )
  })))

  script_vals <- as.character(mf[[script_col]])
  file_raw <- as.character(mf[[file_col]])
  file_norm <- normalize_file_string(file_raw)
  file_rel <- strip_project_prefix(file_norm, root)

  matched_file <- file_raw %in% target_aliases |
    file_norm %in% target_aliases |
    file_rel %in% target_aliases

  keep <- !(script_vals == script_label & matched_file)
  out <- mf[keep, , drop = FALSE]
  readr::write_csv(out, manifest_path)
  invisible(NULL)
}

validate_manifest_no_duplicates_for_script <- function(manifest_path, script_label) {
  if (!file.exists(manifest_path)) return(invisible(TRUE))

  mf <- suppressMessages(readr::read_csv(manifest_path, show_col_types = FALSE))
  if (nrow(mf) == 0) return(invisible(TRUE))

  nm_lower <- tolower(names(mf))
  script_col <- names(mf)[match("script", nm_lower)]
  file_col <- names(mf)[match("file", nm_lower)]
  if (is.na(file_col)) file_col <- names(mf)[match("path", nm_lower)]
  if (is.na(script_col) || is.na(file_col)) return(invisible(TRUE))

  sub <- mf[mf[[script_col]] == script_label, , drop = FALSE]
  if (nrow(sub) == 0) return(invisible(TRUE))

  file_vals <- normalize_file_string(sub[[file_col]])
  dup_counts <- sort(table(file_vals), decreasing = TRUE)
  dup_counts <- dup_counts[dup_counts > 1]
  if (length(dup_counts) > 0) {
    stop("Manifest duplicate rows for K28 artifacts")
  }
  invisible(TRUE)
}

k28_artifact_files <- c(
  file.path(outputs_dir, "FOF_x_time_x_frailtyScore_on_CompositeZ_fixed_terms.csv"),
  file.path(outputs_dir, "FOF_x_time_x_frailtyScore_on_CompositeZ_fixed_terms.rds"),
  file.path(outputs_dir, "FOF_x_time_x_frailtyScore_on_CompositeZ_change_by_frailty.csv"),
  file.path(outputs_dir, "FOF_x_time_x_frailtyCat_on_CompositeZ_fixed_terms.csv"),
  file.path(outputs_dir, "FOF_x_time_x_frailtyCat_on_CompositeZ_fixed_terms.rds"),
  file.path(outputs_dir, "FOF_x_time_x_frailtyCat_on_CompositeZ_change_by_cat.csv"),
  file.path(outputs_dir, "k28_interaction_report.md"),
  file.path(outputs_dir, "k28_interaction_report.txt"),
  here::here("manifest", "sessionInfo_K28.txt")
)

# Idempotency: remove previous K28 rows for K28 artifact files before appending.
manifest_remove_rows_for_files(
  manifest_path = manifest_path,
  script_label = script_label,
  files = k28_artifact_files
)

parse_cli <- function(args) {
  out <- list(
    input_csv = NA_character_,
    input_rdata = NA_character_
  )
  for (arg in args) {
    if (startsWith(arg, "--input-csv=")) {
      out$input_csv <- sub("^--input-csv=", "", arg)
    }
    if (startsWith(arg, "--input-rdata=")) {
      out$input_rdata <- sub("^--input-rdata=", "", arg)
    }
  }
  out
}

load_analysis_long <- function(args) {
  if (exists("analysis_long", inherits = TRUE)) {
    obj <- get("analysis_long", inherits = TRUE)
    if (is.data.frame(obj)) {
      message("K28: Using existing analysis_long object from environment")
      return(obj)
    }
  }

  if (!is.na(args$input_csv) && file.exists(args$input_csv)) {
    message("K28: Loading analysis_long from --input-csv")
    return(readr::read_csv(args$input_csv, show_col_types = FALSE))
  }

  if (!is.na(args$input_rdata) && file.exists(args$input_rdata)) {
    message("K28: Loading analysis_long from --input-rdata")
    e <- new.env(parent = emptyenv())
    objs <- load(args$input_rdata, envir = e)
    if ("analysis_long" %in% objs) {
      return(get("analysis_long", envir = e))
    }
    stop("--input-rdata does not contain object named analysis_long")
  }

  default_rdata <- c(
    here::here("R-scripts", "K18_MAIN", "outputs", "K18_analysis_data.RData"),
    here::here("R-scripts", "K15_MAIN", "outputs", "K15_frailty_analysis_data.RData"),
    here::here("R-scripts", "K15", "outputs", "K15_frailty_analysis_data.RData")
  )
  hit <- default_rdata[file.exists(default_rdata)][1]
  if (is.na(hit) || !nzchar(hit)) {
    stop(
      "analysis_long object not found and no fallback input available. ",
      "Provide analysis_long in environment or use --input-csv / --input-rdata."
    )
  }

  e <- new.env(parent = emptyenv())
  objs <- load(hit, envir = e)
  if ("analysis_long" %in% objs && is.data.frame(get("analysis_long", envir = e))) {
    message("K28: Loaded analysis_long from ", hit)
    return(get("analysis_long", envir = e))
  }

  df_name <- c("analysis_data", "data", "df")
  df_name <- df_name[df_name %in% objs][1]
  if (is.na(df_name) || !nzchar(df_name)) {
    stop("Fallback RData does not contain analysis_long or analysis_data/data/df object")
  }

  wide <- get(df_name, envir = e)
  if (!is.data.frame(wide)) {
    stop("Fallback object is not a data.frame: ", df_name)
  }

  id_col <- c("id", "ID", "Jnro", "NRO")
  id_col <- id_col[id_col %in% names(wide)][1]
  z0_col <- c("Composite_Z0", "ToimintaKykySummary0")
  z0_col <- z0_col[z0_col %in% names(wide)][1]
  z12_col <- c("Composite_Z12", "Composite_Z2", "ToimintaKykySummary2")
  z12_col <- z12_col[z12_col %in% names(wide)][1]

  fof_col <- c("FOF_status", "kaatumisenpelkoOn")
  fof_col <- fof_col[fof_col %in% names(wide)][1]
  frailty_score_col <- c("frailty_score_3", "frailty_count_3")
  frailty_score_col <- frailty_score_col[frailty_score_col %in% names(wide)][1]

  req_wide <- c(id_col, z0_col, z12_col, fof_col, frailty_score_col)
  if (any(is.na(req_wide))) {
    stop("Fallback wide-data conversion failed: missing required columns in fallback RData")
  }

  message("K28: Building analysis_long from fallback wide data: ", hit)
  out <- wide %>%
    mutate(
      id = .data[[id_col]],
      FOF_status = .data[[fof_col]],
      frailty_score_3 = .data[[frailty_score_col]],
      Composite_Z0 = .data[[z0_col]],
      Composite_Z12 = .data[[z12_col]]
    ) %>%
    select(any_of(c("id", "FOF_status", "frailty_score_3", "frailty_cat_3", "Composite_Z0", "Composite_Z12"))) %>%
    pivot_longer(
      cols = c("Composite_Z0", "Composite_Z12"),
      names_to = "time",
      values_to = "Composite_Z"
    ) %>%
    mutate(time = if_else(time == "Composite_Z0", "baseline", "followup"))

  out
}

ensure_numeric <- function(x, nm) {
  y <- suppressWarnings(as.numeric(as.character(x)))
  if (all(is.na(y)) && any(!is.na(x))) {
    stop("Column ", nm, " could not be converted to numeric")
  }
  y
}

pick_last_vs_first <- function(df, first_level, last_level) {
  if (!"contrast" %in% names(df)) return(df)
  target <- paste0(last_level, " - ", first_level)
  hit <- df %>% filter(.data$contrast == target)
  if (nrow(hit) > 0) return(hit)
  df %>% slice(1)
}

fmt_num <- function(x, digits = 3) {
  ifelse(is.na(x), "NA", formatC(x, format = "f", digits = digits))
}

fmt_p <- function(x) {
  ifelse(is.na(x), "NA", ifelse(x < 0.001, "<0.001", formatC(x, format = "f", digits = 3)))
}

normalize_contrast_cols <- function(df) {
  out <- as.data.frame(df)
  if (!"lower.CL" %in% names(out) && "asymp.LCL" %in% names(out)) out$lower.CL <- out$asymp.LCL
  if (!"upper.CL" %in% names(out) && "asymp.UCL" %in% names(out)) out$upper.CL <- out$asymp.UCL
  if (!"p.value" %in% names(out) && "p.value" %in% tolower(names(out))) {
    p_idx <- which(tolower(names(out)) == "p.value")[1]
    out$p.value <- out[[p_idx]]
  }
  if (!"lower.CL" %in% names(out)) out$lower.CL <- NA_real_
  if (!"upper.CL" %in% names(out)) out$upper.CL <- NA_real_
  if (!"p.value" %in% names(out)) out$p.value <- NA_real_
  out
}

args <- parse_cli(commandArgs(trailingOnly = TRUE))
analysis_long <- load_analysis_long(args)

req_cols <- c("id", "time", "Composite_Z", "FOF_status", "frailty_score_3")
missing_cols <- setdiff(req_cols, names(analysis_long))
if (length(missing_cols) > 0) {
  stop("Puuttuvat pakolliset sarakkeet (req_cols): ", paste(missing_cols, collapse = ", "))
}

analysis_long <- analysis_long %>%
  mutate(
    id = as.factor(.data$id),
    time = factor(.data$time, levels = unique(as.character(.data$time))),
    Composite_Z = ensure_numeric(.data$Composite_Z, "Composite_Z"),
    FOF_status = suppressWarnings(as.integer(as.character(.data$FOF_status))),
    frailty_score_3 = ensure_numeric(.data$frailty_score_3, "frailty_score_3")
  )

bad_fof <- unique(stats::na.omit(analysis_long$FOF_status[!analysis_long$FOF_status %in% c(0L, 1L)]))
if (length(bad_fof) > 0) {
  stop("FOF_status sisältää arvoja jotka eivät ole 0/1: ", paste(bad_fof, collapse = ", "))
}

analysis_long <- analysis_long %>%
  mutate(
    FOF_status_f = factor(.data$FOF_status, levels = c(0, 1), labels = c("nonFOF", "FOF"))
  )

if (any(is.na(analysis_long$time))) {
  stop("time contains NA values after factor conversion")
}

time_levels <- levels(analysis_long$time)
if (length(time_levels) < 2) {
  stop("time must contain at least two levels")
}

dup_check <- analysis_long %>%
  count(.data$id, .data$time, name = "n") %>%
  filter(.data$n > 1)
if (nrow(dup_check) > 0) {
  stop("id-time duplicates detected; each id-time pair must be unique")
}

# Primary model: continuous frailty score
m_int_score <- lmer(
  Composite_Z ~ time * FOF_status_f * frailty_score_3 + (1 | id),
  data = analysis_long,
  REML = FALSE
)
print(summary(m_int_score))

fixed_score <- broom.mixed::tidy(m_int_score, effects = "fixed", conf.int = TRUE)
if (!"p.value" %in% names(fixed_score)) fixed_score$p.value <- NA_real_
fixed_score <- fixed_score %>%
  mutate(std.error = dplyr::coalesce(.data$std.error, NA_real_)) %>%
  select(any_of(c("term", "estimate", "std.error", "conf.low", "conf.high", "p.value")))

fixed_score_3way <- fixed_score %>%
  filter(grepl("time.*FOF_status_f.*frailty_score_3", .data$term))

score_fixed_csv <- file.path(outputs_dir, "FOF_x_time_x_frailtyScore_on_CompositeZ_fixed_terms.csv")
score_fixed_rds <- file.path(outputs_dir, "FOF_x_time_x_frailtyScore_on_CompositeZ_fixed_terms.rds")

write_csv_and_manifest(
  fixed_score_3way,
  score_fixed_csv,
  label = "FOF_x_time_x_frailtyScore_on_CompositeZ_fixed_terms",
  kind = "table_csv"
)
write_rds_and_manifest(
  fixed_score_3way,
  score_fixed_rds,
  label = "FOF_x_time_x_frailtyScore_on_CompositeZ_fixed_terms",
  kind = "table_rds"
)

emm_score <- emmeans(
  m_int_score,
  ~ time * FOF_status_f | frailty_score_3,
  at = list(frailty_score_3 = c(0, 1, 2, 3))
)

score_changes_obj <- contrast(
  emm_score,
  method = "revpairwise",
  by = c("FOF_status_f", "frailty_score_3")
) 

score_changes_all <- as.data.frame(summary(score_changes_obj, infer = c(TRUE, TRUE))) %>%
  normalize_contrast_cols()

if (length(time_levels) > 2) {
  score_changes <- score_changes_all %>%
    group_by(.data$FOF_status_f, .data$frailty_score_3) %>%
    group_modify(~ pick_last_vs_first(.x, first_level = time_levels[1], last_level = time_levels[length(time_levels)])) %>%
    ungroup()
} else {
  score_changes <- score_changes_all
}

score_change_csv <- file.path(outputs_dir, "FOF_x_time_x_frailtyScore_on_CompositeZ_change_by_frailty.csv")
write_csv_and_manifest(
  score_changes,
  score_change_csv,
  label = "FOF_x_time_x_frailtyScore_on_CompositeZ_change_by_frailty",
  kind = "table_csv",
  notes = if (length(time_levels) > 2) {
    paste0("Selected last-vs-first contrast: ", time_levels[length(time_levels)], " - ", time_levels[1])
  } else {
    NA_character_
  }
)

has_cat <- "frailty_cat_3" %in% names(analysis_long)
fixed_cat_3way <- tibble::tibble()
cat_changes <- tibble::tibble()

if (has_cat) {
  cat_values <- unique(stats::na.omit(as.character(analysis_long$frailty_cat_3)))
  allowed_cat <- c("robust", "pre-frail", "frail")

  if (!all(cat_values %in% allowed_cat)) {
    stop(
      "frailty_cat_3 contains unsupported levels. Expected robust/pre-frail/frail, got: ",
      paste(sort(cat_values), collapse = ", ")
    )
  }

  analysis_long <- analysis_long %>%
    mutate(frailty_cat_3 = factor(as.character(.data$frailty_cat_3), levels = allowed_cat))

  m_int_cat <- lmer(
    Composite_Z ~ time * FOF_status_f * frailty_cat_3 + (1 | id),
    data = analysis_long,
    REML = FALSE
  )

  fixed_cat <- broom.mixed::tidy(m_int_cat, effects = "fixed", conf.int = TRUE)
  if (!"p.value" %in% names(fixed_cat)) fixed_cat$p.value <- NA_real_

  fixed_cat <- fixed_cat %>%
    mutate(std.error = dplyr::coalesce(.data$std.error, NA_real_)) %>%
    select(any_of(c("term", "estimate", "std.error", "conf.low", "conf.high", "p.value")))

  fixed_cat_3way <- fixed_cat %>%
    filter(grepl("time.*FOF_status_f.*frailty_cat_3", .data$term))

  cat_fixed_csv <- file.path(outputs_dir, "FOF_x_time_x_frailtyCat_on_CompositeZ_fixed_terms.csv")
  cat_fixed_rds <- file.path(outputs_dir, "FOF_x_time_x_frailtyCat_on_CompositeZ_fixed_terms.rds")

  write_csv_and_manifest(
    fixed_cat_3way,
    cat_fixed_csv,
    label = "FOF_x_time_x_frailtyCat_on_CompositeZ_fixed_terms",
    kind = "table_csv"
  )
  write_rds_and_manifest(
    fixed_cat_3way,
    cat_fixed_rds,
    label = "FOF_x_time_x_frailtyCat_on_CompositeZ_fixed_terms",
    kind = "table_rds"
  )

  emm_cat <- emmeans(m_int_cat, ~ time * FOF_status_f | frailty_cat_3)

  cat_changes_obj <- contrast(
    emm_cat,
    method = "revpairwise",
    by = c("FOF_status_f", "frailty_cat_3")
  )

  cat_changes_all <- as.data.frame(summary(cat_changes_obj, infer = c(TRUE, TRUE))) %>%
    normalize_contrast_cols()

  if (length(time_levels) > 2) {
    cat_changes <- cat_changes_all %>%
      group_by(.data$FOF_status_f, .data$frailty_cat_3) %>%
      group_modify(~ pick_last_vs_first(.x, first_level = time_levels[1], last_level = time_levels[length(time_levels)])) %>%
      ungroup()
  } else {
    cat_changes <- cat_changes_all
  }

  cat_change_csv <- file.path(outputs_dir, "FOF_x_time_x_frailtyCat_on_CompositeZ_change_by_cat.csv")
  write_csv_and_manifest(
    cat_changes,
    cat_change_csv,
    label = "FOF_x_time_x_frailtyCat_on_CompositeZ_change_by_cat",
    kind = "table_csv",
    notes = if (length(time_levels) > 2) {
      paste0("Selected last-vs-first contrast: ", time_levels[length(time_levels)], " - ", time_levels[1])
    } else {
      NA_character_
    }
  )
}

threeway_line <- if (nrow(fixed_score_3way) > 0) {
  rw <- fixed_score_3way[1, ]
  paste0(
    "Jatkuvan frailty_score_3-mallin 3-way-termi ", rw$term,
    ": estimate ", fmt_num(rw$estimate),
    ", 95 % LV [", fmt_num(rw$conf.low), ", ", fmt_num(rw$conf.high), "]",
    ", p = ", fmt_p(rw$p.value), "."
  )
} else {
  "Jatkuvan frailty_score_3-mallin 3-way-termiä ei löytynyt fixed_terms-taulukosta."
}

score_change_lines <- if (nrow(score_changes) > 0) {
  score_changes %>%
    mutate(
      line = paste0(
        "Muutos ", .data$FOF_status_f,
        ", frailty_score_3=", .data$frailty_score_3,
        ": ", .data$contrast,
        " = ", fmt_num(.data$estimate),
        " (95 % LV ", fmt_num(.data$lower.CL), "...", fmt_num(.data$upper.CL),
        "), p = ", fmt_p(.data$p.value), "."
      )
    ) %>%
    pull(.data$line)
} else {
  "Jatkuvan mallin change_by_frailty-taulukko on tyhjä."
}

cat_line <- if (has_cat && nrow(fixed_cat_3way) > 0) {
  rw <- fixed_cat_3way[1, ]
  paste0(
    "Kategorisen frailty_cat_3-mallin 3-way-termi ", rw$term,
    ": estimate ", fmt_num(rw$estimate),
    ", 95 % LV [", fmt_num(rw$conf.low), ", ", fmt_num(rw$conf.high), "]",
    ", p = ", fmt_p(rw$p.value), "."
  )
} else if (has_cat) {
  "Kategorisen frailty_cat_3-mallin 3-way-termiä ei löytynyt fixed_terms-taulukosta."
} else {
  "frailty_cat_3 ei ollut datassa, joten kategorista herkkyysanalyysiä ei ajettu."
}

cat_change_line <- if (has_cat && nrow(cat_changes) > 0) {
  rw <- cat_changes[1, ]
  paste0(
    "Esimerkkimuutos kategorisesta mallista (", rw$FOF_status_f, ", ", rw$frailty_cat_3,
    "): ", rw$contrast, " = ", fmt_num(rw$estimate),
    " (95 % LV ", fmt_num(rw$lower.CL), "...", fmt_num(rw$upper.CL),
    "), p = ", fmt_p(rw$p.value), "."
  )
} else if (has_cat) {
  "Kategorisen mallin change_by_cat-taulukko on tyhjä."
} else {
  "Kategorisen mallin change_by_cat-taulukkoa ei tuotettu (frailty_cat_3 puuttui)."
}

summarize_score_changes <- function(df, fof_group) {
  grp <- df %>%
    filter(.data$FOF_status_f == fof_group) %>%
    mutate(frailty_score_3 = as.numeric(.data$frailty_score_3)) %>%
    arrange(.data$frailty_score_3)
  if (nrow(grp) == 0) return(paste0("Muutos ", fof_group, ": ei rivejä."))
  parts <- paste0(
    "s", grp$frailty_score_3, ": ", fmt_num(grp$estimate),
    " (p=", fmt_p(grp$p.value), ")"
  )
  paste0("Muutos ", fof_group, " frailty_score_3=0..3: ", paste(parts, collapse = "; "), ".")
}

summarize_cat_changes <- function(df, fof_group) {
  grp <- df %>%
    filter(.data$FOF_status_f == fof_group) %>%
    mutate(frailty_cat_3 = as.character(.data$frailty_cat_3)) %>%
    arrange(factor(.data$frailty_cat_3, levels = c("robust", "pre-frail", "frail")))
  if (nrow(grp) == 0) return(paste0("Muutos ", fof_group, " frailty_cat_3: ei rivejä."))
  parts <- paste0(
    grp$frailty_cat_3, ": ", fmt_num(grp$estimate),
    " (p=", fmt_p(grp$p.value), ")"
  )
  paste0("Muutos ", fof_group, " frailty_cat_3: ", paste(parts, collapse = "; "), ".")
}

report_lines <- c(
  "# K28: time × FOF × frailty -interaktio",
  paste0("Aineistossa käytetyt time-tasot: ", paste(time_levels, collapse = ", "), "."),
  paste0("Raportoitu muutosvertailu: ", time_levels[length(time_levels)], " - ", time_levels[1], "."),
  threeway_line,
  summarize_score_changes(score_changes, "nonFOF"),
  summarize_score_changes(score_changes, "FOF"),
  cat_line,
  if (has_cat) summarize_cat_changes(cat_changes, "nonFOF") else cat_change_line,
  if (has_cat) summarize_cat_changes(cat_changes, "FOF") else NULL
)

report_md <- file.path(outputs_dir, "k28_interaction_report.md")
report_txt <- file.path(outputs_dir, "k28_interaction_report.txt")

write_lines_and_manifest(report_lines, report_md, label = "k28_interaction_report_md", kind = "report_md")
write_lines_and_manifest(report_lines, report_txt, label = "k28_interaction_report_txt", kind = "report_txt")

sessioninfo_path <- here::here("manifest", "sessionInfo_K28.txt")
writeLines(capture.output(sessionInfo()), con = sessioninfo_path)
append_artifact(label = "sessionInfo_K28", kind = "sessioninfo", path = sessioninfo_path)

validate_manifest_no_duplicates_for_script(manifest_path, script_label)

message("K28 complete. Outputs written to: ", outputs_dir)
