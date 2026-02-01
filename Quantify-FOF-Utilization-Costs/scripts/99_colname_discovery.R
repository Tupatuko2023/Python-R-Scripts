# Discovery of outcome columns in aim2_panel.csv
library(readr)
library(dplyr)

# Try to find the panel file
panel_path <- "Quantify-FOF-Utilization-Costs/outputs/aim2_panel.csv"

if (file.exists(panel_path)) {
  panel <- read_csv(panel_path, n_max = 5)
  cols <- colnames(panel)
  
  cat("--- ALL COLUMNS IN aim2_panel.csv ---
")
  print(cols)
  
  patterns <- c("visit", "period", "hosp", "ward", "out", "in", "util", "cost")
  
  cat("\n--- MATCHING COLUMNS ---
")
  for (p in patterns) {
    matches <- grep(p, cols, value = TRUE, ignore.case = TRUE)
    if (length(matches) > 0) {
      cat(sprintf("Pattern '%s': %s\n", p, paste(matches, collapse = ", ")))
    }
  }
} else {
  cat(sprintf("Panel file not found at: %s\n", panel_path))
  # Fallback: check if we can see it in DATA_ROOT if environment is available
  # (But usually we want to see what's in the repo outputs first)
}

