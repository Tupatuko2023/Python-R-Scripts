# Data Dictionary Workflow (Finnish -> English)

**Problem:** The raw data (in `DATA_ROOT`) contains Finnish column headers. Agents often guess the English translation, leading to errors.
**Solution:** A strict "Infer -> Verify -> Freeze" workflow.

## 1. The Principle: "Do Not Guess"

- **Never** use an English variable name in analysis code unless it exists in `data/VARIABLE_STANDARDIZATION.csv` with a `verified=True` status (or equivalent confidence).
- If a variable is missing, do not invent a name like `visit_count` if the raw column is `kayntikerrat`. You must register it first.

## 2. The Workflow

### Step 1: Inventory (Infer)

1.  Script reads `DATA_ROOT` headers.
2.  Script checks `data/VARIABLE_STANDARDIZATION.csv`.
3.  If new columns found, script generates a "Mapping Candidate" list.
    - _Agent Action:_ You can propose translations but MUST mark them as `status="INFERRED"`.
    - Example: `kayntikerrat` -> `visit_count (INFERRED)`

### Step 2: Human Verification

1.  A human (or domain expert) reviews the `INFERRED` mappings.
2.  They correct meanings (e.g., `hoitopaivat` might be "treatment days" or "inpatient days" - specific distinction matters).
3.  They change status to `VERIFIED`.

### Step 3: Freeze

1.  The `data/VARIABLE_STANDARDIZATION.csv` is committed to git.
2.  This file is now the **Law**.

## 3. Forbidden Fields (PII)

- Any column resembling a social security number (HETU, SATU) or name is **Forbidden**.
- If found, add to `redaction_list` and do not map to analysis variables.
- **Option B Rule:** These columns must be dropped immediately after load, or ideally, not loaded at all.

## 4. How to Handle Ambiguity

If you (the Agent) are unsure what a Finnish abbreviation means (e.g., `toimenpide_koodi_X`):

1.  **Stop.** Do not assume.
2.  Check `docs/GLOSSARY_FI_EN.md` (if exists).
3.  Ask the user: "I found column 'X'. Does this map to 'Procedure Code'?"
4.  Once confirmed, add to `VARIABLE_STANDARDIZATION.csv`.
