Decisions (ADR-lite)

- Data policy: Option B (repo contains metadata only; raw data repo-external).
- CI policy: all tests run without DATA_ROOT; synthetic sample only.
- Dependencies: prefer Python stdlib; optional extras gated behind try/except with friendly messages.
- READY closeout completed at commit 1b36623; next phase metadata expansion.
- Aggregate outputs gate: ALLOW_AGGREGATES=1 + --allow-aggregates; small-cell suppression n < 5; outputs gitignored.
- PDF/PPTX extractor uses layout-aware JSONL chunking; outputs gitignored; identifier safety check enforced.

- Knowledge package builder added: scripts/40_build_knowledge_package.py (zip + index.json; gitignored outputs; defense-in-depth identifier check).
