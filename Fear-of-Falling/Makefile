SHELL := /bin/sh
R ?= R
RSCRIPT ?= Rscript
PYTHON ?= python
UV ?= uv
VENV_DIR ?= .venv
PYPROJECT ?= pyproject.toml
RENV_LOCK ?= renv.lock
LINTR_CONFIG ?= .lintr
TEST_SCRIPT ?= tests/run_smoke_tests.R

.PHONY: help all check-tools setup setup-r setup-py lint lint-r lint-py format format-r format-py test test-r test-py \
validate run analyze report clean clean-cache clean-outputs fof-preflight

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "Examples:"
	@echo "  make setup"
	@echo "  make lint"
	@echo "  make test"
	@echo "  make run RUN_SCRIPT=R-scripts/K16/K16.R"
	@echo "  make report REPORT=path/to/report.qmd"

all: setup lint test validate ## Run setup, lint, test, validate.

check-tools: ## Check required tools (R/Rscript).
	@command -v $(R) >/dev/null 2>&1 || { echo "ERROR: R not found in PATH."; exit 1; }
	@command -v $(RSCRIPT) >/dev/null 2>&1 || { echo "ERROR: Rscript not found in PATH."; exit 1; }

setup: check-tools setup-r setup-py ## Setup R and (optional) Python.

setup-r: ## Restore renv environment (requires renv.lock).
	@if [ ! -f "$(RENV_LOCK)" ]; then \
		echo "ERROR: $(RENV_LOCK) not found. Ensure renv is used in this subproject."; \
		exit 1; \
	fi
	@$(RSCRIPT) -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv'); renv::restore(); renv::status()"

setup-py: ## Setup Python (uv if available; else venv + pip).
	@if [ -f "$(PYPROJECT)" ]; then \
		if command -v $(UV) >/dev/null 2>&1; then \
			$(UV) sync; \
		else \
			$(PYTHON) -m venv "$(VENV_DIR)"; \
			if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
			elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
			elif [ -x "$(VENV_DIR)/Scripts/python" ]; then PY_BIN="$(VENV_DIR)/Scripts/python"; \
			else PY_BIN="$(PYTHON)"; fi; \
			$$PY_BIN -m pip install -U pip; \
			$$PY_BIN -m pip install ruff pytest; \
		fi; \
	else \
		req_file=$$(ls requirements*.txt 2>/dev/null | head -n 1); \
		if [ -n "$$req_file" ]; then \
			$(PYTHON) -m venv "$(VENV_DIR)"; \
			if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
			elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
			elif [ -x "$(VENV_DIR)/Scripts/python" ]; then PY_BIN="$(VENV_DIR)/Scripts/python"; \
			else PY_BIN="$(PYTHON)"; fi; \
			$$PY_BIN -m pip install -U pip; \
			$$PY_BIN -m pip install -r "$$req_file"; \
		else \
			echo "INFO: No Python config found (pyproject.toml/requirements*.txt). Skipping Python setup."; \
		fi; \
	fi

lint: check-tools lint-r lint-py ## Run R and Python lint.

lint-r: ## Run lintr (installs lintr if missing).
	@if [ ! -f "$(LINTR_CONFIG)" ]; then \
		echo "INFO: $(LINTR_CONFIG) not found; lintr will use defaults."; \
	fi
	@$(RSCRIPT) -e "if (!requireNamespace('lintr', quietly = TRUE)) install.packages('lintr'); lintr::lint_dir('.')"

lint-py: ## Run ruff lint if Python config exists.
	@if [ -f "$(PYPROJECT)" ] || ls requirements*.txt >/dev/null 2>&1; then \
		if command -v $(UV) >/dev/null 2>&1; then \
			$(UV) run -- ruff --version >/dev/null 2>&1 || { echo "ERROR: ruff not installed. Run 'make setup-py'."; exit 1; }; \
			$(UV) run -- ruff check .; \
		else \
			if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
			elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
			elif [ -x "$(VENV_DIR)/Scripts/python" ]; then PY_BIN="$(VENV_DIR)/Scripts/python"; \
			else PY_BIN="$(PYTHON)"; fi; \
			$$PY_BIN -m ruff --version >/dev/null 2>&1 || { echo "ERROR: ruff not installed. Run 'make setup-py'."; exit 1; }; \
			$$PY_BIN -m ruff check .; \
		fi; \
	else \
		echo "INFO: No Python config found. Skipping Python lint."; \
	fi

format: format-r format-py ## Run formatters (R and Python).

format-r: ## Run styler (fails if styler not installed).
	@$(RSCRIPT) -e "if (!requireNamespace('styler', quietly = TRUE)) stop('styler not installed; install.packages(\"styler\")'); styler::style_dir('.')"

format-py: ## Run ruff format if Python config exists.
	@if [ -f "$(PYPROJECT)" ] || ls requirements*.txt >/dev/null 2>&1; then \
		if command -v $(UV) >/dev/null 2>&1; then \
			$(UV) run -- ruff --version >/dev/null 2>&1 || { echo "ERROR: ruff not installed. Run 'make setup-py'."; exit 1; }; \
			$(UV) run -- ruff format .; \
		else \
			if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
			elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
			elif [ -x "$(VENV_DIR)/Scripts/python" ]; then PY_BIN="$(VENV_DIR)/Scripts/python"; \
			else PY_BIN="$(PYTHON)"; fi; \
			$$PY_BIN -m ruff --version >/dev/null 2>&1 || { echo "ERROR: ruff not installed. Run 'make setup-py'."; exit 1; }; \
			$$PY_BIN -m ruff format .; \
		fi; \
	else \
		echo "INFO: No Python config found. Skipping Python format."; \
	fi

