#!/usr/bin/env Rscript
# ==============================================================================
# K50 - Contrast-Focused Figure 2 From Saved Primary LONG Model
# File tag: K50.V3_make-fig2-contrast-focused.R
# Purpose: Build manuscript-facing Figure 2 variants from the saved K50 primary
#          LONG mixed model, adding explicit model-based adjusted contrasts.
#
# Outcome: locomotor_capacity
# Predictors: FOF_status, time
# Moderator/interaction: time * FOF_status
# Grouping variable: id
# Covariates: age, sex, BMI
#
# Required vars (DO NOT INVENT; must match req_cols check in code):
# id, time, FOF_status, age, sex, BMI, locomotor_capacity
#
# Mapping example (optional; raw -> analysis; keep minimal + explicit):
# saved merMod model.frame -> emmeans grid -> Panel A means + Panel B contrasts
#
# Reproducibility:
# - renv restore/snapshot REQUIRED
# - seed: 20251124 (not used; no randomness)
#
# Outputs + manifest:
# - script_label: K50 (canonical)
# - outputs dir: R-scripts/K50/outputs/  (resolved via init_paths(script_label))
# - manifest: append 1 row per artifact to manifest/manifest.csv
#
# Workflow (tick off; do not skip):
# 01) Init paths + options + dirs (init_paths)
# 02) Load saved exact primary LONG model object
# 03) Validate model class and model-frame variables
# 04) Compute adjusted means and direct contrasts with emmeans
# 05) Build Panel A and Panel B plotting tables
# 06) Save publication-facing figures and CSV tables
# 07) Save technical note, caption, and results text proposal
# 08) Append manifest row per artifact
# 09) Save sessionInfo artifact
# 10) EOF marker
# ==============================================================================
#
suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(emmeans)
  library(here)
  library(grid)
})

# --- Standard init (MANDATORY) -----------------------------------------------
args_all <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args_all, value = TRUE)

script_base <- if (length(file_arg) > 0) {
  sub("\\.[Rr]$", "", basename(sub("^--file=", "", file_arg[1])))
} else {
  "K50"
}
script_label <- sub("\\.V.*$", "", script_base)
if (is.na(script_label) || script_label == "") script_label <- "K50"

source(here::here("R", "functions", "reporting.R"))
paths <- init_paths(script_label)
outputs_dir <- paths$outputs_dir
manifest_path <- paths$manifest_path
artifact_dir <- file.path(outputs_dir, "FIG2_contrast_focused")
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

req_cols <- c("id", "time", "FOF_status", "age", "sex", "BMI", "locomotor_capacity")

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

save_text_artifact <- function(path, lines, label, notes) {
  writeLines(lines, con = path)
  append_manifest_safe(
    label = label,
    kind = "text",
    path = path,
    notes = notes
  )
}

