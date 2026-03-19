#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
  library(here)
  library(lme4)
  library(lmerTest)
})

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths("K50")
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path
script_label <- "K50"

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
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

resolve_data_root <- function() {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(data_root)) {
    env_path <- here::here("config", ".env")
    if (file.exists(env_path)) {
      env_lines <- readLines(env_path, warn = FALSE)
      hit <- grep("^DATA_ROOT\\s*=", env_lines, value = TRUE)
      if (length(hit) > 0) {
        data_root <- sub("^DATA_ROOT\\s*=\\s*", "", hit[[1]])
        data_root <- gsub('^"|"$', "", data_root)
      }
    }
  }
  if (!nzchar(data_root)) {
    stop("DATA_ROOT is required for K50 diagnostics.", call. = FALSE)
  }
  data_root <- normalizePath(data_root, winslash = "/", mustWork = FALSE)
  if (!dir.exists(data_root)) {
    stop(
      sprintf("Resolved DATA_ROOT does not exist: %s", data_root),
      call. = FALSE
    )
  }
  data_root
}

safe_num <- function(x) suppressWarnings(as.numeric(x))

normalize_fof <- function(x) {
  s <- tolower(trimws(as.character(x)))
  num <- suppressWarnings(as.integer(x))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "nonfof", "ei fof", "no fof", "false")] <- 0L
  out[s %in% c("1", "fof", "fear", "yes", "true")] <- 1L
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 1L)
  out[use_num] <- num[use_num]
  factor(out, levels = c(0L, 1L))
}

normalize_time <- function(x) {
  s <- tolower(trimws(as.character(x)))
  num <- suppressWarnings(as.integer(x))
  out <- rep(NA_integer_, length(s))
  out[s %in% c("0", "baseline", "base", "t0")] <- 0L
  out[s %in% c("12", "12m", "m12", "followup", "follow-up", "12_months")] <- 12L
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 12L)
  out[use_num] <- num[use_num]
  out
}

normalize_sex <- function(x) {
  s <- tolower(trimws(as.character(x)))
  num <- suppressWarnings(as.integer(x))
  out <- rep(NA_character_, length(s))
  out[s %in% c("0", "female", "f", "woman", "nainen")] <- "female"
  out[s %in% c("1", "male", "m", "man", "mies")] <- "male"
  use_num <- is.na(out) & !is.na(num) & num %in% c(0L, 1L)
  out[use_num & num == 0L] <- "female"
  out[use_num & num == 1L] <- "male"
  factor(out)
}

write_table <- function(tbl, label, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".csv"))
  readr::write_csv(tbl, out_path, na = "")
  append_manifest_safe(label, "table_csv", out_path, n = nrow(tbl), notes = notes)
  out_path
}

write_text <- function(lines, label, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".txt"))
  writeLines(lines, con = out_path)
  append_manifest_safe(label, "text", out_path, n = length(lines), notes = notes)
  out_path
}

write_png_plot <- function(label, notes, code) {
  out_path <- file.path(outputs_dir, paste0(label, ".png"))
  png(out_path, width = 1400, height = 1000, res = 150)
  tryCatch(
    force(code),
    finally = dev.off()
  )
  append_manifest_safe(label, "figure_png", out_path, notes = notes)
  out_path
}

qq_correlation <- function(x) {
  x <- stats::na.omit(as.numeric(x))
  if (length(x) < 10) return(NA_real_)
  theo <- qnorm(ppoints(length(x)))
  obs <- sort(scale(x)[, 1])
  suppressWarnings(cor(theo, obs))
}

abs_resid_fitted_cor <- function(fitted, resid) {
  ok <- is.finite(fitted) & is.finite(resid)
  if (sum(ok) < 10) return(NA_real_)
  suppressWarnings(cor(fitted[ok], abs(resid[ok]), method = "spearman"))
}

