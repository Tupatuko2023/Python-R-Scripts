# Task: K40 domain overrides + export governance

## Context
K40.V2_frailty-index.R: domain_label fixed and k40_selected_deficits.csv externalized to DATA_ROOT.
Post-run QC: prop_other ~0.69 indicates domain classification insufficient for meaningful domain-balance QC.

## Objectives
- Make workflow-compliant record for the K40 domain-label + export-selected-deficits change already implemented.
- Prepare next step: reduce prop_other using deterministic domain overrides and other triage output.

## Definition of Done
- [x] K40.V2 includes methodological domain_label() (no other_<varname> fallback).
- [x] k40_selected_deficits.csv exported to DATA_ROOT/paper_01/frailty_vulnerability/.
- [ ] Add k40_other_vars_to_classify.csv output.
- [ ] Add optional config: k40_domain_overrides.csv (overrides-first).
- [ ] Re-run K40 and report prop_other target < 0.20 (prefer < 0.10).

## Notes
Branch: chore/k40-frailty-fix
Commit: 99a0f63
