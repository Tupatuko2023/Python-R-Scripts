# DEAC: 14 komponentin ensimmäinen synteettinen pisteytyserä

## Tila

- State: `03-review`
- Ownerin tehtävänanto: 2026-09-30, kaksi rajattua työjonoa
- Scope: vain 14 komponentin puhtaat pisteytysfunktiot ja synteettiset testit

## Auktoriteetti

- `DEAC-Frailty-Index/docs/DEAC_HANDOVER.md` v1.1.0,
  SHA-256 `7E83E4FE34BEF5A4ADC548F6E67663EA343C94E68844739C37E046A4226A2539`.
- Hyväksytty mittari sisältää 20 komponenttia; tämä erä ei laske indeksiä,
  nimittäjää eikä 80 prosentin kelpoisuutta.
- Suojattu K40-kartta koskee skeemaa, ei tuotantoaineiston laskentavaltuutusta.

## Tuotokset ja rajat

- Tee erilliseen haaraan 14 sääntövalmista komponenttia kuvaava puhdas Python-API
  ja vastaavat synteettiset testit. Pidä syöteheaderit ja lähdekohtaiset
  erityiskoodit erillisessä suojatussa sidonnassa, ei julkisessa koodissa.
- Testaa hyväksytyt pisteet, puuttuva syöte, tuntemattoman koodin fail-closed
  sekä kuulon/näön 3 → 1 ja 4 → puuttuva.
- Neurologisen yhdistelmän osittain puuttuvat osasyötteet ovat erillisiä
  testitapauksia; avoimeen tapaukseen ei keksitä pistettä.
- Älä lue osallistujarivejä, muodosta 14 komponentin vaihtoehtoindeksiä
  tai toteuta kuutta vielä lähdeselvitystä odottavaa komponenttia.

## Definition of Done

- [x] Koodidiffissä ei ole suojattuja headereita tai koodistoja.
- [x] Kaikki 14 hyväksyttyä sääntöä ja rajatut puuttuvuustapaukset testattu
  synteettisesti, ilman tuotantodataa.
- [x] Repositoryn soveltuva gate ja Python-testit ajettu; tulokset kirjattu.
- [x] Avoin neurologisen osittaisen puuttuvuuden tulkinta raportoitu ilman
  oletuspistettä.
- [x] Paikallinen diff ja testitulokset palautettu Ownerille ennen commitia,
  pushia tai PR:ää.

## Log

- 2026-09-30T19:46:21+03:00 Ownerin toimeksianto vastaanotettu; ready-tehtävä
  kirjattu erillisessä, origin/main-pohjaisessa työpuussa. Ei data-ajoa.
- 2026-09-30T19:48:01+03:00 Valittu ready-jonosta ja siirretty
  `02-in-progress`-tilaan. Toinen, lähdeprotokollia koskeva tehtävä jäi
  erikseen ready-jonoon.
- 2026-09-30T20:05:58+03:00 Synteettiset testit:
  `uv run --offline --no-project --with pytest python -B -m pytest -q ../tests/test_deac_components.py`
  (DEAC-aliprojektin juuresta), exit 0, 121 läpäistyä. Staged-diffin
  `git diff --cached --check` exit 0. Repon
  `bash tools/run-gates.sh --mode pre-push --smoke` exit 0.
  Osittain puuttuva neurologinen syöte nostaa tarkistettavan poikkeuksen;
  hyväksyttyä pisteytysratkaisua ei ole päätelty. Tehtävä siirretty
  `03-review`-tilaan ja paikallinen diff palautetaan Ownerin katselmointiin;
  ei commitia, pushia eikä PR:ää.
- 2026-09-30T20:33:13+03:00 Ownerin koodikatselmoinnin jatkotehtävä:
  neurologisen yhdistelmän tunnettu 1 palauttaa 1 myös muiden osasyötteiden
  puuttuessa; vain ilman tunnettua 1:tä osittainen puuttuvuus jää avoimeksi.
  Moduulin puuttuvuusrajaus ja synteettiset ylärajan ylittävät testit
  täsmennetty. Kuuden muun komponentin lähdeselvitys ei kuulu tähän PR:ään.
- 2026-09-30T20:35:49+03:00 Korjatun erän testit:
  `uv run --offline --no-project --with pytest python -B -m pytest -q ../tests/test_deac_components.py`
  (DEAC-aliprojektin juuresta), exit 0, 136 läpäistyä.
  `git diff --cached --check`, exit 0, ja
  `bash tools/run-gates.sh --mode pre-push --smoke`, exit 0.
  Vain 14 komponentin rakennusosat ja niiden dokumentaatio valitaan
  PR:ään; suojattua lähdeadapteria ja DEAC-indeksin laskentaa ei ole.
