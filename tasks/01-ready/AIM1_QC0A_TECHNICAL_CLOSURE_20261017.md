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

- 2026-10-17: Ownerin rajatusta QC0a Workflow Consolidation -toimeksiannosta valmisteltu yksi READY-kortti erillisessä tehtäväworktreessä paikallisesta `origin/main`-viitteestä. Tämä on tehtävän valmistelu; teknistä toteutusta tai tuotanto-QC0a:ta ei käynnistetty.

## Blockers

- Oikean työkirjan avaaminen ja raakamuotoisen otsakemanifestin tuottaminen pysyvät kiellettyinä, kunnes olemassa olevan aineistovaltuutuksen soveltuvuus on osoitettu tai vain puuttuva rajaus on hyväksytty toimivaltaisesti.
- Kriittinen suojausvika tai suojatun sisällön vuotoriski pysäyttää tuotantokelpoisuuden; tavallinen synteettinen testivika korjataan ja testataan uudelleen tässä samassa tehtävässä.

## Links

- `Fear-of-Falling/README.md`
- `AIM1_ANALYSIS_GUIDANCE_PACKAGE/README.md`
- Yksityiset `AIM1_QC0_HOTL_AUTHORITY_REUSE_VERDICT.md`, `AIM1_QC0_EXISTING_AUTHORITY_DECISION.md` ja `AIM1_QC0_INTEGRATED_TECHNICAL_CLOSURE.md` (ei kopioida julkiseen repositoryyn).
