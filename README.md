# Python and R Scripts

Main project:
- [Electronic Frailty Index](Electronic-Frailty-Index/README.md)

Quick start:
- Open `Electronic-Frailty-Index/README.md` and follow the Quickstart section.


## Electronic Frailty Index — quickstart

See: Electronic-Frailty-Index/docs/GETTING_STARTED.md  
Reproducibility: Electronic-Frailty-Index/docs/REPRODUCIBILITY.md

### Run the synthetic demo
    conda env create -f Electronic-Frailty-Index/env/environment.yml
    conda activate efi
    python Electronic-Frailty-Index/docs/SYNTHETIC_DEMO/demo_py.py

### Build docs
    quarto render Electronic-Frailty-Index/docs/PHDSUM_efi_progress_2024_summary.md --to html --output-dir Electronic-Frailty-Index/docs
    quarto render Electronic-Frailty-Index/docs/PHDSUM_efi_progress_2024_summary.md --to pdf  --output-dir Electronic-Frailty-Index/docs