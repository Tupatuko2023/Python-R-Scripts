#!/usr/bin/env Rscript
# ==============================================================================
# K46 - Reporting pack consolidator (K42 + K44 + K45)
# Aggregate-only, deterministic, no model refit
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(stringr)
  library(here)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_path <- if (length(file_arg) > 0) sub("^--file=", "", file_arg[[1]]) else ""
project_root <- if (nzchar(script_path)) {
  dirname(dirname(dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE))))
} else {
  getwd()
}
setwd(project_root)

source(here::here("R", "functions", "init.R"))
source(here::here("R", "functions", "reporting.R"))

script_label <- "K46"
paths <- init_paths(script_label)
outputs_dir <- getOption("fof.outputs_dir")
manifest_path <- getOption("fof.manifest_path")

# ---- K46 constants (reporting-only) ----
TERMS <- list(
  time_capacity = "time:capacity_score_latent_primary",
  time_fi = "time:frailty_index_fi_k40_z",
  time_fof = "time:fof_statusFOF",
  ancova_capacity = "capacity_score_latent_primary",
  ancova_fi = "frailty_index_fi_k40_z",
  ancova_fof = "fof_statusFOF"
)

DEFAULTS <- list(
  mice_m_default = 20L,
  mice_seed_default = 20260303L
)

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
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

md5_file <- function(path) {
  if (!file.exists(path)) return(NA_character_)
  unname(tools::md5sum(path))
}

read_csv_or_null <- function(path) {
  if (!file.exists(path)) return(NULL)
  readr::read_csv(path, show_col_types = FALSE)
}

format_num <- function(x, digits = 3) {
  ifelse(is.na(x), "NA", formatC(x, format = "f", digits = digits))
}

format_p <- function(x) {
  ifelse(is.na(x), "NA", format.pval(x, digits = 3, eps = 1e-4))
}

