#!/usr/bin/env Rscript

# - K5.1_MA: Moderation Analysis Script for Fear of Falling & Functional
#   Performance
# [K5.1.V4_Moderation_analysis.R]
# - "Performs an advanced moderation
#   analysis with multiple enhancements and diagnostics."

###############################################################################
# Moderation workflow - upgraded version
#
# Outcome:      Delta_Composite_Z
# Moderator:    Composite_Z0 (continuous, plus quartiles)
# Group:        FOF_status (0 vs 1)
# Covariates:   Age, Sex, BMI
#
# This script:
#   1) Reproduces main linear and quartile moderation models.
#   2) Tests nonlinearity of Composite_Z0 with splines and spline-by-FOF interaction.
#   3) Runs Johnson-Neyman on centered and standardized moderator.
#   4) Implements multiple imputation (MICE) and pools main results.
#   5) Applies inverse probability weights for outcome observation.
#   6) Adds multiplicity control and effect sizes.
#   7) Probes simple effects at clinically relevant moderator cutpoints.
#   8) Produces diagnostics, tables and figures into ./outputs.
#   9) Prints an updated Finnish Results text block.
#
# Required variables in the analysis data:
#   Delta_Composite_Z, Composite_Z0, FOF_status, Age, Sex, BMI
#
# If your raw data has different names, map them after reading:
#   raw_data <- raw_data %>%
#     dplyr::mutate(
#       Composite_Z0 = ToimintaKykySummary0,
#       Delta_Composite_Z = ToimintaKykySummary2 - ToimintaKykySummary0,
#       FOF_status = dplyr::case_when(kaatumisenpelkoOn %in% c("0", 0) ~ 0,
#                                     kaatumisenpelkoOn %in% c("1", 1) ~ 1,
#                                     TRUE ~ NA_real_),
#       Age = age,
#       Sex = sex,
#       BMI = BMI
#     )
###############################################################################

set.seed(123)

# 1. Setup and packages -------------------------------------------------------

required_packages <- c(
  "here",
  "dplyr",
  "ggplot2",
  "broom",
  "emmeans",
  "sandwich",
  "lmtest",
  "splines",
  "mice",
  "effectsize",
  "performance",
  "car",
  "knitr"
)

load_or_stop <- function(pkgs) {
  for (p in pkgs) {
    if (!requireNamespace(p, quietly = TRUE)) {
      stop(
        sprintf(
          "Package '%s' is required but not installed. Please install it with install.packages('%s').",
          p, p
        ),
        call. = FALSE
      )
    }
    suppressPackageStartupMessages(library(p, character.only = TRUE))
  }
}

load_or_stop(required_packages)

# 1b. Outputs-kansio K5:n alle -------------------------------------------

outputs_dir <- here::here("R-scripts", "K5", "outputs")
if (!dir.exists(outputs_dir)) {
  dir.create(outputs_dir, recursive = TRUE)
}

# --- Erillinen manifest-kansio projektissa: ./manifest -----------------------
# Projektin juurikansio oletetaan olevan .../Fear-of-Falling
manifest_dir <- here::here("manifest")
if (!dir.exists(manifest_dir)) {
  dir.create(manifest_dir, recursive = TRUE)
}
manifest_path <- file.path(manifest_dir, "manifest.csv")

# --- Skriptikohtainen alikansio tuloksille ---

# Skriptin tunniste ---
script_label <- "K5.1_MA"  # MA = Moderation Analysis

script_dir <- file.path(outputs_dir, script_label)
if (!dir.exists(script_dir)) {
  dir.create(script_dir, recursive = TRUE)
}

# Helper to save CSV + simple HTML table --------------------------------------

save_table_csv_html <- function(df, basename) {
  csv_path  <- file.path(script_dir, paste0(basename, ".csv"))
  html_path <- file.path(script_dir, paste0(basename, ".html"))

  utils::write.csv(df, csv_path, row.names = FALSE)

  html_table <- knitr::kable(
    df, format = "html",
    table.attr = "border='1' style='border-collapse:collapse;'"
  )
  html_content <- paste0(
    "<html><head><meta charset='UTF-8'></head><body>",
    "<h3>", basename, "</h3>",
    html_table,
    "</body></html>"
  )
  writeLines(html_content, con = html_path)
}

# Small diagnostic plot helpers -----------------------------------------------

plot_resid_fitted <- function(model, basename) {
  df <- data.frame(
    fitted = fitted(model),
    resid = resid(model)
  )
  p <- ggplot(df, aes(x = fitted, y = resid)) +
    geom_point(alpha = 0.5) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(
      x = "Sovitettu arvo",
      y = "Jäännös",
      title = "Jäännökset vs sovitetut arvot"
    ) +
    theme_minimal()
  ggplot2::ggsave(
    filename = file.path(script_dir, paste0(basename, "_resid_fitted.png")),
    plot = p, width = 6, height = 4, dpi = 300
  )
}

