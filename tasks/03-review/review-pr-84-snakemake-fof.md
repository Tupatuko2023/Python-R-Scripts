# TASK: Review PR #84: Snakemake workflow for Quantify-FOF-Utilization-Costs

## STATUS
- State: 03-review
- PR: #84
- Branch: add-snakemake-fof-13302765633610309720
- Assignee: Codex

## OBJECTIVE
- Review Snakemake DAG + Conda/renv bridge + Option B governance compliance.

## FINDINGS
### Blocking (resolved)
1. Preprocess no longer prints absolute paths for missing files.
2. Missing `DATA_ROOT` now exits non-zero (fail-closed).
3. `use_sample` is now routed via Snakefile to preprocess and inventory wrapper.

### Non-blocking
1. `docs/SNAKEMAKE.md` can be expanded with CI lint instructions and WSL2 details.

## VALIDATION
- `python scripts/10_preprocess_tabular.py --use-sample` (passed; wrote `outputs/intermediate/analysis_ready.csv` with 0 rows in sample-missing case)
- `snakemake -n` (blocked locally: command not found in current shell)

## RECOMMENDATION
- Needs local Snakemake verification in mamba env before merge.

## LOG
- 2026-02-14T18:16:13+02:00 Review task created and findings recorded.
- 2026-02-14T18:16:13+02:00 Blocking fixes implemented in preprocess, Snakefile, inventory wrapper, and config.
