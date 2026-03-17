# Legacy cleanup superseded alignment

## Context

- Follow-up after `tasks/03-review/k33-locomotor-capacity-qc.md`.
- This run is limited to safe-mode ambiguity reduction only.
- No correctness fixes are reopened in this task.
- Authoritative contract: `docs/ANALYSIS_PLAN.md`.
- Outcome roles:
  - `locomotor_capacity` = current primary outcome
  - `z3` = deterministic fallback / sensitivity outcome
  - `Composite_Z` = legacy bridge only
- Constraints: max 5 files changed this run, no deletions, no raw-data edits, keep active human-readable references outcome-explicit.

## Inputs

- `prompts/4_6cafofv2.txt`
- `docs/ANALYSIS_PLAN.md`
- `tasks/03-review/k33-locomotor-capacity-qc.md`
- `R-scripts/K33/outputs/k33_patient_level_output_receipt.txt`
- `R-scripts/K36/outputs/k36_external_input_receipt.txt`
- `R-scripts/K38/outputs/k38_methods_snippet.txt`

## Outputs

- Superseded register documenting active K33 exports and legacy bridge leftovers
- Manifest rows for the new legacy-cleanup note and sessionInfo artifact
- Review note capturing the safe-mode cleanup scope and residual legacy files

## Definition of Done (DoD)

- Follow-up task moves only `01-ready -> 02-in-progress -> 03-review`
- No legacy files are deleted in safe mode
- Active references remain outcome-explicit (`locomotor_capacity` primary, `z3` fallback)
- Leftover generic K33 exports and older K36/K38 bridge-era artifacts are clearly marked as superseded
- Manifest and review note reflect the cleanup-only scope

## Log

- 2026-03-17 18:37:29+0200 Follow-up task created for safe-mode legacy cleanup and superseded alignment only.
- 2026-03-17 18:38:04+0200 Audited K33/K36/K38 human-readable receipts and snippets; active texts were already outcome-explicit, so the remaining need was an explicit superseded register rather than another modeling change.
- 2026-03-17 18:39:12+0200 Enumerated leftover generic K33 exports in `DATA_ROOT/paper_01/analysis/` and older K36/K38 aggregate artifacts retained in the repo from pre-alignment runs.
- 2026-03-17 18:40:03+0200 Added a safe-mode superseded register, wrote sessionInfo for this cleanup run, and appended manifest rows for both artifacts.
- 2026-03-17 18:40:48+0200 Re-ran preflight after documentation-only edits; status PASS.

## Blockers

- None for this cleanup-only scope.
- Historical files remain on disk by design because safe mode forbids unapproved deletion.

## Links

- Prior review: `tasks/03-review/k33-locomotor-capacity-qc.md`
- Prompt packet: `prompts/4_6cafofv2.txt`

## Summary

- Files changed this run:
  - `R-scripts/K33/outputs/k33_legacy_superseded_register.txt`
  - `manifest/manifest.csv`
  - `manifest/sessionInfo_legacy_cleanup_superseded_alignment.txt`
  - `tasks/03-review/legacy_cleanup_superseded_alignment.md`
- This run did not modify K33/K36/K38 code paths. It only reduced ambiguity by labeling which exports are active and which remaining files are superseded legacy bridge artifacts.

## What Changed

- Added a new superseded register under `R-scripts/K33/outputs/` that records:
  - active outcome-explicit K33 exports in `DATA_ROOT`
  - superseded generic `fof_analysis_k33_long/wide.*` bridge exports still present in `DATA_ROOT`
  - superseded historical K36/K38 aggregate outputs still present in the repo
- Added manifest rows for the superseded register and this run's sessionInfo artifact.
- Kept existing K33/K36/K38 receipts and snippets unchanged because they already point to the active outcome-explicit contract.

## Rerun Status

- `python .codex/skills/fof-preflight/scripts/preflight.py`: PASS

## Outputs Regenerated

- `R-scripts/K33/outputs/k33_legacy_superseded_register.txt`
- `manifest/sessionInfo_legacy_cleanup_superseded_alignment.txt`

## Manual Review

- Treat `fof_analysis_k33_long/wide.*` as superseded legacy bridge exports only.
- Treat `k36_*primary*`, `k36_*extended*`, `k36_*model_comparison*`, and `k38_table_primary_vs_extended.csv` as historical pre-alignment artifacts unless and until a future approved cleanup removes or archives them.
- Active manuscript-facing references should continue to cite the outcome-explicit `locomotor_capacity` primary and `z3` fallback outputs.
