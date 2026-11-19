---
id: "PRJ-AIM1-REPO"
title: "AIM1:n erillinen analyysirepo"
short_name: "AIM1-analyysirepo"
repo: "Tupatuko2023/Python-R-Scripts"
repo_ref: "origin/main"
state: "active"
delivery: "not_delivered"
goal: "Rakentaa erillinen, katselmoitava ja myöhemmin julkistamiseen soveltuva AIM1-analyysirepo lähdekriittisesti dokumentoiduista työpaketeista."
done_criterion: "AIM1:n sovittu analyysikoodi, lähde- ja tutkimuspäätösrajaukset, synteettiset testit ja julkaisuvalmiuden erillinen arvio on hyväksytty; projekti suljetaan vain ihmisomistajan päätöksellä."
latest_status: "2026-11-19: WP1:n tekninen pilotti on hyväksytty ja 17/17 synteettistä testiä läpäisi. PRS:n dokumentaatio-PR #233 toimitettiin mainiin commitilla 1c90b7ed8ab1cc4a977acee2ebcf9e1ec83b615c. WP1:n tekninen 04-done-kirjaus on lifecycle-PR #234:ssä; sen main-toimituksen tila tarkistetaan PR:stä. Työpuun siivousta ei ole tehty. AIM1-projekti jatkuu."
next_step: "Selvitä Python-tiedostojen julkaisuoikeus ja nykyinen omistava §3.1 erillisinä jatkoasioina. Arvioi AIM1-projektin seuraavat työpaketit erikseen. Älä julkaise AIM1-kohderepoa tai poista työpuita ilman erillistä päätöstä."
source_description_sha256: "25ebce316d938aa2111dd9df66cddf649ee68d2249e1444599305f5b0da76507"
source_captured_at: "2026-11-19"
observed_at: "2026-11-19"
observed_commit: "1c90b7ed8ab1cc4a977acee2ebcf9e1ec83b615c"
observed_worktree_label: "aim1-wp1-lifecycle-20261119"
blocker: "Nykyinen omistava METHODS_AND_SCORING.md §3.1 puuttuu tieteellisestä vahvistuksesta. Juuren LICENSE/README ja .github/CONTRIBUTING.md tukevat MIT:n soveltumista Python-koodiin, mutta saman repon npm-paketin package.json ilmoittaa ISC:n; oikeudenhaltijan vahvistus julkaisu- ja ilmoitusoikeudesta puuttuu. Nämä eivät estä teknistä katselmointia."
orchestrator: "Owner"
agent: "Termux Codex"
agent_tool: "Codex"
environment: "Android Termux"
started_date: "2026-11-19"
paused_date: ""
completed_date: ""
pause_reason: ""
link: "https://github.com/Tupatuko2023/Python-R-Scripts/pull/233"
worktree_inventory: "unknown"
tasks:
  - "AIM1_REPO_WP1_20261119"
---

## AIM1:n erillinen analyysirepo

## Lähdekuvaus

<!-- prettier-ignore-start -->
<!-- source-description:begin -->
Rakennetaan erillinen AIM1-analyysirepo nimellä frailty-healthcare-use-costs.
Työ etenee rajattuina tehtävinä: ensin paikallinen reporunko ja
DEAC-indeksin puhtaan kokoajamoduulin synteettinen pilotti, myöhemmin
erikseen arvioidut palvelukäytön, mallinnuksen ja kustannusten osat.
Tutkimuspäätökset, käsikirjoituskuvaukset, toteutuskoodi, testinäyttö ja
julkaisuoikeus pidetään erillisinä. Projektin valmistuminen ei seuraa
yksittäisen työpaketin valmistumisesta.
<!-- source-description:end -->
<!-- prettier-ignore-end -->

## Tehtäväviitteet

| repo                            | task                     | path                                      |
| ------------------------------- | ------------------------ | ----------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | `AIM1_REPO_WP1_20261119` | `tasks/04-done/AIM1_REPO_WP1_20261119.md` |

## Jatkamismuistio

WP1:n paikallinen runko, tavutarkka siirto ja alkuperäinen synteettinen testi
ovat valmistuneet paikalliseen kohderepon commit-revisioon `84291412792211fa30a98f5c15fbfa31ded9f6dc`;
testi läpäisi 17/17 tapausta eristetyssä ympäristössä.
Tiedostokohtaiset lähde- ja kohdehashit ovat tehtäväkortissa; kummankin tiedoston
kaksi kappaletta vastaavat tavutasolla. Ihmisomistaja hyväksyi PRS:n
dokumentaatio-PR #233:n revision `f16380a66b511bf83116a9817abda4d46e08a65a`
[pysyvässä kommentissa](https://github.com/Tupatuko2023/Python-R-Scripts/pull/233#issuecomment-7020512654).
PR yhdistettiin mainiin commitilla `1c90b7ed8ab1cc4a977acee2ebcf9e1ec83b615c`.
WP1:n tekninen `04-done`-kirjaus on [lifecycle-PR #234:ssä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/234);
sen main-toimitus todennetaan erikseen PR:n tilasta.
Nykyinen §3.1 tarvitaan pisteytyksen tieteelliseen vahvistukseen, mutta sen
puuttuminen ei pysäytä rungon, tavukopioiden tai synteettisen testin valmistelua.
Lähderepon `LICENSE`, README ja `.github/CONTRIBUTING.md` tukevat MIT:n
soveltumista Python-koodiin; saman repon npm-paketin `package.json` ilmoittaa
ISC:n. `package.json` ei nimeä siirrettyjä Python-tiedostoja eikä
DEAC-hakemistossa ole erillistä lisenssitiedostoa. Merkinnät näyttävät koskevan
eri sisältöjä, mutta oikeudenhaltijan vahvistus Python-tiedostojen
julkaisuoikeudesta ja tarvittavista ilmoituksista puuttuu.
PRS:n WP1-dokumentaatiotoimitus on varmennettu `origin/main`-haarasta.
WP1:n työpuuta eikä muita työpuita siivota.

## Vaiheiden erottelu 2026-11-19

- Tekninen toteutus ja synteettinen testaus: valmis, 17/17 PASS.
- Ihmisen WP1-hyväksyntä: annettu täsmärevisiolle; viite yllä.
- PRS:n WP1-dokumentaation main-toimitus: tehty ja varmennettu.
- WP1:n tekninen `04-done`-kirjaus: tehty lifecycle-PR #234:ssä; sen main-toimitus tarkistetaan PR:stä.
- Tämän tehtävän worktree-siivous: ei tehty.

## Worktree-havainnot

| label                       | state    | evidence                                                                                                 |
| --------------------------- | -------- | -------------------------------------------------------------------------------------------------------- |
| aim1-wp1-20261119           | retained | Erillinen paikallinen tehtävätyöpuu perustettu noudetusta origin/main-commitista b12155dd; ei poistettu. |
| aim1-wp1-lifecycle-20261119 | active   | Erillinen sulkukirjauksen työpuu perustettu varmennetusta origin/main-commitista 1c90b7ed; ei poistettu. |

Inventaario kattaa vain tämän projektin tehtävätyöpuut; koko monorepon
työpuiden täydellistä inventaariota ei ole tehty.
