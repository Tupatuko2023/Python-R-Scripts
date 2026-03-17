#!/usr/bin/env Rscript

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
outputs_dir <- file.path(project_root, "R-scripts", "K50", "outputs")
manifest_path <- file.path(project_root, "manifest", "manifest.csv")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)

source(file.path(project_root, "R", "functions", "person_dedup_lookup.R"))

resolve_data_root <- function() {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(data_root)) {
    env_path <- file.path(project_root, "config", ".env")
    if (file.exists(env_path)) {
      env_lines <- readLines(env_path, warn = FALSE)
      hit <- grep("^export DATA_ROOT=", env_lines, value = TRUE)
      if (length(hit) > 0) {
        data_root <- sub("^export DATA_ROOT=", "", hit[[1]])
        data_root <- gsub('^"|"$', "", data_root)
      }
    }
  }
  if (!nzchar(data_root)) {
    stop("DATA_ROOT is required for K50 helper estimates.", call. = FALSE)
  }
  normalizePath(data_root, winslash = "/", mustWork = FALSE)
}

manifest_row <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  data.frame(
    timestamp = as.character(Sys.time()),
    script = "K50",
    label = label,
    kind = kind,
    path = path,
    n = as.character(n),
    notes = notes,
    stringsAsFactors = FALSE
  )
}

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  row <- manifest_row(label, kind, path, n = n, notes = notes)
  if (!file.exists(manifest_path)) {
    utils::write.table(row, manifest_path, sep = ",", row.names = FALSE, col.names = TRUE, quote = TRUE)
  } else {
    old <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
    out <- rbind(old, row)
    utils::write.table(out, manifest_path, sep = ",", row.names = FALSE, col.names = TRUE, quote = TRUE)
  }
}

safe_num <- function(x) suppressWarnings(as.numeric(x))

normalize_fof <- function(x) {
  s <- tolower(trimws(as.character(x)))
  num <- suppressWarnings(as.integer(x))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "nonfof", "ei fof", "no fof", "false")] <- 0L
  out[s %in% c("1", "fof", "fear", "yes", "true")] <- 1L
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 1L)
  out[use_num] <- num[use_num]
  out
}

normalize_sex <- function(x) {
  s <- tolower(trimws(as.character(x)))
  num <- suppressWarnings(as.integer(x))
  out <- rep(NA_character_, length(s))
  out[s %in% c("0", "female", "f", "woman", "nainen")] <- "female"
  out[s %in% c("1", "male", "m", "man", "mies")] <- "male"
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 1L)
  out[use_num & num == 0L] <- "female"
  out[use_num & num == 1L] <- "male"
  out
}

read_model_terms <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

write_table <- function(df, label, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".csv"))
  utils::write.csv(df, out_path, row.names = FALSE, na = "")
  append_manifest_safe(label, "table_csv", file.path("R-scripts", "K50", "outputs", paste0(label, ".csv")), n = nrow(df), notes = notes)
}

write_text <- function(lines, label, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".txt"))
  writeLines(lines, con = out_path)
  append_manifest_safe(label, "text", file.path("R-scripts", "K50", "outputs", paste0(label, ".txt")), n = length(lines), notes = notes)
}

standardize_table <- function(tbl, data_df, outcome_var, continuous_terms, binary_terms, interaction_terms) {
  sd_y <- stats::sd(data_df[[outcome_var]], na.rm = TRUE)
  out <- tbl
  out$effect_scale <- NA_character_
  out$standardized_estimate <- NA_real_

  for (i in seq_len(nrow(out))) {
    term <- out$term[[i]]
    est <- safe_num(out$estimate[[i]])
    if (!is.finite(est) || !is.finite(sd_y) || sd_y == 0) next
    if (term %in% continuous_terms) {
      sd_x <- stats::sd(data_df[[term]], na.rm = TRUE)
      if (is.finite(sd_x) && sd_x > 0) {
        out$effect_scale[[i]] <- "standardized_beta"
        out$standardized_estimate[[i]] <- est * sd_x / sd_y
      }
    } else if (term %in% binary_terms) {
      out$effect_scale[[i]] <- "semi_standardized_outcome_sd"
      out$standardized_estimate[[i]] <- est / sd_y
    } else if (term %in% interaction_terms) {
      pieces <- strsplit(term, ":", fixed = TRUE)[[1]]
      sd_piece <- 1
      for (piece in pieces) {
        if (piece %in% names(data_df)) {
          if (piece %in% continuous_terms) {
            piece_sd <- stats::sd(data_df[[piece]], na.rm = TRUE)
            if (is.finite(piece_sd) && piece_sd > 0) sd_piece <- sd_piece * piece_sd
          }
        }
      }
      out$effect_scale[[i]] <- "semi_standardized_interaction"
      out$standardized_estimate[[i]] <- est * sd_piece / sd_y
    }
  }
  out
}

data_root <- resolve_data_root()
wide_path <- file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_wide.rds")
long_path <- file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_long.rds")

wide_raw <- readRDS(wide_path)
long_raw <- readRDS(long_path)
wide_raw <- prepare_k50_person_dedup(wide_raw, "WIDE", "locomotor_capacity")$data
long_raw <- prepare_k50_person_dedup(long_raw, "LONG", "locomotor_capacity")$data

