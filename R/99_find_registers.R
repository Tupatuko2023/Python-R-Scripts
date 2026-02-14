#!/usr/bin/env Rscript
library(readxl)

# Try to find DATA_ROOT
data_root <- Sys.getenv("DATA_ROOT")

if (data_root == "") {
  # Try to read from Quantify-FOF-Utilization-Costs/config/.env
  env_path <- "Quantify-FOF-Utilization-Costs/config/.env"
  if (file.exists(env_path)) {
    lines <- readLines(env_path)
    data_root_line <- lines[grep("^DATA_ROOT=", lines)]
    if (length(data_root_line) > 0) {
      data_root <- sub("^DATA_ROOT=", "", data_root_line)
    }
  }
}

if (data_root == "" || !dir.exists(data_root)) {
  # Fallback to default if not found
  data_root <- "/data/data/com.termux/files/home/FOF_LOCAL_DATA"
}

cat("Scanning DATA_ROOT:", data_root, "\n")

# Scan for Excel files
all_files <- list.files(path = data_root, pattern = "\\.xlsx$", recursive = TRUE, full.names = TRUE)

# Filter for keywords
keywords <- c("pkl", "poli", "osasto", "ward")
candidates <- all_files[grepl(paste(keywords, collapse = "|"), basename(all_files), ignore.case = TRUE)]

cat("Found", length(candidates), "candidates.\n")

results <- list()

for (f in candidates) {
  cat("\nInspecting:", f, "\n")
  tryCatch({
    # Use readxl to read just the header
    header <- names(readxl::read_excel(f, n_max = 1))
    cat("Columns:", paste(header, collapse = ", "), "\n")
    results[[f]] <- header
  }, error = function(e) {
    cat("Error reading file:", conditionMessage(e), "\n")
  })
}

# Generate Report
report_path <- "docs/REGISTER_PATHS.md"
if (!dir.exists(dirname(report_path))) dir.create(dirname(report_path), recursive = TRUE)

cat("# REGISTER_PATHS.md\n\nGenerated on:", as.character(Sys.time()), "\n\n", file = report_path)
cat("## Found Register Files\n\n", file = report_path, append = TRUE)

if (length(results) == 0) {
    cat("No matching files found.\n", file = report_path, append = TRUE)
} else {
    for (f in names(results)) {
      cat("### ", basename(f), "\n", file = report_path, append = TRUE)
      cat("- **Path**: `", f, "`\n", file = report_path, append = TRUE)
      cat("- **Columns**: `", paste(results[[f]], collapse = ", "), "`\n\n", file = report_path, append = TRUE)
    }
}

cat("Report saved to:", report_path, "\n")
