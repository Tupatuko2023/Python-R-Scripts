# Makefile EFI projektin peruskomentoihin
# Riippuvuudet: conda, python, optional: ruff, black, pytest, quarto

SHELL := bash
PY := python

ENV_FILE := Electronic-Frailty-Index/env/environment.yml
DEMO := Electronic-Frailty-Index/docs/SYNTHETIC_DEMO/demo_py.py

.PHONY: help setup demo cli-run lint format test report clean

help:
	@echo "Targets:"
	@echo "  setup     - Luo conda ympäristön"
	@echo "  demo      - Aja synteettinen Python demo"
	@echo "  cli-run   - Aja EFI CLI synteettisellä datalla"
	@echo "  lint      - Ruff ja Black tarkistus jos asennettuna"
	@echo "  format    - Black muotoilu"
	@echo "  test      - pytest jos testit kansiossa"
	@echo "  report    - Quarto build jos qmd tiedostoja"
	@echo "  clean     - Poistaa out hakemiston"

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
	@if ls docs/*.qmd >/dev/null 2>&1; then quarto render docs; else echo "Ei qmd raportteja. Ohita."; fi

clean:
	rm -rf out
	rm -rf docs/_site