# K50 figure inventory audit

## Goal

Determine deterministically whether the manuscript-proposed figure package
already exists in the K50 pipeline, is only partially supported, or is
missing. This is an evidence audit only, not a figure-production task.

Targets:

- Figure 1: analytic sample derivation / participant flow for WIDE vs LONG
- Figure 2: adjusted marginal means trajectory by baseline FOF
- Supplement S1: missingness by FOF group and time
- Supplement S2: sensitivity forest/effect summary
- Supplement S3: CFA loading / measurement summary

## Scope

- read-only audit of `R-scripts/K50/`, `manifest/manifest.csv`, manuscript
  drafts, and K50 outputs
- may create a small audit report or helper artifact if it improves evidence
  traceability
- do not create new official figures
- do not modify raw data

## Definition of Done

- each target figure is labeled `EXISTS_READY`, `PARTIAL_SUPPORT_ONLY`, or
  `MISSING`
- every non-missing status has explicit evidence files and artifact paths
- QC/diagnostic figures are distinguished from journal-ready figure candidates
- any new audit artifact is written under the standard K50 outputs path and
  logged to manifest one row per artifact

## Log

- 2026-03-20 00:08:00 +0200 task created from orchestrator prompt
- 2026-03-20 00:16:00 +0200 audited repo guidance, K50 outputs, manifest rows,
  and manuscript/review notes from `Fear-of-Falling/` without rerunning K50 or
  changing raw data
- 2026-03-20 00:17:00 +0200 wrote audit artifacts
  `R-scripts/K50/outputs/k50_figure_inventory_status.csv` and
  `R-scripts/K50/outputs/k50_figure_inventory_audit.md`; appended one manifest
  row per audit artifact

## Review Summary

- Figure statuses:
  - Figure 1 analytic sample flow: `PARTIAL_SUPPORT_ONLY`
  - Figure 2 adjusted marginal means trajectory: `PARTIAL_SUPPORT_ONLY`
  - Supplement S1 missingness by group/time: `PARTIAL_SUPPORT_ONLY`
  - Supplement S2 sensitivity forest/effect summary: `PARTIAL_SUPPORT_ONLY`
  - Supplement S3 CFA loading summary: `PARTIAL_SUPPORT_ONLY`
- Strongest positive evidence:
  - LONG cohort-flow render already exists under `diagram/` with matching
    manifest rows, but not as a combined WIDE-vs-LONG final figure
  - K50 missingness, primary/fallback/FI22 model-term tables, diagnostics, and
    standardized helper tables all exist with manifest support
  - upstream CFA loading tables exist under `R-scripts/K32/outputs/` and
    `R-scripts/K39/outputs/`
- Important negative evidence:
  - no ready primary locomotor-capacity trajectory figure was found in K50
    outputs or manifest
  - no missingness figure, sensitivity forest figure, or CFA loading figure was
    found as rendered artifacts
- QC distinction:
  - K50 diagnostics PNGs are real and manifest-backed, but they were explicitly
    classified as QC-only rather than part of the proposed manuscript figure
    package
