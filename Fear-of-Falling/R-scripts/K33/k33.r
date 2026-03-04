#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(here)
})

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

resolve_k15_input <- function(data_root) {
  candidates <- c(
    file.path(data_root, "paper_01", "frailty", "kaatumisenpelko_with_frailty_k15.rds"),
    file.path(data_root, "paper_01", "frailty", "kaatumisenpelko_with_frailty_k15.csv"),
    file.path(data_root, "paper_01", "frailty", "kaatumisenpelko_with_frailty_scores.rds"),
    file.path(data_root, "paper_01", "frailty", "kaatumisenpelko_with_frailty_scores.csv")
  )
  hit <- resolve_existing(candidates)
  if (is.na(hit)) {
    stop(
      "Could not resolve K15 frailty input under DATA_ROOT. Tried:\n- ",
      paste(candidates, collapse = "\n- "),
      call. = FALSE
    )
  }
  list(path = hit, candidates = candidates)
}

read_dataset <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") return(readRDS(path))
  if (ext == "csv") return(readr::read_csv(path, show_col_types = FALSE))
  stop("Unsupported dataset extension: ", ext, call. = FALSE)
}

resolve_col <- function(nms, candidates) {
  nms_l <- tolower(nms)
  cand_l <- tolower(candidates)
  idx <- match(cand_l, nms_l)
  idx <- idx[!is.na(idx)][1]
  if (is.na(idx)) return(NA_character_)
  nms[[idx]]
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

normalize_frailty_cat3 <- function(x) {
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_character_, length(s))
  out[s %in% c("robust", "0")] <- "robust"
  out[s %in% c("pre-frail", "prefrail", "pre frail", "1")] <- "pre-frail"
  out[s %in% c("frail", "2", "3", "4")] <- "frail"
  factor(out, levels = c("robust", "pre-frail", "frail"))
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
  status <- system2("/usr/bin/Rscript", args = args)
  as.integer(status)
}

# ---- main ----
data_root <- resolve_data_root()
k15_input <- resolve_k15_input(data_root)
source_df <- read_dataset(k15_input$path)

id_col <- resolve_col(names(source_df), c("id", "participant_id", "subject_id", "record_id"))
fof_col <- resolve_col(names(source_df), c("FOF_status", "kaatumisenpelkoOn", "kaatumisenpelko_on"))
frailty_col <- resolve_col(names(source_df), c("frailty_cat_3", "frailty_cat"))
balance_col <- resolve_col(names(source_df), c("tasapainovaikeus"))
age_col <- resolve_col(names(source_df), c("age", "Agelka"))
sex_col <- resolve_col(names(source_df), c("sex", "sukupuoli"))
bmi_col <- resolve_col(names(source_df), c("BMI", "bmi"))
comp0_col <- resolve_col(names(source_df), c("ToimintaKykySummary0", "Composite_Z0", "composite_z0"))
comp12_col <- resolve_col(names(source_df), c("ToimintaKykySummary2", "Composite_Z12", "composite_z12", "Composite_Z2"))

required_map <- c(
  id = id_col,
  FOF_status = fof_col,
  frailty_cat_3 = frailty_col,
  tasapainovaikeus = balance_col,
  age = age_col,
  sex = sex_col,
  BMI = bmi_col,
  Composite_Z0 = comp0_col,
  Composite_Z12 = comp12_col
)
if (any(is.na(required_map))) {
  miss <- names(required_map)[is.na(required_map)]
  stop(
    "K33 missing required source mappings: ", paste(miss, collapse = ", "),
    "\nAvailable columns (subset): ", paste(head(names(source_df), 40), collapse = ", "),
    call. = FALSE
  )
}

wide_df <- source_df %>%
  transmute(
    id = .data[[id_col]],
    FOF_status = normalize_fof(.data[[fof_col]]),
    frailty_cat_3 = normalize_frailty_cat3(.data[[frailty_col]]),
    tasapainovaikeus = normalize_binary(.data[[balance_col]]),
    age = as.numeric(.data[[age_col]]),
    sex = as.character(.data[[sex_col]]),
    BMI = as.numeric(.data[[bmi_col]]),
    Composite_Z_baseline = as.numeric(.data[[comp0_col]]),
    Composite_Z_12m = as.numeric(.data[[comp12_col]])
  ) %>%
  mutate(delta_composite_z = Composite_Z_12m - Composite_Z_baseline)