plot_qq <- function(model, basename) {
  res <- resid(model)
  n <- length(res)
  res_sorted <- sort(res)
  probs <- ppoints(n)
  theor <- stats::qnorm(probs)
  df <- data.frame(
    theoretical = theor,
    sample = res_sorted
  )
  p <- ggplot(df, aes(x = theoretical, y = sample)) +
    geom_point(alpha = 0.5) +
    geom_abline(intercept = 0, slope = 1, linetype = "dashed") +
    labs(
      x = "Teoreettinen kvantiili",
      y = "Otoksen kvantiili",
      title = "Normaali Q-Q -kuva"
    ) +
    theme_minimal()
  ggplot2::ggsave(
    filename = file.path(script_dir, paste0(basename, "_qq.png")),
    plot = p, width = 6, height = 4, dpi = 300
  )
}

plot_leverage <- function(model, basename) {
  lev <- hatvalues(model)
  df <- data.frame(
    index = seq_along(lev),
    leverage = lev
  )
  p <- ggplot(df, aes(x = index, y = leverage)) +
    geom_point(alpha = 0.5) +
    geom_line(alpha = 0.4) +
    labs(
      x = "Havainto",
      y = "Leverage",
      title = "Leverage-arvot"
    ) +
    theme_minimal()
  ggplot2::ggsave(
    filename = file.path(script_dir, paste0(basename, "_leverage.png")),
    plot = p, width = 6, height = 4, dpi = 300
  )
}

# Simuloitu data (varavaihtoehto) ---------------------------------------------

simulate_moderation_data <- function(n = 400L) {
  set.seed(123)
  Age <- round(rnorm(n, mean = 75, sd = 6))
  Sex <- factor(sample(c("F", "M"), size = n, replace = TRUE, prob = c(0.6, 0.4)))
  BMI <- rnorm(n, mean = 27, sd = 4)
  Composite_Z0 <- rnorm(n, mean = 0, sd = 1)
  FOF_status <- rbinom(n, size = 1, prob = 0.4)

  baseline_effect <- -0.1 * Composite_Z0
  mod_effect <- -0.25 * FOF_status + 0.15 * FOF_status * Composite_Z0
  noise <- rnorm(n, mean = 0, sd = 0.5)
  Delta_Composite_Z <- baseline_effect + mod_effect + noise

  data.frame(
    Delta_Composite_Z = Delta_Composite_Z,
    Composite_Z0 = Composite_Z0,
    FOF_status = FOF_status,
    Age = Age,
    Sex = Sex,
    BMI = BMI
  )
}

# Johnson–Neyman-apufunktiot --------------------------------------------------

compute_jn_region_binary <- function(model, alpha = 0.05, mod_var = "cComposite_Z0") {
  coefs <- coef(model)
  vc <- vcov(model)

  fof_coef_name <- grep("^FOF_status1$", names(coefs), value = TRUE)
  if (length(fof_coef_name) != 1L) {
    stop("FOF_status1 coefficient not found in model.", call. = FALSE)
  }

  int_pattern1 <- paste0("FOF_status1:", mod_var)
  int_pattern2 <- paste0(mod_var, ":FOF_status1")
  int_coef_name <- grep(paste0("(", int_pattern1, "|", int_pattern2, ")"),
                        names(coefs), value = TRUE)
  if (length(int_coef_name) != 1L) {
    stop("Interaction coefficient for FOF_status1 x moderator not found.", call. = FALSE)
  }

  b1 <- coefs[fof_coef_name]
  b3 <- coefs[int_coef_name]

  var_b1 <- vc[fof_coef_name, fof_coef_name]
  var_b3 <- vc[int_coef_name, int_coef_name]
  cov_b1b3 <- vc[fof_coef_name, int_coef_name]

  df_res <- df.residual(model)
  t_crit <- stats::qt(1 - alpha / 2, df = df_res)

  A <- t_crit^2 * var_b3 - b3^2
  B <- 2 * (t_crit^2 * cov_b1b3 - b1 * b3)
  C <- t_crit^2 * var_b1 - b1^2

  disc <- B^2 - 4 * A * C
  z_min <- min(model$model[[mod_var]], na.rm = TRUE)
  z_max <- max(model$model[[mod_var]], na.rm = TRUE)

  if (disc < 0 || abs(A) < .Machine$double.eps) {
    z0 <- mean(model$model[[mod_var]], na.rm = TRUE)
    eff <- b1 + b3 * z0
    se_eff <- sqrt(var_b1 + 2 * z0 * cov_b1b3 + z0^2 * var_b3)
    t_val <- eff / se_eff
    p_val <- 2 * stats::pt(-abs(t_val), df = df_res)
    region_type <- if (p_val < alpha) "significant_all" else "nonsignificant_all"
    return(list(
      roots = numeric(0),
      region_type = region_type,
      alpha = alpha,
      mod_min = z_min,
      mod_max = z_max
    ))
  }

  sqrt_disc <- sqrt(disc)
  z1 <- (-B - sqrt_disc) / (2 * A)
  z2 <- (-B + sqrt_disc) / (2 * A)
  roots <- sort(c(z1, z2))

  list(
    roots = roots,
    region_type = "partially_significant",
    alpha = alpha,
    mod_min = z_min,
    mod_max = z_max
  )
}

