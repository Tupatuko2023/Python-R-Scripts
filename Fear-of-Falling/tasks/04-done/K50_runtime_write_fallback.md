# K50 runtime write fallback

## Context

Participant-level dedup is already frozen and validated. The remaining blocker
in the K50 main path is a runtime/write-path issue: the LONG confirmatory run
reaches artifact writing and then crashes in the Termux environment with the
known `readr`/`vroom` manifest bus error.

This task is strictly about runtime-safe artifact writing. It must not change
analysis logic, model formulas, participant selection, dedup policy, or the
shared helper.

## Inputs

- `R-scripts/K50/K50.r`
- `R/functions/reporting.R`
- `manifest/manifest.csv`

## Outputs

- smallest possible Termux-safe write fallback in the K50 main write path
- successful end-to-end `K50.r --shape LONG --outcome locomotor_capacity` run
- refreshed K50 main artifacts written without the Termux bus error

## Definition of Done (DoD)

- no changes to participant dedup, bridge mapping, or conflict policy
- K50 main reaches the write phase and completes successfully in the current
  runtime
- write fallback is scoped only to artifact/manifest writing
- cohort-flow reference counts remain the control reference:
  `527 / 14 / 8 / 225`

## Notes

- Treat this as an environment/runtime task, not an analysis bug.
- Prefer the smallest fallback possible, for example base-R `write.csv()` in
  Termux-sensitive write paths.

## Log

- 2026-03-16T03:59:00+02:00 Task created from orchestrator guidance to isolate
  the K50 Termux write-path bus error from the now-frozen participant-dedup
  work.
- 2026-03-16T04:03:00+02:00 Identified the failing path as
  `append_manifest()` in `R/functions/init.R`, where Termux was still reading
  and rewriting `manifest.csv` through `readr::read_csv()` / `readr::write_csv()`
  during artifact append.
- 2026-03-16T04:03:00+02:00 Added a minimal Termux-only manifest fallback in
  `R/functions/init.R`: manifest read/write now uses base-R
  `utils::read.csv()` / `utils::write.csv()` under Termux, while non-Termux
  runtimes keep the existing `readr` path. No analysis, model, dedup, or
  bridge logic was changed.
- 2026-03-16T04:05:00+02:00 First rerun passed the original bus-error point but
  stopped on a manifest schema mismatch: existing Termux-read `manifest.csv`
  exposed `n` as character while new rows still carried integer type. Manifest
  row normalization was added in `R/functions/init.R` so append operations use a
  stable all-character manifest schema across runtimes.
- 2026-03-16T04:07:40+02:00 `K50.r --shape LONG --outcome locomotor_capacity`
  completed successfully after the write fallback and manifest normalization
  patch. Main artifacts and manifest rows were written without the previous
  Termux `readr`/`vroom` bus error. Receipt diagnostics remained aligned with
  the frozen person-dedup state (`n_raw_person_lookup=527`,
  `ex_duplicate_person_lookup=14`, `ex_person_conflict_ambiguous=8`), while
  cohort-flow remains the control reference for `527 / 14 / 8 / 225`.
