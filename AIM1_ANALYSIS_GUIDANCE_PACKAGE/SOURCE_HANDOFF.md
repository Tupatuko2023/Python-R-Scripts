# AIM1 Source Handoff

**DRAFT — non-authority.** Source index + refresh triggers for the AIM1 Analysis
Guidance Package. Mirrors the Dissertation `AIM1_SOURCE_HANDOFF_PACKAGE.md` by hash.

## Authority sources (Dissertation repo)

| ID | SOURCE_REPO | SOURCE_PATH | VERSION/HASH | AUTHORITY_CLASS | CURRENT_STATUS | REFRESH_TRIGGER |
|---|---|---|---|---|---|---|
| S1 | FOF-Dissertation-Project | `docs/plans/research-plan/aim1.qmd` | blob `ddb27b91fde871a85ecef96698f63c0e2cb763ee` | SCIENTIFIC_AUTHORITY | maintained | aim1.qmd blob change |
| S2 | FOF-Dissertation-Project | `GPT/(DMA1) Dissertation Meeting Analyst/knowledge/METHODS_AND_SCORING.md` | `4fd2ddf3d19268fef09b90aa0d7ad8095dadb417b2601238fcfbebf1ec7aaaef` | SCIENTIFIC_OWNER_APPROVED (§3.1) | §3.1 ADOPTED | §3.1 / D-0xx change |
| S3 | FOF-Dissertation-Project | `GPT/(DMA1) Dissertation Meeting Analyst/knowledge/DECISION_LOG.md` | `131dab0920ed047422b5f228980489bab29973e382b8a29bb6909fe6db82c480` | APPROVED_DECISION_HISTORY | D-001…D-012 | new decision |
| S4 | FOF-Dissertation-Project | `docs/plans/research-plan/aim2.qmd` | blob `4ad2bdb518eb0ccfa72cf62b7ec7b1fbcb00a965` | SCIENTIFIC_AUTHORITY (AIM2 boundary) | maintained | aim2.qmd blob change |
| S5 | Python-R-Scripts | `DEAC-Frailty-Index/docs/DEAC_HANDOVER.md` | `b8527242bf9718ecbaddee6514837b2ad4f1b77c99b55bd18daf26abe3a00890` (v1.2.0) | DERIVED_SNAPSHOT | derived handover | handover version change |

## Planning artifacts (Dissertation staging, gitignored — copied here)

| ID | SOURCE_PATH (Dissertation staging) | SHA-256 | CURRENT_STATUS |
|---|---|---|---|
| P1 | `AIM1_CANDIDATE_SAP_v0.1.md` | `fffc1e63…` | candidate SAP (not approved) |
| P2 | `AIM1_PRE_ANALYSIS_GATE_REGISTER.md` | `80e75b62…` | gate register |
| P3 | `AIM1_ANALYSIS_DECISION_DRAFT.md` | `736033da…` | decision framework |
| P4 | `AIM1_ANALYSIS_EVIDENCE_RECONCILIATION.md` | `ea817392…` | reconciliation |
| P5 | `AIM1_DEAC_ADOPTION_DECISION_PACKET.md` | `749c8bdb…` | G1/G2 packet |
| P6 | `AIM1_G5_TIME_FRAME_RECONCILIATION.md` | `11a14f9c…` | G5 |
| P7 | `OPEN_DECISION_REGISTER.md` | `23d205bd…` | open decisions |
| P8 | `MANUSCRIPT_PROVENANCE_AND_OPEN_ITEMS.md` | `09431c0f…` | provenance |
| P9 | `METHODS_SOURCE_RESOLUTION.md` | `181dcdcf…` | source resolution |
| P10 | `AIM1_BMC_GERIATRICS_MANUSCRIPT_FOUNDATION.md` | `aee236c2…` | manuscript draft |
| P11 | `AIM1_HANDOFF_BASELINE_v1.md` / `AIM1_SOURCE_HANDOFF_PACKAGE.md` | (freeze) | frozen baseline |

## External evidence input (not authority)

| ID | SOURCE_PATH | SHA-256 | CURRENT_STATUS |
|---|---|---|---|
| X1 | `Frailty-indeksin analyysiopas.md` (NotebookLM) | `1fe47c70d4ad0d6f8b616eb05367a37bb96f8fc05c965e3f2211ac3254c492ae` | reconciled; not authority |

## Rules

- Changes flow **back** to the Dissertation repository; this package never edits
  the sources.
- Refresh when a trigger fires; re-copy the affected artifact and update its hash.
- No participant-level data, secrets, or Windows paths except as provenance.
