# K50 FIG2 review follow-up

## Context

Sourcery review flagged two maintainability and bug-risk items in the K50 Figure 2 V3 script: repeated literal contrast labels and implicit ordering assumptions in the emmeans contrast vectors. The same review also noted that manifest rows for unchanged artifact paths should be idempotent across reruns.

## Inputs

- `R-scripts/K50/K50.V3_make-fig2-contrast-focused.R`
- Sourcery review comments on contrast ordering and manifest behavior

## Outputs

- updated `R-scripts/K50/K50.V3_make-fig2-contrast-focused.R`
- rerun FIG2 artifacts with unchanged estimates and duplicate-safe manifest rows

## Definition of Done (DoD)

- Contrast labels are defined once and reused throughout the script.
- Between-group and DID contrasts are built from the actual emmeans grid ordering rather than hard-coded assumptions.
- Manifest updates are idempotent for unchanged FIG2 artifact paths.
- The rerun succeeds and contrast estimates remain unchanged.

## Log

- 2026-03-27T00:12:00+02:00 Added shared contrast label constants, replaced implicit emmeans ordering assumptions with grid-derived weights, and changed manifest writes to idempotent upserts.
- 2026-03-27T00:19:00+02:00 Validated with `fof-preflight`, parse-check, and two end-to-end reruns in Debian PRoot; estimates were unchanged and FIG2 manifest paths remained duplicate-free across reruns.
- 2026-03-27T00:00:00+02:00 Task created to address Sourcery review comments on the K50 FIG2 V3 script without changing the underlying model or estimates.
