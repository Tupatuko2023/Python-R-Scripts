# Task: WP-A1 SCI-03 locomotor construction verification

## Status

03-review

## Workflow

Follow `agent_workflow.md`. Only a task in `tasks/01-ready/` may be started.
The agent moves the task to `tasks/02-in-progress/` before work and to
`tasks/03-review/` after reporting. Only a human may move the task to
`tasks/04-done/`.

## Scope

Verify the authoritative construction/source-of-truth details for WP-A1
`SCI-03`.

In scope:

- Preserve the strongly supported candidate outcome hierarchy:
  `locomotor_capacity` as primary candidate, `z3` as deterministic fallback,
  and `Composite_Z` as legacy bridge.
- Trace the authoritative upstream producer/export path for locomotor outcomes.
- Verify exact chair-rise transformation.
- Verify exact `z3` implementation and coverage threshold.
- Identify which evidence can be frozen and which remains unresolved.

Out of scope:

- Editing `ANALYSIS_PLAN.md`, `K50.r`, target manuscript code, raw data,
  outputs, or manifests.
- Implementing locomotor construction in the target manuscript repository.
- Declaring the complete construction contract frozen before producer/export and
  transformation details are verified.

## Objective

Produce an owner-ready verification packet that establishes whether the
locomotor construction contract can be frozen, including:

- authoritative upstream producer/export path;
- chair-rise transformation formula;
- CFA/export ownership boundary;
- `z3` implementation;
- `z3` indicator coverage threshold;
- legacy `Composite_Z` bridge boundary.

## QC applicability

- Classification: NOT APPLICABLE for evidence/provenance verification.
- Trigger or reason: This task starts as documentation and provenance tracing
  only. It must not modify raw data, variable coding, outcome derivation,
  missingness rules, model frames, K18/QC code, analysis outputs, or manuscript
  outputs.
- Required command when applicable: If verification expands into construction
  code changes, producer reruns, output regeneration, or manuscript-output
  acceptance, K18/QC becomes REQUIRED before accepting those results.
- Expected evidence: smoke gates, FOF preflight, `git diff --check`, and a
  clear K18/QC applicability statement.

## Constraints

- Do not modify raw data.
- Keep changes minimal, reversible, and documented.
- Do not commit or push unless separately authorized.
- Do not expose secrets or participant-level data.
- Do not modify `ANALYSIS_PLAN.md`, `K50.r`, target manuscript code, outputs, or
  manifests in this verification task.
- Do not freeze the complete construction contract until upstream producer/export
  and transformation details are verified.

## Acceptance Criteria

- [x] Task is moved from `01-ready` to `02-in-progress` before work starts.
- [x] Candidate outcome hierarchy is preserved without reopening it absent new
  contrary evidence.
- [x] Authoritative upstream producer/export path is identified or explicitly
  marked unresolved.
- [x] Chair-rise transformation is verified or explicitly marked unresolved.
- [x] Exact `z3` implementation and coverage threshold are verified or explicitly
  marked unresolved.
- [x] `Composite_Z` is classified as legacy bridge without deleting or silently
  harmonizing legacy evidence.
- [x] No scientific implementation, raw data, outputs, manifests, or manuscript
  code are changed.
- [x] Task finishes in `tasks/03-review/` with `OWNER_DECISION_REQUIRED` or an
  explicitly recorded owner disposition.

## Agent Report

### Scope Boundary

This SCI-03 verification is evidence-only. No construction code, K50 code,
`ANALYSIS_PLAN.md`, target manuscript code, raw data, generated outputs, or
manifest rows were modified. No producer, K18 QC, or model rerun was executed.

The already supported outcome hierarchy is preserved:

- `locomotor_capacity` = primary candidate.
- `z3` = deterministic fallback / sensitivity.
- `Composite_Z` = legacy bridge only.

### Evidence Matrix

