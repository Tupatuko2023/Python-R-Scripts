---
id: "PRJ-PROJECT-WRITE-SCOPE-POLICY"
title: "Tehtäväkohtaisen kirjoitusrajauksen käyttöönotto"
short_name: "Tehtäväkohtainen kirjoitusrajaus"
repo: "Tupatuko2023/Python-R-Scripts"
repo_ref: "origin/main"
state: "planned"
delivery: "not_delivered"
goal: "Korvataan mekaaninen viiden tiedoston ajoraja tehtäväkohtaisella, ennalta hyväksytyllä tavoitteella, yksilöidyillä kirjoituspoluilla ja toimitusrajalla nykyohjeet yhtenäistäen."
done_criterion: "Korvaava sääntö ja välttämättömät viitekorjaukset on validoitu tehtäväkortin hyväksymiskriteereillä, hyväksytty, toimitettu kanoniseen mainiin ja tehtävä suljettu repon menettelyn mukaisesti."
latest_status: "2026-11-18: Read-only-selvitys valmistunut ja Owner hyväksynyt toteutuksen PR-katselmointiin asti kertapoikkeuksella. READY-kortti ja tämä planned-projektitietue alustettu eristetyssä worktreessä origin/mainista (b0499e2d)."
next_step: "Siirrä project-write-scope-policy-001 tilaan 02-in-progress, vaihda tämä tietue active-tilaan Git-suojan (--verify-guard) kautta ja toteuta hyväksytyt ohje- ja viitemuutokset."
source_description_sha256: "5e46c7af00b837cf3ede2eed2e5256bc1df5f11f7d71785160bcfe98b6ee4367"
source_captured_at: "2026-11-18"
observed_at: "2026-11-18"
observed_commit: "b0499e2de483e68f1f73f65d88859cac9b6778af"
observed_worktree_label: "project-write-scope-policy"
blocker: ""
orchestrator: "FCPO2"
agent: "Antigravity"
agent_tool: "Antigravity"
environment: "Windows PowerShell; GitHub Ubuntu CI"
started_date: ""
paused_date: ""
completed_date: ""
pause_reason: ""
link: ""
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

| repo                            | task                             | path                                               |
| ------------------------------- | -------------------------------- | -------------------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | `project-write-scope-policy-001` | `tasks/01-ready/project-write-scope-policy-001.md` |

Taulukko viittaa tehtävään repoidentiteetillä ja koko repojuureen suhteutetulla
polulla; tehtäväkortti omistaa elinkaaren ja hyväksynnät.

## Jatkamismuistio

Lue `SKILLS.md`, `AGENTS.md` ja `docs/governance/project_registry/README.md` ennen
päivityksiä. Owner (`Tupatuko2023`) ja orkestroija (`FCPO2`) valtuuttivat
2026-11-18 tämän projektitietueen perustamisen sekä tehtävän
`project-write-scope-policy-001` toteutuksen PR-katselmointiin asti nimetyllä
kertapoikkeuksella voimassa olevasta viiden tiedoston ajorajasta.

Toteutus tehdään eristetyssä worktreessä `tmp/project-write-scope-policy-001`
haarassa `docs/project-write-scope-policy-001` suoraan varmennetusta
`origin/main`-commitista `b0499e2de483e68f1f73f65d88859cac9b6778af`. Likainen
päächeckout (ja sen seuraamaton `tasks/00-backlog/project-write-scope-policy-001.md`
-kopio) sekä kaikki muut 12 työpuuta säilytetään koskemattomina. Käytä kaikissa
tämän ensiluonnin jälkeisissä päivityksissä `--verify-guard`-tarkistusta ennen
kirjoitusta ja pidä toteutus, `main`-toimitus sekä worktree-siivous erillään.

## Worktree-havainnot

| label                      | state  | evidence                                                                                                                                               |
| -------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| project-write-scope-policy | active | tmp/project-write-scope-policy-001 perustettu origin/mainista (b0499e2d); päächeckout ja 12 muuta olemassa olevaa työpuuta säilytetään koskemattomina. |

Inventaario kattaa tämän projektin oman toteutustyöpuun; koko monorepon muita
työpuita ei siivota tässä tehtävässä, joten `worktree_inventory` on `unknown`.
