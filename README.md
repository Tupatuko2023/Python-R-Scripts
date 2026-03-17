![Python and R Scripts cover](docs/assets/cover/python-r-scripts-cover.jpg)

# Python-R-Scripts Monorepo

![python-ci](https://github.com/Tupatuko2023/Python-R-Scripts/actions/workflows/python-ci.yml/badge.svg)
![r-ci](https://github.com/Tupatuko2023/Python-R-Scripts/actions/workflows/r-ci.yml/badge.svg)

Tämä monorepositorio sisältää R- ja Python-pohjaisia analyysiputkia, skriptejä ja työkaluja lääketieteelliseen tutkimukseen ja terveysdatan analysointiin. Projekti on osa laajempaa väitöskirjatyötä ja tutkimuskokonaisuutta.

## English Summary

This is a monorepo for Python and R based medical research pipelines.

**Security First:** STRICTLY NO PHI / PII or raw data allowed in this repository. All data must remain external or gitignored. Report vulnerabilities privately via GitHub Security Advisories, DO NOT open a public issue. See [SECURITY.md](.github/SECURITY.md).

**Subprojects:**
- `Fear-of-Falling`: R-based pipeline for physical performance and FOF analysis.
- `Electronic-Frailty-Index`: Python & R tools for EFI calculation.
- `Quantify-FOF-Utilization-Costs`: Hybrid pipeline for healthcare utilization costs.

**Contributing:** Please read [CONTRIBUTING.md](.github/CONTRIBUTING.md) before making changes. All artifacts must be logged, and reproducibility must be ensured.

---

## Tärkeää: Tietoturva ja datapolitiikka

Tietoturva ja tutkimusetiikka ovat tämän projektin keskiössä.

*   **EHDOTON KIELTO:** Tähän repositorioon **ei saa koskaan viedä raakadataa, henkilötietoja (PII) tai potilastietoja (PHI)**.
*   **Data-asetukset:** Raakadata säilytetään aina repositorion ulkopuolella (esim. `DATA_ROOT`-polussa) tai se on `.gitignore`-listattu. Repo sisältää vain koodia, dokumentaatiota ja synteettistä esimerkkidataa.
*   **Tietoturvavuodot:** Jos huomaat repositoriossa arkaluontoista dataa, raportoi se välittömästi [yksityisen tietoturvakäytännön mukaisesti](.github/SECURITY.md). **Älä avaa julkista issue-tikettiä.**

---

## Aliprojektit (Subprojects)

Repositorio on jaettu useisiin itsenäisiin aliprojekteihin, joilla on oma dokumentaationsa ja ympäristönsä:

1. **[Fear-of-Falling (FOF)](Fear-of-Falling/README.md):** R-analyysiputki kaatumisen pelon ja toimintakyvyn välisen yhteyden tutkimiseen. Sisältää Kxx-analyysiskriptit, `renv`-ympäristön ja manifesti-pohjaisen tuloshallinnan.
2. **[Electronic-Frailty-Index (EFI)](Electronic-Frailty-Index/README.md):** Python- ja R-työkaluja haurausindeksin (EFI) laskemiseen ja validointiin. Sisältää kliinisen datan prosessointiin ja logistiseen regressioon tarkoitettuja skriptejä.
3. **[Quantify-FOF-Utilization-Costs](Quantify-FOF-Utilization-Costs/README.md):** Hybridiputki (R + Python) kaatumisen pelkoon liittyvän palvelukäytön ja kustannusten kvantifiointiin. Painottaa turvallista aggregointia ja raportointia (Option B).

---

## Kontribuointi ja kehitys

Arvostamme apuasi koodin ja analyysien parantamisessa.

*   **Ohjeet:** Lue ehdottomasti **[Kontribuutio-ohjeet (CONTRIBUTING.md)](.github/CONTRIBUTING.md)** ennen muutosten tekemistä. Se määrittelee vaaditut QC-tarkistukset, manifesti-lokituksen ja koodausstandardit.
*   **Pull Requests:** Käytä [PR-mallipohjaa](.github/pull_request_template.md) varmistaaksesi, että kaikki laatutarkistukset on tehty.
*   **Ympäristöt:** Projekti tukee Windows (PowerShell 7), Linux ja Android (Termux) -ympäristöjä.

---

## Viittaaminen (Citation) ja Lisenssi

*   **Viittaaminen:** Jos käytät tämän repositorion koodia tutkimuksessasi, viittaa siihen **[CITATION.cff](CITATION.cff)** -tiedoston ohjeiden mukaisesti.
*   **Lisenssi:** Projekti on lisensoitu [MIT-lisenssillä](LICENSE).
*   **Vastuunvapautus:** Lue myös [DISCLAIMER.md](DISCLAIMER.md).

---

## Pikastartti (Quick Start)

Katso tarkemmat ajo-ohjeet kunkin aliprojektin omasta README-tiedostosta.

### Fear of Falling (R)

```bash
cd Fear-of-Falling
Rscript -e 'renv::restore()'
# Aja skripti (esim. K11)
Rscript "R-scripts/K11/K11_MAIN.V1_primary-ancova.R"
```

### Electronic Frailty Index (Python)

```bash
python Electronic-Frailty-Index/src/efi/cli.py --input data/external/synthetic_patients.csv --out out/efi_scores.csv
```

---

## Kehittäjän työkalut (CLI)

*   **Kimi CLI:** `tools/kimi_cli.py` (NVIDIA NIM -pohjainen tekoälyavustaja).
*   **Markdown Linting:** Käytä `npm run lint` tai `pre-commit` hookeja Markdown-muotoilun varmistamiseen.

```bash
# Markdown-korjaukset lokaalisti
npx prettier --write "**/*.md"
npx markdownlint-cli2 --fix "**/*.md"
```
