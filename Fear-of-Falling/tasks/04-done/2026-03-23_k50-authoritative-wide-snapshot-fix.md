# K50 authoritative WIDE snapshot and modeled-cohort provenance export fix

## Context

Fix K50 source-of-truth drift by locking one authoritative WIDE input snapshot, making canonical WIDE path resolution deterministic, and exporting modeled-cohort provenance from that same authoritative run.

## Inputs

- `R-scripts/K50/K50.r`
- `R-scripts/K50/k50_wide_authoritative_input.lock`
- `tasks/03-review/2026-03-23_k50-wide-source-of-truth-resolution.md`
- `R-scripts/K51/outputs/K51_linkage_population_disposition/k51_linkage_vs_k50_population_disposition_memo.md`
- `manifest/manifest.csv`

## Outputs

- K50 code fix for authoritative WIDE input resolution
- K50 modeled-cohort provenance export from the canonical run
- Review-ready task log

## Definition of Done (DoD)

- [x] K50 WIDE default input resolution is deterministic and hash-locked.
- [x] K50 receipt/provenance records explicit input hash and authoritative snapshot metadata.
- [x] K50 writes a modeled-cohort provenance artifact from the same canonical run.
- [x] K51 analytic Table 1 remains blocked in this pass.
- [x] Task is moved to `tasks/03-review/` after validation.

## Log

- 2026-03-23 16:32:00 +0200 Created K50-only source-of-truth fix task. This pass locks one authoritative WIDE snapshot and exports modeled-cohort provenance; K51 publication stays blocked.

- 2026-03-23 16:46:00 +0200 Added `R-scripts/K50/k50_wide_authoritative_input.lock` and updated `R-scripts/K50/K50.r` so default WIDE resolution is now deterministic and hash-verified against one authoritative `paper_02` snapshot.
- 2026-03-23 16:46:00 +0200 Added receipt/provenance fields for `input_resolution`, authoritative snapshot metadata, SHA-256, and explicit `rows_after_person_dedup`; added a new modeled-cohort provenance export from the same canonical run.
- 2026-03-23 16:46:00 +0200 Validation: `parse(file = "R-scripts/K50/K50.r")` passed, `fof-preflight` returned only a pre-existing K51 warning, authoritative lock hashes matched on disk, and `Rscript R-scripts/K50/K50.r --shape WIDE --outcome locomotor_capacity` completed successfully in Debian/proot with authoritative output `rows_modeled=230` and group split `69/161`.
- 2026-03-23 16:46:00 +0200 K51 manuscript-facing analytic Table 1 remains blocked by design in `tasks/02-in-progress/2026-03-23_k51-analytic-table1-implementation.md`; next task must consume the new authoritative K50 WIDE `n=230` rather than revisit K50 source-of-truth.

## Blockers

- None in this pass. K50 authoritative WIDE run completed; K51 publication remains intentionally blocked pending its separate follow-up task.

## Links
