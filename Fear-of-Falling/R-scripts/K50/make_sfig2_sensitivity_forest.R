#!/usr/bin/env Rscript

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

project_root <- getwd()
outputs_dir <- file.path(project_root, "R-scripts", "K50", "outputs", "SFIG2_sensitivity_forest")
manifest_path <- file.path(project_root, "manifest", "manifest.csv")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)

append_manifest <- function(file_label, kind, path, n = "NA", notes = "") {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  row <- paste(ts, "K50_SFIG2_sensitivity_forest", file_label, kind, path, n, notes, sep = ",")
  write(row, file = manifest_path, append = TRUE)
}

read_terms <- function(path, branch_label, model_label) {
  df <- read.csv(path, check.names = FALSE)
  if ("effect" %in% names(df)) {
    df <- df[df$effect == "fixed", , drop = FALSE]
  }
  keep <- df$term %in% c("FOF_status1", "time:FOF_status1")
  df <- df[keep, , drop = FALSE]
  if (!nrow(df)) return(df)
  data.frame(
    term = df$term,
    estimate = df$estimate,
    conf.low = df$conf.low,
    conf.high = df$conf.high,
    branch = if ("branch" %in% names(df)) df$branch else tolower(branch_label),
    outcome = if ("outcome" %in% names(df)) df$outcome else NA_character_,
    model_role = if ("model_role" %in% names(df)) df$model_role else NA_character_,
    formula = if ("formula" %in% names(df)) df$formula else NA_character_,
    n = if ("n" %in% names(df)) df$n else NA_real_,
    branch_label = branch_label,
    model_label = model_label,
    panel_label = ifelse(df$term == "FOF_status1", "FOF main effect", "Time x FOF_status interaction"),
    row_label = paste(branch_label, model_label),
    stringsAsFactors = FALSE
  )
}

specs <- list(
  list(path = file.path(project_root, "R-scripts", "K50", "outputs", "k50_wide_locomotor_capacity_model_terms_primary.csv"), branch = "WIDE", model = "primary"),
  list(path = file.path(project_root, "R-scripts", "K50", "outputs", "k50_long_locomotor_capacity_model_terms_primary.csv"), branch = "LONG", model = "primary"),
  list(path = file.path(project_root, "R-scripts", "K50", "outputs", "k50_wide_z3_model_terms_fallback.csv"), branch = "WIDE", model = "z3"),
  list(path = file.path(project_root, "R-scripts", "K50", "outputs", "k50_long_z3_model_terms_fallback.csv"), branch = "LONG", model = "z3"),
  list(path = file.path(project_root, "R-scripts", "K50", "outputs", "k50_wide_locomotor_capacity_model_terms_fi22.csv"), branch = "WIDE", model = "FI_22-adjusted"),
  list(path = file.path(project_root, "R-scripts", "K50", "outputs", "k50_long_locomotor_capacity_model_terms_fi22.csv"), branch = "LONG", model = "FI_22-adjusted")
)

for (spec in specs) stopifnot(file.exists(spec$path))

plot_df <- do.call(rbind, lapply(specs, function(spec) {
  read_terms(spec$path, spec$branch, spec$model)
}))
stopifnot(nrow(plot_df) > 0)

panel_order_main <- c("WIDE primary", "LONG primary", "WIDE z3", "LONG z3", "WIDE FI_22-adjusted", "LONG FI_22-adjusted")
panel_order_interaction <- c("LONG primary", "LONG z3", "LONG FI_22-adjusted")
plot_df$row_label <- trimws(plot_df$row_label)
plot_df$branch_color <- ifelse(plot_df$branch_label == "WIDE", "#2C7FB8", "#D95F0E")

plot_data_path <- file.path(outputs_dir, "k50_sfig2_sensitivity_forest_plot_data.csv")
utils::write.csv(plot_df, plot_data_path, row.names = FALSE)

fig_path <- file.path(outputs_dir, "k50_sfig2_sensitivity_forest.png")
pdf_path <- file.path(outputs_dir, "k50_sfig2_sensitivity_forest.pdf")