| Claim | Evidence | Status |
|---|---|---|
| Current construction producer candidate | `R-scripts/K32/k32.r` declares `K32_CORE_LOCOMOTOR_CAPACITY`, builds locomotor indicators from raw Excel, fits the CFA branch, builds `z3`, and writes K50-ready wide/long exports. `R-scripts/K32/outputs/k32_patient_level_output_receipt.txt` records `script=K32`, input `paper_02/workbook.xlsx`, `analysis_dir=/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/analysis`, and K50 export paths. | VERIFIED as strongest current executable producer candidate; owner freeze still required. |
| K50 consumer path | K50 receipts consume `/data/data/com.termux/files/home/FOF_LOCAL_DATA/paper_02/analysis/fof_analysis_k50_wide.rds` and `fof_analysis_k50_long.rds`. The WIDE receipt records `authoritative_snapshot_id=paper_02_2026-03-21`, `rows_loaded=535`, `rows_modeled=230`; LONG records `rows_loaded=1070`, `rows_modeled=630`. | VERIFIED current consumer chain. |
| K33 role | `R-scripts/K33/k33.r` externalizes outcome-explicit K33 datasets from canonical K50 inputs and runs K18 QC, but its receipt points to `paper_01/analysis` paths from 2026-03-17. | CONFLICTING as current authority; useful as older handoff/QC evidence, not current K50 producer authority. |
| Raw/source variables | K32 decision log maps gait, chair, and balance from `paper_02/workbook.xlsx` sheet `Taul1`, skip `1`: gait timed walk columns, chair `tk_tuolilta_nousu_5_krt...` / `x2sk_tuolilta_nousu_5_krt...`, and right/left one-leg stance columns. `docs/FUNCTIONAL_TESTS_DERIVED_SCHEMA.md` supports `FTSST0/2`, `SLS_mean0/2`, and gait-speed conventions. | VERIFIED. |
| Chair-rise transformation | K32 transforms chair to capacity direction as `indicator_chair_capacity_0 = -1 * clean_nonnegative(indicator_chair_raw_0, allow_zero = FALSE)` and same for 12m. K32 expected loading signs are gait(+), chair(+), balance(+). Target repo explicitly omits chair reverse-coding in MVP because its snippet lacked the formula. | VERIFIED in current K32; NEEDS_MIGRATION in target repo. |
| Balance preprocessing | K32 builds balance from summary if present, else right/left mean, and recodes values `>300` to `NA`. Target repo implements the same `>300` rule and right/left row mean for synthetic fields. | VERIFIED. |
| Gait preprocessing | K32 `to_gait_speed()` keeps `kavelynopeus_m_sek*` as speed, otherwise derives `10 / timed_seconds`. | VERIFIED. |
| CFA / `locomotor_capacity` scoring | K32 fits one-factor `Capacity =~ gait + chair + balance` on baseline complete rows, uses `lavaan::lavPredict(..., method = "regression")`, scores baseline and 12m with the baseline-fitted model, and flips orientation if gait loading or most expected-positive loadings are negative. Current diagnostics show admissible TRUE and regression score method. | VERIFIED as current executable contract. |
| CFA admissibility and score coverage | K32 has hard gate `SCORE_NA_SHARE_MAX = 0.25` for baseline CFA score NA share and `MIN_CANONICAL_SCORE_COMPLETENESS = 0.40` for canonical score completeness. Current K32 QC reports primary CFA admissible TRUE, `lc0=0.794`, `lc12=0.497`. | VERIFIED for current run; owner must accept whether 0.40 is the frozen publication threshold. |
| `z3` construction | K32 baseline-anchors gait, chair, and balance separately using baseline mean/sd for both baseline and follow-up, then computes `z3_0` and `z3_12m` as `na_row_mean()` of the three z indicators. | VERIFIED. |
| `z3` coverage threshold | K32 `na_row_mean()` only sets NA when all three indicators are missing, so the executable z3 algorithm allows at least 1/3 observed indicators. K32 canonical export QC uses only overall content-share gate `>= 0.40`, not a row-level 2/3 or 3/3 threshold. Upstream spec previously marked the 2/3 vs 3/3 question unresolved. | CONFLICTING / OWNER_DECISION_REQUIRED. |
| Baseline/follow-up semantics | K32 decision log locks `0 = baseline`, `2 = 12 months`; canonical long output uses `time = 0L` and `12L`. K50 QC gates verify exact time levels 0/12 and two rows per id for LONG. | VERIFIED. |
| Canonical export schema | K32 writes `fof_analysis_k50_wide.{csv,rds}` and `fof_analysis_k50_long.{csv,rds}` under `DATA_ROOT/paper_02/analysis`. Canonical wide includes `locomotor_capacity_0`, `locomotor_capacity_12m`, `z3_0`, `z3_12m`; canonical long includes `locomotor_capacity` and `z3`. | VERIFIED. |
| `Composite_Z` role | K32 canonical export QC requires `Composite_Z` absent; K50 refuses `Composite_Z` unless `--allow-composite-z VERIFIED`; docs classify it as legacy bridge. | VERIFIED as legacy bridge only. |
| Target manuscript consumer | `/data/data/com.termux/files/home/src/fof-locomotor-capacity-cohort/R/transform_locomotor_indicators.R` validates balance/chair source fields and computes balance mean, but intentionally omits chair reverse-coding and has no CFA/z3/K32-equivalent producer. Prompt 102 says upstream CFA/z3 construction path is not frozen. | VERIFIED target is not authoritative construction implementation yet. |

