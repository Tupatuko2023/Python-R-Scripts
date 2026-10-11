# TASK-TRANSFER-PREFLIGHT-PREVIEW-SKILL — avustava CLI-skill-ehdokas (Preflight & Preview)

## Context

Windows–Termux-siirtotyönkulku (`Fear-of-Falling/docs/LOCAL_FILE_TRANSFER_RUNBOOK.md`) on
kaksisuuntainen ja staging-only. Siirron mekaaninen turvallisuus (hard-deny,
ylikirjoitussuoja, kohdetörmäyksen esto, fail-closed) on yksinomaan suoritettavissa
skripteissä (`export_artifacts_to_windows.sh`, `fof_v2_ssh_adapter.py`,
`fof_kb_pull.py`, `place_verified_bundle.py`) — **ei** agentin ohjeistuksessa.
Ohut, lukeva apuskilli voi vähentää manuaalista komentojen muotoilua ja tulosten
jäsennystä. Tämä tehtävä valmistelee **katselmoitavan ehdokkaan**; sitä ei asenneta
eikä aktivoida.

## Objective

Yksi ohut, lukeva avustava skill-ehdokas nykyisen Windows-agentin CLI-alustalle
(OpenCode), säilytettynä katselmointisijainnissa automaattisen löydettävyyden
ulkopuolella.

## Scope (katselmoitava ehdokas)

- `tasks/03-review/skill-candidates/fof-transfer-preflight-preview/SKILL.md` (uusi)
- tämä tehtäväkortti

## Sijainti ja löydettävyys (tarkennettu)

- Ehdokas siirrettiin **pois** `.opencode/skills/fof-transfer-preflight-preview/SKILL.md`-polusta
  (joka on OpenCoden automaattisesti skannaama) → `tasks/03-review/skill-candidates/…`.
- **Tilat erotetaan:** *löydettävissä* (tiedosto skannattavassa hakemistossa) ≠ *ladattu*
  (agentti kutsui `skill`-työkalua) ≠ *käytetty* (ohje muutti toimintaa). Aiempi väite
  "ei aktivoitu" oli epätarkka: sijainti `.opencode/skills/`-hakemistossa teki ehdokkaan
  **löydettäväksi** tässä checkoutissa.
- Uusi sijainti `tasks/03-review/skill-candidates/…` on OpenCoden/Codexin
  skill-löydettävyyspolkujen ulkopuolella (ks. lähteet) → ehdokas ei ole löydettävissä.
- Repon `SKILLS.md` nimeää aktiivisten skillien sijainnit `skills/` ja `.codex/skills/`;
  `skills/`-hakemistoa ei ole tässä repossa. Katselmointisijainti `tasks/03-review/…` on
  review-artefakti, ei aktiivinen skill-sijainti → ei ristiriitaa ohjeiden kanssa.

## Requirements

1. Lukee runbookin ja tunnistaa siirtosuunnan (A outbound; B pull).
2. Valmistelee preflight- (`--check`) ja preview-komennot (siirto- ja sijoitus-preview erikseen).
3. Selittää käyttäjän toimittamat tulosteet.
4. Erottaa siirron `VERIFIED`, paluukuitin (`NOT_DELIVERED`) ja `PLACED`-sijoituksen.
5. Kertoo puuttuvat tiedot ja ihmisen hyväksynnät — ei täytä niitä itse.
6. **Ei** suorita komentoja, hyväksy digestejä, aktivoi profiileja eikä siirrä tiedostoja
   (**käyttörajaus, ei tekninen esto**).
7. Kuvaa valmisteltavien komentojen vaikutukset (kirjoitukset + verkko) koodiviittein.
8. Viittaa runbookiin kopioimatta sitä.

## Komentojen vaikutukset (koodista tarkistettu)

- `fof_v2_ssh_adapter.py --check`: `ssh …` → **verkko**; ei payloadia.
- `export_artifacts_to_windows.sh` (preview): **ei SSH:tä** (vain `--execute`); rajattu
  `<run_id>.json`-diagnostiikka vain jos `FOF_V2_DIAG_ROOT` on valmisteltu.
