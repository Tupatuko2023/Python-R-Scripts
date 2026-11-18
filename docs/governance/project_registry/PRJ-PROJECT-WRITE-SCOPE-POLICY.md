---
id: "PRJ-PROJECT-WRITE-SCOPE-POLICY"
title: "Tehtäväkohtaisen kirjoitusrajauksen käyttöönotto"
short_name: "Tehtäväkohtainen kirjoitusrajaus"
repo: "Tupatuko2023/Python-R-Scripts"
repo_ref: "origin/main"
state: "closed"
delivery: "delivered"
goal: "Korvataan mekaaninen viiden tiedoston ajoraja tehtäväkohtaisella, ennalta hyväksytyllä tavoitteella, yksilöidyillä kirjoituspoluilla ja toimitusrajalla nykyohjeet yhtenäistäen."
done_criterion: "Korvaava sääntö ja välttämättömät viitekorjaukset on validoitu tehtäväkortin hyväksymiskriteereillä, hyväksytty, toimitettu kanoniseen mainiin ja tehtävä suljettu repon menettelyn mukaisesti."
latest_status: "2026-11-18: Toteutus hyväksytty (revisio 87cd0490), toimitettu mainiin (PR #227, e96e146b) ja suljettu (04-done). Työpuu tmp/project-write-scope-policy-001 ja haarat säilytetään koskemattomina ilman poistoja."
next_step: "Projekti on toimitettu ja suljettu; tehtäväkohtainen kirjoitusrajaus on voimassa SKILLS.md:ssä. Älä avaa valmista korttia uudelleen; mahdollinen myöhempi worktree- ja haarasiivous vaatii erillisen valtuutuksen."
source_description_sha256: "5e46c7af00b837cf3ede2eed2e5256bc1df5f11f7d71785160bcfe98b6ee4367"
source_captured_at: "2026-11-18"
observed_at: "2026-11-18"
observed_commit: "e96e146b3abda3ffe4c40143085e870bd31cdb56"
observed_worktree_label: "project-write-scope-policy"
blocker: ""
orchestrator: "FCPO2"
agent: "Antigravity"
agent_tool: "Antigravity"
environment: "Windows PowerShell; GitHub Ubuntu CI"
started_date: "2026-11-18"
paused_date: ""
completed_date: "2026-11-18"
pause_reason: ""
link: "https://github.com/Tupatuko2023/Python-R-Scripts/pull/227"
worktree_inventory: "unknown"
tasks:
  - "project-write-scope-policy-001"
---

## Tehtäväkohtaisen kirjoitusrajauksen käyttöönotto

## Lähdekuvaus

<!-- prettier-ignore-start -->
<!-- source-description:begin -->
Korvataan Python-R-Scripts-repon yleinen viiden tiedoston
ajokohtainen raja tehtäväkohtaisella, ennalta hyväksytyllä
tavoitteella ja yksilöidyillä kirjoituspoluilla. Yhtenäistetään
vain tähän muutokseen suoraan liittyvät nykyohjeet.
Hyväksytyssä rajauksessa agentti voi jatkaa sovittuun
toimitusvaiheeseen ilman saman luvan toistuvaa kysymistä.
Rajauksen laajentaminen edellyttää uutta päätöstä.
Pakolliset tarkistukset, kohdistettu stageaus, riippumaton
katselmointi, tutkimusaineiston suojaus ja muiden työn
säilyttäminen pysyvät voimassa.
<!-- source-description:end -->
<!-- prettier-ignore-end -->

## Tehtäväviitteet

| repo                            | task                             | path                                              |
| ------------------------------- | -------------------------------- | ------------------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | `project-write-scope-policy-001` | `tasks/04-done/project-write-scope-policy-001.md` |

Taulukko viittaa tehtävään repoidentiteetillä ja koko repojuureen suhteutetulla
polulla; tehtäväkortti omistaa elinkaaren ja hyväksynnät.

## Jatkamismuistio

Lue `SKILLS.md`, `AGENTS.md` ja `docs/governance/project_registry/README.md` ennen
päivityksiä. Owner (`Tupatuko2023`) ja orkestroija (`FCPO2`) valtuuttivat
2026-11-18 tämän projektitietueen perustamisen sekä tehtävän
`project-write-scope-policy-001` toteutuksen PR-katselmointiin asti nimetyllä
kertapoikkeuksella voimassa olevasta viiden tiedoston ajorajasta.

Toteutus tehtiin eristetyssä worktreessä `tmp/project-write-scope-policy-001`
haarassa `docs/project-write-scope-policy-001` suoraan varmennetusta
`origin/main`-commitista `b0499e2de483e68f1f73f65d88859cac9b6778af`. Ownerin
pysyvä [hyväksyntä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/227#issuecomment-6982284690)
(`2026-11-18T14:59:11Z`) kohdistui täsmärevisioon
`87cd0490696178cc9c46f215a868b3bd4465794e`, joka toimitettiin
[PR #227:ssä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/227)
`origin/main`-committiin `e96e146b3abda3ffe4c40143085e870bd31cdb56`.

Tehtävän tekninen `04-done`-siirto ja tämän projektitietueen `closed` /
`delivered` -sulku toimitetaan yhdessä omassa sulku-PR:ssään. Likainen
päächeckout (ja sen seuraamaton `tasks/00-backlog/project-write-scope-policy-001.md`
-kopio), tämä toteutustyöpuu, tehtävähaarat sekä kaikki muut 12 työpuuta
säilytetään koskemattomina erillään `main`-toimituksesta.

## Worktree-havainnot

| label                      | state    | evidence                                                                                                                                                                                                                                |
| -------------------------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| project-write-scope-policy | retained | tmp/project-write-scope-policy-001 sekä haarat docs/project-write-scope-policy-001 (87cd0490) ja chore/project-write-scope-policy-closeout-001 säilytetty PR #227:n (e96e146b) jälkeen; päächeckout ja 12 muuta työpuuta koskemattomia. |

Inventaario kattaa tämän projektin oman toteutustyöpuun; koko monorepon muita
työpuita ei siivota tässä tehtävässä, joten `worktree_inventory` on `unknown`.
