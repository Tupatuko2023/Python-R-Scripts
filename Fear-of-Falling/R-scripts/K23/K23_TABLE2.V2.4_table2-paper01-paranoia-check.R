#!/usr/bin/env Rscript
# ==============================================================================
# K23_TABLE2 - V2.4 paranoia-check (replica vs manuscript gold standard)
# File tag: K23_TABLE2.V2.4_table2-paper01-paranoia-check.R
# Purpose: Deterministic QC diff between V2.3 replica CSV and hardcoded
#          manuscript Table 2 gold-standard values.
#
# Outputs:
# - table2_paper01_v2_3_paranoia_diff.csv
# - table2_paper01_v2_3_paranoia_summary.txt
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(stringr)
  library(tibble)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K23_TABLE2"
}
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K23_TABLE2"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
manifest_path <- paths$manifest_path
outputs_dir <- here::here("R-scripts", "K23", "outputs", script_label)
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
options(fof.outputs_dir = outputs_dir, fof.manifest_path = manifest_path, fof.script = script_label)

parse_cli <- function(args) {
  out <- list(
    input = NA_character_,
    output_diff = NA_character_,
    output_summary = NA_character_
  )
  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--output_diff=")) out$output_diff <- sub("^--output_diff=", "", arg)
    if (startsWith(arg, "--output_summary=")) out$output_summary <- sub("^--output_summary=", "", arg)
  }
  out
}

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(
      script = script_label,
      label = label,
      path = get_relpath(path),
      kind = kind,
      n = n,
      notes = notes
    ),
    manifest_path
  )
}

parse_mean_sd <- function(x) {
  nums <- stringr::str_extract_all(x, "[-+]?[0-9]*\\.?[0-9]+")[[1]]
  if (length(nums) < 2) return(c(NA_real_, NA_real_))
  c(as.numeric(nums[1]), as.numeric(nums[2]))
}

parse_delta_ci <- function(x) {
  txt <- str_replace_all(x, "\u2013|\u2014", "-")
  nums <- stringr::str_extract_all(txt, "[-+]?[0-9]*\\.?[0-9]+")[[1]]
  if (length(nums) < 3) return(c(NA_real_, NA_real_, NA_real_))
  if (length(nums) >= 4 && suppressWarnings(as.numeric(nums[2])) == 95) {
    return(c(as.numeric(nums[1]), as.numeric(nums[3]), as.numeric(nums[4])))
  }
  c(as.numeric(nums[1]), as.numeric(nums[2]), as.numeric(nums[3]))
}

parse_p <- function(x) {
  txt <- trimws(as.character(x))
  if (!nzchar(txt)) return(NA_real_)
  if (startsWith(txt, "<")) {
    val <- suppressWarnings(as.numeric(sub("^<\\s*", "", txt)))
    if (is.na(val)) return(0.001)
    return(val)
  }
  suppressWarnings(as.numeric(txt))
}

normalize_outcome_key <- function(x) {
  dplyr::case_when(
    x %in% c("MWS") ~ "MWS",
    x %in% c("FTSST") ~ "FTSST",
    x %in% c("SLS") ~ "SLS",
    x %in% c("HGS (female)", "HGS — Women", "HGS - Women") ~ "HGS_women",
    x %in% c("HGS (male)", "HGS — Men", "HGS - Men") ~ "HGS_men",
    TRUE ~ NA_character_
  )
}

cli <- parse_cli(commandArgs(trailingOnly = TRUE))
input_path <- if (!is.na(cli$input) && nzchar(cli$input)) {
  cli$input
} else {
  file.path(outputs_dir, "table2_paper01_v2_3_replica.csv")
}
output_diff <- if (!is.na(cli$output_diff) && nzchar(cli$output_diff)) {
  cli$output_diff
} else {
  file.path(outputs_dir, "table2_paper01_v2_3_paranoia_diff.csv")
}
output_summary <- if (!is.na(cli$output_summary) && nzchar(cli$output_summary)) {
  cli$output_summary
} else {
  file.path(outputs_dir, "table2_paper01_v2_3_paranoia_summary.txt")
}

