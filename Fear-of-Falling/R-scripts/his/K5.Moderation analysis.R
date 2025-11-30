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
#   Rscript K3.moderaatioanalyysi.R /path/to/your_data.csv
#
# Behavior:
#   - If a valid CSV path is supplied as the first argument, the script reads it.
#   - If no path is supplied or the file does not exist, the script simulates
#     a minimal reproducible example dataset and runs the full pipeline on that.
#
# Outputs (created under ./outputs/):
#   - Tables (CSV + HTML):
#       * discrete_cell_counts.*
#       * discrete_lsmeans.*
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
#       * diagnostics_jn_resid_fitted.png
#       * diagnostics_jn_qq.png
#       * diagnostics_jn_leverage.png
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
#   - Centering improves interpretability of the main effect of FOF_status and
#     reduces multicollinearity between main and interaction terms.
#
# Johnson-Neyman:
#   - The script computes analytic J-N thresholds for the effect of FOF_status
#     across the observed range of cComposite_Z0, using the standard linear
#     model variance-covariance matrix.
#
# Robustness:
#   - HC3 robust standard errors are computed for both discrete and continuous
#     models via sandwich::vcovHC and lmtest::coeftest.
#
# CHANGELOG (major fixes compared to earlier draft notes):
#   - Converted narrative code chunks into a single runnable script.
#   - Standardized to tidyverse style and modular helper functions.
#   - Added dynamic quartile merging (Q3 + Q4) if any FOF x quartile cell has N < 30.
#   - Implemented analytic Johnson-Neyman solution for FOF_status x cComposite_Z0.
#   - Added model diagnostics, HC3 robust sensitivity, and automated export of
#     tables and ggplot figures.
###############################################################################

# ----------------------------- 1. Setup --------------------------------------

set.seed(123)

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
  "haven"
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

# ------------------------ 2. Helper functions --------------------------------

