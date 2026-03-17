#!/usr/bin/env Rscript
# ==============================================================================
# K33 - Canonical locomotor_capacity primary export and QC handoff
# File tag: K33.V2_locomotor-capacity-primary-export.R
# Purpose: Externalize outcome-explicit K33 patient-level datasets aligned to the K50 locomotor_capacity primary contract and hand them to K18 QC.
#
# Outcome: locomotor_capacity (primary), z3 (fallback/sensitivity)
# Predictors: FOF_status
# Moderator/interaction: None
# Grouping variable: id
# Covariates: age, sex, BMI, tasapainovaikeus
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id
# time
# FOF_status
# age
# sex
# BMI
# tasapainovaikeus
# locomotor_capacity
# z3
# locomotor_capacity_0
# locomotor_capacity_12m
# z3_0
# z3_12m
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# fof_analysis_k50_long$locomotor_capacity -> K33 primary long outcome
# fof_analysis_k50_long$z3 -> K33 fallback long outcome
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: NA (set only when randomness is used: MI/bootstrap/resampling)
#
# Outputs + manifest:
# - script_label: K33 (canonical)
# - outputs dir: R-scripts/K33/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load canonical K50 long/wide datasets
# 03) Standardize vars + QC (sanity checks early)
# 04) Build outcome-explicit K33 long/wide exports
# 05) Externalize patient-level datasets under DATA_ROOT
# 06) Run K18 QC on the primary long dataset
# 07) Save receipt/QC/sessionInfo artifacts
# 08) Append manifest row per artifact
# 09) EOF marker
# ==============================================================================
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(tibble)
  library(here)
})

req_cols <- c(
  "id", "time", "FOF_status", "age", "sex", "BMI", "tasapainovaikeus",
  "locomotor_capacity", "z3", "locomotor_capacity_0", "locomotor_capacity_12m", "z3_0", "z3_12m"
)

source(here::here("R/functions/init.R"))

paths <- init_paths("K33")
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

resolve_data_root <- function() {
  dr <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(dr)) {
    stop(
      "K33 requires DATA_ROOT for patient-level I/O. Set config/.env and run via hardened Termux/PRoot runner.",
      call. = FALSE
    )
  }
  dr
}

resolve_existing <- function(candidates) {
  hit <- candidates[file.exists(candidates)][1]
  if (is.na(hit) || !nzchar(hit)) return(NA_character_)
  normalizePath(hit, winslash = "/", mustWork = TRUE)
}

read_dataset <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") return(as_tibble(readRDS(path)))
  if (ext == "csv") return(as_tibble(readr::read_csv(path, show_col_types = FALSE)))
  stop("Unsupported dataset extension: ", ext, call. = FALSE)
}

normalize_fof <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "nonfof", "ei fof", "no fof", "false")] <- 0L
  out[s %in% c("1", "fof", "true")] <- 1L
  suppressWarnings(num <- as.integer(s))
  out[is.na(out) & !is.na(num) & num %in% c(0L, 1L)] <- num[is.na(out) & !is.na(num) & num %in% c(0L, 1L)]
  out
}

normalize_binary <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "no", "ei", "false")] <- 0L
  out[s %in% c("1", "yes", "kylla", "kylä", "true")] <- 1L
  suppressWarnings(num <- as.integer(s))
  out[is.na(out) & !is.na(num) & num %in% c(0L, 1L)] <- num[is.na(out) & !is.na(num) & num %in% c(0L, 1L)]
  out
}

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(
      script = "K33",
      label = label,
      path = get_relpath(path),
      kind = kind,
      n = n,
      notes = notes
    ),
    manifest_path
  )
}

run_k18_qc <- function(data_path) {
  args <- c("R-scripts/K18/K18_QC.V1_qc-run.R", "--data", data_path, "--shape", "LONG", "--dict", "data/data_dictionary.csv")
  as.integer(system2("/usr/bin/Rscript", args = args))
}

