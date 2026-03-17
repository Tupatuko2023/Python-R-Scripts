# K32 Validation Join Frailty From K15

## Context

Enable known-groups validation in K32 by sourcing `frailty_cat` (and related frailty fields) from K15 outputs via `DATA_ROOT`.

Scope is limited to K32 validation-layer enrichment. No hot edits are allowed until this task is moved to `tasks/01-ready/` and then `tasks/02-in-progress/`.

## Inputs

- Current K32 validation script:
  - `R-scripts/K32/k32_validation.r`
- Current K32 patient-level dataset location (external):
  - `${DATA_ROOT}/paper_01/capacity_scores/kaatumisenpelko_with_capacity_scores_k32.rds` (preferred)
- K15 context:
  - `R-scripts/K15/k15.r` (if present as canonical entrypoint)
  - `R-scripts/K15/outputs/*` (currently mostly aggregate CSVs)
- Environment:
  - `config/.env` with `DATA_ROOT`

## Outputs

- Backlog planning artifact now:
  - `tasks/00-backlog/K32_validation_join_frailty_from_K15.md`
- Future implementation artifact (after gate move):
  - updated `R-scripts/K32/k32_validation.r` with optional external frailty join
- Future runtime output:
  - `R-scripts/K32/outputs/k32_validation_known_groups.csv` populated with real group comparisons when frailty input exists

## Definition of Done (DoD)

- When implemented (future `01-ready` step), `k32_validation.r` must:
  - resolve optional K15-derived patient-level dataset from `DATA_ROOT/paper_01/...` (prefer `.rds`)
  - left join frailty category onto K32 validation data using deterministic keys (baseline-only)
  - run known-groups test using joined frailty category if available
  - preserve current deterministic skip behavior with explicit reason if K15 dataset not found
- Governance constraints:
  - do not write patient-level joined tables to repo outputs
  - keep repo outputs aggregate-only validation CSVs
  - do not modify K32 measurement script (`k32.r`)
  - do not modify K30/K31, externalization logic, or manifest helper code
- If K15 patient-level frailty dataset is not externalized under `DATA_ROOT`, create and complete a separate one-at-a-time task first:
  - `K15 externalize frailty outputs to DATA_ROOT with receipt`

## Log

- 2026-03-01 Created backlog task from template.
- 2026-03-01 Reconnaissance:
  - `R-scripts/K15/outputs/` contains many aggregate CSV outputs.
  - `${DATA_ROOT}/paper_01/` currently shows `capacity_scores/`; no confirmed K15 patient-level frailty dataset path yet.
  - Implication: K15 externalization may be a prerequisite before K32 known-groups join can populate.
- 2026-03-01 Moved task: `tasks/00-backlog/K32_validation_join_frailty_from_K15.md` -> `tasks/01-ready/K32_validation_join_frailty_from_K15.md` -> `tasks/02-in-progress/K32_validation_join_frailty_from_K15.md`.
- 2026-03-01 Implemented optional K15 frailty join in `R-scripts/K32/k32_validation.r`:
  - deterministic DATA_ROOT resolver for K15-derived external datasets under `paper_01`
  - deterministic join key resolution (`id`/`participant_id`/`subject_id`/`study_id`/`record_id`/`tunniste`)
  - baseline preference when time marker exists in K15 dataset
  - known-groups uses joined `frailty_cat_from_k15` when available; otherwise deterministic skip with explicit reason
- 2026-03-01 Validation command (PASS):
  - `proot-distro login debian --termux-home -- bash -lc 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd /data/data/com.termux/files/home/Python-R-Scripts/Fear-of-Falling && set -a && [ -f config/.env ] && . config/.env && set +a && /usr/bin/Rscript R-scripts/K32/k32_validation.r'`
- 2026-03-01 Validation result:
  - Script PASS, validation artifacts regenerated and manifest rows appended.
  - `k32_validation_known_groups.csv` currently remains skipped with reason:
    `frailty column not found in K15-derived dataset`
  - Governance preserved: aggregate-only repo outputs; no patient-level repo outputs written.
  - `qc-summarizer` PASS after change.

## Blockers

- Possible prerequisite task:
  - K15 patient-level frailty externalization to `DATA_ROOT` (if missing)
  - and/or ensure externalized K15 dataset includes `frailty_cat`.

## Links

- Related task:
  - `tasks/03-review/K32_final_validation_layer.md`
