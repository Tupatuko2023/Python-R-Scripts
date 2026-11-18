# Agentin suoritusprotokolla — Quantify-FOF-Utilization-Costs

Tämä protokolla soveltaa repojuuren kanonista [../SKILLS.md](../SKILLS.md)-ohjetta
tämän aliprojektin tehtäviin (`Quantify-FOF-Utilization-Costs/tasks/`).
Repojuuren hallinnollinen etusija koskee tehtävävaltuutusta, PR-menettelyä,
`main`-toimitusta, teknistä sulkua ja siivousta; aliprojektin Option B -,
`DATA_ROOT`-, aggregaattien kaksiosaisen valtuutuksen, `n < 5` - ja
muuttujastandardointirajoja ([GEMINI.md](GEMINI.md), [CLAUDE.md](CLAUDE.md)) ei
koskaan syrjäytetä, ja ratkaisematon ristiriita pysäyttää riippuvan toimenpiteen:

1. **Lähtötila, työpuu ja valtuutus:** Perusta tehtävälle eristetty worktree
   `git fetch origin main` -haun jälkeen varmennetusta täydestä commit-SHA:sta
   koskematta päächeckoutin haaraan tai paikallisiin muutoksiin. Tarkista
   työhakemisto (`Quantify-FOF-Utilization-Costs/` analyysiskripteille; saman
   eristetyn worktreen repojuuri päärepon hallinta-/rekisterikomennoille) sekä
   tehtäväkortin hyväksytyt kirjoituspolut ja toimitusraja
   ([../SKILLS.md](../SKILLS.md)).
2. **Toteutus (`01-ready -> 02-in-progress`):** Siirrä hyväksytty tehtävä omassa
   jonossaan kansioon `Quantify-FOF-Utilization-Costs/tasks/02-in-progress/`,
   päivitä mahdollisen linkitetyn `PRJ-*.md`-tietueen tehtäväpolku samassa
   muutoksessa ja toteuta vain sallitut kirjoituspolut.
3. **Validointi ja QC:** Suorita tehtävän luonteeseen soveltuvat tarkistukset
   ([GEMINI.md](GEMINI.md), [CLAUDE.md](CLAUDE.md)); puhdas dokumentaatiotehtävä
   ei käynnistä `Full Run` -ajoa eikä lue `DATA_ROOT`-aineistoa.
4. **Katselmointiin luovutus (`03-review` + PR):** Siirrä kortti omassa jonossaan
   kansioon `Quantify-FOF-Utilization-Costs/tasks/03-review/` (päivittäen
   mahdollisen linkitetyn `PRJ-*.md`-tietueen tehtäväpolun) ja toimita muutokset
   PR-katselmointiin valtuutetun toimitusrajan mukaisesti. Älä puske suoraan
   `main`-haaraan.
5. **Hyväksyntä, `main`-toimitus ja tekninen sulku (`04-done`):** Siirrä tehtävä
   omassa jonossaan kansioon `Quantify-FOF-Utilization-Costs/tasks/04-done/`
   vasta täsmärevisioon kohdistuvan pysyvän riippumattoman ihmishyväksyntänäytön,
   valtuutetun PR-mergen, `origin/main`-toimitusvarmennuksen ja sulkuvaltuutuksen
   jälkeen ([WORKFLOW.md](WORKFLOW.md), erottaen `TASK`-sulun projektin omista
   valmistumiskriteereistä). Pidä työpuun ja haarojen siivous erillään
   toimituksesta.