save_plot_combo <- function(path, plot_top, plot_bottom, width, height, compact = FALSE) {
  if (grepl("\\.png$", path, ignore.case = TRUE)) {
    grDevices::png(filename = path, width = width, height = height, units = "in", res = 300)
  } else if (grepl("\\.pdf$", path, ignore.case = TRUE)) {
    grDevices::pdf(file = path, width = width, height = height, useDingbats = FALSE)
  } else {
    stop("Unsupported output device for path: ", path, call. = FALSE)
  }

  grid::grid.newpage()
  layout <- if (isTRUE(compact)) {
    grid::grid.layout(nrow = 2, ncol = 1, heights = unit(c(0.9, 2.1), "null"))
  } else {
    grid::grid.layout(nrow = 1, ncol = 2, widths = unit(c(1.25, 1), "null"))
  }

  grid::pushViewport(grid::viewport(layout = layout))
  if (isTRUE(compact)) {
    print(plot_top, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
    print(plot_bottom, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 1))
  } else {
    print(plot_top, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
    print(plot_bottom, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
  }
  grDevices::dev.off()
}

model_path <- Sys.getenv(
  "K50_PRIMARY_MODEL_RDS",
  unset = file.path(outputs_dir, "k50_long_locomotor_capacity_model_primary.rds")
)

if (!file.exists(model_path)) {
  stop(
    paste0(
      "Exact K50 primary model object is missing. Expected: ",
      model_path,
      ". Run R-scripts/K50/K50.r with --shape LONG --outcome locomotor_capacity first."
    ),
    call. = FALSE
  )
}

fit <- readRDS(model_path)
if (!inherits(fit, "merMod")) {
  stop("Loaded K50 primary model object is not a merMod fit.", call. = FALSE)
}

model_df <- stats::model.frame(fit)
missing_cols <- setdiff(req_cols, names(model_df))
if (length(missing_cols) > 0) {
  stop(
    "Saved K50 model frame is missing required variables: ",
    paste(missing_cols, collapse = ", "),
    call. = FALSE
  )
}

key_missing_n <- sum(!stats::complete.cases(model_df[, req_cols]))
if (key_missing_n > 0) {
  stop(
    "Saved K50 model frame contains missing values in key variables: ",
    key_missing_n,
    call. = FALSE
  )
}

fof_levels <- sort(unique(as.character(stats::na.omit(model_df$FOF_status))))
if (!identical(fof_levels, c("0", "1"))) {
  stop("Saved K50 model frame must use FOF_status levels 0 and 1.", call. = FALSE)
}

time_values <- sort(unique(as.numeric(as.character(stats::na.omit(model_df$time)))))
if (!identical(time_values, c(0, 12))) {
  stop("Saved K50 model frame must use numeric time values 0 and 12.", call. = FALSE)
}

age_mean <- mean(model_df$age, na.rm = TRUE)
bmi_mean <- mean(model_df$BMI, na.rm = TRUE)

emm <- emmeans::emmeans(
  fit,
  specs = ~ FOF_status * time,
  at = list(
    time = c(0, 12),
    age = age_mean,
    BMI = bmi_mean
  ),
  weights = "proportional"
)

panel_a <- as.data.frame(summary(emm, infer = c(TRUE, TRUE))) %>%
  rename(
    estimate = emmean,
    std.error = SE,
    conf.low = lower.CL,
    conf.high = upper.CL
  ) %>%
  mutate(
    term = case_when(
      as.character(FOF_status) == "0" & as.numeric(as.character(time)) == 0 ~ "No FOF baseline",
      as.character(FOF_status) == "0" & as.numeric(as.character(time)) == 12 ~ "No FOF 12 months",
      as.character(FOF_status) == "1" & as.numeric(as.character(time)) == 0 ~ "FOF baseline",
      TRUE ~ "FOF 12 months"
    ),
    time = as.numeric(as.character(time)),
    FOF_status = as.character(FOF_status),
    time_label = if_else(time == 0, "Baseline", "12 months"),
    FOF_label = if_else(FOF_status == "0", "No FOF", "FOF")
  ) %>%
  select(term, FOF_status, FOF_label, time, time_label, estimate, std.error, df, conf.low, conf.high) %>%
  arrange(match(FOF_label, c("No FOF", "FOF")), time)

if (nrow(panel_a) != 4) {
  stop("Panel A emmeans table must contain exactly four rows.", call. = FALSE)
}

emm_by_time <- emmeans::emmeans(
  fit,
  specs = ~ FOF_status | time,
  at = list(
    time = c(0, 12),
    age = age_mean,
    BMI = bmi_mean
  ),
  weights = "proportional"
)

baseline_followup_contrasts <- as.data.frame(
  summary(
    contrast(
      emm_by_time,
      method = list("FOF - No FOF" = c(-1, 1))
    ),
    infer = c(TRUE, TRUE)
  )
) %>%
  mutate(
    time = as.numeric(as.character(time)),
    term = if_else(time == 0, "FOF - No FOF at baseline (model-estimated)", "FOF - No FOF at 12 months"),
    contrast_group = "Between-group level difference"
  )

did_tbl <- as.data.frame(
  summary(
    contrast(
      emm,
      method = list("FOF change - No FOF change" = c(1, -1, -1, 1))
    ),
    infer = c(TRUE, TRUE)
  )
) %>%
  mutate(
    time = NA_real_,
    term = "Difference in change over time",
    contrast_group = "Interaction contrast"
  )

panel_b <- bind_rows(baseline_followup_contrasts, did_tbl) %>%
  mutate(
    contrast = term,
    time_label = case_when(
      term == "FOF - No FOF at baseline (model-estimated)" ~ "Baseline",
      term == "FOF - No FOF at 12 months" ~ "12 months",
      TRUE ~ "Change difference"
    ),
    display_label = factor(
      contrast,
      levels = c(
        "FOF - No FOF at baseline (model-estimated)",
        "FOF - No FOF at 12 months",
        "Difference in change over time"
      )
    ),
    estimate_ci = sprintf("%.3f (%.3f, %.3f)", estimate, lower.CL, upper.CL),
    p_label = ifelse(is.na(p.value), "NA", format.pval(p.value, digits = 3, eps = 0.001))
  ) %>%
  rename(
    std.error = SE,
    conf.low = lower.CL,
    conf.high = upper.CL
  ) %>%
  select(
    term, contrast_group, contrast, time_label, estimate, std.error, df,
    conf.low, conf.high, t.ratio, p.value, estimate_ci, p_label, display_label
  )

if (nrow(panel_b) != 3) {
  stop("Panel B contrast table must contain exactly three rows.", call. = FALSE)
}

table_to_text_crosscheck(panel_b, "FOF - No FOF at baseline (model-estimated)")
table_to_text_crosscheck(panel_b, "FOF - No FOF at 12 months")
table_to_text_crosscheck(panel_b, "Difference in change over time")

panel_a_path <- file.path(artifact_dir, "k50_fig2_emmeans_panelA.csv")
panel_b_path <- file.path(artifact_dir, "k50_fig2_contrasts_panelB.csv")
readr::write_csv(panel_a, panel_a_path, na = "")
readr::write_csv(panel_b %>% select(-display_label), panel_b_path, na = "")
append_manifest_safe(
  label = "k50_fig2_emmeans_panelA",
  kind = "table_csv",
  path = panel_a_path,
  n = nrow(panel_a),
  notes = "Panel A adjusted estimated marginal means for contrast-focused Figure 2"
)
append_manifest_safe(
  label = "k50_fig2_contrasts_panelB",
  kind = "table_csv",
  path = panel_b_path,
  n = nrow(panel_b),
  notes = "Panel B adjusted between-group contrasts for contrast-focused Figure 2"
)

plot_a <- panel_a %>%
  mutate(time_label = factor(time_label, levels = c("Baseline", "12 months")))

fig_a <- ggplot(plot_a, aes(x = time_label, y = estimate, color = FOF_label, group = FOF_label)) +
  geom_line(linewidth = 1.05) +
  geom_point(size = 2.4) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.08, linewidth = 0.65) +
  scale_color_manual(values = c("No FOF" = "#2166AC", "FOF" = "#B2182B")) +
  labs(
    title = "Panel A. Adjusted trajectories",
    subtitle = "95% CIs reflect group-specific estimated marginal means, not between-group contrasts",
    x = "Time",
    y = "Adjusted locomotor capacity",
    color = NULL
  ) +
  theme_minimal(base_size = 11.5) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    plot.title.position = "plot"
  )

