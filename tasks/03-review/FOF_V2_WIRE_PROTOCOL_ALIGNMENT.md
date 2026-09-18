# TASK: FOF_ARTIFACT_HANDOFF/2 Wire Protocol Alignment

## Objective
Align the canonical PowerShell receiver with the normative FOF_ARTIFACT_HANDOFF/2 sender wire format and prove the complete sender-to-receiver contract with an isolated end-to-end test.

## Scope
- v2 archive: `manifest.json` plus `files/<staging_path>`.
- sender-generated run_id transported and correlated end to end.
- canonical v2 manifest, content digest and receipt schema.
- receiver, sender, adapter, documentation and integration tests only.

## Exclusions
- DEAC transfer profile and senior brief.
- Failed-run cleanup or staging migration.
- Scientific code, data, Registry and Changelog.

## Definition of done
- Real sender bundle is accepted by the real receiver in isolated temporary staging.
- VERIFIED.json and stdout receipt have the same run_id and required v2 fields.
- Sender correlation logic returns SUCCESS.
- Negative protocol/security tests pass.
- Clean checkout and preflight checks pass.
- Focused PR is prepared; no automatic merge.

## Log
- 2026-09-18: Task admitted after forensic diagnosis of sender/receiver wire mismatch.
