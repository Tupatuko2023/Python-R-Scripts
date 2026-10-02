# DEAC: MOI ikäpisteiden poisto ja kvintiilipisteytys

## Tila

- State: `03-review`
- Ownerin toimeksianto: 2026-10-01, erillinen synteettinen MOI-toteutus.
- Lähtöcommit: `5ae1c8ec830715d0b5976314273fa2b91fea9b7a` (PR #173).

## Auktoriteetti ja vahvistetut säännöt

- `DEAC-Frailty-Index/docs/DEAC_HANDOVER.md` v1.1.0, §5 komponentti 4,
  SHA-256 `7E83E4FE34BEF5A4ADC548F6E67663EA343C94E68844739C37E046A4226A2539`.
- Ownerin 2026-10-01 vahvistama soveltamistulkinta on sittemmin kirjattu
  yksityiseen `DECISION_LOG.md`-tiedostoon tunnuksella `DMA1-D-012` sekä
  kanonisen `METHODS_AND_SCORING.md` §3.1:een. Näiden Ownerin toimittamat
  SHA-256-viitteet ovat `131DAB0920ED047422B5F228980489BAB29973E382B8A29BB6909FE6DB82C480`
  ja `4FD2DDF3D19268FEF09B90AA0D7AD8095DADB417B2601238FCFBEBF1EC7AAAEF`.
  Yksityisiä tiedostoja ei kopioida julkiseen repoon.
- Owner vahvisti 2026-10-01: lähtötilanteen MOI-indeksi sisältää ikäpisteet;
  käytetään lähtötilanteen ikää; ikäpisteet vähennetään täsmälleen kerran;
  kvintiilit muodostetaan ikäpisteettömästä MOI:sta DEAC-analyysin
  lähtötilanteen kohortissa.
- Saman ikäpisteettömän MOI-arvon tulee saada aina sama DEAC-piste.
- Waris ym. 2011 §4.1:n viimeinen ikämerkintä on `75 years`; Ownerin
  soveltamistulkinta on lähtötilanteen ikä `>=75` → 6 ikäpistettä. Tämä
  tulkinta ei ole artikkelin eksplisiittinen ikäraja (DMA1-D-012).
- Lähdekenttien tarkat nimet ja sovitin kuuluvat suojattuun ympäristöön, eivät
  tähän julkiseen toteutukseen.

## Rajaus

- Toteuta synteettisesti testattavat, puhtaat MOI-apufunktiot: Waris 2011
  ikäpisteet dokumentoiduille ikäluokille, lähtötilanteen MOI-indeksin
  ikäpisteiden vähennys kerran sekä kohorttikohtainen viiden kvintiilin
  sovitus ja pisteytys.
- Dokumentoi kvantiilien laskentamenetelmä ja tasatulosten käsittely niin,
  että identtiset ikäpisteettömät MOI-arvot saavat saman pisteen.
- Käytä Ownerin hyväksymää `>=75 → 6` -tulkintaa; älä esitä sitä Waris
  2011:n eksplisiittisenä ylärajana.
- Älä lisää lähdeheadereita, lähdeadapteria, osallistuja-aineiston lukua,
  tuotantoajoa tai muiden DEAC-komponenttien muutoksia.
- Älä muuta hyväksyttyä handoveria tai muita tieteellisiä sääntöjä.

## Definition of Done

- [x] Toteutus käyttää vain synteettisissä testeissä annettuja arvoja eikä lue
  lähdeaineistoa.
- [x] Testit kattavat tunnetut ikäpisteet, yhden vähennyksen, kvintiilirajat,
  puuttuvuuden ja tasatulokset; sama arvo saa saman pisteen.
- [x] Yli 75-vuotiaiden käsittely perustuu Ownerin soveltamistulkintaan
  DMA1-D-012; lähteen `75 years` -sanamuoto ja Ownerin `>=75 → 6` -sääntö
  erotetaan toisistaan.
- [x] Dokumentoitu toteutus ei paljasta suojattuja kenttänimiä tai
  osallistujatietoja.
- [x] Soveltuva repository-gate ja kohdennetut Python-testit läpäisevät.
- [x] Tehtävä ja rajattu koodimuutos palautetaan Ownerin katselmointiin PR:ssä;
  agentti ei mergeä.

## Loki

- 2026-10-01T19:19:38+03:00: Owner antoi nimenomaisen orkestroijan käskyn
  luoda MOI-tehtävä ready-jonoon; taski kirjattu PR #173:n main-commitista
  erilliseen puhtaaseen työpuuhun. Osallistuja-aineistoa ei avattu.
- 2026-10-01T19:20:15+03:00: Tehtävä valittiin ready-jonosta ja siirrettiin
  `02-in-progress`-tilaan ennen toteutuksen aloittamista.
- 2026-10-01T19:22:00+03:00: Toteutettu erilliset puhtaat apufunktiot
  ikäpisteille, kertaluonteiselle vähennykselle ja R-7-kvintiileille;
  tasatulokset kuuluvat saman rajan alempaan luokkaan. Yli 75-vuotiaat
  epäonnistuvat näkyvästi, koska tarkistetuissa lähdeohjeissa ei ole tätä
  ikäluokan laajennusta.
- 2026-10-01T19:26:11+03:00: DEAC:n kohdennetut testit läpäisivät
  (`uv run --offline --no-project --with pytest python -B -m pytest -q
  tests/test_deac_moi.py tests/test_deac_components.py tests/test_deac_index.py`;
  250 passed). `bash tools/run-gates.sh --mode pre-push --smoke` exit 0;
  `git diff --cached --check` exit 0. Paikallisia Prettier/markdownlint-binäärejä
  ei ole asennettuna; Markdown CI tarkistaa README-muutoksen PR:ssä.
- 2026-10-01T19:27:00+03:00: Paikallinen Definition of Done täyttyi; sama tehtävä
  siirrettiin `03-review`-tilaan ja rajattu neljän tiedoston diff valmistellaan
  Ownerin PR-katselmointiin.
- 2026-10-01T19:30:03+03:00: PR #174 avattiin commitista
  `420a3ea4b611978d44ef6c3fa71f3b63bbee2f53`. GitHubin Python-testit,
  Markdown-lint, CodeQL/Sourcery-analyysit ja smoke-muutostunnistus läpäisivät;
  K-skriptien smoke-ajo ohitettiin, koska muutos ei koske niitä. PR odottaa
  Ownerin katselmointia; agentti ei mergeä.
- 2026-10-02: Edellä mainitut 2026-10-01 kohdat, joissa ikäluokan
  soveltaminen kuvattiin avoimeksi, ovat historiallista tilaa ja ne on
  korvattu nykyisellä DMA1-D-012-provenienssilla. Nykyinen sääntö on
  lähtötilanteen ikä `>=75` → 6; päätöstä ei avata uudelleen.
