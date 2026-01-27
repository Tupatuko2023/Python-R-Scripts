Reporting scaffold (non-sensitive)

This project writes reports only as non-sensitive summaries. Reports must never include participant-level rows.

Inputs
- QC outputs: outputs/qc/ (overview, missingness, schema drift, inputs)
- Optional aggregates: outputs/aggregates/aim2_aggregates.csv (already suppressed for n < 5)

Output
- outputs/reports/aim2_report.md (gitignored)

Guardrails
- No identifiers (e.g., id) or row-level exports.
- Small-cell suppression applies via the aggregates gate (see docs/aggregate_formats.md).
- If required inputs are missing, report generation must produce a placeholder explaining what is missing.
- Run logs must be metadata-only and written to a local, gitignored file (manifest/run_log.local.csv).
