Evidence Bundle -- Template (Audit-Ready)

1. Task Metadata

- Task ID: KXX
- Title: <short descriptive title>
- Scope: <target doc(s) only; confirm no cross-project edits>
- Related prior task(s): <e.g., K50 (closed)>
- Date: <YYYY-MM-DD>
- Agent: <agent id>

---

2. Gating Proof (Workflow Compliance)

- Task created in: "tasks/00-backlog/"
- Moved to: "tasks/01-ready/" before any edits
- Edits performed only after "01-ready" state: `Y/N`
- No reopening of closed tasks (e.g., K50): `Y/N`

Evidence (log excerpt):

<insert 1-3 lines from task log showing transition>

---

3. Commit Evidence

- Commit hash(es):
  - <hash1>
  - <hash2> (if multiple)
- Branch: main
- Status: pushed / local only (specify)

Commit message(s):

<copy exact commit message(s)>

---

4. Diff Summary (Human-Readable)

Intent:

- <1-2 sentence description of what changed and why>

Changed sections:

- <section 1>
- <section 2>
- <section 3>

Non-changes (explicit):

- No changes to:
  - <e.g., scripts/>
  - <e.g., other project docs>
  - <e.g., data / outputs>

---

5. Diff Snippet (Minimal, Concrete)

- <before line>
+ <after line>

- <before line>
+ <after line>

(Keep to 3-5 lines; focus on the core policy change)

---

6. Consistency Basis

Upstream alignment:

- <e.g., K50 / paper_01 FI_22-primary line>

Implementation alignment:

- <e.g., K40_FI_KAAOS.R produces required variables>

Conclusion:

- <why the chosen change is consistent across pipeline + docs>

---

7. Scope Control

- Changes limited to:
  - <target file(s)>
- No changes to:
  - closed task artifacts
  - unrelated modules
- No scope creep detected: `Y/N`

---

8. Data Governance (Option B Check)

- No raw or participant-level data added: `Y/N`
- No DATA_ROOT leakage: `Y/N`
- No absolute paths in docs/stdout: `Y/N`
- Manifest unchanged or metadata-only: `Y/N`

---

9. QC / Additional Notes (Optional)

- <e.g., QC fields clarified>
- <e.g., assumptions documented>
- <e.g., known deferred issues -> link future task (KXX)>

---

10. Definition of Done (DoD)

- `Y/N` Target document updated with minimal diff
- `Y/N` Change is reversible
- `Y/N` Consistency verified against upstream decisions
- `Y/N` Task log updated
- `Y/N` Evidence bundle created

---

11. Audit Status

- Ready for audit: `Y/N`
- Known limitations:
  - <e.g., no full diff attached / partial evidence>

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
