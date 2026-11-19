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
latest_status: "2026-11-19: WP1:n tekninen toteutus ja 17/17 synteettistä testiä ovat valmiit. PRS:n dokumentaatio-PR #233 on review-vaiheessa; Sourceryn huomiot käsitellään. Ihmishyväksyntä, main-toimitus ja työpuun siivous puuttuvat."
next_step: "Tarkista PR #233:n päivitetyn revision CI ja katselmointihuomiot sekä pyydä sen jälkeen ihmisomistajan päätös tästä dokumentaatiotoimituksesta. Python-koodin julkaisuoikeuden vahvistus ja §3.1:n tieteellinen tarkistus etenevät erikseen."
source_description_sha256: "25ebce316d938aa2111dd9df66cddf649ee68d2249e1444599305f5b0da76507"
source_captured_at: "2026-11-19"
observed_at: "2026-11-19"
observed_commit: "b12155dd760e86bc0077d0ad966fc5ee08c0c135"
observed_worktree_label: "aim1-wp1-20261119"
blocker: "Nykyinen omistava METHODS_AND_SCORING.md §3.1 puuttuu tieteellisestä vahvistuksesta. Juuren LICENSE/README ja .github/CONTRIBUTING.md tukevat MIT:n soveltumista Python-koodiin, mutta saman repon npm-paketin package.json ilmoittaa ISC:n; oikeudenhaltijan vahvistus julkaisu- ja ilmoitusoikeudesta puuttuu. Nämä eivät estä teknistä katselmointia."
orchestrator: "Owner"
agent: "Termux Codex"
agent_tool: "Codex"
environment: "Android Termux"
started_date: "2026-11-19"
paused_date: ""
completed_date: ""
pause_reason: ""
link: ""
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

| repo                            | task                     | path                                        |
| ------------------------------- | ------------------------ | ------------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | `AIM1_REPO_WP1_20261119` | `tasks/03-review/AIM1_REPO_WP1_20261119.md` |

## Jatkamismuistio

WP1:n paikallinen runko, tavutarkka siirto ja alkuperäinen synteettinen testi
ovat valmistuneet paikalliseen kohderepon commit-revisioon `84291412792211fa30a98f5c15fbfa31ded9f6dc`;
testi läpäisi 17/17 tapausta eristetyssä ympäristössä.
Tiedostokohtaiset lähde- ja kohdehashit ovat tehtäväkortissa; kummankin tiedoston
kaksi kappaletta vastaavat tavutasolla. PRS:n dokumentaatio-PR #233 on avattu
ihmiskatselmointia varten. Tehtävä on edelleen `03-review`-jonossa. Seuraavaksi
tarkistetaan päivitetyn PR-revision CI- ja review-tulos ja pyydetään ihmisomistajan
päätös.
Nykyinen §3.1 tarvitaan pisteytyksen tieteelliseen vahvistukseen, mutta sen
puuttuminen ei pysäytä rungon, tavukopioiden tai synteettisen testin valmistelua.
Lähderepon `LICENSE`, README ja `.github/CONTRIBUTING.md` tukevat MIT:n
soveltumista Python-koodiin; saman repon npm-paketin `package.json` ilmoittaa
ISC:n. `package.json` ei nimeä siirrettyjä Python-tiedostoja eikä
DEAC-hakemistossa ole erillistä lisenssitiedostoa. Merkinnät näyttävät koskevan
eri sisältöjä, mutta oikeudenhaltijan vahvistus Python-tiedostojen
julkaisuoikeudesta ja tarvittavista ilmoituksista puuttuu.
Main-toimitusta ei ole tehty. WP1:n työpuuta eikä muita työpuita siivota.

## Vaiheiden erottelu 2026-11-19

- Tekninen toteutus ja synteettinen testaus: valmis katselmointiin.
- Ihmisen WP1-hyväksyntä: odottaa päätöstä.
- Main-toimitus: ei tehty.
- Tämän tehtävän worktree-siivous: ei tehty.

## Worktree-havainnot

| label             | state  | evidence                                                                                                 |
| ----------------- | ------ | -------------------------------------------------------------------------------------------------------- |
| aim1-wp1-20261119 | active | Erillinen paikallinen tehtävätyöpuu perustettu noudetusta origin/main-commitista b12155dd; ei poistettu. |

Inventaario kattaa vain tämän projektin tehtävätyöpuun; koko monorepon
työpuiden täydellistä inventaariota ei ole tehty.
