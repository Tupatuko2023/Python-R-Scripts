#!/usr/bin/env Rscript
# ==============================================================================
# K40_FI_KAAOS - Frailty Index (FI) builder from KAAOS raw xlsx (deterministic)
# NOTE: In this monorepo, helper functions may live under Fear-of-Falling/R/functions.
# File tag: K40_FI_KAAOS.R
# Purpose:
#   Build deterministic FI = proportion of deficits (0-1), with FI_z as
#   standardized derived variable, using non-performance deficits only.
#
# Outcome: frailty_index_fi and frailty_index_fi_z (derived)
# Predictors: dynamically detected KAAOS deficit candidates from the selected sheet
# Moderator/interaction: none
# Grouping variable: participant identifier column resolved dynamically
# Covariates: none
#
# Required vars (dynamic raw-sheet contract; no fixed req_cols applies):
# - `ID_COL` override or deterministic identifier-column inference from the KAAOS sheet
# - `candidate deficit columns` read dynamically from the selected raw KAAOS sheet
# - `label row` if the first row contains item labels used for readable outputs
# - `time/visit column` only if baseline filtering is available in the raw sheet
#
# Mapping example (dynamic raw -> analysis; no static column inventory is declared here):
# - raw identifier column -> `id_col`
# - raw health/deficit columns -> candidate inventory -> selected deficits -> FI scores
#
# Data Source (Option B):
#   ${DATA_ROOT}/paper_02/KAAOS_data.xlsx   (RAW XLSX; do not use Kaatumisenpelko.csv)
# Optional override if ID column header is ambiguous:
#   export ID_COL="...1"
#
# Outputs + manifest (repo-local, aggregated only):
#   - outputs dir: (init_paths(script_label))
#   - manifest: append per artifact
#
# Patient-level outputs (never in repo; DATA_ROOT only):
#   - ${DATA_ROOT}/paper_02/frailty_vulnerability/kaaos_with_frailty_index_k40.(csv|rds)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(readr)
  library(readxl)
})

# --- Resolve project root -----------------------------------------------------------
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
subproject_root <- here::here()
setwd(subproject_root)

find_functions_dir <- function(root) {
  # Standard project structure: Fear-of-Falling/R/functions
  p1 <- file.path(root, "R", "functions")
  if (file.exists(file.path(p1, "init.R"))) return(p1)
  
  # Monorepo structure: Python-R-Scripts/Fear-of-Falling/R/functions
  p2 <- file.path(root, "Fear-of-Falling", "R", "functions")
  if (file.exists(file.path(p2, "init.R"))) return(p2)
  
  # Fallback: search from current working directory
  p3 <- file.path(getwd(), "R", "functions")
  if (file.exists(file.path(p3, "init.R"))) return(p3)

  stop("Missing required helper scripts init.R (searched in Fear-of-Falling/R/functions).", call. = FALSE)
}

functions_dir <- find_functions_dir(subproject_root)
source(file.path(functions_dir, "init.R"))
suppressWarnings(try(source(file.path(functions_dir, "reporting.R")), silent = TRUE))

# Ensure manifest append is type-stable even with old timestamp parsing.
append_manifest <- function(row, manifest_path) {
  stopifnot(is.data.frame(row))
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)

  if (!file.exists(manifest_path)) {
    readr::write_csv(row, manifest_path)
  } else {
    old <- suppressMessages(readr::read_csv(
      manifest_path,
      show_col_types = FALSE,
      col_types = readr::cols(
        timestamp = readr::col_character(),
        n = readr::col_character(),
        .default = readr::col_guess()
      )
    ))
    row$n <- as.character(row$n)
    out <- dplyr::bind_rows(old, row)
    readr::write_csv(out, manifest_path)
  }
  invisible(manifest_path)
}

script_label <- "K40_FI_KAAOS"

resolve_data_root_early <- function(root) {
  from_env <- Sys.getenv("DATA_ROOT", "")
  if (nzchar(from_env)) return(from_env)

  env_path <- file.path(root, "config", ".env")
  if (file.exists(env_path)) {
    env_lines <- readLines(env_path, warn = FALSE)
    hit <- grep("^DATA_ROOT\\s*=", env_lines, value = TRUE)
    if (length(hit) > 0) {
      value <- sub("^DATA_ROOT\\s*=\\s*", "", hit[[1]])
      value <- gsub('^"|"$', "", value)
      value <- gsub("^'|'$", "", value)
      if (nzchar(value)) return(value)
    }
  }

  stop(
    "DATA_ROOT is required but missing. Set DATA_ROOT env var or config/.env DATA_ROOT=...",
    call. = FALSE
  )
}

# Fail fast before any IO-heavy pipeline step.
data_root <- resolve_data_root_early(subproject_root)

paths <- init_paths(script_label)
# Override outputs location to project-standard R-scripts/ tree
run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")
outputs_dir <- file.path("R-scripts", "K40", "outputs", script_label, run_id)
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
manifest_path <- getOption("fof.manifest_path")

# Record helper location in decision log later (relative only, no abs paths)
helpers_origin <- if (grepl("Fear-of-Falling", functions_dir, fixed = TRUE)) "Fear-of-Falling/R/functions" else "Quantify-FOF-Utilization-Costs/R/functions"

if (!exists("save_sessioninfo_manifest", mode = "function")) {
  save_sessioninfo_manifest <- function(outputs_dir, manifest_path, script) {
    sessioninfo_path <- file.path(outputs_dir, paste0("sessioninfo_", script, ".txt"))
    dir.create(dirname(sessioninfo_path), recursive = TRUE, showWarnings = FALSE)
    writeLines(capture.output(sessionInfo()), con = sessioninfo_path)
    append_manifest(
      manifest_row(script = script, label = "sessioninfo", path = get_relpath(sessioninfo_path), kind = "sessioninfo"),
      manifest_path
    )
    invisible(sessioninfo_path)
  }
}

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  # Old manifests may have parsed timestamp as datetime; normalize to character.
  if (file.exists(manifest_path)) {
    old_manifest <- suppressMessages(readr::read_csv(manifest_path, show_col_types = FALSE))
    if ("timestamp" %in% names(old_manifest) && !is.character(old_manifest$timestamp)) {
      old_manifest$timestamp <- as.character(old_manifest$timestamp)
      readr::write_csv(old_manifest, manifest_path)
    }
  }
  append_manifest(
    manifest_row(script = script_label, label = label, path = get_relpath(path), kind = kind, n = n, notes = notes),
    manifest_path
  )
}

write_agg_csv <- function(df, filename, label = filename, notes = NA_character_) {
  out_path <- file.path(outputs_dir, filename)
  readr::write_csv(df, out_path)
  append_artifact(label = label, kind = "table_csv", path = out_path, n = nrow(df), notes = notes)
  out_path
}

write_agg_txt <- function(lines, filename, label = filename, notes = NA_character_) {
  out_path <- file.path(outputs_dir, filename)
  writeLines(lines, out_path)
  append_artifact(label = label, kind = "text", path = out_path, n = length(lines), notes = notes)
  out_path
}

write_agg_md <- function(lines, filename, label = filename, notes = NA_character_) {
  out_path <- file.path(outputs_dir, filename)
  writeLines(lines, out_path)
  append_artifact(label = label, kind = "text_md", path = out_path, n = length(lines), notes = notes)
  out_path
}

write_manifest_diag <- function(run_id, label_suffix, prefer_renv = TRUE) {
  diag_path <- file.path("manifest", paste0(label_suffix, "_", run_id, ".txt"))
  dir.create(dirname(diag_path), recursive = TRUE, showWarnings = FALSE)

  diag_lines <- if (prefer_renv && requireNamespace("renv", quietly = TRUE)) {
    capture.output(renv::diagnostics())
  } else {
    capture.output(sessionInfo())
  }

  writeLines(diag_lines, diag_path)
  append_artifact(
    label = label_suffix,
    kind = "diagnostic",
    path = diag_path,
    n = length(diag_lines),
    notes = "K40 appendix export diagnostics saved under manifest/"
  )
  diag_path
}

md5_file <- function(path) unname(tools::md5sum(path))

clean_names_simple <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  make.unique(x, sep = "_")
}

