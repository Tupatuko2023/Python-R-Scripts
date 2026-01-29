Runbook (Option B, Aim 2)

This project is Option B: raw data stays outside the repo (DATA_ROOT). Repo contains only code + metadata + templates + synthetic sample.

1. Local setup (Termux/PRoot-safe)

1. Create local config (never commit):

Copy config/.env.example to config/.env

Set DATA_ROOT to an absolute path

1. (Optional) Enable aggregates when permitted:

Set ALLOW_AGGREGATES=1 in local config/.env

1. Inventory after each new paper_02 batch

python scripts/00_inventory_manifest.py --scan paper_02

1. QC (safe-by-default)

Sample (CI-safe):

python scripts/30_qc_summary.py --use-sample

1. Preprocess tabular

Sample (no aggregates):

python scripts/10_preprocess_tabular.py --use-sample

Aggregates (double-gated):

ALLOW_AGGREGATES=1 python scripts/10_preprocess_tabular.py --use-sample --allow-aggregates

Suppression applies for n < 5 (metrics blank, suppressed=1)

1. Reporting (non-sensitive)

Build report from QC + optional aggregates:

python scripts/50_build_report.py

Outputs are gitignored under outputs/reports/

Stdout & artifact safety (Option B)

Stdout and logs must never print absolute paths; print only repo-relative identifiers like outputs/...

QC/report/knowledge text artifacts are scanned with qc_no_abs_paths_check and must fail closed with a generic message (no match echoing).

XLSX parsing requires openpyxl; if an XLSX input is encountered and openpyxl is missing, scripts exit non-zero with a generic dependency error.

1. PDF/PPTX extraction (optional, layout-aware)

Requires optional parsers (pdfplumber/pypdf/python-pptx).

Run:

python scripts/20_extract_pdf_pptx.py --scan paper_02

Outputs are gitignored under docs/derived_text/

Safety: extractor is fail-closed on identifier-like tokens.

1. Knowledge package (agent-ready)

Default bundle (metadata + docs + manifests + tests):

python scripts/40_build_knowledge_package.py

Include derived text (optional):

python scripts/40_build_knowledge_package.py --include-derived

Outputs are gitignored under outputs/knowledge/

Common failure modes

DATA_ROOT missing: scripts exit cleanly with guidance.

Parser missing: extractor logs SKIPPED/ERROR with install guidance.

Safety check triggered: aborts; review derived_text and input source content.
