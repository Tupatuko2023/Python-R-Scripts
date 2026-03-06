# Task: K40 FI KAAOS FI_v8 Quick Patch + Pool Expansion Audit

## Context
FI_v7 was methodologically valid but retained one keep=1 map row dropping due to ordinal level rule.

## Plan
1. Quick patch: map var 27 as binary (0/1, missing code 2).
2. Re-run K40 FI pipeline and verify selected deficits.
3. Pool expansion audit from aggregate artifacts:
   - k40_kaaos_column_inventory.csv
   - k40_kaaos_var_labels.csv
   - k40_kaaos_numeric_candidates.csv

## Done Criteria
- Run succeeds with deterministic settings and map loaded.
- `n_selected_deficits_after_map` increases vs FI_v7 (target 22).
- `k40_kaaos_map_drop_reasons.csv` has no keep=1 non-selected rows.
- Audit list is produced with buckets:
  - possible_keep
  - possible_continuous_with_cutoff
  - exclude_followup
  - exclude_physiology
  - exclude_meta

## Log
- 2026-03-06 04:04: Started FI_v8 quick patch (var 27 binary) and pool expansion audit.
- 2026-03-06 04:01: FI_v8 quick patch run OK (run_id=20260306_040158), n_selected_deficits_after_map=22 and all keep=1 rows selected.
- 2026-03-06 04:03: Pool expansion audit generated (`k40_kaaos_pool_expansion_audit.csv`): possible_keep=3, possible_continuous_with_cutoff=3, exclude_followup=16, exclude_physiology=25, exclude_meta=6.
