# Thesis Scope & Guardrails (Fear-of-Falling)

**Status:** Active
**Last Updated:** 2025-12-29
**Anchors:** [ANALYSIS_PLAN](ANALYSIS_PLAN.md), [QC_CHECKLIST](../QC_CHECKLIST.md)

This document defines the **scope boundaries** and **technical guardrails** for the Fear-of-Falling (FOF) subproject. It translates the research plan (dated 11 Oct 2025) into actionable constraints for the codebase agent.

---

## 1. Research Scope (Immutable Core)

The following elements are derived from the approved research plan and **must not be changed** without explicit authorization.

### 1.1 Study Design

* **Design:** Longitudinal observational cohort study.

* **Population:** Older adults (MFFP cohort).

* **Timepoints:** Baseline ($T_0$) and 12-month follow-up ($T_{12}$).

* **Intervention:** None (observational).

### 1.2 Scientific Aims (Simplified)

| Aim | Description | Key Analysis |
| :--- | :--- | :--- |
| **Aim 1** | Determine if baseline FOF predicts physical performance change. | LMM: `Composite_Z ~ time * FOF_status` |
| **Aim 2** | Robustness check for Aim 1. | ANCOVA: `Composite_Z2 ~ FOF_status + Composite_Z0` |
| **Aim 3** | Identify moderators (e.g., SRH, morbidities). | Interaction models (FOF × Moderator). |

### 1.3 Core Definitions (Do not reinvent)

* **Fear of Falling (FOF):** Binary status (0 = No FOF, 1 = FOF). Source: `kaatumisenpelkoOn`.

* **Outcome:** Physical performance composite score (Z-score standardized).

* **Follow-up:** 12 months (tolerance ± window defined in QC).

---

## 2. Technical Guardrails

### 2.1 Privacy & Governance

1. **No PII:** Never output tables or logs containing participant IDs, names, or birthdates.
2. **Aggregate Only:** QC artifacts must aggregate data (counts, distributions), not list individual rows.
3. **Local Execution:** Analysis runs locally. Do not upload raw data to external services.

### 2.2 Data Integrity

1. **Read-Only Raw Data:** Files in `data/raw/` (or equivalent) are immutable.
2. **No Manual Edits:** All data cleaning and transformation must be performed by reproducible R scripts.
3. **Strict QC:** No modeling before passing `K18_QC` gates (see [QC_CHECKLIST](../QC_CHECKLIST.md)).

### 2.3 Reproducibility

1. **Environment:** Use `renv` for package management.
2. **Randomness:** Use `set.seed(20251124)` *only* when necessary (bootstrap/MI).
3. **Artifact Tracking:** Every output file must be logged in `manifest/manifest.csv`.

---

## 3. Change Management (Where to edit what)

| Component | Location | Agent Permission | Acceptance Criteria |
| :--- | :--- | :--- | :--- |
| **Scope** | `docs/THESIS_SCOPE.md` | **Read-Only** | N/A (Human edits only) |
| **Plan** | `docs/ANALYSIS_PLAN.md` | **Propose** | Must align with Scope. |
| **Code** | `R-scripts/Kxx/` | **Edit** | Passes QC & Smoke tests. |
| **Data** | `data/` | **Read-Only** | N/A |
| **Outputs** | `R-scripts/Kxx/outputs/` | **Write** | Logged in Manifest. |

### 3.1 Acceptance Criteria for Code Changes

* **Unified Diff:** Changes submitted as patches.

* **No Regression:** Existing QC checks pass.

* **Documentation:** Updates to `README.md` or code comments if logic changes.

---

## 4. Known Uncertainties (TODOs)

* **Variable Map:** Confirm exact column names for `age`, `sex` in `data_dictionary.csv`.

* **Time Coding:** Verify if `time` is coded as `0/1`, `baseline/m12`, or `0/12`.

* **Directory Structure:** Confirm `R-scripts` folder hierarchy (K-folders).

*Reference: Research Plan (11 Oct 2025); Repo Rules (CLAUDE.md).*
