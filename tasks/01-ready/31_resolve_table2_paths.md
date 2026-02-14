# TASK: Locate Register Files for Table 2

## STATUS
- State: 01-ready
- Priority: Critical
- Assignee: Gemini Termux Orchestrator (S-QF)

## PROBLEM
The Table 2 script failed because `PATH_PKL_VISITS_XLSX` and `PATH_WARD_DIAGNOSIS_XLSX` are unset.
We need to find the exact filenames within `DATA_ROOT` to set these variables.

## OBJECTIVE
1.  **Scan**: Search `DATA_ROOT` for Excel files matching "pkl", "poli", "osasto", "ward".
2.  **Inspect**: For each candidate, print the Column Names (headers) to identify the ID column.
3.  **Report**: Output the full paths and ID column names so we can construct the run command.

## STEPS
1.  **Discovery Script**: Create `R/99_find_registers.R`.
    -   `list.files(pattern = "\.xlsx$", recursive = TRUE)` inside DATA_ROOT.
    -   Filter for keywords.
    -   Use `readxl::read_excel(..., n_max=1)` to print headers.
2.  **Execute**: Run the script.
3.  **Output**: Save findings to `docs/REGISTER_PATHS.md`.

## DEFINITION OF DONE
- [ ] We know the exact path to the Outpatient (PKL) file.
- [ ] We know the exact path to the Inpatient (Ward) file.
- [ ] We know the ID column name for both.