### Current Supported Construction Contract

Supported, subject to owner acceptance:

- Producer candidate: `R-scripts/K32/k32.r`.
- Raw source: `paper_02/workbook.xlsx`, sheet `Taul1`, skip `1`, as recorded in
  K32 receipts/logs.
- Gait: use `kavelynopeus_m_sek*` if present, otherwise `10 / timed_seconds`;
  higher is better.
- Chair: use raw five-times-sit-to-stand seconds and transform to capacity as
  `-1 * clean_nonnegative(raw_seconds, allow_zero = FALSE)`; higher is better
  after transformation.
- Balance: use `SLS_mean*`/summary branch if present, otherwise right-left mean;
  values `>300` become `NA`.
- CFA: one latent factor with gait, chair, and balance, baseline-fitted model,
  regression factor scores for baseline and 12 months, orientation-flip rule
  tied to expected positive loading signs.
- `locomotor_capacity`: CFA regression factor score columns
  `locomotor_capacity_0`, `locomotor_capacity_12m`, and long
  `locomotor_capacity`.
- `z3`: baseline-anchored z-score mean of gait, chair, and balance; current code
  allows any nonzero component count per row via `na_row_mean()`.
- Export: K32 writes canonical K50-ready artifacts under
  `DATA_ROOT/paper_02/analysis/fof_analysis_k50_wide.rds` and
  `DATA_ROOT/paper_02/analysis/fof_analysis_k50_long.rds`.
- K50 consumer: `R-scripts/K50/K50.r` consumes those canonical columns and does
  not derive CFA or z3 from raw variables.
- Legacy bridge: `Composite_Z` remains bridge-only and absent from K32 canonical
  K50 export.

### Unresolved Construction Details

- `OWNER_DECISION_REQUIRED`: confirm that K32, not K33 or target-repo MVP code,
  is the authoritative upstream construction producer for the current study.
- `OWNER_DECISION_REQUIRED`: confirm whether the row-level `z3` threshold is the
  current executable 1/3-or-more observed indicator rule, or whether a stricter
  2/3 or 3/3 rule must be implemented later.
- `OWNER_DECISION_REQUIRED`: confirm that K32's canonical score completeness
  threshold `MIN_CANONICAL_SCORE_COMPLETENESS = 0.40` is scientifically frozen
  for publication/migration, not merely a current engineering gate.
- `NEEDS_MIGRATION`: target manuscript repository currently lacks the verified
  chair transformation, CFA scoring, z3 construction, K32 receipt linkage, and
  K50 consumer bridge.

### Evidence FOR

- K32 has executable producer code, receipts, export QC, score summaries, CFA
  diagnostics, source variable logs, and exact K50-ready export paths.
- K50 current receipts consume the matching `paper_02/analysis` K32 outputs and
  enforce canonical branch naming, z3 fallback presence, and `Composite_Z`
  gating.
- Upstream docs agree on the hierarchy: `locomotor_capacity` primary candidate,
  `z3` fallback/sensitivity, `Composite_Z` legacy bridge.
- Target repo itself warns that upstream CFA/z3 construction is not frozen and
  omits undocumented chair reverse-coding.

### Evidence AGAINST / Cautions

- K33 is named as a canonical locomotor export/QC handoff, but current K33
  receipt points to older `paper_01` K50 inputs, while current K50 receipts use
  `paper_02`; this prevents promoting K33 as the current authoritative producer
  without owner clarification.
- Upstream spec previously marked exact chair transformation and z3 threshold as
  unresolved; K32 now provides executable evidence for chair, but the owner must
  decide whether to freeze K32's current row-level z3 semantics.
- K32 longitudinal invariance output reports `metric_not_supported`, so the CFA
  score can be treated as a structured summary score, but stronger longitudinal
  measurement-invariance claims should remain cautious.

### Recommendation

Overall SCI-03 disposition: `OWNER_DECISION_REQUIRED`.

SCI-03 must not be approved as one undivided construction contract because the
evidence strength differs across subcontracts. The owner gate is split as
follows.

Allowed owner disposition values for SCI-03C and SCI-03D: `APPROVED`,
`REJECTED`, or `NEEDS_VERIFICATION`. `REJECTED` requires an explicit
replacement scientific rule from the owner; Codex must not invent a replacement
coverage rule or numeric threshold.

