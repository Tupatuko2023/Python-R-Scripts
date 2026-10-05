# Tehtävä: DEAC v2:n K40-lähdesidonta ja rajattu aineistoajo

## Tila

04-done — aloitettu 2026-10-03; katselmoitu ja hyväksytty 2026-10-05

## Tavoite

Toteuta ja validoi DEAC v2:n runtime-lähdesidonta hyväksytyn K40-lähdekartan,
DEAC-handoverin sekä tässä tehtävässä kirjatun Ownerin soveltamisohjeen mukaan.
Käytä vain paikallisesti hyväksyttyä lähtötilanteen työkirjasnapshotia. Tämä
tehtävä ei valtuuta muita lähteitä, kohortteja tai analyysejä.

## Hyväksytty soveltamisohje

Owner vahvisti 2026-10-02 seuraavat kolme sääntöä tässä keskustelussa
2026-10-03:

1. Käden tai jalan mitatuista tuloksista käytetään ainoaa numeerista tulosta,
   jos vain yksi puoli on mitattu; jos molemmat on mitattu, valitaan parempi
   mitattu tulos.
2. Fyysisen testin E ilman varmennettua syytä ja E1 käsitellään puuttuvana.
   Varmennettu fyysinen/toiminnallinen kyvyttömyys saa vajeen 1. Mitattu
   puristusluokka 0 pysyy kelvollisena tuloksena ja saa vajeen 1.
3. Puuttuva 10 m aika apuvälineluokasta riippumatta on puuttuva tulos.
   Apuvälineluokka yksin ei osoita kyvyttömyyttä. Erikseen varmennettu
   fyysinen/toiminnallinen kyvyttömyys saa vajeen 1.

Puuttuva komponentti ei kuulu havaittujen komponenttien nimittäjään.
Handover 1.2.0:n 80 %:n kattavuussääntö ja kaikki muut komponenttisäännöt
pysyvät ennallaan. Tieteelliset kysymykset B1/B2 eivät kuulu tehtävään.

## Tietosuoja ja lähderajat

- Aineiston käsittely on Ownerin erikseen tässä toimeksiannossa valtuuttama,
  rajattu Termux-ajo; tämä ei ole yleinen lupa muihin DATA_ROOT-ajoihin.
- Älä tulosta, kopioi, commitoi tai raportoi osallistujarivejä, tunnisteita,
  suojattuja otsikoita tai koodistoja. Älä tallenna osallistujatason välituloksia
  repositorioon.
- Pidä täsmällinen runtime-kenttäkartta repo-ulkopuolella ja suojaa se
  käyttöjärjestelmän tiedosto-oikeuksilla.
- Raportoi vain koosteet, virheiden lukumäärät/luokat ja kattavuus. Älä julkaise
  pienisoluisia tai tunnistettavia alaryhmätuloksia.
- Yksityisen DMA1-päätösrekisterin ja METHODS-omistajan synkronointi on
  myöhempi erillinen työ; älä väitä sitä tehdyksi.

## Toteutus ja validointi

1. Sido vain lähdekartassa yksiselitteisesti vahvistetut kentät ja koodit
   nykyiseen 20 komponentin adapteriin. Epäselvä sidonta pysäyttää kyseisen
   arvon/komponentin fail-closed-periaatteella; älä arvaa.
2. Lisää synteettiset testit puuttuvuudelle, ei-sovellu-tilalle, testikohtaisille
   E/E1-tapauksille, kahden puolen mittauksille, MOI:n ikäpisteiden kertapoistolle,
   nopeusmuunnokselle, 20 komponentin järjestykselle ja 80 %:n rajalle.
3. Aja soveltuvat testit ja pakollinen repository-gate ennen aineistoajoa.
4. Aja vasta testien jälkeen rajattu paikallinen DEAC v2 -laskenta hyväksytyllä
   lähtötilanteen kohortilla. Säilytä osallistujatason tulos vain suojatussa,
   repositorion ulkopuolisessa sijainnissa. Raportoi Ownerille koosteet ja
   kattavuus, älä raakoja arvoja.

## Definition of Done

- Jokainen 20 komponentin runtime-sidonta on lähteeseen jäljitettävä tai
  eksplisiittisesti merkitty estetyksi; mitään sidontaa ei ole päätelty
  osallistuja-arvoista.
- Kolme Ownerin hyväksymää reunasääntöä toteutuu synteettisissä testeissä.
- DEAC-kokoaja noudattaa 80 %:n kattavuus- ja havaittujen komponenttien
  nimittäjäsääntöä.
- Testit ja soveltuva gate läpäisevät; suojatun ajon tulokset eivät sisällä
  osallistujatason tietoja.
- Paikallinen päätöslisä kuvaa hyväksynnän provenienssin ja toteaa
  yksityisen DMA1/METHODS-synkronoinnin olevan vielä tekemättä.

## Loki

- 2026-10-03: Orkestroijan nimenomaisesta käskystä tehtävä luotu 01-readyyn.
- 2026-10-03: Siirretty 02-in-progressiin ja toteutus aloitettu erillisessä,
  puhtaassa työpuussa.
- 2026-10-03: 277 synteettistä DEAC-testiä läpäisi; `tools/run-gates.sh
  --mode pre-push --smoke` läpäisi. Testit kattoivat sivuvalinnan, E/E1- ja
  kyvyttömyystulkinnan sekä kävelyajan ja apuvälinemetatiedon erottelun.
- 2026-10-03: Aineistoajo estetty fail-closed: varmennetun kartan 20
  komponenttirivin ehdokkaille ei löytynyt yksiselitteisiä täsmäyksiä
  työkirjan tarkistetun otsikkorivin kanssa. Tarkkaa lähdesidontaa ei arvata;
  tarvitaan kenttäkohtainen alias-/versiokartta tai vahvistettu lähdeskeema.
- 2026-10-03: Työkirjan ja suojatun K40-kartan tiivisteet vastasivat aiemmin
  hyväksyttyjä identiteettejä. Lähde-esityksen tiivistekin täsmäsi; sen tekstiä
  tai esimerkkejä ei poimittu. Identiteettien täsmääminen ei ratkaissut
  sarakesidonnan yksikäsitteisyyttä.
