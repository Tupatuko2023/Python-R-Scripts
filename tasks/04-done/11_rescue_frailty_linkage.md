# TASK: Rescue Frailty Linkage & Enforce Methodology (Critical)

## STATUS
- State: 04-done
- Priority: Critical
- Assignee: Gemini Termux Orchestrator (S-QF)

## BACKGROUND & SOURCE OF TRUTH
According to the technical audit (`Raportin korjaus...rtf`), the current linkage rate (N=126) is unacceptably low compared to the available source data (N~276). The issue is identified as a likely **ID formatting mismatch** (NRO vs. ID/Sotu) or missing mapping logic.

Furthermore, the audit explicitly defines the calculation logic:
1.  **Frailty Proxy**: Must use **3 components** (Strength, Speed, Activity). **Exhaustion** must be EXCLUDED (not measured by RAND-36).
2.  **FOF**: Must be strictly **Binary (0/1)** based on variable `T8_KaatumisenpelkoOn`.

## OBJECTIVE
Recover the "missing" ~150 participants by fixing the ID linkage and implementing the strictly defined Frailty/FOF logic in the build pipeline.

## CONSTRAINTS (Option B)
1.  **No PII**: Never print ID values (e.g., "010101-XXXX"). Use generic descriptions like "Format: 6 digits, type: string".
2.  **Aggregates Only**: Report match rates and missingness % only.
3.  **Termux-Native**: Use `termux-wake-lock` for build operations.

## STEPS

### 1. Discovery & ID Forensics
* Locate the source file containing `NRO` and `T8_KaatumisenpelkoOn` (likely `KAAOS_data.xlsx`, `kaatumisenpelko.csv` or similar).
* Create a temporary diagnostic script `R/99_debug_linkage.R` to analyze the merge failure:
    * Load `aim2_panel.csv` (Target) and Source Data.
    * Compare `class(id)` and `nchar(id)` in both.
    * Check for leading zeros, whitespace, or "1.0" vs "1" formatting.
    * Calculate **Anti-Join**: How many IDs are in Source but not in Panel?
    * *Output:* A summary table of the mismatch reasons.

### 2. Implement the Fix (Build Script)
* Modify `scripts/build_real_panel.py` (or the relevant R builder):
    * **ID Normalization**: Apply robust cleaning before merge (e.g., `str.trim().lstrip('0')`, force to string).
    * **Mapping**: If Source uses `NRO` and Panel uses `RegistryID`, ensure the mapping file (from `data/`) is applied correctly.
    * **Logic Update**:
        * Calculate Frailty Proxy = Sum(Strength, Speed, Activity) [Range 0-3].
        * Force `FOF` to 0/1 (drop or handle '2'/'3'/'EOS' as missing if not binary).

### 3. Execution & Verification
* Run the build: `termux-wake-lock && python3 scripts/build_real_panel.py && termux-wake-unlock`.
* Run QC: Verify that the new `aim2_panel.csv` has:
    * Significantly higher N with Frailty data (Target > 200).
    * Frailty columns corresponding to the 3 components.

### 4. Handover Update
* Update `docs/FRAILTY_HANDOVER.md` with:
    * "Before" vs "After" match counts.
    * Technical root cause of the mismatch (e.g., "Source IDs had leading zeros").

## DEFINITION OF DONE
- [x] ID Match count increased significantly (approaching ~276 source records).
- [x] Frailty logic strictly follows "3 components, no exhaustion".
- [x] FOF is verified as binary (0/1).
- [x] Handover document updated with forensic findings.