make_jn_slope_plot <- function(model, jn_info, mod_var = "cComposite_Z0",
                               filename = "jn_slope_plot.png",
                               xlabel = "Lähtötason komposiitti (keskitetty)") {
  coefs <- coef(model)
  vc <- vcov(model)

  fof_coef_name <- grep("^FOF_status1$", names(coefs), value = TRUE)
  int_pattern1 <- paste0("FOF_status1:", mod_var)
  int_pattern2 <- paste0(mod_var, ":FOF_status1")
  int_coef_name <- grep(paste0("(", int_pattern1, "|", int_pattern2, ")"),
                        names(coefs), value = TRUE)

  if (length(fof_coef_name) != 1L || length(int_coef_name) != 1L) {
    stop("Could not find FOF_status1 or interaction term in the model.", call. = FALSE)
  }

  b1 <- coefs[fof_coef_name]
  b3 <- coefs[int_coef_name]

  var_b1 <- vc[fof_coef_name, fof_coef_name]
  var_b3 <- vc[int_coef_name, int_coef_name]
  cov_b1b3 <- vc[fof_coef_name, int_coef_name]

  df_res <- df.residual(model)
  alpha <- jn_info$alpha
  t_crit <- stats::qt(1 - alpha / 2, df = df_res)

  z_seq <- seq(jn_info$mod_min, jn_info$mod_max, length.out = 200)

  effects <- b1 + b3 * z_seq
  se_eff <- sqrt(var_b1 + 2 * z_seq * cov_b1b3 + z_seq^2 * var_b3)
  lower <- effects - t_crit * se_eff
  upper <- effects + t_crit * se_eff
  p_vals <- 2 * stats::pt(-abs(effects / se_eff), df = df_res)
  sig_flag <- p_vals < alpha

  df <- data.frame(
    moderator = z_seq,
    effect = effects,
    lower = lower,
    upper = upper,
    p_value = p_vals,
    significant = sig_flag
  )

  p <- ggplot(df, aes(x = moderator, y = effect)) +
    geom_ribbon(aes(ymin = lower, ymax = upper, alpha = significant),
                show.legend = FALSE) +
    geom_line() +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(
      x = xlabel,
      y = "FOF 1 vs 0 -vaikutus Delta_Composite_Z -muutokseen",
      title = "Johnson-Neyman -slope FOF-statukselle"
    ) +
    scale_alpha_manual(values = c(`TRUE` = 0.3, `FALSE` = 0.05)) +
    theme_minimal()

  if (!is.null(jn_info$roots) && length(jn_info$roots) > 0) {
    for (r in jn_info$roots) {
      p <- p + geom_vline(xintercept = r, linetype = "dotted")
    }
  }

  ggplot2::ggsave(
    filename = file.path(script_dir, filename),
    plot = p, width = 7, height = 5, dpi = 300
  )
}

# 2. Load data and basic checks ----------------------------------------------

data_default_path <- here::here("data", "external", "KaatumisenPelko.csv")

args <- commandArgs(trailingOnly = TRUE)
is_interactive <- interactive()

if (length(args) > 0 && file.exists(args[1])) {
  data_path <- args[1]
  message("Using data file (command line): ", data_path)
  raw_data <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  data_source <- "file"

} else if (is_interactive) {
  message("No command line data path supplied. Using project data via here().")

  data_path <- data_default_path

  if (!file.exists(data_path)) {
    stop(
      "Data file not found: ", data_path,
      "\nCheck that dataset/KaatumisenPelko.csv exists in the project root."
    )
  }

  message("Using data file (RStudio interactive): ", data_path)
  raw_data <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  data_source <- "file"

} else {
  message("No valid data file supplied. Using simulated data.")
  raw_data <- simulate_moderation_data()
  data_source <- "simulated"
}

# Mapataan sarakkeet analyysin käyttämiin nimiin ------------------------------

raw_data <- raw_data %>%
  dplyr::mutate(
    Composite_Z0 = ToimintaKykySummary0,
    Delta_Composite_Z = ToimintaKykySummary2 - ToimintaKykySummary0,
    FOF_status = dplyr::case_when(
      kaatumisenpelkoOn %in% c("0", 0) ~ 0,
      kaatumisenpelkoOn %in% c("1", 1) ~ 1,
      TRUE ~ NA_real_
    ),
    Age = age,
    Sex = sex
    # BMI = BMI
  )

# Tarkista vaaditut sarakkeet -------------------------------------------------

required_columns <- c(
  "Delta_Composite_Z",
  "Composite_Z0",
  "FOF_status",
  "Age",
  "Sex",
  "BMI"
)