fig_b <- ggplot(panel_b, aes(x = estimate, y = display_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey45", linewidth = 0.6) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.18, linewidth = 0.7, color = "#4D4D4D") +
  geom_point(aes(color = contrast_group), size = 2.8) +
  scale_color_manual(values = c(
    "Between-group level difference" = "#B2182B",
    "Interaction contrast" = "#2166AC"
  )) +
  labs(
    title = "Panel B. Adjusted contrasts",
    subtitle = "Model-based FOF minus No FOF estimates with 95% confidence intervals",
    x = "Adjusted contrast estimate",
    y = NULL,
    color = NULL
  ) +
  theme_minimal(base_size = 11.5) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    plot.title.position = "plot"
  )

fig_compact_a <- fig_a +
  theme(
    legend.position = "none",
    axis.title.x = element_blank(),
    plot.subtitle = element_blank()
  )

fig_compact_b <- fig_b +
  labs(
    title = "Compact Figure 2. Contrast-first view",
    subtitle = "Top strip retains trajectory context; bottom forest plot carries the primary between-group interpretation"
  )

primary_png <- file.path(artifact_dir, "k50_fig2_contrast_focused_primary.png")
primary_pdf <- file.path(artifact_dir, "k50_fig2_contrast_focused_primary.pdf")
compact_png <- file.path(artifact_dir, "k50_fig2_contrast_focused_compact.png")
compact_pdf <- file.path(artifact_dir, "k50_fig2_contrast_focused_compact.pdf")

save_plot_combo(primary_png, fig_a, fig_b, width = 12, height = 6.75, compact = FALSE)
save_plot_combo(primary_pdf, fig_a, fig_b, width = 12, height = 6.75, compact = FALSE)
save_plot_combo(compact_png, fig_compact_a, fig_compact_b, width = 7.25, height = 8.5, compact = TRUE)
save_plot_combo(compact_pdf, fig_compact_a, fig_compact_b, width = 7.25, height = 8.5, compact = TRUE)

append_manifest_safe(
  label = "k50_fig2_contrast_focused_primary_png",
  kind = "figure_png",
  path = primary_png,
  n = nrow(panel_b),
  notes = "Primary two-panel contrast-focused Figure 2 PNG"
)
append_manifest_safe(
  label = "k50_fig2_contrast_focused_primary_pdf",
  kind = "figure_pdf",
  path = primary_pdf,
  n = nrow(panel_b),
  notes = "Primary two-panel contrast-focused Figure 2 PDF"
)
append_manifest_safe(
  label = "k50_fig2_contrast_focused_compact_png",
  kind = "figure_png",
  path = compact_png,
  n = nrow(panel_b),
  notes = "Compact contrast-first Figure 2 PNG"
)
append_manifest_safe(
  label = "k50_fig2_contrast_focused_compact_pdf",
  kind = "figure_pdf",
  path = compact_pdf,
  n = nrow(panel_b),
  notes = "Compact contrast-first Figure 2 PDF"
)

caption_lines <- c(
  "Figure 2. Contrast-focused adjusted locomotor-capacity results by baseline fear of falling.",
  "Panel A shows model-adjusted estimated marginal means for the No FOF and FOF groups at baseline and 12 months from the saved primary LONG mixed model (locomotor_capacity ~ time * FOF_status + age + sex + BMI + (1 | id)).",
  "Panel A confidence intervals describe uncertainty around the group-specific estimated marginal means and should not be interpreted as direct between-group contrasts.",
  "Panel B shows the model-based between-group contrasts with 95% confidence intervals for the model-estimated baseline FOF minus No FOF difference, the 12-month FOF minus No FOF difference, and the interaction contrast defined as the difference in change over time between groups.",
  "The primary inference is based on the contrast estimates in Panel B."
)

results_lines <- c(
  sprintf(
    paste0(
      "The adjusted model-estimated baseline contrast indicated lower locomotor capacity in the FOF group than in the No FOF group ",
      "(estimate %.3f, 95%% CI %.3f to %.3f, p = %s), and the adjusted 12-month contrast remained in the same direction ",
      "(estimate %.3f, 95%% CI %.3f to %.3f, p = %s)."
    ),
    panel_b$estimate[panel_b$term == "FOF - No FOF at baseline (model-estimated)"],
    panel_b$conf.low[panel_b$term == "FOF - No FOF at baseline (model-estimated)"],
    panel_b$conf.high[panel_b$term == "FOF - No FOF at baseline (model-estimated)"],
    panel_b$p_label[panel_b$term == "FOF - No FOF at baseline (model-estimated)"],
    panel_b$estimate[panel_b$term == "FOF - No FOF at 12 months"],
    panel_b$conf.low[panel_b$term == "FOF - No FOF at 12 months"],
    panel_b$conf.high[panel_b$term == "FOF - No FOF at 12 months"],
    panel_b$p_label[panel_b$term == "FOF - No FOF at 12 months"]
  ),
  sprintf(
    paste0(
      "The difference-in-change contrast was %.3f (95%% CI %.3f to %.3f, p = %s), ",
      "supporting a clear separation between the overall level difference and the weaker evidence for a between-group difference in change over time."
    ),
    panel_b$estimate[panel_b$term == "Difference in change over time"],
    panel_b$conf.low[panel_b$term == "Difference in change over time"],
    panel_b$conf.high[panel_b$term == "Difference in change over time"],
    panel_b$p_label[panel_b$term == "Difference in change over time"]
  )
)

technical_note_lines <- c(
  "K50 Figure 2 contrast-focused technical note",
  "",
  "Model backbone:",
  "Saved primary LONG mixed model with locomotor_capacity as the outcome and fixed effects for time * FOF_status + age + sex + BMI plus a random intercept for id.",
  "",
  sprintf("QC check: model frame rows = %d; key-variable missing rows = %d.", nrow(model_df), key_missing_n),
  sprintf("QC check: FOF_status levels = %s.", paste(fof_levels, collapse = ", ")),
  sprintf("QC check: time values = %s.", paste(time_values, collapse = ", ")),
  "",
  "Artifacts:",
  "- Panel A CSV contains group-specific estimated marginal means and 95% CIs.",
  "- Panel B CSV contains direct model-based contrasts, standard errors, confidence intervals, and p-values.",
  "",
  "Interpretation guardrail:",
  "Panel A confidence intervals apply to the adjusted means. The inferential comparison between groups is carried by Panel B contrasts, especially the model-estimated baseline, 12-month, and difference-in-change estimates.",
  "",
  "Table-to-text crosscheck:",
  paste(results_lines, collapse = " ")
)

caption_path <- file.path(artifact_dir, "k50_fig2_caption_proposal.txt")
results_path <- file.path(artifact_dir, "k50_fig2_results_text_2to3_sentences.txt")
technical_note_path <- file.path(artifact_dir, "k50_fig2_technical_note.txt")

save_text_artifact(
  caption_path,
  caption_lines,
  "k50_fig2_caption_proposal",
  "Caption proposal for contrast-focused Figure 2"
)
save_text_artifact(
  results_path,
  results_lines,
  "k50_fig2_results_text_2to3_sentences",
  "Results text proposal after table-to-text crosscheck for contrast-focused Figure 2"
)
save_text_artifact(
  technical_note_path,
  technical_note_lines,
  "k50_fig2_technical_note",
  "Technical note for contrast-focused Figure 2 model backbone and interpretation"
)

session_path <- file.path(artifact_dir, "k50_fig2_contrast_focused_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest_safe(
  label = "k50_fig2_contrast_focused_sessioninfo",
  kind = "sessioninfo",
  path = session_path,
  notes = "Session info for contrast-focused K50 Figure 2 generation"
)

message("Contrast-focused Figure 2 artifacts written to: ", artifact_dir)