xlim <- range(c(plot_df$conf.low, plot_df$conf.high, 0), na.rm = TRUE)

draw_panel <- function(panel_name, row_order) {
  sub <- plot_df[plot_df$panel_label == panel_name, , drop = FALSE]
  sub$row_label <- factor(sub$row_label, levels = rev(row_order))
  sub <- sub[order(sub$row_label), , drop = FALSE]
  y <- seq_len(nrow(sub))

  plot(xlim, c(0.5, length(y) + 0.5), type = "n", yaxt = "n",
       ylab = "", xlab = "Estimate (95% CI)", main = panel_name)
  abline(v = 0, lty = 2, col = "gray55")
  axis(2, at = y, labels = as.character(sub$row_label), las = 1, tick = FALSE)
  segments(sub$conf.low, y, sub$conf.high, y, lwd = 2.5, col = sub$branch_color)
  points(sub$estimate, y, pch = 19, cex = 1.2, col = sub$branch_color)
}

draw_forest <- function() {
  par(mfrow = c(1, 2), mar = c(5, 11, 4, 2), oma = c(0, 0, 0, 0))
  draw_panel("FOF main effect", panel_order_main)
  draw_panel("Time x FOF_status interaction", panel_order_interaction)
  legend("bottomright", legend = c("WIDE estimand", "LONG estimand"),
         col = c("#2C7FB8", "#D95F0E"), pch = 19, lwd = 2.5, bty = "n")
}

png(fig_path, width = 2400, height = 1600, res = 200)
draw_forest()
dev.off()

pdf(pdf_path, width = 12, height = 8)
draw_forest()
dev.off()

note_path <- file.path(outputs_dir, "provenance_note.txt")
provenance_caption_lines <- c(
  "Caption: Supplementary Figure S2. FOF-related estimates across primary, fallback, and FI_22-adjusted models.",
  "Estimates represent unstandardized regression coefficients corresponding to adjusted differences in locomotor capacity on the model (latent) scale, with 95% confidence intervals."
)
note_lines <- c(
  "Supplementary Figure S2 provenance",
  provenance_caption_lines,
  "Locked inputs:",
  paste0("- ", basename(vapply(specs, `[[`, character(1), "path"))),
  "Rules:",
  "- Only FOF-related exported terms were plotted.",
  "- WIDE and LONG rows are shown as distinct estimands and are not pooled.",
  "- No age sex BMI or FI_22 coefficient rows were plotted.",
  "- WIDE interaction rows were not fabricated because they are not estimable in the locked WIDE term tables.",
  "- No K50 full pipeline rerun occurred."
)
writeLines(note_lines, note_path)

session_path <- file.path(outputs_dir, "sessionInfo.txt")
writeLines(capture.output(sessionInfo()), session_path)

append_manifest("k50_sfig2_sensitivity_forest", "figure_png", file.path("R-scripts", "K50", "outputs", "SFIG2_sensitivity_forest", "k50_sfig2_sensitivity_forest.png"), "NA", "Supplementary forest plot from locked K50 term exports")
append_manifest("k50_sfig2_sensitivity_forest_pdf", "figure_pdf", file.path("R-scripts", "K50", "outputs", "SFIG2_sensitivity_forest", "k50_sfig2_sensitivity_forest.pdf"), "NA", "Supplementary forest plot PDF from locked K50 term exports")
append_manifest("k50_sfig2_sensitivity_forest_plot_data", "table_csv", file.path("R-scripts", "K50", "outputs", "SFIG2_sensitivity_forest", "k50_sfig2_sensitivity_forest_plot_data.csv"), nrow(plot_df), "Plot data for supplementary forest plot")
append_manifest("provenance_note", "text", file.path("R-scripts", "K50", "outputs", "SFIG2_sensitivity_forest", "provenance_note.txt"), length(note_lines), "Locked input provenance for supplementary forest plot")
append_manifest("sessionInfo", "sessioninfo", file.path("R-scripts", "K50", "outputs", "SFIG2_sensitivity_forest", "sessionInfo.txt"), "NA", "Session info for supplementary forest plot")
