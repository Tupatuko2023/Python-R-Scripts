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
latest_status: "2026-11-18: Toteutus hyväksytty (revisio fa29be19), toimitettu origin/mainiin (PR #229, 8657ea22) ja tehtävä suljettu (04-done). Windows PS7- ja Termux-ajotestit kirjattu NOT_RUN; työpuu tmp/workflow-guidance-alignment-001 ja haarat säilytetään koskemattomina (retained)."
next_step: "Projekti on toimitettu ja suljettu sulku-PR:n hyväksynnän myötä. Älä avaa valmista korttia uudelleen; mahdollinen myöhempi PS7/Termux-ajonaikainen lataustestaus tai työpuu- ja haarasiivous edellyttää erillistä valtuutusta."
source_description_sha256: "6d8d4564d58eef72484dc6901f9a4c9bbb304f2f42afa415c0fa3b43b94fc6d0"
source_captured_at: "2026-11-18"
observed_at: "2026-11-18"
observed_commit: "8657ea22e79bc14c35b04d0f43e934d7a8e95b17"
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
sulkua: kaikki kolme lähdekuvauksen osa-aluetta on toimitettu `origin/main`iin,
muita avoimia tehtäviä ei ole ja tehtävä `workflow-guidance-alignment-001`
siirretään samassa sulku-PR:ssä polkuun `tasks/04-done/workflow-guidance-alignment-001.md`.
Windows PS7- ja Termux-ajonaikaiset käyttäytymistestit pidetään erillisinä
`NOT_RUN`-merkinnöillä, ja likainen päächeckout, tämä toteutustyöpuu, sen haarat
sekä kaikki 13 aiempaa työpuuta säilytetään koskemattomina (`retained`) erillään
`main`-toimituksesta ja teknisestä sulusta.

## Worktree-havainnot

| label                       | state    | evidence                                                                                                                                                                                                                                     |
| --------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| workflow-guidance-alignment | retained | tmp/workflow-guidance-alignment-001 sekä haarat docs/workflow-guidance-alignment-001 (fa29be19) ja chore/workflow-guidance-alignment-closeout-001 säilytetty PR #229:n (8657ea22) jälkeen; päächeckout ja 13 aiempaa työpuuta koskemattomia. |

Inventaario kattaa tämän projektin oman toteutustyöpuun; muita työpuita ei
siivota tässä tehtävässä, joten `worktree_inventory` on `unknown`.