- 2026-10-03: Repo-ulkopuolinen 20-rivinen alias-katselmointikartta tuotettiin
  kahdesta metadata-rivistä ja inventaariosta käyttöoikeuksin 0600.
  Otsake–selite-parit ovat yksikäsitteisiä; kartan leksikaalisista
  ehdokkaista 11 komponenttiriviä oli yksittäisiä ja 9 moniosaisia (neuro-
  loginen yhdistelmä tarvitsee kolme osakenttää). MOI:n lähtöiälle ei löytynyt
  otsake-/seliteriviltä semanttista ehdokasta, toimintatestien selitteissä ei
  ollut eksplisiittistä lähtötilan tunnistetta eikä yleistä syykenttäehdokasta
  löytynyt. Tämä on lähdesidonnan keskeneräisyys, ei päätös muuttaa pisteytystä.
- 2026-10-03: Adapteriin lisättiin metadata-skeeman hash-, otsake/selite- ja
  pakollisten sidontojen tarkistin, joka on tarkoitettu ajettavaksi ennen
  osallistujarivien lukua.
- 2026-10-03: Lopullinen synteettinen DEAC-testiajo 285/285 PASS; Pythonin
  käännöstarkistus, `git diff --check` ja `tools/run-gates.sh --mode pre-push
  --smoke` PASS. Suojattua kohorttiajoa ei aloitettu, koska MOI-iän sidonta ja
  toistuvien testikenttien lähtötilan valinta eivät ole yksikäsitteisiä.
- 2026-10-03: Lähdeketjun jäljitys tehtiin hyväksytyn handover 1.2.0:n ja
  varmennettujen metadata-artifaktien perusteella; raakaa osallistujariviä ei
  luettu. K40:n legacy-skripti lukee yhden KAAOS-työkirjan dynaamisesti,
  havaitsee mahdollisen seliterivin ja suodattaa baseline-aikapisteen vain,
  jos yleisellä aikakenttähaulla sellainen löytyy; se ei sisällä staattista
  20 DEAC-komponentin lähdekenttävalintaa. K40:n QC-liite rajaa oman FI22-
  nonperformance-ajonsa herkkyysindeksiksi. K14:n eksplisiittiset nimet ovat
  analyysivalmiin CSV:n muuttujakarttaa, eivät Taul1-sarakkeiden
  sarakepaikka-/otsake-/selite-sidonta. K51:n lähdeinventaario käsittelee
  tunnistepohjaista linkitystä rikastetulla lähteellä, ei DEAC:n
  lähtötilakenttiä. FOF:n functional-test-skeema määrittelee 0/2-aikapisteet
  Excel/KaatumisenPelko.csv-haaralle, eikä tarjoa K40 Taul1 -ristiviitettä.
  Esityksen varmennetut aihekuvaukset tukevat mittausten merkitystä ja
  tulokäyntikontekstia, mutta eivät sido niitä Taul1:n sarakepaikkoihin.
  Tämän näytön perusteella 20 komponentista 0 on vielä täysin BOUND ja 20
  jää AMBIGUOUS-tilaan (neurologisen yhdistelmän kolme osakenttää arvioidaan
  erikseen). Taul1:n metadata ei anna lähtöiän kenttää eikä yksilöi
  nonperformance-syykenttää; nämä merkitään erillisiksi SOURCE_NOT_FOUND-
  riippuvuuksiksi, ei pisteytyspäätöksiksi. Tarkat otsakkeet ja selitteet
  pysyvät repo-ulkopuolisessa suojatussa kartassa.
- 2026-10-03T09:38:24+03:00: Lähdeketjun jäljityksen täsmälliset puuttuvat
  artefaktit ovat: (a) K40 Taul1:n versionoitu sarakepaikka–otsake–selite →
  DEAC-komponentti-crosswalk ja sen lähtötilan valintaperusteet kaikille 20
  komponentille; (b) MOI-laskennan lähde, joka osoittaa tallennetun
  kokonaispisteen ikäpiste-sisällön sekä saman lähtötilanteen ikämuuttujan ja
  niiden yhdistämisen; (c) KAAOS:n VAS-kirjaus-/vientiohje, joka vahvistaa
  lähdeyksikön; (d) toimintatestien Taul1-aikapiste-/toistokenttien
  ristiintaulukko mittausprotokollaan; ja (e) testikohtainen
  suoriutumattomuuden syykentän/koodiston määritys. Ilman kohtaa (e) jo
  hyväksytty syytön E/E1 → missing -käsittely pysyy voimassa; syytä ei
  päätellä apuvälineestä tai yleisestä E-koodista. Kuulon ja näön luokkaselitteet
  ovat varmennetut, mutta niitä ei voi sitoa Taul1:n lähdekenttiin ilman (a):ta.
- 2026-10-03T09:38:24+03:00: Synteettiset testit ajettiin uudelleen
  komennolla `uv run --offline --no-project --with pytest pytest -q
  tests/test_deac_source_adapter.py tests/test_deac_components.py
  tests/test_deac_moi.py tests/test_deac_index.py`: 285/285 PASS.
  `git diff --check` PASS; tarkastettu `tools/run-gates.sh --mode pre-push
  --smoke` PASS. Gate ei käynnistänyt aineistoajoa. Suojattuja
  osallistujarivejä ei luettu.
- 2026-10-03T09:38:24+03:00: Rajattu haku tulosti vahingossa
  asiaankuulumattomia aiempien raporttien koosteita työkalutranskriptiin.
  Niitä ei kopioitu tiedostoon tai PR:ään eikä toisteta tässä lokissa; raakaa
  KAAOS-osallistujariviä ei avattu. Tietosuojakäsittelyn tarve jää Data
  Stewardin arvioitavaksi.
- 2026-10-03: Lähdeidentiteetin tarkistus osoitti, että aiempi 68-sarakkeinen
  K40-skeemakartoitus ja K40.V2:n konfiguroitu AUTH_SOURCE ovat eri
  snapshotteja. Niiden sarakemetadatassa vanhat selitteet kohdistuvat
  yksikäsitteisesti AUTH_SOURCEen, jossa on yksi lisäkenttä. Ikäotsake oli
  mukana aiemmassa seliterivissä, mutta jäi komponenttikartan
  ikäehdokaslistasta leksikaalisen haun rajauksen vuoksi. K40.V2:n
  ledger-ketju vahvistaa iän valitusta PRIMARY_FI_INDEX-arvioinnista.
  Aiempi 0/20-verdict koski vain vanhaa skeemakarttaa eikä päde sellaisenaan
  AUTH_SOURCEen. Tarkat lähdeidentiteetit, hashit, otsakkeet ja sarakepaikat
  säilyvät vain suojatussa inventaariossa.
