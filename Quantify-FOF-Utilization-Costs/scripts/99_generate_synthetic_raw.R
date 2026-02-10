#!/usr/bin/env Rscript
# ==============================================================================
# 99_generate_synthetic_raw.R
# Purpose: Generate synthetic Excel files for testing ingestion.
# Wraps the Python generator for robustness with Excel writing.
# Usage: Rscript scripts/99_generate_synthetic_raw.R
# ==============================================================================

message("Calling Python generator for synthetic Excel files...")
system("python3 scripts/99_generate_synthetic_raw.py")
