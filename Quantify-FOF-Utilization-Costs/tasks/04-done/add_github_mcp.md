# TASK: Add GitHub MCP Server (Windows)

**Status**: 01-ready
**Assigned**: Gemini
**Created**: 2026-01-30

## OBJECTIVE

Lisää GitHub MCP -palvelin `config/mcp_windows_fix.json` -tiedostoon, jotta agentti voi käyttää GitHub-työkaluja (issue search, PR management).

## INPUTS

* `config/mcp_windows_fix.json` (current config)
* GitHub Personal Access Token (PAT)

## STEPS

1. **Token Check**: Varmista, että käyttäjällä on `GITHUB_PERSONAL_ACCESS_TOKEN` asetettuna ympäristömuuttujiin tai `.env`-tiedostoon.
2. **Update Config**: Muokkaa `config/mcp_windows_fix.json` lisäämällä `github`-serveri.
    * Implementation: `npx.cmd -y @modelcontextprotocol/server-github` (Node.js version for Windows compatibility).
3. **Update Runbook**: Lisää ohjeet GitHub-tokenin luomiseen ja asettamiseen `docs/runbook_mcp_windows.md` -tiedostoon.

## ACCEPTANCE CRITERIA

* [ ] `config/mcp_windows_fix.json` sisältää validin `github`-lohkon.
* [ ] Dokumentaatio ohjeistaa Tokenin asettamisen.
