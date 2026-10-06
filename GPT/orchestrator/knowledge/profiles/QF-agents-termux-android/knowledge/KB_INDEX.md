# QFOT2 repository knowledge index

Document review status: **REVIEW**. This index routes a task to the smallest relevant set of repository sources. Reading priority is not an authority hierarchy. A source's presence, wording, or location does not establish scientific approval or technical enforcement.

## Provenance and verification basis

- Checkout revision inspected: `a62957e` (branch `main`; clean when this review began).
- The audit is at [`../audit/QFOT2_kb_audit_1_05102026.md`](../audit/QFOT2_kb_audit_1_05102026.md) and was preserved unchanged.
- The profile `knowledge/` directory had no files before this review. Therefore no repository KB copy could be compared with the profile package or installed add-on. The package `references/` paths named by the audit are not repository paths unless independently located.
- Found source files below are repository sources, not copies whose package approval has been established. Their revision is the inspected checkout revision; no content hashes are asserted here.
- `WORKFLOW.md` exists both at repository root and under the QF subproject. Both were inspected. The QF file begins with ASCII `# Analysis Ops Workflow`; the root file begins with ASCII `# Branch Isolation Rule`. Neither starts with a BOM. They are different files and must not be conflated.
- Audit claims about contents not independently found below remain audit observations, not verified repository facts.

## Core sources

| Source | Role and concrete task | Read when | Use limit | Origin and verification | Maintenance |
|---|---|---|---|---|---|
| [Monorepo README](../../../../../../README.md) | Repository-wide scope, subproject map, security policy | QF versus monorepo scope or cross-project routing | General repo guidance; does not establish QF command behavior | Repository-root source; inspected at `a62957e` | Recheck when monorepo scope/security policy changes |
| [Monorepo AGENTS](../../../../../../AGENTS.md) | Working-root, command, safety, task queue and validation rules | Any repository task | General instructions; apply alongside QF-specific sources without treating read order as authority | Repository-root source; inspected at `a62957e` | Recheck when agent workflow changes |
| [SKILLS policy](../../../../../../SKILLS.md) | Task admission/lifecycle and validation policy | Task selection, transition, or repository gate | Declares its own precedence; does not resolve project/scientific authority | Repository-root policy; inspected at `a62957e` | Recheck when repository policy changes |
| [Agent policy](../../../../../../config/agent_policy.md) and [steering](../../../../../../config/steering.md) | Ready-queue and scope constraints | Task admission and file-scope planning | Do not infer source authority from task priority | Repository config; inspected at `a62957e` | Recheck when governance configuration changes |
| [Root WORKFLOW](../../../../../../WORKFLOW.md) | Monorepo task and branch lifecycle | Lifecycle transition or review | Different from QF `WORKFLOW.md`; reconcile scope conflicts instead of inferring precedence | Repository-root source; name/bytes and content inspected at `a62957e` | Recheck with task lifecycle updates |
| [QF README](../../../../../../Quantify-FOF-Utilization-Costs/README.md) | Project scope, Option B, layout, documented quickstart | Scope or sample-route question | Documentation only; “Ready for Data” and described commands do not prove readiness or execution | QF repository source; inspected at `a62957e` | Recheck after layout, CLI, or governance changes |
| [QF AGENTS](../../../../../../Quantify-FOF-Utilization-Costs/AGENTS.md) | Conflict-resolution wording | Agent conflict or merge question | UNION/schema adaptation does not authorize data joins or resolve scientific conflicts | QF repository source; inspected at `a62957e` | Reconcile with agent policy when it changes |
| [QF CLAUDE](../../../../../../Quantify-FOF-Utilization-Costs/CLAUDE.md) | Option B, mapping, reproducibility, manifest, script standards | Mapping or script policy question | Calls the standardization CSV source of truth, but current CSV rows are placeholders/TBD; policy is not implementation proof | QF repository source; inspected at `a62957e` | Recheck with mapping and manifest changes |
| [QF WORKFLOW](../../../../../../Quantify-FOF-Utilization-Costs/WORKFLOW.md) | QF task lifecycle | QF task lifecycle question | Project workflow source; distinct from repository-root `WORKFLOW.md` | QF repository source; bytes/name verified at `a62957e` | Recheck when task lifecycle changes |
| [Python runbook](../../../../../../Quantify-FOF-Utilization-Costs/docs/runbook.md) | Termux install text, Python sample/QC, output and extraction rules | Python route, output, or sample-validation planning | Contains legacy install prose; commands below are documented, not current recommendations or test evidence | QF repository source; inspected at `a62957e` | Reverify environment and commands before recommending |
| [Secure execution guide](../../../../../../docs/guides/RUNBOOK_SECURE_EXECUTION.md) | R environment, DATA_ROOT, QC/model workflow, outputs | Secure R-run planning | Contains commands and analytic assertions; not a grant of data access or proof of implementation | Repository guide; inspected at `a62957e` | Reconcile with current analysis plan and code before use |

