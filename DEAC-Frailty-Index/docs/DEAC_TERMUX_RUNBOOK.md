# DEAC v2:n suojattu Termux-ajo-ohje

## Tila ja viimeisin varmennettu ajo

Laskentatoteutus PR #184 yhdistettiin `main`-haaraan commitilla
`6b64c322b3b6043562e9fba181124e348330038f` 2026-10-05. Mainin viiden
laskentamoduulin SHA-256-tiivisteet täsmäsivät uusinta-ajon manifestiin.
Uusin ajuri tallensi lisäksi oman tiivisteensä.

Suojatun uusinta-ajon kooste oli 540 lähderiviä, 527 ensimmäistä käyntiä,
13 myöhempää käyntiä, 502 MOI-referenssihavaintoa ja kvintiilirajat 4/6/7/9.
Indeksi muodostui 470 henkilölle; 57 jäi kattavuusrajan alle. Aiemman
suojatun tuloksen kanssa tehty vertailu ei löytänyt eroja kohorttiavaimissa,
komponenttipisteissä, indeksien saatavuudessa tai indeksiarvoissa.

Mittarin ominaisuuksien ja tutkimusyhteyksien arviointi jatkuu Termuxissa
paikallisen handoverin, päätöslisän, suojatun konfiguraation ja varmennetun
ajomanifestin perusteella. PC-repon synkronointi tehdään myöhemmin. Yhteyden
puuttuminen ei estä hyväksytyn version käyttöä tai arviointia; todellinen
ristiriita hyväksytyissä pisteytyssäännöissä käsitellään erikseen.

## Komponenttien lähde-, puuttuvuus- ja pisteytysrekisteri

DEAC:n pysyvä rekisteri muodostuu seuraavista toisiaan täydentävistä osista:

- `docs/DEAC_HANDOVER.md` §5–6 luettelee kaikki 20 komponenttia,
  hyväksytyt pisteytyssäännöt, havaittujen komponenttien nimittäjän ja
  vähintään 80 prosentin kattavuusrajan.
- `src/deac_source_adapter.py` yhdistää 20 nimettyä komponenttia semanttisiin
  syötekenttiin ja toteuttaa lähdenormalisoinnin sekä puuttuvuus- ja
  suoriutumattomuussäännöt. `src/deac_components.py`, `src/deac_moi.py` ja
  `src/deac_index.py` toteuttavat pisteytyksen ja indeksin kokoamisen.
- Tarkat snapshot-kohtaiset sarakepaikat, lähdekoodit ja kenttäkohtaiset
  puuttuvuusmääritykset ovat vain suojatussa SourceBindings-tiedostossa.
  Aktiivinen tiedosto sisältää 25 semanttista syötekenttää, joista adapteri
  muodostaa 20 komponenttia; kenttien arvoja tai lähdeotsakkeita ei julkaista.
- `docs/DEAC_DECISION_ADDENDUM.md` kirjaa hyväksytyt tekniset
  soveltamistulkinnat, kuten testikohtaisen varmennetun syyn, sivuvalinnan,
  MOI-ikäpisteet ja poikkeusarvojen käsittelyn.

Suojattu SourceBindings sisältää kenttäkohtaiset tavalliset puuttuvat arvot,
puristusluokan virhekoodit sekä testikohtaiset suoritus- ja syykoodit.
Tuntematon koodi pysäyttää ajon; sitä ei päätellä osallistujajakaumasta.

## Paikalliset suojatut asetukset ja tulokset

`$HOME` tarkoittaa Termuxin käyttäjän kotihakemistoa. Alla lueteltuja
paikallisia tiedostoja ei lisätä versionhallintaan.

