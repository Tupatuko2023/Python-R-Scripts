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

## Sijainti ja löydettävyys (OpenCode)

- Ehdokas on siirretty pois `.opencode/skills/…`-polusta (OpenCoden skannaama) →
  `tasks/03-review/skill-candidates/…`, joka on OpenCoden skill-löydettävyyspolun
  ulkopuolella.
- **Tilat:** _löydettävissä_ (`.opencode/skills/<name>/SKILL.md`) ≠ _ladattu_ (agentti
  kutsui OpenCoden `skill`-työkalua) ≠ _käytetty_. Löydettävyys ei yksin tarkoita
  latausta. Tämä ehdokas ei ole löydettävissä; sijainti (ei pelkkä käyttökielto) pitää
  sen inaktiivisena.
- Codex-kohtainen variantti on mahdollinen **erillinen jatkotyö**, ei osa tätä
  ensimmäistä ehdokasta.

## Requirements

1. Lukee runbookin ja tunnistaa siirtosuunnan (A outbound; B pull).
2. Valmistelee komennot runbookin mukaisina kokonaisuuksina tarvittavine
   ympäristövalintoineen (ei pelkkää adapterin `--check`-komentoa käynnistyskomentona).
3. Selittää käyttäjän toimittamat tulosteet **suunnittain**.
4. Päättelee `VERIFIED`, paluukuitin tilan ja `PLACED`-sijoituksen **vain** käyttäjän
   toimittamasta, kyseiseen ajoon korreloidusta evidenssistä. Puuttuva näyttö =
   **UNVERIFIED**. Ei kovakoodattua `NOT_DELIVERED`-tilaa.
5. Kertoo puuttuvat tiedot **työvaiheittain** (komentojen valmistelu / preview-tulosteen
   tulkinta / myöhempi hyväksyntävaihe) — ei vaadi `run_id`:tä ennen sen syntymistä eikä
   digest-hyväksyntää komentojen valmisteluun.
6. **Ei** suorita komentoja, hyväksy digestejä, aktivoi profiileja eikä siirrä tiedostoja
   (**käyttörajaus, ei tekninen esto**).
7. Kuvaa komentojen vaikutukset (kirjoitukset + verkko) koodiviittein.
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

- **Nykyinen dokumentaatio (virallinen, OpenCode):** <https://opencode.ai/docs/skills/> —
  löydettävyys `.opencode/skills/<name>/SKILL.md`; frontmatter `name` + `description`;
  nimen on vastattava hakemistoa.
- **Asennettujen CLI-versioiden varmennus (lokaali):** `opencode 1.18.35` (ja
  `codex-cli 0.160.0` läsnä). Nämä varmistavat asennetut työkalut, eivät sitä että
  ehdokas on ladattu tai käytetty.
- Python-R-Scripts lähdecommit: `23b41239027acd75f247d9ffce63998832127a10`.
- Suunnitteluaineisto: `FOF-Dissertation-Project/docs/guides/windows-termux/windows-termux-skill.md`.

## Synthetic comparison plan (ei suoritettu) — kolme haaraa

Kaikissa haaroissa samat synteettiset lähtötiedot; mittarit: **(1) valmisteluaika,
(2) käyttäjän työvaiheet, (3) komentovirheet.**

1. **Runbook yksin** — käyttäjä lukee runbookin ja muotoilee komennot itse (myös raa'at
   CLI-komennot kuuluvat tähän haaraan).
2. **Olemassa olevat shell-apurit** — **NOT_AVAILABLE:** `fof-check`/`fof-preview`/`fof-send`
   eivät ole olemassa repossa; suunnitteluaineiston apurit ovat ehdotus, ei toteutus.
3. **Skill** — tämä ehdokas valmistelee komennot ja jäsentää tulosteet.

## Install / removal plan (ei suoritettu)

- **Ylläpitopaikka:** Python-R-Scripts (runbook + skriptit ovat siellä).
- **Asennus (myöhempi, erikseen valtuutettava):** kopioi ehdokas aktiiviseen
  OpenCode-skill-sijaintiin (`.opencode/skills/…`).
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
  pois automaattisesta löydettävyydestä; korjattu commit-viite, suuntaerottelu
  tulostetulkinnassa (ei kovakoodattua `NOT_DELIVERED`), OpenCode-rajaus, vaiheittainen
  puuttuvien tietojen lista ja runbook-tason komentokokonaisuudet. Ei asennusta, ei
  aktivointia, ei siirtoscriptimuutoksia, ei oikeaa aineistoa.

## Blockers

- Ei. Tuotantoprofiilien aktivointi ja oikean aineiston siirto vaativat erillisen valtuutuksen.

## Tila

- REVIEW — katselmoitava ehdokas; ei asennettu, ei aktivoitu, ei löydettävissä.
