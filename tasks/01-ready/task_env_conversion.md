# Task: Turvallinen termux.env -> .env konversio (Option B)

**Tila:** 01-ready
**Konteksti:** Option B -tietoturva estää `DATA_ROOT`:in ja absoluuttisten polkujen etsimisen tai tulostamisen.
**Tavoite:** Muuntaa käyttäjän toimittama `termux.env` turvallisesti projektin paikalliseksi `config/.env` -tiedostoksi paljastamatta polkuja.

## Vaatimukset (DoD)
1. Agentti ei koskaan etsi koko levyltä `termux.env` -tiedostoa.
2. Agentti ohjeistaa käyttäjää lataamaan `termux.env` chattiin TAI asettamaan sen väliaikaisesti Gitin ignoraamaan sijaintiin (esim. `outputs/temp_env/termux.env`).
3. Agentti lukee tiedoston PS7-skriptillä, poimii sallitut avaimet (`DATA_ROOT`, yms.) ja generoi tiedoston `Quantify-FOF-Utilization-Costs/config/.env`.
4. Mitään polkuarvoja (esim. C:\Users\...) ei tulosteta chattiin.
5. Varmistetaan, että uusi `.env` on `.gitignore`:n piirissä.

## Työohje agentille
1. Siirrä tämä task `02-in-progress` -kansioon.
2. Pyydä käyttäjää: "Lataa `termux.env` tähän keskusteluun tiedostona, tai laita se kansioon `outputs/temp_env/` ja ilmoita kun valmis."
3. Suorita PS7-skripti, joka tekee parsinnan turvallisesti muistissa ja kirjoittaa tiedoston.
4. Kirjoita onnistumisesta loki tähän tiedostoon ja siirrä `03-review`.

## Lokit (Agentti täyttää)
- [ ] Odottaa suoritusta.
