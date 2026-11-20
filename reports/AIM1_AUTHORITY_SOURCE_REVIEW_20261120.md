# AIM1 WP2: julkaisuoikeuden ja omistavan §3.1:n rajattu selvitys

Tarkistettu ja oikeudenhaltijan täsmävahvistuksella täydennetty 20.11.2026.
Tämä on lähde- ja oikeusrajauksen selvitys, ei AIM1-repon julkaisupäätös
eikä pisteytyksen tieteellinen hyväksyntä. WP1:n 17/17 synteettistä testiä
ja tavukopiot ovat aiempaa teknistä näyttöä; niitä ei ajettu uudelleen.

## Päätöstaulukko

| Avoin kysymys                             | Tarkistettu lähde                                                                                                                                                                                                          | Havainto                                                                                                                                                                                                                                                                                                                                                                                     | Tarvittava päätös tai puuttuva tieto                                                                                                                                                                  | Seuraava toimenpide                                                                                                               |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| Kahden Python-tiedoston MIT-soveltamisala | WP1:n provenienssi ja ihmisomistajan tässä keskustelussa 20.11.2026 oikeudenhaltijana antama täsmävahvistus; lähde- ja kohdetiedostojen SHA-256 tarkistettu uudelleen                                                      | `deac_index.py` (`c3fe94b631d488a5c5923ce4f31edca866b435464b8e6ce986b5e07c568593d7`) ja `test_deac_index.py` (`396b798f73aced664deb0479a495bc2d9e8febb825bfc9dc5177b71e9ead1713`) saa sisällyttää AIM1-kohderepoon MIT-lisenssillä. Vahvistus koskee näitä täsmäversioita.                                                                                                                   | Säilytä lähteen MIT-lisenssiteksti ja nykyiset tekijänoikeus- ja tekijämerkinnät. Tarkistetuissa Python-tiedostoissa ei ollut erillistä merkintää; lähteen `LICENSE` sisältää tekijänoikeusmerkinnän. | Pidä lisenssiteksti ennallaan. Jos myöhemmin löytyy muun oikeudenhaltijan merkintä tai erillinen ehto, yksilöi se ennen muutosta. |
| Uuden AIM1-repon julkaisu                 | Sama oikeudenhaltijan täsmävahvistus sekä paikallisen kohderepon WP1-provenienssi                                                                                                                                          | Tiedostojen MIT-sisällytysoikeus on vahvistettu. Vahvistus rajaa AIM1-repon julkaisemisen nimenomaisesti ulkopuolelle.                                                                                                                                                                                                                                                                       | AIM1:n ihmisomistajan erillinen julkaisupäätös ja toimitettavan sisällön tarkistus.                                                                                                                   | Pidä kohderepo paikallisena.                                                                                                      |
| Nykyinen omistava DEAC §3.1               | DMA1-lisäosan mukana oleva `references/METHODS_AND_SCORING.md`, VERSION `0.4.1-draft`, SHA-256 `192e59c6ce3d4f86cc1816e71ecbe68cb33205acd23508147c9a521e5411adad`; PRS:n `DEAC-Frailty-Index/docs/DEAC_HANDOVER.md` v1.2.0 | Luettu DMA1-kopio on tiedostotasolla DRAFT ja §3.1:ssä sääntötason hyväksyntämerkintä D-005…D-009. Handover viittaa myöhempään, eri hashin omistavaan §3.1-versioon (`4fd2ddf3d19268fef09b90aa0d7ad8095dadb417b2601238fcfbebf1ec7aaaef`) sekä D-010/D-012-täsmennyksiin. Myöhemmän version tekstiä ei saatu luettua. DMA1-kopion lähdecommittia ei voitu yksilöidä paketoidusta tiedostosta. | Nykyisen omistavan §3.1:n teksti, suhteellinen lähdepolku, versio/commit, SHA-256 ja tieto siitä, korvaako se mainitut versiot.                                                                       | Lähetä alla oleva täsmäpyyntö ihmisomistajalle tai DMA1-lähteen ylläpitäjälle erillisellä valtuutuksella.                         |
| §3.1:n hyväksyntänäyttö                   | DMA1:n `DECISION_LOG.md` kirjaa D-005…D-009 ihmisomistajan 22.9.2026 päätöksiksi ja `SUPERSEDED_BY: none` paikallisessa versiossa; PRS:n MOI-tehtävä ja handover viittaavat D-010/D-012:een                                | Päätösloki on päätöshistorian koonti. Alkuperäistä omistajan hyväksyntäpakettia tai myöhemmän version korvaavuusketjua ei tässä tarkistuksessa luettu. PR #176:n omistajamerge todentaa MOI-tehtävän hyväksynnän, ei yksin koko nykyistä §3.1:tä.                                                                                                                                            | Alkuperäisten omistajapäätösten pysyvät viitteet ja nykyisen §3.1-version soveltuvuuden sekä korvaavuuden vahvistus.                                                                                  | Pidä nykyisen pisteytyksen tieteellinen vastaavuus `NEEDS_VERIFICATION`-tilassa.                                                  |

