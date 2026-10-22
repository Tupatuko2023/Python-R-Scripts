# AIM1 QC0a: tuotantolukijan rajattu tekninen viimeistely

## Context

`AUTH-SOURCE-001`-lähteen P0-identiteetti ja `Taul1`-arkin fyysinen otsakerivi 2 on aiemmin dokumentoitu. HOTL kattaa admitoidun tehtävän palautuvat tekniset korjaukset. AIM1 QC0a:n suojatun työkirjan käsittelyoikeuden soveltuvuus on `NEEDS_VERIFICATION`, ei evätty. Nykyinen `readxl 1.4.5` -prototyyppi on validoitu vain synteettisesti (18/18); se ei ole tuotantolukija. Tämä kortti koskee yhtä teknistä työpakettia eikä muuta tutkimus- tai datankäyttövaltuutta.

## Inputs

- Nykyinen repositoryn `AGENTS.md`, `SKILLS.md`, `config/agent_policy.md`, `config/steering.md` ja `Fear-of-Falling/README.md`.
- Yksityiset AIM1 QC0a:n HOTL-, auktoriteetti- ja tekniset loppuarviot sekä aiempi synteettinen wrapper ja testit; suojattua aineistoa tai `.env`-sisältöä ei lueta.
- Nykyinen task-pohja `tasks/_template.md` ja jo hyväksytyt P0-lähdeidentiteetin tiedot.

## Outputs

- Yksi tehtäväkohtainen yksityinen, synteettisesti validoitu tuotantolukijaehdokas ja tekninen loppukatselmointi.
- Turvallinen, yksityinen validointitietue; ei dataan perustuvia QC-tuloksia, raakaa otsakemanifestia eikä julkista suojattua sisältöä.

## Rajaus ja toteutus

1. Valitse tämä kortti READY-jonosta, siirrä se ensin `02-in-progress`-tilaan ja lokita työ repo-ohjeiden mukaan. Säilytä muiden checkoutien muutokset.
2. Viimeistele yksityinen, tehtäväkohtainen lukijaehdokas yhdelle hashilla lukittavalle lähteelle, ennalta nimetylle arkille ja fyysiselle otsakeriville. Tuotantolähdettä ei avata tässä tehtävässä. Ei fallbackia toiseen työkirjaan, arkkiin tai riviin.
3. Käsittele samalla työpaketilla prosessin kaatuminen, aika- ja muistiraja, XLSX/ZIP-purku, hashin ja avauksen välinen tiedostonvaihto, yksityiset väliaikaistiedostot sekä lokien ja stdout/stderr:n rajaus. Tavalliset tekniset korjaukset ja synteettiset uusintatestit pysyvät saman kortin sisällä.
4. Toteuta ehdollinen yksityinen otsakemanifestin käsittely niin, että sitä ei tuoteta tai katsota oikeasta työkirjasta ilman erikseen varmennettua soveltuvaa aineiston käyttövaltuutta. Julkinen tulos rajataan ennalta määrättyihin turvallisiin tilakoodeihin. Ei osallistuja- tai tunnistearvoja, lukumääriä, jakaumia, kustannuksia eikä analyysia.
5. Testaa täysin synteettisillä XLSX-tiedostoilla myös virheelliset rakenteet ja turvarajojen epäonnistuminen. QFOT2 arvioi lopullisen teknisen näytön yhdessä katselmoinnissa. Kirjaa lukijaehdokkaan hash, testit ja yksi mahdollinen todellinen kriittinen este.
6. Tarkista muuttuneiden tiedostojen rajaus, repo-ohjeiden soveltuvat staattiset tarkistukset ja task-lifecycle. Valmis tehtävä siirtyy `03-review`-tilaan ihmiskatselmointia varten. `04-done`, push, PR tai merge ei seuraa tästä kortista automaattisesti.

## Definition of Done (DoD)

- Yksi tuotantokäyttöön tarkoitettu mutta **ajamaton** lukijaehdokas sekä synteettinen testinäyttö ovat yksityisesti katselmoitavissa, tai yksi kriittinen tekninen este on yksilöity.
- Luku-, muisti-, aika-, väliaikaistiedosto-, loki- ja tulosterajat ovat dokumentoidut ja synteettisesti testatut; teknisen näytön rajat on ilmaistu.
- QFOT2:n tekninen katselmointi on kirjattu. Datankäyttövaltuuden soveltuvuus pysyy erillisenä `NEEDS_VERIFICATION`-asiana, kunnes olemassa oleva viite vahvistetaan.
- `PRODUCTION_QC0A_RUN = NO`; `PARTICIPANT_DATA_ACCESSED = NO`; `AGGREGATE_QC_RUN = NO`; `ANALYSIS_RUN = NO`. Ei uusia tieteellisiä päätöksiä eikä muutoksia G4/G5/G11-tiloihin.

## Log