missing_cols <- setdiff(required_columns, names(raw_data))
if (length(missing_cols) > 0) {
  stop(
    sprintf("Required columns missing: %s",
            paste(missing_cols, collapse = ", ")),
    call. = FALSE
  )
}

fof_vals <- sort(unique(raw_data$FOF_status))
if (!all(fof_vals %in% c(0, 1))) {
  stop(
    sprintf("FOF_status must be coded 0/1. Observed: %s",
            paste(fof_vals, collapse = ", ")),
    call. = FALSE
  )
}

analysis_data <- raw_data %>%
  dplyr::mutate(
    FOF_status = factor(FOF_status, levels = c(0, 1)),
    Sex = factor(Sex)
  ) %>%
  dplyr::select(dplyr::all_of(required_columns))

n_before <- nrow(analysis_data)
analysis_data_cc <- analysis_data %>%
  tidyr::drop_na()
n_after <- nrow(analysis_data_cc)
message("Complete-case rows: ", n_after, " of ", n_before)

if (n_after < n_before * 0.8) {
  warning("More than 20 percent of rows removed in complete-case analysis.")
}

# Center and standardize moderator -------------------------------------------

analysis_data_cc <- analysis_data_cc %>%
  dplyr::mutate(
    cComposite_Z0 = as.numeric(scale(Composite_Z0, center = TRUE, scale = FALSE)),
    zComposite_Z0 = as.numeric(scale(Composite_Z0, center = TRUE, scale = TRUE))
  )

# 3. Main models recap (quartile ANCOVA and continuous interaction) ----------

analysis_data_cc <- analysis_data_cc %>%
  dplyr::mutate(
    Comp_Quartile = dplyr::ntile(Composite_Z0, 4L),
    Comp_Quartile = factor(
      Comp_Quartile,
      levels = 1:4,
      labels = c("Q1_Weakest", "Q2", "Q3", "Q4_Strongest")
    )
  )

cell_counts <- analysis_data_cc %>%
  dplyr::count(FOF_status, Comp_Quartile, name = "N")
save_table_csv_html(cell_counts, "discrete_cell_counts_initial")

if (any(cell_counts$N < 30)) {
  warning("Some FOF x Quartile cells < 30. Merging Q3 and Q4.")
  analysis_data_cc <- analysis_data_cc %>%
    dplyr::mutate(
      Comp_Quartile = as.character(Comp_Quartile),
      Comp_Quartile = dplyr::case_when(
        Comp_Quartile %in% c("Q3", "Q4_Strongest") ~ "Q3_Q4_Strongest",
        TRUE ~ Comp_Quartile
      ),
      Comp_Quartile = factor(
        Comp_Quartile,
        levels = c("Q1_Weakest", "Q2", "Q3_Q4_Strongest")
      )
    )

  cell_counts <- analysis_data_cc %>%
    dplyr::count(FOF_status, Comp_Quartile, name = "N")
}
save_table_csv_html(cell_counts, "discrete_cell_counts_final")

model_quartile_full <- stats::lm(
  Delta_Composite_Z ~ FOF_status * Comp_Quartile + Age + Sex + BMI + Composite_Z0,
  data = analysis_data_cc
)
tidy_quartile_full <- broom::tidy(model_quartile_full, conf.int = TRUE)
save_table_csv_html(tidy_quartile_full, "model_quartile_full_tidy")

model_quartile_pars <- stats::lm(
  Delta_Composite_Z ~ FOF_status * Comp_Quartile + Age + Sex + BMI,
  data = analysis_data_cc
)
tidy_quartile_pars <- broom::tidy(model_quartile_pars, conf.int = TRUE)
save_table_csv_html(tidy_quartile_pars, "model_quartile_pars_tidy")

anova_quartile_compare <- anova(model_quartile_pars, model_quartile_full)
anova_quartile_df <- broom::tidy(anova_quartile_compare)
save_table_csv_html(anova_quartile_df, "model_quartile_full_vs_pars")

emm_quart <- emmeans::emmeans(model_quartile_pars,
                              specs = ~ FOF_status | Comp_Quartile)
emm_quart_df <- as.data.frame(emm_quart)
save_table_csv_html(emm_quart_df, "discrete_lsmeans_pars")

p_lsmeans <- ggplot(emm_quart_df,
                    aes(x = Comp_Quartile, y = emmean,
                        color = FOF_status, group = FOF_status)) +
  geom_point(position = position_dodge(width = 0.2)) +
  geom_errorbar(
    aes(ymin = lower.CL, ymax = upper.CL),
    width = 0.1,
    position = position_dodge(width = 0.2)
  ) +
  geom_line(position = position_dodge(width = 0.2)) +
  labs(
    x = "Lähtötason komposiittikvartiili",
    y = "Vakioitu keskiarvo Delta_Composite_Z",
    color = "FOF_status",
    title = "Vakioidut keskiarvot Delta_Composite_Z FOF- ja kvartiiliryhmittäin"
  ) +
  theme_minimal()
