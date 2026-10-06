# AIM1 Analysis Guidance Package

**Repository:** Python-R-Scripts
**Path:** `AIM1_ANALYSIS_GUIDANCE_PACKAGE/`
**Status:** DRAFT / planning layer — NOT scientific authority, NOT an approved SAP.
**Baseline frozen:** 2026-10-05 (AIM1 Handoff Baseline v1).

This package is the smallest repository-governed layer that lets everyday AIM1
analysis planning continue **independently in Termux**, without routine access to
the Dissertation repository.

## Files

| File                       | Function                                             |
| -------------------------- | ---------------------------------------------------- |
| `README.md`                | this file — scope + usage + artifact index           |
| `ANALYSIS_DECISIONS.md`    | the single AIM1 decision table + the gate router     |
| `EXECUTION_PLAN.md`        | current phase, next operational task, gate sequence  |
| `SOURCE_HANDOFF.md`        | source index, traceability, refresh triggers         |
| `TERMUX_USAGE_AND_TEST.md` | Termux portability rules + the simulated Termux test |

## AIM1_SCOPE

**What AIM1 studies.** An observational, register-linked cohort study of whether
**baseline deficit-accumulation frailty** is associated with later **injury-related
specialised-healthcare utilisation** (outpatient/emergency visits; hospital care)
and the **direct costs** of those services, with an **optional supplementary**
mortality question. Injury-related = ICD-10 S00–S99 + T00–T14 (not confirmed falls).

**What AIM1 does NOT study / claim.** No causal effect; no cost-effectiveness; no
prediction-model development; no full-construct or external validation; no
primary-care / rehabilitation / social-care / societal costs.

**Primary exposure.** Continuous deficit-accumulation frailty index (0–1),
**ADOPTED** for AIM1 (Gate G1) from the DMA1 `METHODS_AND_SCORING.md` §3.1
20-component specification, computed with the observed-component denominator and
eligibility `O/N ≥ 0.80`.

**Outcome domains.** Utilisation (visits, hospital days, hospital episodes — days
vs episodes kept distinct) and direct specialised-care costs (total + components),
plus optional mortality.

**AIM1 / AIM2 boundary.** AIM1 owns the injury-related utilisation and cost
association for the frailty exposure; the fear-of-falling paper (V7/AIM2 area)
owns the FOF service-use/cost comparisons. Do not duplicate the same FOF group
comparisons as frailty main results. (Boundary source: S4.)

**Canonical scientific authority.** The Dissertation repository / DMA1. This
package never edits authority; it cites it by hash and refreshes on trigger.

## How to use (Termux)

1. Read `ANALYSIS_DECISIONS.md` for what is decided/open.
2. Read `EXECUTION_PLAN.md` for the current phase and next permitted task.
3. Use `SOURCE_HANDOFF.md` to know which authority to refresh and when.
4. Resolve the **next operational task** (G6) only through the governance of the
   analysis repository; do not edit the Dissertation repository from here.

## Non-authority statement

This package is a **handoff/planning convenience**. It cannot change a scientific
decision, adopt a version, or authorize analysis. All decisions are owned by the
Dissertation repository / DMA1, cited by `SOURCE_PATH` + hash with a refresh
trigger. Participant-level analysis is **not authorized**.
