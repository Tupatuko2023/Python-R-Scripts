# Align K33-K38 to locomotor_capacity primary and z3 fallback

## Context

- Follow-up task after `tasks/03-review/k32-k33-k38-cfa.md`.
- Authoritative contract: `docs/ANALYSIS_PLAN.md`.
- Outcome roles locked by plan:
  - `locomotor_capacity` = current primary outcome
  - `z3` = deterministic fallback / sensitivity outcome
  - `Composite_Z` = legacy bridge only
- Goal: remove downstream assumptions that still present `z3` or obsolete `capacity_score_z5_primary` as current primary.
- Constraints: minimal reversible diffs, no raw-data edits, max 5 files changed this run, one manifest row per artifact, table-to-text crosscheck before review handoff.

## Inputs

- `docs/ANALYSIS_PLAN.md`
- `tasks/03-review/k32-k33-k38-cfa.md`
- `R-scripts/K33` through `R-scripts/K38`
- `manifest/manifest.csv`

## Outputs

- Minimal downstream primary/fallback alignment patches
- Regenerated K35-K38 artifacts where safe
- Review note with blocker status and diff-oriented summary

## Definition of Done (DoD)

- New follow-up task moves only `01-ready -> 02-in-progress -> 03-review`
- Corrected scripts treat `locomotor_capacity` as primary and `z3` as fallback/sensitivity only
- No active K33-K38 script/report expects `capacity_score_z5_primary` as current primary
- Manifest/output labels are outcome-explicit where regenerated
- Reruns attempted in dependency order; exact blocker logged if K33 still fails

## Log

- 2026-03-17 15:48:16+0200 Follow-up task created from repo-level template intent for locomotor_capacity primary alignment
- 2026-03-17 15:49:22+0200 Read `docs/ANALYSIS_PLAN.md` and prior review note `tasks/03-review/k32-k33-k38-cfa.md`; locked outcome roles to `locomotor_capacity` primary, `z3` fallback, `Composite_Z` legacy bridge.
- 2026-03-17 15:50:11+0200 Ran `fof-preflight`; status PASS.
- 2026-03-17 15:52:03+0200 Grep audit confirmed active downstream mismatch points in `K35`-`K38`: lingering `capacity_score_z5_primary` compatibility language, `Composite_Z` labels, and non-explicit outcome filenames.
- 2026-03-17 15:58:41+0200 Patched `K35`-`K38` so active primary/fallback selectors and reporting now use `locomotor_capacity` primary plus `z3` fallback semantics.
- 2026-03-17 16:00:40+0200 Reran `K35` and `K36` successfully in Debian PRoot with `DATA_ROOT=/data/data/com.termux/files/home/FOF_LOCAL_DATA`.
- 2026-03-17 16:02:29+0200 Reran `K37` and `K38` successfully after `K36` output-shape compatibility fix (`effect = fixed` for downstream consumers).
- 2026-03-17 16:03:08+0200 Reconfirmed `K33` blocker: `K18` QC handoff still fails in `qc_id_integrity_long` after embedded-null warnings from `VARIABLE_STANDARDIZATION.csv`.

## Blockers

- `tasks/_template.md` is not present under `Fear-of-Falling/tasks/`; using direct task instantiation again.
- `K33` still fails in the known `K18` QC handoff: `names(coverage_dist) <- c("n_timepoints", "n_ids")` after embedded-null warnings while reading `data/VARIABLE_STANDARDIZATION.csv`.
- Historical `Composite_Z` artifacts remain on disk in `R-scripts/K36/outputs/` and `R-scripts/K38/outputs/` from older runs; they were not deleted in this safe-mode run and should be treated as superseded, not current primary outputs.

## Links

- Prior review: `tasks/03-review/k32-k33-k38-cfa.md`
- Prompt packet: `prompts/2_6cafofv2.txt`

## Summary

