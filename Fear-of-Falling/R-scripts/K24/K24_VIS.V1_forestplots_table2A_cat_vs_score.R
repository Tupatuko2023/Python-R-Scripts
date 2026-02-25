#!/usr/bin/env Rscript
# ==============================================================================
# K24_VIS - Forest plots for K24 Table2A canonical cat vs score comparison
# File tag: K24_VIS.V1_forestplots_table2A_cat_vs_score.R
# Purpose: Read K24 canonical compare CSV and generate FOF/frailty forest figures
#          plus QC check for FOF cat-vs-score identity.
#
# Default input:
# - R-scripts/K24/outputs/K24_TABLE2A/table2A_cat_vs_score_compare_canonical_v2.csv
#
# Outputs (default out_dir):
# - figures/K24_VIS/K24_canonicalV2_forest_FOF.{png,pdf}
# - figures/K24_VIS/K24_canonicalV2_forest_FrailtyScore.{png,pdf}
# - figures/K24_VIS/K24_canonicalV2_frailtyCat_overallP.{png,pdf} (optional)
# - figures/K24_VIS/K24_canonicalV2_forest_FrailtyCatContrasts.{png,pdf}
# - figures/K24_VIS/K24_canonicalV2_forest_FOF_standardized.{png,pdf}
# - figures/K24_VIS/K24_canonicalV2_forest_FrailtyScore_standardized.{png,pdf}
# - figures/K24_VIS/qc_fof_cat_vs_score_diff.csv (only when mismatch)
# - figures/K24_VIS/qc_sd_baseline_missing.csv (only when baseline SD missing/zero)
# - figures/K24_VIS/plot_manifest.txt
# - figures/K24_VIS/sessionInfo.txt
# ==============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(readr)
  library(tibble)
  library(stringr)
  library(ggplot2)
})

args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)
script_base <- if (length(file_arg) > 0) {
  sub("\\.R$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K24_VIS"
}
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K24_VIS"

source(here::here("R", "functions", "io.R"))
source(here::here("R", "functions", "reporting.R"))

paths <- init_paths(script_label)
manifest_path <- paths$manifest_path

parse_cli <- function(args) {
  out <- list(
    input = here::here("R-scripts", "K24", "outputs", "K24_TABLE2A", "table2A_cat_vs_score_compare_canonical_v2.csv"),
    out_dir = here::here("R-scripts", "K24", "outputs", "K24_TABLE2A", "figures", "K24_VIS"),
    make_cat_p = TRUE,
    format = "both",
    width = 8,
    height = 5,
    audit_input = here::here("R-scripts", "K24", "outputs", "K24_TABLE2A", "table2A_audit_canonical_v2.csv"),
    qc_tol = 0.10,
    z_tol = 1.96,
    qc_strict = FALSE
  )

  for (arg in args) {
    if (startsWith(arg, "--input=")) out$input <- sub("^--input=", "", arg)
    if (startsWith(arg, "--out_dir=")) out$out_dir <- sub("^--out_dir=", "", arg)
    if (startsWith(arg, "--make_cat_p=")) out$make_cat_p <- tolower(sub("^--make_cat_p=", "", arg)) %in% c("true", "1", "yes", "y")
    if (startsWith(arg, "--format=")) out$format <- tolower(sub("^--format=", "", arg))
    if (startsWith(arg, "--width=")) out$width <- suppressWarnings(as.numeric(sub("^--width=", "", arg)))
    if (startsWith(arg, "--height=")) out$height <- suppressWarnings(as.numeric(sub("^--height=", "", arg)))
    if (startsWith(arg, "--audit_input=")) out$audit_input <- sub("^--audit_input=", "", arg)
    if (startsWith(arg, "--qc_tol=")) out$qc_tol <- suppressWarnings(as.numeric(sub("^--qc_tol=", "", arg)))
    if (startsWith(arg, "--z_tol=")) out$z_tol <- suppressWarnings(as.numeric(sub("^--z_tol=", "", arg)))
    if (startsWith(arg, "--qc_strict=")) out$qc_strict <- tolower(sub("^--qc_strict=", "", arg)) %in% c("true", "1", "yes", "y")
  }

  if (!out$format %in% c("png", "pdf", "both")) stop("Invalid --format. Use png|pdf|both.")
  if (!is.finite(out$width) || out$width <= 0) stop("Invalid --width")
  if (!is.finite(out$height) || out$height <= 0) stop("Invalid --height")
  if (!is.finite(out$qc_tol) || out$qc_tol < 0) stop("Invalid --qc_tol")
  if (!is.finite(out$z_tol) || out$z_tol <= 0) stop("Invalid --z_tol")
  out
}

append_artifact <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  rel_path <- get_relpath(path)
  if (file.exists(manifest_path)) {
    existing <- tryCatch(readr::read_csv(manifest_path, show_col_types = FALSE), error = function(e) NULL)
    if (!is.null(existing) && all(c("script", "label", "kind", "path") %in% names(existing))) {
      hit <- existing %>%
        filter(.data$script == script_label, .data$label == label, .data$kind == kind, .data$path == rel_path)
      if (nrow(hit) > 0) return(invisible(FALSE))
    }
  }
  append_manifest(
    manifest_row(script = script_label, label = label, path = rel_path, kind = kind, n = n, notes = notes),
    manifest_path
  )
  invisible(TRUE)
}