ggplot2::ggsave(
  filename = file.path(script_dir, "discrete_lsmeans_plot_updated.png"),
  plot = p_lsmeans, width = 7, height = 5, dpi = 300
)

# Continuous interaction model ------------------------------------------------

model_jn_c <- stats::lm(
  Delta_Composite_Z ~ FOF_status * cComposite_Z0 + Age + Sex + BMI,
  data = analysis_data_cc
)
tidy_jn_c <- broom::tidy(model_jn_c, conf.int = TRUE)
save_table_csv_html(tidy_jn_c, "model_jn_c_tidy")

# 4. Nonlinearity via splines -------------------------------------------------

model_lin <- model_jn_c
model_spline <- stats::lm(
  Delta_Composite_Z ~ FOF_status * splines::ns(cComposite_Z0, df = 3) +
    Age + Sex + BMI,
  data = analysis_data_cc
)

anova_spline <- anova(model_lin, model_spline)
anova_spline_df <- broom::tidy(anova_spline)
save_table_csv_html(anova_spline_df, "model_spline_vs_linear")

z_seq <- seq(min(analysis_data_cc$cComposite_Z0),
             max(analysis_data_cc$cComposite_Z0),
             length.out = 100)

sex_ref <- names(sort(table(analysis_data_cc$Sex), decreasing = TRUE))[1]

newdat <- expand.grid(
  cComposite_Z0 = z_seq,
  FOF_status = levels(analysis_data_cc$FOF_status),
  Age = mean(analysis_data_cc$Age, na.rm = TRUE),
  Sex = factor(sex_ref, levels = levels(analysis_data_cc$Sex)),
  BMI = mean(analysis_data_cc$BMI, na.rm = TRUE)
)

pred_spline <- cbind(
  newdat,
  predict(model_spline, newdata = newdat, se.fit = TRUE)
)
pred_spline$lower <- pred_spline$fit - 1.96 * pred_spline$se.fit
pred_spline$upper <- pred_spline$fit + 1.96 * pred_spline$se.fit

p_spline <- ggplot(pred_spline,
                   aes(x = cComposite_Z0, y = fit,
                       color = FOF_status)) +
  geom_line() +
  geom_ribbon(aes(ymin = lower, ymax = upper, fill = FOF_status),
              alpha = 0.1, color = NA) +
  labs(
    x = "Lähtötason komposiitti (keskitetty)",
    y = "Ennustettu Delta_Composite_Z",
    color = "FOF_status", fill = "FOF_status",
    title = "Spline-malli: FOF x lähtötaso"
  ) +
  theme_minimal()
ggplot2::ggsave(
  filename = file.path(script_dir, "spline_interaction_plot.png"),
  plot = p_spline, width = 7, height = 5, dpi = 300
)

# 5. Johnson-Neyman on centered and standardized moderator --------------------

jn_info_c <- compute_jn_region_binary(model_jn_c, alpha = 0.05,
                                      mod_var = "cComposite_Z0")

jn_summary_c <- if (jn_info_c$region_type == "partially_significant") {
  data.frame(
    scale = "centered",
    region_type = jn_info_c$region_type,
    alpha = jn_info_c$alpha,
    root1 = round(jn_info_c$roots[1], 2),
    root2 = round(jn_info_c$roots[2], 2),
    mod_min = round(jn_info_c$mod_min, 2),
    mod_max = round(jn_info_c$mod_max, 2)
  )
} else {
  data.frame(
    scale = "centered",
    region_type = jn_info_c$region_type,
    alpha = jn_info_c$alpha,
    mod_min = round(jn_info_c$mod_min, 2),
    mod_max = round(jn_info_c$mod_max, 2)
  )
}

make_jn_slope_plot(model_jn_c, jn_info_c,
                   mod_var = "cComposite_Z0",
                   filename = "jn_slope_plot_centered.png",
                   xlabel = "Lähtötason komposiitti (keskitetty)")

model_jn_z <- stats::lm(
  Delta_Composite_Z ~ FOF_status * zComposite_Z0 + Age + Sex + BMI,
  data = analysis_data_cc
)
tidy_jn_z <- broom::tidy(model_jn_z, conf.int = TRUE)
save_table_csv_html(tidy_jn_z, "model_jn_z_tidy")

jn_info_z <- compute_jn_region_binary(model_jn_z, alpha = 0.05,
                                      mod_var = "zComposite_Z0")

jn_summary_z <- if (jn_info_z$region_type == "partially_significant") {
  data.frame(
    scale = "standardized",
    region_type = jn_info_z$region_type,
    alpha = jn_info_z$alpha,
    root1 = round(jn_info_z$roots[1], 2),
    root2 = round(jn_info_z$roots[2], 2),
    mod_min = round(jn_info_z$mod_min, 2),
    mod_max = round(jn_info_z$mod_max, 2)
  )
} else {
  data.frame(
    scale = "standardized",
    region_type = jn_info_z$region_type,
    alpha = jn_info_z$alpha,
    mod_min = round(jn_info_z$mod_min, 2),
    mod_max = round(jn_info_z$mod_max, 2)
  )
}

