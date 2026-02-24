#!/usr/bin/env Rscript
# ==============================================================================
# K26_VIS - Reviewer figure set for predicted Delta Composite_Z
# File tag: K26_VIS.V1_composite-delta-predicted-plots.R
# Purpose: Visualize K26 model predictions (no analysis logic changes).
# Inputs: K26 moderation model RDS objects + canonical K15 RData.
# Outputs: PNG/PDF figures + provenance + qc summary + sessionInfo + manifest rows.
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tidyr)
  library(tibble)
  library(stringr)
  library(ggplot2)
  library(emmeans)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K26_VIS"
}
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K26_VIS"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths("K26")
manifest_path <- paths$manifest_path

parse_cli <- function(args) {
  out <- list(
    model_cat_rds = here::here("R-scripts", "K26", "outputs", "K26", "K26_LMM_MOD", "K26_model_moderation_cat.rds"),
    model_score_rds = here::here("R-scripts", "K26", "outputs", "K26", "K26_LMM_MOD", "K26_model_moderation_score.rds"),
    data_input = here::here("R-scripts", "K15", "outputs", "K15_frailty_analysis_data.RData"),
    output_dir = here::here("R-scripts", "K26", "outputs", "K26_VIS"),
    format = "both",
    grid_n = 50,
    show_points = FALSE,
    include_score_plot = TRUE,
    width = 9,
    height = 6
  )

  for (arg in args) {
    if (startsWith(arg, "--model_cat_rds=")) out$model_cat_rds <- sub("^--model_cat_rds=", "", arg)
    if (startsWith(arg, "--model_score_rds=")) out$model_score_rds <- sub("^--model_score_rds=", "", arg)
    if (startsWith(arg, "--input=")) out$data_input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--data_input=")) out$data_input <- sub("^--data_input=", "", arg)
    if (startsWith(arg, "--output_dir=")) out$output_dir <- sub("^--output_dir=", "", arg)
    if (startsWith(arg, "--format=")) out$format <- tolower(sub("^--format=", "", arg))
    if (startsWith(arg, "--grid_n=")) out$grid_n <- suppressWarnings(as.integer(sub("^--grid_n=", "", arg)))
    if (startsWith(arg, "--show_points=")) out$show_points <- tolower(sub("^--show_points=", "", arg)) %in% c("true", "1", "yes", "y")
    if (startsWith(arg, "--include_score_plot=")) out$include_score_plot <- tolower(sub("^--include_score_plot=", "", arg)) %in% c("true", "1", "yes", "y")
    if (startsWith(arg, "--width=")) out$width <- suppressWarnings(as.numeric(sub("^--width=", "", arg)))
    if (startsWith(arg, "--height=")) out$height <- suppressWarnings(as.numeric(sub("^--height=", "", arg)))
  }

  if (!out$format %in% c("png", "pdf", "both")) stop("Invalid --format. Use png|pdf|both")
  if (!is.finite(out$grid_n) || out$grid_n < 10) stop("Invalid --grid_n; use integer >= 10")
  if (!is.finite(out$width) || out$width <= 0 || !is.finite(out$height) || out$height <= 0) stop("Invalid width/height")
  out
}

first_existing <- function(df, candidates) {
  hit <- candidates[candidates %in% names(df)]
  if (length(hit) == 0) return(NA_character_)
  hit[1]
}

normalize_fof <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  if (is.numeric(x) || is.integer(x)) {
    return(factor(ifelse(x == 1, "FOF", "nonFOF"), levels = c("nonFOF", "FOF")))
  }
  xc <- tolower(trimws(as.character(x)))
  out <- ifelse(xc %in% c("1", "fof", "with fof"), "FOF",
                ifelse(xc %in% c("0", "nonfof", "ei fof", "without fof"), "nonFOF", NA_character_))
  factor(out, levels = c("nonFOF", "FOF"))
}

normalize_sex <- function(x) {
  xc <- tolower(trimws(as.character(x)))
  female_set <- c("0", "2", "f", "female", "woman", "nainen")
  male_set <- c("1", "m", "male", "man", "mies")
  out <- rep(NA_character_, length(xc))
  out[xc %in% female_set] <- "female"
  out[xc %in% male_set] <- "male"
  factor(out, levels = c("female", "male"))
}

