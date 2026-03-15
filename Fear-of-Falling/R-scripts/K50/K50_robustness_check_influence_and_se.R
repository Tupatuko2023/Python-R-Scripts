#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(boot)
})

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
outputs_dir <- file.path(project_root, "R-scripts", "K50", "outputs")
manifest_path <- file.path(project_root, "manifest", "manifest.csv")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)

resolve_data_root <- function() {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(data_root)) {
    env_path <- file.path(project_root, "config", ".env")
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
    stop("DATA_ROOT is required for K50 robustness checks.", call. = FALSE)
  }
  normalizePath(data_root, winslash = "/", mustWork = FALSE)
}

manifest_row <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  data.frame(
    timestamp = as.character(Sys.time()),
    script = "K50",
    label = label,
    kind = kind,
    path = path,
    n = as.character(n),
    notes = notes,
    stringsAsFactors = FALSE
  )
}

append_manifest_safe <- function(label, kind, path, n = NA_integer_, notes = NA_character_) {
  row <- manifest_row(label, kind, path, n = n, notes = notes)
  if (!file.exists(manifest_path)) {
    utils::write.table(row, manifest_path, sep = ",", row.names = FALSE, col.names = TRUE, quote = TRUE)
  } else {
    old <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, check.names = FALSE)
    out <- rbind(old, row)
    utils::write.table(out, manifest_path, sep = ",", row.names = FALSE, col.names = TRUE, quote = TRUE)
  }
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

write_table <- function(df, label, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".csv"))
  utils::write.csv(df, out_path, row.names = FALSE, na = "")
  append_manifest_safe(label, "table_csv", file.path("R-scripts", "K50", "outputs", paste0(label, ".csv")), n = nrow(df), notes = notes)
  out_path
}

write_text <- function(lines, label, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".txt"))
  writeLines(lines, con = out_path)
  append_manifest_safe(label, "text", file.path("R-scripts", "K50", "outputs", paste0(label, ".txt")), n = length(lines), notes = notes)
  out_path
}

term_summary <- function(model, term, model_label) {
  coef_tbl <- summary(model)$coefficients
  idx <- match(term, rownames(coef_tbl))
  if (is.na(idx)) {
    stop("Missing term in model: ", term, call. = FALSE)
  }
  est <- unname(coef_tbl[idx, "Estimate"])
  se <- unname(coef_tbl[idx, "Std. Error"])
  stat_name <- if ("t value" %in% colnames(coef_tbl)) "t value" else colnames(coef_tbl)[3]
  p_name <- if ("Pr(>|t|)" %in% colnames(coef_tbl)) "Pr(>|t|)" else colnames(coef_tbl)[4]
  data.frame(
    model = model_label,
    term = term,
    estimate = est,
    std_error = se,
    statistic = unname(coef_tbl[idx, stat_name]),
    p_value = unname(coef_tbl[idx, p_name]),
    conf_low = est - qt(0.975, df = stats::df.residual(model)) * se,
    conf_high = est + qt(0.975, df = stats::df.residual(model)) * se,
    n_modeled = stats::nobs(model),
    stringsAsFactors = FALSE
  )
}

bootstrap_stat <- function(data, indices) {
  sample_df <- data[indices, , drop = FALSE]
  fit <- stats::lm(
    locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI,
    data = sample_df
  )
  unname(coef(fit)[["FOF_status1"]])
}

data_root <- resolve_data_root()
wide_path <- file.path(data_root, "paper_01", "analysis", "fof_analysis_k50_wide.rds")
wide_raw <- readRDS(wide_path)

wide_df <- data.frame(
  id = trimws(as.character(wide_raw$id)),
  FOF_status = normalize_fof(wide_raw$FOF_status),
  age = safe_num(wide_raw$age),
  sex = normalize_sex(wide_raw$sex),
  BMI = safe_num(wide_raw$BMI),
  locomotor_capacity_0 = safe_num(wide_raw$locomotor_capacity_0),
  locomotor_capacity_12m = safe_num(wide_raw$locomotor_capacity_12m),
  stringsAsFactors = FALSE
)

keep <- stats::complete.cases(wide_df[, c(
  "FOF_status",
  "age",
  "sex",
  "BMI",
  "locomotor_capacity_0",
  "locomotor_capacity_12m"
)])
wide_df <- wide_df[keep, , drop = FALSE]
wide_df$FOF_status <- factor(wide_df$FOF_status, levels = c(0L, 1L))
wide_df$sex <- factor(wide_df$sex)

primary_wide <- stats::lm(
  locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI,
  data = wide_df
)

wide_cooks <- cooks.distance(primary_wide)
wide_lev <- hatvalues(primary_wide)
max_idx <- which.max(wide_cooks)
if (length(max_idx) != 1 || !is.finite(max_idx)) {
  stop("Failed to identify a single influential observation.", call. = FALSE)
}

trimmed_df <- wide_df[-max_idx, , drop = FALSE]
trimmed_wide <- stats::lm(
  locomotor_capacity_12m ~ locomotor_capacity_0 + FOF_status + age + sex + BMI,
  data = trimmed_df
)

set.seed(20260314)
boot_res <- boot::boot(wide_df, bootstrap_stat, R = 2000)
boot_ci <- boot::boot.ci(boot_res, type = c("perc", "norm"))
if (is.null(boot_ci$percent) || is.null(boot_ci$normal)) {
  stop("Bootstrap CI calculation failed.", call. = FALSE)
}

