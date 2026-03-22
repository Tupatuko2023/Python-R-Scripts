#!/usr/bin/env Rscript

project_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
outputs_dir <- file.path(project_root, "R-scripts", "K50", "outputs")
manifest_path <- file.path(project_root, "manifest", "manifest.csv")
dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)

source(file.path(project_root, "R", "functions", "person_dedup_lookup.R"))

resolve_data_root <- function() {
  data_root <- Sys.getenv("DATA_ROOT", unset = "")
  if (!nzchar(data_root)) {
    env_path <- file.path(project_root, "config", ".env")
    if (file.exists(env_path)) {
      env_lines <- readLines(env_path, warn = FALSE)
      hit <- grep("^export DATA_ROOT=", env_lines, value = TRUE)
      if (length(hit) > 0) {
        data_root <- sub("^export DATA_ROOT=", "", hit[[1]])
        data_root <- gsub('^"|"$', "", data_root)
      }
    }
  }
  if (!nzchar(data_root)) {
    stop("DATA_ROOT is required for K50 visualization.", call. = FALSE)
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
  factor(out, levels = c(0L, 1L), labels = c("FOF_status=0", "FOF_status=1"))
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

write_text <- function(lines, label, notes) {
  out_path <- file.path(outputs_dir, paste0(label, ".txt"))
  writeLines(lines, con = out_path)
  append_manifest_safe(label, "text", file.path("R-scripts", "K50", "outputs", paste0(label, ".txt")), n = length(lines), notes = notes)
}

write_figure <- function(label, notes, draw_fun) {
  render_device <- function(path, kind, open_device, tag) {
    ok <- FALSE

    withCallingHandlers(
      tryCatch({
        open_device(path)
        draw_fun()
        grDevices::dev.off()
        ok <- file.exists(path)
      }, error = function(e) {
        message("Figure export failed for ", tag, ": ", conditionMessage(e))
      }),
      warning = function(w) {
        invokeRestart("muffleWarning")
      }
    )

    if (ok) {
      append_manifest_safe(label, kind, file.path("R-scripts", "K50", "outputs", basename(path)), notes = notes)
    } else {
      message("Figure export missing on disk, skipping manifest entry: ", path)
    }

    invisible(ok)
  }

  render_device(
    file.path(outputs_dir, paste0(label, ".pdf")),
    "figure_pdf",
    function(path) grDevices::pdf(path, width = 12, height = 6, onefile = TRUE),
    paste0(label, ":pdf")
  )

  render_device(
    file.path(outputs_dir, paste0(label, ".png")),
    "figure_png",
    function(path) grDevices::png(path, width = 2400, height = 1200, res = 200, type = "cairo"),
    paste0(label, ":png")
  )

  render_device(
    file.path(outputs_dir, paste0(label, ".svg")),
    "figure_svg",
    function(path) grDevices::svg(path, width = 12, height = 6),
    paste0(label, ":svg")
  )
}

data_root <- resolve_data_root()
wide_path <- file.path(data_root, "paper_02", "analysis", "fof_analysis_k50_wide.rds")
wide_raw <- readRDS(wide_path)
wide_raw <- prepare_k50_person_dedup(wide_raw, "WIDE", "locomotor_capacity")$data

plot_df <- data.frame(
  id = trimws(as.character(wide_raw$id)),
  FOF_status = normalize_fof(wide_raw$FOF_status),
  age = safe_num(wide_raw$age),
  sex = normalize_sex(wide_raw$sex),
  BMI = safe_num(wide_raw$BMI),
  FI22_nonperformance_KAAOS = safe_num(wide_raw$FI22_nonperformance_KAAOS),
  locomotor_capacity_0 = safe_num(wide_raw$locomotor_capacity_0),
  locomotor_capacity_12m = safe_num(wide_raw$locomotor_capacity_12m),
  stringsAsFactors = FALSE
)

plot_df$delta_locomotor_capacity <- plot_df$locomotor_capacity_12m - plot_df$locomotor_capacity_0

raw_keep <- stats::complete.cases(plot_df[, c(
  "FOF_status",
  "FI22_nonperformance_KAAOS",
  "delta_locomotor_capacity"
)])
raw_df <- plot_df[raw_keep, , drop = FALSE]

model_keep <- stats::complete.cases(plot_df[, c(
  "FOF_status",
  "FI22_nonperformance_KAAOS",
  "delta_locomotor_capacity",
  "age",
  "sex",
  "BMI"
)])
model_df <- plot_df[model_keep, , drop = FALSE]
model_df$FOF_status <- factor(model_df$FOF_status, levels = levels(raw_df$FOF_status))
model_df$sex <- factor(model_df$sex)

raw_facets <- split(raw_df, raw_df$FOF_status)

draw_raw_facet <- function() {
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par), add = TRUE)
  par(mfrow = c(1, length(raw_facets)), mar = c(5, 5, 4, 1) + 0.1, oma = c(0, 0, 1, 0))
  x_lim <- range(raw_df$FI22_nonperformance_KAAOS, na.rm = TRUE)
  y_lim <- range(raw_df$delta_locomotor_capacity, na.rm = TRUE)
  point_col <- grDevices::rgb(44, 62, 80, maxColorValue = 255, alpha = 120)
  band_col <- grDevices::rgb(192, 57, 43, maxColorValue = 255, alpha = 50)
  line_col <- "#C0392B"

  for (panel_name in names(raw_facets)) {
    panel_df <- raw_facets[[panel_name]]
    plot(
      panel_df$FI22_nonperformance_KAAOS,
      panel_df$delta_locomotor_capacity,
      xlim = x_lim,
      ylim = y_lim,
      pch = 16,
      col = point_col,
      xlab = "FI22_nonperformance_KAAOS",
      ylab = "delta_locomotor_capacity",
      main = panel_name
    )
    if (nrow(panel_df) >= 10 && length(unique(panel_df$FI22_nonperformance_KAAOS)) >= 5) {
      fit <- stats::lm(delta_locomotor_capacity ~ FI22_nonperformance_KAAOS, data = panel_df)
      grid_x <- seq(min(panel_df$FI22_nonperformance_KAAOS), max(panel_df$FI22_nonperformance_KAAOS), length.out = 100)
      pred <- stats::predict(fit, newdata = data.frame(FI22_nonperformance_KAAOS = grid_x), interval = "confidence")
      polygon(c(grid_x, rev(grid_x)), c(pred[, "lwr"], rev(pred[, "upr"])), border = NA, col = band_col)
      lines(grid_x, pred[, "fit"], col = line_col, lwd = 2)
    }
  }
  mtext("Figure A. Raw delta_locomotor_capacity by FI22 and FOF_status", outer = TRUE, cex = 1.1)
}

