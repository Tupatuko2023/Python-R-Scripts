# PS7 Gemini CLI Orchestrator Bootstrap

Tämä ohje kuvaa, miten Fear-of-Falling -projektin Gemini CLI -agentti otetaan käyttöön ja miten sen ajot orkestroidaan Windows PowerShell 7 (`pwsh`) -ympäristössä.

## 1. Ympäristön valmistelu ja validointi

Avaa PowerShell 7 ja siirry projektin juureen. Varmista, että olet oikeassa hakemistossa ja että vaaditut työkalut löytyvät järjestelmästä.

```powershell
# 1. Siirry repojuureen
Set-Location .\Python-R-Scripts\Fear-of-Falling

# 2. Varmista, että Source-of-Truth -dokumentit ovat olemassa
Test-Path .\SYSTEM_PROMPT_POWERSHELL7_S-FOF.md
Test-Path .\CLAUDE.md
Test-Path .\AGENTS.md

# 3. Tarkista vaaditut työkalut (tulostaa polun, jos löytyy)
Get-Command gemini, git, Rscript, python -ErrorAction SilentlyContinue

```

## 2. Gemini CLI Policy Engine (Oikeudet)

Gemini CLI v1.0+ vaatii Policy Engine -asetukset työkalujen suorittamiseen. Luo vaadittu policy-tiedosto kerran (globaalisti):

```powershell
# 1. Luo policy-hakemisto
$policyDir = "$env:USERPROFILE\.gemini\policies"
New-Item -ItemType Directory -Force -Path $policyDir

# 2. Luo s-fof-policy.toml
$tomlContent = @"
[[rule]]
toolName = "read_file"
decision = "allow"
priority = 100

[[rule]]
toolName = "write_file"
decision = "allow"
priority = 100

[[rule]]
toolName = "replace"
decision = "allow"
priority = 100

[[rule]]
toolName = "glob"
decision = "allow"
priority = 100

[[rule]]
toolName = "run_shell_command"
decision = "allow"
priority = 100
"@
Set-Content -Path "$policyDir\s-fof-policy.toml" -Value $tomlContent -Encoding UTF8
```

## 3. Ajoskriptin käynnistäminen

Kaikki agentin suoritukset on ajettava orkestrointiskriptin kautta. Skripti takaa, että agentti saa aina uusimman järjestelmäkehotteen (System Prompt) ja että ajo lokitetaan turvallisesti.

Luo tehtävätiedosto (esim. `task_01.md`), joka sisältää varsinaisen toimeksiannon agentille.

Aja orkestroija:

```powershell
.\scripts\ps7un_gemini_orchestrator.ps1 -TaskFile ".	ask_01.md"

```

## 4. Yleiset vikatilanteet (Common failure signatures)

* **`Get-Command : The term 'gemini' is not recognized...`**
* **Syy:** Gemini CLI -työkalua ei ole asennettu tai se ei ole järjestelmän PATH-ympäristömuuttujassa.
* **Korjaus:** Asenna työkalu tai lisää sen asennuskansio PATH-muuttujaan.


* **`Virhe: Skripti on ajettava Fear-of-Falling -hakemistosta.`**
* **Syy:** Yrität ajaa skriptiä väärästä työhakemistosta.
* **Korjaus:** Aja `Set-Location .\Python-R-Scripts\Fear-of-Falling` ennen skriptin suoritusta.


* **`Virhe: System prompt -tiedostoa ei löytynyt.`**
* **Syy:** `SYSTEM_PROMPT_POWERSHELL7_S-FOF.md` puuttuu työhakemistosta.
* **Korjaus:** Varmista, että tiedosto on olemassa ja olet oikeassa haarassa (branch).
