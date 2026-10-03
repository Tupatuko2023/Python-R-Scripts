# Tehtävä: DEAC v2:n K40-lähdesidonta ja rajattu aineistoajo

## Tila

02-in-progress — aloitettu 2026-10-03

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