- 2026-10-03: Owner yksilöi DEAC v2:n lähteeksi AUTH_SOURCE-työkirjan.
  Metadata-only-tarkistus varmisti Taul1:n rivin 2 sisältävän 69 saraketta;
  aiemman 68 kentän inventaarion kaikki seliteparit kohdistuvat siihen ja yksi
  lisäsarake on linkityskäyttöön. Aiempi 0/20-tulos koskee eri, vanhempaa
  työkirjaa eikä kuvaa AUTH_SOURCE-sidonnan tilaa. Rivin 2 ikäotsake on
  läsnä; otsakkeen koko soluteksti sisältää myös selite-/koodistotekstiä,
  joten täsmävertailu pelkkään `ikä(a)`-merkkijonoon antoi virheellisen
  puuttumistuloksen. Ikäotsakkeen tarkka solu ja muut otsaketekstit pysyvät
  suojatussa kartassa. Tämä lähdeidentiteetin korjaus ei vielä yksin sido
  MOI-totalin muodostusta, toistuvia mittauksia tai testikohtaista
  syykenttää; niitä ei päätellä osallistujariveistä.
- 2026-10-03: AUTH_SOURCE-sidonnan tarkennus vanhan inventaarion avulla:
  12 komponenttiryhmällä on yksi suora skeemaehdokas (neurologisessa
  yhdistelmässä kolme erillistä osakenttää); kahdeksassa ryhmässä on yhä
  vaihtoehtoisia lähdekenttiä: oma liikuntakyky, aiempi kaatuminen, FOF,
  VAS-kipu, yhden jalan seisonta, tuolilta nousu, puristusvoima ja 10 m
  kävely. Yksikäsitteiset ehdokkaat ovat kenttäsidonnan etenemistä, eivät
  itsessään todiste mittaustoiston valinnasta tai muunnoksesta. AUTH_SOURCE:n
  metadata vahvistaa lähtöiän kentän; MOI-totalin ikäpiste-sisältö perustuu
  Ownerin ilmoitukseen. Suojattu laskenta pysyy estettynä, kun kahdeksan
  vaihtoehtoista kenttä-/mittausvalintaa eivät ole jäljitettävissä.
- 2026-10-03: Yllä oleva kahdeksan vaihtoehdon tila tarkistettiin uudelleen
  suoraan Ownerin nimeämän AUTH_SOURCE:n Taul1:n otsake- ja seliteriveiltä
  (ei osallistujarivejä). Ikäotsakkeen tokenit ovat saman fyysisen solun E2
  monirivisessä tekstissä; ne eivät ole erillisissä soluissa. Parserin
  whitespace-normalisointi ja tätä rakennetta jäljittelevä synteettinen testi
  lisättiin.
- 2026-10-03: Aiemmat 12 yksittäistä ehdokasryhmää tarkistettiin semanttista
  selitettä ja hyväksyttyä komponenttisopimusta vasten. Kahdeksasta aiemmin
  moniehdokkaisesta ryhmästä seitsemän sidottiin lähtötilanteeseen ja
  komponenttisopimukseen sopivaan kenttään: oma liikuntakyky, aiempi
  kaatuminen, FOF, kipu-VAS, yhden jalan seisonta, viisi tuolilta nousua ja
  10 m kävelyaika. 500 m kävelyn vaikeus oli jo aiemmassa
  yksittäisehdokasryhmässä ja vahvistui samalla selitevertailulla. Yhteensä
  19/20 komponenttiryhmää on
  nyt sidottu metadata- ja dokumenttinäytöllä. Puristusvoiman kahden
  lähtötilanteen puolikentän semantiikka ei osoita, ovatko arvot jo
  hyväksyttyjä lähdeluokkia vai edellyttävätkö ne vielä muunnosta; tätä
  ryhmää ei kytketä pisteyttäjään ennen kenttäkuvauksen varmistusta.
  AUTH_SOURCE:ssa ei löytynyt tunnistettua testikohtaista syykenttää; E ilman
  varmennettua syytä ja E1 jäävät Ownerin säännön mukaan puuttuviksi, eikä
  fyysistä kyvyttömyyttä päätellä apuvälineestä. Kohorttiajoa ei tehty.
- 2026-10-03: Tarkistukset: `uv run --offline --no-project --with pytest
  pytest -q tests/test_deac_source_adapter.py tests/test_deac_components.py
  tests/test_deac_moi.py tests/test_deac_index.py` — 287/287 PASS;
  `git diff --check` PASS; `tools/run-gates.sh --mode pre-push --smoke`
  PASS. Testit ja gate eivät avanneet osallistujarivejä.
- 2026-10-03: Puristusvoiman tallennusmuodon rajattu selvitys. AUTH_SOURCE:n
  kahden lähtötilanteen puolikentän otsake/selite ei ilmoita yksikköä eikä
  luokkatyyppiä. `K53_TABLE2.V1_table2-authoritative-wide.R` valitsee saman
  AUTH_SOURCE-työkirjan oikean ja vasemman TK-kentän, siirtää arvot HGS
  mittaussarakkeisiin ilman luokitusmuunnosta ja muodostaa niistä jatkuvan
  keskiarvon; `K15.R` dokumentoi vastaavan Puristus0-johdannaisen kg-yksikössä.
  Nämä tukevat mittausarvotulkintaa mutta eivät yksin todista tämän
  snapshotin tallennusmuotoa. `FUNCTIONAL_TESTS_DERIVED_SCHEMA.md` varoittaa
  Excel-haaran luokka/kg-sekoittumisesta; sen arvopohjaista luokittelua ei
  käytetty, koska osallistujarivejä ei luettu. Lähde-esityksen SHA täsmäsi;
  dia 86 viittaa lähteeseen THL (2011), "Käden puristusvoima", Terveys
  2000–2011, s. 3 ja kuvaa mittaustuloksen pyöristämisen ennen
  kuntoluokan arviointia. Tämä tunnistaa tarvittavan luokitustaulukon mutta
  ei vielä vahvista, ovatko AUTH_SOURCE-kentät raakaa kg-mittausta vai jo
  luokiteltuja. Verdict: SOURCE_FORMAT_UNRESOLVED. Adapterin nykyinen
  sopimus odottaa parempien käsien lähdeluokkaa 0–5 eikä tee kg-muunnosta.
  Puristusvoima pysyy ainoana avoimena komponenttisidontana (19/20 sidottu);
  kohorttiajoa tai muunnoskoodia ei tehty. Ratkaisuun tarvitaan
  kenttäkohtainen, versioitu AUTH_SOURCE-tallennusmuodon vahvistus sekä
  tarvittaessa THL 2011 -taulukon täydellinen, sovellettava luokitusohje.
