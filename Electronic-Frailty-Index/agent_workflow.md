# Agentin suoritusprotokolla — Electronic-Frailty-Index

Tämä protokolla soveltaa repojuuren kanonista [../SKILLS.md](../SKILLS.md)-ohjetta
tämän aliprojektin tehtäviin (hallinnollinen etusija koskee tehtävävaltuutusta,
PR-menettelyä, `main`-toimitusta, teknistä sulkua ja siivousta; aliprojektin
tutkimus-, testi- ja dataturvarajoja ei heikennetä):

1. **Valmistelu ja lähtötila:** Varmista työhakemisto, tehtäväkortin hyväksytyt
   kirjoituspolut ja toimitusraja ([../SKILLS.md](../SKILLS.md)). Älä aja
   automaattista `git pull` -komentoa ilman etävaltuutusta äläkä muuta likaista
   päächeckoutia.
2. **Toteutus (`01-ready -> 02-in-progress`):** Siirrä hyväksytty tehtävä
   `02-in-progress`-tilaan ja toteuta muutokset vain sallituissa kirjoituspoluissa.
3. **Validointi:** Aja muutokseen soveltuvat testit ja repon portit
   ([../AGENTS.md](../AGENTS.md)). Korjaa tarkistusvirheet hyväksytyissä poluissa;
   älä ohita pakollisia portteja.
4. **Katselmointiin luovutus (`03-review` + PR):** Siirrä kortti `03-review`-tilaan
   ja toimita muutokset PR-katselmointiin valtuutetun toimitusrajan mukaisesti.
   Älä puske suoraan `main`-haaraan äläkä tee mergeä ilman erillistä
   merge-valtuutusta ja riippumatonta ihmishyväksyntää.
5. **Tekninen sulku (`04-done`) ja erillinen siivous:** Siirrä tehtävä
   `04-done`-kansioon vasta, kun täsmärevisiolla on pysyvä riippumaton
   ihmishyväksyntänäyttö, `origin/main`-toimitus on varmennettu ja sulku on
   valtuutettu ([WORKFLOW.md](WORKFLOW.md)). Säilytä työpuut ja haarat, ellei
   siivousta ole erikseen valtuutettu.
