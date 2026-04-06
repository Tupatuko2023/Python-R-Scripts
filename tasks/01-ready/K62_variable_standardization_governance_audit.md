# K62: variable standardization governance audit

## Context

- This is a new, separate audit task and must not reopen or extend K61.
- `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv` is the
  declared naming source of truth for the paper_02 pipeline, but current repo
  documentation shows a governance gap around what counts as truly frozen vs
  inferred / provisional mapping.
- `Quantify-FOF-Utilization-Costs/CLAUDE.md` and
  `Quantify-FOF-Utilization-Costs/docs/DATA_DICTIONARY_WORKFLOW.md` explicitly
  prohibit guessing names and define the expected flow as
  `INFERRED -> human verification -> freeze`.
- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md` also notes that the
  available snapshot does not include an explicit `verified=True` field, so the
  current "frozen" state is partly assumed rather than clearly governed.
- The purpose of K62 is to inventory governance-risk categories and prepare a
  decision basis for whether the next step should be a documentation rule,
  CSV cleanup, or a two-phase model.

## Inputs

- `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
- `Quantify-FOF-Utilization-Costs/docs/DATA_DICTIONARY_WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
- `tasks/_template.md`

## Outputs

- A scoped workflow record for auditing variable-standardization governance
  without changing the CSV in this phase.
- A completed K62 evidence bundle prepared from the reusable template.
- A decision-ready inventory of governance-risk categories before any cleanup
  task is authorized.

## Inventory Findings

- Total audited data rows: `493`
- Primary category counts:
  - `FROZEN`: `19`
  - `INFERRED`: `0` standalone rows
  - `TBD`: `193`
  - `UNNAMED / header-artifact`: `5`
  - `NUMERIC / list-artifact`: `132`
  - `REDACTED / unclear source`: `144`
  - `DUPLICATE / possible duplicate`: `0` as a primary category
  - `UNKNOWN`: `0`
- Cross-cutting duplicate signals:
  - duplicate `(source_dataset, original_variable)` keys: `69`
  - duplicate `standard_variable` values: `125`
- Governance gap summary:
  - `VARIABLE_STANDARDIZATION.csv` does not contain an explicit `verified`
    field.
  - `474` rows carry both `TBD` and inferred/Codex-scan style notes, so the
    `INFERRED -> human verification -> freeze` chain is not explicitly visible
    in the CSV snapshot itself.
  - The current file mixes likely frozen mappings, inferred mappings, artifact
    rows, redacted-source rows, and duplicate signals in one table without a
    formal status column.

## Example Rows By Category

- `FROZEN`
  - line `2`: `paper_02_outpatient | Henkilotunnus -> id | as_string`
  - line `5`: `paper_02_kaaos | ikä (a) -> age | as_integer`
  - line `10`: `paper_02_hfrs | pvm -> date_hfrs | date_parse_fi`
- `TBD`
  - line `288`: `Kopio_Tutkimusaineisto_osastojaksot_2010_2019.xlsx | IkaNyt -> age_nyt`
  - line `290`: `Kopio_Tutkimusaineisto_osastojaksot_2010_2019.xlsx | Kayntipvm -> visit_date`
  - line `292`: `Kopio_Tutkimusaineisto_osastojaksot_2010_2019.xlsx | Kuolinpvm -> death_date`
- `UNNAMED / header-artifact`
  - line `12`: `KAAOS_data.xlsx | Unnamed: 0 -> unnamed_0`
  - line `13`: `KAAOS_data.xlsx | Unnamed: 1 -> unnamed_1`
  - line `82`: `KAAOS_data_käyntipäivät ilman sotua.xlsx | Unnamed: 2 -> unnamed_2`
- `NUMERIC / list-artifact`
  - line `14`: `KAAOS_data.xlsx | 1. -> 1`
  - line `15`: `KAAOS_data.xlsx | 2. -> 2`
  - line `18`: `KAAOS_data.xlsx | 5. -> 5`
- `REDACTED / unclear source`
  - line `149`: `[REDACTED_NAME] | Unnamed: 0 -> unnamed_0`
  - line `152`: `[REDACTED_NAME] | 1. -> 1`
  - line `218`: `[REDACTED_NAME] | Unnamed: 0 -> unnamed_0`
- `DUPLICATE / possible duplicate` as cross-cutting signal
  - duplicate key example: `[REDACTED_NAME] | Unnamed: 0` at lines `149` and
    `218`
  - duplicate key example: `[REDACTED_NAME] | 1.` at lines `152` and `221`
  - duplicate standard example: `id` at lines `2` and `4`
- `INFERRED`
  - no standalone `INFERRED` rows were observed outside the broader `TBD` set;
    inferred status currently appears embedded in notes rather than exposed as a
    separate governed state.

## Recommendation

- Recommended next step for K63: `C` (two-phase model)
- Phase 1: add or lock an explicit governance rule that distinguishes frozen /
  verified rows from inferred / TBD / artifact rows.
- Phase 2: perform a scoped CSV cleanup only after that rule is explicit,
  including artifact removal / segregation and duplicate handling under human
  verification.

## Definition of Done (DoD)

- The task exists as a new standalone workflow item and was executed only after
  release to `tasks/01-ready/`.
- The task remains an audit / inventory task, not a CSV cleanup or code-change
  task.
- The governing rule `INFERRED -> human verification -> freeze` is used as the
  audit baseline.
- The inventory classifies all rows into an explicit primary category or shows
  that no rows remain `UNKNOWN`.
- The task documents the verified / frozen governance gap in the current CSV
  snapshot.
- A completed K62 evidence bundle exists and is based on the reusable
  template.
- No changes are made in this step to
  `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`.

## Log

- 2026-04-05 00:00:00 Created as a backlog governance-audit task for
  `VARIABLE_STANDARDIZATION.csv` after K61 closed the placeholder-wording debt
  in `ANALYSIS_PLAN.md`.
- 2026-04-06 00:10:00 Released to `tasks/01-ready/` and executed as a
  read-only inventory / governance audit.
- 2026-04-06 00:20:00 Audited `493` data rows; only `19` rows appear frozen by
  transform-rule evidence, while `474` rows carry `TBD` plus inferred/Codex
  scan signals and the CSV still lacks an explicit verified-status field.
- 2026-04-06 00:25:00 Recommended K63 as a two-phase follow-up:
  governance-rule clarification first, then scoped CSV cleanup under explicit
  freeze / verification rules.

## Blockers

- K62 must not edit `VARIABLE_STANDARDIZATION.csv` in this phase.
- K62 must not invent new standard names or silently convert inferred rows into
  frozen mappings.
- Execution is complete; any further work should move to a separate K63-style
  fix task rather than expanding K62 into cleanup.

## Links

- `Quantify-FOF-Utilization-Costs/data/VARIABLE_STANDARDIZATION.csv`
- `Quantify-FOF-Utilization-Costs/docs/DATA_DICTIONARY_WORKFLOW.md`
- `Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md`
- `Quantify-FOF-Utilization-Costs/CLAUDE.md`
- `Quantify-FOF-Utilization-Costs/docs/evidence_bundle_template.md`
