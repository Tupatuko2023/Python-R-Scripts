# Makefile for EFI project basic commands
# Dependencies: conda, python, optional: ruff, black, pytest, quarto

SHELL := bash
PY := python

ENV_FILE := Electronic-Frailty-Index/env/environment.yml
DEMO := Electronic-Frailty-Index/docs/SYNTHETIC_DEMO/demo_py.py

.PHONY: help setup demo cli-run lint format test report clean

help:
	@echo "Targets:"
	@echo "  setup     - Create the conda environment"
	@echo "  demo      - Run the synthetic Python demo"
	@echo "  cli-run   - Run the EFI CLI on synthetic data"
	@echo "  lint      - Ruff and Black checks if installed"
	@echo "  format    - Black formatting"
	@echo "  test      - pytest if tests/ exists"
	@echo "  report    - Quarto build if there are .qmd files"
	@echo "  clean     - Remove the out directory"

setup:
	conda env create -f $(ENV_FILE) || conda env update -f $(ENV_FILE)

demo:
	$(PY) $(DEMO)

cli-run:
	mkdir -p out
	$(PY) src/efi/cli.py --input data/external/synthetic_patients.csv --out out/efi_scores.csv

lint:
	-ruff check .
	-black --check .

format:
	-black .

test:
	-pytest -q

report:
	@if ls docs/*.qmd >/dev/null 2>&1; then quarto render docs; else echo "No .qmd reports found. Skipping."; fi

clean:
	rm -rf out
	rm -rf docs/_site