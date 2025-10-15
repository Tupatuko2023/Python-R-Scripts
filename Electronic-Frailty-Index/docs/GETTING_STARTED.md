# Getting Started - Windows PowerShell

This guide sets up the EFI workspace on Windows in about 10 minutes.

## Prerequisites

- Windows 10 or 11
- VS Code with Git installed
L- Conda or Miniconda
- Node LTS if you want markdownlint in CI
- Quarto 1.8.x if you plan to render reports
- R 4.x only if you run R notebooks

## Folder layout - relative to repository root

- Electronic-Frailty-Index/docs
- Electronic-Frailty-Index/env
- Electronic-Frailty-Index/notebooks
- Electronic-Frailty-Index/scripts
- Electronic-Frailty-Index/report

## 1. Create and activate the Python environment

``powershell
Set-Location C:\GitWork\Python-R-Scripts
conda env create -f .\\Electronic-Frailty-Index\Env\\environment.yml
conda activate efi_env
python --version
pip list | Select-String "pandas|numpy|jupyter|ipykernel"

```powershell

If you prefer pip-tools instead of conda, use `requirements.txt`:

``powershell
pip install -r .\\Electronic-Frailty-Index\\env\\requirements.txt
```

## 2. VS Code - recommended settings

- Default shell: PowerShell
- End of line: LF for Markdown and code
- Suggested extensions:
  - Python, Jupyter
  - Markdown All in One
  - markdownlint
  - Quarto (if you render reports)

## 3. Quarto render - optional

``powershell
Set-Location .\\Electronic-Frailty-Index\report
quarto render

```powershell

Make sure `report` contains a `_quarto.yml` and at least one `.qmd` file before rendering.

## 4. Lint Markdown locally

``powershell
npx markdownlint-cli "Electronic-Frailty-Index/**/*.md" --fix`
```

## 5. Run a notebook

``powershell
Set-Location C:\GitWork\Python-R-Scripts
jupyter lab

# open Electronic-Frailty-Index/notebooks and run cells

```powershell

Tips:
- Use forward slashes in Markdown links, for example `docs/GETTING_STARTED.md`.
- Use Windows paths in PowerShell blocks, for example `.\\Electronic-Frailty-Index\env\environment.yml`.