# --- DATA_ROOT resolution (same logic as k40.r; do not print abs paths) ---------------
infer_data_root <- function() {
  from_env <- Sys.getenv("DATA_ROOT", "")
  if (nzchar(from_env)) return(from_env)

  env_path <- file.path(subproject_root, "config", ".env")
  if (file.exists(env_path)) {
    env_lines <- readLines(env_path, warn = FALSE)
    hit <- grep("^DATA_ROOT\\s*=", env_lines, value = TRUE)
    if (length(hit) > 0) {
      value <- sub("^DATA_ROOT\\s*=\\s*", "", hit[[1]])
      value <- gsub('^"|"$', "", value)
      value <- gsub("^'|'$", "", value)
      if (nzchar(value)) return(value)
    }
  }

  stop(
    "DATA_ROOT is required but missing. Set DATA_ROOT env var or config/.env DATA_ROOT=...",
    call. = FALSE
  )
}

find_col <- function(nms, candidates) {
  hit <- intersect(candidates, nms)
  if (length(hit) == 0) return(NA_character_)
  hit[[1]]
}

resolve_id_column <- function(df) {
  # Explicit override wins; support raw and cleaned names deterministically.
  id_override_raw <- Sys.getenv("ID_COL", "")
  if (nzchar(id_override_raw)) {
    id_override_clean <- clean_names_simple(id_override_raw)
    if (id_override_clean %in% names(df)) {
      return(list(col = id_override_clean, method = "env_override"))
    }
    stop(sprintf("ID_COL override '%s' not found after name cleaning.", id_override_raw), call. = FALSE)
  }

  id_named <- find_col(names(df), c("id", "participant_id", "subject_id", "study_id", "nro", "jnro"))
  if (!is.na(id_named)) {
    return(list(col = id_named, method = "name_match"))
  }

  n <- nrow(df)
  if (n == 0) stop("Could not resolve id column: no rows available for deterministic inference.", call. = FALSE)

  profile <- lapply(names(df), function(vn) {
    x <- df[[vn]]
    type_ok <- is.character(x) || is.integer(x) || is.numeric(x)
    n_miss <- sum(is.na(x))
    miss_rate <- n_miss / n
    uniq_ratio <- if (n > 0) dplyr::n_distinct(x[!is.na(x)]) / n else NA_real_
    tibble(
      var_name = vn,
      type_ok = type_ok,
      miss_rate = miss_rate,
      uniq_ratio = uniq_ratio
    )
  }) %>% bind_rows()

  eligible <- profile %>%
    filter(type_ok, miss_rate <= 0.05, uniq_ratio >= 0.90) %>%
    arrange(desc(uniq_ratio), miss_rate, var_name)

  if (nrow(eligible) == 0) {
    stop("Could not resolve id column (no deterministic fallback candidate). Set ID_COL explicitly.", call. = FALSE)
  }

  if (nrow(eligible) > 1 && !is.na(eligible$uniq_ratio[2]) &&
      abs(eligible$uniq_ratio[1] - eligible$uniq_ratio[2]) < 0.01) {
    stop("Could not resolve id column (top fallback candidates too close). Set ID_COL explicitly.", call. = FALSE)
  }

  list(col = eligible$var_name[[1]], method = "deterministic_fallback")
}

coerce_numeric <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  if (is.logical(x)) return(as.numeric(x))
  if (is.factor(x)) return(as.numeric(x))
  if (is.character(x)) {
    out <- suppressWarnings(as.numeric(x))
    if (sum(!is.na(out)) >= floor(0.7 * length(out[!is.na(x)]))) return(out)
    return(as.numeric(factor(x)))
  }
  suppressWarnings(as.numeric(x))
}

infer_type <- function(x) {
  nn <- x[!is.na(x)]
  nlev <- length(unique(nn))
  if (nlev <= 1) return("constant")
  if (nlev == 2) return("binary")
  if (is.factor(x) || is.character(x)) {
    # If character/factor is mostly numeric-like, treat it as numeric for FI typing.
    xn <- suppressWarnings(as.numeric(as.character(x)))
    n_nonmissing <- sum(!is.na(x))
    n_numeric <- sum(!is.na(xn))
    if (n_nonmissing > 0 && n_numeric >= floor(0.8 * n_nonmissing)) {
      xnn <- xn[!is.na(xn)]
      nlev_num <- length(unique(xnn))
      if (nlev_num <= 1) return("constant")
      if (nlev_num == 2) return("binary")
      if (all(abs(xnn - round(xnn)) < 1e-9) && nlev_num <= 10) return("ordinal")
      return("continuous")
    }
    if (nlev <= 10) return("ordinal")
    return("categorical")
  }
  if (is.numeric(x)) {
    if (all(abs(nn - round(nn)) < 1e-9) && nlev <= 10) return("ordinal")
    return("continuous")
  }
  "other"
}

mode_top_levels <- function(x, k = 3) {
  x <- x[!is.na(x)]
  if (length(x) == 0) return(NA_character_)
  tb <- sort(table(as.character(x)), decreasing = TRUE)
  top <- head(tb, k)
  paste(paste0(names(top), ":", as.integer(top)), collapse = " | ")
}

safe_cor <- function(x, y) {
  ok <- !is.na(x) & !is.na(y)
  if (sum(ok) < 10) return(NA_real_)
  suppressWarnings(cor(x[ok], y[ok]))
}

# Direction harmonization: deterministic and codebook/script-lineage only.
reverse_coded_by_lineage <- c(
  "self_rated_health", "energy_score", "quality_of_life", "general_health"
)

base_continuous_thresholds <- list(
  # FI_v5 deterministic non-performance continuous deficits (source var ids from KAAOS labels).
  # 15 = BMI (kg/m^2), 38 = TK: VAS (cm; 0-10 scale in label context)
  "15" = list(cutoff = c(18.5, 30.0), direction = "outside_range"),
  "38" = list(cutoff = 7.0, direction = "higher_worse")
)
continuous_thresholds <- base_continuous_thresholds
fi_variant <- "FI22_nonperformance_KAAOS"
fi_variant_role <- "sensitivity_index"

# --- Deterministic FI configuration ---------------------------------------------------
pmiss_thr_primary <- 0.20
pmiss_thr_sensitivity <- 0.30
try_sensitivity_if_selected_lt <- 30L
prev_min <- 0.01
prev_max <- 0.80
target_n_deficits <- 40L
max_per_domain <- 12L
coverage_min <- 0.60
N_deficits_min <- 10L
use_proportional_min_deficits <- FALSE
min_deficits_prop <- 0.80
run_optional_diagnostics <- TRUE
scrub_label_contamination_enabled <- TRUE
scrub_label_max_share <- 0.01
exclude_falls_by_label <- TRUE

# Filled after sheet read; used by exclusion/domain/priority helpers.
var_labels <- list()
# Note: In Fear-of-Falling context, deficit_map might be in a different location
# Adjusting to relative search or standard location if possible.
deficit_map_path <- "deficit_map.csv"
deficit_map_loaded <- FALSE
deficit_map_rows <- 0L
map_missing_codes_applied_n <- 0L
mapped_type_overrides_n <- 0L
mapped_exclusions_n <- 0L
deficit_map <- tibble(
  var_name = character(),
  keep = character(),
  keep_bool = logical(),
  domain = character(),
  type = character(),
  direction = character(),
  cutoff = numeric(),
  cutoff_low = numeric(),
  cutoff_high = numeric(),
  priority = integer(),
  missing_codes = character(),
  exclude_reason = character(),
  notes = character()
)

parse_keep_bool <- function(x) {
  xc <- tolower(trimws(as.character(x)))
  xc %in% c("1", "true", "yes", "y", "keep")
}

normalize_token <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x <- gsub("[^a-z0-9]+", "_", x)
  x <- gsub("_+", "_", x)
  x <- gsub("^_|_$", "", x)
  x
}

read_deficit_map <- function(path) {
  if (!file.exists(path)) return(deficit_map)

  dm <- suppressMessages(readr::read_csv(
    path,
    show_col_types = FALSE,
    col_types = readr::cols(
      .default = readr::col_character(),
      cutoff = readr::col_double(),
      cutoff_low = readr::col_double(),
      cutoff_high = readr::col_double(),
      priority = readr::col_integer()
    )
  ))

  required_cols <- c("var_name", "keep")
  if (!all(required_cols %in% names(dm))) {
    stop("deficit_map.csv must include columns: var_name, keep", call. = FALSE)
  }

  for (cn in c("domain", "type", "direction", "cutoff", "cutoff_low", "cutoff_high", "priority", "missing_codes", "exclude_reason", "notes")) {
    if (!(cn %in% names(dm))) dm[[cn]] <- NA
  }

  dm <- dm %>%
    mutate(
      var_name = normalize_token(var_name),
      keep_bool = parse_keep_bool(keep),
      domain = normalize_token(domain),
      type = tolower(trimws(type)),
      direction = tolower(trimws(direction)),
      missing_codes = trimws(missing_codes),
      exclude_reason = trimws(exclude_reason),
      notes = trimws(notes)
    ) %>%
    select(var_name, keep, keep_bool, domain, type, direction, cutoff, cutoff_low, cutoff_high, priority, missing_codes, exclude_reason, notes)

  if (anyDuplicated(dm$var_name) > 0) {
    stop("deficit_map.csv has duplicate var_name entries; keep unique rows only.", call. = FALSE)
  }

  dm
}