if (!file.exists(input_path)) {
  stop("Replica input CSV missing: ", input_path)
}

replica_raw <- readr::read_csv(input_path, show_col_types = FALSE)

gold <- tibble(
  outcome_key = c("MWS", "FTSST", "SLS", "HGS_women", "HGS_men"),
  outcome_label_ms = c("MWS", "FTSST", "SLS", "HGS — Women", "HGS — Men"),
  without_baseline_mean = c(1.31, 16.26, 10.74, 18.16, 24.10),
  without_baseline_sd = c(0.49, 6.99, 12.52, 5.94, 5.94),
  without_delta_mean = c(-0.03, -1.04, -0.26, 0.48, 1.45),
  without_delta_lcl = c(-0.14, -2.56, -2.06, -0.53, -2.97),
  without_delta_ucl = c(0.08, 0.48, 1.53, 1.50, 5.87),
  with_baseline_mean = c(1.12, 18.87, 9.71, 17.59, 28.89),
  with_baseline_sd = c(0.41, 10.19, 13.82, 6.19, 6.85),
  with_delta_mean = c(0.03, -1.55, -0.15, 0.42, -2.07),
  with_delta_lcl = c(-0.01, -3.07, -1.29, -0.02, -7.39),
  with_delta_ucl = c(0.07, -0.03, 0.98, 0.87, 3.24),
  p_A = c(0.220, 0.700, 0.918, 0.901, 0.306),
  p_B = c(0.204, 0.677, 0.915, 0.899, 0.248),
  p_C = c(0.267, 0.711, 0.960, 0.655, 0.271),
  N_without = c(77, 77, 77, 77, 77),
  N_with = c(199, 199, 199, 199, 199)
)

replica <- replica_raw %>%
  mutate(
    outcome_key = normalize_outcome_key(.data$Outcome),
    p_A = vapply(.data$P_Model_A, parse_p, numeric(1)),
    p_B = vapply(.data$P_Model_B, parse_p, numeric(1)),
    p_C = vapply(.data$P_Model_C, parse_p, numeric(1)),
    N_without = suppressWarnings(as.numeric(.data$N_without)),
    N_with = suppressWarnings(as.numeric(.data$N_with))
  ) %>%
  filter(!is.na(outcome_key), outcome_key %in% gold$outcome_key)

wb <- t(vapply(replica$Without_FOF_Baseline, parse_mean_sd, numeric(2)))
wd <- t(vapply(replica$Without_FOF_Delta, parse_delta_ci, numeric(3)))
xb <- t(vapply(replica$With_FOF_Baseline, parse_mean_sd, numeric(2)))
xd <- t(vapply(replica$With_FOF_Delta, parse_delta_ci, numeric(3)))

replica <- replica %>%
  mutate(
    without_baseline_mean = wb[, 1],
    without_baseline_sd = wb[, 2],
    without_delta_mean = wd[, 1],
    without_delta_lcl = wd[, 2],
    without_delta_ucl = wd[, 3],
    with_baseline_mean = xb[, 1],
    with_baseline_sd = xb[, 2],
    with_delta_mean = xd[, 1],
    with_delta_lcl = xd[, 2],
    with_delta_ucl = xd[, 3]
  ) %>%
  select(
    outcome_key, Outcome,
    without_baseline_mean, without_baseline_sd,
    without_delta_mean, without_delta_lcl, without_delta_ucl,
    with_baseline_mean, with_baseline_sd,
    with_delta_mean, with_delta_lcl, with_delta_ucl,
    p_A, p_B, p_C, N_without, N_with
  )

fields <- c(
  "without_baseline_mean", "without_baseline_sd",
  "without_delta_mean", "without_delta_lcl", "without_delta_ucl",
  "with_baseline_mean", "with_baseline_sd",
  "with_delta_mean", "with_delta_lcl", "with_delta_ucl",
  "p_A", "p_B", "p_C", "N_without", "N_with"
)

joined <- replica %>%
  inner_join(gold %>% select(-outcome_label_ms), by = "outcome_key", suffix = c("_yours", "_ms"))

