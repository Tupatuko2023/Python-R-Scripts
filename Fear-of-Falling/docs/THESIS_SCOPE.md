# Thesis Scope & Guardrails (Fear-of-Falling)

**Status:** Active  
**Last Updated:** 2025-12-29  
**Anchors:** [ANALYSIS_PLAN](ANALYSIS_PLAN.md), [QC_CHECKLIST](../QC_CHECKLIST.md)

This document defines the **scope boundaries** and **technical guardrails** for the Fear-of-Falling (FOF) subproject. It translates the research plan (dated **11 Oct 2025**) into actionable constraints for the codebase agent.

---

## 1. Research Scope (Immutable Core)

The following elements are derived from the approved research plan and **must not be changed** without explicit authorization.

### 1.1 Anchoring Facts (Audit Trail)

- **Thesis working title:** _Detecting and Monetising Fall Risks_ (11 Oct 2025 research plan).
- **Primary cohort asset:** Multifactorial falls-prevention programme (MFFP) cohort (**n=477**) and matched municipal controls (**n=1,431**), recruited **2010–2017**.
- **Key construct:** Baseline **fear of falling (FOF)** assessed via a single-item question and treated as **binary** (yes/no).
- **Core follow-up:** Baseline ($T_0$) and 12-month follow-up ($T_{12}$) for physical-performance outcomes.
- **Study 2 linkage:** Deterministic linkage to **regional healthcare financial administration data** to estimate **FOF-attributable service utilisation and expenditure**.
- **Study 3:** **Under construction / TBD** in the research plan (no scope expansion without an approved update).

### 1.2 Study Design

- **Design:** Retrospective/observational analyses of an intervention cohort (MFFP context).
- **Population:** Older adults participating in an MFFP; matched municipal controls exist as an asset; their analytic role must be specified per Aim 2 implementation.
- **Timepoints (Study 1):** Baseline ($T_0$) and 12-month follow-up ($T_{12}$).
- **Intervention context:** Participants were enrolled in a multifactorial falls-prevention programme; **analyses are observational/retrospective** and must avoid causal language unless explicitly justified.

### 1.3 Scientific Aims (Locked to the Research Plan)

| Aim                 | Description (locked)                                                                                                                                          | Primary analyses (allowed)                                                                                                              |
| :------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------------------------------------------------- |
| **Aim 1 (Study 1)** | Test whether **baseline FOF moderates 12-month change** in **composite and task-level physical performance** within the MFFP cohort.                          | Longitudinal models (e.g., LMM/LME): `Outcome ~ time * FOF_status + covariates`                                                         |
| **Aim 2 (Study 2)** | Deterministically link cohort data to **regional financial administration data** to estimate **FOF-attributable health-service utilisation and expenditure**. | Count + cost models (e.g., negative binomial for utilisation; gamma log-link / two-part models for costs), with prespecified covariates |
| **Aim 3 (Study 3)** | **Under construction / TBD**.                                                                                                                                 | **No implementation** beyond placeholders until Aim 3 is formally specified                                                             |

**Important:** ANCOVA for change (e.g., `Outcome_T12 ~ FOF_status + Outcome_T0 + covariates`) is permitted only as a **complementary/sensitivity analysis under Aim 1**, not as a separate aim.

### 1.4 Core Definitions (Do not reinvent)

- **FOF (analysis variable):** Binary yes/no status.
  _Repo standard name:_ `FOF_status`
  _Repo convention:_ Currently maps raw `kaatumisenpelkoOn` {0,1} → `FOF_status` with reference `nonFOF`, but the raw column name and coding must be confirmed against ingest/data_dictionary before changes.
- **Physical-performance outcomes:** Composite Z-score (and task-level tests) defined in the analysis plan; standardisation rules are fixed per-plan.
- **Follow-up window:** 12 months. Any allowable timing window must be explicitly defined in QC (TODO if not specified).
- **Cost/utilisation outcomes (Aim 2):** Service contacts/episodes and costs derived **exclusively** from financial administration data after controller-performed linkage.

---

## 2. Technical Guardrails

### 2.1 Privacy & Governance

1. **No PII:** Never output tables, logs, or screenshots containing participant IDs, names, exact dates of birth, addresses, or other direct identifiers.
2. **Aggregate Only:** QC artifacts must aggregate data (counts, distributions), not list individual rows.
3. **Local Execution:** Analysis runs locally. Do not upload raw data to external services.

### 2.2 Data Integrity

1. **Read-Only Raw Data:** Files in `data/raw/` (or equivalent) are immutable.
2. **No Manual Edits:** All data cleaning and transformation must be performed by reproducible R scripts.
3. **Strict QC:** No modeling before passing `K18_QC` gates (see [QC_CHECKLIST](../QC_CHECKLIST.md)).

### 2.3 Reproducibility

1. **Environment:** Use `renv` for package management.
2. **Randomness:** Use `set.seed(20251124)` _only_ when necessary (bootstrap/MI).
3. **Artifact Tracking:** Every output file must be logged in `manifest/manifest.csv`.

---

## 3. Change Management (Where to edit what)

| Component   | Location                 | Agent Permission | Acceptance Criteria      |
| :---------- | :----------------------- | :--------------- | :----------------------- |
| **Scope**   | `docs/THESIS_SCOPE.md`   | **Read-Only**    | N/A (Human edits only)   |
| **Plan**    | `docs/ANALYSIS_PLAN.md`  | **Propose**      | Must align with Scope.   |
| **Code**    | `R-scripts/Kxx/`         | **Edit**         | Passes QC & Smoke tests. |
| **Data**    | `data/`                  | **Read-Only**    | N/A                      |
| **Outputs** | `R-scripts/Kxx/outputs/` | **Write**        | Logged in Manifest.      |

### 3.1 Acceptance Criteria for Code Changes

- **Unified Diff:** Changes submitted as patches.
- **No Regression:** Existing QC checks pass.
- **Documentation:** Updates to `README.md` or code comments if logic changes.

---

## 4. Known Uncertainties (TODOs)

- **Variable Map:** Confirm exact raw column names for `FOF`, `age`, `sex` (and any comorbidity variables) in `data_dictionary.csv`.
- **Time Coding:** Verify if `time` is coded as `0/1`, `baseline/m12`, or `0/12`.
- **Aim 2 data spec:** Confirm episode definitions, cost fields, and the exact linkage output schema delivered by the data controllers.
- **Directory Structure:** Confirm `R-scripts` folder hierarchy (K-folders).

_Reference: Research Plan (11 Oct 2025); Repo Rules (CLAUDE.md)._
