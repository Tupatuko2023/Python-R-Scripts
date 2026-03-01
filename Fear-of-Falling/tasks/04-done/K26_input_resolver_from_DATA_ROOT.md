# K26 Input Resolver from DATA_ROOT

## Context
K26 is now the canonical implementation path for primary models (`docs/ANALYSIS_PLAN.md` mapping complete, K34 deprecated). Current friction: running K26 without explicit `--input` fails with missing canonical frailty input (`frailty_score_3`). Current deterministic workaround uses a manual bridge (`K15 externalized RDS -> /tmp .RData -> K26 --input=...`), which should be replaced with a built-in resolver.

This task is I/O resolver hardening only. No statistical model/formula changes.

## Inputs
- `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R`
- `config/.env` (`DATA_ROOT`)
- `${DATA_ROOT}/paper_01/frailty/kaatumisenpelko_with_frailty_k15.rds`
- `${DATA_ROOT}/paper_01/analysis/` (K33 outputs)
- `docs/ANALYSIS_PLAN.md` (spec stays unchanged)

## Outputs
- Updated K26 resolver behavior (when task is implemented):
  - `--input` still supported (highest priority).
  - deterministic auto-resolve path from env / externalized datasets.
  - informative fail-fast message when unresolved.
- Optional runner for canonical one-command execution:
  - `scripts/termux/run_k26_proot.sh`
- Repo outputs discipline unchanged (aggregate/receipt only in repo; patient-level remains externalized).

## Deterministic Resolver Specification (to implement when moved to 01-ready)
Resolver priority:
1. CLI `--input=<path>` (if exists, use directly).
2. `DATA_PATH` env var (if exists and valid).
3. `DATA_ROOT` candidates, deterministic order:
   - K33 analysis dataset candidate(s) that already contain all required K26 columns.
   - Else: K15 frailty RDS + K33 analysis dataset joined deterministically by `id` and baseline constraints required by K26.
4. If unresolved: `stop()` with a clear error listing attempted paths and missing required columns.

Required-columns gate (deterministic):
- Must include canonical frailty score (`frailty_score_3` or accepted alias normalized to it).
- Must include other K26-required columns for current modes (cat/score) and covariates.
- If required columns cannot be produced, fail with explicit guidance.

Governance constraints:
- No model/formula edits in `docs/ANALYSIS_PLAN.md`.
- No new competing model scripts.
- No patient-level outputs written into repo outputs.
- DATA_ROOT remains mandatory for patient-level paths.

## Validation Plan (to execute during implementation task)
1. Run K26 with explicit `--input` (backward-compatibility check).
2. Run K26 without `--input` and without manual `/tmp` prep:
   - resolver must auto-locate from DATA_ROOT path(s).
3. Run `bash scripts/termux/run_qc_summarizer_proot.sh`.
4. Run `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling`.
5. Run leak-check to verify no patient-level files reappear in repo outputs.

## Definition of Done (DoD)
- K26 can run in one command without manual `/tmp` bridge.
- Resolver order and missing-column failures are deterministic and explicit.
- ANALYSIS_PLAN statistical spec unchanged.
- Governance preserved (patient-level externalized only).
- QC summarizer + analysis gates pass after resolver change.

## Log
- 2026-03-01 17:17: Backlog task created from template.
- 2026-03-01 17:18: Added deterministic resolver scope/specification (no code changes).
- 2026-03-01 17:18: Captured K26 references showing current `--input` handling and `frailty_score_3` requirement.
- 2026-03-01 17:20: Task moved `tasks/00-backlog -> tasks/01-ready -> tasks/02-in-progress`.
- 2026-03-01 17:24: Implemented K26 input resolver at IO boundary:
  - Resolver priority: `--input` > `DATA_PATH` > `DATA_ROOT` candidates.
  - DATA_ROOT candidates: K33 wide (`rds/csv`) and K15 frailty (`rds/csv`).
  - If K33 lacks frailty score, deterministic join from K15 by normalized id key.
  - Added alias support: `frailty_score` -> `frailty_score_3`, `frailty_cat` -> `frailty_cat_3`,
    and baseline aliases `Composite_Z_baseline` / `Composite_Z_12m`.
- 2026-03-01 17:24: Added runner `scripts/termux/run_k26_proot.sh` (loads `config/.env` in-proot, stable PATH).
- 2026-03-01 17:25: Validation PASS (no manual `/tmp` bridge):
  - `bash scripts/termux/run_k26_proot.sh` -> exit 0, K26 artifacts written.
  - `bash scripts/termux/run_qc_summarizer_proot.sh` -> PASS.
  - `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` -> PASS.
  - Leak-check (`find ...with_capacity_scores... / ...analysis...`) -> empty.

## Blockers
- None at backlog stage.

## Links
- `docs/ANALYSIS_PLAN.md`
- `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R`
- `R-scripts/K15/outputs/k15_patient_level_frailty_output_receipt.txt`
