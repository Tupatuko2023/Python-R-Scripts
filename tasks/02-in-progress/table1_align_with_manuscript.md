# Task: Table 1 align with manuscript

## Context
Table 1 PR is merged; create a follow-up task + branch to align Table 1 with manuscript definitions.

## Priority order
1) Lock analysis population for Table 1: apply age >= 65 and drop missing FOF before summaries; use a single analysis_set object. Report only group Ns (No/Yes).
2) Investigate ATOH mismatch: run aggregate-only diagnostics to identify correct ATOH source column and coding; adjust mapping to match manuscript (Without/With difficulties/Unable).
3) Confirm denominators and % rules match manuscript (row-level non-missing per group).
4) Ensure label is FTSST (not TUG) in Table 1 output.

## Definition of Done
- Task moved to 02-in-progress before edits and to 03-review when done.
- Table 1 uses a single analysis_set object with age >= 65 and non-missing FOF.
- ATOH mapping matches manuscript coding or documented reason if mismatch persists.
- Denominators and percents are row-level non-missing per group.
- FTSST label is correct.
- Minimal diff; rerun relevant script/tests.

## Log
- 2026-02-03T21:03:20+02:00 Task created and moved to 02-in-progress.