map_row <- function(var_name) {
  if (nrow(deficit_map) == 0) return(NULL)
  hit <- deficit_map[deficit_map$var_name == var_name, , drop = FALSE]
  if (nrow(hit) == 0) return(NULL)
  hit
}

map_type <- function(var_name, inferred_type) {
  mr <- map_row(var_name)
  if (is.null(mr)) return(inferred_type)
  if (!is.na(mr$type[[1]]) && nzchar(mr$type[[1]]) && mr$type[[1]] %in% c("binary", "ordinal", "continuous")) {
    return(mr$type[[1]])
  }
  inferred_type
}

thresholds_from_map <- function(dm, valid_vars) {
  out <- list()
  if (nrow(dm) == 0) return(out)

  rows <- dm %>%
    filter(keep_bool, type == "continuous", var_name %in% valid_vars)

  if (nrow(rows) == 0) return(out)

  for (i in seq_len(nrow(rows))) {
    vn <- rows$var_name[[i]]
    dir <- rows$direction[[i]]

    if (!(dir %in% c("lower_worse", "higher_worse", "outside_range"))) {
      stop(sprintf("deficit_map.csv continuous row '%s' has invalid direction '%s'.", vn, dir), call. = FALSE)
    }

    if (dir == "outside_range") {
      lo <- rows$cutoff_low[[i]]
      hi <- rows$cutoff_high[[i]]
      if (is.na(lo) || is.na(hi)) {
        stop(sprintf("deficit_map.csv row '%s' requires cutoff_low and cutoff_high for outside_range.", vn), call. = FALSE)
      }
      out[[vn]] <- list(cutoff = c(lo, hi), direction = dir)
    } else {
      co <- rows$cutoff[[i]]
      if (is.na(co)) {
        stop(sprintf("deficit_map.csv row '%s' requires cutoff for %s.", vn, dir), call. = FALSE)
      }
      out[[vn]] <- list(cutoff = co, direction = dir)
    }
  }
  out
}

parse_missing_codes <- function(x) {
  if (is.na(x) || !nzchar(x)) return(character())
  parts <- unlist(strsplit(x, "\\|", fixed = FALSE))
  parts <- trimws(parts)
  unique(parts[nzchar(parts)])
}

standardize_columns <- function(df) {
  names(df) <- clean_names_simple(names(df))
  df
}

detect_var_id_col <- function(df) {
  preferred <- c("var_name", "variable_id", "item_id", "item", "variable", "id")
  hit <- intersect(preferred, names(df))
  if (length(hit) > 0) return(hit[[1]])

  chr_cols <- names(df)[vapply(df, function(x) is.character(x) || is.factor(x), logical(1))]
  if (length(chr_cols) == 0) {
    stop("Appendix export could not detect an item-id column.", call. = FALSE)
  }

  scores <- vapply(chr_cols, function(vn) {
    x <- trimws(as.character(df[[vn]]))
    x <- x[!is.na(x) & nzchar(x)]
    if (length(x) == 0) return(-1)
    numeric_like <- mean(grepl("^[A-Za-z0-9._-]+$", x))
    unique_n <- length(unique(x))
    as.numeric(numeric_like * 1000 + unique_n)
  }, numeric(1))

  chr_cols[[order(scores, decreasing = TRUE)[1]]]
}

compose_scoring_rule <- function(item_type, direction, cutoff, cutoff_low, cutoff_high) {
  item_type <- tolower(trimws(as.character(item_type)))
  direction <- tolower(trimws(as.character(direction)))

  if (item_type == "binary") {
    if (direction == "higher_worse") return("Binary item: deficit = 1 for worse/present response, else 0.")
    if (direction == "lower_worse") return("Binary item: lower/absent-coded response is treated as worse in current mapping.")
    return("Binary item: scored as coded by the current mapping.")
  }

  if (item_type == "ordinal") {
    if (direction == "higher_worse") return("Ordinal item: higher response levels are worse; scores are scaled to 0-1 by ordered levels.")
    if (direction == "lower_worse") return("Ordinal item: lower response levels are worse; scores are scaled to 0-1 by ordered levels.")
    return("Ordinal item: scored from ordered levels on a 0-1 scale using current coding.")
  }

  if (item_type == "continuous") {
    if (direction == "outside_range" && !is.na(cutoff_low) && !is.na(cutoff_high)) {
      return(sprintf("Continuous item: deficit = 1 outside [%s, %s), else 0.", cutoff_low, cutoff_high))
    }
    if (direction == "higher_worse" && !is.na(cutoff)) {
      return(sprintf("Continuous item: deficit = 1 when value >= %s, else 0.", cutoff))
    }
    if (direction == "lower_worse" && !is.na(cutoff)) {
      return(sprintf("Continuous item: deficit = 1 when value <= %s, else 0.", cutoff))
    }
    return("Continuous item: mapping row exists but threshold details are incomplete.")
  }

  "Scoring rule unavailable from current mapping."
}

escape_md_cell <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- gsub("\\|", "\\\\|", x)
  x
}

appendix_markdown_lines <- function(tbl, title, sources, caveat) {
  header <- paste0("# ", title)
  meta <- c(
    "",
    paste0("Sources: ", paste(sources, collapse = "; ")),
    paste0("Ordinal caveat: ", caveat),
    ""
  )

  cols <- names(tbl)
  md_header <- paste0("| ", paste(cols, collapse = " | "), " |")
  md_sep <- paste0("| ", paste(rep("---", length(cols)), collapse = " | "), " |")
  md_rows <- apply(tbl, 1, function(row) {
    paste0("| ", paste(escape_md_cell(row), collapse = " | "), " |")
  })

  c(header, meta, md_header, md_sep, md_rows)
}

resolve_appendix_map <- function(deficit_map_df, map_source_path) {
  if (nrow(deficit_map_df) > 0) {
    return(list(df = standardize_columns(deficit_map_df), path = map_source_path))
  }

  candidates <- unique(c(
    map_source_path,
    "deficit_map.csv",
    "Fear-of-Falling/deficit_map.csv",
    "../Quantify-FOF-Utilization-Costs/R/40_FI/deficit_map.csv",
    "Quantify-FOF-Utilization-Costs/R/40_FI/deficit_map.csv",
    "../Quantify-FOF-Utilization-Costs/deficit_map.csv"
  ))

  for (candidate in candidates) {
    if (is.na(candidate) || !nzchar(candidate) || !file.exists(candidate)) next
    dm <- read_deficit_map(candidate)
    if (nrow(dm) > 0) {
      return(list(df = standardize_columns(dm), path = candidate))
    }
  }

  list(df = standardize_columns(deficit_map_df), path = map_source_path)
}

