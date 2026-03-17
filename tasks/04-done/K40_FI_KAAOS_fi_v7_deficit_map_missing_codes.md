# Task: K40 FI KAAOS FI_v7 Deficit Map Missing-Codes Hardening

## Context

FI_v6 introduced optional deficit map loading, but map-driven missing code handling was still absent.
This can bias FI upward when ordinal levels include explicit "ei tietoa" codes.

## Blockers

- "ei tietoa" codes in ordinal variables were not recoded to missing via deficit map.
- Map-level QC counters were not fully visible in decision log/red flags.

## Plan

1. Extend deficit-map schema with `missing_codes`.
2. Apply map-based missing-code recoding before candidate inventory and scoring.
3. Add audit counters:
   - map_missing_codes_applied_n
   - mapped_type_overrides_n
   - mapped_exclusions_n
   - n_selected_deficits_after_map
4. Seed active `R/40_FI/deficit_map.csv` for current FI22 set.

## Done Criteria

- K40 script runs with deficit map and writes outputs successfully.
- Decision log and red flags contain map QC counters.
- Selected deficits and domain balance are map-driven and deterministic.
- Governance unchanged: patient-level outputs only under DATA_ROOT.

## Log

- 2026-03-06 03:16: Implemented missing_codes parsing/apply in K40 script and updated template.
- 2026-03-06 03:21: Run OK with map active; run_id=20260306_032106; selected_deficits=20.
- 2026-03-06 03:21: QC counters: map_missing_codes_applied_n=946, mapped_type_overrides_n=2, mapped_exclusions_n=0.
- 2026-03-06 03:21: Ceiling checks stable: p_over_0.70=0, p95=0.4833, p99=0.5581.
- 2026-03-06 03:39: Added `k40_kaaos_map_drop_reasons.csv` artifact for keep=1 map rows.
- 2026-03-06 03:39: Updated map: vars 29 and 31 as binary (higher_worse) with missing_codes retained.
- 2026-03-06 03:39: Run OK (run_id=20260306_033927): n_selected_deficits_after_map=21; single drop reason was `27 -> n_levels_lt_3`.
