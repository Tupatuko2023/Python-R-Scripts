# HANDOVER.md: Agent Workflow Protocol

## Phase 1: Specification (User)
- Create a spec in 'docs/specs/' defining the script's input, logic, and output.

## Phase 2: Architecture (Architect Agent)
- Analyze the spec against 'Policy.md'.
- Produce a Technical Plan in 'docs/architecture/'.
- **GATE 2:** Manager validates the plan (Confidence Score).

## Phase 3: Implementation (Integrator Agent)
- Generate the code based on the Technical Plan.
- Generate unit tests in 'tests/'.
- **GATE 3:** Run tests. If pass -> SUCCESS. If fail -> REFLECTION -> RETRY.

## Phase 4: Audit
- Log all major actions to 'logs/agent_audit.log'.
