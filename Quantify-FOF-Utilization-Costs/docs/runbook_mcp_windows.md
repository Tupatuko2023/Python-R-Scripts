## Recovery executed (2026-01-30)

Korjauskonfiguraatio luotu: `config/mcp_windows_fix.json`.

**K�ytt��notto:**

1. Avaa MCP-hostin asetustiedosto (esim. `%USERPROFILE%\.gemini\settings.json` tai vastaava).
2. Kopioi `config/mcp_windows_fix.json` sis�lt� `mcpServers`-osioon.
3. K�ynnist� agentti uudelleen.

## GitHub MCP Setup (Lis�tty 2026-01-30)

GitHub-ty�kalut vaativat Personal Access Tokenin (PAT).

**1. Luo Token:**

- Mene: [https://github.com/settings/tokens](https://github.com/settings/tokens)
- Luo "Classic" token scopeilla: `repo`, `user`, `read:org`.

**2. Aseta Ymp�rist�muuttuja (Windows):**
Jotta token ei tallennu koodiin, aseta se Windowsin k�ytt�j�kohtaiseksi ymp�rist�muuttujaksi.
Suorita PowerShelliss� (korvaa OMA_TOKEN_T�H�N):

```powershell
[System.Environment]::SetEnvironmentVariable("GITHUB_PERSONAL_ACCESS_TOKEN", "OMA_TOKEN_T�H�N", "User")
```

HUOM: K�ynnist� t�m�n j�lkeen host-sovellus (ja mahdollisesti VS Code/Terminal) kokonaan uudelleen, jotta uusi muuttuja latautuu.

**3. Ota uusi config k�ytt��n:**
Kopioi p�ivitetty `config/mcp_windows_fix.json` uudelleen settings-tiedostoosi. Se sis�lt�� nyt my�s `github`-lohkon.