- 2026-10-03: Owner ratkaisi edellisen tallennusmuotokysymyksen: AUTH_SOURCE:n
  lähtötilanteen oikean ja vasemman käden puristusvoimakentät ovat valmiita
  kuntoluokkia, eivät kilogrammamittauksia. Validi luokka 0 saa hyväksytyn
  vajeen 1. Owner ja senioribiostatistikko olivat tunnistaneet noin 5–7
  tulkintakelvotonta lähdelukua puuttuviksi; niitä ei luokitella tai pisteytetä.
  Tarkistetuista suojatuista kartoista ei löytynyt täsmällistä koodiluetteloa.
- 2026-10-03: Adapterin nykyinen käsittely tarkistettiin: se lukee sidotun
  käden luokka-arvon sellaisenaan, valitsee paremman numeerisen luokan ja
  pisteyttää sen; arvoalueen ulkopuolinen numeerinen koodi pysähtyy
  virheeseen. Aiempi runtime-sidonta ei siis ollut jo normalisoinut näitä
  koodeja. Lisättiin suojatun `invalid_codes_as_missing`-sidonnan tuki, joka
  muuntaa vain eksplisiittisesti määritetyt käden luokan lähdekoodit
  puuttuviksi ennen paremman käden valintaa. Jo `None`-arvo pysyy puuttuvana;
  luokkaa 0 ei voi asettaa puuttuvaksi.
- 2026-10-03: Synteettiset reunatestit erottavat validin luokan 0 (vaje 1),
  tavallisen puuttuvan arvon, erikseen konfiguroidun numeerisen
  poikkeuskoodin (`NA`) ja konfiguroimattoman arvon (fail-closed). Testien
  poikkeuskoodi on synteettinen eikä vastaa tai paljasta lähdekoodia.
- 2026-10-03: Työpuu siirrettiin väliaikaisesta `/tmp`-sijainnista
  pysyvään `/data/data/com.termux/files/home/worktrees/deac-v2-source-binding`
  -sijaintiin samalla branchilla ja HEADilla; diff säilyi. Komponentin
  semanttinen lähdesidonta on nyt 20/20, mutta aineistoajo ei ole valmis ennen
  kuin aiemmin tunnistettujen poikkeuskoodien täsmällinen suojattu lista ja
  käytettävä runtime-sidonta löytyvät. Osallistujarivejä ei avattu eikä
  kohorttiajoa tehty.
- 2026-10-03: Erillisen työpuun tila varmennettiin ennen siirtoa: branch
  `feat/deac-v2-source-binding-20261003`, HEAD
  `ba8a77794481e871c8afa0ba93125eba91fb3cf9`, kaksi muokattua lähdekooditesti-
  tiedostoa ja kaksi uutta dokumenttitiedostoa. Työpuu siirrettiin
  `~/worktrees/deac-v2-source-binding`-hakemistoon; branch, HEAD ja diff
  säilyivät.
- 2026-10-03: Tarkistettiin suojatut edge-case-, toteutusmäärittely-, K40-
  skeema- ja metadatainventaarioartefaktit sekä DEAC-adapterin nykyinen
  käsittely. Näistä ei löytynyt täsmällistä koodiluetteloa; aiempi runtime-
  adapteri ei muuttanut numeerisia luokan ulkopuolisia arvoja `NA`:ksi, vaan
  pisteyttäjä pysäytti ne virheenä. Ownerin lähdetäsmennys kirjattiin
  suojattuun edge-case-muistioon ilman raakojen koodiarvojen kopiointia.
- 2026-10-03: `SourceBindings.invalid_codes_as_missing` lisättiin vain
  puristusluokan puolikentille. Se hyväksyy runtime-sidonnassa ainoastaan
  eksplisiittisesti vahvistetut koodit, soveltaa `NA`-muunnoksen ennen
  paremman käden valintaa ja estää hyväksyttyjen luokkien 0–5 merkitsemisen
  puuttuviksi. Tuntematon poikkeusarvo pysyy fail-closed-tilassa.
- 2026-10-03: Uudet synteettiset testit erottavat luokan 0, tavallisen
  puuttuvuuden, eksplisiittisesti konfiguroidun synteettisen virhekoodin ja
  konfiguroimattoman numeerisen poikkeusarvon. Kohdennettu DEAC-testiajo
  komennolla `uv run --offline --no-project --with pytest pytest -q
  tests/test_deac_source_adapter.py tests/test_deac_components.py
  tests/test_deac_moi.py tests/test_deac_index.py` läpäisi 289/289 testiä.
  Suojattua kohorttiajoa ei tehty: täsmällisen poikkeuskoodiluettelon
  auktoritatiivista viitettä ei löytynyt tarkastetuista kartoista.
- 2026-10-03: Esivalitun testituloksen apurajapinta tarkennettiin fail-closed-
  sääntöön: kyvyttömyyskoodi ilman samassa rajapinnassa varmennettua syytä
  palautuu puuttuvana. Lopullinen kohdennettu testiajo läpäisi 290/290 testiä.
  `git diff --check` ja staged `tools/run-gates.sh --mode pre-push --smoke`
  läpäisivät (exit 0). Gate tarkisti guardrails- ja renv-tilan sekä staged-
  Python-syntaksin; se ei käynnistänyt aineistoajoa. Kohorttiajo pysyy
  estettynä vain täsmällisen poikkeuskoodiluettelon puuttuessa.
- 2026-10-04: Liikuntakyvyn koodisto (0 hyvä, 1 kohtalainen, 2 heikko, 3
  puuttuva) kirjattiin Ownerin vahvistamaksi. Kahden aiemmin saman selitteen
  ehdokkaan fyysiset otsakkeet erotettiin vain Taul1:n metadatasta: ne kuvaavat
  eri takautuvia muutosjaksoja, eivät lähtötilanteen itsearvioitua
  liikuntakykyä. Kumpaakaan ei sidottu komponenttiin. Täsmälliset otsakkeet ja
  sarakeviitteet jäivät suojattuun karttaan; lähtötilanteen
  liikuntakykykentälle tarvitaan vielä yksilöivä lähdeviite tai oikea
  sarakevalinta. Osallistujarivejä ei avattu.