normalize_frailty_cat <- function(x) {
  xc <- tolower(trimws(as.character(x)))
  out <- dplyr::case_when(
    xc %in% c("robust", "0") ~ "Robust",
    xc %in% c("pre-frail", "prefrail", "1") ~ "Pre-frail",
    xc %in% c("frail", "2", "3") ~ "Frail",
    TRUE ~ NA_character_
  )
  factor(out, levels = c("Robust", "Pre-frail", "Frail"))
}

fmt_p <- function(p) {
  p <- suppressWarnings(as.numeric(p))
  vapply(p, function(px) {
    if (is.na(px)) return("")
    if (px < 0.001) return("<0.001")
    sprintf("%.3f", px)
  }, character(1))
}

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  rel_path <- get_relpath(path)
  if (file.exists(manifest_path)) {
    existing <- tryCatch(readr::read_csv(manifest_path, show_col_types = FALSE), error = function(e) NULL)
    if (!is.null(existing) && all(c("script", "label", "kind", "path") %in% names(existing))) {
      hit <- existing %>% filter(.data$script == script_label, .data$label == label, .data$kind == kind, .data$path == rel_path)
      if (nrow(hit) > 0) return(invisible(FALSE))
    }
  }
  append_manifest(
    manifest_row(script = script_label, label = label, path = rel_path, kind = kind, n = n, notes = notes),
    manifest_path
  )
  invisible(TRUE)
}

load_rdata_input <- function(path) {
  e <- new.env(parent = emptyenv())
  objs <- load(path, envir = e)
  if ("analysis_data" %in% objs) {
    d <- get("analysis_data", envir = e)
    if (inherits(d, c("data.frame", "tbl_df", "tbl"))) return(d)
  }
  candidates <- objs[vapply(objs, function(nm) inherits(get(nm, envir = e), c("data.frame", "tbl_df", "tbl")), logical(1))]
  if (length(candidates) == 0) stop("No data.frame object found in data_input RData: ", path)
  get(candidates[1], envir = e)
}

save_plot <- function(plot_obj, base_name, cfg, records) {
  if (cfg$format %in% c("png", "both")) {
    p_png <- file.path(cfg$fig_dir, paste0(base_name, ".png"))
    ggplot2::ggsave(filename = p_png, plot = plot_obj, width = cfg$width, height = cfg$height, dpi = 300)
    records[[length(records) + 1L]] <- list(label = paste0(base_name, "_png"), kind = "figure_png", path = p_png)
  }
  if (cfg$format %in% c("pdf", "both")) {
    p_pdf <- file.path(cfg$fig_dir, paste0(base_name, ".pdf"))
    ggplot2::ggsave(filename = p_pdf, plot = plot_obj, width = cfg$width, height = cfg$height, device = grDevices::cairo_pdf)
    records[[length(records) + 1L]] <- list(label = paste0(base_name, "_pdf"), kind = "figure_pdf", path = p_pdf)
  }
  records
}

cfg <- parse_cli(commandArgs(trailingOnly = TRUE))
if (!file.exists(cfg$model_cat_rds)) stop("Missing model_cat_rds: ", cfg$model_cat_rds)
if (!file.exists(cfg$data_input)) stop("Missing data_input RData: ", cfg$data_input)

cfg$output_dir <- normalizePath(cfg$output_dir, winslash = "/", mustWork = FALSE)
cfg$fig_dir <- file.path(cfg$output_dir, "figures")
dir.create(cfg$fig_dir, recursive = TRUE, showWarnings = FALSE)

m_cat <- readRDS(cfg$model_cat_rds)
m_score <- if (isTRUE(cfg$include_score_plot) && file.exists(cfg$model_score_rds)) readRDS(cfg$model_score_rds) else NULL
raw <- load_rdata_input(cfg$data_input)

