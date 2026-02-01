# TASK: Discovery of Distinct Outcome Columns for Replication (Injury-Only)

## STATUS
- State: 01-ready
- Priority: High
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
To replicate the original manuscript's findings accurately, we need to analyze injury-related outcomes specifically (ICD-10 S00-S99, T00-T14), separate from general utilization.
This requires accessing the raw event-level data (Outpatient visits and Inpatient episodes) to filter by diagnosis codes.

## OBJECTIVE
Identify the exact file paths and column names in the DATA_ROOT (raw data) that correspond to:
1.  **Outpatient Visits**: File path, ID column, Date column, Primary ICD-10 column.
2.  **Inpatient Episodes**: File path, ID column, Admission Date column, Primary ICD-10 column.
3.  **Panel**: Year/Period column name in `aim2_panel.csv`.

## STEPS
1.  **Inspect Dictionary**: Check `data/data_dictionary.csv` and `docs/DATA_LINKAGE_PROTOCOL.md` for raw file hints.
2.  **Inspect Build Script**: Read `scripts/build_real_panel.py` to see which raw files were used.
3.  **Inspect Raw Headers**: Create a temp script to list columns of potential raw files.
4.  **Report**: Create `docs/REPLICATION_CONFIG.md` with the specific paths and column names found.

## DEFINITION OF DONE
- [x] `docs/REPLICATION_CONFIG.md` exists containing:
    - Outpatient File Path & Columns (ID, Date, ICD).
    - Inpatient File Path & Columns (ID, Admit Date, ICD).
    - Panel Year Column Name.
