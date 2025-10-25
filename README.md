# Python and R Scripts

![python-ci](https://github.com/Tupatuko2023/Python-R-Scripts/actions/workflows/python-ci.yml/badge.svg)
![r-ci](https://github.com/Tupatuko2023/Python-R-Scripts/actions/workflows/r-ci.yml/badge.svg)

This repository contains Python and R projects for data analysis and research
workflows. Each subfolder is a standalone project with its own docs.

## Main project

- [Electronic Frailty Index](Electronic-Frailty-Index/README.md)

## Quick start

```bash
python src/efi/cli.py \
  --input data/external/synthetic_patients.csv \
  --out out/efi_scores.csv \
  --report-md out/report.md
```

## License and citation

- License: [MIT License](LICENSE)
- How to cite: [CITATION.cff](CITATION.cff)

## Disclaimer

See [DISCLAIMER.md](DISCLAIMER.md). No PHI or PII in this repository.

## Layout (high level)

```text
├─ Electronic-Frailty-Index/
│  ├─ docs/                   # EFI documentation and reports
│  ├─ env/                    # conda environment
│  ├─ figures/                # images and figures
│  ├─ BMI/                    # BMI features and scripts
│  ├─ CCI/                    # CCI features and scripts
│  ├─ HFRS/                   # HFRS features and scripts
│  └─ logistic_regression/    # logistic regression models and scripts
├─ src/efi/                   # Python CLI
├─ data/external/             # synthetic example data
├─ tests/                     # pytest tests
├─ .github/workflows/         # continuous integration workflows
└─ out/                       # outputs, ignored in VCS
```
