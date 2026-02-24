#!/usr/bin/env Rscript
# ==============================================================================
# K25_RESULTS - Canonical Results text from K24 Table 2A canonical CSV (V2)
# File tag: K25_RESULTS.V2_table2A-results-text-canonical.R
# Purpose: Deterministic table-to-text generator for K24 canonical rerun outputs.
#
# Default input:
# - R-scripts/K24/outputs/K24_TABLE2A/table2A_paper_ready_canonical_cat_v2.csv
#
# Outputs:
# - results_table2A_from_K24_canonical_v2.md
# - results_table2A_from_K24_canonical_v2.txt
# - results_table2A_from_K24_canonical_v2_narrative.md
# - results_table2A_from_K24_canonical_v2_narrative.txt
# - sessionInfo_v2.txt
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(stringr)
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
    style = "both"
  )
  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--style=")) out$style <- tolower(sub("^--style=", "", arg))
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
  nums <- str_extract_all(as.character(x), "[-+]?[0-9]*\\.?[0-9]+")[[1]]
  if (length(nums) < 3) return(c(NA_real_, NA_real_, NA_real_))
  c(as.numeric(nums[1]), as.numeric(nums[2]), as.numeric(nums[3]))
}

fmt_p <- function(x) {
  p <- suppressWarnings(as.numeric(x))
  if (is.na(p)) return(as.character(x))
  if (p < 0.001) return("<0.001")
  sprintf("%.3f", p)
}

build_text <- function(tab2, style = c("list", "narrative")) {
  style <- match.arg(style)
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
      as.character(r$Outcome), ": beta ", as.character(r$FOF_Beta_CI),
      ", p=", r$p_fof_fmt,
      ", Model_N=", r$Model_N,
      ", group Ns=", r$N_without, "/", r$N_with
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
    "Across all five Table 2A outcomes, adjusted FOF effects were small and imprecise, with 95% confidence intervals crossing zero, indicating no clear independent association with 12-month change in this dataset."
  } else {
    "FOF effects were mixed across outcomes; interpretation is based on confidence intervals and model-adjusted estimates from Table 2A."
  }

  provenance_sentence <- "Frailty variables were derived using the K15 canonical pipeline (K15_RData input; no fallback derivation)."

  if (style == "narrative") {
    para1 <- headline
    para2 <- paste0("Outcome-specific estimates were: ", paste(fof_fragments, collapse = "; "), ".")
    para3 <- paste0(
      "Frailty overall tests from the same models were: ",
      paste(frailty_fragments, collapse = "; "), ". ",
      "HGS (Women) was near conventional significance (p=", hgs_women_row$p_frailty_fmt,
      "), whereas HGS (Men) should be interpreted as exploratory because of small Model_N=",
      hgs_men_row$Model_N, " (group Ns ", hgs_men_row$N_without, "/", hgs_men_row$N_with, ")."
    )
    para4 <- paste0(
      "Model_N reflects complete cases for outcome and covariates in the regression model. ",
      "Because multiple outcomes are analyzed, findings should be interpreted cautiously as secondary/exploratory comparisons without multiplicity correction in this table."
    )

    md_lines <- c(
      "# Results Text from Table 2A (K24 canonical V2)",
      "", para1,
      "", para2,
      "", para3,
      "", para4,
      "", provenance_sentence
    )
    txt_lines <- c(para1, "", para2, "", para3, "", para4, "", provenance_sentence)
  } else {
    para1 <- paste0(headline, " Outcome-specific estimates were: ", paste(fof_fragments, collapse = "; "), ".")
    para2 <- paste0(
      "Frailty overall tests from the same models were: ",
      paste(frailty_fragments, collapse = "; "), ". ",
      "HGS (Women) was near conventional significance (p=", hgs_women_row$p_frailty_fmt,
      "), whereas HGS (Men) should be interpreted as exploratory because of small Model_N=",
      hgs_men_row$Model_N, " (group Ns ", hgs_men_row$N_without, "/", hgs_men_row$N_with, ")."
    )
    para3 <- paste0(
      "Model_N reflects complete cases for outcome and covariates in the regression model. ",
      "Because multiple outcomes are analyzed, findings should be interpreted cautiously as secondary/exploratory comparisons without multiplicity correction in this table."
    )

    md_lines <- c(
      "# Results Text from Table 2A (K24 canonical V2)",
      "", para1,
      "", para2,
      "", para3,
      "", provenance_sentence
    )
    txt_lines <- c(para1, "", para2, "", para3, "", provenance_sentence)
  }

  list(md = md_lines, txt = txt_lines)
}

cli <- parse_cli(commandArgs(trailingOnly = TRUE))
if (!cli$style %in% c("list", "narrative", "both")) {
  stop("Unsupported --style. Use list/narrative/both")
}

input_path <- if (!is.na(cli$input) && nzchar(cli$input)) {
  cli$input
} else {
  here::here("R-scripts", "K24", "outputs", "K24_TABLE2A", "table2A_paper_ready_canonical_cat_v2.csv")
}
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
if (nrow(tab2) != 5) stop("Expected exactly 5 outcomes in canonical paper-ready CSV.")

out_list_md <- file.path(outputs_dir, "results_table2A_from_K24_canonical_v2.md")
out_list_txt <- file.path(outputs_dir, "results_table2A_from_K24_canonical_v2.txt")
out_narr_md <- file.path(outputs_dir, "results_table2A_from_K24_canonical_v2_narrative.md")
out_narr_txt <- file.path(outputs_dir, "results_table2A_from_K24_canonical_v2_narrative.txt")
session_path <- file.path(outputs_dir, "sessionInfo_v2.txt")

if (cli$style %in% c("list", "both")) {
  t1 <- build_text(tab2, "list")
  writeLines(t1$md, con = out_list_md)
  writeLines(t1$txt, con = out_list_txt)
  append_artifact("results_table2A_from_K24_canonical_v2_md", "doc_md", out_list_md, nrow(tab2), "K25 V2 list style results text from K24 canonical CSV")
  append_artifact("results_table2A_from_K24_canonical_v2_txt", "text", out_list_txt, nrow(tab2), "K25 V2 list style plain text from K24 canonical CSV")
}

if (cli$style %in% c("narrative", "both")) {
  t2 <- build_text(tab2, "narrative")
  writeLines(t2$md, con = out_narr_md)
  writeLines(t2$txt, con = out_narr_txt)
  append_artifact("results_table2A_from_K24_canonical_v2_narrative_md", "doc_md", out_narr_md, nrow(tab2), "K25 V2 narrative results text from K24 canonical CSV")
  append_artifact("results_table2A_from_K24_canonical_v2_narrative_txt", "text", out_narr_txt, nrow(tab2), "K25 V2 narrative plain text from K24 canonical CSV")
}

session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = session_path)
append_artifact("sessionInfo_v2", "sessioninfo", session_path, notes = "K25 V2 sessionInfo + renv diagnostics")

cat("Saved K25 V2 outputs in:", outputs_dir, "\n")
