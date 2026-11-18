# Työnkulkuohje — Quantify-FOF-Utilization-Costs

Hallinnollisessa työnkulussa (tehtäväkohtainen kirjoitus- ja toimitusrajaus,
PR-menettely, `main`-toimitus, tekninen `04-done`-sulku, projektirekisteri ja
siivous) noudatetaan repojuuren kanonista ohjetta [../SKILLS.md](../SKILLS.md)
sekä [../WORKFLOW.md](../WORKFLOW.md)- ja [../AGENTS.md](../AGENTS.md)-ohjeita.
Tämän aliprojektin oma tehtäväjono (`Quantify-FOF-Utilization-Costs/tasks/`)
sekä sen ehdottomat Option B -, `DATA_ROOT`-, aggregaatti-, `n < 5` - ja
muuttujastandardointirajat ([GEMINI.md](GEMINI.md), [CLAUDE.md](CLAUDE.md),
[AGENTS.md](AGENTS.md),
[../docs/guides/RUNBOOK_SECURE_EXECUTION.md](../docs/guides/RUNBOOK_SECURE_EXECUTION.md))
säilyvät täysimääräisesti voimassa. Aliprojektin analyysikomennot ajetaan kansiosta
`Quantify-FOF-Utilization-Costs/` ja päärepon portti-/rekisterikomennot worktreen
repojuuresta.

## PR-, toimitus- ja sulkumenettely

1. **Lähtötila ja haara:** Älä puske suoraan `main`-haaraan äläkä pakota
   likaisen päächeckoutin päivitystä. Perusta tehtävähaara tai eristetty
   worktree varmennetusta `origin/main`ista tehtävävaltuutuksen puitteissa.
2. **Toteutus ja katselmointi (`03-review`):** Toteuta muutokset hyväksytyissä
   kirjoituspoluissa, aja soveltuvat tarkistukset ja siirrä tehtäväkortti
   `tasks/02-in-progress/` -> `tasks/03-review/` PR-katselmointia varten.
   Katselmoitu ja hyväksytty toteutus-PR yhdistetään `main`iin kortin ollessa
   `03-review`-tilassa (erillinen vanha kielto yhdistää `03-review`-kortti on
   poistettu [../SKILLS.md](../SKILLS.md):n mukaisena).
3. **Hyväksytty `main`-toimitus ja tekninen sulku (`04-done`):** Pelkkä
   `git push` ei oikeuta `04-done`-siirtoon. Merge ja tekninen
   `03-review -> 04-done` -sulku-PR edellyttävät erillistä valtuutusta,
   [../SKILLS.md](../SKILLS.md):n mukaista täsmärevisioon kohdistuvaa pysyvää
   riippumatonta ihmishyväksyntänäyttöä sekä `origin/main`-toimituksen
   varmennusta.
4. **Siivouksen erottelu:** Toteutuksen valmistuminen, `main`-toimitus ja
   työpuiden/haarojen siivous ovat erillisiä vaiheita; työpuita ja haaroja ei
   poisteta ilman erillistä siivousvaltuutusta.