manual_vif <- function(mm) {
  mm <- as.data.frame(mm)
  mm <- mm[, setdiff(names(mm), "(Intercept)"), drop = FALSE]
  if (ncol(mm) == 0) {
    return(tibble(term = character(), vif = numeric()))
  }
  out <- lapply(names(mm), function(term) {
    y <- mm[[term]]
    x <- mm[, setdiff(names(mm), term), drop = FALSE]
    if (ncol(x) == 0) {
      vif <- 1
    } else {
      fit <- stats::lm(y ~ ., data = x)
      r2 <- summary(fit)$r.squared
      vif <- if (is.na(r2) || r2 >= 1) Inf else 1 / (1 - r2)
    }
    tibble(term = term, vif = vif)
  })
  bind_rows(out)
}

classify_vif <- function(vif_tbl) {
  max_vif <- suppressWarnings(max(vif_tbl$vif, na.rm = TRUE))
  if (!is.finite(max_vif) || max_vif >= 10) return("clear concern")
  if (max_vif >= 5) return("mild deviation")
  "no clear concern"
}

classify_qq <- function(x) {
  qc <- qq_correlation(x)
  if (is.na(qc) || qc < 0.97) return(list(level = "clear concern", value = qc))
  if (qc < 0.99) return(list(level = "mild deviation", value = qc))
  list(level = "no clear concern", value = qc)
}

classify_abs_cor <- function(fitted, resid) {
  rho <- abs_resid_fitted_cor(fitted, resid)
  if (is.na(rho) || abs(rho) >= 0.2) return(list(level = "clear concern", value = rho))
  if (abs(rho) >= 0.1) return(list(level = "mild deviation", value = rho))
  list(level = "no clear concern", value = rho)
}

data_root <- resolve_data_root()
wide_path <- file.path(data_root, "paper_02", "analysis", "fof_analysis_k50_wide.rds")
long_path <- file.path(data_root, "paper_02", "analysis", "fof_analysis_k50_long.rds")

wide_df <- readRDS(wide_path) %>%
  transmute(
    id = trimws(as.character(id)),
    FOF_status = normalize_fof(FOF_status),
    age = safe_num(age),
    sex = normalize_sex(sex),
    BMI = safe_num(BMI),
    locomotor_capacity_0 = safe_num(locomotor_capacity_0),
    locomotor_capacity_12m = safe_num(locomotor_capacity_12m)
  ) %>%
  filter(
    !is.na(locomotor_capacity_0),
    !is.na(locomotor_capacity_12m),
    !is.na(FOF_status),
    !is.na(age),
    !is.na(sex),
    !is.na(BMI)
  )

long_df <- readRDS(long_path) %>%
  transmute(
    id = trimws(as.character(id)),
    time = normalize_time(time),
    FOF_status = normalize_fof(FOF_status),
    age = safe_num(age),
    sex = normalize_sex(sex),
    BMI = safe_num(BMI),
    locomotor_capacity = safe_num(locomotor_capacity)
  ) %>%
  filter(
    !is.na(locomotor_capacity),
    !is.na(time),
    !is.na(FOF_status),
    !is.na(age),
    !is.na(sex),
    !is.na(BMI)
  )

wide_model <- stats::lm(
  locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI,
  data = wide_df
)

long_model <- lmerTest::lmer(
  locomotor_capacity ~ time * FOF_status + age + sex + BMI + (1 | id),
  data = long_df,
  REML = FALSE
)

wide_resid <- resid(wide_model)
wide_fitted <- fitted(wide_model)
wide_cooks <- cooks.distance(wide_model)
wide_lev <- hatvalues(wide_model)
wide_vif <- manual_vif(model.matrix(wide_model))

long_resid <- resid(long_model)
long_fitted <- fitted(long_model)
long_vif <- manual_vif(model.matrix(~ time * FOF_status + age + sex + BMI, data = long_df))
long_ranef <- ranef(long_model)$id[, 1]

