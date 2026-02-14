# Task: Table 1 Iteration 2 (FOF binary, no pairwise, level-p for multicat)

## Context
- Source: prompts/FOF_Burden_and_Cost_Copilot_Finland_2.txt
- Target script: Quantify-FOF-Utilization-Costs/R/10_table1/12_table1_patient_characteristics_by_fof_wfrailty.R

## Scope (allowed)
- Force FOF to binary (No vs Yes) for Table 1
- Remove Pairwise column entirely
- Add per-level 2x2 p-values for multicat level rows
- Update p-value spec to match iteration 2

## Non-goals (forbidden)
- No raw data output
- No absolute paths in logs
- No pairwise output

## Acceptance criteria
- Table 1 columns: Variable, No, Yes, P-value (overall)
- No Pairwise (adj) column
- Multicat level rows include p-values (2x2 level vs rest)
- Suppression applies to level p-values if any cell < 5

## Workflow gates
- Follow WORKFLOW.md and task checklist.

## Log
- 2026-02-07T10:38:36+02:00 Siirretty 02-in-progress ja aloitettu Iteration 2.
- 2026-02-07T10:47:04+02:00 Table1 ajettu DATA_ROOTilla (ALLOW_AGGREGATES=1) ja CSV validoitu (no pairwise, overall p ok, level-p rivit ok).
