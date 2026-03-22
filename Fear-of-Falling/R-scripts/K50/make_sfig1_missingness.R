#!/usr/bin/env Rscript

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

project_root <- getwd()
outputs_dir <- file.path(project_root, "R-scripts", "K50", "outputs", "SFIG1_missingness")
manifest_path <- file.path(project_root, "manifest", "manifest.csv")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)

append_manifest <- function(file_label, kind, path, n = "NA", notes = "") {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  row <- paste(ts, "K50_SFIG1_missingness", file_label, kind, path, n, notes, sep = ",")
  write(row, file = manifest_path, append = TRUE)
}

read_missingness <- function(path, branch_label) {
  df <- read.csv(path, check.names = FALSE)
  df <- df[!is.na(df$FOF_status) & nzchar(trimws(as.character(df$FOF_status))), , drop = FALSE]
  df$branch <- branch_label
  df$fof_label <- ifelse(as.character(df$FOF_status) == "1", "FOF", "No FOF")
  df$time_label <- ifelse(as.numeric(df$time) == 0, "Baseline", "12 months")
  df$outcome_missing_prop <- df$outcome_missing_n / df$n
  df
}

wide_path <- file.path(project_root, "R-scripts", "K50", "outputs", "k50_wide_locomotor_capacity_missingness_group_time.csv")
long_path <- file.path(project_root, "R-scripts", "K50", "outputs", "k50_long_locomotor_capacity_missingness_group_time.csv")
stopifnot(file.exists(wide_path), file.exists(long_path))

plot_df <- rbind(
  read_missingness(wide_path, "WIDE"),
  read_missingness(long_path, "LONG")
)

plot_data_path <- file.path(outputs_dir, "k50_sfig1_missingness_plot_data.csv")
utils::write.csv(plot_df, plot_data_path, row.names = FALSE)

fig_path <- file.path(outputs_dir, "k50_sfig1_missingness.png")
png(fig_path, width = 2200, height = 1400, res = 200)
par(mfrow = c(1, 2), mar = c(5, 5, 4, 2), oma = c(0, 0, 3, 0))
cols <- c("No FOF" = "#2C7FB8", "FOF" = "#D95F0E")

for (branch_name in c("WIDE", "LONG")) {
  sub <- plot_df[plot_df$branch == branch_name, , drop = FALSE]
  sub <- sub[order(sub$fof_label, sub$time), , drop = FALSE]
  ylim <- c(0, max(plot_df$outcome_missing_prop, na.rm = TRUE) * 1.15)
  plot(c(1, 2), c(0, 0), type = "n", xaxt = "n", ylim = ylim,
       xlab = "Time", ylab = "Missing outcome proportion", main = branch_name)
  axis(1, at = c(1, 2), labels = c("Baseline", "12 months"))
  for (group_name in c("No FOF", "FOF")) {
    grp <- sub[sub$fof_label == group_name, , drop = FALSE]
    grp <- grp[order(grp$time), , drop = FALSE]
    lines(c(1, 2), grp$outcome_missing_prop, lwd = 3, col = cols[[group_name]])
    points(c(1, 2), grp$outcome_missing_prop, pch = 19, cex = 1.2, col = cols[[group_name]])
  }
}

legend("topright", legend = c("No FOF", "FOF"), col = cols, lwd = 3, pch = 19, bty = "n")
mtext("Supplementary Figure S1. Outcome missingness at baseline and 12 months by baseline fear-of-falling status in the K50 branch review.", outer = TRUE, cex = 1.05)
dev.off()

note_path <- file.path(outputs_dir, "provenance_note.txt")
note_lines <- c(
  "Supplementary Figure S1 provenance",
  "Caption: Supplementary Figure S1. Outcome missingness at baseline and 12 months by baseline fear-of-falling status in the K50 branch review.",
  "Locked inputs:",
  paste0("- ", basename(c(wide_path, long_path))),
  "Rules:",
  "- Missingness was plotted as a proportion because explicit denominators n were available in the locked missingness tables.",
  "- Only baseline FOF_status groups No FOF and FOF were plotted; rows with missing FOF_status were excluded.",
  "- WIDE and LONG are shown as separate panels because they are related but non-identical analysis populations.",
  "- No K50 full pipeline rerun occurred."
)
writeLines(note_lines, note_path)

session_path <- file.path(outputs_dir, "sessionInfo.txt")
writeLines(capture.output(sessionInfo()), session_path)

append_manifest("k50_sfig1_missingness", "figure_png", file.path("R-scripts", "K50", "outputs", "SFIG1_missingness", "k50_sfig1_missingness.png"), "NA", "Supplementary missingness figure from locked K50 group-time tables")
append_manifest("k50_sfig1_missingness_plot_data", "table_csv", file.path("R-scripts", "K50", "outputs", "SFIG1_missingness", "k50_sfig1_missingness_plot_data.csv"), nrow(plot_df), "Plot data for supplementary missingness figure")
append_manifest("provenance_note", "text", file.path("R-scripts", "K50", "outputs", "SFIG1_missingness", "provenance_note.txt"), length(note_lines), "Locked input provenance for supplementary missingness figure")
append_manifest("sessionInfo", "sessioninfo", file.path("R-scripts", "K50", "outputs", "SFIG1_missingness", "sessionInfo.txt"), "NA", "Session info for supplementary missingness figure")
