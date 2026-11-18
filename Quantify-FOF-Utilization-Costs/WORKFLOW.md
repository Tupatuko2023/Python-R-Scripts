# Työnkulkuohje — Quantify-FOF-Utilization-Costs

Hallinnollisessa työnkulussa (tehtäväkohtainen kirjoitus- ja toimitusrajaus,
PR-menettely, `main`-toimitus, tekninen `04-done`-sulku, projektirekisteri ja
siivous) noudatetaan repojuuren kanonista ohjetta [../SKILLS.md](../SKILLS.md)
sekä [../WORKFLOW.md](../WORKFLOW.md)- ja [../AGENTS.md](../AGENTS.md)-ohjeita.
Tämän aliprojektin oma tehtäväjono (`Quantify-FOF-Utilization-Costs/tasks/`)
sekä sen ehdottomat Option B -, `DATA_ROOT`-, aggregaattien kaksiosaisen
valtuutuksen, `n < 5` - ja muuttujastandardointirajat ([GEMINI.md](GEMINI.md),
[CLAUDE.md](CLAUDE.md), [AGENTS.md](AGENTS.md),
[../docs/guides/RUNBOOK_SECURE_EXECUTION.md](../docs/guides/RUNBOOK_SECURE_EXECUTION.md))
säilyvät täysimääräisesti voimassa; ratkaisematon ristiriita pysäyttää riippuvan
toimenpiteen eikä anna lupaa valita heikompaa sääntöä. Aliprojektin
analyysikomennot ajetaan kansiosta `Quantify-FOF-Utilization-Costs/` ja
valtuutetut repojuuren hallinta-/rekisterikomennot saman eristetyn worktreen
repojuuresta.

## PR-, toimitus- ja sulkumenettely

1. **Eristetty tehtäväworktree ja varmennettu lähtö-SHA:** Älä puske suoraan
   `main`-haaraan äläkä vaihda tai pakota päächeckoutin haaraa tai paikallisia
   muutoksia. Perusta eristetty tehtäväworktree ja tehtävähaara
   `git fetch origin main` -haun jälkeen talteen otetusta ja varmennetusta
   täydestä commit-SHA:sta ([../SKILLS.md](../SKILLS.md)).
2. **Toteutus ja katselmointi (`03-review`):** Toteuta muutokset hyväksytyissä
   kirjoituspoluissa, aja tehtävän luonteeseen soveltuvat tarkistukset (puhdas
   dokumentaatiotehtävä ei käynnistä `Full Run` -analyysiajoa eikä lue
   `DATA_ROOT`-aineistoa; ks. [GEMINI.md](GEMINI.md)) ja siirrä tehtäväkortti
   omassa jonossaan (`Quantify-FOF-Utilization-Costs/tasks/02-in-progress/` ->
   `Quantify-FOF-Utilization-Costs/tasks/03-review/`) päivittäen samalla
   mahdollisen linkitetyn `PRJ-*.md`-tietueen tehtäväpolun. Katselmoitu ja
   hyväksytty toteutus-PR yhdistetään `main`iin kortin ollessa `03-review`-tilassa.
3. **Hyväksytty `main`-toimitus ja tekninen sulku (`04-done`):** Pelkkä
   `git push` ei oikeuta `04-done`-siirtoon. Merge ja tekninen
   `Quantify-FOF-Utilization-Costs/tasks/03-review/ -> Quantify-FOF-Utilization-Costs/tasks/04-done/`
   -sulku-PR edellyttävät erillistä valtuutusta, [../SKILLS.md](../SKILLS.md):n
   mukaista täsmärevisioon kohdistuvaa pysyvää riippumatonta ihmishyväksyntänäyttöä
   sekä `origin/main`-toimituksen varmennusta (erottaen `TASK`-sulun projektin
   omista valmistumiskriteereistä).
4. **Siivouksen erottelu:** Toteutuksen valmistuminen, `main`-toimitus ja
   työpuiden/haarojen siivous ovat erillisiä vaiheita; työpuita ja haaroja ei
   poisteta ilman erillistä nimettyä siivousvaltuutusta ja
   [../SKILLS.md](../SKILLS.md):n ehdollista tarkistusketjua.