| Subdecision | Contract question | Frozen or pending contract | Owner disposition | Rationale |
|---|---|---|---|---|
| SCI-03A authoritative producer | Is `R-scripts/K32/k32.r` the current authoritative executable upstream producer for locomotor construction? | K32 is the current authoritative executable upstream producer for this repo version and its K50-ready export chain. | APPROVED | K32 has executable construction code, K32 receipts, export QC, and matching K50 consumer receipts. K50 consumes downstream exports and does not construct the locomotor outcome. |
| SCI-03B chair-rise transformation | Is the K32 chair transformation contract frozen? | Chair contribution is `-1 * clean_nonnegative(raw_seconds, allow_zero = FALSE)`. | APPROVED | The exact formula is verified in K32 executable code and aligns chair with higher-better locomotor capacity. This freezes only direction/formula semantics, not raw-data contents. |
| SCI-03C z3 construction and row-level coverage | Is `z3` the baseline-anchored mean of three component z-scores, and what row-level coverage rule is authoritative? | z3 core construction is frozen as the baseline-anchored mean of three component z-scores. Row-level coverage semantics remain unresolved. | NEEDS_VERIFICATION for coverage | K32 verifies the z3 core construction, but the executable behavior allowing any nonzero component count via `na_row_mean()` does not by itself create scientific authority. No explicit owner-approved row-level 1/3, 2/3, or 3/3 coverage rule was recorded. |
| SCI-03D K32 content-share gate | Is K32's canonical score completeness/content-share gate scientifically frozen at `0.40`? | K32 currently implements `MIN_CANONICAL_SCORE_COMPLETENESS = 0.40`; scientific freeze remains pending. | NEEDS_VERIFICATION | The threshold can affect valid constructed outcome availability and therefore downstream cohort/N; it must not be promoted from engineering gate to scientific contract without owner approval. |

#### SCI-03C Decision Support: Row-Level z3 Coverage

Current K32 evidence: `z3_0` and `z3_12m` are computed with
`na_row_mean(cbind(gait_z, chair_z, balance_z))`. The helper counts non-missing
components, computes `rowMeans(..., na.rm = TRUE)`, and sets the result to `NA`
only when `nonmiss == 0`.

| Available z3 components in row | Current K32 behavior | z3 validity consequence | Cohort/N consequence | Owner decision meaning |
|---|---|---|---|---|
| 3/3 | Produces z3 from all three component z-scores. | Complete three-component z3. | Row can contribute z3 if downstream model-frame variables are otherwise present. | Approval would accept full-component rows as valid. |
| 2/3 | Produces z3 from the two observed component z-scores. | Partial-component z3; one component missing. | More z3 rows than a strict 3/3 rule; component mix can differ across participants/timepoints. | Approval would accept current K32 partial-row behavior at 2/3. |
| 1/3 | Produces z3 from the single observed component z-score. | Single-component z3 under current executable logic. | More z3 rows than 2/3 or 3/3 rules; comparability risk is highest here. | Approval would accept current K32 single-component fallback. |
| 0/3 | Sets z3 to `NA`. | No z3 value. | Row cannot contribute a z3 outcome value. | Approval would keep all-missing rows invalid. |

SCI-03C is therefore not a question about the already frozen z3 formula when all
three components are present. It is the scientific missing-component rule: should
the current executable 1/3-or-more behavior be accepted, or should the owner
provide a stricter replacement rule before migration?

#### SCI-03D Decision Support: K32 0.40 Content-Share Gate

Current K32 evidence: `MIN_CANONICAL_SCORE_COMPLETENESS <- 0.40`. The canonical
export QC applies this at export-QC level, not as a per-row exclusion rule:

| Gate item | Current K32 definition |
|---|---|
| Numerator | Count/share of non-missing canonical score values for each exported score column and timepoint. |
| Denominator | `nrow(canonical_wide)` for the corresponding wide export, currently 535 participants in the K32 receipt. |
| Application point | Canonical export QC after K32 constructs `canonical_wide`; checked separately for `locomotor_capacity_0`, `locomotor_capacity_12m`, `z3_0`, and `z3_12m`. |
| Pass rule | Both timepoint shares for the score family must be `>= MIN_CANONICAL_SCORE_COMPLETENESS` (`0.40`). |
| Below threshold | The QC check would fail for that score family/export; current code evidence does not show a row-level deletion caused by this gate. |
| At/above threshold | The QC check passes; current K32 receipt shows the canonical export was accepted. |

Known aggregate evidence from existing K32 receipts/QC:

