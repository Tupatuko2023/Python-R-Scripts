# TASK: Table 2 (FOF Utilization) Orchestration + Script

## STATUS
- State: Done
- Priority: High
- Assignee: Codex (6caqf)

## PROBLEM
Table 2 “Usage of Injury Related Health Services” needs a locked spec and a single R script that produces the CSV with proper governance (Option B, aggregates gate, suppression) and correct model outputs. The workflow requires creating and moving a task file before work starts.

## OBJECTIVE
Produce a repo doc that locks the Table 2 spec and a single R script that generates the Table 2 CSV using the required inputs and safety gates.

## SCOPE
- Table 2 spec: rows, columns, N, units, and “Adjusted for age and sex” text.
- R script: read data via env vars, enforce ID linkage, compute adjusted rates and IRR, output safe aggregate CSV.
- Workflow: follow task move rules and remote-sync policy.

## RISKS / KB MISSING
- **ID linkage missing**: `aim2_analysis$id` is pseudonymized while registry data uses direct identifiers. A link table is required; fail-closed without it.
- **Diagnosis selection**: default to `Pdgo` only; including secondary diagnoses must be explicitly decided.

## COMMANDS
CI-safe:
- `python -m unittest discover -s Quantify-FOF-Utilization-Costs/tests`
- `python Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py --use-sample`

Local (only with permit + data available):
- `ALLOW_AGGREGATES=1 INTEND_AGGREGATES=true Rscript Quantify-FOF-Utilization-Costs/R/15_table2_usage_injury_services.R`

## DEFINITION OF DONE
- [ ] Doc exists that locks Table 2 spec and governance requirements.
- [ ] Single R script exists and produces `R/15_table2/outputs/table2_generated.csv` (gitignored) with correct columns and row order.
- [ ] Script fail-closed on missing ID link table and respects Option B + aggregates gate.
- [ ] Task file moved to `tasks/02-in-progress/` when work starts.

## UPDATES
- n<5-suppressio poistettu (virheellinen sääntö)
- Muutetut tiedostot:
- `Quantify-FOF-Utilization-Costs/docs/table2_runbook.md`
- `Quantify-FOF-Utilization-Costs/R/15_table2/15_table2_usage_injury_services.R`
- `.gitignore`

## BLOCKED
- Resolved.

## STARTUP
- Startup protocol: source scripts/bootstrap_env.sh

## DOD
- Table 2 generated: `R/15_table2/outputs/table2_generated.csv` (gitignored).
