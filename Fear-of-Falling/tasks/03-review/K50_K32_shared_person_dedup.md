# K50/K32 shared person dedup

## Context

K50 cohort-flow already uses workbook-grounded person dedup, but K50 main and
the upstream K32 canonical export path must use the same person basis so the
analysis does not mix 527-person cohort-flow counts with 551 id-level inputs.

## Inputs

- `R/functions/person_dedup_lookup.R`
- `R-scripts/K50/K50.r`
- `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R`
- `R-scripts/K32/k32.r`

## Outputs

- shared workbook-grounded person dedup helper
- K50 main script deduplicating canonical inputs before modeling
- K50 cohort-flow refactored to the shared helper
- K32 upstream export deduplicating workbook persons before canonical K50 export

## Definition of Done (DoD)

- shared helper resolves `DATA_ROOT`, workbook lookup, and `id <-> NRO`
  bridging
- K50 main and cohort-flow report the same aggregate dedup diagnostics
- K32 canonical export is produced from a deduplicated workbook person basis
- no output or receipt writes SSN values

## Log

- 2026-03-15T21:35:00+02:00 Task created to move validated K50 person dedup
  into a shared helper and apply it to both K50 main and K32 upstream export.
- 2026-03-15T21:44:00+02:00 Added shared helper
  `R/functions/person_dedup_lookup.R` with `.env` fallback, workbook lookup,
  `id <-> NRO` bridge resolution, SSN normalization, person-key attachment, and
  shared LONG/WIDE dedup candidate selection.
- 2026-03-15T21:44:00+02:00 Patched `R-scripts/K50/K50.r` to run the shared
  person dedup immediately after canonical input load and to record aggregate
  dedup diagnostics in decision and receipt artifacts.
- 2026-03-15T21:44:00+02:00 Patched
  `R-scripts/K50/K50.1_COHORT_FLOW.V1_derive-cohort-flow.R` to consume the
  shared helper while preserving the validated production counts path.
- 2026-03-15T21:44:00+02:00 Patched `R-scripts/K32/k32.r` so workbook persons
  are deduplicated before score derivation and canonical K50 export, using
  `Sotu` as person key and workbook `NRO`/canonical `id` only as the bridge.
- 2026-03-15T21:47:00+02:00 Cohort-flow regression check passed after the
  refactor. Reference counts remained:
  `N_RAW_PERSON_LOOKUP=527`,
  `EX_DUPLICATE_PERSON_LOOKUP=14`,
  `EX_PERSON_CONFLICT_AMBIGUOUS=8`,
  `N_ANALYTIC_PRIMARY=225`.
- 2026-03-15T21:47:00+02:00 K50 main run reached output writing but hit the
  known Termux `readr`/`vroom` manifest bus-error in `append_manifest()`. This
  is a runtime blocker in artifact writing, not a dedup logic failure.
- 2026-03-15T21:47:00+02:00 K32 end-to-end validation is still blocked by the
  local runtime: direct Termux R is missing `lavaan`, and Debian proot failed
  during base `utils`/`uname` startup. The K32 patch is syntactically valid but
  not fully runtime-validated in this session.
- 2026-03-15T21:49:00+02:00 Public K32 artifact writing was tightened so the
  script no longer emits the protected `sotu` column name or the raw workbook
  filename into newly generated public decision/receipt artifacts.
- 2026-03-15T21:50:00+02:00 This run was intentionally capped to five edited
  files by steering. K50 ancillary consumer scripts were therefore left
  unchanged in code, but the upstream K32 canonical export and the K50 main
  and cohort-flow paths now share the same person-dedup policy. A follow-up run
  can still wire the ancillary scripts directly to the shared helper if direct
  in-script dedup is required there as well.
