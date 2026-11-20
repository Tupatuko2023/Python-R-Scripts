# DEAC20: 500 m kävelyvaikeuden rajattu lähdesidonta

## Tausta

Yksityinen, hash-varmennettu toimeksianto rajaa ensimmäisen komponentin
lähdesidonnan. Nykyinen komponenttipisteyttäjä kattaa pisteytettävät luokat;
tehtävä lisää tarvittaessa vain yhden komponentin eristetyn sidonnan ja
synteettisen varmennuksen. Lähteen tarkka skeema ja koodiselite pysyvät
erillisessä yksityisessä toimituksessa. Tämä kortti ei hyväksy menetelmää,
tuotantoajoa eikä AIM1-kohderepon julkaisua.

## Syötteet

- PRS:n nykyinen `deac_components.py` ja `deac_source_adapter.py`.
- Erikseen toimitettu yksityinen, vain metadataa sisältävä lähdepaketti.
- Ihmisomistajan 20.11.2026 antama rajattu toteutusvaltuutus.

## Tuotokset

- Yhden 500 m -komponentin lähdesidottu, synteettisesti testattava tulos.
- Yksityinen täsmäskeeman ja koodiselitteen tarkastusraportti.
- Päivitetty `PRJ-AIM1-REPO`-tilanne ja generoitu rekisterin CSV.

## Sallitut kirjoituspolut

- `tasks/01-ready/TASK-DEAC20-K40-WALK500-FIRST-BINDING.md` →
  `tasks/02-in-progress/` → `tasks/03-review/` → `tasks/04-done/`
  saman tiedostonimen alla. Viimeinen siirto tehtiin ihmisomistajan
  täsmähyväksynnän jälkeen repo-ohjeen mukaisena teknisenä sulkuna.
- `DEAC-Frailty-Index/src/deac_source_adapter.py` vain todettuun rajapinta-aukkoon.
- `tests/test_deac_source_adapter.py` vain synteettisiin yleisiin testeihin.
- `docs/governance/project_registry/PRJ-AIM1-REPO.md`.
- `tools/project_registry/outputs/projects.csv` vain ignoroituna johdannaisena.

Yksityinen täsmäsidonta ja raportti kirjoitetaan vain toimeksiannon nimeämään
Git-ignoroituun yksityiseen tuloshakemistoon. Muita seurattuja polkuja ei muuteta.

## Valmistumiskriteerit (DoD)

- Lähdemetadata varmennettu ilman osallistujarivejä.
- Pisteyttäjä käytetään muuttumattomana; dokumentoimaton koodi ja väärä
  lähdesidonta hylätään, lähteen puuttuvuus käsitellään ennen pisteytystä.
- Rajatut synteettiset testit ja yksi smoke-ajo suoritettu; tulokset kirjattu.
- Julkinen diff sisältää vain yleisen koodin, synteettiset testit ja
  hallintadokumentaation. Yksityiset lähdetekstit ja polut pysyvät ulkona.
- Rekisteri ja CSV validoitu. Tehtävä siirretään katselmointiin, ei `04-done`.

## Loki

- 2026-11-20T20:17:15+02:00 Tehtäväkortti luotu ihmisomistajan valtuuttamana;
  toimeksiannon SHA-256 ja suojatun metadatalähteen tiivisteet varmennettu.
- 2026-11-20T20:17:58+02:00 Kortti siirretty `02-in-progress`-tilaan;
  `tools/run-gates.sh --mode pre-push --smoke` läpäisi ja rekisterin
  kirjoitussuoja palautti `OK`.
- 2026-11-20T20:24:49+02:00 Yhden komponentin lähdesidonta lisätty
  olemassa olevan pisteyttäjän eteen. Yksityinen metadata- ja
  täsmäkoodistotarkistus läpäisi 16/16 synteettistä tapausta; alkuperäisen
  `tests/test_deac_source_adapter.py`-tiedoston rajattu ajo läpäisi 70/70
  testiä eristetyssä Python 3.14.6 / pytest 9.1.1 -ympäristössä.
  `git diff --check`, Python-käännös sekä repoportin smoke-tarkistus läpäisivät.
  Testiriippuvuudet asennettiin vain paikallisesta välimuistista `--offline`.
  Osallistujarivejä ei luettu, eikä indeksikokoajaa tai pisteyttäjää muutettu.