read_compare_sniff <- function(path) {
  if (!file.exists(path)) stop("Input compare CSV not found: ", path)

  x <- tryCatch(readr::read_csv(path, show_col_types = FALSE), error = function(e) NULL)
  delim <- ","

  if (is.null(x) || !("Outcome" %in% names(x))) {
    x <- tryCatch(readr::read_delim(path, delim = "\t", show_col_types = FALSE), error = function(e) NULL)
    delim <- "\\t"
  }

  if (is.null(x) || !("Outcome" %in% names(x))) {
    stop("Could not parse compare file with comma or tab delimiter; missing Outcome column.")
  }

  list(data = as_tibble(x), delim = delim)
}

parse_beta_ci <- function(x) {
  x <- as.character(x)
  x <- stringr::str_replace_all(x, " to ", ",")
  x <- stringr::str_replace_all(x, "\\[|\\]", "")
  x <- stringr::str_replace_all(x, "\\(|\\)", "")
  nums <- stringr::str_extract_all(x, "[-+]?[0-9]*\\.?[0-9]+")

  out <- lapply(nums, function(v) {
    if (length(v) >= 3) {
      c(beta = as.numeric(v[1]), lcl = as.numeric(v[2]), ucl = as.numeric(v[3]))
    } else {
      c(beta = NA_real_, lcl = NA_real_, ucl = NA_real_)
    }
  })
  as_tibble(do.call(rbind, out))
}

parse_mean_sd <- function(x) {
  x <- as.character(x)
  x <- stringr::str_replace_all(x, "\\u2013", "-")
  nums <- stringr::str_extract_all(x, "[-+]?[0-9]*\\.?[0-9]+")
  out <- lapply(nums, function(v) {
    # Expected "N=72, 1.31 (0.49)" -> n, mean, sd
    if (length(v) >= 3) {
      c(n = as.numeric(v[1]), mean = as.numeric(v[2]), sd = as.numeric(v[3]))
    } else {
      c(n = NA_real_, mean = NA_real_, sd = NA_real_)
    }
  })
  as_tibble(do.call(rbind, out))
}

fmt_p <- function(p) {
  p <- suppressWarnings(as.numeric(p))
  vapply(p, function(px) {
    if (is.na(px)) return("")
    if (px < 0.001) return("<0.001")
    sprintf("%.3f", px)
  }, character(1))
}

save_plot <- function(plot_obj, base_name, cfg, records) {
  out_files <- character(0)
  if (cfg$format %in% c("png", "both")) {
    p_png <- file.path(cfg$out_dir, paste0(base_name, ".png"))
    ggplot2::ggsave(filename = p_png, plot = plot_obj, width = cfg$width, height = cfg$height, dpi = 300)
    records[[length(records) + 1L]] <- list(label = paste0(base_name, "_png"), kind = "figure_png", path = p_png)
    out_files <- c(out_files, p_png)
  }
  if (cfg$format %in% c("pdf", "both")) {
    p_pdf <- file.path(cfg$out_dir, paste0(base_name, ".pdf"))
    ggplot2::ggsave(filename = p_pdf, plot = plot_obj, width = cfg$width, height = cfg$height, device = grDevices::cairo_pdf)
    records[[length(records) + 1L]] <- list(label = paste0(base_name, "_pdf"), kind = "figure_pdf", path = p_pdf)
    out_files <- c(out_files, p_pdf)
  }
  list(files = out_files, records = records)
}

