# Variable Standardization Specification

Tämä tiedosto (`VARIABLE_STANDARDIZATION.csv`) määrittelee säännöt, joilla analyysiaineiston sarakenimet standardoidaan **kanoniseen muotoon** (canonical_name) ennen QC-tarkistuksia ja mallinnusta.

## Tavoite

Varmistaa, että analyysikoodi (`Composite_Z ~ time * FOF_status ...`) toimii ennustettavasti riippumatta siitä, onko lähdedatassa käytetty vanhoja tai projektikohtaisia alias-nimiä (esim. `ID` vs `id`, `Age` vs `age`).

## Sarakkeet

- **canonical_name**: Analyysissa käytettävä standardinimi (vastaa `docs/ANALYSIS_PLAN.md`).
- **alias**: Datan mahdollinen sarakenimi, joka halutaan käsitellä.
- **priority**: Konfliktinratkaisu (pienempi numero voittaa, jos logiikkaa laajennetaan; nyt pääosin informatiivinen).
- **action**:
  - `rename_to_canonical`: Uudelleennimeä sarake automaattisesti ja turvallisesti.
  - `verify`: Pysäytä ajo (STOP), jos tämä alias löytyy. Vaatii ihmisen hyväksynnän (muuta CSV:ssä action -> rename_to_canonical tai korjaa ETL-putki).

## Konfliktit (Conflict Check)

Standardointifunktio (`standardize_names`) pysäyttää ajon välittömästi, jos datassa on **useita** samaan kanoniseen nimeen mapattavia sarakkeita (esim. sekä `id` että `ID` löytyvät, tai `FOF` ja `FOF_status`). Tämä estää vahinkovarjostamisen (shadowing).

## Käyttöohje

Jos QC-ajo pysähtyy virheeseen `[VERIFY HIT]`, se tarkoittaa, että datasta löytyi sarake (esim. `kaatumisenpelkoOn`), jota ei ole vielä "valtuutettu" automaattiseen muunnokseen.

1. Varmista, että sarakkeen sisältö on todella se mitä odotetaan.
2. Muuta `VARIABLE_STANDARDIZATION.csv`:ssä action `verify` -> `rename_to_canonical`.
3. Commitoi muutos ja aja QC uudelleen.