| Sisältö                                                        | Sijainti                                                                                                               |
| -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Lähdepolku ja `KAAOS_ID_COL`                                   | `$HOME/Python-R-Scripts/config/.env`                                                                                   |
| Snapshot-kohtainen SourceBindings, puuttuvuus- ja testikoodit  | `$HOME/.local/share/deac-schema-inventory/deac_v2_SourceBindings_AUTH_SOURCE_20261005_owner-missing-decisions-v3.json` |
| Ensimmäisen käynnin valitsin, päivämääräsarake ja QC-odotukset | `$HOME/.local/share/deac-schema-inventory/deac_v2_cohort_selector_AUTH_SOURCE_20261005.json`                           |
| Tapauskohtainen MOI-korjausloki                                | `$HOME/.local/share/deac-schema-inventory/deac_v2_moi_case_correction_20261004.json`                                   |
| Ajon CSV ja manifesti                                          | `$HOME/.local/share/deac-schema-inventory/deac_v2_run_<UTC-aikaleima>/`                                                |

Konfiguraatiot, korjausloki, osallistujatulokset ja manifestit on suojattu
tiedostotilalla `0600`; ajohakemistot luodaan tilalla `0700`. Manifesti
kirjaa lähteen, koodimoduulien, asetusten ja tulostiedoston tiivisteet,
kohorttivalinnan sarakepaikat ja vain koontitason QC:n.

## Riippuvuudet

- Python 3.10 tai uudempi Termuxissa.
- Ajuri ja laskentakoodi käyttävät vain Pythonin vakiokirjastoa; erillistä
  Excel-lukijapakettia ei tarvita.
- Synteettisiä testejä varten tarvitaan `pytest`. Uusia ajonaikaisia
  Python-riippuvuuksia ei ole lisätty.

## Ajo

Aja aliprojektin juuresta. Ajuri palauttaa virheen, jos lähdesnapshot,
asetushashit, otsakesidonta tai kohortin QC eivät vastaa suojattuja
määrityksiä. Osallistujatason CSV ja manifesti kirjoitetaan uuteen,
suojattuun UTC-aikaleimalliseen hakemistoon; olemassa olevaa tulosta ei
ylikirjoiteta.

```bash
cd "$HOME/worktrees/deac-v2-source-binding/DEAC-Frailty-Index"
python src/deac_run.py \
  --env "$HOME/Python-R-Scripts/config/.env" \
  --bindings "$HOME/.local/share/deac-schema-inventory/deac_v2_SourceBindings_AUTH_SOURCE_20261005_owner-missing-decisions-v3.json" \
  --selector "$HOME/.local/share/deac-schema-inventory/deac_v2_cohort_selector_AUTH_SOURCE_20261005.json" \
  --correction "$HOME/.local/share/deac-schema-inventory/deac_v2_moi_case_correction_20261004.json" \
  --output-parent "$HOME/.local/share/deac-schema-inventory"
```

Ajuri tulostaa manifestin polun ja koonti-QC:n, ei tunnisteita, lähdearvoja
eikä osallistujarivejä. Viimeksi varmennetun ajon manifesti ja tulos säilyvät
suojattuina omassa aikaleimahakemistossaan.

Synteettisten DEAC-testien komento repojuuresta:

```bash
cd "$HOME/worktrees/deac-v2-source-binding"
uv run --offline --no-project --with pytest pytest -q tests/test_deac_*.py
```

## Tutkimuksellisen arvioinnin rajaus

Seuraava vaihe kuvaa jakauman, komponenttien puuttuvuuden ja kattavuuden sekä
vertailee 470 indeksin saanutta ja 57 kattavuusrajan alittanutta. Työ jatkuu
Termuxissa paikallisen handoverin, päätöslisän, suojatun konfiguraation ja
varmennetun manifestin perusteella; PC-repon synkronointi tehdään myöhemmin.
PC-yhteyden puuttuminen ei estä hyväksytyn version käyttöä tai arviointia.
Todellinen hyväksyttyjen sääntöjen ristiriita käsitellään erikseen. Arviointi
ei muuta laskentatoteutusta tai hyväksyttyjä pisteytyssääntöjä. DEAC:n
kategoriset raja-arvot ja FI22/C22-suhde pysyvät avoimina, kunnes Owner tekee
niistä erilliset tutkimukselliset päätökset.