cfg <- parse_cli(commandArgs(trailingOnly = TRUE))
dir.create(cfg$out_dir, recursive = TRUE, showWarnings = FALSE)

read_res <- read_compare_sniff(cfg$input)
compare_df <- read_res$data

need_compare <- c("Outcome", "FOF_beta_score", "FOF_p_score", "N_model_score", "Frailty_score_beta", "Frailty_score_lcl", "Frailty_score_ucl", "Frailty_score_p", "Frailty_cat_overall_p", "N_model_cat")
miss_compare <- setdiff(need_compare, names(compare_df))
if (length(miss_compare) > 0) {
  stop("Compare CSV missing required columns: ", paste(miss_compare, collapse = ", "))
}

outcome_levels <- c("MWS", "FTSST", "SLS", "HGS (Women)", "HGS (Men)")
if ("HGS" %in% compare_df$Outcome) {
  # keep pooled HGS in compare for QC context, but plots use paper-ready outcome order
  outcome_levels_all <- c("MWS", "FTSST", "SLS", "HGS", "HGS (Women)", "HGS (Men)")
} else {
  outcome_levels_all <- outcome_levels
}

# ---- QC: FOF(cat) vs FOF(score) identity per outcome --------------------------
qc_status <- "PASS"
qc_reason <- "No large cat-vs-score FOF differences"
qc_path <- file.path(cfg$out_dir, "qc_fof_cat_vs_score_diff.csv")
qc_diff <- tibble()
sd_qc_path <- file.path(cfg$out_dir, "qc_sd_baseline_missing.csv")
sd_qc_df <- tibble()
max_abs_beta_diff <- NA_real_
max_z_diff_all <- NA_real_
max_z_diff_excl_hgs_men <- NA_real_
outlier_outcome <- NA_character_
sign_flip_any <- FALSE

