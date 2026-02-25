# Implement Table 3 generation + Snakemake integration (Quantify-FOF-Utilization-Costs)

## Scope
- Add Table 3 R script under `Quantify-FOF-Utilization-Costs/R/20_table3/`
- Integrate target to Snakemake with stable outputs under `outputs/`
- Keep aggregate outputs gated (`ALLOW_AGGREGATES=1` + explicit intent argument)
- Update Snakemake docs and add short Table 3 runbook

## Deliverables
- `Quantify-FOF-Utilization-Costs/R/20_table3/20_table3_injury_usage_per_1000_py.R`
- `Quantify-FOF-Utilization-Costs/R/20_table3/README.md`
- `Quantify-FOF-Utilization-Costs/workflow/Snakefile` rule `table3`
- `Quantify-FOF-Utilization-Costs/docs/SNAKEMAKE.md` table3 usage notes

## Acceptance
- `snakemake -n` succeeds
- `snakemake --summary` includes table3 outputs
- `snakemake --dag | dot -Tpng > dag.png` works
- `snakemake -j 1 table3 --config use_sample=True allow_aggregates=True` produces:
  - `outputs/tables/table3.csv`
  - `outputs/tables/table3.md`
  - `outputs/logs/table3.log`

## Notes
- No hardcoded `DATA_ROOT` or absolute paths in script/docs.
- If `allow_aggregates=False`, `table3` fails closed by design.