- 2026-10-04: Lisättiin synteettisesti testattava kohorttiajurin ydin, joka
  sovittaa MOI-kvintiilit valmiiksi rajatun lähtötilannekohortin
  ikäpisteettömistä MOI-arvoista, pisteyttää saman kohortin 20 komponenttia
  kahdessa läpikäynnissä ja palauttaa vain koontilaskurit. Se ei lue
  työkirjoja, valitse käyntejä tai tuota rivi-/henkilötason tuloksia.
  SourceBindings-konfiguraatiota ja kohorttiajoa ei tehty, koska
  lähtötilanteen liikuntakykykentän sidonta on yhä avoin. Uudet ja aiemmat
  kohdennetut DEAC-testit läpäisivät 294/294; `tools/run-gates.sh --mode
  pre-push --smoke` läpäisi (exit 0). Gate ei käynnistänyt aineistoajoa.
- 2026-10-04: Ownerin antama liikuntakyvyn täysi selite löytyi yksikäsitteisesti
  AUTH_SOURCE Taul1:n otsakemetadatasta. Se sitoo lähtötilanteen
  itsearviointikentän ja vahvistaa luokat 0–2 sekä luokan 3 puuttuvaksi.
  Aiemmat takautuvan muutosjakson ehdokkaat hylättiin tähän komponenttiin
  kuulumattomina. Suojattu valintatallenne ja 25 fyysisen kentän
  SourceBindings-konfiguraatio luotiin; lähdehash, sarakepaikkojen
  yksikäsitteisyys, otsake/seliteparit sekä grip-poikkeuskonfiguraation
  identiteetti validoitiin ilman osallistujarivejä. Konfiguraatiolla tehty
  synteettinen liikuntakyvyn 0–3-tarkistus läpäisi. Kohorttiajoa ei tehty.
- 2026-10-04: Ajurin SourceBindings-konfiguraation fail-closed-lataus ja
  lähtötilannekohortin kaksivaiheinen synteettinen käsittely lisättiin.
  Testit läpäisivät 296/296; `python -m compileall`, `git diff --check` ja
  `tools/run-gates.sh --mode pre-push --smoke` läpäisivät. Ajurin
  varsinaista työkirjalukijaa eikä kohortin valintasääntöä ole vielä kytketty;
  osallistujarivejä ei luettu.
- 2026-10-04: XLSX-lukija lisättiin. Se tarkistaa snapshotin hashin, välilehden
  sekä sidotut metadata-rivit ennen valittujen sarakkeiden lukua; lukija käyttää
  SourceBindingsin vahvistettuja fyysisiä sarakepaikkoja eikä etsi kenttiä
  osallistujadatan tekstistä. Synteettisen XLSX:n lukutestit läpäisivät.
  AUTH_SOURCE-esilento vahvisti hashin ja 25 kentän metadatasidonnat, mutta
  kohortin henkilötunniste ei ole yksikäsitteinen kaikilla aktiivisilla
  lähderiveillä. Siksi pisteytystä, kohorttivalintaa tai tulostiedostoa ei
  muodostettu. Suojattu lukumääräkooste jäi ajonaikaiseen tarkistusraporttiin;
  tunnisteita tai rivejä ei tulostettu.
- 2026-10-04: Senioribiostatistikon vahvistama kohorttisääntö toteutettiin:
  AUTH_SOURCE-rivit yhdistetään varmennetulla henkilöavaimella ja
  klinikkapäivällä, ja kustakin 527 henkilöstä valitaan aikaisin käynti
  riippumatta työkirjan rivijärjestyksestä. Kooste: 540 komponenttiriviä,
  527 yksilöllistä henkilöä, 13 myöhempää käyntiriviä sivuutettiin; avain- tai
  päivämääräpuutteita eikä ensimmäisen päivän ristiriitoja ei ollut. Tämä
  täsmäytys ei käyttänyt lukua 527 valinnan pakottamiseen.
- 2026-10-04: Ensimmäinen suojattu pisteytysesilento pysähtyi ennen
  MOI-kvintiilejä: valitussa lähtötilannekohortissa 25 MOI-arvoa oli
  tekstimuotoisia kahdessa raakamuodossa (myöhempi tarkistus osoitti ne
  saman koodin kirjoitusasuiksi), eikä koodia ollut määritelty
  MOI-kentän suojatussa puuttuvuuskoodistossa. Koodien raakatekstejä ei
  tulostettu. Niitä ei muutettu automaattisesti puuttuviksi, koska hyväksytty
  E/E1-puuttuvuussääntö koskee fyysisten testien tulkintaa eikä ratkaise
  MOI-kentän koodimerkitystä. Siksi kvintiilejä, komponenttipisteitä tai
  DEAC-tuloksia ei muodostettu eikä osallistujatulosta tallennettu. Tarvitaan
  MOI-kentän lähteeseen perustuva koodiselite tai Ownerin rajattu
  vahvistus käsittelysäännöstä; kohorttipäätöstä ei avata uudelleen.
- 2026-10-04: MOI-merkintöjen rajattu lähdetarkistus täsmensi edellistä
  havaintoa. Kaikki 25 tekstimuotoista havaintoa normalisoituvat samaan
  lähdemerkintään, joka esiintyy kahdessa kirjainkokomuodossa; ne eivät ole
  tekstimuotoisia numeroita. Koodikohtaiset frekvenssit pysyvät vain
  suojatussa QC-raportissa. AUTH_SOURCE:n MOI-selite ei yksin luettele
  erikoismerkintää. Varmennetun KAAOS-ohjeen MOI-kohdat (diat 17 ja 21) sekä
  aiemmat suojatut semantiikka-/puuttuvuuskartat tukevat tämän merkinnän
  puuttuvuustulkintaa. Molemmat kirjoitusasut lisättiin vain suojatun
  runtime-konfiguraation MOI-kentän puuttuvuuskäsittelyyn; tarkat kooditekstit
  ja konfiguraatio pysyvät repo-ulkopuolella. Uusi suojattu ajo sivuutti nämä
  MOI-arvot kvintiiliviitteestä, mutta pysähtyi ennen pisteytystä, koska
  osa lähtötilanteen i'istä alitti Waris 2011:n määrittelemän ikäpistealueen.
  Näille arvoille ei ekstrapoloitu ikäpisteitä eikä pisteytetty nollaa;
  osallistujatuloksia ei muodostettu tai tallennettu. Kohortti on edelleen
  527 henkilön ensimmäinen
  käynti, eikä kohorttipäätöstä muutettu.
