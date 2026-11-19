---
id: "PRJ-WORKFLOW-GUIDANCE-ALIGNMENT"
title: "Työnkulkuohjeiden yhtenäistäminen päärepossa ja aliprojekteissa"
short_name: "Työnkulkuohjeiden yhtenäistäminen päärepossa ja aliprojekteissa"
repo: "Tupatuko2023/Python-R-Scripts"
repo_ref: "origin/main"
state: "closed"
delivery: "delivered"
goal: "Yhtenäistetään päärepon ja aliprojektien työnkulkuohjeet valmistumisen, main-toimituksen ja siivouksen erottelun, PR-/ihmishyväksyntämenettelyn sekä hallinnollisten etusijaviittausten osalta."
done_criterion: "Päärepon ja aliprojektien työnkulkuohjeiden ristiriidat (valmistumisen, main-toimituksen ja siivouksen erottelu, suorapush-/DONE-säännöt sekä keskinäiset etusijaviittaukset) on yhtenäistetty, validoitu, hyväksytty, toimitettu kanoniseen mainiin ja tehtävä suljettu repon menettelyn mukaisesti."
latest_status: "2026-11-19: Toteutus hyväksytty (fa29be19), toimitettu origin/mainiin (PR #229, 8657ea22) ja suljettu (PR #230, b12155dd). Windows PS7- ja Termux-ajotestit NOT_RUN; työpuu tmp/workflow-guidance-alignment-001 ja paikalliset tehtävähaarat poistettu valtuutetussa siivouksessa (worktree-cleanup-001), etähaarat säilytetään."
next_step: "Projekti on toimitettu ja suljettu, ja sen toteutustyöpuu paikallisine haaroineen on siivottu. Älä avaa valmista korttia uudelleen; mahdollinen myöhempi PS7/Termux-ajonaikainen lataustestaus edellyttää erillistä valtuutusta."
source_description_sha256: "6d8d4564d58eef72484dc6901f9a4c9bbb304f2f42afa415c0fa3b43b94fc6d0"
source_captured_at: "2026-11-18"
observed_at: "2026-11-19"
observed_commit: "b12155dd760e86bc0077d0ad966fc5ee08c0c135"
observed_worktree_label: "workflow-guidance-alignment"
blocker: ""
orchestrator: "FCPO2"
agent: "Antigravity"
agent_tool: "Antigravity"
environment: "Windows PowerShell; GitHub Ubuntu CI"
started_date: "2026-11-18"
paused_date: ""
completed_date: "2026-11-18"
pause_reason: ""
link: "https://github.com/Tupatuko2023/Python-R-Scripts/pull/229"
worktree_inventory: "unknown"
tasks:
  - "workflow-guidance-alignment-001"
---

## Työnkulkuohjeiden yhtenäistäminen päärepossa ja aliprojekteissa

## Lähdekuvaus

<!-- prettier-ignore-start -->
<!-- markdownlint-disable MD032 -->
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
<!-- markdownlint-enable MD032 -->
<!-- prettier-ignore-end -->

## Tehtäväviitteet

| repo                            | task                              | path                                               |
| ------------------------------- | --------------------------------- | -------------------------------------------------- |
| `Tupatuko2023/Python-R-Scripts` | `workflow-guidance-alignment-001` | `tasks/04-done/workflow-guidance-alignment-001.md` |

Taulukko viittaa tehtävään repoidentiteetillä ja koko repojuureen suhteutetulla
polulla; tehtäväkortti omistaa elinkaaren ja hyväksynnät.

## Jatkamismuistio

Lue `SKILLS.md`, `AGENTS.md` ja `docs/governance/project_registry/README.md` ennen
päivityksiä. Owner (`Tupatuko2023`) ja orkestroija (`FCPO2`) hyväksyivät
2026-11-18 tämän projektitietueen perustamisen sekä tehtävän
`workflow-guidance-alignment-001` kirjoitusrajauksen ja katselmointikorjaukset.

Toteutus tehtiin eristetyssä worktreessä `tmp/workflow-guidance-alignment-001`
haarassa `docs/workflow-guidance-alignment-001` suoraan varmennetusta
`origin/main`-commitista `8e71adfa539b05f95361134eb7b8e57e6a898199`. Ownerin
pysyvä [ihmishyväksyntä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/229#issuecomment-6986138907)
(`2026-11-18T17:23:22Z`) kohdistui täsmärevisioon
`fa29be19258f4a585af2afd76d97eed6051567b1`, joka toimitettiin
[PR #229:ssä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/229)
`origin/main`-committiin `8657ea22e79bc14c35b04d0f43e934d7a8e95b17`.

Projektin omat valmistumiskriteerit (`done_criterion`) tarkistettiin ennen
sulkua: kaikki kolme lähdekuvauksen osa-aluetta toimitettiin `origin/main`iin,
ja sulku toimitettiin [PR #230:ssä](https://github.com/Tupatuko2023/Python-R-Scripts/pull/230)
`origin/main`-committiin `b12155dd760e86bc0077d0ad966fc5ee08c0c135`. Windows PS7-
ja Termux-ajonaikaiset käyttäytymistestit pidetään erillisinä `NOT_RUN`-merkinnöillä.
Ownerin 2026-11-19 valtuuttamassa siivoustehtävässä `worktree-cleanup-001`
työpuu `tmp/workflow-guidance-alignment-001` (varmennetut regeneroitavat
`node_modules/`, `projects.csv` ja `__pycache__/` poistettuina) sekä paikalliset
haarat `docs/workflow-guidance-alignment-001` (`fa29be19`) ja
`chore/workflow-guidance-alignment-closeout-001` (`4a5ade34`) poistettiin ilman
pakotusta (`git worktree remove`, `git branch -d`); likainen päächeckout ja
etähaarat säilytettiin koskemattomina. Tarkistus perustui toimitus-,
Git-omistajuus-, status- ja prosessihavaintoihin ilman eksklusiivista lukkoa.

## Worktree-havainnot

| label                       | state   | evidence                                                                                                                                                                                                                                              |
| --------------------------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| workflow-guidance-alignment | removed | tmp/workflow-guidance-alignment-001 ja paikalliset haarat docs/workflow-guidance-alignment-001 (fa29be19) sekä chore/workflow-guidance-alignment-closeout-001 (4a5ade34) poistettu 2026-11-19 ilman forcea; PR #229/#230 squash-puut origin/mainissa. |

Inventaario kattaa tämän projektin oman toteutustyöpuun; koska monorepossa on
edelleen muita säilytettyjä työpuita eikä poissulkevaa lukkoa käytetty,
`worktree_inventory` pidetään arvossa `unknown`.
