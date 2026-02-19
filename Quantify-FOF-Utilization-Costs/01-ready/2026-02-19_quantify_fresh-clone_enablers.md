# Quantify-FOF-Utilization-Costs Fresh Clone Enablement (2026-02-19)

**Status:** Ready for Review
**Agent:** Jules
**Target:** Quantify-FOF-Utilization-Costs

## 1. Summary of WORKFLOW.md Compliance

I have followed the `WORKFLOW.md` guidelines for the "Execute" phase:
*   **Minimal Changes:** Only added 3 files (`requirements.txt`, `Makefile`, and this report) and updated 1 file (`README.md`).
*   **Option B (Data Governance):** Ensured no sensitive data is touched or committed. All commands use synthetic data (`--use-sample`) or CI-safe paths.
*   **Gap Analysis:** Verified that `scripts/10_preprocess_tabular.py` and `unittest` failed without dependencies, confirming the need for `requirements.txt`.
*   **Documentation:** Updated `README.md` to guide new users.

## 2. Necessity Matrix (Gap Analysis)

| Proposal | Needed? | Rationale | Evidence in Repo |
| :--- | :--- | :--- | :--- |
| **requirements.txt** | **YES** | `unittest` fails immediately due to `ModuleNotFoundError: No module named 'pandas'`. `scripts/10_preprocess_tabular.py` imports `pandas`, `numpy`. `openpyxl` needed for Excel. | `tests/test_end_to_end_smoke.py`, `scripts/10_preprocess_tabular.py` imports. |
| **Makefile** | **YES** | Standardizes "Fresh Clone" setup and testing across environments (Linux/Mac/Win). Matches pattern in `Fear-of-Falling` but simplified. | Absence of `Makefile` in subproject; `Fear-of-Falling/Makefile` exists as prior art. |
| **README.md Update** | **YES** | Current `Quickstart` commands were manual and prone to path errors. New instructions use `make` for reliability. | `Quantify-FOF-Utilization-Costs/README.md` contained manual commands. |
| **environment.yaml** | **NO** | `environment.yaml` exists for Snakemake/Conda but is heavy. `requirements.txt` provides a lightweight, standard pip alternative without altering the Conda definition. | `Quantify-FOF-Utilization-Costs/environment.yaml`. |

## 3. File Changes

### Added Files
*   `Quantify-FOF-Utilization-Costs/requirements.txt`: Minimal dependencies (`pandas`, `numpy`, `openpyxl`).
*   `Quantify-FOF-Utilization-Costs/Makefile`: Targets for `setup`, `test`, `qc`, `clean`.

### Modified Files
*   `Quantify-FOF-Utilization-Costs/README.md`: Added "Fresh Clone (CI-safe)" section.

### Git Diff (Summary)

