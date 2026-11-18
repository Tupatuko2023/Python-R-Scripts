# Työnkulkuohje — Fear-of-Falling

Hallinnollisessa työnkulussa (tehtäväkohtainen kirjoitus- ja toimitusrajaus,
PR-menettely, `main`-toimitus, tekninen `04-done`-sulku, projektirekisteri ja
siivous) noudatetaan repojuuren kanonista ohjetta [../SKILLS.md](../SKILLS.md)
sekä [../WORKFLOW.md](../WORKFLOW.md)- ja [../AGENTS.md](../AGENTS.md)-ohjeita.
Tämän aliprojektin oma tehtäväjono (`Fear-of-Falling/tasks/`) sekä sen tiukemmat
tutkimus-, tietosuoja-, `AUTH_SOURCE`/`DATA_ROOT`-, Kxx- ja `K18/QC`-suojaukset
([AGENTS.md](AGENTS.md), [GEMINI.md](GEMINI.md), [CLAUDE.md](CLAUDE.md),
[agent_workflow.md](agent_workflow.md)) säilyvät täysimääräisesti voimassa;
ratkaisematon ristiriita pysäyttää riippuvan toimenpiteen eikä anna lupaa valita
heikompaa sääntöä.

Aliprojektin analyysit ja tutkimus-QC ajetaan aina `Fear-of-Falling/`-työjuuresta;
valtuutetut repojuuren hallintaportit ja projektirekisterikomennot suoritetaan
saman eristetyn tehtäväworktreen repojuuressa rajatussa suorituskontekstissa
([SYSTEM_PROMPT_POWERSHELL7_S-FOF.md](SYSTEM_PROMPT_POWERSHELL7_S-FOF.md),
[SYSTEM_PROMPT_TERMUX_S-FOF.md](SYSTEM_PROMPT_TERMUX_S-FOF.md)).

## PR-, toimitus- ja sulkumenettely

1. **Eristetty tehtäväworktree ja varmennettu lähtö-SHA:** Älä puske suoraan
   `main`-haaraan äläkä vaihda tai pakota päächeckoutin haaraa tai paikallisia
   muutoksia. Perusta eristetty tehtäväworktree ja tehtävähaara `git fetch origin main`
   -haun jälkeen talteen otetusta ja varmennetusta täydestä commit-SHA:sta
   ([../SKILLS.md](../SKILLS.md)).
2. **Toteutus ja katselmointi (`03-review`):** Säilytä kortti jokaisessa
   siirrossa omassa tehtäväjonossaan (`Fear-of-Falling/tasks/01-ready/` ->
   `Fear-of-Falling/tasks/02-in-progress/` ->
   `Fear-of-Falling/tasks/03-review/`; aliprojektin kortti ei siirry päärepon
   `tasks/`-jonoon). Päivitä mahdollisen linkitetyn `PRJ-*.md`-rekisteritietueen
   tehtäväpolku samassa muutoksessa jokaisen siirron kanssa, suorita soveltuvat
   tarkistukset sekä `K18/QC`-päätösportti ([agent_workflow.md](agent_workflow.md))
   ja avaa/päivitä PR katselmointiin.
3. **Hyväksytty `main`-toimitus ja tekninen sulku (`04-done`):** Pelkkä
   `git push` ei oikeuta `04-done`-siirtoon. PR:n yhdistäminen ja tekninen
   `Fear-of-Falling/tasks/03-review/ -> Fear-of-Falling/tasks/04-done/` -sulku
   edellyttävät erillistä valtuutusta, [../SKILLS.md](../SKILLS.md):n mukaista
   täsmärevisioon kohdistuvaa pysyvää riippumatonta ihmishyväksyntänäyttöä sekä
   `origin/main`-toimituksen varmennusta. Linkitetyn `PRJ-*.md`-tietueen
   tehtäväpolku päivitetään samalla, mutta projektin `state`/`delivery` muutetaan
   tilaan `closed`/`delivered` vain, jos projektin omat valmistumiskriteerit
   täyttyvät.
4. **Siivouksen erottelu:** Toteutuksen valmistuminen, `main`-toimitus ja
   worktree-/haarasiivous kirjataan aina erikseen; työpuita ja haaroja ei
   poisteta ilman erillistä nimettyä siivousvaltuutusta ja
   [../SKILLS.md](../SKILLS.md):n ehdollista tarkistusketjua.
