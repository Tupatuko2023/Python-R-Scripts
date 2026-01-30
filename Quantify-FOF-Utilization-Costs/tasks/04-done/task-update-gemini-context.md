# Task: Update GEMINI.md Operational Commands

## Status

* **Source:** Completed Aim 2 Pipeline
* **Target:** GEMINI.md

## Context

The project now relies on R scripts for Aim 2. The `GEMINI.md` "Operational Commands" section needs to include these commands so the agent can execute the pipeline efficiently.

## Instructions

Append the following lines to the `## OPERATIONAL COMMANDS` section in `GEMINI.md`:

* **Aim 2 Init**: `Rscript scripts/00_setup_env.R`
* **Aim 2 Build**: `Rscript scripts/10_build_panel_person_period.R`
* **Aim 2 Models**: `Rscript scripts/30_models_panel_nb_gamma.R`