if (file.exists(cfg$audit_input)) {
  audit_df <- readr::read_csv(cfg$audit_input, show_col_types = FALSE)
  if (all(c("Outcome", "Frailty_Mode", "FOF_Beta_CI", "Model_N") %in% names(audit_df))) {
    audit_long <- audit_df %>%
      filter(Frailty_Mode %in% c("cat", "score")) %>%
      select(Outcome, Frailty_Mode, FOF_Beta_CI, Model_N)

    parsed <- parse_beta_ci(audit_long$FOF_Beta_CI)
    audit_long <- bind_cols(audit_long, parsed)

    qc_diff <- audit_long %>%
      select(Outcome, Frailty_Mode, beta, lcl, ucl, Model_N) %>%
      tidyr::pivot_wider(names_from = Frailty_Mode, values_from = c(beta, lcl, ucl, Model_N)) %>%
      mutate(
        se_cat = abs((ucl_cat - lcl_cat) / (2 * 1.96)),
        se_score = abs((ucl_score - lcl_score) / (2 * 1.96)),
        d_beta = beta_cat - beta_score,
        abs_d_beta = abs(d_beta),
        z_diff = abs_d_beta / sqrt(se_cat^2 + se_score^2),
        sign_flip = dplyr::if_else(!is.na(beta_cat) & !is.na(beta_score) & beta_cat != 0 & beta_score != 0 & sign(beta_cat) != sign(beta_score), TRUE, FALSE, FALSE),
        qc_note = dplyr::case_when(
          Outcome == "HGS (Men)" ~ paste0("small-N exploratory; Model_N(cat/score)=", Model_N_cat, "/", Model_N_score),
          TRUE ~ ""
        )
      )

    if (nrow(qc_diff) > 0) {
      max_abs_beta_diff <- max(qc_diff$abs_d_beta, na.rm = TRUE)
      max_z_diff_all <- max(qc_diff$z_diff, na.rm = TRUE)
      max_z_diff_excl_hgs_men <- suppressWarnings(max(qc_diff$z_diff[qc_diff$Outcome != "HGS (Men)"], na.rm = TRUE))
      if (!is.finite(max_z_diff_excl_hgs_men)) max_z_diff_excl_hgs_men <- NA_real_
      outlier_outcome <- qc_diff$Outcome[which.max(qc_diff$z_diff)][1]
      sign_flip_any <- any(qc_diff$sign_flip, na.rm = TRUE)

      readr::write_csv(qc_diff, qc_path)
      if (isTRUE(cfg$qc_strict)) {
        if (isTRUE(sign_flip_any) || (is.finite(max_z_diff_all) && max_z_diff_all > cfg$z_tol)) {
          qc_status <- "FAIL"
          qc_reason <- paste0("Strict mode: z_diff/sign_flip exceeded threshold; outlier=", outlier_outcome)
          warning("K24_VIS QC FAIL (strict): z-diff/sign-flip exceeded strict threshold. See ", qc_path)
        }
      } else {
        if (isTRUE(sign_flip_any) || (is.finite(max_z_diff_all) && max_z_diff_all > cfg$z_tol)) {
          qc_status <- "WARN"
          qc_reason <- paste0("Expected model-spec difference; outlier=", outlier_outcome, "; report z_diff and sign_flip; abs-diff shown for audit.")
          message("K24_VIS QC WARN: z-diff/sign-flip threshold exceeded (expected by model spec). See ", qc_path)
        } else {
          qc_status <- "PASS"
          qc_reason <- paste0("z-diff within threshold (z_tol=", sprintf("%.2f", cfg$z_tol), "); no sign flip.")
          message("K24_VIS QC PASS: z-diff within threshold and no sign flips. See ", qc_path)
        }
      }
    } else {
      qc_status <- "PASS"
      qc_reason <- "No comparable cat/score rows found for FOF diff check"
      message("K24_VIS QC PASS: no comparable cat/score rows found.")
    }
  } else {
    qc_status <- "UNKNOWN"
    qc_reason <- "Audit input missing Outcome/Frailty_Mode/FOF_Beta_CI/Model_N columns"
    warning("K24_VIS QC UNKNOWN: audit file lacks required columns for cat-vs-score FOF check")
  }
} else {
  qc_status <- "UNKNOWN"
  qc_reason <- "Audit input not found; cannot perform cat-vs-score FOF identity check"
  warning("K24_VIS QC UNKNOWN: audit input not found at ", cfg$audit_input)
}

# ---- Plot data ----------------------------------------------------------------
# FOF forest (prefer cat from audit if available, else compare score columns)
fof_df <- NULL
if (file.exists(cfg$audit_input)) {
  audit_df <- readr::read_csv(cfg$audit_input, show_col_types = FALSE)
  if (all(c("Outcome", "Frailty_Mode", "FOF_Beta_CI", "P_FOF", "Model_N") %in% names(audit_df))) {
    fof_df <- audit_df %>%
      filter(Frailty_Mode == "cat", Outcome %in% outcome_levels) %>%
      mutate(parsed = parse_beta_ci(FOF_Beta_CI)) %>%
      tidyr::unnest(parsed) %>%
      transmute(
        Outcome,
        beta,
        lcl,
        ucl,
        p = P_FOF,
        model_n = Model_N,
        label = paste0("p=", fmt_p(P_FOF), "; N=", Model_N)
      )
  }
}

if (is.null(fof_df) || nrow(fof_df) == 0) {
  fof_df <- compare_df %>%
    filter(Outcome %in% outcome_levels) %>%
    transmute(
      Outcome,
      beta = suppressWarnings(as.numeric(FOF_beta_score)),
      lcl = NA_real_,
      ucl = NA_real_,
      p = FOF_p_score,
      model_n = N_model_score,
      label = paste0("p=", fmt_p(FOF_p_score), "; N=", N_model_score)
    )
}

fof_df <- fof_df %>%
  distinct(Outcome, .keep_all = TRUE) %>%
  mutate(Outcome = factor(Outcome, levels = rev(outcome_levels)))

