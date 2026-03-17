# KXX Deduplicate K26 vs K34 Primary Models

## Context

K34 was implemented during orchestration, but project context indicates overlapping scope with existing K26 primary modeling workflow. We need a deterministic single source of truth for implementation without changing the statistical specification in `docs/ANALYSIS_PLAN.md`.

This task is deduplication + documentation alignment only.

## Inputs

- `docs/ANALYSIS_PLAN.md` (authoritative _what_ to run)
- `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R`
- `R-scripts/K34/k34.r`
- `manifest/manifest.csv` (historical artifacts; no rewrite)

## Outputs

- Canonical implementation mapping documented in plan docs (K26 canonical path).
- Deterministic K34 deprecation behavior (wrapper or immediate stop-message pointing to K26).
- No statistical-spec changes in plan; no manifest history rewrite.

## Reproduction / Audit Commands

```bash
cd Python-R-Scripts/Fear-of-Falling
sed -n '1,220p' R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R
sed -n '1,220p' R-scripts/K34/k34.r
grep -n "Composite_Z" R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R | sed -n '1,120p'
grep -n "Composite_Z" R-scripts/K34/k34.r | sed -n '1,120p'
```

## Observed Duplication (from audit)

- K34 executes the exact plan formulas:
  - LMM: `Composite_Z ~ time * FOF_status + time * frailty_cat_3 + time * tasapainovaikeus + age + sex + BMI + (1 | id)`
  - ANCOVA: `Composite_Z_12m ~ Composite_Z_baseline + FOF_status + frailty_cat_3 + tasapainovaikeus + age + sex + BMI`
- K26 already provides the established primary long-modeling pipeline for Composite_Z time/frailty/FOF and related moderation/sensitivity workflow.
- Keeping both runnable creates two competing implementation paths for the same analysis family.

## Deterministic Resolution (to implement when moved to 01-ready)

1. Keep `docs/ANALYSIS_PLAN.md` statistical model specification unchanged.
2. Add explicit “implementation mapping” section in plan docs naming K26 as canonical primary implementation path.
3. Deprecate K34 deterministically:
   - replace `R-scripts/K34/k34.r` runtime body with immediate, informative `stop()` pointing to canonical K26 script
   - include deprecation reason + migration pointer
4. Preserve governance:
   - patient-level outputs remain DATA_ROOT-only
   - repo outputs aggregate/receipt-only
5. Preserve history:
   - do **not** delete existing K34 manifest rows
   - do **not** rewrite historical manifest entries

## Validation Plan (after implementation)

```bash
cd Python-R-Scripts/Fear-of-Falling
# Run canonical path (K26) with existing project runner conventions
bash scripts/termux/run_qc_summarizer_proot.sh
bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling
# Optional: verify deprecated K34 fails fast with canonical-pointer message
```

## Definition of Done (DoD)

- Exactly one canonical implementation path documented for ANALYSIS_PLAN primary models.
- K34 cannot be accidentally used as a parallel pipeline (deterministic deprecation stop-message).
- Plan model specification unchanged.
- No manifest history rewrite.
- Gates + qc summarizer remain PASS on canonical path.

## Log

- 2026-03-01 16:37: Backlog task created.
- 2026-03-01 16:37: Duplication audited via K26/K34 header+formula inspection; implementation deferred until `tasks/01-ready`.
- 2026-03-01 16:48: Task moved `tasks/01-ready -> tasks/02-in-progress`.
- 2026-03-01 16:50: Implemented dedup edits:
  - Added canonical implementation mapping to `docs/ANALYSIS_PLAN.md` (K26 canonical, K34 deprecated).
  - Replaced `R-scripts/K34/k34.r` runtime body with deterministic deprecation `stop()` message pointing to K26.
  - Statistical model formulas/spec in plan were not changed.
- 2026-03-01 16:53: Validation run (canonical K26 default invocation) failed as expected on input contract:
  - Command: `/usr/bin/Rscript R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R`
  - Result: `Missing required canonical frailty column(s): frailty_score_3`
- 2026-03-01 16:56: Validation run (canonical K26 with deterministic temporary input bridge) PASS:
  - Built temporary `/tmp/k26_input_from_k15.rdata` from `${DATA_ROOT}/paper_01/frailty/kaatumisenpelko_with_frailty_k15.rds` as object `analysis_data`.
  - Ran K26 with `--input=/tmp/k26_input_from_k15.rdata`.
  - Result: K26 artifacts generated successfully under K26 outputs.
- 2026-03-01 16:58: `bash scripts/termux/run_qc_summarizer_proot.sh` PASS.
- 2026-03-01 16:59: `bash ../tools/run-gates.sh --mode analysis --project Fear-of-Falling` PASS.
- 2026-03-01 17:00: Leak-check command returned no patient-level repo output leak paths.
- 2026-03-01 17:01: Confirmed manifest history preserved; historical K34 rows retained (no deletion/rewrite).

## Blockers

- None.

## Links

- `docs/ANALYSIS_PLAN.md`
- `R-scripts/K26/K26_LMM_MOD.V1_time-frailty-CompositeZ0-moderation.R`
- `R-scripts/K34/k34.r`