build_appendix_export <- function(deficit_map_df, selected_path, outputs_dir, map_source_path) {
  selected_source <- "keep_fallback"
  selected_ids <- character()
  if (!is.null(selected_path) && file.exists(selected_path)) {
    selected_tbl <- suppressMessages(readr::read_csv(selected_path, show_col_types = FALSE))
    selected_tbl <- standardize_columns(selected_tbl)
    selected_col <- detect_var_id_col(selected_tbl)
    selected_ids <- trimws(as.character(selected_tbl[[selected_col]]))
    selected_ids <- selected_ids[!is.na(selected_ids) & nzchar(selected_ids)]
    if (length(selected_ids) > 0) {
      selected_source <- "selected_deficits"
    }
  }

  resolved_map <- resolve_appendix_map(deficit_map_df, map_source_path)
  dm <- resolved_map$df
  item_col <- detect_var_id_col(dm)
  dm[[item_col]] <- trimws(as.character(dm[[item_col]]))

  if (length(selected_ids) > 0) {
    appendix_df <- dm %>%
      mutate(selection_order = match(.data[[item_col]], selected_ids)) %>%
      filter(!is.na(selection_order)) %>%
      arrange(selection_order, priority, .data[[item_col]])
  } else {
    appendix_df <- dm %>%
      filter(isTRUE(keep_bool)) %>%
      arrange(priority, .data[[item_col]])
  }

  appendix_df <- appendix_df %>%
    mutate(
      item_id = .data[[item_col]],
      label = vapply(item_id, function(vn) {
        lbl <- var_labels[[vn]]
        if (!is.null(lbl) && nzchar(trimws(as.character(lbl)))) return(trimws(as.character(lbl)))
        note <- notes[match(vn, item_id)]
        if (!is.na(note) && nzchar(trimws(note))) return(trimws(note))
        vn
      }, character(1)),
      domain = ifelse(is.na(domain) | !nzchar(domain), NA_character_, domain),
      item_type = ifelse(is.na(type) | !nzchar(type), NA_character_, type),
      direction = ifelse(is.na(direction) | !nzchar(direction), NA_character_, direction),
      scoring_rule = vapply(
        seq_len(n()),
        function(i) compose_scoring_rule(item_type[[i]], direction[[i]], cutoff[[i]], cutoff_low[[i]], cutoff_high[[i]]),
        character(1)
      ),
      missing_codes = ifelse(is.na(missing_codes) | !nzchar(missing_codes), NA_character_, missing_codes),
      priority = ifelse(is.na(priority), NA_integer_, as.integer(priority)),
      selection_source = selected_source
    ) %>%
    transmute(
      item_id,
      label,
      domain,
      item_type,
      direction,
      scoring_rule,
      missing_codes,
      priority,
      notes
    )

  csv_path <- file.path(outputs_dir, "k40_fi22_appendix_deficit_definitions.csv")
  md_path <- file.path(outputs_dir, "k40_fi22_appendix_deficit_definitions.md")
  readr::write_csv(appendix_df, csv_path)

  md_lines <- appendix_markdown_lines(
    appendix_df,
    title = "Frailty Index deficit definitions and scoring rules",
    sources = c(
      paste0("mapping=", resolved_map$path),
      paste0("selector=", if (!is.null(selected_path) && file.exists(selected_path)) basename(selected_path) else "keep==1 fallback"),
      paste0("selection_mode=", selected_source)
    ),
    caveat = "Some ordinal items may still need manuscript-facing verbal level descriptions if source labels do not encode them."
  )
  writeLines(md_lines, md_path)

  list(
    table = appendix_df,
    csv_path = csv_path,
    md_path = md_path,
    selection_source = selected_source,
    map_source_path = resolved_map$path,
    ordinal_caveat = "Some ordinal items may still need manuscript-facing verbal level descriptions if source labels do not encode them."
  )
}

apply_missing_codes_from_map <- function(df, dm) {
  if (nrow(dm) == 0) return(list(df = df, n_replaced = 0L))
  replaced <- 0L

  rows <- dm %>% filter(var_name %in% names(df), !is.na(missing_codes), nzchar(missing_codes))
  if (nrow(rows) == 0) return(list(df = df, n_replaced = 0L))

  for (i in seq_len(nrow(rows))) {
    vn <- rows$var_name[[i]]
    miss_codes <- parse_missing_codes(rows$missing_codes[[i]])
    if (length(miss_codes) == 0) next

    x_chr <- trimws(as.character(df[[vn]]))
    hit <- !is.na(x_chr) & x_chr %in% miss_codes
    if (any(hit)) {
      df[[vn]][hit] <- NA
      replaced <- replaced + sum(hit)
    }
  }

  list(df = df, n_replaced = as.integer(replaced))
}

detect_label_row <- function(df, id_col) {
  if (nrow(df) == 0 || is.na(id_col) || !(id_col %in% names(df))) {
    return(list(detected = FALSE, id_token = NA_character_, labelish_hits = 0L))
  }

  first_row <- df[1, , drop = FALSE]
  id_token <- tolower(trimws(as.character(first_row[[id_col]][1])))
  id_ok <- id_token %in% c("nro", "id", "participant", "participant_id", "subject", "subject_id")

  other_cols <- setdiff(names(df), id_col)
  other_vals <- trimws(as.character(first_row[1, other_cols, drop = TRUE]))
  labelish_hits <- sum(
    !is.na(other_vals) &
      (
        nchar(other_vals) >= 20 |
        grepl("0\\s*=|1\\s*=|2\\s*=", other_vals, perl = TRUE)
      )
  )

  list(detected = isTRUE(id_ok && labelish_hits >= 2), id_token = id_token, labelish_hits = as.integer(labelish_hits))
}

capture_var_labels <- function(df_row) {
  out <- list()
  for (vn in names(df_row)) {
    val <- trimws(as.character(df_row[[vn]][1]))
    if (!is.na(val) && nzchar(val)) out[[vn]] <- val
  }
  out
}

scrub_label_contamination <- function(df, labels, enabled = TRUE, max_share = 0.01) {
  if (!enabled || length(labels) == 0) return(list(df = df, n_replaced = 0L))

  n_replaced <- 0L
  for (vn in names(labels)) {
    if (!(vn %in% names(df))) next
    lbl <- trimws(as.character(labels[[vn]]))
    if (!nzchar(lbl)) next
    x <- as.character(df[[vn]])
    hit <- !is.na(x) & trimws(x) == lbl
    share <- if (length(x) > 0) mean(hit) else 0
    if (share > 0 && share <= max_share) {
      df[[vn]][hit] <- NA
      n_replaced <- n_replaced + sum(hit)
    }
  }

  list(df = df, n_replaced = n_replaced)
}

recode_sentinel_missing <- function(x) {
  # KAAOS uses E/E1 style sentinels for unknown/non-assessable values.
  if (!(is.character(x) || is.factor(x))) return(x)
  xc <- trimws(as.character(x))
  xc[xc %in% c("E", "E1", "e", "e1")] <- NA_character_
  xc
}

var_label <- function(vn) {
  lbl <- var_labels[[vn]]
  if (is.null(lbl) || !nzchar(trimws(lbl))) return(vn)
  tolower(trimws(as.character(lbl)))
}

score_binary_safe <- function(x) {
  if (is.logical(x)) return(ifelse(is.na(x), NA_real_, ifelse(x, 1, 0)))

  xn <- suppressWarnings(as.numeric(as.character(x)))
  if (sum(!is.na(xn)) >= floor(0.8 * sum(!is.na(x)))) {
    vals <- sort(unique(xn[!is.na(xn)]))
    if (length(vals) != 2) return(rep(NA_real_, length(x)))
    if (all(vals %in% c(0, 1))) return(ifelse(is.na(xn), NA_real_, xn))
    if (all(vals %in% c(1, 2))) return(ifelse(is.na(xn), NA_real_, ifelse(xn == 2, 1, 0)))
    return(rep(NA_real_, length(x)))
  }

  xc <- tolower(trimws(as.character(x)))
  yes <- c("yes", "y", "kylla", "kyl", "1", "true")
  no <- c("no", "n", "ei", "0", "false")
  if (all(na.omit(unique(xc)) %in% c(yes, no))) {
    return(ifelse(is.na(xc), NA_real_, ifelse(xc %in% yes, 1, 0)))
  }

  rep(NA_real_, length(x))
}

ordinal_to_0_1 <- function(x) {
  xn <- suppressWarnings(as.numeric(as.character(x)))
  ok_num <- sum(!is.na(xn)) >= floor(0.8 * sum(!is.na(x)))
  if (ok_num) {
    vals <- sort(unique(xn[!is.na(xn)]))
    if (length(vals) < 3) return(rep(NA_real_, length(x)))
    pos <- match(xn, vals)
    out <- (pos - 1) / (length(vals) - 1)
    out[is.na(x)] <- NA_real_
    return(out)
  }

  xf <- factor(as.character(x))
  levs <- levels(xf)
  if (length(levs) < 3) return(rep(NA_real_, length(x)))
  out <- (as.numeric(xf) - 1) / (length(levs) - 1)
  out[is.na(x)] <- NA_real_
  attr(out, "ordinal_ordering") <- "alphabetical_fallback_NEEDS_REVIEW"
  out
}

