# TASK: Snakemake sample-mode verify + USE_SAMPLE parsing hardening

## STATUS
- State: 03-review
- Priority: Medium
- Assignee: Codex VSCode

## OBJECTIVE
- Harden use_sample parsing in Quantify-FOF-Utilization-Costs/workflow/Snakefile to avoid YAML string truthiness traps.
- Verify Snakemake sample-mode pipeline with --config use_sample=True (dry-run + summary + dag render).
- Keep Option B: no raw data, no absolute paths, no DATA_ROOT printing.

## DEFINITION OF DONE
- Snakefile parses use_sample safely:
  - USE_SAMPLE = str(config.get(""use_sample"", ""false"")).lower() in (""1"", ""true"", ""yes"", ""y"")
- Commits created.
- Verification commands attempted:
  - snakemake -n --config use_sample=True
  - snakemake --summary --config use_sample=True
  - snakemake --dag --config use_sample=True | dot -Tpng > outputs/dag.png
- Changes pushed to remote branch and verified (Remote Sync Rule).
- Task moved to 03-review (NOT 04-done; human moves after remote verified).

## LOG
- 2026-02-14T18:53:59+02:00 Created task file (metadata only).
- 2026-02-14T18:53:59+02:00 Moved to 02-in-progress.
- 2026-02-14T18:58:53.2292475+02:00 Verification blocked in this environment (no working Snakemake env). Moved to 03-review with blocker.