- **`fof_kb_pull.py preview`: ei pelkästään lukeva — paikallisia kirjoituksia, ei verkkoa.**
  Luo uuden erän `new_directory(batch_root, batch_id)`, `snapshots/` (0700) ja
  `write_new(batch/'snapshots/NNNN', data)` per valittu tiedosto sekä `manifest.json` ja
  `runtime.json` (`fof_kb_pull.py`, `def preview`). `approve` kirjoittaa hyväksynnän erään.
  `serve`/`pull` käyttävät SSH:tä.
- `place_verified_bundle.py preview`: **ei kirjoita**; `execute` kirjoittaa kohteet + kuitin.

## Sources & versions (nykyinen dokumentaatio ≠ asennettu versio)

- **Nykyinen dokumentaatio (virallinen):**
  - OpenCode skills: https://opencode.ai/docs/skills/ (`.opencode/skills/<name>/SKILL.md`;
    frontmatter `name` + `description`; nimen on vastattava hakemistoa).
  - Codex skills: https://developers.openai.com/codex/skills , https://developers.openai.com/codex/build-skills.
- **Asennettujen CLI-versioiden varmennus (lokaali):** `codex-cli 0.160.0`, `opencode 1.18.35`.
- Python-R-Scripts lähdecommit: `23b41239027acd75f247d9ffce63998832127a10`.
- Suunnitteluaineisto: `FOF-Dissertation-Project/docs/guides/windows-termux/windows-termux-skill.md`.

## Synthetic comparison plan (ei suoritettu) — kolme haaraa

Kaikissa haaroissa samat synteettiset lähtötiedot; mittarit: **(1) valmisteluaika,
(2) käyttäjän työvaiheet, (3) komentovirheet.**

1. **Runbook yksin** — käyttäjä lukee runbookin ja muotoilee komennot itse.
2. **Olemassa olevat shell-apurit** — **ei käytettävissä:** `fof-check`/`fof-preview`/`fof-send`
   eivät ole olemassa repossa (`git grep` ei löydä; suunnitteluaineiston apurit ovat
   ehdotus, ei toteutus). Haara kirjataan "ei läsnä"; lähin olemassa oleva vertailukohta
   on raaka CLI-komentojono.
3. **Skill** — tämä ehdokas valmistelee komennot ja jäsentää tulosteet.

## Install / removal plan (ei suoritettu)

- **Ylläpitopaikka:** Python-R-Scripts (runbook + skriptit ovat siellä).
- **Asennus (myöhempi, erikseen valtuutettava):** kopioi ehdokas repossa sovittuun
  aktiiviseen skill-sijaintiin (`.opencode/skills/…` tai `.codex/skills/…`).
- **Poisto:** poista `tasks/03-review/skill-candidates/fof-transfer-preflight-preview/`
  ja palauta tämä kortti. Ei runtime-/profiilimuutoksia.

## Avoimet varmennuskohdat

- Ei vielä ajettu: vertailu ja mahdollinen aktivointi.
- Ehdokas jää `03-review`-tilaan.

## Proposals (ei toteutettu)

- Codex CLI -variantti erillisenä jatkona.
- Kuuden poikkeavan FIRA1-paikallistiedoston yhdistely erillisenä backlog-työnä
  (säilytetyt kopiot: `C:\FOF_KB_RUNTIME_20261006\evidence\pc-checkout-backup-20261010\_moved-aside\`).

## Log

- 2026-10-11: Valmisteltu ehdokas (base `23b41239027acd75f247d9ffce63998832127a10`); siirretty
  pois automaattisesta löydettävyydestä `tasks/03-review/skill-candidates/…`; korjattu
  aiempi virheellinen commit-viite; tarkennettu komentojen vaikutukset ja vertailusuunnitelma.
  Ei asennusta, ei aktivointia, ei siirtoscriptimuutoksia, ei oikeaa aineistoa.

## Blockers

- Ei. Tuotantoprofiilien aktivointi ja oikean aineiston siirto vaativat erillisen valtuutuksen.

## Tila

- REVIEW — katselmoitava ehdokas; ei asennettu, ei aktivoitu, ei löydettävissä.
