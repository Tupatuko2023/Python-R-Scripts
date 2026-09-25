# DEAC → FIRA1 ANALYSIS HANDOVER

- STATUS: APPROVED_FOR_FIRA1_HANDOVER
- HANDOVER_VERSION: 1.0.0
- CREATED_DATE: 2026-09-23
- SOURCE_METHODS_VERSION: 0.4.1-draft
- SOURCE_METHODS_HASH: 192E59C6CE3D4F86CC1816E71ECBE68CB33205ACD23508147C9A521E5411ADAD
- AUTHORITY SOURCE: `METHODS_AND_SCORING.md` §3.1. If this handover and the
  canonical owner conflict, STOP; METHODS §3.1 wins; do not reconcile
  automatically.

## 1. Purpose

Hand the current approved DEAC operational specification to FIRA1 for
read-only implementation-feasibility planning in `Python-R-Scripts`. This
handover packages canonical state; it does not create or replace it.

## 2. Authority hierarchy

- **`METHODS_AND_SCORING.md` §3.1** = canonical scientific state **within the
  DMA1 Knowledge architecture**.
- **Scientific approval authority** = the **human dissertation Owner /
  researcher**. DMA1 does not itself decide science.
- **DMA1** = canonical Knowledge/state steward and meeting-analysis/
  governance workflow.
- **FIRA1** = research / implementation-feasibility and frailty-analysis
  assistant.
- **`Python-R-Scripts`** = implementation and validation repository.
- **`DATA_ROOT`** = participant-level source-data boundary.
- **This handover** = derived, non-canonical snapshot of §3.1.
- If this handover conflicts with `METHODS_AND_SCORING.md` §3.1: **STOP;
  §3.1 wins; do not reconcile automatically.**
- Implementation findings may trigger a scientific review; they must never
  silently rewrite scientific authority.

## 3. Paper-1 / DEAC direction change

Paper-1 direction changed 2026-09-17 (DMA1-D-001): from the FOF/frailty
physical-performance trajectory to frailty + FOF effects on accidental
hospital visits vs controls. DEAC is the current approved frailty
(deficit-accumulation) exposure. The prior FI22/C22 framing is **not** the
current implementation; the FI22/C22 relationship remains open (B2).

## 4. Current approved DEAC

`CURRENT_DEAC_OPERATIONALIZATION = APPROVED` (DMA1-D-007). The index is a
20-component deficit-accumulation index, 0 = better / 1 = greater deficit,
computed per §5–§6. The broader frailty framework is `PARTIALLY_DECIDED`.

## 5. 20-component snapshot

Components and approved scoring (snapshot of `METHODS_AND_SCORING.md` §3.1):

1. Diabetes — 0/1 as source-coded (`Index = diabetes * 1`).
2. Alzheimer / Parkinson / stroke-AVH — combined into one 0/1 neurological
   deficit.
3. Self-rated health — `source_value * 0.25` (0–1 in 0,25 steps).
4. MOI — remove age points first; then quintiles →
   `0 / 0,25 / 0,50 / 0,75 / 1`.
5. Alcohol — `category * 0.5` (0→0, 1→0,5, 2→1).
6. Hearing — 0→0, 1→1, 2→0.
7. Vision — 0→0, 1→1, 2→0.
8. Memory — 0→0; source categories 1/2 → 1.
9. Mood — 0→0; source categories 1/2 → 1.
10. Sleep — 0→0, 1→0,5, 2→1, 3→1, 4→1.
11. Self-rated mobility — `category * 0.5` (0→0, 1→0,5, 2→1).
12. Difficulty walking 500 m — `category * 0.5` (0→0, 1→0,5, 2→1).
13. Balance difficulty — 0→0, 1→1.
14. Previous fall — 0→0, 1→1.
15. Fear of falling (FOF) — 0→0, 1→1.
16. Pain (VAS) — `<4 → 0; 4–6 → 0,5; >6 → 1`.
17. Single-leg stance (better leg) — `<5 s → 1; 5–<10 s → 0,5; ≥10 s → 0`.
18. Five chair rises — `<11,20 s → 0; 11,20–<13,70 s → 0,25;
    13,70–<16,70 s → 0,5; 16,70–60,00 s → 0,75; >60,00 s → 1`. The
    historical/intermediate `0.05` line is **not** a scoring category.
19. Grip strength (better-hand source class) — class 0→1, 1→0,8, 2→0,6,
    3→0,4, 4→0,2, 5→0.
