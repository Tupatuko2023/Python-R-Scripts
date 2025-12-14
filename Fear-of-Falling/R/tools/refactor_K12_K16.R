
# Tämä skripti refaktoroi K12-K16 R-skriptit siten, että niissä on yhtenäinen alkuosa
# (header), käsin tehty manifest_row-lohko poistetaan ja sessioninfo tall
# ennetaan lopussa.

files <- file.path("R-scripts", paste0("K", 12:16), paste0("K", 12:16, ".R"))

header_for <- function(fallback_label) {
  paste0(
    '# --- Kxx template (put at top of every script) -------------------------------\n',
    'suppressPackageStartupMessages({ library(here); library(dplyr) })\n\n',
    'rm(list = ls(pattern = "^(save_|init_paths$|append_manifest$|manifest_row$)"),\n',
    '   envir = .GlobalEnv)\n\n',
    'source(here("R","functions","io.R"))\n',
    'source(here("R","functions","checks.R"))\n',
    'source(here("R","functions","modeling.R"))\n',
    'source(here("R","functions","reporting.R"))\n\n',
    'script_label <- sub("\\\\.R$", "", basename(commandArgs(trailingOnly=FALSE)[grep("--file=", commandArgs())] |> sub("--file=", "", x=_)))\n',
    'if (is.na(script_label) || script_label == "") script_label <- "', fallback_label, '"\n',
    'paths <- init_paths(script_label)\n\n',
    'set.seed(20251124)\n\n'
  )
}

for (i in seq_along(files)) {
  f <- files[i]
  x <- readLines(f, warn = FALSE)
  
  # 1) Prepend header (vain jos ei jo ole)
  if (!any(grepl("Kxx template", x))) {
    x <- c(header_for(paste0("K", 11 + i)), x)
  }
  
  # 2) Poista käsin tehty manifest_rows-blokki (heuristiikka)
  drop_from <- grep("^manifest_rows\\s*<-\\s*tibble::tibble\\(", x)
  if (length(drop_from) == 1) {
    # etsi write_csv -osion loppu
    drop_to <- grep("^}\\s*$", x)  # karkea; voit säätää
    drop_to <- drop_to[drop_to > drop_from][1]
    if (!is.na(drop_to)) x <- x[-seq(drop_from, drop_to)]
  }
  
  # 3) Varmista sessioninfo lopussa
  if (!any(grepl("save_sessioninfo_manifest\\(", x))) {
    x <- c(x, "", "save_sessioninfo_manifest()", "")
  }
  
  writeLines(x, f)
}