score_deficit <- function(x, var_name, var_type) {
  reverse_dir <- var_name %in% reverse_coded_by_lineage
  mr <- map_row(var_name)
  map_direction <- if (!is.null(mr) && !is.na(mr$direction[[1]]) && nzchar(mr$direction[[1]])) mr$direction[[1]] else "as_coded"

  if (var_type == "binary") {
    if (map_direction == "higher_worse") {
      xn <- suppressWarnings(as.numeric(as.character(x)))
      if (sum(!is.na(xn)) > 0) {
        out <- ifelse(is.na(xn), NA_real_, ifelse(xn > 0, 1, 0))
      } else {
        out <- score_binary_safe(x)
      }
    } else {
      out <- score_binary_safe(x)
    }
    if (reverse_dir) out <- ifelse(is.na(out), NA_real_, 1 - out)
    return(out)
  }

  if (var_type == "ordinal") {
    out <- ordinal_to_0_1(x)
    if (reverse_dir) out <- ifelse(is.na(out), NA_real_, 1 - out)
    return(out)
  }

  if (var_type == "continuous") {
    rule <- continuous_thresholds[[var_name]]
    if (is.null(rule)) return(rep(NA_real_, length(x)))
    xn <- coerce_numeric(x)
    if (rule$direction == "lower_worse") return(ifelse(is.na(xn), NA_real_, ifelse(xn <= rule$cutoff, 1, 0)))
    if (rule$direction == "higher_worse") return(ifelse(is.na(xn), NA_real_, ifelse(xn >= rule$cutoff, 1, 0)))
    if (rule$direction == "outside_range" && length(rule$cutoff) == 2) {
      lo <- min(rule$cutoff)
      hi <- max(rule$cutoff)
      return(ifelse(is.na(xn), NA_real_, ifelse(xn < lo | xn >= hi, 1, 0)))
    }
    return(rep(NA_real_, length(x)))
  }

  rep(NA_real_, length(x))
}

domain_label <- function(var_name) {
  mr <- map_row(var_name)
  if (!is.null(mr) && !is.na(mr$domain[[1]]) && nzchar(mr$domain[[1]])) return(mr$domain[[1]])
  key <- paste(var_name, var_label(var_name))
  if (grepl("comorb|diag|disease|icd|sairaus", key, ignore.case = TRUE)) return("comorbidity")
  if (grepl("adl|iadl|toimintakyky|limitation|difficulty|rajoit", key, ignore.case = TRUE)) return("functional")
  if (grepl("fatigue|exhaust|uup|weight|appetite|pain|symptom|self_rated|energy", key, ignore.case = TRUE)) return("symptom")
  if (grepl("med|drug|rx|laake|medication", key, ignore.case = TRUE)) return("medication_proxy")
  paste0("other_", substr(clean_names_simple(var_label(var_name)), 1, 20))
}

priority_rank <- function(var_name) {
  mr <- map_row(var_name)
  if (!is.null(mr) && !is.na(mr$priority[[1]])) return(as.integer(mr$priority[[1]]))
  key <- paste(var_name, var_label(var_name))
  if (grepl("diag|doctor|icd|disease|sairaus|comorb", key, ignore.case = TRUE)) return(1L)
  if (grepl("adl|iadl|toimintakyky|limitation|difficulty|rajoit", key, ignore.case = TRUE)) return(2L)
  if (grepl("symptom|fatigue|exhaust|uup|weight|appetite|pain|self_rated|energy", key, ignore.case = TRUE)) return(3L)
  if (grepl("med|drug|rx|laake|medication", key, ignore.case = TRUE)) return(4L)
  5L
}

# -----------------------------------------------------------------------------
# 1) Read KAAOS raw xlsx (ONLY source) and build base_df (baseline 1 row / id)
# -----------------------------------------------------------------------------
xlsx_rel <- file.path("paper_02", "KAAOS_data.xlsx")
xlsx_path <- file.path(data_root, xlsx_rel)

if (!file.exists(xlsx_path)) {
  stop("Required raw input is missing under DATA_ROOT: paper_02/KAAOS_data.xlsx", call. = FALSE)
}

sheets <- readxl::excel_sheets(xlsx_path)
if (length(sheets) == 0) stop("No sheets found in KAAOS_data.xlsx", call. = FALSE)

# Deterministic sheet selection: prefer common names, else first.
pref_pat <- "(data|baseline|kaaos|sheet1|1)"
hits <- sheets[grepl(pref_pat, sheets, ignore.case = TRUE)]
sheet_use <- if (length(hits) > 0) sort(hits)[[1]] else sheets[[1]]

base_df <- readxl::read_excel(xlsx_path, sheet = sheet_use, guess_max = 5000)
base_df <- tibble::as_tibble(base_df)
names(base_df) <- clean_names_simple(names(base_df))

id_resolved <- resolve_id_column(base_df)
id_col <- id_resolved$col
id_resolution_method <- id_resolved$method

label_row_info <- detect_label_row(base_df, id_col)
label_row_detected <- label_row_info$detected
label_row_removed <- FALSE
if (label_row_detected && nrow(base_df) >= 1) {
  var_labels <- capture_var_labels(base_df[1, , drop = FALSE])
  base_df <- base_df[-1, , drop = FALSE]
  label_row_removed <- TRUE
} else {
  var_labels <- list()
}
n_labels_captured <- length(var_labels)
var_labels_df <- if (n_labels_captured > 0) {
  tibble(var_name = names(var_labels), label = unlist(var_labels, use.names = FALSE))
} else {
  tibble(var_name = character(), label = character())
}
write_agg_csv(var_labels_df, "k40_kaaos_var_labels.csv", notes = "Captured label row mapping (aggregate metadata)")

scrub_res <- scrub_label_contamination(
  base_df,
  labels = var_labels,
  enabled = scrub_label_contamination_enabled,
  max_share = scrub_label_max_share
)
base_df <- scrub_res$df
scrub_values_replaced <- scrub_res$n_replaced

# If long, keep baseline deterministically (baseline/bl/0/0m/m0/t0).
time_col <- find_col(names(base_df), c("time", "timepoint", "visit", "aika"))
baseline_rule_used <- FALSE
if (!is.na(time_col)) {
  tvals <- tolower(as.character(base_df[[time_col]]))
  base_levels <- c("baseline", "bl", "0", "0m", "m0", "t0")
  if (any(tvals %in% base_levels, na.rm = TRUE)) {
    base_df <- base_df[tvals %in% base_levels, , drop = FALSE]
    baseline_rule_used <- TRUE
  }
}

base_df <- base_df %>%
  arrange(.data[[id_col]]) %>%
  group_by(.data[[id_col]]) %>%
  slice(1L) %>%
  ungroup()

# Recode known sentinel codes before inventory/type inference.
base_df <- base_df %>% mutate(across(everything(), recode_sentinel_missing))

# Search for deficit_map.csv in multiple locations if not found in root
if (!file.exists(deficit_map_path)) {
  candidates <- c("deficit_map.csv", "Fear-of-Falling/deficit_map.csv", "Quantify-FOF-Utilization-Costs/deficit_map.csv")
  for (c in candidates) {
    if (file.exists(c)) {
      deficit_map_path <- c
      break
    }
  }
}

deficit_map <- read_deficit_map(deficit_map_path)
if (nrow(deficit_map) > 0) {
  deficit_map <- deficit_map %>% filter(var_name %in% names(base_df))
  deficit_map_rows <- nrow(deficit_map)
  continuous_thresholds <- modifyList(base_continuous_thresholds, thresholds_from_map(deficit_map, names(base_df)))
  deficit_map_loaded <- TRUE
} else {
  deficit_map_rows <- 0L
}
write_agg_csv(
  deficit_map,
  "k40_kaaos_deficit_map_applied.csv",
  notes = "Optional deficit map rows that matched current data columns"
)

map_missing_res <- apply_missing_codes_from_map(base_df, deficit_map)
base_df <- map_missing_res$df
map_missing_codes_applied_n <- map_missing_res$n_replaced

# -----------------------------------------------------------------------------
# 2) Candidate inventory and exclusions (same deterministic rules as k40.r)
# -----------------------------------------------------------------------------
perf_regex <- "puristus|grip|kavely|kävely|velynopeus|gait|10\\s*m|10m|tug|timed|tuoli|chair|seisom|single_leg|balance|sls"
exposure_regex <- "^fof_status($|_)|^kaatumisen[_\\s]*pelko|^tasapainovaikeus($|_)"
outcome_regex <- "^composite_z|toimintakykysummary|delta_composite_z"
derived_construct_regex <- "^frailty_|^frailty_index|^fi$|^fi_z$"
admin_regex <- "^id$|^time$|^visit$|^aika$|capacity_score"