- 2026-10-04: Owner vahvisti alle 55 vuoden soveltamistulkinnan: ikäpisteet
  ovat 0, koska Waris 2011:n ensimmäinen positiivinen luokka alkaa 55 vuodesta.
  Artikkelin kohortissa esiintyy 45–54-vuotiaita (Methods §2.1), mutta lähde
  ei kirjoita nollariviä erikseen; 0 pistettä alle 55-vuotiaille on Ownerin
  sovellus, ei artikkelin suora sanamuoto. Tulkinta kirjattiin paikalliseen
  päätöslisään ja `waris_2011_age_points`-funktioon; synteettiset rajatestit
  i’ille 54 ja 55 lisättiin. Yksityisen päätösrekisterin ja METHODS-omistajan
  synkronointi jää myöhemmäksi.
- 2026-10-04: Päivitetyn sääntöketjun suojattu uudelleenajo vahvisti yhä
  527/527 ensimmäisen käynnin valinnan ja ohitti MOI-puuttuvuuskoodit
  hyväksytyn konfiguraation mukaan. Pisteytys pysähtyi fail-closed, koska
  yhden havaitun MOI-kokonaispisteen arvo on pienempi kuin saman henkilön
  lähtöiästä johdetut MOI-ikäpisteet. Yksittäistä riviä tai arvoja ei avattu
  raporttiin; poikkeaman määrä ja tunnisteet säilyvät suojatussa QC:ssä.
  Kvintiilejä, DEAC-pisteitä tai osallistujatulostetta ei muodostettu.
- 2026-10-04: Owner vahvisti yhden tapauksen senioribiostatistikolta saadun
  tapauskohtaisen korjauspäätöksen: lähdearvo säilytetään, mutta tämän tapauksen
  ikäpisteetön MOI asetetaan nollaksi ennen kvintiilejä. Yleistä
  `max(0, total - age_points)` -sääntöä ei lisätä. Ajuriin lisättiin
  suojattuun korjausmerkintään sidottu tarkka kohdistus, joka vaatii samaa
  henkilöavainta, alkuperäistä MOI-totalia ja lähtöikää sekä todentaa, että
  tavallinen vähennys olisi negatiivinen; muuten ajo pysähtyy. Synteettinen
  regressio varmistaa, että vain kohdistettu tapaus korjautuu, lähderivi ei
  muutu ja uusi/eri ristiriita pysäyttää. Testit: 308 läpäissyt; compileall,
  diff-tarkistus ja pre-push-smoke-gate läpäisivät. Suojattu tapausloki ja
  AUTH_SOURCE-kohortin jatkoajo ovat vielä tekemättä, koska tapauskohtaista
  korjausmerkintää ei ole voitu sitoa uudelleen todennettuun lähdearvoon ja
  lähtöikään tässä työpuussa. Osallistujatulosta ei muodostettu.
- 2026-10-04: Owner täsmensi, että aiemman 527 henkilön ensimmäisen
  käyntikohortin avain- ja käyntipäiväsidonnat on palautettava aiemman
  esilennon omista syötteistä. Rajatussa etsinnässä nykyinen SourceBindings-
  konfiguraatio sisälsi komponenttikentät mutta ei näitä kahta kohorttisidontaa;
  nykyisestä prosessiympäristöstä eikä tarkastetusta paikallisesta asetuksesta
  löytynyt henkilöavaimen sarakevalintaa. Repo-/väliaikaistyötilojen koodista
  tai rajatuista suojatuista ajolokeista ei löytynyt aiemman valinnan
  täsmällistä ajokutsua. Otsakemetadatan päivämääräehdokasta ei käytetty
  kohorttivalintaan, koska henkilöavaimen sidontaa ei voitu todentaa.
  Esilentoa ei toistettu, tapauslokia ei luotu eikä osallistujatuloksia
  muodostettu. Toteutuksen poikkeus vaatii nyt lisäksi saman
  snapshot-hashin, henkilöavaimen ja lähtökäyntipäivän täsmäytyksen sekä
  alkuperäisen MOI-totalin ja lähtöiän; korjaus ei voi osua toiseen riviin.
  Synteettiset testit pysyivät 308/308 läpäisseinä.
- 2026-10-04: Aiemman kohorttiesilennon sidonnat palautettiin nykyisestä
  Termux-asetuksesta ja AUTH_SOURCE-metadataa vasten. Henkilöavain löytyi
  paikallisesta KAAOS_ID_COL-asetuksesta ja käyntipäivä yksikäsitteisestä
  päivämäärämetadatasarakkeesta. Kohortti täsmäsi uudelleen: 540 lähderiviä,
  527 henkilöä, 13 myöhempää käyntiä ohitettu, ei avain-/päivämääräpuutteita
  eikä ensimmäisen päivän ristiriitoja. MOI-tarkistus löysi täsmälleen yhden
  negatiivisen ikäpisteettömän tuloksen. Sen tapauskohtainen korjausmerkintä
  luotiin suojattuun 0600-lokiin: lähdearvo, avain ja lähtökäynti ovat siellä,
  eivät tässä tiedostossa. Provenienssi kirjaa Ownerin tässä keskustelussa
  välittämän senioribiostatistikon hyväksynnän; erillistä allekirjoitettua
  asiakirjaa ei väitetä tarkistetuksi.
  Kohorttilaskenta pysähtyi tämän jälkeen FOF-komponentin hyväksytyn 0/1-
  syötealueen ulkopuoliseen lähdekategoriaan. Sidottu kenttäselite ei määritä
  kyseisen kategorian puuttuvuusmerkitystä. Tästä syystä indeksitulostetta tai
  koonti-QC:tä ei tallennettu. Kysymys on nyt FOF-lähdekoodin rajatusta
  semanttisesta sidonnasta; MOI-korjausta, kohorttia tai muuta komponenttia
  ei avata uudelleen.

