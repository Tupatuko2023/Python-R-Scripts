suppressPackageStartupMessages({
  library(here)
  library(ggplot2)
})

source(here::here("R", "functions", "init.R"))

paths <- init_paths("K21")
outputs_dir <- file.path(paths$outputs_dir, "compare_frailty_proxies_delta")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
manifest_path <- paths$manifest_path

csv_path <- file.path(outputs_dir, "compare_frailty_proxies_delta_composite_z.csv")
md_path <- file.path(outputs_dir, "compare_frailty_proxies_delta_composite_z.md")
fig_path <- file.path(outputs_dir, "compare_frailty_proxies_delta_forest.png")

rdata_candidates <- c(
  here::here("R-scripts", "K15", "outputs", "K15.3._frailty_analysis_data.RData"),
  here::here("R-scripts", "K15", "outputs", "K15_frailty_analysis_data.RData")
)
rdata_path <- rdata_candidates[file.exists(rdata_candidates)][1]
if (is.na(rdata_path)) {
  stop("K15-derived analysis RData missing")
}

load(rdata_path)
if (!exists("analysis_data")) {
  stop("analysis_data object missing in loaded RData")
}

d <- analysis_data
notes <- character(0)

# Outcome mapping aligned with K15.3 logic.
if (!"Composite_Z0" %in% names(d) && "ToimintaKykySummary0" %in% names(d)) {
  d$Composite_Z0 <- d$ToimintaKykySummary0
  notes <- c(notes, "Composite_Z0 mapped from ToimintaKykySummary0")
}
if (!"Composite_Z3" %in% names(d)) {
  if ("ToimintaKykySummary2" %in% names(d)) {
    d$Composite_Z3 <- d$ToimintaKykySummary2
    notes <- c(notes, "Composite_Z3 mapped from ToimintaKykySummary2")
  } else if ("Composite_Z2" %in% names(d)) {
    d$Composite_Z3 <- d$Composite_Z2
    notes <- c(notes, "Composite_Z3 mapped from Composite_Z2")
  }
}

if (!all(c("Composite_Z0", "Composite_Z3") %in% names(d))) {
  stop("Cannot construct delta_composite_z: missing Composite_Z0/Composite_Z3")
}

d$delta_composite_z <- d$Composite_Z3 - d$Composite_Z0