exclusion_reason <- function(vn) {
  key <- paste(vn, var_label(vn))
  if (grepl(perf_regex, key, ignore.case = TRUE)) return("exclude: performance test (K40 non-performance)")
  if (grepl(exposure_regex, key, ignore.case = TRUE)) return("exclude: primary exposure")
  if (grepl(outcome_regex, key, ignore.case = TRUE)) return("outcome_or_component")
  if (grepl(derived_construct_regex, key, ignore.case = TRUE)) return("derived_frailty_construct")
  if (grepl(admin_regex, key, ignore.case = TRUE)) return("administrative_or_non_deficit")
  if (grepl("age|ikä|sex|gender|sukupuoli", key, ignore.case = TRUE)) return("exclude: demographic non-deficit")
  if (grepl("kaatumisen|fear\\s*of\\s*falling|\\bfof\\b", key, ignore.case = TRUE)) return("exclude: outcome/exposure (FOF)")
  if (isTRUE(exclude_falls_by_label) && grepl("\\bkaatuminen\\b|\\bfalls?\\b", key, ignore.case = TRUE)) return("exclude: falls history (sensitivity-safe)")
  if (grepl("tupak|smok|alkohol|alcohol|liikuntaharr|physical\\s*activity|exercise", key, ignore.case = TRUE)) return("exclude: lifestyle exposure (not a deficit)")
  if (grepl("vanhemp|\\bsiblings?\\b|sisaru", key, ignore.case = TRUE)) return("exclude: non-health/background variable")
  mr <- map_row(vn)
  if (!is.null(mr) && !is.na(mr$keep_bool[[1]]) && !isTRUE(mr$keep_bool[[1]])) {
    if (!is.na(mr$exclude_reason[[1]]) && nzchar(mr$exclude_reason[[1]])) {
      return(paste0("exclude: deficit_map (", mr$exclude_reason[[1]], ")"))
    }
    return("exclude: deficit_map keep=false")
  }
  NA_character_
}

col_inventory <- tibble(
  var_name = names(base_df),
  class = vapply(base_df, function(x) class(x)[1], character(1)),
  n = nrow(base_df),
  n_miss = vapply(base_df, function(x) sum(is.na(x)), integer(1)),
  p_miss = n_miss / pmax(n, 1),
  n_levels = vapply(base_df, function(x) length(unique(x[!is.na(x)])), integer(1))
)
write_agg_csv(col_inventory, "k40_kaaos_column_inventory.csv", notes = "K40 KAAOS full column inventory (aggregate only)")

excluded_vars <- tibble(var_name = names(base_df)) %>%
  mutate(reason = vapply(var_name, exclusion_reason, character(1))) %>%
  filter(!is.na(reason))
mapped_exclusions_n <- sum(grepl("^exclude: deficit_map", excluded_vars$reason))
write_agg_csv(excluded_vars, "k40_kaaos_excluded_vars.csv", notes = "Deterministic hard exclusions (KAAOS)")

candidate_names <- setdiff(names(base_df), excluded_vars$var_name)

candidate_inventory <- lapply(candidate_names, function(vn) {
  x <- base_df[[vn]]
  inferred_type <- infer_type(x)
  vtype <- map_type(vn, inferred_type)
  type_overridden <- !identical(vtype, inferred_type)
  d <- score_deficit(x, vn, vtype)
  prev <- if (vtype == "binary") mean(d == 1, na.rm = TRUE) else NA_real_
  ord_flag <- if (!is.null(attr(d, "ordinal_ordering"))) attr(d, "ordinal_ordering") else NA_character_
  tibble(
    var_name = vn,
    type = vtype,
    type_inferred = inferred_type,
    type_overridden = type_overridden,
    n = length(x),
    n_miss = sum(is.na(x)),
    p_miss = mean(is.na(x)),
    prevalence = prev,
    n_levels = length(unique(x[!is.na(x)])),
    top_levels = mode_top_levels(x),
    direction_rule = ifelse(vn %in% reverse_coded_by_lineage, "reverse_by_codebook_lineage", "as_coded"),
    ordinal_ordering_flag = ord_flag
  )
}) %>% bind_rows()
mapped_type_overrides_n <- sum(candidate_inventory$type_overridden, na.rm = TRUE)
write_agg_csv(candidate_inventory, "k40_kaaos_candidate_inventory.csv", notes = "Candidate inventory after hard exclusions (KAAOS)")

# Numeric candidate diagnostics to support documented continuous cutoff expansion.
numeric_candidates <- lapply(candidate_names, function(vn) {
  x_raw <- base_df[[vn]]
  x_num <- suppressWarnings(as.numeric(as.character(x_raw)))
  n_nonmissing <- sum(!is.na(x_raw))
  n_numeric <- sum(!is.na(x_num))
  p_numeric <- if (n_nonmissing > 0) n_numeric / n_nonmissing else NA_real_
  tibble(
    var_name = vn,
    label = var_label(vn),
    n_nonmissing = n_nonmissing,
    n_numeric = n_numeric,
    p_numeric = p_numeric,
    min = suppressWarnings(min(x_num, na.rm = TRUE)),
    median = suppressWarnings(median(x_num, na.rm = TRUE)),
    p95 = suppressWarnings(as.numeric(quantile(x_num, probs = 0.95, na.rm = TRUE))),
    max = suppressWarnings(max(x_num, na.rm = TRUE))
  )
}) %>% bind_rows() %>%
  mutate(across(c(min, median, p95, max), ~ ifelse(is.infinite(.x), NA_real_, .x))) %>%
  arrange(desc(p_numeric), var_name)
write_agg_csv(numeric_candidates, "k40_kaaos_numeric_candidates.csv", notes = "Numeric candidate diagnostics for continuous cutoff registry")

# -----------------------------------------------------------------------------
# 3) Deterministic screening + sensitivity + redundancy
# -----------------------------------------------------------------------------
eligibility_core <- function(df, miss_thr) {
  df %>%
    mutate(
      miss_ok = p_miss <= miss_thr,
      binary_ok = ifelse(type == "binary", !is.na(prevalence) & prevalence >= prev_min & prevalence <= prev_max, TRUE),
      ordinal_ok = ifelse(type == "ordinal", n_levels >= 3, TRUE),
      continuous_ok = ifelse(type == "continuous", var_name %in% names(continuous_thresholds), TRUE),
      type_ok = type %in% c("binary", "ordinal", "continuous"),
      eligible = miss_ok & binary_ok & ordinal_ok & continuous_ok & type_ok
    )
}

primary_screen <- eligibility_core(candidate_inventory, miss_thr = pmiss_thr_primary)
primary_eligible <- primary_screen %>% filter(eligible)

select_deficits <- function(screen_df) {
  screen_df %>%
    filter(eligible) %>%
    mutate(
      domain = vapply(var_name, domain_label, character(1)),
      priority = vapply(var_name, priority_rank, integer(1))
    ) %>%
    arrange(priority, p_miss, var_name) %>%
    group_by(domain) %>%
    mutate(domain_rank = row_number()) %>%
    ungroup() %>%
    filter(domain_rank <= max_per_domain) %>%
    arrange(priority, p_miss, var_name) %>%
    slice_head(n = target_n_deficits)
}

selected_primary <- select_deficits(primary_screen)
augmentation_used <- nrow(selected_primary) < try_sensitivity_if_selected_lt
use_sensitivity <- augmentation_used
pmiss_thr_used <- if (augmentation_used) pmiss_thr_sensitivity else pmiss_thr_primary

active_screen <- if (augmentation_used) {
  eligibility_core(candidate_inventory, miss_thr = pmiss_thr_sensitivity)
} else {
  primary_screen
}

selected <- select_deficits(active_screen)