test: check-tools test-r test-py ## Run tests (R + optional Python).

test-r: ## Run R smoke tests (requires TEST_SCRIPT file).
	@if [ ! -f "$(TEST_SCRIPT)" ]; then \
		echo "ERROR: TEST_SCRIPT not found: $(TEST_SCRIPT). Set TEST_SCRIPT=path/to/test.R"; \
		exit 1; \
	fi
	@$(RSCRIPT) "$(TEST_SCRIPT)"

test-py: ## Run pytest if Python config exists.
	@if [ -f "$(PYPROJECT)" ] || ls requirements*.txt >/dev/null 2>&1; then \
		if command -v $(UV) >/dev/null 2>&1; then \
			$(UV) run -- pytest --version >/dev/null 2>&1 || { echo "ERROR: pytest not installed. Run 'make setup-py'."; exit 1; }; \
			$(UV) run -- pytest; \
		else \
			if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
			elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
			elif [ -x "$(VENV_DIR)/Scripts/python" ]; then PY_BIN="$(VENV_DIR)/Scripts/python"; \
			else PY_BIN="$(PYTHON)"; fi; \
			$$PY_BIN -m pytest --version >/dev/null 2>&1 || { echo "ERROR: pytest not installed. Run 'make setup-py'."; exit 1; }; \
			$$PY_BIN -m pytest; \
		fi; \
	else \
		echo "INFO: No Python config found. Skipping Python tests."; \
	fi

validate: run ## Validate by running RUN_SCRIPT via Rscript.

run analyze: check-tools ## Run analysis with RUN_SCRIPT=path/to/script.R (required).
	@if [ -z "$(RUN_SCRIPT)" ]; then \
		echo "ERROR: RUN_SCRIPT is required (e.g., make run RUN_SCRIPT=R-scripts/K16/K16.R)."; \
		exit 1; \
	fi
	@if [ ! -f "$(RUN_SCRIPT)" ]; then \
		echo "ERROR: RUN_SCRIPT not found: $(RUN_SCRIPT)"; \
		exit 1; \
	fi
	@$(RSCRIPT) "$(RUN_SCRIPT)"

frailty_balance: check-tools ## Run K15.3 frailty with balance (outputs to R-scripts/K15/outputs)
	@$(RSCRIPT) R-scripts/K15/K15.3.frailty_n_balance.R

test-k15-3: ## Run K15.3 smoke test
	@$(RSCRIPT) tests/test_K15.3.R

fof-preflight: ## Run diff-aware FOF preflight checker
	@bash scripts/fof-preflight.sh

report: check-tools ## Render report with REPORT=path/to/report.qmd|Rmd (required).
	@if [ -z "$(REPORT)" ]; then \
		echo "ERROR: REPORT is required (e.g., make report REPORT=reports/report.qmd)."; \
		exit 1; \
	fi
	@if [ ! -f "$(REPORT)" ]; then \
		echo "ERROR: REPORT not found: $(REPORT)"; \
		exit 1; \
	fi
	@case "$(REPORT)" in \
		*.qmd) \
			command -v quarto >/dev/null 2>&1 || { echo "ERROR: quarto not found in PATH."; exit 1; }; \
			quarto render "$(REPORT)"; \
			;; \
		*.Rmd) \
			$(RSCRIPT) -e "rmarkdown::render('$(REPORT)')"; \
			;; \
		*) \
			echo "ERROR: REPORT must end with .qmd or .Rmd"; \
			exit 1; \
			;; \
	esac

clean-cache: ## Remove caches only (POSIX rm/find).
	@echo "Cleaning caches (POSIX-only rm/find)."
	@rm -rf .pytest_cache 2>/dev/null || true
	@rm -rf .ruff_cache 2>/dev/null || true
	@rm -rf .Rhistory 2>/dev/null || true
	@rm -rf .RData 2>/dev/null || true
	@rm -rf .Rproj.user 2>/dev/null || true
	@rm -rf renv/.cache 2>/dev/null || true
	@find . -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true

clean-outputs: ## Remove outputs (explicit; never touches data/).
	@echo "Removing outputs (explicit)."
	@if command -v find >/dev/null 2>&1; then \
		rm -rf outputs; \
		find R-scripts -type d -name outputs -print -exec rm -rf {} + 2>/dev/null || true; \
	else \
		rm -rf outputs 2>/dev/null || true; \
		echo "INFO: 'find' not available. Only removed ./outputs."; \
		echo "INFO: Windows: remove subfolder outputs under R-scripts manually if needed."; \
	fi

clean: clean-cache ## Clean caches; set CLEAN_OUTPUTS=1 to remove outputs.
	@if [ "$(CLEAN_OUTPUTS)" = "1" ]; then \
		$(MAKE) clean-outputs; \
	else \
		echo "INFO: Outputs not removed. Use CLEAN_OUTPUTS=1 to remove outputs."; \
	fi