simulate_moderation_data <- function(n = 400L) {
  # Simulate a plausible data set for debugging and illustration.
  set.seed(123)
  Age <- round(rnorm(n, mean = 75, sd = 6))
  Sex <- factor(sample(c("F", "M"), size = n, replace = TRUE, prob = c(0.6, 0.4)))
  BMI <- rnorm(n, mean = 27, sd = 4)
  Composite_Z0 <- rnorm(n, mean = 0, sd = 1)
  FOF_status <- rbinom(n, size = 1, prob = 0.4)
  
  # Moderation structure: effect of FOF varies with Composite_Z0
  # Non-FOF has slightly better improvements at lower Composite_Z0.
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

save_table_csv_html <- function(df, basename) {
  csv_path <- file.path("outputs", paste0(basename, ".csv"))
  html_path <- file.path("outputs", paste0(basename, ".html"))
  
  utils::write.csv(df, csv_path, row.names = FALSE)
  
  html_table <- knitr::kable(df, format = "html", table.attr = "border='1' style='border-collapse:collapse;'")
  html_content <- paste0(
    "<html><head><meta charset='UTF-8'></head><body>",
    "<h3>", basename, "</h3>",
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

compute_jn_region_binary <- function(model, alpha = 0.05, mod_var = "cComposite_Z0") {
  coefs <- coef(model)
  vc <- vcov(model)
  
  # Coefficient for FOF_status level "1" vs reference "0"
  fof_coef_name <- grep("^FOF_status1$", names(coefs), value = TRUE)
  if (length(fof_coef_name) != 1L) {
    stop("Could not find coefficient for FOF_status1 in the model. Check factor coding.", call. = FALSE)
  }
  
  # Interaction term may appear in either order
  int_pattern1 <- paste0("FOF_status1:", mod_var)
  int_pattern2 <- paste0(mod_var, ":FOF_status1")
  int_coef_name <- intersect(
    grep(int_pattern1, names(coefs), value = TRUE),
    c(int_pattern1, int_pattern2)
  )
  if (length(int_coef_name) == 0L) {
    int_coef_name <- grep(int_pattern2, names(coefs), value = TRUE)
  }
  if (length(int_coef_name) != 1L) {
    stop("Could not find interaction coefficient for FOF_status1 x moderator.", call. = FALSE)
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
    region_type <- if (p_val < alpha) "significant_for_all_observed_values" else "nonsignificant_for_all_observed_values"
    
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

make_jn_slope_plot <- function(model, jn_info, mod_var = "cComposite_Z0") {
  coefs <- coef(model)
  vc <- vcov(model)
  
  # Haetaan FOF_status1- ja interaktiotermit
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
    geom_ribbon(aes(ymin = lower, ymax = upper, alpha = significant),
                show.legend = FALSE) +
    geom_line() +
    geom_hline(yintercept = 0, linetype = "dashed") +
    labs(
      x = paste0("Baseline composite z-score (centered: ", mod_var, ")"),
      y = "Effect of FOF_status (1 vs 0) on Delta_Composite_Z",
      title = "Johnson–Neyman slope function for FOF_status"
    ) +
    scale_alpha_manual(values = c(`TRUE` = 0.3, `FALSE` = 0.05)) +
    theme_minimal()
  
  # Piirretään J–N-rajat, jos niitä on
  if (!is.null(jn_info$roots) && length(jn_info$roots) > 0) {
    for (r in jn_info$roots) {
      p <- p + geom_vline(xintercept = r, linetype = "dotted")
    }
  }
  
  ggplot2::ggsave(
    filename = file.path("outputs", "jn_slope_plot.png"),
    plot = p,
    width = 7, height = 5, dpi = 300
  )
}


# --------------------- 3. Load data and sanity checks ------------------------

args <- commandArgs(trailingOnly = TRUE)
is_interactive <- interactive()

if (length(args) > 0 && file.exists(args[1])) {
  # Komentorivikäyttö: Rscript skripti.R data.csv
  data_path <- args[1]
  message("Using data file (command line): ", data_path)
  raw_data <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  data_source <- "file"
  
} else if (is_interactive) {
  # RStudio / interaktiivinen käyttö: luetaan suoraan oma csv
  message("No command line data path supplied. Using interactive data_path.")
  
  data_path <- "C:/Users/tomik/OneDrive/TUTKIMUS/Päijät-Sote/P-Sote/P-Sote/dataset/KaatumisenPelko.csv"
  
  if (!file.exists(data_path)) {
    stop("Data file not found: ", data_path)
  }
  
  message("Using data file (RStudio interactive): ", data_path)
  raw_data <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  data_source <- "file"
  
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
      # BMI on jo nimellä "BMI", joten ei tarvitse uudelleennimetä
    )
  
  message("Column names after mapping:")
  print(names(raw_data))
  
  
} else {
  # Viimeinen varavaihtoehto: simuloitu data (jos ei polkua eikä interaktiota)
  message("No valid data file supplied. Using simulated data.")
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
    sprintf(
      "The following required columns are missing from the data: %s",
      paste(missing_cols, collapse = ", ")
    ),
    call. = FALSE
  )
}

# Check and enforce FOF_status in {0,1}
fof_vals <- sort(unique(raw_data$FOF_status))
if (!all(fof_vals %in% c(0, 1))) {
  stop(
    sprintf(
      "FOF_status must contain only 0 and 1. Observed unique values: %s",
      paste(fof_vals, collapse = ", ")
    ),
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
analysis_data <- analysis_data %>% tidyr::drop_na()
n_after <- nrow(analysis_data)

message("Rows before listwise deletion: ", n_before)
message("Rows after listwise deletion:  ", n_after)

if (n_after < n_before * 0.8) {
  warning("More than 20 percent of rows were removed due to missing data.")
}

# -------------------- 4. Discrete moderation (quartiles) ---------------------

# 4.1 Create quartiles for Composite_Z0
analysis_data <- analysis_data %>%
  dplyr::mutate(
    Comp_Quartile = dplyr::ntile(Composite_Z0, 4L),
    Comp_Quartile = factor(
      Comp_Quartile,
      levels = 1:4,
      labels = c("Q1_Weakest", "Q2", "Q3", "Q4_Strongest")
    )
  )

cell_counts <- analysis_data %>%
  dplyr::count(FOF_status, Comp_Quartile, name = "N")

message("Cell counts for FOF_status x Comp_Quartile (4 levels):")
print(cell_counts)

save_table_csv_html(cell_counts, "discrete_cell_counts_initial")

# Merge Q3 and Q4 if any cell has N < 30
if (any(cell_counts$N < 30)) {
  warning("Some FOF_status x Comp_Quartile cells have N < 30. Merging Q3 and Q4 into Q3_Q4_Strongest.")
  analysis_data <- analysis_data %>%
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
  cell_counts <- analysis_data %>%
    dplyr::count(FOF_status, Comp_Quartile, name = "N")
  message("Cell counts after merging Q3 and Q4:")
  print(cell_counts)
}

save_table_csv_html(cell_counts, "discrete_cell_counts_final")

# 4.2 ANCOVA model with interaction
model_quartile <- stats::lm(
  Delta_Composite_Z ~ FOF_status * Comp_Quartile + Age + Sex + BMI + Composite_Z0,
  data = analysis_data
)

message("\nDiscrete moderation model (quartiles) summary:")
print(summary(model_quartile))

# Omnibus interaction test via nested model comparison
model_quartile_no_int <- update(model_quartile, . ~ . - FOF_status:Comp_Quartile)
omni_test <- anova(model_quartile_no_int, model_quartile)
message("\nOmnibus test for FOF_status x Comp_Quartile interaction:")
print(omni_test)

# 4.3 Robust HC3 standard errors for discrete model
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

# Optional compact letter display if multcomp is available
if (requireNamespace("multcomp", quietly = TRUE)) {
  # Käytetään multcomp::cld emmeans-objektille
  cld_quart <- multcomp::cld(emm_quart, Letters = letters)
  cld_quart_df <- as.data.frame(cld_quart)
  save_table_csv_html(cld_quart_df, "discrete_lsmeans_cld")
}

# LS-means plot
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

# -------------------- 5. Continuous moderation (J-N) -------------------------

# 5.1 Center Composite_Z0
analysis_data <- analysis_data %>%
  dplyr::mutate(
    cComposite_Z0 = as.numeric(scale(Composite_Z0, center = TRUE, scale = FALSE))
  )

# 5.2 Model with interaction: FOF_status x cComposite_Z0
model_jn <- stats::lm(
  Delta_Composite_Z ~ FOF_status * cComposite_Z0 + Age + Sex + BMI,
  data = analysis_data
)

message("\nContinuous moderation model (Johnson-Neyman) summary:")
print(summary(model_jn))

# 5.3 Robust HC3 for J-N model
vc_hc3_jn <- sandwich::vcovHC(model_jn, type = "HC3")
robust_jn <- lmtest::coeftest(model_jn, vcov. = vc_hc3_jn)

tidy_jn <- broom::tidy(model_jn, conf.int = TRUE)
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
jn_info <- compute_jn_region_binary(model_jn, alpha = 0.05, mod_var = "cComposite_Z0")

jn_summary <- if (jn_info$region_type == "partially_significant") {
  data.frame(
    region_type = jn_info$region_type,
    alpha = jn_info$alpha,
    root1 = jn_info$roots[1],
    root2 = jn_info$roots[2],
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

save_table_csv_html(jn_summary, "jn_region_summary")

# 5.5 Slope plot and J-N visualization
make_jn_slope_plot(model_jn, jn_info, mod_var = "cComposite_Z0")

# ---------------------- 6. Diagnostics for both models ----------------------

# Quartile model diagnostics
plot_resid_fitted(model_quartile, "diagnostics_quartile")
plot_qq(model_quartile, "diagnostics_quartile")
plot_leverage(model_quartile, "diagnostics_quartile")

bp_quartile <- lmtest::bptest(model_quartile)
message("\nBreusch-Pagan test for quartile model:")
print(bp_quartile)

# J-N model diagnostics
plot_resid_fitted(model_jn, "diagnostics_jn")
plot_qq(model_jn, "diagnostics_jn")
plot_leverage(model_jn, "diagnostics_jn")

bp_jn <- lmtest::bptest(model_jn)
message("\nBreusch-Pagan test for J-N model:")
print(bp_jn)

# ------------------------- 7. Session info ----------------------------------

session_info <- sessionInfo()
capture.output(session_info, file = file.path("outputs", "session_info.txt"))

message("\nAnalysis completed. Outputs are saved under ./outputs/.")
