# TASK: Integrate Frailty Score from 'Fear-of-Falling' Project

## STATUS
- State: 02-done
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The current Aim 2 analysis lacks Frailty interactions (identified as a gap in `50_handover.md`).
The Frailty score logic/data exists in a sibling project: `../Fear-of-Falling/R-scripts/K15_MAIN/K15_MAIN.V1_frailty-proxy.R`.
We need to leverage this existing asset to enrich our Aim 2 panel.

## OBJECTIVE
1. **Locate & Assess**: Find the frailty data/script in the sibling directory.
2. **Link**: Update the Aim 2 build process (`scripts/10_build_panel_person_period.R` or the Python builder) to merge this Frailty Score into `aim2_panel.csv`.
   - *Key Check*: If the sibling project produces a CSV (e.g., `frailty_scores.csv`), read it from `DATA_ROOT` (assuming shared data root) or simulate the merge if it's code-only.
3. **Analyze**: Run a quick "Frailty Interaction Check":
   - Update `scripts/30_models_panel_nb_gamma.R` to include `FOF * frailty`.
   - OR: Run separate models for Frail vs Non-Frail.
4. **Visualize**: Update dashboard to show "Effect by Frailty Status".

## CONSTRAINTS (Option B & Termux)
1. **Cross-Project Access**: You may read `../Fear-of-Falling/` content (read-only).
2. **Data Policy**: Do NOT copy raw data from the other project into this repo. Assume the *output* of that script is available in `DATA_ROOT/derived/` or similar.
3. **Execution**: Use `termux-wake-lock`.

## STEPS
1. **Discovery**:
   - `ls -F ../Fear-of-Falling/R-scripts/K15_MAIN/`
   - Check if a derived frailty file exists in `DATA_ROOT`.
2. **Build Update**:
   - Modify the panel builder to LEFT JOIN the frailty indicator.
3. **Model Update**:
   - Add interaction term `FOF_status * frailty` to the GLM formulas.
4. **Execution**:
   - Run Build -> Models -> Dashboard sequence.

## DEFINITION OF DONE
- [x] `aim2_panel.csv` now contains a `frailty` column.
- [x] Models now output interaction estimates OR stratified results.
- [x] Dashboard includes a Frailty-specific visualization.
