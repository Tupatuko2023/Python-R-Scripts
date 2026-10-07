# AIM1 Execution Plan

**DRAFT — non-authority planning layer.** No gate is resolved by constructing this
plan.

## Current state

```text
CURRENT_PHASE       = PRE_ANALYSIS
CURRENT_NEXT_TASK   = G6 — final AIM1 estimand set
PARTICIPANT_LEVEL_ANALYSIS_AUTHORIZED = NO
```

## Gate sequence (from the current gate dependencies)

```text
G6  final estimand set
 → G4  costing specification + AIM1 applicability
 → G3  hospital unit lock (days vs episodes)
 → G7  final covariate set
 → G11 + bounded aggregate QC   (exact N / eligibility boundaries = DATA_QC_DEPENDENT)
 → G8  final model-family lock
 → approved SAP
 → separately authorized participant-level analysis
```

Residual G5 sub-items (emigration/gap, cost accrual at death, person-time gap)
must be closed before the affected time/cost estimands.

## Rules

- Resolve one gate at a time through repository governance.
- Do **not** silently resolve any gate while planning.
- No participant-level data, no aggregate QC, no model fitting in the PRE_ANALYSIS
  phase except the explicitly authorized bounded aggregate QC at G11.
- The candidate SAP (`AIM1_CANDIDATE_SAP_v0.1.md`, source P1) is the planning
  target; it becomes executable only after the gates close and a separate analysis
  authorization is issued.

## First operational task — G6

**Goal:** decide the final AIM1 **estimand set** (core / secondary / sensitivity /
optional supplementary), on top of the adopted exposure (G1/G2) and resolved time
framework (G5 core).

**Inputs (available in this package):** the embedded candidate estimand inventory
in `ANALYSIS_DECISIONS.md` §4 (portable projection of the candidate SAP);
`ANALYSIS_DECISIONS.md`; the reconciled death/time handling.

**Output:** an estimand decision (Owner) recorded back into the Dissertation
repository, then mirrored here.

**Done when:** a new agent in Termux can discover G6 and its prerequisites from
this package alone, without a Windows lookup or Owner explanation.
