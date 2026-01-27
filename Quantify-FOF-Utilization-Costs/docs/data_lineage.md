Data lineage (skeleton)

Goal: document end-to-end flow without embedding sensitive paths.

Sections:
1) Sources (repo-external): MFFP cohort + register extracts (controller delivery)
2) Inventory: scripts/00_inventory_manifest.py (metadata-only)
3) Preprocess: scripts/10_preprocess_tabular.py (schema validation + safe aggregates)
4) QC: scripts/30_qc_summary.py (non-sensitive summaries)
5) Knowledge package: scripts/40_build_knowledge_package.py (agent-ready bundle; no raw data)
