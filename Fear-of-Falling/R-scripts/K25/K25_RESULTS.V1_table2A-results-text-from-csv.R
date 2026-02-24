#!/usr/bin/env Rscript
# ==============================================================================
# K25_RESULTS - Generate Results text from K24 Table 2A paper-ready CSV
# File tag: K25_RESULTS.V1_table2A-results-text-from-csv.R
# Purpose: Deterministic table-to-text generator (no new statistical modeling).
#
# Input default:
# - R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_v1_1.csv
#
# Outputs:
# - R-scripts/K25/outputs/K25_RESULTS/results_table2A_from_K24_v1_1.md
# - R-scripts/K25/outputs/K25_RESULTS/results_table2A_from_K24_v1_1.txt
# - R-scripts/K25/outputs/K25_RESULTS/sessionInfo.txt
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
  "K25_RESULTS"
}
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K25_RESULTS"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
manifest_path <- paths$manifest_path
outputs_dir <- here::here("R-scripts", "K25", "outputs", script_label)
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
options(fof.outputs_dir = outputs_dir, fof.manifest_path = manifest_path, fof.script = script_label)

parse_cli <- function(args) {
  out <- list(
    input = NA_character_,
    out_md = NA_character_,
    out_txt = NA_character_
  )
  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--out_md=")) out$out_md <- sub("^--out_md=", "", arg)
    if (startsWith(arg, "--out_txt=")) out$out_txt <- sub("^--out_txt=", "", arg)
  }
  out
}

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  append_manifest(
    manifest_row(script = script_label, label = label, path = get_relpath(path), kind = kind, n = n, notes = notes),
    manifest_path
  )
}

parse_beta_ci <- function(x) {
  nums <- str_extract_all(x, "[-+]?[0-9]*\\.?[0-9]+")[[1]]
  if (length(nums) < 3) return(c(NA_real_, NA_real_, NA_real_))
  c(as.numeric(nums[1]), as.numeric(nums[2]), as.numeric(nums[3]))
}

fmt_p <- function(x) {
  p <- suppressWarnings(as.numeric(x))
  if (is.na(p)) return(as.character(x))
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

cli <- parse_cli(commandArgs(trailingOnly = TRUE))
input_path <- if (!is.na(cli$input) && nzchar(cli$input)) {
  cli$input
} else {
  here::here("R-scripts", "K24", "outputs", "K24_TABLE2A", "table2A_paper_ready_v1_1.csv")
}
out_md <- if (!is.na(cli$out_md) && nzchar(cli$out_md)) cli$out_md else file.path(outputs_dir, "results_table2A_from_K24_v1_1.md")
out_txt <- if (!is.na(cli$out_txt) && nzchar(cli$out_txt)) cli$out_txt else file.path(outputs_dir, "results_table2A_from_K24_v1_1.txt")
session_path <- file.path(outputs_dir, "sessionInfo.txt")

if (!file.exists(input_path)) stop("Input CSV missing: ", input_path)
tab <- readr::read_csv(input_path, show_col_types = FALSE)

required <- c("Outcome", "N_without", "N_with", "Model_N", "FOF_Beta_CI", "P_FOF", "P_Frailty_Overall")
missing_cols <- setdiff(required, names(tab))
if (length(missing_cols) > 0) stop("Missing required columns in input CSV: ", paste(missing_cols, collapse = ", "))

order_outcomes <- c("MWS", "FTSST", "SLS", "HGS (Women)", "HGS (Men)")
tab2 <- tab %>%
  filter(Outcome %in% order_outcomes) %>%
  mutate(Outcome = factor(Outcome, levels = order_outcomes)) %>%
  arrange(Outcome)

if (nrow(tab2) != 5) stop("Expected exactly 5 outcomes in paper-ready CSV.")

beta_ci <- t(vapply(tab2$FOF_Beta_CI, parse_beta_ci, numeric(3)))
tab2 <- tab2 %>%
  mutate(
    beta = beta_ci[, 1],
    lcl = beta_ci[, 2],
    ucl = beta_ci[, 3],
    p_fof_fmt = vapply(P_FOF, fmt_p, character(1)),
    p_frailty_fmt = vapply(P_Frailty_Overall, fmt_p, character(1)),
    ci_crosses_zero = ifelse(is.na(lcl) | is.na(ucl), NA, lcl <= 0 & ucl >= 0)
  )

fof_fragments <- vapply(seq_len(nrow(tab2)), function(i) {
  r <- tab2[i, ]
  paste0(
    as.character(r$Outcome), ": β=", sprintf("%.3f", r$beta),
    " (95% CI ", sprintf("%.3f", r$lcl), " to ", sprintf("%.3f", r$ucl), "), p=", r$p_fof_fmt,
    ", Model_N=", r$Model_N, ", group Ns=", r$N_without, "/", r$N_with
  )
}, character(1))

frailty_fragments <- vapply(seq_len(nrow(tab2)), function(i) {
  r <- tab2[i, ]
  paste0(as.character(r$Outcome), " p=", r$p_frailty_fmt)
}, character(1))

hgs_women_row <- tab2 %>% filter(Outcome == "HGS (Women)")
hgs_men_row <- tab2 %>% filter(Outcome == "HGS (Men)")

all_ci_cross_zero <- all(tab2$ci_crosses_zero, na.rm = TRUE)
headline <- if (all_ci_cross_zero) {
  "Across all five Table 2A outcomes, adjusted FOF effects were small and 95% confidence intervals crossed zero, indicating no clear independent association with 12-month change in this dataset."
} else {
  "FOF effects were mixed across outcomes; interpretation is based on confidence intervals and model-adjusted estimates from Table 2A."
}

para1 <- paste0(
  headline, " Outcome-specific estimates were: ",
  paste(fof_fragments, collapse = "; "), "."
)

para2 <- paste0(
  "Frailty overall tests from the same models were: ",
  paste(frailty_fragments, collapse = "; "), ". ",
  "HGS (Women) was near conventional significance (p=", hgs_women_row$p_frailty_fmt, "), whereas HGS (Men) should be treated as exploratory because of small Model_N=",
  hgs_men_row$Model_N, " (group Ns ", hgs_men_row$N_without, "/", hgs_men_row$N_with, ")."
)

para3 <- paste0(
  "Model_N reflects complete cases for outcome and covariates in the regression model. ",
  "Because multiple outcomes are analyzed, findings should be interpreted cautiously as secondary/exploratory comparisons without multiplicity correction in this table."
)

md_lines <- c(
  "# Results Text from Table 2A (K24 V1.1)",
  "",
  para1,
  "",
  para2,
  "",
  para3
)

txt_lines <- c(para1, "", para2, "", para3)

writeLines(md_lines, con = out_md)
writeLines(txt_lines, con = out_txt)

append_artifact(
  label = "results_table2A_from_K24_v1_1_md",
  kind = "doc_md",
  path = out_md,
  n = nrow(tab2),
  notes = "K25 results text generated from K24 paper-ready Table 2A CSV"
)
append_artifact(
  label = "results_table2A_from_K24_v1_1_txt",
  kind = "text",
  path = out_txt,
  n = nrow(tab2),
  notes = "K25 plain-text results paragraph from K24 paper-ready Table 2A CSV"
)

session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = session_path)
append_artifact(
  label = "sessionInfo",
  kind = "sessioninfo",
  path = session_path,
  notes = "K25 sessionInfo + renv diagnostics"
)

cat("Saved:\n")
cat(" - ", out_md, "\n", sep = "")
cat(" - ", out_txt, "\n", sep = "")
cat(" - ", session_path, "\n", sep = "")
