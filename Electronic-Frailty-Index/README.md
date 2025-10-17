# Project purpose & eFI overview

This repository reports how I participated in developing a Finnish
**electronic Frailty Index (eFI)** by combining **text-derived deficits** from
FinBERT-based clinical NER with **structured** EHR data (ICD‑10, labs). In
Central Finland EHRs (102,525 patients; 10.6 M notes), NER achieved F1 ≥ 0.81
and outperformed ICD‑10 for detecting falls and incontinence; NER-based onsets
were more predictive of mortality.

## 2024 Progress Report

See [PHDSUM_efi_progress_2024_summary.md](./docs/PHDSUM_efi_progress_2024_summary.md)

## Quickstart

## Electronic Frailty Index — quickstart

See also:

- [GETTING_STARTED.md](./docs/GETTING_STARTED.md)
- [REPRODUCIBILITY.md](./docs/REPRODUCIBILITY.md)

### Run the synthetic demo

```bash
conda env create -f [environment.yml](http://_vscodecontentref_/0)
conda activate efi
python [demo_py.py](http://_vscodecontentref_/1)
```

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
