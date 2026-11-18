# Agentin suoritusprotokolla — Quantify-FOF-Utilization-Costs

Tämä protokolla soveltaa repojuuren kanonista [../SKILLS.md](../SKILLS.md)-ohjetta
tämän aliprojektin tehtäviin (`Quantify-FOF-Utilization-Costs/tasks/`).
Repojuuren hallinnollinen etusija koskee tehtävävaltuutusta, PR-menettelyä,
`main`-toimitusta, teknistä sulkua ja siivousta; aliprojektin Option B -,
`DATA_ROOT`-, `n < 5` - ja muuttujastandardointirajoja ([GEMINI.md](GEMINI.md),
[CLAUDE.md](CLAUDE.md)) ei koskaan syrjäytetä:

1. **Lähtötila ja valtuutus:** Tarkista työhakemisto (`Quantify-FOF-Utilization-Costs/`
   aliprojektin skripteille; worktreen repojuuri päärepon porteille) sekä
   tehtäväkortin hyväksytyt kirjoituspolut ja toimitusraja
   ([../SKILLS.md](../SKILLS.md)). Älä aja automaattista `git pull` -komentoa
   ilman valtuutusta äläkä muuta likaista päächeckoutia.
2. **Toteutus (`01-ready -> 02-in-progress`):** Siirrä hyväksytty tehtävä
   `tasks/02-in-progress/`-kansioon ja toteuta vain sallitut kirjoituspolut.
3. **Validointi ja QC:** Suorita soveltuvat savutestit, QC ja tietoturvatarkistukset
   ([GEMINI.md](GEMINI.md), [CLAUDE.md](CLAUDE.md)).
4. **Katselmointiin luovutus (`03-review` + PR):** Siirrä kortti
   `tasks/03-review/`-kansioon ja toimita muutokset PR-katselmointiin
   valtuutetun toimitusrajan mukaisesti. Älä puske suoraan `main`-haaraan.
5. **Hyväksyntä, `main`-toimitus ja tekninen sulku (`04-done`):** Siirrä tehtävä
   `tasks/04-done/`-kansioon vasta täsmärevisioon kohdistuvan pysyvän
   riippumattoman ihmishyväksyntänäytön, valtuutetun PR-mergen,
   `origin/main`-toimitusvarmennuksen ja sulkuvaltuutuksen jälkeen
   ([WORKFLOW.md](WORKFLOW.md)). Pidä työpuun ja haarojen siivous erillään
   toimituksesta.
