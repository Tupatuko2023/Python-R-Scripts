Quantify-FOF-Utilization-Costs

Aim 2: Quantify FOF-related health-service utilisation and costs (Finland, MFFP cohort + register linkage by controllers).

Data governance (Option B)

- No raw, decrypted, or participant-level register data is stored in this Git repository.
- Raw inputs must live outside the repo in a secure location (set DATA_ROOT).
- This repo contains only: metadata (manifest + dictionaries), schemas, documentation, synthetic test data, and pipeline scripts.

Project layout

- data/: metadata + synthetic samples (CI-safe)
- data/external/: placeholder only (gitignored)
- manifest/: dataset manifest + run logs (metadata only)
- scripts/: pipeline skeleton (safe-by-default)
- outputs/: generated QC/aggregate artifacts (ignored)
- tests/: CI-safe tests using synthetic sample only

Quickstart (synthetic / CI-safe)
From repo root:

1. Run tests:
   python -m unittest discover -s Quantify-FOF-Utilization-Costs/tests

2. Smoke-run QC on synthetic sample:
   python Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py --use-sample

NOTE: Run python Quantify-FOF-Utilization-Costs/scripts/00_inventory_manifest.py --scan paper_02 whenever you receive a new paper_02 data batch so the manifest stays in sync.

Quickstart (local with sensitive data)

1. Create Quantify-FOF-Utilization-Costs/config/.env from .env.example
2. Set DATA_ROOT to your secure repo-external data location (controller/permit compliant)
3. Inventory external files (metadata only; no copy into repo):
   python Quantify-FOF-Utilization-Costs/scripts/00_inventory_manifest.py --scan paper_02

If data is missing, scripts will exit with actionable instructions.

## Execution Environments

This subproject supports two primary execution environments:

*   **Windows (Standard):** Uses PowerShell 7.0. Follow the guidelines in `GEMINI.md`.
*   **Android (Termux):** Uses Bash and `termux-wake-lock`. Follow the guidelines in `GEMINI_TERMUX.md`.
    *   **Note:** In Termux, the Python-based builder (`scripts/build_real_panel.py`) is used instead of the R-based builder to prevent memory-related segmentation faults.

How to obtain data (high level)
Register linkage and extraction are handled by designated controllers under permits. This repo intentionally does not encode sensitive locations, keys, or any participant-level data.

## Aim 2 Analysis Pipeline (Panel Data)

**Status:** Ready for Data (R Scripts)

1. **Environment Setup:**
   `Rscript scripts/00_setup_env.R`
   (Initializes `renv` and installs dependencies: tidyverse, MASS, sandwich, etc.)
2. **Data Build (Secure):**
   *   **Windows:** `Rscript scripts/10_build_panel_person_period.R`
   *   **Android (Termux):** `python scripts/build_real_panel.py`
   (Reads `DATA_ROOT`, applies `data/VARIABLE_STANDARDIZATION.csv`, saves `derived/aim2_panel.csv`)
3. **Quality Control:**
   `Rscript scripts/20_qc_panel_summary.R`
   (Checks derived panel for logical consistency and zeros; outputs to `outputs/qc_summary_aim2.txt`)
4. **Modeling (NB & Gamma):**
   `Rscript scripts/30_models_panel_nb_gamma.R`
   (Runs Negative Binomial and Gamma models, performs cluster bootstrap, and saves aggregate results to `outputs/panel_models_summary.csv`)

## Handoff complete

Operational docs and CI-safe verification are in place:

- Runbook: docs/runbook.md
- Checklist: docs/checklist.md
- End-to-end smoke test (sample pipeline):
  - python -m unittest Quantify-FOF-Utilization-Costs.tests.test_end_to_end_smoke
- Build an agent-ready knowledge package (gitignored outputs):
  - python scripts/40_build_knowledge_package.py
  - Optional include derived text: python scripts/40_build_knowledge_package.py --include-derived

Reminder: after each new paper_02 batch, update the manifest inventory:

- python scripts/00_inventory_manifest.py --scan paper_02

## Documentation & Standards

- **Agent & Dev Rules:** [CLAUDE.md](CLAUDE.md) (Read this first!)
- **Analysis Plan:** [docs/ANALYSIS_PLAN.md](docs/ANALYSIS_PLAN.md)
- **Data Dictionary Workflow:** [docs/DATA_DICTIONARY_WORKFLOW.md](docs/DATA_DICTIONARY_WORKFLOW.md)
