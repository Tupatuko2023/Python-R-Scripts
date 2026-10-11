# TASK-TRANSFER-PREFLIGHT-PREVIEW-SKILL — avustava CLI-skill-ehdokas (Preflight & Preview)

## Context

Windows–Termux-siirtotyönkulku (`Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md`) on
kaksisuuntainen ja staging-only. Siirron mekaaninen turvallisuus (hard-deny,
ylikirjoitussuoja, kohdetörmäyksen esto, fail-closed) on yksinomaan suoritettavissa
skripteissä (`export_artifacts_to_windows.sh`, `fof_v2_ssh_adapter.py`,
`fof_kb_pull.py`, `place_verified_bundle.py`) — **ei** agentin ohjeistuksessa.
Ohut, pelkästään lukeva apuskilli voi vähentää manuaalista komentojen muotoilua ja
tulosten jäsennystä. Tämä tehtävä valmistelee **katselmoitavan ehdokkaan**; sitä ei
asenneta eikä aktivoida.

## Objective

Yksi ohut, lukeva avustava skill-ehdokas nykyisen Windows-agentin CLI-alustalle
(OpenCode), ylläpidettynä Python-R-Scripts-repossa runbookin ja skriptien vieressä.

## Scope (katselmoitava ehdokas)

- `.opencode/skills/fof-transfer-preflight-preview/SKILL.md` (uusi)
- tämä tehtäväkortti

## Requirements

1. Lukee runbookin ja tunnistaa siirtosuunnan (A: Termux→Windows outbound;
   B: Windows→Termux pull).
2. Valmistelee preflight- (`--check`) ja preview-komennot (siirto-preview ja
   sijoitus-preview erikseen).
3. Selittää käyttäjän toimittamat tulosteet (`SUCCESS/0`, `FAILED/1`,
   `UNKNOWN_REMOTE_STATE/3`, `EMPTY_NOT_EXECUTABLE`, `PLACE_REJECTED: <CODE>`,
   tiedostokohtaiset tilat).
4. Erottaa kolme eri asiaa: siirron `VERIFIED`, paluukuitti (`NOT_DELIVERED`) ja
   `PLACED`-sijoitus (erillinen `PLACE/1`).
5. Kertoo puuttuvat tiedot ja ihmisen hyväksynnät (`content_digest`,
   `placement_digest`) — ei täytä niitä itse.
6. **Ei** suorita shell-komentoja, hyväksy digestejä, aktivoi profiileja eikä siirrä
   tiedostoja. Tämä on **käyttörajaus, ei tekninen esto** (mekaaninen turva on
   skripteissä).
7. Kuvaa valmisteltavien komentojen vaikutukset (kirjoitukset ja verkkoyhteydet).
8. Viittaa runbookiin kopioimatta sitä skillin sisään.

## Sources & versions

- Python-R-Scripts varmennettu lähtöcommit: `ae84e8eb6f7c6659602b415283e99a14a0f77ba1`.
- `Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md`.
- Nykyiset siirtoskriptit (`Fear-of-Falling/scripts/termux/…`).
- Suunnitteluaineisto: `FOF-Dissertation-Project/docs/guides/windows-termux/windows-termux-skill.md`.
- Asennetut CLI-versiot: **codex-cli 0.160.0**, **opencode 1.18.35**.
- Skill-rakenne: OpenCode `.opencode/skills/<n>/SKILL.md` (YAML `name`+`description`);
  Codex `.codex/skills/<n>/SKILL.md`.

## Install / removal plan (ei suoritettu)

- **Ylläpitopaikka:** Python-R-Scripts, koska runbook + skriptit (skillin kohde) ovat siellä.
- **Asennus:** tiedosto on jo repossa polussa `.opencode/skills/fof-transfer-preflight-preview/SKILL.md`;
  OpenCode lataa sen repositorion skill-hakemistosta ilman erillistä asennusta.
- **Poisto:** poista hakemisto `.opencode/skills/fof-transfer-preflight-preview/` ja palauta
  tämä kortti. Ei runtime-/profiilimuutoksia.

## Synthetic comparison plan (ei suoritettu)

- **Vertailu:** runbook yksin vs tämä skill, samalla synteettisellä siirtotehtävällä
  (ei oikeaa aineistoa).
- **Mittarit:** (1) valmisteluaika, (2) käyttäjän vaiheiden lukumäärä,
  (3) komentovirheiden lukumäärä.
- Tulos kirjataan erikseen; vertailua **ei** suoriteta tässä.

## Validation (avoin)

- Ei vielä ajettu. Ehdokas jää `03-review`-tilaan.

## Proposals (ei toteutettu)

- Codex CLI -variantti erillisenä jatkona.
- Kuuden poikkeavan FIRA1-paikallistiedoston yhdistely erillisenä backlog-työnä
  (säilytetyt kopiot: `C:\FOF_KB_RUNTIME_20261006\evidence\pc-checkout-backup-20261010\_moved-aside\`).

## Log

- 2026-10-11: Valmisteltu katselmoitava ehdokas eristetyssä haarassa (base `ae84e8eb…`).
  Ei asennusta, ei aktivointia, ei siirtoscriptimuutoksia, ei oikeaa aineistoa.

## Blockers

- Ei. Tuotantoprofiilien aktivointi ja oikean aineiston siirto vaativat erillisen
  valtuutuksen (PENDING-validoinnit + ihmisen sisältöhyväksyntä).

## Tila

- REVIEW — katselmoitava ehdokas; ei asennettu eikä aktivoitu.