## Myöhemmän omistavan version paikannus 20.11.2026

PRS:n `DEAC-Frailty-Index/docs/DEAC_HANDOVER.md` v1.2.0 (commit
`78449a44356020f584190a2586d5baec41d01dee`, 2.10.2026) ilmoittaa
omistavan `METHODS_AND_SCORING.md`-tiedoston **koko tiedoston** SHA-256:ksi
`4fd2ddf3d19268fef09b90aa0d7ad8095dadb417b2601238fcfbebf1ec7aaaef`
ja päätöslokin hashiksi
`131dab0920ed047422b5f228980489bab29973e382b8a29bb6909fe6db82c480`.
FOF-Dissertation-Project-repon 8.11.2026 menetelmätehtävä nimeää
omistavan lähteen suhteelliseksi poluksi
`GPT/(DMA1) Dissertation Meeting Analyst/knowledge/METHODS_AND_SCORING.md`,
versioksi `0.5.2-draft` (päivitetty 2.10.2026) ja §3.1:n kohdaksi rivit
155–172. Tehtävä kertoo primäärisen työpuun olleen sen lukulähde.
Handoverin ja tehtävän metatiedot ovat keskenään yhteneviä mutta johdettuja.
Ne eivät yksilöi omistavan tiedoston Git-committia eivätkä tarjoa sen tavuja.

Täsmäpolkua ei löytynyt FOF-Dissertation-Project-repon `main`-haaran
Git-puusta eikä saman polun commit-historiasta; paikallisessa PRS:n koko
Git-historiassa ei ollut `METHODS_AND_SCORING.md`-tiedostoa. Saatavilla
olevista paikallisista nimiosumista löytyi vain aiempi `0.4.1-draft`-kopio
(SHA-256 `192e59c6ce3d4f86cc1816e71ecbe68cb33205acd23508147c9a521e5411adad`).
Myöhemmän version omistavaa sisältöä ja hyväksyntä-/korvaavuusnäyttöä ei
voitu tarkistaa. Täsmäpolun ja hashin löytyminen johdetusta kortista ei
muuta tieteellisen vastaavuuden tilaa `NEEDS_VERIFICATION`.

## Yksityisen lähdetoimituksen vastaanotto 20.11.2026

Erillisen yksityisen toimituksen manifesti (SHA-256
`a02d4e9401cce9ff70a75c5dfd842640b3beb596f22ee655e55cf1eea162c49d`)
ja kaikki sen kuusi lähde- tai ohjetiedostoa tarkistettiin ilmoitettuihin
SHA-256-arvoihin. Seitsemän tiedoston tavukopio varmennettiin pysyvässä
yksityisessä säilytyksessä. Vastaanotto-ohje on käsittelyohje, ei uusi
tutkimuspäätös tai hyväksyntä.

