# Työnkulkuohje — Electronic-Frailty-Index

Hallinnollisessa työnkulussa (tehtäväkohtainen kirjoitus- ja toimitusrajaus,
PR-menettely, `main`-toimitus, tekninen `04-done`-sulku ja siivous) noudatetaan
repojuuren kanonista ohjetta [../SKILLS.md](../SKILLS.md) sekä
[../WORKFLOW.md](../WORKFLOW.md)- ja [../AGENTS.md](../AGENTS.md)-ohjeita.
Tämän aliprojektin analyysi-, testi- ja dataturvasäännöt säilyvät voimassa;
aliprojektin skriptit ajetaan tarvittaessa omasta työjuurestaan ja päärepon
portti-/rekisterikomennot worktreen repojuuresta.

## PR-, toimitus- ja sulkumenettely

1. **Lähtötila ja haara:** Älä puske muutoksia suoraan `main`-haaraan äläkä
   päivitä likaista päächeckoutia väkisin. Perusta tehtävähaara (tai eristetty
   worktree) varmennetusta `origin/main`ista tehtävävaltuutuksen mukaisesti.
2. **Toteutus ja katselmointi (`03-review`):** Etene hyväksytyissä
   kirjoituspoluissa sovittuun toimitusrajaan asti, suorita soveltuvat
   tarkistukset, siirrä tehtäväkortti `03-review`-kansioon ja avaa tai päivitä PR
   katselmointiin (kun valtuutus kattaa pushin ja PR:n).
3. **Hyväksytty `main`-toimitus ja tekninen sulku (`04-done`):** Tehtävää ei saa
   siirtää `04-done`-kansioon pelkän `git push` -ajon perusteella. Merge ja
   `04-done`-sulku edellyttävät erillistä valtuutusta sekä
   [../SKILLS.md](../SKILLS.md):n mukaista täsmärevisioon kohdistuvaa pysyvää,
   riippumatonta ihmishyväksyntänäyttöä ja `origin/main`-toimituksen varmennusta.
4. **Siivouksen erottelu:** Työpuun ja haarojen säilytys on oletus toimituksen
   jälkeen; poistot tehdään vain erillisellä siivousvaltuutuksella ja kirjataan
   erillään `main`-toimituksesta.