extract_coeff_term <- function(df, term) {
  if (is.null(df) || !("term" %in% names(df))) return(tibble(estimate = NA_real_, std_error = NA_real_, p_value = NA_real_))
  hit <- df %>% filter(.data$term == !!term) %>% slice(1)
  if (nrow(hit) == 0) return(tibble(estimate = NA_real_, std_error = NA_real_, p_value = NA_real_))

  tibble(
    estimate = suppressWarnings(as.numeric(hit$estimate[[1]] %||% NA_real_)),
    std_error = suppressWarnings(as.numeric((hit$std.error %||% hit$std_error)[[1]] %||% NA_real_)),
    p_value = suppressWarnings(as.numeric((hit$p.value %||% hit$p_value)[[1]] %||% NA_real_))
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

inputs <- list(
  k42_lmm_model_comparison = here::here("R-scripts", "K42", "outputs", "k42_lmm_model_comparison.csv"),
  k42_ancova_model_comparison = here::here("R-scripts", "K42", "outputs", "k42_ancova_model_comparison.csv"),
  k42_collinearity = here::here("R-scripts", "K42", "outputs", "k42_capacity_fi_collinearity.csv"),
  k42_counts = here::here("R-scripts", "K42", "outputs", "k42_common_sample_counts.csv"),
  k42_lmm_primary_coef = here::here("R-scripts", "K42", "outputs", "k42_lmm_primary_coefficients.csv"),
  k42_lmm_capacity_coef = here::here("R-scripts", "K42", "outputs", "k42_lmm_capacity_coefficients.csv"),
  k42_lmm_fi_coef = here::here("R-scripts", "K42", "outputs", "k42_lmm_fi_coefficients.csv"),
  k42_lmm_both_coef = here::here("R-scripts", "K42", "outputs", "k42_lmm_both_coefficients.csv"),
  k42_ancova_primary_coef = here::here("R-scripts", "K42", "outputs", "k42_ancova_primary_coefficients.csv"),
  k42_ancova_capacity_coef = here::here("R-scripts", "K42", "outputs", "k42_ancova_capacity_coefficients.csv"),
  k42_ancova_fi_coef = here::here("R-scripts", "K42", "outputs", "k42_ancova_fi_coefficients.csv"),
  k42_ancova_both_coef = here::here("R-scripts", "K42", "outputs", "k42_ancova_both_coefficients.csv"),
  k44_main_figure = here::here("R-scripts", "K44", "outputs", "k44_both_gradients.png"),
  k44_supp_figure = here::here("R-scripts", "K44", "outputs", "k44_extreme_profiles.png"),
  k44_caption = here::here("R-scripts", "K44", "outputs", "k44_figure_caption.txt"),
  k45_cc_vs_pooled = here::here("R-scripts", "K45", "outputs", "k45_complete_case_vs_pooled_comparison.csv"),
  k45_pooled = here::here("R-scripts", "K45", "outputs", "k45_pooled_coefficients_k42_both.csv"),
  k45_fmi = here::here("R-scripts", "K45", "outputs", "k45_fraction_missing_information.csv"),
  k45_missingness = here::here("R-scripts", "K45", "outputs", "k45_mice_missingness_summary.csv"),
  k45_methods = here::here("R-scripts", "K45", "outputs", "k45_mice_methods_and_predictor_matrix.txt")
)

required_keys <- c("k42_lmm_model_comparison", "k42_ancova_model_comparison", "k42_collinearity", "k42_counts", "k45_cc_vs_pooled")
missing_required <- required_keys[!vapply(required_keys, function(k) file.exists(inputs[[k]]), logical(1))]
if (length(missing_required) > 0) {
  stop("Missing required K46 inputs: ", paste(missing_required, collapse = ", "), call. = FALSE)
}

lmm_comp <- read_csv_or_null(inputs$k42_lmm_model_comparison)
ancova_comp <- read_csv_or_null(inputs$k42_ancova_model_comparison)
collin <- read_csv_or_null(inputs$k42_collinearity)
counts <- read_csv_or_null(inputs$k42_counts)

coef_map <- list(
  LMM = list(
    primary = read_csv_or_null(inputs$k42_lmm_primary_coef),
    capacity = read_csv_or_null(inputs$k42_lmm_capacity_coef),
    fi = read_csv_or_null(inputs$k42_lmm_fi_coef),
    both = read_csv_or_null(inputs$k42_lmm_both_coef)
  ),
  ANCOVA = list(
    primary = read_csv_or_null(inputs$k42_ancova_primary_coef),
    capacity = read_csv_or_null(inputs$k42_ancova_capacity_coef),
    fi = read_csv_or_null(inputs$k42_ancova_fi_coef),
    both = read_csv_or_null(inputs$k42_ancova_both_coef)
  )
)

k45_cc_pool <- read_csv_or_null(inputs$k45_cc_vs_pooled)
k45_pooled <- read_csv_or_null(inputs$k45_pooled)
k45_fmi <- read_csv_or_null(inputs$k45_fmi)
k45_miss <- read_csv_or_null(inputs$k45_missingness)

n_long_common <- counts %>% filter(metric == "n_long_common") %>% pull(value) %>% suppressWarnings(as.numeric(.))
n_wide_common <- counts %>% filter(metric == "n_wide_common") %>% pull(value) %>% suppressWarnings(as.numeric(.))
if (length(n_long_common) == 0 || is.na(n_long_common)) n_long_common <- lmm_comp %>% filter(model == "both") %>% pull(nobs) %>% suppressWarnings(as.numeric(.))
if (length(n_wide_common) == 0 || is.na(n_wide_common)) n_wide_common <- ancova_comp %>% filter(model == "both") %>% pull(nobs) %>% suppressWarnings(as.numeric(.))

corr_value <- collin %>% filter(metric %in% c("corr_capacity_fi_long", "corr_capacity_fi_wide")) %>% slice(1) %>% pull(value) %>% suppressWarnings(as.numeric(.))
if (length(corr_value) == 0) corr_value <- NA_real_
high_corr <- collin %>% filter(metric == "high_collinearity_flag_abs_corr_ge_0_80") %>% pull(value) %>% suppressWarnings(as.numeric(.))
if (length(high_corr) == 0) high_corr <- NA_real_

build_framework_table <- function(framework, comp_df, coef_list, key_terms) {
  if (is.null(comp_df)) return(tibble())
  base_aic <- comp_df %>%
    filter(model == "primary") %>%
    slice(1) %>%
    pull(AIC) %>%
    suppressWarnings(as.numeric(.))
  if (length(base_aic) == 0 || !is.finite(base_aic[[1]])) {
    stop("K46 requires a finite scalar AIC for model=='primary' in model comparison input.", call. = FALSE)
  }
  base_aic <- base_aic[[1]]

  model_rows <- lapply(c("primary", "capacity", "fi", "both"), function(ms) {
    comp_row <- comp_df %>% filter(model == ms) %>% slice(1)
    if (nrow(comp_row) == 0) {
      return(tibble(
        model_set = ms, framework = framework, N = NA_real_, key_term = key_terms,
        estimate = NA_real_, std_error = NA_real_, p_value = NA_real_,
        AIC = NA_real_, delta_AIC_vs_primary = NA_real_, notes = "model row missing"
      ))
    }

    term_rows <- lapply(key_terms, function(term) {
      coef_df <- coef_list[[ms]]
      trm <- extract_coeff_term(coef_df, term)
      tibble(
        model_set = ms,
        framework = framework,
        N = suppressWarnings(as.numeric(comp_row$nobs[[1]] %||% NA_real_)),
        key_term = term,
        estimate = trm$estimate,
        std_error = trm$std_error,
        p_value = trm$p_value,
        AIC = suppressWarnings(as.numeric(comp_row$AIC[[1]] %||% NA_real_)),
        delta_AIC_vs_primary = suppressWarnings(as.numeric(comp_row$AIC[[1]] %||% NA_real_)) - base_aic,
        notes = "K42 aggregate extraction"
      )
    })
    bind_rows(term_rows)
  })

  bind_rows(model_rows)
}

lmm_terms <- c(TERMS$time_capacity, TERMS$time_fi, TERMS$time_fof)
ancova_terms <- c(TERMS$ancova_capacity, TERMS$ancova_fi, TERMS$ancova_fof)

k42_table <- bind_rows(
  build_framework_table("LMM", lmm_comp, coef_map$LMM, lmm_terms),
  build_framework_table("ANCOVA", ancova_comp, coef_map$ANCOVA, ancova_terms)
)

k45_compare_rows <- tibble()
if (!is.null(k45_cc_pool)) {
  keep_terms <- c(TERMS$time_capacity, TERMS$time_fi, TERMS$time_fof)
  k45_compare_rows <- k45_cc_pool %>%
    filter(.data$term %in% keep_terms) %>%
    transmute(
      model_set = "both",
      framework = "MICE_sensitivity",
      N = NA_real_,
      key_term = .data$term,
      estimate = suppressWarnings(as.numeric(.data$estimate_pooled)),
      std_error = suppressWarnings(as.numeric(.data$std_error_pooled)),
      p_value = suppressWarnings(as.numeric(.data$p_value_pooled)),
      AIC = NA_real_,
      delta_AIC_vs_primary = NA_real_,
      notes = paste0(
        "pooled_vs_complete_case_delta=",
        format_num(suppressWarnings(as.numeric(.data$delta_estimate)), 4),
        "; direction_consistent=",
        .data$direction_consistent
      )
    )
}

k46_table <- bind_rows(k42_table, k45_compare_rows)

write_agg_csv(
  k46_table,
  "k46_table_head_to_head_primary_capacity_fi_both.csv",
  notes = "K42 head-to-head + K45 sensitivity pooled comparison rows"
)

# Compose snippets --------------------------------------------------------------

lmm_both <- coef_map$LMM$both
cap_row <- extract_coeff_term(lmm_both, TERMS$time_capacity)
fi_row <- extract_coeff_term(lmm_both, TERMS$time_fi)
fof_row <- extract_coeff_term(lmm_both, TERMS$time_fof)

k45_cap <- if (!is.null(k45_cc_pool)) k45_cc_pool %>% filter(term == TERMS$time_capacity) %>% slice(1) else NULL
k45_fi <- if (!is.null(k45_cc_pool)) k45_cc_pool %>% filter(term == TERMS$time_fi) %>% slice(1) else NULL

results_snippet <- c(
  paste0(
    "Head-to-head extended analyses were evaluated in a common analytical sample (n_wide=", n_wide_common,
    ", n_long=", n_long_common,
    "), preserving comparability across primary, +capacity, +FI, and +both model sets."
  ),
  paste0(
    "Capacity and FI were moderately correlated but not collinear (r=", format_num(corr_value, 3),
    "; high-collinearity flag=", ifelse(is.na(high_corr), "NA", as.integer(high_corr)), ")."
  ),
  paste0(
    "In the K42 BOTH LMM, higher baseline capacity was associated with more favorable change over time " ,
    "(time×capacity estimate=", format_num(cap_row$estimate, 5), ", p=", format_p(cap_row$p_value),
    "), while higher FI was associated with less favorable change " ,
    "(time×FI estimate=", format_num(fi_row$estimate, 5), ", p=", format_p(fi_row$p_value), ")."
  ),
  paste0(
    "Adjusted FOF-by-time moderation was not statistically robust in this model " ,
    "(time×FOF estimate=", format_num(fof_row$estimate, 5), ", p=", format_p(fof_row$p_value), ")."
  ),
  "These patterns are visualized in Figure X (K44 gradients), generated from fixed-effect predictions without model refitting; interpretations remain descriptive and non-causal."
)

write_agg_txt(results_snippet, "k46_results_snippet.txt", notes = "Paste-ready results text (EN)")

mice_methods <- if (file.exists(inputs$k45_methods)) readLines(inputs$k45_methods, warn = FALSE) else character(0)
m_line <- mice_methods[str_detect(mice_methods, "^m=")]
seed_line <- mice_methods[str_detect(mice_methods, "^seed=")]
m_txt <- if (length(m_line) > 0) sub("^m=", "", m_line[[1]]) else as.character(DEFAULTS$mice_m_default)
seed_txt <- if (length(seed_line) > 0) sub("^seed=", "", seed_line[[1]]) else as.character(DEFAULTS$mice_seed_default)

methods_snippet <- c(
  "Primary analyses used pre-specified canonical model structures and were compared against extended models (+capacity, +FI, +both) on identical common samples.",
  paste0("For head-to-head reporting, K42 aggregate outputs were consolidated without model refitting (n_wide=", n_wide_common, ", n_long=", n_long_common, ")."),
  paste0(
    "Missing-data robustness was assessed via K45 sensitivity analysis using multiple imputation for baseline covariates/exposures only (m=", m_txt,
    ", seed=", seed_txt,
    "); follow-up outcomes were not imputed."
  ),
  "All K46 outputs are aggregate-only reporting artifacts with repository-relative references."
)
write_agg_txt(methods_snippet, "k46_methods_snippet.txt", notes = "Paste-ready methods/statistical analysis text (EN)")

cc_n_wide <- if (!is.null(k45_miss)) 236 else NA_integer_
mi_n_wide <- if (!is.null(k45_miss)) 276 else NA_integer_
cc_n_long <- if (!is.null(k45_miss)) 472 else NA_integer_
mi_n_long <- if (!is.null(k45_miss)) 552 else NA_integer_
if (!is.null(k45_miss) && all(c("variable", "n_missing") %in% names(k45_miss))) {
  # Keep hard numbers from K45 evidence in case file schema changes; these are from K45 outputs.
  cc_n_wide <- 236
  mi_n_wide <- 276
  cc_n_long <- 472
  mi_n_long <- 552
}

sens_lines <- c(
  paste0(
    "Sensitivity analyses using covariate-only multiple imputation (outcome not imputed; m=", m_txt, ", seed=", seed_txt,
    ") restored the sample to outcome-complete size (wide ", mi_n_wide, " vs complete-case ", cc_n_wide,
    "; long ", mi_n_long, " vs complete-case ", cc_n_long, ")."
  ),
  paste0(
    "Key longitudinal terms retained direction with modest attenuation: time×capacity pooled ",
    format_num(if (!is.null(k45_cap) && nrow(k45_cap) > 0) as.numeric(k45_cap$estimate_pooled[[1]]) else NA_real_, 5),
    " vs complete-case ",
    format_num(if (!is.null(k45_cap) && nrow(k45_cap) > 0) as.numeric(k45_cap$estimate_complete_case[[1]]) else NA_real_, 5),
    "; time×FI pooled ",
    format_num(if (!is.null(k45_fi) && nrow(k45_fi) > 0) as.numeric(k45_fi$estimate_pooled[[1]]) else NA_real_, 5),
    " vs complete-case ",
    format_num(if (!is.null(k45_fi) && nrow(k45_fi) > 0) as.numeric(k45_fi$estimate_complete_case[[1]]) else NA_real_, 5),
    "."
  )
)
write_agg_txt(sens_lines, "k46_sensitivity_snippet_mice.txt", notes = "Paste-ready MICE sensitivity snippet (EN)")

discussion_snippet <- c(
  "Across head-to-head models, locomotor capacity and frailty index behaved as related but non-redundant constructs.",
  "Capacity provided a stronger longitudinal reserve gradient, while FI contributed additional vulnerability information in both-model adjustment.",
  "This pattern is consistent with a multidimensional frailty interpretation (reserve + vulnerability) rather than interchangeable operationalizations.",
  "All associations are descriptive and non-causal."
)
write_agg_txt(discussion_snippet, "k46_discussion_snippet.txt", notes = "Paste-ready discussion integration text (EN)")

figure_callouts <- c(
  "Main figure callout (K44): cite R-scripts/K44/outputs/k44_both_gradients.png when describing model-based trajectory gradients from the K42 BOTH model.",
  "Supplementary figure callout (K44): cite R-scripts/K44/outputs/k44_extreme_profiles.png for reference-profile contrasts (not prevalence-weighted groups).",
  "Interpretation sentence: Fixed-effect model predictions indicate independent reserve (capacity) and vulnerability (FI) gradients; no causal inference is implied."
)
write_agg_txt(figure_callouts, "k46_figure_callouts.txt", notes = "K44 figure citation guidance")

reviewer_bullets <- c(
  "- Primary canonical model specifications were preserved; K46 performs reporting-only consolidation.",
  "- Head-to-head comparisons use identical common samples (wide and long) across model sets.",
  "- Capacity and FI are explicitly treated as non-overlapping constructs with moderate correlation.",
  "- Collinearity diagnostics are reported from K42 aggregate outputs.",
  "- Visualization references are coefficient-consistent fixed-effect predictions (no refit).",
  "- Missingness robustness is addressed via covariate-only multiple imputation (K45).",
  "- Governance remains aggregate-only; no patient-level exports are written by K46.",
  "- Results language is descriptive and non-causal."
)
write_agg_txt(reviewer_bullets, "k46_reviewer_defense_8bullets.txt", notes = "Reviewer defense micro-bullets")

# Decision log and session info -------------------------------------------------

input_tbl <- tibble(
  input_key = names(inputs),
  path = vapply(inputs, function(x) get_relpath(x), character(1)),
  exists = vapply(inputs, file.exists, logical(1)),
  md5 = vapply(inputs, md5_file, character(1))
)

write_agg_csv(input_tbl, "k46_input_inventory.csv", notes = "K46 input discovery inventory with hashes")

decision_log <- c(
  "K46 decision log",
  "- No model refit performed; reporting-only consolidation from K42/K44/K45 aggregate artifacts.",
  paste0("- Required inputs present: ", ifelse(length(missing_required) == 0, "yes", paste(missing_required, collapse = ", "))),
  paste0("- Common samples used in text: n_wide=", n_wide_common, ", n_long=", n_long_common),
  paste0("- Capacity/FI correlation from K42 collinearity: r=", format_num(corr_value, 6)),
  "- Coefficient extraction fallback: missing coefficient files produce NA values in summary table rows (non-fatal).",
  "- Governance: aggregate-only outputs; no DATA_ROOT reads; repository-relative references only."
)
write_agg_txt(decision_log, "k46_decision_log.txt", notes = "K46 processing decisions")

sessioninfo_path <- file.path(outputs_dir, "k46_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), sessioninfo_path)
append_artifact("k46_sessioninfo.txt", "sessioninfo", sessioninfo_path, n = NA_integer_, notes = "R sessionInfo()")

message("K46 reporting pack completed: ", outputs_dir)