```diff
diff --git a/Quantify-FOF-Utilization-Costs/Makefile b/Quantify-FOF-Utilization-Costs/Makefile
new file mode 100644
index 0000000..f67cf91
--- /dev/null
+++ b/Quantify-FOF-Utilization-Costs/Makefile
@@ -0,0 +1,41 @@
+SHELL := /bin/sh
+PYTHON ?= python
+VENV_DIR ?= .venv
+REQUIREMENTS ?= requirements.txt
+UV ?= uv
+
+.PHONY: help setup test qc clean
+
+help: ## Show this help.
+	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)
+
+setup: ## Setup Python environment (venv + requirements).
+	@if command -v $(UV) >/dev/null 2>&1; then \
+		$(UV) venv "$(VENV_DIR)"; \
+		$(UV) pip install -r "$(REQUIREMENTS)"; \
+	else \
+		$(PYTHON) -m venv "$(VENV_DIR)"; \
+		if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
+		elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
+		elif [ -x "$(VENV_DIR)/Scripts/python" ]; then PY_BIN="$(VENV_DIR)/Scripts/python"; \
+		else PY_BIN="$(PYTHON)"; fi; \
+		$$PY_BIN -m pip install -U pip; \
+		$$PY_BIN -m pip install -r "$(REQUIREMENTS)"; \
+	fi
+
+test: ## Run CI-safe unit tests.
+	@if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
+	elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
+	else PY_BIN="$(PYTHON)"; fi; \
+	$$PY_BIN -m unittest discover -s tests
+
+qc: ## Run smoke-run QC on synthetic sample.
+	@if [ -x "$(VENV_DIR)/bin/python" ]; then PY_BIN="$(VENV_DIR)/bin/python"; \
+	elif [ -x "$(VENV_DIR)/Scripts/python.exe" ]; then PY_BIN="$(VENV_DIR)/Scripts/python.exe"; \
+	else PY_BIN="$(PYTHON)"; fi; \
+	$$PY_BIN scripts/30_qc_summary.py --use-sample
+
+clean: ## Clean cache and outputs.
+	@rm -rf .pytest_cache .ruff_cache __pycache__ .venv 2>/dev/null || true
+	@find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
+	@rm -rf outputs/qc outputs/reports outputs/knowledge 2>/dev/null || true
diff --git a/Quantify-FOF-Utilization-Costs/README.md b/Quantify-FOF-Utilization-Costs/README.md
index 7fdcd75..fb2f2e8 100644
--- a/Quantify-FOF-Utilization-Costs/README.md
+++ b/Quantify-FOF-Utilization-Costs/README.md
@@ -24,16 +24,35 @@ Jokainen analyysiskripti sijaitsee omassa kansiossaan `R/`-hakemiston alla ja ki
 outputit sekä lokit vain omaan `outputs/` ja `logs/` -alihakemistoonsa (gitignored).
 Yhteisiä `outputs/`-hakemistoja ei käytetä.

-Quickstart (synthetic / CI-safe)
-From repo root:
+Fresh Clone (CI-safe)

-1. Run tests:
-   python -m unittest discover -s Quantify-FOF-Utilization-Costs/tests
+This subproject uses a Makefile for standard operations. These commands use synthetic data (`data/sample/`) and do not require `DATA_ROOT`.

-2. Smoke-run QC on synthetic sample:
-   python Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py --use-sample
+**Windows (PowerShell) / macOS / Linux:**

-NOTE: Run python Quantify-FOF-Utilization-Costs/scripts/00_inventory_manifest.py --scan paper_02 whenever you receive a new paper_02 data batch so the manifest stays in sync.
+1.  **Setup Python Environment:**
+    ```bash
+    cd Quantify-FOF-Utilization-Costs
+    make setup
+    ```
+
+2.  **Run Tests (CI-safe):**
+    ```bash
+    make test
+    ```
+    *Verifies Python scripts and security guardrails.*
+
+3.  **Run Smoke QC (Sample Data):**
+    ```bash
+    make qc
+    ```
+    *Generates non-sensitive QC reports in `outputs/qc/`.*
+
+Legacy commands (from repo root):
+*   Run tests: `python -m unittest discover -s Quantify-FOF-Utilization-Costs/tests`
+*   Smoke-run QC: `python Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py --use-sample`
+
+NOTE: Run `python scripts/00_inventory_manifest.py --scan paper_02` (from subproject dir) whenever you receive a new paper_02 data batch so the manifest stays in sync.

 Quickstart (local with sensitive data)

diff --git a/Quantify-FOF-Utilization-Costs/requirements.txt b/Quantify-FOF-Utilization-Costs/requirements.txt
new file mode 100644
index 0000000..e79054d
--- /dev/null
+++ b/Quantify-FOF-Utilization-Costs/requirements.txt
@@ -0,0 +1,3 @@
+pandas>=2.2.0
+numpy
+openpyxl
```

## 4. Fresh Clone Commands

**Prerequisites:**
*   Python 3.10+
*   Make (optional, but recommended. If missing, follow `Legacy commands` in README).

**Steps (Windows PowerShell / macOS / Linux):**

1.  **Navigate to subproject:**
    ```bash
    cd Quantify-FOF-Utilization-Costs
    ```

2.  **Setup:**
    ```bash
    make setup
    ```

3.  **Run CI-safe Verification:**
    ```bash
    make test
    make qc
    ```

## 5. Smoke-Run Verification

I verified the changes in the sandbox environment:

1.  **`make setup`**: Successfully created `.venv` and installed `pandas`, `numpy`, `openpyxl` (via `uv` or `pip`).
2.  **`make test`**: Ran `unittest discover`.
    *   **Result:** `Ran 17 tests in 5.225s OK`.
    *   **Success:** All tests passed (previously 1 failure due to missing pandas).
3.  **`make qc`**: Ran `scripts/30_qc_summary.py --use-sample`.
    *   **Result:** Wrote 7 CSV files to `outputs/qc/`.
    *   **Success:** Output files generated correctly.

## 6. What was NOT Changed

*   **`environment.yaml`**: Left as-is to support existing Conda/Snakemake workflows without disruption. `requirements.txt` is provided as the lightweight alternative.
*   **Scripts**: No Python or R scripts were modified. Changes were purely infrastructural.