col_age <- first_existing(raw, c("age"))
col_bmi <- first_existing(raw, c("BMI"))
col_sex <- first_existing(raw, c("sex"))
col_fof <- first_existing(raw, c("FOF_status", "kaatumisenpelkoOn"))
col_fcat <- first_existing(raw, c("frailty_cat_3"))
col_fscore <- first_existing(raw, c("frailty_score_3"))
col_cz0 <- first_existing(raw, c("Composite_Z0", "ToimintaKykySummary0"))
col_cz12 <- first_existing(raw, c("Composite_Z12", "ToimintaKykySummary2"))
col_bal <- first_existing(raw, c("Balance_problem", "tasapainovaikeus"))

need <- c(col_age, col_bmi, col_sex, col_fof, col_fcat, col_fscore, col_cz0, col_cz12)
if (any(is.na(need))) stop("Missing required canonical columns in data_input for K26_VIS")

wide <- raw %>%
  transmute(
    age = suppressWarnings(as.numeric(.data[[col_age]])),
    BMI = suppressWarnings(as.numeric(.data[[col_bmi]])),
    sex = normalize_sex(.data[[col_sex]]),
    FOF_status = normalize_fof(.data[[col_fof]]),
    frailty_cat_3 = normalize_frailty_cat(.data[[col_fcat]]),
    frailty_score_3 = suppressWarnings(as.numeric(.data[[col_fscore]])),
    Balance_problem = if (!is.na(col_bal)) suppressWarnings(as.numeric(.data[[col_bal]])) else NA_real_,
    Composite_Z0 = suppressWarnings(as.numeric(.data[[col_cz0]])),
    Composite_Z12 = suppressWarnings(as.numeric(.data[[col_cz12]]))
  ) %>%
  mutate(
    cComposite_Z0 = Composite_Z0 - mean(Composite_Z0, na.rm = TRUE),
    Delta_Composite_Z = Composite_Z12 - Composite_Z0
  )

mean_age <- mean(wide$age, na.rm = TRUE)
mean_bmi <- mean(wide$BMI, na.rm = TRUE)
sex_ref <- names(sort(table(wide$sex), decreasing = TRUE))[1]
sex_ref <- ifelse(length(sex_ref) == 0 || is.na(sex_ref), "female", sex_ref)

bal_mean <- if ("Balance_problem" %in% names(model.frame(m_cat)) && !all(is.na(wide$Balance_problem))) {
  mean(wide$Balance_problem, na.rm = TRUE)
} else {
  NULL
}

# Figure 1: predicted delta by frailty_cat_3 x FOF_status
at_fig1 <- list(age = mean_age, BMI = mean_bmi, sex = sex_ref, cComposite_Z0 = 0)
if (!is.null(bal_mean)) at_fig1$Balance_problem <- bal_mean

emm_fig1 <- emmeans::emmeans(
  m_cat,
  ~ time_f | FOF_status * frailty_cat_3,
  at = at_fig1
)
fig1_delta <- as_tibble(summary(emmeans::contrast(
  emm_fig1,
  method = list(delta_12_0 = c(-1, 1)),
  by = c("FOF_status", "frailty_cat_3")
), infer = TRUE)) %>%
  transmute(
    FOF_status,
    frailty_cat_3,
    estimate,
    lower.CL,
    upper.CL,
    p.value,
    label = paste0("p=", fmt_p(p.value))
  )

p1 <- ggplot(fig1_delta, aes(x = estimate, y = frailty_cat_3, color = FOF_status)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lower.CL, xmax = upper.CL), height = 0.16, position = position_dodge(width = 0.5)) +
  geom_point(position = position_dodge(width = 0.5), size = 2.8) +
  geom_text(aes(label = label), position = position_dodge(width = 0.5), nudge_y = 0.18, hjust = 0, show.legend = FALSE, size = 3.0) +
  labs(
    title = "K26 VIS: Predicted ΔComposite_Z by frailty category and FOF",
    subtitle = "Estimated marginal change (12-0) with 95% CI; covariates fixed",
    x = "Predicted ΔComposite_Z (12-0)",
    y = "Frailty category",
    color = "FOF status"
  ) +
  theme_minimal(base_size = 12)

