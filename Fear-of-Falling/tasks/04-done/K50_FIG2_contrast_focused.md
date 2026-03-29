# K50 FIG2 contrast-focused figure

## Context

The manuscript-facing Figure 2 currently shows adjusted trajectories with
group-wise confidence intervals, but it does not visualize the model-based
between-group contrasts directly. The next step is to add a contrast-focused
Figure 2 variant that keeps the same saved primary LONG mixed-model backbone
and extends the reporting layer with explicit adjusted contrasts.

## Inputs

- `R-scripts/K50/K50.V2_make-fig2-trajectory-exact.R`
- `R-scripts/K50/outputs/k50_long_locomotor_capacity_model_primary.rds`
- `R-scripts/K50/outputs/k50_long_locomotor_capacity_model_frame_primary.rds`
- `manifest/manifest.csv`
- `prompts/1_10cafofv2.txt`
- `prompts/14_Locomotor_Capacity_Modeling_Copilot.txt`

## Outputs

- `R-scripts/K50/K50.V3_make-fig2-contrast-focused.R`
- `R-scripts/K50/outputs/FIG2_contrast_focused/` artifacts for:
  - primary two-panel figure (`png`, `pdf`)
  - compact contrast-first figure (`png`, `pdf`)
  - Panel A emmeans table (`csv`)
  - Panel B contrast table (`csv`)
  - technical note (`txt`)
  - caption proposal (`txt`)
  - Results text proposal (`txt`)
  - session info (`txt`)
- one manifest row per new artifact

## Definition of Done (DoD)

- New work is implemented as a parallel V3 script without changing the V2 path.
- The saved primary LONG model object is used as-is; no raw-data edits or model
  refit are introduced.
- Fail-closed checks verify `FOF_status` in `{0, 1}`, `time` in `{0, 12}`, and
  no missing values in key model-frame variables.
- Panel A reports adjusted estimated marginal means; Panel B reports direct
  contrasts for baseline, 12-month, and difference-in-change.
- All new artifacts are written under
  `R-scripts/K50/outputs/FIG2_contrast_focused/` and logged once each in
  `manifest/manifest.csv`.
- At least one smoke run of the V3 script succeeds from the Fear-of-Falling
  root, plus QC runner and QC summary are executed if feasible without scope
  creep.

## Log


- 2026-03-26T00:00:00+02:00 Task created from orchestrator prompt for a contrast-focused Figure 2 implementation using the saved K50 primary LONG model and existing workflow guardrails.
- 2026-03-26T17:42:37+02:00 Loaded AGENTS.md, CLAUDE.md, README.md, SKILLS.md, config/agent_policy.md, config/steering.md, agent_workflow.md, WORKFLOW.md, and both requested prompts before implementation.
- 2026-03-26T17:44:23+02:00 Implemented `R-scripts/K50/K50.V3_make-fig2-contrast-focused.R`, generated the contrast-focused Figure 2 artifact set, and appended one manifest row per new Figure 2 artifact.
- 2026-03-26T17:45:19+02:00 Ran `K18_QC.V1_qc-run.R` against the saved K50 LONG model frame and confirmed `QC OK: all required checks passed.`
- 2026-03-26T17:45:21+02:00 Ran the `fof-qc-summarizer` skill script and produced aggregate QC summary outputs under `R-scripts/K18/outputs/K18_QC/qc_summary/`.
- 2026-03-26T17:45:30+02:00 Verified FIG2 contrast table against the generated Results text and technical note; baseline contrast = -0.0907 (95% CI -0.1737 to -0.0077), 12-month contrast = -0.0710 (95% CI -0.1686 to 0.0266), and difference-in-change = 0.0197 (95% CI -0.0674 to 0.1069).
- 2026-03-26T17:45:35+02:00 `Results_Draft_version_2.qmd` was not present in this subproject tree, so manuscript text was delivered as standalone caption/results text artifacts instead of editing a missing file.

## Blockers

- Host Termux R may not load the saved `merMod` object if the locked mixed-model package stack is unavailable; in that case the run must use the Debian PRoot R environment with a clean PATH.
