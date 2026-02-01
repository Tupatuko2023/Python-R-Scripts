#!/usr/bin/env Rscript
library(readxl)
library(dplyr)

DATA_ROOT <- "/data/data/com.termux/files/home/FOF_LOCAL_DATA"
raw_path <- file.path(DATA_ROOT, "paper_02", "KAAOS_data_sotullinen.xlsx")

cat("Inspecting raw Excel:", raw_path, "\n")

# Read header row (row 2 in Excel usually, but let's read first few and check)
raw_labels <- read_excel(raw_path, n_max = 2, col_names = FALSE)
labels <- as.character(raw_labels[2, ])

cat("\nFound", length(labels), "columns.\n")

# Search for relevant terms
targets <- c("puristus", "kävely", "liikunta", "paino", "pituus", "pelko", "ikä", "sukupuoli", "500m", "2km")

for (t in targets) {
  matches <- which(grepl(t, labels, ignore.case = TRUE))
  if (length(matches) > 0) {
    cat("\nMatches for '", t, "':\n", sep="")
    for (m in matches) {
      cat("  [Col ", m, "] ", labels[m], "\n", sep="")
    }
  }
}

# Potential N (total rows minus headers)
# We can read one column to be fast
nro_col <- read_excel(raw_path, range = cell_cols(1), skip = 1)
cat("\nTotal rows in NRO column (excluding label):", nrow(nro_col), "\n")
cat("Non-NA NROs:", sum(!is.na(nro_col[[1]])), "\n")
