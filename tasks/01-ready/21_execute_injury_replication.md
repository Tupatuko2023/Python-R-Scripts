# TASK: Execute Injury-Only Replication Analysis (Python)

## STATUS
- State: 01-ready
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
We have identified the raw files and columns for "Injury-Related" outcomes (ICD-10 S00-T14).
Now we must execute the expert-provided Python script to calculating the IRRs.
This script bypasses the derived panel's "total visits" and calculates fresh aggregates from raw data, filtering strictly for injuries.

## OBJECTIVE
1.  **Create Script**: Create `scripts/70_replicate_injury_icd.py` using the expert's template.
2.  **Configure**: Populate the `CONFIG` dictionary within the script using the findings from `docs/REPLICATION_CONFIG.md`:
    -   `OUTPATIENT_EVENTS_PATH`: `paper_02/Tutkimusaineisto_pkl_kaynnit_2010_2019.csv`
    -   `INPATIENT_EPISODES_PATH`: `paper_02/Tutkimusaineisto_osastojakso_diagnoosit (1).xlsx`
    -   `ID_COL`: `Henkilotunnus`
    -   `OUT_DATE_COL`: `Kayntipvm`
    -   `IN_ADMIT_COL`: `OsastojaksoAlkuPvm`
    -   `OUT_ICD_COL`: `Pdgo` (Primary Diagnosis)
    -   `IN_ICD_COL`: `Pdgo`
3.  **Execute**: Run the script using `termux-wake-lock`.
4.  **Report**: Append the results to `FRAILTY_HANDOVER.md`.

## STEPS
1.  **Write Script**: Copy the expert's Python code into `scripts/70_replicate_injury_icd.py`.
2.  **Edit Config**: Manually update the `CONFIG = { ... }` block in the file to match the paths above.
3.  **Run**: `termux-wake-lock && python3 scripts/70_replicate_injury_icd.py && termux-wake-unlock`.
4.  **Verify Output**: Check `outputs/replication_injury/replication_injury_nb_age_sex.csv`.
5.  **Update Handover**: Add a new table in `FRAILTY_HANDOVER.md` comparing these new "Injury Only" IRRs to the Original Manuscript.

## DEFINITION OF DONE
- [x] `scripts/70_replicate_injury_icd.py` exists and has correct paths.
- [x] Script executes without error.
- [x] `FRAILTY_HANDOVER.md` contains the Injury-Only IRRs.
- [x] Interpretation: Do these new numbers match the manuscript (1.18 / 1.70) better than the all-cause numbers?
