# DEAC20: kahdeksan kyselykomponentin varmennetut lähdesidonnat

## Tausta

Ihmisomistajan 21.11.2026 valtuuttama rajattu työpaketti sitoo diabeteksen,
alkoholin, muistin, mielialan, unen, oman liikuntakyvyn, tasapainovaikeuden ja
kaatumisen pelon lähdekentät olemassa oleviin pisteyttäjiin. Suojatut otsakkeet,
sarakepaikat ja täsmäkoodisto pysyvät yksityisessä ajonaikaisessa konfiguraatiossa.
Nykyisen menetelmäkuvauksen auktoriteetti ja AIM1-kohderepon julkaisuvaltuutus
ovat tästä teknisestä synteettisestä työstä erillisiä.

## Syötteet

- Yksityinen, hash-varmennettu toimeksianto ja vain metadataa sisältävät lähteet.
- `DEAC-Frailty-Index/src/deac_components.py` ja nykyinen lähdesovitin.
- PRJ-AIM1-REPO-projektirekisteri.

## Tuotokset

- Kahdeksan kentän eristetty sidontarajapinta ja yleiset synteettiset testit.
- Yksityinen metadata- ja täsmäkoodistotarkistus ilman osallistujarivejä.
- Päivitetty projektitietue ja ignoroitu CSV-näkymä.
- Yksi katselmoitava PR main-haaraan; ei mergeä tässä tehtävävaiheessa.

## Sallitut kirjoituspolut

- `tasks/01-ready/TASK-DEAC20-K40-EIGHT-VERIFIED-BINDINGS-20261121.md` →
  `tasks/02-in-progress/` → `tasks/03-review/` saman tiedostonimen alla.
- `DEAC-Frailty-Index/src/deac_source_adapter.py`.
- `tests/test_deac_source_adapter.py`.
- `docs/governance/project_registry/PRJ-AIM1-REPO.md`.
- `tools/project_registry/outputs/projects.csv` vain ignoroituna johdannaisena.

Yksityinen tarkastusraportti ja ajonaikainen konfiguraatio säilytetään
vain toimeksiannossa rajatussa Git-ignoroidussa paikallisessa kohteessa.
Tämä kortti ei laajenna yksityistä kirjoitusrajausta.

## Valmistumiskriteerit

- Vain varmennetut kahdeksan sidontaa toteutettu ilman pisteytyssäännön,
  indeksikokoajan tai WALK500:n muutosta.
- Pisteytettävät arvot, puuttuvuus, tuntemattomat arvot ja väärä sidonta
  tarkistettu komponenttikohtaisesti synteettisesti; puuttuva lähdenäyttö
  rajaa vain riippuvan komponentin.
- Sovittimen ja pisteyttäjien regressiotestit sekä WALK500-tapaukset läpäisevät.
- Julkinen diff ja pushattava historia sisältävät vain hyväksytyt kirjoituspolut
  eivätkä suojattuja metatietoja, yksityistä raporttia tai osallistujadataa.
- Rekisteri ja sen CSV on validoitu. Kortti siirtyy `03-review`-tilaan;
  `04-done`, merge ja siivous odottavat erillistä hyväksyntää.

## Loki

- 2026-11-21T11:50:58+02:00 Kortti luotu ihmisomistajan valtuuttamana.
  Toimeksiannon ja kolmen metadatalähteen SHA-256 varmennettiin;
  eristetty työpuu perustettiin `origin/main`-revisiosta.
- 2026-11-21T11:59:17+02:00 Rajattu kahdeksan komponentin sovitin lisätty
  nykyisten pisteyttäjien eteen. Käännös ja `git diff --check` läpäisivät.
  Yksityinen metadataan sidottu tarkistus läpäisi 117/117 synteettistä väitettä;
  komponenttikohtaiset määrät ovat vain Git-ignoroidussa tarkastusraportissa.
  Repojuuren sovitin- ja pisteyttäjätestit läpäisivät 349/349 eristetyllä
  Python 3.14.6 / pytest 9.1.1 -tulkilla, mukaan lukien WALK500.
  Osallistujarivejä, tuotantotyökirjaa tai indeksiä ei ajettu.
- 2026-11-21T11:59:47+02:00 Kortti siirretty `03-review`-tilaan
  teknisen toteutuksen ja synteettisten testien jälkeen. Ihmisomistajan
  sisältöhyväksyntä ja main-toimitus odottavat.

## Esteet

- Nykyisen §3.1:n auktoriteetti ja AIM1-kohderepon julkaisuvaltuutus
  säilyvät erillisinä avoimina kysymyksinä.

## Linkit

- `docs/governance/project_registry/PRJ-AIM1-REPO.md`