- 2026-10-05: Paikallisen päächeckoutin skill-blob on vanhempi kuin
  DEAC-työpuun skill-blob; työpuun versio vastaa käytettävissä olevaa
  origin/main-refiä, kieltää yksityisen tiedon paljastamisen ja sallii
  tarkastetut repository-testit. Suojattu käsittely jatkui tässä erillisessä
  työpuussa; päächeckoutia ei muutettu. Edellisen 19 koodiryhmän koonti
  verrattiin tallennettuihin kenttämuistiinpanoihin, puuttuvuusmäärityksiin,
  hyväksyttyyn pisteytykseen ja rajattuihin esityksen määritelmäkohtiin.
  Kuusi lähteessä puuttuvuudeksi vahvistettua kenttäarvoa lisättiin uuteen
  repo-ulkopuoliseen 0600-runtime-konfiguraatioversioon; alkuperäistä
  konfiguraatiota ei ylikirjoitettu. Synteettiset testit käyttävät vain
  keinotekoisia merkkijonotunnisteita, eivät suojattuja lähdekoodeja.
  Viisi ryhmää jää lähdeselvitykseen/Owner-ratkaisuun: kaksi itsearvioidun
  terveyden kentässä, yksi mielialakentässä ja kaksi aiemman kaatumisen
  kentässä. Tarkat koodit, frekvenssit ja määritelmäkatkelmat ovat vain
  suojatussa `deac_v2_code_semantics_review_20261005.md`-raportissa.
  Näitä tapauksia ei pisteytetty eikä kohorttiajoa tehty. Pytest: 302/302
  PASS; suojatun runtime-konfiguraation synteettinen tarkistus: 6/6 PASS;
  pre-push-smoke-gate ja `git diff --check`: PASS.
- 2026-10-05: Rajattu jatkotarkistus varmisti, että mielialakentän lisämerkintä
  tarkoittaa lähteen mukaan “ei tietoa”. Se lisättiin vain uuteen suojattuun
  runtime-konfiguraatioversioon tavallisena puuttuvuutena; hyväksytty
  mielialan pisteytys ei muuttunut. Testiin lisättiin geneerinen synteettinen
  puuttuvuuskoe; adapteritestit 45/45 PASS ja suojatun koodin synteettinen
  tarkistus PASS. Lähdeselvitys ei määrittänyt kahden itsearvioidun terveyden
  eikä kahden aiemman kaatumisen lisäryhmän merkitystä. Niitä ei normalisoitu
  eikä pisteytetty. Päätöspaketti ja täsmälliset koodikohtaiset koosteet ovat
  vain repo-ulkopuolisessa suojatussa raportissa; 20 komponentin indeksiä tai
  osallistuja-ajoa ei muodostettu.
- 2026-10-05: Owner päätti, että tämän AUTH_SOURCE-snapshotin kaksi
  lähdeselitteen ulkopuolista aiemman kaatumisen merkintää käsitellään tässä
  DEAC-ajossa tulkintakelvottomina puuttuvina; niiden alkuperäistä merkitystä
  ei päätellä. Itsearvioidun terveyden lähteen “ei tietoa” -luokka ja Ownerin
  vahvistama lisämerkintä ovat puuttuvia. Täsmälliset koodit ja määrät on
  kirjattu vain repo-ulkopuoliseen suojattuun päätös- ja runtime-karttaan.
- 2026-10-05: Suojatun esilennon jälkeen jo konfiguroitujen puuttuvuusmerkkien
  numeerisen/tekstimuotoisen esityksen ero yhdenmukaistettiin työkirjan
  lukijan tuottamaan tyyppiin; merkityksiä tai pisteytyksiä ei muutettu.
  Testikohtaisten statusmerkkien reuna-alkutilan välilyönnit ja kirjainkoko
  normalisoidaan koodikirjan hakuun, ja normalisoitujen avainten törmäykset
  hylätään. Tunnettu positiivinen neurologinen osakenttä antaa edelleen
  yhdistelmävajeen 1; jos positiivista ei ole ja vähintään yksi osakenttä
  puuttuu, yhdistelmäkomponentti on tavallisen puuttuvuussäännön mukaisesti
  puuttuva, ei nolla.
- 2026-10-05: Rajatut DEAC-testit 320/320 PASS; tarkastettu
  pre-push-smoke-gate ja `git diff --check` PASS. Suojattu kohorttiajo:
  540 lähderiviä, 527 yksilöllistä ensimmäistä käyntiä, 13 myöhempää käyntiä
  ohitettu, ei kohorttiristiriitoja; MOI-referenssijoukossa 502 havaintoa.
  Kattavuusrajan täytti 470 henkilöä ja 57 jäi sen alle; 470 DEAC-indeksiä
  laskettiin. Indeksin henkilötason tulokset ovat vain oikeuksin rajatussa
  repo-ulkopuolisessa suojatussa sijainnissa. Keskusteluun ei tulostettu
  osallistujarivejä, tunnisteita tai lähdekoodeja.
- 2026-10-05: Vaihtoehtoinen `run_baseline_cohort`-polku ohjattiin samaan
  `score_first_visit_cohort`-toteutukseen. Se vaatii nyt varmennetun
  `FirstVisitCohort`-olion ja välittää tapauskohtaisen MOI-korjauksen; irrallinen
  rivitehdas ei voi ohittaa kohdistusvarmistusta. Synteettinen parity-testi
  vertaa kvintiilirajoja ja koontituloksia molempien julkisten kutsujen välillä.
  Puristusvoimakohtaa päivitettiin erottamaan historiallinen koodilistan
  etsintä nykyisestä suojatusta runtime-normalisoinnista; luokat 0–5 säilyvät
  valideina. DEAC-testit 321/321 PASS, `git diff --check` PASS ja tarkastettu
  `tools/run-gates.sh --mode pre-push --smoke` PASS (exit 0; Python-gate
  ilmoitti, ettei staged Python-tiedostoja ollut). Ensimmäinen manifestiyritys
  jätettiin tarkoituksella pending-tilaan, koska alkuperäisen ajon tarkkaa
  versio- ja valitsintietoa ei voitu rekonstruoida.
- 2026-10-05: Uusi suojattu ajo tehtiin lukitusta nykytilasta. `config/.env`
  -asetuksen avainvalitsin täsmäsi työkirjan metadataan; käyntipäivävalitsin
  varmennettiin aiemman tehtävämerkinnän yksikäsitteisestä päivämääräkentästä
  ja nykyisestä Taul1-metadatasta. Esilento täsmäsi: 540 lähderiviä, 527
  henkilöä, 13 myöhempää käyntiä, ei puuttuvia avaimia/päiviä eikä saman
  päivän ristiriitoja. Uudelleenlaskenta tuotti 502 MOI-referenssihavainnolla
  rajat 4/6/7/9. Uusi ajo tuotti 470 indeksiä ja 57 kattavuuden alle jäänyttä;
  vanhan suojatun tuloksen kanssa tehdyssä paikallisessa avainkohtaisessa
  vertailussa kohortti-, komponentti- ja indeksierot olivat 0. Uusi tulos ja
  varmennettu manifesti ovat repo-ulkopuolisessa suojatussa hakemistossa;
  osallistujarivejä, tunnisteita tai suojattuja lähdearvoja ei kirjata tähän.
  Manifestin lähde-, koodi- ja konfiguraatiosidonnat sekä tulosartefaktin hash
  tarkistettiin suoraan. Uusinta-ajo täsmäsi: 540 lähderiviä, 527 henkilöä,
  502 MOI-havaintoa, rajat 4/6/7/9, 470 indeksiä ja 57 kattavuusrajan alle
  jäänyttä; osallistujatuloksen erot aiempaan suojattuun tulokseen 0.
  Toteutuscommitit 73b7ef1, 601cf48 ja 047149b yksilöitiin; perustava erä
  julkaistaan PR #182:ssa ja kohorttiajurin erä PR #183:ssa. PR #183:n haaraan
  yhdistettiin perustavan erän kaksi myöhempää neurokomponentin korjaus- ja
  dokumentointicommittia (00742cb, 7fc95ee), jotta pino sisältää nykyisen
  hyväksytyn koodin. Työpuun tarkistus on puhdas ja `git diff --check` PASS.
  Aiemmin ajetut 321 DEAC-testiä ja pre-push-smoke-gate läpäisivät; PR:ien
  CI-tulokset tarkistetaan lopullisen pushin jälkeen.
