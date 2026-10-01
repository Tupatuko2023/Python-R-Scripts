# DEAC: MOI ikäpisteiden poisto ja kvintiilipisteytys

## Tila

- State: `03-review`
- Ownerin toimeksianto: 2026-10-01, erillinen synteettinen MOI-toteutus.
- Lähtöcommit: `5ae1c8ec830715d0b5976314273fa2b91fea9b7a` (PR #173).

## Auktoriteetti ja vahvistetut säännöt

- `DEAC-Frailty-Index/docs/DEAC_HANDOVER.md` v1.1.0, §5 komponentti 4,
  SHA-256 `7E83E4FE34BEF5A4ADC548F6E67663EA343C94E68844739C37E046A4226A2539`.
- Owner vahvisti 2026-10-01: lähtötilanteen MOI-indeksi sisältää ikäpisteet;
  käytetään lähtötilanteen ikää; ikäpisteet vähennetään täsmälleen kerran;
  kvintiilit muodostetaan ikäpisteettömästä MOI:sta DEAC-analyysin
  lähtötilanteen kohortissa.
- Saman ikäpisteettömän MOI-arvon tulee saada aina sama DEAC-piste.
- Waris ym. 2011 §4.1:n viimeinen ikämerkintä on `75 years`; yli 75-vuotiaiden
  käsittelyä ei laajenneta ilman käytetyn KAAOS/MOI-ohjeen lähdetukea.
- Lähdekenttien tarkat nimet ja sovitin kuuluvat suojattuun ympäristöön, eivät
  tähän julkiseen toteutukseen.

## Rajaus

- Toteuta synteettisesti testattavat, puhtaat MOI-apufunktiot: Waris 2011
  ikäpisteet dokumentoiduille ikäluokille, lähtötilanteen MOI-indeksin
  ikäpisteiden vähennys kerran sekä kohorttikohtainen viiden kvintiilin
  sovitus ja pisteytys.
- Dokumentoi kvantiilien laskentamenetelmä ja tasatulosten käsittely niin,
  että identtiset ikäpisteettömät MOI-arvot saavat saman pisteen.
- Hylkää ratkaisematon yli 75-vuotiaiden ikäpisteytys näkyvästi; älä päättele
  `75 years` -merkinnästä ylärajaa.
- Älä lisää lähdeheadereita, lähdeadapteria, osallistuja-aineiston lukua,
  tuotantoajoa tai muiden DEAC-komponenttien muutoksia.
- Älä muuta hyväksyttyä handoveria tai muita tieteellisiä sääntöjä.

## Definition of Done

- [x] Toteutus käyttää vain synteettisissä testeissä annettuja arvoja eikä lue
  lähdeaineistoa.
- [x] Testit kattavat tunnetut ikäpisteet, yhden vähennyksen, kvintiilirajat,
  puuttuvuuden ja tasatulokset; sama arvo saa saman pisteen.
- [x] Yli 75-vuotiaiden säännön lähde tarkistettiin saatavilla olevasta
  lähdejäljestä;
  jos sitä ei löydy, ikä hylätään näkyvästi eikä lähdeaukkoa täytetä oletuksella.
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
