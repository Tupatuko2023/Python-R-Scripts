# R/functions/reporting.R

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

# --- 1) Save table as CSV ------------------------------------------------------
save_table_csv <- function(tbl, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  readr::write_csv(tbl, path)
  invisible(path)
}

# (valinnainen) Save as HTML via knitr::kable (jos haluat edelleen html:t)
save_table_html <- function(tbl, path, title = NULL) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  html_table <- knitr::kable(
    tbl, format = "html",
    table.attr = "border='1' style='border-collapse:collapse;'"
  )
  html_content <- paste0(
    "<html><head><meta charset='UTF-8'></head><body>",
    if (!is.null(title)) paste0("<h3>", title, "</h3>") else "",
    html_table,
    "</body></html>"
  )
  writeLines(html_content, con = path)
  invisible(path)
}

# --- 2) Save sessionInfo -------------------------------------------------------
save_sessioninfo <- function(path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  txt <- capture.output(sessionInfo())
  writeLines(txt, con = path)
  invisible(path)
}

# --- 3) Append manifest row ----------------------------------------------------
# Suositus: yksi manifest rivittää "artefaktit" (csv/png/html/txt) + metatiedot.
append_manifest <- function(row, manifest_path) {
  stopifnot(is.data.frame(row))
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  
  if (!file.exists(manifest_path)) {
    readr::write_csv(row, manifest_path)
  } else {
    old <- suppressMessages(readr::read_csv(manifest_path, show_col_types = FALSE))
    out <- dplyr::bind_rows(old, row)
    readr::write_csv(out, manifest_path)
  }
  invisible(manifest_path)
}

# Helper: tee standardirivi manifestiin
manifest_row <- function(script, label, path, kind,
                         n = NA_integer_, notes = NA_character_) {
  tibble::tibble(
    timestamp = as.character(Sys.time()),
    script    = script,
    label     = label,
    kind      = kind,      # "table_csv", "table_html", "figure_png", "sessioninfo", ...
    path      = path,
    n         = n,
    notes     = notes
  )
}

# --- 4) (valinnainen) table -> text paragraph + crosscheck ---------------------
# Tämä tekee yhden lauseen esim. FOF-efektistä tidy-taulukosta.
results_paragraph_from_table <- function(tbl, term, outcome_label = "Outcome") {
  stopifnot(is.data.frame(tbl))
  hit <- tbl %>% dplyr::filter(.data$term == !!term)
  if (nrow(hit) == 0) return(NA_character_)
  
  est <- hit$estimate[[1]]
  lo  <- hit$conf.low[[1]]
  hi  <- hit$conf.high[[1]]
  p   <- hit$p.value[[1]]
  
  paste0(
    outcome_label, ": ", term, " estimate = ",
    sprintf("%.3f", est),
    " (95% CI ", sprintf("%.3f", lo), ", ", sprintf("%.3f", hi),
    "), p = ", signif(p, 3), "."
  )
}

# “Crosscheck”: varmistaa että term löytyi ja ettei NA:tä ole
table_to_text_crosscheck <- function(tbl, term) {
  hit <- tbl %>% dplyr::filter(.data$term == !!term)
  if (nrow(hit) == 0) stop("Term not found in table: ", term)
  if (any(is.na(hit$estimate)) || any(is.na(hit$p.value))) {
    stop("NA values in estimate/p.value for term: ", term)
  }
  TRUE
}

# --- 5) Initialize paths for script --------------------------------------------
init_paths <- function(script_label) {
  outputs_dir   <- here::here("R-scripts", script_label, "outputs")
  manifest_path <- here::here("manifest", "manifest.csv")
  dir.create(outputs_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)
  
  options(
    fof.outputs_dir   = outputs_dir,
    fof.manifest_path = manifest_path,
    fof.script        = script_label
  )
  
  list(outputs_dir = outputs_dir, manifest_path = manifest_path)
}

# --- 6) Save table as CSV and (optionally) HTML, update manifest ----------------

save_table_csv_html <- function(tbl, label,
                                outputs_dir   = getOption("fof.outputs_dir"),
                                manifest_path = getOption("fof.manifest_path"),
                                script        = getOption("fof.script"),
                                title = label,
                                n = NA_integer_,
                                write_html = TRUE) {
  
  if (is.null(outputs_dir) || is.null(manifest_path) || is.null(script)) {
    stop("Missing outputs_dir/manifest_path/script. Call init_paths('K11') first or pass them explicitly.")
  }
  
  csv_path <- file.path(outputs_dir, paste0(label, ".csv"))
  save_table_csv(tbl, csv_path)
  append_manifest(
    manifest_row(script = script, label = label, path = csv_path, kind = "table_csv", n = n),
    manifest_path
  )
  
  html_path <- NA_character_
  if (isTRUE(write_html)) {
    html_path <- file.path(outputs_dir, paste0(label, ".html"))
    save_table_html(tbl, html_path, title = title)
    append_manifest(
      manifest_row(script = script, label = label, path = html_path, kind = "table_html", n = n),
      manifest_path
    )
  }
  
  invisible(list(csv = csv_path, html = html_path))
}

# --- 7) Save sessionInfo and update manifest -----------------------------------
save_sessioninfo_manifest <- function(
    outputs_dir   = getOption("fof.outputs_dir"),
    manifest_path = getOption("fof.manifest_path"),
    script        = getOption("fof.script")
) {
  if (is.null(outputs_dir) || is.null(manifest_path) || is.null(script)) {
    stop("Missing outputs_dir/manifest_path/script. Call init_paths('K11') first or pass them explicitly.")
  }
  
  sessioninfo_path <- file.path(outputs_dir, paste0("sessioninfo_", script, ".txt"))
  save_sessioninfo(sessioninfo_path)
  append_manifest(
    manifest_row(script = script, label = "sessioninfo", path = sessioninfo_path, kind = "sessioninfo"),
    manifest_path
  )
  
  invisible(sessioninfo_path)
}
# --- End of reporting.R --------------------------------------------------------