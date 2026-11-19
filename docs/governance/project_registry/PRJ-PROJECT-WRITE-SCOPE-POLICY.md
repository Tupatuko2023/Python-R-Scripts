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
latest_status: "2026-11-19: Toteutus hyväksytty (87cd0490), toimitettu mainiin (PR #227, e96e146b) ja suljettu (PR #228, 8e71adfa). Työpuu tmp/project-write-scope-policy-001 ja paikalliset tehtävähaarat poistettu valtuutetussa siivouksessa (worktree-cleanup-001); etähaarat säilytetään."
next_step: "Projekti on toimitettu ja suljettu, ja sen toteutustyöpuu paikallisine haaroineen on siivottu. Älä avaa valmista korttia uudelleen."
source_description_sha256: "5e46c7af00b837cf3ede2eed2e5256bc1df5f11f7d71785160bcfe98b6ee4367"
source_captured_at: "2026-11-18"
observed_at: "2026-11-19"
observed_commit: "b12155dd760e86bc0077d0ad966fc5ee08c0c135"
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
`delivered` -sulku toimitettiin [PR #228:ssa](https://github.com/Tupatuko2023/Python-R-Scripts/pull/228)
`origin/main`-committiin `8e71adfa539b05f95361134eb7b8e57e6a898199`. Ownerin
2026-11-19 valtuuttamassa siivoustehtävässä `worktree-cleanup-001` työpuu
`tmp/project-write-scope-policy-001` (varmennetut regeneroitavat `node_modules/`
ja `projects.csv` poistettuina) sekä paikalliset haarat
`docs/project-write-scope-policy-001` (`87cd0490`) ja
`chore/project-write-scope-policy-closeout-001` (`899dc00b`) poistettiin ilman
pakotusta (`git worktree remove`, `git branch -d`). Likainen päächeckout (ja sen
seuraamaton `tasks/00-backlog/project-write-scope-policy-001.md` -kopio) sekä
etähaarat säilytettiin koskemattomina. Tarkistus perustui toimitus-, Git-omistajuus-,
status- ja prosessihavaintoihin ilman käyttöjärjestelmätason eksklusiivista lukkoa.

## Worktree-havainnot

| label                      | state   | evidence                                                                                                                                                                                                                                    |
| -------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| project-write-scope-policy | removed | tmp/project-write-scope-policy-001 ja paikalliset haarat docs/project-write-scope-policy-001 (87cd0490) sekä chore/project-write-scope-policy-closeout-001 (899dc00b) poistettu 2026-11-19 ilman forcea; PR #227/#228 squash-puut mainissa. |

Inventaario kattaa tämän projektin oman toteutustyöpuun; koska monorepossa on
edelleen muita säilytettyjä työpuita eikä poissulkevaa lukkoa käytetty,
`worktree_inventory` pidetään arvossa `unknown`.
