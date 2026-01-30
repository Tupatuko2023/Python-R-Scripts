# Task: Update README for Aim 2 Pipeline

## Status

* **Source:** Completed Tasks (Scripts 00-30)
* **Target:** README.md

## Context

The Aim 2 analysis code (Panel Data) is now implemented. The README needs to be updated to serve as a quick reference for running this specific pipeline.

## Instructions

Apped the following section to `README.md` (e.g., before "Handoff complete" or in a new "Analysis Pipelines" section).

### Content to Append/Insert:

## Aim 2 Analysis Pipeline (Panel Data)

**Status:** Ready for Data (R Scripts)

1. **Environment Setup:**
   `Rscript scripts/00_setup_env.R`
   (Initializes `renv` and installs dependencies: tidyverse, MASS, sandwich, etc.)
2. **Data Build (Secure):**
   `Rscript scripts/10_build_panel_person_period.R`
   (Reads `DATA_ROOT`, applies `data/VARIABLE_STANDARDIZATION.csv`, saves `derived/aim2_panel.csv`)
3. **Quality Control:**
   `Rscript scripts/20_qc_panel_summary.R`
   (Checks derived panel for logical consistency and zeros; outputs to `outputs/qc_summary_aim2.txt`)
4. **Modeling (NB & Gamma):**
   `Rscript scripts/30_models_panel_nb_gamma.R`
   (Runs Negative Binomial and Gamma models, performs cluster bootstrap, and saves aggregate results to `outputs/panel_models_summary.csv`)

---