## Task-specific sources

| Source | Role and concrete task | Read when | Use limit | Origin and verification | Maintenance |
|---|---|---|---|---|---|
| [Variable standardization CSV](../../../../../../Quantify-FOF-Utilization-Costs/metadata/VARIABLE_STANDARDIZATION.csv) | Source/destination names and transform placeholders | Variable mapping or recode request | CSV preserved unchanged; rows include `TBD`; do not infer or approve a conversion | QF repository CSV; header and rows inspected at `a62957e` | Human-approved mapping update only in a separate task |
| [Data dictionary CSV](../../../../../../Quantify-FOF-Utilization-Costs/metadata/data_dictionary.csv) | Variable labels, types, units, coding placeholders | Schema question | `TBD` and placeholder text are unresolved; metadata names do not make metrics safe to publish | QF repository CSV; header and rows inspected at `a62957e` | Update only with verified provenance and approval |
| [Termux context](../../../../../../Quantify-FOF-Utilization-Costs/GEMINI_TERMUX.md) | Termux-specific historical agent routes and commands | Termux command question | Conflicts with current source layout in places; not authoritative runtime evidence | QF repository source; inspected at `a62957e` | Reconcile or retire stale routes |
| [Termux R blocker handover](../../../../../../Quantify-FOF-Utilization-Costs/docs/HANDOVER_termux_r_install_blockers.md) | Historical Termux/PRoot installation and smoke observations | Runtime blocker history | Historical, environment-specific; alternatives are proposals, not recommendations | QF repository source; inspected at `a62957e` | Revalidate before relying on any status |

## Background sources (open only for a stated historical question)

| Source | Role and concrete task | Read when | Use limit | Origin and verification | Maintenance |
|---|---|---|---|---|---|
| [Data placement comparison](<../../../../../../docs/guides/Datan sijoitus- ja suojausmallin vertailu.docx.md>) | Historical Option A/B rationale | Asked to explain design history | Partially inspected; advocacy and risk claims are not approval or technical controls | Repository background report; selected sections inspected at `a62957e` | Preserve in place; relabel only through separate documentation task |
| [Project structure and agent integration report](<../../../../../../docs/guides/Quantify FOF – Projektirakenne, Datakäsittely ja Agentti‐integraatio.docx.md>) | Historical architecture proposals | Asked to explain design history | Partially inspected; proposals include unsafe/obsolete patterns and do not establish current implementation | Repository background report; selected sections inspected at `a62957e` | Preserve in place; do not route routine tasks here |
| `K1-K18.R.md` | Historical analysis-code interpretation | A named K1–K18 passage is requested | **Not found** in this checkout; audit/package reference is not a repository path. No claim about its contents or default search behavior | Unavailable; `rg --files` checked | Recheck only if task needs this source |
| `Muuttujasanakirja.md` | Human-readable metadata overview | A specific inventory snapshot is requested | **Not found** in this checkout; do not substitute a similarly named file without checking | Unavailable; `rg --files` checked | Recheck only if task needs this source |

