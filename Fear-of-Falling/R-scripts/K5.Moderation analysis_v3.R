#!/usr/bin/env Rscript

###############################################################################
# README
#
# Purpose:
#   Moderation analysis of change in composite z-score (Delta_Composite_Z)
#   by FOF_status, with baseline Composite_Z0 as moderator.
#   Implements:
#     - Discrete moderation via quartiles of Composite_Z0.
#     - Continuous moderation via Johnson-Neyman probing of FOF_status x Composite_Z0.
#
# Required columns in the input data:
#   - Delta_Composite_Z  (numeric; follow-up minus baseline composite z-score)
#   - Composite_Z0       (numeric; baseline composite z-score)
#   - FOF_status         (numeric; must be 0 or 1)
#   - Age                (numeric)
#   - Sex                (categorical; will be treated as factor)
#   - BMI                (numeric)
#
# Usage:
#   Rscript K5.Moderation analysis.R /path/to/your_data.csv
#
# Behavior:
#   - If a valid CSV path is supplied as the first argument, the script reads it.
#   - If no path is supplied or the file does not exist, the script simulates
#     a minimal reproducible example dataset and runs the full pipeline on that.
#
# Data input modes:
#   (A) Command line / batch use:
#       - When you run the script as:
#           Rscript K5.Moderation analysis.R /path/to/your_data.csv
#         the CSV file is expected to ALREADY contain the analysis variables
#         with the following column names:
#           * Delta_Composite_Z
#           * Composite_Z0
#           * FOF_status  (0/1)
#           * Age
#           * Sex
#           * BMI
#
#   (B) Interactive use in R / RStudio:
#       - When you source() the script and set 'data_path' manually to a
#         project-specific dataset (e.g. KaatumisenPelko.csv), the script
#         assumes the following ORIGINAL variable names in that file:
#           * ToimintaKykySummary0  (baseline composite)
#           * ToimintaKykySummary2  (follow-up composite)
#           * kaatumisenpelkoOn     (0/1 FOF indicator)
#           * age                   (age in years)
#           * sex                   (sex/gender)
#           * BMI                   (body mass index)
#       - These are internally mapped to the analysis variables:
#           Composite_Z0        <- ToimintaKykySummary0
#           Delta_Composite_Z   <- ToimintaKykySummary2 - ToimintaKykySummary0
#           FOF_status          <- as.integer(kaatumisenpelkoOn)
#           Age                 <- age
#           Sex                 <- sex
#           BMI                 <- BMI
#
#   In summary:
#     - Command line mode expects the analysis-ready columns.
#     - Interactive mode can start from the original project variable names
#       and performs the mapping inside the script.


#
# Outputs (created under ./outputs/):
#   - Tables (CSV + HTML):
#       * discrete_cell_counts.initial/final.*
#       * discrete_lsmeans.*
#       * discrete_lsmeans_cld.*
#       * model_quartile_tidy.*
#       * model_quartile_robustHC3.*
#       * model_jn_tidy.*
#       * model_jn_robustHC3.*
#       * jn_region_summary.*
#   - Plots (PNG):
#       * discrete_lsmeans_plot.png
#       * jn_slope_plot.png
#       * diagnostics_quartile_resid_fitted.png
#       * diagnostics_quartile_qq.png
#       * diagnostics_quartile_leverage.png
#       * diagnostics_quartile_scale_location.png
#       * diagnostics_quartile_cooks.png
#       * diagnostics_jn_resid_fitted.png
#       * diagnostics_jn_qq.png
#       * diagnostics_jn_leverage.png
#       * diagnostics_jn_scale_location.png
#       * diagnostics_jn_cooks.png
#   - Session info:
#       * session_info.txt
#
# Missing data:
#   - Strategy: listwise deletion for the variables used in each model.
#   - The script reports N before and after filtering and warns if more than
#     20 percent of rows are removed.
#
# Centering and scaling:
#   - Composite_Z0 is mean-centered (cComposite_Z0) for continuous moderation.
#   - Quartiles are formed from the raw Composite_Z0 distribution.
#
# Notes:
#   - The script is written for reproducible research use.
#   - Packages are checked on load; an informative error is thrown if missing.
#   - Robust HC3 standard errors are used as the main reference; classical SEs
#     are exported as sensitivity.
###############################################################################

# ----------------------------- 1. Setup --------------------------------------

