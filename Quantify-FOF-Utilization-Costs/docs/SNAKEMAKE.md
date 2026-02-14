# Snakemake Workflow for Quantify-FOF-Utilization-Costs

This document outlines the usage of Snakemake for orchestrating the Aim 2 analysis pipeline.

## Overview

The pipeline automates the steps from data inventory to report generation, ensuring reproducibility and managing dependencies. It uses a Conda environment for Snakemake and Python dependencies, while leveraging `renv` for R package management.

### Pipeline Steps (DAG)

1.  **Inventory**: Scans the `DATA_ROOT` directory and updates `manifest/run_log.csv`.
2.  **Preprocess**: ETL of raw data into `outputs/intermediate/analysis_ready.csv`.
3.  **QC**: Generates QC summaries in `outputs/qc/`.
4.  **Models**: Runs statistical models (Negative Binomial / Gamma) and outputs `outputs/panel_models_summary.csv`.
5.  **Report**: Compiles the final Aim 2 report (`outputs/reports/aim2_report.md`).

## Prerequisites

- **Conda/Mamba**: Install [Miniforge](https://github.com/conda-forge/miniforge) or Anaconda.
- **R**: Ensure R (>= 4.0) is installed and `renv` is initialized (`renv::restore()`).
- **WSL2 (Windows)**: Recommended environment for Windows users.

## Setup

1.  **Navigate to the subproject:**

    ```bash
    cd Quantify-FOF-Utilization-Costs
    ```

2.  **Create the environment:**

    ```bash
    mamba env create -f environment.yaml
    ```

3.  **Activate the environment:**
    ```bash
    mamba activate snakemake-fof
    ```

## Configuration

Edit `config/config.yaml` to customize settings:

- `data_root`: Path to raw data (default: `../data/external`).
- `allow_aggregates`: Set to `True` to enable aggregate outputs.

## Running the Workflow

1.  **Dry-run (check execution plan):**

    ```bash
    snakemake -n
    ```

2.  **Execute (run on 1 core):**

    ```bash
    snakemake -j 1
    ```

3.  **Visualize the DAG:**
    ```bash
    snakemake --dag | dot -Tpng > dag.png
    ```

## Troubleshooting

- **Renv issues**: Always run Snakemake from the `Quantify-FOF-Utilization-Costs/` root to ensure `.Rprofile` loads the correct R library.
- **Missing Data**: Verify `DATA_ROOT` points to a valid directory containing `KaatumisenPelko.csv` or other required files.
- **Permission Denied**: Check file permissions for scripts (ensure `chmod +x` if running directly, though Snakemake handles python/Rscript calls).

## Bridging (Conda + Renv)

This workflow uses a "bridge" strategy:

- **Snakemake** runs in a Conda environment.
- **Python scripts** run in the same Conda environment.
- **R scripts** run using the system R installation, but `renv` ensures project-specific packages are used. The `Rscript` command is invoked from the shell, respecting the `.Rprofile` in the project root.