score_df <- compare_df %>%
  filter(Outcome %in% outcome_levels) %>%
  transmute(
    Outcome,
    beta = suppressWarnings(as.numeric(Frailty_score_beta)),
    lcl = suppressWarnings(as.numeric(Frailty_score_lcl)),
    ucl = suppressWarnings(as.numeric(Frailty_score_ucl)),
    p = Frailty_score_p,
    model_n = N_model_score,
    label = paste0("p=", fmt_p(Frailty_score_p), "; N=", N_model_score)
  ) %>%
  mutate(Outcome = factor(Outcome, levels = rev(outcome_levels)))

catp_df <- compare_df %>%
  filter(Outcome %in% outcome_levels) %>%
  transmute(
    Outcome,
    p = Frailty_cat_overall_p,
    model_n = N_model_cat,
    label = paste0("p=", fmt_p(Frailty_cat_overall_p), "; N=", N_model_cat)
  ) %>%
  mutate(Outcome = factor(Outcome, levels = rev(outcome_levels)))

# ---- Frailty categorical contrasts forest data --------------------------------
cat_contrast_df <- compare_df %>%
  filter(Outcome %in% outcome_levels) %>%
  transmute(
    Outcome,
    Model_N = N_model_cat,
    pre_beta = suppressWarnings(as.numeric(Frailty_cat_prefrail_beta)),
    pre_lcl = suppressWarnings(as.numeric(Frailty_cat_prefrail_lcl)),
    pre_ucl = suppressWarnings(as.numeric(Frailty_cat_prefrail_ucl)),
    pre_p = Frailty_cat_prefrail_p,
    frail_beta = suppressWarnings(as.numeric(Frailty_cat_frail_beta)),
    frail_lcl = suppressWarnings(as.numeric(Frailty_cat_frail_lcl)),
    frail_ucl = suppressWarnings(as.numeric(Frailty_cat_frail_ucl)),
    frail_p = Frailty_cat_frail_p
  ) %>%
  tidyr::pivot_longer(
    cols = c(pre_beta, pre_lcl, pre_ucl, pre_p, frail_beta, frail_lcl, frail_ucl, frail_p),
    names_to = c("contrast", ".value"),
    names_pattern = "^(pre|frail)_(beta|lcl|ucl|p)$"
  ) %>%
  mutate(
    contrast = dplyr::recode(contrast, pre = "Pre-frail vs robust", frail = "Frail vs robust"),
    Outcome = factor(Outcome, levels = rev(outcome_levels)),
    label = paste0("p=", fmt_p(p), "; N=", Model_N)
  )

# ---- Baseline SD table for standardized betas ---------------------------------
sd_df <- tibble(Outcome = outcome_levels, sd_baseline = NA_real_)
if (file.exists(cfg$audit_input)) {
  audit_df <- readr::read_csv(cfg$audit_input, show_col_types = FALSE)
  if (all(c("Outcome", "Frailty_Mode", "N_without", "N_with", "Without_FOF_Baseline", "With_FOF_Baseline") %in% names(audit_df))) {
    sd_df <- audit_df %>%
      filter(Frailty_Mode == "cat", Outcome %in% outcome_levels) %>%
      distinct(Outcome, N_without, N_with, Without_FOF_Baseline, With_FOF_Baseline, .keep_all = FALSE) %>%
      mutate(
        parsed_without = lapply(Without_FOF_Baseline, parse_mean_sd),
        parsed_with = lapply(With_FOF_Baseline, parse_mean_sd)
      ) %>%
      tidyr::unnest_wider(parsed_without, names_sep = "_wo") %>%
      tidyr::unnest_wider(parsed_with, names_sep = "_wi") %>%
      mutate(
        n_wo = suppressWarnings(as.numeric(N_without)),
        n_wi = suppressWarnings(as.numeric(N_with)),
        sd_wo = suppressWarnings(as.numeric(parsed_without_wosd)),
        sd_wi = suppressWarnings(as.numeric(parsed_with_wisd)),
        sd_baseline = dplyr::if_else(
          !is.na(n_wo) & !is.na(n_wi) & n_wo > 1 & n_wi > 1 & !is.na(sd_wo) & !is.na(sd_wi),
          sqrt((((n_wo - 1) * sd_wo^2) + ((n_wi - 1) * sd_wi^2)) / pmax((n_wo + n_wi - 2), 1)),
          NA_real_
        )
      ) %>%
      select(Outcome, sd_baseline)
  }
}
if (nrow(sd_df) == 0) {
  sd_df <- tibble(Outcome = outcome_levels, sd_baseline = NA_real_)
}
sd_df <- sd_df %>%
  mutate(Outcome = as.character(Outcome)) %>%
  distinct(Outcome, .keep_all = TRUE)