required <- c(
  "delta_composite_z",
  "frailty_cat_3",
  "frailty_cat_3_balance",
  "FOF_status",
  "age",
  "sex",
  "BMI"
)
missing_cols <- setdiff(required, names(d))
if (length(missing_cols) > 0) {
  stop(paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
}

normalize_frailty <- function(x) {
  x_chr <- tolower(trimws(as.character(x)))
  x_chr[x_chr %in% c("prefrail", "pre frail", "pre_frail", "pre-frail")] <- "pre-frail"
  x_chr[x_chr %in% c("robust")] <- "robust"
  x_chr[x_chr %in% c("frail")] <- "frail"
  factor(x_chr, levels = c("robust", "pre-frail", "frail"))
}

d$frailty_cat_3 <- normalize_frailty(d$frailty_cat_3)
d$frailty_cat_3_balance <- normalize_frailty(d$frailty_cat_3_balance)

if (is.numeric(d$FOF_status) || is.integer(d$FOF_status)) {
  d$FOF_status <- factor(ifelse(d$FOF_status == 1, "FOF", "nonFOF"), levels = c("nonFOF", "FOF"))
} else {
  d$FOF_status <- factor(d$FOF_status)
}

if (is.numeric(d$sex) || is.integer(d$sex)) {
  d$sex <- factor(ifelse(d$sex == 1, "male", "female"), levels = c("female", "male"))
} else {
  d$sex <- factor(d$sex)
}

na_balance <- sum(is.na(d$frailty_cat_3_balance))
na_balance_pct <- 100 * na_balance / nrow(d)

common_df <- d[complete.cases(d[, required]), required]
n_common <- nrow(common_df)

fit_A <- lm(delta_composite_z ~ frailty_cat_3 + FOF_status + age + sex + BMI, data = common_df)
fit_B <- lm(delta_composite_z ~ frailty_cat_3_balance + FOF_status + age + sex + BMI, data = common_df)

extract_frailty_terms <- function(fit, frailty_prefix, model_label, n_obs) {
  sm <- summary(fit)$coefficients
  ci <- suppressMessages(confint(fit))
  terms <- rownames(sm)
  keep <- grepl(paste0("^", frailty_prefix), terms)
  if (!any(keep)) return(data.frame())
  data.frame(
    section = "coefficients",
    model = model_label,
    term = terms[keep],
    estimate = sm[keep, "Estimate"],
    conf.low = ci[terms[keep], 1],
    conf.high = ci[terms[keep], 2],
    p.value = sm[keep, "Pr(>|t|)"],
    statistic = sm[keep, "t value"],
    df = fit$df.residual,
    n = n_obs,
    note = "reference level = robust",
    row.names = NULL
  )
}

metrics <- data.frame(
  section = "model_metrics",
  model = c("A_frailty_cat_3", "B_frailty_cat_3_balance"),
  term = c("AIC", "AIC"),
  estimate = c(AIC(fit_A), AIC(fit_B)),
  conf.low = NA_real_,
  conf.high = NA_real_,
  p.value = NA_real_,
  statistic = NA_real_,
  df = NA_real_,
  n = n_common,
  note = c("smaller is better", "smaller is better"),
  row.names = NULL
)
metrics <- rbind(
  metrics,
  data.frame(
    section = "model_metrics",
    model = c("A_frailty_cat_3", "B_frailty_cat_3_balance"),
    term = c("adjR2", "adjR2"),
    estimate = c(summary(fit_A)$adj.r.squared, summary(fit_B)$adj.r.squared),
    conf.low = NA_real_, conf.high = NA_real_, p.value = NA_real_,
    statistic = NA_real_, df = NA_real_, n = n_common,
    note = c("larger is better", "larger is better"),
    row.names = NULL
  ),
  data.frame(
    section = "qc",
    model = c("common_sample", "balance_missingness"),
    term = c("N_common", "frailty_cat_3_balance_NA_pct"),
    estimate = c(n_common, na_balance_pct),
    conf.low = NA_real_, conf.high = NA_real_, p.value = NA_real_,
    statistic = c(na_balance, NA_real_), df = NA_real_, n = nrow(d),
    note = c("same N used for A and B", "percent missing in full analysis_data"),
    row.names = NULL
  ),
  data.frame(
    section = "comparison",
    model = "A_vs_B_non_nested",
    term = c("AIC_diff_B_minus_A", "adjR2_diff_B_minus_A"),
    estimate = c(AIC(fit_B) - AIC(fit_A), summary(fit_B)$adj.r.squared - summary(fit_A)$adj.r.squared),
    conf.low = NA_real_, conf.high = NA_real_, p.value = NA_real_,
    statistic = NA_real_, df = NA_real_, n = n_common,
    note = c("negative favors B", "positive favors B"),
    row.names = NULL
  )
)

coefs <- rbind(
  extract_frailty_terms(fit_A, "frailty_cat_3", "A_frailty_cat_3", n_common),
  extract_frailty_terms(fit_B, "frailty_cat_3_balance", "B_frailty_cat_3_balance", n_common)
)

out <- rbind(metrics, coefs)

if (length(notes) > 0) {
  out <- rbind(
    out,
    data.frame(
      section = "notes",
      model = "derivation",
      term = "mapping",
      estimate = NA_real_, conf.low = NA_real_, conf.high = NA_real_,
      p.value = NA_real_, statistic = NA_real_, df = NA_real_, n = n_common,
      note = paste(notes, collapse = " | "),
      row.names = NULL
    )
  )
}

write.csv(out, csv_path, row.names = FALSE, na = "")

# Single-panel forest plot: frail vs robust contrast in model A vs B.
plot_df <- out[
  out$section == "coefficients" &
    out$term %in% c("frailty_cat_3frail", "frailty_cat_3_balancefrail"),
  c("model", "estimate", "conf.low", "conf.high")
]

if (nrow(plot_df) == 2) {
  plot_df$model <- factor(
    plot_df$model,
    levels = c("A_frailty_cat_3", "B_frailty_cat_3_balance"),
    labels = c("Model A: frailty_cat_3", "Model B: frailty_cat_3_balance")
  )

  p <- ggplot(plot_df, aes(x = estimate, y = model)) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.15, orientation = "y") +
    geom_point(size = 2) +
    labs(
      title = "Frail vs Robust Effect on delta_composite_z",
      subtitle = "Comparison of traditional vs balance-extended frailty proxy",
      x = "Estimate (95% CI)",
      y = NULL
    ) +
    theme_minimal(base_size = 11)

  ggsave(
    filename = fig_path,
    plot = p,
    width = 7,
    height = 4.5,
    dpi = 300
  )
}

