# K32 runtime recovery and clean rerun

## Context

Participant-level dedup is already frozen and validated upstream. The remaining
K32 blockers are runtime/environmental: local Termux R is missing `lavaan`, and
the Debian proot runner currently fails during startup. Because K32 has not
been rerun cleanly since the dedup migration, old output artifacts still remain
and privacy grep continues to hit stale files.

This task is strictly about restoring a working K32 runtime and replacing stale
artifacts with clean rerun outputs. It must not change participant selection,
dedup policy, shared helper logic, or conflict handling.

## Inputs

- `R-scripts/K32/k32.r`
- `R-scripts/K32/k32_validation.r`
- current K32 runtime environment under Termux / proot
- `R-scripts/K32/outputs/`

## Outputs

- recovered runtime capable of executing `k32.r` and `k32_validation.r`
- fresh K32 outputs generated from the current deduplicated upstream logic
- stale privacy-leaking K32 artifacts removed or replaced by clean rerun outputs

## Definition of Done (DoD)

- no new dedup algorithm or participant-policy change is introduced
- `k32.r` completes successfully in a stable runtime
- `k32_validation.r` completes successfully in the same stable runtime
- stale K32 output artifacts that trigger privacy grep are replaced or removed
- privacy grep over current K32 outputs is clean

## Notes

- Fix runtime first, then rerun, then clean/replace artifacts.
- Treat `lavaan` availability and proot startup as environment recovery work,
  not analysis logic work.

## Log

- 2026-03-16T03:59:00+02:00 Task created from orchestrator guidance to isolate
  K32 runtime recovery and clean rerun from the already completed participant
  dedup migration.
- 2026-03-16T04:11:00+02:00 Verified that both the local Termux renv and the
  Debian proot runtime see `lavaan`; the usable runner is Debian proot when
  `PATH` is restricted to system binaries and `config/.env` is sourced before
  `/usr/bin/Rscript`.
- 2026-03-16T04:13:00+02:00 `k32.r` completed successfully in the recovered
  Debian runtime, wrote refreshed K32 output artifacts under
  `R-scripts/K32/outputs/`, and regenerated canonical K50 input files under
  `DATA_ROOT/paper_01/analysis/`.
- 2026-03-16T04:15:00+02:00 `k32_validation.r` first failed on a runtime join
  type mismatch (`character` vs `double`) in the optional K15 frailty join.
  This was fixed by normalizing `.join_key` to trimmed character on both sides.
- 2026-03-16T04:16:00+02:00 `k32_validation.r` then failed on output-schema
  compatibility because the regenerated K32 score dataset exposes baseline
  indicator columns as `indicator_*_0`. Validation was updated to accept these
  canonical baseline names without changing any participant or dedup logic.
- 2026-03-16T04:17:00+02:00 `k32_validation.r` completed successfully in the
  same recovered Debian runtime and wrote refreshed validation artifacts,
  including the upstream dedup note.
- 2026-03-16T04:17:00+02:00 Privacy grep over `R-scripts/K32/outputs` and
  `manifest/manifest.csv` returned clean after the rerun, indicating the old
  `sotu`/workbook-path leaking artifacts were successfully replaced by the new
  clean outputs.