map_drop_reasons <- if (nrow(deficit_map) == 0) {
  tibble(
    var_name = character(),
    in_map_keep1 = logical(),
    in_candidate_pool = logical(),
    passes_type_ok = logical(),
    passes_missingness = logical(),
    passes_prevalence = logical(),
    passes_levels = logical(),
    passes_continuous = logical(),
    final_selected = logical(),
    drop_reason = character()
  )
} else {
  keep_vars <- deficit_map %>% filter(keep_bool) %>% pull(var_name)
  tibble(var_name = keep_vars) %>%
    left_join(active_screen %>% select(var_name, type_ok, miss_ok, binary_ok, ordinal_ok, continuous_ok, eligible), by = "var_name") %>%
    mutate(
      in_map_keep1 = TRUE,
      in_candidate_pool = !is.na(type_ok),
      passes_type_ok = ifelse(is.na(type_ok), FALSE, type_ok),
      passes_missingness = ifelse(is.na(miss_ok), FALSE, miss_ok),
      passes_prevalence = ifelse(is.na(binary_ok), FALSE, binary_ok),
      passes_levels = ifelse(is.na(ordinal_ok), FALSE, ordinal_ok),
      passes_continuous = ifelse(is.na(continuous_ok), FALSE, continuous_ok),
      final_selected = var_name %in% selected$var_name,
      drop_reason = case_when(
        final_selected ~ "selected",
        !in_candidate_pool ~ "excluded_or_missing_from_candidate_pool",
        !passes_type_ok ~ "type_not_ok",
        !passes_continuous ~ "continuous_cutoff_missing_or_invalid",
        !passes_missingness ~ "missingness",
        !passes_prevalence ~ "prev_out_of_range_or_binary_not_scored",
        !passes_levels ~ "n_levels_lt_3",
        TRUE ~ "other"
      )
    ) %>%
    arrange(drop_reason, var_name)
}
write_agg_csv(map_drop_reasons, "k40_kaaos_map_drop_reasons.csv", notes = "Drop reasons for deficit_map keep=1 rows")

selected_deficits_path <- write_agg_csv(
  selected %>% select(var_name, type, p_miss, prevalence, domain, priority, direction_rule),
  "k40_kaaos_selected_deficits.csv",
  notes = "Selected deficits after deterministic screening and redundancy rule (KAAOS)"
)

appendix_export <- build_appendix_export(
  deficit_map_df = deficit_map,
  selected_path = selected_deficits_path,
  outputs_dir = outputs_dir,
  map_source_path = deficit_map_path
)
append_artifact(
  label = "k40_fi22_appendix_deficit_definitions",
  kind = "table_csv",
  path = appendix_export$csv_path,
  n = nrow(appendix_export$table),
  notes = "Appendix FI22 deficit definitions reconstructed from deficit_map + selected-deficits"
)
append_artifact(
  label = "k40_fi22_appendix_deficit_definitions",
  kind = "text_md",
  path = appendix_export$md_path,
  n = nrow(appendix_export$table),
  notes = "Markdown appendix FI22 deficit definitions reconstructed from deficit_map + selected-deficits"
)
appendix_diag_path <- write_manifest_diag(
  run_id = run_id,
  label_suffix = "sessionInfo_k40_appendix_fi22_definitions",
  prefer_renv = FALSE
)

write_agg_csv(
  selected %>% select(var_name, type, n_miss, p_miss, prevalence, n_levels),
  "k40_kaaos_deficit_missingness_prevalence.csv",
  notes = "Per-deficit missingness/prevalence (KAAOS)"
)

# -----------------------------------------------------------------------------
# 4) Compute FI (0-1) and FI_z with fixed thresholds
# -----------------------------------------------------------------------------
score_df <- tibble(id = base_df[[id_col]])
for (vn in selected$var_name) {
  vtype <- selected$type[selected$var_name == vn]
  score_df[[paste0("d_", vn)]] <- score_deficit(base_df[[vn]], vn, vtype)
}

deficit_cols <- grep("^d_", names(score_df), value = TRUE)
n_deficits <- length(deficit_cols)
min_deficits_required <- if (use_proportional_min_deficits) {
  max(N_deficits_min, as.integer(ceiling(min_deficits_prop * n_deficits)))
} else {
  N_deficits_min
}

if (n_deficits == 0) {
  score_df$fi <- NA_real_
  score_df$fi_z <- NA_real_
  score_df$n_deficits_observed <- 0L
  score_df$coverage <- NA_real_
  score_df$fi_eligible <- FALSE
} else {
  observed_counts <- rowSums(!is.na(score_df[, deficit_cols, drop = FALSE]))
  coverage <- observed_counts / n_deficits
  fi_raw <- rowMeans(score_df[, deficit_cols, drop = FALSE], na.rm = TRUE)
  fi_raw[!is.finite(fi_raw)] <- NA_real_

  fi_eligible <- coverage >= coverage_min & observed_counts >= min_deficits_required
  fi <- ifelse(fi_eligible, fi_raw, NA_real_)
  fi_z <- as.numeric(scale(fi))

  score_df$n_deficits_observed <- observed_counts
  score_df$coverage <- coverage
  score_df$fi_eligible <- fi_eligible
  score_df$fi <- fi
  score_df$fi_z <- fi_z
}

fi_summary <- tibble(
  metric = c("n_rows", "n_selected_deficits", "n_rows_fi_eligible", "n_rows_fi_na",
             "fi_mean", "fi_sd", "fi_min", "fi_max", "fi_z_mean", "fi_z_sd"),
  value = c(
    nrow(score_df),
    n_deficits,
    sum(score_df$fi_eligible, na.rm = TRUE),
    sum(is.na(score_df$fi)),
    mean(score_df$fi, na.rm = TRUE),
    sd(score_df$fi, na.rm = TRUE),
    suppressWarnings(min(score_df$fi, na.rm = TRUE)),
    suppressWarnings(max(score_df$fi, na.rm = TRUE)),
    mean(score_df$fi_z, na.rm = TRUE),
    sd(score_df$fi_z, na.rm = TRUE)
  )
)
write_agg_csv(fi_summary, "k40_kaaos_fi_distribution_summary.csv", notes = "FI and FI_z aggregate distribution summary (KAAOS)")

if (run_optional_diagnostics && n_deficits > 0) {
  q <- quantile(score_df$fi, probs = c(0.50, 0.75, 0.90, 0.95, 0.99), na.rm = TRUE, names = TRUE)
  ceiling_checks <- tibble(
    metric = c(names(q), "p_over_0_70", "p_over_0_66"),
    value = c(as.numeric(q), mean(score_df$fi > 0.70, na.rm = TRUE), mean(score_df$fi > 0.66, na.rm = TRUE))
  )
  write_agg_csv(ceiling_checks, "k40_kaaos_fi_ceiling_checks.csv", notes = "Ceiling/submaximal checks (aggregated)")

  domain_balance <- selected %>% count(domain, sort = TRUE)
  write_agg_csv(domain_balance, "k40_kaaos_domain_balance.csv", notes = "Selected deficit counts by domain")

  dmat <- score_df[, deficit_cols, drop = FALSE]
  cm <- suppressWarnings(cor(dmat, use = "pairwise.complete.obs"))
  if (is.matrix(cm) && ncol(cm) >= 2) {
    pairs <- which(abs(cm) >= 0.80 & upper.tri(cm), arr.ind = TRUE)
    redund <- if (nrow(pairs) == 0) {
      tibble(var1 = character(), var2 = character(), cor = numeric())
    } else {
      tibble(var1 = colnames(cm)[pairs[, 1]], var2 = colnames(cm)[pairs[, 2]], cor = cm[pairs])
    }
    write_agg_csv(redund, "k40_kaaos_redundancy_cor_pairs_ge_0_80.csv", notes = "Potential redundant deficit pairs (|r|>=0.80)")
  }

  if ("age" %in% names(base_df)) {
    tmp_age <- tibble(age = suppressWarnings(as.numeric(base_df$age)), fi = score_df$fi) %>%
      filter(!is.na(age), !is.na(fi))
    if (nrow(tmp_age) >= 30) {
      fit <- lm(fi ~ age, data = tmp_age)
      age_grad <- tibble(
        metric = c("n", "beta_age", "se_age", "p_age", "r2"),
        value = c(
          nrow(tmp_age),
          coef(summary(fit))["age", "Estimate"],
          coef(summary(fit))["age", "Std. Error"],
          coef(summary(fit))["age", "Pr(>|t|)"],
          summary(fit)$r.squared
        )
      )
      write_agg_csv(age_grad, "k40_kaaos_age_gradient_lm.csv", notes = "FI ~ age (aggregated)")
    }
  }
}

