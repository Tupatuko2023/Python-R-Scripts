Methodology (skeleton)

Aim 2 scope
- Quantify FOF-related health-service utilisation and costs.
- Register linkage and delivery are controller-managed; repo stores metadata only.

Key metrics (placeholder definitions)
- Utilisation counts: total, outpatient, inpatient, emergency, primary care.
- Inpatient burden: inpatient days.
- Costs: total EUR and components (inpatient, outpatient, medication) where available.
- Time window: period_start, period_end, followup_days.
- Covariates: FOF_status, age, sex (TBD), BMI (kg/m^2).

Allowed in-repo outputs
- Non-sensitive QC summaries and aggregates only (counts, missingness, schema drift).
- No participant-level extracts or raw register files stored in repo.

Allowed aggregate outputs
- Aggregates are opt-in (double gate): ALLOW_AGGREGATES=1 and --allow-aggregates.
- Small-cell suppression applies (n < 5): metrics suppressed.
- No participant identifiers are written to aggregates.
- See: docs/aggregate_formats.md

Unstructured inputs (PDF/PPTX)
- Layout-aware extraction writes JSONL chunks (text vs tables) into docs/derived_text/ (gitignored).
- Extraction is optional and depends on available parsers (pdfplumber/pypdf/python-pptx).
- Safety check aborts if identifier-like tokens are detected.
