# TASK: Resolve ID Linkage (Panel ID vs Raw Sotu/NRO)

## STATUS
- State: 01-ready
- Priority: Critical
- Assignee: Gemini Termux Orchestrator (S-QF)

## PROBLEM
The Codex agent cannot join `tupakointi` to `aim2_panel.csv` because the Join Keys do not match.
- Panel `id`: Integers (1, 2, 3...).
- Raw Data: `NRO` (Int/String) or `Sotu` (String).
- Match Rate: 0.

## OBJECTIVE
Find the mapping logic or the "Key File" that links `aim2_panel.csv` back to the raw `KAAOS_data_sotullinen.xlsx`.

## STEPS
1.  **Inspect Build Script**: Read `scripts/build_real_panel.py`.
    -   Look for how the `id` column is generated. Is it just `reset_index()`?
    -   Does the script save a key map (e.g., `derived/id_map.csv`)?
2.  **Inspect Derived Folder**: List files in `derived/` to see if there's a hidden mapping file.
3.  **Update Handover**:
    -   If a key file exists: Instruct Codex to load it as a bridge (`Panel -> KeyFile -> Raw`).
    -   If `id` is just row number: Instruct Codex to load the raw data, *sort it exactly the same way*, and assume alignment (Risky, but fallback).

## DEFINITION OF DONE
- [x] We know exactly how to link Panel ID 1 to its real identity: **Panel `id` IS Sotu**.
- [x] `docs/TABLE_1_HANDOVER.md` is updated with the correct bridging logic (Join Panel `id` to Excel `Sotu`).