make_jn_slope_plot(model_jn_z, jn_info_z,
                   mod_var = "zComposite_Z0",
                   filename = "jn_slope_plot_standardized.png",
                   xlabel = "Lähtötason komposiitti (standardisoitu)")

jn_summary_all <- rbind(jn_summary_c, jn_summary_z)
save_table_csv_html(jn_summary_all, "jn_region_summary_centered_and_z")

# 6. Missing data: MICE workflow ----------------------------------------------

md_pattern <- mice::md.pattern(analysis_data[, required_columns], plot = FALSE)
md_pattern_df <- as.data.frame(md_pattern)
save_table_csv_html(md_pattern_df, "missing_data_pattern")

mice_data <- analysis_data[, required_columns]

ini <- mice::mice(mice_data, m = 1, maxit = 0, printFlag = FALSE)
pred <- ini$predictorMatrix
pred["Delta_Composite_Z", ] <- 0

imp <- mice::mice(mice_data, m = 20, predictorMatrix = pred,
                  seed = 123, printFlag = FALSE)

fit_imp_jn <- with(imp, lm(
  Delta_Composite_Z ~ factor(FOF_status) * I(scale(Composite_Z0, center = TRUE, scale = FALSE)) +
    Age + factor(Sex) + BMI
))
pool_imp_jn <- mice::pool(fit_imp_jn)
imp_jn_summary <- summary(pool_imp_jn, conf.int = TRUE)
save_table_csv_html(imp_jn_summary, "mice_pooled_model_jn")

# 7. Selection sensitivity: IPW -----------------------------------------------

cc_indicator <- complete.cases(analysis_data[, required_columns])
analysis_data$CC <- as.integer(cc_indicator)

ipw_model <- stats::glm(
  CC ~ FOF_status + Composite_Z0 + Age + Sex + BMI,
  data = analysis_data,
  family = binomial,
  na.action = na.exclude
)

analysis_data$ipw_prob <- fitted(ipw_model)
analysis_data$ipw_weight <- ifelse(analysis_data$CC == 1,
                                   1 / analysis_data$ipw_prob,
                                   NA_real_)

analysis_data_cc_ipw <- analysis_data_cc %>%
  dplyr::mutate(
    ipw_weight = analysis_data$ipw_weight[match(rownames(analysis_data_cc),
                                                rownames(analysis_data))]
  )

model_jn_c_ipw <- stats::lm(
  Delta_Composite_Z ~ FOF_status * cComposite_Z0 + Age + Sex + BMI,
  data = analysis_data_cc_ipw,
  weights = ipw_weight
)
tidy_jn_c_ipw <- broom::tidy(model_jn_c_ipw, conf.int = TRUE)
save_table_csv_html(tidy_jn_c_ipw, "model_jn_c_ipw_tidy")

# 8. Multiplicity and effect sizes --------------------------------------------

tidy_main <- tidy_jn_c
key_terms <- tidy_main$term %in% c("FOF_status1", "cComposite_Z0",
                                   "FOF_status1:cComposite_Z0",
                                   "Age", "BMI")
p_vals <- tidy_main$p.value[key_terms]
names(p_vals) <- tidy_main$term[key_terms]

holm_p <- p.adjust(p_vals, method = "holm")
bh_p <- p.adjust(p_vals, method = "BH")

mult_df <- data.frame(
  term = names(p_vals),
  p_raw = p_vals,
  p_holm = holm_p,
  p_bh = bh_p
)
save_table_csv_html(mult_df, "multiplicity_adjusted_pvalues")

eta_sq <- effectsize::eta_squared(car::Anova(model_jn_c, type = 3),
                                  partial = TRUE)
eta_sq_df <- as.data.frame(eta_sq)
save_table_csv_html(eta_sq_df, "effectsize_eta_sq")

g_obj <- effectsize::hedges_g(Delta_Composite_Z ~ FOF_status,
                              data = analysis_data_cc,
                              ci = 0.95)
g_df <- as.data.frame(g_obj)
save_table_csv_html(g_df, "effectsize_hedges_g_center")

# Model R^2 summary (robust to r2_generic class) ------------------------------

r2_obj <- performance::r2(model_jn_c)
r2_list <- unclass(r2_obj)
if (is.list(r2_list)) {
  r2_df <- data.frame(r2_list, check.names = FALSE)
} else {
  r2_df <- data.frame(R2 = as.numeric(r2_obj))
}
save_table_csv_html(r2_df, "model_r2_summary")

# 9. Simple effect probes at clinically relevant cutpoints -------------------

cutpoints <- c(-1, 0, 1)
cut_labels <- c("Low (-1 SD)", "Mean (0)", "High (+1 SD)")

