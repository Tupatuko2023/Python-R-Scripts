# Getting Started - 10 minute quickstart

Prerequisites: conda, R+renv, Quarto 1.8.x, TinyTeX [TODO], Node LTS (optional)

## Environments
conda env create -f env\environment.yml
conda activate efi
install.packages("renv"); renv::init()

## Build docs
quarto render docs\PHDSUM_efi_progress_2024_summary.md --to html --output-dir docs
quarto render docs\PHDSUM_efi_progress_2024_summary.md --to pdf  --output-dir docs

See docs\REPRODUCIBILITY.md