
## Recovery executed (2026-01-30)

Korjauskonfiguraatio luotu: `config/mcp_windows_fix.json`.

**Käyttöönotto:**

1. Avaa MCP-hostin asetustiedosto (esim. `%USERPROFILE%\.gemini\settings.json` tai vastaava).
2. Kopioi `config/mcp_windows_fix.json` sisältö `mcpServers`-osioon.
3. Käynnistä agentti uudelleen.

## GitHub MCP Setup (Lisätty 2026-01-30)

GitHub-työkalut vaativat Personal Access Tokenin (PAT).

**1. Luo Token:**

* Mene: [https://github.com/settings/tokens](https://github.com/settings/tokens)
* Luo "Classic" token scopeilla: `repo`, `user`, `read:org`.

**2. Aseta Ympäristömuuttuja (Windows):**
Jotta token ei tallennu koodiin, aseta se Windowsin käyttäjäkohtaiseksi ympäristömuuttujaksi.
Suorita PowerShellissä (korvaa OMA_TOKEN_TÄHÄN):

```powershell
[System.Environment]::SetEnvironmentVariable("GITHUB_PERSONAL_ACCESS_TOKEN", "OMA_TOKEN_TÄHÄN", "User")
```

HUOM: Käynnistä tämän jälkeen host-sovellus (ja mahdollisesti VS Code/Terminal) kokonaan uudelleen, jotta uusi muuttuja latautuu.

**3. Ota uusi config käyttöön:**
Kopioi päivitetty `config/mcp_windows_fix.json` uudelleen settings-tiedostoosi. Se sisältää nyt myös `github`-lohkon.
