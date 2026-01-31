# Runbook: MCP Diagnostics & Setup (Windows PowerShell 7)

**Päivämäärä:** 2026-01-30
**Kohderyhmä:** Gemini CLI -käyttäjät (Windows)
**Tarkoitus:** Korjata "Docker works, others missing" -tilanne ja konfiguroida MCP-serverit.

## 1. Nykytila ja Suositus

**Havainnot:**

- **Docker Daemon:** Ei yhteyttä (`npipe` error). Docker Desktop ei ole käynnissä tai ei hyväksy yhteyksiä.
- **Konfiguraatio:** `mcpServers` -määritykset puuttuvat aktiivisesta konfiguraatiosta (`.gemini/settings.json` tai VS Code).
- **Environment:** Node.js ja Python on asennettu, mutta MCP-servereitä ei ole määritelty niitä käyttämään.

**Suositus: A (Pysy PowerShell 7:ssä ja korjaa konfiguraatio)**
Koska käytät jo CLI:tä, helpoin tapa on korjata `settings.json` ja käynnistää Docker. VS Code (Option B) on vaihtoehto, jos haluat graafisen käyttöliittymän, mutta se ei korjaa CLI-agentin näkyvyyttä.

## 2. Korjaustoimenpiteet (Checklist)

### Vaihe 1: Käynnistä Docker

- [ ] Käynnistä **Docker Desktop** Windowsissa.
- [ ] Varmista PowerShellissä: `docker ps` ei anna virhettä.

### Vaihe 2: Konfiguroi Gemini CLI

Luo tai muokkaa tiedostoa `~/.gemini/settings.json` (Windowsissa `C:\Users\<user>\.gemini\settings.json`).

Lisää `mcpServers`-lohko (katso Config Snippet alla).

- [ ] Kopioi alla oleva JSON `settings.json` -tiedostoon.
- [ ] Varmista, että JSON on validi (ei ylimääräisiä pilkkuja).

### Vaihe 3: Aseta Ympäristömuuttujat

Jotta `secure-analysis-r` toimii, data-polku pitää määritellä.

- [ ] PowerShell: `$env:PRIVATE_DATA_PATH = "C:\Polku\Dataan"`
- [ ] Pysyvä asetus: `[System.Environment]::SetEnvironmentVariable('PRIVATE_DATA_PATH', 'C:\Polku\Dataan', 'User')`

## 3. Config Snippet (Windows-yhteensopiva)

Tämä konfiguraatio lisää Docker-serverit ja esimerkin `filesystem`-serveristä (stdio).

```json
{
  "mcpServers": {
    "healthcare-mcp-public": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--network",
        "host",
        "cicatriiz/healthcare-mcp-public:latest"
      ]
    },
    "secure-analysis-r": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "--network",
        "none",
        "-v",
        "${PRIVATE_DATA_PATH}:/data:ro",
        "finite-sample/rmcp:latest"
      ]
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "C:\\GitWork\\Python-R-Scripts"
      ]
    }
  }
}
```

**Huomioita Windows-käyttäjille:**

1. **Polut:** Käytä tuplakenoja `\\` tai kauttaviivoja `/` poluissa JSON-sisällä.
2. **Command:** `npx` vaatii, että Node.js on PATHissa. Jos ei toimi, käytä täyttä polkua `C:\\Program Files\\nodejs\\npx.cmd`.
3. **Docker:** `--network host` toimii Windowsissa rajoitetusti, mutta MCP stdio-putken (via `docker run -i`) pitäisi toimia.

## 4. Vianmääritys

| Ongelma                        | Ratkaisu                                                                |
| ------------------------------ | ----------------------------------------------------------------------- |
| `docker: error during connect` | Käynnistä Docker Desktop.                                               |
| Serveri ei näy listassa        | Tarkista JSON-syntaksi ja tiedoston sijainti (`.gemini/settings.json`). |
| `npx` ei löydy                 | Lisää Node.js PATHiin tai käytä täyttä polkua.                          |
