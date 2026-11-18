# Työnkulkuohje — Fear-of-Falling

Hallinnollisessa työnkulussa (tehtäväkohtainen kirjoitus- ja toimitusrajaus,
PR-menettely, `main`-toimitus, tekninen `04-done`-sulku, projektirekisteri ja
siivous) noudatetaan repojuuren kanonista ohjetta [../SKILLS.md](../SKILLS.md)
sekä [../WORKFLOW.md](../WORKFLOW.md)- ja [../AGENTS.md](../AGENTS.md)-ohjeita.
Tämän aliprojektin oma tehtäväjono (`Fear-of-Falling/tasks/`) sekä sen tiukemmat
tutkimus-, tietosuoja-, `AUTH_SOURCE`/`DATA_ROOT`-, Kxx- ja `K18/QC`-suojaukset
([AGENTS.md](AGENTS.md), [GEMINI.md](GEMINI.md), [CLAUDE.md](CLAUDE.md),
[agent_workflow.md](agent_workflow.md)) säilyvät täysimääräisesti voimassa.
Aliprojektin analyysiskriptit ajetaan `Fear-of-Falling/`-hakemistosta ja päärepon
portti-/rekisterikomennot worktreen repojuuresta.

## PR-, toimitus- ja sulkumenettely

1. **Lähtötila ja haara:** Älä puske suoraan `main`-haaraan äläkä päivitä
   likaista päächeckoutia väkisin. Perusta tehtävähaara tai eristetty worktree
   varmennetusta `origin/main`ista tehtävävaltuutuksen puitteissa.
2. **Toteutus ja katselmointi (`03-review`):** Toteuta vain hyväksytyt
   kirjoituspolut, suorita soveltuvat tarkistukset ja `K18/QC`-päätösportti
   ([agent_workflow.md](agent_workflow.md)), siirrä tehtäväkortti
   `Fear-of-Falling/tasks/03-review/`-kansioon (tai päärepon tehtävässä päärepon
   `tasks/03-review/`-kansioon) ja avaa/päivitä PR katselmointiin.
3. **Hyväksytty `main`-toimitus ja tekninen sulku (`04-done`):** Pelkkä
   `git push` ei oikeuta `04-done`-siirtoon. PR:n yhdistäminen ja tekninen
   `03-review -> 04-done` -sulku edellyttävät erillistä valtuutusta,
   [../SKILLS.md](../SKILLS.md):n mukaista täsmärevisioon kohdistuvaa pysyvää
   riippumatonta ihmishyväksyntänäyttöä sekä `origin/main`-toimituksen
   varmennusta.
4. **Siivouksen erottelu:** Toteutuksen valmistuminen, `main`-toimitus ja
   worktree-/haarasiivous kirjataan aina erikseen; työpuita ja haaroja ei
   poisteta ilman erillistä siivousvaltuutusta.