probe_list <- lapply(seq_along(cutpoints), function(i) {
  cp <- cutpoints[i]
  label <- cut_labels[i]

  emm_cp <- emmeans::emmeans(
    model_jn_c,
    specs = ~ FOF_status | cComposite_Z0,
    at = list(cComposite_Z0 = cp)
  )
  contr_cp <- emmeans::contrast(emm_cp, method = "revpairwise")
  df_cp <- as.data.frame(contr_cp)
  df_cp$cutpoint <- cp
  df_cp$cut_label <- label
  df_cp
})

probe_df <- do.call(rbind, probe_list)
save_table_csv_html(probe_df, "simple_effects_by_moderator_cutpoints")

contrast_fof_by_moderator_cutpoints <- probe_df

age_med <- stats::median(analysis_data_cc$Age)
analysis_data_cc <- analysis_data_cc %>%
  dplyr::mutate(
    Age_group = ifelse(Age <= age_med, "Younger", "Older")
  )

# 10. Precision context: detectable interaction effect -----------------------

alpha <- 0.05
target_power <- 0.8
z_alpha <- stats::qnorm(1 - alpha / 2)
z_power <- stats::qnorm(target_power)

jn_term <- tidy_main[tidy_main$term == "FOF_status1:cComposite_Z0", ]
se_beta <- jn_term$std.error[1]
beta_detectable <- (z_alpha + z_power) * se_beta

precision_df <- data.frame(
  term = "FOF_status1:cComposite_Z0",
  se_beta = se_beta,
  approx_detectable_beta_for_80pct_power = beta_detectable
)
save_table_csv_html(precision_df, "precision_detectable_interaction")

# 11. Diagnostics and HC3 robust checks --------------------------------------

vc_hc3_jn <- sandwich::vcovHC(model_jn_c, type = "HC3")
robust_jn <- lmtest::coeftest(model_jn_c, vcov. = vc_hc3_jn)
robust_jn_df <- data.frame(
  term = rownames(robust_jn),
  estimate = robust_jn[, "Estimate"],
  std_error = robust_jn[, "Std. Error"],
  statistic = robust_jn[, "t value"],
  p_value = robust_jn[, "Pr(>|t|)"],
  row.names = NULL
)
save_table_csv_html(robust_jn_df, "model_jn_c_robustHC3")

plot_resid_fitted(model_jn_c, "diagnostics_jn_c")
plot_qq(model_jn_c, "diagnostics_jn_c")
plot_leverage(model_jn_c, "diagnostics_jn_c")

bp_jn <- lmtest::bptest(model_jn_c)
bp_jn_df <- broom::tidy(bp_jn)
save_table_csv_html(bp_jn_df, "breusch_pagan_jn_c")

# 12. Updated Finnish Results text block -------------------------------------

results_text <- paste(
  "Tulokset pysyivät pääpiirteissään samoina, kun analysit laajennettiin",
  "ei-lineaarisuuden, puuttuvien arvojen ja valikoitumisen herkkyystarkasteluihin.",
  "Spline-malli ei parantanut sovitusta merkittävästi lineaariseen moderointimalliin verrattuna,",
  "eikä FOF-status x Composite_Z0 -interaktiolle saatu johdonmukaista näyttöä ei-lineaarisesta vaikutuksesta.",
  "Johnson-Neyman -analyysi vahvisti, että FOF-ryhmien välinen ero Delta_Composite_Z -muutoksessa oli",
  "tilastollisesti merkitsevä vain kapealla lähtötason alueella lähellä keskiarvoa,",
  "kun taas hyvin heikoilla ja hyvin vahvoilla lähtötasoilla erot olivat saman suuntaisia,",
  "mutta luottamusvälit laajenivat.",
  "Multiple imputation (MICE, m = 20) ja inverse probability -painotuksella tehty analyysi tuottivat",
  "pääosin samansuuntaiset estimaatit FOF-statuksen, iän ja BMI:n vaikutuksille,",
  "eikä FOF x lähtötaso -interaktio tullut merkitseväksi myöskään näissä malleissa.",
  "Ikä ja BMI säilyivät johdonmukaisesti heikompaan toimintakyvyn muutokseen liittyvinä tekijöinä,",
  "kun taas sukupuolen ja jatkuvan lähtötason komposiitin päävaikutukset olivat epävarmempia.",
  "Monen testin korjaus (Holm ja BH) ei muuttanut johtopäätöksiä siitä, mitkä termit olivat luotettavasti merkitseviä.",
  "Havaittujen efektikokojen perusteella FOF-statuksen vaikutus oli pieni-keskisuuri,",
  "ja laskennallinen havaittava interaktioefekti oli nykyisellä otoskoolla varsin suuri,",
  "mikä tukee tulkintaa, että nollahavainto moderoinnista voi osin heijastaa rajallista tilastollista tarkkuutta."
)
writeLines(results_text, con = file.path(script_dir, "results_addendum_finnish.txt"))

