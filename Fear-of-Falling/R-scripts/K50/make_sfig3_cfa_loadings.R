#!/usr/bin/env Rscript

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

project_root <- getwd()
outputs_dir <- file.path(project_root, "R-scripts", "K50", "outputs", "SFIG3_cfa_loadings")
manifest_path <- file.path(project_root, "manifest", "manifest.csv")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)

append_manifest <- function(file_label, kind, path, n = "NA", notes = "") {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  row <- paste(ts, "K50_SFIG3_cfa_loadings", file_label, kind, path, n, notes, sep = ",")
  write(row, file = manifest_path, append = TRUE)
}

k32_loadings_path <- file.path(project_root, "R-scripts", "K32", "outputs", "k32_cfa_primary_loadings.csv")
k32_summary_path <- file.path(project_root, "R-scripts", "K32", "outputs", "k32_cfa_primary_summary.txt")
k39_loadings_path <- file.path(project_root, "R-scripts", "K39", "outputs", "k39_cfa_primary_loadings.csv")
stopifnot(file.exists(k32_loadings_path), file.exists(k32_summary_path), file.exists(k39_loadings_path))

df <- read.csv(k32_loadings_path, check.names = FALSE)
df <- df[df$lhs == "Capacity" & df$op == "=~" & df$rhs %in% c("gait", "chair", "balance"), c("rhs", "std.all"), drop = FALSE]
stopifnot(nrow(df) == 3)
df$indicator_label <- c(gait = "Gait", chair = "Chair rise", balance = "Balance")[df$rhs]
df <- df[match(c("gait", "chair", "balance"), df$rhs), , drop = FALSE]

plot_data_path <- file.path(outputs_dir, "k50_sfig3_cfa_loadings_plot_data.csv")
utils::write.csv(df, plot_data_path, row.names = FALSE)

fig_path <- file.path(outputs_dir, "k50_sfig3_cfa_loadings.png")
png(fig_path, width = 2000, height = 1400, res = 200)
par(mar = c(5, 5, 4, 2))
yl <- max(df$std.all) * 1.15
bp <- barplot(df$std.all, names.arg = df$indicator_label, ylim = c(0, yl),
              col = c("#2C7FB8", "#D95F0E", "#238B45"), ylab = "Standardized loading",
              main = "Supplementary Figure S3. Standardized loadings for the three-indicator locomotor-capacity factor")
text(bp, df$std.all + 0.04, labels = sprintf("%.3f", df$std.all), cex = 1)
dev.off()

note_path <- file.path(outputs_dir, "provenance_note.txt")
note_lines <- c(
  "Supplementary Figure S3 provenance",
  "Caption: Supplementary Figure S3. Standardized loadings for the three-indicator locomotor-capacity factor used as the primary latent outcome.",
  "Locked inputs:",
  paste0("- ", basename(c(k32_loadings_path, k32_summary_path, k39_loadings_path))),
  "Rules:",
  "- The plotted standardized loadings come from the locked K32 Capacity CFA output only.",
  "- K39 CFA artifacts were inspected but not plotted because they describe a different latent construct rather than locomotor capacity.",
  "- No global fit indices are claimed here because the three-indicator Capacity CFA is just-identified.",
  "- No CFA rerun occurred."
)
writeLines(note_lines, note_path)

session_path <- file.path(outputs_dir, "sessionInfo.txt")
writeLines(capture.output(sessionInfo()), session_path)

append_manifest("k50_sfig3_cfa_loadings", "figure_png", file.path("R-scripts", "K50", "outputs", "SFIG3_cfa_loadings", "k50_sfig3_cfa_loadings.png"), "NA", "Supplementary CFA loading figure from locked K32 outputs")
append_manifest("k50_sfig3_cfa_loadings_plot_data", "table_csv", file.path("R-scripts", "K50", "outputs", "SFIG3_cfa_loadings", "k50_sfig3_cfa_loadings_plot_data.csv"), nrow(df), "Plot data for supplementary CFA loading figure")
append_manifest("provenance_note", "text", file.path("R-scripts", "K50", "outputs", "SFIG3_cfa_loadings", "provenance_note.txt"), length(note_lines), "Locked input provenance for supplementary CFA loading figure")
append_manifest("sessionInfo", "sessioninfo", file.path("R-scripts", "K50", "outputs", "SFIG3_cfa_loadings", "sessionInfo.txt"), "NA", "Session info for supplementary CFA loading figure")
