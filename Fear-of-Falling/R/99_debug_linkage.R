#!/usr/bin/env Rscript
library(readxl)
library(dplyr)
library(readr)

DATA_ROOT <- "/data/data/com.termux/files/home/FOF_LOCAL_DATA"

# 1. Load KAAOS Data
kaaos_path <- file.path(DATA_ROOT, "paper_02", "KAAOS_data.xlsx")
# Read with no column names first to see what we have
kaaos_raw <- read_excel(kaaos_path, col_names = FALSE)

# According to build_real_panel.py, it skips 1 row.
kaaos_build <- kaaos_raw[-1, ] 
colnames(kaaos_build) <- as.character(kaaos_build[1, ])
kaaos_build <- kaaos_build[-1, ] 

# 2. Load Sotu Mapping
sotu_path <- file.path(DATA_ROOT, "paper_02", "sotut.xlsx")
sotu <- read_excel(sotu_path)

# 3. Load Target Panel (if exists)
panel_path <- file.path(DATA_ROOT, "derived", "aim2_panel.csv")
if (file.exists(panel_path)) {
  panel <- read_csv(panel_path)
} else {
  panel <- NULL
}

cat("\n--- ID Forensics ---\\n")

# Force both to character for comparison
kaaos_nro <- as.character(kaaos_build$NRO)
sotu_nro <- as.character(sotu$NRO)

cat("N in KAAOS:", length(kaaos_nro), "\n")
cat("N in Sotu mapping:", length(sotu_nro), "\n")
cat("N matched (NRO):", length(intersect(kaaos_nro, sotu_nro)), "\n")

# Check for Sotu/id formatting
if (!is.null(panel)) {
  cat("\n--- Panel (aim2_panel.csv) analysis ---\\n")
  panel_ids <- as.character(unique(panel$id))
  sotu_ids <- as.character(unique(sotu$Sotu))
  
  in_both_ids <- intersect(panel_ids, sotu_ids)
  cat("IDs matched between Sotu file and Panel:", length(in_both_ids), "\n")
  
  # How many rows in panel have FOF_status and frailty?
  cat("Panel rows with FOF_status (not NA):", sum(!is.na(panel$FOF_status)), "\n")
  cat("Panel rows with frailty_binary (not unknown):", sum(panel$frailty_binary != "unknown"), "\n")
}

# Summary of T8_KaatumisenpelkoOn
fof_col_idx <- which(grepl("Kaatumisenpelko", colnames(kaaos_build)))
cat("\nFound Kaatumisenpelko columns in KAAOS:\n")
print(colnames(kaaos_build)[fof_col_idx])

# Check FOF values
fof_col_name <- colnames(kaaos_build)[fof_col_idx][1]
fof_vals <- kaaos_build[[fof_col_name]]
cat("\nFOF values distribution in KAAOS ( ", fof_col_name, " ):\n", sep="")
print(table(fof_vals, useNA = "always"))

# Find Frailty components: Strength (Puristusvoima), Speed (Kävelynopeus), Activity (Liikunta?)
# Audit says: 3 components (Strength, Speed, Activity).
# Let's search for these.
strength_cols <- which(grepl("Puristus", colnames(kaaos_build), ignore.case = TRUE))
speed_cols <- which(grepl("kavely", colnames(kaaos_build), ignore.case = TRUE))
activity_cols <- which(grepl("liikunta", colnames(kaaos_build), ignore.case = TRUE))

cat("\nPotential Strength columns:\n")
print(colnames(kaaos_build)[strength_cols])
cat("\nPotential Speed columns:\n")
print(colnames(kaaos_build)[speed_cols])
cat("\nPotential Activity columns:\n")
print(colnames(kaaos_build)[activity_cols])

# Anti-join reasons
cat("\nPotential mismatch reasons (NRO):\n")
if (any(grepl(".0", kaaos_nro, fixed = TRUE))) cat("- Found '.0' suffixes in KAAOS NRO\n")
if (any(grepl(".0", sotu_nro, fixed = TRUE))) cat("- Found '.0' suffixes in Sotu NRO\n")