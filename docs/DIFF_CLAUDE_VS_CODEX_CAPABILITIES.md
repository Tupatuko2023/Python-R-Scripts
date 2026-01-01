# Claude vs Codex: capability and policy comparison

## Evidence-based facts (Codex)
### Tooling visible to this Codex session
- `functions.shell_command`
- `functions.apply_patch`
- `functions.list_mcp_resources`
- `functions.list_mcp_resource_templates`
- `functions.read_mcp_resource`
- `functions.update_plan`
- `functions.view_image`
- `mcp__MCP_DOCKER__browser_click`
- `mcp__MCP_DOCKER__browser_close`
- `mcp__MCP_DOCKER__browser_console_messages`
- `mcp__MCP_DOCKER__browser_drag`
- `mcp__MCP_DOCKER__browser_evaluate`
- `mcp__MCP_DOCKER__browser_file_upload`
- `mcp__MCP_DOCKER__browser_fill_form`
- `mcp__MCP_DOCKER__browser_handle_dialog`
- `mcp__MCP_DOCKER__browser_hover`
- `mcp__MCP_DOCKER__browser_install`
- `mcp__MCP_DOCKER__browser_navigate`
- `mcp__MCP_DOCKER__browser_navigate_back`
- `mcp__MCP_DOCKER__browser_network_requests`
- `mcp__MCP_DOCKER__browser_press_key`
- `mcp__MCP_DOCKER__browser_resize`
- `mcp__MCP_DOCKER__browser_run_code`
- `mcp__MCP_DOCKER__browser_select_option`
- `mcp__MCP_DOCKER__browser_snapshot`
- `mcp__MCP_DOCKER__browser_take_screenshot`
- `mcp__MCP_DOCKER__browser_tabs`
- `mcp__MCP_DOCKER__browser_type`
- `mcp__MCP_DOCKER__browser_wait_for`
- `mcp__MCP_DOCKER__code-mode`
- `mcp__MCP_DOCKER__mcp-add`
- `mcp__MCP_DOCKER__mcp-config-set`
- `mcp__MCP_DOCKER__mcp-create-profile`
- `mcp__MCP_DOCKER__mcp-exec`
- `mcp__MCP_DOCKER__mcp-find`
- `mcp__MCP_DOCKER__mcp-remove`
- `multi_tool_use.parallel`

### Network policy indicators
- Env var names indicate network disabled: `CODEX_SANDBOX_NETWORK_DISABLED`, `SBX_NONET_ACTIVE`.
- Offline tooling flags present: `PIP_NO_INDEX`, `CARGO_NET_OFFLINE`, `NPM_CONFIG_OFFLINE`.

## What is missing from Codex to check GitHub Actions
- Network egress is disabled, so GitHub endpoints cannot be reached.
- No repo-local orchestrator config or allowlist files were found to override egress policy.

## Outcome-explaining delta
- Codex has tooling available but cannot make outbound network calls due to sandbox egress disablement.
- Claude likely had egress enabled or a GitHub-specific connector; evidence needed to confirm.

## Claude details required (not provided yet)
- Tooling used (web browsing, GitHub integration, API connector).
- Egress policy (allowlist, proxy requirements).
- Auth method and scope.
- Evidence of successful requests (endpoints called, status codes).

## Comparison table (fill in Claude column when available)

| Dimension | Codex (this run) | Claude (need evidence) | Parity fix (least change) |
|---|---|---|---|
| Tools / integration | Tools exist (shell + MCP browser), but egress disabled prevents external calls | Unknown | Enable egress or provide GitHub connector |
| Network egress | Disabled (env indicates no net) | Unknown | Enable egress to GitHub domains only |
| Domain allowlist | Not found in repo config | Unknown | Allowlist `github.com`, `api.github.com`, `raw.githubusercontent.com` |
| Proxy policy | Proxy env vars exist, values unknown | Unknown | Set proxy env vars if required by org |
| GitHub integration | None observed | Unknown | Provide GitHub connector or API access |
| Auth mechanism | None observed | Unknown | GitHub App or fine-grained PAT with Actions read |
| Secrets injection | None observed | Unknown | Inject token via runtime secrets |

## Smallest change to reach Claude parity (likely)
Enable outbound egress to GitHub endpoints with a strict allowlist, then inject a least-privilege token (Actions read + Contents read). This is the minimum change that can unlock Actions run checks without expanding access broadly.

Minimum parity change checklist:
- Enable egress (GitHub-only allowlist).
- Provide proxy config if required by org policy.
- Inject a GitHub credential (fine-grained PAT or App) with Actions/Contents read.

Concrete config delta (example only; adapt to orchestrator schema):
```yaml
network:
  egress: enabled
  allowlist:
    - github.com
    - api.github.com
    - raw.githubusercontent.com
    - objects.githubusercontent.com
  deny_all_else: true
secrets:
  - name: GITHUB_TOKEN
    source: vault/path/to/least-privilege-token
env:
  - name: GITHUB_TOKEN
    valueFrom: secret:GITHUB_TOKEN
```