wide_metrics <- tibble(
  metric = c(
    "n_modeled",
    "qq_correlation",
    "abs_resid_fitted_spearman",
    "max_cooks_distance",
    "max_leverage",
    "mean_leverage"
  ),
  value = c(
    nrow(wide_df),
    qq_correlation(wide_resid),
    abs_resid_fitted_cor(wide_fitted, wide_resid),
    max(wide_cooks, na.rm = TRUE),
    max(wide_lev, na.rm = TRUE),
    mean(wide_lev, na.rm = TRUE)
  )
)

long_metrics <- tibble(
  metric = c(
    "n_modeled",
    "n_ids",
    "qq_correlation",
    "abs_resid_fitted_spearman",
    "random_intercept_qq_correlation"
  ),
  value = c(
    nrow(long_df),
    dplyr::n_distinct(long_df$id),
    qq_correlation(long_resid),
    abs_resid_fitted_cor(long_fitted, long_resid),
    qq_correlation(long_ranef)
  )
)

write_table(wide_metrics, "k50_primary_wide_diagnostics_metrics", "Primary WIDE diagnostics metrics")
write_table(long_metrics, "k50_primary_long_diagnostics_metrics", "Primary LONG diagnostics metrics")
write_table(wide_vif, "k50_primary_wide_vif", "Primary WIDE VIF table")
write_table(long_vif, "k50_primary_long_vif", "Primary LONG VIF table")

write_png_plot("k50_primary_wide_residuals_vs_fitted", "Primary WIDE residuals versus fitted", {
  plot(wide_fitted, wide_resid, pch = 19, col = "#2C5E4F80",
       xlab = "Fitted values", ylab = "Residuals",
       main = "K50 Primary WIDE: Residuals vs Fitted")
  abline(h = 0, lty = 2, col = "firebrick")
  lines(lowess(wide_fitted, wide_resid), col = "navy", lwd = 2)
})

write_png_plot("k50_primary_wide_qq", "Primary WIDE residual QQ plot", {
  qqnorm(wide_resid, pch = 19, col = "#2C5E4F80", main = "K50 Primary WIDE: Residual QQ")
  qqline(wide_resid, col = "firebrick", lwd = 2)
})

write_png_plot("k50_primary_wide_residual_hist", "Primary WIDE residual histogram", {
  hist(wide_resid, breaks = "FD", col = "#2C5E4F", border = "white",
       main = "K50 Primary WIDE: Residual Histogram", xlab = "Residual")
})

write_png_plot("k50_primary_wide_cooks_distance", "Primary WIDE Cook's distance", {
  plot(wide_cooks, type = "h", lwd = 2, col = "#8C2F39",
       main = "K50 Primary WIDE: Cook's Distance", xlab = "Observation", ylab = "Cook's distance")
  abline(h = 4 / nrow(wide_df), lty = 2, col = "navy")
})

write_png_plot("k50_primary_wide_leverage", "Primary WIDE leverage", {
  plot(wide_lev, type = "h", lwd = 2, col = "#8C2F39",
       main = "K50 Primary WIDE: Leverage", xlab = "Observation", ylab = "Hat value")
  abline(h = 2 * length(coef(wide_model)) / nrow(wide_df), lty = 2, col = "navy")
})

write_png_plot("k50_primary_long_residuals_vs_fitted", "Primary LONG residuals versus fitted", {
  plot(long_fitted, long_resid, pch = 19, col = "#1F4E7980",
       xlab = "Fitted values", ylab = "Residuals",
       main = "K50 Primary LONG: Residuals vs Fitted")
  abline(h = 0, lty = 2, col = "firebrick")
  lines(lowess(long_fitted, long_resid), col = "navy", lwd = 2)
})

write_png_plot("k50_primary_long_qq", "Primary LONG residual QQ plot", {
  qqnorm(long_resid, pch = 19, col = "#1F4E7980", main = "K50 Primary LONG: Residual QQ")
  qqline(long_resid, col = "firebrick", lwd = 2)
})