vis_model <- stats::lm(
  delta_locomotor_capacity ~ FOF_status * FI22_nonperformance_KAAOS + age + sex + BMI,
  data = model_df
)

fi22_grid <- seq(
  min(model_df$FI22_nonperformance_KAAOS, na.rm = TRUE),
  max(model_df$FI22_nonperformance_KAAOS, na.rm = TRUE),
  length.out = 100
)

newdata <- expand.grid(
  FI22_nonperformance_KAAOS = fi22_grid,
  FOF_status = levels(model_df$FOF_status),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
newdata$FOF_status <- factor(newdata$FOF_status, levels = levels(model_df$FOF_status))
newdata$age <- mean(model_df$age, na.rm = TRUE)
newdata$BMI <- mean(model_df$BMI, na.rm = TRUE)
newdata$sex <- factor(levels(model_df$sex)[1], levels = levels(model_df$sex))

pred <- stats::predict(vis_model, newdata = newdata, interval = "confidence")
newdata$fit <- pred[, "fit"]
newdata$lwr <- pred[, "lwr"]
newdata$upr <- pred[, "upr"]

draw_model_based <- function() {
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par), add = TRUE)
  par(mar = c(5, 5, 4, 1) + 0.1)
  y_lim <- range(c(newdata$lwr, newdata$upr), na.rm = TRUE)
  plot(
    range(newdata$FI22_nonperformance_KAAOS),
    y_lim,
    type = "n",
    xlab = "FI22_nonperformance_KAAOS",
    ylab = "Predicted delta_locomotor_capacity",
    main = "Figure B. Model-based predicted delta_locomotor_capacity"
  )

  cols <- c("#1F77B4", "#D62728")
  fills <- c(
    grDevices::rgb(31, 119, 180, maxColorValue = 255, alpha = 50),
    grDevices::rgb(214, 39, 40, maxColorValue = 255, alpha = 50)
  )

  for (i in seq_along(levels(newdata$FOF_status))) {
    group <- levels(newdata$FOF_status)[i]
    group_df <- newdata[newdata$FOF_status == group, , drop = FALSE]
    polygon(
      c(group_df$FI22_nonperformance_KAAOS, rev(group_df$FI22_nonperformance_KAAOS)),
      c(group_df$lwr, rev(group_df$upr)),
      border = NA,
      col = fills[i]
    )
    lines(group_df$FI22_nonperformance_KAAOS, group_df$fit, lwd = 3, col = cols[i])
  }
  legend("topright", legend = levels(newdata$FOF_status), col = cols, lwd = 3, bty = "n")
}

write_figure(
  "k50_visual_fi22_fof_delta_raw_facet",
  "Faceted raw-data figure for FI22, FOF, and delta_locomotor_capacity",
  draw_raw_facet
)

write_figure(
  "k50_visual_fi22_fof_delta_model_based",
  "Model-based predicted figure for FI22, FOF, and delta_locomotor_capacity",
  draw_model_based
)

note_lines <- c(
  "K50 FI22-FOF-delta visualization note",
  "",
  "Figure A is a descriptive faceted raw-data figure using canonical WIDE variables:",
  "x = FI22_nonperformance_KAAOS, y = delta_locomotor_capacity, facet = FOF_status.",
  "Figure B is an illustrative model-based predicted figure using the visualization model:",
  "delta_locomotor_capacity ~ FOF_status * FI22_nonperformance_KAAOS + age + sex + BMI.",
  "These figures do not replace the locked K50 primary, FI22 sensitivity, diagnostics, or robustness analyses.",
  "delta_locomotor_capacity is defined canonically as locomotor_capacity_12m - locomotor_capacity_0.",
  "Composite_Z remains verification-only and FI22_nonperformance_KAAOS remains sensitivity-only."
)

write_text(note_lines, "k50_visual_fi22_fof_delta_note", "Visualization note for FI22, FOF_status, and delta_locomotor_capacity")

session_path <- file.path(outputs_dir, "k50_visual_fi22_fof_delta_sessioninfo.txt")
writeLines(capture.output(sessionInfo()), con = session_path)
append_manifest_safe(
  "k50_visual_fi22_fof_delta_sessioninfo",
  "sessioninfo",
  file.path("R-scripts", "K50", "outputs", "k50_visual_fi22_fof_delta_sessioninfo.txt"),
  notes = "K50 visualization session info"
)