| Score/timepoint | Non-missing n | Share | Gate result |
|---|---:|---:|---|
| `locomotor_capacity_0` | 425/535 | 0.794 | Pass |
| `locomotor_capacity_12m` | 266/535 | 0.497 | Pass |
| `z3_0` | 497/535 | 0.929 | Pass |
| `z3_12m` | 310/535 | 0.579 | Pass |

This evidence documents current export acceptance, but it does not by itself
quantify a row-level or participant-level exclusion count caused by the 0.40
gate. If the owner needs the exact N impact of alternative thresholds or stricter
row-level coverage rules, that remains `NEEDS_VERIFICATION` in a separate
protected-data decision-support run.

Preserved hierarchy:

- `locomotor_capacity` = primary.
- `z3` = deterministic fallback / sensitivity.
- `Composite_Z` = legacy bridge.

Recommended next owner questions:

1. Approve SCI-03A K32 authoritative producer and SCI-03B chair transformation
   as written?
2. For SCI-03C, should the current executable row-level `z3` behavior
   (1/3-or-more observed indicators) be frozen, or should a stricter owner-rule
   be specified before implementation?
3. For SCI-03D, should K32's `0.40` content-share gate be frozen as the
   scientific construction threshold, or should a replacement rule be specified
   before implementation?

If SCI-03C and SCI-03D are approved later, SCI-03 can move to `APPROVED` in a
subsequent owner-disposition step. If either is rejected, the owner must name the
replacement construction rule before any implementation or migration task.
If either remains `NEEDS_VERIFICATION`, dependent implementation and manuscript
migration stay locked.

Status: `OWNER_DECISION_REQUIRED`.

Confidence: HIGH for current K32 -> K50 producer/consumer evidence, HIGH for
chair transformation in K32, HIGH for current CFA/z3 implementation evidence,
MEDIUM for final z3 coverage-threshold contract until owner disposition is
recorded.

### QC Applicability

K18/QC: NOT APPLICABLE for this agent run. This task changed only task-card
documentation and inspected aggregate/source-code evidence. It did not modify
data, variable coding, outcome derivation, missingness rules, model frames,
K18/QC code, analysis outputs, or manuscript artifacts. If a later task changes
K32 construction, regenerates K32/K50-ready outputs, or changes z3 thresholds,
K18/QC becomes stop-the-line required before modeling or migration acceptance.

## Log

- 2026-08-08T00:00:00+03:00 Created from `tasks/_template.md` per
  `prompts/6_scientific_packet_2_FARO1.txt`; placed in `tasks/01-ready/`.
- 2026-08-08T00:00:00+03:00 Moved from `tasks/01-ready/` to
  `tasks/02-in-progress/` for SCI-03 construction verification.
- 2026-08-08T00:00:00+03:00 Inspected K32 construction producer, K32 receipts
  and QC outputs, K33 externalization/QC handoff, K50 consumer receipts/logs,
  upstream locomotor docs, and target manuscript repository transform code.
- 2026-08-08T00:00:00+03:00 Produced SCI-03 construction provenance map without
  modifying construction code, K50, docs, manuscript code, raw data, outputs, or
  manifest.
- 2026-08-08T00:00:00+03:00 Converted SCI-03 into owner-gate subdecisions per
  `prompts/9_scientific_packet_2_FARO1.txt`: SCI-03A K32 producer and SCI-03B
  chair transformation are recommended for approval; SCI-03C row-level z3
  coverage and SCI-03D `0.40` content-share gate remain
  `OWNER_DECISION_REQUIRED`.
- 2026-08-08T00:00:00+03:00 Recorded final SCI-03 owner-gate state from
  `prompts/10_scientific_packet_2_FARO1.txt`: SCI-03A APPROVED, SCI-03B
  APPROVED, z3 core construction frozen as baseline-anchored three-component
  z-score mean, SCI-03C row-level coverage NEEDS_VERIFICATION, and SCI-03D
  `0.40` content-share gate NEEDS_VERIFICATION.
- 2026-08-08T00:00:00+03:00 Added owner-facing SCI-03C/SCI-03D decision-support
  tables per `prompts/11_scientific_packet_2_FARO1.txt`: current K32 z3 behavior
  is 3/3, 2/3, and 1/3 observed components produce z3 while 0/3 produces `NA`;
  K32's `0.40` gate is an export-QC non-missing share check with existing
  aggregate pass shares but no row-level exclusion count in current receipts.

## Blockers

Requires scientific-owner disposition for SCI-03C row-level z3 coverage
semantics and SCI-03D K32 `0.40` content-share gate. Overall SCI-03 remains
`OWNER_DECISION_REQUIRED`; no implementation/migration task is authorized yet.
