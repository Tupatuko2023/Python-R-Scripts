Evidence Bundle -- K63

1. Task Metadata

- Task ID: K63
- Title: variable standardization status rule and controlled cleanup
- Scope: phase-separated governance follow-up for
  `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`; no CSV
  edits in backlog state
- Related prior task(s): K62 (closed audit baseline)
- Date: 2026-04-09
- Agent: codex

---

2. Gating Proof (Workflow Compliance)

- Task created in: "tasks/00-backlog/"
- Moved to: "tasks/01-ready/" before any edits
- Edits performed only after "01-ready" state: `N`
- No reopening of closed tasks (e.g., K50): `Y`

Evidence (log excerpt):

- 2026-04-09 00:00:00 Created as a backlog follow-up to K62 to separate
  governance-rule definition from any later CSV cleanup.

---

3. Commit Evidence

- Commit hash(es):
  - `<pending>`
- Branch: main
- Status: local only

Commit message(s):

- `<pending>`

---

4. Diff Summary (Human-Readable)

Intent:

- Create a separate K63 follow-up that first makes mapping status governance
  explicit and only then authorizes controlled CSV cleanup.

Changed sections:

- K63 task scaffold
- K63 evidence bundle scaffold
- no CSV changes in this phase

Non-changes (explicit):

- No changes to:
  - `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
  - analysis scripts
  - closed K60 / K61 artifacts

---

5. Diff Snippet (Minimal, Concrete)

- <no explicit follow-up task for status-model governance>
+ <K63 created to separate Phase 1 status-rule definition from Phase 2 cleanup>

- <duplicate-risk is only an audit finding>
+ <duplicate source/original keys and duplicate standard names are promoted to explicit K63 scope>

(Keep to 3-5 lines; focus on the core policy change)

---

6. Consistency Basis

Upstream alignment:

- K62 concluded that the safe next step is a two-phase model rather than direct
  CSV cleanup.

Implementation alignment:

- `CLAUDE.md` and `DATA_DICTIONARY_WORKFLOW.md` already require
  `INFERRED -> human verification -> freeze`; K63 operationalizes that rule as
  an explicit status-governance task.

Conclusion:

- K63 should not begin as ad hoc cleanup; it should first define the rule that
  determines which rows can be trusted and which rows remain provisional or
  artifact-only.

---

7. Scope Control

- Changes limited to:
  - K63 task / evidence scaffolding
- No changes to:
  - `VARIABLE_STANDARDIZATION.csv`
  - closed task artifacts
  - unrelated modules
- No scope creep detected: `Y`

---

8. Data Governance (Option B Check)

- No raw or participant-level data added: `Y`
- No DATA_ROOT leakage: `Y`
- No absolute paths in docs/stdout: `Y`
- Manifest unchanged or metadata-only: `Y`

---

9. QC / Additional Notes (Optional)

- K62 found `19` frozen-like rows out of `493` data rows.
- K62 found duplicate signals across both source/original keys and
  `standard_variable` values.
- Recommended model remains `C`: explicit governance rule first, then scoped
  cleanup under human approval.

---

10. Definition of Done (DoD)

- `N` Target CSV updated with minimal diff
- `Y` Change is reversible
- `Y` Consistency verified against upstream decisions
- `Y` Task log updated
- `Y` Evidence bundle created

---

11. Audit Status

- Ready for audit: `N`
- Known limitations:
  - execution has not started
  - commit metadata will be filled after K63 is acted on

---

Usage Notes

- Keep bundle short and factual (no narrative prose)
- Always include:
  - gating proof
  - commit
  - diff snippet
- Never include:
  - raw data
  - absolute paths
  - large diffs