diff_rows <- list()
for (i in seq_len(nrow(joined))) {
  for (f in fields) {
    yours <- joined[[paste0(f, "_yours")]][i]
    ms <- joined[[paste0(f, "_ms")]][i]
    diff_rows[[length(diff_rows) + 1L]] <- tibble(
      Outcome = joined$Outcome[i],
      outcome_key = joined$outcome_key[i],
      field = f,
      yours = ifelse(is.na(yours), NA_character_, as.character(yours)),
      manuscript = ifelse(is.na(ms), NA_character_, as.character(ms)),
      diff = ifelse(is.na(yours) || is.na(ms), NA_real_, as.numeric(yours) - as.numeric(ms)),
      abs_diff = ifelse(is.na(yours) || is.na(ms), NA_real_, abs(as.numeric(yours) - as.numeric(ms))),
      note = ifelse(is.na(yours) || is.na(ms), "parse_or_missing", "")
    )
  }
}

diff_df <- bind_rows(diff_rows) %>% arrange(desc(abs_diff), Outcome, field)
readr::write_csv(diff_df, output_diff)

numeric_diff <- diff_df %>% filter(!is.na(abs_diff))
max_abs_diff <- if (nrow(numeric_diff) > 0) max(numeric_diff$abs_diff) else NA_real_
parse_fail_n <- sum(diff_df$note == "parse_or_missing", na.rm = TRUE)
tol_strict <- 0.005
tol_relaxed <- 0.010
pass_strict <- is.finite(max_abs_diff) && max_abs_diff <= tol_strict
pass_relaxed <- is.finite(max_abs_diff) && max_abs_diff <= tol_relaxed
top10 <- head(numeric_diff %>% arrange(desc(abs_diff)), 10)

summary_lines <- c(
  "K23_TABLE2 V2.4 paranoia-check summary",
  paste0("Input replica CSV: ", input_path),
  paste0("Output diff CSV: ", output_diff),
  "",
  "Coverage:",
  paste0("- outcomes compared: ", paste(unique(diff_df$Outcome), collapse = ", ")),
  paste0("- fields per outcome: ", length(fields)),
  paste0("- rows in diff table: ", nrow(diff_df)),
  "",
  "Tolerance evaluation:",
  paste0("- max_abs_diff: ", sprintf("%.6f", max_abs_diff)),
  paste0("- strict tolerance (<= ", tol_strict, "): ", ifelse(pass_strict, "PASS", "FAIL")),
  paste0("- relaxed tolerance (<= ", tol_relaxed, "): ", ifelse(pass_relaxed, "PASS", "FAIL")),
  paste0("- parsing/missing notes: ", parse_fail_n),
  "",
  "Top differences (abs_diff):"
)

if (nrow(top10) > 0) {
  top_lines <- apply(top10, 1, function(r) {
    paste0("- ", r[["Outcome"]], " / ", r[["field"]], ": abs_diff=", sprintf("%.6f", as.numeric(r[["abs_diff"]])))
  })
  summary_lines <- c(summary_lines, top_lines)
} else {
  summary_lines <- c(summary_lines, "- No numeric rows parsed.")
}

writeLines(summary_lines, con = output_summary)

append_artifact(
  label = "table2_paper01_v2_3_paranoia_diff_csv",
  kind = "table_csv",
  path = output_diff,
  n = nrow(diff_df),
  notes = "V2.4 paranoia-check cell-level numeric diffs vs manuscript gold standard"
)
append_artifact(
  label = "table2_paper01_v2_3_paranoia_summary_txt",
  kind = "qc_text",
  path = output_summary,
  notes = "V2.4 paranoia-check summary (max diff + tolerance verdict)"
)

cat("Saved paranoia-check outputs:\n")
cat(" - ", output_diff, "\n", sep = "")
cat(" - ", output_summary, "\n", sep = "")
cat("max_abs_diff=", sprintf("%.6f", max_abs_diff), " | strict=", ifelse(pass_strict, "PASS", "FAIL"),
    " | relaxed=", ifelse(pass_relaxed, "PASS", "FAIL"), "\n", sep = "")
