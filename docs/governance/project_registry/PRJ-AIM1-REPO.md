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
latest_status: "2026-11-21: WALK500:n sulkukirjaus toimitettiin PR #240:ssä mainiin ja nimetyt työpuut sekä haarat siivottiin. Kahdeksan kyselykomponentin rajattu lähdesidonta ja synteettiset testit valmistuivat; tehtävä on 03-review-tilassa. Julkisen sovittimen ja pisteyttäjien regressiotestit 349/349 PASS sekä erillinen yksityinen metadataan sidottu tarkistus 117/117 PASS. AIM1-projekti jatkuu aktiivisena."
next_step: "Tarkista kahdeksan komponentin rajattu PR ja sen CI- sekä katselmointitulokset; ihmisomistajan hyväksyntä ja main-toimitus ovat erillisiä seuraavia vaiheita. Nykyisen §3.1:n auktoriteetti ja AIM1-kohderepon julkaisupäätös pysyvät avoimina."
source_description_sha256: "25ebce316d938aa2111dd9df66cddf649ee68d2249e1444599305f5b0da76507"
source_captured_at: "2026-11-19"
observed_at: "2026-11-21"
observed_commit: "3a29c4c4359edf0252efbe3a14afc3eb2cccf644"
observed_worktree_label: "aim1-deac-eight-bindings-20261121"
blocker: "AIM1-kohderepon erillinen julkaisupäätös puuttuu, vaikka kahden yksilöidyn Python-tiedostoversion MIT-sisällytysoikeus on vahvistettu. Historiallinen 0.4.1-draft ja D-005…D-009-merkinnät ovat saatavilla, mutta alkuperäiset hyväksyntäpaketit, myöhempi 0.5.2-draft, D-011 sekä nykyinen päätös- ja korvaavuusketju puuttuvat tieteellisestä vastaavuustarkistuksesta. Nämä eivät estä rajattua paikallista selvitystä."
orchestrator: "Owner"
agent: "Termux Codex"
agent_tool: "Codex"
environment: "Android Termux"
started_date: "2026-11-19"
paused_date: ""
completed_date: ""
pause_reason: ""
link: "https://github.com/Tupatuko2023/Python-R-Scripts/pull/239"
worktree_inventory: "unknown"
tasks:
  - "AIM1_REPO_WP1_20261119"
  - "AIM1_WP1_CLEANUP_20261120"
  - "AIM1_AUTHORITY_SOURCE_REVIEW_20261120"
  - "TASK-DEAC20-K40-WALK500-FIRST-BINDING"
  - "TASK-DEAC20-K40-EIGHT-VERIFIED-BINDINGS-20261121"
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