write_png_plot("k50_primary_long_residual_hist", "Primary LONG residual histogram", {
  hist(long_resid, breaks = "FD", col = "#1F4E79", border = "white",
       main = "K50 Primary LONG: Residual Histogram", xlab = "Residual")
})

write_png_plot("k50_primary_long_random_effects_qq", "Primary LONG random intercept QQ plot", {
  qqnorm(long_ranef, pch = 19, col = "#1F4E7980", main = "K50 Primary LONG: Random Intercept QQ")
  qqline(long_ranef, col = "firebrick", lwd = 2)
})

write_png_plot("k50_primary_long_random_effects_hist", "Primary LONG random intercept histogram", {
  hist(long_ranef, breaks = "FD", col = "#1F4E79", border = "white",
       main = "K50 Primary LONG: Random Intercept Histogram", xlab = "Random intercept")
})

wide_norm <- classify_qq(wide_resid)
wide_hetero <- classify_abs_cor(wide_fitted, wide_resid)
wide_influence <- if (max(wide_cooks, na.rm = TRUE) >= 1 || max(wide_lev, na.rm = TRUE) >= 0.2) {
  "clear concern"
} else if (max(wide_cooks, na.rm = TRUE) >= 4 / nrow(wide_df) || max(wide_lev, na.rm = TRUE) >= 2 * length(coef(wide_model)) / nrow(wide_df)) {
  "mild deviation"
} else {
  "no clear concern"
}

long_norm <- classify_qq(long_resid)
long_hetero <- classify_abs_cor(long_fitted, long_resid)
long_re <- classify_qq(long_ranef)

interpretation_lines <- c(
  "K50 primary model diagnostics report",
  "Diagnostics evaluate signs of violation; they do not prove assumptions.",
  paste0("WIDE linearity/homoscedasticity: ", wide_hetero$level, " (|Spearman fitted vs |residual|| = ", sprintf("%.3f", abs(wide_hetero$value)), ")."),
  paste0("WIDE residual normality: ", wide_norm$level, " (QQ correlation = ", sprintf("%.3f", wide_norm$value), ")."),
  paste0("WIDE influence/leverage: ", wide_influence, " (max Cook's distance = ", sprintf("%.3f", max(wide_cooks, na.rm = TRUE)), ", max leverage = ", sprintf("%.3f", max(wide_lev, na.rm = TRUE)), ")."),
  paste0("WIDE multicollinearity: ", classify_vif(wide_vif), " (max VIF = ", sprintf("%.3f", max(wide_vif$vif, na.rm = TRUE)), ")."),
  paste0("LONG linearity/homoscedasticity: ", long_hetero$level, " (|Spearman fitted vs |residual|| = ", sprintf("%.3f", abs(long_hetero$value)), ")."),
  paste0("LONG residual normality: ", long_norm$level, " (QQ correlation = ", sprintf("%.3f", long_norm$value), ")."),
  paste0("LONG multicollinearity: ", classify_vif(long_vif), " (max VIF = ", sprintf("%.3f", max(long_vif$vif, na.rm = TRUE)), ")."),
  paste0("LONG random effects distribution: ", long_re$level, " (random-intercept QQ correlation = ", sprintf("%.3f", long_re$value), ")."),
  "Practical reading: mild deviations are ordinary in epidemiologic regression and mixed models; the diagnostics should be used to flag material concerns rather than to seek perfect assumptions."
)

write_text(interpretation_lines, "k50_primary_model_diagnostics_interpretation", "Primary WIDE/LONG diagnostics interpretation")

session_path <- file.path(outputs_dir, "k50_primary_model_diagnostics_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest_safe("k50_primary_model_diagnostics_sessioninfo", "sessioninfo", session_path, notes = "K50 model diagnostics session info")
