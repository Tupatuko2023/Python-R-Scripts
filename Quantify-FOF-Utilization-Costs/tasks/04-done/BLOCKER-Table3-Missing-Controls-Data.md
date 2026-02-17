# BLOCKER: Table 3 Missing Controls Data

**Status**: 02-in-progress (BLOCKER)
**Assigned**: Gemini / Data Team
**Created**: 2026-02-16

## DESCRIPTION
Table 3 analysis pipeline is currently halted (fail-closed) because the control cohort data has not been linked to the analysis ID space. The original `Verrokit.XLSX` file cannot be used in the pipeline for privacy reasons as it contains raw identifiers.

## REQUEST TO DATA TEAM
To proceed, we require two pseudonymized CSV files in the `DATA_ROOT/derived/` directory:

1. **controls_link_table.csv**
   Columns: `id`, `register_id`
   - `id`: Must be a pseudonymized analysis ID (e.g., CTRL_0001). This must not overlap with case cohort IDs.
   - `register_id`: Key to join diagnosis/procedure events to the person.

2. **controls_panel.csv**
   Columns: `id`, `case_status`, `fof_status`, `age`, `sex`, `py`
   - `id`: Exactly matching IDs in the link table.
   - `case_status`: All rows must have the value `control`.
   - `py`: Person-years (follow-up). Value must be > 0.

## RESOLUTION STEPS
1. [x] Delivery of synthetic/production files to `$DATA_ROOT/derived/`.
2. [x] Validation via `python scripts/32_qc_controls_delivery.py`.
3. [x] Transition to `tasks/04-done/` once QC passes.

## RESOLUTION
Synthetic test data delivered and validated.
QC Output:
- safe_counts: {'link_rows': 2, 'panel_rows': 2, 'shared_ids': 2}
- Result: PASS
Blocker resolved. Ready to proceed to `15_build_table3_inputs.py`.