| Lähde                                                                                                                                           | Nyt varmennettu näyttö                                                                                                                           | Auktoriteettiraja                                                                                                           |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| `METHODS_AND_SCORING.md` 0.4.1-draft, SHA-256 `192e59c6ce3d4f86cc1816e71ecbe68cb33205acd23508147c9a521e5411adad`                                | Historiallisen §3.1:n sääntötason D-005…D-009-hyväksyntämerkinnät ovat itse luonnoksessa; koko tiedosto on DRAFT.                                | Ei todista myöhempää tai nykyistä omistavaa sääntöä.                                                                        |
| `DECISION_LOG.md` 1.2.1:n D-005…D-009-otteet; lähteen koko tiedoston SHA-256 `57d453c051aa6d048ce7ae457369a9dd96350b5e7e0ce2f4e174c4c8352463dc` | Historialliset päätösmerkinnät kirjaavat 22.9.2026 ihmisomistajan hyväksynnät ja nimeävät niiden alkuperäiset hyväksyntäpaketit.                 | Alkuperäisiä päivättyjä hyväksyntäpaketteja ei toimitettu; `SUPERSEDED_BY: none` kuvaa vain tämän vanhan lokiversion tilaa. |
| PRS:n DEAC-handover 1.2.0 ja D-012:n valmis tehtävä                                                                                             | Handover raportoi D-010:n ja D-012:n myöhemmät täsmennykset. D-012-tehtävä ja PR #176:n omistajamerge tukevat rajattua MOI-tulkinnan toteutusta. | Handover on johdettu; PR:n hyväksyntä ei hyväksy koko nykyistä §3.1:tä eikä osoita D-010:n alkuperäistä päätöstä.           |
| `deac_index.py`, SHA-256 `c3fe94b631d488a5c5923ce4f31edca866b435464b8e6ce986b5e07c568593d7`                                                     | Toimitettu vertailumoduuli vastaa WP1:n tavukopiota.                                                                                             | Toteutus on vertailukohde, ei menetelmäsäännön hyväksyntä.                                                                  |

D-011:n alkuperäistä päätöstä, D-010:n ja D-012:n alkuperäisiä
hyväksyntämerkintöjä, myöhempää päätöslokia eikä 0.5.2-draft-version tavuja
ole toimituksessa. Vanhan ja myöhemmän koko tiedoston hashit eroavat, mutta
§3.1:n todellista tekstieroa ei voi tarkistaa ilman myöhemmän version tavuja.
Nykyisen omistavan säännön tila säilyy `AUTHORITY_UNRESOLVED` ja sen
vastaavuus toteutukseen `NEEDS_VERIFICATION`.

## Täsmäversion ja ilmoitusten varmennus

Sekä alkuperäisen PRS-lähteen että paikallisen AIM1-kohteen kahden Python-tiedoston
SHA-256 täsmäsivät yllä annettuihin arvoihin. Kohteen `LICENSE` on lähteen
MIT-lisenssin tavukopio, SHA-256
`9376874055d4aee919c382209a5906af10b52cc0e17590bf28af5ee70752c169`;
sen merkintä on `Copyright (c) 2025 Tomi Korpi`. Kummastakaan tarkistetusta
Python-tiedostosta ei löytynyt muuta lisenssi-, tekijänoikeus- tai
tekijämerkintää. WP1:n aiemmin havaitsema npm-paketin `ISC`-metadata jää
pakettikohtaiseksi havainnoksi; tämän keskustelun oikeudenhaltijavahvistus
ratkaisee näiden kahden täsmäversion AIM1-repoon sisällyttämisen MIT:llä.
Vahvistukselle ei ole tässä työssä erillistä pysyvää GitHub-viitettä;
ihmisomistajan keskustelussa antama päätös ja yllä olevat hashit on kirjattu
provenienssiksi. Tiedostoja tai lisenssejä ei muutettu.