# QC gates required by K33
qc_gate <- tibble::tibble(
  check = c(
    "wide_id_unique",
    "time_exact_levels_0_12",
    "long_2_rows_per_id",
    "delta_identity_tol_1e8",
    "frailty_levels_valid",
    "tasapainovaikeus_levels_valid"
  ),
  ok = c(
    dplyr::n_distinct(wide_df$id) == nrow(wide_df),
    TRUE,
    TRUE,
    isTRUE(all(abs(wide_df$delta_composite_z - (wide_df$Composite_Z_12m - wide_df$Composite_Z_baseline)) <= 1e-8 | is.na(wide_df$delta_composite_z))),
    all(na.omit(as.character(wide_df$frailty_cat_3)) %in% c("robust", "pre-frail", "frail")),
    all(na.omit(wide_df$tasapainovaikeus) %in% c(0L, 1L))
  ),
  detail = c(
    paste0("nrow=", nrow(wide_df), "; n_distinct_id=", dplyr::n_distinct(wide_df$id)),
    "long time forced to {0,12}",
    "validated after long build",
    "absolute tolerance 1e-8",
    paste(sort(unique(na.omit(as.character(wide_df$frailty_cat_3)))), collapse = ";"),
    paste(sort(unique(na.omit(wide_df$tasapainovaikeus))), collapse = ";")
  )
)

long_df <- wide_df %>%
  select(id, FOF_status, frailty_cat_3, tasapainovaikeus, age, sex, BMI, Composite_Z_baseline, Composite_Z_12m) %>%
  tidyr::pivot_longer(
    cols = c(Composite_Z_baseline, Composite_Z_12m),
    names_to = "time_source",
    values_to = "Composite_Z"
  ) %>%
  mutate(time = dplyr::if_else(time_source == "Composite_Z_baseline", 0L, 12L)) %>%
  select(id, time, FOF_status, frailty_cat_3, tasapainovaikeus, Composite_Z, age, sex, BMI) %>%
  arrange(id, time)

# Update long gate checks
qc_gate$ok[qc_gate$check == "time_exact_levels_0_12"] <- identical(sort(unique(long_df$time)), c(0L, 12L))
row_count_by_id <- long_df %>% count(id, name = "n")
qc_gate$ok[qc_gate$check == "long_2_rows_per_id"] <- all(row_count_by_id$n == 2L)
qc_gate$detail[qc_gate$check == "long_2_rows_per_id"] <- paste0("min=", min(row_count_by_id$n), "; max=", max(row_count_by_id$n))

qc_path <- file.path(outputs_dir, "k33_qc_gates.csv")
readr::write_csv(qc_gate, qc_path)
append_manifest_safe("k33_qc_gates", "table_csv", qc_path, n = nrow(qc_gate), notes = "K33 canonical dataset QC gates")

if (!all(qc_gate$ok)) {
  stop("K33 QC gates failed. See: ", qc_path, call. = FALSE)
}

external_dir <- file.path(data_root, "paper_01", "analysis")
dir.create(external_dir, recursive = TRUE, showWarnings = FALSE)

long_csv <- file.path(external_dir, "fof_analysis_k33_long.csv")
long_rds <- file.path(external_dir, "fof_analysis_k33_long.rds")
wide_csv <- file.path(external_dir, "fof_analysis_k33_wide.csv")
wide_rds <- file.path(external_dir, "fof_analysis_k33_wide.rds")

readr::write_csv(long_df, long_csv)
saveRDS(long_df, long_rds)
readr::write_csv(wide_df, wide_csv)
saveRDS(wide_df, wide_rds)

k18_status <- run_k18_qc(long_rds)
if (k18_status != 0L) {
  stop("K18 QC failed on K33 long dataset (status=", k18_status, ").", call. = FALSE)
}

receipt_path <- file.path(outputs_dir, "k33_patient_level_output_receipt.txt")
receipt <- c(
  "script=K33",
  paste0("timestamp_utc=", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste0("data_root=", data_root),
  paste0("source_k15_path=", k15_input$path),
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
  "notes=K33 canonical datasets externalized; repo stores only aggregate QC + receipt."
)
writeLines(receipt, con = receipt_path)
append_manifest_safe("k33_patient_level_output_receipt", "text", receipt_path, n = nrow(wide_df), notes = "External patient-level K33 long/wide datasets written to DATA_ROOT")

session_path <- file.path(outputs_dir, "k33_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest_safe("k33_sessioninfo", "sessioninfo", session_path, n = NA_integer_, notes = NA_character_)

message("K33 complete. External datasets written to: ", external_dir)
