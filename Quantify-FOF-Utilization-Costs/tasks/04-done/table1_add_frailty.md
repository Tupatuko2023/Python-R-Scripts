# TASK: Table 1 add Frailty (Fried)

**Status**: 02-in-progress
**Assigned**: 3caqf
**Created**: 2026-02-04

## PROBLEM STATEMENT

Add Frailty (Fried) 3-class to Table 1 by FOF.

## ASSUMPTIONS

- `frailty_fried` is an existing ground truth field.
- Levels are robust / pre-frail / frail.

## INPUTS

- `Quantify-FOF-Utilization-Costs/R/10_table1_patient_characteristics_by_fof.R`

## PLANNED STEPS

1. pick_col
2. normalize_frailty3
3. summ_multicat

## ACCEPTANCE CRITERIA

- [ ] Table 1 includes Frailty (Fried), n (%) with robust / pre-frail / frail rows.
- [ ] Denominators and p-values follow existing Table 1 conventions.

## DECISIONS

- Used the canonical Table 1 script at `R/10_table1_patient_characteristics_by_fof.R` because no file exists under `R/10_table1/`.
- Added fail-closed sanity checks after frailty recode (all-NA / <2 levels / unexpected levels).

## CHECKS

- Not run (no data/ALLOW_AGGREGATES env set).

## LOG

- 2026-02-04T23:59:43Z Moved to 03-review; awaiting orchestrator review; no runs performed; no outputs committed.
