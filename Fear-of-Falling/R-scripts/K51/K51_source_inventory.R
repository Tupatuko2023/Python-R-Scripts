#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
})

script_label <- "K51"
manifest_script <- "K51_source_verification"

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "person_dedup_lookup.R"))
source(here::here("R", "functions", "k51_source_inventory.R"))

paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  row <- data.frame(
    timestamp = as.character(Sys.time()),
    script = manifest_script,
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

write_table_with_manifest <- function(tbl, label, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".csv"))
  readr::write_csv(tbl, out_path, na = "")
  append_manifest_safe(label, "table_csv", out_path, n = nrow(tbl), notes = notes)
  out_path
}

resolve_input_path <- function() {
  data_root <- resolve_data_root()
  if (is.na(data_root)) stop("K51 source verification requires DATA_ROOT.", call. = FALSE)
  candidates <- c(
    file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_long.rds"),
    file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_long.csv")
  )
  hits <- candidates[file.exists(candidates)]
  if (length(hits) == 0L) {
    stop("K51 source verification could not resolve canonical K50 LONG input.", call. = FALSE)
  }
  normalizePath(hits[[1]], winslash = "/", mustWork = TRUE)
}

analytic_input_path <- resolve_input_path()
if (tolower(tools::file_ext(analytic_input_path)) != "rds") {
  stop("K51 source verification expects canonical K50 LONG input as .rds for the current analytic cohort.", call. = FALSE)
}

analytic_state <- k51_sv_derive_current_analytic(analytic_input_path)
candidates <- k51_sv_resolve_candidates()

inventory_tbl <- candidates %>%
  mutate(
    analytic_input_path = analytic_state$input_path,
    analytic_n = analytic_state$analytic_n
  )

report_tbl <- bind_rows(Map(
  function(source_name, path, role, required_columns) {
    k51_sv_evaluate_candidate(source_name, path, role, required_columns, analytic_state$analytic_df)
  },
  candidates$source_name,
  candidates$path,
  candidates$role,
  candidates$required_columns
))

inventory_path <- write_table_with_manifest(
  inventory_tbl,
  "k51_source_inventory",
  "Sibling-upstream source inventory for K51 verified enrichment source task"
)

report_path <- write_table_with_manifest(
  report_tbl,
  "k51_source_verification_report",
  "Coverage verification of sibling-upstream person-level sources against current analytic cohort"
)

report_v2_path <- write_table_with_manifest(
  report_tbl,
  "k51_source_verification_report_v2",
  "Coverage verification with duplicate-resolution pass for sibling-upstream person-level sources against current analytic cohort"
)

decision_label <- "k51_source_verification_decision_log"
decision_path <- file.path(outputs_dir, paste0(decision_label, ".txt"))
acceptable <- report_tbl %>% filter(isTRUE(acceptable_source))
decision_lines <- c(
  "K51 source verification run",
  paste0("analytic_input_path=", analytic_state$input_path),
  paste0("analytic_n=", analytic_state$analytic_n),
  paste0("candidate_sources=", nrow(report_tbl)),
  if (nrow(acceptable) > 0L) {
    paste0("acceptable_sources=", paste(acceptable$source_name, collapse = " | "))
  } else {
    "acceptable_sources=NONE"
  },
  "Decision rule: acceptable_source requires coverage_ratio >= 0.9 and duplicate_keys == 0 using shared person-key attachment.",
  "Sibling aggregate table1_patient_characteristics_by_fof.csv is excluded as an enrichment input by design.",
  paste0("inventory_path=", inventory_path),
  paste0("report_path=", report_path)
)
writeLines(decision_lines, con = decision_path)
append_manifest_safe(
  decision_label,
  "text",
  decision_path,
  n = nrow(report_tbl),
  notes = "K51 source verification decision log"
)

decision_v2_label <- "k51_source_verification_decision_log_v2"
decision_v2_path <- file.path(outputs_dir, paste0(decision_v2_label, ".txt"))
root_row <- report_tbl %>% filter(source_name == "root_kaatumisenpelko_csv")
decision_v2_lines <- c(
  "K51 source verification run v2",
  paste0("analytic_input_path=", analytic_state$input_path),
  paste0("analytic_n=", analytic_state$analytic_n),
  if (nrow(root_row) == 1L) {
    c(
      paste0("root_kaatumisenpelko_exists=", file.exists(root_row$path[[1]])),
      paste0("root_kaatumisenpelko_matched_analytic_ids=", root_row$matched_analytic_ids[[1]]),
      paste0("root_kaatumisenpelko_coverage_ratio=", root_row$coverage_ratio[[1]]),
      paste0("root_kaatumisenpelko_duplicate_keys_before=", root_row$duplicate_keys[[1]]),
      paste0("root_kaatumisenpelko_duplicate_keys_after_dedup=", root_row$duplicate_keys_after_dedup[[1]]),
      paste0("root_kaatumisenpelko_rows_removed_by_dedup=", root_row$rows_removed_by_dedup[[1]]),
      paste0("root_kaatumisenpelko_acceptable_source=", root_row$acceptable_source[[1]])
    )
  } else {
    "root_kaatumisenpelko_status=not_evaluated"
  },
  "Decision rule: acceptable_source requires coverage_ratio >= 0.9 and duplicate_keys_after_dedup == 0.",
  paste0("report_v2_path=", report_v2_path)
)
writeLines(decision_v2_lines, con = decision_v2_path)
append_manifest_safe(
  decision_v2_label,
  "text",
  decision_v2_path,
  n = nrow(report_tbl),
  notes = "K51 source verification decision log v2 with duplicate-resolution pass"
)