sd_qc_df <- sd_df %>%
  filter(is.na(sd_baseline) | sd_baseline <= 0) %>%
  mutate(qc_issue = "sd_baseline missing_or_nonpositive", std_method = "baseline_sd")

if (nrow(sd_qc_df) > 0) {
  readr::write_csv(sd_qc_df, sd_qc_path)
  if (!isTRUE(cfg$qc_strict) && qc_status == "PASS") {
    qc_status <- "WARN"
    qc_reason <- paste0("Expected model-spec difference; baseline SD missing for some outcomes (see ", basename(sd_qc_path), ").")
  }
}

fof_std_df <- fof_df %>%
  mutate(Outcome = as.character(Outcome)) %>%
  left_join(sd_df, by = "Outcome") %>%
  mutate(
    beta_std = beta / sd_baseline,
    lcl_std = lcl / sd_baseline,
    ucl_std = ucl / sd_baseline,
    Outcome = factor(Outcome, levels = rev(outcome_levels)),
    label_std = paste0("p=", fmt_p(p), "; N=", model_n)
  )

score_std_df <- score_df %>%
  mutate(Outcome = as.character(Outcome)) %>%
  left_join(sd_df, by = "Outcome") %>%
  mutate(
    beta_std = beta / sd_baseline,
    lcl_std = lcl / sd_baseline,
    ucl_std = ucl / sd_baseline,
    Outcome = factor(Outcome, levels = rev(outcome_levels)),
    label_std = paste0("p=", fmt_p(p), "; N=", model_n)
  )

p_fof <- ggplot(fof_df, aes(x = beta, y = Outcome)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lcl, xmax = ucl), height = 0.2, color = "#2a4d69", na.rm = TRUE) +
  geom_point(size = 2.8, color = "#2a4d69") +
  geom_text(aes(label = label), nudge_y = 0.22, hjust = 0, size = 3.1, color = "#1b1b1b") +
  labs(
    title = "K24 canonical V2: FOF effect forest plot",
    subtitle = "FOF beta (95% CI), prefer frailty cat rows",
    x = "FOF beta (95% CI)",
    y = NULL
  ) +
  theme_minimal(base_size = 12)

p_score <- ggplot(score_df, aes(x = beta, y = Outcome)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lcl, xmax = ucl), height = 0.2, color = "#005b4f", na.rm = TRUE) +
  geom_point(size = 2.8, color = "#005b4f") +
  geom_text(aes(label = label), nudge_y = 0.22, hjust = 0, size = 3.1, color = "#1b1b1b") +
  labs(
    title = "K24 canonical V2: Frailty score effect forest plot",
    subtitle = "Frailty score (per +1) beta (95% CI)",
    x = "Frailty score beta (95% CI)",
    y = NULL
  ) +
  theme_minimal(base_size = 12)

p_cat <- ggplot(catp_df, aes(x = suppressWarnings(as.numeric(p)), y = Outcome)) +
  geom_vline(xintercept = 0.05, linetype = "dashed", color = "grey50") +
  geom_point(size = 2.8, color = "#8c2d04") +
  geom_text(aes(label = label), nudge_x = 0.03, hjust = 0, size = 3.1, color = "#1b1b1b") +
  scale_x_continuous(limits = c(0, 1), expand = expansion(mult = c(0.02, 0.15))) +
  coord_cartesian(clip = "off") +
  labs(
    title = "K24 canonical V2: Frailty cat overall p-values",
    subtitle = "Overall frailty categorical test (p-only panel)",
    x = "p-value",
    y = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.margin = margin(5.5, 160, 5.5, 5.5))

