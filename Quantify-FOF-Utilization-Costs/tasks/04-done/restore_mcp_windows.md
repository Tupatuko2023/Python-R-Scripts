# TASK: Restore MCP connectivity on Windows PowerShell

**Status**: 01-ready
**Assigned**: Gemini
**Created**: 2026-01-30

## OBJECTIVE

Restore MCP connectivity on Windows PowerShell (Docker + stdio). This includes ensuring Docker is reachable and generating a valid configuration for both containerized and local (stdio) MCP servers.

## INPUTS

- `docs/runbook_mcp_windows.md`
- `config/mcp/mcpServers.example.json`

## STEPS

1. **Gate check**: Verify Docker is running (`docker ps`) and reachable.
2. **Create config**: Generate `config/mcp_windows_fix.json` with correct Windows paths for `filesystem` (stdio) and `MCP_DOCKER` servers.
3. **Documentation**: Update `docs/runbook_mcp_windows.md` with instructions on how to apply the generated fix.

## ACCEPTANCE CRITERIA

- [ ] `config/mcp_windows_fix.json` exists and contains valid JSON.
- [ ] Windows paths in the JSON are correctly escaped (double backslashes).
- [ ] `docs/runbook_mcp_windows.md` is updated with application instructions.