- 2026-10-22T14:42:07+03:00: READY-checkpoint palautettu nykyisestä tehtäväworktreestä; siirretty 02-in-progress-tilaan. Uusi 19.10.2026 hyväksyntänäyttö arvioidaan erillään teknisestä katselmoinnista.

- 2026-10-17: Ownerin rajatusta QC0a Workflow Consolidation -toimeksiannosta valmisteltu yksi READY-kortti erillisessä tehtäväworktreessä paikallisesta `origin/main`-viitteestä. Tämä on tehtävän valmistelu; teknistä toteutusta tai tuotanto-QC0a:ta ei käynnistetty.

- 2026-10-22T14:51:41+03:00: Uusi luvanäyttö sidottu repo-ulkoiseen yksityiseen evidenssiin; aiempi lupasoveltuvuuden puute päivitetty rajatun paikallisen käsittelyn osalta. Yksityinen lukijaehdokas SHA-256 `1ad5fe5047c4746f416e766a1e8afcf94cae3c51c485d6518cff12e31279fbb3`; aiempi 18/18 ja uusi 11/11 synteettinen validointi PASS. Portit PASS. QFOT2:n riippumaton loppukatselmointi ja suojatun ajon erottaminen mallipalvelusta ovat edelleen avoimia; PRODUCTION_QC0A_RUN=NOT_RUN.

- 2026-10-22T15:26:44+03:00: Erillinen riippumaton vain-luku-katselmointi SHA-256-versiolle `1ad5fe5047c4746f416e766a1e8afcf94cae3c51c485d6518cff12e31279fbb3` valmis: rajattu paikallisajo PASS-ehdoin. Tarkistaja ajoi synteettiset 11/11 ja aiemmat 18/18; tuotantoajo NOT_RUN katselmoinnissa. `..`-argumentti hylätty; oikea työjuuri on päächeckoutin Fear-of-Falling ja argumentti `.`. Väliaikaisen koodisijainnin hash tarkistetaan välittömästi ennen ajoa.

## Blockers

- Oikean työkirjan avaaminen ja raakamuotoisen otsakemanifestin tuottaminen pysyvät kiellettyinä, kunnes olemassa olevan aineistovaltuutuksen soveltuvuus on osoitettu tai vain puuttuva rajaus on hyväksytty toimivaltaisesti.
- Kriittinen suojausvika tai suojatun sisällön vuotoriski pysäyttää tuotantokelpoisuuden; tavallinen synteettinen testivika korjataan ja testataan uudelleen tässä samassa tehtävässä.

## Links

- `Fear-of-Falling/README.md`
- `AIM1_ANALYSIS_GUIDANCE_PACKAGE/README.md`
- Yksityiset `AIM1_QC0_HOTL_AUTHORITY_REUSE_VERDICT.md`, `AIM1_QC0_EXISTING_AUTHORITY_DECISION.md` ja `AIM1_QC0_INTEGRATED_TECHNICAL_CLOSURE.md` (ei kopioida julkiseen repositoryyn).

## 2026-10-22 jatkovaltuutuksen mukainen lopputila

Käyttäjän tämän tehtävän jatkotoimeksianto salli riippumattoman loppukatselmoinnin jälkeen yhden rajatun paikallisen QC0a-ajon. Tämä tarkennus korvaa yllä olevan alkuperäisen `PRODUCTION_QC0A_RUN = NO` -valmistelurajan vain tämän nimetyn ajon osalta. Katselmoitu lukija SHA-256 `1ad5fe5047c4746f416e766a1e8afcf94cae3c51c485d6518cff12e31279fbb3`; importoitu safety-moduuli SHA-256 `b5a5554561f68ace07b3a8bb3cbd5f736b68ce8a23815a60065b9137eaf7852a`. Riippumaton tekninen katselmointi: `PASS_FOR_BOUNDED_LOCAL_RUN`; synteettinen validointi: uusi 11/11 ja aiempi 18/18 PASS. Oikea työjuuri oli päächeckoutin `Fear-of-Falling/` ja argumentti `.`.

`PRODUCTION_QC0A_RUN = PASS`; yksi yksityinen 0600-otsakemanifesti luotu; suojattu stdout/stderr ohjattu pois mallikontekstista. `AGGREGATE_QC_RUN = NO`; `ANALYSIS_RUN = NO`. Yksityinen ajokuitti on repo-ulkopuolella. Raakoja otsakkeita, osallistuja-arvoja, tunnisteita tai manifestin sisältöä ei lisätä repositoryyn tai tähän korttiin. Väliaikaisessa `/usr/tmp`-sijainnissa oleva koodi tarvitsee saman hashin tarkistuksen ennen mahdollista myöhempää uudelleenkäyttöä.

- 2026-10-22T15:27:48+03:00: Rajattu tuotanto-QC0a PASS; yksityinen ajokuitti kirjattu ja tehtävä siirretty 03-review-tilaan ihmisen hyväksyntää varten. `04-done` ja Git-toimitus eivät sisälly tähän siirtoon.