p_cat_contrasts <- ggplot(cat_contrast_df, aes(x = beta, y = Outcome, color = contrast)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lcl, xmax = ucl), position = position_dodge(width = 0.6), height = 0.15, na.rm = TRUE) +
  geom_point(position = position_dodge(width = 0.6), size = 2.4) +
  geom_text(
    aes(label = label),
    position = position_dodge(width = 0.6),
    nudge_y = 0.23,
    hjust = 0,
    size = 2.9,
    show.legend = FALSE
  ) +
  scale_color_manual(values = c("Pre-frail vs robust" = "#8c510a", "Frail vs robust" = "#01665e")) +
  labs(
    title = "K24 canonical V2: Frailty categorical contrasts",
    subtitle = "Pre-frail vs robust and frail vs robust (beta, 95% CI)",
    x = "Frailty contrast beta (95% CI)",
    y = NULL,
    color = "Contrast"
  ) +
  theme_minimal(base_size = 12)

p_fof_std <- ggplot(fof_std_df, aes(x = beta_std, y = Outcome)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lcl_std, xmax = ucl_std), height = 0.2, color = "#2a4d69", na.rm = TRUE) +
  geom_point(size = 2.8, color = "#2a4d69") +
  geom_text(aes(label = label_std), nudge_y = 0.22, hjust = 0, size = 3.1, color = "#1b1b1b") +
  labs(
    title = "K24 canonical V2: FOF standardized beta",
    subtitle = "Standardized beta per baseline SD (beta / SD_baseline)",
    x = "FOF standardized beta (95% CI), per baseline SD",
    y = NULL
  ) +
  theme_minimal(base_size = 12)

# Suodatetaan HGS (Men) pois selkeämpää skaalaa varten
fof_std_df_excl_men <- fof_std_df %>%
  filter(Outcome != "HGS (Men)")

p_fof_std_excl_men <- ggplot(fof_std_df_excl_men, aes(x = beta_std, y = Outcome)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lcl_std, xmax = ucl_std), height = 0.2, color = "#2a4d69", na.rm = TRUE) +
  geom_point(size = 2.8, color = "#2a4d69") +
  geom_text(aes(label = label_std), nudge_y = 0.22, hjust = 0, size = 3.1, color = "#1b1b1b") +
  labs(
    title = "K24 canonical V2: FOF standardized beta (excl. HGS Men)",
    subtitle = "Standardized beta per baseline SD (beta / SD_baseline)",
    x = "FOF standardized beta (95% CI), per baseline SD",
    y = NULL
  ) +
  theme_minimal(base_size = 12)

