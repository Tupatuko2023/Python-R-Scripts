SHELL := /bin/sh
PYTHON ?= python
VENV_DIR ?= .venv
REQUIREMENTS ?= requirements.txt
UV ?= uv

.PHONY: help setup test qc clean

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Setup Python environment (venv + requirements).
	@if command -v $(UV) >/dev/null 2>&1; then \
		$(UV) venv "$(VENV_DIR)"; \
		$(UV) pip install -r "$(REQUIREMENTS)"; \
	else \
		$(PYTHON) -m venv "$(VENV_DIR)"; \
		if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
		elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
		elif [ -x "$(VENV_DIR)/Scripts/python" ]; then PY_BIN="$(VENV_DIR)/Scripts/python"; \
		else PY_BIN="$(PYTHON)"; fi; \
		$$PY_BIN -m pip install -U pip; \
		$$PY_BIN -m pip install -r "$(REQUIREMENTS)"; \
	fi

test: ## Run CI-safe unit tests.
	@if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
	elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
	else PY_BIN="$(PYTHON)"; fi; \
	$$PY_BIN -m unittest discover -s tests

qc: ## Run smoke-run QC on synthetic sample.
	@if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
	elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
	else PY_BIN="$(PYTHON)"; fi; \
	$$PY_BIN scripts/30_qc_summary.py --use-sample

clean: ## Clean cache and outputs.
	@rm -rf .pytest_cache .ruff_cache __pycache__ .venv 2>/dev/null || true
	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	@rm -rf outputs/qc outputs/reports outputs/knowledge 2>/dev/null || true
