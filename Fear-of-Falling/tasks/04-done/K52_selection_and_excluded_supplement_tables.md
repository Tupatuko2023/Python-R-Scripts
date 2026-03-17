# K52 selection and excluded supplement tables

## Goal

Create a new K52 work package for supplementary baseline tables that sit
outside the now-closed K51 Table 1 package.

K52 should produce:

- a full-population baseline table by FOF for the deduplicated
  baseline-eligible cohort
- an excluded-population baseline table by FOF for the baseline-eligible but
  not-analytic cohort
- an analysis-vs-excluded comparison table for the same extended variable set

## Scope

- create the implementation under `R-scripts/K52/`
- keep K51 closed as the Table 1 package
- reuse current K50/K51 cohort construction and shared
  `person_dedup_lookup.R`
- reuse the same baseline enrichment source
  `KAAOS_data_sotullinen.xlsx`
- reuse the three-key override map from
  `R-scripts/K51/K51_three_key_override_map.csv`
- do not create a parallel cohort-definition path
- do not modify K50 or K51 logic as part of K52

## Recommended outputs

- `R-scripts/K52/outputs/k52_long_full_population_table.csv`
- `R-scripts/K52/outputs/k52_long_full_population_table.html`
- `R-scripts/K52/outputs/k52_long_excluded_population_table.csv`
- `R-scripts/K52/outputs/k52_long_excluded_population_table.html`
- `R-scripts/K52/outputs/k52_long_analysis_vs_excluded_table.csv`
- `R-scripts/K52/outputs/k52_long_analysis_vs_excluded_table.html`
- `R-scripts/K52/outputs/k52_long_input_receipt.txt`
- `R-scripts/K52/outputs/k52_long_decision_log.txt`
- `R-scripts/K52/outputs/k52_long_sessioninfo.txt`

## Population definitions

- `full_population = 472`
- `analytic_population = 230`
- `excluded_population = 242`

`excluded_population` means baseline-eligible people who are not in the
analytic cohort.

## Variable inventory

Keep the same extended row set as current K51 extended tables so the new
supplements stay directly comparable:

- Women, n (%)
- Age, mean (SD)
- Diseases, n (%)
- Diabetes
- Dementia
- Parkinson's
- Cerebrovascular Accidents
- Comorbidity (>1 disease)
- Self-rated Health, n (%)
- Good / Moderate / Bad
- Mikkeli Osteoporosis Index, mean (SD)
- Body Mass Index, mean (SD)
- Smoked, n (%)
- Alcohol, n (%)
- No / Moderate / Large
- Self-Rated Mobility, n (%)
- Good / Moderate / Weak
- Walking 500 m, n (%)
- No / Difficulties / Cannot
- Balance difficulties, n (%)
- Fallen, n (%)
- Fractures, n (%)
- Pain (Visual Analog Scale), mm, mean (SD)
- Locomotor capacity at baseline, mean (SD)
- Frailty Index (FI), mean (SD)

## Design constraints

- K52 must live in its own `R-scripts/K52/` package
- K52 must reuse K51/K50 cohort and enrichment logic rather than re-derive a
  separate baseline population
- K52 outputs go only to `R-scripts/K52/outputs/` and `manifest/manifest.csv`
- use explicit population labels:
  `full_population`, `analytic_population`, `excluded_population`
- keep excluded-by-FOF and analysis-vs-excluded comparison as separate tables

## Definition of Done

- a new K52 script exists under `R-scripts/K52/`
- full-population table uses `n=472`
- excluded-population table uses `n=242`
- analysis-vs-excluded comparison uses `230` vs `242`
- all K52 outputs land in `R-scripts/K52/outputs/`
- manifest rows are appended for each K52 artifact
- K51 remains unchanged and closed

## Log

- 2026-03-16T00:00:00+02:00 Task created from orchestrator prompts
  `prompts/24_4cafofv2.txt` and `prompts/25_4cafofv2.txt`.
- 2026-03-16T00:00:00+02:00 Rationale recorded: K51 is now accepted as the
  closed baseline Table 1 package, so new selection/excluded supplementary
  tables should be implemented as a separate K52 package rather than extending
  K51 again.
- 2026-03-16T00:00:00+02:00 Implemented
  [K52.V1_selection-and-excluded-baseline-tables.R](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K52/K52.V1_selection-and-excluded-baseline-tables.R)
  under `R-scripts/K52/`. The script reuses the same cohort and baseline
  enrichment logic as accepted K51, including the audited
  [K51_three_key_override_map.csv](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K51/K51_three_key_override_map.csv),
  without modifying K50 or K51 code.
- 2026-03-16T00:00:00+02:00 LONG smoke-run succeeded on canonical input
  `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_01/analysis/fof_analysis_k50_long.rds`.
  K52 wrote:
  [k52_long_full_population_table.csv](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K52/outputs/k52_long_full_population_table.csv),
  [k52_long_excluded_population_table.csv](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K52/outputs/k52_long_excluded_population_table.csv),
  [k52_long_analysis_vs_excluded_table.csv](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K52/outputs/k52_long_analysis_vs_excluded_table.csv),
  matching HTML outputs, plus receipt/decision-log/sessioninfo artifacts and
  manifest rows.
- 2026-03-16T00:00:00+02:00 Verified population counts from
  [k52_long_decision_log.txt](/data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling/R-scripts/K52/outputs/k52_long_decision_log.txt):
  `full_population_n=472`, `analytic_population_n=230`,
  `excluded_population_n=242`, `full_population_without_fof_n=144`,
  `full_population_with_fof_n=328`, `excluded_population_without_fof_n=75`,
  `excluded_population_with_fof_n=167`, `analysis_vs_excluded_counts=230 vs 242`.
- 2026-03-16T00:00:00+02:00 Verified table structure:
  all three K52 CSV tables render the full 33-row extended variable set.
- 2026-03-16T00:00:00+02:00 Validation:
  `python ../.codex/skills/fof-preflight/scripts/preflight.py`
  returned `Preflight status: PASS`.
- 2026-03-17T00:00:00+02:00 Review acceptance:
  accept this K52 supplementary-table implementation. Acceptance-pass confirmed
  `full_population_n=472`, `analytic_population_n=230`,
  `excluded_population_n=242`, excluded FOF split `75 / 167`, receipt-backed
  canonical input plus enrichment and override-map provenance, full 33-row
  extended structure in all three K52 tables, and manifest rows for every K52
  artifact. No K51 or K50 logic changes were required.
