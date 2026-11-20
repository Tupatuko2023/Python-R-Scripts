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
latest_status: "2026-11-20: WP1:n tekninen pilotti ja kaksi vanhaa työpuuta on suljettu valtuutetusti. PRS:n dokumentaatio-PR:t #233, #234 ja #235 on varmennettu mainista. Siivoustehtävän tekninen 04-done-siirto on valmisteltu erilliseen elinkaarikatselmointiin; siivouskirjauksen toimitustyöpuu ja haara säilyvät. AIM1-projekti jatkuu."
next_step: "Katselmoi siivoustehtävän erillinen elinkaarikirjaus. Sen main-toimituksen jälkeen tarkista ja tee vain erikseen valtuutettu siivouskirjauksen työpuun ja haaran loppusiivous. Selvitä Python-tiedostojen julkaisuoikeus ja nykyinen omistava §3.1 erillisinä jatkoasioina; AIM1-kohderepo pysyy paikallisena."
source_description_sha256: "25ebce316d938aa2111dd9df66cddf649ee68d2249e1444599305f5b0da76507"
source_captured_at: "2026-11-19"
observed_at: "2026-11-20"
observed_commit: "7c87864a0aacb65b6ba976295d604b5aa42035ed"
observed_worktree_label: "aim1-wp1-cleanup-closeout-20261120"
blocker: "Nykyinen omistava METHODS_AND_SCORING.md §3.1 puuttuu tieteellisestä vahvistuksesta. Juuren LICENSE/README ja .github/CONTRIBUTING.md tukevat MIT:n soveltumista Python-koodiin, mutta saman repon npm-paketin package.json ilmoittaa ISC:n; oikeudenhaltijan vahvistus julkaisu- ja ilmoitusoikeudesta puuttuu. Nämä eivät estä teknistä katselmointia."
orchestrator: "Owner"
agent: "Termux Codex"
agent_tool: "Codex"
environment: "Android Termux"
started_date: "2026-11-19"
paused_date: ""
completed_date: ""
pause_reason: ""
link: "https://github.com/Tupatuko2023/Python-R-Scripts/pull/235"
worktree_inventory: "complete"
tasks:
  - "AIM1_REPO_WP1_20261119"
  - "AIM1_WP1_CLEANUP_20261120"
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

| repo                            | task                        | path                                         |
| ------------------------------- | --------------------------- | -------------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | `AIM1_REPO_WP1_20261119`    | `tasks/04-done/AIM1_REPO_WP1_20261119.md`    |
| `Tupatuko2023/Python-R-Scripts` | `AIM1_WP1_CLEANUP_20261120` | `tasks/04-done/AIM1_WP1_CLEANUP_20261120.md` |

## Jatkamismuistio

WP1:n paikallinen runko, tavutarkka siirto ja alkuperäinen synteettinen testi
ovat valmistuneet paikalliseen kohderepon commit-revisioon `84291412792211fa30a98f5c15fbfa31ded9f6dc`;
testi läpäisi 17/17 tapausta eristetyssä ympäristössä.
Tiedostokohtaiset lähde- ja kohdehashit ovat tehtäväkortissa; kummankin tiedoston
kaksi kappaletta vastaavat tavutasolla. Ihmisomistaja hyväksyi PRS:n
dokumentaatio-PR #233:n revision `f16380a66b511bf83116a9817abda4d46e08a65a`
[pysyvässä kommentissa](https://github.com/Tupatuko2023/Python-R-Scripts/pull/233#issuecomment-7020512654).
PR yhdistettiin mainiin commitilla `1c90b7ed8ab1cc4a977acee2ebcf9e1ec83b615c`.
WP1:n tekninen `04-done`-kirjaus toimitettiin mainiin
[lifecycle-PR #234:ssä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/234).
Nykyinen §3.1 tarvitaan pisteytyksen tieteelliseen vahvistukseen, mutta sen
puuttuminen ei pysäytä rungon, tavukopioiden tai synteettisen testin valmistelua.
Lähderepon `LICENSE`, README ja `.github/CONTRIBUTING.md` tukevat MIT:n
soveltumista Python-koodiin; saman repon npm-paketin `package.json` ilmoittaa
ISC:n. `package.json` ei nimeä siirrettyjä Python-tiedostoja eikä
DEAC-hakemistossa ole erillistä lisenssitiedostoa. Merkinnät näyttävät koskevan
eri sisältöjä, mutta oikeudenhaltijan vahvistus Python-tiedostojen
julkaisuoikeudesta ja tarvittavista ilmoituksista puuttuu.
PRS:n WP1-dokumentaatio-PR #233 ja sulkukirjaus-PR #234 ovat `MERGED`-tilassa.
Niiden main-commitit `1c90b7ed8ab1cc4a977acee2ebcf9e1ec83b615c` ja
`02fbcd96303d2c9e9b4e5441176af00d20e5a5f9` on varmennettu `origin/main`-haarasta.
Käyttäjän erikseen nimeämät kaksi WP1-työpuuta ja niiden haarat siivottiin
20.11.2026. AIM1-kohderepo ja muiden töiden työpuut säilyvät.
Tämä siivouskirjaus toimitettiin mainiin
[PR #235:ssä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/235)
commitilla `7c87864a0aacb65b6ba976295d604b5aa42035ed`.
Siivoustehtävän tekninen `04-done`-siirto valmistellaan erilliseen PR:ään;
sen hyväksyntä ja main-toimitus ovat vielä avoimia.

## Vaiheiden erottelu 2026-11-20

- Tekninen toteutus ja synteettinen testaus: valmis, 17/17 PASS.
- Ihmisen WP1-hyväksyntä: annettu täsmärevisiolle; viite yllä.
- PRS:n WP1-dokumentaation main-toimitus: tehty ja varmennettu.
- WP1:n tekninen `04-done`-kirjaus: tehty ja toimitettu mainiin PR #234:ssä.
- Nimettyjen WP1-työpuiden siivous: tehty 20.11.2026.
- Siivouksen dokumentaation main-toimitus: tehty ja varmennettu PR #235:stä.
- Siivoustehtävän tekninen `04-done`-kirjaus: valmisteltu erilliseen katselmointiin; main-toimitus avoin.
- Siivouskirjauksen oman työpuun ja haaran loppusiivous: tekemättä.

## Worktree-havainnot

| label                              | state    | evidence                                                                                                  |
| ---------------------------------- | -------- | --------------------------------------------------------------------------------------------------------- |
| aim1-wp1-20261119                  | removed  | PR #233 varmennettu mainista; työpuu ja paikallis- sekä origin-haara poistettu 20.11.2026.                |
| aim1-wp1-lifecycle-20261119        | removed  | PR #234 varmennettu mainista; työpuu ja paikallis- sekä origin-haara poistettu 20.11.2026.                |
| aim1-wp1-cleanup-20261120          | retained | Siivouskirjauksen PR #235 on mainissa; tämä työpuu ja haara odottavat valtuutetun loppusiivouksen ehtoja. |
| aim1-wp1-cleanup-closeout-20261120 | active   | Teknisen `04-done`-sulkukirjauksen erillinen työpuu; oma katselmointi ja toimitus avoimia.                |

Inventaario kattaa tämän projektin tehtävätyöpuut. Gitin koko työpuulista
tarkistettiin, mutta muiden projektien työpuita ei siivottu.
