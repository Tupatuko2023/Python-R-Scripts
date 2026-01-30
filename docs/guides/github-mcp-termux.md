# GitHub MCP Termuxissa

## Mika on MCP-client/host?

MCP-client (tai MCP-host) on sovellus, joka yhdistaa MCP-serveriin ja valittaa tyokalukutsuja. Tassa tapauksessa MCP-serveri on GitHub MCP joko GitHubin hostaamana remote-endpointtina (HTTP/SSE) tai paikallisesti ajettavana `github-mcp-server`-prosessina (stdio).

## Codex ja Gemini: roolit ja arkkitehtuuri

Tarkeaa: Codex CLI ja Gemini CLI ovat molemmat MCP-hosteja. Codex ei tyypillisesti "kayta GitHub MCP:ta Geminin kautta", vaan liitos tehdaan suoraan siihen hostiin, jota kaytat agenttina.

Polku A (suositus): Codex -> GitHub MCP

```
Codex CLI (MCP-host)
  -> GitHub MCP (remote HTTP/SSE) tai github-mcp-server (local stdio)
```

Codex-konffi (remote, virallinen) `~/.codex/config.toml`:

```toml
[mcp_servers.github]
url = "https://api.githubcopilot.com/mcp/"
bearer_token_env_var = "GITHUB_PAT_TOKEN"
```

Vaihtoehtoisesti (virallinen):

```bash
codex mcp add github --url https://api.githubcopilot.com/mcp/
```

Polku B (vaihtoehto, ei MCP-bridge): Codex -> (shell) Gemini -> GitHub MCP

```
Codex CLI
  -> (shell/command) gemini (MCP-host)
       -> GitHub MCP (remote/local)
```

Tassa mallissa MCP-tyokalut eivat ole samassa agentissa; Codex saa vain Gemini CLI:n tulosteen.

## Suositus Termuxiin (Gemini CLI + remote HTTP/SSE)

Gemini CLI on dokumentoidusti MCP-yhteensopiva ja toimii Linuxissa. Termuxissa helpoin polku on GitHubin hostattu MCP-serveri:

- Remote URL: `https://api.githubcopilot.com/mcp/`
- Transport: HTTP/SSE (Streamable HTTP)
- Auth: OAuth tai PAT (Authorization: Bearer ...)

### Asennus (Node 20+)

```bash
npm install -g @google/gemini-cli
# tai kertakaytto:
npx @google/gemini-cli
```

### Token-hygienia (esimerkki)

Laita token ymparistomuuttujaan. Esim. `~/.gemini/.env`:

```bash
GITHUB_MCP_PAT=YOUR_TOKEN
```

### Remote MCP -konffi (Gemini CLI)

`~/.gemini/settings.json`:

```json
{
  "mcpServers": {
    "github": {
      "httpUrl": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer $GITHUB_MCP_PAT"
      }
    }
  }
}
```

### Testi (Gemini CLI)

```bash
gemini
/mcp list
```

## Local fallback (stdio + Go-build)

Jos remote ei toimi (esim. organisaatiopolitiikat), voit ajaa localin `github-mcp-server` stdio-tilassa. Dockeria ei oleteta Termuxissa.

```bash
git clone https://github.com/github/github-mcp-server
cd github-mcp-server
go build -o github-mcp-server ./cmd/github-mcp-server

GITHUB_PERSONAL_ACCESS_TOKEN=YOUR_TOKEN ./github-mcp-server stdio
```

### MCP-clientin stdio-konffi (yleinen malli)

```json
{
  "mcpServers": {
    "github": {
      "command": "/path/to/github-mcp-server",
      "args": ["stdio"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "$GITHUB_MCP_PAT"
      }
    }
  }
}
```

### Testi (local server)

```bash
GITHUB_PERSONAL_ACCESS_TOKEN=YOUR_TOKEN ./github-mcp-server tool-search "issue" --max-results 5
```

## Remote-yhteyden pikadiagnostiikka (curl)

```bash
curl -i -H "Accept: text/event-stream" https://api.githubcopilot.com/mcp/
curl -i -H "Accept: text/event-stream" -H "Authorization: Bearer YOUR_TOKEN" https://api.githubcopilot.com/mcp/
```

## Vianetsinta

- 401/403: tokenin scopet puuttuvat, token vanhentunut, tai organisaation Copilot/MCP-policy estaa.
- HTTP/SSE ei toimi: MCP-client ei tue Streamable HTTP -transporttia.
- TLS/CA: paivita `ca-certificates` Termuxissa/prootissa.
- Android taustarajoitteet: pidä Termux foregroundissa raskaiden sessioiden ajan.

## Turvaohjeet

- Ala koskaan committaa tokeneita tai `.env`-tiedostoja.
- Pida tokenit ymparistomuuttujissa tai clientin salaisissa syotteissa.
- Kayta vain vahvimmin tarvittavia scopeja.

---

## Termux: canonical MCP test protocol

See also: `SKILLS.md` → "Authoritative MCP Test Protocol" (canonical).