wide_df <- data.frame(
  FOF_status = normalize_fof(wide_raw$FOF_status),
  age = safe_num(wide_raw$age),
  sex = normalize_sex(wide_raw$sex),
  BMI = safe_num(wide_raw$BMI),
  FI22_nonperformance_KAAOS = safe_num(wide_raw$FI22_nonperformance_KAAOS),
  locomotor_capacity_0 = safe_num(wide_raw$locomotor_capacity_0),
  locomotor_capacity_12m = safe_num(wide_raw$locomotor_capacity_12m),
  stringsAsFactors = FALSE
)

long_df <- data.frame(
  id = trimws(as.character(long_raw$id)),
  time = safe_num(long_raw$time),
  FOF_status = normalize_fof(long_raw$FOF_status),
  age = safe_num(long_raw$age),
  sex = normalize_sex(long_raw$sex),
  BMI = safe_num(long_raw$BMI),
  FI22_nonperformance_KAAOS = safe_num(long_raw$FI22_nonperformance_KAAOS),
  locomotor_capacity = safe_num(long_raw$locomotor_capacity),
  stringsAsFactors = FALSE
)

wide_primary_df <- wide_df[stats::complete.cases(wide_df[, c("FOF_status", "age", "sex", "BMI", "locomotor_capacity_0", "locomotor_capacity_12m")]), , drop = FALSE]
wide_fi22_df <- wide_df[stats::complete.cases(wide_df[, c("FOF_status", "age", "sex", "BMI", "FI22_nonperformance_KAAOS", "locomotor_capacity_0", "locomotor_capacity_12m")]), , drop = FALSE]
long_primary_df <- long_df[stats::complete.cases(long_df[, c("time", "FOF_status", "age", "sex", "BMI", "locomotor_capacity")]), , drop = FALSE]
long_fi22_df <- long_df[stats::complete.cases(long_df[, c("time", "FOF_status", "age", "sex", "BMI", "FI22_nonperformance_KAAOS", "locomotor_capacity")]), , drop = FALSE]

wide_primary_tbl <- read_model_terms(file.path(outputs_dir, "k50_wide_locomotor_capacity_model_terms_primary.csv"))
wide_fi22_tbl <- read_model_terms(file.path(outputs_dir, "k50_wide_locomotor_capacity_model_terms_fi22.csv"))
long_primary_tbl <- read_model_terms(file.path(outputs_dir, "k50_long_locomotor_capacity_model_terms_primary.csv"))
long_fi22_tbl <- read_model_terms(file.path(outputs_dir, "k50_long_locomotor_capacity_model_terms_fi22.csv"))

wide_standardized <- rbind(
  standardize_table(
    wide_primary_tbl,
    wide_primary_df,
    "locomotor_capacity_12m",
    continuous_terms = c("locomotor_capacity_0", "age", "BMI"),
    binary_terms = c("FOF_status1", "sexmale"),
    interaction_terms = character()
  ),
  standardize_table(
    wide_fi22_tbl,
    wide_fi22_df,
    "locomotor_capacity_12m",
    continuous_terms = c("locomotor_capacity_0", "age", "BMI", "FI22_nonperformance_KAAOS"),
    binary_terms = c("FOF_status1", "sexmale"),
    interaction_terms = character()
  )
)

long_standardized <- rbind(
  standardize_table(
    long_primary_tbl,
    long_primary_df,
    "locomotor_capacity",
    continuous_terms = c("time", "age", "BMI"),
    binary_terms = c("FOF_status1", "sexmale"),
    interaction_terms = c("time:FOF_status1")
  ),
  standardize_table(
    long_fi22_tbl,
    long_fi22_df,
    "locomotor_capacity",
    continuous_terms = c("time", "age", "BMI", "FI22_nonperformance_KAAOS"),
    binary_terms = c("FOF_status1", "sexmale"),
    interaction_terms = c("time:FOF_status1")
  )
)

write_table(wide_standardized, "k50_wide_standardized_effects", "Post-hoc standardized and semi-standardized WIDE helper effects")
write_table(long_standardized, "k50_long_standardized_effects", "Post-hoc standardized and semi-standardized LONG helper effects")

simr_available <- requireNamespace("simr", quietly = TRUE)
note_lines <- c(
  "K50 standardized effects and interaction power note",
  "",
  "These helper estimates are manuscript-supporting post-hoc summaries and do not replace the locked primary or FI22 sensitivity results.",
  "Continuous covariates are reported as standardized beta-type effects using predictor SD and outcome SD.",
  "Binary terms such as FOF_status1 are reported as semi-standardized effects in outcome-SD units.",
  "The LONG time x FOF_status interaction should still be interpreted cautiously as no interaction detected rather than evidence of identical trajectories."
)

if (simr_available) {
  power_lines <- c(
    "simr is available in this runtime, but interaction-power simulation was not executed automatically in this helper because the locked K50 mixed model object is not reconstructed in this base-R runtime.",
    "If interaction power is needed later in a runtime with the locked lmer model available, report any non-detection cautiously and note limited power to detect small interaction effects when appropriate."
  )
} else {
  power_lines <- c(
    "simr is not available in this runtime, so simulation-based interaction power was skipped.",
    "Report the LONG interaction conservatively as no interaction detected and, if manuscript space allows, note that power to detect small interaction effects may be limited."
  )
}

write_text(c(note_lines, "", power_lines), "k50_standardized_effects_and_power_note", "Note for standardized helper effects and interaction power availability")

session_path <- file.path(outputs_dir, "k50_standardized_effects_and_power_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest_safe(
  "k50_standardized_effects_and_power_sessioninfo",
  "sessioninfo",
  file.path("R-scripts", "K50", "outputs", "k50_standardized_effects_and_power_sessioninfo.txt"),
  notes = "K50 helper standardized effects session info"
)
