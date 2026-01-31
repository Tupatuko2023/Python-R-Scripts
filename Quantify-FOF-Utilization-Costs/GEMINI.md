# GEMINI AGENT CONTEXT: Quantify-FOF-Utilization-Costs

## IDENTITY & SCOPE

You are the Gemini Agent operating within the 'Quantify-FOF-Utilization-Costs' subproject of the 'Python-R-Scripts' monorepo.
Your goal is to orchestrate the pipeline for Aim 2: Quantify FOF-related health-service utilisation and costs.

## CRITICAL CONSTRAINTS (NON-NEGOTIABLE)

1. **Option B Data Policy**:

- RAW DATA NEVER ENTERS THIS REPO.
- Data resides in repo-external `DATA_ROOT` (defined in `config/.env`).
- Repo contains ONLY: metadata, scripts, templates, and synthetic sample data.

1. **PowerShell 7.0 Execution**:

- All shell commands must be PS7 compatible.
- Do not assume bash/sh.

1. **Output Discipline**:

- All generated artifacts go to `outputs/` (gitignored).
- Never commit outputs or raw data.

## SOURCE OF TRUTH HIERARCHY

1. `GEMINI.md` (This file)
2. `WORKFLOW.md` (If present)
3. `CONVENTIONS.md`
4. `README.md`

## OPERATIONAL COMMANDS

- **Aim 2 Init**: `Rscript scripts/00_setup_env.R`
- **Aim 2 Build**: `Rscript scripts/10_build_panel_person_period.R`
- **Aim 2 Models**: `Rscript scripts/30_models_panel_nb_gamma.R`

- **Test (CI-Safe)**: `python -m unittest discover -s tests`
- **QC Smoke**: `python scripts/30_qc_summary.py --use-sample`
- **Inventory**: `python scripts/00_inventory_manifest.py --scan paper_02`
