# AIM1: julkaisuoikeuden ja omistavan §3.1-lähteen selvitys

## Valtuutus ja rajaus

Ihmisomistaja valtuutti 20.11.2026 uuden rajatun PRJ-AIM1-REPO-työpaketin:
kahden WP1:ssä siirretyn Python-tiedoston julkaisuoikeuden puuttuvan
vahvistuksen yksilöinti, nykyisen omistavan `METHODS_AND_SCORING.md` §3.1:n
paikannus ja tarvittaessa lukupohjainen vertailu `deac_index.py`-moduuliin.
WP1:n tehtäviä ei avata uudelleen. Osallistujadataa ei ajeta, pisteytystä tai
lisenssejä ei muuteta, AIM1-kohderepoa ei julkaista eikä viestejä lähetetä.

## Sallitut kirjoituspolut ja toimitusraja

- Tämä kortti: `tasks/01-ready/`, `tasks/02-in-progress/` ja
  `tasks/03-review/AIM1_AUTHORITY_SOURCE_REVIEW_20261120.md`.
- `reports/AIM1_AUTHORITY_SOURCE_REVIEW_20261120.md`.
- `docs/governance/project_registry/PRJ-AIM1-REPO.md`.
- Ohjeen generoima, ignoroitu `tools/project_registry/outputs/projects.csv`.
- Toimitusraja: paikallinen katselmoitava commit. Ei pushia, PR:ää, mergeä,
  `04-done`-siirtoa eikä työpuun siivousta tässä valtuutuksessa.

## Valmistumiskriteerit

- WP1:n lisenssiselvityksen perusteella yksilöidään puuttuva vahvistus,
  oikea vastaaja ja erillinen AIM1-kohderepon julkaisupäätös.
- Omistavan §3.1:n saatavilla olevat versiot, hashit ja päätösviitteet
  erotetaan; puuttuva ajantasainen lähde rajataan täsmäpyyntöön.
- Saatavilla oleva §3.1 verrataan indeksikokoajan toteutukseen vain sen
  todistusarvon rajoissa. Koodia ei muuteta.
- Yksityisiä lähdetekstejä tai paikallisia absoluuttisia polkuja ei lisätä
  julkiseen raporttiin. Projektirekisteri ja CSV päivitetään ohjeen mukaan;
  dokumentti- ja rekisteriportit ajetaan.

## Loki

- 2026-11-20: Kortti luotu ihmisomistajan nimenomaisesta toimeksiannosta
  erilliseen työpuuhun. WP1:n päättynyt ketju säilyy ennallaan.
- 2026-11-20T04:05:03Z: Kortti siirrettiin `02-in-progress`-tilaan.
  Lähderepon WP1-oikeusselvitystä käytettiin lähtönä. DMA1:n luettu §3.1-kopio
  on `0.4.1-draft` eikä vastaa myöhemmän handoverin ilmoittamaa hashia;
  nykyistä omistavaa tekstiä ja alkuperäisiä päätöspaketteja ei saatu
  varmennettua. Rajattu vanhemman lähteen ja kokoajan vertailu sekä
  lähettämätön täsmäpyyntö kirjattiin raporttiin. Osallistujadataa ei luettu.
- 2026-11-20: Projektirekisterin kirjoitussuoja läpäisi ennen muutosta;
  lähdekuvauksen hash pysyi samana. CSV generoitiin ohjeen mukaan ja
  `--check`, ignore-tarkistus sekä `git diff --check` läpäisivät.
  Tutkimus- ja QC-ajot: NOT APPLICABLE (vain dokumentaatiota).
- 2026-11-20: Repojuuren `tools/run-gates.sh --mode pre-push --smoke`
  läpäisi. Rekisterin 62 yksikkötestistä neljä ei päässyt suoritukseen
  Termux-Pythonin `os.link`-puutteen vuoksi; 58 muuta ei raportoinut virhettä.
  Laajempaa testisarjaa ei merkitä PASS-tilaan. Tehtävän rajattu raportti,
  rekisteri ja toimiva CSV-tarkistus ovat valmiit ihmiskatselmointiin.
- 2026-11-20: Kortti siirrettiin `03-review`-tilaan ja rekisterin
  tehtäväviite päivitettiin samassa työvaiheessa. Ihmisomistajan hyväksyntää,
  `04-done`-siirtoa tai etätoimitusta ei kirjattu.
- 2026-11-20T04:40:48Z: Ihmisomistaja vahvisti tässä keskustelussa
  oikeudenhaltijana `deac_index.py`-version SHA-256
  `c3fe94b631d488a5c5923ce4f31edca866b435464b8e6ce986b5e07c568593d7`
  ja `test_deac_index.py`-version SHA-256
  `396b798f73aced664deb0479a495bc2d9e8febb825bfc9dc5177b71e9ead1713`
  MIT-sisällytysoikeuden AIM1-kohderepoon. Lähde- ja kohdehashit sekä
  MIT-lisenssin tavuvastaavuus tarkistettiin; kummassakaan
  Python-tiedostossa ei ollut erillisiä oikeusmerkintöjä.
  Vahvistus ei ole AIM1-repon julkaisuvaltuutus eikä tämän
  `03-review`-tehtävän erillinen hyväksyntä.
- 2026-11-20: Oikeusvahvistuksen kirjaamisen jälkeen rekisterin
  lähdekuvauksen hash, CSV-generointi ja `--check`, ignore-tarkistus,
  `git diff --check` sekä repojuuren pre-push-smoke-portti läpäisivät.
  Aiempaa ympäristöstä johtuvaa `os.link`-testirajoitusta ei muutettu.
- 2026-11-20: Jatkoselvityksessä handoverin myöhemmän omistavan version
  koko tiedoston hash ja projektin menetelmäkortin täsmäpolku sekä
  `0.5.2-draft`-versioviite kohdistettiin. Omistavaa tekstiä tai
  Git-committia ei löytynyt käytettävissä olevasta main-historiasta tai
  paikallisista kopioista; tieteellinen tila pysyy `NEEDS_VERIFICATION`.
  Raporttiin täydennettiin lähettämätön täsmäpyyntö. Neljä aiemmin
  `os.link`-puutteeseen pysähtynyttä testiä ajettiin Debian-Pythonilla:
  4/4 PASS. Koko 62 testin sarjaa ei ajettu siellä uudelleen.
- 2026-11-20: Aiempi HEAD `31da2eddf51e6a2b38c2dbdc05c4b087f3447af5`
  säilytettiin yksityisessä, tilapäisestä työpuusta erillisessä täyden
  historian Git-bundlessa. Erillinen tarkistusrepo palautti saman HEADin
  ja läpäisi Gitin yhteystarkistuksen. Täydennyscommitin säilytys
  varmennettiin erikseen commitin jälkeen yksityisessä säilytysmanifestissa.
- 2026-11-20: Ihmisomistaja valtuutti tämän `03-review`-tehtävän rajatun
  PRS-dokumentaatiotoimituksen pushin ja PR:n avaamisen. Alkuperäinen
  paikallisen commitin toimitusraja yllä on historiallinen; tämä uusi
  valtuutus koskee vain raporttia, tehtäväkorttia ja projektirekisteriä.
  AIM1-kohderepon julkaisu, merge ja `04-done`-siirto jäävät ulkopuolelle.
