# Task: K40 FI KAAOS Supplementary Deficit Registry

## Context

FI22 pipeline is frozen as sensitivity index. The next step is a manuscript-ready supplementary deficit registry table.

## Plan

1. Generate supplementary registry from locked map + source-of-truth labels.
2. Ensure table includes var_name, label, domain, type, coding rule, and missing codes.
3. Update methods/QC documentation with explicit inclusion-rule wording.

## Done Criteria

- `R/40_FI/k40_fi22_deficit_registry.csv` exists and has 22 locked deficits.
- Methods document includes inclusion-rule sentence and missing-code handling clarity.

## Log

- 2026-03-06 07:20: Created supplementary deficit registry from `deficit_map.csv` and run `20260306_065213` labels.