## Task-specific source routing

Starting source means the first useful source for the task, not the highest authority. Reading order never resolves an authority conflict.

| Task | Starting source | Supporting sources | Stop condition |
|---|---|---|---|
| Documentation change | The document being changed and [QF README](../../../../../../Quantify-FOF-Utilization-Costs/README.md) for project claims | [QF AGENTS](../../../../../../Quantify-FOF-Utilization-Costs/AGENTS.md); [QF CLAUDE](../../../../../../Quantify-FOF-Utilization-Costs/CLAUDE.md) for data/mapping rules; relevant runbook | Stop only the claim or edit dependent on missing source, unclear scope, or unresolved conflict; continue independent copyediting. |
| Agent instruction review | The instruction under review and the [reviewer specification below](#profile-instruction-agent-instruction-reviewer) | [QF AGENTS](../../../../../../Quantify-FOF-Utilization-Costs/AGENTS.md), [QF CLAUDE](../../../../../../Quantify-FOF-Utilization-Costs/CLAUDE.md), relevant runbook and repository policies | Stop a dependent action if its source, authority, scope, or safety control is unresolved. Do not present review as a technical test. |
| Variable mapping | [Variable standardization CSV](../../../../../../Quantify-FOF-Utilization-Costs/metadata/VARIABLE_STANDARDIZATION.csv) | [Data dictionary CSV](../../../../../../Quantify-FOF-Utilization-Costs/metadata/data_dictionary.csv); QF CLAUDE; named source documentation | Stop mapping/recode when source, target, dataset, transform, code, provenance, or approval is missing or `TBD`/`FIXME`. Do not infer a conversion. |
| Python execution guidance | [Python runbook](../../../../../../Quantify-FOF-Utilization-Costs/docs/runbook.md) | QF README; [Termux context](../../../../../../Quantify-FOF-Utilization-Costs/GEMINI_TERMUX.md); current script when execution is separately authorized | Stop if environment, working root, input class, output effects, fallback route, or required gates cannot be verified. A documented command is not a tested command. |
| Secure R-run planning | [Secure execution guide](../../../../../../docs/guides/RUNBOOK_SECURE_EXECUTION.md) | QF CLAUDE; current [analysis plan](../../../../../../Quantify-FOF-Utilization-Costs/docs/ANALYSIS_PLAN.md); mapping CSVs | Stop dependent planning if the approved method, panel provenance, mapping, environment, DATA_ROOT authorization, or output conditions are unresolved. Do not run a research pipeline from this profile task. |
| Termux/PRoot | [Termux/PRoot execution reference](TERMUX_PROOT_EXECUTION_REFERENCE.md) | QF runbook; Termux context; [historical blocker handover](../../../../../../Quantify-FOF-Utilization-Costs/docs/HANDOVER_termux_r_install_blockers.md) | Stop if current host/container, distribution, runtime, working root, install source, or command behavior is unknown. Never issue a Termux-to-PRoot login from inside PRoot. |
| Synthetic validation | QF README's sample quickstart | Python runbook; current entrypoint and sample source; ignore/output rules | Stop if the exact sample is not shown to be synthetic, a path can fall back to DATA_ROOT/external input, or outputs/side effects cannot be confined and inspected. |
| Aggregate release review | Python runbook's aggregate/suppression section | Secure execution guide; installed instruction; approved metadata allow-list and current output implementation | Stop unless explicit task-specific user permission and `ALLOW_AGGREGATES=1` are both in effect, the output fields are approved, and `n < 5` suppression is verified. A data-derived metric is not safe merely because it is called metadata. |
| Historical analysis-code interpretation | A named section in `K1-K18.R.md`, if independently located | Provenance and version-specific dictionary/mapping for the same analysis | Stop if the requested source is unavailable or is being used to assert current method, runtime, mapping, or production behavior. |

## Profile instruction: agent instruction reviewer

This section is a **profile instruction** for a text-review role. It does not state that an automated reviewer or technical control is implemented.

- **Purpose:** assess whether an agent instruction is in scope, supported by the requested sources, internally consistent, and explicit about authorization and safety boundaries.
- **Inputs:** user task and authorization; instruction under review; relevant located sources and their read scope; any proposed environment, commands, inputs, and outputs; known missing sources and conflicts.
- **Checks:** task scope and reviewer/agent role; source provenance and authority limits; Option B and repo-external data; source/target mapping provenance; output/log/stdout path and identifier risks; manifest field allow-list; `outputs/` and `docs/derived_text/` exclusion; both aggregate gates; `n < 5` blank plus `suppressed=1`; extraction identifier stops; Termux versus PRoot command context; documented versus executed/tested command status.
- **Results:** report `PASS`, `FAIL`, or `NEEDS_VERIFICATION` for each required check with source, evidence/read scope, unresolved gap, and correction. Overall `PASS` requires every required check to pass. A `FAIL` or required `NEEDS_VERIFICATION` blocks only actions that depend on that check; unrelated safe text work may continue.
- **Fail-closed conditions:** do not infer missing source contents, mapping approval, current runtime, manifest allow-list, user permission, or technical enforcement. Stop a dependent action when required provenance, environment, output safety, suppression, or authorization cannot be established. A documented rule is not evidence that software enforces it.
- **Forbidden actions:** execute reviewed commands; read or process research/participant-level data; calculate aggregates; edit mappings or data; approve methods or permissions; change repository or installed add-on files; claim technical enforcement from instruction wording.

## Open decisions and safe routing

- The root agent policy, root `WORKFLOW.md`, QF `WORKFLOW.md`, QF README, and QF agent guidance have different scopes. Their reading order does not resolve authority. Keep unresolved precedence as `NEEDS_VERIFICATION` and stop only work that depends on a disputed rule.
- The audit describes a sex-code discrepancy between package copies. The repository CSVs inspected here do **not** reproduce those values: the standardization CSV's sex-related rows are absent and the dictionary uses `TBD`. Do not copy the audit's values into repository knowledge or infer a recode. The CSVs remain unchanged.
- The audit's proposed profile `AGENTS.md`, `runbook.md`, and related Knowledge copies were not present under this profile. No operational copy was edited. New safety guidance is explicitly a profile instruction in this knowledge set, not a canonical repository change.
- Manifest field allow-list: `NEEDS_VERIFICATION`. The QF CLAUDE source gives a manifest template, but this review does not approve those fields as safe or complete. A value derived from data is not automatically safe metadata.
- Runtime versions, current installation guidance, PRoot distribution, and command availability: `NEEDS_VERIFICATION`. No stale version is promoted to a current recommendation.
- Technical enforcement of output sanitization, aggregate gates, suppressions, and extractor behavior: `NEEDS_VERIFICATION`. Documentation statements are requirements, not implementation evidence.
- Aggregate release requires both task-specific explicit user permission and `ALLOW_AGGREGATES=1`. No aggregates were calculated in the initial stage. A later, separately authorized synthetic QC smoke produced seven QC summaries in its own ignored output directory, as recorded in the [execution reference](TERMUX_PROOT_EXECUTION_REFERENCE.md#command-review-ledger). It processed no research data or external inputs. This smoke does not pass add-on behavior tests or technical control implementation tests. For `n < 5`, protectable values are blank and `suppressed=1`.
- Do not place raw, decrypted, participant-level data, generated `outputs/`, or `docs/derived_text/` artifacts in commits. Do not print absolute environment paths, identifiers, or secrets. Do not turn metric values calculated from data into approved metadata without a specific review.

## When no KB search is needed

No project source lookup is needed for a wording-only edit to user-provided text or a fully synthetic, project-independent example, provided the response makes no claims about current project files, variable meanings, runtime commands, or project policy.