if (!dir.exists("outputs")) {
  dir.create("outputs", recursive = TRUE)
}



required_packages <- c(
  "dplyr",
  "ggplot2",
  "broom",
  "emmeans",
  "sandwich",
  "lmtest",
  "knitr",
  "haven",
  "here"
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


data_path <- here("data", "external", "KaatumisenPelko.csv")
# ------------------------ 2. Helper functions --------------------------------

# Simulaatio-haara: siemen asetetaan vain tässä, jotta muu analyysi ei lukitu yhteen satunnaissiemeneen.
simulate_moderation_data <- function(n = 400L) {
  # Simulate a plausible data set for debugging and illustration.
  set.seed(123)
  Age <- round(rnorm(n, mean = 75, sd = 6))
  Sex <- factor(sample(c("F", "M"), size = n, replace = TRUE, prob = c(0.6, 0.4)))
  BMI <- rnorm(n, mean = 27, sd = 4)
  Composite_Z0 <- rnorm(n, mean = 0, sd = 1)
  FOF_status <- rbinom(n, size = 1, prob = 0.5)
  Delta_Composite_Z <- rnorm(
    n,
    mean = -0.1 * FOF_status + 0.05 * Composite_Z0,
    sd = 0.5
  )
  dplyr::tibble(
    Delta_Composite_Z = Delta_Composite_Z,
    Composite_Z0 = Composite_Z0,
    FOF_status = FOF_status,
    Age = Age,
    Sex = Sex,
    BMI = BMI
  )
}

save_table_csv_html <- function(df, basename) {
  csv_path <- file.path("outputs", paste0(basename, ".csv"))
  html_path <- file.path("outputs", paste0(basename, ".html"))
  utils::write.csv(df, csv_path, row.names = FALSE)
  meta <- data.frame(
    generated_at = as.character(Sys.time()),
    n_rows = nrow(df),
    model = if (exists("model_quartile")) deparse(formula(model_quartile)) else NA_character_
  )
  html_table <- knitr::kable(
    df,
    format = "html",
    table.attr = "border='1' style='border-collapse:collapse;'"
  )
  meta_table <- knitr::kable(
    meta,
    format = "html",
    table.attr = "border='1' style='border-collapse:collapse;'"
  )
  html_content <- paste0(
    "<html><head><meta charset='UTF-8'></head><body>",
    "<h3>", basename, "</h3>",
    meta_table,
    html_table,
    "</body></html>"
  )
  writeLines(html_content, con = html_path)
}

plot_resid_fitted <- function(model, basename) {
  df <- data.frame(
    fitted = fitted(model),
    resid = resid(model)
  )
  p <- ggplot(df, aes(x = fitted, y = resid)) +
    geom_point(alpha = 0.5) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(
      x = "Fitted values",
      y = "Residuals",
      title = "Residuals vs fitted"
    ) +
    theme_minimal()
  ggplot2::ggsave(
    filename = file.path("outputs", paste0(basename, "_resid_fitted.png")),
    plot = p,
    width = 6, height = 4, dpi = 300
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
      x = "Theoretical quantiles",
      y = "Sample quantiles",
      title = "Normal Q-Q plot"
    ) +
    theme_minimal()
  ggplot2::ggsave(
    filename = file.path("outputs", paste0(basename, "_qq.png")),
    plot = p,
    width = 6, height = 4, dpi = 300
  )
}

plot_leverage <- function(model, basename) {
  lev <- stats::hatvalues(model)
  cook <- stats::cooks.distance(model)
  df <- data.frame(
    index = seq_along(lev),
    leverage = lev,
    cooks_distance = cook
  )
  p <- ggplot(df, aes(x = index, y = leverage)) +
    geom_point(alpha = 0.5) +
    geom_line(alpha = 0.4) +
    labs(
      x = "Observation index",
      y = "Leverage",
      title = "Leverage (hat values)"
    ) +
    theme_minimal()
  ggplot2::ggsave(
    filename = file.path("outputs", paste0(basename, "_leverage.png")),
    plot = p,
    width = 6, height = 4, dpi = 300
  )
}

plot_scale_location <- function(model, basename) {
  res <- rstandard(model)
  df <- data.frame(
    fitted = fitted(model),
    sqrt_std_resid = sqrt(abs(res))
  )
  p <- ggplot(df, aes(x = fitted, y = sqrt_std_resid)) +
    geom_point(alpha = 0.5) +
    geom_smooth(se = FALSE, method = "loess") +
    labs(
      x = "Fitted values",
      y = "Sqrt(|standardized residuals|)",
      title = "Scale-location plot"
    ) +
    theme_minimal()
  ggplot2::ggsave(
    filename = file.path("outputs", paste0(basename, "_scale_location.png")),
    plot = p,
    width = 6, height = 4, dpi = 300
  )
}

plot_cooks <- function(model, basename) {
  cook <- stats::cooks.distance(model)
  df <- data.frame(index = seq_along(cook), cooks_distance = cook)
  p <- ggplot(df, aes(x = index, y = cooks_distance)) +
    geom_bar(stat = "identity") +
    labs(
      x = "Observation index",
      y = "Cook's distance",
      title = "Cook's distance"
    ) +
    theme_minimal()
  ggplot2::ggsave(
    filename = file.path("outputs", paste0(basename, "_cooks.png")),
    plot = p,
    width = 6, height = 4, dpi = 300
  )
}

compute_jn_region_binary <- function(model, alpha = 0.05, mod_var = "cComposite_Z0",
                                     vcov_mat = sandwich::vcovHC(model, type = "HC3")) {
  coefs <- coef(model)
  vc <- vcov_mat

  # Coefficient for FOF_status level "1" vs reference "0"
  fof_coef_name <- grep("^FOF_status1$", names(coefs), value = TRUE)
  if (length(fof_coef_name) != 1L) {
    stop(
      "Could not find coefficient for FOF_status1 in the model. Check factor coding.",
      call. = FALSE
    )
  }

  # Interaction term may appear in either order
  int_pattern1 <- paste0("FOF_status1:", mod_var)
  int_pattern2 <- paste0(mod_var, ":FOF_status1")

  int_coef_name <- grep(
    paste0("^(", int_pattern1, "|", int_pattern2, ")$"),
    names(coefs),
    value = TRUE
  )

  if (length(int_coef_name) != 1L) {
    stop(
      "Could not uniquely identify interaction term for FOF_status1 and ",
      mod_var,
      ". Found: ", paste(int_coef_name, collapse = ", ")
    )
  }

  b1 <- coefs[fof_coef_name]
  b3 <- coefs[int_coef_name]
  var_b1 <- vc[fof_coef_name, fof_coef_name]
  var_b3 <- vc[int_coef_name, int_coef_name]
  cov_b1b3 <- vc[fof_coef_name, int_coef_name]

  df_res <- df.residual(model)
  t_crit <- stats::qt(1 - alpha / 2, df = df_res)

  # Quadratic equation: (b1 + b3*z)^2 = t_crit^2 * (var_b1 + 2*z*cov_b1b3 + z^2*var_b3)
  A <- b3^2 - t_crit^2 * var_b3
  B <- 2 * (b1 * b3 - t_crit^2 * cov_b1b3)
  C <- b1^2 - t_crit^2 * var_b1

  disc <- B^2 - 4 * A * C

  z_min <- min(model$model[[mod_var]], na.rm = TRUE)
  z_max <- max(model$model[[mod_var]], na.rm = TRUE)

  if (disc < 0 || abs(A) < .Machine$double.eps) {
    # No real roots: either always significant or never significant
    # Determine by evaluating at center of moderator
    z0 <- mean(model$model[[mod_var]], na.rm = TRUE)
    eff <- b1 + b3 * z0
    se_eff <- sqrt(var_b1 + 2 * z0 * cov_b1b3 + z0^2 * var_b3)
    t_val <- eff / se_eff
    p_val <- 2 * stats::pt(-abs(t_val), df = df_res)
    region_type <- if (p_val < alpha) {
      "significant_for_all_observed_values"
    } else {
      "nonsignificant_for_all_observed_values"
    }

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
                               vcov_mat = sandwich::vcovHC(model, type = "HC3")) {
  coefs <- coef(model)
  vc <- vcov_mat

  # Haetaan FOF_status1- ja interaktiotermit
  fof_coef_name <- grep("^FOF_status1$", names(coefs), value = TRUE)
  int_pattern1 <- paste0("FOF_status1:", mod_var)
  int_pattern2 <- paste0(mod_var, ":FOF_status1")
  int_coef_name <- grep(
    paste0("(", int_pattern1, "|", int_pattern2, ")"),
    names(coefs),
    value = TRUE
  )

  if (length(fof_coef_name) != 1L || length(int_coef_name) != 1L) {
    stop(
      "Could not find FOF_status1 or interaction term in the model.",
      call. = FALSE
    )
  }

  b1 <- coefs[fof_coef_name]
  b3 <- coefs[int_coef_name]
  var_b1 <- vc[fof_coef_name, fof_coef_name]
  var_b3 <- vc[int_coef_name, int_coef_name]
  cov_b1b3 <- vc[fof_coef_name, int_coef_name]
  df_res <- df.residual(model)

  alpha <- jn_info$alpha
  t_crit <- stats::qt(1 - alpha / 2, df = df_res)

  # Tehdään moderator-akselin pisteet
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
    geom_ribbon(
      aes(ymin = lower, ymax = upper, alpha = significant)
    ) +
    geom_line() +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(
      x = mod_var,
      y = "Effect of FOF_status (1 vs 0) on Delta_Composite_Z",
      title = "Johnson-Neyman plot for FOF_status by moderator"
    ) +
    scale_alpha_manual(values = c(`TRUE` = 0.3, `FALSE` = 0.05)) +
    theme_minimal()

  # Piirretään J N rajat, jos niitä on
  if (!is.null(jn_info$roots) && length(jn_info$roots) > 0) {
    for (r in jn_info$roots) {
      p <- p + geom_vline(xintercept = r, linetype = "dotted")
    }
  }

  ggplot2::ggsave(
    filename = file.path("outputs", "jn_slope_plot.png"),
    plot = p,
    width = 7, height = 5,
    dpi = 300
  )
}

if (!dir.exists("outputs")) {
  dir.create("outputs", recursive = TRUE)
}

# --- 2.1 Skriptin tunniste ja manifest-polku ---
script_label <- "K5_main"  # voit halutessasi vaihtaa nimen

manifest_path <- file.path("outputs", "manifest.csv")



# ------------------------ 3. Load data and sanity checks ------------------------

args <- commandArgs(trailingOnly = TRUE)
is_interactive <- interactive()

if (length(args) > 0 && file.exists(args[1])) {
  # Komentorivikäyttö: Rscript skripti.R data.csv
  data_path <- args[1]
  message("Using data file (command line): ", data_path)
  raw_data <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  data_source <- "file"

} else if (is_interactive) {
  # RStudio / interaktiivinen käyttö: käyttäjä määrittää projektipohjaisen polun.
  message("No command line data path supplied. Please set 'data_path' to your CSV file.")
  # Example project-based path (uncomment and edit):
  # if (requireNamespace("here", quietly = TRUE)) data_path <- here::here("dataset", "KaatumisenPelko.csv")
  if (!exists("data_path") || !file.exists(data_path)) {
    stop("Data file not found. Define 'data_path' to point to your CSV file.")
  }
  message("Using data file (interactive): ", data_path)
  raw_data <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  data_source <- "file"

  # Map original project-specific variable names to the generic analysis variables
  # described in the README:
  #   ToimintaKykySummary0  -> Composite_Z0
  #   ToimintaKykySummary2  -> Delta_Composite_Z (difference)
  #   kaatumisenpelkoOn     -> FOF_status (0/1)
  #   age                   -> Age
  #   sex                   -> Sex
  #   BMI                   -> BMI

  raw_data <- raw_data %>%
    dplyr::mutate(
      # baseline-komposiitti
      Composite_Z0 = ToimintaKykySummary0,
      # muutoskomposiitti (follow-up - baseline)
      Delta_Composite_Z = ToimintaKykySummary2 - ToimintaKykySummary0,
      # FOF-status 0/1
      FOF_status = as.integer(kaatumisenpelkoOn)
    ) %>%
    dplyr::rename(
      Age = age,
      Sex = sex
      # BMI on jo nimellä "BMI"
    )
} else {
  # Fallback: simulate data if no file is found
  message("No valid data file supplied. Using simulated data for illustration.")
  raw_data <- simulate_moderation_data()
  data_source <- "simulated"
}

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
    "The following required columns were not found in the data: ",
    paste(missing_cols, collapse = ", ")
  )
}

