# DEAC20: neurologisen yhdistelmän varmennettu lähdesidonta

## Tausta

Ihmisomistajan 21.11.2026 valtuuttama työpaketti rajaa työn kolmeen
neurologiseen osakenttään ja jo olemassa olevaan pisteyttäjään. Yksityinen
lähdevalmistelu on tarkistettu tiivisteillä. Nykyisen §3.1:n auktoriteetti,
tuotantorivin alkuperä ja AIM1-kohderepon julkaisuvaltuutus ovat erillisiä.

## Sallitut kirjoituspolut

- Tämä kortti elinkaaripoluissa `tasks/01-ready/`, `tasks/02-in-progress/`
  ja `tasks/03-review/` samalla tiedostonimellä.
- `DEAC-Frailty-Index/src/deac_source_adapter.py`
- `tests/test_deac_source_adapter.py`
- `docs/governance/project_registry/PRJ-AIM1-REPO.md`
- `DEAC-Frailty-Index/outputs/` vain yksityiselle, ignoroidulle
  metadata- ja synteettiselle tarkastusnäytölle.
- `tools/project_registry/outputs/projects.csv` vain ignoroituna johdannaisena.

## Toteutus ja hyväksymisehdot

- Lisää eristetty kolmen semanttisen kentän rajapinta nykyiseen sovittimeen.
  Varmenna kutsujan antama hash, metadatapositio, otsake, selite ja sidontojen
  yksikäsitteisyys ennen rivin lukemista. Käytä nykyistä `score_neurological`-
  pisteyttäjää muuttamatta sitä.
- Salli vain kunkin osakentän `0`, `1` ja tavallinen `None`. Hylkää
  dokumentoimattomat puuttuvuusalias-koodit, väärät tyypit, tuntemattomat
  koodit ja `NOT_APPLICABLE`.
- Testaa 27 synteettistä yhdistelmää, jokaisen kentän virheelliset arvot,
  väärä metadata ja regressiot, myös WALK500 ja kahdeksan kentän erä.
- Pidä täsmämetadata, lähdeotteet ja yksityinen tarkistusnäyttö poissa
  julkisesta diffistä ja pushattavasta historiasta. Älä lue osallistujarivejä.
- Päivitä PRJ-AIM1-REPO ja generoi sekä tarkista ignoroitu CSV. Julkinen
  toimitus sisältää vain neljä yllä nimettyä seurattua tiedostoa.

## Loki

- 2026-11-21T18:34:02+02:00 Kortti luotu ihmisomistajan valtuuttamana.
  Yksityisen toimeksiannon ja manifestin tiedostotiivisteet varmennettiin;
  eristetty työpuu perustettiin `origin/main`-commitista
  `9acc14240de042d7f73cb0440a7e4d3004976b4a`.
- 2026-11-21T18:37:55+02:00 Kortti siirrettiin `02-in-progress`-tilaan.
  Neurologinen eristetty sidonta toteutettiin muuttamatta pisteyttäjää.
  Julkiset sovitin- ja pisteyttäjätestit läpäisivät 412/412.
  Erillinen metadatatarkistus dokumentoitiin paikallisesti.

- 2026-11-21T18:55:09+02:00 Jatkettiin samassa eristetyssä työpuussa
  ajantasaiselta `origin/main`-pohjalta. DEAC-testit läpäisivät 493/493,
  mukaan lukien sovitin- ja pisteyttäjätestit. `PRJ-AIM1-REPO` päivitettiin
  ja kortti siirrettiin `03-review`-tilaan.

- 2026-11-21T19:58:59+02:00 Varmennettiin hyväksyntä ja main-toimitus.
  Kortti siirrettiin teknisesti `04-done`-jonoon sulkuhaaraan ja
  projektirekisterin tehtäväviite päivitettiin.

## Hyväksyntä ja main-toimitus

- Ihmisomistaja `Tupatuko2023` hyväksyi 2026-11-21T17:35:39Z tämän tehtävän
  neurologisen lähdesidonnan PR:ssä #245, rajattuna HEADiin
  `26369127646774e2bf15294f28f34863021376a6`.
  [Pysyvä hyväksyntänäyttö](https://github.com/Tupatuko2023/Python-R-Scripts/pull/245#issuecomment-7066599156)
- PR #245 toimitettiin mainiin 2026-11-21T17:37:31Z squash-commitilla
  `7f544327e6ddcf0fa456d4eafcbc01f1f5f1a270`. Commit varmennettiin `origin/main`ista
  ja sen tiedostopuu vastasi hyväksyttyä HEADia.
- Python CI, Markdown CI ja CodeQL läpäisivät. Sourceryn katselmointi ohitettiin
  kiintiön vuoksi. Työpuu ja toteutushaarat on kirjattu säilytettäviksi.

## Tila

- DONE. Neurologisen lähdesidonnan rajattu tehtävä on toimitettu.

## Esteet

- Nykyisen §3.1:n auktoriteetti ja AIM1-kohderepon julkaisuvaltuutus ovat
  avoimia jatkoasioita. Ne eivät estä tätä synteettistä sidontatyötä.
