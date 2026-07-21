# Agent Execution Protocol

Standard operating procedure for Gemini Agents gpa1qf-gpa4qf:

1. **Discovery**: 'git pull' to stay in sync with other agents.
2. **QC applicability**: decide whether K18/QC is REQUIRED or NOT APPLICABLE
   before selecting commands or writing the execution plan.
3. **Work**: Move task to '02-in-progress', execute changes.
4. **Validation**: Run smoke tests and applicable QC.
5. **Synchronization**: 'git push' changes to origin.
6. **Completion**: Move task to '04-done' ONLY after step 5 is confirmed.

## K18/QC Applicability Decision Gate

Before execution, list the changed file classes and inspect task-specific
acceptance criteria.

```text
Does the task modify data, variable coding, ID/time structure, FOF derivation,
baseline/follow-up/delta definitions, missingness rules, inclusion/exclusion
logic, model frames, K18/QC code, QC artifacts, or explicitly require K18/QC?
  yes -> REQUIRED
  no  -> NOT APPLICABLE with documented reason
```

K18/QC REQUIRED triggers include participant-level or observation-level data,
imported or processed data structure, variable names/types/labels/factor levels,
ID uniqueness or ID-time structure, baseline or follow-up outcome definitions,
delta derivation, FOF status derivation or coding, missingness rules or outputs,
inclusion/exclusion logic, model-frame construction, K18 scripts, QC checks,
thresholds, summarizers, runners, QC artifacts, analysis outputs whose
acceptance depends on K18 evidence, and any task acceptance criterion that
explicitly requires K18/QC.

K18/QC is normally NOT APPLICABLE for prose documentation, README restructuring,
task-card documentation, diagram file organization, `git mv` operations with
unchanged scientific content, path-reference maintenance, legacy archiving,
non-scientific manifest path correction, formatting or spelling, repository
metadata that does not change analysis execution, and manuscript handoff
documentation.

Completed task validation must record exactly one of:

```text
K18/QC: PASS
K18/QC: NOT APPLICABLE — <specific reason>
```

`NOT APPLICABLE` is invalid when data, variable coding, inclusion logic, model
frames, K18 code, QC code, or QC artifacts changed. If K18/QC is REQUIRED and
cannot run, the task remains blocked. Task-specific acceptance criteria override
the default classification.