20. Maximal 10 m gait speed — `>1,0 m/s → 0; 0,6–1,0 m/s → 0,5; <0,6 m/s → 1`.

## 6. Missing / NA / nonperformance rules

- Eligibility (DMA1-D-005): `M/N ≤ 0,20 ⇔ O/N ≥ 0,80`; exactly 20 %
  permitted; integer form `O ≥ ceil(0,80·N)`; N=20 → 16 observed / 4
  missing INCLUDE, 15 observed / 5 missing EXCLUDE.
- Denominator (DMA1-D-005):
  `DEAC = (sum of observed deficit scores) / (number of observed components)`.
- Ordinary missing (DMA1-D-005): no value; not imputed.
- Not applicable (DMA1-D-008): handled as missing — no deficit score,
  excluded from the denominator; the ≥80 % eligibility rule still applies.
- Nonperformance (DMA1-D-008): for an applicable DEAC physical-performance
  test, physical/functional inability → deficit 1; other reason → missing.

## 7. FOF current status

FOF is a 0/1 component in the current approved DEAC (DMA1-D-009). A later
planned analysis compares DEAC with FOF vs DEAC without FOF; that planned
comparison does **not** make current inclusion open.

## 8. Still-open scientific questions (do NOT resolve)

- **B1** — DEAC index-level categorical cut-points: `NOT_YET_DECIDED`. This
  does **not** limit use of the approved DEAC as a **continuous 0–1 index**.
- **B2** — FI22/C22 relationship / framework naming: `OPEN`.

## 9. Implementation-QA questions (verification only, not scientific)

- MOI age-removal code correctness / MOI version.
- Better-hand formation for grip.
- Anomalous source codes → missing handling.
- Source-schema semantic definitions of numeric-coded categories
  (memory/mood categories 1/2, sleep levels, alcohol categories,
  hearing/vision class 2, self-rated health source scale).
- The non-adopted "maximal walking distance" note (no scoring rule).

## 10. Repository boundary

- Private dissertation repo (`FOF-Dissertation-Project`) owns scientific
  intent/authority (this handover's source).
- `Python-R-Scripts` owns reproducible implementation + validation.
- Implementation findings may trigger scientific review; they must never
  silently rewrite scientific authority.

## 11. DATA_ROOT boundary

- Participant-level data lives under `${DATA_ROOT}` outside both repos;
  never committed, copied, printed, or summarized with raw values.
- FIRA1 may read `DATA_ROOT` schema / data dictionary only as authorized by
  the analysis-repo governance; no raw values in any artifact.

## 12. FIRA1 permitted actions

- Read this handover and the `Python-R-Scripts` governance.
- Map each of the 20 canonical rules to source variables (schema / data
  dictionary only).
- Return per-component verdicts and an implementation plan.

## 13. FIRA1 prohibited actions

- Do NOT implement DEAC code in the first run.
- Do NOT change any scientific rule (component, score, boundary, missing,
  not-applicable, nonperformance, FOF) to fit implementation.
- Do NOT resolve B1/B2.
- Do NOT write DMA1 Knowledge.
- Do NOT access or commit `DATA_ROOT` participant-level data.

## 14. Validation contract (pre-specified for the later implementation)

Invariants:
- `0 ≤ component deficit ≤ 1`; `0 ≤ DEAC ≤ 1`.
- `observed < ceil(0,8 × relevant) → DEAC missing`.
- N=20, observed=16 → eligible; N=20, observed=15 → ineligible.
- not applicable → out of denominator.
- functional inability → deficit 1; other nonperformance → missing.

Boundary tests:
- pain: `3,99 / 4 / 6 / 6,01`;
- single-leg stance: `4,99 / 5 / 9,99 / 10`;
- chair-rise: `11,19 / 11,20 / 13,69 / 13,70 / 16,69 / 16,70 / 60 / >60`;
- gait: `0,59 / 0,60 / 1,00 / >1,00`.

## 15. Return contract

Return exactly one:

```text
DEAC_IMPLEMENTATION_FEASIBILITY_READY_FOR_OWNER_REVIEW
DEAC_IMPLEMENTATION_FEASIBILITY_BLOCKED
```

With per-component verdicts — `IMPLEMENTABLE` / `SOURCE_SCHEMA_UNRESOLVED` /
`IMPLEMENTATION_CONFLICT` / `DATA_DICTIONARY_GAP` — no code and no rule
changes.
