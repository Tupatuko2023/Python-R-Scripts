Evidence Bundle -- K61

1. Task Metadata

- Task ID: K61
- Title: required-fields placeholder standardization
- Scope: `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md` required-fields
  and standardization wording only; no code changes
- Related prior task(s): K60 (closed scope; not reopened)
- Date: 2026-04-05
- Agent: codex

---

2. Gating Proof (Workflow Compliance)

- Task created in: "tasks/00-backlog/"
- Moved to: "tasks/01-ready/" before any edits
- Edits performed only after "01-ready" state: `Y`
- No reopening of closed tasks (e.g., K50): `Y`

Evidence (log excerpt):

- 2026-04-05 00:00:00 Created as a backlog task for placeholder-style
  required-fields cleanup after K60 intentionally deferred this
  documentation-only debt.
- 2026-04-05 00:15:00 Released to `tasks/01-ready/` and executed as a
  documentation-only cleanup.

---

3. Commit Evidence

- Commit hash(es):
  - <fill after commit>
- Branch: main
- Status: local only (pending push)

Commit message(s):

<fill after commit>

---

4. Diff Summary (Human-Readable)

Intent:

- Replace placeholder-style pseudo-standard names with explicit
  `KB missing` / `needs standardization mapping` wording, without inventing new
  standardized variable names.

Changed sections:

- `3.2 Required fields`
- related standardization / "Do not guess" wording if needed
- K61 task log / evidence bundle

Non-changes (explicit):

- No changes to:
  - analysis scripts
  - upstream K60 artifacts
  - data / outputs

---

5. Diff Snippet (Minimal, Concrete)

- `person*time (riskiaika per periodi; PY)`
+ `riskiaika per periodi (KB missing; needs standardization mapping before run)`

- `morbidity__ / comorbidity** (esim. Charlson tms. SAP:n mukaan)`
+ `lähtötilanteen komorbiditeettikenttä/-kentät (KB missing; needs standardization mapping before run)`

- `prior_falls** (aiemmat kaatumiset tms. SAP:n mukaan)`
+ `aiemmat kaatumiset tai vastaava lähtötilanteen riskihistoriakenttä (KB missing; needs standardization mapping before run)`

(Keep to 3-5 lines; focus on the core policy change)

---

6. Consistency Basis

Upstream alignment:

- K60 already aligned paper_02 frailty policy without reopening closed K50
  scope; K61 is the separate follow-up for placeholder cleanup only.

Implementation alignment:

- `Quantify-FOF-Utilization-Costs/CLAUDE.md` forbids guessing names and points
  to `data/VARIABLE_STANDARDIZATION.csv` as the naming source of truth.

Conclusion:

- K61 should remove pseudo-standard placeholders and replace them with explicit
  mapping-required wording, not guessed English aliases.

---

7. Scope Control

- Changes limited to:
  - `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
  - K61 task / evidence records
- No changes to:
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

- Placeholder risks identified at scaffold time:
  `person*time`, `morbidity__ / comorbidity**`, `prior_falls**`.
- Placeholder cleanup is restricted to the required-fields / standardization
  wording only; no frailty, model, or code changes are included.

---

10. Definition of Done (DoD)

- `Y` Target document updated with minimal diff
- `Y` Change is reversible
- `Y` Consistency verified against upstream decisions
- `Y` Task log updated
- `Y` Evidence bundle created

---

11. Audit Status

- Ready for audit: `Y`
- Known limitations:
  - commit hash and push status are filled after the execution commit is
    created

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
