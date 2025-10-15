# Getting Started

This guide boots the project in 10 minutes. The repo includes only synthetic data. No PHI.

## Prerequisites
- Windows 10 or 11
- VS Code
- Conda or Miniconda
- R 4.x
- Quarto 1.8.x
- Node LTS for markdownlint
- TinyTeX for PDF output [TODO: add link]

## Folder map
- docs: documentation and this guide
- report: Quarto reports
- env: environment descriptors
- notebooks: analysis notebooks
- docs/SYNTHETIC_DEMO: synthetic CSV and demo scripts

## Python setup and demo
    conda env create -f env\environment.yml
    conda activate efi
    python docs\SYNTHETIC_DEMO\demo_py.py

## R setup and demo
    install.packages("renv")
    renv::init()
    source("docs/SYNTHETIC_DEMO/demo_r.R")

## Build docs
    quarto render docs\PHDSUM_efi_progress_2024_summary.md --to html --output-dir docs
    quarto render docs\PHDSUM_efi_progress_2024_summary.md --to pdf  --output-dir docs

## Lint markdown
    markdownlint .

Links
- Reproducibility: docs/REPRODUCIBILITY.md