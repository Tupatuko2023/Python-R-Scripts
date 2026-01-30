# Project Configuration — Quantify FOF Utilization & Costs — R/Python Hybrid Pipeline

## CRITICAL RULES (NON-NEGOTIABLE)

1. **Option B Data Governance:**
   - **NO RAW DATA IN GIT.** All data reading must occur via `DATA_ROOT` path resolution.
   - Repo contains only metadata, schemas, documentation, and synthetic test data.
   - Do not paste sample rows of real participant data into issues or comments.

2. **No "Guessing" (Finnish Metadata Protocol):**
   - Do not translate variable names or values from Finnish to English based on intuition.
   - Use `data/VARIABLE_STANDARDIZATION.csv` as the source of truth.
   - If a term is missing, follow `docs/DATA_DICTIONARY_WORKFLOW.md`: Mark as `INFERRED`, request confirmation, then freeze.

3. **Reproducibility:**
   - **R:** Use `renv` (lockfile).
   - **Python:** Use `requirements.txt` / `pyproject.toml`.
   - **Randomness:** Use `set.seed(20250130)` (or project standard) only when necessary (bootstrapping, simulation).

4. **Output Discipline:**
   - All artifacts (plots, tables) must go to `outputs/` (or script-specific `outputs/`).
   - Every artifact generation must be logged in `manifest/dataset_manifest.csv` (File, Date, Script, Hash) and run metadata appended to `manifest/run_log.csv`.

5. **Script Standards:**
   - **R Scripts:** Must follow the "STANDARD R SCRIPT INTRO" below.
   - **Python Scripts:** Must use `path_resolver.py` for all I/O and follow the "STANDARD PYTHON HEADER".

---

## STANDARD R SCRIPT INTRO (MANDATORY for R)

**Purpose:** Ensure every R analysis script is self-documenting, reproducible, and manifest-compliant.

### Script Naming & ID

- **Format:** `Q{number}_{name}.R` (e.g., `Q01_ingest.R`, `Q20_models.R`)
- **Tag:** `Q{number}.V{version}_{desc}.R` (e.g., `Q20.V1_poisson_model.R`)

### Copy-paste R Header Template

```r
#!/usr/bin/env Rscript
# ==============================================================================
# {{SCRIPT_ID}} - {{TITLE}}
# File tag: {{FILE_TAG}}
# Purpose: {{ONE_LINE_PURPOSE}}
#
# Outcome: {{OUTCOME}} (e.g., Total_Cost_12m, Service_Count_12m)
# Predictors: FOF_status
# Covariates: Age, Sex, BMI, Comorbidities
#
# Required vars (DO NOT INVENT; check VARIABLE_STANDARDIZATION.csv):
# {{REQUIRED_VARS}}
#
# Data Source: DATA_ROOT (Option B compliant)
#
# Reproducibility:
# - renv restore
# - seed: {{SEED}} (if needed)
#
# Outputs + manifest:
# - outputs dir: outputs/{{SCRIPT_ID}}/
# - manifest: append to manifest/dataset_manifest.csv and record runs in manifest/run_log.csv
#
# Workflow:
# 01) Init paths (path_resolver)
# 02) Load Data (DATA_ROOT)
# 03) Standardize & QC (see docs/DATA_DICTIONARY_WORKFLOW.md)
# 04) Analysis / Modeling
# 05) Save Outputs
# 06) Update Manifest
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  # library(fof.utils) # if available
})

# --- Init ---
# TODO: Source path_resolver or equivalent to get DATA_ROOT
# DATA_ROOT <- Sys.getenv("DATA_ROOT")
# if (DATA_ROOT == "") stop("DATA_ROOT not set (Option B protection)")

```

### Valid Script Checklist (R)

1. Header present and filled?
2. `DATA_ROOT` used for input? (No hardcoded local paths)
3. Variable names verified against `VARIABLE_STANDARDIZATION.csv`?
4. Manifest updated at the end?

---

## STANDARD PYTHON HEADER (MANDATORY for Python)

```python
"""
{{SCRIPT_ID}} - {{TITLE}}

Purpose: {{ONE_LINE_PURPOSE}}
Data Governance: Option B (DATA_ROOT required)

Usage:
  python {{SCRIPT_FILENAME}}
"""
import os
import sys
from pathlib import Path

# Add project root to path for imports
current_file = Path(__file__).resolve()
project_root = current_file.parents[1] # Adjust based on depth
sys.path.append(str(project_root))

from scripts.path_resolver import get_data_root, resolve_output_dir
from scripts._io_utils import update_manifest

def main():
    DATA_ROOT = get_data_root()
    # ... logic ...

if __name__ == "__main__":
    main()
```
