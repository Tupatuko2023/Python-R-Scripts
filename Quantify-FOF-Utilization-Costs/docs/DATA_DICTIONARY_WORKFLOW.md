# Data Dictionary Workflow (Finnish -> English)

**Problem:** The raw data (in `DATA_ROOT`) contains Finnish column headers. Agents often guess the English translation, leading to errors.
**Solution:** A strict "Infer -> Verify -> Freeze" workflow.

## 1. The Principle: "Do Not Guess"

- **Never** use an English variable name in analysis code unless it has
  explicit governance status and is eligible for pipeline use under the rules
  below.
- If a variable is missing, do not invent a name like `visit_count` if the raw column is `kayntikerrat`. You must register it first.
- Default pipeline rule: only rows with `status="frozen"` are allowed in
  analysis.

## 2. Governance Status Vocabulary

- `frozen`
  - Meaning: human-verified mapping with documented source evidence and an
    unambiguous Finnish-to-English interpretation.
  - Pipeline use: allowed by default.
  - How reached: a row is promoted only after human verification,
    source-backed review, and explicit freeze approval.
- `inferred`
  - Meaning: candidate mapping proposed by an agent or script, but not yet
    confirmed by a human.
  - Pipeline use: blocked by default.
  - How reached: inventory or translation candidate exists, but verification is
    pending.
- `tbd`
  - Meaning: a variable is known to be needed, but its mapping remains
    unresolved or ambiguous.
  - Pipeline use: blocked by default.
  - How reached: required field identified, but no unambiguous mapping is ready
    for review or freeze.
- `artifact`
  - Meaning: non-analytic row such as `Unnamed:*`, numeric/list artifacts,
    redacted-source placeholders, or similar metadata noise.
  - Pipeline use: never allowed in analysis.
  - How reached: row is identified as structural noise or non-analytic content
    rather than a real variable mapping.

Cross-cutting note:

- Duplicate signals are not a standalone pipeline-eligible status. Duplicate
  source/original keys and duplicate `standard_variable` values must be treated
  as governance risks and resolved in a later cleanup task.

## 3. The Workflow

### Step 1: Inventory (Infer)

1. Script reads `DATA_ROOT` headers.
2. Script checks `data/VARIABLE_STANDARDIZATION.csv`.
3. If new columns found, script generates a "Mapping Candidate" list.
   - _Agent Action:_ You can propose translations but MUST mark them as
     `status="inferred"` or `status="tbd"` if ambiguity remains.
   - Example: `kayntikerrat` -> `visit_count (status="inferred")`

### Step 2: Human Verification

1. A human (or domain expert) reviews the `inferred` / `tbd` mappings.
2. They confirm the documented source, correct meanings, and verify that the
   mapping is unambiguous.
3. Only after that review may the row be promoted to `frozen`.

### Step 3: Freeze

1. Promotion from `inferred` / `tbd` to `frozen` requires all of the following:
   - human verification
   - documented source evidence
   - unambiguous mapping semantics
2. The approved mapping is then committed to
   `data/VARIABLE_STANDARDIZATION.csv`.
3. Only `frozen` mappings are pipeline-eligible by default.

## 4. Pipeline Rule

- Default rule: analysis code and production pipelines may consume only
  `frozen` mappings.
- `inferred`, `tbd`, and `artifact` rows are blocked from default analysis use.
- Any override to this rule must be explicit, human-approved, and documented as
  a temporary exception rather than treated as implicit freeze.

## 5. Forbidden Fields (PII)

- Any column resembling a social security number (HETU, SATU) or name is **Forbidden**.
- If found, add to `redaction_list` and do not map to analysis variables.
- **Option B Rule:** These columns must be dropped immediately after load, or ideally, not loaded at all.

## 6. How to Handle Ambiguity

If you (the Agent) are unsure what a Finnish abbreviation means (e.g., `toimenpide_koodi_X`):

1. **Stop.** Do not assume.
2. Check `docs/GLOSSARY_FI_EN.md` (if exists).
3. Ask the user: "I found column 'X'. Does this map to 'Procedure Code'?"
4. Once confirmed, document the source and promote the row to `frozen`.

## 7. Cleanup Deferral

- Artifact rows, duplicate-risk rows, and redacted/unclear-source rows are not
  resolved in the governance-definition step.
- These rows must be handled in a separate Phase 2 cleanup task after the
  status model above is explicit and human-approved.