# Basic cleaning and factor coding
analysis_data <- raw_data %>%
  dplyr::mutate(
    FOF_status = factor(FOF_status, levels = c(0, 1)),
    Sex = factor(Sex)
  )

# ------------------------ 4. Main moderation pipeline as a function -------------------

run_moderation_pipeline <- function(data) {

  # Tehdään kopio ja varmistetaan faktorit
  analysis_data <- data %>%
    dplyr::mutate(
      FOF_status = factor(FOF_status, levels = c(0, 1)),
      Sex = factor(Sex)
    )

  # Tarkistetaan, onko Sexillä vähintään 2 tasoa tässä datassa
  sex_has_two_levels <- !is.null(analysis_data$Sex) && nlevels(analysis_data$Sex) >= 2

  if (!sex_has_two_levels) {
    message(
      "Note: Sex has fewer than 2 observed levels in this dataset (nlevels(Sex) = ",
      nlevels(analysis_data$Sex),
      "). Sex will be omitted from the models for this run."
    )
  }

  # Määritellään kovariaattiosa kaavoihin dynaamisesti
  covariate_part <- if (sex_has_two_levels) {
    "Age + Sex + BMI"
  } else {
    "Age + BMI"
  }


  # ------------------------ 4. Discrete moderation (quartiles) -------------------

  ## 4.0 Listwise deletion kvartiilimallille

  vars_quartile <- c("Delta_Composite_Z", "FOF_status", "Composite_Z0", "Age", "Sex", "BMI")

  # data, jossa ei ole puuttuvia arvoja kvartiilimallin kannalta keskeisissä muuttujissa
  dat_quartile <- analysis_data[complete.cases(analysis_data[vars_quartile]), ]

  n0_quartile <- nrow(analysis_data)
  nq <- nrow(dat_quartile)
  prop_removed_q <- (n0_quartile - nq) / n0_quartile

  message(
    "Quartile model: removed ", n0_quartile - nq, " rows (",
    round(100 * prop_removed_q, 1), "%) due to missing data."
  )

  if (prop_removed_q > 0.20) {
    warning("More than 20% of rows removed in quartile model.")
  }

  # 4.1 Create quartiles for Composite_Z0 (suodatetussa datassa)
  dat_quartile <- dat_quartile %>%
    dplyr::mutate(
      Comp_Quartile = cut(
        Composite_Z0,
        breaks = quantile(Composite_Z0, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE),
        include.lowest = TRUE,
        labels = c("Q1_Weakest", "Q2", "Q3", "Q4_Strongest")
      )
    )

  cell_counts <- dat_quartile %>%
    dplyr::count(FOF_status, Comp_Quartile, name = "N")

  message("Cell counts for FOF_status x Comp_Quartile (4 levels):")
  print(cell_counts)

  save_table_csv_html(cell_counts, "discrete_cell_counts_initial")

  # Merge Q3 and Q4 only if any FOF x (Q3/Q4) cell has N < 30 (threshold for sparse cells).
  needs_merge <- any(cell_counts$N < 30 & cell_counts$Comp_Quartile %in% c("Q3", "Q4_Strongest"))
  if (needs_merge) {
    warning("Some FOF x (Q3/Q4) cells have N < 30. Merging Q3 and Q4 into Q3_Q4_Strongest.")
    dat_quartile <- dat_quartile %>%
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
    cell_counts <- dat_quartile %>%
      dplyr::count(FOF_status, Comp_Quartile, name = "N")
    message("Cell counts after merging Q3 and Q4:")
    print(cell_counts)
  }

  save_table_csv_html(cell_counts, "discrete_cell_counts_final")

  # 4.2 ANCOVA model with interaction (building formula dynamically)
  formula_quartile <- as.formula(
    paste("Delta_Composite_Z ~ FOF_status * Comp_Quartile +", covariate_part)
  )

  model_quartile <- stats::lm(
    formula_quartile,
    data = dat_quartile
  )

  message("\nDiscrete moderation model (quartiles) summary:")
  print(summary(model_quartile))

  # Omnibus interaction test via nested model comparison
  model_quartile_no_int <- update(model_quartile, . ~ . - FOF_status:Comp_Quartile)
  omni_test <- anova(model_quartile_no_int, model_quartile)
  message("\nOmnibus test for FOF_status x Comp_Quartile interaction:")
  print(omni_test)

  # 4.3 Robust HC3 standard errors for discrete model (primary reporting)
  # HC3-robust coeftest is treated as the main reference; classical tidy() output is retained as a sensitivity table.
  vc_hc3_quartile <- sandwich::vcovHC(model_quartile, type = "HC3")
  robust_quartile <- lmtest::coeftest(model_quartile, vcov. = vc_hc3_quartile)

  tidy_quartile <- broom::tidy(model_quartile, conf.int = TRUE)
  robust_quartile_df <- data.frame(
    term = rownames(robust_quartile),
    estimate = robust_quartile[, "Estimate"],
    std_error = robust_quartile[, "Std. Error"],
    statistic = robust_quartile[, "t value"],
    p_value = robust_quartile[, "Pr(>|t|)"],
    row.names = NULL
  )

  save_table_csv_html(tidy_quartile, "model_quartile_tidy")
  save_table_csv_html(robust_quartile_df, "model_quartile_robustHC3")

  # 4.4 LS-means and plot
  emm_quart <- emmeans::emmeans(
    model_quartile,
    specs = ~ FOF_status | Comp_Quartile
  )
  emm_quart_df <- as.data.frame(emm_quart)
  save_table_csv_html(emm_quart_df, "discrete_lsmeans")

  if (requireNamespace("multcomp", quietly = TRUE)) {
    cld_quart <- multcomp::cld(emm_quart, Letters = letters)
    cld_quart_df <- as.data.frame(cld_quart)
    save_table_csv_html(cld_quart_df, "discrete_lsmeans_cld")
  }

  p_lsmeans <- ggplot(emm_quart_df, aes(
    x = Comp_Quartile,
    y = emmean,
    color = FOF_status,
    group = FOF_status
  )) +
    geom_point(position = position_dodge(width = 0.2)) +
    geom_errorbar(
      aes(ymin = lower.CL, ymax = upper.CL),
      width = 0.2,
      position = position_dodge(width = 0.2)
    ) +
    labs(
      x = "Baseline composite quartile",
      y = "Adjusted mean Delta_Composite_Z",
      color = "FOF_status",
      title = "Adjusted means of Delta_Composite_Z by FOF_status and Composite_Z0 quartile"
    ) +
    theme_minimal()

  ggplot2::ggsave(
    filename = file.path("outputs", "discrete_lsmeans_plot.png"),
    plot = p_lsmeans,
    width = 7, height = 5, dpi = 300
  )

  # -------------------- 5. Continuous moderation (J N) -------------------------


  ## 5.0 Listwise deletion JN-mallille

  vars_jn <- c("Delta_Composite_Z", "FOF_status", "Composite_Z0", "Age", "Sex", "BMI")

  dat_jn <- analysis_data[complete.cases(analysis_data[vars_jn]), ]

  n0_jn <- nrow(analysis_data)
  nj <- nrow(dat_jn)
  prop_removed_j <- (n0_jn - nj) / n0_jn

  message(
    "JN model: removed ", n0_jn - nj, " rows (",
    round(100 * prop_removed_j, 1), "%) due to missing data."
  )

  if (prop_removed_j > 0.20) {
    warning("More than 20% of rows removed in JN model.")
  }

  # 5.1 Center Composite_Z0 (suodatetussa datassa)
  dat_jn <- dat_jn %>%
    dplyr::mutate(
      cComposite_Z0 = as.numeric(scale(Composite_Z0, center = TRUE, scale = FALSE))
    )

  # 5.2 Model with interaction: FOF_status x cComposite_Z0 (dynamic covariates)
  formula_continuous <- as.formula(
    paste("Delta_Composite_Z ~ FOF_status * cComposite_Z0 +", covariate_part)
  )

  model_continuous <- stats::lm(
    formula_continuous,
    data = dat_jn
  )

  # Backward-compatible alias for earlier naming in outputs (model_jn).
  model_jn <- model_continuous

  message("\nContinuous moderation model (Johnson-Neyman) summary:")
  print(summary(model_jn))

  # 5.3 Robust HC3 for J-N model (primary reporting)
  # HC3-robust coeftest serves as the main inferential reference; classical lm summary and tidy() are kept as sensitivity analyses.
  vc_hc3_jn <- sandwich::vcovHC(model_continuous, type = "HC3")
  robust_jn <- lmtest::coeftest(model_continuous, vcov. = vc_hc3_jn)

  tidy_jn <- broom::tidy(model_continuous, conf.int = TRUE)
  robust_jn_df <- data.frame(
    term = rownames(robust_jn),
    estimate = robust_jn[, "Estimate"],
    std_error = robust_jn[, "Std. Error"],
    statistic = robust_jn[, "t value"],
    p_value = robust_jn[, "Pr(>|t|)"],
    row.names = NULL
  )

  save_table_csv_html(tidy_jn, "model_jn_tidy")
  save_table_csv_html(robust_jn_df, "model_jn_robustHC3")

  # 5.4 Johnson-Neyman regions
  jn_info <- compute_jn_region_binary(
    model_continuous, alpha = 0.05, mod_var = "cComposite_Z0", vcov_mat = vc_hc3_jn
  )

  jn_summary <- if (jn_info$region_type == "partially_significant") {
    data.frame(
      region_type = jn_info$region_type,
      alpha = jn_info$alpha,
      root_1 = jn_info$roots[1],
      root_2 = jn_info$roots[2],
      mod_min = jn_info$mod_min,
      mod_max = jn_info$mod_max
    )
  } else {
    data.frame(
      region_type = jn_info$region_type,
      alpha = jn_info$alpha,
      mod_min = jn_info$mod_min,
      mod_max = jn_info$mod_max
    )
  }

  message("\nJohnson-Neyman region summary:")
  print(jn_summary)


  ## Lyhyt tulkintaviesti konsoliin
  if (jn_info$region_type == "partially_significant") {
    message(
      "FOF_status effect (1 vs 0) on Delta_Composite_Z is statistically significant for cComposite_Z0 in [",
      round(jn_info$roots[1], 3), ", ",
      round(jn_info$roots[2], 2),
      "] and non-significant outside this interval (within the observed moderator range)."
    )
  } else if (jn_info$region_type == "significant_for_all_observed_values") {
    message(
      "FOF_status effect (1 vs 0) on Delta_Composite_Z is statistically significant ",
      "for all observed values of cComposite_Z0."
    )
  } else if (jn_info$region_type == "nonsignificant_for_all_observed_values") {
    message(
      "FOF_status effect (1 vs 0) on Delta_Composite_Z is non-significant ",
      "for all observed values of cComposite_Z0."
    )
  } else {
    message(
      "Unrecognized JN region_type: ", jn_info$region_type,
      ". Please check compute_jn_region_binary()."
    )
  }

  message(
    "Observed range of cComposite_Z0 is [",
    round(jn_info$mod_min, 2), ", ",
    round(jn_info$mod_max, 2), "]."
  )

  save_table_csv_html(jn_summary, "jn_region_summary")


  # 5.5 Slope plot and J-N visualization
  make_jn_slope_plot(
    model_continuous,
    jn_info,
    mod_var = "cComposite_Z0",
    vcov_mat = vc_hc3_jn
  )

  if (requireNamespace("car", quietly = TRUE)) {
    # Quartile-malli
    vif_quart_raw <- car::vif(model_quartile)

    if (is.matrix(vif_quart_raw)) {
      # Faktorit: car::vif palauttaa GVIF-matriisin
      vif_quart <- data.frame(
        term = rownames(vif_quart_raw),
        GVIF = vif_quart_raw[, "GVIF"],
        Df = vif_quart_raw[, "Df"],
        GVIF_adj = vif_quart_raw[, "GVIF^(1/(2*Df))"],
        row.names = NULL
      )
    } else {
      # Pelkät numeriset kovariaatit: tavallinen VIF-vektori
      vif_quart <- data.frame(
        term = names(vif_quart_raw),
        VIF = as.numeric(vif_quart_raw),
        row.names = NULL
      )
    }

    # Jatkuva malli
    vif_cont_raw <- car::vif(model_continuous)

    if (is.matrix(vif_cont_raw)) {
      vif_cont <- data.frame(
        term = rownames(vif_cont_raw),
        GVIF = vif_cont_raw[, "GVIF"],
        Df = vif_cont_raw[, "Df"],
        GVIF_adj = vif_cont_raw[, "GVIF^(1/(2*Df))"],
        row.names = NULL
      )
    } else {
      vif_cont <- data.frame(
        term = names(vif_cont_raw),
        VIF = as.numeric(vif_cont_raw),
        row.names = NULL
      )
    }

    save_table_csv_html(vif_quart, "vif_quartile_model")
    save_table_csv_html(vif_cont, "vif_continuous_model")
  }


  # ------------------------ 5.6: Sample size summary -------------------

  n_summary <- data.frame(
    model       = c("quartile", "continuous JN"),
    n_original  = c(n0_quartile, n0_jn),
    n_used      = c(nq, nj),
    removed     = c(n0_quartile - nq, n0_jn - nj),
    removed_pct = c(100 * prop_removed_q, 100 * prop_removed_j)
  )

  save_table_csv_html(n_summary, "sample_size_summary")


  # --- 6. Yhdistetty päämallitaulukko tälle skriptille ---
  # Käytetään HC3-robusteja tuloksia molemmista malleista

  # Huom: robust_quartile_df on jo laskettu ylempänä (quartile-mallille).
  main_results <- dplyr::bind_rows(
    dplyr::mutate(robust_quartile_df, model = "quartile (FOF x Comp_Quartile + kovariaatit)"),
    dplyr::mutate(robust_jn_df,        model = "continuous JN (FOF x cComposite_Z0 + kovariaatit)")
  )

  main_results_path <- file.path("outputs", paste0(script_label, "_main_results.csv"))
  utils::write.csv(main_results, main_results_path, row.names = FALSE)
  message("Päämallien tulokset tallennettu: ", main_results_path)

  # --- Manifest-rivit tälle skriptille ---
  manifest_rows <- data.frame(
    script      = script_label,
    type        = c("table",                     "table",                     "table",                    "plot",                    "plot"),
    filename    = c(
      paste0(script_label, "_main_results.csv"), # juuri luotu yhteenvetotaulukko
      "model_quartile_robustHC3.csv",            # discretin moderoinnin robustit SE:t (save_table_csv_html teki tämän)
      "model_jn_robustHC3.csv",                  # JN-mallin robustit SE:t
      "discrete_lsmeans_plot.png",               # LS-keskiarvot FOF x kvartiilit
      "jn_slope_plot.png"                        # JN-slope-kuva
    ),
    description = c(
      "Päämallien HC3-robustit kertoimet: quartile- ja JN-mallit yhdessä taulukossa",
      "Quartile-mallin HC3-robustit kertoimet (ANCOVA, FOF x Comp_Quartile)",
      "Jatkuvan JN-mallin HC3-robustit kertoimet (FOF x cComposite_Z0)",
      "LS-keskiarvokuvio Delta_Composite_Z: FOF_status x Composite_Z0-kvartiilit",
      "Johnson–Neyman -slope-kuva: FOF-vaikutus moderaattorin funktiona"
    ),
    stringsAsFactors = FALSE
  )

  # Kirjoita/päivitä manifest.csv
  if (!file.exists(manifest_path)) {
    utils::write.table(
      manifest_rows,
      file      = manifest_path,
      sep       = ",",
      row.names = FALSE,
      col.names = TRUE,
      append    = FALSE,
      qmethod   = "double"
    )
  } else {
    utils::write.table(
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

  # ---------------------- 7. Diagnostics for both models ----------------------

  # Quartile model diagnostics
  plot_resid_fitted(model_quartile, "diagnostics_quartile")
  plot_qq(model_quartile, "diagnostics_quartile")
  plot_leverage(model_quartile, "diagnostics_quartile")
  plot_scale_location(model_quartile, "diagnostics_quartile")
  plot_cooks(model_quartile, "diagnostics_quartile")

  bp_quartile <- lmtest::bptest(model_quartile)
  message("\nBreusch-Pagan test for quartile model:")
  print(bp_quartile)

  # Continuous J-N model diagnostics
  plot_resid_fitted(model_continuous, "diagnostics_jn")
  plot_qq(model_continuous, "diagnostics_jn")
  plot_leverage(model_continuous, "diagnostics_jn")
  plot_scale_location(model_continuous, "diagnostics_jn")
  plot_cooks(model_continuous, "diagnostics_jn")

  bp_jn <- lmtest::bptest(model_continuous)
  message("\nBreusch-Pagan test for J-N model:")
  print(bp_jn)

  # ------------------------- 8. Session info ----------------------------------

  session_info <- sessionInfo()
  capture.output(session_info, file = file.path("outputs", "session_info.txt"))

  message("\nAnalysis completed. Outputs are saved under ./outputs/.")

  # Palautetaan keskeiset objektit interaktiivista käyttöä varten
  invisible(list(
    model_quartile   = model_quartile,
    model_continuous = model_continuous,
    jn_info          = jn_info,
    n_summary        = n_summary
  ))
}

# ------------------------ 9. Run pipeline (non-interactive or interactive) -------------------

if (data_source %in% c("file", "simulated")) {
  pipeline_results <- run_moderation_pipeline(analysis_data)
}
