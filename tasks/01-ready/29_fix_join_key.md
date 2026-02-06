# TASK: Fix Join Key for Table 1 (ID vs NRO)

## STATUS
- State: 01-ready
- Priority: Critical
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND
The Codex agent (3caqf) reported a 'match_rate: 0'. 
Forensics revealed that the script was trying to join Panel `id` (Numeric, e.g. 1, 2, 3) to Excel `Sotu` (String, e.g. "010150-XXXX").
The correct mapping is Panel `id` <--> Excel `NRO` (Column 1).

## OBJECTIVE
Update `docs/TABLE_1_HANDOVER.md` to specify the correct join key and add integrity gates.

## STEPS
1.  **Verify**: Confirm Column 1 in `KAAOS_data_sotullinen.xlsx` is `NRO`.
2.  **Update**: Modify `docs/TABLE_1_HANDOVER.md`:
    -   Specify joining Panel `id` to Excel `NRO` (Column 1).
    -   Add strict match rate gate (fail if < 70%).
    -   Add exact numeric mapping code for `frailty_fried`.

## DEFINITION OF DONE
- [ ] `docs/TABLE_1_HANDOVER.md` instructs the correct join key (`NRO`).
- [ ] Codex is ready to re-run with high-confidence instructions.
