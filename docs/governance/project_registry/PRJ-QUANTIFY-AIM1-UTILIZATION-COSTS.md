---
id: "PRJ-QUANTIFY-AIM1-UTILIZATION-COSTS"
title: "Quantify-FOF-Utilization-Costs: AIM1:n palvelukäyttö ja laskennallinen rahallinen arvo"
short_name: "Quantify AIM1"
repo: "Tupatuko2023/Python-R-Scripts"
repo_ref: "origin/main"
state: "active"
delivery: "not_delivered"
goal: "Koota Quantify-FOF-Utilization-Costs-aliprojektin AIM1-palvelukäyttö- ja kustannustyön lähteet, rajatut analyysit ja raportointipäätökset katselmoitavaksi kokonaisuudeksi."
done_criterion: "Sovittu AIM1-kokonaisuus ja sen lähde- sekä menetelmärajaukset on ihmisen hyväksymä, toimitettu mainiin ja projektin sulku on päätetty erikseen."
latest_status: "2026-11-21: Projektiseurannan rajattu PR #241 on hyväksytty ja toimitettu mainiin commitilla 6d11037d0a78f61cd98a398d0cdf76e3f6110e58; siihen liittyvä tehtävä siirrettiin tekniseen 04-done-tilaan. G4:n paikallinen valmistelukortti on edelleen kesken. Rahalliset analyysit ja diagnostiikka on raportoitu paikallisissa katselmointitoimituksissa, mutta luokkamallien raportointipäätöstä ei ole tehty."
next_step: "Katselmoi S70–S79:n splinin epävarmuuslisä sekä kaikkien yhdeksän luokkamallin raportointiehdotus tutkijan ja biostatistikon kanssa; päätä sen jälkeen, mitä siirretään esityksen ja käsikirjoituksen tuloksiin. Tarkista G4-kortin julkaisukelpoisuus erillisenä rajattuna tehtävänä."
source_description_sha256: "30f71e7f28837812dccaa0b5467bfc07a6fa7a813c78fbfc2afa456bf31102b3"
source_captured_at: "2026-11-21"
observed_at: "2026-11-21"
observed_commit: "6d11037d0a78f61cd98a398d0cdf76e3f6110e58"
observed_worktree_label: "quantify-fof-project-registry-20261121"
blocker: "G4:n tieteellinen raportointiratkaisu ja osa kustannuslähteen semantiikasta ovat avoimia; nykyinen paikallinen G4-kortti ei ole julkaistavissa tähän seurantamuutokseen sellaisenaan. Nämä eivät estä projektin aktiivista jatkoseurantaa."
orchestrator: "Owner"
agent: "Termux Codex"
agent_tool: "Codex"
environment: "Android Termux"
started_date: "2026-11-21"
paused_date: ""
completed_date: ""
pause_reason: ""
link: ""
worktree_inventory: "unknown"
tasks:
  - "TASK-QUANTIFY-AIM1-PROJECT-TRACKING-20261121"
---

## Quantify AIM1:n projektiseuranta

## Lähdekuvaus

<!-- prettier-ignore-start -->
<!-- source-description:begin -->
Quantify-FOF-Utilization-Costs-aliprojektin AIM1-työssä selvitetään lähtötilanteen DEAC20:n yhteyttä myöhempään palvelukäyttöön ja laskennalliseen rahalliseen arvoon. Työ etenee erillisinä lähde-, menetelmä-, toteutus- ja raportointitehtävinä. Ehdolliset analyysit ja katselmointipaketit eivät yksin vahvista tieteellisiä tulkintoja eivätkä osoita toimitusta mainiin.
<!-- source-description:end -->
<!-- prettier-ignore-end -->

## Tehtäväviitteet

| repo                            | task                                           | path                                                                                           |
| ------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | `TASK-QUANTIFY-AIM1-PROJECT-TRACKING-20261121` | `Quantify-FOF-Utilization-Costs/tasks/04-done/TASK-QUANTIFY-AIM1-PROJECT-TRACKING-20261121.md` |

## Jatkamismuistio

