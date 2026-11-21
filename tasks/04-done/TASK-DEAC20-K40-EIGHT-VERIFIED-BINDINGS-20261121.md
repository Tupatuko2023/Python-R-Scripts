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
- PR #242:n rajattu toteutus toimitettu mainiin; tekninen sulkukirjaus
  toimitetaan erillisellä katselmoitavalla PR:llä.

## Sallitut kirjoituspolut

- `tasks/01-ready/TASK-DEAC20-K40-EIGHT-VERIFIED-BINDINGS-20261121.md` →
  `tasks/02-in-progress/` → `tasks/03-review/` → `tasks/04-done/`
  saman tiedostonimen alla ihmisomistajan täsmähyväksynnän jälkeen.
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
- Rekisteri ja sen CSV on validoitu. Kortin tekninen `04-done`-tila
  perustuu ihmisomistajan pysyvään hyväksyntäkommenttiin; sulkukirjauksen
  main-toimitus ja työpuiden siivous kirjataan erikseen.

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
- 2026-11-21T12:06:07+02:00 Neljän tiedoston diff ja pushattava historia
  tarkastettiin. Repoportit, Markdownlint, Prettier ja rekisterin CSV-tarkistus
  läpäisivät. Haara puskettiin ja PR #242 avattiin main-haaraan
  ihmiskatselmointia varten; sitä ei ole yhdistetty.
- 2026-11-21T12:13:01+02:00 Sourceryn kolmesta huomiosta korjattiin
  riviarvon kertalukeminen ja tyylin pitkät rivit. Varmennettujen kenttien
  osajoukko voidaan pisteyttää, kun toisen kentän lähdenäyttö puuttuu.
  Rajatut julkiset regressiotestit läpäisivät 351/351 ja erillinen yksityinen
  metadatatarkistus 117/117 synteettistä väitettä. Päivityksen repoportit,
  CI ja katselmointi tarkistetaan ennen lopullista toimitusraporttia.
- 2026-11-21T12:45:20+02:00 Ihmisomistajan GitHub-kommentti
  [PR #242:ssa](https://github.com/Tupatuko2023/Python-R-Scripts/pull/242#issuecomment-7061421906)
  varmennettiin: tekijä `Tupatuko2023`, aika 2026-11-21T10:42:55Z,
  tehtävä tämä kahdeksan komponentin sidontapaketti ja hyväksytty HEAD
  `7b1a0e346c08155f63f3b57913b841361293ad4c`. Kaikki PR:n
  soveltuvat CI-tarkistukset olivat SUCCESS tai tarkoituksella SKIPPED;
  Sourceryn aiemmat kolme huomautusta käsiteltiin eikä avoimia
  review-ketjuja ollut. Aiemman revision kirjallista Sourcery-hyväksyntää
  ei luettu nykyisen revision hyväksynnäksi.
- 2026-11-21T12:45:20+02:00 PR #242 yhdistettiin mainiin squash-commitilla
  `de0a68b34d960a3cccac6319ceab9de4ea6ffc0f`. PR:n MERGED-tila,
  hyväksytty HEAD ja merge-commit varmennettiin GitHubista; commit
  varmennettiin `origin/main`-haaran kärjeksi. Kortti siirrettiin
  teknisesti `04-done`-tilaan erillistä sulku-PR:ää varten.
- 2026-11-21T12:48:23+02:00 Sulun dokumentti- ja rekisterivalidointi
  läpäisivät. Rekisterin 62 testistä 58 läpäisi Termux-Pythonissa;
  neljä kovien linkkien testiä pysähtyi ympäristön puuttuvaan `os.link`-
  tukeen. Nämä neljä läpäisivät erikseen Debianin `/usr/bin/python3`-
  tulkissa. Rekisterin CSV muodostettiin Git-ignoroituun tulospolkuun.

## Sulkutila

- Tekninen toteutus ja PR #242:n main-toimitus: valmis ja varmennettu.
- Tämän `04-done`-kirjauksen main-toimitus: odottaa sulku-PR:n omaa
  ihmisarviointia ja yhdistämistä.
- Toteutus- ja sulkutyöpuun siivous: tekemättä; erillinen nimetty
  poistovaltuutus tarvitaan.

## Esteet

- Nykyisen §3.1:n auktoriteetti ja AIM1-kohderepon julkaisuvaltuutus
  säilyvät erillisinä avoimina kysymyksinä.

## Linkit

- `docs/governance/project_registry/PRJ-AIM1-REPO.md`
- `https://github.com/Tupatuko2023/Python-R-Scripts/pull/242`