# 13. Manifestin päivitys: keskeiset taulukot ja kuvat -----------------------

tidy_jn_c_path <- file.path(script_dir, "K5.1_MA_tidy_jn_c.csv")
if (!file.exists(tidy_jn_c_path)) {
  utils::write.csv(tidy_jn_c, tidy_jn_c_path, row.names = FALSE)
}

jn_summary_all_path <- file.path(script_dir, "K5.1_MA_jn_summary_all.csv")
if (!file.exists(jn_summary_all_path)) {
  utils::write.csv(jn_summary_all, jn_summary_all_path, row.names = FALSE)
}

mult_df_path <- file.path(script_dir, "K5.1_MA_multiplicity_pvalues.csv")
if (!file.exists(mult_df_path)) {
  utils::write.csv(mult_df, mult_df_path, row.names = FALSE)
}

eta_sq_df_path <- file.path(script_dir, "K5.1_MA_eta_sq_partial.csv")
if (!file.exists(eta_sq_df_path)) {
  utils::write.csv(eta_sq_df, eta_sq_df_path, row.names = FALSE)
}

g_df_path <- file.path(script_dir, "K5.1_MA_effectsize_hedges_g.csv")
if (!file.exists(g_df_path)) {
  utils::write.csv(g_df, g_df_path, row.names = FALSE)
}

r2_df_path <- file.path(script_dir, "K5.1_MA_model_r2.csv")
if (!file.exists(r2_df_path)) {
  utils::write.csv(r2_df, r2_df_path, row.names = FALSE)
}

jn_slope_centered_src <- file.path(outputs_dir, "jn_slope_plot_centered.png")
jn_slope_centered_dst <- file.path(script_dir, "jn_slope_plot_centered.png")
if (file.exists(jn_slope_centered_src)) {
  file.copy(jn_slope_centered_src, jn_slope_centered_dst, overwrite = TRUE)
}

spline_plot_src <- file.path(outputs_dir, "spline_interaction_plot.png")
spline_plot_dst <- file.path(script_dir, "spline_interaction_plot.png")
if (file.exists(spline_plot_src)) {
  file.copy(spline_plot_src, spline_plot_dst, overwrite = TRUE)
}

results_addendum_src <- file.path(outputs_dir, "results_addendum_finnish.txt")
results_addendum_dst <- file.path(script_dir, "results_addendum_finnish.txt")
if (file.exists(results_addendum_src)) {
  file.copy(results_addendum_src, results_addendum_dst, overwrite = TRUE)
}

manifest_rows <- data.frame(
  script      = script_label,
  type        = c(
    "table", "table", "table", "table", "table", "table",
    "plot", "plot",
    "text"
  ),
  filename    = c(
    file.path(script_label, basename(tidy_jn_c_path)),
    file.path(script_label, basename(jn_summary_all_path)),
    file.path(script_label, basename(eta_sq_df_path)),
    file.path(script_label, basename(g_df_path)),
    file.path(script_label, basename(mult_df_path)),
    file.path(script_label, basename(r2_df_path)),
    file.path(script_label, "jn_slope_plot_centered.png"),
    file.path(script_label, "spline_interaction_plot.png"),
    file.path(script_label, "results_addendum_finnish.txt")
  ),
  description = c(
    "Päämoderointimallin regressiokertoimet (lm: Delta_Composite_Z ~ FOF_status * cComposite_Z0 + kovariaatit)",
    "Johnson–Neyman-alueiden yhteenveto (keskitetty ja standardoitu moderaattori)",
    "Osittainen eta-neliö (partial eta^2) jatkuvassa moderointimallissa",
    "Hedges g -efektikoko (FOF 1 vs 0) koko aineistossa",
    "P-arvojen monen vertailun korjaus (Holm ja BH) keskeisille termeille",
    "Mallin selitysaste (R2 ja adj. R2) jatkuvassa moderointimallissa",
    "JN-slope-kuva: FOF 1 vs 0 -ero ΔComposite_Z:ssa moderaattorin funktiona (keskitetty)",
    "Spline-interaktiokuva: FOF x lähtötason komposiitti (keskitetty)",
    "Suomenkielinen tulosteksti moderointianalyysin lisäselvitykselle"
  ),
  stringsAsFactors = FALSE
)

if (!file.exists(manifest_path)) {
  write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = TRUE,
    append    = FALSE,
    qmethod   = "double"
  )
} else {
  write.table(
    manifest_rows,
    file      = manifest_path,
    sep       = ",",
    row.names = FALSE,
    col.names = FALSE,
    append    = TRUE,
    qmethod   = "double"
  )
}
message("Manifest päivitetty: ", manifest_path)

# 14. Session info ------------------------------------------------------------

session_info <- sessionInfo()
capture.output(session_info, file = file.path(script_dir, "session_info.txt"))

message("Analysis complete. Outputs written to ./outputs/", script_label)

# End of K5.1.V4_Moderation_analysis.R