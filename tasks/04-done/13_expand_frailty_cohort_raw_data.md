# TASK: Expand Frailty Cohort using Raw Data (KAAOS_data_sotullinen.xlsx)

## STATUS
- State: 04-done
- Priority: Critical
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The user identified that `Kaatumisenpelko.csv` (N=276) excludes participants who dropped out at 12 months.
However, for Aim 2 (Register Analysis), we only need Baseline (T0) frailty data.
The raw file `KAAOS_data_sotullinen.xlsx` likely contains the full baseline cohort (estimated N > 400), which would significantly increase statistical power.

## OBJECTIVE
1. **Inspect Raw Data**: Read `DATA_ROOT/KAAOS_data_sotullinen.xlsx`.
2. **Identify Variables**: Find the raw columns corresponding to the 3 Fried Frailty components at Baseline (T0):
   - **Strength**: Handgrip (Puristusvoima kg).
   - **Speed**: Walking speed (Kävelynopeus m/s or time for X meters).
   - **Activity**: Physical activity level (Liikunta).
3. **Calculate Proxy**: Re-implement the frailty scoring logic on this larger raw dataset.
4. **Link & Measure**: Update `aim2_panel.csv` with this expanded frailty set and report the new N.

## CONSTRAINTS
- **Read-Only**: Do not modify the raw Excel file.
- **Privacy**: Do not print SOTU or Name columns. Use `NRO` or generated ID for reporting.
- **Termux**: Use `termux-wake-lock` (Excel parsing is heavy).

## STEPS
1. **Discovery (R/99_inspect_raw.R)**:
   - Load `KAAOS_data_sotullinen.xlsx`.
   - Print column names matching "puristus", "kävely", "liikunta", "paino", "pituus".
   - Report the total row count (Potential N).
2. **Refine Logic**:
   - Create a mapping script to standardize these raw columns to `strength`, `speed`, `activity`.
   - Calculate `frailty_score` (0-3) and `frailty_cat` (Robust/Pre-frail/Frail).
3. **Update Builder**:
   - Modify `scripts/build_real_panel.py` to pull Frailty from this raw source instead of the CSV.
4. **Execution**:
   - Run Build -> QC (Check new N) -> Models -> Handover.

## DEFINITION OF DONE
- [x] Potential N is identified (e.g., > 300).
- [x] Frailty is calculated for the expanded group.
- [x] `aim2_panel.csv` match rate increases (goal: close to full panel N=486).
- [x] `FRAILTY_HANDOVER.md` updated with the "Expanded" numbers.
