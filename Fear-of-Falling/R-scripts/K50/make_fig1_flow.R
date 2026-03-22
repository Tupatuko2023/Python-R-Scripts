#!/usr/bin/env Rscript

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

project_root <- getwd()
outputs_dir <- file.path(project_root, "R-scripts", "K50", "outputs", "FIG1_flow")
manifest_path <- file.path(project_root, "manifest", "manifest.csv")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)

counts_path <- file.path(project_root, "R-scripts", "K50", "outputs", "k50_long_locomotor_capacity_cohort_flow_counts.csv")
wide_receipt_path <- file.path(project_root, "R-scripts", "K50", "outputs", "k50_wide_locomotor_capacity_input_receipt.txt")
long_receipt_path <- file.path(project_root, "R-scripts", "K50", "outputs", "k50_long_locomotor_capacity_input_receipt.txt")

stopifnot(file.exists(counts_path), file.exists(wide_receipt_path), file.exists(long_receipt_path))

read_receipt <- function(path) {
  lines <- readLines(path, warn = FALSE)
  keep <- grepl("=", lines, fixed = TRUE)
  parts <- strsplit(lines[keep], "=", fixed = TRUE)
  keys <- vapply(parts, `[`, character(1), 1)
  vals <- vapply(parts, function(x) paste(x[-1], collapse = "="), character(1))
  out <- as.list(vals)
  names(out) <- keys
  out
}

append_manifest <- function(file_label, kind, path, notes) {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  row <- paste(ts, "K50_FIG1_flow", file_label, kind, path, "NA", notes, sep = ",")
  write(row, file = manifest_path, append = TRUE)
}

draw_box <- function(x0, y0, x1, y1, fill, border = "#203040", lwd = 2) {
  rect(x0, y0, x1, y1, col = fill, border = border, lwd = lwd)
}

draw_arrow <- function(x0, y0, x1, y1, col = "#203040") {
  arrows(x0, y0, x1, y1, length = 0.08, lwd = 2, col = col)
}

counts <- read.csv(counts_path, check.names = FALSE)
wide_receipt <- read_receipt(wide_receipt_path)
long_receipt <- read_receipt(long_receipt_path)

count_value <- function(key) {
  hit <- counts$value[counts$count == key]
  if (!length(hit)) return(NA_real_)
  as.numeric(hit[[1]])
}

wide_loaded <- as.numeric(wide_receipt$rows_loaded)
wide_modeled <- as.numeric(wide_receipt$rows_modeled)
long_loaded_rows <- as.numeric(long_receipt$rows_loaded)
long_modeled_rows <- as.numeric(long_receipt$rows_modeled)
long_raw_id <- count_value("N_RAW_ID")
long_with_fof <- count_value("N_WITH_FOF")
long_outcome_complete <- count_value("N_OUTCOME_COMPLETE")
long_primary_participants <- count_value("N_ANALYTIC_PRIMARY")

fig_path <- file.path(outputs_dir, "k50_fig1_flow.png")
png(fig_path, width = 2200, height = 1400, res = 180)
par(mar = c(1, 0, 3, 0), xpd = NA)
plot.new()
plot.window(xlim = c(0, 100), ylim = c(0, 100))

title(main = "Figure 1. Analytic sample derivation for complete-case and repeated-measures analyses", cex.main = 1.25)

draw_box(32, 77, 68, 89, fill = "#E7F0F7")
text(
  50, 83,
  sprintf(
    "Source cohort\n%d participants available\nfor branch-specific analysis",
    wide_loaded
  ),
  font = 2,
  cex = 1.04
)

draw_arrow(42, 78, 24, 65)
draw_arrow(58, 78, 76, 65)

draw_box(8, 48, 40, 66, fill = "#F7E9DA")
text(24, 61, "Complete-case analysis (WIDE)", font = 2, cex = 1.05)
text(24, 56.2, sprintf("%d participants screened", wide_loaded), cex = 0.98)
text(24, 51.5, sprintf("%d participants in primary model", wide_modeled), cex = 1.02)

draw_box(60, 52, 92, 68, fill = "#E6F3EA")
text(76, 63.5, "Repeated-measures analysis (LONG)", font = 2, cex = 1.02)
text(76, 59.5, sprintf("%d participants with valid FOF", long_with_fof), cex = 0.98)
text(76, 55.2, sprintf("%d observations in mixed model", long_modeled_rows), cex = 0.98)

draw_arrow(76, 52, 76, 42)
draw_box(60, 26, 92, 42, fill = "#F1F8E8")
text(76, 37.5, sprintf("%d participants with complete paired outcome", long_outcome_complete), cex = 0.95)
text(76, 32.8, sprintf("%d participants with complete primary covariates", long_primary_participants), cex = 0.95)

dev.off()

append_manifest("k50_fig1_flow", "figure_png", file.path("R-scripts", "K50", "outputs", "FIG1_flow", "k50_fig1_flow.png"), "Combined WIDE+LONG analytic sample flow built from locked K50 aggregate artifacts")