primary_terms <- term_summary(primary_wide, "FOF_status1", "primary_wide")
trimmed_terms <- term_summary(trimmed_wide, "FOF_status1", "wide_without_max_cooks")

influence_tbl <- data.frame(
  removed_rank = 1L,
  removed_row_index = max_idx,
  id = wide_df$id[[max_idx]],
  cooks_distance = unname(wide_cooks[[max_idx]]),
  leverage = unname(wide_lev[[max_idx]]),
  cooks_cutoff_4_over_n = 4 / nrow(wide_df),
  leverage_cutoff_2p_over_n = 2 * length(coef(primary_wide)) / nrow(wide_df),
  stringsAsFactors = FALSE
)

comparison_tbl <- rbind(primary_terms, trimmed_terms)
comparison_tbl$estimate_delta_vs_primary <- comparison_tbl$estimate - primary_terms$estimate[[1]]
comparison_tbl$abs_estimate_delta_vs_primary <- abs(comparison_tbl$estimate_delta_vs_primary)
comparison_tbl$p_delta_vs_primary <- comparison_tbl$p_value - primary_terms$p_value[[1]]

bootstrap_tbl <- data.frame(
  model = "primary_wide_bootstrap",
  term = "FOF_status1",
  estimate = primary_terms$estimate[[1]],
  bootstrap_mean = mean(boot_res$t[, 1], na.rm = TRUE),
  bootstrap_sd = stats::sd(boot_res$t[, 1], na.rm = TRUE),
  bootstrap_ci_low_perc = boot_ci$percent[4],
  bootstrap_ci_high_perc = boot_ci$percent[5],
  bootstrap_ci_low_norm = boot_ci$normal[2],
  bootstrap_ci_high_norm = boot_ci$normal[3],
  n_boot = nrow(boot_res$t),
  n_modeled = nrow(wide_df),
  stringsAsFactors = FALSE
)

trimmed_row <- comparison_tbl[comparison_tbl$model == "wide_without_max_cooks", , drop = FALSE]
substantive_change <- abs(trimmed_row$estimate_delta_vs_primary[[1]]) >= 0.10 ||
  xor(trimmed_row$p_value[[1]] < 0.05, primary_terms$p_value[[1]] < 0.05)

bootstrap_null_changed <- !(bootstrap_tbl$bootstrap_ci_low_perc[[1]] <= 0 &&
  bootstrap_tbl$bootstrap_ci_high_perc[[1]] >= 0)

note_lines <- c(
  "K50 primary WIDE robustness confirmation",
  "",
  paste0(
    "Primary WIDE FOF_status1: estimate=",
    sprintf("%.3f", primary_terms$estimate[[1]]),
    ", p=", sprintf("%.3f", primary_terms$p_value[[1]]),
    ", n=", primary_terms$n_modeled[[1]], "."
  ),
  paste0(
    "After removing the max-Cook observation (id=",
    influence_tbl$id[[1]],
    ", Cook's distance=", sprintf("%.3f", influence_tbl$cooks_distance[[1]]),
    "), FOF_status1 estimate=",
    sprintf("%.3f", trimmed_terms$estimate[[1]]),
    ", p=", sprintf("%.3f", trimmed_terms$p_value[[1]]),
    ", n=", trimmed_terms$n_modeled[[1]], "."
  ),
  paste0(
    "Bootstrap percentile CI for the primary WIDE FOF_status1 coefficient: ",
    sprintf("%.3f", bootstrap_tbl$bootstrap_ci_low_perc[[1]]),
    " to ",
    sprintf("%.3f", bootstrap_tbl$bootstrap_ci_high_perc[[1]]),
    " (",
    bootstrap_tbl$n_boot[[1]],
    " resamples)."
  ),
  if (isTRUE(substantive_change)) {
    "Influence-removal sensitivity indicates a material change relative to the locked primary inference."
  } else {
    "Influence-removal sensitivity does not materially change the locked primary inference."
  },
  if (isTRUE(bootstrap_null_changed)) {
    "Bootstrap CI suggests a different null conclusion than the model-based primary output."
  } else {
    "Bootstrap CI remains consistent with the primary null conclusion."
  },
  "Interpretation: the narrow robustness check does not reopen outcome architecture, formulas, or K50 implementation. Missingness remains the main substantive caveat."
)

write_table(influence_tbl, "k50_primary_wide_robustness_influential_observation", "Primary WIDE influential observation removed for robustness check")
write_table(comparison_tbl, "k50_primary_wide_robustness_comparison", "Primary vs influence-removed WIDE robustness comparison")
write_table(bootstrap_tbl, "k50_primary_wide_robustness_bootstrap", "Primary WIDE bootstrap robustness summary")
write_text(note_lines, "k50_primary_wide_robustness_note", "Primary WIDE robustness interpretation")

session_path <- file.path(outputs_dir, "k50_primary_wide_robustness_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest_safe(
  "k50_primary_wide_robustness_sessioninfo",
  "sessioninfo",
  file.path("R-scripts", "K50", "outputs", "k50_primary_wide_robustness_sessioninfo.txt"),
  notes = "K50 primary WIDE robustness session info"
)