| repo                            | task                                               | path                                                                  |
| ------------------------------- | -------------------------------------------------- | --------------------------------------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | `AIM1_REPO_WP1_20261119`                           | `tasks/04-done/AIM1_REPO_WP1_20261119.md`                             |
| `Tupatuko2023/Python-R-Scripts` | `AIM1_WP1_CLEANUP_20261120`                        | `tasks/04-done/AIM1_WP1_CLEANUP_20261120.md`                          |
| `Tupatuko2023/Python-R-Scripts` | `AIM1_AUTHORITY_SOURCE_REVIEW_20261120`            | `tasks/04-done/AIM1_AUTHORITY_SOURCE_REVIEW_20261120.md`              |
| `Tupatuko2023/Python-R-Scripts` | `TASK-DEAC20-K40-WALK500-FIRST-BINDING`            | `tasks/04-done/TASK-DEAC20-K40-WALK500-FIRST-BINDING.md`              |
| `Tupatuko2023/Python-R-Scripts` | `TASK-DEAC20-K40-EIGHT-VERIFIED-BINDINGS-20261121` | `tasks/03-review/TASK-DEAC20-K40-EIGHT-VERIFIED-BINDINGS-20261121.md` |

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
DEAC-hakemistossa ole erillistä lisenssitiedostoa. WP1:n katselmoinnin aikaan
oikeudenhaltijan vahvistus puuttui. Ihmisomistaja vahvisti 20.11.2026
oikeudenhaltijana täsmäversioiden `deac_index.py` (SHA-256
`c3fe94b631d488a5c5923ce4f31edca866b435464b8e6ce986b5e07c568593d7`)
ja `test_deac_index.py` (SHA-256
`396b798f73aced664deb0479a495bc2d9e8febb825bfc9dc5177b71e9ead1713`)
sisällyttämisen AIM1-kohderepoon MIT-lisenssillä. Lähteen MIT-teksti ja nykyiset
merkinnät säilytetään. Vahvistus ei valtuuta kohderepon julkaisemista.
PRS:n WP1-dokumentaatio-PR #233 ja sulkukirjaus-PR #234 ovat `MERGED`-tilassa.
Niiden main-commitit `1c90b7ed8ab1cc4a977acee2ebcf9e1ec83b615c` ja
`02fbcd96303d2c9e9b4e5441176af00d20e5a5f9` on varmennettu `origin/main`-haarasta.
Käyttäjän erikseen nimeämät kaksi WP1-työpuuta ja niiden haarat siivottiin
20.11.2026. AIM1-kohderepo ja muiden töiden työpuut säilyvät.
Tämä siivouskirjaus toimitettiin mainiin
[PR #235:ssä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/235)
commitilla `7c87864a0aacb65b6ba976295d604b5aa42035ed`.
Siivoustehtävän tekninen `04-done`-siirto toimitettiin mainiin
[PR #236:ssa](https://github.com/Tupatuko2023/Python-R-Scripts/pull/236)
commitilla `30d01bb762f5f391f4fe77311594c1a9705f6fb7`.
Toteutunut loppusiivous on kirjattu [PR:n pysyvään kommenttiin](https://github.com/Tupatuko2023/Python-R-Scripts/pull/236#issuecomment-7029737997).
Uusi lähde- ja julkaisuoikeusselvitys on erillinen työpaketti; sen rajatut
havainnot ovat `reports/AIM1_AUTHORITY_SOURCE_REVIEW_20261120.md`:ssä.
Ihmisomistaja hyväksyi selvityksen [PR #237:n täsmäkommentissa](https://github.com/Tupatuko2023/Python-R-Scripts/pull/237#issuecomment-7043856754).
Dokumentaatio toimitettiin `origin/main`-haaraan commitilla
`116737082a053aa1b7500b856e3525356a0e83ed`. Tämä ei vahvista
nykyistä §3.1:tä eikä valtuuta AIM1-kohderepon julkaisua.

## Vaiheiden erottelu 2026-11-20

- Tekninen toteutus ja synteettinen testaus: valmis, 17/17 PASS.
- Ihmisen WP1-hyväksyntä: annettu täsmärevisiolle; viite yllä.
- PRS:n WP1-dokumentaation main-toimitus: tehty ja varmennettu.
- WP1:n tekninen `04-done`-kirjaus: tehty ja toimitettu mainiin PR #234:ssä.
- Nimettyjen WP1-työpuiden siivous: tehty 20.11.2026.
- Siivouksen dokumentaation main-toimitus: tehty ja varmennettu PR #235:stä.
- Siivoustehtävän tekninen `04-done`-kirjaus: toimitettu mainiin PR #236:ssa.
- Siivouskirjauksen nimetyt työpuut ja haarat: poistettu; kuittaus PR #236:ssa.
- Julkaisuoikeuden ja omistavan §3.1:n lähdeselvitys: tehty ja hyväksytty PR #237:ssa; tekninen `04-done`-sulku toimitettu mainiin PR #238:ssa.
- WALK500:n rajattu tekninen sidonta: ihmisomistaja hyväksyi
  [täsmärevision](https://github.com/Tupatuko2023/Python-R-Scripts/pull/239#issuecomment-7049246851),
  ja PR #239 toimitettiin mainiin commitilla
  `2de6c1e516ee207aa8fb193d684807e31e3fbb33`.
- WALK500:n tekninen `04-done`-siirto: valmisteltu sulkuhaarassa;
  sulkukirjauksen oma PR-toimitus odottaa katselmointia.
- WALK500:n nimetyt työpuut ja haarat: säilytetty; siivousta ei ole tehty.

## Jatkovaihe 2026-11-21

- WALK500:n `04-done`-sulkukirjaus toimitettiin mainiin PR #240:ssä commitilla
  `3a29c4c4359edf0252efbe3a14afc3eb2cccf644`.
- Nimetyt WALK500-työpuut ja niiden paikalliset sekä origin-haarat poistettiin;
  [pysyvä kuittaus](https://github.com/Tupatuko2023/Python-R-Scripts/pull/240#issuecomment-7050347297)
  erottaa siivouksen main-toimituksesta.
- Kahdeksan kyselykomponentin erillinen lähdesidontatehtävä aloitettiin
  eristetyssä työpuussa. Rajattu toteutus ja synteettiset testit valmistuivat;
  tehtävä siirrettiin `03-review`-tilaan. PR-toimitus arvioidaan erikseen.

## Worktree-havainnot

| label                              | state    | evidence                                                                                     |
| ---------------------------------- | -------- | -------------------------------------------------------------------------------------------- |
| aim1-wp1-20261119                  | removed  | PR #233 varmennettu mainista; työpuu ja paikallis- sekä origin-haara poistettu 20.11.2026.   |
| aim1-wp1-lifecycle-20261119        | removed  | PR #234 varmennettu mainista; työpuu ja paikallis- sekä origin-haara poistettu 20.11.2026.   |
| aim1-wp1-cleanup-20261120          | removed  | PR #235 mainissa; työpuu ja paikallis- sekä origin-haara poistettu valtuutetusti 20.11.2026. |
| aim1-wp1-cleanup-closeout-20261120 | removed  | PR #236 mainissa; työpuu ja paikallis- sekä origin-haara poistettu valtuutetusti 20.11.2026. |
| aim1-authority-review-20261120     | retained | Alkuperäinen yksityinen lähdetyöpuu; sen committia ei toimitettu PR #237:ssä.                |
| aim1-authority-public-20261120     | removed  | PR #237:n main-toimitus varmennettu; nimetty työpuu ja haarat poistettu 20.11.2026.          |
| aim1-authority-closeout-20261120   | removed  | PR #238:n main-toimitus varmennettu; nimetty työpuu ja haarat poistettu 20.11.2026.          |
| aim1-walk500-20261120              | removed  | PR #239 mainissa; nimetty työpuu ja haarat poistettu 20.11.2026.                             |
| aim1-walk500-closure-20261120      | removed  | PR #240 mainissa; nimetty työpuu ja haarat poistettu 20.11.2026.                             |
| aim1-deac-eight-bindings-20261121  | active   | Kahdeksan komponentin rajatun tehtävän eristetty työpuu; toimitus odottaa.                   |

Taulukko kuvaa tämän projektin nimetyt työpuut tähän havaintoon asti.
Uuden työpuun perustamisen jälkeen koko inventaarion kattavuus on `unknown`;
muiden projektien työpuita ei siivottu.