p_score_std <- ggplot(score_std_df, aes(x = beta_std, y = Outcome)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbarh(aes(xmin = lcl_std, xmax = ucl_std), height = 0.2, color = "#005b4f", na.rm = TRUE) +
  geom_point(size = 2.8, color = "#005b4f") +
  geom_text(aes(label = label_std), nudge_y = 0.22, hjust = 0, size = 3.1, color = "#1b1b1b") +
  labs(
    title = "K24 canonical V2: Frailty score standardized beta",
    subtitle = "Standardized beta per baseline SD (beta / SD_baseline)",
    x = "Frailty score standardized beta (95% CI), per baseline SD",
    y = NULL
  ) +
  theme_minimal(base_size = 12)

artifacts <- list()

sv <- save_plot(p_fof, "K24_canonicalV2_forest_FOF", cfg, artifacts)
artifacts <- sv$records
sv <- save_plot(p_score, "K24_canonicalV2_forest_FrailtyScore", cfg, artifacts)
artifacts <- sv$records

if (isTRUE(cfg$make_cat_p)) {
  sv <- save_plot(p_cat, "K24_canonicalV2_frailtyCat_overallP", cfg, artifacts)
  artifacts <- sv$records
}
sv <- save_plot(p_cat_contrasts, "K24_canonicalV2_forest_FrailtyCatContrasts", cfg, artifacts)
artifacts <- sv$records
sv <- save_plot(p_fof_std, "K24_canonicalV2_forest_FOF_standardized", cfg, artifacts)
artifacts <- sv$records
sv <- save_plot(p_fof_std_excl_men, "K24_canonicalV2_forest_FOF_standardized_excl_HGS_Men", cfg, artifacts)
artifacts <- sv$records
sv <- save_plot(p_score_std, "K24_canonicalV2_forest_FrailtyScore_standardized", cfg, artifacts)
artifacts <- sv$records

plot_manifest_path <- file.path(cfg$out_dir, "plot_manifest.txt")
session_path <- file.path(cfg$out_dir, "sessionInfo.txt")

manifest_lines <- c(
  "K24_VIS plot manifest",
  paste0("timestamp=", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste0("script=", script_label),
  paste0("input=", normalizePath(cfg$input, winslash = "/", mustWork = TRUE)),
  paste0("input_delimiter=", read_res$delim),
  paste0("audit_input=", cfg$audit_input),
  paste0("qc_status=", qc_status),
  paste0("qc_reason=", qc_reason),
  paste0("qc_tol=", cfg$qc_tol),
  paste0("z_tol=", cfg$z_tol),
  paste0("qc_strict=", cfg$qc_strict),
  paste0("max_abs_beta_diff=", ifelse(is.finite(max_abs_beta_diff), sprintf("%.6f", max_abs_beta_diff), "NA")),
  paste0("max_z_diff_all=", ifelse(is.finite(max_z_diff_all), sprintf("%.6f", max_z_diff_all), "NA")),
  paste0("max_z_diff_excl_hgs_men=", ifelse(is.finite(max_z_diff_excl_hgs_men), sprintf("%.6f", max_z_diff_excl_hgs_men), "NA")),
  paste0("outlier_outcome=", ifelse(is.na(outlier_outcome), "NA", outlier_outcome)),
  paste0("sign_flip_any=", sign_flip_any),
  "std_method=baseline_sd",
  "sd_source=audit",
  paste0("sd_baseline_missing_n=", nrow(sd_qc_df)),
  paste0("format=", cfg$format),
  paste0("width=", cfg$width),
  paste0("height=", cfg$height),
  paste0("make_cat_p=", cfg$make_cat_p),
  "files_written="
)

if (length(artifacts) > 0) {
  manifest_lines <- c(manifest_lines, vapply(artifacts, function(a) paste0(" - ", a$path), character(1)))
}
if (file.exists(qc_path)) {
  manifest_lines <- c(manifest_lines, paste0(" - ", qc_path))
}
if (file.exists(sd_qc_path)) {
  manifest_lines <- c(manifest_lines, paste0(" - ", sd_qc_path))
}

writeLines(manifest_lines, con = plot_manifest_path)

session_lines <- capture.output(sessionInfo())
if (requireNamespace("renv", quietly = TRUE)) {
  session_lines <- c(session_lines, "", "---- renv diagnostics ----", capture.output(renv::diagnostics()))
}
writeLines(session_lines, con = session_path)

# Manifest append
for (a in artifacts) {
  append_artifact(a$label, a$kind, a$path, notes = "K24_VIS V1 forest plot artifact")
}

if (file.exists(qc_path)) {
  append_artifact(
    label = "qc_fof_cat_vs_score_diff_csv",
    kind = "qc_table_csv",
    path = qc_path,
    n = nrow(qc_diff),
    notes = "K24_VIS QC diff table with CI-based z_diff/sign_flip; abs diff retained for audit"
  )
}
if (file.exists(sd_qc_path)) {
  append_artifact(
    label = "qc_sd_baseline_missing_csv",
    kind = "qc_table_csv",
    path = sd_qc_path,
    n = nrow(sd_qc_df),
    notes = "K24_VIS QC for baseline SD availability used in standardized beta plots"
  )
}

append_artifact(
  label = "plot_manifest_txt",
  kind = "qc_text",
  path = plot_manifest_path,
  notes = "K24_VIS run parameters, delimiter detection, QC status, and written files"
)
append_artifact(
  label = "sessionInfo",
  kind = "sessioninfo",
  path = session_path,
  notes = "K24_VIS sessionInfo + renv diagnostics"
)

cat("K24_VIS completed. Output dir:", cfg$out_dir, "\n")
cat("QC status:", qc_status, "-", qc_reason, "\n")
if (file.exists(qc_path)) cat("QC diff file:", qc_path, "\n")
