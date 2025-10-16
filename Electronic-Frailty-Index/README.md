# Project purpose & eFI overview
This repository develops a Finnish **electronic Frailty Index (eFI)** by combining **text-derived deficits** from FinBERT-based clinical NER with **structured** EHR data (ICD‑10, labs). In Central Finland EHRs (102,525 patients; 10.6 M notes), NER achieved F1 ≥ 0.81 and outperformed ICD‑10 for detecting falls and incontinence; NER-based onsets were more predictive of mortality. fileciteturn3file7 fileciteturn3file8 fileciteturn3file5

## 2024 Progress Report
See `docs/PHDSUM_efi_progress_2024_summary.md`.

# Quickstart

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


### Windows (PowerShell)

```powershell
Set-Location "C:/GitWork/Python-R-Scripts/Electronic-Frailty-Index"
quarto render .\report\efi_2024_progress.qmd
```

### Linux/macOS (bash)

```bash
cd /path/to/Python-R-Scripts/Electronic-Frailty-Index
quarto render ./report/efi_2024_progress.qmd
```

See also: [GETTING_STARTED.md](./docs/GETTING_STARTED.md)
