
# TASK: Security Audit & Path Sanitization

**Status**: 01-ready
**Assigned**: Gemini
**Created**: 2026-01-30
**Priority**: Critical

## OBJECTIVE

Ensure no absolute paths to sensitive data are committed to git or displayed in verbose logs. Sanitize manifest paths and verify gitignore coverage for sensitive metadata.

## INPUTS

* manifest/dataset_manifest.csv (target for inspection)
* .gitignore (target for update)
* scripts/ (check for hardcoded paths)

## STEPS

1. **Manifest Safety**:
* Check 'manifest/dataset_manifest.csv' for absolute paths (e.g., 'C:/Users/...').
* IF absolute paths exist: Add 'manifest/dataset_manifest.csv' to '.gitignore' immediately OR convert paths to relative.


2. **Git History Check**:
* Run 'git status' to ensure no secrets or external data files are staged.
* Verify no sensitive files are tracked in current HEAD.


3. **Output Hygiene**:
* Verify scripts output paths using '{DATA_ROOT}' placeholder logic instead of hardcoded absolute paths where applicable.



## ACCEPTANCE CRITERIA

* [ ] 'manifest/dataset_manifest.csv' is either gitignored OR contains no absolute paths.
* [ ] 'git status' is clean of sensitive files.
* [ ] No absolute paths to data found in recent logs or script outputs.
