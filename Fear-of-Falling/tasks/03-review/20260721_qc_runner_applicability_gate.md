# Define K18/QC runner applicability gate

## Status

03-review

## Objective

Make K18/QC runner applicability deterministic for all future agents.

The K18/QC runner is a conditional analysis-QC gate, not a universal
repository-change gate.

## Required repository policy

Add a consistent rule to:

- `AGENTS.md`;
- `agent_workflow.md`;
- `README.md`;
- `tasks/_template.md`;
- `CLAUDE.md` only where clarification is necessary.

Do not create a separate Codex skill for this repository-specific policy.

## Mandatory triggers

K18/QC or the README-defined Termux QC runner is required when a change affects
one or more of:

- participant-level or observation-level data;
- imported or processed data structure;
- variable names, types, labels, factor levels, or coding;
- ID uniqueness or ID-time structure;
- baseline or follow-up outcome definitions;
- delta derivation;
- FOF status derivation or coding;
- missingness rules or missingness outputs;
- inclusion or exclusion logic;
- model-frame construction;
- K18 scripts;
- QC checks, thresholds, summarizers, runners, or QC artifacts;
- analysis outputs whose acceptance depends on K18 evidence;
- a task whose acceptance criteria explicitly require K18/QC.

## Normally not applicable

K18/QC is normally not applicable when a change is limited to:

- prose documentation;
- README restructuring;
- task-card documentation;
- diagram file organization;
- `git mv` operations with unchanged scientific content;
- path-reference maintenance;
- legacy archiving;
- non-scientific manifest path correction;
- formatting or spelling;
- repository metadata that does not change analysis execution;
- manuscript handoff documentation.

Task-specific acceptance criteria may override this default.

## Required task field

Add to `tasks/_template.md`:

```text
## QC applicability

- Classification: REQUIRED | NOT APPLICABLE
- Trigger or reason:
- Required command when applicable:
- Expected evidence:
```

An agent must complete this field before implementation.

## Required decision sequence

Before writing the execution plan:

1. List changed file classes.
2. Determine whether any mandatory trigger applies.
3. Inspect task-specific acceptance criteria.
4. Set `QC applicability`.
5. Include the K18/QC command only when classification is `REQUIRED`.

## Validation reporting

Every completed task must record exactly one of:

```text
K18/QC: PASS
```

or

```text
K18/QC: NOT APPLICABLE — <specific reason>
```

`NOT APPLICABLE` is invalid when data, variable coding, inclusion logic, model
frames, K18 code, QC code, or QC artifacts changed.

A failed environment attempt must not be reported as PASS.

When K18/QC is genuinely required and cannot run, the task remains blocked.

When K18/QC is not applicable, a PRoot or runner failure is not a task blocker
and the runner should not be invoked merely to demonstrate that it fails.

## AGENTS.md requirement

Add a compact rule stating:

- evaluate QC applicability before commands are selected;
- do not run K18/QC for unrelated docs-only or diagram-only work;
- run it early for analysis- or QC-affecting work;
- task-specific acceptance criteria override defaults.

## agent_workflow.md requirement

Add a decision gate before execution:

```text
Does the task modify data, variable coding, inclusion rules, model frames,
K18/QC code, QC artifacts, or explicitly require K18/QC?
  yes -> REQUIRED
  no  -> NOT APPLICABLE with documented reason
```

## README.md requirement

Explain:

- what the K18/QC Termux runner starts;
- when it is required;
- when it is not applicable;
- how PASS and NOT APPLICABLE are reported;
- that environment repair belongs to a separate bootstrap task.

## CLAUDE.md requirement

Preserve the mandatory QC minimum for analysis work.

Clarify only that repository hygiene and documentation changes do not require
rerunning K18 when no scientific or QC input/output changes.

## Acceptance criteria

- Future agents can make the decision without inference.
- The same rule appears consistently across agent instructions, workflow, user
  documentation, and task template.
- Analysis-affecting changes cannot bypass K18/QC.
- Unrelated documentation and diagram tasks do not invoke the runner.
- Task-specific acceptance criteria remain authoritative.
- No separate Codex skill is introduced.

## Evidence

- `AGENTS.md` defines the mandatory K18/QC applicability gate for agents.
- `agent_workflow.md` includes the decision tree and exact reporting formats.
- `README.md` explains the Termux runner, required triggers, non-applicable
  cases, and separate environment repair handling.
- `tasks/_template.md` requires every task to record QC applicability before
  implementation.
- `CLAUDE.md` was inspected and left unchanged because its existing analysis QC
  rule does not make K18/QC universal for documentation or repository-hygiene
  work.

## Validation

- K18/QC: NOT APPLICABLE — repository policy documentation only; no data,
  variable coding, inclusion logic, model frame, K18 code, QC code, or QC
  artifact changed.
- `git diff --check`: PASS
- `bash scripts/fof-preflight.sh`: PASS
- `bash tools/run-gates.sh --project Fear-of-Falling`: PASS

## Log

- 2026-07-21 Human approval: released to `01-ready` for implementation.
- 2026-07-21 QC runner applicability gate implemented and moved to `03-review`.
