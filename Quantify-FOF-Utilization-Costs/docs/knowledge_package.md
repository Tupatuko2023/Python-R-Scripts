Knowledge package (agent-ready, non-sensitive)

Purpose: create a portable bundle for agents and collaborators that contains only non-sensitive project context: metadata, manifests, documentation, and optional derived text chunks (JSONL).

Included
- data/ metadata (e.g., data_dictionary.csv, VARIABLE_STANDARDIZATION.csv)
- manifest/ CSVs (dataset_manifest.csv, run_log.csv)
- docs/ (methodology, decisions, aggregate_formats, reporting, knowledge_package)
- Optional docs/derived_text/ JSONL/logs (gitignored in repo, but may be bundled locally)
- tests/ (metadata/guardrail tests)

Excluded (never bundle)
- Raw data under repo-external DATA_ROOT
- Local secrets/config: config/.env
- Any participant-level exports under outputs/
- Any file that fails identifier safety checks

Outputs
- outputs/knowledge/knowledge_package.zip (gitignored)
- outputs/knowledge/index.json (inventory + checksums for bundled files)
