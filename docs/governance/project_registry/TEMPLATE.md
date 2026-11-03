---
id: ""
title: ""
short_name: ""
repo: ""
repo_ref: ""
state: ""
delivery: ""
goal: ""
done_criterion: ""
latest_status: ""
next_step: ""
source_description_sha256: ""
source_captured_at: ""
observed_at: ""
observed_commit: ""
observed_worktree_label: ""
blocker: ""
orchestrator: ""
agent: ""
agent_tool: ""
environment: ""
started_date: ""
paused_date: ""
completed_date: ""
pause_reason: ""
link: ""
worktree_inventory: ""
tasks:
  - "<tehtävän tunniste>"
---

## Projektin täyttöpohja

Tämä on tyhjä pohja, ei kerättävä PRJ-tietue. Kopioi vain tehtävän sallimaan
PRJ-<SLUG>.md-polkuun ja täytä nykyisen README-sopimuksen mukaisesti.
Repoidentiteetti ei korvaa täyttä tehtäväpolkua. Tyhjät pakolliset kentät,
päivät, lähdehash ja havaintocommit täytetään ennen validointia.

## Lähdekuvaus

<!-- source-description:begin -->
<!-- source-description:end -->

Kirjaa hyväksytty yksityiskohtainen projektikuvaus merkkien väliin ja laske
--print-source-hash-komennolla sen SHA256. Muutokset hyväksyttyyn lähdekuvaukseen
vaativat ihmisomistajan päätöksen. Pidä päivittäinen tilahavainto erillisenä.

## Tehtäväviitteet

| repo               | task       | path                                 |
| ------------------ | ---------- | ------------------------------------ |
| <repoidentiteetti> | <tunniste> | <koko repojuureen suhteutettu polku> |

Taulukko viittaa tehtävään; älä kopioi sen lifecycle-tilaa rinnakkaiseksi tiedoksi.

## Jatkamismuistio

Täytä nykytilanne, seuraava toimi, vastuullinen toimija, este ja evidenssiviite.
Erota paikallinen toteutus, main-toimitus ja työpuun siivous. Jos toimitusta ei
ole varmennettu, käytä not_delivered/unknown. Inventaarion oletus on unknown.

## Worktree-havainnot

| label | state | evidence |
| ----- | ----- | -------- |

Tyhjä taulukko ei todista siivousta. Sallittuja tiloja ovat active, retained,
removed ja unknown. Merkitse complete vain dokumentoidusti kattavaan inventaarioon.
