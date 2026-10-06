# Termux Usage and Simulated Test

**DRAFT — non-authority.** How to use this package from Termux, and the required
self-containment test.

## 1. Portability rules

- All operational routing uses **repository-relative paths**, stable IDs and
  hashes. Windows paths appear in `SOURCE_HANDOFF.md` **as provenance only**.
- No file here requires reading `C:/GitWork/FOF-Dissertation-Project` to be
  understood: the decision content is summarised in `ANALYSIS_DECISIONS.md`.
- No participant-level data, secrets, or credentials are present.
- To resolve a gate, edit the **Dissertation** repository (its governance), then
  refresh the affected summary here (see `SOURCE_HANDOFF.md` triggers).
- This package is **not** the AIM1 plugin; it is the operational planning layer.

## 2. Simulated Termux test (package-only)

Answerable from this package alone, without consulting the Dissertation repository:

| #   | Question                                            | Answer derivable from                        | Answer                                                                                                                                                              |
| --- | --------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | What is AIM1?                                       | `README.md` AIM1_SCOPE                       | Observational register-linked cohort: baseline deficit-accumulation frailty vs later injury-related specialised-care utilisation + direct costs; optional mortality |
| 2   | What frailty exposure is adopted?                   | `README.md`, `ANALYSIS_DECISIONS.md` (G1)    | Continuous 0–1 DEAC 20-component index (`METHODS_AND_SCORING.md` §3.1), observed-component denominator, `O/N ≥ 0.80`                                                |
| 3   | What are G1 and G2?                                 | `ANALYSIS_DECISIONS.md`                      | G1 = DEAC/AIM1 exposure adoption; G2 = missingness/eligibility/non-performance — **both ADOPTED**                                                                   |
| 4   | What is the current index date?                     | `ANALYSIS_DECISIONS.md` (G5_CORE)            | the corresponding MFFP patient's **first MFFP visit**                                                                                                               |
| 5   | What is the current follow-up end?                  | `ANALYSIS_DECISIONS.md` (G5_CORE)            | **death or 31 December 2019**, whichever occurs first                                                                                                               |
| 6   | Which G5 items remain unresolved?                   | `ANALYSIS_DECISIONS.md` (G5*RES*\*)          | emigration/gap rules; cost accrual at death; exact person-time gap handling                                                                                         |
| 7   | Is participant-level analysis authorized?           | `EXECUTION_PLAN.md`                          | **NO**                                                                                                                                                              |
| 8   | What is the next permitted task?                    | `EXECUTION_PLAN.md`                          | **G6 — final AIM1 estimand set**                                                                                                                                    |
| 9   | What does G6 need to decide?                        | `EXECUTION_PLAN.md`, `ANALYSIS_DECISIONS.md` | the final core / secondary / sensitivity / optional supplementary estimand set                                                                                      |
| 10  | Where is the candidate SAP?                         | `SOURCE_HANDOFF.md` (P1)                     | Dissertation staging `AIM1_CANDIDATE_SAP_v0.1.md`, SHA-256 `fffc1e63…` (summarised here)                                                                            |
| 11  | Where is the gate register?                         | `SOURCE_HANDOFF.md` (P2)                     | Dissertation staging `AIM1_PRE_ANALYSIS_GATE_REGISTER.md`, SHA-256 `80e75b62…` (summarised here)                                                                    |
| 12  | When must Dissertation/DMA1 authority be refreshed? | `SOURCE_HANDOFF.md`                          | when a refresh trigger fires (any S1–S5 hash change, a new DMA1-D-0xx decision, or a new adoption)                                                                  |

**Result: all 12 answers derivable from the package alone → PASS.**

## 3. What the test proves / does not prove

- **Proves:** routine AIM1 planning (scope, decisions, phase, next task, gate
  routing) is answerable in Termux without a Windows lookup.
- **Does not prove:** that the package is yet committed/pushed to the
  Python-R-Scripts remote (so a fresh Termux clone can pull it). That is a
  separate governed Git step (see the run report).