red_flags <- bind_rows(
  tibble(flag = "rows_below_coverage_or_min_deficits",
         value = sum(!score_df$fi_eligible, na.rm = TRUE),
         detail = sprintf("coverage_min=%.2f;N_deficits_min=%d;min_deficits_required=%d", coverage_min, N_deficits_min, min_deficits_required)),
  tibble(flag = "selected_deficits_lt_10",
         value = as.integer(n_deficits < 10),
         detail = sprintf("selected_deficits=%d", n_deficits)),
  tibble(flag = "selected_deficits_lt_30",
         value = as.integer(n_deficits < 30),
         detail = sprintf("selected_deficits=%d", n_deficits)),
  tibble(flag = "used_missingness_sensitivity_pmiss_0_30",
         value = as.integer(use_sensitivity),
         detail = ifelse(use_sensitivity,
                         sprintf("selected_primary_lt_%d", try_sensitivity_if_selected_lt),
                         "primary branch sufficient")),
  tibble(flag = "fi_all_na",
         value = as.integer(all(is.na(score_df$fi))),
         detail = "All rows NA after eligibility gate"),
  tibble(flag = "continuous_thresholds_defined",
         value = length(continuous_thresholds),
         detail = "Count of continuous thresholds available"),
  tibble(flag = "map_missing_codes_applied_n",
         value = map_missing_codes_applied_n,
         detail = "Number of values recoded to NA via deficit_map missing_codes"),
  tibble(flag = "mapped_type_overrides_n",
         value = mapped_type_overrides_n,
         detail = "Number of candidate vars with map type override"),
  tibble(flag = "mapped_exclusions_n",
         value = mapped_exclusions_n,
         detail = "Number of vars excluded by deficit_map keep=false"),
  tibble(flag = "n_selected_deficits_after_map",
         value = n_deficits,
         detail = "Selected deficits count after map adjustments")
)
write_agg_csv(red_flags, "k40_kaaos_red_flags.csv", notes = "Deterministic red flag checks (KAAOS)")

# -----------------------------------------------------------------------------
# 5) Externalize patient-level outputs (DATA_ROOT only) + receipt (no abs paths)
# -----------------------------------------------------------------------------
external_dir <- file.path(data_root, "paper_02", "frailty_vulnerability")
dir.create(external_dir, recursive = TRUE, showWarnings = FALSE)

external_csv <- file.path(external_dir, "kaaos_with_frailty_index_k40.csv")
external_rds <- file.path(external_dir, "kaaos_with_frailty_index_k40.rds")

patient_out <- score_df %>%
  select(id, fi, fi_z, n_deficits_observed, coverage, fi_eligible) %>%
  rename(frailty_index_fi = fi, frailty_index_fi_z = fi_z)

readr::write_csv(patient_out, external_csv)
saveRDS(patient_out, external_rds)

receipt_lines <- c(
  sprintf("timestamp=%s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  sprintf("run_id=%s", run_id),
  sprintf("input_relpath=%s", xlsx_rel),
  sprintf("sheet_selected=%s", sheet_use),
  sprintf("baseline_filter_used=%s", as.character(baseline_rule_used)),
  sprintf("external_dir_rel=%s", file.path("paper_02", "frailty_vulnerability")),
  sprintf("external_csv_name=%s", basename(external_csv)),
  sprintf("external_rds_name=%s", basename(external_rds)),
  sprintf("rows_exported=%d", nrow(patient_out)),
  sprintf("cols_exported=%d", ncol(patient_out)),
  sprintf("md5_csv=%s", md5_file(external_csv)),
  sprintf("md5_rds=%s", md5_file(external_rds)),
  sprintf("n_selected_deficits=%d", n_deficits),
  sprintf("appendix_rows=%d", nrow(appendix_export$table)),
  sprintf("appendix_selection_source=%s", appendix_export$selection_source),
  sprintf("appendix_csv=%s", basename(appendix_export$csv_path)),
  sprintf("appendix_md=%s", basename(appendix_export$md_path)),
  sprintf("appendix_diag=%s", basename(appendix_diag_path)),
  sprintf("fi_variant=%s", fi_variant),
  sprintf("fi_variant_role=%s", fi_variant_role),
  sprintf("coverage_min=%.2f", coverage_min),
  sprintf("N_deficits_min=%d", N_deficits_min),
  sprintf("min_deficits_required=%d", min_deficits_required),
  sprintf("appendix_map_source=%s", appendix_export$map_source_path),
  "appendix_sources=deficit_map.csv + k40_kaaos_selected_deficits.csv (fallback keep==1 if selector missing)",
  sprintf("appendix_ordinal_caveat=%s", appendix_export$ordinal_caveat),
  "governance=patient-level outputs written only under DATA_ROOT"
)
write_agg_txt(receipt_lines, "k40_kaaos_patient_level_output_receipt.txt", notes = "External patient-level output receipt (KAAOS)")

# Decision log (no absolute paths)
log_lines <- c(
  sprintf("timestamp=%s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  sprintf("run_id=%s", run_id),
  sprintf("input_relpath=%s", xlsx_rel),
  sprintf("sheet_selected=%s", sheet_use),
  sprintf("baseline_filter_used=%s", as.character(baseline_rule_used)),
  sprintf("id_col=%s", id_col),
  sprintf("id_resolution_method=%s", id_resolution_method),
  sprintf("label_row_detected=%s", as.character(label_row_detected)),
  sprintf("label_row_removed=%s", as.character(label_row_removed)),
  sprintf("n_labels_captured=%d", n_labels_captured),
  sprintf("scrub_enabled=%s", as.character(scrub_label_contamination_enabled)),
  sprintf("scrub_values_replaced=%d", scrub_values_replaced),
  sprintf("exclude_falls_by_label=%s", as.character(exclude_falls_by_label)),
  sprintf("augmentation_used=%s", as.character(augmentation_used)),
  sprintf("pmiss_thr_used=%.2f", pmiss_thr_used),
  sprintf("try_sensitivity_if_selected_lt=%d", try_sensitivity_if_selected_lt),
  sprintf("helpers_origin=%s", helpers_origin),
  sprintf("deficit_map_path=%s", deficit_map_path),
  sprintf("deficit_map_loaded=%s", as.character(deficit_map_loaded)),
  sprintf("deficit_map_rows=%d", deficit_map_rows),
  sprintf("fi_variant=%s", fi_variant),
  sprintf("fi_variant_role=%s", fi_variant_role),
  sprintf("map_missing_codes_applied_n=%d", map_missing_codes_applied_n),
  sprintf("mapped_type_overrides_n=%d", mapped_type_overrides_n),
  sprintf("mapped_exclusions_n=%d", mapped_exclusions_n),
  sprintf("n_selected_deficits_after_map=%d", n_deficits),
  sprintf("appendix_rows=%d", nrow(appendix_export$table)),
  sprintf("appendix_selection_source=%s", appendix_export$selection_source),
  sprintf("appendix_csv=%s", basename(appendix_export$csv_path)),
  sprintf("appendix_md=%s", basename(appendix_export$md_path)),
  sprintf("appendix_diag=%s", basename(appendix_diag_path)),
  sprintf("primary_missingness_threshold=%.2f", pmiss_thr_primary),
  sprintf("sensitivity_missingness_threshold=%.2f", pmiss_thr_sensitivity),
  sprintf("used_sensitivity=%s", as.character(use_sensitivity)),
  sprintf("eligible_deficits_primary=%d", nrow(primary_eligible)),
  sprintf("selected_deficits=%d", n_deficits),
  sprintf("target_n_deficits=%d", target_n_deficits),
  sprintf("max_per_domain=%d", max_per_domain),
  sprintf("N_deficits_min=%d", N_deficits_min),
  sprintf("min_deficits_required=%d", min_deficits_required),
  sprintf("use_proportional_min_deficits=%s", as.character(use_proportional_min_deficits)),
  sprintf("coverage_min=%.2f", coverage_min),
  sprintf("appendix_map_source=%s", appendix_export$map_source_path),
  "appendix_sources=deficit_map.csv + selected-deficits; fallback keep==1 only when selector file is absent",
  sprintf("appendix_ordinal_caveat=%s", appendix_export$ordinal_caveat),
  "direction_rule=no_correlation_driven_flipping;codebook_or_lineage_only",
  "redundancy_rule=diagnosis>functional_limitation>symptom_self_report>medication_proxy"
)
write_agg_txt(log_lines, "k40_kaaos_decision_log.txt", notes = "Deterministic K40 KAAOS decisions and thresholds")

session_path <- save_sessioninfo_manifest(outputs_dir = outputs_dir, manifest_path = manifest_path, script = script_label)
session_alias <- file.path(outputs_dir, "k40_kaaos_sessioninfo.txt")
file.copy(session_path, session_alias, overwrite = TRUE)
append_artifact("k40_kaaos_sessioninfo.txt", "sessioninfo", session_alias, notes = "K40 KAAOS session info alias")

message("K40_FI_KAAOS completed.")