# Figure 2: moderation plot Delta vs baseline by frailty_cat_3 x FOF_status
c0_range <- range(wide$cComposite_Z0, na.rm = TRUE)
grid_vals <- seq(c0_range[1], c0_range[2], length.out = cfg$grid_n)
at_fig2 <- list(age = mean_age, BMI = mean_bmi, sex = sex_ref, cComposite_Z0 = grid_vals)
if (!is.null(bal_mean)) at_fig2$Balance_problem <- bal_mean

emm_fig2 <- emmeans::emmeans(
  m_cat,
  ~ time_f | FOF_status * frailty_cat_3 * cComposite_Z0,
  at = at_fig2
)
fig2_delta <- as_tibble(summary(emmeans::contrast(
  emm_fig2,
  method = list(delta_12_0 = c(-1, 1)),
  by = c("FOF_status", "frailty_cat_3", "cComposite_Z0")
), infer = TRUE)) %>%
  transmute(
    FOF_status,
    frailty_cat_3,
    cComposite_Z0,
    estimate,
    lower.CL,
    upper.CL
  )

p2 <- ggplot(fig2_delta, aes(x = cComposite_Z0, y = estimate, color = FOF_status, fill = FOF_status)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_ribbon(aes(ymin = lower.CL, ymax = upper.CL), alpha = 0.18, color = NA) +
  geom_line(linewidth = 0.9) +
  facet_wrap(~ frailty_cat_3, nrow = 1) +
  labs(
    title = "K26 VIS: Moderation of predicted ΔComposite_Z by baseline Composite_Z0",
    subtitle = "Predicted change (12-0) across baseline centered Composite_Z0, by frailty and FOF",
    x = "Baseline Composite_Z0 (centered)",
    y = "Predicted ΔComposite_Z (12-0)",
    color = "FOF status",
    fill = "FOF status"
  ) +
  theme_minimal(base_size = 12)

# Optional Figure 3: score-mode delta by frailty score and FOF
fig3_delta <- NULL
p3 <- NULL
if (!is.null(m_score)) {
  score_vals <- sort(unique(as.integer(round(wide$frailty_score_3))))
  score_vals <- score_vals[score_vals %in% 0:3]
  if (length(score_vals) > 0) {
    at_fig3 <- list(age = mean_age, BMI = mean_bmi, sex = sex_ref, cComposite_Z0 = 0, frailty_score_3 = score_vals)
    if (!is.null(bal_mean)) at_fig3$Balance_problem <- bal_mean

    emm_fig3 <- emmeans::emmeans(
      m_score,
      ~ time_f | FOF_status * frailty_score_3,
      at = at_fig3
    )
    fig3_delta <- as_tibble(summary(emmeans::contrast(
      emm_fig3,
      method = list(delta_12_0 = c(-1, 1)),
      by = c("FOF_status", "frailty_score_3")
    ), infer = TRUE)) %>%
      transmute(
        FOF_status,
        frailty_score_3,
        estimate,
        lower.CL,
        upper.CL,
        p.value
      )

    p3 <- ggplot(fig3_delta, aes(x = frailty_score_3, y = estimate, color = FOF_status, group = FOF_status)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
      geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL), width = 0.08, alpha = 0.7) +
      geom_line(linewidth = 0.9) +
      geom_point(size = 2.6) +
      scale_x_continuous(breaks = score_vals) +
      labs(
        title = "K26 VIS: Predicted ΔComposite_Z by frailty score and FOF",
        subtitle = "Score-mode sensitivity (per frailty score level; baseline fixed at mean)",
        x = "Frailty score (0-3)",
        y = "Predicted ΔComposite_Z (12-0)",
        color = "FOF status"
      ) +
      theme_minimal(base_size = 12)
  }
}

records <- list()
records <- save_plot(p1, "K26_VIS_predicted_delta_by_frailtycat_x_fof", cfg, records)
records <- save_plot(p2, "K26_VIS_moderation_delta_vs_baseline_by_frailtycat", cfg, records)
if (!is.null(p3)) {
  records <- save_plot(p3, "K26_VIS_predicted_delta_by_frailtyscore_x_fof", cfg, records)
}

