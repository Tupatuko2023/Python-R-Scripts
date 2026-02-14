# Analytic Governance Summary

## Scope and Purpose
This document provides a one‑page, audit‑ready overview of governance for the Table 2 analysis pipeline. It covers cohort control, outcome definition, environment safeguards, QC procedures, and version locking.

## Cohort Governance (Snapshot Control, N‑Parity)
- The analytic cohort is defined by the current `aim2_analysis` snapshot.
- Current cohort size: FOF_No=144, FOF_Yes=330.
- Manuscript reported 147/330; the difference originates upstream (cohort snapshot), not from Table 2 filtering.
- Cohort parity is documented and traceable; deviations are recorded in methodology.

## Outcome Governance (Hospital Definition)
- Hospital outcome is locked to: dxfile → injury ICD‑10 (S00–S99, T00–T14) → date‑bounded merge → interval collapse → distinct days.
- This definition reproduces the manuscript scale for FOF_No (≈378/1000 PY).
- Broader T‑range (T00–T98) is treated as sensitivity only, not the primary definition.

## Environment Governance (Controlled Execution)
- All analysis runs are environment‑controlled via bootstrap and `.env`.
- Aggregated outputs require double‑gate authorization: `ALLOW_AGGREGATES=1` and `INTEND_AGGREGATES=true`.
- No participant‑level exports are written to repo artifacts.

## QC Governance (Stepwise Inclusion Audit)
- QC includes stepwise inclusion counts, linkage parity checks, follow‑up sanity, and hospital/outpatient sensitivity checks.
- QC results are aggregates only and do not expose identifiers or raw paths.
- QC is used to detect definition drift and explain deviations (e.g., cohort parity).

## Version Locking and Documentation Policy
- Table 2 definition is version‑locked: `TABLE2_LOCKED_v2_collapsed_dx_days`.
- Deviations from manuscript N are explicitly documented.
- Supporting notes are maintained in:
  - `docs/table2_technical_reproducibility_note.md`
  - `docs/methodology.md`
