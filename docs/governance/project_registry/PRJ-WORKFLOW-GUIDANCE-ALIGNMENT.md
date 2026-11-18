---
id: "PRJ-WORKFLOW-GUIDANCE-ALIGNMENT"
title: "Työnkulkuohjeiden yhtenäistäminen päärepossa ja aliprojekteissa"
short_name: "Työnkulkuohjeiden yhtenäistäminen päärepossa ja aliprojekteissa"
repo: "Tupatuko2023/Python-R-Scripts"
repo_ref: "origin/main"
state: "planned"
delivery: "not_delivered"
goal: "Yhtenäistetään päärepon ja aliprojektien työnkulkuohjeet valmistumisen, main-toimituksen ja siivouksen erottelun, PR-/ihmishyväksyntämenettelyn sekä hallinnollisten etusijaviittausten osalta."
done_criterion: "Päärepon ja aliprojektien työnkulkuohjeiden ristiriidat (valmistumisen, main-toimituksen ja siivouksen erottelu, suorapush-/DONE-säännöt sekä keskinäiset etusijaviittaukset) on yhtenäistetty, validoitu, hyväksytty, toimitettu kanoniseen mainiin ja tehtävä suljettu repon menettelyn mukaisesti."
latest_status: "2026-11-18: Read-only-lukutarkastus suoritettu ja Owner hyväksynyt 16 polun kirjoitusrajauksen, lähdekuvauksen ja toimitusrajan PR-katselmointiin asti. READY-kortti ja tämä planned-tietue alustettu origin/mainista (8e71adfa)."
next_step: "Siirrä workflow-guidance-alignment-001 tilaan 02-in-progress, aktivoi tämä projektitietue Git-suojan (--verify-guard) kautta ja toteuta hyväksytyt 15 ohjetiedoston päivitykset."
source_description_sha256: "6d8d4564d58eef72484dc6901f9a4c9bbb304f2f42afa415c0fa3b43b94fc6d0"
source_captured_at: "2026-11-18"
observed_at: "2026-11-18"
observed_commit: "8e71adfa539b05f95361134eb7b8e57e6a898199"
observed_worktree_label: "workflow-guidance-alignment"
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
  - "workflow-guidance-alignment-001"
---

## Työnkulkuohjeiden yhtenäistäminen päärepossa ja aliprojekteissa

## Lähdekuvaus

<!-- prettier-ignore-start -->
<!-- source-description:begin -->
Yhtenäistetään Python-R-Scripts-repon päärepon ja aliprojektien
ristiriitaiset työnkulkuohjeet vastaamaan nykyistä PR-, hyväksyntä-
ja tehtäväkohtaisen kirjoitusrajauksen menettelyä:
1. Erotetaan työn valmistuminen katselmointiin (03-review),
   hyväksytty main-toimitus ja tekninen sulku (04-done) sekä
   erikseen valtuutettava työpuun ja haarojen siivous.
2. Korjataan aliprojektien vanhat suorapush- ja automaattiset
   DONE-ohjeet vastaamaan SKILLS.md:n PR- ja ihmishyväksyntäportteja.
3. Selkeytetään ohjeiden keskinäiset etusija- ja polkuviittaukset
   säilyttäen aliprojektien omat tehtäväjonot ja kaikki
   tutkimusaineiston, ympäristön ja QC:n suojaukset.
Historiallisia tehtäväkortteja tai muutoslokeja ei kirjoiteta uusiksi.
<!-- source-description:end -->
<!-- prettier-ignore-end -->

## Tehtäväviitteet

| repo                            | task                              | path                                                |
| ------------------------------- | --------------------------------- | --------------------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | `workflow-guidance-alignment-001` | `tasks/01-ready/workflow-guidance-alignment-001.md` |

Taulukko viittaa tehtävään repoidentiteetillä ja koko repojuureen suhteutetulla
polulla; tehtäväkortti omistaa elinkaaren ja hyväksynnät.

## Jatkamismuistio

Lue `SKILLS.md`, `AGENTS.md` ja `docs/governance/project_registry/README.md` ennen
päivityksiä. Owner (`Tupatuko2023`) ja orkestroija (`FCPO2`) hyväksyivät
2026-11-18 tämän projektitietueen perustamisen sekä tehtävän
`workflow-guidance-alignment-001` kirjoitusrajauksen ja toimitusrajan
PR-katselmointiin asti.

Toteutus tehdään eristetyssä worktreessä `tmp/workflow-guidance-alignment-001`
haarassa `docs/workflow-guidance-alignment-001` suoraan varmennetusta
`origin/main`-commitista `8e71adfa539b05f95361134eb7b8e57e6a898199`. Likainen
päächeckout sekä kaikki 13 aiempaa työpuuta säilytetään koskemattomina. Käytä
kaikissa tämän ensiluonnin jälkeisissä päivityksissä `--verify-guard`-tarkistusta
ennen kirjoitusta ja pidä toteutuksen valmistuminen, `main`-toimitus sekä
worktree-siivous erillään.

## Worktree-havainnot

| label                       | state  | evidence                                                                                                                                                  |
| --------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| workflow-guidance-alignment | active | tmp/workflow-guidance-alignment-001 perustettu origin/mainista (8e71adfa); päächeckout ja 13 aiemmin olemassa olevaa työpuuta säilytetään koskemattomina. |

Inventaario kattaa tämän projektin oman toteutustyöpuun; muita työpuita ei
siivota tässä tehtävässä, joten `worktree_inventory` on `unknown`.
