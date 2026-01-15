#!/usr/bin/env Rscript
# Generate run_order.csv programmatically to avoid line break issues

# Normalize function: remove line breaks, trim whitespace
norm <- function(x) {
  if (is.null(x) || length(x) == 0) return("")
  x <- gsub("[\r\n]+", " ", as.character(x))
  x <- gsub("[[:space:]]+", " ", x)
  trimws(x)
}

# Define verified core scripts (evidence-based)
rows <- list(
  list(
    script_id = "K1",
    file_path = "R-scripts/K1/K1.7.main.R",
    verified = TRUE,
    file_tag = "K1_MAIN.V1_zscore-change.R",
    depends_on = "",
    reads_primary = "data/external/KaatumisenPelko.csv (via K1.1)",
    writes_primary = "R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv",
    run_command = "Rscript R-scripts/K1/K1.7.main.R",
    notes = "Legacy K1 pipeline; sources K1.1-K1.6; bootstrap seed 20251124"
  ),
  list(
    script_id = "K2",
    file_path = "R-scripts/K2/K2.Z_Score_C_Pivot_2G.R",
    verified = TRUE,
    file_tag = "K2.V1_zscore-pivot-2g.R",
    depends_on = "K1",
    reads_primary = "R-scripts/K1/outputs/K1_Z_Score_Change_2G.csv",
    writes_primary = "R-scripts/K2/outputs/K2_Z_Score_Change_2G_Transposed.csv",
    run_command = "Rscript R-scripts/K2/K2.Z_Score_C_Pivot_2G.R",
    notes = "Legacy K2; transposes K1 z-scores by FOF status"
  ),
  list(
    script_id = "K3",
    file_path = "R-scripts/K3/K3.7.main.R",
    verified = TRUE,
    file_tag = "K3_MAIN.V1_original-values.R",
    depends_on = "",
    reads_primary = "data/external/KaatumisenPelko.csv (via K1.1 shared)",
    writes_primary = "R-scripts/K3/outputs/K3_Values_2G.csv",
    run_command = "Rscript R-scripts/K3/K3.7.main.R",
    notes = "Legacy K3; shares K1.1 and K1.5 modules with K1"
  ),
  list(
    script_id = "K4",
    file_path = "R-scripts/K4/K4.A_Score_C_Pivot_2G.R",
    verified = TRUE,
    file_tag = "K4.V1_values-pivot-2g.R",
    depends_on = "K3",
    reads_primary = "R-scripts/K3/outputs/K3_Values_2G.csv",
    writes_primary = "R-scripts/K4/outputs/K4_Values_2G_Transposed.csv",
    run_command = "Rscript R-scripts/K4/K4.A_Score_C_Pivot_2G.R",
    notes = "Legacy K4; transposes K3 original values by FOF status"
  ),
  list(
    script_id = "K18_QC",
    file_path = "R-scripts/K18/K18_QC.V1_qc-run.R",
    verified = TRUE,
    file_tag = "K18_QC.V1_qc-run.R",
    depends_on = "",
    reads_primary = "CLI --data argument (CSV path)",
    writes_primary = "R-scripts/K18/outputs/K18_QC/qc/ (artifacts)",
    run_command = "Rscript R-scripts/K18/K18_QC.V1_qc-run.R --data <path> --shape AUTO",
    notes = "Stop-the-line QC; args: --data (required) --shape (default AUTO) --dict (default data/data_dictionary.csv)"
  ),
  list(
    script_id = "K15",
    file_path = "R-scripts/K15/K15.R",
    verified = TRUE,
    file_tag = "K15.R",
    depends_on = "",
    reads_primary = "data/external/KaatumisenPelko.csv OR analysis_data (memory)",
    writes_primary = "R-scripts/K15/outputs/K15_frailty_analysis_data.RData",
    run_command = "Rscript R-scripts/K15/K15.R",
    notes = "Legacy K15; creates frailty proxy vars; saves RData for K16"
  ),
  list(
    script_id = "K16",
    file_path = "R-scripts/K16/K16.R",
    verified = TRUE,
    file_tag = "K16.R",
    depends_on = "K15",
    reads_primary = "R-scripts/K15/outputs/K15_frailty_analysis_data.RData",
    writes_primary = "R-scripts/K16/outputs/ (CSV outputs)",
    run_command = "Rscript R-scripts/K16/K16.R",
    notes = "Legacy K16; frailty-adjusted ANCOVA/mixed; loads K15 RData"
  ),
  list(
    script_id = "K01_MAIN",
    file_path = "R-scripts/K01_MAIN/K01_MAIN.V1_zscore-change.R",
    verified = TRUE,
    file_tag = "K01_MAIN.V1_zscore-change.R",
    depends_on = "",
    reads_primary = "data/external/KaatumisenPelko.csv",
    writes_primary = "R-scripts/K01_MAIN/outputs/",
    run_command = "Rscript R-scripts/K01_MAIN/K01_MAIN.V1_zscore-change.R",
    notes = "Refactored K1 with CLAUDE.md standards"
  )
)

# Convert to data.frame
df <- do.call(rbind, lapply(rows, function(r) {
  data.frame(
    script_id = norm(r$script_id),
    file_path = norm(r$file_path),
    verified = ifelse(isTRUE(r$verified), "TRUE", "FALSE"),
    file_tag = norm(r$file_tag),
    depends_on = norm(r$depends_on),
    reads_primary = norm(r$reads_primary),
    writes_primary = norm(r$writes_primary),
    run_command = norm(r$run_command),
    notes = norm(r$notes),
    stringsAsFactors = FALSE
  )
}))

# Write CSV
write.csv(df, "docs/run_order.csv", row.names = FALSE, quote = TRUE)

# Validate
d <- read.csv("docs/run_order.csv", stringsAsFactors = FALSE)
cat("✓ Created docs/run_order.csv\n")
cat("  Rows:", nrow(d), "\n")
cat("  Columns:", ncol(d), "\n")
cat("  Verified scripts:", sum(d$verified == "TRUE"), "\n")
cat("\n")
print(head(d, 3))