## Rajattu §3.1–koodi-vertailu

Vertailukoodi on paikallisen AIM1-kohderepon
`DEAC-Frailty-Index/src/deac_index.py`, SHA-256
`c3fe94b631d488a5c5923ce4f31edca866b435464b8e6ce986b5e07c568593d7`.
Se vastaa tavutasolla WP1:n PRS-lähdettä. Vertailun sääntölähde on yllä
mainittu luettu **vanhempi** `0.4.1-draft`-kopio; tästä ei päätellä
ajantasaisen §3.1:n vastaavuutta. Uusi toimitus ei muuttanut tämän jo tehdyn
vertailun lähdeversiota. Handoverin D-010/D-012-täsmennykset koskevat
komponenttien ylävirran pisteytystä ja luokittelua; kokoajamoduuli vastaanottaa
vain valmiiksi normalisoidut arvot.

| Kohta                          | Havainto vanhempaan §3.1-kopioon nähden                                                                                                                                                                                                                    | Rajaus                                                                                          |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Komponenttijoukko              | Moduulin 20 nimettyä paikkaa vastaavat lähteen 20 komponentin rakennetta, mukaan lukien yksi neurologinen komponentti ja FOF.                                                                                                                              | Moduuli ei määritä lähdemuuttujia eikä pisteytä komponentteja.                                  |
| Kelpoisuus ja indeksi          | Toteutus hyväksyy vähintään 80 % relevanttien paikkojen havaituista pisteistä, sallii tasan 80 % ja jakaa havaittujen pisteiden summan havaittujen määrällä. Tämä vastaa vanhemman tekstin laskentakuvausta.                                               | Luettu lähde ei yksilöi kaikkia teknisiä reunatapauksia, kuten nollaa relevanttia komponenttia. |
| Puuttuva ja ei-sovellettava    | `None` jää relevantiksi mutta havaitsemattomaksi; `NOT_APPLICABLE` jätetään pois relevanttien joukosta ja pisteiden nimittäjästä. Tämä on vanhemman tekstin relevanttien komponenttien ja ei-sovellettavan poisjätön kanssa rakenteellisesti yhteensopiva. | Sovitin ratkaisee, mikä tila on aidosti ei-sovellettava. Sen oikeellisuutta ei tarkistettu.     |
| Suoriutumattomuus ja pisteytys | Moduuli ottaa vain valmiiksi normalisoidun 0–1-arvon. Lähteen fyysisen suoriutumattomuuden luokittelu, MOI, mittausvalinta ja muut komponenttipisteet jäävät upstream-koodille.                                                                            | Ei todettua ristiriitaa kokoajassa; upstream-vastaavuus ja uudempi §3.1 jäävät varmistamatta.   |

## Lähettämätön täsmäpyyntö

Pyydän AIM1:n ihmisomistajalta tai DMA1:n omistavan lähteen ylläpitäjältä
nykyisen omistavan `METHODS_AND_SCORING.md` §3.1:n soveltuvan tekstin tai
luettavan täsmäversion. Tunnettu sijaintiviite on
`GPT/(DMA1) Dissertation Meeting Analyst/knowledge/METHODS_AND_SCORING.md`
FOF-Dissertation-Project-projektin primäärisessä työpuussa. Sen 8.11.2026
tehtävä kuvaa version `0.5.2-draft`, päivityspäivän 2.10.2026, rivit 155–172
ja koko tiedoston SHA-256:n
`4fd2ddf3d19268fef09b90aa0d7ad8095dadb417b2601238fcfbebf1ec7aaaef`.
Toimittakaa lähderepo tai -paketti, suhteellinen polku, version/commitin
tunnus jos tiedosto on versionhallinnassa, nykyinen koko tiedoston SHA-256,
soveltuva §3.1-teksti sekä omistajan hyväksyntäviitteet D-005…D-012:n
osalta. Kertokaa, onko mainittu 0.5.2-versio edelleen voimassa vai mikä
päätös korvasi sen, ja erottakaa koko tiedoston hashmuutos varsinaisesta
§3.1:n sääntömuutoksesta. Vertailtava indeksikokoaja on
`DEAC-Frailty-Index/src/deac_index.py`, SHA-256
`c3fe94b631d488a5c5923ce4f31edca866b435464b8e6ce986b5e07c568593d7`.
Pyydän erityisesti vahvistamaan, mitkä kohdat koskevat valmiiksi
normalisoitujen komponenttien kokoamista ja mitkä niiden upstream-pisteytystä.
Pyyntöä ei lähetetty tässä työpaketissa.

