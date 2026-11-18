# Työnkulkuohje — Electronic-Frailty-Index

Hallinnollisessa työnkulussa (tehtäväkohtainen kirjoitus- ja toimitusrajaus,
PR-menettely, `main`-toimitus, tekninen `04-done`-sulku, projektirekisteri ja
siivous) noudatetaan repojuuren kanonista ohjetta [../SKILLS.md](../SKILLS.md)
sekä [../WORKFLOW.md](../WORKFLOW.md)- ja [../AGENTS.md](../AGENTS.md)-ohjeita.
Tämän aliprojektin analyysi-, testi- ja dataturvasäännöt säilyvät voimassa, ja
ratkaisematon ohjeristiriita pysäyttää riippuvan toimenpiteen eikä anna lupaa
valita heikompaa sääntöä. Aliprojektin skriptit ajetaan tarvittaessa omasta
työjuurestaan ja valtuutetut repojuuren hallinta-/rekisterikomennot saman
eristetyn worktreen repojuuresta.

## PR-, toimitus- ja sulkumenettely

1. **Eristetty tehtäväworktree ja varmennettu lähtö-SHA:** Älä puske muutoksia
   suoraan `main`-haaraan äläkä vaihda tai pakota päächeckoutin haaraa tai
   paikallisia muutoksia. Perusta eristetty tehtäväworktree ja tehtävähaara
   `git fetch origin main` -haun jälkeen talteen otetusta ja varmennetusta
   täydestä commit-SHA:sta ([../SKILLS.md](../SKILLS.md)).
2. **Toteutus ja katselmointi (`03-review`):** Etene hyväksytyissä
   kirjoituspoluissa sovittuun toimitusrajaan asti, suorita muutokseen
   soveltuvat tarkistukset (puhdas dokumentaatiomuutos ei käynnistä suojatun
   datan lukua), siirrä tehtäväkortti sen omassa tehtäväjonossa
   `03-review`-kansioon (päivittäen samalla mahdollisen linkitetyn
   `PRJ-*.md`-tietueen tehtäväpolun) ja avaa tai päivitä PR katselmointiin.
3. **Hyväksytty `main`-toimitus ja tekninen sulku (`04-done`):** Tehtävää ei saa
   siirtää `04-done`-kansioon pelkän `git push` -ajon perusteella. Merge ja
   `04-done`-sulku edellyttävät erillistä valtuutusta sekä
   [../SKILLS.md](../SKILLS.md):n mukaista täsmärevisioon kohdistuvaa pysyvää,
   riippumatonta ihmishyväksyntänäyttöä ja `origin/main`-toimituksen varmennusta
   (erottaen `TASK`-sulun projektin omista valmistumiskriteereistä).
4. **Siivouksen erottelu:** Työpuun ja haarojen säilytys on oletus toimituksen
   jälkeen; poistot tehdään vain erillisellä nimetyllä siivousvaltuutuksella ja
   [../SKILLS.md](../SKILLS.md):n ehdollisella menettelyllä erillään
   `main`-toimituksesta.
