Review note - K50_FI22_primary_update

Status

PASS_WITH_ISSUES

High-level conclusion

The current `Fear-of-Falling/docs/ANALYSIS_PLAN.md` correctly implements the
intended FI_22-primary hierarchy:

- `frailty_index_fi` / `frailty_index_fi_z` are the primary frailty terms.
- `frailty_cat_3` and `frailty_score_3` are restricted to fallback /
  sensitivity use.
- FI-based terms appear in the primary wide and long model examples.
- FI QC / circularity requirements are explicitly documented.

Open review issues

1. Workflow DoD cannot be closed from `ANALYSIS_PLAN.md` alone.
2. The condition "no further analysis-document edits" is not fully
   diff-verifiable without `BEFORE_DOC` evidence.
3. The document contains broader structural / runbook additions beyond the
   narrow FI_22-primary correction.
4. Multi-level FI terminology remains manageable but should stay tightly
   separated: patient-level fields in formulas, variant labels only in
   provenance / QC text.

Review decision

Do not edit `ANALYSIS_PLAN.md` in this process-fix pass.

Keep task in `03-review`.

Human must decide whether:

- current state is acceptable for closure despite the documented audit
  limitations, or
- broader structural additions should be split into a separate task before
  final closure.
