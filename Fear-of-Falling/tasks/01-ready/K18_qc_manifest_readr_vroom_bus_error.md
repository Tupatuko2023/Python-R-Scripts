# K18 QC manifest readr vroom bus error

## Context

`K18_QC` is not currently replayable on this Termux machine even though the
paper_01 cohort-flow implementation is complete and accepted.

The blocker is infrastructural, not analytical:

- `renv` autoload initially failed on missing `cli`
- after `RENV_CONFIG_AUTOLOADER_ENABLED=FALSE`, the run advanced further
- the remaining hard failure is a `readr`/`vroom` bus error when reading
  `manifest/manifest.csv`

This must remain separate from the cohort-flow implementation, which already
passed acceptance based on internal artifact consistency.

## Inputs

- `R-scripts/K18/K18_QC.V1_qc-run.R`
- `manifest/manifest.csv`
- local Termux R runtime
- `tasks/04-done/K50_paper01_cohort_flow_diagram.md`

## Outputs

- reproducible root-cause note for the manifest read path crash
- minimal fix or environment workaround for replaying `K18_QC`
- updated validation guidance once the infra blocker is resolved

## Definition of Done (DoD)

- the exact failure signature is reproduced and documented
- the failing path is isolated to environment/runtime or manifest I/O behavior
- a minimal fix or validated workaround is implemented
- `K18_QC` can be rerun successfully on this machine or the machine-specific
  limitation is documented with a deterministic workaround

## Constraints

- do not reopen or modify the accepted paper_01 cohort-flow logic
- do not change K50 model logic while fixing the QC runtime bug
- treat this as infrastructure/runtime work, not analysis work

## Log

- 2026-03-15T00:00:00+02:00 Task created as a follow-up from the accepted
  paper_01 cohort-flow implementation after repeated `readr/vroom` bus errors
  blocked full `K18_QC` replay on this Termux environment.
