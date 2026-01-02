<!-- markdownlint-disable MD013 -->

# RCA: Codex cannot check GitHub Actions runs/logs/API

## Executive summary

- Most likely root cause: network egress is disabled in this Codex runtime.
- Evidence: runtime env var names include `CODEX_SANDBOX_NETWORK_DISABLED` and `SBX_NONET_ACTIVE`, plus offline flags like `PIP_NO_INDEX`, `CARGO_NET_OFFLINE`, and `NPM_CONFIG_OFFLINE`.
- Impact: any attempt to reach GitHub endpoints (Actions runs, logs, REST/GraphQL) fails at transport before auth is evaluated.
- Why this is primary: auth/scopes cannot be tested if TCP/DNS/TLS cannot establish a connection.

## Evidence collected (non-secret)

### Repository workflows present

- `.github/workflows/python-ci.yml`
- `.github/workflows/r-ci.yml`
- `.github/workflows/smoke-tests.yml`
- `.github/workflows/markdownlint.yml`
- `.github/workflows/codeql.yml`

### Runtime indicators

- Env var names indicate network disabled: `CODEX_SANDBOX_NETWORK_DISABLED`, `SBX_NONET_ACTIVE`.
- Offline tooling flags present: `PIP_NO_INDEX`, `CARGO_NET_OFFLINE`, `NPM_CONFIG_OFFLINE`.
- Proxy variables are present in the environment list (`HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`, `NO_PROXY`) but values were not printed to avoid secrets.
- Evidence source: runtime env name listing from this session (offline snapshot; no values captured).

### Orchestrator config discovery

- Searched for agent/orchestrator/env config files in repo; none found (`*agent*.yml`, `*agent*.yaml`, `*orchestrator*.json`, `.env*`).
- No repo-level config indicating allowlists, proxy policy, or secrets injection was located.

## Root cause

The Codex runtime is running with network egress disabled, which prevents any outbound GitHub API/web requests. This blocks Actions run status/logs/API checks at the transport layer regardless of token presence or scopes.

## Evidence quality note

- Primary evidence is the presence of network-disabled indicators (`CODEX_SANDBOX_NETWORK_DISABLED`, `SBX_NONET_ACTIVE`) and offline flags, plus a successful PS1 offline run returning exit_code=10.
- Online confirmation is pending explicit approval; no network tests were executed in this session.

## Transport vs auth decision tree (error type -> conclusion)

- DNS failure (`NXDOMAIN`, `SERVFAIL`): network/DNS blocked or proxy required.
- TLS handshake failure (`certificate verify failed`, `handshake failure`): MITM/proxy CA trust issue.
- Timeout / connection refused: egress blocked or proxy missing.
- HTTPS routed to `127.0.0.1` proxy and fails: forced proxy policy or local proxy misconfiguration.
- HTTP 401: auth missing/invalid token.
- HTTP 403: scope missing, SSO/SAML not authorized, IP allowlist, or rate limit.
- HTTP 404 on private repo: repo not visible to token/app installation.

## Alternative hypotheses (24) and falsification tests

1. DNS blocked globally. Test: `nslookup api.github.com` or `dig api.github.com` (expected: DNS error).
2. TCP egress blocked (any host). Test: `curl -I https://example.com` (expected: timeout/refused).
3. TLS MITM or blocked by CA trust. Test: `openssl s_client -connect api.github.com:443 -servername api.github.com` (expected: TLS verify/handshake error).
4. GitHub domain blocked by allowlist. Test: `curl -I https://example.com` succeeds but `curl -I https://api.github.com` fails (expected: timeout or refused).
5. GitHub API blocked by corporate firewall. Test: `curl -I https://api.github.com` fails; `curl -I https://github.com` succeeds (expected: timeout/refused to api).
6. Proxy required but not configured. Test: proxy env vars empty; `curl` fails until proxy is set (expected: timeout/refused).
7. Proxy configured but auth missing. Test: `curl` to any host returns 407 (expected: HTTP 407).
8. Proxy configured but MITM cert not trusted. Test: `curl` fails with TLS verify errors (expected: TLS error).
9. Proxy bypass misconfigured (NO_PROXY). Test: `curl` to internal host works, GitHub fails (expected: timeout/refused to GitHub).
10. IP allowlist restriction at org level. Test: `curl` to `https://api.github.com` works; org endpoint returns 403 with IP allowlist hint (expected: HTTP 403).
11. SAML SSO not authorized for token. Test: 403 with SSO required message on org API (expected: HTTP 403).
12. PAT missing. Test: GitHub API returns 401 to authenticated endpoint (expected: HTTP 401).
13. Fine-grained PAT missing Actions permissions. Test: 403 on Actions runs endpoint only (expected: HTTP 403).
14. Repo visibility mismatch (private repo). Test: 404 on repo endpoint with valid token (expected: HTTP 404).
15. Token expired or revoked. Test: 401 with valid format token (expected: HTTP 401).
16. Token audience mismatch (GitHub App vs PAT). Test: 401/403 with invalid token type (expected: HTTP 401/403).
17. GitHub App lacks installation on repo. Test: 404 for app auth on repo (expected: HTTP 404).
18. GitHub App permissions missing `actions:read`. Test: 403 on Actions endpoint (expected: HTTP 403).
19. GitHub REST endpoint path typo. Test: 404 for specific path; base API works (expected: HTTP 404 on endpoint).
20. Rate limit exceeded. Test: 403 with rate limit headers; retry after (expected: HTTP 403).
21. GitHub API blocked by user-agent policy. Test: 403 with custom UA works (expected: HTTP 403).
22. TLS version mismatch. Test: `curl --tlsv1.2` succeeds but default fails (expected: TLS error on default).
23. Network policy blocks GitHub via DNS sinkhole. Test: DNS resolves to private IPs (expected: private IP response).
24. Local host firewall blocks outbound 443. Test: `curl` to non-GitHub host on 443 fails (expected: timeout/refused).

