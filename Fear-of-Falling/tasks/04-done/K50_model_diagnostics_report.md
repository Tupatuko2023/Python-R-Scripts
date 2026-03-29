# K50 model diagnostics report

## Context

The forensic code audit is complete and did not find a genuine coding defect in
`R-scripts/K50/K50.r`. The next step is a separate diagnostics report for the
locked primary K50 models. This task is not meant to prove assumptions; it is
meant to inspect plausible assumption violations and assess whether they appear
acceptable, mildly imperfect, or materially concerning.

## Inputs

- `R-scripts/K50/K50.r`
- locked primary K50 outputs under `R-scripts/K50/outputs/`
- canonical K50-ready inputs under `DATA_ROOT/paper_01/analysis/`
- `docs/ANALYSIS_PLAN.md`
- `tasks/03-review/K50_forensic_script_audit.md`

## Outputs

- diagnostic plots and tables for the primary `WIDE` ANCOVA
- diagnostic plots and tables for the primary `LONG` mixed model
- short diagnostics interpretation note using language such as:
  - no clear concern
  - mild deviation
  - clear concern
- manifest rows for each diagnostic artifact

## Definition of Done (DoD)

- Diagnostics cover at least:
  - residual vs fitted
  - residual QQ-plot
  - residual histogram
  - Cook's distance / leverage
  - VIF
  - random effects distribution for `LONG`
- Diagnostics are tied to the locked primary models, not new exploratory model
  variants.
- The report does not claim to prove assumptions; it evaluates signs of
  violation.
- Any deviations are interpreted as likely negligible, mild, or clearly
  concerning in practical modeling terms.
- `R-scripts/K50/K50.r` remains unchanged unless a genuine coding defect is
  separately proven.
- `Composite_Z` remains verification-only.
- `FI22_nonperformance_KAAOS` remains sensitivity-only.
- Task moves to `tasks/03-review/` after diagnostics and interpretation are
  written.

## Constraints

- Do not run new exploratory model variants.
- Do not modify `R-scripts/K50/K50.r` unless a genuine coding defect is proven.
- Do not introduce aliases.
- Do not relabel `Composite_Z` as `z3`.
- Do not move `FI22_nonperformance_KAAOS` into locomotor outcome construction.
- Do not touch unrelated queue items or the unrelated deletion outside this
  task.

## Canonical work order

1. Confirm required diagnostics packages and environment
2. Reconstruct the locked primary `WIDE` and `LONG` model objects
3. Produce residual and influence diagnostics
4. Produce VIF and random-effects diagnostics
5. Write a short interpretation note
6. Append manifest rows and move task to review

## Links

- `R-scripts/K50/K50.r`
- `docs/ANALYSIS_PLAN.md`
- `tasks/03-review/K50_forensic_script_audit.md`

## Log

- 2026-03-14T00:00:00+02:00 Task created from orchestrator prompt
  `17_3cafofv2.txt` and expert note `3_Z_Score_Composite_Advisor.txt`.
- 2026-03-14T00:00:00+02:00 Task added to `tasks/01-ready/` as the next
  diagnostics-only step after forensic audit completion.
- 2026-03-14T00:00:00+02:00 Task moved to `tasks/02-in-progress/` for primary
  model diagnostics on the locked `WIDE` and `LONG` branches. This step checks
  for signs of assumption violations rather than trying to prove assumptions.
- 2026-03-14T00:00:00+02:00 Primary diagnostics report executed successfully
  from canonical `WIDE` and `LONG` inputs without changing `R-scripts/K50/K50.r`.
  Diagnostic artifacts were written under `R-scripts/K50/outputs/` and
  manifest rows were appended one per final artifact after removing the partial
  rows from the aborted first attempt.
- 2026-03-14T00:00:00+02:00 `WIDE` diagnostics summary:
  linearity/homoscedasticity = `mild deviation`
  (`|Spearman fitted vs |residual|| = 0.131`);
  residual normality = `clear concern`
  (`QQ correlation = 0.948`);
  influence/leverage = `clear concern`
  (`max Cook's distance = 1.534`, `max leverage = 0.154`);
  multicollinearity = `no clear concern`
  (`max VIF = 1.276`).
- 2026-03-14T00:00:00+02:00 `LONG` diagnostics summary:
  linearity/homoscedasticity = `no clear concern`
  (`|Spearman fitted vs |residual|| = 0.095`);
  residual normality = `clear concern`
  (`QQ correlation = 0.944`);
  multicollinearity = `no clear concern`
  (`max VIF = 4.109`);
  random effects distribution = `no clear concern`
  (`random-intercept QQ correlation = 0.998`).
- 2026-03-14T00:00:00+02:00 Practical interpretation remained cautious rather
  than absolutist: residual non-normality and `WIDE` influence diagnostics are
  notable caveats, but the overall pattern is more consistent with ordinary
  epidemiologic model imperfection than a coding defect. `Composite_Z`
  remained verification-only and `FI22_nonperformance_KAAOS` remained
  sensitivity-only.
- 2026-03-14T00:00:00+02:00 Independent diagnostics interpretation supported
  the same bottom line: no pipeline or formula defect, no major
  multicollinearity concern, strong `LONG` random-effects behavior, but
  imperfect residual normality in both branches and a few influential
  observations in `WIDE`. The main remaining methodological caveat is
  missingness, with `WIDE` influence diagnostics as the next targeted
  robustness-check candidate rather than any need to reopen core model
  architecture.
- 2026-03-14T00:00:00+02:00 Follow-up methodological review confirmed that the
  current pipeline order is appropriate: primary analysis, FI22 sensitivity,
  integrated synthesis, forensic audit, diagnostics, then a narrow robustness
  check. The review explicitly endorsed keeping outcome architecture locked and
  targeting the next step only at `WIDE` influence sensitivity and/or robust
  inference rather than changing formulas or outcomes.
- 2026-03-14T00:00:00+02:00 Methodological freeze before robustness is now
  explicitly locked: diagnostics did not justify reopening model specification,
  outcome architecture, or coding decisions. The remaining justified step is a
  narrow robustness confirmation focused on `WIDE` influence and robust
  inference, while missingness remains the main substantive caveat to carry
  forward into reporting.
- 2026-03-14T00:00:00+02:00 A further methodological confirmation reinforced
  the same lock: diagnostics support a robustness check, not a redesign. The
  correct next step remains a narrow confirmation of `WIDE` influence
  sensitivity and/or robust inference, with missingness retained as the main
  reporting caveat and no justification to reopen formulas, outcomes, or
  `R-scripts/K50/K50.r`.
