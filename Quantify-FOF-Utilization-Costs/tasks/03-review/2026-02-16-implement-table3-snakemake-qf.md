# Implement Table 3 generation + Snakemake integration (Quantify-FOF-Utilization-Costs)

## Scope
- Add Table 3 R script under `R/20_table3/`
- Integrate as Snakemake target
- Outputs: `outputs/tables/table3.csv` + `outputs/tables/table3.md`
- Log: `outputs/logs/table3.log`

## Deliverables
- R script: `R/20_table3/20_table3_injury_usage_per_1000_py.R`
- Snakemake rule: `workflow/Snakefile`
- Config: `config/config.yaml` (`table3` section)
- Readme: `R/20_table3/README.md`

## Acceptance criteria
- `snakemake -n` succeeds
- `snakemake --summary` succeeds
- `snakemake -j 1 table3` produces `outputs/tables/table3.csv` and `outputs/tables/table3.md` when inputs exist

## Verification commands
```bash
cd Quantify-FOF-Utilization-Costs
snakemake -n
snakemake --summary
snakemake -j 1 table3
snakemake -j 1 --forcerun build_table3_inputs table3
```

## Log
- 2026-02-16: Task created.
- 2026-02-16: User-provided draft existed as untracked file; left untouched; integrated via clean copy under `R/20_table3/`.
- 2026-02-16: Verification: `snakemake -n` and `snakemake --summary` passed; `snakemake -j 1 table3` reached script execution and failed only due to missing configured input files (`Visits input not found`).
- 2026-02-16: Added deterministic Table 3 build-input stage (`build_table3_inputs`) writing `DATA_ROOT/derived/table3_visits_input.csv` + `DATA_ROOT/derived/table3_treat_input.csv`; wired as dependency before `table3`.
- 2026-02-16: Added fail-closed controls config/gates: `table3.cohort_file`, `table3.cohort_sheet`, `table3.cohort_id_col`, `table3.case_flag_col`, `table3.case_flag_case_value`, `table3.controls_link_table`, `table3.controls_panel_file`; build now stops with actionable message when controls linkage/panel is missing.
- 2026-02-16: Added ID disjointness gate in build step (`case_ids ∩ control_ids = ∅` required).
- 2026-02-16: Verification: `snakemake -n table3` succeeds (dry-run). Forced execution (`snakemake -j 1 --forcerun build_table3_inputs table3`) fails closed at `outputs/logs/table3_inputs.log` with `Controls linkage gate failed: roster contains controls but table3.controls_link_table is empty.`
- 2026-02-16: Current blocker (data): missing `controls_link_table` and `controls_panel_file` in DATA_ROOT-compatible ID space; task remains in `03-review` pending data delivery + remote sync/PR verification.
