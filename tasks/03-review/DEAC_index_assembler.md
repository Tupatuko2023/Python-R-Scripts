# DEAC: 20 komponentin synteettinen indeksikokoaja

## Tila

- State: `03-review`
- Ownerin tehtävänanto: 2026-10-01, PR #172:n hyväksytyn pisteytyserän jälkeen.
- Lähtöcommit: `b68a71d25adaeb5b1c8cd3c3314325f802f3893e`.

## Rajaus

- Toteuta puhdas kokoaja, joka vaatii kaikki 20 nimettyä komponenttipaikkaa ja hyväksyy normalisoidut 0–1-pisteet sekä puuttuvuuden.
- Laske havaittujen pisteiden summa ja havaittujen komponenttien nimittäjä; sovella handover v1.1.0:n vähintään 80 prosentin kattavuusrajaa relevantteihin komponentteihin.
- Pidä MOI omana pakollisena nimettynä paikkanaan. Erota aidosti ei-sovellettava tavallisesta puuttuvasta ilman lähde- tai syytulkintaa.
- Lisää vain synteettiset rajatestit ja lyhyt käyttörajaus READMEhen.
- Älä toteuta lähdeadapteria, kvintiilejä, yksikkömuunnoksia, mittauksen valintaa, osallistujatason ajoa tai 19 komponentin vaihtoehtoindeksiä.
- Kuuden komponentin lähdesidonta raportoidaan erillisenä avoimien kohtien pakettina; suojattua metadataa ei julkaista PR:ssä.

## Definition of Done

- [x] Kaikki 20 nimeä vaaditaan; puuttuva tai ylimääräinen nimi ja virheellinen piste hylätään näkyvästi.
- [x] Synteettiset testit kattavat 16/20- ja 15/20-rajan, tavallisen puuttuvuuden, ei-sovellettavuuden ja 0–1-pistealueen.
- [x] Soveltuva repository-gate ja kohdennetut Python-testit läpäisevät.
- [x] Rajattu diff valmisteltiin Ownerin PR-katselmointiin; agentti ei mergeä.

## Loki

- 2026-10-01T11:05:20Z: Ownerin suora toimeksianto vastaanotettu. Matching ready-tehtävä kirjattu PR #172:n todennetusta merge-commitista erilliseen puhtaaseen työpuuhun; ei data-ajoa.
- 2026-10-01T11:05:20Z: Tehtävä valittu ready-jonosta ja siirretty in-progress-tilaan ennen toteutusta. Lähdesidonnan erillistä työtä ei yhdistetä tähän PR:ään.
- 2026-10-01T11:09:00Z: Puhdas 20-paikkainen kokoaja ja synteettiset testit valmiit. `uv run --offline --no-project --with pytest python -B -m pytest -q ../tests/test_deac_index.py ../tests/test_deac_components.py` DEAC-juuresta: exit 0, 219 läpäistyä. `git diff --cached --check`: exit 0. `tools/run-gates.sh --mode pre-push --smoke`: exit 0. Handover v1.1.0:n SHA-256 täsmäsi hyväksyttyyn arvoon. Tuotantoaineistoa tai suojattua adapteria ei käytetty. Tehtävä siirretään review-tilaan PR-arviota varten.
