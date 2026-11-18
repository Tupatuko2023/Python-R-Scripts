# AGENTS.md — DEAC-Frailty-Index

Nämä ohjeet koskevat vain `DEAC-Frailty-Index/`-aliprojektia. Hallinnollisessa
työnkulussa (tehtäväkohtainen kirjoitus- ja toimitusrajaus, PR-menettely,
`main`-toimitus, tekninen `04-done`-sulku ja siivous) noudata lisäksi repojuuren
[../SKILLS.md](../SKILLS.md)-, [../AGENTS.md](../AGENTS.md)- ja
[../config/steering.md](../config/steering.md)-sääntöjä; ne eivät koskaan
syrjäytä alla olevaa tieteellistä auktoriteettia tai `DATA_ROOT`-suojausta, ja
ratkaisematon ristiriita pysäyttää riippuvan toimenpiteen eikä anna lupaa valita
heikompaa sääntöä. Varmista työhakemisto ennen komentoja: aja aliprojektin
skriptit sen juuresta (`DEAC-Frailty-Index/`) ja valtuutetut repojuuren
hallinta-/rekisterikomennot saman eristetyn worktreen repojuuresta.

## Auktoriteetti ja ensimmäinen ajo

- Lue `docs/DEAC_HANDOVER.md` kokonaan ennen suunnittelua tai toteutusta.
- Tieteellisen hyväksynnän antaa väitöskirjan ihmisomistaja. Kanoninen tila on
  yksityisen `FOF-Dissertation-Project`-repon `METHODS_AND_SCORING.md` §3.1;
  handover on siitä johdettu ei-kanoninen tilannekuva.
- Jos handover, kanoninen METHODS tai toteutuksen oletukset ovat ristiriidassa,
  pysähdy ja vie asia omistajan ratkaistavaksi. Älä sovita ristiriitaa itse.
- Älä muuta tieteellisiä sääntöjä lähdedatan saatavuuden tai rakenteen vuoksi.
  FI22/KAAOS/EFI-legacy-koodi on korkeintaan teknistä vertailuaineistoa.
- Ensimmäinen varsinainen FIRA1-ajo on handoverin katselmointi ja toteutuksen
  feasibility-audit, ei pisteytyksen implementointi.

## Data ja toteutus

- `DATA_ROOT` ja osallistujatason data pysyvät repositorion ulkopuolella.
  Niitä saa lukea vasta erillisellä valtuutuksella; älä koskaan commitoi tai
  tulosta osallistujatason arvoja tai tunnisteita.
- Uusi toteutusskripti tarvitsee vastaavan testin repojuuren `Policy.md`-ohjeen
  mukaan. Käytä synteettisiä testisyötteitä ja pysähdy puuttuvaan skeemaan.
- Pidä raskas laskenta erillään raportoinnista ja renderöinnistä. Kirjaa
  myöhemmät artefaktit repojuuren manifesti- ja output-käytäntöjen mukaan.
- Pidä muutokset pieninä ja rajattuina tähän aliprojektiin. Etene vain
  tehtäväkortin hyväksytyissä kirjoituspoluissa ja sovittuun toimitusrajaan asti
  ([../SKILLS.md](../SKILLS.md)): älä puske suoraan `main`-haaraan, älä tee
  valtuuttamattomia etäoperaatioita tai mergeä ilman täsmärevision riippumatonta
  ihmishyväksyntää, ja pidä työpuun/haarojen siivous erillään toimituksesta.
