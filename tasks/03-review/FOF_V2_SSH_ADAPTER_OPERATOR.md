# FOF v2 SSH adapter and operator runbook

## Context

Owner packet `fof-durable-handoff-v2-ssh-adapter-and-operator-runbook`
authorizes dedicated admission, local implementation and harmless Windows smoke.
Status: review. No production activation, receiver change, Git delivery or A4 work.

## Scope

- Fear-of-Falling/scripts/termux/fof_v2_ssh_adapter.py
- Fear-of-Falling/tests/test_v2_ssh_adapter.py
- Fear-of-Falling/docs/ARTIFACT_TRANSFER.md
- This task card (ready -> in-progress -> review).

## Acceptance

Binary stdin/stdout and SSH exit preservation; noninteractive host-key-verified
SSH; strict runtime configuration; exact delivered receiver; synthetic local
and real Windows smoke PASS; existing source/legacy regressions PASS.
Production profile and receiver approvals remain empty; unrelated state intact.
K18/QC: NOT APPLICABLE — transport invocation only, no scientific changes.

## Agent log

- 2026-09-16: Admitted from explicit Owner packet; ready card created.
- 2026-09-16: Moved in-progress before implementation; reviewed current sender/receiver contracts.

- 2026-09-16: DURABLE_HANDOFF_V2_OPERATOR_PATH_READY_FOR_HUMAN_REVIEW.
  Exact four-file scope: adapter, focused tests, operator section in existing
  transport document and this task. No second convenience wrapper.
- Runtime contract: FOF_V2_SSH_ALIAS + FOF_V2_RECEIVER_SCRIPT; SSH alias owns
  user/host/port/key configuration outside Git. Optional explicit synthetic
  FOF_V2_SMOKE_SESSION binds the existing receiver smoke route. Binary stdio
  and exit status pass through exec SSH; no payload processing, retries,
  deletion, production approval or Git/import behavior added.
- Adapter suite: 11/11 PASS, including binary 2 MiB preservation, config before
  stdin consumption, injection rejection, strict SSH options, exact JSON and
  stderr separation, sender SUCCESS/FAILED/UNKNOWN, preview and approval gates.
- Existing protocol/source suite: 48/48 PASS, zero skips (130.808 s).
  Initial run used an obsolete PRoot-visible PowerShell path and failed with
  exit 127; then the existing PowerShell binary required a .NET heap limit.
  Final tests used existing PowerShell 7.4.1 through a test-only Debian bind,
  DOTNET_GCHeapHardLimit=0x10000000 and DOTNET_gcServer=0. No installation,
  repository/runtime configuration change or receiver modification.
- Historical check_sender.py: 29/29 PASS, deterministic/source-preserving,
  zero network/Git calls. Syntax/AST, Bash syntax, documentation links/fences,
  executable mode and whitespace PASS. fof-preflight exit 0: existing K40
  dynamic-contract WARN only, no FAIL. K18/QC NOT APPLICABLE.
- Real Windows smoke: approved synthetic files only; adapter --check PASS;
  normal test identity -> SUCCESS/exit 0 with durable VERIFIED and 2/2 file
  size/SHA parity; separate nonempty-but-unapproved content registry ->
  correlated FAILED/exit 1 with zero VERIFIED. Production registry unchanged.
  Receiver remained 0670147b40662a5cfbd84336da9beb4a830f1f63524f508cbc51a4a1424c9ec0.
  Windows HEAD/index/status and four core implementation hashes matched before
  and after. Existing receiver/production areas were not written; new isolated
  smoke sessions/evidence are preserved, with no cleanup or retry.
- External evidence: fof-v2-adapter-real-w7o7rysl/result.json, preview.json,
  verified.json, per-case stdout/stderr and Windows baseline. Sessions:
  success 0133e8419b8f4c21a12b822b4a05d69b;
  content-rejected 153b6a1ba4ed4736b0590bee13581ca5.
  Protocol log: fof-v2-adapter-protocol-tests.txt. Machine-specific locations
  stay in external runtime evidence, not portable repository configuration.
- Source HEAD/index and unrelated pre-existing regular-file hashes unchanged;
  sender byte-identical, production profile EMPTY_NOT_EXECUTABLE/files=[] and
  receiver approved_content_digests=[] preserved. No scientific payload, A4
  work, reverse transfer, rsync, Git delivery or production activation.
- Normal ready -> in-progress -> review lifecycle completed; done remains a
  human decision. This local implementation has not been committed or pushed.

- Reviewed SHA-256 `Fear-of-Falling/scripts/termux/fof_v2_ssh_adapter.py`: `13e74c9114851ba8b651dd54d7edd4d9b6f88249e45e0e891edddc5fda6adf1b`.

- Reviewed SHA-256 `Fear-of-Falling/tests/test_v2_ssh_adapter.py`: `d21bbba2b74e07cc576803720469de4e17962371a82081654c61d860f26f8f6a`.

- Reviewed SHA-256 `Fear-of-Falling/docs/ARTIFACT_TRANSFER.md`: `608754d0019f3fc1f25b18d20214da96f9fa00d730ae8328e4d9f35b3ba4d478`.

- 2026-09-16T16:01:49+03:00: Ruff-korjaus: vain testimoduulin importtijärjestys,
  käyttämättömien os/sys-importtien poisto ja E701/E702-rivien jako.
  AST ilman ylimmän tason importteja sekä kaikki vakiot/fixture-merkkijonot
  identtiset; assertioita, protokollaodotuksia tai SSH-valintoja ei muutettu.
  Ruff PASS (adapteri + testit); adapteri 11/11, protokolla 48/48 ilman
  skippejä ja legacy 29/29 PASS. Syntaksi/whitespace, Prettier ja Markdownlint
  PASS; fof-preflight vain ennestään tunnettu K40 WARN.
  Testin uusi SHA-256: `4d9a40143d83d09776a1a469b8f236540109f38fd6251490d94c7b7455b6776e`.
  Testin Git blob: `e357da82d6f59e3e220ee97fd3e71750169a3892`.
  Adapteri/hash/mode ennallaan; aiempi Windows SUCCESS/FAILED-smoke säilyy.
  Dokumentin hyväksytty main-pohjainen korjaus pysyy muuttumattomana:
  SHA-256 `fa71b9404609e75851001dfd330bb80b1dcfb2102e959fecebb78dff9ba9a2a2`,
  blob `50c33e2e722ab9bb9094b85439fc0da75c48e594`.
  Ulkoinen näyttö: `fof-test-ruff-repair/adapter.log`, `protocol.log`,
  `legacy.log` ja `result.json`. Ei Windows-uusinta-ajoa, Git-toimitusta,
  tuotantoaktivointia tai tehtävän tilasiirtoa.