- 2026-11-20T20:25:47+02:00 Kortti siirretty `03-review`-tilaan
  teknisen toteutuksen ja rajattujen testien valmistuttua.
  Ihmisomistajan sisältöhyväksyntä ja mahdollinen PR-toimitus odottavat;
  tätä korttia ei siirretty `04-done`-tilaan.
- 2026-11-20T21:13:17+02:00 Julkisen toimituksen neljä tiedostoa ja
  pushattava historia tarkistettu; haara puskettiin ja PR #239 avattiin
  main-haaraan. Ihmisomistajan täsmähyväksyntä, CI-katselmointi ja
  main-toimitus odottavat.
- 2026-11-20T21:17:45+02:00 PR #239:n lint löysi rekisteritaulukon
  Prettier-muotoilupoikkeaman. Taulukon sarakeleveydet korjattu;
  paikallinen Prettier-, markdownlint-, CSV- ja diff-tarkistus läpäisi.
- 2026-11-20T21:24:27+02:00 Sourceryn kirjallinen katselmointi toi
  seitsemän huomiota. Pisteytettävän numeerisen arvon puuttuvuusalias,
  monitulkintainen fyysinen otsake ja vaihtoehtoinen synteettinen otsake
  käsiteltiin koodissa ja testeissä. Rajattu pytest-ajo 75/75 PASS ja
  yksityinen metadataan sidottu synteettinen tarkistus 16/16 PASS.
  Tuotantokohortin integrointi ja rivin alkuperän todistus eivät kuulu
  tämän yhden komponentin eristettyyn tekniseen pilottiin.
- 2026-11-20T21:28:33+02:00 Toisen, edeltävään revisioon kohdistuneen
  Sourcery-katselmoinnin lisähuomiot käsitelty: semanttinen selite
  tarkistetaan seliteriviltä, sidonta luetaan paikallisesta kopiosta,
  ja synteettinen testi sisältää toisen kentän sekä `None`-puuttuvuuden.
  Tehtäväkortin otsikot käännetty suomeksi. Rajattu pytest-ajo
  78/78 PASS ja yksityinen metadataan sidottu tarkistus 16/16 PASS.
- 2026-11-20T21:56:44+02:00 Ihmisomistaja `Tupatuko2023` hyväksyi
  PR #239:n täsmärevision `7bab41c48d294f55acabd763bc3ab1f4f93a40a9`
  ja kahden viimeisen Sourcery-huomion vastineet
  [pysyvässä GitHub-kommentissa](https://github.com/Tupatuko2023/Python-R-Scripts/pull/239#issuecomment-7049246851).
  Sourceryn kirjallista arviota ei kirjata hyväksytyksi.
- 2026-11-20T21:58:00+02:00 PR #239 yhdistettiin mainiin commitilla
  `2de6c1e516ee207aa8fb193d684807e31e3fbb33`; toimitus varmennettiin
  `origin/main`-haarasta. Hyväksytyn HEADin tarkistukset läpäisivät, eikä
  avoimia review-ketjuja ollut ennen yhdistämistä.
- 2026-11-20T21:59:27+02:00 Sama tehtävä siirrettiin teknisesti
  `03-review`-tilasta `04-done`-tilaan erillisessä sulkuhaarassa.
  Sulkukirjauksen PR-toimitus ja tämän tehtävän työpuiden siivous ovat
  vielä tekemättä; AIM1-projekti pysyy aktiivisena.

## Esteet

- Menetelmän nykyinen §3.1-auktoriteetti ja AIM1-kohderepon julkaisuvaltuutus
  pysyvät erillisinä avoimina asioina; ne eivät estä tätä paikallista
  synteettistä teknistä tehtävää.
- Tuotantokäyttö edellyttää, että kutsuja sitoo rivin ja metadatan samaan
  muuttumattomaan lähdeversioon. Tämä pilotti ei todista mielivaltaisen
  rivimappingin alkuperää eikä muuta kohorttiajoa.

## Linkit

- `docs/governance/project_registry/PRJ-AIM1-REPO.md`
- `https://github.com/Tupatuko2023/Python-R-Scripts/pull/239`
- `https://github.com/Tupatuko2023/Python-R-Scripts/pull/239#issuecomment-7049246851`
