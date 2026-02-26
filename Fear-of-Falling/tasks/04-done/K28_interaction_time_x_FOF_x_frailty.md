# K28 interaction: time × FOF × frailty

## Context
Tuotantovalmis K28-analyysi tarvitaan long-datalle: 3-way interaktio
`time × FOF_status_f × frailty_score_3` (jatkuva) ja optionaalinen
`time × FOF_status_f × frailty_cat_3` (kategorinen), mixed model
`(1|id)`, raportointikelpoiset taulukot ja lyhyt suomenkielinen tulkintateksti
projektin CLAUDE/AGENTS/manifest-konventioilla.

## Inputs
- `analysis_long` (objekti tai projektin tukema CSV-lataus)
- Pakolliset sarakkeet: `id`, `time`, `Composite_Z`, `FOF_status`, `frailty_score_3`
- Optionaalinen sarake: `frailty_cat_3`
- Ohjeet: `CLAUDE.md`, `AGENTS.md`, `WORKFLOW.md`, `agent_workflow.md`

## Outputs
- `R-scripts/K28/k28.r`
- `R-scripts/K28/outputs/FOF_x_time_x_frailtyScore_on_CompositeZ_fixed_terms.csv`
- `R-scripts/K28/outputs/FOF_x_time_x_frailtyScore_on_CompositeZ_fixed_terms.rds`
- `R-scripts/K28/outputs/FOF_x_time_x_frailtyScore_on_CompositeZ_change_by_frailty.csv`
- (jos `frailty_cat_3` löytyy)
  - `R-scripts/K28/outputs/FOF_x_time_x_frailtyCat_on_CompositeZ_fixed_terms.csv`
  - `R-scripts/K28/outputs/FOF_x_time_x_frailtyCat_on_CompositeZ_fixed_terms.rds`
  - `R-scripts/K28/outputs/FOF_x_time_x_frailtyCat_on_CompositeZ_change_by_cat.csv`
- `R-scripts/K28/outputs/k28_interaction_report.md`
- `R-scripts/K28/outputs/k28_interaction_report.txt`
- `manifest/sessionInfo_K28.txt`
- Uudet rivit `manifest/manifest.csv`

## Definition of Done (DoD)
- K28-skriptissä on STANDARD SCRIPT INTRO, `script_label <- "K28"` ja `init_paths(script_label)`.
- Input-validoinnit pysäyttävät ajon selkeästi virhetilanteissa.
- Continuous-outputit syntyvät aina ja categorical-outputit vain jos `frailty_cat_3` on saatavilla.
- Raporttiteksti (5–12 riviä, suomi) generoidaan taulukoista ilman keksittyjä lukuja.
- Jokaisesta artefaktista yksi manifest-rivi + `sessionInfo_K28.txt` logattuna manifestiin.
- Smoke run `/usr/bin/Rscript R-scripts/K28/k28.r` onnistuu.

## Log
- 2026-02-26 14:58:00 Created backlog task from template; waiting for move to `tasks/01-ready/` before execution.
- 2026-02-26 14:58:40 Moved task to `tasks/01-ready/` and immediately to `tasks/02-in-progress/`.
- 2026-02-26 15:10:00 Implemented `R-scripts/K28/k28.r` with standard intro, validations, models, exports, report text, and manifest logging.
- 2026-02-26 15:13:34 Smoke run passed in proot Debian with `/usr/bin/Rscript R-scripts/K28/k28.r`; required artifacts generated.
- 2026-02-26 15:19:48 Review check completed: script conventions and table-to-text values pass, but manifest integrity fails due to duplicate K28 rows from repeated runs.
- 2026-02-26 15:20:00 Sent back to `tasks/01-ready/` for correction before approval.
- 2026-02-26 15:33:08 Implemented manifest idempotency in `R-scripts/K28/k28.r`: remove old K28 rows for deterministic artifact paths before append; added duplicate guard stop at script end.
- 2026-02-26 15:33:08 Ran K28 twice in proot Debian (`/usr/bin/Rscript R-scripts/K28/k28.r`); manifest check by `script==K28` and `path` shows 9 unique files and no duplicates (`n==1` per file).
- 2026-02-26 15:33:30 Returned task to `tasks/03-review/` for re-review.
- 2026-02-26 15:41:44 Re-review passed: ran K28 twice in proot Debian, `manifest/manifest.csv` check (`script==K28`, `path` counts) returned `duplicates: NONE` and 9 unique files.
- 2026-02-26 15:41:44 Acceptance granted; moved task to `tasks/04-done/`.

## Blockers
- Ei aktiivisia blockereita (manifest-idempotenssi vahvistettu review-smokessa).

## Links
- `tasks/04-done/K28_interaction_time_x_FOF_x_frailty.md`