data_root <- resolve_data_root()
k50_long_path <- resolve_existing(c(
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_long.rds"),
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_long.csv")
))
k50_wide_path <- resolve_existing(c(
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_wide.rds"),
  file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_wide.csv")
))

if (any(is.na(c(k50_long_path, k50_wide_path)))) {
  stop(
    paste0(
      "K33 could not resolve canonical K50 inputs.\n",
      "k50_long=", k50_long_path, "\n",
      "k50_wide=", k50_wide_path
    ),
    call. = FALSE
  )
}

long_raw <- read_dataset(k50_long_path)
wide_raw <- read_dataset(k50_wide_path)

required_long <- c("id", "time", "FOF_status", "age", "sex", "BMI", "tasapainovaikeus", "locomotor_capacity", "z3")
required_wide <- c("id", "FOF_status", "age", "sex", "BMI", "tasapainovaikeus", "locomotor_capacity_0", "locomotor_capacity_12m", "z3_0", "z3_12m")
miss_long <- setdiff(required_long, names(long_raw))
miss_wide <- setdiff(required_wide, names(wide_raw))
if (length(miss_long) > 0 || length(miss_wide) > 0) {
  stop(
    paste0(
      "K33 canonical inputs are missing required columns.\n",
      "long: ", paste(miss_long, collapse = ", "), "\n",
      "wide: ", paste(miss_wide, collapse = ", ")
    ),
    call. = FALSE
  )
}

long_df <- long_raw %>%
  transmute(
    id = trimws(as.character(.data$id)),
    time = as.integer(.data$time),
    FOF_status = normalize_fof(.data$FOF_status),
    age = as.numeric(.data$age),
    sex = as.character(.data$sex),
    BMI = as.numeric(.data$BMI),
    tasapainovaikeus = normalize_binary(.data$tasapainovaikeus),
    locomotor_capacity = as.numeric(.data$locomotor_capacity),
    z3 = as.numeric(.data$z3)
  ) %>%
  arrange(.data$id, .data$time)

wide_df <- wide_raw %>%
  transmute(
    id = trimws(as.character(.data$id)),
    FOF_status = normalize_fof(.data$FOF_status),
    age = as.numeric(.data$age),
    sex = as.character(.data$sex),
    BMI = as.numeric(.data$BMI),
    tasapainovaikeus = normalize_binary(.data$tasapainovaikeus),
    locomotor_capacity_0 = as.numeric(.data$locomotor_capacity_0),
    locomotor_capacity_12m = as.numeric(.data$locomotor_capacity_12m),
    z3_0 = as.numeric(.data$z3_0),
    z3_12m = as.numeric(.data$z3_12m)
  ) %>%
  mutate(
    delta_locomotor_capacity = .data$locomotor_capacity_12m - .data$locomotor_capacity_0,
    delta_z3 = .data$z3_12m - .data$z3_0
  )

qc_gate <- tibble(
  check = c(
    "wide_id_unique",
    "long_time_exact_0_12",
    "long_2_rows_per_id",
    "primary_delta_identity_tol_1e8",
    "fallback_delta_identity_tol_1e8",
    "fof_levels_valid",
    "tasapainovaikeus_levels_valid"
  ),
  ok = c(
    dplyr::n_distinct(wide_df$id) == nrow(wide_df),
    identical(sort(unique(long_df$time)), c(0L, 12L)),
    FALSE,
    isTRUE(all(abs(wide_df$delta_locomotor_capacity - (wide_df$locomotor_capacity_12m - wide_df$locomotor_capacity_0)) <= 1e-8 | is.na(wide_df$delta_locomotor_capacity))),
    isTRUE(all(abs(wide_df$delta_z3 - (wide_df$z3_12m - wide_df$z3_0)) <= 1e-8 | is.na(wide_df$delta_z3))),
    all(na.omit(wide_df$FOF_status) %in% c(0L, 1L)),
    all(na.omit(wide_df$tasapainovaikeus) %in% c(0L, 1L))
  ),
  detail = c(
    paste0("nrow=", nrow(wide_df), "; n_distinct_id=", dplyr::n_distinct(wide_df$id)),
    paste(sort(unique(long_df$time)), collapse = ";"),
    NA_character_,
    "absolute tolerance 1e-8",
    "absolute tolerance 1e-8",
    paste(sort(unique(na.omit(wide_df$FOF_status))), collapse = ";"),
    paste(sort(unique(na.omit(wide_df$tasapainovaikeus))), collapse = ";")
  )
)

