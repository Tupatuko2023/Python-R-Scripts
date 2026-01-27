Quantify-FOF-Utilization-Costs

Aim 2: Quantify FOF-related health-service utilisation and costs (Finland, MFFP cohort + register linkage by controllers).

Data governance (Option B)
- No raw, decrypted, or participant-level register data is stored in this Git repository.
- Raw inputs must live outside the repo in a secure location (set DATA_ROOT).
- This repo contains only: metadata (manifest + dictionaries), schemas, documentation, synthetic test data, and pipeline scripts.

Project layout
- data/: metadata + synthetic samples (CI-safe)
- data/external/: placeholder only (gitignored)
- manifest/: dataset manifest + run logs (metadata only)
- scripts/: pipeline skeleton (safe-by-default)
- outputs/: generated QC/aggregate artifacts (ignored)
- tests/: CI-safe tests using synthetic sample only

Quickstart (synthetic / CI-safe)
From repo root:

1) Run tests:
python -m unittest discover -s Quantify-FOF-Utilization-Costs/tests

2) Smoke-run QC on synthetic sample:
python Quantify-FOF-Utilization-Costs/scripts/30_qc_summary.py --use-sample

NOTE: Run python Quantify-FOF-Utilization-Costs/scripts/00_inventory_manifest.py --scan paper_02 whenever you receive a new paper_02 data batch so the manifest stays in sync.

Quickstart (local with sensitive data)
1) Create Quantify-FOF-Utilization-Costs/config/.env from .env.example
2) Set DATA_ROOT to your secure repo-external data location (controller/permit compliant)
3) Inventory external files (metadata only; no copy into repo):
   python Quantify-FOF-Utilization-Costs/scripts/00_inventory_manifest.py --scan paper_02

If data is missing, scripts will exit with actionable instructions.

How to obtain data (high level)
Register linkage and extraction are handled by designated controllers under permits. This repo intentionally does not encode sensitive locations, keys, or any participant-level data.