- **Valmistelu:** G4:n rajattu valmistelu alkoi aiemmin. Sen laaja paikallinen kortti on jaetussa työpuussa polussa `tasks/02-in-progress/AIM1_G4_COSTING_DECISION_PREP_20261022.md`, mutta sitä ei seurata Gitissä eikä se ole tämän haaran tehtäväviite. Kortin sisältö tarkistetaan erikseen ennen mahdollista julkaisua; sitä ei kopioitu tähän muutokseen.
- **Myöhempi toteutus:** ehdollinen kaksiosainen rahallinen kokonaismalli, DEAC20-ennustekäyrät, 12 vammaluokan kuvaileva euroerittely ja yhdeksän luokkamallin alustavat sovitukset sekä diagnostiikka on raportoitu paikallisissa katselmointipaketeissa. Viimeisin S70–S79:n spline-epävarmuuslisä on paikallinen paketti `AIM1_DEAC20_S70_SPLINE_POINTWISE_HC3_REVIEW_20261118.zip`, SHA-256 `dca251f2e0e71fbac23a01138465320ace04d78cce718e4510d9ae4601543428`. Paketin eheyden paikallinen tarkistus ei ole tieteellinen hyväksyntä.
- **Toimitustunnisteet:** G4:n paikallinen valmistelukortti raportoi kaksiosaisen mallin tunnisteettoman katselmointiyhteenvedon `aim1_cost_two_part_review_summary_v2.md` (SHA-256 `e086e57d4233044d89a60a37e483f20284c60440a31ee76813778f1ab572ad83`). Ennustekäyrän katselmointipaketti on `AIM1_DEAC20_COST_CURVE_REVIEW_V2_20261116.zip` (SHA-256 `bae935d14ca9f2a77f925330cad60d926686a353f58cdd418048f1590794dcca`), kuvailevan euroerittelyn paketti `AIM1_DEAC20_COST_CLASS_EUROS_470_20261117.zip` (SHA-256 `799871f985201b41d967fc419e70442607c8b2b689350f38750e34a866508508`) ja yhdeksän luokkamallin katselmointipaketti `AIM1_DEAC20_CLASS_COUNT_EUR_FIT_REVIEW_20261117.zip` (SHA-256 `1e24493f7cb05e5567ba8b80546ed4fac72a6891519cbc597d1bd00429b608dd`). Näiden jälkeen raportoitiin erillinen diagnostinen toisto `AIM1_DEAC20_CLASS_FIT_DIAGNOSTIC_REPEAT_REVIEW_20261117.zip` (SHA-256 `8c7eceea3003e216a702ffbbcb10e2b4c7c4532325053928ec59110278f55ea1`). ZIPien ulkoiset summat tarkistettiin paikallisista kopioista tätä PR-katselmointia varten; sisältöä tai tieteellisiä päätelmiä ei varmennettu tässä seurantatehtävässä.
- **Keskeneräinen työ:** yhdeksän luokkamallin raportointitapa ja S70–S79:n splinin pistekohtaisten välien tulkinta odottavat tutkijan ja biostatistikon yhteistä katselmointia. G4:n lähdepeiton ja rahallisen tulkinnan varaukset säilyvät; uutta analyysia ei käynnistetä seurantatehtävässä.
- **Seuraava toimi:** käsittele kyseinen katselmointi sekä mahdollinen G4-kortin rajattu Git-kelpoisuustarkistus erillisinä tehtävinä. Älä muuta nykyisiä tuloksia tämän rekisterimerkinnän perusteella.

## Vaiheiden erottelu 2026-11-21

- Katselmointipaketit: paikallisesti valmisteltu; yksittäisen viimeisen paketin Windows-vastaanottoa ei varmennettu tässä seurantatehtävässä.
- Ihmisomistajan tieteellinen hyväksyntä: avoin.
- Tämän projektiseurantamuutoksen `origin/main`-toimitus: PR #241, squash-commit `6d11037d0a78f61cd98a398d0cdf76e3f6110e58`, varmennettu 21.11.2026. Tekninen `04-done`-sulkukirjaus käsitellään erillisessä lifecycle-PR:ssä.
- G4-työn Git-toimitus: ei varmennettu tämän paikallisen kortin perusteella.
- Työpuun siivous: tekemättä; mitään työpuuta ei poistettu.

## Worktree-havainnot

| label                                  | state    | evidence                                                                                                                                    |
| -------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| quantify-fof-project-registry-20261121 | active   | PR #241 toimitettiin mainiin; erillinen tekninen sulkukirjaus valmistellaan samassa eristetyssä työpuussa. Työpuuta tai haaraa ei poisteta. |
| shared-main-checkout                   | retained | Jaetussa työpuussa on seuraamaton G4-kortti ja muiden töiden muutoksia; sitä ei muutettu.                                                   |

Inventaarion kattavuus on `unknown`; taulukko ei väitä kaikkien Quantify-työpuiden siivousta.
