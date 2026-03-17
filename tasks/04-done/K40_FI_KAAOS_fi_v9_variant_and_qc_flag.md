# Task: K40 FI KAAOS FI_v9 Variant Lock + QC Flag

## Context

FI_v8 established stable non-performance FI with deterministic map controls and no keep=1 drop rows.
Given current single-sheet KAAOS constraint, this index is treated as a sensitivity construct.

## Plan

1. Add explicit variant metadata to receipt and decision log:
   - fi_variant
   - fi_variant_role
2. Add QC red flag:
   - selected_deficits_lt_30
3. Re-run K40 and verify new keys are emitted.

## Done Criteria

- Run succeeds and outputs include variant keys.
- red_flags contains selected_deficits_lt_30.
- Governance unchanged (patient-level output only under DATA_ROOT).

## Log

- 2026-03-06 04:22: Added variant lock and selected_deficits_lt_30 flag.