row_count_by_id <- long_df %>% count(id, name = "n")
qc_gate$ok[qc_gate$check == "long_2_rows_per_id"] <- all(row_count_by_id$n == 2L)
qc_gate$detail[qc_gate$check == "long_2_rows_per_id"] <- paste0("min=", min(row_count_by_id$n), "; max=", max(row_count_by_id$n))

qc_path <- file.path(outputs_dir, "k33_qc_gates.csv")
readr::write_csv(qc_gate, qc_path)
append_manifest_safe("k33_qc_gates", "table_csv", qc_path, n = nrow(qc_gate), notes = "K33 locomotor_capacity primary / z3 fallback QC gates")

if (!all(qc_gate$ok)) {
  stop("K33 QC gates failed. See: ", qc_path, call. = FALSE)
}

external_dir <- file.path(data_root, "paper_01", "analysis")
dir.create(external_dir, recursive = TRUE, showWarnings = FALSE)

long_csv <- file.path(external_dir, "fof_analysis_k33_locomotor_capacity_primary_long.csv")
long_rds <- file.path(external_dir, "fof_analysis_k33_locomotor_capacity_primary_long.rds")
wide_csv <- file.path(external_dir, "fof_analysis_k33_locomotor_capacity_primary_wide.csv")
wide_rds <- file.path(external_dir, "fof_analysis_k33_locomotor_capacity_primary_wide.rds")

readr::write_csv(long_df, long_csv)
saveRDS(long_df, long_rds)
readr::write_csv(wide_df, wide_csv)
saveRDS(wide_df, wide_rds)

k18_status <- run_k18_qc(long_rds)
if (k18_status != 0L) {
  stop("K18 QC failed on K33 primary long dataset (status=", k18_status, ").", call. = FALSE)
}

receipt_path <- file.path(outputs_dir, "k33_patient_level_output_receipt.txt")
receipt <- c(
  "script=K33",
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("data_root=", data_root),
  paste0("source_k50_long_path=", k50_long_path),
  paste0("source_k50_wide_path=", k50_wide_path),
  "primary_outcome=locomotor_capacity",
  "fallback_outcome=z3",
  "legacy_bridge_outcome=Composite_Z",
  paste0("external_dir=", external_dir),
  paste0("long_csv_path=", long_csv),
  paste0("long_csv_md5=", unname(tools::md5sum(long_csv))),
  paste0("long_rds_path=", long_rds),
  paste0("long_rds_md5=", unname(tools::md5sum(long_rds))),
  paste0("wide_csv_path=", wide_csv),
  paste0("wide_csv_md5=", unname(tools::md5sum(wide_csv))),
  paste0("wide_rds_path=", wide_rds),
  paste0("wide_rds_md5=", unname(tools::md5sum(wide_rds))),
  paste0("long_nrow=", nrow(long_df)),
  paste0("long_ncol=", ncol(long_df)),
  paste0("wide_nrow=", nrow(wide_df)),
  paste0("wide_ncol=", ncol(wide_df)),
  paste0("k18_qc_status=", k18_status),
  "notes=K33 exports outcome-explicit locomotor_capacity primary data plus z3 fallback; Composite_Z remains legacy bridge only."
)
writeLines(receipt, con = receipt_path)
append_manifest_safe("k33_patient_level_output_receipt", "text", receipt_path, n = nrow(wide_df), notes = "Outcome-explicit K33 patient-level datasets written to DATA_ROOT")

session_path <- file.path(outputs_dir, "k33_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest_safe("k33_sessioninfo", "sessioninfo", session_path, n = NA_integer_, notes = "K33 session info")

message("K33 complete. External datasets written to: ", external_dir)
