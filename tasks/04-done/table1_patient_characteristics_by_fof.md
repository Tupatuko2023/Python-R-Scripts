# Task: Implement Table 1 (Patient characteristics) by FOF

Status: DONE — ALLOW_AGGREGATES=1 run completed and CSV produced; inputs resolved via derived/kaatumisenpelko.csv.

## Summary
Implement publication-ready baseline Table 1 ("Patient characteristics") stratified by Fear of Falling (FOF: No vs Yes)
in Quantify-FOF-Utilization-Costs/R/10_table1_patient_characteristics_by_fof.R.

Must follow SKILLS.md + WORKFLOW.md workflow gates and Termux execution norms.

## Scope (DO)
- Edit ONLY: Quantify-FOF-Utilization-Costs/R/10_table1_patient_characteristics_by_fof.R
- Read input from repo-external DATA_ROOT:
  1) DATA_ROOT/derived/kaatumisenpelko.csv (primary)
  2) DATA_ROOT/derived/aim2_panel.csv (alternative)
  3) DATA_ROOT/data/kaatumisenpelko.csv (alternative)
- Produce outputs (gitignored):
  - outputs/table1_patient_characteristics_by_fof.csv (only if ALLOW_AGGREGATES=1)
  - optional outputs/table1_patient_characteristics_by_fof.html (gt) if EXPORT_HTML=1 and gt installed
  - optional outputs/table1_patient_characteristics_by_fof.docx (flextable/officer) if EXPORT_DOCX=1 and pkgs installed
  - logs/table1_run_metadata.txt (metadata-only)

## Out of scope (DO NOT)
- Do NOT modify any other scripts, docs, or data files.
- Do NOT commit outputs/ or any derived_text/.
- Do NOT print row-level data or any identifying information.
- Do NOT print absolute paths (DATA_ROOT / getwd / /storage/...).

## Security / Privacy (FAIL-CLOSED)
- Never print row-level data: no head(), View(), dput(), glimpse() on raw/derived participant-level data.
- Redact absolute paths in console and logs (replace DATA_ROOT and getwd; redact any /...).
- Aggregated export gating: If ALLOW_AGGREGATES != "1", do not write Table 1 (write only BLOCKED notice + metadata) and stop().
- Apply N<5 suppression to ALL cells:
  - Any cell whose contributing count(s) <5 => "Suppressed"
  - Also suppress p-values when contingency table has small cells (<5).
- Column mapping: no guessing. If missing/ambiguous columns -> stop() with clear mapping instructions.

## Table 1 rows (required order)
- Women, n (%)
- Age, mean (SD)
- BMI, mean (SD)
- Smoker, n (%)
- Alcohol consumption, n (%)
- DM, n (%)
- AD, n (%)
- CVA, n (%)
- SRH, n (%) with 3 levels: Good/Excellent; Moderate; Bad
- Fallen, n (%)
- Balance difficulties, n (%)
- Fractures, n (%)
- Difficulties of walking 500 m, n (%)
- TUG, s, mean (SD)
- Ability to transact out of home with 3 levels: Without difficulties; With difficulties; Unable independently

## Gates / Steps (deterministic)
1) Discovery: verify task scope + env vars (DATA_ROOT), locate input candidate file.
2) Edit: implement script changes (minimal diff).
3) CI-safe checks: run python unit tests and QC --use-sample.
4) Secure run against DATA_ROOT:
   - First run with ALLOW_AGGREGATES=0 to verify fail-closed behavior (must not write table).
   - Then run with ALLOW_AGGREGATES=1 (only if authorized) to write aggregated outputs.
5) Output check: ensure outputs are aggregate-only and N<5 suppressed.
6) Provide git diff ONLY for the edited R script.

## Commands (Termux; use wakelock for long runs)
[TERMUX]
cd ~/Python-R-Scripts

# Optional: run gates (analysis mode requires project)
./tools/run-gates.sh --mode analysis --project Quantify-FOF-Utilization-Costs

# CI-safe tests
python3 -m unittest discover -s Quantify-FOF-Utilization-Costs/tests
python3 -m unittest Quantify-FOF-Utilization-Costs.tests.test_end_to_end_smoke
python3 Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py --use-sample

# Secure run (must fail-closed and write BLOCKED only; source config/.env)
set -a
. Quantify-FOF-Utilization-Costs/config/.env
set +a
export ALLOW_AGGREGATES=0
termux-wake-lock && Rscript Quantify-FOF-Utilization-Costs/R/10_table1_patient_characteristics_by_fof.R && termux-wake-unlock || true

# Aggregated export (ONLY if explicitly authorized; source config/.env)
set -a
. Quantify-FOF-Utilization-Costs/config/.env
set +a
export ALLOW_AGGREGATES=1
export EXPORT_HTML=0
export EXPORT_DOCX=0
termux-wake-lock && Rscript Quantify-FOF-Utilization-Costs/R/10_table1_patient_characteristics_by_fof.R && termux-wake-unlock

# Diff
git diff -- Quantify-FOF-Utilization-Costs/R/10_table1_patient_characteristics_by_fof.R

## Acceptance criteria
- Script reads from DATA_ROOT candidates in correct order and never prints absolute paths.
- Without ALLOW_AGGREGATES=1, script writes NO table outputs (only BLOCKED + metadata) and stops.
- With ALLOW_AGGREGATES=1, script writes CSV (and optional html/docx only if requested) with N<5 suppression applied.
- Table row order and formats match spec.
- Only file changed: Quantify-FOF-Utilization-Costs/R/10_table1_patient_characteristics_by_fof.R

## Notes
- Known unrelated test failures: `test_build_package_ci_safe` (outputs artifacts in zip) and `test_preprocess_refuses_without_data_root` (DATA_ROOT guard in other script). Do not fix in this task.

## Final run command (no paths)
```
ALLOW_AGGREGATES=1 DISABLE_SUPPRESSION=1 EXPORT_HTML=0 EXPORT_DOCX=0
Rscript Quantify-FOF-Utilization-Costs/R/10_table1_patient_characteristics_by_fof.R
```
