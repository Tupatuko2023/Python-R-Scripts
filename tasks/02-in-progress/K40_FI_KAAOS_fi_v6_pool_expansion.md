# Task: K40 FI KAAOS FI_v6 Pool Expansion (deficit_map)

## Context
FI_v5 remains at ~22 selected deficits after deterministic exclusions and sentinel handling.
Main blocker is candidate pool size in the current KAAOS input block.

## Blockers
- Single-sheet KAAOS baseline block has limited non-performance/non-leakage deficits.
- Numeric-coded variable names need explicit domain/type/cutoff mapping for stable expansion.

## Plan
1. Add optional `R/40_FI/deficit_map.csv` support in `K40_FI_KAAOS.R`.
2. Keep hard exclusions deterministic (performance/exposure/lifestyle/demographic/falls toggle).
3. Allow map-driven overrides for `type`, `domain`, `priority`, and continuous cutoffs.
4. Emit aggregate artifact of applied mapping rows.

## Done Criteria
- Script runs with and without deficit map file.
- Decision log includes map status/row count.
- Aggregate file `k40_kaaos_deficit_map_applied.csv` is produced.
- Governance unchanged: patient-level output only to DATA_ROOT.

## Log
- 2026-03-05 21:10: Started FI_v6 map-based expansion implementation (template + loader + decision-log keys).
- 2026-03-06 03:03: Run OK with `DATA_ROOT` + `ID_COL=...1`; run_id=20260306_030345; selected_deficits=22; map loader active path keys written to decision log.
- 2026-03-06 03:03: `deficit_map.csv` not present (expected at this stage), so `deficit_map_loaded=FALSE` and `deficit_map_rows=0`.
