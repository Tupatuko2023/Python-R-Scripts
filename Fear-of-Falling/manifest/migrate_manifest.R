#!/usr/bin/env Rscript
# Manifest Migration Script - Clean Migration (Option 1)
# Date: 2025-12-21
# Purpose: Restructure manifest.csv to match manifest_row() output format

# Paths
manifest_backup <- "manifest_backup_20251221.csv"
manifest_legacy <- "manifest_legacy.csv"
manifest_new    <- "manifest.csv"

cat("Reading backup manifest...\n")
# Read the backup using base R
df <- read.csv(manifest_backup, stringsAsFactors = FALSE, na.strings = c("NA", ""))

cat("Total rows read:", nrow(df), "\n")
cat("Current columns:", paste(names(df), collapse = ", "), "\n\n")

# Extract legacy rows (1-41) - these are the first 41 data rows
cat("Extracting legacy rows (1-41)...\n")
legacy_data <- df[1:41, ]
write.csv(legacy_data, manifest_legacy, row.names = FALSE, na = "NA")
cat("Legacy rows saved to:", manifest_legacy, "\n")
cat("Legacy rows count:", nrow(legacy_data), "\n\n")

# Extract new format rows (42+)
cat("Extracting correct format rows (42+)...\n")
new_data <- df[42:nrow(df), ]
cat("New format rows count:", nrow(new_data), "\n\n")

# Restructure: select only the correct columns in correct order
# Expected: timestamp, script, label, kind, path, n, notes
cat("Restructuring to correct column order...\n")
new_manifest <- new_data[, c("timestamp", "script", "label", "kind", "path", "n", "notes")]

cat("New manifest structure:\n")
cat("Columns:", paste(names(new_manifest), collapse = ", "), "\n")
cat("Rows:", nrow(new_manifest), "\n\n")

# Write new manifest
cat("Writing new manifest to:", manifest_new, "\n")
write.csv(new_manifest, manifest_new, row.names = FALSE, na = "NA")

cat("\n=== Migration Complete ===\n")
cat("Backup:      ", manifest_backup, "\n")
cat("Legacy:      ", manifest_legacy, "(41 rows)\n")
cat("New manifest:", manifest_new, "(", nrow(new_manifest), "rows)\n")
cat("\nNew header: timestamp,script,label,kind,path,n,notes\n")
