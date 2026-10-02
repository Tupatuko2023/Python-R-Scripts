# DEAC:n K40-lähdenormalisoinnin yksiselitteiset tapaukset

## Tila

- State: `04-done`
- Type: synteettinen lähdenormalisointi

## Tavoite

Toteuta PR #178:n adapterin eteen rajattu normalisointikerros niille
K40-lähdetapauksille, joiden tulkinta on yksiselitteinen hyväksytyn
`DEAC_HANDOVER.md` v1.2.0:n ja varmennetun suojatun reunatapaustaulukon
perusteella. Tavoite ei ole tuotantolähteen sidonta tai osallistuja-ajo.

## Hyväksytty rajaus

- VAS on senttimetreinä; senttimetriarvo välitetään pisteytykseen ilman
  yksikkömuunnosta.
- VAS:n E/E1 ovat ei-numeerisia tavallisia puuttuvia arvoja, eivät
  toimintatestin suoriutumattomuutta.
- Jo valmiiksi hyväksytyn mittauksen semanttinen arvo välitetään adapterille
  muuttamatta mittausvalintaa tai arvoa. Jos mittaus ei ole jo valittu,
  normalisointikerros ei valitse sitä.
- Pidä K40:n täsmälliset otsikot ja suojattu koodisto runtime-määrityksessä;
  synteettisiin testeihin vain aliasarvot.

## Rajauksen ulkopuolella / avoimena säilytettävä

- Älä valitse parempaa jalkaa tai kättä kaksipuolisista syötteistä tässä
  erässä. Eri puolten E/E1/puuttuvat-yhdistelmät pysyvät ratkaisemattomina.
- Älä päättele toimintatestin E-koodista fyysistä/funktionaalista syytä ilman
  testikohtaista lähdenäyttöä.
- Älä päättele puuttuvasta 10 m ajasta suoriutumattomuuden syytä
  apuvälineluokasta.
- Älä lue osallistujarivejä, sovita kvintiilejä, aja kohorttia tai julkaise
  suojattuja kenttänimiä/koodistoja.
- Älä muuta handoverin tai pisteytyssääntöjen sisältöä.

## Definition of Done

- Muutos rajautuu normalisointiin ja synteettisiin testeihin (enintään viisi
  tiedostoa tässä ajossa).
- Testaa VAS:n senttimetriarvon muuttumaton välitys ja E/E1-puuttuvuus.
- Testaa, että ennalta valitun mittauksen arvo/status välittyy ilman
  uudelleenvalintaa; keskeneräinen valinta pysähtyy fail-closed.
- Testaa erikseen, että jalan/käden E/E1-yhdistelmistä ja puuttuvan 10 m ajan
  apuvälineluokasta ei tehdä automaattisia pisteytyspäätöksiä.
- Kohdennetut DEAC-pytestit ja tarkastettu repository-gate läpäisevät.
- Tehtävä ja loki eivät sisällä suojattuja headereita, osallistujarivejä tai
  esimerkkiarvoja.

## Työloki

- 2026-10-02T19:42:30+03:00: Ownerin nimenomaisella orkestrointikäskyllä
  matching ready-tehtävä luotu. Työ perustuu PR #178:n mainiin mergettyyn
  adapteriin, handover 1.2.0:aan ja suojattuun tapaustaulukkoon.
- 2026-10-02T19:43:10+03:00: Tehtävä siirretty ennen toteutusta tilaan
  `02-in-progress`. `tools/run-gates.sh --mode pre-push --smoke` läpäisi
  (exit 0); komennon sisäiset tarkistukset luettiin ennen ajoa.
- 2026-10-02T19:48:20+03:00: Lisätty VAS:n senttimetriarvon ja määritettyjen
  puuttuvuusaliasten normalisointi sekä jo valitun testituloksen
  läpivientirajapinta. Ei tehdä yksikkömuunnosta, mittausvalintaa eikä
  E-koodin syytulkintaa.
- 2026-10-02T19:49:19+03:00: `uv run --offline --no-project --with pytest
  pytest tests/test_deac_*.py -q` läpäisi (270 testiä); `git diff --check`
  läpäisi.
- 2026-10-02T19:49:19+03:00: Staged `bash tools/run-gates.sh --mode pre-push
  --smoke` läpäisi (exit 0): guardrails, renv, Python-syntaksi ja smoke-gatet.
- 2026-10-02T19:50:23+03:00: Lopullinen staged gate läpäisi exit 0 myös
  `03-review`-polussa olevan tehtävän kanssa. DoD täyttyy synteettiselle
  rajaukselle; tehtävä siirretty Ownerin katselmointiin `03-review`-tilaan.
  Aiemmin epäonnistunut
  gate-yritys johtui vain väliaikaisen bytecode-polun oikeuksista; onnistunut
  ajo käytti repon oletuspolkua.
- 2026-10-02T21:24:55+03:00: Riippumaton Owner-hyväksyntänäyttö: PR #179
  (<https://github.com/Tupatuko2023/Python-R-Scripts/pull/179>) yhdistettiin
  Owner-tunnuksella `Tupatuko2023` 2026-10-02T18:20:23Z. Hyväksytyn työn
  head `b1d334d0deb741998e206d7701bd3ce8b6f4d656`; merge-commit
  `30fca2d52b10bba2a2388e196d6b9a0887097ec7`. PR:n diff sisälsi tämän saman
  tehtävän `03-review`-tilassa. Tämä GitHub-merkintä on riippumaton näyttö;
  taskin oma merkintä ei muodosta hyväksyntää.
- 2026-10-02T21:24:55+03:00: Sama hyväksytty tehtävä teknisesti siirretty
  `04-done`-tilaan. Erillinen lifecycle-PR toimitetaan Ownerin arvioitavaksi;
  agentti ei hyväksy tai mergeä sitä.

## Ownerin tarkistettavat avoimet sidonnat

| Tapaus | Tämän työn ratkaisu | Jäljellä oleva täsmällinen kysymys |
|---|---|---|
| Jalan tai käden kahden puolen arvot, kun toinen puoli puuttuu tai on E/E1 | Adapteri ei valitse puolta; vain ennalta valittu semanttinen arvo voidaan syöttää. | Miten lähdesäännön mukainen “parempi puoli” ratkaistaan, kun toisen puolen tulos puuttuu tai on koodattu epäonnistumiseksi? |
| Toimintatestin E | Testikohtainen koodikirja on pakollinen; tuntematon teksti pysähtyy. | Osoittaako kyseisen testin E fyysistä/funktionaalista kyvyttömyyttä vai muuta suoriutumattomuutta? |
| 10 m aika puuttuu, apuvälineluokka on kirjattu | Apuvälineluokkaa ei tulkita suoriutumattomuuden syyksi. | Onko kyseiselle testille dokumentoitu sääntö, joka yhdistää puuttuvan ajan apuvälineluokkaan ja fyysiseen kyvyttömyyteen? |