# QC summary
qc_rows <- list(
  tibble(check = "fig1_all_cells_present", pass = nrow(fig1_delta) >= 6, detail = paste0("rows=", nrow(fig1_delta))),
  tibble(check = "fig2_grid_rows", pass = nrow(fig2_delta) >= (cfg$grid_n * 6), detail = paste0("rows=", nrow(fig2_delta), ", grid_n=", cfg$grid_n)),
  tibble(check = "fig1_no_na", pass = all(is.finite(fig1_delta$estimate) & is.finite(fig1_delta$lower.CL) & is.finite(fig1_delta$upper.CL)), detail = "estimate/lcl/ucl finite"),
  tibble(check = "fig2_no_na", pass = all(is.finite(fig2_delta$estimate) & is.finite(fig2_delta$lower.CL) & is.finite(fig2_delta$upper.CL)), detail = "estimate/lcl/ucl finite")
)
if (!is.null(fig3_delta)) {
  qc_rows <- c(qc_rows, list(
    tibble(check = "fig3_no_na", pass = all(is.finite(fig3_delta$estimate) & is.finite(fig3_delta$lower.CL) & is.finite(fig3_delta$upper.CL)), detail = paste0("rows=", nrow(fig3_delta)))
  ))
}
qc_summary <- bind_rows(qc_rows)
qc_summary <- qc_summary %>% mutate(overall_status = ifelse(all(pass), "PASS", "WARN"))
qc_path <- file.path(cfg$output_dir, "qc_summary.csv")
readr::write_csv(qc_summary, qc_path)

prov_path <- file.path(cfg$output_dir, "K26_VIS_provenance.txt")
prov_lines <- c(
  "K26_VIS provenance",
  paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("script=", script_label),
  paste0("data_input=", normalizePath(cfg$data_input, winslash = "/", mustWork = TRUE)),
  paste0("model_cat_rds=", normalizePath(cfg$model_cat_rds, winslash = "/", mustWork = TRUE)),
  paste0("model_score_rds=", ifelse(!is.null(m_score), normalizePath(cfg$model_score_rds, winslash = "/", mustWork = TRUE), "<not-used>")),
  "delta_definition=Composite_Z12 - Composite_Z0 (12-month follow-up minus baseline)",
  "frailty_source=canonical K15/K26 pipeline (no fallback derivation in K26_VIS)",
  paste0("model_formula_cat=", paste(deparse(formula(m_cat)), collapse = " ")),
  paste0("model_formula_score=", ifelse(!is.null(m_score), paste(deparse(formula(m_score)), collapse = " "), "<not-used>")),
  paste0("nobs_cat=", nobs(m_cat)),
  paste0("nobs_score=", ifelse(!is.null(m_score), as.character(nobs(m_score)), "NA")),
  paste0("grid_n=", cfg$grid_n),
  paste0("covariates_fixed=age(mean=", sprintf("%.3f", mean_age), "), BMI(mean=", sprintf("%.3f", mean_bmi), "), sex=", sex_ref,
         ifelse(!is.null(bal_mean), paste0(", Balance_problem(mean=", sprintf("%.3f", bal_mean), ")"), "")),
  paste0("qc_overall_status=", qc_summary$overall_status[1]),
  paste0("qc_file=", normalizePath(qc_path, winslash = "/", mustWork = TRUE))
)
writeLines(prov_lines, con = prov_path)

session_path <- file.path(cfg$output_dir, "sessionInfo.txt")
session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = session_path)

for (a in records) {
  append_artifact(a$label, a$kind, a$path, notes = "K26_VIS reviewer figure artifact")
}
append_artifact("K26_VIS_provenance_txt", "txt", prov_path, notes = "K26_VIS input/model/grid provenance trace")
append_artifact("K26_VIS_qc_summary_csv", "qc_table_csv", qc_path, n = nrow(qc_summary), notes = "K26_VIS QC checks for grid/prediction completeness")
append_artifact("K26_VIS_sessionInfo_txt", "sessioninfo", session_path, notes = "K26_VIS sessionInfo + renv diagnostics")

cat("K26_VIS completed. Output dir:", cfg$output_dir, "\n")
cat("QC overall:", qc_summary$overall_status[1], "\n")
