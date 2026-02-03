# CI Fix: Packaging Excludes outputs/ and Enforce DATA_ROOT Gate

## Context
Python CI-safe tests are failing:
- test_build_package_ci_safe includes outputs/ in the knowledge package zip.
- test_preprocess_refuses_without_data_root allows ETL to run without DATA_ROOT.

This task is separate from the Table 1 PR and must be done on a new branch off origin/main.

## Inputs
- Quantify-FOF-Utilization-Costs/tests/test_knowledge_package.py
- Quantify-FOF-Utilization-Costs/tests/test_security.py
- Packaging/zip builder and ETL/preprocess entrypoint used by tests

## Outputs
- Code changes that:
  1) deterministically exclude outputs/** (and logs/**) from the package zip
  2) fail-closed when DATA_ROOT is missing in the ETL/preprocess entrypoint

## Definition of Done (DoD)
- python3 -m unittest discover -s Quantify-FOF-Utilization-Costs/tests passes
- No changes to the Table 1 branch/PR
- Outputs/logs remain untracked

## Log
- 2026-02-03  Created task.
- 2026-02-03  Updated knowledge package builder to exclude outputs/; enforced DATA_ROOT env gating in preprocess; tests passing.

## Blockers
- None

## Links
- None
