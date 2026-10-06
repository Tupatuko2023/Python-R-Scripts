# AIM1 Analysis Decisions + Gate Router

**DRAFT — non-authority planning layer.** Mirrors the Dissertation
`AIM1_PRE_ANALYSIS_GATE_REGISTER.md` / `OPEN_DECISION_REGISTER.md` by hash. Refresh
on the triggers in `SOURCE_HANDOFF.md`.

## 1. Decision table

| DECISION_ID | QUESTION | STATUS | DECISION | AUTHORITY | SOURCE_VERSION | WHAT_IT_ENABLES | WHAT_IT_BLOCKS | REFRESH_TRIGGER |
|---|---|---|---|---|---|---|---|---|
| G1 | Which DEAC version/exposure for AIM1? | **ADOPTED** | Adopt `METHODS_AND_SCORING.md` §3.1 DEAC 20-component spec as continuous 0–1 baseline exposure | Owner scientific decision 2026-10-05 | METHODS §3.1 `4fd2ddf3…` | exposure definition; eligibility; candidate SAP | nothing (closed) | new DEAC/AIM1 adoption decision |
| G2 | Missingness / eligibility / non-performance rules? | **ADOPTED** | Adopt DMA1-D-005 + D-008 with §3.1 component rules | Owner scientific decision 2026-10-05 | DECISION_LOG `131dab09…` | computable index; eligibility; QC spec | nothing (closed) | new missingness/non-performance decision |
| G5_CORE | Index date / follow-up end / death? | **RESOLVED_AUTHORITY_VERIFIED** | index = first MFFP visit; follow-up = index → death or 31 Dec 2019 | METHODS §2 / D-002 D (`FOR DRAFT`) | METHODS §2 `4fd2ddf3…` | time framework; person-time | time-based estimands until residuals decided | METHODS §2 / D-002 change |
| G5_RES_EMIG | Emigration / gap rules? | OPEN | — | Owner | — | — | time framework completeness | Owner decision |
| G5_RES_COST | Cost accrual at death? | OPEN | — | Owner | — | — | cost estimand | Owner decision |
| G5_RES_PT | Exact person-time gap handling? | OPEN | — | Owner | — | — | rate estimands | Owner decision |
| G6 | Final AIM1 estimand set? | OPEN — **NEXT TASK** | — | Owner | candidate SAP `fffc1e63…` | downstream G7/G8 | all estimation | G6 decision |
| G3 | Hospital unit lock (days vs episodes)? | OPEN | — | Owner | B6 `TABLE2_LOCKED_v2_collapsed_dx_days` | hospital outcome | hospital-primary statement | Owner lock |
| G4 | Costing specification + AIM1 applicability? | OPEN | — | Owner / data controller | W9/prior work | cost outcomes | cost estimands | costing metadata |
| G7 | Final covariate set? | OPEN | — | Owner | decision draft `736033da…` | models | model specification | G6 + G7 decision |
| G8 | Model-family lock? | OPEN | — | Owner + QC | candidate SAP §9 | model fitting | analysis | QC pass |
| G9 | Sensitivity set? | OPEN | — | Owner | reconciliation `ea817392…` | robustness | analysis | G6 decision |
| G10 | Mortality include/omit? | OPEN | — | Owner | candidate SAP §10 | optional module | mortality analysis | Owner decision |
| G11 | Analysis population / eligibility (exact N)? | OPEN | — | Owner + QC | adopted §3.1 eligibility | analysis population | analysis | G1/G2 (done) + QC |
| G12 | Ethics / permit documentation? | OPEN | — | Authority | — | manuscript/submission | submission only | permit document |

## 2. Gate router

| GATE_ID | STATUS | EXACT_UNRESOLVED_QUESTION | WHAT_BLOCKS | WHAT_DOES_NOT_BLOCK | NEXT_ALLOWED_ACTION | AUTHORITY_NEEDED | DATA_QC_DEPENDENCY | TERMUX_RESOLVABLE |
|---|---|---|---|---|---|---|---|---|
| G1 | ADOPTED | — | — | all | use adopted exposure | Owner (done) | no | yes (done) |
| G2 | ADOPTED | — | — | all | use adopted rules | Owner (done) | no | yes (done) |
| G5_CORE | RESOLVED | — | — | rate/time planning | plan person-time | Owner (done) | no | yes (done) |
| G5_RES_EMIG | OPEN | emigration/move censoring rule | time-based estimands | exposure/index | propose rule | Owner | no | yes |
| G5_RES_COST | OPEN | cost accrual at death | cost estimands | utilisation | propose rule | Owner | no | yes |
| G5_RES_PT | OPEN | person-time gap handling | rate estimands | cumulative/descriptive | propose rule | Owner | no | yes |
| G6 | OPEN (**next**) | final core/secondary/sensitivity estimand set | G7, G8, analysis | exposure/time/scope | draft estimand decision | Owner | no | yes |
| G3 | OPEN | primary hospital unit (days vs episodes) | hospital primary statement | visits/costs | propose lock | Owner | no | yes |
| G4 | OPEN | costing source/valuation/year/perspective/AIM1 applicability | cost estimands | utilisation | propose spec | Owner + controller | no | partial |
| G7 | OPEN | final covariate set | models | descriptives | propose covariate table | Owner | partial | yes |
| G8 | OPEN | model-family lock | model fitting | estimands | propose after QC | Owner | yes | partial |
| G9 | OPEN | sensitivity set | robustness reporting | primary analysis | propose set | Owner | partial | yes |
| G10 | OPEN | include mortality? | mortality module | core AIM1 | propose include/omit | Owner | no | yes |
| G11 | OPEN | analysis population / exact N | analysis | planning | propose eligibility | Owner | yes | partial |
| G12 | OPEN | permit document | manuscript/submission | analysis | locate document | Authority | no | partial |

## 3. Notes

- Gate semantics come from the real candidate SAP / gate-register definitions,
  not from the ID.
- G1/G2 are closed and must **not** be reopened. The G5 **core** must **not** be
  reopened; only its named residual sub-items are open.
- No gate is silently resolved by this package.