# Table-to-text crosscheck by reading back CSV values.
z <- read.csv(csv_path, stringsAsFactors = FALSE)

mA <- subset(z, section == "model_metrics" & model == "A_frailty_cat_3" & term == "AIC")
mB <- subset(z, section == "model_metrics" & model == "B_frailty_cat_3_balance" & term == "AIC")
rA <- subset(z, section == "model_metrics" & model == "A_frailty_cat_3" & term == "adjR2")
rB <- subset(z, section == "model_metrics" & model == "B_frailty_cat_3_balance" & term == "adjR2")
qN <- subset(z, section == "qc" & model == "common_sample")
qNA <- subset(z, section == "qc" & model == "balance_missingness")
ca <- subset(z, section == "coefficients" & model == "A_frailty_cat_3")
cb <- subset(z, section == "coefficients" & model == "B_frailty_cat_3_balance")

aic_better <- if (mB$estimate < mA$estimate) "B" else "A"
r2_better <- if (rB$estimate > rA$estimate) "B" else "A"

fmt <- function(x, d = 4) format(round(as.numeric(x), d), nsmall = d)

md <- c(
  "# Compare frailty proxies on delta_composite_z",
  "",
  paste0("Data source: `", gsub("^.*Fear-of-Falling/", "", rdata_path), "`"),
  paste0("Common-sample N used in both models: ", qN$estimate),
  paste0("frailty_cat_3_balance missing in full analysis_data: ", fmt(qNA$estimate, 2), "%"),
  "",
  "## Models",
  "A: `delta_composite_z ~ frailty_cat_3 + FOF_status + age + sex + BMI`",
  "B: `delta_composite_z ~ frailty_cat_3_balance + FOF_status + age + sex + BMI`",
  "",
  "## Fit metrics (same N)",
  paste0("AIC: A=", fmt(mA$estimate), ", B=", fmt(mB$estimate), " (lower better; winner=", aic_better, ")"),
  paste0("adjR2: A=", fmt(rA$estimate), ", B=", fmt(rB$estimate), " (higher better; winner=", r2_better, ")"),
  "",
  "## Frailty coefficients (reference=robust)",
  "Model A terms:",
  paste0("- ", ca$term, ": est=", fmt(ca$estimate), ", 95% CI [", fmt(ca$conf.low), ", ", fmt(ca$conf.high), "], p=", fmt(ca$p.value)),
  "Model B terms:",
  paste0("- ", cb$term, ": est=", fmt(cb$estimate), ", 95% CI [", fmt(cb$conf.low), ", ", fmt(cb$conf.high), "], p=", fmt(cb$p.value)),
  "",
  "## Method note",
  "A vs B are non-nested (different frailty predictors), so no nested anova test is used.",
  "",
  "## Table-to-text crosscheck",
  "All values above are read back from the generated CSV."
)

writeLines(md, md_path)

append_manifest(
  manifest_row(
    script = "K21",
    label = "compare_frailty_proxies_delta_composite_z",
    path = get_relpath(csv_path),
    kind = "table_csv",
    n = nrow(out),
    notes = "Model A vs B on delta_composite_z using common-sample and non-nested fit metrics"
  ),
  manifest_path
)

append_manifest(
  manifest_row(
    script = "K21",
    label = "compare_frailty_proxies_delta_composite_z",
    path = get_relpath(md_path),
    kind = "doc_md",
    n = NA_integer_,
    notes = "Narrative summary crosschecked against CSV"
  ),
  manifest_path
)

if (file.exists(fig_path)) {
  append_manifest(
    manifest_row(
      script = "K21",
      label = "compare_frailty_proxies_delta_forest",
      path = get_relpath(fig_path),
      kind = "plot_png",
      n = n_common,
      notes = "Single-panel forest plot: frail vs robust estimate (A vs B)"
    ),
    manifest_path
  )
}

message("K21 complete: ", csv_path)
message("K21 complete: ", md_path)
message("K21 complete: ", fig_path)
