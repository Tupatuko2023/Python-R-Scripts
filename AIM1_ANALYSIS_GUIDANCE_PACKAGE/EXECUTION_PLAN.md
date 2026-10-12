# AIM1 Execution Plan

**DRAFT — non-authority planning layer.** No gate is resolved by constructing this
plan.

## Current state

```text
CURRENT_PHASE       = PRE_ANALYSIS
CURRENT_NEXT_TASK   = G4 — costing specification + AIM1 applicability
PARTICIPANT_LEVEL_ANALYSIS_AUTHORIZED = NO
```

## Gate sequence (from the current gate dependencies)

```text
G6  final estimand set          [RESOLVED / ADOPTED 2026-10-07]
  → G4  costing specification + AIM1 applicability   [NEXT]
 → G3  hospital outcome hierarchy [RESOLVED / ADOPTED]
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

## Operational task status

- **G6 (final estimand set): `RESOLVED / ADOPTED`** (Owner scientific decision
  2026-10-07). CORE = E1, E2, E4; SECONDARY = E3, E5, E6; SENSITIVITY = E8
  (separate authorization required); OPTIONAL_SUPPLEMENTARY = E-MORT (G10 open);
  DEFER = E-COMP.
- **NEXT_OPERATIONAL_TASK = G4** — costing specification + AIM1 applicability.

### G4 task

**Goal:** resolve the costing specification and its AIM1 applicability for the
adopted cost estimands — E4 (total direct specialised-care cost), E5 (outpatient),
E6 (inpatient): costing source, valuation, price year, perspective, zero-cost
handling, follow-up/person-time handling, and AIM1 applicability. Do not fabricate
costing details.

**Inputs (available in this package):** `ANALYSIS_DECISIONS.md` (G4 row + §4
inventory); `SOURCE_HANDOFF.md`.

**Output:** a costing decision (Owner) recorded back into the Dissertation
repository, then mirrored here.

**Done when:** a new agent in Termux can discover G4 and its prerequisites from
this package alone.

## G7 approved operational projection

```text
G7_PRIMARY = ADOPTED
PRIMARY_COVARIATES = baseline age, baseline sex
APPLICABILITY = E1-E4
E5_E6 = NEEDS_VERIFICATION
CAUSAL_MINIMAL_SUFFICIENCY = NOT_CLAIMED
ANALYSIS_AUTHORIZED = NO
```

## G3 approved operational projection

```text
G3 = RESOLVED / ADOPTED
E2 = PRIMARY: injury-related hospital days/person-year
E3 = SECONDARY: injury-related hospital episodes/person-year
G3_TECHNICAL_RULES = OPEN
```