- Active code changes this run: `R-scripts/K35/k35.r`, `R-scripts/K36/k36.r`, `R-scripts/K37/k37.r`, `R-scripts/K38/k38.r`.
- Primary/fallback contract after patch:
  - `locomotor_capacity` = active primary outcome branch
  - `z3` = deterministic fallback / sensitivity branch
  - `Composite_Z` = legacy bridge only; no longer used in active K36-K38 reruns
- Regenerated outcome-explicit artifacts now exist for K35-K38 and were appended to `manifest/manifest.csv`.

## Rerun Status

- `R-scripts/K35/k35.r`: PASS
- `R-scripts/K36/k36.r`: PASS
- `R-scripts/K37/k37.r`: PASS
- `R-scripts/K38/k38.r`: PASS
- `R-scripts/K33/k33.r`: FAIL in `K18` QC handoff (`qc_id_integrity_long`)

## Files Changed

- `R-scripts/K35/k35.r`
- `R-scripts/K36/k36.r`
- `R-scripts/K37/k37.r`
- `R-scripts/K38/k38.r`

## Primary/Fallback Replacements

- `K35` no longer frames the comparator as `z5`; it now labels `capacity_score_latent_primary` as the locomotor_capacity primary line and `capacity_score_z3_primary` as fallback.
- `K36` no longer models active downstream results on `Composite_Z`. It now reads canonical `fof_analysis_k50_long/wide` datasets and fits `locomotor_capacity` primary models plus parallel `z3` fallback models.
- `K37` no longer captions or plots `Composite_Z` trajectories. It now renders `locomotor_capacity` primary trajectories, a primary-vs-fallback coefficient comparison, and a `locomotor_capacity_0` vs `z3_0` baseline concordance figure.
- `K38` no longer reports “primary vs extended” language. It now reports `locomotor_capacity` primary vs `z3` fallback and writes an explicit outcome-labeled table: `k38_table_locomotor_capacity_primary_vs_z3_fallback.csv`.

## Regenerated Outputs

- `R-scripts/K35/outputs/k35_locomotor_capacity_behavior_summary.csv`
- `R-scripts/K35/outputs/k35_locomotor_capacity_distribution.csv`
- `R-scripts/K35/outputs/k35_locomotor_capacity_vs_z3_fallback.csv`
- `R-scripts/K36/outputs/k36_locomotor_capacity_lmm_fixed_effects.csv`
- `R-scripts/K36/outputs/k36_z3_fallback_lmm_fixed_effects.csv`
- `R-scripts/K36/outputs/k36_locomotor_capacity_ancova_coefficients.csv`
- `R-scripts/K36/outputs/k36_z3_fallback_ancova_coefficients.csv`
- `R-scripts/K36/outputs/k36_outcome_model_overview.csv`
- `R-scripts/K37/outputs/k37_locomotor_capacity_predicted_trajectories.png`
- `R-scripts/K37/outputs/k37_locomotor_capacity_vs_z3_model_comparison.png`
- `R-scripts/K37/outputs/k37_locomotor_capacity_vs_z3_baseline.png`
- `R-scripts/K38/outputs/k38_table_locomotor_capacity_primary_vs_z3_fallback.csv`
- `R-scripts/K38/outputs/k38_results_snippet.txt`
- `R-scripts/K38/outputs/k38_methods_snippet.txt`
- `R-scripts/K38/outputs/k38_discussion_snippet.txt`
- `R-scripts/K38/outputs/k38_figure_callouts.txt`

## Table-To-Text Crosscheck

- `K37` caption text now explicitly references `locomotor_capacity` and `z3`.
- `K38` results snippet matches the rerun table values: primary LMM `time_f12:FOF_statusFOF = 0.016`, fallback LMM `time_f12:FOF_statusFOF = 0.022`, and ANCOVA FOF estimates `-0.016` / `-0.035`.

## Manual Review

- Treat old `Composite_Z` CSV/TXT outputs in `K36` and `K38` as superseded until a later cleanup run is approved.
- Fix the `K33 -> K18` QC blocker separately if the legacy bridge dataset still needs rerunnable support.