## Least-privilege fixes (choose smallest that works)

### A) Allow outbound to GitHub only (preferred)

- Allowlist domains: `github.com`, `api.github.com`, `raw.githubusercontent.com`.
- Optional: `objects.githubusercontent.com`, `uploads.githubusercontent.com` if logs or artifacts are needed.
- No secrets required for public repos; for private repos, use a scoped token.
- Note: auth-only fixes do not help while `SBX_NONET_ACTIVE` / `CODEX_SANDBOX_NETWORK_DISABLED` is present.

Validation tests (online, opt-in only):

1. `curl -I https://api.github.com` returns 200 or 403 (rate limit) instead of network errors.
2. `curl -I https://github.com` returns 200/301.
3. Authenticated call to `/repos/ORG/REPO/actions/runs?per_page=1` (header redacted), expect 200/403.

### B) Enforce proxy with explicit env vars

- Set `HTTPS_PROXY`, `HTTP_PROXY`, and `NO_PROXY` (least scope).
- Provide cert trust if proxy MITM is used.

Validation tests:

1. `curl -I https://example.com` succeeds with proxy.
2. `curl -I https://api.github.com` succeeds with proxy.

### C) Use GitHub App or fine-grained PAT (least privilege auth)

- GitHub App permissions: `Actions: Read`, `Contents: Read`, `Metadata: Read`.
- Fine-grained PAT: repository `Actions: Read` and `Contents: Read`.
- Ensure org SSO authorization if required.

Validation tests:

1. `GET /repos/{owner}/{repo}` returns 200.
2. `GET /repos/{owner}/{repo}/actions/runs?per_page=1` returns 200.

## Concrete orchestrator/agent-config changes (least privilege)

### A) Enable egress with a tight allowlist

Example (pseudo-config; replace with your orchestrator schema):

```yaml
network:
  egress: enabled
  allowlist:
    - github.com
    - api.github.com
    - raw.githubusercontent.com
    - objects.githubusercontent.com
  deny_all_else: true
```

### B) Enforce proxy (only if org policy requires it)

```yaml
network:
  egress: enabled
  proxy:
    http: ${HTTP_PROXY}
    https: ${HTTPS_PROXY}
    no_proxy: ${NO_PROXY}
```

### C) Inject GitHub credential (only after transport works)

```yaml
secrets:
  - name: GITHUB_TOKEN
    source: vault/path/to/least-privilege-token
env:
  - name: GITHUB_TOKEN
    valueFrom: secret:GITHUB_TOKEN
```

Rollback:

- Disable egress or remove allowlist entries to revert to offline behavior.
- Remove proxy settings and secret injections to return to pre-change state.

## Claude vs Codex delta (high level)

- Codex runtime shows network-disabled indicators in env vars.
- Claude run details were not provided, so its tooling and egress policy cannot be verified here.

## Required inputs from user to complete Claude vs Codex parity

- Claude runtime logs showing which tool/integration performed GitHub queries.
- Claude network policy (allowlist/proxy/egress) and any GitHub connector config.
- Auth mechanism (PAT vs App vs OAuth) and scopes.
- Any org SSO/IP allowlist requirements.

## Validation tests (offline vs online)

### Offline (no network)

1. Confirm env flags are present: `CODEX_SANDBOX_NETWORK_DISABLED`, `SBX_NONET_ACTIVE`.
2. Confirm offline tooling flags: `PIP_NO_INDEX`, `CARGO_NET_OFFLINE`, `NPM_CONFIG_OFFLINE`.
3. Confirm no repo-level allowlist/proxy/secrets config exists in the workspace.
4. Confirm tool list does not include a GitHub connector.

### Online (opt-in only)

Run `RUN_NETWORK_TESTS=1 scripts/diag_network_github.sh` after explicit approval.

- Exit code 10: network disabled indicators present.
- Exit code 20: DNS/TLS failure detected.
- Exit code 0: network tests passed (continue to auth tests).

## Observed outcome (this session)

- Offline run attempt (bash): `bash scripts/diag_network_github.sh` from PowerShell.
- Result: blocked by host policy (`E_ACCESSDENIED`), exit_code=1.
- Offline run (PowerShell): `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/diag_network_github.ps1`.
- Result: `CODEX_SANDBOX_NETWORK_DISABLED` / `SBX_NONET_ACTIVE` detected, exit_code=10.
- Network tests did not run; no secrets were printed.
- Recommendation: use `scripts/diag_network_github.ps1` on this host or run the bash script in WSL/Git Bash if allowed.
- Push attempt failure: `github.com:443` via `127.0.0.1` proxy failed; captured in `repo_audit/push_failure_evidence.txt`.

## Diagnostic script

Use `scripts/diag_network_github.sh` to collect transport-layer evidence without printing secrets.
