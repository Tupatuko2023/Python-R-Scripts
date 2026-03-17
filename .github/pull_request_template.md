## Kuvaus muutoksista (Description)
## Liittyvät issuet (Related Issues)
Fixes #

## Työskentelyalue (Scope)
- [ ] `Fear-of-Falling`
- [ ] `Electronic-Frailty-Index`
- [ ] `Quantify-FOF-Utilization-Costs`
- [ ] Muu: 

## Laadunvarmistus ja Turvallisuus (QC & Security Checklist)
- [ ] **Dataturva:** Koodi/PR ei sisällä raakadataa (`data/`), henkilötietoja (PII/PHI) tai salaisuuksia.
- [ ] **Working Directory:** Skriptit on ajettu aliprojektin juuresta (esim. `cd Python-R-Scripts/Fear-of-Falling`) ja polut ovat suhteellisia tai käyttävät `here::here()`-pakettia.
- [ ] **Toistettavuus:** Ympäristö on palautettu (`renv::restore()` / `requirements.txt`). Siemenluku (`set.seed`) on käytössä vain satunnaisuutta sisältävissä malleissa.
- [ ] **Output Discipline:** Generoidut artefaktit (taulukot, kuvat) ohjautuvat oikeaan `outputs/`-kansioon ja niistä on kirjattu rivi `manifest/manifest.csv`-tiedostoon. (Artefakteja ei ole commitoitu repon historiaan ilman erillistä syytä).
- [ ] **Table-to-Text Crosscheck:** Jos raportointitekstejä on päivitetty, numerot vastaavat täsmälleen analyysimallien tuloksia (estimaatit, luottamusvälit).

## Validointi (Validation / How to test)
```bash
# Esimerkki:
# Rscript R-scripts/K11/K11_MAIN.V1_primary-ancova.R
```

## Tekoäly / Agentit (AI Assistance)
- [ ] Ei agenttia / Ihmisen kirjoittama.
- [ ] Agentin generoima / avustama (Agentti toimi *fail-closed* -periaateella ohjeiden mukaisesti).
