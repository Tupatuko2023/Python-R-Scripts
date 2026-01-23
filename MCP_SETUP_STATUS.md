# GitHub MCP & Codex (Termux) – Väliraportti

Päiväys: 2026-01-23

## Tausta ja tavoite
Tavoitteena oli saada Codex CLI toimimaan Termuxissa GitHub MCP:n kanssa turvallisesti ja headless-yhteensopivasti. Ratkaisuissa vältetään pysyvät token‑exportit ja tokenien tulostus, ja tarjotaan sekä MCP ON (token vaaditaan) että MCP OFF (ei tokenia) -polut.

## Mitä tehtiin (tiivistetty)
- Varmistettiin, että Codex MCP‑konfiguraatio käyttää `bearer_token_env_var = "GH_TOKEN"`.
- Toteutettiin wrapperit:
  - `codex-gh` (MCP ON, token/secrets/gh fallback, timeout).
  - `codex-nogh` (MCP OFF, väliaikainen config‑toggle + restore).
  - `codex` (entrypoint; ohjaa MCP ON/OFF automaattisesti).
- Debugattiin GH_TOKEN-not-set ja TTY‑ongelmat erilleen.
- Todettiin, että XDG_CONFIG_HOME ei ohjaa Codexin config‑hakua tässä buildissa.
- Päivitettiin FOF‑projektin SKILLS.md:ään lyhyt wrapper‑maininta.

## Mikä onnistui
- MCP OFF toimii ilman tokenia: `codex-nogh mcp list` näyttää “No MCP servers configured yet”.
- MCP ON toimii, kun token‑lähde on käytössä (secrets‑tiedosto tai gh fallback).
- `codex-nogh` palauttaa `~/.codex/config.toml`:n varmasti (trap + backup, lock estää rinnakkaisuudet).
- TTY‑vaatimus on selvä: TUI ei käynnisty non‑TTY‑ympäristössä.

## Mikä ei toiminut / rajoitteet
- XDG_CONFIG_HOME‑ylikirjoitus ei vaikuta Codexin configin hakuun tässä buildissa.
- Codexin TUI ei käynnisty non‑TTY‑sessiossa (“stdin is not a terminal”). Tämä ei liity MCP‑tokeniin.
- MCP ON vaatii token‑lähteen; gh auth -login ei yksin riitä MCP:lle ilman GH_TOKENia.

## Nykyinen toimiva tila (Known Good States)
- **Default (sujuva)**: `codex` → MCP OFF jos tokenia ei ole saatavilla.
- **MCP ON (token)**: `CODEX_FORCE_MCP_ON=1 codex`.
- **MCP ON (gh fallback)**: `CODEX_FORCE_MCP_ON=1 CODEX_GH_FALLBACK=1 CODEX_GH_TIMEOUT=5 codex`.
- **MCP OFF**: `codex-nogh` tai `CODEX_FORCE_MCP_OFF=1 codex`.
- **Non‑TTY**: käytä `codex mcp list` tai `codex exec "<prompt>"`.

## Seuraavat askeleet (jos aloitetaan myöhemmin alusta)
1. Päätä, halutaanko MCP ON oletuksena vai vain opt‑in.
2. Seuraa Codex CLI:n mahdollista tukea MCP‑palvelimen disable‑avaimelle.
3. Varmista TTY‑ympäristö, jos TUI:a tarvitaan.
4. Jos haluat tokenittoman MCP ON -polun, luo `~/.secrets/github_fine_grained_pat` itse (chmod 600).

## Tiedostot ja polut (täydellinen lista)
### Wrapperit
- `/data/data/com.termux/files/home/bin/codex`
  - Entry point; ohjaa MCP ON/OFF automaattisesti.
- `/data/data/com.termux/files/home/bin/codex-gh`
  - MCP ON -polku; secrets‑tiedosto ensisijainen, opt‑in gh fallback timeoutilla.
- `/data/data/com.termux/files/home/bin/codex-nogh`
  - MCP OFF -polku; poistaa väliaikaisesti `[mcp_servers.github]` ja palauttaa configin.

### Konfiguraatio
- `/data/data/com.termux/files/home/.codex/config.toml`
  - Sisältää `[mcp_servers.github]` ja GH_TOKEN‑ympäristömuuttujan.

### Dokumentaatio
- `/data/data/com.termux/files/home/src/FOF-Dissertation-Project/SKILLS.md`
  - Authoritative MCP Test Protocol; sisältää wrapper‑maininnan.
- `docs/guides/github-mcp-termux.md` (PUUTTUU tässä repossa)

## Huomiot
- “No MCP servers configured yet” on **odotettu** MCP OFF -tilassa.
- “stdin is not a terminal” on **TTY‑ehto**, ei MCP‑token‑ongelma.

## FINAL STATE (2026-01-23)

**Status:** DONE (headless MCP validated)

### Summary
- GitHub MCP toimii headless-automaatiossa ilman TTY:tä.
- Wrapperit / aliakset **eivät ole tarpeen**.
- Suositeltu ja ainoa tarvittava malli on **per-komento GH_TOKEN-injektio**.
- TTY/TUI on **valinnainen** ja erillinen automaatiokäytöstä.

### Canonical usage (no token output, no persistent export)

```bash
GH_TOKEN="$(gh auth token -h github.com 2>/dev/null)" codex mcp list

Optional tools listing:

GH_TOKEN="$(gh auth token -h github.com 2>/dev/null)" codex mcp tools github 2>/dev/null || \
GH_TOKEN="$(gh auth token -h github.com 2>/dev/null)" codex mcp tools 2>/dev/null || true

Headless exec from a trusted git repo (optional; external timeout):

cd <trusted-git-repo>
git rev-parse --is-inside-work-tree

command -v timeout >/dev/null 2>&1 || pkg install -y coreutils
GH_TOKEN="$(gh auth token -h github.com 2>/dev/null)" timeout 60s codex exec "<prompt>"
```

### Repo scope

MCP configuration is user-scoped, not repo-scoped.

Config location: ~/.codex/config.toml

MCP works in all trusted git repositories, including:

Python-R-Scripts

FOF-Dissertation-Project


The only repo-specific requirement is Codex’s trusted git repo check.


### Notes

“github ready” in logs confirms MCP server initialization.

A codex exec response may still report “none detected” if the prompt did not invoke MCP tools; this does not indicate MCP failure.