- 2026-10-05: Sourceryn kolme PR #182 -huomiota korjattiin commitissa
  `93c557f`: kyvyttömyysstatus vaatii nyt hyväksytyn syykoodin kaikissa
  kutsupoluissa, tekstistatus normalisoidaan ja numeerinen status täsmäytetään
  täsmällisesti. Puuttuvan, tuntemattoman ja varmennetun syyn sekä numeerisen
  statuksen kohdennetut regressiotestit läpäisivät (92/92); PR #182:n headin
  testit, lint, CodeQL ja Python-/JavaScript-analyysit läpäisivät.
- 2026-10-05: Sourceryn neljä PR #183 -huomiota korjattiin commitissa
  `570c569` ja invarianttien lisätarkistuksella commitissa `ad51250`.
  Kohorttivalitsimen alkuperä ja henkilöavain–päivä–rivi-kytkös tarkistetaan
  uudelleen pisteytyksessä; valitut rivit jäädytetään. Työkirjan hash ja
  metadata luetaan samasta vakaasta snapshotista. Suojattu CSV kirjoitetaan
  yksityiseen väliaikaistiedostoon ja julkaistaan atomisesti ilman ylikirjoitusta;
  keskeytys siivoaa väliaikaistiedoston. Koko DEAC-testijoukko 332/332 ja
  pre-push-smoke-gate läpäisivät.
- 2026-10-05T10:24:33Z: Ihmisomistaja `Tupatuko2023` yhdisti PR #184:n, jonka
  diff sisältää tämän tehtävän katselmointiin siirron, kohorttiajurin ja sen
  testit. Pysyvä hyväksyntänäyttö: [PR #184](https://github.com/Tupatuko2023/Python-R-Scripts/pull/184),
  merge-commit `6b64c322b3b6043562e9fba181124e348330038f`.
- 2026-10-05T10:48:54Z: PR:n alkuperäinen ajo-manifesti tarkistettiin suoraan.
  Se viittasi `047149b`-versioon; `deac_cohort_runner.py` ja
  `deac_source_adapter.py` eivät täsmänneet mainiin. Mainin laskentamoduuleilla
  tehtiin siksi uusi suojattu ajo. Kohorttiesilento: 540 lähderiviä, 527
  yksilöllistä ensimmäistä käyntiä, 13 myöhempää käyntiä, ei puuttuvia avaimia
  tai päiviä eikä tasatilanteita. MOI: 502 havaintoa, rajat 4/6/7/9; 470
  indeksiä ja 57 kattavuusrajan alitusta. Aiemman suojatun tuloksen vertailu:
  avainerot 0, komponenttipiste-erot 0, indeksin saatavuuserot 0 ja
  indeksiarvoerot 0. Viimeisin ajo-manifesti on
  `$HOME/.local/share/deac-schema-inventory/deac_v2_run_20261005T104813Z/`-hakemistossa;
  manifesti ja osallistujatulos ovat käyttöoikeuksin 0600.
- 2026-10-05: Termux-ajuri ja pysyvä ajo-ohje lisättiin. Suojattu kohortin
  valitsin säilyttää myös päivämääräsarakkeen ja valintasäännön. SourceBindings
  sisältää 25 semanttista lähdesyötekenttää, joista toteutus tuottaa 20
  hyväksyttyä komponenttia. DEAC-testit 334/334 ja pre-push-smoke-gate
  läpäisivät. Ajuri suoritettiin mainin laskentamoduuleilla; uusi manifesti
  kirjasi myös ajurin hashin. README ja runbook rajaavat seuraavan vaiheen
  mittarin ominaisuuksien ja tutkimusyhteyksien erilliseen arviointiin.
- 2026-10-05T10:52:41Z: Pysyvä komentoriviajuri ajettiin commitissa `c15ed24`.
  Kaikkien viiden laskentamoduulin tiivisteet täsmäsivät PR #184:n merge-commitiin;
  ajurin tiiviste kirjattiin uuteen suojattuun manifestiin. QC pysyi samana:
  540/527/13, MOI 502 ja rajat 4/6/7/9, indeksejä 470 ja kattavuusrajan alla
  57. Vertailu aiempaan suojattuun tulokseen: avain-, komponentti-, saatavuus-
  ja indeksiarvoerot 0. Manifesti on
  `$HOME/.local/share/deac-schema-inventory/deac_v2_run_20261005T105241Z/`
  -hakemistossa, SHA-256
  `fbe39c012c41aa99cc5736ba2207573616c1c255a3b6b628e8677494eebb4876`.
- 2026-10-05: Uusi suojattu ajo commitin `ad51250` koodilla. Uusinta-ajo
  täsmäsi: 540 lähderiviä, 527 henkilöä, 13 myöhempää käyntiä, ei puuttuvia
  avaimia/päiviä eikä ensimmäisen päivän ristiriitoja; 502 MOI-havaintoa,
  kvintiilirajat 4/6/7/9, 470 indeksiä ja 57 kattavuusrajan alitusta.
  Aiemman suojatun tuloksen kanssa erot olivat avaimissa 0, komponenttipisteissä
  0, indeksien saatavuudessa 0 ja indeksiarvoissa 0. Uusi manifesti ja tulos
  sekä kaikkien viitattujen artefaktien tiivisteet varmennettiin; tiedostot
  jäivät paikallisesti suojatuiksi.
