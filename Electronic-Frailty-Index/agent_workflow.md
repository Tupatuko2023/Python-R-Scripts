# Agentin suoritusprotokolla — Electronic-Frailty-Index

Tämä protokolla soveltaa repojuuren kanonista [../SKILLS.md](../SKILLS.md)-ohjetta
tämän aliprojektin tehtäviin (hallinnollinen etusija koskee tehtävävaltuutusta,
PR-menettelyä, `main`-toimitusta, teknistä sulkua ja siivousta; aliprojektin
tutkimus-, testi- ja dataturvarajoja ei heikennetä, ja ratkaisematon ristiriita
pysäyttää riippuvan toimenpiteen):

1. **Valmistelu ja eristetty worktree:** Perusta tehtävälle eristetty worktree
   `git fetch origin main` -haun jälkeen varmennetusta täydestä commit-SHA:sta
   koskematta päächeckoutin haaraan tai paikallisiin muutoksiin, ja tarkista
   hyväksytyt kirjoituspolut sekä toimitusraja ([../SKILLS.md](../SKILLS.md)).
2. **Toteutus (`01-ready -> 02-in-progress`):** Siirrä hyväksytty tehtävä omassa
   tehtäväjonossaan `02-in-progress`-kansioon (päivittäen samalla mahdollisen
   linkitetyn `PRJ-*.md`-tietueen tehtäväpolun) ja toteuta vain sallitut
   kirjoituspolut.
3. **Validointi:** Aja muutokseen soveltuvat testit ja repon portit
   ([../AGENTS.md](../AGENTS.md)). Korjaa tarkistusvirheet hyväksytyissä poluissa;
   älä ohita pakollisia portteja.
4. **Katselmointiin luovutus (`03-review` + PR):** Siirrä kortti omassa
   tehtäväjonossaan `03-review`-kansioon (päivittäen mahdollisen linkitetyn
   `PRJ-*.md`-tietueen tehtäväpolun) ja toimita muutokset PR-katselmointiin
   valtuutetun toimitusrajan mukaisesti. Älä puske suoraan `main`-haaraan äläkä
   tee mergeä ilman erillistä merge-valtuutusta ja riippumatonta ihmishyväksyntää.
5. **Tekninen sulku (`04-done`) ja erillinen siivous:** Siirrä tehtävä omassa
   tehtäväjonossaan `04-done`-kansioon vasta, kun täsmärevisiolla on pysyvä
   riippumaton ihmishyväksyntänäyttö, `origin/main`-toimitus on varmennettu ja
   sulku on valtuutettu ([WORKFLOW.md](WORKFLOW.md), erottaen `TASK`-sulun
   projektin omista valmistumiskriteereistä). Säilytä työpuut ja haarat, ellei
   siivousta ole erikseen valtuutettu.