## Tarkistusraja

FOF-Dissertation-Project-repon `main` (havaittu commit
`9e3b06a517ca2c9cd9175f94873750e156af4841`) ei sisällä omistavaa
`METHODS_AND_SCORING.md`-tiedostoa tavallisena Git-puutiedostona. Sen
8.11.2026 AIM1-menetelmäkortti raportoi erillisestä omistavasta lähteestä;
kortti ja handover ovat johdettuja viitteitä, eivät korvaa itse lähdettä.
Yksityistä §3.1-tekstiä, hyväksyntäpakettia, absoluuttisia paikallisia polkuja
tai osallistujatietoja ei sisällytetty tähän raporttiin.

## Validointi

Ennen täydennyscommittia aiempi HEAD
`31da2eddf51e6a2b38c2dbdc05c4b087f3447af5` tallennettiin yksityiseen,
tilapäisestä työpuusta erilliseen pysyvään säilytyshakemistoon
täyden historian Git-bundlena `aim1-authority-31da2e.bundle` (SHA-256
`ce4cc4ed54cd9a9781064f57e7c0ced061fbd7e8a63c823bf9ca771c3d74d6de`).
Bundle avattiin erilliseen tarkistusrepoon: palautettu HEAD täsmäsi ja
`git fsck --connectivity-only` onnistui. Täydennetyn revision vastaava
säilytyskuitti on kirjattu yksityiseen manifestiin; yksityistä
absoluuttista polkua ei kirjata julkiseen raporttiin.

- Projektirekisterin lähdekuvauksen SHA-256 pysyi samana; CSV generoitiin,
  `render_projects_csv.py --check` ja `git check-ignore` läpäisivät.
- `tools/run-gates.sh --mode pre-push --smoke` läpäisi. Analyysi- ja QC-ajot
  eivät sovellu tähän dokumentaatiotehtävään.
- Rekisterityökalun 62 yksikkötestistä neljä pysähtyi tämän Termux-Pythonin
  puuttuvaan `os.link`-rajapintaan. Muut 58 eivät raportoineet virhettä.
  Tämä ei ole uuden projektitietueen validointivirhe eikä sarjaa merkitä
  läpäistyksi. Rekisterin oma CSV-`--check` läpäisi.
- Neljä juuri tähän rajapintaan pysähtynyttä testiä ajettiin erikseen
  Debian-ympäristön `/usr/bin/python3`-tulkilla (Python 3.13.5,
  `os.link` käytettävissä): `4/4 PASS`, paluukoodi 0. Komento oli
  `python3 -B -m unittest -v test_render_projects_csv.GitGateTests.test_ignored_hard_link_to_tracked_source_is_rejected test_render_projects_csv.SafePublicationTests.test_alias_created_during_write_is_rechecked_before_replace test_render_projects_csv.SafePublicationTests.test_atomic_replace_does_not_modify_other_hard_link test_render_projects_csv.SafePublicationTests.test_hard_link_to_source_is_rejected`
  hakemistossa `tools/project_registry/tests`. Tämä täydentää neljän
  ympäristövirheen näyttöä; koko 62 testin sarjaa ei ajettu Debianissa.
